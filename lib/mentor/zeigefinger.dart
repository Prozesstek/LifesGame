import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/erster_start.dart';
import '../home/erster_start_provider.dart';
import '../ui/der_reihe_nach.dart';
import 'scheinwerfer.dart';

/// Zeigt, worauf der Mentor gerade zeigt (ADR-0079, seit ADR-0095 mit
/// Scheinwerfer und gelbem Punkt).
///
/// Er steht nur da, solange der erste Start bei [schritt] ist und
/// [aktiv] gilt — etwa nur um die eine Fähigkeit, die gerade gelernt
/// ist. Getippt wird auf das Ziel selbst.
class Zeigefinger extends ConsumerWidget {
  const Zeigefinger({
    required this.schritt,
    required this.child,
    this.aktiv = true,
    this.radius = 14,
    this.punkt = true,
    this.eng = false,
    super.key,
  });

  final Schritt schritt;

  /// Im Raster: das Licht läuft kürzer aus ([ScheinwerferZiel.eng]).
  final bool eng;
  final Widget child;
  final bool aktiv;

  /// Ob der gelbe Punkt dazukommt. Ohne ihn zeigt nur das Licht — wo
  /// die ganze Fläche gemeint ist, nicht ein Knopf darin (07.11.2026).
  final bool punkt;

  /// Die Rundung des Ziels — so rund liegt es im Licht.
  final double radius;

  /// Woran Tests den Punkt finden. Heißt noch nach dem Ring, der bis
  /// ADR-0095 hier stand.
  static const Key ringKey = ValueKey<String>('zeigefinger');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zeigt = aktiv && ref.watch(ersterStartProvider).schritt == schritt;
    // **Bleibt stehen und blendet nur aus.** Fiele er weg, stünde das
    // Ziel an einer anderen Stelle im Baum und baute sich neu — samt
    // allem, was darin gerade aufspringt (`gotchas.md`).
    return ZeigeRing(
      sichtbar: zeigt,
      radius: radius,
      punkt: punkt,
      eng: eng,
      child: child,
    );
  }
}

/// Punkt und Licht, ohne zu fragen, ob sie dran sind — für Stellen, die
/// das selbst wissen, wie der Beute-Dialog des ersten Siegs.
///
/// Der Name stammt aus der Zeit des Goldrings (ADR-0079).
class ZeigeRing extends StatelessWidget {
  const ZeigeRing({
    required this.child,
    this.radius = 14,
    this.sichtbar = true,
    this.punkt = true,
    this.eng = false,
    super.key,
  });

  final Widget child;
  final double radius;

  /// Im Raster: das Licht läuft kürzer aus ([ScheinwerferZiel.eng]).
  final bool eng;

  /// Ob der gelbe Punkt dazukommt (siehe [Zeigefinger.punkt]).
  final bool punkt;

  /// Ob gerade gezeigt wird. Aus heißt: nur das Ziel.
  final bool sichtbar;

  /// Wie weit der Punkt über die Ecke des Ziels hinausragt.
  static const double ueberstand = 6;

  @override
  Widget build(BuildContext context) {
    return _InsBild(
      aktiv: sichtbar,
      child: ScheinwerferZiel(
        aktiv: sichtbar,
        radius: radius,
        eng: eng,
        // Das Licht kommt mit dem Punkt, wenn das Ziel steht (08.11.2026).
        ab: _SpaeterPunkt.warten,
        child: Stack(
          // Das Ziel bekommt dieselben Maße, als stünde nichts darüber —
          // sonst schrumpfte eine Kachel im Raster auf ihren Inhalt.
          fit: StackFit.passthrough,
          clipBehavior: Clip.none,
          children: <Widget>[
            child,
            if (sichtbar && punkt)
              const Positioned(
                top: -ueberstand,
                right: -ueberstand,
                child: _SpaeterPunkt(),
              ),
          ],
        ),
      ),
    );
  }
}

/// **Was der Mentor zeigt, steht im Bild** (08.11.2026): Liegt das Ziel
/// in einer Liste unterhalb des Sichtbaren — „Sperren“ ganz unten im
/// Blatt eines Stücks —, rollt die Liste beim ersten Bild dorthin. Ohne
/// Gleiten: Es geschieht, bevor man hinsieht, und danach rutscht nichts.
class _InsBild extends StatefulWidget {
  const _InsBild({required this.aktiv, required this.child});

  final bool aktiv;
  final Widget child;

  @override
  State<_InsBild> createState() => _InsBildState();
}

class _InsBildState extends State<_InsBild> {
  @override
  void initState() {
    super.initState();
    if (widget.aktiv) _zeige();
  }

  @override
  void didUpdateWidget(_InsBild alt) {
    super.didUpdateWidget(alt);
    if (widget.aktiv && !alt.aktiv) _zeige();
  }

  void _zeige() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || Scrollable.maybeOf(context) == null) return;
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// **Der Punkt kommt zuletzt** (06.11.2026): erst der Mentor, dann sein
/// Ziel, dann der Punkt — er blendet ein, wenn das Ziel steht.
class _SpaeterPunkt extends StatelessWidget {
  const _SpaeterPunkt();

  static const Duration blende = Duration(milliseconds: 220);

  /// Wann das Ziel steht: erst dann kommen Punkt und Licht.
  static final Duration warten = DerReiheNach.fertigNach(1);

  @override
  Widget build(BuildContext context) {
    final gesamt = warten + blende;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: gesamt,
      curve: Interval(warten.inMicroseconds / gesamt.inMicroseconds, 1),
      builder: (context, t, kind) => Opacity(opacity: t, child: kind),
      child: const ZielPunkt(key: Zeigefinger.ringKey),
    );
  }
}

/// **Der Zurück-Pfeil, auf den der Mentor zeigt** (08.11.2026): als
/// `leading` einer Kopfzeile. Bei [schritt] trägt er den gelben Punkt —
/// dann ist hier alles getan, und es geht auf der Startseite weiter.
/// Ohne Weg zurück steht nichts da.
class ZurueckPfeil extends StatelessWidget {
  const ZurueckPfeil({required this.schritt, super.key});

  final Schritt schritt;

  static const Key pfeilKey = ValueKey<String>('mentor-zurueck');

  @override
  Widget build(BuildContext context) {
    if (!Navigator.of(context).canPop()) return const SizedBox.shrink();
    return Center(
      child: Zeigefinger(
        schritt: schritt,
        radius: 20,
        child: const BackButton(key: pfeilKey),
      ),
    );
  }
}
