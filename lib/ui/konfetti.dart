import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'palette.dart';

/// **Konfetti, wenn der Tag geschafft ist** — das letzte Fällige ist
/// abgehakt. Reine Rechnung, ohne Leinwand.
///
/// Es schiesst dort hoch, wo getippt wurde, fächert auf, flattert und
/// sinkt über den ganzen Bildschirm. Der seltenste Moment des Häkchens,
/// höchstens einmal am Tag; deshalb darf er laut sein. Gesät, damit
/// derselbe Wurf in einem Test derselbe ist.
class Konfetti {
  Konfetti({required Offset von, int seed = 5, int anzahl = 90})
    : stuecke = _werfen(von, math.Random(seed), anzahl);

  /// Wie lange es in der Luft ist, in Sekunden.
  static const double dauer = 2.4;

  /// Die letzten Sekunden blendet es aus, statt am Rand zu verschwinden.
  static const double ausblenden = 0.6;

  /// Schwere und Luft, in Punkten je Sekunde. Mit der Luft fällt ein
  /// Schnipsel nie schneller als `schwere / luft` — wie Papier.
  static const double schwere = 900;
  static const double luft = 2.2;

  /// Die Farben: alles, was im Spiel Freude bedeutet, auf Leder wie auf
  /// Pergament zu sehen.
  static const List<Color> farben = <Color>[
    Palette.goldOnDark,
    Palette.accentOnDark,
    Palette.successOnDark,
    Palette.manaOnDark,
    Palette.rahmenEdelHell,
    Palette.tintStern,
  ];

  final List<KonfettiStueck> stuecke;
  double alter = 0;

  bool get vorbei => alter >= dauer;

  /// Wie deckend es gerade ist, 1 bis 0.
  double get deckkraft {
    final rest = dauer - alter;
    if (rest >= ausblenden) return 1;
    return math.max(0, rest / ausblenden);
  }

  void update(double dt) {
    alter += dt;
    for (final stueck in stuecke) {
      stueck.update(dt);
    }
  }

  static List<KonfettiStueck> _werfen(Offset von, math.Random zufall, int n) {
    return <KonfettiStueck>[
      for (var i = 0; i < n; i++)
        () {
          // Ein Kegel nach oben, gut einen Radiant breit zu jeder Seite.
          final winkel = -math.pi / 2 + (zufall.nextDouble() - 0.5) * 2.0;
          final tempo = 700 + zufall.nextDouble() * 800;
          return KonfettiStueck(
            ort: von,
            vx: math.cos(winkel) * tempo,
            vy: math.sin(winkel) * tempo,
            winkel: zufall.nextDouble() * math.pi,
            drehtempo: (zufall.nextDouble() - 0.5) * 12,
            kipptempo: 6 + zufall.nextDouble() * 8,
            flattern: 3 + zufall.nextDouble() * 4,
            farbe: farben[i % farben.length],
            groesse: Size(
              7 + zufall.nextDouble() * 5,
              4 + zufall.nextDouble() * 2,
            ),
          );
        }(),
    ];
  }
}

/// Ein Schnipsel. **Veränderlich, wie jedes Teilchen** (`Beutestueck`):
/// Neunzig neue Werte je Bild wären Buchhaltung ohne Nutzen.
class KonfettiStueck {
  KonfettiStueck({
    required this.ort,
    required this.vx,
    required this.vy,
    required this.winkel,
    required this.drehtempo,
    required this.kipptempo,
    required this.flattern,
    required this.farbe,
    required this.groesse,
  });

  Offset ort;
  double vx;
  double vy;

  /// Wie es in der Ebene gedreht ist.
  double winkel;
  final double drehtempo;

  /// Wie schnell es sich um die eigene Achse wendet — dann wird es
  /// schmal und wieder breit, und das ist das Flattern, das man sieht.
  final double kipptempo;

  /// Wie schnell es seitlich pendelt.
  final double flattern;

  final Color farbe;
  final Size groesse;

  double _alter = 0;

  /// Wie breit es gerade von vorn zu sehen ist, nie ganz null.
  double get kippen => math.max(0.15, math.cos(_alter * kipptempo).abs());

  void update(double dt) {
    _alter += dt;
    final bremse = math.exp(-Konfetti.luft * dt);
    vx *= bremse;
    vy = vy * bremse + Konfetti.schwere * dt;
    final pendel = math.sin(_alter * flattern) * 40;
    ort = ort.translate((vx + pendel) * dt, vy * dt);
    winkel += drehtempo * dt;
  }
}

/// Malt das Konfetti.
class KonfettiMaler extends CustomPainter {
  KonfettiMaler(this.wuerfe, {required Listenable repaint})
    : super(repaint: repaint);

  final List<Konfetti> wuerfe;

  @override
  void paint(Canvas canvas, Size size) {
    for (final wurf in wuerfe) {
      final deckkraft = wurf.deckkraft;
      if (deckkraft <= 0) continue;
      for (final stueck in wurf.stuecke) {
        canvas
          ..save()
          ..translate(stueck.ort.dx, stueck.ort.dy)
          ..rotate(stueck.winkel)
          ..drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: stueck.groesse.width,
              height: stueck.groesse.height * stueck.kippen,
            ),
            Paint()..color = stueck.farbe.withValues(alpha: deckkraft),
          )
          ..restore();
      }
    }
  }

  @override
  bool shouldRepaint(KonfettiMaler alt) => !identical(alt.wuerfe, wuerfe);
}
