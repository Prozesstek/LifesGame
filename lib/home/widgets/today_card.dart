import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../../habits/daily_quests_provider.dart';
import '../../habits/habit_check_flow.dart';
import '../../habits/habits_controller.dart';
import '../../habits/habits_screen.dart';
import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';

/// **Heute** auf der Startseite: die offenen Gewohnheiten, abhakbar ohne
/// Bildschirmwechsel.
///
/// **Warum auf der Startseite.** Das Häkchen ist die eine Handlung, die
/// jeden Tag passieren soll — und war einer von sechs gleich großen
/// Kreisen, einen Tipp und einen Bildschirm entfernt. Jede Reibung dort
/// kostet genau die Tage, an denen die Lust ohnehin knapp ist.
///
/// **Nur, was offen ist.** Erledigtes schrumpft auf eine Zeile, sobald
/// alles erledigt ist, weist die Karte auf die Truhe. Sie ist damit
/// kurz, wo sie nichts mehr verlangt, und die Figur behält den Platz.
///
/// Abgehakt wird über [toggleHabit] — dieselbe Stelle wie auf dem
/// Gewohnheiten-Bildschirm, samt Klang, Feiern und aufsteigenden Zahlen.
/// Alles Weitere (Ziele Schritt für Schritt, Auslöser ändern, Vorlagen)
/// bleibt dort; ein Tipp auf „Heute" führt hin.
class TodayCard extends ConsumerWidget {
  const TodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(habitTrackerProvider);
    final today = ref.watch(todayProvider);

    final liste = tracker.dailyListOn(today);
    final offen = <Habit>[
      for (final habit in liste)
        if (!tracker.isChecked(habit.id, today)) habit,
    ];
    final erledigt = liste.length - offen.length;
    final abholbar = ref.watch(claimableQuestsProvider).length;

    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Kopf(
            done: erledigt,
            total: liste.length,
            streak: tracker.currentDayStreak(today),
            heuteGetan: tracker.hasCheckOn(today),
          ),
          if (liste.isEmpty)
            const _Hinweis(
              icon: Icons.play_circle_outline,
              text:
                  'Noch nichts auf der Liste — starte deine erste '
                  'Gewohnheit',
            )
          else ...<Widget>[
            for (final habit in offen)
              _OffeneZeile(
                key: ValueKey<String>(habit.id),
                habit: habit,
                cue: tracker.cueFor(habit.id),
                onTap: () => toggleHabit(context, ref, habit),
              ),
            // Eine erledigte Tagesaufgabe wartet (ADR-0055) — abgeholt
            // wird auf dem Gewohnheiten-Bildschirm, wo die Aufgaben stehen.
            if (abholbar > 0)
              _Hinweis(
                icon: Icons.flag_rounded,
                text: abholbar == 1
                    ? 'Eine Tagesaufgabe ist erledigt — abholen'
                    : '$abholbar Tagesaufgaben sind erledigt — abholen',
                highlight: true,
              ),
            if (offen.isEmpty)
              _Hinweis(
                icon: Icons.inventory_2_outlined,
                text: tracker.canOpenChest(today)
                    ? 'Alles erledigt — die Tagestruhe wartet'
                    : 'Alles erledigt',
                highlight: tracker.canOpenChest(today),
              )
            else if (erledigt > 0)
              _Hinweis(
                icon: Icons.check_circle,
                text: erledigt == 1 ? '1 erledigt' : '$erledigt erledigt',
              ),
          ],
        ],
      ),
    );
  }
}

void _oeffneGewohnheiten(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const HabitsScreen()));
}

/// „Heute" und der Stand — führt zum Gewohnheiten-Bildschirm.
class _Kopf extends StatelessWidget {
  const _Kopf({
    required this.done,
    required this.total,
    required this.streak,
    required this.heuteGetan,
  });

  final int done;
  final int total;

  /// Die Tageskette (ADR-0055) — die eine Zahl, die man schützen will.
  final int streak;

  /// Ob heute schon etwas abgehakt ist. Sonst brennt die Flamme blass:
  /// Die Kette lebt noch, aber heute trägt sie noch nichts.
  final bool heuteGetan;

  @override
  Widget build(BuildContext context) {
    return Druck(
      child: InkWell(
        onTap: () => _oeffneGewohnheiten(context),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: <Widget>[
              const Text(
                'Heute',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Palette.text,
                ),
              ),
              if (streak > 0) ...<Widget>[
                const SizedBox(width: 10),
                _Flamme(streak: streak, heuteGetan: heuteGetan),
              ],
              const Spacer(),
              if (total > 0)
                Text(
                  '$done / $total',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Palette.textDim,
                  ),
                ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Palette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Die Flamme der Tageskette: kräftig, sobald heute etwas abgehakt ist,
/// blass, solange der Tag sie noch nicht trägt.
class _Flamme extends StatelessWidget {
  const _Flamme({required this.streak, required this.heuteGetan});

  final int streak;
  final bool heuteGetan;

  @override
  Widget build(BuildContext context) {
    final farbe = heuteGetan ? Palette.accent : Palette.muted;
    return Semantics(
      label: heuteGetan
          ? '$streak Tage am Stück'
          : '$streak Tage am Stück, heute noch offen',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.local_fire_department_rounded, size: 20, color: farbe),
          const SizedBox(width: 2),
          Text(
            '$streak',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: farbe,
            ),
          ),
        ],
      ),
    );
  }
}

/// Eine offene Gewohnheit: antippen hakt ab.
class _OffeneZeile extends StatelessWidget {
  const _OffeneZeile({
    required this.habit,
    required this.cue,
    required this.onTap,
    super.key,
  });

  final Habit habit;
  final String? cue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = cue;

    return Semantics(
      button: true,
      label: '${habit.name} abhaken',
      child: Druck(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.radio_button_unchecked,
                  size: 22,
                  color: Palette.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        habit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Palette.text,
                        ),
                      ),
                      if (text != null)
                        Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Palette.textDim,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Eine Zeile, die nicht abhakt, sondern hinführt.
class _Hinweis extends StatelessWidget {
  const _Hinweis({
    required this.icon,
    required this.text,
    this.highlight = false,
  });

  final IconData icon;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final farbe = highlight ? Palette.accent : Palette.textDim;

    return Druck(
      child: InkWell(
        onTap: () => _oeffneGewohnheiten(context),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: farbe),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: farbe,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
