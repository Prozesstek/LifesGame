import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/palette.dart';
import '../../ui/druck.dart';
import '../../ui/sprung.dart';

/// Eine Frage mit ihren Antwortmöglichkeiten.
///
/// Ein Tipp ist die Antwort, es gibt kein „Prüfen“ dazwischen. Die
/// gewählte **springt** auf, wenn sie stimmt, und **wackelt**, wenn
/// nicht; die richtige steht dann grün daneben. Die Erklärung kommt von
/// unten (`AntwortLeiste`), seit dem 18.10. nicht mehr hier.
///
/// **Ein Rätsel** ([geraten]) wird nicht gewertet: Eine falsche Schätzung
/// steht braun statt rot da und schüttelt nicht den Kopf.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    required this.question,
    required this.selected,
    required this.onSelect,
    this.geraten = false,
    super.key,
  });

  /// Ob nur geschätzt wird — das Rätsel vor einer Seite.
  final bool geraten;

  final Question question;

  /// Gewählter Antwortindex, oder null solange nicht geantwortet wurde.
  final int? selected;

  final ValueChanged<int> onSelect;

  /// Wie lange eine Antwort springt oder wackelt.
  static const Duration antwortDauer = Duration(milliseconds: 480);

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
              gewaehlt: selected == i,
              geraten: geraten,
              onTap: _isAnswered ? null : () => onSelect(i),
            ),
          ),
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

class _Option extends StatefulWidget {
  const _Option({
    required this.label,
    required this.state,
    required this.gewaehlt,
    required this.geraten,
    this.onTap,
  });

  final String label;
  final _OptionState state;

  /// Beim Rätsel ist eine falsche Wahl keine Strafe: braun, ohne Kreuz.
  final bool geraten;

  /// Ob diese getippt wurde — nur sie springt oder wackelt. Die richtige
  /// neben einer falschen wird grün, bewegt sich aber nicht.
  final bool gewaehlt;

  final VoidCallback? onTap;

  @override
  State<_Option> createState() => _OptionWidgetState();
}

class _OptionWidgetState extends State<_Option>
    with SingleTickerProviderStateMixin {
  // In `initState`, nicht faul: Nur eine von vier Antworten bewegt sich je
  // in `build`, die anderen fassten ihn sonst erst im `dispose` an
  // (`gotchas.md`).
  late final AnimationController _antwort;

  @override
  void initState() {
    super.initState();
    _antwort = AnimationController(
      vsync: this,
      duration: QuestionCard.antwortDauer,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(_Option alt) {
    super.didUpdateWidget(alt);
    final beantwortet =
        alt.state == _OptionState.open && widget.state != _OptionState.open;
    if (beantwortet && widget.gewaehlt) _antwort.forward(from: 0);
  }

  @override
  void dispose() {
    _antwort.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final falsch = widget.geraten ? Palette.accent : Palette.enemy;
    final border = switch (state) {
      _OptionState.open => Palette.surfaceRaised,
      _OptionState.correct => Palette.success,
      _OptionState.wrong => falsch,
      _OptionState.dimmed => Palette.surface,
    };
    final grund = switch (state) {
      _OptionState.correct when widget.gewaehlt => Color.alphaBlend(
        Palette.success.withValues(alpha: 0.14),
        Palette.surface,
      ),
      _OptionState.wrong => Color.alphaBlend(
        falsch.withValues(alpha: 0.1),
        Palette.surface,
      ),
      _ => Palette.surface,
    };
    final textColor = switch (state) {
      _OptionState.dimmed => Palette.muted,
      _ => Palette.text,
    };

    final knopf = Druck(
      enabled: widget.onTap != null,
      child: Material(
        color: grund,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: widget.onTap,
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
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      color: textColor,
                    ),
                  ),
                ),
                if (state == _OptionState.correct)
                  const Icon(Icons.check, size: 18, color: Palette.success),
                if (state == _OptionState.wrong && !widget.geraten)
                  const Icon(Icons.close, size: 18, color: Palette.enemy),
              ],
            ),
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _antwort,
      child: knopf,
      builder: (context, child) {
        final t = _antwort.value;
        if (t >= 1) return child ?? const SizedBox.shrink();
        return switch (state) {
          _OptionState.correct => Transform.scale(
            scale: Sprung.stoss(t, hoehe: 0.09),
            child: child,
          ),
          // Dreimal hin und her, schnell leiser — ein Kopfschütteln. Nicht
          // beim Rätsel: Dort war es eine Schätzung, kein Fehler.
          _OptionState.wrong when widget.geraten =>
            child ?? const SizedBox.shrink(),
          _OptionState.wrong => Transform.translate(
            offset: Offset(7 * math.sin(t * math.pi * 6) * (1 - t), 0),
            child: child,
          ),
          _ => child ?? const SizedBox.shrink(),
        };
      },
    );
  }
}
