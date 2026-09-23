import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// **Jeder Knopf gibt nach, wenn man ihn drückt** — eine Stelle für alle.
///
/// Zwei Wege führen hierher, und beide nehmen dieselben Zahlen:
///
/// * Die Knöpfe aus dem Theme (Holzplanke, Holzknopf, `TextButton`,
///   `OutlinedButton`) über [Druck.builder] in ihrem `ButtonStyle`. Keine
///   Aufrufstelle muss davon wissen.
/// * Alles Eigene — Kreise, Kacheln, Knoten, die Plätze in der Grube —
///   wird in ein [Druck] gelegt.
///
/// **Lauschen, nicht fangen.** [Druck] hört mit einem [Listener] auf den
/// Finger und nimmt an keiner Geste teil: Tippen, Halten, Ziehen und
/// Scrollen gehen weiter an das, was darunter liegt.
///
/// **Der Innerste gewinnt.** Ein Finger auf dem Plus einer Gewohnheit liegt
/// auch auf ihrer Kachel. Der innerste [Druck] (oder eine [DruckSperre])
/// hört ihn zuerst und beansprucht ihn; die äusseren lassen ihn dann in
/// Ruhe. Sonst sänke die ganze Karte mit dem kleinen Knopf ein.
///
/// **Wer scrollt, drückt nicht.** Wandert der Finger weiter als
/// [kTouchSlop], federt die Fläche zurück.
class Druck extends StatefulWidget {
  const Druck({required this.child, this.enabled = true, super.key});

  final Widget child;

  /// Ein gesperrter Knopf gibt nicht nach — er soll gerade nicht so tun,
  /// als hätte er etwas angenommen.
  final bool enabled;

  /// Wie weit ein Knopf höchstens einsinkt, als Anteil seiner Grösse.
  static const double tiefsteSkala = 0.9;

  /// Wie weit eine breite Fläche mindestens einsinkt. Eine Kachel über die
  /// ganze Breite, die um ein Zehntel schrumpft, sähe aus wie ein Fehler.
  static const double flachsteSkala = 0.97;

  /// Um wie viele Punkte der Rand ungefähr nach innen wandert.
  static const double einsinkenPunkte = 6;

  /// Die Skala eines Knopfs aus dem Theme — dort ist seine Grösse beim
  /// Bauen noch nicht bekannt.
  static const double knopfSkala = 0.92;

  static const Duration hinein = Duration(milliseconds: 70);
  static const Duration heraus = Duration(milliseconds: 220);

  /// Wie weit eine Fläche der Grösse [groesse] einsinkt: kleine Knöpfe
  /// deutlich, breite Kacheln kaum.
  static double skalaFuer(Size groesse) {
    final laengste = math.max(groesse.width, groesse.height);
    if (laengste <= 0) return knopfSkala;
    return (1 - 2 * einsinkenPunkte / laengste).clamp(
      tiefsteSkala,
      flachsteSkala,
    );
  }

  /// Für `ButtonStyle.backgroundBuilder` oder `foregroundBuilder`: legt
  /// das, was der Knopf zeichnet, in den Druck.
  static Widget builder(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) {
    return DruckSkala(
      gedrueckt: states.contains(WidgetState.pressed),
      child: child ?? const SizedBox.shrink(),
    );
  }

  /// Finger, die ein innerer [Druck] oder eine [DruckSperre] schon hat.
  static final Set<int> _beansprucht = <int>{};

  @override
  State<Druck> createState() => _DruckState();
}

class _DruckState extends State<Druck> {
  bool _gedrueckt = false;
  double _skala = Druck.knopfSkala;
  int? _finger;
  Offset _start = Offset.zero;

  void _runter(PointerDownEvent event) {
    if (!widget.enabled || _finger != null) return;
    if (!Druck._beansprucht.add(event.pointer)) return;
    _finger = event.pointer;
    _start = event.position;
    _setze(true);
  }

  void _bewegt(PointerMoveEvent event) {
    if (event.pointer != _finger) return;
    if ((event.position - _start).distance > kTouchSlop) _loslassen(event);
  }

  void _loslassen(PointerEvent event) {
    if (event.pointer != _finger) return;
    Druck._beansprucht.remove(event.pointer);
    _finger = null;
    _setze(false);
  }

  @override
  void dispose() {
    final finger = _finger;
    if (finger != null) Druck._beansprucht.remove(finger);
    super.dispose();
  }

  void _setze(bool gedrueckt) {
    if (_gedrueckt == gedrueckt) return;
    setState(() {
      _gedrueckt = gedrueckt;
      if (gedrueckt) {
        final groesse = context.size;
        if (groesse != null) _skala = Druck.skalaFuer(groesse);
      }
    });
  }

  @override
  void didUpdateWidget(Druck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _gedrueckt) _gedrueckt = false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _runter,
      onPointerMove: _bewegt,
      onPointerUp: _loslassen,
      onPointerCancel: _loslassen,
      child: DruckSkala(
        gedrueckt: _gedrueckt,
        skala: _skala,
        child: widget.child,
      ),
    );
  }
}

/// Beansprucht jeden Finger, der auf [child] landet, ohne selbst
/// nachzugeben — für einen Knopf aus dem Theme, der in einer Fläche mit
/// [Druck] liegt. Der Knopf sinkt über sein Theme ein, die Fläche bleibt.
class DruckSperre extends StatelessWidget {
  const DruckSperre({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => Druck._beansprucht.add(e.pointer),
      onPointerUp: (e) => Druck._beansprucht.remove(e.pointer),
      onPointerCancel: (e) => Druck._beansprucht.remove(e.pointer),
      child: child,
    );
  }
}

/// Die Bewegung selbst: schnell hinein, federnd heraus.
///
/// Zeichnet nur — ob gedrückt ist, entscheidet der Aufrufer. Das Kind wird
/// skaliert, sein Platz im Layout bleibt: Nichts daneben rutscht nach.
class DruckSkala extends StatelessWidget {
  const DruckSkala({
    required this.gedrueckt,
    required this.child,
    this.skala = Druck.knopfSkala,
    super.key,
  });

  final bool gedrueckt;
  final double skala;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: gedrueckt ? skala : 1,
      duration: gedrueckt ? Druck.hinein : Druck.heraus,
      curve: gedrueckt ? Curves.easeOut : Curves.easeOutBack,
      child: child,
    );
  }
}
