import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../../ui/druck.dart';
import '../../ui/gehrung.dart';
import '../../ui/gold_icon.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';
import '../gear_icon.dart';
import 'rarity_badge.dart';

/// **Ein Fach im Tresen des Händlers** (AktivesBrett, 21.11.2026): im
/// dunklen Inneren das Stück und sein Name, darunter der Preis.
///
/// Der Rahmen ist **derselbe Holzrahmen wie überall** (`GehrungsMaler`,
/// AktivesBrett, 22.11.2026), gemalt für die Größe, die der Tresen dem
/// Fach gibt. Der Rand der Seltenheit ist hier etwas dicker als sonst
/// ([seltenheitsRand]).
class LadenFach extends StatelessWidget {
  const LadenFach({
    required this.angebot,
    required this.block,
    required this.gewaehlt,
    required this.gesammelt,
    required this.onTap,
    super.key,
  });

  final GearCopy angebot;

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

  /// Wie dick der Rand der Seltenheit im Laden ist — dicker als sonst
  /// (`RarityBadge.rahmenBreite`), damit man sie im Tresen erkennt.
  static const double seltenheitsRand = 3;

  /// Das dunkle Innere eines Fachs.
  static const Color innenFarbe = Color(0xFF241811);

  bool get isOutOfReach =>
      block == PurchaseBlock.gesperrt || block == PurchaseBlock.zuWenigGold;

  @override
  Widget build(BuildContext context) {
    final item = angebot.item;
    if (item == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) =>
          _fach(item, Offset.zero & constraints.biggest),
    );
  }

  Widget _fach(GearItem item, Rect r) {
    // Innerhalb des Holzes: oben das Stück im Rand seiner Seltenheit,
    // darunter der Preis.
    final holz = r.deflate(GehrungsMaler.breite + 3);
    final preisHoehe = math.min(20.0, holz.height * 0.18);
    final innen = Rect.fromLTRB(
      holz.left,
      holz.top,
      holz.right,
      holz.bottom - preisHoehe - 2,
    );
    final planke = Rect.fromLTRB(
      holz.left,
      holz.bottom - preisHoehe,
      holz.right,
      holz.bottom,
    );
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
              // Derselbe Holzrahmen wie überall, innen dunkel.
              const Positioned.fill(
                child: CustomPaint(painter: GehrungsMaler(mitte: innenFarbe)),
              ),
              // Im Inneren: der Rand der Seltenheit, das Stück, der Name.
              Positioned.fromRect(
                rect: innen,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: RarityBadge.rahmenOf(item.rarity),
                      width: seltenheitsRand,
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
                            fontSize: 13,
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
              // Darunter der Preis — oder ein Haken, wenn gekauft.
              Positioned.fromRect(
                rect: planke,
                child: Center(child: _preis(gekauft, blass, planke.height)),
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

  /// Der Preis passt in seine Zeile: Schrift und Münze richten sich nach
  /// ihrer Höhe, nicht umgekehrt.
  Widget _preis(bool gekauft, double blass, double hoehe) {
    final groesse = (hoehe * 0.95).clamp(9.0, 15.0);
    if (gekauft) {
      return Icon(
        Icons.check_circle,
        size: groesse,
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
            Icon(Icons.lock, size: groesse, color: Palette.textOnDark),
            const SizedBox(width: 3),
          ],
          GoldIcon(size: groesse),
          const SizedBox(width: 4),
          Text(
            '${angebot.paid}',
            style: TextStyle(
              fontSize: groesse,
              height: 1,
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
