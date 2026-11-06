import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../../habits/cue_text.dart';
import '../../habits/habit_check_flow.dart';
import '../../habits/habits_controller.dart';
import '../../habits/habits_screen.dart';
import '../../habits/widgets/habit_check_tile.dart';
import '../../habits/widgets/haekchen_kreis.dart';
import '../../habits/widgets/habit_countdown.dart';
import '../../skills/gebiet_farbe.dart';
import '../../skills/gebiet_zeichen.dart';
import '../../ui/anschlagtafel.dart';
import '../../ui/druck.dart';
import '../../ui/halten_und_ziehen.dart';
import '../../ui/palette.dart';
import '../../ui/pulsieren.dart';
import '../erster_start.dart';
import '../erster_start_provider.dart';

/// **Heute** auf der Startseite: die offenen Gewohnheiten, abhakbar ohne
/// Bildschirmwechsel.
///
/// **Warum auf der Startseite.** Das Häkchen ist die eine Handlung, die
/// jeden Tag passieren soll — und war einer von sechs gleich großen
/// Kreisen, einen Tipp und einen Bildschirm entfernt. Jede Reibung dort
/// kostet genau die Tage, an denen die Lust ohnehin knapp ist.
///
/// **Auch, was erledigt ist** (Frederik, 30.09.). Bis dahin schrumpfte
/// Erledigtes auf „✓ 2“, und am Ende des Tages stand nichts mehr da, was
/// man geschafft hat. Jetzt bleibt jede Zeile stehen, abgehakt und
/// durchgestrichen, unter den offenen — die Reihenfolge ist die von
/// `HabitTracker.dailyListOn`. Ein Tipp auf eine erledigte nimmt das
/// Häkchen zurück, wie im Gewohnheiten-Bildschirm.
///
/// Abgehakt wird über [tapHabit] — dieselbe Stelle wie auf dem
/// Gewohnheiten-Bildschirm, samt Klang, Feiern und aufsteigenden Zahlen.
/// Ein Zeitziel öffnet dort seinen Timer (ADR-0067); die Restzeit steht
/// rechts in der Zeile.
/// Alles Weitere (Ziele Schritt für Schritt, Auslöser ändern, Vorlagen)
/// bleibt dort; hin führt der Kreis „Gewohnheiten“.
///
/// **Eine Anschlagtafel, jede Gewohnheit ein Zettel** (23.10.2026,
/// Frederik: „die Gewohnheiten aber eigentlich auch“ — nach den
/// Tagesaufgaben am Lagerfeuer). Die Zettel hängen untereinander, damit
/// Name und „Wann“ lesbar bleiben und Gekoppeltes unter seinem Anker
/// steht. Erledigt liegt ein Stempel darauf.
class TodayCard extends ConsumerWidget {
  const TodayCard({super.key});

  /// Woran Tests die Flamme des Vorsatzes vom Lagerfeuer finden
  /// (ADR-0076).
  static const Key flammeKey = ValueKey<String>('heute-zuerst');

  /// Der Schein um den Zettel von [habitId], der beim ersten Häkchen
  /// pulsiert (06.11.2026).
  static Key pulsKey(String habitId) {
    return ValueKey<String>('heute-puls-$habitId');
  }

