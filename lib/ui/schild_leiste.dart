import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'holz_teile.dart';
import 'menue_leiste.dart';
import 'palette.dart';

/// **Die Kopfzeile jedes Bereichs: ein Holzschild an zwei Ketten**
/// (20.11.2026, Frederik: „Von oben hängt ein Holzschild mit Ketten wie in
/// einer alten Bar das Namensschild. Dort steht eingebrannt der Titel“).
///
/// Ersetzt die Pergamentleiste: Oben liegt der dunkle Grund des
/// Bildschirms, mittig hängt das Schild. Es wächst mit dem Wort und lässt
/// links und rechts [SchildLeiste.luft]; reicht der Platz zwischen
/// Zurück-Knopf und Knöpfen rechts nicht, wird die Schrift kleiner — sie
/// steht nie über den Rand. **Das Schild hängt über den Inhalt hinaus**
/// und nimmt keinen Tipp an; was darunter liegt, bleibt bedienbar.
///
/// Beim Öffnen schwingt es zwei, drei Mal gedämpft ein, um die Mitte der
/// Aufhängung — nicht, wer am Gerät Bewegung abgeschaltet hat.
class SchildLeiste extends StatelessWidget implements PreferredSizeWidget {
  const SchildLeiste({
    required this.titel,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions = const <Widget>[],
    this.hintergrund = Colors.transparent,
    super.key,
  });

  final String titel;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final List<Widget> actions;

  /// Was hinter der Leiste liegt — durchsichtig zeigt den Grund des
  /// Bildschirms.
  final Color hintergrund;

  /// Wie hoch die Zeile der Knöpfe ist.
  static const double hoehe = kToolbarHeight;

  /// Wie lang die Ketten unter dem Rand des Bildschirms mindestens sind.
  static const double kette = 22;

  /// Luft zwischen Wort und Rand des Schilds, je Seite.
  static const double luft = 24;

  /// Abstand des Schilds zu den Knöpfen links und rechts.
  static const double abstand = 6;

  /// In Tests schwingt nichts (`test/flutter_test_config.dart`).
  static bool schwingt = true;

  /// Luft zwischen Unterkante des Schilds und dem Inhalt.
  static const double unten = 6;

  /// **Der Inhalt beginnt unter dem Schild** (20.11.2026, Frederik: „zeig
  /// mir jetzt mal wie es aussieht wenn der content erst unter dem schild
  /// anfängt“): Die Leiste ist so hoch wie Ketten, Brett und [unten].
  @override
  Size get preferredSize =>
      const Size.fromHeight(kette + HaengeSchild.brett + unten);

