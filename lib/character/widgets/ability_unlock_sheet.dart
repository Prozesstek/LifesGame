import 'package:abilities/abilities.dart';
import 'package:combat/combat.dart';
import 'package:flutter/material.dart';

import '../../combat/move_help.dart';
import '../../ui/palette.dart';

/// Was mit der frisch freigeschalteten Fähigkeit geschehen soll.
enum UnlockChoice { equip, inventory }

/// Der Freischaltungsscreen (Issue #21, Punkt 7).
///
/// **Eine Freischaltung war bisher unsichtbar.** Eine Seite bestehen oder
/// eine Streak-Marke reissen gab still eine Fähigkeit dazu — sehen konnte
/// man sie nur, wenn man von selbst auf den Charakterbildschirm ging und
/// die Auswahl öffnete. Der Moment, auf den der ganze Baum hinarbeitet,
/// fand nirgends statt.
///
/// **Ist kein Platz frei, feiert er trotzdem** und nennt die Stufe, die
/// den nächsten bringt. Die Feier zu verschlucken, weil gerade kein Platz
/// da ist, wäre die schlechteste Antwort: Der Spieler hätte etwas
/// erreicht und bekäme dafür nichts zu sehen.
class AbilityUnlockSheet extends StatelessWidget {
  const AbilityUnlockSheet({
    required this.ability,
    required this.move,
    required this.attack,
    required this.hasFreeSlot,
    required this.nextSlotLevel,
    super.key,
  });

  final Ability ability;
  final Move move;

  /// Der Angriffswert, mit dem die Zahlen im Hilfetext gerechnet werden.
  final int attack;

  final bool hasFreeSlot;

  /// Die Stufe, die den nächsten Platz bringt. Null heisst: alle offen.
  final int? nextSlotLevel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Palette.muted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Icon(Icons.auto_awesome, size: 40, color: Palette.gold),
            ),
            const SizedBox(height: 14),
            const Text(
              'Herzlichen Glückwunsch',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Palette.gold,
                fontSize: 13,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _sourceLine(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Du hast ${move.name} freigeschaltet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            // Dieselben Sätze wie der Tooltip im Kampf, mit denselben
            // echten Zahlen — keine zweite Beschreibung, die davon
            // auseinanderläuft.
            Text(
              moveHelpFor(move, attack).effect,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Palette.textDim,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (moveHelpFor(move, attack).perfect case final String perfekt)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  perfekt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Palette.accent,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ),
            const SizedBox(height: 22),
            ..._actions(context),
          ],
        ),
      ),
    );
  }

  /// Woher sie kommt.
  ///
  /// **Der Satz ist der halbe Sinn der Feier.** Wer nicht weiss, wofür er
  /// belohnt wurde, lernt nichts daraus — und bei den vier Streak-Marken
  /// ist gerade das die Aussage: Die Kette selbst hat sie gebracht, keine
  /// Lektion.
  String _sourceLine() {
    return switch (ability.source) {
      FromTheory() => 'Aus der Theorie',
      FromStreak(:final days) => 'Für $days Tage am Stück',
      FromWeapon() => 'Von deiner Waffe',
    };
  }

  List<Widget> _actions(BuildContext context) {
    if (hasFreeSlot) {
      return <Widget>[
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(UnlockChoice.equip),
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: const Text('Direkt ausrüsten'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(UnlockChoice.inventory),
          child: const Text('Ins Inventar'),
        ),
      ];
    }

    return <Widget>[
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Palette.surfaceRaised,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          nextSlotLevel == null
              ? 'Alle Plätze sind belegt. Du kannst auf dem '
                    'Charakterbildschirm umstellen.'
              : 'Gerade ist kein Platz frei. Der nächste geht auf '
                    'Level $nextSlotLevel auf.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Palette.muted,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ),
      const SizedBox(height: 10),
      TextButton(
        onPressed: () => Navigator.of(context).pop(UnlockChoice.inventory),
        child: const Text('Weiter'),
      ),
    ];
  }
}
