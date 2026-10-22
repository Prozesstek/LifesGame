import 'package:habits/habits.dart';

import '../combat/tagesgrube_text.dart';
import 'skills.dart';

/// Der Text, mit dem man seine Skills in eine Gruppe kopiert (ADR-0085)
/// — **reine Rechnung**, kein Widget.
///
/// ```
/// Lifes Game · Frederik, der Rüstige
/// Gesamtlevel 74
/// 🏃 Körper 34 · 🧠 Geist 21
/// 🔬 Wissenschaft 9 · 🤝 Gesellschaft 10
/// 🔥 Längste Kette 63 Tage
/// prozesstek.de/LifesGame
/// ```
///
/// Solange es keinen Server gibt, ist das der Vergleich: eine Zahl, die
/// man zeigen kann. Die längste Kette steht dabei, die laufende nicht —
/// was einmal stand, bleibt.
abstract final class SkillText {
  /// Das Zeichen zu einem Gebiet, im Text. Ein `switch` ohne Rückfall:
  /// Ein neues Gebiet ist ein Compilerfehler statt einer Lücke.
  static String zeichen(SkillArea area) {
    return switch (area) {
      SkillArea.koerper => '🏃',
      SkillArea.geist => '🧠',
      SkillArea.wissenschaft => '🔬',
      SkillArea.gesellschaft => '🤝',
    };
  }

  static String _gebiet(Skills skills, SkillArea area) {
    return '${zeichen(area)} ${area.label} ${skills.of(area).level}';
  }

  /// Der ganze Text. [name] und [titel] stehen nur da, wenn es sie gibt.
  static String teilen({
    required Skills skills,
    required int longestStreak,
    String name = '',
    String? titel,
  }) {
    final wer = <String>[
      if (name.trim().isNotEmpty) name.trim(),
      ?titel,
    ].join(', ');
    return <String>[
      wer.isEmpty ? 'Lifes Game' : 'Lifes Game · $wer',
      'Gesamtlevel ${skills.gesamt}',
      '${_gebiet(skills, SkillArea.koerper)} · '
          '${_gebiet(skills, SkillArea.geist)}',
      '${_gebiet(skills, SkillArea.wissenschaft)} · '
          '${_gebiet(skills, SkillArea.gesellschaft)}',
      if (longestStreak > 0)
        '🔥 Längste Kette $longestStreak '
            '${longestStreak == 1 ? 'Tag' : 'Tage'}',
      TagesgrubeText.adresse,
    ].join('\n');
  }
}
