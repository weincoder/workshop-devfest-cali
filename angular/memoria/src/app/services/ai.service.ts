import { Injectable, inject } from '@angular/core';
import { FirebaseApp, getApp, getApps, initializeApp } from 'firebase/app';
import { ReCaptchaV3Provider, initializeAppCheck } from 'firebase/app-check';
import {
  AgentPlatformBackend,
  ChatSession,
  FunctionCall,
  FunctionDeclarationsTool,
  FunctionResponsePart,
  GenerativeModel,
  GoogleAIBackend,
  Schema,
  getAI,
  getGenerativeModel,
} from 'firebase/ai';
import { environment } from '../../environments/environment';
import { MenuColorService } from './menu-color.service';
import { WordsService } from './words.service';

export interface AiResponse {
  text: string;
  toolsCalled: string[];
}

type SaveGeneratedWordsArgs = { words?: string[] };
type ChangeMenuColorArgs = { color?: string };

@Injectable({ providedIn: 'root' })
export class AiService {
  private readonly menuColorService = inject(MenuColorService);
  private readonly wordsService = inject(WordsService);

  private model: GenerativeModel | null = null;
  private chat: ChatSession | null = null;

  constructor() {
    if (environment.isFirebaseConfigured) {
      this.initializeAi();
    }
  }

  private initializeAi(): void {
    const firebaseApp: FirebaseApp =
      getApps().length > 0 ? getApp() : initializeApp(environment.firebase);

    // Firebase App Check (obligatorio para Firebase AI Logic desde Nov 2026)
    const debugToken = environment.appCheck.debugToken.trim();
    const recaptchaSiteKey = environment.appCheck.recaptchaV3SiteKey.trim();

    if (debugToken) {
      (globalThis as Record<string, unknown>)['FIREBASE_APPCHECK_DEBUG_TOKEN'] = debugToken;
    } else if (!recaptchaSiteKey) {
      // Genera automáticamente un debug token y lo imprime en la consola del navegador
      (globalThis as Record<string, unknown>)['FIREBASE_APPCHECK_DEBUG_TOKEN'] = true;
    }

    try {
      initializeAppCheck(firebaseApp, {
        provider: new ReCaptchaV3Provider(
          recaptchaSiteKey || 'workshop-debug-placeholder-key',
        ),
        isTokenAutoRefreshEnabled: true,
      });
    } catch (err) {
      console.warn('App Check ya inicializado o aviso de configuración:', err);
    }

    const backend = environment.useVertexAI
      ? new AgentPlatformBackend(environment.vertexAILocation)
      : new GoogleAIBackend();

    const ai = getAI(firebaseApp, { backend });

    // 🔧 PASO 1 (TOOLS): Agrega aquí nuevas FunctionDeclarations para el workshop
    const appTools: FunctionDeclarationsTool = {
      functionDeclarations: [
        {
          name: 'saveGeneratedWords',
          description:
            'Usa esta herramienta cuando el usuario pida una lista de palabras para memorizar. ' +
            'Genera las palabras tú mismo y pásalas en el arreglo para iniciar la práctica.',
          parameters: Schema.object({
            properties: {
              words: Schema.array({
                description:
                  'Arreglo de palabras tangibles generadas por la IA (en mayúsculas y sin tildes).',
                items: Schema.string(),
              }),
            },
          }),
        },
        {
          name: 'changeMenuColor',
          description: 'Cambia el color de fondo del tablero de la aplicación.',
          parameters: Schema.object({
            properties: {
              color: Schema.string({
                description:
                  'Color deseado. Opciones válidas: azul, blanco, rosado, amarillo, morado, verde, oscuro.',
              }),
            },
          }),
        },
      ],
    };

    const systemInstruction =
      'Eres un asistente experto en entrenamiento de memoria para el workshop de DevFest Cali. ' +
      'Tu objetivo es generar listas de palabras de OBJETOS COTIDIANOS y TANGIBLES (ej: MESA, SILLA, GATO, LAPIZ). ' +
      'Evita conceptos abstractos salvo que el usuario pida un tema específico. ' +
      'IMPORTANTE: Cuando el usuario pida palabras para memorizar, NO respondas listando texto plano; ' +
      'llama directamente a la herramienta saveGeneratedWords con las palabras en MAYÚSCULAS y sin tildes. ' +
      'Responde siempre en español de forma breve y amigable.';

    this.model = getGenerativeModel(ai, {
      model: environment.chatModel,
      systemInstruction,
      tools: [appTools],
    });

    this.chat = this.model.startChat();
  }

