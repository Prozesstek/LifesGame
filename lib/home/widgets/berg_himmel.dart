import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// **Der Berg lebt** (16.11.2026, Frederik: „mach mal geiler“): Hinter
/// der Startseite ziehen Wolken, Schnee rieselt am Gipfel, und das Licht
/// folgt der Uhr — Morgenrot, klarer Tag, Abendglut, nachts Sterne und
/// Mond.
///
/// **Nur Darstellung.** Nichts hier erzeugt oder liest eine Zahl des
/// Spiels; die Uhr bestimmt nur die Farbe.
///
/// **Alles liegt auf dem Raster des Bildes**: Wolken, Sterne, Mond und
/// Flocken sind Blöcke in der Größe eines Bildpunkts des Bergs und
/// bewegen sich in ganzen Blöcken — sonst sähe man weiche Formen vor
/// harter Pixelart.
///
/// **Eigene Ebenen** (`gotchas.md`): Das Bild und was sich darüber
/// bewegt, liegen je in einer `RepaintBoundary`. Der Himmel malt
/// höchstens [bilderJeSekunde]-mal je Sekunde neu und die Seite darüber
/// gar nicht mit. In Tests steht er still ([lebt]).
class BergHimmel extends StatefulWidget {
  const BergHimmel({
    required this.child,
    this.schleier = 0,
    this.schleierFarbe = const Color(0xFF000000),
    super.key,
  });

  final Widget child;

  /// Wie stark [schleierFarbe] über dem Bild liegt, 0 bis 1.
  final double schleier;
  final Color schleierFarbe;

  static const String bild = 'assets/UI/Berg.jpg';

  /// Die Maße von [bild] — daraus rechnet der Maler, wo der Gipfel auf
  /// dem Bildschirm liegt.
  static const Size bildGroesse = Size(880, 1017);

  /// Ein Bildpunkt der Zeichnung, in Punkten des Bildes.
  static const double bildpunkt = 4;

  static const int bilderJeSekunde = 20;

  /// Aus in Tests (`test/flutter_test_config.dart`): Eine Bewegung ohne
  /// Ende ließe `pumpAndSettle` nie zur Ruhe kommen.
  static bool lebt = true;

  /// Woher die Uhrzeit kommt — in Tests und Vorschauen überschreibbar.
  static DateTime Function() uhr = DateTime.now;

  @override
  State<BergHimmel> createState() => _BergHimmelState();
}

class _BergHimmelState extends State<BergHimmel>
    with SingleTickerProviderStateMixin {
  // In `initState` angelegt, nicht faul (`gotchas.md`).
  late final Ticker _takt;
  late final ValueNotifier<_Moment> _moment;

  @override
  void initState() {
    super.initState();
    _moment = ValueNotifier<_Moment>(_Moment(0, _stunde()));
    _takt = createTicker(_tick);
    if (BergHimmel.lebt) _takt.start();
  }

  static double _stunde() {
    final jetzt = BergHimmel.uhr();
    return jetzt.hour + jetzt.minute / 60;
  }

  void _tick(Duration vergangen) {
    final schritt =
        vergangen.inMilliseconds * BergHimmel.bilderJeSekunde ~/ 1000;
    if (schritt == _moment.value.schritt) return;
    _moment.value = _Moment(schritt, _stunde());
  }

  @override
  void dispose() {
    _takt.dispose();
    _moment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.schleierFarbe,
              image: DecorationImage(
                image: const AssetImage(BergHimmel.bild),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  widget.schleierFarbe.withValues(alpha: widget.schleier),
                  BlendMode.srcATop,
                ),
              ),
            ),
          ),
        ),
        RepaintBoundary(
          child: IgnorePointer(
            child: CustomPaint(painter: _HimmelMaler(_moment)),
          ),
        ),
        widget.child,
      ],
    );
  }
}

/// Ein Bild des Himmels: der wievielte Schritt, und wie spät es ist.
@immutable
class _Moment {
  const _Moment(this.schritt, this.stunde);

  final int schritt;

  /// 0 bis 24, mit Bruchteil.
  final double stunde;

  double get sekunden => schritt / BergHimmel.bilderJeSekunde;
}

/// Das Licht einer Tageszeit.
@immutable
class Tageslicht {
  const Tageslicht({
    required this.oben,
    required this.unten,
    required this.wolke,
    required this.nacht,
  });

  /// Der Schleier über dem Bild, oben und unten — mit Deckkraft.
  final Color oben;
  final Color unten;

  final Color wolke;

  /// Wie sehr Sterne und Mond zu sehen sind, 0 bis 1.
  final double nacht;

  static const Tageslicht _nachts = Tageslicht(
    oben: Color(0xB8060A22),
    unten: Color(0x8C0E1434),
    wolke: Color(0xB02B3560),
    nacht: 1,
  );
  static const Tageslicht _morgens = Tageslicht(
    oben: Color(0x596A4A9A),
    unten: Color(0x8CF7A45E),
    wolke: Color(0xD9FFD9C2),
    nacht: 0.12,
  );
  static const Tageslicht _tags = Tageslicht(
    oben: Color(0x00FFFFFF),
    unten: Color(0x00FFFFFF),
    wolke: Color(0xD9F4F7FF),
    nacht: 0,
  );
  static const Tageslicht _abends = Tageslicht(
    oben: Color(0x8C43246E),
    unten: Color(0xA6F0682E),
    wolke: Color(0xD9FFB894),
    nacht: 0.15,
  );

