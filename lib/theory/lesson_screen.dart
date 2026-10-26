import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';
import '../progression/show_level_up.dart';
import 'package:theory/theory.dart';

import '../audio/sound_effects.dart';
import '../character/abilities_controller.dart';
import '../achievements/show_achievement_unlock.dart';
import '../character/show_ability_unlock.dart';
import '../skills/gebiet_farbe.dart';
import '../ui/aufstieg.dart';
import '../ui/palette.dart';
import 'antwort_klang.dart';
import 'theory_controller.dart';
import 'widgets/antwort_leiste.dart';
import 'widgets/lese_haeppchen.dart';
import 'widgets/lesson_result_view.dart';
import 'widgets/question_card.dart';
import 'widgets/runden_balken.dart';
import 'widgets/seiten_farbe.dart';
import '../gear/gear_controller.dart';

/// Was der Bildschirm gerade zeigt.
///
/// [raten] ist das Rätsel vor dem Lesen (`Lesson.teaser`), nur wenn die
/// Seite eins hat. [repeat] ist die zweite Runde (ADR-0055): Was im
/// ersten Durchgang falsch war, kommt am Ende noch einmal — bis es sitzt.
enum _Stage { raten, reading, quiz, repeat, result }

/// Eine Lektion: erst lesen, dann Fragen, dann Ergebnis.
///
/// **Hat die Seite ein Rätsel**, kommt es zuerst: geschätzt, nicht
/// gewertet (`Lesson.teaser`).
///
/// **Seit dem 18.10. eine Spielrunde wie bei Duolingo**: Der Text kommt
/// in Häppchen (`LeseHaeppchen`), jede Antwort klingt — richtig eine
/// Stufe höher als die davor (`AntwortKlang`) —, springt oder wackelt,
/// und von unten kommt das Urteil (`AntwortLeiste`). Oben springt ein
/// Balken mit jeder, die sitzt. Am Ende zählen Erfahrung und Gold hoch,
/// drei von drei werfen Konfetti. **Keine Zahl ändert sich.**
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({required this.lesson, this.gebiet, super.key});

  final Lesson lesson;

  /// In welchem Gebiet die Seite gelesen wird — ihre Farbe (26.10.2026).
  ///
  /// Der Baum reicht das Gebiet, aus dem man kommt: *Stress* unter Geist
  /// ist blau. **Ohne Angabe das Zuhause der Seite**, die Wurzel ihres
  /// ersten Elternteils (`gebietDerSeite`) — das unterscheidet sich nur
  /// bei einer Seite mit zwei Eltern.
  final SkillArea? gebiet;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  static const double _maxWidth = 560;

  late _Stage _stage;
  int _index = 0;
  List<int?> _answers = const <int?>[];
  LessonResult? _result;

  /// Ob die letzte Abgabe einen Schlüssel gebracht hat (ADR-0048).
  bool _schluessel = false;

  /// Die Lektion in der Reihenfolge, in der sie **angezeigt** wird
  /// (ADR-0027). Null, solange noch gelesen wird.
  ///
  /// Neu gemischt bei jedem Anlauf: Wer eine Seite wiederholt, soll sich
  /// nicht an Stellen erinnern statt an Inhalte.
  ShuffledLesson? _shuffled;

  /// Die zweite Runde: Fragen, die noch einmal kommen, als Platz in der
  /// Lektion. Wer eine davon wieder falsch beantwortet, bekommt sie ans
  /// Ende gehängt.
  ///
  /// **Gewertet wird der erste Durchgang.** Die zweite Runde ist zum
  /// Lernen da, nicht zum Bestehen — sonst bestünde jede Seite, und die
  /// 60 % aus `TheoryRewards` wären keine Grenze mehr.
  List<int> _nachholen = const <int>[];

  /// Die Frage, die in der zweiten Runde gerade steht — frisch gemischt,
  /// damit sich niemand die Stelle der richtigen Antwort merkt.
  Question? _nachholFrage;
  int? _nachholAntwort;

  /// Wie viele Antworten in Folge richtig waren — die Stufe der
  /// Tonleiter. Eine falsche setzt sie zurück.
  int _inFolge = 0;

  /// Welche Fragen (als Platz in der Lektion) schon einmal richtig
  /// beantwortet sind. So weit steht der Balken oben.
  Set<int> _geloest = const <int>{};

  /// Zählt jede neu gestellte Frage. Daran erkennt der Wechsel, dass er
  /// schieben muss — auch wenn in der zweiten Runde dieselbe wiederkommt.
  int _gestellt = 0;

  /// Was nach dem Ergebnis gefeiert wird, solange es noch aussteht.
  Future<void> Function()? _feier;

  /// Der Host über dem Bildschirm, für das Konfetti. Er liegt **im**
  /// Bildschirm: Die Seite ist eine eigene Route über dem Baum.
  final GlobalKey<AufstiegHostState> _host = GlobalKey<AufstiegHostState>();

  /// Das Rätsel vor dem Lesen, Antworten gemischt — oder null.
  Question? _raetsel;

  /// Was geschätzt wurde. Wird nirgends gespeichert und zählt nicht.
  int? _geschaetzt;

  Lesson get _lesson => widget.lesson;

  SkillArea? get _gebiet =>
      widget.gebiet ??
      gebietDerSeite(ref.read(theoryGraphProvider), _lesson.id);

  Question get _question => _questionAt(_index);

  @override
  void initState() {
    super.initState();
    final teaser = _lesson.teaser;
    _raetsel = teaser == null ? null : shuffleOptions(teaser, Random());
    _stage = teaser == null ? _Stage.reading : _Stage.raten;
  }

  /// Eine Schätzung. Gut geschätzt klingt der erste Ton der Leiter; daneben
  /// klingt nichts — es war kein Fehler, nur eine Vermutung.
  void _schaetze(int option) {
    final raetsel = _raetsel;
    if (raetsel == null) return;
    setState(() => _geschaetzt = option);
    if (raetsel.isCorrect(option)) {
      ref.read(soundPlayerProvider).play(SoundEffect.ton1);
      unawaited(HapticFeedback.mediumImpact());
    } else {
      unawaited(HapticFeedback.selectionClick());
    }
  }

  void _zumText() => setState(() => _stage = _Stage.reading);

  bool get _isAnswered => _answers[_index] != null;

  bool get _isLastQuestion => _index == _lesson.questionCount - 1;

  void _startQuiz() {
    setState(() {
      _stage = _Stage.quiz;
      _index = 0;
      _answers = List<int?>.filled(_lesson.questionCount, null);
      _result = null;
      _shuffled = ShuffledLesson.of(_lesson, Random());
      _inFolge = 0;
      _geloest = const <int>{};
      _gestellt++;
    });
  }

  void _answer(int option) {
    final richtig = _question.isCorrect(option);
    final platz = _lessonIndexAt(_index);
    setState(() {
      final updated = List<int?>.of(_answers);
      updated[_index] = option;
      _answers = updated;
      _antwortZaehlt(richtig, platz);
    });
    _antwortKlingt(richtig);
  }

  /// Nur innerhalb von `setState` aufrufen.
  void _antwortZaehlt(bool richtig, int platz) {
    _inFolge = richtig ? _inFolge + 1 : 0;
    if (richtig) _geloest = <int>{..._geloest, platz};
  }

  /// Klang und Vibration einer Antwort. Im Browser wird aus der
  /// Vibration ein `navigator.vibrate` — am Android-Handy spürbar, am
  /// iPhone nicht (`state.md`, 18.10.).
  void _antwortKlingt(bool richtig) {
    ref
        .read(soundPlayerProvider)
        .play(AntwortKlang.fuer(richtig: richtig, inFolge: _inFolge));
    unawaited(
      richtig ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact(),
    );
  }

  void _next() {
    if (!_isLastQuestion) {
      setState(() {
        _index++;
        _gestellt++;
      });
      return;
    }

    final falsch = <int>[
      for (var i = 0; i < _lesson.questionCount; i++)
        if (!_questionAt(i).isCorrect(_answers[i])) _lessonIndexAt(i),
    ];
    if (falsch.isEmpty) {
      _finish();
      return;
    }
    setState(() {
      _stage = _Stage.repeat;
      _nachholen = falsch;
      _ladeNachholFrage();
    });
  }

  Question _questionAt(int shownIndex) {
    final gemischt = _shuffled;
    if (gemischt == null) return _lesson.questions[shownIndex];
    return gemischt.questions[shownIndex].question;
  }

  int _lessonIndexAt(int shownIndex) {
    return _shuffled?.questions[shownIndex].lessonIndex ?? shownIndex;
  }

  /// Holt die vorderste Frage der zweiten Runde, mit neu gemischten
  /// Antworten. Nur innerhalb von `setState` aufrufen.
  void _ladeNachholFrage() {
    final platz = _nachholen.first;
    _nachholFrage = ShuffledLesson.of(
      _lesson,
      Random(),
    ).questions.firstWhere((q) => q.lessonIndex == platz).question;
    _nachholAntwort = null;
    _gestellt++;
  }

  void _answerRepeat(int option) {
    final frage = _nachholFrage;
    if (frage == null) return;
    final richtig = frage.isCorrect(option);
    setState(() {
      _nachholAntwort = option;
      _antwortZaehlt(richtig, _nachholen.first);
    });
    _antwortKlingt(richtig);
  }

  void _nextRepeat() {
    final frage = _nachholFrage;
    if (frage == null) return;
    final richtig = frage.isCorrect(_nachholAntwort);
    final rest = <int>[..._nachholen.skip(1), if (!richtig) _nachholen.first];
    if (rest.isEmpty) {
      _finish();
      return;
    }
    setState(() {
      _nachholen = rest;
      _ladeNachholFrage();
    });
  }

  void _finish() {
    // Zurueckuebersetzen, bevor ausgewertet wird — die Stellen auf dem
    // Bildschirm sind nicht die Stellen im Katalog.
    final gemischt = _shuffled;
    final inLektion = gemischt == null
        ? _answers
        : gemischt.toLessonAnswers(_answers);

    // **Vor dem Abgeben lesen.** Danach ist der Fortschritt drin und der
    // Unterschied verschwunden — es gaebe nichts mehr zu feiern.
    final vorher = ref.read(unlockedAbilitiesProvider);
    final vorherErrungen = achievementsBefore(ref);
    final vorherLevel = levelBefore(ref);
    final schluesselVorher = ref.read(availableKeysProvider);

    final result = ref
        .read(theoryProgressProvider.notifier)
        .submit(_lesson, inLektion);

    // **Drei von drei lösen den Akkord auf**, in dem die Leiter der
    // Antworten stand — und werfen Konfetti aus der Mitte. Vom Knopf
    // ganz unten käme es kaum über die untere Hälfte.
    if (result.isPerfect) {
      ref.read(soundPlayerProvider).play(SoundEffect.tagGeschafft);
      final flaeche = _host.currentContext?.size;
      if (flaeche != null) {
        _host.currentState?.konfetti(
          von: Offset(flaeche.width / 2, flaeche.height * 0.55),
        );
      }
    } else if (result.isPassed) {
      ref.read(soundPlayerProvider).play(SoundEffect.lektion);
    }

    // **Errungenschaften zuerst, Faehigkeiten danach.** Eine
    // Errungenschaft kann eine Faehigkeit mitbringen (ADR-0033, Punkt 7);
    // andersherum stuende die Faehigkeit da, bevor gesagt waere, woher
    // sie kommt.
    Future<void> feier() async {
      await showAchievementUnlocks(context, ref, before: vorherErrungen);
      if (!mounted) return;
      await showLevelUp(context, ref, before: vorherLevel);
      if (!mounted) return;
      await showAbilityUnlocks(context, ref, before: vorher);
    }

    setState(() {
      _result = result;
      _stage = _Stage.result;
      // Eine erstmals bestandene Seite ist ein Schlüssel (ADR-0048) —
      // gezeigt nur, wenn er nicht am Vorrat von zehn verfiel.
      _schluessel = ref.read(availableKeysProvider) > schluesselVorher;
      _feier = feier;
    });
    // **Erst gezählt, dann gefeiert.** Zählen Erfahrung und Gold hoch,
    // meldet das Ergebnis das Ende (`onGezaehlt`); sonst einen Bildaufbau
    // später — erst steht das Ergebnis da, dann kommt die Feier darüber.
    final zaehlt = result.xpGained > 0 || result.goldGained > 0;
    if (!zaehlt) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _feiern());
    }
  }

  /// Zeigt, was noch zu feiern ist — genau einmal.
  ///
  /// Solange es aussteht, geht es nicht zurück (`PopScope`): Ein
  /// Aufstieg, der nicht gezeigt wurde, käme nie wieder, weil sein
  /// „vorher“ nur hier steht. Wer es trotzdem versucht, bekommt die Feier
  /// sofort.
  void _feiern() {
    final feier = _feier;
    if (feier == null || !mounted) return;
    setState(() => _feier = null);
    unawaited(feier());
  }

  @override
  Widget build(BuildContext context) {
    final fragt = _stage == _Stage.quiz || _stage == _Stage.repeat;
    return PopScope(
      canPop: _feier == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _feiern();
      },
      child: SeitenFarbe(
        gebiet: _gebiet,
        child: Scaffold(
          // **Die einzige Seite, die ganz Pergament ist.** Überall sonst
          // liegen Pergamentflächen auf Leder; hier ist der Bildschirm
          // selbst die Seite, die gelesen wird — ein Fließtext über die
          // volle Höhe braucht keinen Rahmen, der ihn zur Karte macht.
          backgroundColor: Palette.surface,
          appBar: AppBar(
            title: Text(_lesson.title),
            backgroundColor: Palette.surface,
            bottom: fragt ? _balken() : null,
          ),
          body: AufstiegHost(
            key: _host,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: switch (_stage) {
                  _Stage.raten => _buildRaetsel(),
                  _Stage.reading => LeseHaeppchen(
                    lesson: _lesson,
                    onStart: _startQuiz,
                  ),
                  _Stage.quiz => _buildQuiz(),
                  _Stage.repeat => _buildRepeat(),
                  _Stage.result => _buildResult(),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _balken() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(RundenBalken.hoehe + 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: RundenBalken(
          geloest: _geloest.length,
          gesamt: _lesson.questionCount,
        ),
      ),
    );
  }

  Widget _buildRaetsel() {
    final raetsel = _raetsel;
    if (raetsel == null) return const SizedBox.shrink();
    return _Frage(
      gestellt: _gestellt,
      kopf: const Row(
        children: <Widget>[
          Icon(Icons.lightbulb_outline, size: 16, color: Palette.accent),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Was schätzt du?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Palette.accent,
              ),
            ),
          ),
        ],
      ),
      frage: raetsel,
      gewaehlt: _geschaetzt,
      onSelect: _schaetze,
      knopf: 'Weiter',
      onWeiter: _geschaetzt != null ? _zumText : null,
      geraten: true,
    );
  }

  Widget _buildQuiz() {
    final gewaehlt = _answers[_index];
    return _Frage(
      gestellt: _gestellt,
      kopf: Text(
        'Frage ${_index + 1} von ${_lesson.questionCount}',
        style: const TextStyle(fontSize: 12, color: Palette.muted),
      ),
      frage: _question,
      gewaehlt: gewaehlt,
      onSelect: _answer,
      knopf: _isLastQuestion ? 'Auswerten' : 'Weiter',
      onWeiter: _isAnswered ? _next : null,
    );
  }

  Widget _buildRepeat() {
    final frage = _nachholFrage;
    if (frage == null) return const SizedBox.shrink();
    final offen = _nachholen.length;

    return _Frage(
      gestellt: _gestellt,
      kopf: Row(
        children: <Widget>[
          const Icon(Icons.replay_rounded, size: 16, color: Palette.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              offen == 1
                  ? 'Noch einmal — die letzte'
                  : 'Noch einmal — $offen offen',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Palette.accent,
              ),
            ),
          ),
        ],
      ),
      frage: frage,
      gewaehlt: _nachholAntwort,
      onSelect: _answerRepeat,
      knopf: 'Weiter',
      onWeiter: _nachholAntwort != null ? _nextRepeat : null,
    );
  }

  Widget _buildResult() {
    final result = _result;
    if (result == null) return const SizedBox.shrink();

    // **Direkt zur nächsten** (ADR-0070): Wer im Fluss ist, liest weiter,
    // ohne über den Baum zu gehen. Nur nach bestandener Seite — sonst ist
    // „Nochmal“ der nächste Schritt.
    final weiter = result.isPassed
        ? ref.watch(stepAfterLessonProvider(_lesson.id))
        : null;

    return LessonResultView(
      lesson: _lesson,
      result: result,
      keyGained: _schluessel,
      next: weiter,
      onNext: weiter == null ? null : () => _zurNaechsten(weiter),
      onRetry: _startQuiz,
      onDone: () => Navigator.of(context).pop(),
      onGezaehlt: _feiern,
    );
  }

  /// Öffnet die nächste Seite, falls sie noch zu ist, und liest sie an
  /// der Stelle dieser — „Zurück“ führt von dort in den Baum, nicht durch
  /// alle gelesenen Seiten.
  void _zurNaechsten(TheoryStep schritt) {
    if (schritt.needsOpening) {
      final offen = ref
          .read(theoryProgressProvider.notifier)
          .openNode(
            schritt.node.id,
            availablePoints: ref.read(availableTheoryPointsProvider),
          );
      if (!offen) return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LessonScreen(
          lesson: schritt.node.lesson,
          // Im selben Gebiet weiter, wenn die nächste Seite dort steht.
          gebiet: gebietVon(
            ref.read(theoryGraphProvider),
            schritt.node.id,
            bevorzugt: _gebiet,
          ),
        ),
      ),
    );
  }
}

