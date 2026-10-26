import 'package:flutter/material.dart';
import 'package:habits/habits.dart';
import 'package:progression/progression.dart';

import '../../ui/palette.dart';
import '../gebiet_farbe.dart';
import '../gebiet_zeichen.dart';

/// Ein Skill als kleine Marke: das Zeichen des Gebiets und sein Level
/// (ADR-0085), Zeichen und Strich in der Farbe des Gebiets. **Eine Stelle** für die Kachel einer Gewohnheit und den
/// Kopf des Wissensbaums.
///
/// Darunter ein dünner Strich, wie weit es bis zur nächsten Stufe ist —
/// ohne ihn sähe ein Skill, der wochenlang auf 34 steht, aus wie einer,
/// der nicht wächst.
class SkillAbzeichen extends StatelessWidget {
  const SkillAbzeichen({
    required this.area,
    required this.skill,
    this.aufDunkel = false,
    super.key,
  });

  final SkillArea area;
  final SkillLevel skill;

  /// Auf Leder statt Pergament — der Kopf des Baums.
  final bool aufDunkel;

  @override
  Widget build(BuildContext context) {
    final farbe = aufDunkel ? Palette.textOnDark : Palette.text;
    final fuellung = GebietFarbe.auf(area, dunkel: aufDunkel);

    return Semantics(
      label: '${area.label}, Stufe ${skill.level}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(gebietZeichen(area), size: 15, color: fuellung),
              const SizedBox(width: 3),
              Text(
                '${skill.level}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: farbe,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: skill.ratio,
                minHeight: 3,
                backgroundColor:
                    (aufDunkel ? Palette.textOnDarkDim : Palette.muted)
                        .withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(fuellung),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
