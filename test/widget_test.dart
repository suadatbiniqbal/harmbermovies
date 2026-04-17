import 'package:flutter_test/flutter_test.dart';
import 'package:harmber_movies/main.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const HarmberApp());
    // Verify that the app renders
    expect(find.byType(HarmberApp), findsOneWidget);
  });
}
