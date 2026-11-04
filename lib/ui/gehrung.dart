import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Welcher Rahmen — er sagt, wo man ist.
enum RahmenArt {
  /// Alltag: Holz mit Messingecken, Splittern, Astlöchern, Moos.
  holz,

  /// Theorie und Bibliothek: dazu Efeu, der aus einer Ecke wächst.
  ranken,

  /// Der Dungeon: dunkleres Holz, Eisen und Nieten.
  eisen,

  /// Belohnungen: Messing-Einlage innen und Ziernägel.
  messing,
}

/// **Der Holzrahmen auf Gehrung** — gemalt, nicht gedehnt.
///
/// Vier Leisten als Trapeze, die in den Ecken schräg auf 45° aneinander
/// stoßen, wie bei einem Bilderrahmen. Licht von oben links. Jeder
/// Bildpunkt wird für die jeweilige Größe ausgerechnet; die Details
/// (Splitter, Astlöcher, Moos, Ranken) setzt ein Zufall, dessen Startwert
/// aus der Größe kommt — jede Karte anders, aber bei jedem Bild gleich.
class GehrungsMaler extends CustomPainter {
  const GehrungsMaler({this.pixel = 1, this.mitte, this.art = RahmenArt.holz});

  /// Logische Punkte je Bildpunkt — 1 für Karten, 2 für Dialoge.
  final double pixel;

  /// Womit die Mitte gefüllt wird; null lässt sie frei.
  final Color? mitte;

  final RahmenArt art;

  /// Breite einer Leiste in Bildpunkten.
  static const int breite = 12;

  static const Color _k = Color(0xFF130505);
  static const Color _tief = Color(0xFF5D3A2B);
  static const Color _schatten = Color(0xFF894D2D);
  static const Color _holz = Color(0xFFA8602F);
  static const Color _licht = Color(0xFFC0803C);
  static const Color _glanz = Color(0xFFDDA05A);
  // Das dunklere Holz des Dungeons.
  static const Color _eTief = Color(0xFF2E211C);
  static const Color _eSchatten = Color(0xFF4A3329);
  static const Color _eHolz = Color(0xFF654332);
  static const Color _eLicht = Color(0xFF7D5640);
  static const Color _eGlanz = Color(0xFF94694D);
  // Messing.
  static const Color _mHell = Color(0xFFF3DC95);
  static const Color _mMitte = Color(0xFFC9A04A);
  static const Color _mTief = Color(0xFF6E5420);
  // Eisen.
  static const Color _iHell = Color(0xFFB9B6C0);
  static const Color _iMitte = Color(0xFF6E6A76);
  static const Color _iTief = Color(0xFF2E2A33);
  // Grün für Moos und Ranken.
  static const Color _gHell = Color(0xFF9AD25E);
  static const Color _gMitte = Color(0xFF4F9440);
  static const Color _gTief = Color(0xFF2C5A2A);

  /// Ausgerechnete Rahmen, je Größe, Art und Pixel — ein Rahmen wird bei
  /// jedem Bild der Karte neu gemalt (Abhaken animiert sie), ausgerechnet
  /// aber nur einmal. Höchstens [_merkGrenze] Einträge, die ältesten
  /// fliegen zuerst.
  static final Map<(double, double, double, RahmenArt), List<(Color, Path)>>
  _gemerkt = <(double, double, double, RahmenArt), List<(Color, Path)>>{};
  static const int _merkGrenze = 64;

  @override
  void paint(Canvas canvas, Size size) {
    final w = (size.width / pixel).round();
    final h = (size.height / pixel).round();
    if (w <= 2 * breite + 8 || h <= 2 * breite + 8) return;
    final pw = size.width / w;
    final ph = size.height / h;

    if (mitte case final m?) {
      canvas.drawRect(
        Rect.fromLTRB(
          breite * pw,
          breite * ph,
          size.width - breite * pw,
          size.height - breite * ph,
        ),
        Paint()..color = m,
      );
    }
    final schluessel = (size.width, size.height, pixel, art);
    final pfade = _gemerkt.remove(schluessel) ?? _rechne(w, h, pw, ph);
    _gemerkt[schluessel] = pfade;
    if (_gemerkt.length > _merkGrenze) _gemerkt.remove(_gemerkt.keys.first);

    final farbe = Paint()..isAntiAlias = false;
    for (final (c, p) in pfade) {
      canvas.drawPath(p, farbe..color = c);
    }
  }

  /// Wie viele Rahmen gerade ausgerechnet bereitliegen — für Tests.
  @visibleForTesting
  static int get gemerkt => _gemerkt.length;

