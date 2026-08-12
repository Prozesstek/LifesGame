import 'package:flutter/material.dart';
import 'package:progression/progression.dart';

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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Level ${level.level}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Icon(Icons.savings_outlined, size: 18, color: Palette.gold),
              const SizedBox(width: 6),
              Text(
                '$gold Gold',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Palette.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: level.ratio,
              minHeight: 7,
              backgroundColor: Palette.surfaceRaised,
              valueColor: const AlwaysStoppedAnimation<Color>(Palette.accent),
            ),
          ),
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
