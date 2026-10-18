import 'dart:math' as math;

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
import '../../ui/druck.dart';
import '../../ui/halten_und_ziehen.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../../ui/sprung.dart';

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
/// bleibt dort; ein Tipp auf „Heute" führt hin.
class TodayCard extends ConsumerWidget {
  const TodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(habitTrackerProvider);
    final today = ref.watch(todayProvider);

    // Samt Einrückung und „jetzt dran" (ADR-0065).
    final liste = tracker.stackOn(today);
    final erledigt = liste
        .where((eintrag) => tracker.isChecked(eintrag.habit.id, today))
        .length;

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
              _Zeile(
                key: ValueKey<String>(eintrag.habit.id),
                habit: eintrag.habit,
                done: tracker.isChecked(eintrag.habit.id, today),
                cue: CueText.lineFor(tracker, eintrag.habit.id),
                treat: tracker.treatFor(eintrag.habit.id),
                depth: eintrag.depth,
                cued: eintrag.isCued,
                timed: tracker.hasTimer(eintrag.habit.id),
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
              const Icon(
                Icons.checklist_rounded,
                size: 22,
                color: Palette.text,
                semanticLabel: 'Heute',
              ),
              // Immer im Baum, auch ohne Kette: Sonst entstünde sie mit
              // dem ersten Häkchen neu und hätte kein Vorher, aus dem sie
              // zünden könnte.
              _Flamme(streak: streak, heuteGetan: heuteGetan),
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
/// blass, solange der Tag sie noch nicht trägt. Ohne Kette steht nichts
/// da.
///
/// **Mit dem ersten Häkchen des Tages zündet sie** (18.10.), wie die
/// Flamme bei Duolingo: Sie schiesst hoch und pendelt zurück, glüht,
/// Funken steigen, und die Zahl rollt eins weiter. Danach brennt sie
/// still. Nur dann — wer die Startseite später öffnet, sieht sie schon
/// brennen.
class _Flamme extends StatefulWidget {
  const _Flamme({required this.streak, required this.heuteGetan});

  final int streak;
  final bool heuteGetan;

  static const Duration zuenden = Duration(milliseconds: 900);

  @override
  State<_Flamme> createState() => _FlammeState();
}

class _FlammeState extends State<_Flamme> with SingleTickerProviderStateMixin {
  // In `initState`, nicht faul: Ohne Kette baut die Flamme nichts, und
  // ein fauler Controller entstünde erst in `dispose` (`gotchas.md`).
  late final AnimationController _zuenden;

  @override
  void initState() {
    super.initState();
    _zuenden = AnimationController(
      vsync: this,
      duration: _Flamme.zuenden,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(_Flamme alt) {
    super.didUpdateWidget(alt);
    if (!alt.heuteGetan && widget.heuteGetan) _zuenden.forward(from: 0);
  }

  @override
  void dispose() {
    _zuenden.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = widget.streak;
    if (streak <= 0) return const SizedBox.shrink();
    final farbe = widget.heuteGetan ? Palette.accent : Palette.muted;
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Semantics(
        label: widget.heuteGetan
            ? '$streak Tage am Stück'
            : '$streak Tage am Stück, heute noch offen',
        child: AnimatedBuilder(
          animation: _zuenden,
          builder: (context, _) {
            final t = _zuenden.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CustomPaint(
                  painter: t < 1 ? _GlutMaler(t) : null,
                  child: Transform.scale(
                    scale: Sprung.stoss(t, hoehe: 0.8),
                    alignment: Alignment.bottomCenter,
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      size: 20,
                      color: farbe,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                _RollendeZahl(wert: streak, farbe: farbe),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Die Zahl der Kette: Die neue rollt von unten herein, die alte nach
/// oben hinaus.
class _RollendeZahl extends StatelessWidget {
  const _RollendeZahl({required this.wert, required this.farbe});

  final int wert;
  final Color farbe;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      transitionBuilder: (child, animation) {
        final neu = child.key == ValueKey<int>(wert);
        final rollen = Tween<Offset>(
          begin: Offset(0, neu ? 0.8 : -0.8),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return SlideTransition(
          position: rollen,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Text(
        '$wert',
        key: ValueKey<int>(wert),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: farbe,
        ),
      ),
    );
  }
}

/// Der Schein hinter der zündenden Flamme und die Funken, die aufsteigen.
class _GlutMaler extends CustomPainter {
  const _GlutMaler(this.t);

  final double t;

  static const int _funken = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final mitte = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    final glut = Sprung.vergeht(t, 0.7);
    if (glut > 0) {
      final weit = r * (1.3 + 1.2 * (1 - glut));
      canvas.drawCircle(
        mitte,
        weit,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              Palette.tintLava.withValues(alpha: 0.7 * glut),
              Palette.tintLava.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: mitte, radius: weit)),
      );
    }

    final steigen = Sprung.abschnitt(t, 0.08, 1);
    if (steigen <= 0 || steigen >= 1) return;
    for (var i = 0; i < _funken; i++) {
      final seite = (i - (_funken - 1) / 2) * r * 0.32;
      final hoch = r * (0.4 + steigen * (2.4 + 0.5 * (i % 3)));
      final wackeln = math.sin(steigen * 9 + i * 1.7) * r * 0.2;
      canvas.drawCircle(
        Offset(mitte.dx + seite + wackeln, mitte.dy - hoch),
        1.8 * (1 - steigen) + 0.4,
        Paint()
          ..color = (i.isEven ? Palette.tintLava : Palette.accent).withValues(
            alpha: 1 - steigen,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_GlutMaler alt) => alt.t != t;
}

/// Eine Gewohnheit von heute: antippen hakt ab — oder nimmt das Häkchen
/// zurück. Erledigt steht sie grau und durchgestrichen da, ohne Auslöser.
class _Zeile extends StatelessWidget {
  const _Zeile({
    required this.habit,
    required this.done,
    required this.cue,
    required this.onTap,
    this.treat,
    this.depth = 0,
    this.cued = false,
    this.timed = false,
    this.onTimerDone,
    super.key,
  });

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

  /// Der laufende Timer ist bei null angekommen.
  final VoidCallback? onTimerDone;

  @override
  Widget build(BuildContext context) {
    final text = done ? null : cue;
    final stufen = depth > _hoechstens ? _hoechstens : depth;

    return Padding(
      padding: EdgeInsets.only(left: _schritt * stufen),
      child: PlatzLaedtEin(
        aktiv: cued,
        radius: 6,
        child: _zeile(text, done ? null : treat),
      ),
    );
  }

  Widget _zeile(String? text, String? danach) {
    return Semantics(
      button: true,
      label: done
          ? '${habit.name} erledigt'
          : '${habit.name} ${timed ? 'Timer öffnen' : 'abhaken'}'
                '${cued ? ', jetzt dran' : ''}',
      child: Druck(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: <Widget>[
                HaekchenKreis(
                  isChecked: done,
                  size: 22,
                  offenFarbe: Palette.accent,
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: done ? Palette.textDim : Palette.text,
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: Palette.textDim,
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
                      if (danach != null) TreatLine(text: danach, fontSize: 11),
                    ],
                  ),
                ),
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
          ),
        ),
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

/// Eine Zeile, die nicht abhakt, sondern hinführt — nur ein Zeichen. Was es heißt, sagt [label] dem Vorleser.
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
        child: InkWell(
          onTap: () => _oeffneGewohnheiten(context),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
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
