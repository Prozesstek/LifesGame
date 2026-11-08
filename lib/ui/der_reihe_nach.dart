import 'package:flutter/material.dart';

/// **Im Tutorial baut sich jeder Screen der Reihe nach auf** (06.11.2026,
/// Frederik: „dass Elemente nacheinander animiert werden, also so
/// nacheinander reinfliegen“).
///
/// Erst schiebt sich der Mentor herein ([mentor]), dann fliegt eins nach
/// dem anderen von unten herein, was neu ist — [nr] ist sein Platz in der
/// Reihe, [abstand] liegt zwischen zweien. Licht, gelber Punkt und
/// Pulsieren kommen danach ([fertigNach]).
///
/// **Läuft einmal, wenn das Element erscheint**, und nur, solange
/// [aktiv]: Außerhalb des Tutorials steht alles einfach da. Die Hülle
/// bleibt dabei immer stehen, sonst baute sich das Kind neu, sobald
/// [aktiv] wechselt (`gotchas.md`).
class DerReiheNach extends StatelessWidget {
  const DerReiheNach({
    required this.nr,
    required this.child,
    this.aktiv = true,
    this.nachDemMentor = true,
    super.key,
  });

  final int nr;
  final Widget child;
  final bool aktiv;

  /// Ob es wartet, bis der Kasten des Mentors steht. Ohne fliegt das
  /// erste sofort.
  final bool nachDemMentor;

  /// So lange schiebt sich der Kasten des Mentors herein (`MentorKasten`).
  static const Duration mentor = Duration(milliseconds: 320);

  /// Zwischen zwei Elementen.
  static const Duration abstand = Duration(milliseconds: 130);

  /// Wie lange eins fliegt.
  static const Duration flug = Duration(milliseconds: 380);

  /// Wann das [anzahl]-te Element steht — ab dann darf etwas leuchten.
  static Duration fertigNach(int anzahl, {bool nachDemMentor = true}) =>
      (nachDemMentor ? mentor : Duration.zero) +
      abstand * (anzahl > 0 ? anzahl - 1 : 0) +
      flug;

  @override
  Widget build(BuildContext context) {
    final ruhig = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final warten = (nachDemMentor ? mentor : Duration.zero) + abstand * nr;
    final gesamt = warten + flug;
    return TweenAnimationBuilder<double>(
      // **Der Anfang zählt nur beim Erscheinen**: Wechselt [aktiv] später,
      // bleibt es bei 1 und das Kind, wo es ist.
      tween: Tween<double>(begin: aktiv && !ruhig ? 0 : 1, end: 1),
      duration: gesamt,
      curve: Interval(
        warten.inMicroseconds / gesamt.inMicroseconds,
        1,
        curve: Curves.easeOut,
      ),
      // **Nur Deckkraft, kein Weg** (08.11.2026, Frederik: „ohne dass
      // Sachen verschoben werden“): Der Platz steht vom ersten Bild an,
      // das Element blendet darin ein.
      builder: (context, t, kind) => Opacity(opacity: t, child: kind),
      child: child,
    );
  }
}
