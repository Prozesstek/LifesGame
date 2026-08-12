import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory/theory.dart';

import '../home/widgets/level_card.dart';
import '../progression/level_provider.dart';
import '../ui/palette.dart';
import 'branch_screen.dart';
import 'theory_controller.dart';
import 'widgets/branch_card.dart';

/// Der Skillbaum: alle Theoriezweige und ihre Levelsperren.
class SkillTreeScreen extends ConsumerWidget {
  const SkillTreeScreen({super.key, this.tree = theoryTree});

  final SkillTree tree;

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(theoryProgressProvider);
    final level = ref.watch(playerLevelProvider);
    final gold = ref.watch(goldProvider);
    final nextUnlock = tree.nextUnlock(level.level);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theorie'),
        backgroundColor: Palette.background,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: <Widget>[
              LevelCard(level: level, gold: gold),
              const SizedBox(height: 10),
              _Intro(
                passed: progress.passedCountIn(tree),
                total: tree.lessonCount,
                nextUnlock: nextUnlock,
              ),
              const SizedBox(height: 20),
              for (final branch in tree.branches) ...<Widget>[
                BranchCard(
                  branch: branch,
                  passedLessons: progress.passedCount(branch),
                  isUnlocked: branch.isUnlockedAt(level.level),
                  onTap: () => _openBranch(context, branch),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openBranch(BuildContext context, TheoryBranch branch) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BranchScreen(branch: branch)),
    );
  }
}

/// Ein Satz zum Stand und, falls etwas gesperrt ist, das nächste Ziel.
class _Intro extends StatelessWidget {
  const _Intro({
    required this.passed,
    required this.total,
    required this.nextUnlock,
  });

  final int passed;
  final int total;
  final TheoryBranch? nextUnlock;

  @override
  Widget build(BuildContext context) {
    final next = nextUnlock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$passed von $total Lektionen im ganzen Baum bestanden',
          style: const TextStyle(fontSize: 13, color: Palette.textDim),
        ),
        if (next != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            '„${next.name}" öffnet sich auf Level ${next.unlockLevel}.',
            style: const TextStyle(fontSize: 13, color: Palette.muted),
          ),
        ],
      ],
    );
  }
}
