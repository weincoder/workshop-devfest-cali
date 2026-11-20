import { Component, computed, effect, inject, signal } from '@angular/core';
import { WordPractice } from './domain/models/word-practice';
import { WordsService } from './services/words.service';
import { HeaderComponent } from './ui/components/header/header.component';
import { MainSectionComponent } from './ui/components/main-section/main-section.component';
import { PromptFormComponent } from './ui/components/prompt-form/prompt-form.component';
import { ResultsModalComponent } from './ui/components/results-modal/results-modal.component';
import { SetupBannerComponent } from './ui/components/setup-banner/setup-banner.component';
import { WordPracticeComponent } from './ui/components/word-practice/word-practice.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    SetupBannerComponent,
    HeaderComponent,
    PromptFormComponent,
    WordPracticeComponent,
    MainSectionComponent,
    ResultsModalComponent,
  ],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {
  private readonly wordsService = inject(WordsService);

  readonly words = signal<WordPractice[]>([]);
  readonly score = signal(0);
  readonly attempts = signal(0);
  readonly showResultsModal = signal(false);

  readonly lastScore = signal(0);
  readonly lastTotalWords = signal(0);
  readonly lastFinalAccuracy = signal(0);

  readonly allWordsAttempted = computed(
    () => this.words().length > 0 && this.words().every((w) => w.status !== 'pending'),
  );

  constructor() {
    effect(() => {
      const wordsFromAI = this.wordsService.words();
      this.words.set(
        wordsFromAI.map((word) => ({
          original: word,
          userInput: '',
          status: 'pending',
        })),
      );
      this.score.set(0);
      this.attempts.set(0);
    });
  }

  checkWord(index: number): void {
    this.words.update((currentWords) => {
      const target = currentWords[index];
      if (!target || target.status !== 'pending' || !target.userInput.trim()) {
        return currentWords;
      }

      const normalizedInput = target.userInput
        .normalize('NFD')
        .replaceAll(/[\u0300-\u036f]/g, '')
        .trim()
        .toUpperCase();

      const updated = { ...target };
      this.attempts.update((a) => a + 1);

      if (normalizedInput === updated.original) {
        updated.status = 'correct';
        this.score.update((s) => s + 1);
      } else {
        updated.status = 'incorrect';
      }

      const next = [...currentWords];
      next[index] = updated;
      return next;
    });
  }

  finalizePractice(): void {
    const total = this.words().length;
    const currentScore = this.score();
    this.lastScore.set(currentScore);
    this.lastTotalWords.set(total);
    this.lastFinalAccuracy.set(total > 0 ? Math.round((currentScore / total) * 100) : 0);
    this.showResultsModal.set(true);
    this.wordsService.clearWords();
  }

  cancelPractice(): void {
    this.wordsService.clearWords();
  }

  restartPractice(): void {
    this.showResultsModal.set(false);
    this.score.set(0);
    this.attempts.set(0);
    this.wordsService.clearWords();
  }
}
