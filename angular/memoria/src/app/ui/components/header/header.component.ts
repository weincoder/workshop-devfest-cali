import { Component, inject } from '@angular/core';
import { environment } from '../../../../environments/environment';
import { MenuColorService } from '../../../services/menu-color.service';

@Component({
  selector: 'app-header',
  standalone: true,
  template: `
    <header class="bg-gradient-to-r from-purple-700 via-indigo-700 to-blue-700 shadow-lg">
      <div class="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
        <div class="flex h-16 items-center justify-between">
          <div class="flex items-center gap-3">
            <span class="text-2xl">🧠</span>
            <div>
              <h1 class="text-lg font-bold text-white leading-tight">AI Memory Trainer</h1>
              <p class="text-xs text-purple-200">Angular + Firebase {{ backendLabel }}</p>
            </div>
          </div>

          <div class="flex items-center gap-3">
            <span
              class="hidden sm:inline-flex items-center gap-1.5 rounded-full bg-white/15 px-3 py-1 text-xs font-medium text-white backdrop-blur"
            >
              <span
                class="h-2.5 w-2.5 rounded-full border border-white/60"
                [style.background-color]="menuColorService.color()"
              ></span>
              Tema: {{ menuColorService.colorName() }}
            </span>

            <span
              class="rounded-full px-3 py-1 text-xs font-semibold"
              [class]="
                isConfigured
                  ? 'bg-emerald-500/20 text-emerald-200 border border-emerald-400/40'
                  : 'bg-amber-500/20 text-amber-200 border border-amber-400/40'
              "
            >
              {{ isConfigured ? '● Conectado' : '○ Sin IDs' }}
            </span>
          </div>
        </div>
      </div>
    </header>
  `,
})
export class HeaderComponent {
  readonly menuColorService = inject(MenuColorService);
  readonly isConfigured = environment.isFirebaseConfigured;
  readonly backendLabel = environment.useVertexAI ? 'Vertex AI' : 'Gemini API';
}
