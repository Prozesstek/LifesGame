import 'package:achievements/achievements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/palette.dart';
import 'achievements_controller.dart';
import 'achievements_screen.dart';

/// Der Weg zu den Errungenschaften, vom Charakter aus.
///
/// **Warum vom Charakter und nicht vom Startbildschirm** (ADR-0033,
/// Punkt 11): ADR-0013 trennt beide Bildschirme nach einer Frage — der
/// Start zeigt, *was ich tue*, der Charakter, *wer ich bin*. Eine
/// Errungenschaft ist das Zweite. Ein sechster Kreis auf dem Start hätte
/// diese Trennung aufgeweicht.
class AchievementsCard extends ConsumerWidget {
  const AchievementsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verdient = ref.watch(earnedAchievementIdsProvider).length;
    final gesamt = AchievementCatalog.all.length;
    final fame = ref.watch(fameProvider);

    return Material(
      color: Palette.surfaceRaised,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.emoji_events_outlined,
                size: 28,
                color: Palette.accent,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Errungenschaften',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Palette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$verdient von $gesamt · $fame Ruhm',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Palette.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 22, color: Palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}
