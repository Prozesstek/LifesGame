import 'package:lifes_game/home/erster_start_provider.dart';

/// Die Hinweise des Mentors (`Hinweis`) sind schon weggetippt. Für
/// Tests, die nach einem Häkchen weitertippen und nicht den Mentor
/// prüfen — sonst fängt seine Tippfläche den Tipp ab.
final hinweisGesehen = hinweiseProvider.overrideWith(
  () => Hinweise(schon: Hinweis.values.toSet()),
);
