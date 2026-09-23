import 'lesson.dart';
import 'rewards.dart';

/// Eine beantwortete Rückfrage.
class ReviewAnswer {
  const ReviewAnswer({
    required this.day,
    required this.lessonId,
    required this.questionIndex,
    required this.correct,
  });

  /// Tage seit dem 1.1.1970 — dieses Package kennt keinen Kalender.
  final int day;
  final String lessonId;
  final int questionIndex;
  final bool correct;

  Map<String, Object?> toJson() => <String, Object?>{
        'day': day,
        'lesson': lessonId,
        'question': questionIndex,
        'correct': correct,
      };

  static ReviewAnswer? fromJson(Object? json) {
    if (json is! Map) return null;
    final day = json['day'];
    final lesson = json['lesson'];
    final question = json['question'];
    final correct = json['correct'];
    if (day is! int || lesson is! String || question is! int) return null;
    if (correct is! bool || question < 0) return null;
    return ReviewAnswer(
      day: day,
      lessonId: lesson,
      questionIndex: question,
      correct: correct,
    );
  }
}

/// Die Frage eines Tages.
class ReviewQuestion {
  const ReviewQuestion({required this.lesson, required this.questionIndex});

  final Lesson lesson;
  final int questionIndex;

  Question get question => lesson.questions[questionIndex];
}

/// **Die Rückfrage des Tages** (ADR-0045, `docs/vorlagen/lernen.md`).
///
/// Eine Frage am Tag aus einer bestandenen Lektion. Richtig beantwortet,
/// kommt die Lektion erst nach wachsenden Abständen wieder
/// ([TheoryRewards.reviewIntervals]); falsch, schon morgen.
///
/// **Eine Historie, kein Stand** — dieselbe Bauform wie die Häkchen.
/// Welche Lektion fällig ist und was die Rückfragen eingebracht haben,
/// wird aus den Antworten gerechnet (ADR-0008).
class ReviewLog {
  ReviewLog(Map<int, ReviewAnswer> answers)
      : _answers = Map<int, ReviewAnswer>.unmodifiable(answers);

  const ReviewLog.empty() : _answers = const <int, ReviewAnswer>{};

  factory ReviewLog.fromJson(Map<String, Object?> json) {
    final antworten = <int, ReviewAnswer>{};
    final roh = json['answers'];
    if (roh is List) {
      for (final eintrag in roh) {
        final antwort = ReviewAnswer.fromJson(eintrag);
        if (antwort != null) antworten[antwort.day] = antwort;
      }
    }
    return ReviewLog(antworten);
  }

  /// Je Tag höchstens eine Antwort.
  final Map<int, ReviewAnswer> _answers;

  Map<String, Object?> toJson() => <String, Object?>{
        'answers': <Object?>[
          for (final tag in _answers.keys.toList()..sort())
            _answers[tag]!.toJson(),
        ],
      };

  bool get isEmpty => _answers.isEmpty;

  ReviewAnswer? answerOn(int day) => _answers[day];

  /// Wie oft die Rückfrage richtig beantwortet wurde.
  int get correctCount => _answers.values.where((a) => a.correct).length;

  int get totalXp => correctCount * TheoryRewards.xpForReview;

  int get totalGold => correctCount * TheoryRewards.goldForReview;

  /// Die Antworten zu [lessonId], die jüngste zuerst.
  List<ReviewAnswer> _zu(String lessonId) {
    return _answers.values.where((a) => a.lessonId == lessonId).toList()
      ..sort((x, y) => y.day.compareTo(x.day));
  }

  /// An welchem Tag [lessonId] wieder dran ist — null, wenn sie noch nie
  /// gefragt wurde. Dann ist sie sofort fällig.
  int? dueDayOf(String lessonId) {
    final antworten = _zu(lessonId);
    if (antworten.isEmpty) return null;
    final letzte = antworten.first;
    const abstaende = TheoryRewards.reviewIntervals;
    if (!letzte.correct) return letzte.day + abstaende.first;

    var folge = 0;
    for (final a in antworten) {
      if (!a.correct) break;
      folge++;
    }
    final i = folge > abstaende.length ? abstaende.length - 1 : folge - 1;
    return letzte.day + abstaende[i];
  }

  /// Die Frage von [day], aus den bestandenen Lektionen [passed] — oder
  /// null, wenn heute nichts fällig ist.
  ///
  /// Ist heute schon geantwortet, ist es **diese** Frage, auch wenn
  /// inzwischen eine andere Lektion dazugekommen ist. Sonst die, die am
  /// längsten fällig ist; eine nie gefragte vor allen. Gleichstand
  /// entscheidet der Tag, damit nicht jeden Tag dieselbe vorne steht.
  ReviewQuestion? questionFor(int day, List<Lesson> passed) {
    final beantwortet = _answers[day];
    if (beantwortet != null) {
      for (final lesson in passed) {
        if (lesson.id == beantwortet.lessonId &&
            beantwortet.questionIndex < lesson.questions.length) {
          return ReviewQuestion(
            lesson: lesson,
            questionIndex: beantwortet.questionIndex,
          );
        }
      }
      return null;
    }

    int faellig(Lesson l) => dueDayOf(l.id) ?? -1;
    final kandidaten = <Lesson>[
      for (final l in passed)
        if (l.questions.isNotEmpty && faellig(l) <= day) l,
    ];
    if (kandidaten.isEmpty) return null;

    final frueheste = kandidaten.map(faellig).reduce((x, y) => x < y ? x : y);
    final vorne = <Lesson>[
      for (final l in kandidaten)
        if (faellig(l) == frueheste) l,
    ];
    final lesson = vorne[day % vorne.length];
    final schon = _zu(lesson.id).length;
    return ReviewQuestion(
      lesson: lesson,
      questionIndex: (schon + day) % lesson.questions.length,
    );
  }

  /// Beantwortet die Frage von [day] mit [choice]. Null, wenn heute schon
  /// geantwortet wurde.
  ({ReviewLog log, bool correct})? answer(
    int day,
    ReviewQuestion question,
    int choice,
  ) {
    if (_answers.containsKey(day)) return null;
    final korrekt = choice == question.question.correctIndex;
    return (
      log: ReviewLog(<int, ReviewAnswer>{
        ..._answers,
        day: ReviewAnswer(
          day: day,
          lessonId: question.lesson.id,
          questionIndex: question.questionIndex,
          correct: korrekt,
        ),
      }),
      correct: korrekt,
    );
  }
}
