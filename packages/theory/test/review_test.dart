import 'package:test/test.dart';
import 'package:theory/theory.dart';

/// Die Rückfrage des Tages (ADR-0045): eine Frage aus einer bestandenen
/// Lektion, in wachsenden Abständen wieder.
void main() {
  const tag = 20000;
  final a = habitsBranch.lessons[0];
  final b = habitsBranch.lessons[1];

  int richtig(ReviewQuestion q) => q.question.correctIndex;
  int falsch(ReviewQuestion q) => (q.question.correctIndex + 1) % 4;

  /// Beantwortet die heutige Frage und gibt das neue Log zurück.
  ReviewLog antworte(
    ReviewLog log,
    int tag,
    List<Lesson> bestanden, {
    required bool korrekt,
  }) {
    final frage = log.questionFor(tag, bestanden)!;
    return log
        .answer(tag, frage, korrekt ? richtig(frage) : falsch(frage))!
        .log;
  }

  group('Welche Frage', () {
    test('ohne bestandene Lektion gibt es keine', () {
      const leer = ReviewLog.empty();
      expect(leer.questionFor(tag, const <Lesson>[]), isNull);
    });

    test('sie kommt aus einer bestandenen Lektion', () {
      final frage = const ReviewLog.empty().questionFor(tag, <Lesson>[a]);
      expect(frage, isNotNull);
      expect(frage!.lesson.id, a.id);
      expect(a.questions, contains(frage.question));
    });

    test('derselbe Tag, dieselbe Frage', () {
      const log = ReviewLog.empty();
      final eins = log.questionFor(tag, <Lesson>[a, b])!;
      final zwei = log.questionFor(tag, <Lesson>[a, b])!;
      expect(zwei.lesson.id, eins.lesson.id);
      expect(zwei.questionIndex, eins.questionIndex);
    });

    test('nach der Antwort bleibt die Frage des Tages stehen', () {
      final log =
          antworte(const ReviewLog.empty(), tag, <Lesson>[a], korrekt: true);
      final frage = log.questionFor(tag, <Lesson>[a, b])!;
      expect(frage.lesson.id, a.id, reason: 'b kam erst danach dazu');
      expect(log.answerOn(tag)!.correct, isTrue);
    });
  });

  group('Die Abstände', () {
    test('richtig: 1, 3, 7, dann 21 Tage', () {
      var log = const ReviewLog.empty();
      final nur = <Lesson>[a];
      var heute = tag;
      final abstaende = <int>[];
      for (var i = 0; i < 5; i++) {
        log = antworte(log, heute, nur, korrekt: true);
        final faellig = log.dueDayOf(a.id)!;
        abstaende.add(faellig - heute);
        heute = faellig;
      }
      expect(abstaende, <int>[1, 3, 7, 21, 21]);
    });

    test('dazwischen ist nichts fällig', () {
      final log =
          antworte(const ReviewLog.empty(), tag, <Lesson>[a], korrekt: true);
      // Am nächsten Tag ist a fällig (ein Tag), danach drei Tage Ruhe.
      final zweiter = antworte(log, tag + 1, <Lesson>[a], korrekt: true);
      expect(zweiter.questionFor(tag + 2, <Lesson>[a]), isNull);
      expect(zweiter.questionFor(tag + 4, <Lesson>[a]), isNotNull);
    });

    test('falsch: morgen wieder, und die Reihe beginnt von vorn', () {
      var log = const ReviewLog.empty();
      log = antworte(log, tag, <Lesson>[a], korrekt: true);
      log = antworte(log, tag + 1, <Lesson>[a], korrekt: true);
      log = antworte(log, tag + 4, <Lesson>[a], korrekt: false);

      expect(log.dueDayOf(a.id), tag + 5);
      log = antworte(log, tag + 5, <Lesson>[a], korrekt: true);
      expect(log.dueDayOf(a.id), tag + 6, reason: 'wieder ein Tag');
    });

    test('die am längsten fällige kommt zuerst, nie gefragte vor allen', () {
      var log = const ReviewLog.empty();
      log = antworte(log, tag, <Lesson>[a], korrekt: true);
      // a ist morgen fällig, b noch nie gefragt worden.
      final frage = log.questionFor(tag + 1, <Lesson>[a, b])!;
      expect(frage.lesson.id, b.id);
    });
  });

  group('Was sie einbringt', () {
    test('richtig: Erfahrung und Gold, falsch: nichts', () {
      var log = const ReviewLog.empty();
      log = antworte(log, tag, <Lesson>[a], korrekt: true);
      log = antworte(log, tag + 1, <Lesson>[a], korrekt: false);

      expect(log.totalXp, TheoryRewards.xpForReview);
      expect(log.totalGold, TheoryRewards.goldForReview);
    });

    test('einmal je Tag', () {
      final log =
          antworte(const ReviewLog.empty(), tag, <Lesson>[a], korrekt: true);
      final frage = log.questionFor(tag, <Lesson>[a])!;
      expect(log.answer(tag, frage, richtig(frage)), isNull);
    });
  });

  group('Speichern', () {
    test('überlebt den Neustart', () {
      final log =
          antworte(const ReviewLog.empty(), tag, <Lesson>[a], korrekt: true);
      final gelesen = ReviewLog.fromJson(log.toJson());
      expect(gelesen.answerOn(tag)!.lessonId, a.id);
      expect(gelesen.totalXp, log.totalXp);
    });

    test('Unlesbares wird übersprungen, nicht geworfen', () {
      final gelesen = ReviewLog.fromJson(<String, Object?>{
        'answers': <Object?>[
          'quatsch',
          <String, Object?>{'day': 'x'},
          <String, Object?>{
            'day': tag,
            'lesson': a.id,
            'question': 0,
            'correct': true,
          },
        ],
      });
      expect(gelesen.answerOn(tag), isNotNull);
      expect(gelesen.totalXp, TheoryRewards.xpForReview);
    });
  });
}
