import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../ui/pixel_art.dart';

/// Welches Bild zu einem Ausrüstungsstück gehört.
///
/// **Reine Darstellung.** Was ein Stück *tut*, steht in `package:gear`;
/// hier steht nur, wie es aussieht — dieselbe Trennung wie bei
/// [MoveIcons] für die Züge.
///
/// **Jedes der achtundvierzig Stücke hat eins** — seit dem 21.09. alle
/// aus dem Raven-Fantasy-Paket (64 × 64, Frederiks Download), damit Laden,
/// Charakter und Fähigkeiten einen Stil haben. Davor waren es vier gemalte
/// Waffen und achtzehn erzeugte Stücke; das Werkzeug dafür ist entfallen,
/// es hätte die Raven-Bilder beim nächsten Lauf überschrieben.
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
  /// Der Schlüssel zur Beute des Wächters (ADR-0048), Raven fc77.
  static const String schluessel = 'assets/Items/Schluessel.png';

  /// Item-Id → Pfad der Zeichnung.
  ///
  /// Nach Platz sortiert, innerhalb eines Platzes nach Seltenheit — so,
  /// wie der Katalog sie führt. Welche Nummer aus dem Raven-Paket hinter
  /// welcher Datei steht, hält `assets/RAVEN.md` fest.
  static const Map<String, String> _dateien = <String, String>{
    'gear-kurzbogen': 'assets/Waffen/Boegen/Kurzbogen.png',
    'gear-uebungsklinge': 'assets/Waffen/Schwerter/Uebungsklinge.png',
    'gear-streitkolben': 'assets/Waffen/Kolben/Streitkolben.png',
    'gear-geschliffene-klinge':
        'assets/Waffen/Schwerter/GeschliffeneKlinge.png',
    'gear-kriegsstab': 'assets/Waffen/Staebe/Kriegsstab.png',
    'gear-zweihaender': 'assets/Waffen/Schwerter/Zweihaender.png',
    'gear-langbogen': 'assets/Waffen/Boegen/Langbogen.png',
    'gear-sonnenklinge': 'assets/Waffen/Schwerter/Sonnenklinge.png',
    'gear-lederwams': 'assets/Ruestung/Lederwams.png',
    'gear-gestepptes-wams': 'assets/Ruestung/GesteppteWams.png',
    'gear-schuppenpanzer': 'assets/Ruestung/Schuppenpanzer.png',
    'gear-kettenpanzer': 'assets/Ruestung/Kettenpanzer.png',
    'gear-plattenharnisch': 'assets/Ruestung/Plattenharnisch.png',
    'gear-drachenschuppenpanzer': 'assets/Ruestung/Drachenschuppenpanzer.png',
    'gear-runenharnisch': 'assets/Ruestung/Runenharnisch.png',
    'gear-titanenpanzer': 'assets/Ruestung/Titanenpanzer.png',
    'gear-lederkappe': 'assets/Helme/Lederkappe.png',
    'gear-eisenhaube': 'assets/Helme/Eisenhaube.png',
    'gear-schuppenhaube': 'assets/Helme/Schuppenhaube.png',
    'gear-visierhelm': 'assets/Helme/Visierhelm.png',
    'gear-turnierhelm': 'assets/Helme/Turnierhelm.png',
    'gear-drachenhelm': 'assets/Helme/Drachenhelm.png',
    'gear-runenkrone': 'assets/Helme/Runenkrone.png',
    'gear-krone-des-hochwaechters': 'assets/Helme/KroneDesHochwaechters.png',
    'gear-feste-stiefel': 'assets/Schuhe/FesteStiefel.png',
    'gear-genagelte-stiefel': 'assets/Schuhe/GenagelteStiefel.png',
    'gear-schienbeinschutz': 'assets/Schuhe/Schienbeinschutz.png',
    'gear-stahlbeinlinge': 'assets/Schuhe/Stahlbeinlinge.png',
    'gear-schwere-schienen': 'assets/Schuhe/SchwereSchienen.png',
    'gear-windlaeufer': 'assets/Schuhe/Windlaeufer.png',
    'gear-drachenschuppenstiefel': 'assets/Schuhe/Drachenschuppenstiefel.png',
    'gear-stiefel-des-titanen': 'assets/Schuhe/StiefelDesTitanen.png',
    'gear-schlichter-ring': 'assets/Ringe/SchlichterRing.png',
    'gear-kupferring': 'assets/Ringe/Kupferring.png',
    'gear-taktring': 'assets/Ringe/Taktring.png',
    'gear-siegelring': 'assets/Ringe/Siegelring.png',
    'gear-aderring': 'assets/Ringe/Aderring.png',
    'gear-sternenring': 'assets/Ringe/Sternenring.png',
    'gear-ring-der-glut': 'assets/Ringe/RingDerGlut.png',
    'gear-ring-des-erzdaemons': 'assets/Ringe/RingDesErzdaemons.png',
    'gear-glasperle': 'assets/Talismane/Glasperle.png',
    'gear-flusskiesel': 'assets/Talismane/Flusskiesel.png',
    'gear-bernsteinamulett': 'assets/Talismane/Bernsteinamulett.png',
    'gear-silberamulett': 'assets/Talismane/Silberamulett.png',
    'gear-runenamulett': 'assets/Talismane/Runenamulett.png',
    'gear-phoenixfeder': 'assets/Talismane/Phoenixfeder.png',
    'gear-drachenzahn': 'assets/Talismane/Drachenzahn.png',
    'gear-herz-des-titanen': 'assets/Talismane/HerzDesTitanen.png',
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
  /// Vorgabe wie bei [MoveIcons].
  ///
  /// Die Zahlen standen hier dreimal, wortgleich. Seit `PixelArt` daraus
  /// eine Entscheidung ableitet — hart skalieren oder weich — darf es sie
  /// nur noch einmal geben.
  static const int artSize = PixelArt.artSize;
  static const int assetSize = PixelArt.assetSize;
}
