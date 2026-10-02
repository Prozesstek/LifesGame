import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../gear/gear_icon.dart';
import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';

/// Die drei Aufgaben des Tages (ADR-0055) — mit Stand und, sobald eine
/// erledigt ist, dem Knopf zum Abholen.
///
/// **Abholen ist ein eigener Tipp**, nicht automatisch: Der kurze Moment,
/// in dem der Schlüssel dazukommt, ist die Belohnung — wie beim Öffnen der
/// Tagestruhe.
class DailyQuestsCard extends StatelessWidget {
  const DailyQuestsCard({
    required this.quests,
    required this.isClaimed,
    required this.onClaim,
    super.key,
  });

  /// Woran man den Knopf zum Abholen findet — er trägt kein Wort mehr.
  static const Key abholenKey = ValueKey<String>('quest-abholen');

  final List<DailyQuest> quests;
  final bool Function(DailyQuest quest) isClaimed;
  final void Function(DailyQuest quest) onClaim;

  @override
  Widget build(BuildContext context) {
    final fertig = quests.where(isClaimed).length;

    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.flag_rounded,
                size: 22,
                color: Palette.text,
                semanticLabel: 'Tagesaufgaben',
              ),
              const Spacer(),
              Text(
                '$fertig / ${quests.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Palette.textDim,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 4),
          for (final quest in quests)
            _Zeile(
              key: ValueKey<String>(quest.id),
              quest: quest,
              claimed: isClaimed(quest),
              onClaim: () => onClaim(quest),
            ),
        ],
      ),
    );
  }
}

/// Ein kleiner Knopf statt der Holzplanke: Die Planke ist für ganze
/// Zeilen gebaut und drückte in einer Aufgabenzeile den Text weg.
class _AbholenKnopf extends StatelessWidget {
  const _AbholenKnopf({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abholen',
      child: Druck(
        child: Material(
          color: Palette.accent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '+1',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Palette.surface,
                    ),
                  ),
                  SizedBox(width: 3),
                  PixelArt(
                    assetPath: GearIcons.schluessel,
                    side: 20,
                    fallback: Icon(Icons.key, size: 16, color: Palette.surface),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Zeile extends StatelessWidget {
  const _Zeile({
    required this.quest,
    required this.claimed,
    required this.onClaim,
    super.key,
  });

  final DailyQuest quest;
  final bool claimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final anteil = quest.target <= 0
        ? 0.0
        : (quest.progress / quest.target).clamp(0.0, 1.0);

    // Der Satz steht immer da, offen wie abgeholt: Ein Zeichen mit Balken
    // sagt nicht, was zu tun ist.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Icon(
            claimed ? Icons.check_circle : _zeichen(quest.kind),
            size: 20,
            color: claimed ? Palette.success : Palette.accent,
          ),
          const SizedBox(width: 10),
          if (claimed)
            // Abgeholt braucht es keinen Balken mehr.
            Expanded(
              child: Text(
                quest.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Palette.textDim,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Palette.textDim,
                ),
              ),
            )
          else ...<Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    quest.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Palette.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: anteil,
                      minHeight: 6,
                      backgroundColor: Palette.surfaceRaised,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Palette.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (quest.isDone)
              _AbholenKnopf(key: DailyQuestsCard.abholenKey, onTap: onClaim)
            else
              Text(
                '${quest.progress} / ${quest.target}',
                style: const TextStyle(fontSize: 12, color: Palette.textDim),
              ),
          ],
        ],
      ),
    );
  }

  static IconData _zeichen(QuestKind kind) => switch (kind) {
    QuestKind.zweiHaekchen => Icons.check_circle_outline,
    QuestKind.dreiHaekchen => Icons.check_circle_outline,
    QuestKind.alles => Icons.done_all_rounded,
    QuestKind.liegengeblieben => Icons.history_rounded,
    QuestKind.rueckfrage => Icons.quiz_outlined,
  };
}
