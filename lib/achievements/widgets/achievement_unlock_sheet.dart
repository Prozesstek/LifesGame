import 'package:achievements/achievements.dart';
import 'package:flutter/material.dart';
import 'package:identity/identity.dart';

import '../../ui/palette.dart';

/// Das Blatt, das eine neue Errungenschaft feiert.
///
/// **Es sagt, was sie eingebracht hat, und nicht nur, dass es sie gibt.**
/// Erfahrung und Gold sind bei einem Meilenstein schon gutgeschrieben,
/// bevor dieses Blatt erscheint — sie werden aus der Historie gerechnet,
/// nicht ausgeschüttet (ADR-0033). Der Text sagt deshalb „gutgeschrieben"
/// und nicht „erhalten".
///
/// **Bei einer Entdeckung steht bewusst da, dass es nichts gibt.** Das ist
/// der Kern des Issues: „Du bekommst nichts dafür. …außer Respekt."
class AchievementUnlockSheet extends StatelessWidget {
  const AchievementUnlockSheet({required this.achievement, super.key});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final titel = TitleCatalog.byId(achievement.titleId);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  achievement.isDiscovery
                      ? Icons.auto_awesome
                      : Icons.emoji_events,
                  size: 26,
                  color: Palette.accent,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    achievement.isDiscovery ? 'Entdeckt' : 'Meilenstein',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Palette.accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              achievement.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Palette.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              achievement.requirement,
              style: const TextStyle(fontSize: 13, color: Palette.textDim),
            ),
            const SizedBox(height: 16),
            _Ertrag(achievement: achievement, titel: titel),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Weiter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ertrag extends StatelessWidget {
  const _Ertrag({required this.achievement, required this.titel});

  final Achievement achievement;
  final CharacterTitle? titel;

  @override
  Widget build(BuildContext context) {
    final zeilen = <String>[
      if (achievement.tier.xp > 0)
        '${achievement.tier.xp} Erfahrung gutgeschrieben',
      if (achievement.tier.gold > 0) '${achievement.tier.gold} Gold',
      '${achievement.tier.fame} Ruhm',
      if (titel != null) 'Titel „${titel!.label}" freigeschaltet',
      if (achievement.moveId != null) 'Eine neue Fähigkeit steht zur Wahl',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Palette.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final zeile in zeilen)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '· $zeile',
                style: const TextStyle(fontSize: 13, color: Palette.text),
              ),
            ),
          if (achievement.isDiscovery) ...<Widget>[
            const SizedBox(height: 8),
            const Text(
              'Gold und Erfahrung gibt es dafür nicht. Entdeckungen sagen '
              'etwas darüber, wer du bist — nicht, wie viel du geschafft '
              'hast.',
              style: TextStyle(fontSize: 12, color: Palette.muted),
            ),
          ],
        ],
      ),
    );
  }
}
