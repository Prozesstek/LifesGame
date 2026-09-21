import 'package:abilities/abilities.dart';
import 'package:flutter/material.dart';
import 'package:progression/progression.dart';

import '../../action/pit_text.dart';
import '../../combat/move_icon.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';
import '../../ui/holz.dart';

/// Die vier Fähigkeitsslots nebeneinander.
///
/// **Warum die Slots dastehen, auch wenn sie leer sind.** Hausregel aus
/// ADR-0013, dort schon für den gesperrten vierten Slot formuliert: „Ein
/// Startbildschirm, der nur zeigt, was schon fertig ist, verschweigt,
/// worum es geht." Ein Spieler auf Level 2 soll sehen, dass auf Level 3
/// etwas aufgeht — sonst ist der Aufstieg eine Zahl.
///
/// **Slot 1 gehört der Waffe** (ADR-0013, ADR-0017): Er ist von Level 1 an
/// offen und trägt, was die getragene Waffe mitbringt. Er wird nicht
/// gewählt — deshalb ist er der einzige, der sich nicht antippen lässt.
class AbilitySlotsRow extends StatelessWidget {
  const AbilitySlotsRow({
    required this.level,
    required this.weaponMove,
    required this.chosen,
    required this.unlocked,
    required this.onChoose,
    required this.onClear,
    super.key,
  });

  final int level;

  /// Der Waffenzug in Slot 1. Nie leer: Ohne Waffe greift der Kurzbogen.
  final String weaponMove;

  /// Was auf den freien Slots liegt.
  final ChosenAbilities chosen;

  /// Was der Spieler auf einen freien Slot legen darf.
  final List<Ability> unlocked;

  /// [index] zählt die **freien** Slots ab 0 — Slot 1 ist nicht dabei.
  final void Function(int index, String moveId) onChoose;
  final void Function(int index) onClear;

  @override
  Widget build(BuildContext context) {
    final open = AbilitySlots.openAt(level);
    final next = AbilitySlots.nextUnlockAfter(level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (var slot = 1; slot <= AbilitySlots.total; slot++) ...<Widget>[
              if (slot > 1) const SizedBox(width: 8),
              Expanded(
                child: _Slot(
                  slot: slot,
                  isOpen: slot <= open,
                  isWeaponSlot: slot == 1,
                  move: _moveIn(slot),
                  onTap: slot == 1 || slot > open
                      ? null
                      : () => _pick(context, slot - 2),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _hint(next, open),
          style: const TextStyle(fontSize: 12, color: Palette.textDim),
        ),
      ],
    );
  }

  /// Die Id auf [slot]. Null heisst leer — bei Slot 1 kommt das nicht
  /// vor.
  String? _moveIn(int slot) {
    if (slot == 1) return weaponMove;
    return chosen.at(slot - 2);
  }

  /// Der Satz unter den Slots.
  ///
  /// Nennt die nächste Stufe, damit ein gesperrter Platz ein Ziel ist
  /// statt einer Absage — und sagt bei offenen leeren Plätzen, dass da
  /// etwas hingehört.
  String _hint(int? next, int open) {
    final frei = open - 1;
    final belegt = chosen.length;

    if (next != null && belegt >= frei) {
      return 'Nächster Platz ab Level $next.';
    }
    if (belegt < frei) {
      final offen = frei - belegt;
      return offen == 1
          ? 'Ein Platz ist noch frei — antippen und belegen.'
          : '$offen Plätze sind noch frei — antippen und belegen.';
    }
    return 'Alle vier Plätze offen und belegt.';
  }

  Future<void> _pick(BuildContext context, int freeIndex) async {
    final current = chosen.at(freeIndex);

    final result = await showModalBottomSheet<_Pick>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (sheetContext) {
        return HolzBlatt(
          child: SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Text(
                    'Fähigkeit wählen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Palette.text,
                    ),
                  ),
                ),
                if (unlocked.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Text(
                      'Noch nichts freigeschaltet.',
                      style: TextStyle(color: Palette.muted),
                    ),
                  ),
                for (final ability in unlocked)
                  _AbilityOption(
                    ability: ability,
                    isChosen: ability.moveId == current,
                    // Was anderswo liegt, wird nicht versteckt: Antippen
                    // schiebt es hierher. Erst aufräumen zu müssen, bevor man
                    // umstellen kann, wäre ein Umweg ohne Gewinn.
                    isElsewhere:
                        ability.moveId != current &&
                        chosen.contains(ability.moveId),
                    onTap: () =>
                        Navigator.of(sheetContext).pop(_Pick(ability.moveId)),
                  ),
                if (current != null)
                  ListTile(
                    leading: const Icon(Icons.close, color: Palette.muted),
                    title: const Text(
                      'Platz räumen',
                      style: TextStyle(color: Palette.textDim),
                    ),
                    onTap: () =>
                        Navigator.of(sheetContext).pop(const _Pick(null)),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) return;
    final moveId = result.moveId;
    if (moveId == null) {
      onClear(freeIndex);
    } else {
      onChoose(freeIndex, moveId);
    }
  }
}

/// Ein Eintrag im Auswahlblatt.
class _AbilityOption extends StatelessWidget {
  const _AbilityOption({
    required this.ability,
    required this.isChosen,
    required this.isElsewhere,
    required this.onTap,
  });

