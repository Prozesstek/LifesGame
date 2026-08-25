import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../character/character_screen.dart';
import '../dev/dev_controller.dart';
import '../dev/dev_screen.dart';
import '../combat/combat_controller.dart';
import '../combat/enemy_picker_screen.dart';
import '../gear/gear_controller.dart';
import '../gear/shop_screen.dart';
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
    final level = ref.watch(playerLevelProvider);
    final gold = ref.watch(goldProvider);
    final passed = ref.watch(passedPagesProvider);
    final totalPages = ref.watch(totalPagesProvider);

    final tracker = ref.watch(habitTrackerProvider);
    final unlockedHabits = ref.watch(unlockedHabitsProvider);
    final today = ref.watch(todayProvider);
    final activeHabits = tracker.activeTemplates;
    final enemy = ref.watch(selectedEnemyProvider);
    final equippedCount = ref.watch(loadoutProvider).equippedCount;
    final combatOpen = ref.watch(combatUnlockedProvider);
    final combatBlock = ref.watch(combatBlockReasonProvider);

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
                      'Vier Gebiete und das Handbuch, '
                      'Level ${level.level}',
                  status: '$passed / $totalPages',
                  onTap: () => _open(context, const SkillTreeScreen()),
                ),
                const SizedBox(height: 10),
                HubTile(
                  icon: Icons.sports_martial_arts,
                  title: 'Kampf',
                  subtitle: combatBlock ?? 'Drei Gegner — Dungeon kommt später',
                  status: combatOpen ? enemy.name : null,
                  // Gesperrt, bis das Handbuch durch ist (ADR-0018). Mit
                  // nur einem Move ist der erste Kampf nicht knapp,
                  // sondern unmöglich — und der Zweig gibt genau die
                  // Erfahrung, die den zweiten Slot öffnet.
                  onTap: combatOpen
                      ? () => _open(context, const EnemyPickerScreen())
                      : null,
                ),
                const SizedBox(height: 10),
                HubTile(
                  icon: Icons.storefront_outlined,
                  title: 'Laden',
                  subtitle: 'Ausrüstung für sechs Plätze',
                  status: '$gold Gold',
                  onTap: () => _open(context, const ShopScreen()),
                ),
                const SizedBox(height: 10),
                HubTile(
                  icon: Icons.person_outline,
                  title: 'Charakter',
                  subtitle: 'Werte und Ausrüstung',
                  status: '$equippedCount / ${GearSlot.values.length}',
                  onTap: () => _open(context, const CharacterScreen()),
                ),

                // Nur im Debug-Build. Im Release ist der Zweig samt
                // Bildschirm gar nicht erst im Bündel (ADR-0021).
                if (devModeAvailable) ...<Widget>[
                  const SizedBox(height: 10),
                  HubTile(
                    icon: Icons.science_outlined,
                    title: 'Entwicklermodus',
                    subtitle: 'Werte schenken, alles freischalten',
                    status: ref.watch(activeSlotProvider).label,
                    onTap: () => _open(context, const DevScreen()),
                  ),
                ],
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
