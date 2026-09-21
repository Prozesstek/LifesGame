/// Was der Held auf Knopfdruck kann.
///
/// **Zwei, nicht zehn.** Ein Prototyp beantwortet eine Frage; hier ist es
/// die, ob ein Kampf aus Laufen und Automatikschlag genug hergibt. Die
/// Antwort war beim Spielen offenbar „noch nicht" — also bekommt er
/// Knöpfe. Zwei reichen, um es zu beantworten: einer zum Ausweichen,
/// einer für die Traube.
///
/// Was eine Fähigkeit **tut**, steht in `world.dart`. Was sie **kostet**
/// und wie stark sie ist, steht in `balance.dart`. Hier steht nur, welche
/// es gibt und wie sie heissen.
enum ActionAbility {
  /// Ein Satz nach vorn, in Laufrichtung.
  ///
  /// Der Ausweg aus einer Traube — und der Grund, überhaupt auf die
  /// Bewegung zu achten. Ohne ihn ist Umzingeltwerden ein Urteil, kein
  /// Fehler.
  sturmschritt('Sturmschritt'),

  /// Ein Schlag, der **alle** in der Nähe trifft.
  ///
  /// Das eigentliche Hack'n'Slay-Gefühl: Der Moment, in dem sechs Gegner
  /// gleichzeitig Zahlen über dem Kopf haben. Mit Einzelschlägen gibt es
  /// diesen Moment nicht, egal wie stark man ist.
  rundumschlag('Rundumschlag');

  const ActionAbility(this.label);

  final String label;
}

/// Die Zahlen hinter einer Fähigkeit.
class AbilitySpec {
  const AbilitySpec({
    required this.cooldown,
    required this.radius,
    required this.power,
    required this.duration,
    required this.speedFactor,
  });

  /// Sekunden bis zum nächsten Einsatz.
  final double cooldown;

  /// Wirkradius in Weltpunkten. 0, wenn die Fähigkeit nicht trifft.
  final double radius;

  /// Faktor auf den Schaden. 0, wenn sie keinen anrichtet.
  final double power;

  /// Wie lange sie wirkt. 0 für alles, was sofort geschieht.
  final double duration;

  /// Tempo während [duration], als Vielfaches der Laufgeschwindigkeit.
  final double speedFactor;
}
