import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../character/character_screen.dart';
import '../dev/dev_controller.dart';
import '../dev/dev_screen.dart';
import '../combat/combat_controller.dart';
import '../combat/enemy_picker_screen.dart';
import '../gear/shop_screen.dart';
import '../habits/habits_screen.dart';
import '../progression/level_provider.dart';
import '../theory/skill_tree_screen.dart';
import '../ui/palette.dart';
import 'widgets/character_stage.dart';
import 'widgets/hub_circle.dart';

/// Startbildschirm — die Figur in der Mitte, die Bereiche darum herum.
///
/// **Bis Issue #35 war das eine Liste aus fünf Kacheln.** Sie hat
/// funktioniert und nichts erzählt: Ein Habit-Tracker, dessen Startseite
/// aussieht wie ein Einstellungsmenü, muss seine eigene Aussage jeden Tag
/// aufs Neue behaupten. Jetzt steht der Charakter in der Mitte, und die
/// fünf Bereiche liegen als Kreise darum.
///
/// Gesperrte Bereiche stehen bewusst mit dabei. Ein Startbildschirm, der
/// nur zeigt, was schon fertig ist, verschweigt, worum es geht — und der
/// Kreis nennt beim Antippen den Weg (ADR-0020).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(playerLevelProvider);
    final gold = ref.watch(goldProvider);

    final combatOpen = ref.watch(combatUnlockedProvider);
    final combatBlock = ref.watch(combatBlockReasonProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      HubCircle(
                        icon: Icons.check_circle_outline,
                        label: 'Gewohnheiten',
                        onTap: () => _open(context, const HabitsScreen()),
                      ),
                      HubCircle(
                        icon: Icons.account_tree_outlined,
                        label: 'Theorie',
                        onTap: () => _open(context, const SkillTreeScreen()),
                      ),
                      HubCircle(
                        icon: Icons.sports_martial_arts,
                        label: 'Kampf',
                        // Der Kampf hängt am Moveset (ADR-0025). Ist es zu
                        // dünn, nennt der Kreis beim Antippen, woran es
                        // liegt — der Satz unterscheidet drei Fälle, und
                        // der dritte ist der wichtigste: gelernt, aber
                        // nicht angelegt.
                        lockedReason: combatOpen ? null : combatBlock,
                        onTap: () => _open(context, const EnemyPickerScreen()),
                      ),
                    ],
                  ),

                  // **Die Figur bekommt, was übrig bleibt.** Der Rest des
                  // Bildschirms steht fest; damit passt das Layout auf
                  // jede Höhe, ohne zu scrollen und ohne überzulaufen.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: CharacterStage(level: level, gold: gold),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      HubCircle(
                        icon: Icons.storefront_outlined,
                        label: 'Laden',
                        onTap: () => _open(context, const ShopScreen()),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // Nur im Debug-Build. Im Release ist der Zweig
                          // samt Bildschirm gar nicht erst im Bündel
                          // (ADR-0021), und an dieser Stelle steht dann
                          // nichts.
                          if (devModeAvailable) const _DevKnopf(),
                          HubCircle(
                            icon: Icons.person_outline,
                            label: 'Charakter',
                            onTap: () =>
                                _open(context, const CharacterScreen()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

/// Der kleine Knopf über dem Charakterkreis.
///
/// Er sitzt bewusst abseits der fünf Bereiche und ist kleiner als sie:
/// Der Entwicklermodus ist kein Teil des Spiels, sondern ein Werkzeug —
/// und er arbeitet auf einem eigenen Spielstand (ADR-0021).
class _DevKnopf extends ConsumerWidget {
  const _DevKnopf();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, right: 4),
      child: Tooltip(
        message: 'Entwicklermodus — ${ref.watch(activeSlotProvider).label}',
        child: InkWell(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const DevScreen())),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Palette.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Palette.muted),
            ),
            child: const Icon(
              Icons.science_outlined,
              size: 17,
              color: Palette.muted,
            ),
          ),
        ),
      ),
    );
  }
}
