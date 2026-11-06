import 'package:flutter/material.dart';

import '../ui/palette.dart';

/// **Der Scheinwerfer des Mentors** (ADR-0095): ein dunkler Schleier über
/// dem Bildschirm, in dem nur liegt, worauf er gerade zeigt.
///
/// Ziele melden sich mit [ScheinwerferZiel] an. Ohne Ziel bleibt der
/// Schleier weg — der Mentor spricht dann nur.
///
/// **Der Schleier nimmt keinen Tipp an.** Auch was im Dunkeln liegt,
/// bleibt erreichbar: Der Mentor zeigt, er sperrt nicht (ADR-0079).
class Scheinwerfer extends StatefulWidget {
  const Scheinwerfer({required this.child, super.key});

  final Widget child;

  /// Wie dunkel der Schleier ist.
  static const double dunkel = 0.62;

  /// Wie weit das Licht um ein Ziel herum reicht.
  static const double rand = 6;

  /// Wie lange er auf- und abblendet.
  static const Duration blende = Duration(milliseconds: 380);

  static const Key schleierKey = ValueKey<String>('scheinwerfer');

  @override
  State<Scheinwerfer> createState() => _ScheinwerferState();
}

class _ScheinwerferState extends State<Scheinwerfer>
    with SingleTickerProviderStateMixin {
  final Map<GlobalKey, double> _ziele = <GlobalKey, double>{};

  /// Ziele, die nur mit anderen im Licht liegen — der Kasten des
  /// Mentors. Allein ziehen sie keinen Schleier auf.
  final Set<GlobalKey> _begleiter = <GlobalKey>{};
  final GlobalKey _flaeche = GlobalKey();
  final ValueNotifier<int> _neu = ValueNotifier<int>(0);
  late final AnimationController _blende;

  @override
  void initState() {
    super.initState();
    _blende = AnimationController(vsync: this, duration: Scheinwerfer.blende);
  }

  @override
  void dispose() {
    _blende.dispose();
    _neu.dispose();
    super.dispose();
  }

  void _melde(GlobalKey ziel, double radius, {bool begleiter = false}) {
    _ziele[ziel] = radius;
    begleiter ? _begleiter.add(ziel) : _begleiter.remove(ziel);
    _wechsel();
  }

  void _abmelden(GlobalKey ziel) {
    _begleiter.remove(ziel);
    if (_ziele.remove(ziel) != null) _wechsel();
  }

  /// Nach dem Bild: Erst dann stehen die Ziele, wo sie stehen.
  void _wechsel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_ziele.keys.every(_begleiter.contains)) {
        _blende.reverse();
      } else {
        final ruhig = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
        ruhig ? _blende.value = 1 : _blende.forward();
      }
      _neu.value++;
    });
  }

  /// Die Löcher im Schleier, in seinen eigenen Koordinaten.
  List<RRect> _loecher() {
    final flaeche = _flaeche.currentContext?.findRenderObject();
    if (flaeche is! RenderBox || !flaeche.hasSize) return const <RRect>[];
    final ursprung = flaeche.localToGlobal(Offset.zero);
    return <RRect>[
      for (final MapEntry(key: ziel, value: radius) in _ziele.entries)
        if (ziel.currentContext?.findRenderObject() case final RenderBox box
            when box.attached && box.hasSize)
          RRect.fromRectAndRadius(
            (box.localToGlobal(Offset.zero) - ursprung & box.size).inflate(
              Scheinwerfer.rand,
            ),
            Radius.circular(radius + Scheinwerfer.rand),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return _Anmeldung(
      state: this,
      // Rollt etwas, wandert sein Ziel mit — der Schleier zeichnet neu.
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) {
          _neu.value++;
          return false;
        },
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            widget.child,
            // Eigene Ebene: Der Schleier zeichnet beim Einblenden und
            // Rollen neu — ohne sie malte der ganze Bildschirm darunter mit.
            IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  key: _flaeche,
                  painter: _Schleier(
                    loecher: _loecher,
                    blende: _blende,
                    neu: _neu,
                  ),
                  child: AnimatedBuilder(
                    animation: _blende,
                    builder: (_, _) => _blende.value > 0
                        ? const SizedBox.expand(key: Scheinwerfer.schleierKey)
                        : const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Anmeldung extends InheritedWidget {
  const _Anmeldung({required this.state, required super.child});

  final _ScheinwerferState state;

  @override
  bool updateShouldNotify(_Anmeldung alt) => alt.state != state;
}

class _Schleier extends CustomPainter {
  _Schleier({required this.loecher, required this.blende, required this.neu})
    : super(repaint: Listenable.merge(<Listenable>[blende, neu]));

  final List<RRect> Function() loecher;
  final Animation<double> blende;
  final Listenable neu;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOut.transform(blende.value);
    if (t == 0) return;
    final pfad = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    for (final loch in loecher()) {
      pfad.addRRect(loch);
    }
    canvas.drawPath(
      pfad,
      Paint()
        ..color = Palette.scheinwerfer.withValues(
          alpha: Scheinwerfer.dunkel * t,
        ),
    );
  }

  @override
  bool shouldRepaint(_Schleier alt) => true;
}

/// Meldet [child] beim [Scheinwerfer] darüber an, solange [aktiv] gilt.
///
/// **Das Kind bleibt immer an derselben Stelle im Baum**, ob es im Licht
/// liegt oder nicht — sonst baute es sich neu, samt allem, was darin
/// gerade aufspringt (`gotchas.md`).
class ScheinwerferZiel extends StatefulWidget {
  const ScheinwerferZiel({
    required this.child,
    this.aktiv = true,
    this.radius = 14,
    this.begleiter = false,
    super.key,
  });

  final Widget child;
  final bool aktiv;

  /// Liegt im Licht, **wenn** ein anderes Ziel den Schleier aufzieht —
  /// allein zieht es keinen auf. Für den Kasten des Mentors: Er spricht
  /// auch dort, wo er auf nichts zeigt.
  final bool begleiter;

  /// Die Rundung des Lochs — so rund wie das Ziel.
  final double radius;

  @override
  State<ScheinwerferZiel> createState() => _ScheinwerferZielState();
}

class _ScheinwerferZielState extends State<ScheinwerferZiel> {
  final GlobalKey _ziel = GlobalKey();
  _ScheinwerferState? _bei;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _melde();
  }

  @override
  void didUpdateWidget(ScheinwerferZiel alt) {
    super.didUpdateWidget(alt);
    if (alt.aktiv != widget.aktiv ||
        alt.radius != widget.radius ||
        alt.begleiter != widget.begleiter) {
      _melde();
    }
  }

  void _melde() {
    final bei = context.dependOnInheritedWidgetOfExactType<_Anmeldung>()?.state;
    if (_bei != bei) _bei?._abmelden(_ziel);
    _bei = bei;
    if (widget.aktiv) {
      bei?._melde(_ziel, widget.radius, begleiter: widget.begleiter);
    } else {
      bei?._abmelden(_ziel);
    }
  }

  /// **Abmelden, sobald es aus dem Baum fällt** — nicht erst in
  /// `dispose`: Das kommt nach dem Malen, und bis dahin würde der Schleier
  /// ein Ziel ausmessen, das nicht mehr dasteht („inactive element“).
  @override
  void deactivate() {
    _bei?._abmelden(_ziel);
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    if (widget.aktiv) {
      _bei?._melde(_ziel, widget.radius, begleiter: widget.begleiter);
    }
  }

  @override
  void dispose() {
    _bei?._abmelden(_ziel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _ziel, child: widget.child);
}

/// **Der gelbe Punkt** (ADR-0095): Hier geht es hin. Pulsiert ein paar
/// Mal und bleibt dann stehen.
///
/// **Endlich mit Absicht**: Eine Bewegung ohne Ende liesse
/// `pumpAndSettle` nie zur Ruhe kommen (`gotchas.md`).
class ZielPunkt extends StatefulWidget {
  const ZielPunkt({this.groesse = 16, super.key});

  final double groesse;

  static const int pulse = 5;
  static const Duration takt = Duration(milliseconds: 600);

  @override
  State<ZielPunkt> createState() => _ZielPunktState();
}

class _ZielPunktState extends State<ZielPunkt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _takt;

  @override
  void initState() {
    super.initState();
    _takt = AnimationController(vsync: this, duration: ZielPunkt.takt);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ruhig = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (ruhig) {
      _takt.value = 0;
    } else if (!_takt.isAnimating && _takt.value == 0) {
      _takt.repeat(reverse: true, count: ZielPunkt.pulse * 2);
    }
  }

  @override
  void dispose() {
    _takt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.groesse;
    return IgnorePointer(
      child: SizedBox(
        width: g,
        height: g,
        // Eigene Ebene: Der Punkt pulsiert (`gotchas.md`).
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _takt,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_takt.value);
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: <Widget>[
                  // Der Hof, der beim Pulsieren aufgeht.
                  Container(
                    width: g * (1 + 0.9 * t),
                    height: g * (1 + 0.9 * t),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Palette.hinweis.withValues(alpha: 0.35 * (1 - t)),
                    ),
                  ),
                  Container(
                    width: g,
                    height: g,
                    decoration: BoxDecoration(
                      color: Palette.hinweis,
                      shape: BoxShape.circle,
                      border: Border.all(color: Palette.background, width: 2.5),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Palette.hinweis.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
