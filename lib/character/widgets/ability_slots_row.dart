import 'package:abilities/abilities.dart';
import 'package:flutter/material.dart';
import 'package:progression/progression.dart';

import '../../action/pit_text.dart';
import '../../combat/move_icon.dart';
import '../../ui/druck.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';

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
/// gewählt — antippen zeigt seine Werte, mehr nicht.
///
/// **Sie wählt nichts mehr aus** (ADR-0049). Bis zum 25.09. hing an
/// dieser Reihe ein eigenes Auswahlblatt; seit die Fähigkeiten einen
/// eigenen Bildschirm haben, meldet sie nur den angetippten Platz, und
/// das Blatt mit den Werten entscheidet.
class AbilitySlotsRow extends StatelessWidget {
  const AbilitySlotsRow({
    required this.level,
    required this.weaponMove,
    required this.chosen,
    required this.onTapSlot,
    super.key,
  });

  final int level;

  /// Der Waffenzug in Slot 1. Nie leer: Ohne Waffe greift der Kurzbogen.
  final String weaponMove;

  /// Was auf den freien Slots liegt.
  final ChosenAbilities chosen;

  /// Wird für jeden **offenen** Platz gerufen, [slot] zählt ab 1.
  final void Function(int slot) onTapSlot;

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
                  onTap: slot > open ? null : () => onTapSlot(slot),
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
  /// statt einer Absage — und sagt bei offenen leeren Plätzen, wo das
  /// herkommt, was hineingehört.
  String _hint(int? next, int open) {
    final frei = open - 1;
    final belegt = chosen.length;

    if (next != null && belegt >= frei) {
      return 'Nächster Platz ab Level $next.';
    }
    if (belegt < frei) {
      final offen = frei - belegt;
      return offen == 1
          ? 'Ein Platz ist noch frei — unten eine Fähigkeit antippen.'
          : '$offen Plätze sind noch frei — unten eine Fähigkeit antippen.';
    }
    return 'Alle vier Plätze offen und belegt.';
  }
}

/// Das Bild einer Fähigkeit — oder [fallback], solange sie keins hat.
///
/// Immer [side] groß, auch mit Zeichen statt Bild: Sonst wären die
/// Plätze verschieden hoch, je nachdem, was darauf liegt.
class MoveBild extends StatelessWidget {
  const MoveBild({
    required this.moveId,
    required this.side,
    required this.fallback,
    super.key,
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
      child: Druck(
        enabled: onTap != null,
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
                    MoveBild(
                      moveId: belegt,
                      side: _bildSeite,
                      fallback: zeichen,
                    )
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
