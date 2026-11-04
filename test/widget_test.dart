import 'package:convena/components/components.dart';
import 'package:convena/models/user.dart';
import 'package:convena/pages/home_page.dart';
import 'package:convena/services/auth_service.dart';
import 'package:convena/services/theme_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ConvenaTopBar renders brand title and notification button', (
    WidgetTester tester,
  ) async {
    bool notificationTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: ConvenaTopBar(
            onNotificationTap: () {
              notificationTapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Convena'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    expect(notificationTapped, isTrue);
  });

  testWidgets('ConvenaTopBar.withBack renders back button and label', (
    WidgetTester tester,
  ) async {
    bool backTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: ConvenaTopBar.withBack(
            label: 'Dashboard',
            onBackPressed: () {
              backTapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    expect(backTapped, isTrue);
  });

  testWidgets('ConvenaBottomNavBar renders 4 tabs and handles tap', (
    WidgetTester tester,
  ) async {
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              bottomNavigationBar: ConvenaBottomNavBar(
                currentIndex: selectedIndex,
                onTap: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
              ),
            );
          },
        ),
      ),
    );

    // Verify all 4 default navigation icons exist
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

    // Tap on Search tab (index 2)
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pump();

    expect(selectedIndex, 2);
  });

  testWidgets('Long email address does not cause RenderFlex overflow in profile', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    const testUser = User(
      id: '1',
      name: 'Evangelion',
      displayName: 'Evangelion Unit 01',
      username: 'evangelion',
      email:
          'very.long.super.extended.user.email.address.that.exceeds.screen.width@company-domain.corp.internal.example.com',
      role: 'admin',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService(prefs)),
          ChangeNotifierProvider(create: (_) => AuthService(prefs)),
        ],
        child: const MaterialApp(
          home: HomePage(user: testUser),
        ),
      ),
    );

    // Switch to profile tab (index 3)
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();

    // Verify no RenderFlex exception occurred and the email text is found
    expect(tester.takeException(), isNull);
    expect(find.text(testUser.email), findsOneWidget);
  });
}
