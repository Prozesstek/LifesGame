import 'package:flutter/material.dart';

import '../../ui/palette.dart';
import 'seiten_farbe.dart';

/// **Wie weit die Seite ist** — ein dicker Balken oben, der mit jeder
/// richtigen Antwort ein Stück vorspringt, in der Farbe der Seite
/// ([SeitenFarbe]).
///
/// Gezählt wird, was **sitzt**, nicht was beantwortet ist: Eine falsche
/// Antwort lässt ihn stehen, und erst die zweite Runde füllt ihn voll
/// (ADR-0055). So zeigt er dasselbe wie das Ende der Seite — sie endet,
/// wenn alles einmal richtig war.
class RundenBalken extends StatelessWidget {
  const RundenBalken({required this.geloest, required this.gesamt, super.key});

  final int geloest;
  final int gesamt;

  static const double hoehe = 12;

  /// Wie lange ein Sprung dauert. Die Kurve schiesst über das Ziel
  /// hinaus und kehrt zurück — vorspringen statt vorschieben.
  static const Duration dauer = Duration(milliseconds: 520);

  @override
  Widget build(BuildContext context) {
    final ziel = gesamt <= 0 ? 0.0 : geloest / gesamt;
    return Semantics(
      label: '$geloest von $gesamt richtig',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: ziel),
        duration: dauer,
        curve: Curves.easeOutBack,
        builder: (context, wert, _) => CustomPaint(
          size: const Size(double.infinity, hoehe),
          painter: _BalkenMaler(
            wert,
            farbe: SeitenFarbe.of(context),
            hell: SeitenFarbe.hellOf(context),
          ),
        ),
      ),
    );
  }
}

class _BalkenMaler extends CustomPainter {
  const _BalkenMaler(this.wert, {required this.farbe, required this.hell});

  /// Wie voll, 0 bis 1 — die Kurve darf kurz darüber hinaus.
  final double wert;

  final Color farbe;

  /// Der helle Ton für den Glanz oben.
  final Color hell;

  @override
  void paint(Canvas canvas, Size size) {
    final rund = Radius.circular(size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, rund),
      Paint()..color = Palette.surfaceSunken,
    );
    final breite = size.width * wert.clamp(0.0, 1.0);
    // Schmaler als hoch sähe der Balken aus wie ein Punkt; dann lieber
    // gar nicht.
    if (breite < size.height) return;
    final voll = Rect.fromLTWH(0, 0, breite, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(voll, rund),
      Paint()..color = farbe,
    );
    // Der Glanz oben: ein heller Streifen, eingerückt wie bei Duolingo.
    final glanz = Rect.fromLTWH(
      size.height / 2,
      size.height * 0.2,
      breite - size.height,
      size.height * 0.24,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(glanz, Radius.circular(glanz.height / 2)),
      Paint()..color = hell.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_BalkenMaler alt) =>
      alt.wert != wert || alt.farbe != farbe || alt.hell != hell;
}