  @override
  Widget build(BuildContext context) {
    final oben = MediaQuery.paddingOf(context).top;
    final route = ModalRoute.of(context);
    final zurueck =
        leading ??
        (automaticallyImplyLeading && (route?.impliesAppBarDismissal ?? false)
            ? const BackButton()
            : null);
    final theme = AppBarTheme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: hintergrund,
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Palette.textOnDark),
          child: IconTheme.merge(
            data:
                theme.iconTheme ??
                const IconThemeData(color: Palette.textOnDark),
            child: CustomMultiChildLayout(
              delegate: _SchildLayout(oben: oben),
              children: <Widget>[
                if (zurueck != null)
                  LayoutId(
                    id: _Teil.links,
                    child: SizedBox(
                      width: hoehe,
                      height: hoehe,
                      child: Center(child: zurueck),
                    ),
                  ),
                if (actions.isNotEmpty)
                  LayoutId(
                    id: _Teil.rechts,
                    child: SizedBox(
                      height: hoehe,
                      child: IconTheme.merge(
                        data:
                            theme.actionsIconTheme ??
                            const IconThemeData(color: Palette.textOnDark),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions,
                        ),
                      ),
                    ),
                  ),
                LayoutId(
                  id: _Teil.schild,
                  child: IgnorePointer(
                    child: Semantics(
                      header: true,
                      namesRoute: true,
                      label: titel,
                      excludeSemantics: true,
                      child: HaengeSchild(
                        titel: titel,
                        kettenLaenge: oben + kette,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _Teil { links, rechts, schild }

/// Legt Zurück-Knopf und Knöpfe in die Zeile unter dem Rand und das Schild
/// in den Platz dazwischen — mittig, wenn es passt, sonst so mittig wie
/// möglich. Das Schild darf unten über die Leiste hinaus.
class _SchildLayout extends MultiChildLayoutDelegate {
  _SchildLayout({required this.oben});

  final double oben;

  @override
  void performLayout(Size size) {
    final zeile = BoxConstraints.loose(Size(size.width, SchildLeiste.hoehe));
    var linksRand = 0.0;
    var rechtsRand = size.width;
    if (hasChild(_Teil.links)) {
      final g = layoutChild(_Teil.links, zeile);
      positionChild(
        _Teil.links,
        Offset(0, oben + (SchildLeiste.hoehe - g.height) / 2),
      );
      linksRand = g.width;
    }
    if (hasChild(_Teil.rechts)) {
      final g = layoutChild(_Teil.rechts, zeile);
      positionChild(
        _Teil.rechts,
        Offset(
          size.width - g.width,
          oben + (SchildLeiste.hoehe - g.height) / 2,
        ),
      );
      rechtsRand = size.width - g.width;
    }
    // Ohne Knopf auf einer Seite bleibt dort trotzdem ein Rand.
    linksRand = math.max(linksRand, 12);
    rechtsRand = math.min(rechtsRand, size.width - 12);
    final frei = math.max(
      0.0,
      rechtsRand - linksRand - 2 * SchildLeiste.abstand,
    );
    final schild = layoutChild(_Teil.schild, BoxConstraints(maxWidth: frei));
    final links = linksRand + SchildLeiste.abstand;
    final x = ((size.width - schild.width) / 2)
        .clamp(
          links,
          math.max(links, rechtsRand - SchildLeiste.abstand - schild.width),
        )
        .toDouble();
    positionChild(_Teil.schild, Offset(x, 0));
  }

  @override
  bool shouldRelayout(_SchildLayout alt) => alt.oben != oben;
}

/// **Das Schild selbst**: zwei Ketten von oben, darunter das Brett mit dem
/// Titel. So breit wie das Wort plus [SchildLeiste.luft],
/// höchstens so breit, wie es darf — dann wird die Schrift kleiner.
class HaengeSchild extends StatefulWidget {
  const HaengeSchild({
    required this.titel,
    required this.kettenLaenge,
    super.key,
  });

  final String titel;
  final double kettenLaenge;

  /// Höhe des Bretts.
  static const double brett = 52;

  /// Logische Punkte je Bildpunkt.
  static const double pixel = 2;

  /// Wie die Schrift steht: hell wie auf jedem Holzknopf
  /// ([Palette.textOnDark]), mit demselben dunklen Rand unten rechts, damit
  /// sie auf der Maserung nicht verschwimmt (Frederik, 20.11.2026: „Alle
  /// anderen Buttons haben Holzhintergrund und weiße Schrift“).
  static const TextStyle schrift = TextStyle(
    fontFamily: MenueLeiste.schrift,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1,
    color: Palette.textOnDark,
    letterSpacing: 0.4,
    shadows: <Shadow>[
      Shadow(color: Color(0xCC1A0E05), offset: Offset(1, 1)),
      Shadow(color: Color(0x661A0E05), offset: Offset(1.5, 1.5), blurRadius: 2),
    ],
  );

  @override
  State<HaengeSchild> createState() => _HaengeSchildState();
}

class _HaengeSchildState extends State<HaengeSchild>
    with SingleTickerProviderStateMixin {
  late final AnimationController _schwung;

  /// Wie weit es anfangs ausschlägt, im Bogenmaß.
  static const double _ausschlag = 0.07;

  @override
  void initState() {
    super.initState();
    _schwung = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (SchildLeiste.schwingt && !still && _schwung.status.isDismissed) {
      _schwung.forward();
    }
  }

  @override
  void dispose() {
    _schwung.dispose();
    super.dispose();
  }

  /// Gedämpftes Pendel: zweieinhalb Schwünge, die auslaufen.
  static double winkel(double t) =>
      _ausschlag *
      math.exp(-3.2 * t) *
      math.cos(2 * math.pi * 2.5 * t) *
      (1 - t);

  @override
  Widget build(BuildContext context) {
    final brett = SizedBox(
      height: HaengeSchild.brett,
      child: CustomPaint(
        painter: const SchildMaler(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SchildLeiste.luft),
          child: Center(
            widthFactor: 1,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.titel,
                maxLines: 1,
                softWrap: false,
                style: HaengeSchild.schrift,
              ),
            ),
          ),
        ),
      ),
    );
    // Die Ketten nehmen die Breite des Bretts, deshalb liegen sie im
    // Stapel darüber statt in einer Spalte.
    final schild = Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: widget.kettenLaenge),
          child: brett,
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          // Ein Glied reicht in die Öse hinein.
          height: widget.kettenLaenge + 2 * HaengeSchild.pixel,
          child: const CustomPaint(painter: KettenMaler()),
        ),
      ],
    );
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _schwung,
        builder: (context, kind) => Transform.rotate(
          alignment: Alignment.topCenter,
          angle: _schwung.isAnimating ? winkel(_schwung.value) : 0,
          child: kind,
        ),
        child: schild,
      ),
    );
  }
}

/// Wo die Ketten am Brett sitzen, vom Rand aus in Bildpunkten.
const int _kettenEinzug = 9;

/// **Das Brett** — wie die Kartenrahmen: Leisten auf Gehrung mit Licht von
/// oben links, innen eine ruhige Tafel für die Schrift, oben zwei
/// Messingösen, an denen die Ketten hängen.
class SchildMaler extends CustomPainter {
  const SchildMaler({this.pixel = HaengeSchild.pixel});

  final double pixel;

