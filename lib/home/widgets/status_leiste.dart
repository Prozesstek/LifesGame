import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:progression/progression.dart';

import '../../progression/widgets/level_roadmap_blatt.dart';
import '../../skills/widgets/gebiets_balken.dart';
import '../../ui/aufstieg.dart';
import '../../ui/beute_flug.dart';
import '../../ui/druck.dart';
import '../../ui/gold_icon.dart';
import '../../ui/level_abzeichen.dart';
import '../../ui/palette.dart';

/// **Level oben rechts, das Gold nur kurz** — das Abzeichen mit einem Ring darum,
/// der die Erfahrung bis zum nächsten Level zeigt, daneben das Gold
/// (Frederik, 22.10.2026).
///
/// **Bis dahin eine Karte zwischen den Kreisen und „Heute“**, mit einem
/// geraden Balken. Oben rechts steht es, wo man es in Spielen sucht, und
/// „Heute“ bekommt den Platz.
///
/// **Links daneben wartet der Balken des Gebiets** (ADR-0085): Er blendet
/// sich ein, wenn ein Häkchen seine grünen Funken wirft, und sagt damit,
/// dass dieselbe Erfahrung auch in den Skill geht (`GebietsBalken`). Sein
/// Platz ist immer reserviert; ohne Häkchen ist er leer.
///
/// **Sie zeigt, was angekommen ist** (18.10.). Ein Häkchen wirft Münzen
/// zur Goldzahl und Funken in den Ring (`BeuteFlug`); was noch fliegt,
/// zieht sie ab, und so steigen Zahl und Ring mit jedem Stück, das
/// ankommt. Deshalb nimmt sie die Erfahrung und schlägt das Level selbst
/// nach — wie `playerLevelProvider`, nur ohne das, was noch unterwegs ist.
///
/// **Links steht auf der Startseite das Haustier** (24.10.2026), ohne
/// Rahmen ([links]).
///
/// **Steht auf der Startseite, auf dunklem Leder, und in der Titelzeile des
/// Gewohnheiten-Bildschirms** (ADR-0092).
/// Dort ist sie [klein], auf Pergament und ohne den Balken des Gebiets: Die
/// Funken fliegen dort in die Kacheln der Gebiete.
class StatusLeiste extends StatelessWidget {
  const StatusLeiste({
    required this.xp,
    required this.gold,
    this.links,
    this.klein = false,
    super.key,
  });

  /// Was ganz links steht — auf der Startseite das Haustier.
  final Widget? links;

  /// Für die Titelzeile: kleiner Ring, nur so breit wie nötig.
  final bool klein;

  /// Wie groß der Ring in der Titelzeile ist.
  static const double kleinerRing = 42;

  /// Die ganze Erfahrung, wie `effectiveXpProvider` sie nennt.
  final int xp;
  final int gold;

  /// Der Ring, zum Finden in Tests: Ein Tipp öffnet die Roadmap.
  static const Key ringKey = ValueKey<String>('level-ring');

