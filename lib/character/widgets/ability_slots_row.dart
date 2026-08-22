import 'package:flutter/material.dart';
import 'package:gear/gear.dart';
import 'package:progression/progression.dart';

import '../../ui/palette.dart';

/// Die vier Fähigkeitsslots nebeneinander.
///
/// **Warum die Slots dastehen, obwohl es noch keine Fähigkeiten gibt.**
/// Hausregel aus ADR-0013, dort schon für den gesperrten vierten Slot
/// formuliert: „Ein Startbildschirm, der nur zeigt, was schon fertig ist,
/// verschweigt, worum es geht." Ein Spieler auf Level 2 soll sehen, dass
/// auf Level 3 etwas aufgeht — sonst ist der Aufstieg eine Zahl.
///
/// **Slot 1 gehört der Waffe** (ADR-0013): Drei Slots sind frei wählbar,
/// einer wird von der getragenen Waffe bestimmt. Deshalb steht er von
/// Level 1 an offen und zeigt, was gerade getragen wird.
///
/// **Was hier noch nicht steht:** die Fähigkeiten selbst. Welche zwanzig
/// es gibt und was sie tun, ist nicht entschieden. Bis dahin zeigt ein
/// offener Slot „leer" — und der Satz darunter sagt, warum.
class AbilitySlotsRow extends StatelessWidget {
  const AbilitySlotsRow({required this.level, required this.weapon, super.key});

  final int level;

  /// Die getragene Waffe. Null heißt: keine angelegt.
  final GearItem? weapon;

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
                  weapon: weapon,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _hint(next),
          style: const TextStyle(fontSize: 12, color: Palette.textDim),
        ),
      ],
    );
  }

  /// Der Satz unter den Slots.
  ///
  /// Er hat zwei Aufgaben, und beide sind Ehrlichkeit: Er nennt die
  /// nächste Stufe, damit ein gesperrter Platz ein Ziel ist statt einer
  /// Absage — und er sagt, dass die Fähigkeiten selbst noch fehlen, damit
  /// ein leerer Slot nicht wie ein Fehler aussieht.
  String _hint(int? next) {
    const offen =
        'Die Fähigkeiten selbst kommen noch — die Plätze stehen '
        'schon.';
    if (next == null) return 'Alle vier Plätze offen. $offen';
    return 'Nächster Platz ab Level $next. $offen';
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.slot,
    required this.isOpen,
    required this.isWeaponSlot,
    required this.weapon,
  });

  final int slot;
  final bool isOpen;
  final bool isWeaponSlot;
  final GearItem? weapon;

  @override
  Widget build(BuildContext context) {
    final requiredLevel = AbilitySlots.levelForSlot(slot);

    return Semantics(
      label: _semantics(requiredLevel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOpen ? Palette.surfaceRaised : Palette.background,
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
                color: isOpen ? Palette.textDim : Palette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icon {
    if (!isOpen) return Icons.lock_outline;
    if (isWeaponSlot) return Icons.colorize;
    return Icons.add_circle_outline;
  }

  Color get _iconColour {
    if (!isOpen) return Palette.muted;
    if (isWeaponSlot && weapon != null) return Palette.accent;
    return Palette.muted;
  }

  /// Was unter dem Symbol steht.
  ///
  /// Der Waffenslot nennt die Waffe statt „leer": Was dort landet, ist
  /// keine Wahl, sondern folgt aus der Ausrüstung — und das ist die
  /// Aussage, die ADR-0013 mit diesem Slot machen wollte.
  String get _caption {
    if (!isOpen) return 'ab Level ${AbilitySlots.levelForSlot(slot)}';
    if (isWeaponSlot) return weapon?.name ?? 'keine Waffe';
    return 'leer';
  }

  String _semantics(int? requiredLevel) {
    if (!isOpen) return 'Platz $slot gesperrt, ab Level $requiredLevel';
    if (isWeaponSlot) {
      return 'Platz $slot, Waffe: ${weapon?.name ?? 'keine angelegt'}';
    }
    return 'Platz $slot, leer';
  }
}
