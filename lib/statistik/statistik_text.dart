import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../habits/widgets/weekday_picker.dart';
import '../ui/palette.dart';

/// Wie die Statistik (ADR-0087) spricht und welche Farben sie trägt —
/// **eine Stelle** für Bildschirm, Graphen und Jahresrückblick.
///
/// Gerechnet wird nichts: Die Zahlen kommen aus `StatRechnung` in
/// `package:habits`.
abstract final class StatText {
  static const List<String> _monateKurz = <String>[
    'Jan',
    'Feb',
    'Mär',
    'Apr',
    'Mai',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Okt',
    'Nov',
    'Dez',
  ];

  static const List<String> _monateLang = <String>[
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];

  static String monatKurz(int monat) => _monateKurz[monat - 1];

  static String monatLang(int monat) => _monateLang[monat - 1];

  /// „Mo 05.10.“
  static String tag(Day tag) =>
      '${Wochentage.kurz(tag.weekday)} ${_zwei(tag.day)}.${_zwei(tag.month)}.';

  /// „Okt 2026“
  static String monat(Day tag) => '${monatKurz(tag.month)} ${tag.year}';

  /// Was über dem Fenster steht: „05.10. – 11.10.“, „Oktober 2026“,
  /// „2026“ oder „seit Okt 2026“.
  static String fenster(StatFenster fenster) => switch (fenster.zeitraum) {
    StatZeitraum.woche =>
      '${_zwei(fenster.von.day)}.${_zwei(fenster.von.month)}. – '
          '${_zwei(fenster.bis.day)}.${_zwei(fenster.bis.month)}.',
    StatZeitraum.monat => '${monatLang(fenster.von.month)} ${fenster.von.year}',
    StatZeitraum.jahr => '${fenster.von.year}',
    StatZeitraum.gesamt => 'seit ${monat(fenster.von)}',
  };

  /// Die Knöpfe oben: W, M, J und Gesamt.
  static String zeitraum(StatZeitraum zeitraum) => switch (zeitraum) {
    StatZeitraum.woche => 'Woche',
    StatZeitraum.monat => 'Monat',
    StatZeitraum.jahr => 'Jahr',
    StatZeitraum.gesamt => 'Gesamt',
  };

  /// „82 %“ oder „–“, wenn nichts fällig war.
  static String prozent(StatQuote quote) {
    final p = quote.prozent;
    return p == null ? '–' : '$p %';
  }

  /// „4.200“ — mit Tausenderpunkt.
  static String zahl(int wert) {
    final roh = wert.abs().toString();
    final teile = <String>[];
    for (var ende = roh.length; ende > 0; ende -= 3) {
      teile.insert(0, roh.substring(ende - 3 < 0 ? 0 : ende - 3, ende));
    }
    return '${wert < 0 ? '−' : ''}${teile.join('.')}';
  }

  static String _zwei(int n) => n.toString().padLeft(2, '0');
}

/// Die Farben der Statistik: **Grün wie das Häkchen**, je kräftiger, je
/// mehr erledigt; Eis blau, Ruhetage grau. Eine Bedeutung, eine Farbe.
abstract final class StatFarbe {
  static const Color erledigt = Palette.success;
  static const Color leer = Palette.surfaceSunken;
  static const Color eis = Palette.tintEis;
  static const Color kette = Palette.gold;
  static Color get ruhetag => Palette.muted.withValues(alpha: 0.35);

  /// Die Farbe eines Tages im Raster, oder null für einen Tag, der noch
  /// kommt — der hat nur einen Rand.
  static Color? tag(StatTag tag) {
    if (tag.zukunft) return null;
    if (tag.eis) return eis;
    if (tag.ruhetag) return ruhetag;
    return quote(tag.quote);
  }

  /// Von blass bis kräftig grün nach der Quote; ohne Fälliges grau.
  static Color quote(StatQuote quote) {
    final anteil = quote.anteil;
    if (anteil == null) return ruhetag;
    if (anteil == 0) return leer;
    return Color.lerp(leer, erledigt, 0.3 + 0.7 * anteil)!;
  }
}
