import 'package:test/test.dart';
import 'package:theory/theory.dart';

/// Eine Seite mit drei Fragen — der Inhalt ist hier egal, geprüft wird die
/// Struktur. Inhaltliche Prüfungen stehen in `content_test.dart`.
Lesson _page(String id) {
  return Lesson(
    id: id,
    title: 'Titel $id',
    summary: 'Worum es geht.',
    sections: const <LessonSection>[
      LessonSection(heading: 'Abschnitt', body: 'Text.'),
    ],
    questions: const <Question>[
      Question(
        prompt: 'Frage?',
        options: <String>['a', 'b'],
        correctIndex: 0,
        explanation: 'Weil.',
      ),
    ],
  );
}

TheoryNode _node(
  String id, {
  List<String> parents = const <String>[],
  int cost = 1,
  String? ability,
}) {
  return TheoryNode(
    id: id,
    lesson: _page(id),
    iconId: 'icon-$id',
    parentIds: parents,
    cost: cost,
    unlocksAbility: ability,
  );
}

void main() {
  group('Ein Knoten', () {
    test('ohne Eltern ist eine Wurzel', () {
      expect(_node('koerper').isRoot, isTrue);
      expect(_node('schlaf', parents: <String>['koerper']).isRoot, isFalse);
    });

    test('kostet standardmäßig einen Theoriepunkt', () {
      expect(_node('schlaf').cost, 1);
    });

    test('kann kostenlos sein — das Handbuch (ADR-0019)', () {
      final free = _node('habits-01', cost: 0);

      expect(free.isFree, isTrue);
      expect(_node('schlaf').isFree, isFalse);
    });

    test('trägt seinen Namen über die Lektion, nicht doppelt', () {
      expect(_node('schlaf').name, 'Titel schlaf');
    });
  });

  group('Der Graph', () {
    // koerper ──> schlaf ──┐
    //                      ├──> ernaehrung   (zwei Eltern, ADR-0019 Punkt 5)
    // wissenschaft ────────┘
    final graph = TheoryGraph(<TheoryNode>[
      _node('koerper'),
      _node('wissenschaft'),
      _node('schlaf', parents: <String>['koerper']),
      _node('ernaehrung', parents: <String>['schlaf', 'wissenschaft']),
    ]);

    test('kennt seine Wurzeln', () {
      expect(graph.roots.map((n) => n.id), <String>['koerper', 'wissenschaft']);
    });

    test('findet Kinder und Eltern', () {
      expect(graph.childrenOf('koerper').map((n) => n.id), <String>['schlaf']);
      expect(
        graph.parentsOf('ernaehrung').map((n) => n.id),
        <String>['schlaf', 'wissenschaft'],
      );
    });

    test('zählt seine Knoten', () {
      expect(graph.nodeCount, 4);
    });

    test('findet einen Knoten über seine Id, sonst null', () {
      expect(graph.nodeById('schlaf')?.id, 'schlaf');
      expect(graph.nodeById('gibtesnicht'), isNull);
    });
  });

  group('Öffnen', () {
    final graph = TheoryGraph(<TheoryNode>[
      _node('koerper'),
      _node('wissenschaft'),
      _node('schlaf', parents: <String>['koerper']),
      _node('ernaehrung', parents: <String>['schlaf', 'wissenschaft']),
    ]);

    test('eine Wurzel ist immer öffenbar', () {
      expect(graph.canOpen('koerper', const <String>{}), isTrue);
    });

    test('ein Kind braucht seinen Elternknoten', () {
      expect(graph.canOpen('schlaf', const <String>{}), isFalse);
      expect(graph.canOpen('schlaf', const <String>{'koerper'}), isTrue);
    });

    test('bei zwei Eltern genügt einer (ADR-0019)', () {
      final ueberKoerper =
          graph.canOpen('ernaehrung', const <String>{'schlaf'});
      final ueberWissen = graph.canOpen(
        'ernaehrung',
        const <String>{'wissenschaft'},
      );
      final nurGrossvater = graph.canOpen(
        'ernaehrung',
        const <String>{'koerper'},
      );

      expect(
        ueberKoerper,
        isTrue,
        reason: 'Beide zu verlangen baut eine unsichtbare Reihenfolge quer '
            'durch zwei Wurzeln.',
      );
      expect(ueberWissen, isTrue);
      expect(nurGrossvater, isFalse, reason: 'Ein Großelternteil zählt nicht.');
    });

    test('ein unbekannter Knoten ist nie öffenbar', () {
      expect(graph.canOpen('gibtesnicht', const <String>{'koerper'}), isFalse);
    });
  });

  group('Der Graph muss gesund sein', () {
    test('Ids sind eindeutig', () {
      final doppelt = TheoryGraph(<TheoryNode>[
        _node('koerper'),
        _node('koerper'),
      ]);

      expect(doppelt.duplicateIds, <String>['koerper']);
      expect(doppelt.isHealthy, isFalse);
    });

    test('jede Eltern-Id zeigt auf einen vorhandenen Knoten', () {
      final insLeere = TheoryGraph(<TheoryNode>[
        _node('schlaf', parents: <String>['gibtesnicht']),
      ]);

      expect(insLeere.danglingParentIds, <String>['gibtesnicht']);
      expect(insLeere.isHealthy, isFalse);
    });

    test('der Graph ist kreisfrei — sonst hängt der Baum', () {
      final kreis = TheoryGraph(<TheoryNode>[
        _node('a', parents: <String>['c']),
        _node('b', parents: <String>['a']),
        _node('c', parents: <String>['b']),
      ]);

      expect(kreis.isAcyclic, isFalse);
      expect(kreis.isHealthy, isFalse);
    });

    test('ein Graph ohne Wurzel ist krank, auch ohne Kreis im Test', () {
      // Jeder Knoten hat einen Elternknoten -> es gibt keinen Einstieg.
      final ohneWurzel = TheoryGraph(<TheoryNode>[
        _node('a', parents: <String>['b']),
        _node('b', parents: <String>['a']),
      ]);

      expect(ohneWurzel.roots, isEmpty);
      expect(ohneWurzel.isHealthy, isFalse);
    });

    test('ein gesunder Graph meldet keine Befunde', () {
      final gesund = TheoryGraph(<TheoryNode>[
        _node('koerper'),
        _node('schlaf', parents: <String>['koerper']),
      ]);

      expect(gesund.duplicateIds, isEmpty);
      expect(gesund.danglingParentIds, isEmpty);
      expect(gesund.isAcyclic, isTrue);
      expect(gesund.isHealthy, isTrue);
    });
  });
}
