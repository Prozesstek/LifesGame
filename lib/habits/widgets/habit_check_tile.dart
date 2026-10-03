import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../ui/gold_icon.dart';
import '../../ui/palette.dart';
import '../../ui/holz.dart';
import '../../ui/druck.dart';

/// Eine laufende Gewohnheit: abhaken, Streak sehen, ein Tagesziel füllen.
///
/// **Zwei Griffe, damit keiner mehrdeutig wird.** Die Kachel selbst hakt
/// ganz ab oder nimmt zurück — dieselbe Geste wie vor ADR-0028, und die
/// einzige für alles ohne Ziel. Das Plus daneben füllt ein Ziel um einen
/// Schritt. Wer fünf Gläser trinkt, tippt fünfmal auf das Plus; wer schon
/// weiß, dass der Tag steht, tippt einmal auf die Kachel.
///
/// **Ohne Untertexte seit Issue #35 — mit Zahlen seit Issue #46.** Unter
/// dem Namen stand bis #35 eine Zeile Prosa („+1 Stärke · 3 Tage am
/// Stück · x1,2"), und sie ist zu Recht gegangen: Bei fünf Gewohnheiten
/// waren das zehn Zeilen, die sich täglich kaum ändern. Was dabei
/// verloren ging, war der **Ertrag** — die Kachel zeigte den
/// Multiplikator, aber nirgends, was er in Erfahrung bedeutet. Er steht
/// jetzt als Zahl da, vor dem Tippen: „was bringt mir das" ist die
/// Frage, die ein Tracker jeden Tag beantworten muss.
///
/// Die Zahlen kommen fertig herein und werden hier nicht gerechnet —
/// `HabitTracker.xpForNextCheck` ist die eine Stelle, die weiß, was ein
/// Häkchen wert ist.
class HabitCheckTile extends StatelessWidget {
  const HabitCheckTile({
    required this.habit,
    required this.isChecked,
    required this.streak,
    required this.nextMultiplier,
    required this.xpGain,
    required this.goldGain,
    required this.progress,
    required this.onToggle,
    required this.onAdvance,
    required this.onStop,
    this.cue,
    this.treat,
    this.days,
    this.cued = false,
    this.onEditCue,
    super.key,
  });

  /// Wie lange der Wechsel von „offen" auf „erledigt" dauert.
  ///
  /// Kurz genug, dass niemand wartet, lang genug, dass man es sieht — ein
  /// Häkchen, das ohne Regung erscheint, fühlt sich nach Formular an.
  static const Duration checkDuration = Duration(milliseconds: 220);

  final Habit habit;
  final bool isChecked;

  /// Länge der Kette, die heute zählt.
  final int streak;

  /// Der Multiplikator, den das nächste Häkchen brächte.
  final double nextMultiplier;

  /// Erfahrung für das nächste Häkchen — oder die, die das heutige schon
  /// gebracht hat.
  final int xpGain;

  /// Gold, ebenso.
  final int goldGain;

  /// Wie weit das Tagesziel gefüllt ist.
  final int progress;

  final VoidCallback onToggle;

  /// Ein Schritt auf das Tagesziel.
  final VoidCallback onAdvance;

  final VoidCallback onStop;

  /// Wann die Gewohnheit drankommt — „nach dem Zähneputzen" (ADR-0052).
  ///
  /// Steht **unten** auf der Kachel, nicht unter dem Namen: Die Mitte
  /// ist, wo man zum Abhaken hintippt, und eine eigene Tippfläche dort
  /// machte aus einem Häkchen einen Dialog. Auf einer erledigten Kachel
  /// fällt er weg — dort hat er seine Arbeit getan.
  final String? cue;

  /// Was es danach gibt — „Kaffee" (ADR-0066). Steht unter dem Auslöser,
  /// solange die Kachel offen ist: Die Vorfreude gehört **vor** das
  /// Häkchen.
  final String? treat;

  /// Die Wochentage als „Mo Mi Fr" (ADR-0064) — null, wenn jeder Tag
  /// fällig ist. Steht vor dem Auslöser in derselben Zeile.
  final String? days;

  /// Ob sie **jetzt dran** ist, weil ihr Anker abgehakt wurde
  /// (ADR-0065). Dann trägt der Kreis links die Akzentfarbe.
  final bool cued;

  /// Öffnet die Frage nach dem Auslöser. Null blendet die Zeile aus.
  final VoidCallback? onEditCue;

  HabitGoal? get _goal => habit.goal;

