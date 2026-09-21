import 'package:flutter_test/flutter_test.dart';
import 'package:buddy_app/main.dart';
import 'package:buddy_app/core/constants/app_strings.dart';

void main() {
  testWidgets('BuddyApp smoke test renders SplashScreen correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const BuddyApp());

    // Verify brand name and tagline
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.tagline), findsOneWidget);
    expect(find.text(AppStrings.slideToGetStarted), findsOneWidget);
  });
}
