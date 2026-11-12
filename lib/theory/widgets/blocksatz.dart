import 'package:flutter/material.dart';

import '../silbentrennung.dart';
import 'buch_stil.dart';

/// Ein Stück eines Absatzes mit seinem Stil — meist ein Wort oder der
/// Leerraum dahinter. Der Text darf weiche Trennstriche tragen.
class SatzStueck {
  const SatzStueck(this.text, this.stil);

  final String text;
  final TextStyle stil;
}

/// **Ein Absatz im Blocksatz, wie im Buch** (12.11.2026).
///
/// Flutter bricht an einem weichen Trennstrich um, zeichnet aber keinen
/// Strich. `Blocksatz` legt den Absatz deshalb zur Probe an, sieht nach,
/// welche Zeile an einem weichen Strich endet, und setzt dort einen
/// echten. Rutscht ein Strich dadurch aus dem Zeilenende, wird diese
/// Stelle nicht mehr getrennt — so lange, bis nichts mehr wandert.
///
/// Mit [initiale] steht der erste Buchstabe groß über
/// [BuchStil.initialeZeilen] Zeilen, und der Text läuft rechts daneben,
/// darunter wieder über die ganze Breite.
///
/// Die Entscheidung, wo getrennt wird, hängt nur an Text und Breite, nicht
/// an der Farbe: Der Text, der sich Wort für Wort einblendet, wird deshalb
/// nicht in jedem Bild neu umbrochen.
class Blocksatz extends StatelessWidget {
  const Blocksatz({
    required this.stuecke,
    this.initiale,
    this.semantik,
    super.key,
  });

  final List<SatzStueck> stuecke;

  /// Der erste Buchstabe, groß und in der Farbe der Seite. Er steht
  /// **nicht** in [stuecke].
  final Text? initiale;

  /// Was der Vorleser hört — der ganze Absatz ohne Trennstriche.
  final String? semantik;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    // **Nichts erben.** Die Probe misst ohne Stil von außen; erbte das
    // Bild etwa den Buchstabenabstand des Themes, bräche es anders um als
    // gemessen — Striche mitten in der Zeile, Wörter, die fehlen.
    final kind = DefaultTextStyle(
      style: const TextStyle(),
      child: LayoutBuilder(
        builder: (context, grenzen) {
          final cap = initiale;
          if (cap == null) return _satz(stuecke, grenzen.maxWidth, scaler);
          return _mitInitiale(cap, grenzen.maxWidth, scaler);
        },
      ),
    );
    final label = semantik;
    if (label == null) return kind;
    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: kind,
    );
  }

  static Widget _satz(
    List<SatzStueck> stuecke,
    double breite,
    TextScaler scaler,
  ) {
    final gesetzt = _Satz.setze(stuecke, breite, scaler);
    return Text.rich(
      TextSpan(children: gesetzt),
      textAlign: TextAlign.justify,
      textScaler: scaler,
    );
  }

  Widget _mitInitiale(Text cap, double breite, TextScaler scaler) {
    final capStil = cap.style ?? BuchStil.initiale;
    final capMaler = TextPainter(
      text: TextSpan(text: cap.data, style: capStil),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final capBreite = capMaler.width;
    capMaler.dispose();

    final schmal = breite - capBreite - BuchStil.initialeAbstand;
    final zeilen = BuchStil.initialeZeilen;
    final teilung = _Satz.teile(stuecke, schmal, scaler, zeilen);
    final neben = teilung.neben;
    final rest = teilung.rest;
    final hoehe = teilung.hoehe;

    final daneben = rest.isEmpty
        ? Text.rich(
            TextSpan(children: neben),
            textAlign: TextAlign.justify,
            textScaler: scaler,
          )
        // Auch die letzte Zeile neben der Initiale steht im Blocksatz: Ein
        // unsichtbarer Platzhalter in Zeilenbreite rutscht in eine vierte
        // Zeile, die abgeschnitten wird.
        : ClipRect(
            child: SizedBox(
              height: hoehe,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxHeight: double.infinity,
                child: Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      ...neben,
                      const TextSpan(text: ' '),
                      WidgetSpan(child: SizedBox(width: schmal - 1, height: 1)),
                    ],
                  ),
                  textAlign: TextAlign.justify,
                  textScaler: scaler,
                ),
              ),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: capBreite,
              height: hoehe,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxHeight: double.infinity,
                child: Transform.translate(
                  offset: const Offset(0, _initialeVersatz),
                  child: cap,
                ),
              ),
            ),
            const SizedBox(width: BuchStil.initialeAbstand),
            Expanded(child: daneben),
          ],
        ),
        if (rest.isNotEmpty) _satz(rest, breite, scaler),
      ],
    );
  }

  /// Wie weit die Initiale nach oben rückt, damit ihre Oberkante mit der
  /// ersten Zeile abschließt — gemessen an Cormorant (Vorschau 12.11.).
  static const double _initialeVersatz = -6;
}

