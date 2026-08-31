import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory/theory.dart';

import '../ui/palette.dart';
import 'theory_controller.dart';
import 'widgets/lesson_result_view.dart';
import 'widgets/question_card.dart';

/// Was der Bildschirm gerade zeigt.
enum _Stage { reading, quiz, result }

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

  /// Die Lektion in der Reihenfolge, in der sie **angezeigt** wird
  /// (ADR-0027). Null, solange noch gelesen wird.
  ///
  /// Neu gemischt bei jedem Anlauf: Wer eine Seite wiederholt, soll sich
  /// nicht an Stellen erinnern statt an Inhalte.
  ShuffledLesson? _shuffled;

  Lesson get _lesson => widget.lesson;

  Question get _question {
    final gemischt = _shuffled;
    if (gemischt == null) return _lesson.questions[_index];

    return gemischt.questions[_index].question;
  }

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
    if (_isLastQuestion) {
      _finish();
      return;
    }
    setState(() => _index++);
  }

  void _finish() {
    // Zurueckuebersetzen, bevor ausgewertet wird — die Stellen auf dem
    // Bildschirm sind nicht die Stellen im Katalog.
    final gemischt = _shuffled;
    final inLektion = gemischt == null
        ? _answers
        : gemischt.toLessonAnswers(_answers);

    final result = ref
        .read(theoryProgressProvider.notifier)
        .submit(_lesson, inLektion);
    setState(() {
      _result = result;
      _stage = _Stage.result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson.title),
        backgroundColor: Palette.background,
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

  Widget _buildResult() {
    final result = _result;
    if (result == null) return const SizedBox.shrink();

    return LessonResultView(
      lesson: _lesson,
      result: result,
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
