import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../../ui/druck.dart';
import '../../ui/gold_icon.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';
import '../gear_icon.dart';
import 'laden_bild.dart';
import 'rarity_badge.dart';

/// **Ein Fach im Tresen des Händlers** (AktivesBrett, 21.11.2026): im
/// dunklen Inneren das Stück und sein Name, auf der Planke der Preis.
///
/// Rahmen, Inneres und Planke sind gemalt (`LadenBild`); das Fach legt
/// nur darüber, was sich ändert. [skala] rechnet Bildpunkte in Punkte.
class LadenFach extends StatelessWidget {
  const LadenFach({
    required this.angebot,
    required this.bild,
    required this.skala,
    required this.block,
    required this.gewaehlt,
    required this.gesammelt,
    required this.onTap,
    super.key,
  });

  final GearCopy angebot;
  final LadenFachBild bild;
  final double skala;

  /// Ob es sich kaufen lässt — dieselbe Antwort wie auf der Tafel.
  final PurchaseBlock? block;

  /// Ob es gerade auf der Tafel steht: dann weiße Winkel um den Rahmen.
  final bool gewaehlt;

  /// Ob man das Stück schon einmal hatte (die Sammlung, ADR-0080).
  final bool gesammelt;
  final VoidCallback onTap;

  /// Das Zeichen der Sammlung, damit Tests es finden.
  static const Key gesammeltKey = ValueKey<String>('schon-gesammelt');

  /// Wie blass ein Stück steht, das man nicht kaufen kann.
  static const double ausserReichweite = 0.4;

  bool get isOutOfReach =>
      block == PurchaseBlock.gesperrt || block == PurchaseBlock.zuWenigGold;

  @override
  Widget build(BuildContext context) {
    final item = angebot.item;
    if (item == null) return const SizedBox.shrink();
    final rahmen = _skaliert(bild.rahmen);
    final innen = _skaliert(bild.innen).shift(-rahmen.topLeft);
    final planke = _skaliert(bild.planke).shift(-rahmen.topLeft);
    final pfad = GearIcons.forItemId(item.id);
    final seite = (innen.shortestSide * 0.62).floorToDouble();
    final blass = isOutOfReach ? ausserReichweite : 1.0;
    final gekauft = block == PurchaseBlock.bereitsGekauft;

    return Semantics(
      button: true,
      selected: gewaehlt,
      label: item.name,
      child: Druck(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              // Im Inneren: der Rand der Seltenheit, das Stück, der Name.
              Positioned.fromRect(
                rect: innen,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: RarityBadge.rahmenOf(
                        item.rarity,
                      ).withValues(alpha: 0.85),
                      width: RarityBadge.rahmenBreite,
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: Center(
                          child: Opacity(
                            opacity: gekauft ? 0.5 : blass,
                            child: pfad != null
                                ? PixelArt(
                                    assetPath: pfad,
                                    side: seite,
                                    fallback: _ersatz(item, seite),
                                  )
                                : _ersatz(item, seite),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: RarityBadge.colorOnDarkOf(item.rarity),
                            shadows: _schatten,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Auf der Planke: der Preis — oder ein Haken, wenn gekauft.
              Positioned.fromRect(
                rect: planke,
                child: Center(child: _preis(gekauft, blass)),
              ),
              if (gesammelt)
                const Positioned(
                  left: 2,
                  top: 2,
                  child: Icon(
                    Icons.collections_bookmark,
                    key: gesammeltKey,
                    size: 14,
                    color: Palette.goldOnDark,
                  ),
                ),
              if (gewaehlt)
                const Positioned.fill(
                  child: IgnorePointer(child: CustomPaint(painter: _Winkel())),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preis(bool gekauft, double blass) {
    if (gekauft) {
      return const Icon(
        Icons.check_circle,
        size: 18,
        color: Palette.textOnDarkDim,
        semanticLabel: 'gekauft',
      );
    }
    return Opacity(
      opacity: blass,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (block == PurchaseBlock.gesperrt) ...<Widget>[
            const Icon(Icons.lock, size: 13, color: Palette.textOnDark),
            const SizedBox(width: 3),
          ],
          const GoldIcon(size: 15),
          const SizedBox(width: 4),
          Text(
            '${angebot.paid}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Palette.textOnDark,
              shadows: _schatten,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _ersatz(GearItem item, double seite) => Icon(
    GearIcons.fallbackFor(item.slot),
    size: seite,
    color: Palette.textOnDark,
  );

  Rect _skaliert(Rect r) => Rect.fromLTRB(
    r.left * skala,
    r.top * skala,
    r.right * skala,
    r.bottom * skala,
  );

  static const List<Shadow> _schatten = <Shadow>[
    Shadow(color: Color(0xCC1A1016), offset: Offset(1, 1), blurRadius: 1),
  ];
}

/// Vier weiße Winkel an den Ecken des Rahmens: Dieses Fach steht auf der
/// Tafel.
class _Winkel extends CustomPainter {
  const _Winkel();

  @override
  void paint(Canvas canvas, Size size) {
    final lang = size.shortestSide * 0.16;
    final stift = Paint()
      ..color = const Color(0xFFF4EFE6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final r = Offset.zero & size;
    for (final (ecke, dx, dy) in <(Offset, double, double)>[
      (r.topLeft, 1, 1),
      (r.topRight, -1, 1),
      (r.bottomLeft, 1, -1),
      (r.bottomRight, -1, -1),
    ]) {
      canvas
        ..drawLine(ecke, ecke + Offset(lang * dx, 0), stift)
        ..drawLine(ecke, ecke + Offset(0, lang * dy), stift);
    }
  }

  @override
  bool shouldRepaint(_Winkel oldDelegate) => false;
}
