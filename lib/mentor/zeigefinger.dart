import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/erster_start.dart';
import '../home/erster_start_provider.dart';
import '../ui/palette.dart';

/// Ein Ring um das, worauf der Mentor gerade zeigt (ADR-0079).
///
/// Er steht nur da, solange der erste Start bei [schritt] ist und
/// [aktiv] gilt — etwa nur um die eine Fähigkeit, die gerade gelernt
/// ist. Der Ring nimmt keinen Tipp an: Getippt wird auf das Ziel selbst.
class Zeigefinger extends ConsumerWidget {
  const Zeigefinger({
    required this.schritt,
    required this.child,
    this.aktiv = true,
    this.radius = 14,
    super.key,
  });

  final Schritt schritt;
  final Widget child;
  final bool aktiv;

  /// Die Rundung des Rings — so rund wie das Ziel.
  final double radius;

  static const Key ringKey = ValueKey<String>('zeigefinger');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zeigt = aktiv && ref.watch(ersterStartProvider).schritt == schritt;
    // **Der Ring bleibt stehen und blendet nur aus.** Fiele er weg, stünde
    // das Ziel an einer anderen Stelle im Baum und baute sich neu — samt
    // allem, was darin gerade aufspringt: Nach dem ersten Häkchen lag der
    // Stempel auf „Heute“ sofort da, statt aufzuschlagen (`gotchas.md`).
    return ZeigeRing(sichtbar: zeigt, radius: radius, child: child);
  }
}

/// Der Ring selbst, ohne zu fragen, ob er dran ist — für Stellen, die
/// das selbst wissen, wie der Beute-Dialog des ersten Siegs.
class ZeigeRing extends StatefulWidget {
  const ZeigeRing({
    required this.child,
    this.radius = 14,
    this.sichtbar = true,
    super.key,
  });

  final Widget child;
  final double radius;

  /// Ob der Ring gerade steht. Aus heißt: nur das Ziel, wie ohne Ring.
  final bool sichtbar;

  /// Wie weit der Ring um das Ziel herum liegt.
  static const double abstand = 5;

  /// So oft pulsiert er, dann steht er still und leuchtet weiter.
  /// **Endlich mit Absicht**: Eine Bewegung ohne Ende liesse
  /// `pumpAndSettle` nie zur Ruhe kommen (`gotchas.md`).
  static const int pulse = 5;

  static const Duration takt = Duration(milliseconds: 650);

  @override
  State<ZeigeRing> createState() => _ZeigeRingState();
}

class _ZeigeRingState extends State<ZeigeRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _takt;
  bool _gepulst = false;

  @override
  void initState() {
    super.initState();
    // In `initState`, nicht faul: Ein `late final` mit Startwert entstünde
    // sonst womöglich erst im `dispose` (`gotchas.md`).
    _takt = AnimationController(vsync: this, duration: ZeigeRing.takt);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.sichtbar) _pulsiere();
  }

  @override
  void didUpdateWidget(ZeigeRing alt) {
    super.didUpdateWidget(alt);
    if (widget.sichtbar && !alt.sichtbar) _pulsiere();
  }

  void _pulsiere() {
    final ruhig = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (ruhig) {
      _takt.value = 1;
    } else if (!_gepulst) {
      _gepulst = true;
      _takt.repeat(reverse: true, count: ZeigeRing.pulse * 2);
    }
  }

  @override
  void dispose() {
    _takt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const abstand = ZeigeRing.abstand;
    return Stack(
      // Das Ziel bekommt dieselben Maße, als stünde kein Ring um es —
      // sonst schrumpfte eine Kachel im Raster auf ihren Inhalt.
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: <Widget>[
        widget.child,
        if (widget.sichtbar)
          Positioned(
            left: -abstand,
            top: -abstand,
            right: -abstand,
            bottom: -abstand,
            child: IgnorePointer(
              child: AnimatedBuilder(
                key: Zeigefinger.ringKey,
                animation: _takt,
                builder: (context, _) {
                  final t = Curves.easeInOut.transform(_takt.value);
                  // Nie ganz weg: Auch zwischen zwei Pulsen und nach dem
                  // letzten steht der Ring halb da.
                  final hell = 0.55 + 0.45 * t;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        widget.radius + abstand,
                      ),
                      border: Border.all(
                        color: Palette.goldOnDark.withValues(alpha: hell),
                        width: 3,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Palette.goldOnDark.withValues(alpha: 0.45 * t),
                          blurRadius: 14 * t,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
