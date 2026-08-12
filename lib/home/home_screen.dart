import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory/theory.dart';

import '../combat/combat_screen.dart';
import '../habits/habits_controller.dart';
import '../habits/habits_screen.dart';
import '../progression/level_provider.dart';
import '../theory/skill_tree_screen.dart';
import '../theory/theory_controller.dart';
import '../ui/palette.dart';
import 'widgets/hub_tile.dart';
import 'widgets/level_card.dart';

/// Startbildschirm — der Weg zu allem anderen.
///
/// Gesperrte Bereiche stehen bewusst mit dabei. Ein Startbildschirm, der
/// nur zeigt, was schon fertig ist, verschweigt, worum es geht.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(theoryProgressProvider);
    final level = ref.watch(playerLevelProvider);
    final gold = ref.watch(goldProvider);
    final passed = progress.passedCountIn(theoryTree);

    final tracker = ref.watch(habitTrackerProvider);
    final unlockedHabits = ref.watch(unlockedHabitsProvider);
    final today = ref.watch(todayProvider);
    final activeHabits = tracker.activeTemplates;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: <Widget>[
                const _Header(),
                const SizedBox(height: 20),
                LevelCard(level: level, gold: gold),
                const SizedBox(height: 24),
                HubTile(
                  icon: Icons.check_circle_outline,
                  title: 'Gewohnheiten',
                  subtitle: _habitSubtitle(unlockedHabits.length),
                  status: activeHabits.isEmpty
                      ? null
                      : '${tracker.completedOn(today)} / '
                            '${activeHabits.length}',
                  onTap: () => _open(context, const HabitsScreen()),
                ),
                const SizedBox(height: 10),
                HubTile(
                  icon: Icons.account_tree_outlined,
                  title: 'Theorie',
                  subtitle:
                      '${theoryTree.branchCount} Zweige, '
                      'Level ${level.level}',
                  status: '$passed / ${theoryTree.lessonCount}',
                  onTap: () => _open(context, const SkillTreeScreen()),
                ),
                const SizedBox(height: 10),
                HubTile(
                  icon: Icons.sports_martial_arts,
                  title: 'Kampf',
                  subtitle: 'Einzelgegner — Dungeon kommt später',
                  onTap: () => _open(context, const CombatScreen()),
                ),
                const SizedBox(height: 10),
                HubTile(
                  icon: Icons.storefront_outlined,
                  title: 'Shop',
                  subtitle: 'Ausrüstung, Tränke, Dungeon-Zugänge',
                  status: 'in Arbeit',
                ),
                const SizedBox(height: 10),
                HubTile(
                  icon: Icons.person_outline,
                  title: 'Charakter',
                  subtitle: 'Werte, Ausrüstung, Fähigkeiten',
                  status: 'in Arbeit',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  /// Ohne freigeschaltete Vorlage steht hier der Weg dorthin, nicht das
  /// Versprechen einer Funktion, die noch leer wäre.
  static String _habitSubtitle(int unlockedCount) {
    if (unlockedCount == 0) {
      return 'Vorlagen kommen aus dem Skillbaum';
    }
    return 'Täglich abhaken, Werte aufbauen';
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Lifes Game',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Was du im Alltag tust, macht deinen Charakter stark.',
          style: TextStyle(fontSize: 14, color: Palette.textDim),
        ),
      ],
    );
  }
}
