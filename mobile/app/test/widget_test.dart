import 'package:app/config/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('AI Diary smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('📔 AI Diary'), findsOneWidget);
    expect(find.text('Arrancando el DevFest Cali'), findsOneWidget);
  });
}
