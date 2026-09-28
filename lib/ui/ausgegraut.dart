import 'package:flutter/widgets.dart';

/// Eine Zeichnung für etwas, das man noch nicht hat: entsättigt und halb
/// durchsichtig, aber erkennbar.
///
/// **Eine Stelle für Fähigkeiten und Ausrüstung** (ADR-0049, ADR-0057).
/// Stünde das Grau in beiden Bildschirmen, sähe „noch nicht" irgendwann
/// an zwei Stellen verschieden aus.
class Ausgegraut extends StatelessWidget {
  const Ausgegraut({required this.child, this.aktiv = true, super.key});

  final Widget child;

  /// Ob überhaupt ausgegraut wird. So bleibt der Baum gleich, egal ob
  /// das Stück da ist oder nicht.
  final bool aktiv;

  /// Wie stark es verblasst.
  static const double deckkraft = 0.45;

  /// Die Helligkeitsanteile von Rot, Grün und Blau, wie jede
  /// Graustufen-Umrechnung sie benutzt.
  static const ColorFilter grau = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    if (!aktiv) return child;
    return Opacity(
      opacity: deckkraft,
      child: ColorFiltered(colorFilter: grau, child: child),
    );
  }
}
