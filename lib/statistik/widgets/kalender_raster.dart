import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../habits/widgets/weekday_picker.dart';
import '../../ui/druck.dart';
import '../../ui/palette.dart';
import '../statistik_text.dart';

/// **Das Kalender-Raster** (ADR-0087): jedes Kästchen ein Tag, je mehr
/// erledigt, desto kräftiger grün.
///
/// Woche: sieben in einer Reihe. Monat: ein Kalenderblatt. Jahr: wie bei
/// GitHub, 53 Spalten zu sieben Tagen, quer zu rollen. Gesamt: je Jahr
/// eine Zeile mit zwölf Monaten. Ein Tipp wählt ein Kästchen; was dahinter
/// steckt, steht darunter ([onTag]).
///
/// [fortschritt] lässt die Kästchen nacheinander erscheinen, 0 bis 1.
class KalenderRaster extends StatelessWidget {
  const KalenderRaster({
    required this.rechnung,
    required this.fenster,
    required this.onTag,
    this.gewaehlt,
    this.fortschritt = 1,
    super.key,
  });

  final StatRechnung rechnung;
  final StatFenster fenster;

  /// Ein Tag wurde angetippt — bei „Gesamt“ der erste Tag des Monats.
  final ValueChanged<Day> onTag;
  final Day? gewaehlt;
  final double fortschritt;

  /// Woran ein Test das Kästchen eines Tages findet.
  static Key zelleKey(Day tag) => ValueKey<String>('raster-$tag');

  /// Woran ein Test das ganze Jahresraster findet.
  static const Key jahrKey = ValueKey<String>('raster-jahr');

  @override
  Widget build(BuildContext context) {
    return switch (fenster.zeitraum) {
      StatZeitraum.woche => _woche(),
      StatZeitraum.monat => _monat(),
      StatZeitraum.jahr => _Jahresraster(
        tage: rechnung.tage(fenster),
        fenster: fenster,
        heute: rechnung.heute,
        gewaehlt: gewaehlt,
        fortschritt: fortschritt,
        onTag: onTag,
      ),
      StatZeitraum.gesamt => _gesamt(),
    };
  }

  double _sichtbar(int index, int anzahl) =>
      (fortschritt * anzahl - index).clamp(0.0, 1.0);

