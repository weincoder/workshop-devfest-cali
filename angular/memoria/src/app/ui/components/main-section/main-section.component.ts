import { Component, inject, input, output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { WordPractice } from '../../../domain/models/word-practice';
import { MenuColorService } from '../../../services/menu-color.service';

@Component({
  selector: 'app-main-section',
  standalone: true,
  imports: [FormsModule],
  template: `
    <section
      class="text-white flex justify-center min-h-[calc(100vh-4rem)] p-4 transition-colors duration-500"
      [style.background-color]="menuColorService.color()"
    >
      <main class="w-full max-w-2xl bg-slate-900/95 rounded-2xl shadow-2xl p-6 sm:p-8 border border-slate-700/80 h-fit my-4 animate-fade-in">
        <header class="mb-6 text-center">
          <h2 class="text-3xl font-black bg-gradient-to-r from-purple-400 to-cyan-400 text-transparent bg-clip-text">
            MemoPalabras 🧠
          </h2>
          <p class="text-slate-400 mt-2">
            Escribe las {{ words().length }} palabras que memorizaste en orden.
          </p>
          <div class="flex justify-center gap-8 mt-4 text-base">
            <p>Aciertos: <span class="font-bold text-emerald-400">{{ score() }}</span></p>
            <p>Intentos: <span class="font-bold text-amber-400">{{ attempts() }}</span></p>
          </div>
        </header>

        <hr class="border-slate-700 mb-6" />

        <div class="space-y-4">
          @for (word of words(); track word.original; let i = $index) {
            <div class="bg-slate-800/80 p-4 rounded-xl border border-slate-700/60">
              <div class="flex items-center justify-between mb-2">
                <label class="text-sm font-mono tracking-wider text-cyan-400" [for]="'word-' + i">
                  Palabra #{{ i + 1 }}
                </label>
                <div>
                  @if (word.status === 'correct') {
                    <span class="text-xl">✅</span>
                  }
                  @if (word.status === 'incorrect') {
                    <span class="text-xl">❌</span>
                  }
                </div>
              </div>

              <div class="flex gap-2">
                <input
                  [id]="'word-' + i"
                  type="text"
                  [(ngModel)]="word.userInput"
                  [disabled]="word.status !== 'pending'"
                  placeholder="Escribe la palabra aquí..."
                  class="w-full px-3 py-2.5 bg-slate-900 border border-slate-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-purple-500 disabled:opacity-60"
                  (keyup.enter)="wordChecked.emit(i)"
                />
                <button
                  type="button"
                  (click)="wordChecked.emit(i)"
                  [disabled]="word.status !== 'pending'"
                  class="px-4 py-2.5 bg-blue-600 hover:bg-blue-500 rounded-lg font-semibold text-white transition cursor-pointer disabled:bg-slate-700 disabled:cursor-not-allowed"
                >
                  Verificar
                </button>
              </div>

              @if (word.status === 'incorrect') {
                <p class="mt-2 text-rose-400 text-xs">
                  Palabra incorrecta. La respuesta correcta era:
                  <span class="font-bold text-rose-200">{{ word.original }}</span>
                </p>
              }
            </div>
          }
        </div>

        <div class="mt-8 flex flex-col sm:flex-row gap-3">
          <button
            type="button"
            (click)="practiceCancelled.emit()"
            class="sm:w-1/3 py-3 bg-slate-700 hover:bg-slate-600 rounded-xl font-semibold text-white transition cursor-pointer"
          >
            Volver al Chat
          </button>
          <button
            type="button"
            (click)="practiceFinalized.emit()"
            [disabled]="!allAttempted()"
            class="sm:w-2/3 py-3 bg-purple-600 hover:bg-purple-500 rounded-xl font-bold text-white transition cursor-pointer disabled:bg-slate-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Finalizar Práctica y Ver Resultados
          </button>
        </div>
      </main>
    </section>
  `,
})
export class MainSectionComponent {
  readonly menuColorService = inject(MenuColorService);

  readonly words = input.required<WordPractice[]>();
  readonly score = input.required<number>();
  readonly attempts = input.required<number>();
  readonly allAttempted = input.required<boolean>();

  readonly wordChecked = output<number>();
  readonly practiceFinalized = output<void>();
  readonly practiceCancelled = output<void>();
}
