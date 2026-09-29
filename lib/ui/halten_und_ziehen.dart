/// Halten und Ziehen, wie beim Deckbau in Clash Royale (ADR-0057).
///
/// **Eine Stelle für Ausrüstung und Fähigkeiten.** Beide Bildschirme
/// ziehen ein Stück aus dem Raster auf einen Platz oben. Wie sich das
/// anfühlt (Haltezeit, das Bild unter dem Finger, welcher Platz leuchtet
/// und welcher zurücktritt), soll an beiden Stellen gleich sein. Stünde
/// es zweimal da, fühlte es sich irgendwann zweimal verschieden an.
library;

import 'package:flutter/material.dart';

import 'palette.dart';

/// Wie ein Platz gerade zum gezogenen Stück steht.
///
/// **Beim Ziehen soll man sehen, wohin es gehört**, bevor man loslässt.
/// Der passende Platz leuchtet, die anderen treten zurück.
enum SlotDragState {
  /// Es wird nichts gezogen.
  ruhig,

  /// Das gezogene Stück passt auf diesen Platz.
  passt,

  /// Und es schwebt gerade darüber: Loslassen legt es an.
  darueber,

  /// Das gezogene Stück passt hier nicht.
  passtNicht;

  /// Die Randfarbe, oder [normal], solange nichts Besonderes ist.
  Color randFarbe(Color normal) => switch (this) {
    darueber => Palette.success,
    passt => Palette.accent,
    _ => normal,
  };

  /// Die Randbreite, oder [normal].
  double randBreite(double normal) => switch (this) {
    darueber => 3,
    passt => 2.5,
    _ => normal,
  };

  /// Welcher Zustand für einen Platz gilt, wenn etwas gezogen wird
  /// ([zieht]), ob es auf diesen Platz passt ([passt]), und ob es gerade
  /// darüber schwebt ([schwebt]).
  static SlotDragState fuer({
    required bool zieht,
    required bool passt,
    required bool schwebt,
  }) {
    if (!zieht) return ruhig;
    if (!passt) return passtNicht;
    return schwebt ? darueber : SlotDragState.passt;
  }
}

/// Ein Platz während des Ziehens: Der passende wird etwas größer, die
/// übrigen treten zurück.
class PlatzBeimZiehen extends StatelessWidget {
  const PlatzBeimZiehen({
    required this.zustand,
    required this.child,
    super.key,
  });

  final SlotDragState zustand;
  final Widget child;

  static const Duration _dauer = Duration(milliseconds: 120);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: _dauer,
      opacity: zustand == SlotDragState.passtNicht ? 0.35 : 1,
      child: AnimatedScale(
        duration: _dauer,
        scale: switch (zustand) {
          SlotDragState.darueber => 1.08,
          SlotDragState.passt => 1.04,
          _ => 1,
        },
        child: child,
      ),
    );
  }
}

/// Eine Kachel, die sich nach kurzem Halten ziehen lässt.
///
/// **Halten, nicht sofort ziehen**, damit Rollen und Antippen bleiben,
/// wie sie waren. Beim Start gibt das Handy einen kurzen Stoß, und unter
/// dem Finger hängt [bild], etwas größer als auf der Kachel und mittig
/// unter dem Finger statt an seiner Ecke.
///
/// [aktiv] false: Die Kachel lässt sich nicht ziehen und bleibt, was sie
/// ist. So bleibt der Baum gleich, egal ob etwas zu ziehen ist.
class HaltenUndZiehen<T extends Object> extends StatelessWidget {
  const HaltenUndZiehen({
    required this.data,
    required this.aktiv,
    required this.bild,
    required this.rahmenFarbe,
    required this.onStart,
    required this.onEnde,
    required this.child,
    super.key,
  });

  final T data;
  final bool aktiv;

  /// Was unter dem Finger hängt, ohne Rahmen. Den Rahmen setzt dieses
  /// Widget.
  final Widget bild;

  /// Die Farbe des Rahmens um [bild], meist die der Seltenheit.
  final Color rahmenFarbe;

  final VoidCallback onStart;

  /// Ein Ende gibt es auf drei Wegen (abgelegt, zurückgeflogen,
  /// abgebrochen), und alle drei landen hier.
  final VoidCallback onEnde;

  final Widget child;

  /// Wie groß das Stück unter dem Finger hängt.
  static const double schwebeSeite = 64;

  @override
  Widget build(BuildContext context) {
    if (!aktiv) return child;

    return LongPressDraggable<T>(
      data: data,
      onDragStarted: onStart,
      onDragEnd: (_) => onEnde(),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Transform.translate(
        offset: const Offset(-schwebeSeite / 2, -schwebeSeite / 2),
        child: Container(
          width: schwebeSeite,
          height: schwebeSeite,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: rahmenFarbe, width: 2),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Center(child: bild),
        ),
      ),
      child: child,
    );
  }
}

/// Rollt [scroll] ganz nach oben, zu den Plätzen, wenn es nicht schon
/// dort ist.
///
/// **Wer zieht, wird nach oben gebracht**: Die Plätze stehen ganz oben,
/// das Stück meist weiter unten. Ohne das müsste man mit dem Finger auf
/// dem Stück gleichzeitig rollen.
void zuDenPlaetzen(ScrollController scroll) {
  if (!scroll.hasClients || scroll.offset <= 0) return;
  scroll.animateTo(
    0,
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutCubic,
  );
}

/// Ein leerer Platz, der etwas aufnehmen könnte, leuchtet sanft auf.
///
/// **Statt des Satzes „halten und hierher ziehen“.** Die App soll ohne
/// Lesen gehen; das Leuchten sagt „hier gehört etwas hin“, und wer es
/// antippt, bekommt den Satz doch noch.
///
/// **Dreimal, nicht endlos:** Eine Endlos-Animation liesse
/// `pumpAndSettle` in jedem Test hängen, der einen solchen Platz zeigt —
/// und nach drei Mal hat man es gesehen. Es beginnt neu, sobald der Platz
/// wieder frei wird.
class PlatzLaedtEin extends StatefulWidget {
  const PlatzLaedtEin({
    required this.aktiv,
    required this.child,
    this.radius = 10,
    super.key,
  });

  final bool aktiv;
  final Widget child;
  final double radius;

  static const Duration takt = Duration(milliseconds: 700);
  static const int mal = 3;

  @override
  State<PlatzLaedtEin> createState() => _PlatzLaedtEinState();
}

class _PlatzLaedtEinState extends State<PlatzLaedtEin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _takt = AnimationController(
    vsync: this,
    duration: PlatzLaedtEin.takt,
  );

  @override
  void initState() {
    super.initState();
    if (widget.aktiv) _starte();
  }

  @override
  void didUpdateWidget(PlatzLaedtEin alt) {
    super.didUpdateWidget(alt);
    if (widget.aktiv && !alt.aktiv) _starte();
    if (!widget.aktiv) _takt.value = 0;
  }

  void _starte() {
    _takt
      ..value = 0
      ..repeat(reverse: true, count: PlatzLaedtEin.mal * 2);
  }

  @override
  void dispose() {
    _takt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _takt,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_takt.value);
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(
              color: Palette.accentOnDark.withValues(alpha: t),
              width: 2.5,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Palette.accentOnDark.withValues(alpha: 0.5 * t),
                blurRadius: 10 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
