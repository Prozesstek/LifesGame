import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../gebiet_farbe.dart';

/// **Der Streifen am linken Rand** einer Gewohnheit, in der Farbe ihres
/// Gebiets (ADR-0090) — eine Stelle für die Kachel und den Zettel auf
/// „Heute“.
///
/// Erledigt wird er blass, wie der Rest der Kachel. **Ohne Gebiet** —
/// eine alte eigene Gewohnheit, nach der noch nicht gefragt wurde — ist
/// er durchsichtig, aber gleich breit: Sonst stünde ihr Name eine Spur
/// weiter links als die der anderen.
///
/// Ein `Container`, kein `DecoratedBox`: Nur der rückt sein Kind um den
/// Rand ein (`gotchas.md`). Wer ihn einsetzt, nimmt [breite] von seinem
/// linken Abstand.
class GebietStreifen extends StatelessWidget {
  const GebietStreifen({
    required this.area,
    required this.child,
    this.blass = false,
    super.key,
  });

  final SkillArea? area;
  final Widget child;

  /// Erledigt: der Streifen tritt zurück.
  final bool blass;

  static const double breite = 5;

  @override
  Widget build(BuildContext context) {
    final gebiet = area;
    final farbe = gebiet == null
        ? Colors.transparent
        : GebietFarbe.pergament(gebiet).withValues(alpha: blass ? 0.4 : 1);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: farbe, width: breite),
        ),
      ),
      child: child,
    );
  }
}
