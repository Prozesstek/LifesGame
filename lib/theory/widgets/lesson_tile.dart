import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/palette.dart';

/// Eine Lektion in der Zweig-Übersicht.
class LessonTile extends StatelessWidget {
  const LessonTile({
    required this.number,
    required this.lesson,
    required this.record,
    required this.isUnlocked,
    required this.onTap,
    super.key,
  });

  final int number;
  final Lesson lesson;

  /// Ergebnis eines früheren Versuchs, oder null.
  final LessonRecord? record;

  final bool isUnlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPassed = record?.isPassed ?? false;

    return Material(
      color: isUnlocked ? Palette.surfaceRaised : Palette.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isUnlocked ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Badge(
                number: number,
                isPassed: isPassed,
                isUnlocked: isUnlocked,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      lesson.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.white : Palette.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isUnlocked
                          ? lesson.summary
                          : 'Erst nach der vorherigen Lektion',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Palette.textDim,
                      ),
                    ),
                    if (record != null) ...<Widget>[
                      const SizedBox(height: 6),
                      _ScoreLine(record: record, lesson: lesson),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.number,
    required this.isPassed,
    required this.isUnlocked,
  });

  final int number;
  final bool isPassed;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final color = isPassed
        ? Palette.success
        : isUnlocked
        ? Palette.accent
        : Palette.muted;

    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: isPassed
          ? Icon(Icons.check, size: 17, color: color)
          : isUnlocked
          ? Text(
              '$number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            )
          : Icon(Icons.lock_outline, size: 15, color: color),
    );
  }
}

class _ScoreLine extends StatelessWidget {
  const _ScoreLine({required this.record, required this.lesson});

  final LessonRecord? record;
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final current = record;
    if (current == null) return const SizedBox.shrink();

    final text = current.isPerfect
        ? 'Alle Fragen richtig'
        : 'Bestes Ergebnis: '
              '${current.bestCorrect} von ${current.questionCount}';

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: current.isPassed ? Palette.success : Palette.textDim,
      ),
    );
  }
}