  async ask(prompt: string): Promise<AiResponse> {
    if (!environment.isFirebaseConfigured || !this.chat) {
      return {
        text:
          '⚠️ Firebase aún no está configurado. Pega tus credenciales en `firebase-config.json` ' +
          'en la raíz del proyecto, ejecuta `node setup-firebase.mjs` y recarga la página.',
        toolsCalled: [],
      };
    }

    const toolsCalled: string[] = [];

    try {
      let result = await this.chat.sendMessage(prompt);
      let functionCalls = result.response.functionCalls();

      // Soporta múltiples llamadas a herramientas en un solo turno
      while (functionCalls && functionCalls.length > 0) {
        const functionResponses: FunctionResponsePart[] = [];

        for (const call of functionCalls) {
          toolsCalled.push(call.name);
          const toolResult = await this.handleFunctionCall(call);
          functionResponses.push({
            type: 'functionResponse',
            functionResponse: {
              ...(call.id ? { id: call.id } : {}),
              name: call.name,
              response: toolResult,
            },
          });
        }

        result = await this.chat.sendMessage(functionResponses);
        functionCalls = result.response.functionCalls();
      }

      const text = (result.response.text() ?? '').trim();
      return {
        text: text || '¡Listo! Acción ejecutada correctamente.',
        toolsCalled,
      };
    } catch (error) {
      console.error('Error en AiService.ask():', error);
      return {
        text:
          '❌ Hubo un error comunicándose con Firebase AI. ' +
          'Revisa la consola del navegador, verifica que la API de Vertex AI (o Gemini Developer API) ' +
          'esté habilitada en tu proyecto Firebase y confirma tus credenciales en firebase-config.json.',
        toolsCalled,
      };
    }
  }

  // 🔧 PASO 2 (DISPATCHER): Agrega aquí el `case` de tu nueva tool
  private async handleFunctionCall(functionCall: FunctionCall): Promise<Record<string, unknown>> {
    console.log('⚡ Function Call detectada:', functionCall.name, functionCall.args);

    switch (functionCall.name) {
      case 'saveGeneratedWords':
        return this.handleSaveGeneratedWords(functionCall.args as SaveGeneratedWordsArgs);
      case 'changeMenuColor':
        return this.handleChangeMenuColor(functionCall.args as ChangeMenuColorArgs);
      default:
        return { status: 'error', message: `Herramienta desconocida: ${functionCall.name}` };
    }
  }

  // 🔧 PASO 3 (HANDLERS): Implementa aquí la lógica de cada tool
  private handleSaveGeneratedWords(args: SaveGeneratedWordsArgs): Record<string, unknown> {
    if (args && Array.isArray(args.words) && args.words.length > 0) {
      const cleanWords = args.words.map((word) =>
        this.normalizeNoAccents(String(word)).toUpperCase().trim(),
      );

      this.wordsService.clearWords();
      this.wordsService.addWords(cleanWords);

      return {
        status: 'success',
        count: cleanWords.length,
        message: 'Palabras guardadas en el tablero de memorización.',
      };
    }

    return { status: 'error', message: 'No se recibieron palabras válidas.' };
  }

  private handleChangeMenuColor(args: ChangeMenuColorArgs): Record<string, unknown> {
    const requested = String(args.color ?? '').toLowerCase().trim();
    const updated = this.menuColorService.setColor(requested);

    if (!updated) {
      return {
        status: 'error',
        message: `Color no válido. Colores permitidos: ${this.menuColorService.getAllowedColors().join(', ')}`,
      };
    }

    return { status: 'success', appliedColor: requested };
  }

  private normalizeNoAccents(input: string): string {
    return input.normalize('NFD').replaceAll(/[\u0300-\u036f]/g, '');
  }
}
