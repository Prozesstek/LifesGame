import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../theory/review_controller.dart';
import 'habits_controller.dart';

/// Die drei Aufgaben von heute (ADR-0055).
///
/// Die Regel steht in `package:habits` (`DailyQuests.forDay`); hier wird
/// nur eingesetzt, was jenes Package nicht kennt: ob es heute eine
/// Rückfrage gibt und ob sie richtig beantwortet ist. **Rechnet nichts.**
final dailyQuestsProvider = Provider<List<DailyQuest>>((ref) {
  final frage = ref.watch(todaysReviewProvider);
  final antwort = ref.watch(todaysReviewAnswerProvider);
  return DailyQuests.forDay(
    ref.watch(habitTrackerProvider),
    ref.watch(todayProvider),
    reviewAvailable: frage != null || antwort != null,
    reviewCorrect: antwort?.correct ?? false,
  );
});

/// Aufgaben, die erledigt und noch nicht abgeholt sind.
final claimableQuestsProvider = Provider<List<DailyQuest>>((ref) {
  final tracker = ref.watch(habitTrackerProvider);
  final heute = ref.watch(todayProvider);
  return <DailyQuest>[
    for (final quest in ref.watch(dailyQuestsProvider))
      if (quest.isDone && !tracker.isQuestClaimed(heute, quest.id)) quest,
  ];
});
