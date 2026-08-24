import 'package:flutter/material.dart';

import '../../ui/palette.dart';

/// Zeigt die freien Theoriepunkte.
///
/// Sie sind die Währung des Baums (ADR-0019) und müssen deshalb überall
/// sichtbar sein, wo etwas zu öffnen ist — sonst tippt der Spieler auf
/// einen Knoten, um erst dort zu erfahren, dass er nicht kann.
class PointsChip extends StatelessWidget {
  const PointsChip({required this.points, super.key});

  final int points;

  @override
  Widget build(BuildContext context) {
    final hasAny = points > 0;
    final color = hasAny ? Palette.gold : Palette.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.hexagon_outlined, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            '$points',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
