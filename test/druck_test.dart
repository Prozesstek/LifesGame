import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/main.dart';
import 'package:lifes_game/ui/druck.dart';

/// Wie weit das [AnimatedScale] über [text] gerade eingestellt ist.
double _skala(WidgetTester tester, String text) {
  return tester
      .widget<AnimatedScale>(
        find
            .ancestor(of: find.text(text), matching: find.byType(AnimatedScale))
            .first,
      )
      .scale;
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: LifesGameApp.theme(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

Widget _kachel(String text, {bool enabled = true}) {
  return Druck(
    enabled: enabled,
    child: SizedBox(width: 120, height: 60, child: Text(text)),
  );
}

void main() {
  group('Druck', () {
    testWidgets('sinkt beim Drücken ein und federt beim Loslassen zurück', (
      tester,
    ) async {
      await _pump(tester, _kachel('Knopf'));
      expect(_skala(tester, 'Knopf'), 1);

      final finger = await tester.startGesture(
        tester.getCenter(find.text('Knopf')),
      );
      await tester.pump();
      expect(_skala(tester, 'Knopf'), lessThan(1));

      await finger.up();
      await tester.pump();
      expect(_skala(tester, 'Knopf'), 1);
    });

    testWidgets('gesperrt gibt er nicht nach', (tester) async {
      await _pump(tester, _kachel('Zu', enabled: false));

      final finger = await tester.startGesture(
        tester.getCenter(find.text('Zu')),
      );
      await tester.pump();
      expect(_skala(tester, 'Zu'), 1);
      await finger.up();
    });

    testWidgets('wer scrollt, drückt nicht', (tester) async {
      await _pump(tester, _kachel('Weg'));

      final finger = await tester.startGesture(
        tester.getCenter(find.text('Weg')),
      );
      await tester.pump();
      await finger.moveBy(const Offset(0, kTouchSlop + 4));
      await tester.pump();
      expect(_skala(tester, 'Weg'), 1);
      await finger.up();
    });

    testWidgets('der Innerste gewinnt', (tester) async {
      await _pump(
        tester,
        Druck(
          child: SizedBox(
            width: 300,
            height: 120,
            child: Column(
              children: <Widget>[const Text('Karte'), _kachel('Innen')],
            ),
          ),
        ),
      );

      final finger = await tester.startGesture(
        tester.getCenter(find.text('Innen')),
      );
      await tester.pump();
      expect(_skala(tester, 'Innen'), lessThan(1));
      expect(_skala(tester, 'Karte'), 1, reason: 'die Karte bleibt stehen');
      await finger.up();
    });

    test('kleine Knöpfe sinken tiefer als breite Kacheln', () {
      final knopf = Druck.skalaFuer(const Size(48, 48));
      final kachel = Druck.skalaFuer(const Size(360, 70));
      expect(knopf, lessThan(kachel));
      expect(knopf, greaterThanOrEqualTo(Druck.tiefsteSkala));
      expect(kachel, lessThanOrEqualTo(Druck.flachsteSkala));
    });
  });

  group('Die Knöpfe aus dem Theme', () {
    for (final (name, bauen) in <(String, Widget Function(Widget))>[
      ('Holzplanke', (c) => FilledButton(onPressed: () {}, child: c)),
      ('TextButton', (c) => TextButton(onPressed: () {}, child: c)),
      ('OutlinedButton', (c) => OutlinedButton(onPressed: () {}, child: c)),
    ]) {
      testWidgets('$name sinkt ein', (tester) async {
        await _pump(tester, bauen(const Text('Los')));

        final finger = await tester.startGesture(
          tester.getCenter(find.text('Los')),
        );
        await tester.pump();
        expect(_skala(tester, 'Los'), lessThan(1));
        await finger.up();
        await tester.pump(const Duration(seconds: 1));
      });
    }

    testWidgets('der Holzknopf sinkt ein', (tester) async {
      await _pump(
        tester,
        IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
      );

      final finger = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.add)),
      );
      await tester.pump();
      final skala = tester
          .widget<AnimatedScale>(
            find
                .ancestor(
                  of: find.byIcon(Icons.add),
                  matching: find.byType(AnimatedScale),
                )
                .first,
          )
          .scale;
      expect(skala, lessThan(1));
      await finger.up();
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