/// Ein Absatz, geteilt an der Initiale: was neben ihr steht, schon gesetzt,
/// und was darunter weiterläuft, noch roh.
class _Teilung {
  const _Teilung(this.neben, this.rest, this.hoehe);

  final List<InlineSpan> neben;
  final List<SatzStueck> rest;
  final double hoehe;
}

/// Wo ein Absatz getrennt wird — die Rechnung hinter [Blocksatz].
abstract final class _Satz {
  /// Zustand eines weichen Strichs.
  static const int _weich = 0;
  static const int _strich = 1;
  static const int _ganz = 2;

  /// Wie oft höchstens nachgebessert wird.
  static const int _runden = 8;

  /// Gemerkte Entscheidungen, nach Text, Stil und Breite.
  static final Map<String, List<List<int>>> _gemerkt =
      <String, List<List<int>>>{};

  static List<InlineSpan> setze(
    List<SatzStueck> stuecke,
    double breite,
    TextScaler scaler,
  ) {
    final zustand = _zustand(stuecke, breite, scaler);
    return <InlineSpan>[
      for (var i = 0; i < stuecke.length; i++)
        TextSpan(
          text: _aus(stuecke[i].text, zustand[i]).text,
          style: stuecke[i].stil,
        ),
    ];
  }

  /// Teilt nach [zeilen] Zeilen bei [breite].
  static _Teilung teile(
    List<SatzStueck> stuecke,
    double breite,
    TextScaler scaler,
    int zeilen,
  ) {
    final zustand = _zustand(stuecke, breite, scaler);
    final gesetzt = <_Gesetzt>[
      for (var i = 0; i < stuecke.length; i++)
        _aus(stuecke[i].text, zustand[i]),
    ];
    final maler = _maler(stuecke, gesetzt, breite, scaler);
    final enden = _zeilenEnden(maler);
    final metrik = maler.computeLineMetrics();
    maler.dispose();

    final anzahl = zeilen < metrik.length ? zeilen : metrik.length;
    var hoehe = 0.0;
    for (var z = 0; z < anzahl; z++) {
      hoehe += metrik[z].height;
    }
    if (enden.length <= zeilen) {
      return _Teilung(_spans(stuecke, gesetzt), const <SatzStueck>[], hoehe);
    }

    final schnitt = enden[zeilen - 1];
    final neben = <InlineSpan>[];
    final rest = <SatzStueck>[];
    var pos = 0;
    for (var i = 0; i < stuecke.length; i++) {
      final g = gesetzt[i];
      final laenge = g.text.length;
      if (pos + laenge <= schnitt) {
        neben.add(TextSpan(text: g.text, style: stuecke[i].stil));
      } else if (pos >= schnitt) {
        rest.add(stuecke[i]);
      } else {
        final innen = schnitt - pos;
        neben.add(
          TextSpan(text: g.text.substring(0, innen), style: stuecke[i].stil),
        );
        final ab = g.herkunft[innen];
        rest.add(SatzStueck(stuecke[i].text.substring(ab), stuecke[i].stil));
      }
      pos += laenge;
    }
    // Was unten weiterläuft, beginnt nicht mit einem Leerraum.
    while (rest.isNotEmpty && rest.first.text.trim().isEmpty) {
      rest.removeAt(0);
    }
    if (rest.isNotEmpty) {
      rest[0] = SatzStueck(rest[0].text.trimLeft(), rest[0].stil);
    }
    return _Teilung(neben, rest, hoehe);
  }

  static List<InlineSpan> _spans(
    List<SatzStueck> stuecke,
    List<_Gesetzt> gesetzt,
  ) => <InlineSpan>[
    for (var i = 0; i < stuecke.length; i++)
      TextSpan(text: gesetzt[i].text, style: stuecke[i].stil),
  ];

