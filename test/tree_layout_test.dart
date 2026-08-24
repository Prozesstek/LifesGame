import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/theory/widgets/tree_layout.dart';
import 'package:theory/theory.dart';

/// Die Anordnung ist reine Rechnung — und genau deshalb prüfbar, ohne
/// etwas zu zeichnen.
///
/// Was hier schiefgehen kann, sieht man auf einem Screenshot erst, wenn
/// man an die richtige Stelle scrollt: zwei Knoten übereinander, ein
/// Kind außerhalb der Fläche, eine Wurzel ohne Position.
void main() {
  final layout = TreeLayout.of(theoryGraph, theoryRootIds);

  group('Jeder Knoten bekommt genau einen Platz', () {
    test('alle 24 sind angeordnet', () {
      expect(layout.positions.length, theoryGraph.nodeCount);
    });

    test('kein Knoten fehlt', () {
      for (final node in theoryGraph.nodes) {
        expect(layout[node.id], isNotNull, reason: node.id);
      }
    });

    test('ein verbindender Knoten hat trotzdem nur eine Stelle', () {
      // `koerper-stress` hängt an Körper und Geist. Zwei Positionen
      // hieße: eine der beiden Linien endet im Nichts.
      final verbindend = theoryGraph.nodes.where((n) => n.parentIds.length > 1);

      expect(verbindend, isNotEmpty);
      for (final node in verbindend) {
        expect(layout[node.id], isNotNull, reason: node.id);
      }
    });
  });

  group('Nichts liegt übereinander', () {
    test('keine zwei Knoten teilen sich einen Platz', () {
      final stellen = layout.positions.values.toList();

      expect(stellen.toSet().length, stellen.length);
    });

    test('zwischen zwei Knoten liegt mindestens ein Durchmesser', () {
      final eintraege = layout.positions.entries.toList();

      for (var i = 0; i < eintraege.length; i++) {
        for (var j = i + 1; j < eintraege.length; j++) {
          final abstand = (eintraege[i].value - eintraege[j].value).distance;

          expect(
            abstand,
            greaterThanOrEqualTo(TreeLayout.nodeRadius * 2),
            reason: '${eintraege[i].key} und ${eintraege[j].key}',
          );
        }
      }
    });
  });

  group('Alles liegt auf der Fläche', () {
    test('kein Knoten ragt seitlich heraus', () {
      for (final entry in layout.positions.entries) {
        expect(
          entry.value.dx - TreeLayout.nodeRadius,
          greaterThanOrEqualTo(0),
          reason: entry.key,
        );
        expect(
          entry.value.dx + TreeLayout.nodeRadius,
          lessThanOrEqualTo(layout.size.width),
          reason: entry.key,
        );
      }
    });

    test('kein Knoten liegt unter dem unteren Rand', () {
      for (final entry in layout.positions.entries) {
        expect(
          entry.value.dy,
          lessThanOrEqualTo(layout.size.height),
          reason: entry.key,
        );
      }
    });
  });

  group('Die Bänder stehen untereinander', () {
    test('jede Wurzel hat ein Band', () {
      expect(layout.bandTops.keys, theoryRootIds);
    });

    test('die Bänder folgen aufeinander', () {
      final oben = theoryRootIds.map((id) => layout.bandTops[id]!).toList();

      for (var i = 1; i < oben.length; i++) {
        expect(oben[i], greaterThan(oben[i - 1]));
      }
    });

    test('eine Wurzel steht über den Kindern ihres eigenen Bandes', () {
      for (final rootId in theoryRootIds) {
        final wurzel = layout[rootId]!;
        final bandOben = layout.bandTops[rootId]!;
        final bandUnten = bandOben + TreeLayout.bandHeight;

        for (final kind in theoryGraph.childrenOf(rootId)) {
          final stelle = layout[kind.id];
          if (stelle == null) continue;

          // Ein verbindender Knoten wird nur **einmal** platziert, im
          // Band seiner ersten Wurzel. Für die zweite Wurzel liegt er
          // außerhalb des eigenen Bandes — und darf dann auch darüber
          // stehen. Die Linie läuft dorthin nach oben, und genau das
          // soll man sehen.
          final imEigenenBand = stelle.dy >= bandOben && stelle.dy < bandUnten;
          if (!imEigenenBand) continue;

          expect(stelle.dy, greaterThan(wurzel.dy), reason: kind.id);
        }
      }
    });

    test('ein verbindender Knoten liegt im Band seiner ersten Wurzel', () {
      final stress = layout['koerper-stress']!;
      final koerperOben = layout.bandTops['koerper']!;
      final geistOben = layout.bandTops['geist']!;

      expect(stress.dy, greaterThanOrEqualTo(koerperOben));
      expect(
        stress.dy,
        lessThan(geistOben),
        reason: 'Sonst hätte er zwei Plätze oder stünde im falschen Band.',
      );
    });
  });

  group('Die Wurzel steht mittig', () {
    test('auf halber Breite', () {
      for (final rootId in theoryRootIds) {
        expect(layout[rootId]!.dx, TreeLayout.canvasWidth / 2);
      }
    });
  });

  group('Der Bogen', () {
    test('die äußeren Kinder liegen tiefer als das mittlere', () {
      final kinder = theoryGraph.childrenOf('koerper');
      final stellen = <Offset>[
        for (final k in kinder)
          if (layout[k.id] case final Offset o) o,
      ]..sort((a, b) => a.dx.compareTo(b.dx));

      final mitte = stellen[stellen.length ~/ 2];

      expect(stellen.first.dy, greaterThan(mitte.dy));
      expect(stellen.last.dy, greaterThan(mitte.dy));
    });
  });
}