  /// Alle Bildpunkte eines Rahmens der Größe [w] × [h]: erst das Holz,
  /// dann die Details der Art, zuletzt die Eckbeschläge obenauf.
  _Bild _bild(int w, int h) {
    final bild = _Bild(w, h);
    _holzMalen(bild);
    final zufall = math.Random(w * 7919 + h * 104729 + art.index * 31);
    if (art == RahmenArt.eisen) {
      _nieten(bild);
    } else {
      _splitter(bild, zufall);
      _aeste(bild, zufall);
      _moos(bild, zufall);
    }
    if (art == RahmenArt.messing) _einlage(bild);
    if (art == RahmenArt.ranken) _ranke(bild, zufall);
    _ecken(bild);
    return bild;
  }

  List<(Color, Path)> _rechne(int w, int h, double pw, double ph) {
    final bild = _bild(w, h);

    final pfade = <Color, Path>{};
    bild.jeder(
      (x, y, c) => (pfade[c] ??= Path()).addRect(
        Rect.fromLTWH(x * pw, y * ph, pw + 0.01, ph + 0.01),
      ),
    );
    return <(Color, Path)>[for (final e in pfade.entries) (e.key, e.value)];
  }

  /// Die Farbe des Bildpunkts [x], [y] in einem Rahmen der Größe [w] × [h]
  /// — null, wenn dort nichts liegt. Für Tests.
  @visibleForTesting
  Color? farbeBei(int w, int h, int x, int y) => _bild(w, h).bei(x, y);

  // ---- Grundholz ----------------------------------------------------------

  void _holzMalen(_Bild b) {
    final dunkel = art == RahmenArt.eisen;
    for (var y = 0; y < b.h; y++) {
      for (var x = 0; x < b.w; x++) {
        final l = x, r = b.w - 1 - x, o = y, u = b.h - 1 - y;
        final quer = math.min(math.min(l, r), math.min(o, u));
        if (quer >= breite) {
          if (x < b.w - breite) x = b.w - breite - 1;
          continue;
        }
        b.setze(x, y, _leiste(l, r, o, u, quer, dunkel));
      }
    }
  }

  Color _leiste(int l, int r, int o, int u, int quer, bool dunkel) {
    final String seite;
    final int laengs;
    if (o == quer && o <= l && o <= r) {
      seite = 'o';
      laengs = l;
    } else if (u == quer && u <= l && u <= r) {
      seite = 'u';
      laengs = l + 7;
    } else if (l == quer) {
      seite = 'l';
      laengs = o + 3;
    } else {
      seite = 'r';
      laengs = o + 11;
    }
    final hell = seite == 'o' || seite == 'l';
    final glanz = dunkel ? _eGlanz : _glanz;
    final licht = dunkel ? _eLicht : _licht;
    final holz = dunkel ? _eHolz : _holz;
    final schatten = dunkel ? _eSchatten : _schatten;
    final tief = dunkel ? _eTief : _tief;

    if (quer == 0 || quer == breite - 1) return _k;
    final ecke = math.min(l, r) < breite && math.min(o, u) < breite;
    if (ecke && math.min(l, r) == math.min(o, u)) return tief;
    if (quer == 1) return hell ? glanz : schatten;
    if (quer == breite - 2) return hell ? schatten : tief;

    final faser =
        math.sin(laengs * 0.23 + quer * 2.1) +
        math.sin(laengs * 0.071 + quer * 5.3);
    final grund = switch (seite) {
      'o' => licht,
      'l' => holz,
      _ => schatten,
    };
    if (faser > 1.15) return hell ? schatten : tief;
    if (faser < -1.45) return hell ? glanz : holz;
    return grund;
  }

  // ---- Details ------------------------------------------------------------

  /// Eine Stelle auf einer Leiste: Seite 0 oben, 1 rechts, 2 unten,
  /// 3 links; `laengs` ab der Ecke, `quer` von außen.
  (int, int) _auf(_Bild b, int seite, int laengs, int quer) => switch (seite) {
    0 => (laengs, quer),
    1 => (b.w - 1 - quer, laengs),
    2 => (laengs, b.h - 1 - quer),
    _ => (quer, laengs),
  };

  int _laenge(_Bild b, int seite) => seite.isEven ? b.w : b.h;

  /// Splitter an der Außenkante und kurze Risse ins Holz.
  void _splitter(_Bild b, math.Random z) {
    for (var i = 0; i < 3; i++) {
      final seite = z.nextInt(4);
      final a = breite + 6 + z.nextInt(_laenge(b, seite) - 2 * breite - 12);
      // Die Ecke fehlt: außen zwei Punkte, eine Reihe tiefer einer; die
      // neue Kante wird dunkel.
      for (final (dl, dq) in <(int, int)>[(0, 0), (1, 0), (0, 1)]) {
        final (x, y) = _auf(b, seite, a + dl, dq);
        b.loesche(x, y);
      }
      for (final (dl, dq) in <(int, int)>[(-1, 0), (2, 0), (1, 1), (0, 2)]) {
        final (x, y) = _auf(b, seite, a + dl, dq);
        b.setze(x, y, _k);
      }
      // Manchmal läuft ein Riss weiter ins Holz.
      if (z.nextBool()) {
        for (var q = 3; q < 6; q++) {
          final (x, y) = _auf(b, seite, a + (q - 3), q);
          b.setze(x, y, _tief);
        }
      }
    }
  }

