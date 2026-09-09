import 'package:flutter/material.dart';

import 'palette.dart';
import 'pixel_art.dart';

/// Die Goldmünze als Zeichen.
///
/// **Ein eigenes Widget, weil Gold an vier Stellen steht** — unter der
/// Figur, im Kopf des Ladens, auf jeder Item-Kachel und im Kampfergebnis.
/// Die Münze dort viermal einzusetzen hieße, viermal an
/// [FilterQuality.none] und an den Rückfall zu denken; hier steht beides
/// einmal.
///
/// **Sie ist zugleich der Fall, für den [PixelArt] gebaut wurde.** Mit 18
/// Punkten Kantenlänge ist die Münze deutlich kleiner als die 64
/// Bildpunkte, auf denen sie gezeichnet ist — hart skaliert wäre sie
/// nicht kleiner, sondern zerfressen.
class GoldIcon extends StatelessWidget {
  const GoldIcon({this.size = 18, super.key});

  /// Kantenlänge. Die Münze ist quadratisch, wie alles in diesem Projekt
  /// Gezeichnete.
  final double size;

  static const String assetPath = 'assets/Items/Gold.png';

  @override
  Widget build(BuildContext context) {
    return PixelArt(
      assetPath: assetPath,
      side: size,
      fallback: Icon(Icons.savings_outlined, size: size, color: Palette.gold),
    );
  }
}