  @override
  Widget build(BuildContext context) {
    final goal = _goal;
    final zeigtPlus = goal != null && !isChecked;
    final zeigtBalken = goal != null && !isChecked;

    return Druck(
      child: HolzKarte(
        padding: EdgeInsets.zero,
        color: isChecked ? Palette.surfaceRaised : Palette.surface,
        // Grün, wenn erledigt; in der Akzentfarbe, solange sie dran ist
        // — das Aufleuchten vergeht, die Kante bleibt.
        edgeColor: isChecked
            ? Palette.success
            : (cued ? Palette.accent : Holz.kante),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: <Widget>[
                  _CheckMark(
                    isChecked: isChecked,
                    cued: cued,
                    label: habit.name,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isChecked ? Palette.textDim : Palette.text,
                            decoration: isChecked
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: Palette.muted,
                          ),
                        ),
                        const SizedBox(height: 5),
                        RewardLine(
                          xp: xpGain,
                          gold: goldGain,
                          alreadyEarned: isChecked,
                        ),
                        if (zeigtBalken) ...<Widget>[
                          const SizedBox(height: 7),
                          _GoalBar(
                            done: progress,
                            target: goal.target,
                            label: goal.progressLabel(progress),
                          ),
                        ],
                        if (!isChecked && onEditCue != null) ...<Widget>[
                          const SizedBox(height: 4),
                          _CueLine(
                            cue: cue,
                            days: days,
                            treat: treat,
                            onTap: onEditCue!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (streak > 0) ...<Widget>[
                    const SizedBox(width: 8),
                    _StreakBadge(
                      streak: streak,
                      nextMultiplier: nextMultiplier,
                    ),
                  ],
                  if (zeigtPlus)
                    DruckSperre(
                      child: IconButton(
                        onPressed: onAdvance,
                        icon: const Icon(Icons.add_circle_outline, size: 22),
                        color: Palette.accent,
                        tooltip: _plusTooltip(goal),
                      ),
                    ),
                  DruckSperre(
                    child: IconButton(
                      onPressed: onStop,
                      icon: const Icon(Icons.close, size: 18),
                      color: Palette.muted,
                      tooltip: 'Nicht mehr verfolgen',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _plusTooltip(HabitGoal goal) {
    return goal.step == 1 ? 'Eins mehr' : '${goal.step} ${goal.unit} mehr';
  }
}

/// Die Zeile mit dem Auslöser — oder, ohne ihn, die Frage danach.
///
/// Eine eigene Tippfläche in der Kachel: Wer sie antippt, will den Satz
/// ändern, nicht abhaken. Ihr eigener [Druck] gewinnt als innerster, die
/// Kachel darum bleibt stehen.
class _CueLine extends StatelessWidget {
  const _CueLine({
    required this.cue,
    required this.days,
    required this.treat,
    required this.onTap,
  });

  final String? cue;
  final String? treat;
  final String? days;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = cue;
    final tage = days;
    final farbe = text == null ? Palette.muted : Palette.textDim;
    final danach = treat;

    return Druck(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: danach == null
              ? _wann(text, tage, farbe)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _wann(text, tage, farbe),
                    const SizedBox(height: 2),
                    TreatLine(text: danach),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _wann(String? text, String? tage, Color farbe) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Ohne Auslöser steht nur der Wecker da — die Frage dazu
        // stellt der Dialog, nicht die Kachel.
        Icon(
          text == null ? Icons.add_alarm_outlined : Icons.link_rounded,
          size: text == null ? 18 : 14,
          color: farbe,
          semanticLabel: text == null ? 'Wann machst du das?' : null,
        ),
        // Tage und Auslöser als **ein** Text über zwei Zeilen: Neben
        // Kette und Knöpfen bleiben der Spalte rund 130 Punkte, und
        // zwei Texte nebeneinander kürzten den Auslöser auf drei
        // Wörter.
        if (tage != null || text != null) ...<Widget>[
          const SizedBox(width: 4),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  if (tage != null)
                    TextSpan(
                      text: text == null ? tage : '$tage  ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Palette.textDim,
                      ),
                    ),
                  if (text != null) TextSpan(text: text),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: farbe),
            ),
          ),
        ],
      ],
    );
  }
}

/// Die Belohnung danach mit ihrem Zeichen, dem Geschenk (ADR-0066).
///
/// **Eine Stelle** für Kachel und Startseite, damit das Geschenk überall
/// dasselbe ist.
class TreatLine extends StatelessWidget {
  const TreatLine({required this.text, this.fontSize = 12, super.key});

  static const IconData icon = Icons.redeem_rounded;

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: fontSize + 2, color: Palette.gold),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            semanticsLabel: 'Danach: $text',
            style: TextStyle(fontSize: fontSize, color: Palette.textDim),
          ),
        ),
      ],
    );
  }
}

/// Der Kreis links, der beim Abhaken aufpoppt.
///
/// Der Sprung kommt aus einem [AnimatedSwitcher] statt aus einem eigenen
/// Zustand: Die Kachel bleibt damit zustandslos, und die Animation läuft
/// auch dann, wenn der Tracker von woanders geändert wird.
class _CheckMark extends StatelessWidget {
  const _CheckMark({
    required this.isChecked,
    required this.cued,
    required this.label,
  });

  final bool isChecked;
  final bool cued;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: isChecked,
      label: cued ? '$label, jetzt dran' : label,
      child: AnimatedSwitcher(
        duration: HabitCheckTile.checkDuration,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
          key: ValueKey<bool>(isChecked),
          size: 26,
          color: isChecked
              ? Palette.success
              : (cued ? Palette.accent : Palette.muted),
        ),
      ),
    );
  }
}

