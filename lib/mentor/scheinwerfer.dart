import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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

  /// Wie weich der Rand des Lichts ausläuft, in Punkten.
  static const double weich = 10;

  /// Wie weit das Licht um ein Ziel herum reicht.
  static const double rand = 6;

  /// **Im Raster** (08.11.2026): Zwischen zwei Kacheln liegen 8 Punkte.
  /// Mit [rand] und [weich] liefe das Licht eines Ziels über die Kachel
  /// daneben — sie stand halb im Licht. Ein enges Ziel
  /// ([ScheinwerferZiel.eng]) nimmt deshalb diese beiden.
  static const double randEng = 2;
  static const double weichEng = 3;

  /// Wie lange er auf- und abblendet.
  static const Duration blende = Duration(milliseconds: 380);

  /// Wie lange er stehen bleibt, wenn sein letztes Ziel geht — Zeit für
  /// das nächste, sich zu melden.
  static const Duration halten = Duration(milliseconds: 380);

  static const Key schleierKey = ValueKey<String>('scheinwerfer');

  /// Wo das Licht zuletzt gemalt wurde, in den Koordinaten des Schleiers.
  @visibleForTesting
  static List<Rect> lichtVon(State<Scheinwerfer> state) => <Rect>[
    for (final l in (state as _ScheinwerferState)._zuletzt) l.loch.outerRect,
  ];

  @override
  State<Scheinwerfer> createState() => _ScheinwerferState();
}

