import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../ui/palette.dart';
import '../../ui/holz.dart';

/// Was eine Kette wert ist — als Leiter, nicht als Versprechen.
///
/// **Die Antwort auf „zeigen, wie viel mehr Gewohnheiten geben, wenn man
/// Streaks hält"** (Issue #46). Der Multiplikator stand bisher nur als
/// „x1,2" auf der Kachel: richtig, aber ohne Maßstab. Niemand weiß, ob
/// das viel ist, und vor allem weiß niemand, was als Nächstes käme.
///
/// Die Leiter zeigt alle fünf Meilensteine auf einmal — erreichte,
/// den nächsten, und die, die noch weit weg sind. Das ist der
/// Unterschied zwischen „du bekommst gerade 20 % mehr" und „es geht bis
/// zum Doppelten, und der nächste Schritt ist in vier Tagen".
///
/// Sie rechnet mit der **besten laufenden Kette** über alle
/// Gewohnheiten. Je Gewohnheit wäre genauer und stünde fünfmal
/// untereinander; die Aussage „so weit bist du" ist eine über den
/// Spieler, nicht über eine Zeile seiner Liste.
class StreakLadderCard extends StatelessWidget {
  const StreakLadderCard({required this.bestStreak, super.key});

  /// Die längste Kette, die gerade läuft. 0, wenn keine läuft.
  final int bestStreak;

  /// Erfahrung je Häkchen bei einer Kette von [streak] Tagen — für eine
  /// Vorlage, also ohne Schwierigkeitsfaktor.
  static int xpAt(int streak) => HabitRewards.xpFor(streak < 1 ? 1 : streak);

  @override
  Widget build(BuildContext context) {
    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.local_fire_department,
                size: 16,
                color: Palette.gold,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Beständigkeit',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Palette.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  bestStreak == 0 ? 'keine Kette' : '$bestStreak Tage',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Palette.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              for (final milestone
                  in HabitRewards.streakMilestones) ...<Widget>[
                Expanded(
                  child: _Rung(
                    milestone: milestone,
                    reached: bestStreak >= milestone.days,
                    isNext: _next?.days == milestone.days,
                  ),
                ),
                if (milestone != HabitRewards.streakMilestones.last)
                  const SizedBox(width: 5),
              ],
            ],
          ),
          const SizedBox(height: 9),
          Text(
            _satz,
            style: const TextStyle(
              fontSize: 11,
              height: 1.35,
              color: Palette.textDim,
            ),
          ),
        ],
      ),
    );
  }

  StreakMilestone? get _next => HabitRewards.nextMilestoneAfter(bestStreak);

  /// Der Satz unter der Leiter — immer mit echten Zahlen.
  ///
  /// „20 % mehr" ist eine Behauptung, „21 statt 15" ist eine Zahl. Der
  /// Unterschied ist derselbe wie bei den Hilfetexten im Kampf: Was sich
  /// ausrechnen lässt, wird ausgerechnet.
  String get _satz {
    final milestone = _next;
    if (milestone == null) {
      return 'Der Deckel ist erreicht: jedes Häkchen bringt '
          '${xpAt(bestStreak)} statt ${xpAt(1)} Erfahrung.';
    }

    final faktor = milestone.multiplier.toStringAsFixed(1).replaceAll('.', ',');
    final offen = milestone.days - bestStreak;
    final tage = offen == 1 ? 'Noch ein Tag' : 'Noch $offen Tage';

    return '$tage bis x$faktor — dann bringt jedes Häkchen '
        '${xpAt(milestone.days)} statt ${xpAt(bestStreak)} Erfahrung. '
        'Gold bleibt gleich.';
  }
}

/// Eine Sprosse der Leiter: „7 Tage" über „x1,4".
class _Rung extends StatelessWidget {
  const _Rung({
    required this.milestone,
    required this.reached,
    required this.isNext,
  });

  final StreakMilestone milestone;

  /// Ob die Kette diese Marke schon hat.
  final bool reached;

  /// Ob sie als Nächstes kommt. Genau eine Sprosse trägt das — die
  /// Leiter soll ein Ziel zeigen, nicht fünf.
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final faktor =
        'x${milestone.multiplier.toStringAsFixed(1).replaceAll('.', ',')}';
    final vordergrund = reached
        ? Palette.surface
        : (isNext ? Palette.accent : Palette.muted);

    return Semantics(
      label:
          '${milestone.days} Tage $faktor'
          '${reached ? ', erreicht' : ''}',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        decoration: BoxDecoration(
          color: reached ? Palette.gold : Palette.surfaceSunken,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isNext ? Palette.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: <Widget>[
            Text(
              '${milestone.days}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: vordergrund,
              ),
            ),
            Text(faktor, style: TextStyle(fontSize: 9, color: vordergrund)),
          ],
        ),
      ),
    );
  }
}
