import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../habits/daily_quests_provider.dart';
import '../habits/habits_controller.dart';
import '../theory/review_controller.dart';
import 'am_feuer.dart';

/// Trägt zusammen, was am Lagerfeuer wartet (ADR-0076) — **rechnet
/// nichts**; was offen ist, sagen die Stellen, denen es gehört.
///
/// Die Uhrzeit kommt aus [clockProvider] und wird nur gelesen, wenn sich
/// sonst etwas ändert. Steht die App um sechs offen da, beginnt das Feuer
/// erst beim nächsten Neubau zu brennen — dafür ist kein eigener Takt
/// nötig.
final amFeuerProvider = Provider<AmFeuer>((ref) {
  final today = ref.watch(todayProvider);
  final tracker = ref.watch(habitTrackerProvider);
  return AmFeuer(
    brennt: AmFeuer.brenntUm(
      ref.watch(clockProvider)(),
      tagGeschafft: tracker.isDayComplete(today),
    ),
    rueckfrageOffen:
        ref.watch(todaysReviewProvider) != null &&
        ref.watch(todaysReviewAnswerProvider) == null,
    truheWartet: tracker.canOpenChest(today),
    aufgabenAbholbar: ref.watch(claimableQuestsProvider).length,
  );
});
