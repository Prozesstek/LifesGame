import 'package:flutter/material.dart';
import 'package:progression/progression.dart';

import '../../ui/gold_icon.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';

/// Level, Fortschritt zur nächsten Stufe und Gold.
///
/// Steht auf dem Startbildschirm und über dem Skillbaum — dort ist das Level
/// die Währung, die Zweige öffnet.
class LevelCard extends StatelessWidget {
  const LevelCard({required this.level, required this.gold, super.key});

  final PlayerLevel level;
  final int gold;

  @override
  Widget build(BuildContext context) {
    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // **Beide Seiten müssen schrumpfen können.** Hier stand ein
          // `Spacer` zwischen zwei festen Texten — der verteilt nur, was
          // übrig ist, und schrumpft nichts (`docs/context/gotchas.md`).
          // Aufgefallen ist es an einem langen Goldbetrag: Sobald die Zahl
          // mehr Stellen bekommt, lief die Zeile über.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  'Level ${level.level}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const GoldIcon(),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$gold Gold',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Palette.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          HolzBalken(value: level.ratio, color: Palette.accent),
          const SizedBox(height: 7),
          Text(
            level.isMaxLevel
                ? 'Höchste Stufe erreicht'
                : '${level.xpIntoLevel} von ${level.xpForLevel} Erfahrung '
                      'bis Level ${level.level + 1}',
            style: const TextStyle(fontSize: 12, color: Palette.textDim),
          ),
        ],
      ),
    );
  }
}
