import 'package:flutter/material.dart';

import '../../ui/gold_icon.dart';
import '../../ui/palette.dart';

/// **Die Leiste zum Verkaufen mit Häkchen** (ADR-0083) — eine Stelle für
/// Siegerblatt und Rucksack.
///
/// Wie in AktivesBretts Bild aus Summoners War: Erst schaltet ein Knopf
/// die Auswahl ein, dann setzt jeder Tipp auf ein Stück ein Häkchen, und
/// „Verkaufen“ zeigt, wie viele es sind und was sie bringen. Ohne Worte
/// (ADR-0060): Zeichen und Zahlen, der Satz steht für den Vorleser.
class VerkaufLeiste extends StatelessWidget {
  const VerkaufLeiste({
    required this.waehlen,
    required this.anzahl,
    required this.gold,
    required this.onUmschalten,
    required this.onVerkaufen,
    this.aufDunkel = false,
    super.key,
  });

  /// Ob die Auswahl gerade an ist.
  final bool waehlen;

  /// Wie viele Stücke angehakt sind, und was sie bringen.
  final int anzahl;
  final int gold;

  final VoidCallback onUmschalten;
  final VoidCallback onVerkaufen;

  /// Ob die Leiste auf dunklem Leder steht (Rucksack) statt auf Pergament
  /// (Siegerblatt).
  final bool aufDunkel;

  /// Woran Tests die Knöpfe finden.
  static const Key umschaltenKey = ValueKey<String>('auswahl-umschalten');
  static const Key verkaufenKey = ValueKey<String>('auswahl-verkaufen');

  @override
  Widget build(BuildContext context) {
    final farbe = aufDunkel ? Palette.textOnDark : Palette.text;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        OutlinedButton(
          key: umschaltenKey,
          onPressed: onUmschalten,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            foregroundColor: farbe,
            side: BorderSide(color: farbe.withValues(alpha: 0.6)),
          ),
          child: Icon(
            waehlen ? Icons.close_rounded : Icons.checklist_rounded,
            size: 20,
            semanticLabel: waehlen
                ? 'Auswahl beenden'
                : 'Stücke zum Verkaufen auswählen',
          ),
        ),
        if (waehlen)
          FilledButton(
            key: verkaufenKey,
            onPressed: anzahl == 0 ? null : onVerkaufen,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.sell_outlined, size: 18),
                const SizedBox(width: 6),
                Text(
                  '×$anzahl',
                  semanticsLabel: '$anzahl Stück für $gold Gold verkaufen',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const GoldIcon(size: 16),
                const SizedBox(width: 3),
                Text('+$gold', semanticsLabel: ''),
              ],
            ),
          ),
      ],
    );
  }
}