class _ScheinwerferState extends State<Scheinwerfer>
    with SingleTickerProviderStateMixin {
  final Map<GlobalKey, ({double radius, bool eng, bool wartet})> _ziele =
      <GlobalKey, ({double radius, bool eng, bool wartet})>{};

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
    _beobachte();
  }

  /// Wo die Löcher beim letzten Malen lagen.
  List<({RRect loch, double weich, double hell})> _zuletzt =
      const <({RRect loch, double weich, double hell})>[];

  /// **Bewegt sich ein Ziel, wandert das Licht mit** (08.11.2026). Bis
  /// dahin wurde nur beim Ein- und Ausblenden und beim Rollen neu
  /// gemalt. Fuhr ein Ziel erst danach an seinen Platz — der Kreis
  /// „Fähigkeiten“ mit der unteren Leiste von unten herein —, blieb das
  /// Loch an der alten Stelle, und das Ziel stand im Dunkeln.
  ///
  /// Gemessen wird nach jedem Bild, das ohnehin entsteht; selbst fordert
  /// er keins an. Steht alles still, ruht er — und `pumpAndSettle` mit.
  void _beobachte() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final jetzt = _loecher();
      if (!listEquals(jetzt, _zuletzt)) {
        _zuletzt = jetzt;
        _neu.value++;
      }
      _beobachte();
    });
  }

  @override
  void dispose() {
    _blende.dispose();
    _neu.dispose();
    super.dispose();
  }

  void _melde(
    GlobalKey ziel,
    double radius, {
    bool begleiter = false,
    bool eng = false,
    bool wartet = false,
  }) {
    _ziele[ziel] = (radius: radius, eng: eng, wartet: wartet);
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
        // **Erst kurz warten** (08.11.2026): Wechselt der Schritt, geht
        // das alte Ziel, bevor das neue sich meldet. Ohne Pause hob sich
        // der Schleier dazwischen und fiel gleich wieder — er flackerte.
        // Kommt ein neues Ziel, fängt `forward` ihn auf.
        _blende.animateBack(
          0,
          duration: Scheinwerfer.blende + Scheinwerfer.halten,
          curve: const Interval(0.5, 1, curve: Curves.easeIn),
        );
      } else {
        final ruhig = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
        ruhig ? _blende.value = 1 : _blende.forward();
      }
      _neu.value++;
    });
  }

  /// Die Löcher im Schleier, in seinen eigenen Koordinaten — jedes mit
  /// der Breite seiner weichen Kante.
  List<({RRect loch, double weich, double hell})> _loecher() {
    final flaeche = _flaeche.currentContext?.findRenderObject();
    if (flaeche is! RenderBox || !flaeche.hasSize) {
      return const <({RRect loch, double weich, double hell})>[];
    }
    final ursprung = flaeche.localToGlobal(Offset.zero);
    return <({RRect loch, double weich, double hell})>[
      for (final MapEntry(key: ziel, value: (:radius, :eng, :wartet))
          in _ziele.entries)
        // Ein wartendes Ziel hält den Schleier, hat aber noch kein Licht.
        if (!wartet)
          if (ziel.currentContext?.findRenderObject() case final RenderBox box
              when box.attached && box.hasSize)
            (
              hell: _sichtbarkeit(box, flaeche),
              loch: RRect.fromRectAndRadius(
                (box.localToGlobal(Offset.zero) - ursprung & box.size).inflate(
                  eng ? Scheinwerfer.randEng : Scheinwerfer.rand,
                ),
                Radius.circular(
                  radius + (eng ? Scheinwerfer.randEng : Scheinwerfer.rand),
                ),
              ),
              weich: eng ? Scheinwerfer.weichEng : Scheinwerfer.weich,
            ),
    ];
  }

  /// **Wie sichtbar ein Ziel gerade ist**, 0 bis 1 (08.11.2026): alle
  /// Deckkräfte zwischen ihm und dem Schleier, malgenommen. Das Licht
  /// ist nie heller als sein Ziel — blendet es ein oder aus, tut sein
  /// Licht dasselbe. Bis dahin lag beim Wechsel eines Schritts kurz ein
  /// heller Fleck, wo das alte Ziel schon unsichtbar war.
  static double _sichtbarkeit(RenderObject ziel, RenderObject bis) {
    var hell = 1.0;
    for (RenderObject? o = ziel; o != null && o != bis; o = o.parent) {
      hell *= switch (o) {
        RenderOpacity(:final opacity) => opacity,
        RenderAnimatedOpacity(:final opacity) => opacity.value,
        _ => 1.0,
      };
      if (hell <= 0) return 0;
    }
    return hell.clamp(0.0, 1.0);
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

  final List<({RRect loch, double weich, double hell})> Function() loecher;
  final Animation<double> blende;
  final Listenable neu;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOut.transform(blende.value);
    if (t == 0) return;
    // **Weiche Kante** (07.11.2026): erst der ganze Schleier, dann die
    // Löcher weich herausgenommen — wie der Rand eines Lichtkegels, nicht
    // wie ein ausgeschnittenes Fenster. Das Loch ist um [weich] größer,
    // damit das Ziel selbst ganz im Licht liegt.
    final alles = Offset.zero & size;
    canvas.saveLayer(alles, Paint());
    canvas.drawRect(
      alles,
      Paint()
        ..color = Palette.scheinwerfer.withValues(
          alpha: Scheinwerfer.dunkel * t,
        ),
    );
    for (final (:loch, :weich, :hell) in loecher()) {
      if (hell <= 0) continue;
      final heraus = Paint()
        ..color = Color.fromRGBO(0, 0, 0, hell)
        ..blendMode = BlendMode.dstOut
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, weich);
      canvas.drawRRect(loch.inflate(weich), heraus);
    }
    canvas.restore();
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
    this.eng = false,
    this.ab = Duration.zero,
    super.key,
  });

  final Widget child;
  final bool aktiv;

  /// **Wie lange das Licht wartet**, nachdem [aktiv] gilt (08.11.2026).
  /// Wer der Reihe nach einblendet, bekommt sein Licht erst, wenn er
  /// steht — sonst läge ein heller Fleck auf leerem Grund.
  final Duration ab;

  /// Steht das Ziel dicht neben anderen — eine Kachel im Raster, ein
  /// Platz in der Reihe —, läuft sein Licht kürzer aus
  /// ([Scheinwerfer.randEng]), sonst stünde der Nachbar halb im Licht.
  final bool eng;

  /// Liegt im Licht, **wenn** ein anderes Ziel den Schleier aufzieht —
  /// allein zieht es keinen auf. Für den Kasten des Mentors: Er spricht
  /// auch dort, wo er auf nichts zeigt.
  final bool begleiter;

  /// Die Rundung des Lochs — so rund wie das Ziel.
  final double radius;

  @override
  State<ScheinwerferZiel> createState() => _ScheinwerferZielState();
}

