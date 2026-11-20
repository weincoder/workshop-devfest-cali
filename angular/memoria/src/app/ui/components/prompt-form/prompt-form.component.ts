import { Component, inject, signal } from '@angular/core';
import { FormControl, ReactiveFormsModule, Validators } from '@angular/forms';
import { Message } from '../../../domain/models/message';
import { AiService } from '../../../services/ai.service';
import { MenuColorService } from '../../../services/menu-color.service';

@Component({
  selector: 'app-prompt-form',
  standalone: true,
  imports: [ReactiveFormsModule],
  template: `
    <div
      class="flex items-center justify-center min-h-[calc(100vh-4rem)] p-4 transition-colors duration-500"
      [style.background-color]="menuColorService.color()"
    >
      <div class="w-full max-w-2xl bg-slate-900/95 rounded-2xl shadow-2xl p-6 sm:p-8 border border-slate-700/80 animate-fade-in">
        <div class="text-center">
          <h2 class="text-3xl sm:text-4xl font-black bg-gradient-to-r from-purple-400 via-fuchsia-400 to-cyan-400 text-transparent bg-clip-text">
            Crea tu Práctica 🧠
          </h2>
          <p class="text-slate-400 mt-2 text-base">
            Pídele a Gemini palabras para memorizar o cambia el color del tablero usando Function Calling.
          </p>
        </div>

        <!-- Sugerencias rápidas para probar en el workshop -->
        <div class="mt-5 flex flex-wrap justify-center gap-2">
          @for (suggestion of suggestions; track suggestion) {
            <button
              type="button"
              (click)="useSuggestion(suggestion)"
              [disabled]="isLoading()"
              class="text-xs px-3 py-1.5 rounded-full bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-600 transition cursor-pointer disabled:opacity-50"
            >
              {{ suggestion }}
            </button>
          }
        </div>

        <!-- Historial del chat -->
        @if (messageHistory().length > 0) {
          <section class="mt-6 max-h-72 overflow-y-auto space-y-3 pr-1">
            @for (message of messageHistory(); track $index) {
              <div [class]="message.sender === 'user' ? 'flex justify-end' : 'flex justify-start'">
                <div
                  class="max-w-[85%] rounded-xl px-4 py-2.5 text-sm leading-relaxed"
                  [class]="
                    message.sender === 'user'
                      ? 'bg-indigo-600 text-white rounded-br-sm'
                      : 'bg-slate-800 text-slate-100 border border-slate-700 rounded-bl-sm'
                  "
                >
                  <p class="text-[11px] uppercase tracking-wider opacity-70 mb-1">
                    {{ message.sender === 'user' ? 'Tú' : 'Agente Gemini' }}
                  </p>
                  <p class="whitespace-pre-wrap">{{ message.text }}</p>
                  @if (message.toolsCalled && message.toolsCalled.length > 0) {
                    <div class="mt-2 flex flex-wrap gap-1">
                      @for (tool of message.toolsCalled; track tool) {
                        <span class="text-[11px] font-mono bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 px-2 py-0.5 rounded">
                          ⚡ tool: {{ tool }}()
                        </span>
                      }
                    </div>
                  }
                </div>
              </div>
            }
          </section>
        }

        <!-- Input de prompt -->
        <form (submit)="submitPrompt($event)" class="mt-6">
          <div class="flex">
            <input
              type="text"
              [formControl]="promptControl"
              placeholder="Ej: Dame 6 palabras de objetos cotidianos para memorizar..."
              class="flex-grow px-4 py-3.5 bg-slate-800 border border-slate-600 rounded-l-xl text-white placeholder:text-slate-500 focus:outline-none focus:ring-2 focus:ring-purple-500 transition"
              autocomplete="off"
            />
            <button
              type="submit"
              [disabled]="isLoading() || promptControl.invalid"
              class="px-5 py-3.5 bg-purple-600 hover:bg-purple-500 rounded-r-xl font-semibold text-white transition cursor-pointer disabled:bg-slate-700 disabled:text-slate-400 disabled:cursor-not-allowed"
            >
              Enviar
            </button>
          </div>

          @if (submitted() && promptControl.invalid) {
            <p class="text-rose-400 text-xs mt-2">
              Escribe al menos 3 caracteres para enviar un mensaje.
            </p>
          }
        </form>

        @if (isLoading()) {
          <div class="mt-5 flex items-center justify-center gap-2 text-sm text-slate-300">
            <span class="inline-block h-4 w-4 animate-spin rounded-full border-2 border-purple-400 border-t-transparent"></span>
            <span>Gemini está pensando y evaluando qué herramientas usar...</span>
          </div>
        }
      </div>
    </div>
  `,
})
export class PromptFormComponent {
  readonly menuColorService = inject(MenuColorService);
  private readonly ai = inject(AiService);

  readonly submitted = signal(false);
  readonly isLoading = signal(false);
  readonly messageHistory = signal<Message[]>([]);

  readonly suggestions = [
    'Dame 6 palabras para memorizar',
    'Cambia el fondo a azul',
    'Pon el tema en morado',
    'Genera 8 palabras sobre una oficina',
  ];

  readonly promptControl = new FormControl('', {
    nonNullable: true,
    validators: [Validators.required, Validators.minLength(3)],
  });

  useSuggestion(text: string): void {
    this.promptControl.setValue(text);
    void this.sendQuestion(text);
  }

  async submitPrompt(event: Event): Promise<void> {
    event.preventDefault();
    this.submitted.set(true);

    const question = this.promptControl.value.trim();
    if (this.promptControl.invalid || !question) {
      return;
    }

    await this.sendQuestion(question);
  }

  private async sendQuestion(question: string): Promise<void> {
    this.isLoading.set(true);
    this.promptControl.reset('');
    this.submitted.set(false);

    this.messageHistory.update((history) => [...history, { sender: 'user', text: question }]);

    const response = await this.ai.ask(question);

    this.messageHistory.update((history) => [
      ...history,
      {
        sender: 'agent',
        text: response.text,
        toolsCalled: response.toolsCalled,
      },
    ]);

    this.isLoading.set(false);
  }
}
