import 'package:flutter_test/flutter_test.dart';
import 'package:voice_os/app.dart';

void main() {
  testWidgets('VoiceOS app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VoiceOSApp());

    // Verify the app loads with VoiceOS title
    expect(find.text('VoiceOS'), findsWidgets);
    expect(find.text('Ready'), findsOneWidget);
  });
}