  /// Die Stützstellen des Tages — **eine Tabelle**, dazwischen wird
  /// gemischt.
  static const List<(double, Tageslicht)> verlauf = <(double, Tageslicht)>[
    (0, _nachts),
    (5, _nachts),
    (6.5, _morgens),
    (9, _tags),
    (16.5, _tags),
    (19, _abends),
    (21.5, _nachts),
    (24, _nachts),
  ];

  static Tageslicht um(double stunde) {
    final h = stunde % 24;
    for (var i = 1; i < verlauf.length; i++) {
      final (bis, danach) = verlauf[i];
      if (h > bis) continue;
      final (ab, davor) = verlauf[i - 1];
      final t = bis == ab ? 0.0 : (h - ab) / (bis - ab);
      return Tageslicht(
        oben: Color.lerp(davor.oben, danach.oben, t)!,
        unten: Color.lerp(davor.unten, danach.unten, t)!,
        wolke: Color.lerp(davor.wolke, danach.wolke, t)!,
        nacht: davor.nacht + (danach.nacht - davor.nacht) * t,
      );
    }
    return _nachts;
  }
}

class _Wolke {
  const _Wolke(this.y, this.start, this.tempo, this.zeilen);

  /// Unterkante und Startpunkt, in Punkten des Bildes.
  final double y;
  final double start;

  /// Punkte des Bildes je Sekunde, nach links.
  final double tempo;

  /// Von unten nach oben: Versatz und Länge je Zeile, in Blöcken.
  final List<(int, int)> zeilen;

  int get breite => zeilen.first.$2;
}

class _Stern {
  const _Stern(this.x, this.y, this.phase, this.hell);
  final double x;
  final double y;
  final double phase;
  final double hell;
}

class _Flocke {
  const _Flocke(this.x, this.y, this.tempo, this.phase);

  /// 0 bis 1 über Breite und Höhe.
  final double x;
  final double y;
  final double tempo;
  final double phase;
}

class _HimmelMaler extends CustomPainter {
  _HimmelMaler(this.moment) : super(repaint: moment);

  final ValueNotifier<_Moment> moment;

  /// Der Grat des Bergs in Punkten des Bildes — darüber ist Himmel.
  static const List<Offset> _grat = <Offset>[
    Offset(0, 640),
    Offset(100, 520),
    Offset(160, 455),
    Offset(200, 490),
    Offset(250, 380),
    Offset(330, 290),
    Offset(420, 172),
    Offset(520, 250),
    Offset(600, 300),
    Offset(650, 380),
    Offset(690, 500),
    Offset(740, 515),
    Offset(800, 640),
    Offset(880, 700),
  ];

  static const Offset _mond = Offset(540, 186);
  static const int _mondRadius = 6;

  static double _gratBei(double x) {
    for (var i = 1; i < _grat.length; i++) {
      if (x > _grat[i].dx) continue;
      final a = _grat[i - 1];
      final b = _grat[i];
      return a.dy + (b.dy - a.dy) * (x - a.dx) / (b.dx - a.dx);
    }
    return _grat.last.dy;
  }

  static final List<_Stern> _sterne = () {
    final w = math.Random(7);
    final sterne = <_Stern>[];
    while (sterne.length < 70) {
      final x = w.nextDouble() * BergHimmel.bildGroesse.width;
      final y = w.nextDouble() * 560;
      if (y > _gratBei(x) - 28) continue;
      if ((Offset(x, y) - _mond).distance < 60) continue;
      sterne.add(
        _Stern(
          x,
          y,
          w.nextDouble() * math.pi * 2,
          0.45 + w.nextDouble() * 0.55,
        ),
      );
    }
    return sterne;
  }();

  static final List<_Wolke> _wolken = () {
    final w = math.Random(21);
    const hoehen = <double>[150, 236, 190, 300, 168, 262, 214, 340];
    return <_Wolke>[
      for (final (i, y) in hoehen.indexed)
        _Wolke(
          y,
          // Gleichmäßig über die Bahn verteilt, sonst hängen alle an
          // einer Stelle und der Himmel ist minutenlang leer.
          (i + w.nextDouble() * 0.6) * 1300 / hoehen.length,
          5 + w.nextDouble() * 7 + (i.isEven ? 4 : 0),
          _form(w),
        ),
    ];
  }();

  static List<(int, int)> _form(math.Random w) {
    final breite = 14 + w.nextInt(14);
    final zeilen = <(int, int)>[(0, breite)];
    var ab = 0;
    var laenge = breite;
    final hoch = 2 + w.nextInt(3);
    for (var i = 0; i < hoch; i++) {
      final links = 1 + w.nextInt(3);
      final rechts = 2 + w.nextInt(4);
      if (laenge - links - rechts < 3) break;
      ab += links;
      laenge -= links + rechts;
      zeilen.add((ab, laenge));
    }
    return zeilen;
  }

