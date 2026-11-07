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
    super.key,
  });

  final Schritt schritt;
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
    super.key,
  });

  final Widget child;
  final double radius;

  /// Ob der gelbe Punkt dazukommt (siehe [Zeigefinger.punkt]).
  final bool punkt;

  /// Ob gerade gezeigt wird. Aus heißt: nur das Ziel.
  final bool sichtbar;

  /// Wie weit der Punkt über die Ecke des Ziels hinausragt.
  static const double ueberstand = 6;

  @override
  Widget build(BuildContext context) {
    return ScheinwerferZiel(
      aktiv: sichtbar,
      radius: radius,
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
    );
  }
}

/// **Der Punkt kommt zuletzt** (06.11.2026): erst der Mentor, dann sein
/// Ziel, dann der Punkt — er blendet ein, wenn das Ziel steht.
class _SpaeterPunkt extends StatelessWidget {
  const _SpaeterPunkt();

  static const Duration blende = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final warten = DerReiheNach.fertigNach(1);
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
