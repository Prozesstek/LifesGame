import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:progression/progression.dart';

import '../../skills/widgets/gebiets_balken.dart';
import '../../ui/aufstieg.dart';
import '../../ui/beute_flug.dart';
import '../../ui/druck.dart';
import '../../ui/gold_icon.dart';
import '../../ui/level_abzeichen.dart';
import '../../ui/palette.dart';

/// **Level und Gold oben rechts** — das Abzeichen mit einem Ring darum,
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
/// **Steht auf der Startseite und auf dem Gewohnheiten-Bildschirm**, beide
/// Male auf dunklem Leder.
class StatusLeiste extends StatelessWidget {
  const StatusLeiste({
    required this.xp,
    required this.gold,
    this.links,
    super.key,
  });

  /// Was ganz links steht — auf der Startseite das Haustier.
  final Widget? links;

  /// Die ganze Erfahrung, wie `effectiveXpProvider` sie nennt.
  final int xp;
  final int gold;

  /// Der Ring, zum Finden in Tests: Ein Tipp sagt, wie viel noch fehlt.
  static const Key ringKey = ValueKey<String>('level-ring');

  @override
  Widget build(BuildContext context) {
    final host = AufstiegHost.maybeOf(context);
    if (host == null) return _leiste(LevelCurve.levelFor(xp), gold);
    final unterwegsGold = host.unterwegs(FlugZiel.gold);
    final unterwegsXp = host.unterwegs(FlugZiel.erfahrung);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[unterwegsGold, unterwegsXp]),
      builder: (context, _) => _leiste(
        LevelCurve.levelFor(xp - unterwegsXp.value),
        gold - unterwegsGold.value,
      ),
    );
  }

  Widget _leiste(PlayerLevel level, int gold) {
    return Row(
      children: <Widget>[
        ?links,
        // Der Platz des Gebiets: leer, bis ein Häkchen fliegt.
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: 12),
            child: GebietsBalken(aufDunkel: true),
          ),
        ),
        Tooltip(
          triggerMode: TooltipTriggerMode.tap,
          message: level.isMaxLevel
              ? 'Höchste Stufe erreicht'
              : '${level.xpIntoLevel} von ${level.xpForLevel} Erfahrung '
                    'bis Level ${level.level + 1}',
          child: Druck(
            child: FlugZielMarke(
              ziel: FlugZiel.erfahrung,
              staerke: 0.12,
              child: LevelRing(
                key: ringKey,
                level: level.level,
                anteil: level.ratio,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FlugZielMarke(
          ziel: FlugZiel.gold,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const GoldIcon(),
              const SizedBox(width: 5),
              // Die Zahl schrumpft nicht — ein Goldbetrag mit
              // Auslassungspunkten wäre keine Zahl mehr.
              Text(
                '$gold',
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Palette.goldOnDark,
                ),
              ),
            ],
          ),
        ),
      ],
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
