import { Injectable, signal } from '@angular/core';

export const ALLOWED_COLORS = ['azul', 'blanco', 'rosado', 'amarillo', 'morado', 'verde', 'oscuro'] as const;
export type AllowedColor = (typeof ALLOWED_COLORS)[number];

const COLOR_MAP: Record<AllowedColor, string> = {
  azul: '#0ea5e9',
  blanco: '#f1f5f9',
  rosado: '#f472b6',
  amarillo: '#facc15',
  morado: '#7c3aed',
  verde: '#10b981',
  oscuro: '#0f172a',
};

@Injectable({
  providedIn: 'root',
})
export class MenuColorService {
  readonly color = signal<string>(COLOR_MAP.oscuro);
  readonly colorName = signal<AllowedColor>('oscuro');

  setColor(color: string): boolean {
    const normalized = color.toLowerCase().trim() as AllowedColor;
    if (!(normalized in COLOR_MAP)) {
      return false;
    }
    this.colorName.set(normalized);
    this.color.set(COLOR_MAP[normalized]);
    return true;
  }

  getAllowedColors(): readonly string[] {
    return ALLOWED_COLORS;
  }
}
