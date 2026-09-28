import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';
import 'package:theory/theory.dart';

import '../audio/sound_effects.dart';
import '../combat/ladder_controller.dart';
import '../gear/gear_controller.dart';
import '../habits/habit_check_flow.dart';
import '../habits/habits_controller.dart';
import '../progression/show_level_up.dart';
import '../ui/aufstieg.dart';
import '../ui/palette.dart';
import 'review_controller.dart';

/// Was eine Antwort auf die Rückfrage des Tages auslöst (ADR-0045).
///
/// **Seit dem 28.09. in der Theorie** statt auf dem Gewohnheiten-
/// Bildschirm (Issue #88); der Ablauf ist derselbe geblieben und steht
/// deshalb hier statt im Bildschirm.

/// Beantwortet die Rückfrage. Richtig zahlt sie Erfahrung und Gold, und
/// die steigen dort auf, wo getippt wurde.
void answerReview(
  BuildContext context,
  WidgetRef ref,
  ReviewQuestion frage,
  int wahl,
) {
  final vorherLevel = levelBefore(ref);
  final schluesselVorher = ref.read(availableKeysProvider);
  final richtig = ref
      .read(reviewLogProvider.notifier)
      .answer(ref.read(todayProvider), frage, wahl);
  if (richtig == null) return;

  if (richtig) {
    unawaited(HapticFeedback.mediumImpact());
    ref.read(soundPlayerProvider).play(SoundEffect.haekchen);
    AufstiegHost.maybeOf(context)?.zeige(<AufstiegZeile>[
      const AufstiegZeile(
        '+${TheoryRewards.xpForReview} EP  +${TheoryRewards.goldForReview} G',
        color: Palette.goldOnDark,
      ),
      ?keyGainLine(ref, schluesselVorher),
    ]);
  } else {
    unawaited(HapticFeedback.selectionClick());
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    unawaited(showLevelUp(context, ref, before: vorherLevel));
  });
}

/// Nach wie vielen Tagen die Seite der heutigen Rückfrage wiederkommt —
/// erst nach der Antwort bekannt.
int? daysUntilReview(WidgetRef ref, ReviewQuestion frage, Day today) {
  final faellig = ref.read(reviewLogProvider).dueDayOf(frage.lesson.id);
  if (faellig == null) return null;
  return faellig - dayNumberOf(today);
}