  Widget _woche() {
    final tage = rechnung.tage(fenster);
    return Row(
      children: <Widget>[
        for (final (i, tag) in tage.indexed)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: 1,
                    child: _Zelle(
                      key: zelleKey(tag.tag),
                      farbe: StatFarbe.tag(tag),
                      gewaehlt: tag.tag == gewaehlt,
                      sichtbar: _sichtbar(i, tage.length),
                      onTap: () => onTag(tag.tag),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Wochentage.kurz(tag.tag.weekday),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Palette.textDim,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _monat() {
    final tage = rechnung.tage(fenster);
    final leer = fenster.von.weekday - 1;
    final zeilen = ((leer + tage.length) / 7).ceil();
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            for (final w in Wochentage.alle)
              Expanded(
                child: Center(
                  child: Text(
                    Wochentage.kurz(w),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Palette.textDim,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var z = 0; z < zeilen; z++)
          Row(
            children: <Widget>[
              for (var s = 0; s < 7; s++)
                Expanded(child: _monatsZelle(z * 7 + s - leer, tage)),
            ],
          ),
      ],
    );
  }

  Widget _monatsZelle(int index, List<StatTag> tage) {
    if (index < 0 || index >= tage.length) {
      return const AspectRatio(aspectRatio: 1, child: SizedBox.shrink());
    }
    final tag = tage[index];
    return Padding(
      padding: const EdgeInsets.all(2),
      child: AspectRatio(
        aspectRatio: 1,
        child: _Zelle(
          key: zelleKey(tag.tag),
          farbe: StatFarbe.tag(tag),
          gewaehlt: tag.tag == gewaehlt,
          sichtbar: _sichtbar(index, tage.length),
          onTap: () => onTag(tag.tag),
          zahl: tag.tag.day,
        ),
      ),
    );
  }

  Widget _gesamt() {
    final jahre = <int>[
      for (var j = fenster.von.year; j <= fenster.bis.year; j++) j,
    ];
    final anzahl = jahre.length * 12;
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            const SizedBox(width: 40),
            for (var m = 1; m <= 12; m++)
              Expanded(
                child: Center(
                  child: Text(
                    StatText.monatKurz(m).substring(0, 1),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Palette.textDim,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (final (zeile, jahr) in jahre.indexed)
          Row(
            children: <Widget>[
              SizedBox(
                width: 40,
                child: Text(
                  '$jahr',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Palette.textDim,
                  ),
                ),
              ),
              for (final (m, monat)
                  in rechnung
                      .abschnitte(
                        StatFenster.um(
                          StatZeitraum.jahr,
                          Day(jahr, 1, 1),
                          anfang: fenster.von,
                          heute: rechnung.heute,
                        ),
                        StatTeilung.monat,
                      )
                      .indexed)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _Zelle(
                        key: zelleKey(monat.von),
                        farbe: monat.zukunft
                            ? null
                            : StatFarbe.quote(monat.quote),
                        gewaehlt: monat.von == gewaehlt,
                        sichtbar: _sichtbar(zeile * 12 + m, anzahl),
                        onTap: () => onTag(monat.von),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Zelle extends StatelessWidget {
  const _Zelle({
    required this.farbe,
    required this.gewaehlt,
    required this.sichtbar,
    required this.onTap,
    this.zahl,
    super.key,
  });

  /// Null für einen Tag, der noch kommt.
  final Color? farbe;
  final bool gewaehlt;
  final double sichtbar;
  final VoidCallback onTap;

  /// Der Tag des Monats, im Kalenderblatt.
  final int? zahl;

  @override
  Widget build(BuildContext context) {
    final hell =
        farbe == null ||
        ThemeData.estimateBrightnessForColor(farbe!) == Brightness.light;
    return Opacity(
      opacity: sichtbar,
      child: Transform.scale(
        scale: 0.6 + 0.4 * sichtbar,
        child: Druck(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: farbe,
                borderRadius: BorderRadius.circular(5),
                border: gewaehlt
                    ? Border.all(color: Palette.text, width: 2)
                    : farbe == null
                    ? Border.all(color: Palette.surfaceSunken)
                    : null,
              ),
              child: zahl == null
                  ? null
                  : Center(
                      child: Text(
                        '$zahl',
                        style: TextStyle(
                          fontSize: 10,
                          color: hell ? Palette.textDim : Palette.surface,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Das Jahr wie bei GitHub — gemalt statt aus 365 Widgets gebaut, und
/// quer zu rollen. Es öffnet bei heute.
class _Jahresraster extends StatefulWidget {
  const _Jahresraster({
    required this.tage,
    required this.fenster,
    required this.heute,
    required this.gewaehlt,
    required this.fortschritt,
    required this.onTag,
  });

  final List<StatTag> tage;
  final StatFenster fenster;
  final Day heute;
  final Day? gewaehlt;
  final double fortschritt;
  final ValueChanged<Day> onTag;

  static const double zelle = 13;
  static const double luecke = 3;
  static const double kopf = 16;

  @override
  State<_Jahresraster> createState() => _JahresrasterState();
}

class _JahresrasterState extends State<_Jahresraster> {
  ScrollController? _rolle;

  Day get _erster => widget.fenster.von.startOfWeek;

  int _spalte(Day tag) => _erster.daysUntil(tag) ~/ 7;

  int get _spalten => _spalte(widget.fenster.bis) + 1;

  @override
  void dispose() {
    _rolle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const schritt = _Jahresraster.zelle + _Jahresraster.luecke;
    final breite = _spalten * schritt;
    const hoehe = _Jahresraster.kopf + 7 * schritt;
    return LayoutBuilder(
      builder: (context, grenzen) {
        // Einmal, beim ersten Bau: so weit gerollt, dass heute (oder das
        // Ende des Jahres) zu sehen ist.
        _rolle ??= ScrollController(
          initialScrollOffset: math.max(
            0,
            (widget.fenster.enthaelt(widget.heute)
                        ? _spalte(widget.heute) + 2
                        : _spalten) *
                    schritt -
                grenzen.maxWidth,
          ),
        );
        return SingleChildScrollView(
          controller: _rolle,
          scrollDirection: Axis.horizontal,
          child: Druck(
            child: GestureDetector(
              key: KalenderRaster.jahrKey,
              onTapUp: (details) => _tippe(details.localPosition),
              child: CustomPaint(
                size: Size(breite, hoehe),
                painter: _JahresMaler(
                  // Die Schrift der App, nicht die des Malers — sonst
                  // stehen die Monate in einer Ersatzschrift da.
                  schrift: DefaultTextStyle.of(
                    context,
                  ).style.copyWith(fontSize: 10, color: Palette.textDim),
                  tage: widget.tage,
                  erster: _erster,
                  gewaehlt: widget.gewaehlt,
                  fortschritt: widget.fortschritt,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _tippe(Offset ort) {
    const schritt = _Jahresraster.zelle + _Jahresraster.luecke;
    final spalte = (ort.dx / schritt).floor();
    final zeile = ((ort.dy - _Jahresraster.kopf) / schritt).floor();
    if (zeile < 0 || zeile > 6) return;
    final tag = _erster.plus(spalte * 7 + zeile);
    if (widget.fenster.enthaelt(tag)) widget.onTag(tag);
  }
}

class _JahresMaler extends CustomPainter {
  _JahresMaler({
    required this.schrift,
    required this.tage,
    required this.erster,
    required this.gewaehlt,
    required this.fortschritt,
  });

  final TextStyle schrift;
  final List<StatTag> tage;
  final Day erster;
  final Day? gewaehlt;
  final double fortschritt;

  @override
  void paint(Canvas canvas, Size size) {
    const schritt = _Jahresraster.zelle + _Jahresraster.luecke;
    final rand = Paint()
      ..color = Palette.surfaceSunken
      ..style = PaintingStyle.stroke;
    final auswahl = Paint()
      ..color = Palette.text
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final (i, tag) in tage.indexed) {
      final sichtbar = (fortschritt * tage.length - i).clamp(0.0, 1.0);
      if (sichtbar <= 0) continue;
      final abstand = erster.daysUntil(tag.tag);
      final ort = Offset(
        (abstand ~/ 7) * schritt,
        _Jahresraster.kopf + (abstand % 7) * schritt,
      );
      final feld = RRect.fromRectAndRadius(
        ort & const Size.square(_Jahresraster.zelle),
        const Radius.circular(3),
      );
      final farbe = StatFarbe.tag(tag);
      if (farbe == null) {
        canvas.drawRRect(feld, rand);
      } else {
        canvas.drawRRect(
          feld,
          Paint()..color = farbe.withValues(alpha: farbe.a * sichtbar),
        );
      }
      if (tag.tag == gewaehlt) canvas.drawRRect(feld, auswahl);

      // Der Name des Monats über seiner ersten Spalte.
      if (tag.tag.day == 1) {
        final text = TextPainter(
          text: TextSpan(
            text: StatText.monatKurz(tag.tag.month),
            style: schrift,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(canvas, Offset(ort.dx, 0));
      }
    }
  }

  @override
  bool shouldRepaint(_JahresMaler alt) =>
      alt.fortschritt != fortschritt ||
      alt.gewaehlt != gewaehlt ||
      alt.tage != tage;
}
