import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/theory/widgets/tree_layout.dart';
import 'package:theory/theory.dart';

/// Die Anordnung ist reine Rechnung — und genau deshalb prüfbar, ohne
/// etwas zu zeichnen.
///
/// Was hier schiefgehen kann, sieht man auf einem Screenshot erst, wenn
/// man an die richtige Stelle scrollt: zwei Knoten übereinander, ein
/// Kind außerhalb der Fläche, ein Startknoten, der nicht unten sitzt.
///
/// **Die Richtung ist seit ADR-0026 umgekehrt.** Vorher lagen vier
/// Bänder untereinander auf einer verschiebbaren Fläche; jetzt sitzt ein
/// Startknoten unten und genau eine Ebene darüber.
void main() {
  // Ein Handy im Hochformat, abzüglich Kopfzeile und Elternleiste.
  const breite = 390.0;
  const hoehe = 560.0;

  TreeLayout um(String focusId) {
    return TreeLayout.of(theoryGraph, focusId, width: breite, minHeight: hoehe);
  }

  final koerper = um('koerper');

  group('Der Startknoten sitzt unten und mittig', () {
    test('auf halber Breite', () {
      expect(koerper[koerper.focusId]!.dx, breite / 2);
    });

    test('am unteren Rand, nicht in der Mitte', () {
      final y = koerper[koerper.focusId]!.dy;

      expect(y, koerper.size.height - TreeLayout.focusInsetBottom);
      expect(y, greaterThan(koerper.size.height * 0.7));
    });

    test('das gilt für jedes Gebiet', () {
      for (final rootId in theoryRootIds) {
        final layout = um(rootId);

        expect(layout[rootId]!.dx, breite / 2, reason: rootId);
        expect(
          layout[rootId]!.dy,
          layout.size.height - TreeLayout.focusInsetBottom,
          reason: rootId,
        );
      }
    });
  });

  group('Der Baum wächst nach oben', () {
    test('jedes Kind liegt über dem Startknoten', () {
      final start = koerper[koerper.focusId]!;

      for (final kind in theoryGraph.childrenOf('koerper')) {
        expect(koerper[kind.id]!.dy, lessThan(start.dy), reason: kind.id);
      }
    });

    test('die untere Reihe liegt näher am Startknoten als die obere', () {
      final start = koerper[koerper.focusId]!.dy;
      final unten = koerper[koerper.rows.first.first]!.dy;
      final oben = koerper[koerper.rows.last.first]!.dy;

      expect(start - unten, lessThan(start - oben));
    });

    test('zwischen Startknoten und erster Reihe ist Platz für den Knopf', () {
      final start = koerper[koerper.focusId]!.dy;

      for (final id in koerper.rows.first) {
        final luecke = start - koerper[id]!.dy;

        expect(
          luecke,
          greaterThanOrEqualTo(TreeLayout.actionBand - TreeLayout.arcLift),
          reason: id,
        );
      }
    });
  });

  group('Genau eine Ebene ist angeordnet', () {
    test('der Startknoten und seine Kinder, sonst nichts', () {
      final kinder = theoryGraph.childrenOf('koerper').map((n) => n.id);

      expect(koerper.positions.keys.toSet(), <String>{'koerper', ...kinder});
    });

    test('ein Enkel bekommt keinen Platz', () {
      expect(koerper['geist-motivation'], isNull);
    });

    test('jedes Kind steht in genau einer Reihe', () {
      final inReihen = koerper.rows.expand((r) => r).toList();

      expect(inReihen.toSet().length, inReihen.length);
      expect(inReihen.length, theoryGraph.childrenOf('koerper').length);
    });

    test('ein Blatt zieht nichts herein', () {
      // Ein Knoten ohne Kinder ordnet nur sich selbst an — er öffnet
      // direkt, statt eine leere Ebene zu zeigen (ADR-0026).
      final blatt = theoryGraph.nodes.firstWhere(
        (n) => theoryGraph.childrenOf(n.id).isEmpty,
      );
      final layout = um(blatt.id);

      expect(layout.rows, isEmpty);
      expect(layout.positions.keys, <String>[blatt.id]);
    });
  });

  group('Nichts liegt übereinander', () {
    test('kein Platz wird zweimal vergeben', () {
      for (final rootId in theoryRootIds) {
        final stellen = um(rootId).positions.values.toList();

        expect(stellen.toSet().length, stellen.length, reason: rootId);
      }
    });

    test('zwischen zwei Knoten liegt mindestens ein Durchmesser', () {
      for (final rootId in theoryRootIds) {
        final eintraege = um(rootId).positions.entries.toList();

        for (var i = 0; i < eintraege.length; i++) {
          for (var j = i + 1; j < eintraege.length; j++) {
            final abstand = (eintraege[i].value - eintraege[j].value).distance;

            expect(
              abstand,
              greaterThanOrEqualTo(TreeLayout.focusRadius * 2),
              reason: '${eintraege[i].key} und ${eintraege[j].key}',
            );
          }
        }
      }
    });
  });

  group('Alles liegt auf der Fläche', () {
    test('kein Knoten ragt seitlich heraus', () {
      for (final rootId in theoryRootIds) {
        final layout = um(rootId);

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
      }
    });

    test('kein Knoten liegt über oder unter dem Rand', () {
      for (final rootId in theoryRootIds) {
        final layout = um(rootId);

        for (final entry in layout.positions.entries) {
          expect(
            entry.value.dy - TreeLayout.focusRadius,
            greaterThanOrEqualTo(0),
            reason: entry.key,
          );
          expect(
            entry.value.dy + TreeLayout.focusRadius,
            lessThanOrEqualTo(layout.size.height),
            reason: entry.key,
          );
        }
      }
    });

    test('die Fläche ist nie kleiner als das Fenster', () {
      expect(koerper.size.width, breite);
      expect(koerper.size.height, greaterThanOrEqualTo(hoehe));
    });

    test('viele Kinder machen die Fläche höher, nicht enger', () {
      final flach = TreeLayout.of(
        theoryGraph,
        'koerper',
        width: breite,
        minHeight: 0,
      );

      expect(flach.rows.length, greaterThan(1));
      expect(flach.size.width, breite);
      expect(flach.size.height, greaterThan(TreeLayout.actionBand));
    });
  });

  group('Die Reihen', () {
    test('fünf Kinder passen auf einem Handy nicht in eine Reihe', () {
      expect(theoryGraph.childrenOf('koerper').length, 5);
      expect(koerper.rows.length, 2);
    });

    test('die untere Reihe ist die vollere', () {
      expect(
        koerper.rows.first.length,
        greaterThanOrEqualTo(koerper.rows.last.length),
      );
    });

    test('keine Reihe ist voller als erlaubt', () {
      for (final reihe in koerper.rows) {
        expect(reihe.length, lessThanOrEqualTo(TreeLayout.maxPerRow(breite)));
      }
    });

    test('auf einer breiteren Fläche passen mehr nebeneinander', () {
      final breit = TreeLayout.of(
        theoryGraph,
        'koerper',
        width: 900,
        minHeight: hoehe,
      );

      expect(TreeLayout.maxPerRow(900), greaterThan(TreeLayout.maxPerRow(390)));
      expect(breit.rows.length, 1);
    });
  });

  group('Der Bogen', () {
    test('die äußeren Kinder liegen näher am Startknoten', () {
      final stellen = <Offset>[
        for (final id in koerper.rows.first) koerper[id]!,
      ]..sort((a, b) => a.dx.compareTo(b.dx));

      final mitte = stellen[stellen.length ~/ 2];

      expect(stellen.first.dy, greaterThan(mitte.dy));
      expect(stellen.last.dy, greaterThan(mitte.dy));
    });
  });

  group('Ein verbindender Knoten steht in beiden Gebieten', () {
    test('Stress hängt an Körper und an Geist — und erscheint zweimal', () {
      // Der Beleg dafür, dass die Struktur ein Graph ist. Vorher war das
      // ein Sonderfall („nur einmal platzieren"); seit ein Gebiet einen
      // eigenen Bildschirm hat, ist es schlicht wahr.
      expect(um('koerper')['koerper-stress'], isNotNull);
      expect(um('geist')['koerper-stress'], isNotNull);
    });

    test('es ist derselbe Knoten, nicht zwei', () {
      final node = theoryGraph.nodeById('koerper-stress')!;

      expect(node.parentIds, containsAll(<String>['koerper', 'geist']));
    });
  });
}
