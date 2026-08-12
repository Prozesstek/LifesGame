import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/palette.dart';

/// Ein Zweig im Skillbaum.
///
/// Gesperrte Zweige bleiben sichtbar und nennen ihre Stufe — die Sperre soll
/// ein Ziel sein, kein blinder Fleck.
class BranchCard extends StatelessWidget {
  const BranchCard({
    required this.branch,
    required this.passedLessons,
    required this.isUnlocked,
    required this.onTap,
    super.key,
  });

  final TheoryBranch branch;
  final int passedLessons;
  final bool isUnlocked;
  final VoidCallback onTap;

  bool get _isComplete => passedLessons >= branch.lessonCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isUnlocked ? Palette.surfaceRaised : Palette.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isUnlocked ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(_leadingIcon, size: 20, color: _accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      branch.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.white : Palette.muted,
                      ),
                    ),
                  ),
                  Text(
                    isUnlocked
                        ? '$passedLessons / ${branch.lessonCount}'
                        : 'ab Level ${branch.unlockLevel}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Palette.textDim : Palette.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                branch.description,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Palette.textDim,
                ),
              ),
              if (isUnlocked) ...<Widget>[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: branch.lessonCount == 0
                        ? 0
                        : passedLessons / branch.lessonCount,
                    minHeight: 5,
                    backgroundColor: Palette.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(_accent),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData get _leadingIcon {
    if (!isUnlocked) return Icons.lock_outline;
    return _isComplete ? Icons.verified_outlined : Icons.menu_book_outlined;
  }

  Color get _accent {
    if (!isUnlocked) return Palette.muted;
    return _isComplete ? Palette.success : Palette.accent;
  }
}
