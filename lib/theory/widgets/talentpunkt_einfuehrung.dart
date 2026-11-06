import 'package:flutter/material.dart';

import '../../mentor/weiter_tipp.dart';
import '../../ui/der_reihe_nach.dart';
import '../../ui/pulsieren.dart';
import 'points_chip.dart';

/// **Der Talentpunkt, bevor das erste Buch gewählt wird** (06.11.2026,
/// Frederik: „Zoom auf Skillpunkt + Highlight … gezoomt mittig groß und
/// wandert dann nach oben rechts, da wo er jetzt ist, und der Mentor
/// erklärt dabei“).
///
/// Solange [aktiv], steht der Punkt groß in der Mitte und atmet, der
/// Mentor erklärt darüber (`Schritt.talentpunkt`). **Ein Tipp irgendwohin**
/// schickt ihn an seinen Platz in der Kopfzeile ([zielKey]): Er wandert
/// hin und wird dabei kleiner. Ist er angekommen, meldet er
/// [onAngekommen] — dann kommt die Wahl der Bücher.
///
/// Die Hülle steht immer, auch wenn sie nichts zeigt (`gotchas.md`).
class TalentpunktEinfuehrung extends StatefulWidget {
  const TalentpunktEinfuehrung({
    required this.aktiv,
    required this.punkte,
    required this.zielKey,
    required this.onAngekommen,
    required this.child,
    super.key,
  });

  final bool aktiv;

  /// Was auf dem Punkt steht — dieselbe Zahl wie oben rechts.
  final int punkte;

  /// Wo der Punkt hinwandert: der Chip in der Kopfzeile.
  final GlobalKey zielKey;

  final VoidCallback onAngekommen;
  final Widget child;

  /// Wie groß er in der Mitte steht.
  static const double gross = 3;

  /// Wie lange er zu seinem Platz braucht.
  static const Duration flug = Duration(milliseconds: 750);

  /// Woran Tests ihn finden.
  static const Key punktKey = ValueKey<String>('talentpunkt-gross');

  @override
  State<TalentpunktEinfuehrung> createState() => _TalentpunktEinfuehrungState();
}

class _TalentpunktEinfuehrungState extends State<TalentpunktEinfuehrung>
    with SingleTickerProviderStateMixin {
  // In `initState`, nicht faul (`gotchas.md`).
  late final AnimationController _flug;
  final GlobalKey _flaeche = GlobalKey();

  /// Wohin er fliegt — gemessen beim Tipp, nicht im Aufbau: Mitten im
  /// Auslegen lässt sich keine Lage nachschlagen.
  Offset? _ziel;

  @override
  void initState() {
    super.initState();
    _flug = AnimationController(
      vsync: this,
      duration: TalentpunktEinfuehrung.flug,
    );
    _flug.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onAngekommen();
    });
  }

  @override
  void didUpdateWidget(TalentpunktEinfuehrung alt) {
    super.didUpdateWidget(alt);
    // Vorbei: zurück auf Anfang, falls er noch einmal käme.
    if (!widget.aktiv && alt.aktiv) _flug.value = 0;
  }

  @override
  void dispose() {
    _flug.dispose();
    super.dispose();
  }

  void _losfliegen() {
    if (_flug.isAnimating || _flug.isCompleted) return;
    _ziel = _zielMitte();
    final ruhig = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (ruhig) {
      _flug.value = 1;
      widget.onAngekommen();
      return;
    }
    // Neu bauen: Solange er fliegt, nimmt die Fläche keinen Tipp mehr.
    _flug.forward();
    setState(() {});
  }

  /// Die Mitte des Ziels, gemessen in der eigenen Fläche — oder null,
  /// solange eins von beiden noch nicht ausgelegt ist.
  Offset? _zielMitte() {
    final ziel = widget.zielKey.currentContext?.findRenderObject();
    final flaeche = _flaeche.currentContext?.findRenderObject();
    if (ziel is! RenderBox || flaeche is! RenderBox) return null;
    if (!ziel.hasSize || !flaeche.hasSize) return null;
    return flaeche.globalToLocal(
      ziel.localToGlobal(ziel.size.center(Offset.zero)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WeiterTipp(
      aktiv: widget.aktiv && !_flug.isAnimating,
      onWeiter: _losfliegen,
      child: Stack(
        key: _flaeche,
        fit: StackFit.passthrough,
        children: <Widget>[
          widget.child,
          if (widget.aktiv)
            Positioned.fill(
              // **Über dem Scaffold fehlt der Textstil**: Ohne `Material`
              // stünde die Zahl gelb doppelt unterstrichen da.
              child: IgnorePointer(
                child: Material(
                  type: MaterialType.transparency,
                  child: LayoutBuilder(
                    builder: (context, platz) => AnimatedBuilder(
                      animation: _flug,
                      builder: (context, _) => _punkt(platz),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _punkt(BoxConstraints platz) {
    final t = Curves.easeInOutCubic.transform(_flug.value);
    // Etwas über der Mitte: Darunter kommen gleich die Bücher, und unter
    // dem Mentor bleibt Luft.
    final start = Offset(platz.maxWidth / 2, platz.maxHeight * 0.45);
    final mitte = Offset.lerp(start, _ziel ?? start, t)!;
    final groesse =
        TalentpunktEinfuehrung.gross + (1 - TalentpunktEinfuehrung.gross) * t;

    return Stack(
      children: <Widget>[
        Positioned(
          left: mitte.dx,
          top: mitte.dy,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: Transform.scale(
              scale: groesse,
              // Erst der Mentor, dann er (`DerReiheNach`).
              child: DerReiheNach(
                nr: 0,
                child: Pulsieren(
                  key: TalentpunktEinfuehrung.punktKey,
                  // Auf dem Weg atmet er nicht mehr.
                  aktiv: !_flug.isAnimating,
                  radius: 20,
                  verzoegerung: DerReiheNach.fertigNach(1),
                  child: PointsChip(points: widget.punkte),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