  final Ability ability;
  final bool isChosen;

  /// Ob dieselbe Fähigkeit bereits auf einem anderen Platz liegt.
  final bool isElsewhere;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = pitNameOf(ability.moveId);
    final zeile = pitSummaryOf(ability.moveId);
    if (name == null || zeile == null) return const SizedBox.shrink();

    return ListTile(
      leading: _MoveBild(
        moveId: ability.moveId,
        side: 36,
        fallback: const Icon(Icons.bolt, color: Palette.accent),
      ),
      title: Text(name, style: const TextStyle(color: Palette.text)),
      subtitle: Text(
        isElsewhere ? '$zeile · liegt auf einem anderen Platz' : zeile,
        style: TextStyle(color: isElsewhere ? Palette.gold : Palette.textDim),
      ),
      trailing: isChosen
          ? const Icon(Icons.check, color: Palette.accent)
          : null,
      onTap: onTap,
    );
  }
}

/// Das Bild einer Fähigkeit — oder [fallback], solange sie keins hat.
///
/// Immer [side] groß, auch mit Zeichen statt Bild: Sonst stünden im
/// Auswahlblatt die Namen nicht bündig und die Plätze wären verschieden
/// hoch, je nachdem, was darauf liegt.
class _MoveBild extends StatelessWidget {
  const _MoveBild({
    required this.moveId,
    required this.side,
    required this.fallback,
  });

  final String moveId;
  final double side;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final pfad = MoveIcons.forMoveId(moveId);
    final ersatz = SizedBox.square(
      dimension: side,
      child: Center(child: fallback),
    );

    if (pfad == null) return ersatz;
    return PixelArt(assetPath: pfad, side: side, fallback: ersatz);
  }
}

/// Was das Auswahlblatt zurückgibt. Eigener Typ, weil Abbrechen (null vom
/// Blatt) und Räumen (moveId null) zwei verschiedene Antworten sind.
class _Pick {
  const _Pick(this.moveId);

  final String? moveId;
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.slot,
    required this.isOpen,
    required this.isWeaponSlot,
    required this.move,
    required this.onTap,
  });

  final int slot;
  final bool isOpen;
  final bool isWeaponSlot;

  /// Die Id auf diesem Platz, oder null.
  final String? move;
  final VoidCallback? onTap;

  /// Kantenlänge des Bildes auf einem Platz.
  static const double _bildSeite = 32;

  @override
  Widget build(BuildContext context) {
    final belegt = move;
    final zeichen = Icon(_icon, size: 18, color: _iconColour);

    return Semantics(
      button: onTap != null,
      label: _semantics,
      child: Material(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: move == null ? Palette.background : Palette.accent,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (isOpen && belegt != null)
                  _MoveBild(moveId: belegt, side: _bildSeite, fallback: zeichen)
                else
                  SizedBox.square(
                    dimension: _bildSeite,
                    child: Center(child: zeichen),
                  ),
                const SizedBox(height: 6),
                Text(
                  _caption,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: move == null ? Palette.muted : Palette.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon {
    if (!isOpen) return Icons.lock_outline;
    if (isWeaponSlot) return Icons.colorize;
    return move == null ? Icons.add_circle_outline : Icons.bolt;
  }

  Color get _iconColour {
    if (!isOpen) return Palette.muted;
    return move == null ? Palette.muted : Palette.accent;
  }

  String get _caption {
    if (!isOpen) return 'ab Level ${AbilitySlots.levelForSlot(slot)}';
    final id = move;
    return id == null ? 'leer' : (pitNameOf(id) ?? id);
  }

  String get _semantics {
    if (!isOpen) {
      return 'Platz $slot gesperrt, ab Level ${AbilitySlots.levelForSlot(slot)}';
    }
    if (isWeaponSlot) {
      return 'Platz $slot, kommt von der Waffe: $_caption';
    }
    return move == null ? 'Platz $slot, leer' : 'Platz $slot, $_caption';
  }
}
