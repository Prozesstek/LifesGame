import 'package:flutter/material.dart';

import '../../ui/palette.dart';
import '../../ui/sprung.dart';

/// **Was nach einer Antwort von unten kommt** — wie bei Duolingo: grün
/// oder rot, ein Wort, die Erklärung und der Knopf weiter.
///
/// Vor der Antwort steht nur der Knopf da, gesperrt. Mit der Antwort
/// färbt sich der Grund, und die Erklärung wächst über dem Knopf nach
/// oben heraus; das Zeichen davor springt auf. **Die Erklärung kommt
/// auch bei einer richtigen Antwort** — sie ist Teil des Inhalts, nicht
/// nur Fehlerkorrektur.
///
/// Bis zum 18.10. stand sie als Kasten unter den Antworten und der Knopf
/// fest darunter.
class AntwortLeiste extends StatefulWidget {
  const AntwortLeiste({
    required this.richtig,
    required this.erklaerung,
    required this.knopf,
    required this.onWeiter,
    super.key,
  });

  /// Null, solange nicht geantwortet ist.
  final bool? richtig;

  final String erklaerung;

  /// Was auf dem Knopf steht — „Weiter“ oder „Auswerten“.
  final String knopf;

  final VoidCallback onWeiter;

  static const Duration dauer = Duration(milliseconds: 420);

  /// Höher wird die Erklärung nicht; darüber rollt sie. Sonst schöbe eine
  /// lange die Antworten aus dem Bild.
  static const double hoechstens = 180;

  @override
  State<AntwortLeiste> createState() => _AntwortLeisteState();
}

class _AntwortLeisteState extends State<AntwortLeiste>
    with SingleTickerProviderStateMixin {
  // In `initState`, nicht faul (`gotchas.md`).
  late final AnimationController _auf;

  @override
  void initState() {
    super.initState();
    _auf = AnimationController(
      vsync: this,
      duration: AntwortLeiste.dauer,
      value: widget.richtig == null ? 0 : 1,
    );
  }

  @override
  void didUpdateWidget(AntwortLeiste alt) {
    super.didUpdateWidget(alt);
    if (alt.richtig == null && widget.richtig != null) _auf.forward(from: 0);
    if (widget.richtig == null) _auf.value = 0;
  }

  @override
  void dispose() {
    _auf.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final richtig = widget.richtig;
    final farbe = richtig == false ? Palette.enemy : Palette.success;
    final grund = Color.alphaBlend(
      farbe.withValues(alpha: 0.16),
      Palette.surface,
    );

    return AnimatedBuilder(
      animation: _auf,
      builder: (context, child) {
        final t = _auf.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: richtig == null
                ? Palette.surface
                : Color.lerp(Palette.surface, grund, (t * 3).clamp(0.0, 1.0)),
            border: Border(
              top: BorderSide(
                color: richtig == null
                    ? Palette.surfaceRaised
                    : farbe.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
          ),
          child: child,
        );
      },
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (richtig != null)
                SizeTransition(
                  sizeFactor: CurvedAnimation(
                    parent: _auf,
                    curve: Curves.easeOutCubic,
                  ),
                  // Oben angeheftet: Die Kante steigt, und der Inhalt
                  // steigt mit ihr hinter dem Knopf hervor.
                  alignment: Alignment.topCenter,
                  child: _Urteil(
                    richtig: richtig,
                    farbe: farbe,
                    erklaerung: widget.erklaerung,
                    sprung: _auf,
                  ),
                ),
              FilledButton(
                onPressed: richtig == null ? null : widget.onWeiter,
                child: Text(widget.knopf),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Zeichen, Wort und Erklärung über dem Knopf.
class _Urteil extends StatelessWidget {
  const _Urteil({
    required this.richtig,
    required this.farbe,
    required this.erklaerung,
    required this.sprung,
  });

  final bool richtig;
  final Color farbe;
  final String erklaerung;
  final Animation<double> sprung;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AnimatedBuilder(
                animation: sprung,
                builder: (context, child) => Transform.scale(
                  scale: Sprung.feder(sprung.value, von: 0.2),
                  child: child,
                ),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: farbe,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    richtig ? Icons.check_rounded : Icons.close_rounded,
                    size: 20,
                    color: Palette.surface,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  richtig ? 'Richtig' : 'Nicht ganz',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: farbe,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: AntwortLeiste.hoechstens,
            ),
            child: SingleChildScrollView(
              child: Text(
                erklaerung,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Palette.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
