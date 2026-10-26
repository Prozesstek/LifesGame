import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../../habits/habits_controller.dart';
import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../gebiet_farbe.dart';
import '../gebiet_zeichen.dart';

/// **Die einmalige Frage** (ADR-0085): Zu welchem Gebiet gehört eine
/// eigene Gewohnheit, die vor den Skills angelegt wurde?
///
/// Eine nach der anderen, auf der Startseite über „Heute“ — eine Karte,
/// kein Dialog, wie die erste Frage nach einer Gewohnheit (ADR-0068).
/// Sie steht nur da, solange es eine solche Gewohnheit gibt; neue Stände
/// sehen sie nie, weil das Formular das Gebiet gleich mitfragt.
///
/// **Danach steht es fest.** Ein Wechsel verschöbe die Historie in einen
/// anderen Skill, und der alte fiele.
class GebietFrageKarte extends ConsumerWidget {
  const GebietFrageKarte({super.key});

  /// Der Knopf zu einem Gebiet — zum Finden in Tests.
  static Key knopf(SkillArea area) {
    return ValueKey<String>('gebiet-frage-${area.name}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offen = ref.watch(habitTrackerProvider).customWithoutArea;
    if (offen.isEmpty) return const SizedBox.shrink();
    final habit = offen.first;

    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Zu welchem Gebiet gehört „${habit.name}“?',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Palette.text,
            ),
          ),
          const SizedBox(height: 4),
          // Seit ADR-0088 bestimmt das Gebiet auch den Kampfwert — für
          // jedes Häkchen, auch die alten.
          const Text(
            'Dort wächst ihr Skill und ihr Kampfwert, mit allem, was du '
            'schon getan hast. Danach steht es fest.',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Palette.textDim,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final area in SkillArea.values)
                Druck(
                  child: ActionChip(
                    key: knopf(area),
                    avatar: Icon(
                      gebietZeichen(area),
                      size: 16,
                      color: GebietFarbe.pergament(area),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(
                      '${area.label} · ${area.kampfwert.label}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    onPressed: () => ref
                        .read(habitTrackerProvider.notifier)
                        .assignArea(habit.id, area),
                  ),
                ),
            ],
          ),
          if (offen.length > 1) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'noch ${offen.length - 1}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: Palette.muted),
            ),
          ],
        ],
      ),
    );
  }
}
