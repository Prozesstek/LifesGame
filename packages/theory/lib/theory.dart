/// Theorie-Inhalte und Lernfortschritt für Lifes Game.
///
/// Reines Dart: kein Flutter, keine Dependencies. Inhalte lassen sich
/// schreiben und prüfen, ohne die App zu starten (ADR-0004). Der Aufbau als
/// Skillbaum mit levelgebundenen Zweigen steht in ADR-0007.
library;

export 'src/branch.dart';
export 'src/content/geist_branch.dart';
export 'src/content/gesellschaft_branch.dart';
export 'src/content/habits_branch.dart';
export 'src/content/koerper_branch.dart';
export 'src/content/wissenschaft_branch.dart';
export 'src/lesson.dart';
export 'src/progress.dart';
export 'src/rewards.dart';
export 'src/skill_tree.dart';
