import 'package:flutter/material.dart';

import 'pixel_art.dart';

/// **Die Kette** (19.11.2026): zwei Glieder aus Stahl, senkrecht
/// ineinander — das Zeichen für gekoppelte Gewohnheiten (ADR-0065), in
/// den Chips, an denen man koppelt. Zwischen den Karten hängt
/// `SchildKette`.
/// Gezeichnet in `tool/pixel/kette.px.js`.
class KettenZeichen extends StatelessWidget {
  const KettenZeichen({this.side = 18, super.key});

  static const String pfad = 'assets/UI/Kette.png';

  final double side;

  @override
  Widget build(BuildContext context) {
    return PixelArt(
      assetPath: pfad,
      side: side,
      fallback: Icon(Icons.link_rounded, size: side),
    );
  }
}
