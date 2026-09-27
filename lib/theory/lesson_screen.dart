import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../progression/show_level_up.dart';
import 'package:theory/theory.dart';

import '../audio/sound_effects.dart';
import '../character/abilities_controller.dart';
import '../achievements/show_achievement_unlock.dart';
import '../character/show_ability_unlock.dart';
import '../ui/palette.dart';
import 'theory_controller.dart';
import 'widgets/lesson_result_view.dart';
import 'widgets/question_card.dart';
import '../gear/gear_controller.dart';

/// Was der Bildschirm gerade zeigt.
///
/// [repeat] ist die zweite Runde (ADR-0055): Was im ersten Durchgang
/// falsch war, kommt am Ende noch einmal — bis es sitzt.
enum _Stage { reading, quiz, repeat, result }

/// Eine Lektion: erst lesen, dann Fragen, dann Ergebnis.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({required this.lesson, super.key});

  final Lesson lesson;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  static const double _maxWidth = 560;

  _Stage _stage = _Stage.reading;
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

  Lesson get _lesson => widget.lesson;

  Question get _question => _questionAt(_index);

  bool get _isAnswered => _answers[_index] != null;

  bool get _isLastQuestion => _index == _lesson.questionCount - 1;

  void _startQuiz() {
    setState(() {
      _stage = _Stage.quiz;
      _index = 0;
      _answers = List<int?>.filled(_lesson.questionCount, null);
      _result = null;
      _shuffled = ShuffledLesson.of(_lesson, Random());
    });
  }

  void _answer(int option) {
    setState(() {
      final updated = List<int?>.of(_answers);
      updated[_index] = option;
      _answers = updated;
    });
  }

  void _next() {
    if (!_isLastQuestion) {
      setState(() => _index++);
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
  }

  void _answerRepeat(int option) {
    setState(() => _nachholAntwort = option);
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
    setState(() {
      _result = result;
      _stage = _Stage.result;
      // Eine erstmals bestandene Seite ist ein Schlüssel (ADR-0048) —
      // gezeigt nur, wenn er nicht am Vorrat von zehn verfiel.
      _schluessel = ref.read(availableKeysProvider) > schluesselVorher;
    });
    if (result.isPassed) {
      ref.read(soundPlayerProvider).play(SoundEffect.lektion);
    }

    // Einen Bildaufbau spaeter: Erst steht das Ergebnis da, dann kommt
    // die Feier darueber. Andersherum verdeckte sie, wofuer sie kommt.
    // **Errungenschaften zuerst, Faehigkeiten danach.** Eine
    // Errungenschaft kann eine Faehigkeit mitbringen (ADR-0033, Punkt 7);
    // andersherum stuende die Faehigkeit da, bevor gesagt waere, woher
    // sie kommt.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(() async {
        await showAchievementUnlocks(context, ref, before: vorherErrungen);
        if (!mounted) return;
        await showLevelUp(context, ref, before: vorherLevel);
        if (!mounted) return;
        await showAbilityUnlocks(context, ref, before: vorher);
      }());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // **Die einzige Seite, die ganz Pergament ist.** Überall sonst
      // liegen Pergamentflächen auf Leder; hier ist der Bildschirm
      // selbst die Seite, die gelesen wird — ein Fließtext über die
      // volle Höhe braucht keinen Rahmen, der ihn zur Karte macht.
      backgroundColor: Palette.surface,
      appBar: AppBar(
        title: Text(_lesson.title),
        backgroundColor: Palette.surface,
        bottom: _stage == _Stage.quiz ? _quizProgress() : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: switch (_stage) {
            _Stage.reading => _ReadingView(
              lesson: _lesson,
              onStart: _startQuiz,
            ),
            _Stage.quiz => _buildQuiz(),
            _Stage.repeat => _buildRepeat(),
            _Stage.result => _buildResult(),
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _quizProgress() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(3),
      child: LinearProgressIndicator(
        value: (_index + 1) / _lesson.questionCount,
        minHeight: 3,
        backgroundColor: Palette.surface,
        valueColor: const AlwaysStoppedAnimation<Color>(Palette.accent),
      ),
    );
  }

  Widget _buildQuiz() {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            children: <Widget>[
              Text(
                'Frage ${_index + 1} von ${_lesson.questionCount}',
                style: const TextStyle(fontSize: 12, color: Palette.muted),
              ),
              const SizedBox(height: 12),
              QuestionCard(
                question: _question,
                selected: _answers[_index],
                onSelect: _answer,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isAnswered ? _next : null,
              child: Text(_isLastQuestion ? 'Auswerten' : 'Weiter'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepeat() {
    final frage = _nachholFrage;
    if (frage == null) return const SizedBox.shrink();
    final offen = _nachholen.length;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.replay_rounded,
                    size: 16,
                    color: Palette.accent,
                  ),
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
              const SizedBox(height: 12),
              QuestionCard(
                // Ein neuer Schlüssel je Frage: Sonst behielte die Karte
                // die Auswahl der vorigen, wenn dieselbe Frage wiederkommt.
                key: ObjectKey(frage),
                question: frage,
                selected: _nachholAntwort,
                onSelect: _answerRepeat,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nachholAntwort != null ? _nextRepeat : null,
              child: const Text('Weiter'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final result = _result;
    if (result == null) return const SizedBox.shrink();

    return LessonResultView(
      lesson: _lesson,
      result: result,
      keyGained: _schluessel,
      onRetry: _startQuiz,
      onDone: () => Navigator.of(context).pop(),
    );
  }
}

class _ReadingView extends StatelessWidget {
  const _ReadingView({required this.lesson, required this.onStart});

  final Lesson lesson;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: <Widget>[
        Text(
          lesson.summary,
          style: const TextStyle(
            fontSize: 15,
            height: 1.4,
            color: Palette.textDim,
          ),
        ),
        const SizedBox(height: 8),
        for (final section in lesson.sections) ...<Widget>[
          const SizedBox(height: 20),
          Text(
            section.heading,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: const TextStyle(fontSize: 15, height: 1.55),
          ),
        ],
        const SizedBox(height: 32),
        FilledButton(
          onPressed: onStart,
          child: Text('${lesson.questionCount} Fragen beantworten'),
        ),
      ],
    );
  }
}
