import 'package:app/config/state/app_state.dart';
import 'package:app/ui/pages/diary_home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'AI Diary — DevFest Cali',
            debugShowCheckedModeBanner: false,
            theme: appState.appTheme,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(appState.fontSizeFactor),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const DiaryHomePage(),
          );
        },
      ),
    );
  }
}
