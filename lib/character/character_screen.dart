import 'package:achievements/achievements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';
import 'package:identity/identity.dart';

import '../action/hero_power.dart';
import '../achievements/achievements_card.dart';
import '../achievements/achievements_controller.dart';
import '../dev/dev_controller.dart';
import '../gear/gear_controller.dart';
import '../gear/equipment_screen.dart';
import '../gear/shop_screen.dart';
import '../habits/habits_controller.dart';
import '../progression/level_provider.dart';
import '../save/widgets/save_transfer_card.dart';
import '../ui/palette.dart';
import 'abilities_screen.dart';
import 'identity_controller.dart';
import 'widgets/consistency_card.dart';
import 'widgets/identity_card.dart';
import 'widgets/name_dialog.dart';
import 'widgets/title_dialog.dart';
import '../habits/daily_form_text.dart';
import '../ui/holz.dart';
import '../habits/widgets/week_card.dart';
import '../habits/stat_icon.dart';

/// Der Charakterbildschirm: Werte und ihre Herkunft. Ausrüstung und
/// Fähigkeiten haben eigene Bildschirme (ADR-0049, ADR-0057).
///
/// **Der Zweck ist Zurechenbarkeit.** Jede Zahl im Kampf soll hier eine
/// Herkunft haben — so viel aus dem Alltag, so viel aus dem Laden. Ein
/// Charakterbildschirm, der nur Summen zeigt, verschweigt genau die eine
/// Aussage, um die es im Konzept geht: dass die Stärke aus Gewohnheiten
/// kommt.
class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(equippedStatsProvider);
    final level = ref.watch(playerLevelProvider);
    final gold = ref.watch(goldProvider);
    final identity = ref.watch(identityProvider);
    final achievementStats = ref.watch(achievementStatsProvider);
    final earnedTitleIds = ref.watch(earnedTitleIdsProvider);
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
                  earnedTitleIds: earnedTitleIds,
                  level: level,
                  gold: gold,
                  fame: ref.watch(fameProvider),
                  onEditName: () => _editName(context, ref, identity),
                  onChooseTitle: () =>
                      _chooseTitle(context, ref, identity, achievementStats),
                ),
                const SizedBox(height: 16),
                const AchievementsCard(),
                // Nur sichtbar, wenn wirklich etwas geschenkt wurde. Sonst
                // stünde auf jedem Charakterbildschirm eine leere Karte
                // über eine Funktion, die niemand benutzt hat.
                if (ref.watch(devGrantsProvider).isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  const _DevGrantsCard(),
                ],
                const SizedBox(height: 16),
                ConsistencyCard(
                  currentStreak: habits.currentBestStreak(today),
                  longestStreak: habits.longestStreak,
                  totalChecks: habits.totalChecks,
                ),
                const SizedBox(height: 10),
                // **Seit dem 28.09. hier** statt auf dem Gewohnheiten-
                // Bildschirm (Issue #88): Eine Woche im Rückblick sagt,
                // wer man geworden ist, nicht, was heute ansteht.
                WeekCard(
                  today: today,
                  thisWeek: ref.watch(thisWeekProvider),
                  lastWeek: ref.watch(lastWeekProvider),
                ),
                const SizedBox(height: 16),
                const _PowerCard(),
                const SizedBox(height: 8),
                for (final stat in HabitStat.values) ...<Widget>[
                  _StatRow(stat: stat, stats: stats),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 18),
                // **Die Ausrüstung steht seit ADR-0057 nicht mehr hier**,
                // genau wie die Fähigkeiten seit ADR-0049. Was sie an den
                // Werten ändert, steht weiter oben bei „Werte im Kampf“.
                // **Die Fähigkeiten stehen seit ADR-0049 nicht mehr hier.**
                // Der Weg bleibt trotzdem: Wer seinen Charakter ansieht,
                // sucht sie an dieser Stelle. Drei Zeichen statt drei
                // beschrifteter Planken.
                Row(
                  children: <Widget>[
                    _Weg(
                      icon: Icons.shield_outlined,
                      label: 'Zur Ausrüstung',
                      ziel: () => const EquipmentScreen(),
                    ),
                    const SizedBox(width: 10),
                    _Weg(
                      icon: Icons.storefront_outlined,
                      label: 'Zum Laden',
                      ziel: () => const ShopScreen(),
                    ),
                    const SizedBox(width: 10),
                    _Weg(
                      icon: Icons.auto_awesome,
                      label: 'Zu den Fähigkeiten',
                      ziel: () => const AbilitiesScreen(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Ganz unten, weil man es selten braucht — und dann
                // dringend (ADR-0054).
                const SaveTransferCard(),
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
    AchievementStats stats,
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

/// Womit der Held in die Grube geht — die Zahlen, die der Kampf führt,
/// und die Faktoren dahinter (ADR-0042). Darunter stehen die Werte, aus
/// denen sie wachsen.
class _PowerCard extends ConsumerWidget {
  const _PowerCard();

  static String _faktor(double f) =>
      '×${f.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final macht = ref.watch(heroPowerProvider);
    final s = macht.stats;

    final form = DailyFormText.summary(macht.form);

    // Drei Zahlen mit ihrem Zeichen; die Faktoren dahinter und die
    // Tagesform stehen im Tipp, ein Blitz zeigt, dass sie wirkt.
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      message:
          'Level ${_faktor(macht.levelFactor)} · '
          'Waffe ${_faktor(macht.weaponFactor)} · '
          'Rüstung ${_faktor(macht.armorFactor)}'
          '${form == null ? '' : '\n${macht.form.isInForm ? 'In Form' : 'Tagesform'}: $form'}',
      child: HolzKarte(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            for (final (stat, wert) in <(HabitStat, int)>[
              (HabitStat.staerke, s.combatAttack),
              (HabitStat.ausdauer, s.combatMaxHp),
              (HabitStat.disziplin, s.combatDefense),
            ])
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    StatIcon(stat, size: 18),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$wert',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Palette.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (form != null)
              const Icon(Icons.bolt_rounded, size: 20, color: Palette.accent),
          ],
        ),
      ),
    );
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
      child: HolzKarte(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        // Zeichen, Summe, und woher sie kommt: Häkchen und Ausrüstung.
        child: Row(
          children: <Widget>[
            StatIcon(stat, size: 24),
            const SizedBox(width: 12),
            Text(
              '$total',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Palette.text,
              ),
            ),
            const Spacer(),
            _Herkunft(icon: Icons.check_circle_outline, wert: '$base'),
            if (bonus > 0) ...<Widget>[
              const SizedBox(width: 10),
              _Herkunft(
                icon: Icons.backpack_outlined,
                wert: '+$bonus',
                farbe: Palette.success,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Eine Quelle eines Werts: Zeichen und Zahl, klein.
class _Herkunft extends StatelessWidget {
  const _Herkunft({
    required this.icon,
    required this.wert,
    this.farbe = Palette.textDim,
  });

  final IconData icon;
  final String wert;
  final Color farbe;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: farbe),
        const SizedBox(width: 3),
        Text(wert, style: TextStyle(fontSize: 12, color: farbe)),
      ],
    );
  }
}

/// Ein Weg zu einem anderen Bereich — ein Zeichen auf einer Planke.
class _Weg extends StatelessWidget {
  const _Weg({required this.icon, required this.label, required this.ziel});

  final IconData icon;

  /// Nur für den Vorleser.
  final String label;
  final Widget Function() ziel;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FilledButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => ziel())),
        child: Icon(icon, semanticLabel: label),
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
        color: Palette.backgroundRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.goldOnDark.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.science_outlined,
                size: 18,
                color: Palette.goldOnDark,
              ),
              const SizedBox(width: 8),
              const Text(
                'Aus dem Entwicklermodus',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Palette.goldOnDark,
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
                        color: Palette.textOnDarkDim,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${zeile.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Palette.textOnDark,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          const Text(
            'Nicht verdient — geschenkt. Im Dev-Modus zurücksetzbar.',
            style: TextStyle(fontSize: 11, color: Palette.textOnDarkDim),
          ),
        ],
      ),
    );
  }
}
