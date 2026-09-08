import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../../ui/palette.dart';

/// Welche Ausrüstungs-Sets gerade wirken — und was daran noch fehlt.
///
/// **Zeigt auch die, die noch gar nicht wirken.** Ein Set, von dem man ein
/// Teil trägt, ohne es zu wissen, ist kein Ziel; es ist Zufall. Die Karte
/// nennt deshalb jedes Set, von dem mindestens ein Stück angelegt ist,
/// samt der Zahl, die noch fehlt.
class SetCard extends StatelessWidget {
  const SetCard({required this.loadout, super.key});

  final Loadout loadout;

  /// Jedes Set, von dem etwas getragen wird — auch unterhalb der ersten
  /// Stufe.
  List<({GearSet set, int pieces, SetPerk? perk})> get _rows {
    final rows = <({GearSet set, int pieces, SetPerk? perk})>[];
    for (final set in GearSets.all) {
      final pieces = loadout.equippedPiecesOf(set.id);
      if (pieces == 0) continue;
      rows.add((set: set, pieces: pieces, perk: set.perkFor(pieces)));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    // Dieselbe Frage wie im Charakterbildschirm, dieselbe Antwort:
    // `Loadout.wearsAnySetPiece` (`docs/context/gotchas.md`).
    if (!loadout.wearsAnySetPiece) return const SizedBox.shrink();
    final rows = _rows;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 18, color: Palette.surfaceRaised),
            _SetRow(
              set: rows[i].set,
              pieces: rows[i].pieces,
              perk: rows[i].perk,
            ),
          ],
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.set, required this.pieces, required this.perk});

  final GearSet set;
  final int pieces;
  final SetPerk? perk;

  bool get _isActive => perk != null;

  @override
  Widget build(BuildContext context) {
    final naechste = pieces < GearSet.smallSize
        ? GearSet.smallSize
        : GearSet.fullSize;
    final fehlt = naechste - pieces;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Zwei Texte nebeneinander, beide schrumpffähig — die Regel aus
        // `docs/context/gotchas.md`.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: Text(
                set.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _isActive ? Palette.accent : Palette.textDim,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$pieces / ${GearSet.fullSize}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _isActive ? Palette.accent : Palette.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        if (perk case final SetPerk aktiv)
          Text(
            '${aktiv.labels.join(' · ')} auf ${set.target.label}',
            style: const TextStyle(fontSize: 12, color: Palette.success),
          ),
        if (fehlt > 0) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            fehlt == 1
                ? 'Noch ein Teil bis zur nächsten Stufe.'
                : 'Noch $fehlt Teile bis zur nächsten Stufe.',
            style: const TextStyle(fontSize: 12, color: Palette.textDim),
          ),
        ],
      ],
    );
  }
}
