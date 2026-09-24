import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../gear/gear_icon.dart';
import '../../ui/pixel_art.dart';

/// Das Bild der Truhe — dieselbe wie die Tagestruhe (Raven fc6).
const String beuteTruhe = 'assets/Items/Truhe.png';

/// Wie die Beute des Wächters aufgeht (ADR-0048).
///
/// Ein Schlüssel fliegt ins Schloss und dreht sich, die Truhe wackelt und
/// platzt auf, ein Leuchten in der Farbe der Seltenheit, und das Stück
/// springt heraus. Danach blenden [details] ein. Ohne Schlüssel — beim
/// ersten Sieg auf einer Stufe — springt die Truhe gleich auf.
///
/// **Läuft einmal und hält an.** Sonst käme `pumpAndSettle` in Tests nie
/// zur Ruhe, und ein Blatt, das ewig zappelt, liest sich schlecht.
class LootReveal extends StatefulWidget {
  const LootReveal({
    required this.item,
    required this.glow,
    required this.details,
    this.withKey = true,
    this.onBurst,
    super.key,
  });

  /// Das Bild des Stücks.
  final Widget item;

  /// Die Farbe der Seltenheit.
  final Color glow;

  /// Name, Seltenheit, Werte — sie blenden am Ende ein.
  final Widget details;

  final bool withKey;

  /// Im Moment, in dem die Truhe aufplatzt — für den Klang.
  final VoidCallback? onBurst;

  /// Wie lange das Ganze dauert, mit und ohne Schlüssel.
  static const Duration withKeyDuration = Duration(milliseconds: 1900);
  static const Duration withoutKeyDuration = Duration(milliseconds: 1100);

  @override
  State<LootReveal> createState() => _LootRevealState();
}

class _LootRevealState extends State<LootReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.withKey
        ? LootReveal.withKeyDuration
        : LootReveal.withoutKeyDuration,
  );
  bool _geplatzt = false;

  /// Wann die Truhe aufplatzt, als Anteil der Dauer.
  double get _burst => widget.withKey ? 0.55 : 0.25;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (!_geplatzt && _c.value >= _burst) {
        _geplatzt = true;
        widget.onBurst?.call();
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Wie weit [t] zwischen [von] und [bis] ist, 0 bis 1.
  static double _phase(double t, double von, double bis) =>
      ((t - von) / (bis - von)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final b = _burst;

        // Der Schlüssel: hereinfliegen, dann drehen, dann verblassen.
        final flug = Curves.easeOutCubic.transform(_phase(t, 0, b * 0.55));
        final dreh = Curves.easeInOut.transform(_phase(t, b * 0.55, b * 0.8));
        final schluesselWeg = _phase(t, b * 0.85, b);

        // Die Truhe: wackeln kurz vor dem Aufplatzen, dann weg.
        final wackeln = _phase(t, b * 0.7, b);
        final auf = _phase(t, b, b + 0.12);
        final versatz = math.sin(wackeln * math.pi * 8) * 4 * (1 - auf);

        // Das Leuchten und das Stück.
        final leuchten = _phase(t, b, b + 0.3);
        final stueck = Curves.elasticOut.transform(_phase(t, b, 0.95));
        final details = _phase(t, 0.8, 1);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 130,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: <Widget>[
                  // Ein Kreis in der Farbe der Seltenheit, der aufgeht und
                  // stehen bleibt — wie weit, sagt, wie selten.
                  if (leuchten > 0)
                    Opacity(
                      opacity: (1 - leuchten * 0.5).clamp(0.0, 1.0),
                      child: Container(
                        width: 40 + 110 * leuchten,
                        height: 40 + 110 * leuchten,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: <Color>[
                              widget.glow.withValues(alpha: 0.8),
                              widget.glow.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (auf < 1)
                    Transform.translate(
                      offset: Offset(versatz, 0),
                      child: Opacity(
                        opacity: 1 - auf,
                        child: Transform.scale(
                          scale: 1 + auf * 0.4,
                          child: const PixelArt(
                            assetPath: beuteTruhe,
                            side: 76,
                            fallback: Icon(Icons.inventory_2, size: 60),
                          ),
                        ),
                      ),
                    ),
                  if (widget.withKey && schluesselWeg < 1)
                    Transform.translate(
                      // Von links oben ins Schloss vorn an der Truhe.
                      offset: Offset(-95 * (1 - flug), -45 * (1 - flug) + 8),
                      child: Transform.rotate(
                        angle: -math.pi / 4 + dreh * math.pi / 2,
                        child: Opacity(
                          opacity: 1 - schluesselWeg,
                          child: const PixelArt(
                            assetPath: GearIcons.schluessel,
                            side: 40,
                            fallback: Icon(Icons.key, size: 32),
                          ),
                        ),
                      ),
                    ),
                  if (stueck > 0)
                    Transform.translate(
                      offset: Offset(0, 24 * (1 - stueck)),
                      child: Transform.scale(
                        scale: 0.3 + 0.7 * stueck,
                        child: widget.item,
                      ),
                    ),
                ],
              ),
            ),
            Opacity(opacity: details, child: widget.details),
          ],
        );
      },
    );
  }
}