  static const int _leiste = 3;

  Color? farbe(int x, int y, int w, int h) {
    final l = x, r = w - 1 - x, o = y, u = h - 1 - y;
    // Abgeschrägte Ecken.
    if (math.min(l, r) + math.min(o, u) < 2) return null;
    final rand = math.min(math.min(l, r), math.min(o, u));
    if (rand == 0 || math.min(l, r) + math.min(o, u) == 2) {
      return HolzTon.kante;
    }
    // Die Ösen der Ketten, im oberen Rahmen.
    for (final kx in <int>[_kettenEinzug, w - 1 - _kettenEinzug]) {
      final dx = x - kx, dy = y - 2;
      if (dx.abs() <= 1 && dy.abs() <= 1) {
        if (dx == 0 && dy == 0) return HolzTon.kante;
        if (dx < 0 || dy < 0) return HolzTon.messingHell;
        return dx > 0 && dy > 0 ? HolzTon.messingTief : HolzTon.messing;
      }
    }
    if (rand <= _leiste) {
      // Welche Leiste: die, deren Rand am nächsten ist — auf Gehrung.
      final waag = math.min(o, u) <= math.min(l, r);
      final oben = waag ? o <= u : null;
      final links = waag ? null : l <= r;
      if (oben == true) return rand == 1 ? HolzTon.glanz : HolzTon.licht;
      if (links == true) return rand == 1 ? HolzTon.licht : HolzTon.holz;
      if (oben == false) return rand == 1 ? HolzTon.tief : HolzTon.schatten;
      return rand == 1 ? HolzTon.schatten : HolzTon.holz;
    }
    // Die Fuge zwischen Rahmen und Tafel.
    if (rand == _leiste + 1) {
      return o == rand || l == rand ? HolzTon.tief : HolzTon.schatten;
    }
    // Die Tafel: ruhige Maserung, oben eine Spur heller.
    final f = HolzTon.faser(x, y * 2);
    if (f > 1.75) return HolzTon.schatten;
    return y < h * 0.45 ? HolzTon.holz : const Color(0xFF9C5A2C);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = (size.width / pixel).round();
    final h = (size.height / pixel).round();
    if (w < 8 || h < 8) return;
    _maleRaster(canvas, size, w, h, (x, y) => farbe(x, y, w, h));
  }

  @override
  bool shouldRepaint(SchildMaler alt) => alt.pixel != pixel;
}

/// **Die Ketten**: zwei Stränge aus Eisengliedern vom oberen Rand bis zu
/// den Ösen des Bretts, Glieder abwechselnd von vorn und von der Seite.
class KettenMaler extends CustomPainter {
  const KettenMaler({this.pixel = HaengeSchild.pixel});

  final double pixel;

  static const Color _hell = Color(0xFFB9B6C0);
  static const Color _mitte = Color(0xFF6E6A76);
  static const Color _tief = Color(0xFF2E2A33);

  /// Ein Glied von vorn ist so hoch, eines von der Seite [_steg].
  static const int _glied = 6, _steg = 3;

  Color? farbe(int x, int y, int w, int h) {
    // Von unten gezählt, damit an der Öse immer ein ganzes Glied hängt.
    final v = (h - 1 - y) % (_glied + _steg);
    for (final kx in <int>[_kettenEinzug, w - 1 - _kettenEinzug]) {
      final dx = x - kx;
      if (dx.abs() > 2) continue;
      if (v < _glied) {
        // Von vorn: ein Ring, fünf breit, innen offen.
        final rand = v == 0 || v == _glied - 1;
        if (rand) {
          if (dx.abs() == 2) continue;
          return v == _glied - 1 ? _hell : _tief;
        }
        if (dx.abs() < 2) return null;
        return dx < 0 ? _hell : _tief;
      }
      // Von der Seite: ein Steg, drei breit.
      if (dx.abs() == 2) continue;
      return dx < 0 ? _hell : (dx == 0 ? _mitte : _tief);
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = (size.width / pixel).round();
    final h = (size.height / pixel).round();
    if (w < 2 * _kettenEinzug || h < 1) return;
    _maleRaster(canvas, size, w, h, (x, y) => farbe(x, y, w, h));
  }

  @override
  bool shouldRepaint(KettenMaler alt) => alt.pixel != pixel;
}

/// Malt ein Raster aus Bildpunkten, je Farbe ein Pfad.
void _maleRaster(
  Canvas canvas,
  Size size,
  int w,
  int h,
  Color? Function(int x, int y) farbe,
) {
  final pw = size.width / w, ph = size.height / h;
  final pfade = <Color, Path>{};
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final c = farbe(x, y);
      if (c == null) continue;
      (pfade[c] ??= Path()).addRect(
        Rect.fromLTWH(x * pw, y * ph, pw + 0.01, ph + 0.01),
      );
    }
  }
  final p = Paint()..isAntiAlias = false;
  pfade.forEach((c, pfad) => canvas.drawPath(pfad, p..color = c));
}
