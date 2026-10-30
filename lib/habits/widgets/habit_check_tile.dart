import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../skills/widgets/gebiet_streifen.dart';
import '../../ui/gold_icon.dart';
import '../../ui/palette.dart';
import '../../ui/holz.dart';
import '../../ui/druck.dart';
import 'haekchen_kreis.dart';
import 'habit_countdown.dart';

/// Eine laufende Gewohnheit: abhaken, Streak sehen, ein Tagesziel füllen.
///
/// **Zwei Griffe, damit keiner mehrdeutig wird.** Die Kachel selbst hakt
/// ganz ab oder nimmt zurück — dieselbe Geste wie vor ADR-0028, und die
/// einzige für alles ohne Ziel. Das Plus daneben füllt ein Ziel um einen
/// Schritt. Wer fünf Gläser trinkt, tippt fünfmal auf das Plus; wer schon
/// weiß, dass der Tag steht, tippt einmal auf die Kachel.
///
/// **Ein Zeitziel läuft als Timer** (ADR-0067). Statt des Plus steht dort
/// der Knopf zum Timer, und solange er läuft, zeigt der Balken die
/// Restzeit. Was der Tipp auf die Kachel dann tut, entscheidet
/// `tapHabit`, nicht die Kachel.
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
///
/// **Nur noch Erfahrung, Gold und die Kette in Tagen** (ADR-0092). Der
/// Skill steht oben in den Kacheln der Gebiete, Bonus und nächste Stufe
/// der Kette sind weg.
class HabitCheckTile extends StatelessWidget {
  const HabitCheckTile({
    required this.habit,
    required this.isChecked,
    required this.streak,
    required this.xpGain,
    required this.goldGain,
    required this.progress,
    required this.onToggle,
    required this.onAdvance,
    required this.onStop,
    this.onTimer,
    this.onTimerDone,
    this.cue,
    this.treat,
    this.days,
    this.cued = false,
    this.onEditCue,
    super.key,
  });

  final Habit habit;
  final bool isChecked;

  /// Länge der Kette, die heute zählt.
  final int streak;

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

  /// Öffnet den Timer — nur bei einem Zeitziel gesetzt.
  final VoidCallback? onTimer;

  /// Der laufende Timer ist bei null angekommen.
  final VoidCallback? onTimerDone;

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
    final timer = goal?.kind == HabitGoalKind.zeit ? onTimer : null;
    final zeigtPlus = goal != null && !isChecked && timer == null;

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
            child: GebietStreifen(
              area: habit.area,
              blass: isChecked,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  14 - GebietStreifen.breite,
                  12,
                  8,
                  12,
                ),
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
                      _StreakMarke(streak: streak),
                    ],
                    // **Ein Tagesziel behält seinen kleinen Stand**: Sonst
                    // ließe sich eine Menge nicht mehr Schritt für Schritt
                    // füllen, und ein laufender Timer wäre nicht zu sehen.
                    if (timer != null && !isChecked) ...<Widget>[
                      const SizedBox(width: 8),
                      HabitCountdown(
                        habit: habit,
                        onDone: onTimerDone,
                        builder: (context, uhr) => _ZielStand(
                          text: uhr.label,
                          semanticLabel: uhr.semanticLabel,
                          laeuft: uhr.isRunning,
                        ),
                      ),
                      DruckSperre(
                        child: IconButton(
                          key: timerKey(habit.id),
                          onPressed: timer,
                          icon: const Icon(Icons.timer_outlined, size: 22),
                          color: Palette.accent,
                          tooltip: 'Timer',
                        ),
                      ),
                    ],
                    if (zeigtPlus) ...<Widget>[
                      const SizedBox(width: 8),
                      _ZielStand(
                        text: '$progress/${goal.target}',
                        semanticLabel: goal.progressLabel(progress),
                      ),
                      DruckSperre(
                        child: IconButton(
                          onPressed: onAdvance,
                          icon: const Icon(Icons.add_circle_outline, size: 22),
                          color: Palette.accent,
                          tooltip: _plusTooltip(goal),
                        ),
                      ),
                    ],
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
      ),
    );
  }

  /// Der Knopf zum Timer von [habitId] — ohne Wort, also mit Schlüssel.
  static Key timerKey(String habitId) {
    return ValueKey<String>('timer-oeffnen-$habitId');
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

/// Der Kreis links, der beim Abhaken aufspringt.
///
/// Der Sprung steckt im [HaekchenKreis], nicht in der Kachel: Die Kachel
/// bleibt damit zustandslos, und der Sprung läuft auch dann, wenn der
/// Tracker von woanders geändert wird — vom Timer etwa.
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
      child: HaekchenKreis(
        isChecked: isChecked,
        size: 26,
        offenFarbe: cued ? Palette.accent : Palette.muted,
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
      // **Die ganze Zeile schrumpft, keine Zahl wird abgeschnitten.** Auf
      // der vollsten Kachel — Timer **und** Kreuz daneben, dazu die Kette
      // — bleiben für diese Spalte keine 120 Pixel. Mit einem
      // `Flexible` je Zahl stand dort „+…“ zweimal (ADR-0085, beim
      // Ansehen gefunden); eine Zahl mit Auslassungspunkten ist keine.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.auto_awesome, size: 13, color: farbe),
            const SizedBox(width: 3),
            Text('+$xp', style: stil),
            const SizedBox(width: 8),
            const GoldIcon(size: 13),
            const SizedBox(width: 3),
            Text('+$gold', style: stil),
          ],
        ),
      ),
    );
  }
}

/// Die Kette in Tagen, mit ihrer Flamme (ADR-0092).
///
/// Sie ist der Grund, morgen wiederzukommen. Ohne laufende Kette erscheint
/// sie gar nicht — „noch keine Streak" ist eine Null, die niemand lesen
/// muss.
class _StreakMarke extends StatelessWidget {
  const _StreakMarke({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: streak == 1 ? '1 Tag am Stück' : '$streak Tage am Stück',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.local_fire_department,
            size: 16,
            color: Palette.gold,
          ),
          const SizedBox(width: 2),
          Text(
            '$streak',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Palette.gold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wie weit ein Tagesziel ist, klein neben seinem Knopf: „3/5“ oder die
/// Restzeit.
class _ZielStand extends StatelessWidget {
  const _ZielStand({
    required this.text,
    required this.semanticLabel,
    this.laeuft = false,
  });

  final String text;
  final String semanticLabel;

  /// Ob gerade ein Timer läuft — dann steht die Zahl kräftig da.
  final bool laeuft;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      semanticsLabel: semanticLabel,
      style: TextStyle(
        fontSize: 12,
        fontWeight: laeuft ? FontWeight.bold : FontWeight.w600,
        color: laeuft ? Palette.accent : Palette.textDim,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }
}
