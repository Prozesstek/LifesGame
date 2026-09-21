import 'package:flutter/material.dart';
import 'package:identity/identity.dart';
import 'package:progression/progression.dart';

import '../../ui/holz.dart';
import '../../ui/palette.dart';

/// Der Kopf des Charakterbildschirms: wer der Charakter ist.
///
/// Zeigt Name und Titel zusammen in einer Zeile — „Frederik, der
/// Beständige" — und führt zu den beiden Eingaben. Die Trennung ist
/// bewusst: Der Name wird **eingegeben**, der Titel nur **ausgewählt** aus
/// dem, was verdient ist (ADR-0013).
class IdentityCard extends StatelessWidget {
  const IdentityCard({
    required this.identity,
    required this.earnedTitleIds,
    required this.level,
    required this.gold,
    required this.fame,
    required this.onEditName,
    required this.onChooseTitle,
    super.key,
  });

  final Identity identity;

  /// Welche Titel verdient sind. Kommt seit ADR-0033 aus den
  /// Errungenschaften; vorher rechnete `package:identity` es selbst aus
  /// drei Zahlen.
  final Set<String> earnedTitleIds;

  /// Das ganze Level, nicht nur die Zahl: Der Balken braucht auch, wie
  /// weit es bis zum nächsten ist. Gerechnet wird das in
  /// `package:progression`, hier wird nur angezeigt.
  final PlayerLevel level;
  final int gold;

  /// Der Ruhm-Stand. **Eine Zahl zum Vergleichen, kein Guthaben**
  /// (ADR-0033, Punkt 5) — deshalb steht sie neben dem Gold und nicht
  /// darunter mit einem Knopf daneben.
  final int fame;
  final VoidCallback onEditName;
  final VoidCallback onChooseTitle;

  @override
  Widget build(BuildContext context) {
    final title = identity.titleFor(earnedTitleIds);

    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      color: Palette.surfaceRaised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.person_outline, size: 30, color: Palette.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      identity.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: identity.hasName ? Palette.text : Palette.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title == null
                          ? 'Level ${level.level}'
                          : '${title.label} · Level ${level.level}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Palette.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '$gold Gold',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Palette.gold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$fame Ruhm',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Palette.textDim,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Alles hier kommt aus dem, was du getan hast.',
            style: TextStyle(fontSize: 12, color: Palette.muted),
          ),
          const SizedBox(height: 12),
          _LevelBar(level: level),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _Knopf(
                  onPressed: onEditName,
                  icon: Icons.edit_outlined,
                  label: identity.hasName ? 'Name ändern' : 'Name geben',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Knopf(
                  onPressed: onChooseTitle,
                  icon: Icons.military_tech_outlined,
                  label: 'Titel',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Wie weit es bis zum nächsten Level ist.
///
/// **Warum der Balken hier oben steht und nicht bei den Werten.** Er ist
/// der einzige Fortschritt auf diesem Bildschirm, der sich täglich bewegt;
/// die vier Kampfwerte stehen nach etwa 35 Tagen still (ADR-0013). Ohne
/// ihn zeigt der Kopf eine Zahl, die sich alle paar Tage einmal ändert.
class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.level});

  final PlayerLevel level;

  @override
  Widget build(BuildContext context) {
    if (level.isMaxLevel) {
      return const Text(
        'Höchste Stufe erreicht.',
        style: TextStyle(fontSize: 12, color: Palette.gold),
      );
    }

    // Ein frisches Level steht bei 0 — der Balken muss das aushalten,
    // ohne durch null zu teilen.
    final anteil = level.xpForLevel <= 0
        ? 0.0
        : (level.xpIntoLevel / level.xpForLevel).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        HolzBalken(value: anteil, color: Palette.accent),
        const SizedBox(height: 5),
        Text(
          '${level.xpIntoLevel} / ${level.xpForLevel} bis Level '
          '${level.level + 1}',
          style: const TextStyle(fontSize: 11, color: Palette.textDim),
        ),
      ],
    );
  }
}

/// Ein Knopf mit Symbol, dessen Text schrumpfen darf.
///
/// **`OutlinedButton.icon` lässt ihn nicht schrumpfen** — Symbol und Text
/// stehen dort in einer Zeile ohne `Flexible`. Seit die Karte im
/// Holzrahmen liegt, ist sie 24 Punkte schmaler, und in der halben Breite
/// wird „Name ändern" bei grösserer Schrift knapp. Vorbeugend: Zwei Dinge
/// nebeneinander brauchen `Flexible` (`gotchas.md`).
class _Knopf extends StatelessWidget {
  const _Knopf({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
