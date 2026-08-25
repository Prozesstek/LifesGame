import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:identity/identity.dart';

import '../dev/dev_controller.dart';
import '../gear/gear_controller.dart';
import '../gear/shop_screen.dart';
import '../habits/habits_controller.dart';
import '../progression/level_provider.dart';
import '../ui/palette.dart';
import 'abilities_controller.dart';
import 'identity_controller.dart';
import 'widgets/ability_slots_row.dart';
import 'widgets/consistency_card.dart';
import 'widgets/equipment_slot_tile.dart';
import 'widgets/identity_card.dart';
import 'widgets/name_dialog.dart';
import 'widgets/title_dialog.dart';

/// Der Charakterbildschirm: Werte, Ausrüstung, Herkunft der Zahlen.
///
/// **Der Zweck ist Zurechenbarkeit.** Jede Zahl im Kampf soll hier eine
/// Herkunft haben — so viel aus dem Alltag, so viel aus dem Laden. Ein
/// Charakterbildschirm, der nur Summen zeigt, verschweigt genau die eine
/// Aussage, um die es im Konzept geht: dass die Stärke aus Gewohnheiten
/// kommt.
class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  static const double _maxWidth = 560;

  /// Drei Spalten, zwei Reihen. Sechs Plätze gehen auch als 2x3 auf, aber
  /// drei nebeneinander passen auf 390 Pixel Breite, ohne dass die Namen
  /// abgeschnitten werden.
  static const int _gearColumns = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(equippedStatsProvider);
    final loadout = ref.watch(loadoutProvider);
    final level = ref.watch(playerLevelProvider);
    final gold = ref.watch(goldProvider);
    final identity = ref.watch(identityProvider);
    final titleStats = ref.watch(titleStatsProvider);
    final habits = ref.watch(habitTrackerProvider);
    final today = ref.watch(todayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Charakter'),
        backgroundColor: Palette.surface,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: <Widget>[
                IdentityCard(
                  identity: identity,
                  stats: titleStats,
                  level: level,
                  gold: gold,
                  onEditName: () => _editName(context, ref, identity),
                  onChooseTitle: () =>
                      _chooseTitle(context, ref, identity, titleStats),
                ),
                // Nur sichtbar, wenn wirklich etwas geschenkt wurde. Sonst
                // stünde auf jedem Charakterbildschirm eine leere Karte
                // über eine Funktion, die niemand benutzt hat.
                if (ref.watch(devGrantsProvider).isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  const _DevGrantsCard(),
                ],
                const SizedBox(height: 20),
                const _SectionTitle('Beständigkeit'),
                const SizedBox(height: 10),
                ConsistencyCard(
                  currentStreak: habits.currentBestStreak(today),
                  longestStreak: habits.longestStreak,
                  totalChecks: habits.totalChecks,
                ),
                const SizedBox(height: 20),
                const _SectionTitle('Werte im Kampf'),
                const SizedBox(height: 10),
                for (final stat in HabitStat.values) ...<Widget>[
                  _StatRow(stat: stat, stats: stats),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 14),
                const _SectionTitle('Fähigkeiten'),
                const SizedBox(height: 10),
                AbilitySlotsRow(
                  level: level.level,
                  weaponMove: ref.watch(weaponMoveProvider),
                  chosen: ref.watch(chosenAbilitiesProvider),
                  unlocked: ref.watch(unlockedAbilitiesProvider),
                  onChoose: (index, moveId) => ref
                      .read(chosenAbilitiesProvider.notifier)
                      .choose(index, moveId),
                  onClear: (index) =>
                      ref.read(chosenAbilitiesProvider.notifier).clear(index),
                ),
                const SizedBox(height: 18),
                const _SectionTitle('Ausrüstung'),
                const SizedBox(height: 6),
                Text(
                  loadout.equippedCount == 0
                      ? 'Noch nichts angelegt. Im Laden gibt es sechs Plätze '
                            'zu füllen.'
                      : '${loadout.equippedCount} von '
                            '${GearSlot.values.length} Plätzen belegt.',
                  style: const TextStyle(fontSize: 13, color: Palette.textDim),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  // Das Raster sitzt in einer ListView: eigene Höhe, kein
                  // eigenes Scrollen. Sonst scrollten zwei Flächen
                  // ineinander.
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: _gearColumns,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.92,
                  children: <Widget>[
                    for (final slot in GearSlot.values)
                      EquipmentSlotTile(
                        slot: slot,
                        equipped: loadout.equippedIn(slot),
                        owned: loadout.owned
                            .where((item) => item.slot == slot)
                            .toList(),
                        onEquip: (itemId) =>
                            ref.read(loadoutProvider.notifier).equip(itemId),
                        onUnequip: () =>
                            ref.read(loadoutProvider.notifier).unequip(slot),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
                  ),
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('Zum Laden'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Fragt den Namen ab und übernimmt ihn.
  ///
  /// Abbrechen gibt null zurück und ändert nichts — ein leeres Feld
  /// dagegen ist eine gültige Antwort und löscht den Namen wieder.
  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    Identity identity,
  ) async {
    final name = await showNameDialog(context, current: identity.name);
    if (name == null) return;

    ref.read(identityProvider.notifier).setName(name);
  }

  Future<void> _chooseTitle(
    BuildContext context,
    WidgetRef ref,
    Identity identity,
    TitleStats stats,
  ) async {
    final selection = await showTitleDialog(
      context,
      current: identity.chosenTitleId,
      stats: stats,
    );
    if (selection == null) return;

    ref.read(identityProvider.notifier).chooseTitle(selection.titleId);
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat, required this.stats});

  final HabitStat stat;
  final EquippedStats stats;

  @override
  Widget build(BuildContext context) {
    final base = stats.baseFor(stat);
    final bonus = stats.bonusFor(stat);
    final total = stats.totalFor(stat);

    return Semantics(
      label:
          '${stat.label} $total, davon $base aus Gewohnheiten und '
          '$bonus aus Ausrüstung',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    stat.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.combatLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Palette.textDim,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '$total',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bonus > 0 ? '$base Alltag · +$bonus Ausrüstung' : 'Alltag',
                  style: TextStyle(
                    fontSize: 11,
                    color: bonus > 0 ? Palette.success : Palette.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

/// Was der Entwicklermodus zu den Zahlen beigetragen hat.
///
/// **Der Charakterbildschirm lebt von Zurechenbarkeit** — „18 Angriff,
/// davon 3 aus Ausrüstung". Ein geschenkter Wert, der dort stillschweigend
/// mitzählte, wäre der eine Posten ohne Herkunft. Deshalb steht er hier,
/// benannt und mit einem Hinweis, dass er nicht verdient ist (ADR-0021).
class _DevGrantsCard extends ConsumerWidget {
  const _DevGrantsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grants = ref.watch(devGrantsProvider);
    final zeilen = <String, int>{
      'Erfahrung': grants.bonusXp,
      'Gold': grants.bonusGold,
      'Theoriepunkte': grants.bonusTheoryPoints,
      'Fähigkeitspunkte': grants.bonusAbilityPoints,
      'Fähigkeiten': grants.unlockedAbilityIds.length,
    }..removeWhere((_, wert) => wert == 0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2413),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.gold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.science_outlined, size: 18, color: Palette.gold),
              const SizedBox(width: 8),
              const Text(
                'Aus dem Entwicklermodus',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Palette.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final zeile in zeilen.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      zeile.key,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Palette.textDim,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${zeile.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          const Text(
            'Nicht verdient — geschenkt. Im Dev-Modus zurücksetzbar.',
            style: TextStyle(fontSize: 11, color: Palette.muted),
          ),
        ],
      ),
    );
  }
}
