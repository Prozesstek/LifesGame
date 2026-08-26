/// Wie schwer eine Faehigkeit zu treffen ist.
///
/// **Das ist eine Kampfregel, keine Darstellung.** Wie schnell der Marker
/// laeuft und wie breit die Perfect-Zone ist, entscheidet mit darueber, was
/// eine Faehigkeit wert ist -- deshalb steht es hier und nicht im
/// Bildschirm. Die Leiste liest diese Werte und misst nur (ADR-0002).
class TimingSpec {
  const TimingSpec({this.speed = 1.0, this.perfectWindow = 0.24});

  /// Standardwerte der bestehenden Moves. 1.0x und 24 % entsprechen der
  /// Leiste, wie sie vor dem Faehigkeiten-Set lief.
  static const TimingSpec standard = TimingSpec();

  /// Geschwindigkeit des Markers. 1.0 ist Standard, groesser ist
  /// schneller und damit schwerer.
  final double speed;

  /// Breite der Perfect-Zone als Anteil der ganzen Leiste. 0.24 = 24 %.
  ///
  /// Gemessen ueber die **gesamte** Breite, nicht als Abstand von der
  /// Mitte: 24 % heisst, dass die mittleren 24 % der Leiste perfekt sind.
  final double perfectWindow;

  /// Die Good-Zone ist immer doppelt so breit wie die Perfect-Zone.
  ///
  /// Ein eigener Wert je Faehigkeit waere eine dritte Zahl, die niemand
  /// im Kopf behaelt -- und die MD nennt sie nicht. Das Verhaeltnis
  /// stammt aus der alten Leiste (6 % perfekt, 17 % gut).
  double get goodWindow => perfectWindow * 2;

  /// Untergrenzen, damit Umgebungen und Effekte eine Faehigkeit nicht
  /// unspielbar machen koennen.
  ///
  /// Beide stehen so in der Vorlage: „Speed nie unter 0.4x, Fenster nie
  /// unter 3 %". Nach oben ist die Geschwindigkeit gedeckelt, weil ein
  /// Marker, der schneller als etwa viermal Standard laeuft, auf einem
  /// Handy nicht mehr zu treffen ist.
  static const double minSpeed = 0.4;
  static const double maxSpeed = 4.0;
  static const double minWindow = 0.03;

  /// Ein Wertobjekt: Zwei Angaben mit denselben Zahlen sind dasselbe.
  ///
  /// Noetig, weil die Darstellung daran entscheidet, ob sie neu zeichnen
  /// muss -- ohne Vergleich waere jede frisch gerechnete Angabe „anders".
  @override
  bool operator ==(Object other) {
    return other is TimingSpec &&
        other.speed == speed &&
        other.perfectWindow == perfectWindow;
  }

  @override
  int get hashCode => Object.hash(speed, perfectWindow);

  /// Wendet Faktoren aus Umgebung und Statuseffekten an.
  ///
  /// Multiplikativ, wie es die Vorlage vorgibt: Zwei Effekte, die das
  /// Fenster je um ein Viertel kuerzen, lassen etwas mehr als die Haelfte
  /// uebrig -- nicht die Haelfte minus etwas.
  TimingSpec scaled({double speedFactor = 1.0, double windowFactor = 1.0}) {
    return TimingSpec(
      speed: (speed * speedFactor).clamp(minSpeed, maxSpeed),
      perfectWindow: (perfectWindow * windowFactor).clamp(minWindow, 1.0),
    );
  }
}
