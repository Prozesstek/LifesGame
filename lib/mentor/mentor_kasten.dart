import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/erster_start_provider.dart';
import '../ui/holz.dart';
import '../ui/palette.dart';
import '../ui/pixel_art.dart';
import '../ui/pulsieren.dart';
import 'mentor.dart';
import 'scheinwerfer.dart';

/// Der Mentor mit seinem Satz: Bild links, Text rechts, auf Pergament im
/// Holzrahmen.
///
/// **Er schiebt sich herein**, wenn ein neuer Satz kommt, und steht dann
/// still — keine Bewegung ohne Ende, also nichts, worauf
/// `pumpAndSettle` warten müsste.
class MentorKasten extends StatelessWidget {
  const MentorKasten({
    required this.text,
    this.gerahmt = true,
    this.weiter = false,
    super.key,
  });

  final String text;

  /// Ob unten rechts das Zeichen steht, dass ein Tipp weiterführt.
  final bool weiter;

  /// Ob er im eigenen Holzrahmen steht. In einem Dialog nicht: Der hat
  /// schon einen, und zwei ineinander wären dicker als der Inhalt.
  final bool gerahmt;

  static const Key kastenKey = ValueKey<String>('mentor-kasten');

  /// Wie groß sein Bild steht.
  static const double bildSeite = 56;

  /// So lange blendet er ein — und ein neuer Satz in ihm.
  static const Duration dauer = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    // **Nur Deckkraft, kein Weg** (08.11.2026): Er blendet an seinem
    // Platz ein, nichts gleitet — und nur, wenn er erscheint. Wechselt
    // sein Satz, bleibt der Kasten stehen, und nur der Satz blendet neu
    // ein (`_satz`); bis dahin verschwand der ganze Kasten kurz.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: dauer,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
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
    final zeile = Row(
      children: <Widget>[
        const MentorBild(),
        const SizedBox(width: 12),
        Expanded(
          child: TweenAnimationBuilder<double>(
            key: ValueKey<String>(text),
            tween: Tween<double>(begin: 0, end: 1),
            duration: dauer,
            curve: Curves.easeOutCubic,
            builder: (context, t, satz) => Opacity(opacity: t, child: satz),
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
        ),
        // Platz für das Zeichen, damit der Text nicht darunter läuft.
        if (weiter) const SizedBox(width: 14),
      ],
    );
    if (!weiter) return zeile;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        zeile,
        const Positioned(right: -6, bottom: -6, child: WeiterZeichen()),
      ],
    );
  }
}

/// **Ein Tipp führt weiter** (06.11.2026): das kleine Dreieck unten
/// rechts, wie in Dialogen von Rollenspielen. Es hüpft sacht; in Tests
/// steht es still, wie alles, was pulsiert (`Pulsieren.pulsiert`).
class WeiterZeichen extends StatefulWidget {
  const WeiterZeichen({super.key});

  static const Key zeichenKey = ValueKey<String>('mentor-weiter');

  @override
  State<WeiterZeichen> createState() => _WeiterZeichenState();
}

class _WeiterZeichenState extends State<WeiterZeichen>
    with SingleTickerProviderStateMixin {
  // In `initState`, nicht faul (`gotchas.md`).
  late final AnimationController _takt;

  @override
  void initState() {
    super.initState();
    _takt = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ruhig = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (Pulsieren.pulsiert && !ruhig) {
      if (!_takt.isAnimating) _takt.repeat(reverse: true);
    } else {
      _takt.stop();
    }
  }

  @override
  void dispose() {
    _takt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Eigene Ebene: Das Dreieck wippt ohne Ende (`gotchas.md`).
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _takt,
        builder: (context, kind) => Transform.translate(
          offset: Offset(0, 3 * Curves.easeInOut.transform(_takt.value)),
          child: kind,
        ),
        child: const Icon(
          Icons.arrow_drop_down_rounded,
          key: WeiterZeichen.zeichenKey,
          size: 28,
          color: Palette.accent,
          semanticLabel: 'Tippen für weiter',
        ),
      ),
    );
  }
}

/// Das Bild des Mentors: sein Kopf in einem Kreis (`Mentor.bild`) —
/// neben jedem Satz und dort, wo er abfragt (`MentorDialog`). Fehlt die
/// Datei, ein gezeichneter Kopf.
class MentorBild extends StatelessWidget {
  const MentorBild({this.seite = MentorKasten.bildSeite, super.key});

  final double seite;

  @override
  Widget build(BuildContext context) {
    final kopf = _Platzhalter(seite: seite);
    return Container(
      width: seite,
      height: seite,
      decoration: BoxDecoration(
        color: Palette.backgroundRaised,
        shape: BoxShape.circle,
        border: Border.all(color: Palette.goldOnDark, width: 2),
      ),
      child: ClipOval(
        child: PixelArt(assetPath: Mentor.bild, side: seite, fallback: kopf),
      ),
    );
  }
}

class _Platzhalter extends StatelessWidget {
  const _Platzhalter({required this.seite});

  final double seite;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: seite,
      height: seite,
      decoration: BoxDecoration(
        color: Palette.backgroundRaised,
        shape: BoxShape.circle,
        border: Border.all(color: Palette.goldOnDark, width: 2),
      ),
      child: Icon(
        Icons.person_rounded,
        size: seite * 0.64,
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
                    child: IgnorePointer(
                      child: MentorKasten(text: satz.text, weiter: satz.weiter),
                    ),
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