  /// Ein oder zwei Astlöcher: dunkler Kern, ein Ring, Licht oben, und
  /// die Fasern weichen ihm aus.
  void _aeste(_Bild b, math.Random z) {
    for (var i = 0; i < 1 + z.nextInt(2); i++) {
      final seite = z.nextInt(4);
      final a = breite + 6 + z.nextInt(_laenge(b, seite) - 2 * breite - 14);
      for (final (dl, dq, c) in <(int, int, Color)>[
        // Ring
        (-1, 4, _schatten), (0, 3, _schatten), (1, 3, _schatten),
        (2, 4, _schatten), (2, 5, _schatten), (2, 6, _tief),
        (1, 7, _tief), (0, 7, _tief), (-1, 6, _tief), (-1, 5, _schatten),
        // Kern
        (0, 4, _tief), (1, 4, _tief), (0, 5, _k), (1, 5, _tief),
        (0, 6, _tief), (1, 6, _tief),
        // Licht oben am Rand
        (0, 2, _glanz), (1, 2, _glanz),
        // Fasern, die ausweichen
        (-3, 3, _schatten), (-2, 2, _schatten), (3, 2, _schatten),
        (4, 3, _schatten), (-3, 8, _schatten), (4, 8, _schatten),
      ]) {
        final (x, y) = _auf(b, seite, a + dl, dq);
        b.setze(x, y, c);
      }
    }
  }

  /// Moos in den unteren Ecken — wo sich Feuchtigkeit sammelt: dicht am
  /// Boden, dünner nach oben, ein Stück die Seitenleiste hoch.
  void _moos(_Bild b, math.Random z) {
    for (final links in <bool>[true, false]) {
      for (var i = 0; i < 26; i++) {
        final dx = z.nextInt(14);
        final dy = z.nextInt(9);
        // Je weiter von der Ecke, desto seltener.
        if (dx + 2 * dy > 14 || z.nextDouble() < (dx + dy) / 22) continue;
        // Neben dem Eckbeschlag, sonst läge es darunter.
        final x = links ? breite + dx : b.w - 1 - breite - dx;
        final y = b.h - 2 - dy;
        final c = dy == 0
            ? _gTief
            : z.nextInt(3) == 0
            ? _gHell
            : _gMitte;
        b.setze(x, y, c);
      }
    }
  }

  /// Efeu wächst aus der Ecke oben links an beiden Leisten entlang: ein
  /// Stängel in langen Bögen, Blätter abwechselnd zu beiden Seiten.
  void _ranke(_Bild b, math.Random z) {
    for (final seite in <int>[0, 3]) {
      final lang = (_laenge(b, seite) * 0.5).round();
      int? vorher;
      for (var a = 6; a < lang; a++) {
        final q = (5.5 + 2.2 * math.sin(a * 0.13 + seite)).round();
        // Lückenlos: springt der Bogen, füllt ein Punkt die Stufe.
        if (vorher != null && vorher != q) {
          final (fx, fy) = _auf(b, seite, a, vorher);
          b.setze(fx, fy, _gTief);
        }
        vorher = q;
        final (x, y) = _auf(b, seite, a, q);
        b.setze(x, y, _gTief);
        if (a % 9 != 4) continue;
        // Ein Blatt, drei Grüntöne, zur Seite geneigt.
        final r = (a ~/ 9).isEven ? 1 : -1;
        for (final (dl, dq, c) in <(int, int, Color)>[
          (0, r, _gMitte),
          (1, r, _gMitte),
          (2, r, _gTief),
          (0, 2 * r, _gHell),
          (1, 2 * r, _gMitte),
          (2, 2 * r, _gMitte),
          (1, 3 * r, _gHell),
          (-1, r, _gTief),
        ]) {
          final (bx, by) = _auf(b, seite, a + dl, q + dq);
          if (q + dq >= 1 && q + dq <= breite - 2) b.setze(bx, by, c);
        }
      }
    }
  }