/// Eine Frage samt Urteil von unten. Die Frage schiebt sich herein, die
/// vorige hinaus nach links; die Leiste bleibt stehen und klappt zu.
class _Frage extends StatelessWidget {
  const _Frage({
    required this.gestellt,
    required this.kopf,
    required this.frage,
    required this.gewaehlt,
    required this.onSelect,
    required this.knopf,
    required this.onWeiter,
    this.geraten = false,
  });

  /// Ob es das Rätsel ist — dann zählt nichts, und daneben ist nicht rot.
  final bool geraten;

  /// Die wievielte gestellte Frage — wechselt sie, wird geschoben.
  final int gestellt;
  final Widget kopf;
  final Question frage;
  final int? gewaehlt;
  final ValueChanged<int> onSelect;
  final String knopf;

  /// Null, solange nicht geantwortet ist.
  final VoidCallback? onWeiter;

  static const Duration schieben = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    final schluessel = ValueKey<int>(gestellt);
    final weiter = onWeiter;
    return Column(
      children: <Widget>[
        Expanded(
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: schieben,
              // Die neue bremst ins Ziel, die alte ist schnell weg — sonst
              // stünden beide in der Mitte halb übereinander.
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (jetzt, vorige) => Stack(
                fit: StackFit.expand,
                children: <Widget>[...vorige, ?jetzt],
              ),
              transitionBuilder: (kind, animation) {
                // Dieselbe Animation läuft für die gehende rückwärts: Sie
                // schiebt sich nach links hinaus, die neue von rechts herein.
                final kommt = kind.key == schluessel;
                final weg = Tween<Offset>(
                  begin: Offset(kommt ? 1 : -1, 0),
                  end: Offset.zero,
                ).animate(animation);
                // Immer dieselbe Form des Baums, nur die Deckkraft wechselt —
                // sonst würde die gehende Frage beim Wechsel neu gebaut.
                return SlideTransition(
                  position: weg,
                  child: FadeTransition(
                    opacity: kommt ? kAlwaysCompleteAnimation : animation,
                    child: kind,
                  ),
                );
              },
              child: ListView(
                key: schluessel,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                children: <Widget>[
                  kopf,
                  const SizedBox(height: 12),
                  QuestionCard(
                    question: frage,
                    selected: gewaehlt,
                    onSelect: onSelect,
                    geraten: geraten,
                  ),
                ],
              ),
            ),
          ),
        ),
        AntwortLeiste(
          richtig: gewaehlt == null ? null : frage.isCorrect(gewaehlt),
          erklaerung: frage.explanation,
          knopf: knopf,
          onWeiter: weiter ?? () {},
          richtigWort: geraten ? 'Gut geschätzt' : 'Richtig',
          falschWort: geraten ? 'Überraschend, oder?' : 'Nicht ganz',
          falschFarbe: geraten ? Palette.accent : Palette.enemy,
          falschZeichen: geraten
              ? Icons.lightbulb_rounded
              : Icons.close_rounded,
        ),
      ],
    );
  }
}
