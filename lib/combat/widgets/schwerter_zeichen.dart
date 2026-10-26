import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/palette.dart';

/// **Zwei gekreuzte Schwerter** — das Zeichen für „in den Kampf“, auf dem
/// Knopf „Hinab“ im Eingang und in der Tagesgrube (AktivesBrett, 26.10.).
/// Bis dahin standen dort zwei Pfeile nach unten.
///
/// **Nachgezeichnet, nicht übernommen**: Die Vorlage war ein Icon
/// unbekannter Herkunft. Hier ist es aus Linien gerechnet und gehört dem
/// Projekt — scharf in jeder Größe und in jeder Farbe. Ohne [color]
/// nimmt es die Farbe der Zeichen um es herum, auf einem Holzknopf also
/// die der Schrift.
///
/// Jedes Schwert: Spitze mit Kante, Klinge mit Blutrinne, Parierstange,
/// Griff, Knauf. Das Schwert von rechts oben liegt vorn; wo es das
/// andere kreuzt, verdeckt es dessen Linien.
class SchwerterZeichen extends StatelessWidget {
  const SchwerterZeichen({
    this.size = 28,
    this.color,
    this.semanticLabel,
    super.key,
  });

  final double size;
  final Color? color;

  /// Was der Vorleser sagt; ohne steht das Zeichen für ihn nicht da.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final farbe = color ?? IconTheme.of(context).color ?? Palette.textOnDark;
    final zeichen = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _SchwerterMaler(farbe)),
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: zeichen);
    return Semantics(label: label, image: true, child: zeichen);
  }
}

class _SchwerterMaler extends CustomPainter {
  const _SchwerterMaler(this.farbe);

  final Color farbe;

  /// Alle Maße als Anteil der Seite, entlang eines Schwerts gemessen:
  /// x quer, y von der Spitze (negativ) zum Knauf (positiv). Bei 0
  /// kreuzen sich die Klingen — wie in der Vorlage etwa in ihrer Mitte.
  ///
  /// Die Spitze ist ein Quadrat über Eck: Schulter und Kehle liegen je
  /// eine halbe Klingenbreite weiter.
  static const double _klinge = 0.077;
  static const double _spitze = -0.456;
  static const double _schulter = _spitze + _klinge;
  static const double _kehle = _spitze + 2 * _klinge;
  static const double _klingenEnde = 0.225;
  static const double _parierEnde = 0.315;
  static const double _griffEnde = 0.47;
  static const double _knaufEnde = 0.576;
  static const double _strich = 0.046;

  /// Die Knäufe reichen weiter als die Spitzen; um so viel steht das
  /// Kreuz über der Mitte, damit das Zeichen mittig sitzt.
  static const double _hoeher = 0.075;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final mitte = size.center(Offset.zero) - Offset(0, _hoeher * s);
    final linie = Paint()
      ..color = farbe
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strich * s
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Hinten das Schwert mit der Spitze links oben, vorn das andere.
    final hinten = _gedreht(mitte, s, -math.pi / 4);
    final vorn = _gedreht(mitte, s, math.pi / 4);