/// Was ein Häkchen einbringt — oder eingebracht hat.
///
/// **Sie steht auf jeder Kachel, nicht nur nach dem Tippen.** Eine
/// Rückmeldung, die erst nach der Tat kommt, kann nicht zur Tat bewegen;
/// die Zahl vorher ist der Grund, die Zahl danach die Bestätigung.
class RewardLine extends StatelessWidget {
  const RewardLine({
    required this.xp,
    required this.gold,
    this.alreadyEarned = false,
    super.key,
  });

  final int xp;
  final int gold;

  /// Ob es schon geholt ist. Dann tragen die Zahlen die Farbe des Erfolgs
  /// statt die des Angebots.
  final bool alreadyEarned;

  @override
  Widget build(BuildContext context) {
    final farbe = alreadyEarned ? Palette.success : Palette.accent;
    final stil = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: farbe,
    );

    return Semantics(
      label: alreadyEarned
          ? 'Heute geholt: $xp Erfahrung und $gold Gold'
          : 'Bringt $xp Erfahrung und $gold Gold',
      // **Jeder Text schrumpfbar.** Auf der vollsten Kachel — eigene
      // Gewohnheit mit Ziel, also Plus **und** Kreuz daneben, dazu die
      // Streak-Marke — bleiben für diese Spalte keine 90 Pixel. Zwei
      // feste Texte nebeneinander sind genau der Fall aus `gotchas.md`.
      child: Row(
        children: <Widget>[
          Icon(Icons.auto_awesome, size: 13, color: farbe),
          const SizedBox(width: 3),
          Flexible(
            child: Text('+$xp', style: stil, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          const GoldIcon(size: 13),
          const SizedBox(width: 3),
          Flexible(
            child: Text('+$gold', style: stil, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

/// Die Kette als Marke neben dem Namen.
///
/// Sie ist der Grund, morgen wiederzukommen, und damit die einzige Zahl,
/// die den Weg aus dem Untertext heraus verdient hat. Ohne laufende Kette
/// erscheint sie gar nicht — „noch keine Streak" ist eine Null, die
/// niemand lesen muss.
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak, required this.nextMultiplier});

  final int streak;
  final double nextMultiplier;

  @override
  Widget build(BuildContext context) {
    final faktor = nextMultiplier <= 1.0
        ? null
        : 'x${nextMultiplier.toStringAsFixed(1).replaceAll('.', ',')}';

    // **Die nächste Stufe steht darunter** (Issue #88). Bis zum 28.09.
    // zeigte das eine eigene Karte als Leiter über der Liste; hier steht
    // nur, was als Nächstes kommt, und nur an der Kette, die es betrifft.
    final naechste = HabitRewards.nextMilestoneAfter(streak);
    final noch = naechste == null ? 0 : naechste.days - streak;

    return Semantics(
      label: streak == 1 ? '1 Tag am Stück' : '$streak Tage am Stück',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.local_fire_department,
                size: 14,
                color: Palette.gold,
              ),
              const SizedBox(width: 3),
              Text(
                faktor == null ? '$streak' : '$streak · $faktor',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Palette.gold,
                ),
              ),
            ],
          ),
          // Die nächste Stufe ohne Worte: Uhr, Tage, Faktor.
          if (naechste != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.update_rounded,
                  size: 10,
                  color: Palette.textDim,
                ),
                const SizedBox(width: 2),
                Text(
                  '$noch',
                  style: const TextStyle(fontSize: 9, color: Palette.textDim),
                ),
                const Icon(
                  Icons.arrow_right_alt_rounded,
                  size: 11,
                  color: Palette.textDim,
                ),
                Text(
                  _faktor(naechste.multiplier),
                  style: const TextStyle(fontSize: 9, color: Palette.textDim),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _faktor(double wert) {
    return 'x${wert.toStringAsFixed(1).replaceAll('.', ',')}';
  }
}

/// Ein schmaler Balken für den angefangenen Tag, mit seiner Zahl daneben.
///
/// Die Zahl stand bis Issue #35 in der Zeile darüber. Sie ist mit an den
/// Balken gewandert statt zu verschwinden: Ein Balken allein sagt „etwa
/// die Hälfte", und wer fünf Gläser zählt, will wissen, ob er beim
/// dritten oder vierten steht.
class _GoalBar extends StatelessWidget {
  const _GoalBar({
    required this.done,
    required this.target,
    required this.label,
  });

  final int done;
  final int target;
  final String label;

  @override
  Widget build(BuildContext context) {
    final anteil = target <= 0 ? 0.0 : (done / target).clamp(0.0, 1.0);

    return Row(
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: anteil,
              minHeight: 4,
              backgroundColor: Palette.surfaceRaised,
              valueColor: const AlwaysStoppedAnimation<Color>(Palette.accent),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Palette.textDim),
          ),
        ),
      ],
    );
  }
}