  /// Für jedes Stück: der Zustand jedes weichen Strichs darin.
  static List<List<int>> _zustand(
    List<SatzStueck> stuecke,
    double breite,
    TextScaler scaler,
  ) {
    final schluessel = StringBuffer('${breite.toStringAsFixed(1)}|')
      ..write(scaler.scale(100).toStringAsFixed(1));
    for (final s in stuecke) {
      schluessel
        ..write('\u0001')
        ..write(s.text)
        ..write(_ohneFarbe(s.stil).hashCode);
    }
    final key = schluessel.toString();
    final alt = _gemerkt[key];
    if (alt != null) return alt;

    final zustand = <List<int>>[
      for (final s in stuecke)
        List<int>.filled(
          Silbentrennung.weich.allMatches(s.text).length,
          _weich,
        ),
    ];
    for (var runde = 0; runde < _runden; runde++) {
      final gesetzt = <_Gesetzt>[
        for (var i = 0; i < stuecke.length; i++)
          _aus(stuecke[i].text, zustand[i]),
      ];
      final maler = _maler(stuecke, gesetzt, breite, scaler);
      final enden = _zeilenEnden(maler).toSet();
      maler.dispose();

      var geaendert = false;
      var pos = 0;
      for (var i = 0; i < stuecke.length; i++) {
        final g = gesetzt[i];
        for (var k = 0; k < g.striche.length; k++) {
          final stelle = g.striche[k];
          if (stelle < 0) continue;
          final amEnde = enden.contains(pos + stelle + 1);
          if (zustand[i][k] == _weich && amEnde) {
            zustand[i][k] = _strich;
            geaendert = true;
          } else if (zustand[i][k] == _strich && !amEnde) {
            zustand[i][k] = _ganz;
            geaendert = true;
          }
        }
        pos += g.text.length;
      }
      if (!geaendert) break;
    }
    if (_gemerkt.length > 400) _gemerkt.clear();
    _gemerkt[key] = zustand;
    return zustand;
  }

  static TextStyle _ohneFarbe(TextStyle stil) =>
      stil.copyWith(color: const Color(0xFF000000));

  static TextPainter _maler(
    List<SatzStueck> stuecke,
    List<_Gesetzt> gesetzt,
    double breite,
    TextScaler scaler,
  ) => TextPainter(
    text: TextSpan(
      children: <InlineSpan>[
        for (var i = 0; i < stuecke.length; i++)
          TextSpan(text: gesetzt[i].text, style: _ohneFarbe(stuecke[i].stil)),
      ],
    ),
    textAlign: TextAlign.justify,
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout(maxWidth: breite);

  /// Wo jede Zeile endet, als Stelle im gesetzten Text.
  static List<int> _zeilenEnden(TextPainter maler) {
    final laenge = maler.plainText.length;
    final enden = <int>[];
    var pos = 0;
    while (pos < laenge) {
      final zeile = maler.getLineBoundary(TextPosition(offset: pos));
      if (zeile.end <= pos) break;
      enden.add(zeile.end);
      pos = zeile.end;
    }
    return enden;
  }

  /// Ein Stück mit angewandtem Zustand: weich bleibt weich, ein Strich
  /// wird sichtbar, „ganz“ fällt weg.
  static _Gesetzt _aus(String text, List<int> zustand) {
    final out = StringBuffer();
    final herkunft = <int>[];
    final striche = <int>[];
    var k = 0;
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (c != Silbentrennung.weich) {
        herkunft.add(i);
        out.write(c);
        continue;
      }
      final z = k < zustand.length ? zustand[k] : _weich;
      k++;
      if (z == _ganz) {
        striche.add(-1);
        continue;
      }
      striche.add(herkunft.length);
      herkunft.add(i);
      out.write(z == _strich ? '-' : Silbentrennung.weich);
    }
    herkunft.add(text.length);
    return _Gesetzt(out.toString(), herkunft, striche);
  }
}

class _Gesetzt {
  const _Gesetzt(this.text, this.herkunft, this.striche);

  /// Der Text, wie er gezeichnet wird.
  final String text;

  /// Für jede Stelle in [text]: die Stelle im Original (eine mehr am Ende).
  final List<int> herkunft;

  /// Für jeden weichen Strich des Originals: seine Stelle in [text], oder
  /// -1, wenn er weggefallen ist.
  final List<int> striche;
}
