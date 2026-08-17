import 'branch.dart';
import 'lesson.dart';
import 'rewards.dart';
import 'skill_tree.dart';

/// Was von einer abgeschlossenen Lektion übrig bleibt.
class LessonRecord {
  const LessonRecord({
    required this.bestCorrect,
    required this.questionCount,
    required this.xpAwarded,
    required this.goldAwarded,
  });

  /// Liest einen gespeicherten Eintrag. Null, wenn er unbrauchbar ist —
  /// eine einzelne kaputte Lektion darf nicht den ganzen Stand kosten.
  static LessonRecord? fromJson(Object? json) {
    if (json is! Map) return null;
    final bestCorrect = json['bestCorrect'];
    final questionCount = json['questionCount'];
    final xpAwarded = json['xpAwarded'];
    final goldAwarded = json['goldAwarded'];
    if (bestCorrect is! int ||
        questionCount is! int ||
        xpAwarded is! int ||
        goldAwarded is! int) {
      return null;
    }
    if (bestCorrect < 0 || questionCount < 0 || bestCorrect > questionCount) {
      return null;
    }
    return LessonRecord(
      bestCorrect: bestCorrect,
      questionCount: questionCount,
      xpAwarded: xpAwarded,
      goldAwarded: goldAwarded,
    );
  }

  /// Bestes Ergebnis, nicht das letzte. Ein schlechterer zweiter Versuch
  /// nimmt niemandem etwas weg.
  final int bestCorrect;

  final int questionCount;
  final int xpAwarded;
  final int goldAwarded;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'bestCorrect': bestCorrect,
      'questionCount': questionCount,
      'xpAwarded': xpAwarded,
      'goldAwarded': goldAwarded,
    };
  }

  bool get isPassed => TheoryRewards.passes(bestCorrect, questionCount);

  bool get isPerfect => questionCount > 0 && bestCorrect == questionCount;
}

/// Ergebnis eines Lektionsversuchs — inklusive des daraus folgenden
/// neuen Fortschritts.
class LessonResult {
  const LessonResult({
    required this.lessonId,
    required this.correct,
    required this.total,
    required this.xpGained,
    required this.goldGained,
    required this.isNewBest,
    required this.progress,
  });

  final String lessonId;
  final int correct;
  final int total;

  /// Was dieser Versuch eingebracht hat — 0, wenn die Lektion vorher schon
  /// mit gleichem oder besserem Ergebnis bestanden war.
  final int xpGained;
  final int goldGained;

  final bool isNewBest;

  /// Der Fortschritt nach diesem Versuch.
  final TheoryProgress progress;

  bool get isPassed => TheoryRewards.passes(correct, total);

  bool get isPerfect => total > 0 && correct == total;
}

/// Lernfortschritt über alle Lektionen hinweg.
///
/// Unveränderlich: [submit] gibt einen neuen Fortschritt zurück, statt
/// diesen zu verändern.
class TheoryProgress {
  const TheoryProgress(this._records);

  const TheoryProgress.empty() : _records = const <String, LessonRecord>{};

  /// Liest einen gespeicherten Fortschritt.
  ///
  /// Nachsichtig wie [HabitTracker.fromJson]: Lektions-Ids, die es nicht
  /// mehr gibt, werden übersprungen. Der Fortschritt bleibt trotzdem
  /// stimmig, weil Erfahrung und Gold je Lektion mitgespeichert sind —
  /// eine entfernte Lektion nimmt genau ihren eigenen Beitrag mit und
  /// nicht mehr.
  factory TheoryProgress.fromJson(Map<String, Object?> json) {
    final records = <String, LessonRecord>{};
    final raw = json['records'];
    if (raw is Map) {
      for (final entry in raw.entries) {
        final lessonId = entry.key;
        if (lessonId is! String) continue;
        final record = LessonRecord.fromJson(entry.value);
        if (record != null) records[lessonId] = record;
      }
    }
    return TheoryProgress(records);
  }

  final Map<String, LessonRecord> _records;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'records': <String, Object?>{
        for (final entry in _records.entries) entry.key: entry.value.toJson(),
      },
    };
  }

  LessonRecord? recordFor(String lessonId) => _records[lessonId];

  bool isPassed(String lessonId) => _records[lessonId]?.isPassed ?? false;

  /// Ob die Lektion gespielt werden darf. Die erste eines Zweigs immer,
  /// jede weitere erst nach bestandener Vorgängerin.
  bool isUnlocked(TheoryBranch branch, String lessonId) {
    final index = branch.indexOf(lessonId);
    if (index < 0) return false;
    if (index == 0) return true;
    return isPassed(branch.lessons[index - 1].id);
  }

  /// Die erste noch nicht bestandene Lektion — der natürliche Einstieg.
  /// Null, wenn der Zweig durch ist.
  Lesson? nextLesson(TheoryBranch branch) {
    for (final lesson in branch.lessons) {
      if (!isPassed(lesson.id)) return lesson;
    }
    return null;
  }

  int passedCount(TheoryBranch branch) {
    return branch.lessons.where((l) => isPassed(l.id)).length;
  }

  /// Bestandene Lektionen über den ganzen Baum.
  int passedCountIn(SkillTree tree) {
    return tree.branches.fold(0, (sum, b) => sum + passedCount(b));
  }

  /// Ob ein Zweig komplett durch ist.
  bool isBranchComplete(TheoryBranch branch) {
    return branch.lessonCount > 0 && passedCount(branch) == branch.lessonCount;
  }

  int get totalXp {
    return _records.values.fold(0, (sum, r) => sum + r.xpAwarded);
  }

  int get totalGold {
    return _records.values.fold(0, (sum, r) => sum + r.goldAwarded);
  }

  /// Habit-Vorlagen, die durch bestandene Lektionen offen sind.
  List<String> unlockedHabits(TheoryBranch branch) {
    final habits = <String>[];
    for (final lesson in branch.lessons) {
      final habit = lesson.unlocksHabit;
      if (habit != null && isPassed(lesson.id)) habits.add(habit);
    }
    return List<String>.unmodifiable(habits);
  }

  /// Wertet einen Versuch aus. [answers] enthält je Frage den gewählten
  /// Index oder null für „nicht beantwortet“.
  LessonResult submit(Lesson lesson, List<int?> answers) {
    var correct = 0;
    for (var i = 0; i < lesson.questions.length; i++) {
      final answer = i < answers.length ? answers[i] : null;
      if (lesson.questions[i].isCorrect(answer)) correct++;
    }

    final total = lesson.questionCount;
    final previous = _records[lesson.id];
    final bestCorrect = correct > (previous?.bestCorrect ?? -1)
        ? correct
        : previous?.bestCorrect ?? correct;

    // Nur die Differenz zum bereits Gutgeschriebenen wird ausgezahlt.
    final xpAwarded = TheoryRewards.xpFor(bestCorrect, total);
    final goldAwarded = TheoryRewards.goldFor(bestCorrect, total);
    final xpGained = xpAwarded - (previous?.xpAwarded ?? 0);
    final goldGained = goldAwarded - (previous?.goldAwarded ?? 0);

    final record = LessonRecord(
      bestCorrect: bestCorrect,
      questionCount: total,
      xpAwarded: xpAwarded,
      goldAwarded: goldAwarded,
    );

    return LessonResult(
      lessonId: lesson.id,
      correct: correct,
      total: total,
      xpGained: xpGained,
      goldGained: goldGained,
      isNewBest: correct > (previous?.bestCorrect ?? -1),
      progress: TheoryProgress(<String, LessonRecord>{
        ..._records,
        lesson.id: record,
      }),
    );
  }
}
