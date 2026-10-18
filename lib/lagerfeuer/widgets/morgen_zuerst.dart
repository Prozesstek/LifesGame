import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../ui/druck.dart';
import '../../ui/palette.dart';

/// **Was morgen zuerst drankommt** (ADR-0076) — ein Umsetzungsvorsatz.
///
/// Die Gewohnheiten, die morgen fällig sind, als Knöpfe nebeneinander;
/// ein Tipp wählt eine, ein zweiter nimmt sie zurück. Morgen steht sie
/// dann oben in „Heute“, mit einer kleinen Flamme. Sie erzeugt keine
/// Zahl.
///
/// Die Reihenfolge ist die der Liste **ohne** Vorsatz — sonst spränge
/// der gewählte Knopf beim Tippen nach vorn, und der Finger träfe beim
/// zweiten Tipp einen anderen.
class MorgenZuerst extends StatelessWidget {
  const MorgenZuerst({
    required this.habits,
    required this.gewaehlt,
    required this.onWaehle,
    super.key,
  });

  /// Was morgen fällig ist. Leer heißt: Ruhetag.
  final List<Habit> habits;

  /// Die Id der gewählten — oder null.
  final String? gewaehlt;

  /// Wählt [habitId], oder nimmt die Wahl mit null zurück.
  final ValueChanged<String?> onWaehle;

  static Key knopfKey(String habitId) =>
      ValueKey<String>('morgen-zuerst-$habitId');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(
              Icons.wb_twilight_rounded,
              size: 16,
              color: Palette.accentOnDark,
            ),
            SizedBox(width: 6),
            Text(
              'Morgen zuerst',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Palette.accentOnDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (habits.isEmpty)
          const Text(
            'Ruhetag',
            style: TextStyle(fontSize: 13, color: Palette.textOnDarkDim),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final habit in habits)
                _Knopf(
                  key: knopfKey(habit.id),
                  name: habit.name,
                  gewaehlt: habit.id == gewaehlt,
                  onTap: () => onWaehle(habit.id == gewaehlt ? null : habit.id),
                ),
            ],
          ),
      ],
    );
  }
}

class _Knopf extends StatelessWidget {
  const _Knopf({
    required this.name,
    required this.gewaehlt,
    required this.onTap,
    super.key,
  });

  final String name;
  final bool gewaehlt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final farbe = gewaehlt ? Palette.tintLava : Palette.textOnDarkDim;
    return Semantics(
      container: true,
      button: true,
      selected: gewaehlt,
      label: gewaehlt ? '$name, morgen zuerst' : name,
      excludeSemantics: true,
      child: Druck(
        child: Material(
          color: gewaehlt
              ? Palette.tintLava.withValues(alpha: 0.18)
              : Palette.chipOnDark,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: farbe, width: gewaehlt ? 1.5 : 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (gewaehlt) ...<Widget>[
                    const Icon(
                      Icons.local_fire_department,
                      size: 15,
                      color: Palette.tintLava,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: gewaehlt ? FontWeight.bold : null,
                        color: gewaehlt
                            ? Palette.textOnDark
                            : Palette.textOnDarkDim,
                      ),
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
}
