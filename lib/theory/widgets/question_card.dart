import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/palette.dart';

/// Eine Frage mit ihren Antwortmöglichkeiten.
///
/// Nach der Auswahl wird die Erklärung gezeigt — auch bei richtiger
/// Antwort. Die Erklärung ist Teil des Inhalts, nicht nur Fehlerkorrektur.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    required this.question,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final Question question;

  /// Gewählter Antwortindex, oder null solange nicht geantwortet wurde.
  final int? selected;

  final ValueChanged<int> onSelect;

  bool get _isAnswered => selected != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          question.prompt,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < question.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _Option(
              label: question.options[i],
              state: _stateOf(i),
              onTap: _isAnswered ? null : () => onSelect(i),
            ),
          ),
        if (_isAnswered) ...<Widget>[
          const SizedBox(height: 8),
          _Explanation(
            isCorrect: question.isCorrect(selected),
            text: question.explanation,
          ),
        ],
      ],
    );
  }

  _OptionState _stateOf(int index) {
    if (!_isAnswered) return _OptionState.open;
    if (index == question.correctIndex) return _OptionState.correct;
    if (index == selected) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

enum _OptionState { open, correct, wrong, dimmed }

class _Option extends StatelessWidget {
  const _Option({required this.label, required this.state, this.onTap});

  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = switch (state) {
      _OptionState.open => Palette.surfaceRaised,
      _OptionState.correct => Palette.success,
      _OptionState.wrong => Palette.enemy,
      _OptionState.dimmed => Palette.surface,
    };
    final textColor = switch (state) {
      _OptionState.dimmed => Palette.muted,
      _ => Colors.white,
    };

    return Material(
      color: Palette.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14, height: 1.3, color: textColor),
                ),
              ),
              if (state == _OptionState.correct)
                const Icon(Icons.check, size: 18, color: Palette.success),
              if (state == _OptionState.wrong)
                const Icon(Icons.close, size: 18, color: Palette.enemy),
            ],
          ),
        ),
      ),
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation({required this.isCorrect, required this.text});

  final bool isCorrect;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? Palette.success : Palette.enemy;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            isCorrect ? 'Richtig' : 'Nicht ganz',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: Palette.textDim,
            ),
          ),
        ],
      ),
    );
  }
}
