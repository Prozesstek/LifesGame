import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/erster_start_provider.dart';
import '../ui/holz.dart';
import '../ui/palette.dart';
import '../ui/pixel_art.dart';
import 'mentor.dart';
import 'scheinwerfer.dart';

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

/// Der Kasten des Mentors an [ort] — **in der Zeile, nicht darüber**
/// (Issue #183): Er steht oben über dem, worum es geht, und schiebt es
/// nach unten, statt etwas zuzudecken. Man liest von oben nach unten.
///
/// Schweigt der Mentor, ist die Zeile leer; sie steht trotzdem immer im
/// Baum, damit nichts darunter an eine andere Stelle rutscht und sich
/// neu baut (`gotchas.md`).
///
/// **Er liegt im Licht** des Scheinwerfers, sonst läge er unter dem
/// Schleier. **Er nimmt keinen Tipp an**: Der Mentor zeigt, er sperrt
/// nicht (ADR-0079).
class MentorZeile extends ConsumerWidget {
  const MentorZeile({required this.ort, this.rand = 12, super.key});

  final MentorOrt ort;

  /// Wie viel Platz er zur Seite und nach oben lässt.
  final double rand;

  /// Wie viel Luft zu dem bleibt, was unter ihm steht.
  static const double abstand = 10;

  /// Wie breit der Kasten höchstens wird — so breit wie die Startseite.
  static const double maxBreite = 520;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final satz = Mentor.satz(ref.watch(ersterStartProvider).schritt, ort);
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: satz == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: EdgeInsets.fromLTRB(rand, rand, rand, abstand),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxBreite),
                  child: ScheinwerferZiel(
                    radius: 12,
                    begleiter: true,
                    child: IgnorePointer(child: MentorKasten(text: satz.text)),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Legt einen Bildschirm unter den Scheinwerfer und stellt den Mentor
/// oben darüber, wenn er an [ort] etwas zu sagen hat (Issue #183).
///
/// Mit [mitKasten] `false` steht nur der Scheinwerfer: Die Startseite
/// stellt die [MentorZeile] selbst unter Level und Gold.
class MentorFlaeche extends StatelessWidget {
  const MentorFlaeche({
    required this.ort,
    required this.child,
    this.mitKasten = true,
    super.key,
  });

  final MentorOrt ort;
  final Widget child;
  final bool mitKasten;

  @override
  Widget build(BuildContext context) {
    // **Der Scheinwerfer steht immer**, auch wenn der Mentor schweigt:
    // Fiele er weg, stünde [child] an einer anderen Stelle im Baum und
    // baute sich neu (`gotchas.md`). Ohne angemeldetes Ziel ist er
    // unsichtbar.
    if (!mitKasten) return Scheinwerfer(child: child);
    return Scheinwerfer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MentorZeile(ort: ort),
          Expanded(child: child),
        ],
      ),
    );
  }
}
