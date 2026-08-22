import 'package:flutter/material.dart';

import '../../ui/palette.dart';

/// Beständigkeit: was die Gewohnheiten über den Charakter sagen.
///
/// **Warum das hier steht.** Der Charakterbildschirm behauptet oben „Alles
/// hier kommt aus dem, was du getan hast" — und zeigte trotzdem nur Werte
/// und Ausrüstung. Die Streak, der emotional stärkste Wert der App, kam
/// gar nicht vor. Das war eines der fünf Löcher, die ADR-0013 aufgezählt
/// hat, und das letzte davon, das noch offen war.
///
/// **Warum drei Zahlen und nicht eine.** Die laufende Kette allein wäre
/// grausam: Sie steht nach einem verpassten Tag auf 0, und der
/// Bildschirm, der „wer ich bin" zeigen soll, würde behaupten, es sei
/// nichts gewesen. Der Bestwert daneben ist genau die Zusage aus
/// ADR-0013 — einmal verdient heißt behalten. Die Häkchen fangen den Fall
/// auf, in dem beide Ketten kurz sind, weil jemand unregelmäßig, aber viel
/// tut.
///
/// Gerechnet wird nichts davon hier: `package:habits` liefert alle drei.
class ConsistencyCard extends StatelessWidget {
  const ConsistencyCard({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalChecks,
    super.key,
  });

  /// Die längste Kette, die gerade läuft — über alle Gewohnheiten.
  final int currentStreak;

  /// Die längste, die je gelaufen ist. Fällt nie durch einen
  /// verpassten Tag.
  final int longestStreak;

  final int totalChecks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _Figure(
                  value: '$currentStreak',
                  unit: currentStreak == 1 ? 'Tag am Stück' : 'Tage am Stück',
                  emphasised: currentStreak > 0,
                ),
              ),
              Expanded(
                child: _Figure(value: '$longestStreak', unit: 'Bestwert'),
              ),
              Expanded(
                child: _Figure(value: '$totalChecks', unit: 'Häkchen'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_summary, style: _summaryStyle),
        ],
      ),
    );
  }

  /// Der Satz unter den Zahlen. Er trägt die Aussage, die keine der drei
  /// Zahlen allein macht — vor allem im Fall „Kette gerissen, Bestwert
  /// steht": Dass nichts verloren ist, muss dastehen, sonst liest sich
  /// eine 0 wie ein Rückschritt (`konzept.md` 3.7).
  String get _summary {
    if (totalChecks == 0) {
      return 'Noch kein Häkchen. Der erste Tag ist der ganze Trick.';
    }
    if (currentStreak == 0) {
      return 'Die Kette ruht gerade. Der Bestwert bleibt — verpasste Tage '
          'nehmen nichts weg.';
    }
    if (currentStreak >= longestStreak) {
      return 'So beständig warst du noch nie.';
    }
    final fehlt = longestStreak - currentStreak;
    return 'Noch $fehlt ${fehlt == 1 ? 'Tag' : 'Tage'} bis zum Bestwert.';
  }

  TextStyle get _summaryStyle {
    return TextStyle(
      fontSize: 12,
      color: currentStreak == 0 ? Palette.textDim : Palette.success,
    );
  }
}

/// Eine Zahl mit ihrer Einheit darunter.
class _Figure extends StatelessWidget {
  const _Figure({
    required this.value,
    required this.unit,
    this.emphasised = false,
  });

  final String value;
  final String unit;

  /// Die laufende Kette wird hervorgehoben, solange sie läuft — sie ist
  /// die einzige der drei Zahlen, die heute noch beeinflussbar ist.
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $unit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: emphasised ? Palette.accent : Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: const TextStyle(fontSize: 11, color: Palette.textDim),
          ),
        ],
      ),
    );
  }
}
