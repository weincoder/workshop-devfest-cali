import { Component } from '@angular/core';
import { environment } from '../../../../environments/environment';

@Component({
  selector: 'app-setup-banner',
  standalone: true,
  template: `
    @if (!isConfigured) {
      <div class="bg-amber-500/15 border-b border-amber-400/40 px-4 py-3 text-amber-100">
        <div class="mx-auto max-w-4xl flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 text-sm">
          <div>
            <span class="font-bold text-amber-300">⚠️ Firebase aún no está configurado.</span>
            Edita <code class="bg-black/40 px-1.5 py-0.5 rounded text-amber-200">firebase-config.json</code>
            en la raíz y ejecuta:
            <code class="bg-black/40 px-1.5 py-0.5 rounded text-emerald-300">node setup-firebase.mjs</code>
          </div>
          <span class="text-xs text-amber-300/80 whitespace-nowrap">
            Luego recarga la página
          </span>
        </div>
      </div>
    }
  `,
})
export class SetupBannerComponent {
  readonly isConfigured = environment.isFirebaseConfigured;
}
