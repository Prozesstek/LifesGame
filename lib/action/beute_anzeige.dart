import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui/gold_icon.dart';
import '../ui/level_abzeichen.dart';
import '../ui/palette.dart';
import 'action_game.dart';
import 'beute_regen.dart';

/// Die Kasse des Laufs: was an Gold beim Helden angekommen ist. Springt
/// bei jeder Münze kurz auf.
///
/// **Gezählt wird, was angekommen ist**, nicht was gefallen ist — die
/// Zahl soll mit den Münzen steigen, nicht vor ihnen. Nach einer
/// Niederlage zählt sie herunter und glüht rot (ADR-0083).
class LaufKasse extends StatelessWidget {
  const LaufKasse({super.key, required this.regen});

  final BeuteRegen regen;

  static const Key schluessel = ValueKey<String>('lauf-kasse');

  @override
  Widget build(BuildContext context) {
    final leuchten = regen.goldLeuchten;
    final farbe = regen.verloren ? Palette.enemyOnDark : Palette.goldOnDark;
    // Auf einem dunklen Schild: Die Kopfzeile liegt über dem Spielfeld,
    // und auf heller Wand verschwände Gold sonst.
    return Transform.scale(
      scale: 1 + 0.35 * leuchten,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Palette.chipOnDark.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: farbe.withValues(alpha: 0.4 + 0.6 * leuchten),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 7, 2),
          child: Row(
            key: schluessel,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const GoldIcon(size: 16),
              const SizedBox(width: 3),
              Text(
                '${regen.gold}',
                semanticsLabel: '${regen.gold} Gold in diesem Lauf',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color.lerp(farbe, Colors.white, leuchten),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Der Erfahrungsbalken am unteren Rand: das Level und wie weit es zum
/// nächsten ist — mit allem, was in diesem Lauf schon angekommen ist.
///
/// Nur in der Grube der Reihe; Tagesgrube und Prototyp zahlen keine
/// Erfahrung und zeigen ihn nicht. Nach einer Niederlage läuft er
/// zurück, und ein Aufstieg im Lauf fällt wieder ab (ADR-0083).
class ErfahrungsLeiste extends StatelessWidget {
  const ErfahrungsLeiste({super.key, required this.regen});

  final BeuteRegen regen;

  static const Key schluessel = ValueKey<String>('lauf-erfahrung');

  @override
  Widget build(BuildContext context) {
    final stand = regen.stand;
    if (stand == null) return const SizedBox.shrink();
    final leuchten = regen.xpLeuchten;
    final glut = regen.verloren ? Palette.enemyOnDark : Palette.accentOnDark;
    return Semantics(
      label:
          'Level ${stand.level}, '
          '${stand.xpIntoLevel} von ${stand.xpForLevel} Erfahrung',
      child: Row(
        key: schluessel,
        children: <Widget>[
          LevelAbzeichen(level: stand.level, size: 22),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: Palette.trackOnDark,
                borderRadius: BorderRadius.circular(4),
                boxShadow: <BoxShadow>[
                  if (leuchten > 0)
                    BoxShadow(
                      color: glut.withValues(alpha: 0.6 * leuchten),
                      blurRadius: 8,
                    ),
                ],
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: stand.ratio.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color.lerp(glut, Colors.white, leuchten * 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Der Aufstieg mitten im Lauf: Das neue Level springt gross in die
/// Mitte, leuchtet und zieht nach oben ab.
///
/// **Ohne Wort** (ADR-0060): Das Abzeichen trägt die Zahl, der Satz steht
/// nur für den Vorleser. Die Feier mit allem, was das Level bringt,
/// kommt wie bisher nach dem Lauf (`showLevelUp`).
class AufstiegsBild extends StatelessWidget {
  const AufstiegsBild({super.key, required this.game});

  final ActionGame game;

  static const Key schluessel = ValueKey<String>('lauf-aufstieg');

  @override
  Widget build(BuildContext context) {
    final fortschritt = game.beute.aufstieg;
    final stand = game.beute.stand;
    if (fortschritt == null || stand == null) return const SizedBox.shrink();

    // Erst ein Sprung über die Grösse hinaus, dann setzt es sich; im
    // letzten Drittel steigt es und verblasst.
    final sprung = fortschritt < 0.15
        ? 0.4 + 1.0 * (fortschritt / 0.15)
        : 1.4 - 0.4 * math.min(1, (fortschritt - 0.15) / 0.15);
    final aus = fortschritt < 0.66 ? 1.0 : 1 - (fortschritt - 0.66) / 0.34;
    final steigen = fortschritt < 0.66 ? 0.0 : (fortschritt - 0.66) * 120;

    return Align(
      alignment: const Alignment(0, -0.25),
      child: Transform.translate(
        offset: Offset(0, -steigen),
        child: Opacity(
          opacity: aus.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: sprung,
            child: Semantics(
              label: 'Aufstieg auf Level ${stand.level}',
              child: DecoratedBox(
                key: schluessel,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Palette.goldOnDark.withValues(alpha: 0.7),
                      blurRadius: 36,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: LevelAbzeichen(level: stand.level, size: 72),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
