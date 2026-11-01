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
/// **Ein Griff.** Die Kachel selbst hakt ganz ab oder nimmt zurück, auch
/// bei einer Menge: Dort steht nur, wie viel es sein soll („5 Gläser“).
///
/// **Ein Zeitziel läuft als Timer** (ADR-0067). Einen eigenen Knopf dafür
/// gibt es nicht: Der Tipp auf die Kachel öffnet ihn, das entscheidet
/// `tapHabit`. Unter dem Namen steht „0 von 2 Minuten“, solange er läuft die
/// Restzeit.
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
///
/// **Halten richtet sie ein**: Auslöser, Tage, Kopplung und Belohnung. Der
/// Wecker dafür ist weg, und **eine Kopplung sieht man an der Einrückung**
/// (`_ImStapel`), nicht an einer Zeile „Nach: …“.
class HabitCheckTile extends StatelessWidget {
  const HabitCheckTile({
    required this.habit,
    required this.isChecked,
    required this.streak,
    required this.xpGain,
    required this.goldGain,
    required this.onToggle,
    required this.onStop,
    this.hatTimer = false,
    this.onTimerDone,
    this.cue,
    this.anker,
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

  final VoidCallback onToggle;

  final VoidCallback onStop;

  /// Ob ein Tipp den Timer öffnet — dann steht sein Stand auf der Kachel.
  final bool hatTimer;

  /// Der laufende Timer ist bei null angekommen.
  final VoidCallback? onTimerDone;

  /// Wann die Gewohnheit drankommt — „nach dem Zähneputzen" (ADR-0052).
  ///
  /// Steht **unten** auf der Kachel, nicht unter dem Namen: Die Mitte
  /// ist, wo man zum Abhaken hintippt, und eine eigene Tippfläche dort
  /// machte aus einem Häkchen einen Dialog. Auf einer erledigten Kachel
  /// fällt er weg — dort hat er seine Arbeit getan.
  final String? cue;

  /// Der Name der Gewohnheit, an der sie hängt (ADR-0065) — **nur für den
  /// Vorleser**: Im Bild sagt es die Einrückung, und die sieht er nicht.
  final String? anker;

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

  /// Öffnet die Frage nach dem Auslöser: beim Halten der Kachel und beim
  /// Tipp auf ihre Zeile.
  final VoidCallback? onEditCue;

  HabitGoal? get _goal => habit.goal;

  bool get _hatZeile => cue != null || days != null || treat != null;

  @override
  Widget build(BuildContext context) {
    final goal = _goal;
    final hatZeitziel = goal?.kind == HabitGoalKind.zeit && hatTimer;
    final timer = hatZeitziel && !isChecked;
    final zeigtMenge = goal != null && !isChecked && !hatZeitziel;

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
            onLongPress: onEditCue,
            child: GebietStreifen(
              area: habit.area,
              blass: isChecked,
              child: MitEntfernenKreuz(
                onStop: onStop,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    14 - GebietStreifen.breite,
                    12,
                    MitEntfernenKreuz.randRechts,
                    12,
                  ),
                  child: Row(
                    children: <Widget>[
                      _CheckMark(
                        isChecked: isChecked,
                        cued: cued,
                        label: habit.name,
                        anker: anker,
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
                                color: isChecked
                                    ? Palette.textDim
                                    : Palette.text,
                                decoration: isChecked
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: Palette.muted,
                              ),
                            ),
                            if (timer) ...<Widget>[
                              const SizedBox(height: 4),
                              HabitCountdown(
                                key: timerKey(habit.id),
                                habit: habit,
                                onDone: onTimerDone,
                                builder: (context, uhr) => _ZielStand(
                                  text: uhr.isRunning ? uhr.label : uhr.stand,
                                  semanticLabel: uhr.isRunning
                                      ? uhr.semanticLabel
                                      : uhr.stand,
                                  laeuft: uhr.isRunning,
                                ),
                              ),
                            ],
                            if (zeigtMenge) ...<Widget>[
                              const SizedBox(height: 4),
                              _ZielStand(
                                text: goal.label,
                                semanticLabel: goal.label,
                              ),
                            ],
                            if (!isChecked &&
                                onEditCue != null &&
                                _hatZeile) ...<Widget>[
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
                      const SizedBox(width: 12),
                      RewardLine(
                        xp: xpGain,
                        gold: goldGain,
                        alreadyEarned: isChecked,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Der Stand des Timers von [habitId] auf der Kachel.
  static Key timerKey(String habitId) {
    return ValueKey<String>('timer-oeffnen-$habitId');
  }
}

/// **Das rote Kreuz oben rechts** über [child]: stoppt eine Gewohnheit —
/// eine Stelle für alle Kacheln dieses Bildschirms.
///
/// Kein Knopf aus dem Theme, der trüge die Holzfläche. Das [child] hält mit
/// [randRechts] rechts einen Streifen frei, damit weder ein Name noch der
/// Ertrag unter dem Kreuz liegt.
class MitEntfernenKreuz extends StatelessWidget {
  const MitEntfernenKreuz({
    required this.onStop,
    required this.child,
    super.key,
  });

  /// Wie viel Platz das [child] rechts freilässt.
  static const double randRechts = 26;

  static const double _flaeche = 32;

  final VoidCallback onStop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      // Sonst schrumpfte die Kachel auf ihren Inhalt (`gotchas.md`).
      fit: StackFit.passthrough,
      children: <Widget>[
        child,
        Positioned(
          top: 0,
          right: 0,
          child: Semantics(
            button: true,
            child: Tooltip(
              message: 'Nicht mehr verfolgen',
              child: Druck(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onStop,
                  child: const SizedBox.square(
                    dimension: _flaeche,
                    child: Icon(Icons.close, size: 20, color: Palette.enemy),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Die Zeile mit Tagen, Auslöser und Belohnung — nur, wenn es davon etwas
/// gibt.
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
    final danach = treat;

    return Druck(
      child: InkWell(
        onTap: onTap,
        onLongPress: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (tage != null || text != null) _wann(text, tage),
              if (danach != null) ...<Widget>[
                if (tage != null || text != null) const SizedBox(height: 2),
                TreatLine(text: danach),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Tage und Auslöser als **ein** Text über zwei Zeilen: Neben Kette und
  /// Knöpfen bleiben der Spalte rund 130 Punkte, und zwei Texte
  /// nebeneinander kürzten den Auslöser auf drei Wörter.
  Widget _wann(String? text, String? tage) {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          if (tage != null)
            TextSpan(
              text: text == null ? tage : '$tage  ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          if (text != null) TextSpan(text: text),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, color: Palette.textDim),
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
    required this.anker,
  });

  final bool isChecked;
  final bool cued;
  final String label;
  final String? anker;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: isChecked,
      label: <String>[
        label,
        if (cued) 'jetzt dran',
        if (anker case final name?) 'nach $name',
      ].join(', '),
      child: HaekchenKreis(
        isChecked: isChecked,
        size: 26,
        offenFarbe: cued ? Palette.accent : Palette.muted,
      ),
    );
  }
}

/// Was ein Häkchen einbringt — oder eingebracht hat: **groß, rechts auf der
/// Kachel, Erfahrung grün über Gold gelb**.
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

  /// So groß, dass die helleren Farben aus [Palette] lesbar bleiben.
  static const double schrift = 17;

  final int xp;
  final int gold;

  /// Ob es schon geholt ist. Dann stehen die Zahlen gedämpft da: Das
  /// Angebot ist eingelöst.
  final bool alreadyEarned;

  @override
  Widget build(BuildContext context) {
    final xpFarbe = alreadyEarned ? Palette.success : Palette.ertragXp;
    final goldFarbe = alreadyEarned ? Palette.gold : Palette.ertragGold;

    return Semantics(
      label: alreadyEarned
          ? 'Heute geholt: $xp Erfahrung und $gold Gold'
          : 'Bringt $xp Erfahrung und $gold Gold',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.auto_awesome, size: schrift, color: xpFarbe),
              const SizedBox(width: 4),
              Text('+$xp', style: _stil(xpFarbe)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const GoldIcon(size: schrift),
              const SizedBox(width: 4),
              Text('+$gold', style: _stil(goldFarbe)),
            ],
          ),
        ],
      ),
    );
  }

  static TextStyle _stil(Color farbe) {
    return TextStyle(
      fontSize: schrift,
      fontWeight: FontWeight.w800,
      color: farbe,
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

/// Das Tagesziel unter dem Namen: „5 Gläser“, „0 von 2 Minuten“ oder die
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
      overflow: TextOverflow.ellipsis,
      semanticsLabel: semanticLabel,
      style: TextStyle(
        fontSize: 13,
        fontWeight: laeuft ? FontWeight.bold : FontWeight.w600,
        color: laeuft ? Palette.accent : Palette.textDim,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }
}
