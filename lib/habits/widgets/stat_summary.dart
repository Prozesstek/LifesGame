import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../ui/palette.dart';

/// Die vier Charakterwerte nebeneinander.
///
/// Steht bewusst über der Liste: Wer abhakt, soll im selben Blick sehen,
/// wohin es geht. Ohne diese Zeile bliebe der Kern-Loop des Konzepts
/// unsichtbar.
class StatSummary extends StatelessWidget {
  const StatSummary({required this.stats, super.key});

  final CharacterStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final stat in HabitStat.values) ...<Widget>[
          Expanded(
            child: _StatCell(stats: stats, stat: stat),
          ),
          if (stat != HabitStat.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.stats, required this.stat});

  final CharacterStats stats;
  final HabitStat stat;

  @override
  Widget build(BuildContext context) {
    final bonus = stats.bonusFor(stat);
    final remaining = stats.checksToNextPoint(stat);

    return Semantics(
      label: '${stat.label} ${stats.valueFor(stat)}, ${stat.combatLabel}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              stat.label,
              style: const TextStyle(fontSize: 11, color: Palette.textDim),
            ),
            const SizedBox(height: 4),
            // **Beide Zahlen schrumpfbar.** Eine Kachel ist ein Viertel
            // der Breite; „224" neben „+64" ist die längste Fassung, und
            // zwei feste Texte in einer `Row` sind der Fall aus
            // `gotchas.md`. Er ist hier erst aufgefallen, als der
            // Layout-Test einen Stand **mit** Häkchen bekam — ohne
            // Zugewinn wurde die zweite Zahl gar nicht gebaut.
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Flexible(
                  child: Text(
                    '${stats.valueFor(stat)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Palette.text,
                    ),
                  ),
                ),
                if (bonus > 0) ...<Widget>[
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      '+$bonus',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Palette.success,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 5),
            StatPointBar(stats: stats, stat: stat),
            const SizedBox(height: 3),
            Text(
              stats.isAtCap(stat) ? 'am Maximum' : 'noch $remaining',
              style: const TextStyle(fontSize: 10, color: Palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wie weit das nächste **Punkt** dieses Werts gefüllt ist.
///
/// **Die Antwort auf „Gewohnheiten sollen Stats sofort erhöhen"**
/// (Issue #46). Ein Punkt Stärke kostet fünf Häkchen; vier von fünf Malen
/// bewegte sich die Zahl darüber also nicht, und der Zusammenhang
/// zwischen Abhaken und Charakter war unsichtbar. Der Balken bewegt sich
/// bei **jedem** Häkchen.
///
/// Die Kurve selbst bleibt unangetastet: Fünf Häkchen sind weiter ein
/// Punkt. Sie feiner zu machen ginge auch gar nicht — Stärke hat über
/// ein Spielerleben sieben Punkte zu vergeben (`StatCurve`), und die
/// Balance-Simulation hängt an dieser Spanne.
class StatPointBar extends StatelessWidget {
  const StatPointBar({required this.stats, required this.stat, super.key});

  final CharacterStats stats;
  final HabitStat stat;

  /// Wie lange der Balken zu seinem neuen Stand läuft.
  static const Duration duration = Duration(milliseconds: 400);

  /// Der Anteil zwischen 0 und 1. Am Deckel voll.
  double get fraction {
    if (stats.isAtCap(stat)) return 1;
    final proSchritt = StatCurve.ruleFor(stat).checksPerPoint;
    if (proSchritt <= 0) return 0;
    final offen = stats.checksToNextPoint(stat);
    return ((proSchritt - offen) / proSchritt).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final amDeckel = stats.isAtCap(stat);

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: fraction),
        duration: duration,
        curve: Curves.easeOut,
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: 3,
          backgroundColor: Palette.surfaceSunken,
          valueColor: AlwaysStoppedAnimation<Color>(
            amDeckel ? Palette.muted : Palette.success,
          ),
        ),
      ),
    );
  }
}
