import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../ui/palette.dart';
import '../../ui/holz.dart';

/// Der Knopf, der eine Kette rettet — und nur dann da ist, wenn es etwas
/// zu retten gibt.
///
/// **Das Streak-Eis ist ein Gegenstand, kein Nachlass** ([StreakFreeze]).
/// Eine Kette, die von selbst einen Fehltag verzeiht, sagt nichts mehr
/// aus; eine, die ein knappes Eis kostet, schon. Deshalb steht hier
/// beides: was es rettet, und was es kostet.
///
/// **Die Karte erscheint nur, wenn gestern etwas fehlt** und die Kette
/// vorgestern noch stand (`HabitTracker.rescuableDay`). Sie dauerhaft zu
/// zeigen hieße, jeden Tag an eine Möglichkeit zu erinnern, die niemand
/// braucht — und die Erinnerung an einen Fehltag ist genau das, was das
/// Konzept bei den Gewohnheiten ausschließt (3.7).
class StreakFreezeCard extends StatelessWidget {
  const StreakFreezeCard({
    required this.streakAtRisk,
    required this.freezesLeft,
    required this.onUse,
    super.key,
  });

  /// Die längste Kette, die gerade auf dem Spiel steht.
  final int streakAtRisk;

  /// Wie viele Eis noch da sind. Die Karte erscheint nur mit mindestens
  /// einem — der Knopf wäre sonst eine Enttäuschung mit Ankündigung.
  final int freezesLeft;

  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    // Ohne Satz: gerissene Kette mit Länge, daneben das Eis mit Vorrat.
    // Was es tut, sagt ein Tipp auf die Karte.
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      message: _satz,
      child: HolzKarte(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        color: Palette.surfaceRaised,
        edgeColor: Palette.accent,
        child: Row(
          children: <Widget>[
            const Icon(Icons.link_off_rounded, size: 22, color: Palette.enemy),
            const SizedBox(width: 8),
            const Icon(
              Icons.local_fire_department,
              size: 18,
              color: Palette.gold,
            ),
            Text(
              '$streakAtRisk',
              semanticsLabel: 'Kette von $streakAtRisk Tagen gerissen',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Palette.text,
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: onUse,
              icon: const Icon(Icons.ac_unit, size: 18),
              label: Text(
                '×$freezesLeft',
                semanticsLabel:
                    '${StreakFreeze.name} einsetzen, $freezesLeft übrig',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _satz {
    final kette = streakAtRisk == 1
        ? 'Deine Kette von einem Tag'
        : 'Deine Kette von $streakAtRisk Tagen';
    return '$kette ist gerissen. Ein ${StreakFreeze.name} deckt gestern '
        'ab — die Kette läuft weiter, wird aber nicht länger. '
        'Erfahrung gibt es nur für echte Häkchen.';
  }
}
