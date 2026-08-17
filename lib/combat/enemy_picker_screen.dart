import 'package:combat/combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gear/gear_controller.dart';
import '../ui/palette.dart';
import 'combat_controller.dart';
import 'combat_screen.dart';

/// Die Gegnerwahl vor dem Kampf.
///
/// **Warum es diesen Bildschirm überhaupt gibt.** Ein einzelner Gegner ist
/// entweder zu leicht oder zu schwer — dazwischen liegt bei festen Werten
/// fast nichts (ADR-0009). Erst mehrere Gegner machen aus einem starren
/// Kampf eine Frage: Reicht es schon für den nächsten?
///
/// Deshalb zeigt jede Zeile auch die eigenen Werte im Vergleich. Der
/// Spieler soll die Antwort abschätzen können, ohne sie durch Verlieren zu
/// erfahren.
class EnemyPickerScreen extends ConsumerWidget {
  const EnemyPickerScreen({super.key});

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(equippedStatsProvider);
    final selected = ref.watch(selectedEnemyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gegner wählen'),
        backgroundColor: Palette.surface,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Palette.surfaceRaised,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.person_outline,
                        size: 20,
                        color: Palette.accent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Du: ${stats.attack} Angriff · ${stats.maxHp} HP · '
                          '${stats.defense} Verteidigung · '
                          '${stats.maxEnergy} Energie',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final enemy in Enemies.all) ...<Widget>[
                  _EnemyTile(
                    enemy: enemy,
                    isSelected: enemy.id == selected.id,
                    playerAttack: stats.attack,
                    playerHp: stats.maxHp,
                    onTap: () => _start(context, ref, enemy),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _start(BuildContext context, WidgetRef ref, EnemyBlueprint enemy) {
    ref.read(selectedEnemyProvider.notifier).select(enemy);
    // Der Kampf wird neu aufgesetzt, damit die Wahl auch dann greift, wenn
    // schon einer lief.
    ref.read(combatControllerProvider.notifier).restart();
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CombatScreen()));
  }
}

class _EnemyTile extends StatelessWidget {
  const _EnemyTile({
    required this.enemy,
    required this.isSelected,
    required this.playerAttack,
    required this.playerHp,
    required this.onTap,
  });

  final EnemyBlueprint enemy;
  final bool isSelected;
  final int playerAttack;
  final int playerHp;
  final VoidCallback onTap;

  /// Eine grobe Einschätzung, kein Versprechen.
  ///
  /// Bewusst aus denselben zwei Größen gebildet, die der Spieler direkt
  /// darüber sieht: Wie viele Runden brauche ich für seine HP, wie viele
  /// braucht er für meine? Wer nachrechnen will, soll es können. Die echte
  /// Antwort gibt nur der Kampf — deshalb steht hier „vermutlich" und
  /// keine Prozentzahl, die es nicht gibt.
  _Aussicht get _aussicht {
    final meineRunden = enemy.maxHp / playerAttack;
    final seineRunden = playerHp / enemy.attack;

    if (meineRunden < seineRunden * 0.7) return _Aussicht.gut;
    if (meineRunden < seineRunden * 1.05) return _Aussicht.knapp;
    return _Aussicht.zuStark;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: Palette.accent, width: 1.5)
                  : null,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        enemy.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${enemy.maxHp} HP · ${enemy.attack} Angriff · '
                        '${enemy.defense} Verteidigung',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Palette.textDim,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _aussicht.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _aussicht.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Palette.textDim,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wie ein Kampf voraussichtlich ausgeht.
enum _Aussicht {
  gut('sollte gut ausgehen', Palette.success),
  knapp('wird knapp', Palette.gold),
  zuStark('vermutlich noch zu stark', Palette.enemy);

  const _Aussicht(this.label, this.color);

  final String label;
  final Color color;
}
