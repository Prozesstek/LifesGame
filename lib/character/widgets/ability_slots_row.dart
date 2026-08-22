import 'package:abilities/abilities.dart';
import 'package:combat/combat.dart';
import 'package:flutter/material.dart';
import 'package:progression/progression.dart';

import '../../ui/palette.dart';

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

  /// Was in Slot 1 liegt. Nie null: Ohne Waffe greift der Kurzbogen.
  final Move weaponMove;

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

  /// Was auf [slot] liegt. Null heisst leer — bei Slot 1 kommt das nicht
  /// vor.
  Move? _moveIn(int slot) {
    if (slot == 1) return weaponMove;

    final moveId = chosen.at(slot - 2);
    if (moveId == null) return null;
    return Moves.byId(moveId);
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
      backgroundColor: Palette.surface,
      builder: (sheetContext) {
        return SafeArea(
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
                    color: Colors.white,
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
    final move = Moves.byId(ability.moveId);
    if (move == null) return const SizedBox.shrink();

    return ListTile(
      title: Text(move.name, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        isElsewhere
            ? '${moveSummary(move)} · liegt auf einem anderen Platz'
            : moveSummary(move),
        style: TextStyle(color: isElsewhere ? Palette.gold : Palette.textDim),
      ),
      trailing: isChosen
          ? const Icon(Icons.check, color: Palette.accent)
          : null,
      onTap: onTap,
    );
  }
}

/// Was ein Move kostet und bringt, in einer Zeile.
///
/// Reine Darstellung — die Zahlen selbst stehen in `package:combat`. Hier
/// wird nur vorgelesen, was dort steht.
String moveSummary(Move move) {
  final teile = <String>[
    if (move.dealsDamage) 'Schaden ${move.power.toStringAsFixed(1)}',
    move.energyDelta >= 0
        ? '+${move.energyDelta} Energie'
        : '${move.energyDelta} Energie',
    for (final effect in move.effects) _effectLabel(effect),
  ];

  return teile.join(' · ');
}

String _effectLabel(MoveEffect effect) => switch (effect) {
  ApplyPoison() => 'vergiftet',
  ApplyDefenseDown() => 'senkt Verteidigung',
  HealSelf() => 'heilt',
  ShieldSelf() => 'schützt',
};

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
  final Move? move;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
                Icon(_icon, size: 18, color: _iconColour),
                const SizedBox(height: 6),
                Text(
                  _caption,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: move == null ? Palette.muted : Colors.white,
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
    return move?.name ?? 'leer';
  }

  String get _semantics {
    if (!isOpen) {
      return 'Platz $slot gesperrt, ab Level ${AbilitySlots.levelForSlot(slot)}';
    }
    if (isWeaponSlot) {
      return 'Platz $slot, kommt von der Waffe: ${move?.name}';
    }
    return move == null ? 'Platz $slot, leer' : 'Platz $slot, ${move?.name}';
  }
}