  /// Eine Messing-Einlage innen, entlang der ganzen Kante.
  void _einlage(_Bild b) {
    for (var x = breite - 3; x <= b.w - breite + 2; x++) {
      b.setze(x, breite - 3, _mMitte);
      b.setze(x, b.h - breite + 2, _mTief);
    }
    for (var y = breite - 3; y <= b.h - breite + 2; y++) {
      b.setze(breite - 3, y, _mHell);
      b.setze(b.w - breite + 2, y, _mTief);
    }
    // Ziernägel, etwa alle 40 Bildpunkte.
    for (var seite = 0; seite < 4; seite++) {
      final lang = _laenge(b, seite);
      final n = math.max(1, (lang - 2 * breite) ~/ 40);
      for (var i = 1; i <= n; i++) {
        final a = breite + (lang - 2 * breite) * i ~/ (n + 1);
        _knopf(b, seite, a, 5, _mHell, _mMitte, _mTief);
      }
    }
  }

  /// Nieten entlang jeder Leiste, etwa alle 24 Bildpunkte.
  void _nieten(_Bild b) {
    for (var seite = 0; seite < 4; seite++) {
      final lang = _laenge(b, seite);
      final n = math.max(1, (lang - 2 * breite) ~/ 24);
      for (var i = 1; i <= n; i++) {
        final a = breite + (lang - 2 * breite) * i ~/ (n + 1);
        _knopf(b, seite, a, 5, _iHell, _iMitte, _iTief);
      }
    }
  }

  void _knopf(
    _Bild b,
    int seite,
    int a,
    int q,
    Color hell,
    Color mitte,
    Color tief,
  ) {
    for (final (dl, dq, c) in <(int, int, Color)>[
      (0, 0, hell),
      (1, 0, mitte),
      (0, 1, mitte),
      (1, 1, tief),
    ]) {
      final (x, y) = _auf(b, seite, a + dl, q + dq);
      b.setze(x, y, c);
    }
  }

  /// Die Ecken: ein L-förmiger Beschlag über der Fuge, mit zwei Nieten —
  /// Messing, im Dungeon Eisen.
  void _ecken(_Bild b) {
    final eisen = art == RahmenArt.eisen;
    final hell = eisen ? _iHell : _mHell;
    final mitte = eisen ? _iMitte : _mMitte;
    final tief = eisen ? _iTief : _mTief;
    // Das L in der Ecke oben links, für die anderen gespiegelt.
    const arm = 11, dick = 4;
    for (final (sx, sy) in <(bool, bool)>[
      (false, false),
      (true, false),
      (false, true),
      (true, true),
    ]) {
      int px(int x) => sx ? b.w - 1 - x : x;
      int py(int y) => sy ? b.h - 1 - y : y;
      for (var y = 0; y <= arm; y++) {
        for (var x = 0; x <= arm; x++) {
          final imL = (y <= dick && x <= arm) || (x <= dick && y <= arm);
          if (!imL) continue;
          final rand =
              x == 0 ||
              y == 0 ||
              x == arm ||
              y == arm ||
              (x > dick && y == dick) ||
              (y > dick && x == dick);
          final c = rand
              ? _k
              : (x == 1 || y == 1)
              ? hell
              : (x == dick - 1 || y == dick - 1)
              ? tief
              : mitte;
          b.setze(px(x), py(y), c);
        }
      }
      // Zwei Nieten, eine je Arm.
      for (final (nx, ny) in <(int, int)>[(8, 2), (2, 8)]) {
        b.setze(px(nx), py(ny), hell);
        b.setze(px(nx + 1), py(ny), tief);
        b.setze(px(nx), py(ny + 1), tief);
      }
    }
  }

  @override
  bool shouldRepaint(GehrungsMaler alt) =>
      alt.pixel != pixel || alt.mitte != mitte || alt.art != art;
}

/// Die Bildpunkte des Rahmens, bevor sie gemalt werden.
class _Bild {
  _Bild(this.w, this.h) : _p = List<Color?>.filled(w * h, null);

  final int w, h;
  final List<Color?> _p;

  void setze(int x, int y, Color c) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    _p[y * w + x] = c;
  }

  void loesche(int x, int y) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    _p[y * w + x] = null;
  }

  Color? bei(int x, int y) => _p[y * w + x];

  void jeder(void Function(int x, int y, Color c) tu) {
    for (var i = 0; i < _p.length; i++) {
      final c = _p[i];
      if (c != null) tu(i % w, i ~/ w, c);
    }
  }
}

/// **Welcher Rahmen hier gilt** — ein Bildschirm legt ihn einmal um sich,
/// jede [HolzKarte] darin fragt hier nach. Ohne gilt [RahmenArt.holz].
///
/// Ein Dialog liegt in einer eigenen Route und erbt ihn nicht; dort sagt
/// `HolzDialog(art: …)`, welcher Rahmen gilt.
class RahmenOrt extends InheritedWidget {
  const RahmenOrt({required this.art, required super.child, super.key});

  final RahmenArt art;

  static RahmenArt of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RahmenOrt>()?.art ??
      RahmenArt.holz;

  @override
  bool updateShouldNotify(RahmenOrt alt) => alt.art != art;
}
