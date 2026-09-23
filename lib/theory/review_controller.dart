import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';
import 'package:theory/theory.dart';

import '../combat/ladder_controller.dart';
import '../habits/habits_controller.dart';
import '../save/save_providers.dart';
import 'theory_controller.dart';

/// Riverpod-Brücke Rückfrage ↔ UI (ADR-0045), **enthält keine Regeln**:
/// Welche Frage fällig ist und was sie einbringt, steht in
/// `package:theory` ([ReviewLog]).
class ReviewController extends Notifier<ReviewLog> {
  @override
  ReviewLog build() => ref.watch(savedGameProvider).reviews;

  /// Beantwortet die Frage von [today]. Null, wenn heute schon geantwortet
  /// wurde; sonst, ob es richtig war.
  bool? answer(Day today, ReviewQuestion question, int choice) {
    final ergebnis = state.answer(dayNumberOf(today), question, choice);
    if (ergebnis == null) return null;
    state = ergebnis.log;
    return ergebnis.correct;
  }
}

final reviewLogProvider = NotifierProvider<ReviewController, ReviewLog>(
  ReviewController.new,
);

/// Alle bestandenen Seiten, aus Handbuch **und** Graph — aus diesen kommt
/// die Rückfrage. Dieselbe Doppelung wie bei `passedPagesProvider`.
final passedLessonsProvider = Provider<List<Lesson>>((ref) {
  final fortschritt = ref.watch(theoryProgressProvider);
  return <Lesson>[
    for (final lesson in ref.watch(handbookProvider).lessons)
      if (fortschritt.isPassed(lesson.id)) lesson,
    for (final node in ref.watch(theoryGraphProvider).nodes)
      if (fortschritt.isPassed(node.lesson.id)) node.lesson,
  ];
});

/// Die Frage von heute — null, wenn nichts fällig ist oder noch keine
/// Seite bestanden.
final todaysReviewProvider = Provider<ReviewQuestion?>((ref) {
  final heute = dayNumberOf(ref.watch(todayProvider));
  return ref
      .watch(reviewLogProvider)
      .questionFor(heute, ref.watch(passedLessonsProvider));
});

/// Die Antwort von heute, wenn es schon eine gibt.
final todaysReviewAnswerProvider = Provider<ReviewAnswer?>((ref) {
  final heute = dayNumberOf(ref.watch(todayProvider));
  return ref.watch(reviewLogProvider).answerOn(heute);
});