  static final List<_Flocke> _flocken = () {
    final w = math.Random(3);
    return <_Flocke>[
      for (var i = 0; i < 34; i++)
        _Flocke(
          w.nextDouble(),
          w.nextDouble(),
          0.018 + w.nextDouble() * 0.022,
          w.nextDouble() * math.pi * 2,
        ),
    ];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final jetzt = moment.value;
    final t = jetzt.sekunden;
    final licht = Tageslicht.um(jetzt.stunde);

    // Wie `BoxFit.cover` das Bild legt.
    const bild = BergHimmel.bildGroesse;
    final s = math.max(size.width / bild.width, size.height / bild.height);
    final ox = (size.width - bild.width * s) / 2;
    final oy = (size.height - bild.height * s) / 2;
    final b = (BergHimmel.bildpunkt * s).clamp(2.0, 12.0);
    double raster(double v) => (v / b).floorToDouble() * b;
    Offset ort(double x, double y) => Offset(ox + x * s, oy + y * s);

    canvas.clipRect(Offset.zero & size);

    // Das Licht der Tageszeit.
    if (licht.oben.a > 0 || licht.unten.a > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Die warme Farbe liegt am Horizont, nicht am unteren Rand.
            colors: <Color>[licht.oben, licht.unten, licht.unten],
            stops: const <double>[0, 0.3, 1],
          ).createShader(Offset.zero & size),
      );
    }

    final farbe = Paint();

    // Sterne und Mond — nur über dem Grat.
    if (licht.nacht > 0.02) {
      for (final stern in _sterne) {
        final funkeln = 0.6 + 0.4 * math.sin(t * 1.4 + stern.phase);
        farbe.color = const Color(
          0xFFFFF6D8,
        ).withValues(alpha: licht.nacht * stern.hell * funkeln);
        final p = ort(stern.x, stern.y);
        canvas.drawRect(Rect.fromLTWH(raster(p.dx), raster(p.dy), b, b), farbe);
      }
      final mitte = ort(_mond.dx, _mond.dy);
      farbe
        ..color = const Color(0xFFFFF2C4).withValues(alpha: 0.16 * licht.nacht)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, b * 5);
      canvas.drawCircle(mitte, b * (_mondRadius + 3), farbe);
      farbe.maskFilter = null;
      const r = _mondRadius;
      for (var dy = -r; dy <= r; dy++) {
        for (var dx = -r; dx <= r; dx++) {
          if (dx * dx + dy * dy > r * r) continue;
          // Die Sichel: ein zweiter Kreis, nach rechts oben versetzt,
          // nimmt weg.
          final schatten =
              (dx - 3) * (dx - 3) + (dy + 2) * (dy + 2) <= (r - 1) * (r - 1);
          if (schatten) continue;
          farbe.color = const Color(0xFFFFF4D2).withValues(alpha: licht.nacht);
          canvas.drawRect(
            Rect.fromLTWH(
              raster(mitte.dx) + dx * b,
              raster(mitte.dy) + dy * b,
              b,
              b,
            ),
            farbe,
          );
        }
      }
    }

    // Wolken ziehen nach links und kommen rechts wieder.
    for (final wolke in _wolken) {
      // Wolken sind grober als der Rest: zwei Bildpunkte je Block.
      final c = b * 2;
      final lang = wolke.breite * BergHimmel.bildpunkt * 2;
      final bahn = bild.width + lang * 2;
      final x = bild.width + lang - (wolke.start + wolke.tempo * t) % bahn;
      final p = ort(x, wolke.y);
      final links = raster(p.dx);
      final unten = raster(p.dy);
      for (final (i, (ab, laenge)) in wolke.zeilen.indexed) {
        // Die Unterkante einen Ton dunkler, wie gezeichnet.
        farbe.color = i == 0
            ? Color.lerp(licht.wolke, const Color(0xFF6E7AA8), 0.28)!
            : licht.wolke;
        canvas.drawRect(
          Rect.fromLTWH(links + ab * c, unten - (i + 1) * c, laenge * c, c),
          farbe,
        );
      }
    }

    // Schnee am Gipfel — weiter unten taut er weg.
    for (final flocke in _flocken) {
      final y = ((flocke.y + t * flocke.tempo) % 1) * size.height;
      final hoehe = (y - oy) / s;
      final rest = 1 - ((hoehe - 430) / 220).clamp(0.0, 1.0);
      if (rest <= 0) continue;
      final x =
          flocke.x * size.width + math.sin(t * 0.7 + flocke.phase) * b * 2.5;
      farbe.color = Colors.white.withValues(alpha: 0.8 * rest);
      canvas.drawRect(Rect.fromLTWH(raster(x), raster(y), b, b), farbe);
    }
  }

  @override
  bool shouldRepaint(_HimmelMaler old) => old.moment != moment;
}
