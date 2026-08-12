import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory/theory.dart';

import '../ui/palette.dart';
import 'lesson_screen.dart';
import 'theory_controller.dart';
import 'widgets/lesson_tile.dart';

/// Übersicht eines Theoriezweigs: welche Lektionen es gibt, wo man steht.
///
/// Die Levelsperre des Zweigs wird eine Ebene höher geprüft
/// ([SkillTreeScreen]) — hier geht es nur um die Reihenfolge der Lektionen.
class BranchScreen extends ConsumerWidget {
  const BranchScreen({required this.branch, super.key});

  final TheoryBranch branch;

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(theoryProgressProvider);
    final passed = progress.passedCount(branch);
    final habits = progress.unlockedHabits(branch);

    return Scaffold(
      appBar: AppBar(
        title: Text(branch.name),
        backgroundColor: Palette.background,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: <Widget>[
              Text(
                branch.description,
                style: const TextStyle(fontSize: 14, color: Palette.textDim),
              ),
              const SizedBox(height: 16),
              _ProgressBar(passed: passed, total: branch.lessonCount),
              const SizedBox(height: 20),
              for (var i = 0; i < branch.lessons.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: 10),
                LessonTile(
                  number: i + 1,
                  lesson: branch.lessons[i],
                  record: progress.recordFor(branch.lessons[i].id),
                  isUnlocked: progress.isUnlocked(branch, branch.lessons[i].id),
                  onTap: () => _openLesson(context, branch.lessons[i]),
                ),
              ],
              if (habits.isNotEmpty) ...<Widget>[
                const SizedBox(height: 24),
                _UnlockedHabits(habits: habits),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openLesson(BuildContext context, Lesson lesson) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lesson)),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.passed, required this.total});

  final int passed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : passed / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$passed von $total Lektionen bestanden',
          style: const TextStyle(fontSize: 13, color: Palette.textDim),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: Palette.surface,
            valueColor: const AlwaysStoppedAnimation<Color>(Palette.success),
          ),
        ),
      ],
    );
  }
}

/// Die Habit-Vorlagen, die dieser Zweig bisher freigeschaltet hat.
///
/// Noch ohne Wirkung — der Habits-Teil fehlt. Die Verknüpfung sichtbar zu
/// machen ist trotzdem richtig: Sie ist der Grund, warum Theorie in dieser
/// App nicht danebensteht.
class _UnlockedHabits extends StatelessWidget {
  const _UnlockedHabits({required this.habits});

  final List<String> habits;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Freigeschaltete Habit-Vorlagen',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final habit in habits)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.add_task, size: 15, color: Palette.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      habit,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Palette.textDim,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          const Text(
            'Nutzbar, sobald der Habits-Bereich steht.',
            style: TextStyle(fontSize: 11, color: Palette.muted),
          ),
        ],
      ),
    );
  }
}
