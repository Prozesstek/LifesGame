import 'package:test/test.dart';
import 'package:theory/theory.dart';

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
}) {
  return TheoryNode(
    id: id,
    lesson: _page(id),
    iconId: 'icon-$id',
    parentIds: parents,
    cost: cost,
  );
}

/// koerper (frei) ──> schlaf ──> tiefschlaf
final _graph = TheoryGraph(<TheoryNode>[
  _node('koerper', cost: 0),
  _node('schlaf', parents: <String>['koerper']),
  _node('tiefschlaf', parents: <String>['schlaf']),
]);

void main() {
  group('Ein kostenloser Knoten', () {
    test('ist von selbst offen — er kostet keinen Klick', () {
      const leer = TheoryProgress.empty();

      expect(leer.isNodeOpened('koerper', _graph), isTrue);
    });

    test('taucht nicht im Spielstand auf', () {
      const leer = TheoryProgress.empty();

      expect(leer.openedNodeIds, isEmpty);
    });
  });

  group('Öffnen', () {
    test('ein bezahlter Knoten ist danach offen', () {
      final nachher = const TheoryProgress.empty().openNode('schlaf');

      expect(nachher.isNodeOpened('schlaf', _graph), isTrue);
      expect(nachher.openedNodeIds, <String>{'schlaf'});
    });

    test('lässt den alten Fortschritt unberührt', () {
      const vorher = TheoryProgress.empty();

      vorher.openNode('schlaf');

      expect(vorher.openedNodeIds, isEmpty);
    });

    test('zweimal öffnen kostet nicht zweimal', () {
      final zweimal =
          const TheoryProgress.empty().openNode('schlaf').openNode('schlaf');

      expect(zweimal.spentPointsIn(_graph), 1);
    });

    test('ein unbekannter Knoten ist nie offen', () {
      const leer = TheoryProgress.empty();

      expect(leer.isNodeOpened('gibtesnicht', _graph), isFalse);
    });
  });

  group('Ausgegebene Punkte werden abgeleitet, nicht gezählt', () {
    test('leerer Fortschritt hat nichts ausgegeben', () {
      expect(const TheoryProgress.empty().spentPointsIn(_graph), 0);
    });

    test('die Summe der Kosten der geöffneten Knoten', () {
      final zwei = const TheoryProgress.empty()
          .openNode('schlaf')
          .openNode('tiefschlaf');

      expect(zwei.spentPointsIn(_graph), 2);
    });

    test('ein Knoten, den es nicht mehr gibt, kostet nichts mehr', () {
      // Gleiche Nachsicht wie bei den Lektionen (ADR-0010): Wer einen
      // Knoten aus dem Baum nimmt, gibt den Punkt zurück, statt den
      // Spielstand unlesbar zu machen.
      final mitLeiche = const TheoryProgress.empty().openNode('entfernt');

      expect(mitLeiche.spentPointsIn(_graph), 0);
    });
  });

  group('Speichern und laden', () {
    test('geöffnete Knoten überleben eine Runde durch JSON', () {
      final vorher = const TheoryProgress.empty()
          .openNode('schlaf')
          .openNode('tiefschlaf');

      final nachher = TheoryProgress.fromJson(vorher.toJson());

      expect(nachher.openedNodeIds, <String>{'schlaf', 'tiefschlaf'});
    });

    test('ein alter Spielstand ohne Knoten liest sich trotzdem', () {
      final alt = TheoryProgress.fromJson(<String, Object?>{
        'records': <String, Object?>{},
      });

      expect(alt.openedNodeIds, isEmpty);
    });

    test('Unbrauchbares wird übersprungen, nicht geworfen', () {
      final kaputt = TheoryProgress.fromJson(<String, Object?>{
        'openedNodes': <Object?>['schlaf', 42, null],
      });

      expect(kaputt.openedNodeIds, <String>{'schlaf'});
    });

    test('Lektionsfortschritt und Knoten stören sich nicht', () {
      final beides = const TheoryProgress.empty().openNode('schlaf');
      final gelesen = TheoryProgress.fromJson(beides.toJson());

      expect(gelesen.openedNodeIds, <String>{'schlaf'});
      expect(gelesen.isPassed('schlaf'), isFalse);
    });
  });

  group('Öffnen mit Punkten und Struktur', () {
    test('kostenlose Knoten zählen zur offenen Menge', () {
      const leer = TheoryProgress.empty();

      expect(leer.openIdsIn(_graph), <String>{'koerper'});
    });

    test('ein Kind einer freien Wurzel ist mit einem Punkt zu haben', () {
      const leer = TheoryProgress.empty();

      expect(
        leer.canOpenNode('schlaf', _graph, availablePoints: 1),
        isTrue,
      );
    });

    test('ohne Punkt geht nichts', () {
      const leer = TheoryProgress.empty();

      expect(
        leer.canOpenNode('schlaf', _graph, availablePoints: 0),
        isFalse,
      );
    });

    test('der Enkel braucht erst den Elternknoten', () {
      const leer = TheoryProgress.empty();
      final mitSchlaf = leer.openNode('schlaf');

      expect(
        leer.canOpenNode('tiefschlaf', _graph, availablePoints: 9),
        isFalse,
      );
      expect(
        mitSchlaf.canOpenNode('tiefschlaf', _graph, availablePoints: 9),
        isTrue,
      );
    });

    test('was schon offen ist, lässt sich nicht noch einmal kaufen', () {
      final mitSchlaf = const TheoryProgress.empty().openNode('schlaf');

      expect(
        mitSchlaf.canOpenNode('schlaf', _graph, availablePoints: 9),
        isFalse,
      );
    });

    test('eine kostenlose Wurzel gilt nie als kaufbar', () {
      const leer = TheoryProgress.empty();

      expect(
        leer.canOpenNode('koerper', _graph, availablePoints: 9),
        isFalse,
      );
    });
  });
}
