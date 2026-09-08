import 'package:flutter/material.dart';

import '../../ui/palette.dart';

/// Ein Bereich des Spiels als runder Knopf.
///
/// **Er ersetzt seit Issue #35 die Kachelliste.** Fünf Kacheln
/// untereinander waren ein Menü; fünf Kreise um die Figur herum sind ein
/// Ort, an dem die Figur in der Mitte steht. Das ist die Aussage des
/// Produkts, und der Startbildschirm ist die einzige Stelle, an der sie
/// ohne Worte auskommt.
///
/// **Der Kreis trägt Zeichen und Namen.** Der Entwurf zeigt nur einen
/// Buchstaben je Kreis; ein „K" allein sagt aber weder „Kampf" noch
/// „Kaufen". Name unter dem Kreis kostet zwölf Pixel und nimmt die Frage
/// heraus.
class HubCircle extends StatelessWidget {
  const HubCircle({
    required this.icon,
    required this.label,
    required this.onTap,
    this.lockedReason,
    super.key,
  });

  final IconData icon;

  /// Der Name des Bereichs — steht unter dem Kreis.
  final String label;

  /// Wird gerufen, wenn der Bereich offen ist.
  final VoidCallback onTap;

  /// Warum der Bereich zu ist, in einem Satz — oder `null`, wenn er offen
  /// ist.
  ///
  /// **Der Satz verschwindet nicht, er wandert.** Auf der alten Kachel
  /// stand er dauerhaft darunter; ADR-0020 nennt ihn ausdrücklich
  /// wichtig, weil eine Sperre ohne Weg jemanden in die Theorie
  /// zurückschickt, wo er nichts mehr zu tun hat. Ein Kreis hat dafür
  /// keinen Platz, also kommt der Satz beim Antippen.
  final String? lockedReason;

  bool get isLocked => lockedReason != null;

  /// Kantenlänge des Kreises. Drei davon plus Abstand passen bei 390
  /// Pixeln Breite nebeneinander, und 72 liegt über den 48 Pixeln, die
  /// eine Tippfläche mindestens braucht.
  static const double diameter = 72;

  @override
  Widget build(BuildContext context) {
    final farbe = isLocked ? Palette.muted : Palette.accent;

    return Semantics(
      button: true,
      enabled: !isLocked,
      label: label,
      child: InkWell(
        onTap: () => isLocked ? _sageWarum(context) : onTap(),
        borderRadius: BorderRadius.circular(diameter),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    width: diameter,
                    height: diameter,
                    decoration: BoxDecoration(
                      color: Palette.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: farbe, width: 2),
                    ),
                    child: Icon(icon, size: 30, color: farbe),
                  ),
                  if (isLocked)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Palette.background,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock,
                          size: 13,
                          color: Palette.muted,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: diameter + 16,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isLocked ? Palette.muted : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sageWarum(BuildContext context) {
    final grund = lockedReason;
    if (grund == null) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(grund), duration: const Duration(seconds: 4)),
      );
  }
}
