import 'package:convena/components/components.dart';
import 'package:convena/models/event.dart';
import 'package:convena/models/user.dart';
import 'package:convena/pages/home_page.dart';
import 'package:convena/pages/payment_page.dart';
import 'package:convena/services/auth_service.dart';
import 'package:convena/services/event_service.dart';
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

    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

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
          ChangeNotifierProvider(create: (_) => EventService()),
        ],
        child: const MaterialApp(
          home: HomePage(user: testUser),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(testUser.email), findsOneWidget);
  });

  testWidgets('Event and TicketTier model calculations work accurately', (
    WidgetTester tester,
  ) async {
    final event = Event(
      id: 'evt-test-1',
      createdBy: 'usr-1',
      title: 'Global Tech Innovators Summit 2026',
      slug: 'global-tech-summit-2026',
      category: 'conference',
      startDate: DateTime(2026, 11, 20, 9, 0),
      endDate: DateTime(2026, 11, 20, 17, 0),
      venueName: 'Telkom University Convention Hall',
      city: 'Bandung',
      company: 'Telkom University',
      createdAt: DateTime.now(),
      ticketTiers: const [
        TicketTier(
          id: 'tier-standard',
          name: 'Standard',
          price: 0.0,
          quota: 250,
          sold: 10,
        ),
        TicketTier(
          id: 'tier-vip',
          name: 'VIP All-Access + Workshop',
          price: 350000.0,
          quota: 50,
          sold: 5,
        ),
      ],
    );

    expect(event.isFree, isTrue);
    expect(event.formattedLowestPrice, 'GRATIS');
    expect(event.totalCapacity, 300);
    expect(event.attendeeCount, 15);
    expect(event.displayLocation, 'Telkom University Convention Hall, Bandung');
  });

  testWidgets('EventCard displays title, category tag, and lowest price', (
    WidgetTester tester,
  ) async {
    final event = Event(
      id: 'evt-gemastik',
      createdBy: 'usr-1',
      title: 'Gemastik 2.0',
      slug: 'gemastik-2-0',
      shortDescription: 'Hackathon Mahasiswa se-Indonesia',
      category: 'competition',
      startDate: DateTime(2026, 11, 20),
      endDate: DateTime(2026, 11, 23),
      venueName: 'Telkom University Convention Hall',
      city: 'Bandung',
      company: 'Telkom University',
      organizationName: 'HMRPL',
      createdAt: DateTime.now(),
      ticketTiers: const [
        TicketTier(id: 't1', name: 'Standard', price: 0.0, quota: 250),
        TicketTier(id: 't2', name: 'Gold', price: 50000.0, quota: 100),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventCard(event: event),
        ),
      ),
    );

    expect(find.text('Gemastik 2.0'), findsOneWidget);
    expect(find.text('COMPETITION'), findsOneWidget);
    expect(find.text('GRATIS'), findsOneWidget);
    expect(find.text('Detail Event'), findsOneWidget);
  });

  testWidgets('PaymentPage matches payment design with stepper, summary and QRIS', (
    WidgetTester tester,
  ) async {
    final event = Event(
      id: 'evt-test-payment',
      createdBy: 'usr-1',
      title: 'Global Tech Innovators Summit 2026 Tel-U',
      slug: 'global-tech-summit-tel-u',
      category: 'conference',
      startDate: DateTime(2026, 11, 20),
      endDate: DateTime(2026, 11, 20),
      venueName: 'Telkom University Convention Hall',
      createdAt: DateTime.now(),
    );

    const selectedTier = TicketTier(
      id: 'tier-vip',
      name: 'VIP All-Access + Workshop',
      price: 350000.0,
      quota: 50,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentPage(
          event: event,
          selectedTier: selectedTier,
        ),
      ),
    );

    // Verify Card 1 elements
    expect(find.text('Verified Ticket'), findsOneWidget);
    expect(find.text('VIP All-Access + Workshop'), findsOneWidget);

    // Verify Card 2 stepper
    expect(find.text('Ticket Quantity'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // Tap + to increment quantity to 2
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    // Verify Payment methods exist
    expect(find.text('QRIS'), findsOneWidget);
    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('E-Wallet'), findsOneWidget);

    // Verify Card 3 summary
    expect(find.text('ORDER PRICE SUMMARY'), findsOneWidget);
    expect(find.text('Gateway Fee & Service'), findsOneWidget);

    // Verify Card 4 QRIS scanner
    expect(find.text('Scan via GoPay, OVO, BCA, QRIS'), findsOneWidget);
    expect(find.text('Unduh'), findsOneWidget);
  });
}
