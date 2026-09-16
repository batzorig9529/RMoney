import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rmoney_flutter/app/rmoney_app.dart';
import 'package:rmoney_flutter/models/models.dart';
import 'package:rmoney_flutter/screens/dashboard_page.dart';

void main() {
  for (final width in [320.0, 390.0, 1000.0]) {
    testWidgets('dashboard fits $width with large text and large amounts',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var added = false;
      await tester.pumpWidget(MaterialApp(
        theme: buildRMoneyTheme(Brightness.light),
        home: MediaQuery(
          data: MediaQueryData(
              size: Size(width, 900), textScaler: const TextScaler.linear(1.4)),
          child: Scaffold(
              body: DashboardPage(
            records: [
              MoneyRecord(
                  id: 'test',
                  type: MoneyType.income,
                  amount: 1234567890123,
                  date: DateTime.now())
            ],
            savingsPlan: const SavingsPlan(),
            onAdd: () => added = true,
          )),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Гүйлгээ нэмэх'));
      await tester.tap(find.text('Гүйлгээ нэмэх'));
      expect(added, isTrue);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
