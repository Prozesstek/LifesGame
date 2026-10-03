import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../character/abilities_screen.dart';
import '../gear/equipment_screen.dart';
import '../character/character_screen.dart';
import '../dev/dev_controller.dart';
import '../dev/dev_screen.dart';
import '../action/pit_gate.dart';
import '../combat/ladder_screen.dart';
import '../gear/shop_screen.dart';
import '../habits/habits_controller.dart';
import '../habits/habits_screen.dart';
import '../progression/level_provider.dart';
import '../theory/skill_tree_screen.dart';
import '../ui/aufstieg.dart';
import '../ui/palette.dart';
import 'widgets/hub_circle.dart';
import 'widgets/status_leiste.dart';
import 'widgets/today_card.dart';
import '../ui/druck.dart';
import '../habits/daily_quests_provider.dart';
import '../habits/habit_check_flow.dart';
import '../habits/widgets/daily_chest_card.dart';
import '../habits/widgets/daily_quests_card.dart';

/// Startbildschirm — „Heute“ in der Mitte, die Bereiche darum herum.
///
/// **Bis Issue #35 war das eine Liste aus fünf Kacheln.** Sie hat
/// funktioniert und nichts erzählt: Ein Habit-Tracker, dessen Startseite
/// aussieht wie ein Einstellungsmenü, muss seine eigene Aussage jeden Tag
/// aufs Neue behaupten. Seitdem liegen die Bereiche als Kreise um die
/// Mitte. Dort stand bis zum 28.09. der Charakter; jetzt steht dort, was
/// heute zu tun ist, und die Figur ist in der Ausrüstung.
///
/// Gesperrte Bereiche stehen bewusst mit dabei. Ein Startbildschirm, der
/// nur zeigt, was schon fertig ist, verschweigt, worum es geht — und der
/// Kreis nennt beim Antippen den Weg (ADR-0020).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const double _maxWidth = 560;

  /// Das Buch auf dem Theorie-Kreis — Frederiks Zeichnung, 64 × 64.
  static const String theorySymbol = 'assets/UI/Buch.png';

  /// Der Stern auf dem Fähigkeiten-Kreis (ADR-0049).
  ///
  /// **Eine vorhandene Zeichnung statt eines Systemzeichens**, wie das
  /// Buch auf der Theorie. Sternenfall ist die einzige legendäre
  /// Fähigkeit und die einzige, deren Bild mittig und ringsum gleich ist
  /// — auf einem runden Knopf sitzt das, ohne zu kippen.
  static const String abilitySymbol = 'assets/Faehigkeiten/Sternenfall.png';

  /// Der Harnisch auf dem Ausrüstungs-Kreis (ADR-0057), aus demselben
  /// Grund wie der Stern: eine vorhandene Zeichnung, mittig und
  /// symmetrisch, die auf den ersten Blick „Ausrüstung“ sagt.
  static const String gearSymbol = 'assets/Ruestung/Plattenharnisch.png';

  /// Wie gross die Kreise der unteren Reihe sind. **Kleiner als oben**,
  /// weil dort seit ADR-0057 vier stehen: Laden, Fähigkeiten,
  /// Ausrüstung, Charakter. Bei 72 Punkten bräuchten sie mit Namen 352
  /// Punkte Breite, ein Handy hat nach dem Rand 335.
  static const double bottomCircleSize = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(playerLevelProvider);
    final gold = ref.watch(goldProvider);

    final tracker = ref.watch(habitTrackerProvider);
    final today = ref.watch(todayProvider);
    final heute = HubProgress(
      done: tracker.completedOn(today),
      // Was heute fällig ist, nicht was läuft (ADR-0064).
      total: tracker.dailyListOn(today).length,
    );

    final combatOpen = ref.watch(combatUnlockedProvider);
    final combatBlock = ref.watch(combatBlockReasonProvider);

    return Scaffold(
      // Über „Heute" steigen die Zahlen eines Häkchens auf, wie auf dem
      // Gewohnheiten-Bildschirm (`AufstiegHost.maybeOf`).
      body: AufstiegHost(
        child: SafeArea(
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
                          image: HubCircleImage.plain,
                          progress: heute,
                          onTap: () => _open(context, const HabitsScreen()),
                        ),
                        HubCircle(
                          icon: Icons.account_tree_outlined,
                          label: 'Theorie',
                          image: HubCircleImage.plain,
                          symbol: theorySymbol,
                          onTap: () => _open(context, const SkillTreeScreen()),
                        ),
                        HubCircle(
                          icon: Icons.sports_martial_arts,
                          label: 'Kampf',
                          image: HubCircleImage.plain,
                          // Der Kampf hängt am Moveset (ADR-0025). Ist es zu
                          // dünn, nennt der Kreis beim Antippen, woran es
                          // liegt — der Satz unterscheidet drei Fälle, und
                          // der dritte ist der wichtigste: gelernt, aber
                          // nicht angelegt.
                          lockedReason: combatOpen ? null : combatBlock,
                          onTap: () => _open(context, const LadderScreen()),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    StatusLeiste(level: level, gold: gold),
                    const SizedBox(height: 12),

                    // **Heute** (ADR-0053) bekommt, was übrig bleibt. Bis
                    // zum 28.09. stand hier die Figur und gab an vollen
                    // Tagen Platz ab; sie ist jetzt in der Ausrüstung.
                    // Eine lange Liste rollt, statt überzulaufen.
                    // Darunter die **Tagesaufgaben** (Issue #88): Sie hängen
                    // an denselben Häkchen, und abgeholt wird, wo man
                    // abhakt.
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const TodayCard(),
                            // Die **Tagestruhe** direkt darunter: Sie ist
                            // der Lohn für genau diese Liste.
                            if (tracker.canOpenChest(today) ||
                                tracker.hasOpenedChest(today)) ...<Widget>[
                              const SizedBox(height: 10),
                              DailyChestCard(
                                canOpen: tracker.canOpenChest(today),
                                opened: tracker.hasOpenedChest(today)
                                    ? DailyChest.forDay(today)
                                    : null,
                                onOpen: () => openDailyChest(context, ref),
                              ),
                            ],
                            if (ref.watch(dailyQuestsProvider)
                                case final aufgaben
                                when aufgaben.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 10),
                              DailyQuestsCard(
                                quests: aufgaben,
                                isClaimed: (q) =>
                                    tracker.isQuestClaimed(today, q.id),
                                onClaim: (q) =>
                                    claimDailyQuest(context, ref, q),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        HubCircle(
                          icon: Icons.storefront_outlined,
                          label: 'Laden',
                          image: HubCircleImage.plain,
                          size: bottomCircleSize,
                          onTap: () => _open(context, const ShopScreen()),
                        ),
                        // **Nie gesperrt**, obwohl auf Level 1 nur der
                        // Waffenplatz offen ist: Der Bildschirm zeigt vor
                        // allem, was es zu holen gibt, und das ist genau
                        // dann am nützlichsten, wenn man noch nichts hat.
                        HubCircle(
                          icon: Icons.auto_awesome,
                          label: 'Fähigkeiten',
                          image: HubCircleImage.plain,
                          size: bottomCircleSize,
                          symbol: abilitySymbol,
                          onTap: () => _open(context, const AbilitiesScreen()),
                        ),
                        HubCircle(
                          icon: Icons.shield_outlined,
                          label: 'Ausrüstung',
                          image: HubCircleImage.plain,
                          size: bottomCircleSize,
                          symbol: gearSymbol,
                          onTap: () => _open(context, const EquipmentScreen()),
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
                              size: bottomCircleSize,
                              // Die einzige Flaeche, die ihr Zeichen selbst
                              // mitbringt.
                              image: HubCircleImage.character,
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
        child: Druck(
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
      ),
    );
  }
}
