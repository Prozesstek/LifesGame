import 'package:flutter/material.dart';

import 'palette.dart';

/// Eine aufsteigende Zeile, wie über einem gefallenen Gegner in der Grube.
class AufstiegZeile {
  const AufstiegZeile(this.text, {this.color = Palette.accent});

  final String text;
  final Color color;
}

/// **Zahlen steigen dort auf, wo getippt wurde.**
///
/// Merkt sich über einen [Listener], wo der Finger zuletzt aufsetzte, und
/// lässt dort Zeilen aufsteigen und ausblenden ([zeige]). Die Stelle kommt
/// vom Finger, nicht vom Widget: Eine abgehakte Gewohnheit rutscht im
/// selben Moment nach unten (`dailyListOn`) — die Zahlen stehen trotzdem
/// dort, wo man hinsieht.
///
/// Jede Animation endet von selbst; ein Test mit `pumpAndSettle` wartet
/// sie einfach ab.
class AufstiegHost extends StatefulWidget {
  const AufstiegHost({required this.child, super.key});

  final Widget child;

  static const Duration dauer = Duration(milliseconds: 1100);

  /// Wie weit die Zeilen steigen.
  static const double hoehe = 56;

  /// Der Host über [context] — oder null, wenn es keinen gibt. Dann steigt
  /// eben nichts auf; das Häkchen gilt trotzdem.
  static AufstiegHostState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<AufstiegHostState>();

  @override
  State<AufstiegHost> createState() => AufstiegHostState();
}

class AufstiegHostState extends State<AufstiegHost> {
  Offset? _letzterFinger;
  final List<_Stoss> _stoesse = <_Stoss>[];
  int _naechste = 0;

  /// Lässt [zeilen] an der Stelle des letzten Fingers aufsteigen.
  void zeige(List<AufstiegZeile> zeilen) {
    final finger = _letzterFinger;
    final box = context.findRenderObject();
    if (finger == null || zeilen.isEmpty || box is! RenderBox) return;
    setState(() {
      _stoesse.add(
        _Stoss(id: _naechste++, bei: box.globalToLocal(finger), zeilen: zeilen),
      );
    });
  }

  void _fertig(int id) {
    if (!mounted) return;
    setState(() => _stoesse.removeWhere((s) => s.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _letzterFinger = e.position,
      child: Stack(
        children: <Widget>[
          widget.child,
          for (final stoss in _stoesse)
            Positioned(
              key: ValueKey<int>(stoss.id),
              left: stoss.bei.dx - 90,
              width: 180,
              top: stoss.bei.dy - 36,
              child: IgnorePointer(
                child: _Steigen(stoss: stoss, onEnde: () => _fertig(stoss.id)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stoss {
  const _Stoss({required this.id, required this.bei, required this.zeilen});

  final int id;
  final Offset bei;
  final List<AufstiegZeile> zeilen;
}

class _Steigen extends StatelessWidget {
  const _Steigen({required this.stoss, required this.onEnde});

  final _Stoss stoss;
  final VoidCallback onEnde;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AufstiegHost.dauer,
      onEnd: onEnde,
      builder: (context, t, child) {
        // Erst ein kleiner Sprung, dann gleichmässig nach oben; die zweite
        // Hälfte blendet aus.
        final steigen = Curves.easeOutCubic.transform(t);
        final sichtbar = t < 0.5 ? 1.0 : 1 - (t - 0.5) / 0.5;
        final gross = t < 0.15 ? 0.7 + 2 * t : 1.0;
        return Opacity(
          opacity: sichtbar.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -AufstiegHost.hoehe * steigen),
            child: Transform.scale(scale: gross, child: child),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final zeile in stoss.zeilen)
            Text(
              zeile.text,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: zeile.color,
                shadows: const <Shadow>[
                  Shadow(color: Color(0xCC1A0E05), offset: Offset(1, 1)),
                  Shadow(color: Color(0x991A0E05), blurRadius: 3),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
