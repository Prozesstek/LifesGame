import 'package:flutter/material.dart';
import 'package:identity/identity.dart';
import 'package:progression/progression.dart';

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
    required this.stats,
    required this.level,
    required this.gold,
    required this.onEditName,
    required this.onChooseTitle,
    super.key,
  });

  final Identity identity;
  final TitleStats stats;

  /// Das ganze Level, nicht nur die Zahl: Der Balken braucht auch, wie
  /// weit es bis zum nächsten ist. Gerechnet wird das in
  /// `package:progression`, hier wird nur angezeigt.
  final PlayerLevel level;
  final int gold;
  final VoidCallback onEditName;
  final VoidCallback onChooseTitle;

  @override
  Widget build(BuildContext context) {
    final title = identity.titleFor(stats);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Palette.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
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
                        color: identity.hasName ? Colors.white : Palette.muted,
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
              Text(
                '$gold Gold',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Palette.gold,
                ),
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
                child: OutlinedButton.icon(
                  onPressed: onEditName,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(identity.hasName ? 'Name ändern' : 'Name geben'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChooseTitle,
                  icon: const Icon(Icons.military_tech_outlined, size: 18),
                  label: const Text('Titel'),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: anteil,
            minHeight: 7,
            backgroundColor: Palette.surface,
            valueColor: const AlwaysStoppedAnimation<Color>(Palette.accent),
          ),
        ),
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