class _ScheinwerferZielState extends State<ScheinwerferZiel>
    with SingleTickerProviderStateMixin {
  final GlobalKey _ziel = GlobalKey();
  _ScheinwerferState? _bei;

  /// Zählt [ScheinwerferZiel.ab] herunter — ein Takt statt einer Uhr,
  /// damit `pumpAndSettle` mitwartet (`gotchas.md`). In `initState`,
  /// nicht faul.
  late final AnimationController _warten;

  @override
  void initState() {
    super.initState();
    _warten = AnimationController(vsync: this, duration: widget.ab);
    // Ohne Wartezeit gleich fertig — und noch ohne Lauscher: Melden geht
    // in `initState` nicht, das tut `didChangeDependencies`.
    if (widget.aktiv) {
      widget.ab == Duration.zero ? _warten.value = 1 : _warten.forward();
    }
    _warten.addStatusListener((status) {
      if (status == AnimationStatus.completed) _melde();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _melde();
  }

  @override
  void didUpdateWidget(ScheinwerferZiel alt) {
    super.didUpdateWidget(alt);
    if (widget.aktiv && !alt.aktiv) {
      _warten
        ..duration = widget.ab
        ..forward(from: 0);
    }
    if (!widget.aktiv) _warten.reset();
    if (alt.aktiv != widget.aktiv ||
        alt.radius != widget.radius ||
        alt.begleiter != widget.begleiter ||
        alt.eng != widget.eng) {
      _melde();
    }
  }

  void _melde() {
    final bei = context.dependOnInheritedWidgetOfExactType<_Anmeldung>()?.state;
    if (_bei != bei) _bei?._abmelden(_ziel);
    _bei = bei;
    if (widget.aktiv) {
      bei?._melde(
        _ziel,
        widget.radius,
        begleiter: widget.begleiter,
        eng: widget.eng,
        wartet: !_warten.isCompleted,
      );
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
    _melde();
  }

  @override
  void dispose() {
    _bei?._abmelden(_ziel);
    _warten.dispose();
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

/// **Ein Lichtkegel auf dem Ziel** (Frederik, 07.11.2026): Wo der Schleier
/// allein auf dunklem Grund kaum auffällt — die Bibliothek ist selbst
/// dunkel —, liegt unter dem Ziel ein warmer Schein, der nach außen
/// ausläuft. Er nimmt keinen Tipp an und ändert keine Größe.
class ScheinwerferLicht extends StatelessWidget {
  const ScheinwerferLicht({required this.child, super.key});

  final Widget child;

  /// Wie hell die Mitte ist.
  static const double staerke = 0.4;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _Lichtkegel(), child: child);
  }
}

class _Lichtkegel extends CustomPainter {
  const _Lichtkegel();

  @override
  void paint(Canvas canvas, Size size) {
    // Breiter und höher als das Ziel, damit der Rand weich ausläuft.
    final flaeche = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 1.5,
      height: size.height * 1.4,
    );
    canvas.drawOval(
      flaeche,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Palette.goldOnDark.withValues(alpha: ScheinwerferLicht.staerke),
            Palette.goldOnDark.withValues(alpha: ScheinwerferLicht.staerke / 3),
            Palette.goldOnDark.withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.55, 1],
        ).createShader(flaeche),
    );
  }

  @override
  bool shouldRepaint(_Lichtkegel alt) => false;
}
