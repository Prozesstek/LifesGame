import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../../ui/palette.dart';
import '../copy_text.dart';

/// Die Werte eines Exemplars **untereinander**, jeder mit dem
/// Unterschied zum getragenen Stück in Klammern — grün mehr, rot weniger.
/// Darunter die Qualität des Wurfs — ausser [mitQualitaet] ist aus, weil
/// sie schon beim Namen steht (das Blatt eines Stücks).
///
/// Eine Stelle für Laden, Inventar, Beute und das Auswahlblatt am
/// Charakter; gerechnet wird in [CopyText.lines].
class CopyStats extends StatelessWidget {
  const CopyStats({
    required this.copy,
    this.worn,
    this.center = false,
    this.mitQualitaet = true,
    super.key,
  });

  final GearCopy copy;

  /// Was auf dem Platz getragen wird. Null: kein Vergleich.
  final GearCopy? worn;

  /// Zentriert statt linksbündig — im Beute-Blatt.
  final bool center;

  final bool mitQualitaet;

  @override
  Widget build(BuildContext context) {
    final zeilen = CopyText.lines(copy, worn: worn);
    final gut = CopyText.isGoodRoll(copy);

    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final zeile in zeilen)
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: zeile.valueText,
                  style: TextStyle(
                    color: Palette.success,
                    fontWeight: gut ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (zeile.diff != null)
                  TextSpan(
                    text: ' ${zeile.diffText}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: switch (zeile.diff!) {
                        > 0 => Palette.success,
                        < 0 => Palette.enemy,
                        _ => Palette.muted,
                      },
                    ),
                  ),
              ],
            ),
            style: const TextStyle(fontSize: 12, height: 1.3),
          ),
        if (mitQualitaet)
          Text(
            CopyText.qualitaet(copy),
            style: TextStyle(
              fontSize: 11,
              color: gut ? Palette.accent : Palette.muted,
              fontWeight: gut ? FontWeight.bold : FontWeight.normal,
            ),
          ),
      ],
    );
  }
}
