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

TheoryNode _node(String id, {List<String> parents = const <String>[]}) {
  return TheoryNode(
    id: id,
    lesson: _page(id),
    iconId: 'icon-$id',
    parentIds: parents,
  );
}

/// koerper ──> schlaf ──┐
///                       ├──> stress
/// geist ────────────────┘
final _graph = TheoryGraph(<TheoryNode>[
  _node('koerper'),
  _node('geist'),
  _node('schlaf', parents: <String>['koerper']),
  _node('stress', parents: <String>['schlaf', 'geist']),
]);

TheoryProgress _bestanden(Iterable<String> ids) {
  var progress = const TheoryProgress.empty();
  for (final id in ids) {
    progress = progress.submit(_graph.nodeById(id)!.lesson, <int?>[0]).progress;
  }
  return progress;
}

/// Der Anteil der Theorie am Skill eines Gebiets (ADR-0085).
void main() {
  group('TheoryProgress.xpInArea', () {
    test('zählt nur die Seiten unter der Wurzel, sie selbst eingeschlossen',
        () {
      final progress = _bestanden(<String>['koerper', 'schlaf']);
      final eine = TheoryRewards.xpFor(1, 1);

      expect(progress.xpInArea(_graph, 'koerper'), 2 * eine);
      expect(progress.xpInArea(_graph, 'geist'), 0);
    });

    test('eine Seite mit zwei Gebieten zählt in beiden — fürs Level einmal',
        () {
      final progress = _bestanden(<String>['stress']);
      final eine = TheoryRewards.xpFor(1, 1);

      expect(progress.xpInArea(_graph, 'koerper'), eine);
      expect(progress.xpInArea(_graph, 'geist'), eine);
      expect(progress.totalXp, eine);
    });

    test('ein unbekanntes Gebiet bringt nichts', () {
      final progress = _bestanden(<String>['koerper']);
      expect(
        progress.xpInArea(_graph, 'gibt-es-nicht-und-soll-es-nie-geben'),
        0,
      );
    });
  });

  group('ReviewLog.xpFor', () {
    test('zählt nur richtige Antworten zu Seiten des Gebiets', () {
      final log = ReviewLog(<int, ReviewAnswer>{
        1: const ReviewAnswer(
          day: 1,
          lessonId: 'schlaf',
          questionIndex: 0,
          correct: true,
        ),
        2: const ReviewAnswer(
          day: 2,
          lessonId: 'schlaf',
          questionIndex: 0,
          correct: false,
        ),
        3: const ReviewAnswer(
          day: 3,
          lessonId: 'geist',
          questionIndex: 0,
          correct: true,
        ),
      });

      expect(
        log.xpFor(<String>{'koerper', 'schlaf'}),
        TheoryRewards.xpForReview,
      );
      expect(log.xpFor(<String>{'geist'}), TheoryRewards.xpForReview);
      expect(log.xpFor(const <String>{}), 0);
    });
  });
}
