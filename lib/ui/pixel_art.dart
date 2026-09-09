import 'package:flutter/material.dart';

/// Eine gezeichnete Fläche fester Größe — und die Entscheidung, wie sie
/// skaliert wird.
///
/// **Der Grund, warum es dieses Widget gibt, ist eine Zahl.** Alles in
/// diesem Projekt wird auf [artSize] Bildpunkten gezeichnet und als
/// [assetSize] abgelegt. Eine Kachel im Kampf ist rund 88 Punkte breit —
/// dort steht jeder gezeichnete Bildpunkt auf mehreren echten, und
/// [FilterQuality.none] ist richtig: hart skalieren, nicht weichzeichnen.
///
/// **Unterhalb der Zeichengröße kippt das ins Gegenteil.** Eine Münze mit
/// 18 Punkten Kantenlänge zeigt 64 gezeichnete Bildpunkte auf 18 echten;
/// mit `none` fällt dabei jeder dritte einfach weg, und übrig bleibt kein
/// kleineres Bild, sondern ein zerfressenes. `move_icon.dart` benennt
/// genau diesen Fall seit dem 27.08. als den schlimmeren — er stand nur
/// nirgends im Code.
///
/// Die Grenze ist deshalb [artSize] und nicht [assetSize]: Solange jedem
/// gezeichneten Bildpunkt mindestens ein echter bleibt, geht keiner
/// verloren, und das Bild darf hart bleiben.
class PixelArt extends StatelessWidget {
  const PixelArt({
    required this.assetPath,
    required this.side,
    required this.fallback,
    super.key,
  });

  final String assetPath;

  /// Kantenlänge in logischen Punkten. Alles Gezeichnete ist quadratisch.
  final double side;

  /// Was an die Stelle tritt, wenn die Datei fehlt.
  ///
  /// **Kein Beiwerk.** `Image.asset` auf eine fehlende Datei wirft, und
  /// die Bilder dieses Projekts sind schon einmal wieder aus dem Repo
  /// geflogen (Sitzung 27.08.). Ein Bildschirm, der wegen einer Zeichnung
  /// nicht erscheint, wäre der teuerste denkbare Preis dafür.
  final Widget fallback;

  /// **Gezeichnet auf 64 × 64, abgelegt als 256 × 256.** Ein Format für
  /// das ganze Projekt — `MoveIcons`, `GearIcons` und `EnemyIcons` lesen
  /// beide Zahlen hier.
  static const int artSize = 64;
  static const int assetSize = 256;

  /// Wie ein Bild mit [side] Punkten Kantenlänge bei [devicePixelRatio]
  /// skaliert werden soll.
  ///
  /// Reine Funktion, damit die Regel prüfbar ist, ohne ein Bild zu laden.
  static FilterQuality qualityFor(double side, double devicePixelRatio) {
    final echtePixel = side * devicePixelRatio;
    return echtePixel >= artSize ? FilterQuality.none : FilterQuality.medium;
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: side,
      height: side,
      filterQuality: qualityFor(side, MediaQuery.devicePixelRatioOf(context)),
      errorBuilder: (context, error, stack) => fallback,
    );
  }
}
