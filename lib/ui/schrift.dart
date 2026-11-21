import 'dart:ui' show FontFeature;

/// **Die Schrift der App** (21.11.2026, Frederik): Alegreya Sans für
/// alles außer dem Lernbuch (`BuchStil`) und den Titeln (`MenueLeiste`).
///
/// Das Theme setzt sie für jedes `Text`. Wer mit einem eigenen
/// `TextPainter` malt, erreicht das Theme nicht und nennt sie selbst
/// (`gotchas.md`).
abstract final class Schrift {
  static const String app = 'AlegreyaSans';

  /// **Ziffern in Versalhöhe** (21.11.2026, Frederik: „mach die kleinen
  /// Zahlen etwas größer“). Alegreya Sans setzt von sich aus
  /// Mediävalziffern: so hoch wie ein „x“, die 3, 5 und 9 hängen unter
  /// die Linie. Neben Großbuchstaben und Zeichen wirkten Preise, Level und
  /// Zähler damit eine Nummer kleiner. `lnum` macht jede Ziffer so hoch
  /// wie ein „A“ — rund 40 % größer, ohne eine Schriftgröße zu ändern.
  ///
  /// Das Theme legt sie auf jeden Stil. **Wer `fontFeatures` selbst
  /// setzt, ersetzt die Liste** und nimmt dafür [tabelle] oder hängt
  /// [ziffern] an.
  static const List<FontFeature> ziffern = <FontFeature>[
    FontFeature.liningFigures(),
  ];

  /// Ziffern in Versalhöhe **und** gleich breit — für Zahlen, die
  /// laufen (Timer, Zähler), damit nichts springt.
  static const List<FontFeature> tabelle = <FontFeature>[
    FontFeature.liningFigures(),
    FontFeature.tabularFigures(),
  ];
}
