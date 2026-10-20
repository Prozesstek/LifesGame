import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/erster_start_provider.dart';
import '../ui/holz.dart';
import '../ui/palette.dart';
import '../ui/pixel_art.dart';
import 'mentor.dart';

/// Der Mentor mit seinem Satz: Bild links, Text rechts, auf Pergament im
/// Holzrahmen.
///
/// **Er schiebt sich herein**, wenn ein neuer Satz kommt, und steht dann
/// still — keine Bewegung ohne Ende, also nichts, worauf
/// `pumpAndSettle` warten müsste.
class MentorKasten extends StatelessWidget {
  const MentorKasten({required this.text, this.gerahmt = true, super.key});

  final String text;

  /// Ob er im eigenen Holzrahmen steht. In einem Dialog nicht: Der hat
  /// schon einen, und zwei ineinander wären dicker als der Inhalt.
  final bool gerahmt;

  static const Key kastenKey = ValueKey<String>('mentor-kasten');

  /// Wie groß sein Bild steht.
  static const double bildSeite = 56;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(text),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: gerahmt
          ? HolzKarte(
              key: kastenKey,
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
              child: _zeile(),
            )
          : KeyedSubtree(key: kastenKey, child: _zeile()),
    );
  }

  Widget _zeile() {
    return Row(
      children: <Widget>[
        const _MentorBild(),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Palette.text,
              fontSize: 14.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Das Bild des Mentors — bis Frederiks Figur kommt, ein gezeichneter
/// Kopf in einem Kreis (`Mentor.bild`).
class _MentorBild extends StatelessWidget {
  const _MentorBild();

  @override
  Widget build(BuildContext context) {
    const kopf = _Platzhalter();
    final bild = Mentor.bild;
    if (bild == null) return kopf;
    return PixelArt(
      assetPath: bild,
      side: MentorKasten.bildSeite,
      fallback: kopf,
    );
  }
}

class _Platzhalter extends StatelessWidget {
  const _Platzhalter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MentorKasten.bildSeite,
      height: MentorKasten.bildSeite,
      decoration: BoxDecoration(
        color: Palette.backgroundRaised,
        shape: BoxShape.circle,
        border: Border.all(color: Palette.goldOnDark, width: 2),
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 36,
        color: Palette.goldOnDark,
      ),
    );
  }
}

/// Legt den Kasten des Mentors über einen Bildschirm, wenn er an [ort]
/// etwas zu sagen hat — sonst steht nur [child] da.
///
/// **Der Kasten nimmt keinen Tipp an.** Er deckt höchstens einen Streifen
/// zu, und was darunter liegt, bleibt erreichbar: Der Mentor zeigt, er
/// sperrt nicht (ADR-0079, „Zeigefinger“). Wohin er zeigt, markiert
/// `Zeigefinger` am Ziel.
class MentorFlaeche extends ConsumerWidget {
  const MentorFlaeche({
    required this.ort,
    required this.child,
    this.untenFrei = 0,
    super.key,
  });

  final MentorOrt ort;
  final Widget child;

  /// Wie viel Platz der Kasten unten frei lässt. Auf der Startseite die
  /// untere Reihe der Kreise: Der Kasten steht darüber in der leeren
  /// Mitte und zeigt hinunter, statt einen Kreis zuzudecken.
  final double untenFrei;

  /// Wie breit der Kasten höchstens wird — so breit wie die Startseite.
  static const double maxBreite = 520;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final satz = Mentor.satz(ref.watch(ersterStartProvider).schritt, ort);
    if (satz == null) return child;

    final oben = satz.lage == KastenLage.oben;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        Positioned(
          left: 0,
          right: 0,
          top: oben ? 0 : null,
          bottom: oben ? null : 0,
          child: SafeArea(
            top: oben,
            bottom: !oben,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                12,
                12,
                12 + (oben ? 0 : untenFrei),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxBreite),
                  child: IgnorePointer(child: MentorKasten(text: satz.text)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
