import 'vec2.dart';

/// Was ein gefallener Gegner manchmal hinterlässt.
///
/// **Sie ist der Grund, warum ein Lauf ein Lauf ist.** Ohne sie fällt die
/// Gesundheit über 27 Kämpfe nur — und wer einmal zu tief steht, hat
/// verloren, ohne es schon zu wissen. Mit ihr ist jede Traube auch eine
/// Frage: reingehen und heilen, oder ausweichen und dünn bleiben.
class HealthOrb {
  HealthOrb({
    required this.id,
    required this.position,
    required this.heal,
    required this.radius,
  });

  final int id;
  final int heal;
  final double radius;

  Vec2 position;
  double age = 0;
  bool taken = false;
}

/// Eine Kugel, wie der Renderer sie sieht.
class OrbView {
  const OrbView({
    required this.id,
    required this.position,
    required this.radius,
    required this.fading,
  });

  factory OrbView.of(HealthOrb orb, {required bool fading}) {
    return OrbView(
      id: orb.id,
      position: orb.position,
      radius: orb.radius,
      fading: fading,
    );
  }

  final int id;
  final Vec2 position;
  final double radius;

  /// Ob sie bald verschwindet. Der Renderer lässt sie dann blinken —
  /// eine Kugel, die ohne Vorwarnung weg ist, liest sich als Fehler.
  final bool fading;
}
