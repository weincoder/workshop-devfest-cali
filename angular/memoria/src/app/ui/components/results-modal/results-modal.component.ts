import { Component, inject, input, output } from '@angular/core';
import { MenuColorService } from '../../../services/menu-color.service';

@Component({
  selector: 'app-results-modal',
  standalone: true,
  template: `
    <div
      class="fixed inset-0 flex items-center justify-center p-4 z-50 bg-slate-950/85 backdrop-blur-sm animate-fade-in"
    >
      <div class="bg-slate-900 rounded-2xl shadow-2xl p-8 border border-slate-700 w-full max-w-md text-center">
        <div class="text-6xl mb-4">🏆</div>

        <h2 class="text-3xl font-black mb-2 bg-gradient-to-r from-amber-300 to-orange-400 text-transparent bg-clip-text">
          ¡Práctica Completada!
        </h2>
        <p class="text-slate-400 mb-6">Estos son tus resultados.</p>

        <div class="mb-6 bg-slate-800/80 rounded-xl p-5 border border-slate-700">
          <p class="text-sm text-slate-400">Tu Puntuación Final</p>
          <p class="text-5xl font-black text-white mt-1">
            {{ score() }} <span class="text-2xl text-slate-500">/ {{ totalWords() }}</span>
          </p>
          <p
            class="text-lg font-bold mt-2"
            [class]="finalAccuracy() >= 80 ? 'text-emerald-400' : 'text-amber-400'"
          >
            Precisión: {{ finalAccuracy() }}%
          </p>
        </div>

        <button
          type="button"
          (click)="restarted.emit()"
          class="w-full py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-bold text-white transition cursor-pointer"
        >
          Volver a Jugar
        </button>
      </div>
    </div>
  `,
})
export class ResultsModalComponent {
  readonly menuColorService = inject(MenuColorService);

  readonly score = input.required<number>();
  readonly totalWords = input.required<number>();
  readonly finalAccuracy = input.required<number>();

  readonly restarted = output<void>();
}
