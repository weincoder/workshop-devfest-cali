import 'package:app/config/firebase/firebase_options.dart';
import 'package:flutter/material.dart';

class SetupBanner extends StatelessWidget {
  const SetupBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (WorkshopAIConfig.isFirebaseConfigured) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Firebase aún no está configurado. Pega tus IDs en firebase-config.json '
              'en la raíz y ejecuta: node setup-firebase.mjs (luego reinicia Flutter).',
              style: TextStyle(
                color: Colors.amber.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
