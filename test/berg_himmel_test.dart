import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/home/widgets/berg_himmel.dart';

void main() {
  group('Tageslicht', () {
    test('mittags liegt kein Schleier über dem Berg, nachts stehen Sterne', () {
      final mittag = Tageslicht.um(12);
      final nacht = Tageslicht.um(23.5);

      expect(mittag.oben.a, 0);
      expect(mittag.nacht, 0);
      expect(nacht.nacht, 1);
      expect(nacht.oben.a, greaterThan(0.5));
    });

    test('zwischen zwei Stützstellen wird gemischt, ohne Sprung', () {
      var davor = Tageslicht.um(0).nacht;
      for (var h = 0.0; h <= 24; h += 0.25) {
        final jetzt = Tageslicht.um(h).nacht;
        expect((jetzt - davor).abs(), lessThan(0.2), reason: 'um $h Uhr');
        davor = jetzt;
      }
    });

    test('Mitternacht ist auf beiden Seiten dieselbe Nacht', () {
      expect(Tageslicht.um(0).oben, Tageslicht.um(24).oben);
    });
  });

  testWidgets('der Himmel malt zu jeder Stunde und steht in Tests still', (
    tester,
  ) async {
    addTearDown(() => BergHimmel.uhr = DateTime.now);
    for (final stunde in <int>[3, 7, 12, 19, 23]) {
      BergHimmel.uhr = () => DateTime(2026, 11, 16, stunde);
      await tester.pumpWidget(
        MaterialApp(
          home: BergHimmel(key: ValueKey<int>(stunde), child: const Text('x')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('x'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
