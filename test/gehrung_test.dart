import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/ui/gehrung.dart';
import 'package:lifes_game/ui/holz.dart';

/// Der Holzrahmen auf Gehrung (ADR-0099): gemalt, nicht gedehnt, in vier
/// Arten.
void main() {
  const w = 180, h = 90;
  const b = GehrungsMaler.breite;

  Set<Color> farbenIn(GehrungsMaler m, {int? bisZeile, int? abZeile}) => {
    for (var y = abZeile ?? 0; y < (bisZeile ?? h); y++)
      for (var x = 0; x < w; x++) ?m.farbeBei(w, h, x, y),
  };

  test('die Mitte bleibt frei, der Rand ist ringsum dunkel', () {
    const m = GehrungsMaler();
    expect(m.farbeBei(w, h, w ~/ 2, h ~/ 2), isNull);
    expect(m.farbeBei(w, h, b, b), isNull);
    // Die Außenkante mitten auf der linken und rechten Leiste: dunkel —
    // oder leer, falls dort zufällig ein Splitter sitzt.
    for (final (x, y) in <(int, int)>[(0, h ~/ 2), (w - 1, h ~/ 2)]) {
      expect(m.farbeBei(w, h, x, y), anyOf(isNull, const Color(0xFF130505)));
    }
  });

  test('jede Ecke trägt einen Beschlag — Messing, im Dungeon Eisen', () {
    const messingHell = Color(0xFFF3DC95);
    const eisenHell = Color(0xFFB9B6C0);
    for (final (x, y) in <(int, int)>[
      (1, 1),
      (w - 2, 1),
      (1, h - 2),
      (w - 2, h - 2),
    ]) {
      expect(const GehrungsMaler().farbeBei(w, h, x, y), messingHell);
      expect(
        const GehrungsMaler(art: RahmenArt.eisen).farbeBei(w, h, x, y),
        eisenHell,
      );
    }
  });

  test('derselbe Rahmen sieht bei jedem Bild gleich aus', () {
    const m = GehrungsMaler(art: RahmenArt.ranken);
    for (var y = 0; y < h; y += 3) {
      for (var x = 0; x < w; x += 3) {
        expect(m.farbeBei(w, h, x, y), m.farbeBei(w, h, x, y));
      }
    }
  });

  test('zwei Größen haben ihre Splitter an verschiedenen Stellen', () {
    const m = GehrungsMaler();
    // Eine Lücke in der Außenkante ist ein Splitter. Gesucht wird ringsum,
    // je Seite vom Eckbeschlag an gezählt.
    List<String> luecken(int breite) => <String>[
      for (var x = b; x < breite - b; x++) ...<String>[
        if (m.farbeBei(breite, h, x, 0) == null) 'oben $x',
        if (m.farbeBei(breite, h, x, h - 1) == null) 'unten $x',
      ],
      for (var y = b; y < h - b; y++) ...<String>[
        if (m.farbeBei(breite, h, 0, y) == null) 'links $y',
        if (m.farbeBei(breite, h, breite - 1, y) == null) 'rechts $y',
      ],
    ];
    final a = luecken(180), c = luecken(181);
    expect(a, isNotEmpty, reason: 'drei Splitter je Rahmen');
    expect(c, isNotEmpty);
    // Dass sie je Größe woanders liegen, prüft, dass der Zufall die Größe
    // kennt.
    expect(a, isNot(equals(c)));
  });

  test('Ranken nur bei Ranken, kein Grün im Dungeon', () {
    final gruen = <Color>{
      const Color(0xFF9AD25E),
      const Color(0xFF4F9440),
      const Color(0xFF2C5A2A),
    };
    // Oben links wächst die Ranke; Moos sitzt nur unten.
    final obenRanken = farbenIn(
      const GehrungsMaler(art: RahmenArt.ranken),
      bisZeile: b,
    );
    final obenHolz = farbenIn(const GehrungsMaler(), bisZeile: b);
    expect(obenRanken.intersection(gruen), isNotEmpty);
    expect(obenHolz.intersection(gruen), isEmpty);
    expect(
      farbenIn(const GehrungsMaler(art: RahmenArt.eisen)).intersection(gruen),
      isEmpty,
    );
  });

  test('Messing trägt eine Einlage innen', () {
    const einlage = Color(0xFFC9A04A);
    final messing = const GehrungsMaler(art: RahmenArt.messing);
    expect(messing.farbeBei(w, h, w ~/ 2, b - 3), einlage);
    expect(const GehrungsMaler().farbeBei(w, h, w ~/ 2, b - 3), isNot(einlage));
  });

  test('zu klein für einen Rahmen: malt nichts und wirft nicht', () {
    final recorder = ui.PictureRecorder();
    const GehrungsMaler().paint(Canvas(recorder), const Size(20, 20));
    recorder.endRecording().dispose();
  });

  test('ausgerechnet wird je Größe einmal, und nie mehr als 64 bleiben', () {
    for (var i = 0; i < 100; i++) {
      final recorder = ui.PictureRecorder();
      const GehrungsMaler().paint(Canvas(recorder), Size(100.0 + i, 80));
      recorder.endRecording().dispose();
    }
    expect(GehrungsMaler.gemerkt, lessThanOrEqualTo(64));
  });

  testWidgets('eine Karte nimmt den Rahmen ihres Bildschirms', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RahmenOrt(
          art: RahmenArt.ranken,
          child: Column(
            children: <Widget>[
              HolzKarte(key: ValueKey<String>('erbt'), child: Text('a')),
              HolzKarte(
                key: ValueKey<String>('eigen'),
                art: RahmenArt.messing,
                child: Text('b'),
              ),
            ],
          ),
        ),
      ),
    );

    RahmenArt artVon(String key) {
      final paint = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byKey(ValueKey<String>(key)),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      return (paint.painter! as GehrungsMaler).art;
    }

    expect(artVon('erbt'), RahmenArt.ranken);
    expect(artVon('eigen'), RahmenArt.messing);
  });

  testWidgets('ohne Ort ist es Holz', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HolzKarte(child: Text('a'))),
    );
    final paint = tester.widget<CustomPaint>(
      find
          .descendant(
            of: find.byType(HolzKarte),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    expect((paint.painter! as GehrungsMaler).art, RahmenArt.holz);
  });
}
