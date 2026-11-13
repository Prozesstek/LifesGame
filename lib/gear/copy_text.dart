import 'package:gear/gear.dart';

/// Eine Zeile der Werte eines Exemplars: was es bringt, und — wenn auf
/// dem Platz schon etwas liegt — wie viel mehr oder weniger als das.
class StatLine {
  const StatLine({
    required this.label,
    required this.value,
    this.diff,
    this.teiler = 1,
    this.einheit = '',
  });

  /// „Angriffsschaden", „Leben", …
  final String label;

  /// Was dieses Exemplar bringt, im Kampfmassstab.
  final int value;

  /// Der Unterschied zum getragenen Stück. Null, wenn nichts getragen
  /// wird oder es dasselbe Exemplar ist.
  final int? diff;

  /// Durch wie viel [value] für die Anzeige geteilt wird. Abklingzeit und
  /// Manaregeneration stehen im Kampfmassstab mal zehn (`GearBonus`).
  final int teiler;

  /// Was hinter der Zahl steht: „ %“, „/s“.
  final String einheit;

  /// „+11“, „+0,8/s“ — die Zahl allein, für eine Tabelle.
  String get zahlText => '${_signed(value)}$einheit';

  /// „+11 Angriffsschaden", „+0,8/s Manaregeneration".
  String get valueText => '$zahlText $label';

  /// „+2“, „−3“, „±0“ — der Unterschied ohne Klammern, für das Blatt.
  /// Leer ohne Vergleich.
  String get diffZahl {
    final d = diff;
    if (d == null) return '';
    if (d == 0) return '±0';
    return '${_signed(d)}$einheit';
  }

  /// „(+2)", „(−3)", „(±0)" — oder leer ohne Vergleich.
  String get diffText {
    final d = diff;
    if (d == null) return '';
    if (d == 0) return '(±0)';
    return '(${_signed(d)})';
  }

  String _signed(int v) {
    final zahl = _zahl(v.abs());
    return v >= 0 ? '+$zahl' : '−$zahl';
  }

  String _zahl(int v) {
    if (teiler == 1) return '$v';
    final text = (v / teiler).toStringAsFixed(1);
    final ohne = text.endsWith('.0')
        ? text.substring(0, text.length - 2)
        : text;
    return ohne.replaceAll('.', ',');
  }
}

/// Wie ein Exemplar sich beschreibt — **eine Stelle** für Laden,
/// Inventar, Beute und Charakter (ADR-0048).
abstract final class CopyText {
  /// „108 %": wie gut der Wurf ist, gemessen am Katalogwert.
  static String quality(GearCopy copy) => '${(copy.quality * 100).round()} %';

  /// „Qualität 108 %" — so heisst der Wurf seit dem 13.11.2026 überall.
  static String qualitaet(GearCopy copy) => 'Qualität ${quality(copy)}';

  /// Die Werte untereinander, samt Unterschied zu [worn].
  ///
  /// Ein Wert steht da, wenn **eines** der beiden Stücke ihn hat: Bringt
  /// das getragene Abwehr und das neue nicht, steht „+0 Abwehr (−3)" —
  /// sonst sähe man nicht, was man aufgibt.
  ///
  /// **Die Namen sind die des Charakters** (13.11.2026): Angriffsschaden,
  /// Fähigkeitsstärke, Leben, Abwehr. Bis dahin hiess es hier „Angriff“,
  /// „Lebenspunkte“ und „Verteidigung“, und Fähigkeitsstärke,
  /// Manaregeneration und Abklingzeit standen gar nicht da.
  static List<StatLine> lines(GearCopy copy, {GearCopy? worn}) {
    final vergleich = worn == null || worn.uid == copy.uid ? null : worn;
    final a = copy.bonus;
    final b = vergleich?.bonus;
    final werte = <(String, int, int, int, String)>[
      ('Angriffsschaden', a.attack, b?.attack ?? 0, 1, ''),
      ('Fähigkeitsstärke', a.abilityPower, b?.abilityPower ?? 0, 1, ''),
      ('Leben', a.maxHp, b?.maxHp ?? 0, 1, ''),
      ('Abwehr', a.defense, b?.defense ?? 0, 1, ''),
      ('Mana', a.maxEnergy, b?.maxEnergy ?? 0, 1, ''),
      ('Manaregeneration', a.manaRegen, b?.manaRegen ?? 0, 10, '/s'),
      (
        'kürzere Abklingzeit',
        a.cooldownReduction,
        b?.cooldownReduction ?? 0,
        10,
        ' %',
      ),
    ];
    return <StatLine>[
      for (final (label, neu, alt, teiler, einheit) in werte)
        if (neu != 0 || (vergleich != null && alt != 0))
          StatLine(
            label: label,
            value: neu,
            diff: vergleich == null ? null : neu - alt,
            teiler: teiler,
            einheit: einheit,
          ),
    ];
  }

  /// Ob der Wurf über dem Durchschnitt liegt — dann darf er auffallen.
  static bool isGoodRoll(GearCopy copy) => copy.quality >= 1.05;
}
