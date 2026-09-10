import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../ui/pixel_art.dart';

/// Welches Bild zu einem Ausrüstungsstück gehört.
///
/// **Reine Darstellung.** Was ein Stück *tut*, steht in `package:gear`;
/// hier steht nur, wie es aussieht — dieselbe Trennung wie bei
/// [MoveIcons] für die Züge.
///
/// **Vier von siebenundzwanzig Stücken haben eins**, alle vier sind
/// Waffen — es fehlt nur der Streitkolben. Die übrigen tragen weiter das
/// Zeichen ihres Platzes — sechs Zeichen für dreiundzwanzig Stücke, also
/// kein Ersatz für ein Bild, aber genug, um eine Kachel als Kachel
/// erkennbar zu machen.
///
/// **Ein Bild kommt in zwei Schritten dazu:**
///
/// 1. Datei unter `assets/` ablegen, auf 64 × 64 gezeichnet und als
///    [assetSize] Pixel abgelegt. Steht der Ordner noch nicht in
///    `pubspec.yaml`, kommt er dort dazu.
/// 2. Eine Zeile in [_dateien] ergänzen.
///
/// `test/gear_icon_test.dart` prüft danach von selbst mit, dass die Id im
/// Katalog existiert und die Datei wirklich geladen werden kann.
///
/// **Hier steht ein Pfad und kein Dateiname**, anders als bei
/// [MoveIcons]. Der Grund ist der Umweg, den ein Bild nimmt: Gezeichnet
/// wird eine *Klinge*, eingesetzt wird sie als *Übungsklinge*. Die
/// Zeichnungen liegen deshalb nach Art sortiert (`Waffen/Schwerter/`),
/// und welche davon welches Stück darstellt, entscheidet genau diese
/// Tabelle. Die Alternative — jede Datei auf ihre Item-Id umbenennen —
/// hätte die Ordnung zerstört, in der gezeichnet wird, und beim Malen
/// gibt es die Id noch gar nicht.
abstract final class GearIcons {
  /// Item-Id → Pfad der Zeichnung.
  ///
  /// **Vier Klingen liegen im Repo, zwei sind hier eingetragen.** Für
  /// `NormalesSchwert.png` und `RustedSword.png` gibt es noch kein
  /// passendes Stück: Von den fünf Waffen des Katalogs sind nur zwei
  /// Klingen, die drei anderen sind Bogen, Streitkolben und Stab. Sie
  /// einer davon zu geben hieße, im Laden etwas anderes zu zeigen, als
  /// man kauft.
  static const Map<String, String> _dateien = <String, String>{
    // Übungsklinge — die billigste Klinge, aus Holz. Die Zuordnung
    // ergibt sich aus dem Namen und nicht aus dem Preis.
    'gear-uebungsklinge': 'assets/Waffen/Schwerter/WoodenSword.png',

    // Geschliffene Klinge — die schmale, scharfe. Von den vier
    // Zeichnungen ist das Katana die einzige, der man das ansieht.
    'gear-geschliffene-klinge': 'assets/Waffen/Schwerter/Katana.png',

    // Kurzbogen — der einzige Bogen im Katalog.
    'gear-kurzbogen': 'assets/Waffen/Boegen/Kurzbogen.png',

    // Kriegsstab — gezeichnet als „Kampfstab", ein Schaft mit
    // Eisenspitze. Der einzige Stab im Katalog.
    'gear-kriegsstab': 'assets/Waffen/Staebe/Kampfstab.png',
  };

  /// Der Pfad zum Bild, oder `null` wenn es für dieses Stück keins gibt.
  static String? forItemId(String itemId) => _dateien[itemId];

  /// Alle Item-Ids, für die es ein Bild gibt.
  static Iterable<String> get itemIds => _dateien.keys;

  /// Das Ersatzzeichen für einen Platz, solange die Bilder fehlen.
  static IconData fallbackFor(GearSlot slot) {
    return switch (slot) {
      GearSlot.waffe => Icons.colorize,
      GearSlot.ruestung => Icons.shield_outlined,
      GearSlot.helm => Icons.sports_motorsports_outlined,
      GearSlot.schuhe => Icons.directions_walk,
      GearSlot.ring => Icons.circle_outlined,
      GearSlot.talisman => Icons.auto_awesome_outlined,
    };
  }

  /// **Gezeichnet auf 64 × 64, abgelegt als 256 × 256** — dieselbe
  /// Vorgabe wie bei [MoveIcons] und [EnemyIcons].
  ///
  /// Die Zahlen standen hier dreimal, wortgleich. Seit `PixelArt` daraus
  /// eine Entscheidung ableitet — hart skalieren oder weich — darf es sie
  /// nur noch einmal geben.
  static const int artSize = PixelArt.artSize;
  static const int assetSize = PixelArt.assetSize;
}
