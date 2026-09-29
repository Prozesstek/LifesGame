import 'package:abilities/abilities.dart';
import 'package:flutter/material.dart';
import 'package:progression/progression.dart';

import '../../action/pit_text.dart';
import '../../combat/move_icon.dart';
import '../../ui/druck.dart';
import '../../ui/halten_und_ziehen.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';
import '../../ui/level_abzeichen.dart';

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
    this.gezogen,
    this.nimmtAn = _nimmtNichts,
    this.onAblegen = _legtNichts,
    this.einladen = false,
    super.key,
  });

  /// Ob eine freigeschaltete Fähigkeit noch auf keinem Platz liegt. Dann
  /// leuchtet der nächste freie Platz auf — statt des Satzes „unten eine
  /// Fähigkeit halten und hierher ziehen“.
  final bool einladen;

  final int level;

  /// Der Waffenzug in Slot 1. Nie leer: Ohne Waffe greift der Kurzbogen.
  final String weaponMove;

  /// Was auf den freien Slots liegt.
  final ChosenAbilities chosen;

  /// Wird für jeden **offenen** Platz gerufen, [slot] zählt ab 1.
  final void Function(int slot) onTapSlot;

  /// Die Id der Fähigkeit, die gerade gezogen wird, oder null (ADR-0057).
  final String? gezogen;

  /// Ob der Platz [slot] (ab 1) eine gezogene Fähigkeit nimmt. **Die
  /// Regel steht beim Bildschirm**, weil sie dieselbe ist wie für die
  /// Platz-Knöpfe im Blatt: die belegten plus der nächste leere.
  final bool Function(int slot) nimmtAn;

  /// Wird gerufen, wenn [moveId] auf [slot] losgelassen wurde.
  final void Function(int slot, String moveId) onAblegen;

  static bool _nimmtNichts(int _) => false;
  static void _legtNichts(int _, String _) {}

  @override
  Widget build(BuildContext context) {
    final open = AbilitySlots.openAt(level);

    // **Ohne Satz darunter.** Ein gesperrter Platz trägt sein Level als
    // Abzeichen, ein freier leuchtet auf, wenn etwas hineinpasst.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (var slot = 1; slot <= AbilitySlots.total; slot++) ...<Widget>[
              if (slot > 1) const SizedBox(width: 8),
              Expanded(
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (_) => nimmtAn(slot),
                  onAcceptWithDetails: (d) => onAblegen(slot, d.data),
                  builder: (context, kandidaten, _) => PlatzLaedtEin(
                    aktiv:
                        einladen &&
                        slot > 1 &&
                        slot <= open &&
                        _moveIn(slot) == null &&
                        nimmtAn(slot),
                    child: _Slot(
                      slot: slot,
                      isOpen: slot <= open,
                      isWeaponSlot: slot == 1,
                      move: _moveIn(slot),
                      onTap: slot > open ? null : () => onTapSlot(slot),
                      dragState: SlotDragState.fuer(
                        zieht: gezogen != null,
                        passt: nimmtAn(slot),
                        schwebt: kandidaten.isNotEmpty,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
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
    required this.dragState,
  });

  final int slot;
  final SlotDragState dragState;
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
    final zeichen = Icon(
      _icon,
      size: move == null && isOpen ? 26 : 18,
      color: _iconColour,
    );

    return PlatzBeimZiehen(
      zustand: dragState,
      child: Semantics(
        button: onTap != null,
        label: _semantics,
        onTap: onTap,
        excludeSemantics: true,
        child: Druck(
          enabled: onTap != null,
          child: Material(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: dragState.randFarbe(
                      move == null ? Palette.background : Palette.accent,
                    ),
                    width: dragState.randBreite(1),
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
                    // Belegt: der Name. Gesperrt: das Level als Abzeichen.
                    // Leer: nichts, das Plus sagt es.
                    if (!isOpen)
                      LevelAbzeichen(
                        level: AbilitySlots.levelForSlot(slot) ?? 0,
                        size: 24,
                      )
                    else if (belegt != null)
                      Text(
                        _caption,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Palette.text,
                        ),
                      )
                    else
                      const SizedBox(height: 24),
                  ],
                ),
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
