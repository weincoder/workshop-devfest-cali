import { Component, OnDestroy, OnInit, inject, signal } from '@angular/core';
import { WordsService } from '../../../services/words.service';

@Component({
  selector: 'app-word-practice',
  standalone: true,
  template: `
    @if (showMemorizationModal()) {
      <div class="fixed inset-0 bg-slate-950/90 backdrop-blur-sm flex items-center justify-center p-4 z-50 animate-fade-in">
        <div class="bg-slate-900 rounded-2xl shadow-2xl p-6 sm:p-8 border border-slate-700 w-full max-w-lg">
          <h2 class="text-3xl font-black text-center mb-2 bg-gradient-to-r from-teal-400 to-cyan-400 text-transparent bg-clip-text">
            ¡Memoriza estas palabras!
          </h2>
          <p class="text-slate-400 text-center mb-6">
            Tienes <span class="font-bold text-amber-400">{{ timeLeft() }} segundos</span>. ¡Concéntrate!
          </p>

          <div class="grid grid-cols-2 sm:grid-cols-3 gap-3 mb-6 max-h-80 overflow-y-auto">
            @for (word of words(); track word; let i = $index) {
              <div class="bg-slate-800 p-3 rounded-lg border border-slate-700 relative text-center">
                <span class="absolute top-1 left-2 text-[10px] text-slate-400 font-bold">#{{ i + 1 }}</span>
                <p class="text-sm font-bold text-white mt-2 tracking-wide">{{ word }}</p>
              </div>
            }
          </div>

          <button
            type="button"
            (click)="closeMemorizationModal()"
            class="w-full py-3 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-bold text-white transition cursor-pointer"
          >
            ¡Estoy Listo! (Empezar práctica)
          </button>
          <p class="text-slate-500 text-center text-xs mt-3">
            El modal se ocultará automáticamente en {{ timeLeft() }} segundos.
          </p>
        </div>
      </div>
    }
  `,
})
export class WordPracticeComponent implements OnInit, OnDestroy {
  private readonly wordsService = inject(WordsService);

  readonly words = this.wordsService.words;
  readonly showMemorizationModal = signal(true);
  readonly timeLeft = signal(this.wordsService.memorizationDuration());

  private timerId: ReturnType<typeof setInterval> | null = null;

  ngOnInit(): void {
    this.timeLeft.set(this.wordsService.memorizationDuration());
    this.timerId = setInterval(() => {
      this.timeLeft.update((t) => t - 1);
      if (this.timeLeft() <= 0) {
        this.closeMemorizationModal();
      }
    }, 1000);
  }

  ngOnDestroy(): void {
    this.clearTimer();
  }

  closeMemorizationModal(): void {
    this.showMemorizationModal.set(false);
    this.clearTimer();
  }

  private clearTimer(): void {
    if (this.timerId !== null) {
      clearInterval(this.timerId);
      this.timerId = null;
    }
  }
}
