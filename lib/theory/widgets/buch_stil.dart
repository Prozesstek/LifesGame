import 'package:flutter/material.dart';

import '../../ui/palette.dart';

/// **Wie das Lernbuch aussieht — eine Stelle** (12.11.2026).
///
/// Farben, Schriften, Größen und Ränder der Buchseite stehen hier, nicht
/// in den Widgets. Wer die Seite anders haben will, dreht hier.
///
/// Die **Akzentfarbe** (Initiale, Balken der Kästen) ist die des Gebiets
/// (`SeitenFarbe`, ADR-0090) — unter Körper das Rostrot.
abstract final class BuchStil {
  // ---- Farben ----

  /// Die Tinte: dunkles Sepia statt Schwarz.
  static const Color tinte = Color(0xFF3A2614);

  /// Gedämpfte Tinte: Kolumnentitel, Seitenzahl, Bildunterschrift, Zier.
  static const Color tinteBlass = Color(0xFF85694A);

  /// Der Grund eines Kastens — etwas dunkleres Papier.
  static const Color kastenGrund = Color(0xFFEAD9B2);

  /// Sein dünner Rahmen.
  static const Color kastenRand = Color(0xFFB8996A);

  /// Die Seite unter einem Eselsohr und die Rückseite des Knicks.
  static const Color papierDarunter = Color(0xFFE4D1A6);
  static const Color papierRueckseite = Color(0xFFDCC69A);

  /// Der Bundschatten an der Bindung.
  static const Color bund = Palette.einbandDunkel;

  // ---- Schriften ----

  static const String fliessSchrift = 'Lora';
  static const String titelSchrift = 'CormorantGaramond';

  /// Fallbacks, falls eine Schrift fehlt.
  static const List<String> serifen = <String>['Georgia', 'serif'];

  /// Die Schriften sind variabel; das Gewicht kommt über die Achse.
  static List<FontVariation> gewicht(double wght) => <FontVariation>[
    FontVariation('wght', wght),
  ];

  // ---- Größen ----

  static const double fliessGroesse = 17;
  static const double zeilenHoehe = 1.55;
  static const double titelGroesse = 28;
  static const double kolumnenGroesse = 11.5;
  static const double labelGroesse = 11.5;
  static const double seitenzahlGroesse = 14;
  static const double unterschriftGroesse = 14.5;

  /// Die Initiale reicht über so viele Zeilen.
  static const int initialeZeilen = 3;

  /// Ihre Schriftgröße, gemessen an Cormorant: Die Versalhöhe reicht von
  /// der Oberkante der ersten bis auf die Grundlinie der dritten Zeile.
  static const double initialeGroesse = 92;

  /// So weit läuft der Text rechts neben der Initiale.
  static const double initialeAbstand = 6;

  // ---- Ränder der Seite ----

  /// Innen (an der Bindung) schmaler als außen und unten.
  static const double randInnen = 22;
  static const double randAussen = 26;
  static const double randOben = 16;
  static const double randUnten = 10;

  /// Abstand zwischen Absätzen.
  static const double absatz = 12;

  /// Der Bundschatten läuft nach diesem Anteil der Seitenbreite aus.
  static const double bundAnteil = 0.13;

  // ---- Stile ----

  static const TextStyle fliess = TextStyle(
    fontFamily: fliessSchrift,
    fontFamilyFallback: serifen,
    fontSize: fliessGroesse,
    height: zeilenHoehe,
    color: tinte,
    fontVariations: <FontVariation>[FontVariation('wght', 400)],
  );

  static TextStyle get titel => TextStyle(
    fontFamily: titelSchrift,
    fontFamilyFallback: serifen,
    fontSize: titelGroesse,
    height: 1.15,
    color: tinte,
    fontVariations: gewicht(600),
  );

  static TextStyle get kolumnentitel => TextStyle(
    fontFamily: fliessSchrift,
    fontFamilyFallback: serifen,
    fontSize: kolumnenGroesse,
    letterSpacing: 1.8,
    color: tinteBlass,
    fontVariations: gewicht(500),
  );

  static TextStyle get label => TextStyle(
    fontFamily: fliessSchrift,
    fontFamilyFallback: serifen,
    fontSize: labelGroesse,
    letterSpacing: 1.6,
    fontVariations: gewicht(600),
  );

  static const TextStyle seitenzahl = TextStyle(
    fontFamily: fliessSchrift,
    fontFamilyFallback: serifen,
    fontSize: seitenzahlGroesse,
    color: tinteBlass,
  );

  static const TextStyle unterschrift = TextStyle(
    fontFamily: fliessSchrift,
    fontFamilyFallback: serifen,
    fontSize: unterschriftGroesse,
    height: 1.4,
    fontStyle: FontStyle.italic,
    color: tinteBlass,
  );

  static TextStyle get initiale => TextStyle(
    fontFamily: titelSchrift,
    fontFamilyFallback: serifen,
    fontSize: initialeGroesse,
    height: 1,
    fontVariations: gewicht(600),
  );

  /// Das Zierelement: ein Fleuron aus Cormorant.
  static const String zier = '❦';
  static TextStyle get zierStil => TextStyle(
    fontFamily: titelSchrift,
    fontFamilyFallback: serifen,
    fontSize: 22,
    height: 1,
    color: tinteBlass,
  );
}
