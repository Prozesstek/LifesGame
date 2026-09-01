import 'package:flutter/material.dart';

import '../../ui/palette.dart';

/// Zeigt die freien Theoriepunkte.
///
/// Sie sind die Währung des Baums (ADR-0019) und müssen deshalb überall
/// sichtbar sein, wo etwas zu öffnen ist — sonst tippt der Spieler auf
/// einen Knoten, um erst dort zu erfahren, dass er nicht kann.
///
/// **Seit ADR-0026 fällt der Chip auf, statt mitzulaufen** (Issue #21,
/// Punkt 6): eigenes Symbol, eigene Farbe, größere Schrift. Vorher war er
/// eine 13 Pixel hohe Zahl neben dem Titel — die Währung des ganzen
/// Bildschirms sah aus wie eine Fußnote.
///
/// Der Tooltip beantwortet die Frage, die der Chip aufwirft: *woher*
/// kommen die Dinger? Ohne ihn ist die Zahl eine Zahl.
class PointsChip extends StatelessWidget {
  const PointsChip({required this.points, super.key});

  final int points;

  /// Was ein Punkt ist und woher er kommt. Steht hier und nicht im
  /// Bildschirm, damit jede Stelle, die den Chip zeigt, dieselbe Antwort
  /// gibt.
  static const String explanation =
      'Jeder Aufstieg gibt zwei Punkte — damit schaltest du neue Sachen '
      'frei.';

  @override
  Widget build(BuildContext context) {
    final hasAny = points > 0;
    final color = hasAny ? Palette.gold : Palette.muted;

    return Tooltip(
      message: explanation,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: hasAny ? 0.2 : 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: hasAny ? 0.6 : 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.hexagon_rounded, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              '$points',
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
