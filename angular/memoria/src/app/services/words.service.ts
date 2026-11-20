import { Injectable, signal } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class WordsService {
  readonly words = signal<string[]>([]);
  readonly memorizationDuration = signal<number>(45);

  addWord(word: string): void {
    if (word && !this.words().includes(word)) {
      this.words.update((current) => [...current, word]);
    }
  }

  addWords(newWords: string[]): void {
    this.words.update((current) => [
      ...current,
      ...newWords.filter((w) => w && !current.includes(w)),
    ]);
  }

  clearWords(): void {
    this.words.set([]);
  }

  setMemorizationDuration(seconds: number): void {
    const clamped = Math.max(5, Math.min(180, Math.round(seconds)));
    this.memorizationDuration.set(clamped);
  }
}
