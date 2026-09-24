import 'package:gear/gear.dart';

/// Eine Zeile der Werte eines Exemplars: was es bringt, und — wenn auf
/// dem Platz schon etwas liegt — wie viel mehr oder weniger als das.
class StatLine {
  const StatLine({required this.label, required this.value, this.diff});

  /// „Angriff", „Lebenspunkte", …
  final String label;

  /// Was dieses Exemplar bringt, im Kampfmassstab.
  final int value;

  /// Der Unterschied zum getragenen Stück. Null, wenn nichts getragen
  /// wird oder es dasselbe Exemplar ist.
  final int? diff;

  /// „+11 Angriff".
  String get valueText => '${_signed(value)} $label';

  /// „(+2)", „(−3)", „(±0)" — oder leer ohne Vergleich.
  String get diffText {
    final d = diff;
    if (d == null) return '';
    if (d == 0) return '(±0)';
    return d > 0 ? '(+$d)' : '(−${-d})';
  }

  static String _signed(int v) => v >= 0 ? '+$v' : '−${-v}';
}

/// Wie ein Exemplar sich beschreibt — **eine Stelle** für Laden,
/// Inventar, Beute und Charakter (ADR-0048).
abstract final class CopyText {
  /// „108 %": wie gut der Wurf ist, gemessen am Katalogwert.
  static String quality(GearCopy copy) => '${(copy.quality * 100).round()} %';

  /// Die Werte untereinander, samt Unterschied zu [worn].
  ///
  /// Ein Wert steht da, wenn **eines** der beiden Stücke ihn hat: Bringt
  /// das getragene Verteidigung und das neue nicht, steht „+0
  /// Verteidigung (−3)" — sonst sähe man nicht, was man aufgibt.
  static List<StatLine> lines(GearCopy copy, {GearCopy? worn}) {
    final vergleich = worn == null || worn.uid == copy.uid ? null : worn;
    final werte = <(String, int, int)>[
      ('Angriff', copy.bonus.attack, vergleich?.bonus.attack ?? 0),
      ('Lebenspunkte', copy.bonus.maxHp, vergleich?.bonus.maxHp ?? 0),
      ('Verteidigung', copy.bonus.defense, vergleich?.bonus.defense ?? 0),
      ('Energie', copy.bonus.maxEnergy, vergleich?.bonus.maxEnergy ?? 0),
    ];
    return <StatLine>[
      for (final (label, neu, alt) in werte)
        if (neu != 0 || (vergleich != null && alt != 0))
          StatLine(
            label: label,
            value: neu,
            diff: vergleich == null ? null : neu - alt,
          ),
    ];
  }

  /// Ob der Wurf über dem Durchschnitt liegt — dann darf er auffallen.
  static bool isGoodRoll(GearCopy copy) => copy.quality >= 1.05;
}
