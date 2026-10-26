import 'package:flutter_test/flutter_test.dart';
import 'package:convena_app/main.dart';

void main() {
  testWidgets('EventMapScreen smoke test', (WidgetTester tester) async {
    // Build app dan trigger frame
    await tester.pumpWidget(const App());

    // Verifikasi teks header dan tombol utama tampil
    expect(find.text('ITB Ganesha, Bandung'), findsOneWidget);
    expect(find.text('Cari event atau lokasi'), findsOneWidget);
    expect(find.text('Near me'), findsOneWidget);
    expect(find.text('Lihat Event'), findsOneWidget);
  });
}
