import 'package:flutter/material.dart';

import 'pixel_art.dart';

/// **Die Kette** (19.11.2026): zwei Glieder aus Stahl, senkrecht
/// ineinander — das Zeichen für gekoppelte Gewohnheiten (ADR-0065).
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

/// **Die Kette statt der Einrückung** (19.11.2026, Frederik): Eine
/// gekoppelte Gewohnheit steht bündig unter der darüber, und eine Kette
/// hängt über die Lücke zwischen beiden. Nimmt keinen Tipp an.
class AnDerKette extends StatelessWidget {
  const AnDerKette({
    required this.gekoppelt,
    required this.child,
    this.links = 6,
    this.groesse = 30,
    super.key,
  });

  /// Woran Tests die Kette über einer Gewohnheit finden.
  static const Key kettenKey = ValueKey<String>('an-der-kette');

  final bool gekoppelt;
  final Widget child;

  /// Wie weit vom linken Rand die Kette hängt.
  final double links;

  /// Wie hoch das Bild der Kette ist; die Hälfte ragt nach oben.
  final double groesse;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: <Widget>[
        child,
        if (gekoppelt)
          Positioned(
            key: kettenKey,
            left: links,
            top: -groesse / 2,
            child: IgnorePointer(
              child: ExcludeSemantics(child: KettenZeichen(side: groesse)),
            ),
          ),
      ],
    );
  }
}