  /// Das Zeichen des Gebiets an der Zeile von [habitId] (ADR-0085).
  static Key gebietKey(String habitId) {
    return ValueKey<String>('heute-gebiet-$habitId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(habitTrackerProvider);
    final today = ref.watch(todayProvider);

    // Samt Einrückung und „jetzt dran" (ADR-0065).
    final liste = tracker.stackOn(today);
    // Beim ersten Häkchen leuchtet die Gewohnheit (06.11.2026).
    final hervorheben =
        ref.watch(ersterStartProvider).schritt == Schritt.abhaken;

    // **Ohne Schild** (06.11.2026, Frederik): Zu den Gewohnheiten führt
    // jederzeit ihr Kreis. Mit dem Schild ging die kleine Flamme der
    // Tageskette — die Kette zeigt die große Feier beim ersten Häkchen.
    return Anschlagtafel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (tracker.activeIds.isEmpty)
            const _Hinweis(
              icon: Icons.add_circle_outline,
              label: 'Erste Gewohnheit starten',
              highlight: true,
            )
          else if (liste.isEmpty)
            // Es läuft etwas, aber heute ist nichts dran (ADR-0064).
            const _Hinweis(
              icon: Icons.self_improvement_rounded,
              label: 'Ruhetag — heute ist nichts fällig',
            )
          else
            for (final eintrag in liste)
              _Zettel(
                key: ValueKey<String>(eintrag.habit.id),
                habit: eintrag.habit,
                done: tracker.isChecked(eintrag.habit.id, today),
                cue: CueText.lineFor(tracker, eintrag.habit.id),
                treat: tracker.treatFor(eintrag.habit.id),
                depth: eintrag.depth,
                cued: eintrag.isCued,
                timed: tracker.hasTimer(eintrag.habit.id),
                zuerst: tracker.firstUpOn(today) == eintrag.habit.id,
                hervorheben: hervorheben,
                onTap: () => tapHabit(context, ref, eintrag.habit),
                onTimerDone: () =>
                    finishHabitTimer(context, ref, eintrag.habit),
              ),
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

/// Eine Gewohnheit von heute als Zettel an der Tafel: antippen hakt ab —
/// oder nimmt das Häkchen zurück. Erledigt steht sie grau da, ohne
/// Auslöser, und ein Stempel liegt darauf.
class _Zettel extends StatelessWidget {
  const _Zettel({
    required this.habit,
    required this.done,
    required this.cue,
    required this.onTap,
    this.treat,
    this.depth = 0,
    this.cued = false,
    this.timed = false,
    this.zuerst = false,
    this.hervorheben = false,
    this.onTimerDone,
    super.key,
  });

  /// Ob der Mentor gerade auf das erste Häkchen wartet — dann pulsiert
  /// der offene Zettel (06.11.2026).
  final bool hervorheben;

  /// Je Stufe im Stapel so weit nach rechts, höchstens drei Stufen.
  static const double _schritt = 14;
  static const int _hoechstens = 3;

  final Habit habit;
  final bool done;
  final String? cue;

  /// Was es danach gibt (ADR-0066) — nur solange offen.
  final String? treat;
  final VoidCallback onTap;

  /// Wie tief die Gewohnheit unter ihrem Anker hängt (ADR-0065).
  final int depth;

  /// Ob sie jetzt dran ist, weil ihr Anker abgehakt wurde.
  final bool cued;

  /// Ob sie ein Zeitziel hat — dann steht rechts die Restzeit.
  final bool timed;

  /// Ob sie am Abend davor am Feuer als Erstes gewählt wurde (ADR-0076)
  /// — dann trägt sie eine kleine Flamme.
  final bool zuerst;

  /// Der laufende Timer ist bei null angekommen.
  final VoidCallback? onTimerDone;

  /// Wie groß der Stempel auf einem Zettel ist, und wie viel Platz er
  /// rechts braucht.
  static const double _stempel = 36;
  static const double _stempelPlatz = _stempel - 4;

  /// Ein Zettel ist niedrig: wenig Rand, unten kommt die Risskante dazu.
  static const EdgeInsets innen = EdgeInsets.fromLTRB(10, 9, 10, 3);

  /// Wie schief ein Zettel hängt — **aus der Id, nicht aus dem Platz**:
  /// Ein abgehakter wandert nach unten und soll dabei nicht umkippen.
  static double neigungFuer(String id) => (id.hashCode % 5 - 2) * 0.005;

  @override
  Widget build(BuildContext context) {
    final text = done ? null : cue;
    final stufen = depth > _hoechstens ? _hoechstens : depth;

    return Padding(
      padding: EdgeInsets.only(left: _schritt * stufen, top: 2),
      child: Semantics(
        button: true,
        label: done
            ? '${habit.name} erledigt'
            : '${habit.name} ${timed ? 'Timer öffnen' : 'abhaken'}'
                  '${cued ? ', jetzt dran' : ''}'
                  '${zuerst ? ', heute zuerst' : ''}',
        child: Druck(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Pulsieren(
              key: TodayCard.pulsKey(habit.id),
              aktiv: hervorheben && !done,
              child: Steckbrief(
                neigung: neigungFuer(habit.id),
                saat: habit.id.hashCode,
                abgestempelt: done,
                innen: innen,
                stempelGroesse: _stempel,
                // Die Farbe ihres Gebiets am linken Rand (ADR-0090), wie
                // auf der Kachel; erledigt blass.
                streifen: switch (habit.area) {
                  final SkillArea gebiet => GebietFarbe.pergament(
                    gebiet,
                  ).withValues(alpha: done ? 0.4 : 1),
                  null => null,
                },
                child: PlatzLaedtEin(
                  aktiv: cued,
                  radius: 6,
                  child: _zeile(text, done ? null : treat),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _zeile(String? text, String? danach) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          HaekchenKreis(isChecked: done, size: 22, offenFarbe: Palette.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        habit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          // Grau, nicht durchgestrichen: Erledigt sagt der
                          // Stempel.
                          color: done ? Palette.textDim : Palette.text,
                        ),
                      ),
                    ),
                    if (zuerst) ...<Widget>[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.local_fire_department,
                        key: TodayCard.flammeKey,
                        size: 15,
                        color: Palette.tintLava,
                      ),
                    ],
                  ],
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
                if (danach != null) TreatLine(text: danach, fontSize: 11),
              ],
            ),
          ),
          // **Wohin sie zählt** (ADR-0085): das Zeichen ihres
          // Gebiets, in seiner Farbe wie sein Balken in der Leiste oben
          // (ADR-0090). Erledigt liegt dort der Stempel.
          if ((habit.area, done) case (
            final SkillArea gebiet,
            false,
          )) ...<Widget>[
            const SizedBox(width: 8),
            Icon(
              gebietZeichen(gebiet),
              key: TodayCard.gebietKey(habit.id),
              size: 15,
              color: GebietFarbe.pergament(gebiet),
            ),
          ],
          // Erledigt bleibt rechts Platz für den Stempel, sonst läge er
          // auf einem langen Namen.
          if (done) const SizedBox(width: _stempelPlatz),
          if (timed && !done) ...<Widget>[
            const SizedBox(width: 8),
            HabitCountdown(
              habit: habit,
              onDone: onTimerDone,
              builder: (context, uhr) => _Restzeit(uhr: uhr),
            ),
          ],
        ],
      ),
    );
  }
}

/// Die Restzeit eines Zeitziels: blass, solange nichts läuft, in der
/// Akzentfarbe, sobald der Timer läuft.
class _Restzeit extends StatelessWidget {
  const _Restzeit({required this.uhr});

  final HabitClock uhr;

  @override
  Widget build(BuildContext context) {
    final farbe = uhr.isRunning ? Palette.accent : Palette.textDim;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          uhr.isRunning ? Icons.timer_rounded : Icons.timer_outlined,
          size: 15,
          color: farbe,
        ),
        const SizedBox(width: 3),
        Text(
          uhr.label,
          semanticsLabel: uhr.semanticLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: uhr.isRunning ? FontWeight.bold : FontWeight.w600,
            color: farbe,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Ein Zettel, der nicht abhakt, sondern hinführt — nur ein Zeichen. Was
/// es heißt, sagt [label] dem Vorleser.
class _Hinweis extends StatelessWidget {
  const _Hinweis({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final farbe = highlight ? Palette.accent : Palette.textDim;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Druck(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _oeffneGewohnheiten(context),
          child: Steckbrief(
            innen: _Zettel.innen,
            child: Row(
              children: <Widget>[
                Icon(icon, size: highlight ? 26 : 20, color: farbe),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
