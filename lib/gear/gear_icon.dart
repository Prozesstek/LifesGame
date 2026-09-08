import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

/// Welches Bild zu einem Ausrüstungsstück gehört.
///
/// **Reine Darstellung.** Was ein Stück *tut*, steht in `package:gear`;
/// hier steht nur, wie es aussieht — dieselbe Trennung wie bei
/// [MoveIcons] für die Züge.
///
/// **Derzeit hat kein Stück ein Bild.** Issue #35 führt „Items" unter den
/// Designs auf, die noch entstehen müssen. Bis dahin trägt die Kachel das
/// Zeichen ihres Platzes — sechs Zeichen für siebenundzwanzig Stücke,
/// also kein Ersatz für ein Bild, aber genug, um eine Kachel als Kachel
/// erkennbar zu machen.
///
/// **Ein Bild kommt in zwei Schritten dazu:**
///
/// 1. Datei nach `assets/gear/` legen, benannt wie die Item-Id, in
///    [assetSize] Pixel Kantenlänge. Den Ordner in `pubspec.yaml`
///    eintragen — `assets/character/` steht dort als Vorbild.
/// 2. Eine Zeile in [_dateien] ergänzen.
///
/// `test/gear_icon_test.dart` prüft danach von selbst mit, dass die Id im
/// Katalog existiert und die Datei wirklich geladen werden kann.
abstract final class GearIcons {
  static const String _ordner = 'assets/gear';

  /// Item-Id → Dateiname. Leer, solange es keine Bilder gibt.
  ///
  /// **Die Datei heißt wie die Id.** Damit kann die Zuordnung nicht
  /// auseinanderlaufen.
  static const Map<String, String> _dateien = <String, String>{};

  /// Der Pfad zum Bild, oder `null` wenn es für dieses Stück keins gibt.
  static String? forItemId(String itemId) {
    final datei = _dateien[itemId];
    return datei == null ? null : '$_ordner/$datei';
  }

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
  /// Vorgabe wie bei [MoveIcons] und [EnemyIcons]. Ein Format fuer das
  /// ganze Projekt.
  static const int artSize = 64;
  static const int assetSize = 256;
}