  @override
  Widget build(BuildContext context) {
    final host = AufstiegHost.maybeOf(context);
    if (host == null) return _leiste(LevelCurve.levelFor(xp), gold, 0);
    final unterwegsGold = host.unterwegs(FlugZiel.gold);
    final unterwegsXp = host.unterwegs(FlugZiel.erfahrung);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[unterwegsGold, unterwegsXp]),
      builder: (context, _) => _leiste(
        LevelCurve.levelFor(xp - unterwegsXp.value),
        gold - unterwegsGold.value,
        unterwegsGold.value,
      ),
    );
  }

  Widget _leiste(PlayerLevel level, int gold, int goldUnterwegs) {
    return Row(
      mainAxisSize: klein ? MainAxisSize.min : MainAxisSize.max,
      children: <Widget>[
        ?links,
        // Der Platz des Gebiets: leer, bis ein Häkchen fliegt.
        if (!klein)
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 12),
              child: GebietsBalken(aufDunkel: true),
            ),
          ),
        // **Ein Tipp öffnet die Roadmap** (ADR-0098): wie viel fehlt, und
        // was die nächsten Level bringen. Bis dahin stand hier nur der
        // Satz zur Erfahrung als Tooltip.
        Builder(
          builder: (context) => Semantics(
            button: true,
            child: Druck(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => LevelRoadmapBlatt.zeige(context, level),
                child: FlugZielMarke(
                  ziel: FlugZiel.erfahrung,
                  staerke: 0.12,
                  child: LevelRing(
                    key: ringKey,
                    level: level.level,
                    anteil: level.ratio,
                    groesse: klein ? kleinerRing : 54,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        KurzesGold(gold: gold, unterwegs: goldUnterwegs, klein: klein),
      ],
    );
  }
}

/// **Das Gold zeigt sich nur, wenn es mehr wird** (06.11.2026, Frederik:
/// „Gold soll nur da angezeigt werden, wo es auch wirklich gebraucht
/// wird … man sieht es kurz, wenn es sich erhöht, verschwindet dann
/// aber wieder“). Gebraucht wird es im Laden, beim Haustier und beim
/// Verkaufen; hier fliegen nur die Münzen eines Häkchens hin.
///
/// **Der Platz bleibt, und die Marke auch**: Unsichtbar ist es das Ziel
/// der Münzen (`FlugZielMarke`), und es tauchte sonst ohne Ziel auf.
/// Solange Münzen fliegen, steht es; danach hält es [halten] und blendet
/// aus — **über einen Takt, keinen Zeitgeber** (`gotchas.md`).
class KurzesGold extends StatefulWidget {
  const KurzesGold({
    required this.gold,
    required this.unterwegs,
    this.klein = false,
    super.key,
  });

  /// Was angekommen ist.
  final int gold;

  /// Was noch fliegt.
  final int unterwegs;

  final bool klein;

  /// Einblenden, stehen, ausblenden.
  static const Duration ein = Duration(milliseconds: 200);
  static const Duration halten = Duration(milliseconds: 1600);
  static const Duration aus = Duration(milliseconds: 400);

  /// Woran Tests es finden.
  static const Key goldKey = ValueKey<String>('kurzes-gold');

  @override
  State<KurzesGold> createState() => _KurzesGoldState();
}

class _KurzesGoldState extends State<KurzesGold>
    with SingleTickerProviderStateMixin {
  // In `initState`, nicht faul (`gotchas.md`).
  late final AnimationController _takt;

  static final double _einEnde =
      KurzesGold.ein.inMicroseconds / _gesamt.inMicroseconds;
  static final double _haltenEnde =
      (KurzesGold.ein + KurzesGold.halten).inMicroseconds /
      _gesamt.inMicroseconds;
  static final Duration _gesamt =
      KurzesGold.ein + KurzesGold.halten + KurzesGold.aus;

  @override
  void initState() {
    super.initState();
    _takt = AnimationController(vsync: this, duration: _gesamt);
    if (widget.unterwegs > 0) _zeige();
  }

  @override
  void didUpdateWidget(KurzesGold alt) {
    super.didUpdateWidget(alt);
    final mehr = widget.gold > alt.gold;
    final fliegt = widget.unterwegs > alt.unterwegs;
    if (mehr || fliegt) _zeige();
  }

  /// Steht es schon, bleibt es stehen und hält von vorn; sonst blendet es
  /// ein.
  void _zeige() {
    final steht = _takt.value >= _einEnde && _takt.value < _haltenEnde;
    _takt.forward(from: steht ? _einEnde : 0);
  }

  @override
  void dispose() {
    _takt.dispose();
    super.dispose();
  }

  double _deckkraft() {
    final t = _takt.value;
    if (!_takt.isAnimating && (t == 0 || t == 1)) return 0;
    if (t < _einEnde) return t / _einEnde;
    if (t < _haltenEnde) return 1;
    return (1 - (t - _haltenEnde) / (1 - _haltenEnde)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _takt,
      builder: (context, kind) {
        final deckkraft = _deckkraft();
        return ExcludeSemantics(
          excluding: deckkraft == 0,
          child: Opacity(opacity: deckkraft, child: kind),
        );
      },
      child: FlugZielMarke(
        ziel: FlugZiel.gold,
        child: Row(
          key: KurzesGold.goldKey,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const GoldIcon(),
            const SizedBox(width: 5),
            // Die Zahl schrumpft nicht — ein Goldbetrag mit
            // Auslassungspunkten wäre keine Zahl mehr.
            Text(
              '${widget.gold}',
              maxLines: 1,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                // Die Titelzeile ist Pergament, nicht Leder.
                color: widget.klein ? Palette.gold : Palette.goldOnDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// **Das Level-Abzeichen mit einem Ring darum**: Der Ring füllt sich mit
/// der Erfahrung bis zum nächsten Level, von oben im Uhrzeigersinn.
class LevelRing extends StatelessWidget {
  const LevelRing({
    required this.level,
    required this.anteil,
    this.groesse = 54,
    super.key,
  });

  final int level;

  /// Wie voll der Ring ist, 0..1.
  final double anteil;

  final double groesse;

  /// Wie breit der Ring ist.
  static const double breite = 4.5;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Level $level, ${(anteil * 100).round()} Prozent zum nächsten',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: groesse,
        child: CustomPaint(
          painter: _RingMaler(anteil.clamp(0.0, 1.0)),
          child: Center(
            child: LevelAbzeichen(level: level, size: groesse - 2 * breite - 4),
          ),
        ),
      ),
    );
  }
}

class _RingMaler extends CustomPainter {
  _RingMaler(this.anteil);

  final double anteil;

  @override
  void paint(Canvas canvas, Size size) {
    final mitte = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - LevelRing.breite / 2;
    final bahn = Paint()
      ..color = Palette.textOnDarkDim.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = LevelRing.breite;
    canvas.drawCircle(mitte, radius, bahn);
    if (anteil <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: mitte, radius: radius),
      -math.pi / 2,
      2 * math.pi * anteil,
      false,
      Paint()
        ..color = Palette.accentOnDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = LevelRing.breite
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingMaler alt) => alt.anteil != anteil;
}
