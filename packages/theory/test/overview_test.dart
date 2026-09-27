import 'package:theory/theory.dart';
import 'package:test/test.dart';

/// Der Überblick im Wissensbaum ([ADR-0056](../../../docs/decisions/0056-ueberblick-im-wissensbaum.md)):
/// wie viel unter einem Knoten geschafft ist, und was als Nächstes dran
/// ist.
void main() {
  TheoryProgress bestehe(TheoryProgress p, String id) {
    final node = theoryGraph.nodeById(id)!;
    return p.openNode(id).submit(node.lesson, <int?>[
      for (final q in node.lesson.questions) q.correctIndex,
    ]).progress;
  }

  group('Fortschritt unter einem Knoten', () {
    test('zählt die Themen darunter, nicht die eigene Einführung', () {
      final kinder = theoryGraph.childrenOf('kraft-muskulatur');
      var p = bestehe(const TheoryProgress.empty(), 'koerper');
      p = bestehe(p, 'kraft-muskulatur');
      p = bestehe(p, kinder.first.id);

      final stand = p.progressBelow('kraft-muskulatur', theoryGraph);

      expect(stand.passed, 1);
      expect(stand.total, kinder.length);
    });

    test('mit includeSelf zählt der Knoten selbst mit', () {
      final p = bestehe(const TheoryProgress.empty(), 'koerper');

      final stand = p.progressBelow('koerper', theoryGraph, includeSelf: true);

      expect(stand.passed, 1);
      expect(
        stand.total,
        theoryGraph.descendantsOf('koerper', includeSelf: true).length,
      );
    });

    test('ein Thema ohne Kinder hat nichts darunter', () {
      final blatt = theoryGraph.nodes.firstWhere(
        (n) => theoryGraph.childrenOf(n.id).isEmpty,
      );

      final stand = const TheoryProgress.empty().progressBelow(
        blatt.id,
        theoryGraph,
      );

      expect(stand.total, 0);
    });

    test('Ankündigungen zählen nicht mit', () {
      // Unter „Körper“ stehen angekündigte Überschriften; sie haben keine
      // Seite und dürfen „6 / 20“ nicht zu „6 / 22“ machen.
      final angekuendigt = theoryGraph.placeholdersOf('koerper');
      expect(angekuendigt, isNotEmpty);

      final stand = const TheoryProgress.empty().progressBelow(
        'koerper',
        theoryGraph,
      );

      expect(
        stand.total,
        theoryGraph.descendantsOf('koerper').length,
      );
    });
  });

  group('Was als Nächstes dran ist', () {
    test('ohne Offenes nichts', () {
      expect(const TheoryProgress.empty().nextToRead(theoryGraph), isNull);
    });

    test('geöffnet und nicht gelesen ist dran', () {
      final p = const TheoryProgress.empty().openNode('koerper');

      expect(p.nextToRead(theoryGraph)?.id, 'koerper');
    });

    test('gelesen ist nicht mehr dran', () {
      final p = bestehe(const TheoryProgress.empty(), 'koerper');

      expect(p.nextToRead(theoryGraph), isNull);
    });

    test('mit under nur in diesem Teil des Baums', () {
      final p =
          const TheoryProgress.empty().openNode('koerper').openNode('geist');

      expect(p.nextToRead(theoryGraph, under: 'geist')?.id, 'geist');
      expect(p.nextToRead(theoryGraph, under: 'koerper')?.id, 'koerper');
    });

    test('die Einführung kommt vor ihren Themen', () {
      final thema = theoryGraph.childrenOf('kraft-muskulatur').first;
      var p = bestehe(const TheoryProgress.empty(), 'koerper');
      p = p.openNode('kraft-muskulatur').openNode(thema.id);

      expect(p.nextToRead(theoryGraph)?.id, 'kraft-muskulatur');
    });
  });
}
