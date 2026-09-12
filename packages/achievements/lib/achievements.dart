/// Errungenschaften für Lifes Game.
///
/// Reines Dart: kein Flutter, keine Dependencies. Der Katalog lässt sich
/// gegen jeden Fortschritt durchrechnen, ohne die App zu starten
/// (ADR-0033).
///
/// Dieses Package kennt keines der anderen sieben. Es bekommt Zahlen als
/// `AchievementStats`; die App setzt sie zusammen — gleiche Bauform wie
/// `TitleStats` (ADR-0014) und `AbilityProgress` (ADR-0017).
///
/// **Was verdient ist, steht in keinem Spielstand.** Es wird aus der
/// Historie gerechnet, wie Gold, Erfahrung und Titel. Das hat drei Folgen:
/// Es wirkt rückwirkend, der Entwicklermodus kann nichts erschleichen
/// (er schenkt Summanden, keine Historie), und der Spielstand wächst nicht.
library;

export 'src/achievement.dart';
export 'src/catalog.dart';
export 'src/rewards.dart';
export 'src/stats.dart';
