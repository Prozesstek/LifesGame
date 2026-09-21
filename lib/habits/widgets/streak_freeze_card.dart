import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../ui/palette.dart';

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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Palette.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.accent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.ac_unit, size: 16, color: Palette.accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Gestern fehlt etwas',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Palette.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _satz,
            style: const TextStyle(
              fontSize: 11,
              height: 1.35,
              color: Palette.textDim,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onUse,
              icon: const Icon(Icons.ac_unit, size: 16),
              label: Text(
                '${StreakFreeze.name} einsetzen · $freezesLeft übrig',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
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