    // Das hintere auf eigener Ebene, damit das vordere darin ein Loch
    // in Form seines Umrisses schneiden kann — samt etwas Luft.
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final pfad in _linien(hinten, rinneBis: -0.04)) {
      canvas.drawPath(pfad, linie);
    }
    final loch = Paint()..blendMode = BlendMode.clear;
    canvas.drawPath(_umriss(vorn), loch);
    canvas.drawPath(
      _umriss(vorn),
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strich * s * 2,
    );
    canvas.restore();

    for (final pfad in _linien(vorn, rinneBis: 0.14)) {
      canvas.drawPath(pfad, linie);
    }
  }

  /// Wie ein Punkt eines Schwerts aufs Bild kommt.
  static Offset Function(double x, double y) _gedreht(
    Offset mitte,
    double s,
    double winkel,
  ) {
    final c = math.cos(winkel);
    final si = math.sin(winkel);
    return (x, y) => mitte + Offset((x * c - y * si) * s, (x * si + y * c) * s);
  }

  /// Die Linien eines Schwerts. Die Blutrinne des hinteren endet vor
  /// dem Kreuz ([rinneBis]) — hinter dem vorderen bliebe sonst ein
  /// Stummel stehen.
  static List<Path> _linien(
    Offset Function(double, double) p, {
    required double rinneBis,
  }) {
    // Klinge mit Spitze.
    final klinge = Path()
      ..moveTo(p(-_klinge, _klingenEnde).dx, p(-_klinge, _klingenEnde).dy)
      ..lineTo(p(-_klinge, _schulter).dx, p(-_klinge, _schulter).dy)
      ..lineTo(p(0, _spitze).dx, p(0, _spitze).dy)
      ..lineTo(p(_klinge, _schulter).dx, p(_klinge, _schulter).dy)
      ..lineTo(p(_klinge, _klingenEnde).dx, p(_klinge, _klingenEnde).dy);
    // Die Kante der Spitze.
    final kante = Path()
      ..moveTo(p(-_klinge, _schulter).dx, p(-_klinge, _schulter).dy)
      ..lineTo(p(0, _kehle).dx, p(0, _kehle).dy)
      ..lineTo(p(_klinge, _schulter).dx, p(_klinge, _schulter).dy);
    // Die Blutrinne, oben abgesetzt.
    final rinne = Path()
      ..moveTo(p(0, -0.17).dx, p(0, -0.17).dy)
      ..lineTo(p(0, rinneBis).dx, p(0, rinneBis).dy)
      ..moveTo(p(0, -0.235).dx, p(0, -0.235).dy)
      ..lineTo(p(0, -0.23).dx, p(0, -0.23).dy);
    return <Path>[
      klinge,
      kante,
      rinne,
      _stab(p, -0.16, 0.16, _klingenEnde, _parierEnde),
      _kasten(p, -0.045, 0.045, _parierEnde, _griffEnde),
      _stab(p, -0.09, 0.09, _griffEnde, _knaufEnde),
    ];
  }

  /// Die ganze Fläche eines Schwerts — damit verdeckt das vordere.
  static Path _umriss(Offset Function(double, double) p) {
    final klinge = Path()
      ..moveTo(p(-_klinge, _klingenEnde).dx, p(-_klinge, _klingenEnde).dy)
      ..lineTo(p(-_klinge, _schulter).dx, p(-_klinge, _schulter).dy)
      ..lineTo(p(0, _spitze).dx, p(0, _spitze).dy)
      ..lineTo(p(_klinge, _schulter).dx, p(_klinge, _schulter).dy)
      ..lineTo(p(_klinge, _klingenEnde).dx, p(_klinge, _klingenEnde).dy)
      ..close();
    return Path()
      ..addPath(klinge, Offset.zero)
      ..addPath(_stab(p, -0.16, 0.16, _klingenEnde, _parierEnde), Offset.zero)
      ..addPath(_kasten(p, -0.045, 0.045, _parierEnde, _griffEnde), Offset.zero)
      ..addPath(_stab(p, -0.09, 0.09, _griffEnde, _knaufEnde), Offset.zero);
  }

  /// Ein Viereck, quer zum Schwert ausgerichtet.
  static Path _kasten(
    Offset Function(double, double) p,
    double links,
    double rechts,
    double oben,
    double unten,
  ) {
    return Path()..addPolygon(<Offset>[
      p(links, oben),
      p(rechts, oben),
      p(rechts, unten),
      p(links, unten),
    ], true);
  }

  /// Ein Stab mit runden Enden: Parierstange und Knauf.
  static Path _stab(
    Offset Function(double, double) p,
    double links,
    double rechts,
    double oben,
    double unten,
  ) {
    final r = (unten - oben) / 2;
    final mitteY = (oben + unten) / 2;
    final pfad = Path()..moveTo(p(links + r, oben).dx, p(links + r, oben).dy);
    pfad.lineTo(p(rechts - r, oben).dx, p(rechts - r, oben).dy);
    _bogen(pfad, p, rechts - r, mitteY, r, -math.pi / 2);
    pfad.lineTo(p(links + r, unten).dx, p(links + r, unten).dy);
    _bogen(pfad, p, links + r, mitteY, r, math.pi / 2);
    return pfad..close();
  }

  /// Ein Halbkreis um (x, y), Punkt für Punkt, damit er die Drehung
  /// mitmacht.
  static void _bogen(
    Path pfad,
    Offset Function(double, double) p,
    double x,
    double y,
    double r,
    double start,
  ) {
    const schritte = 10;
    for (var i = 1; i <= schritte; i++) {
      final w = start + math.pi * i / schritte;
      final punkt = p(x + r * math.cos(w), y + r * math.sin(w));
      pfad.lineTo(punkt.dx, punkt.dy);
    }
  }

  @override
  bool shouldRepaint(_SchwerterMaler alt) => alt.farbe != farbe;
}
