// Zeichnet die einfachen Bilder der verdienten Ausruestung (ADR-0034) --
// zwei epische und ein legendaeres Stueck je Platz -- und legt sie als PNG
// unter `assets/` ab.
//
// **Die Bilder sind Code, keine Dateien.** Jedes Stueck ist ein paar
// Rechtecke, Linien und Scheiben auf einem 32 x 32 Raster, mit einer
// dunklen Kontur drumherum. Wer eines aendern will, aendert die Form hier
// und laesst das Werkzeug laufen -- statt in einem Malprogramm Pixel zu
// setzen und die Datei zu ersetzen.
//
// **32 statt 64.** Frederiks Zeichnungen sind auf 64 x 64 gemalt; diese
// hier sind bewusst groeber -- "ganz simpel", so war es gewuenscht. Abgelegt
// werden sie trotzdem als 256 x 256, wie alles andere (`PixelArt`): Ein
// gezeichneter Bildpunkt wird zu 8 x 8 echten, und die Kachel skaliert sie
// hart, sobald sie 64 Punkte breit ist.
//
// Reines Dart, kein Flutter: laeuft in einer Sekunde ohne Emulator.
//
//     dart run tool/gear_icons_gen.dart

import 'dart:io';
import 'dart:typed_data';

/// Kantenlaenge der Zeichnung in Bildpunkten.
const int art = 32;

/// Kantenlaenge der abgelegten Datei -- dieselbe wie `PixelArt.assetSize`.
const int asset = 256;

// --- Farben (ARGB) ----------------------------------------------------

const int kontur = 0xFF1A1208;
const int stahl = 0xFFB8BCC4;
const int stahlDunkel = 0xFF7E838C;
const int holz = 0xFF7A4A22;
const int leder = 0xFF5A3A1E;
const int lederHell = 0xFF8A5A2E;

/// Episch: Lila, wie die Marke im Laden.
const int lila = 0xFF7B3FB0;
const int lilaHell = 0xFFB07FE0;
const int lilaDunkel = 0xFF4E2472;

/// Legendaer: Gold.
const int gold = 0xFFE0B040;
const int goldHell = 0xFFF6DC8A;
const int goldDunkel = 0xFF9A7020;

const int glut = 0xFFE05020;
const int glutHell = 0xFFFFA040;
const int eis = 0xFF9AD8F0;
const int weiss = 0xFFF4F0E8;
const int schuppe = 0xFF3E7A5A;
const int schuppeHell = 0xFF6AB08A;
const int rot = 0xFFB0202A;

// --- Die Zeichenflaeche -----------------------------------------------

class Leinwand {
  final List<int> _px = List<int>.filled(art * art, 0);

  int at(int x, int y) =>
      (x < 0 || y < 0 || x >= art || y >= art) ? 0 : _px[y * art + x];

  void set(int x, int y, int farbe) {
    if (x < 0 || y < 0 || x >= art || y >= art) return;
    _px[y * art + x] = farbe;
  }

  /// Gefuelltes Rechteck von (x0,y0) bis einschliesslich (x1,y1).
  void rect(int x0, int y0, int x1, int y1, int farbe) {
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        set(x, y, farbe);
      }
    }
  }

  /// Gefuellte Scheibe um (cx,cy).
  void disc(int cx, int cy, int r, int farbe) {
    for (var y = -r; y <= r; y++) {
      for (var x = -r; x <= r; x++) {
        if (x * x + y * y <= r * r + r ~/ 2) set(cx + x, cy + y, farbe);
      }
    }
  }

  /// Ring um (cx,cy), von Radius [innen] bis [aussen].
  void ring(int cx, int cy, int innen, int aussen, int farbe) {
    for (var y = -aussen; y <= aussen; y++) {
      for (var x = -aussen; x <= aussen; x++) {
        final d = x * x + y * y;
        if (d <= aussen * aussen + aussen ~/ 2 && d > innen * innen) {
          set(cx + x, cy + y, farbe);
        }
      }
    }
  }

  /// Linie mit [dicke] Bildpunkten Breite.
  void line(int x0, int y0, int x1, int y1, int farbe, {int dicke = 1}) {
    final dx = (x1 - x0).abs();
    final dy = (y1 - y0).abs();
    final schritte = dx > dy ? dx : dy;
    for (var i = 0; i <= schritte; i++) {
      final t = schritte == 0 ? 0.0 : i / schritte;
      final x = (x0 + (x1 - x0) * t).round();
      final y = (y0 + (y1 - y0) * t).round();
      for (var ox = 0; ox < dicke; ox++) {
        for (var oy = 0; oy < dicke; oy++) {
          set(x + ox, y + oy, farbe);
        }
      }
    }
  }

  /// Gleichschenkliges Dreieck mit Spitze oben bei (cx, top) und Basis
  /// in Zeile [bottom] von [halbeBreite] je Seite.
  void spitze(int cx, int top, int bottom, int halbeBreite, int farbe) {
    final hoehe = bottom - top;
    for (var y = top; y <= bottom; y++) {
      final t = hoehe == 0 ? 1.0 : (y - top) / hoehe;
      final hb = (halbeBreite * t).round();
      rect(cx - hb, y, cx + hb, y, farbe);
    }
  }

  /// Dasselbe mit der Spitze unten: Basis in Zeile [top], Spitze bei
  /// (cx, bottom).
  void keil(int cx, int top, int bottom, int halbeBreite, int farbe) {
    final hoehe = bottom - top;
    for (var y = top; y <= bottom; y++) {
      final t = hoehe == 0 ? 0.0 : (y - top) / hoehe;
      final hb = (halbeBreite * (1 - t)).round();
      rect(cx - hb, y, cx + hb, y, farbe);
    }
  }

  /// Zieht eine dunkle Kontur um alles, was gezeichnet ist. Das ist der
  /// ganze "Pixel-Look": Ohne sie sind es bunte Flaechen, mit ihr Figuren.
  void kontur_() {
    final alt = List<int>.from(_px);
    for (var y = 0; y < art; y++) {
      for (var x = 0; x < art; x++) {
        if (alt[y * art + x] != 0) continue;
        final nachbar = [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)].any((
          p,
        ) {
          final (nx, ny) = p;
          if (nx < 0 || ny < 0 || nx >= art || ny >= art) return false;
          return alt[ny * art + nx] != 0;
        });
        if (nachbar) _px[y * art + x] = kontur;
      }
    }
  }

  /// Ein Glanzpunkt: eine helle Stelle oben links auf einer Flaeche.
  void glanz(int x, int y, int farbe) {
    set(x, y, farbe);
    set(x + 1, y, farbe);
    set(x, y + 1, farbe);
  }
}

// --- Die Stuecke ------------------------------------------------------

typedef Zeichnung = void Function(Leinwand l);

/// Ein aufrechtes Schwert: Klinge, Parierstange, Griff, Knauf.
void schwert(
  Leinwand l, {
  required int klinge,
  required int klingeSchatten,
  required int stange,
  int breite = 2,
}) {
  final cx = 16;
  l.rect(cx - breite, 4, cx + breite - 1, 20, klinge);
  l.rect(cx, 4, cx + breite - 1, 20, klingeSchatten);
  l.spitze(cx, 1, 4, breite, klinge);
  l.rect(cx - 6, 21, cx + 5, 22, stange);
  l.rect(cx - 1, 23, cx, 28, leder);
  l.rect(cx - 2, 29, cx + 1, 30, stange);
}

void zweihaender(Leinwand l) {
  schwert(
    l,
    klinge: stahl,
    klingeSchatten: stahlDunkel,
    stange: lila,
    breite: 3,
  );
  // Eine Blutrinne: die Linie, die einen Zweihaender vom Schwert trennt.
  l.rect(16, 6, 16, 18, stahlDunkel);
  l.glanz(13, 6, weiss);
}

void sonnenklinge(Leinwand l) {
  schwert(l, klinge: goldHell, klingeSchatten: gold, stange: goldDunkel);
  // Die Sonne sitzt auf der Parierstange.
  l.disc(16, 22, 3, glutHell);
  l.set(16, 22, weiss);
  l.glanz(14, 5, weiss);
}

void langbogen(Leinwand l) {
  // Der Bogen als Bogen: von oben nach unten gebogen, die Sehne gerade.
  for (var y = 2; y <= 29; y++) {
    final t = (y - 2) / 27;
    final x = 11 + (8 * (1 - (2 * t - 1) * (2 * t - 1))).round();
    l.set(x, y, holz);
    l.set(x + 1, y, lederHell);
  }
  l.line(10, 2, 10, 29, weiss);
  // Griffwicklung in der Mitte.
  l.rect(18, 13, 20, 18, lila);
  // Ein Pfeil auf der Sehne.
  l.line(3, 15, 17, 15, holz);
  l.spitze(2, 14, 16, 1, stahl);
  l.rect(4, 14, 5, 16, lilaHell);
}

/// Ein Brustpanzer: Schultern, Rumpf, Taille.
void panzer(
  Leinwand l, {
  required int flaeche,
  required int schatten,
  required int schulter,
}) {
  l.rect(4, 6, 9, 10, schulter);
  l.rect(22, 6, 27, 10, schulter);
  l.rect(8, 5, 23, 24, flaeche);
  l.rect(10, 25, 21, 28, flaeche);
  l.rect(16, 5, 23, 28, schatten);
  l.rect(13, 3, 18, 5, kontur);
  l.rect(15, 6, 16, 28, schatten);
}

void drachenschuppenpanzer(Leinwand l) {
  panzer(l, flaeche: schuppe, schatten: schuppeHell, schulter: lila);
  // Schuppen: ein Muster aus Halbkreisen, das die Flaeche als Haut liest.
  for (var y = 8; y <= 26; y += 4) {
    for (var x = 9; x <= 22; x += 4) {
      final versatz = ((y - 8) ~/ 4).isEven ? 0 : 2;
      l.set(x + versatz, y, schuppeHell);
      l.set(x + versatz + 1, y, schuppeHell);
      l.set(x + versatz, y + 1, kontur);
      l.set(x + versatz + 1, y + 1, kontur);
    }
  }
}

void runenharnisch(Leinwand l) {
  panzer(l, flaeche: stahl, schatten: stahlDunkel, schulter: lilaDunkel);
  // Eine Rune auf der Brust.
  l.rect(15, 10, 16, 20, lilaHell);
  l.rect(12, 12, 19, 13, lilaHell);
  l.rect(13, 17, 18, 18, lilaHell);
}

void titanenpanzer(Leinwand l) {
  panzer(l, flaeche: gold, schatten: goldDunkel, schulter: goldHell);
  l.rect(3, 5, 10, 11, goldHell);
  l.rect(21, 5, 28, 11, goldHell);
  l.rect(14, 12, 17, 15, rot);
  l.glanz(9, 7, weiss);
}

/// Ein Helm: Kuppel und Sehschlitz.
void helm(Leinwand l, {required int flaeche, required int schatten}) {
  l.disc(16, 15, 10, flaeche);
  l.rect(6, 15, 25, 24, flaeche);
  l.rect(17, 6, 25, 24, schatten);
  l.rect(8, 16, 23, 17, kontur);
  l.rect(15, 18, 16, 24, schatten);
}

void drachenhelm(Leinwand l) {
  helm(l, flaeche: lila, schatten: lilaDunkel);
  // Zwei Hoerner.
  l.line(7, 8, 3, 2, lilaHell, dicke: 2);
  l.line(24, 8, 28, 2, lilaHell, dicke: 2);
  l.glanz(10, 8, lilaHell);
}

void runenkrone(Leinwand l) {
  helm(l, flaeche: stahl, schatten: stahlDunkel);
  // Zacken oben, mit Runenlicht.
  for (final x in <int>[8, 13, 18, 23]) {
    l.spitze(x, 2, 6, 1, lilaHell);
  }
  l.rect(14, 10, 17, 13, lilaHell);
}

void kroneDesHochwaechters(Leinwand l) {
  helm(l, flaeche: gold, schatten: goldDunkel);
  for (final x in <int>[7, 12, 16, 20, 25]) {
    l.spitze(x, 1, 6, 1, goldHell);
  }
  l.disc(16, 11, 2, rot);
  l.glanz(9, 9, goldHell);
}

/// Ein Stiefel: Schaft und Fuss, von der Seite.
void stiefel(Leinwand l, {required int flaeche, required int schatten}) {
  l.rect(9, 4, 17, 22, flaeche);
  l.rect(9, 20, 27, 28, flaeche);
  l.rect(14, 4, 17, 22, schatten);
  l.rect(9, 27, 27, 28, kontur);
  l.rect(9, 8, 17, 9, schatten);
}

void windlaeufer(Leinwand l) {
  stiefel(l, flaeche: leder, schatten: lederHell);
  // Ein Fluegel am Knoechel.
  l.line(19, 18, 28, 10, lilaHell, dicke: 2);
  l.line(19, 20, 27, 14, lilaHell, dicke: 2);
  l.line(19, 22, 25, 18, lilaHell, dicke: 2);
}

void drachenschuppenstiefel(Leinwand l) {
  stiefel(l, flaeche: schuppe, schatten: schuppeHell);
  for (var y = 10; y <= 24; y += 4) {
    for (var x = 10; x <= 24; x += 4) {
      if (y < 20 && x > 16) continue;
      l.set(x, y, schuppeHell);
      l.set(x + 1, y, schuppeHell);
      l.set(x, y + 1, kontur);
    }
  }
  l.rect(9, 20, 27, 21, lila);
}

void stiefelDesTitanen(Leinwand l) {
  stiefel(l, flaeche: gold, schatten: goldDunkel);
  l.rect(9, 4, 17, 6, goldHell);
  l.rect(9, 19, 27, 20, goldHell);
  l.glanz(10, 11, goldHell);
}

/// Ein Ring mit Stein oben.
void ringMitStein(
  Leinwand l, {
  required int band,
  required int bandSchatten,
  required int stein,
  required int steinHell,
}) {
  l.ring(16, 18, 6, 9, band);
  for (var y = 9; y <= 27; y++) {
    for (var x = 16; x <= 25; x++) {
      if (l.at(x, y) == band) l.set(x, y, bandSchatten);
    }
  }
  l.disc(16, 8, 4, stein);
  l.glanz(14, 6, steinHell);
}

void sternenring(Leinwand l) {
  ringMitStein(
    l,
    band: stahl,
    bandSchatten: stahlDunkel,
    stein: eis,
    steinHell: weiss,
  );
  // Vier Funken um den Stein.
  l.set(16, 2, weiss);
  l.set(10, 8, weiss);
  l.set(22, 8, weiss);
  l.set(16, 14, lilaHell);
}

void ringDerGlut(Leinwand l) {
  ringMitStein(
    l,
    band: goldDunkel,
    bandSchatten: leder,
    stein: glut,
    steinHell: glutHell,
  );
  l.set(16, 8, glutHell);
}

void ringDesErzdaemons(Leinwand l) {
  ringMitStein(
    l,
    band: gold,
    bandSchatten: goldDunkel,
    stein: rot,
    steinHell: glut,
  );
  // Zwei kleine Hoerner am Stein.
  l.line(12, 6, 10, 2, goldHell, dicke: 1);
  l.line(20, 6, 22, 2, goldHell, dicke: 1);
}

/// Ein Anhaenger an einer Kette.
void kette(Leinwand l, int farbe) {
  l.line(16, 1, 8, 9, farbe);
  l.line(16, 1, 24, 9, farbe);
}

void phoenixfeder(Leinwand l) {
  kette(l, goldDunkel);
  // Eine Feder: Kiel und Fahne, von oben nach unten schmaler.
  l.line(16, 9, 16, 29, goldDunkel);
  for (var y = 10; y <= 27; y++) {
    final t = (y - 10) / 17;
    final hb = (5 * (1 - t) + 1).round();
    final farbe = y < 16 ? glutHell : (y < 22 ? glut : rot);
    l.rect(16 - hb, y, 16 + hb, y, farbe);
  }
  l.line(16, 9, 16, 29, goldDunkel);
  l.set(16, 29, lila);
}

void drachenzahn(Leinwand l) {
  kette(l, leder);
  // Ein gebogener Zahn an einer Lederschnur.
  l.rect(12, 9, 20, 11, leder);
  l.keil(16, 12, 29, 4, weiss);
  for (var y = 13; y <= 25; y++) {
    l.set(17, y, eis);
  }
  l.rect(12, 11, 20, 12, lila);
}

void herzDesTitanen(Leinwand l) {
  kette(l, goldDunkel);
  l.disc(12, 13, 5, gold);
  l.disc(20, 13, 5, gold);
  l.keil(16, 14, 30, 9, gold);
  l.rect(7, 13, 25, 15, gold);
  // Die rechte Haelfte im Schatten, ein Glanz links.
  for (var y = 8; y <= 30; y++) {
    for (var x = 17; x <= 26; x++) {
      if (l.at(x, y) == gold) l.set(x, y, goldDunkel);
    }
  }
  l.glanz(10, 11, goldHell);
}

/// Was gezeichnet wird und wohin es kommt. Der Pfad ist derselbe, der in
/// `GearIcons` steht -- nach Art sortiert, nicht nach Id.
const Map<String, Zeichnung> stuecke = <String, Zeichnung>{
  'assets/Waffen/Schwerter/Zweihaender.png': zweihaender,
  'assets/Waffen/Boegen/Langbogen.png': langbogen,
  'assets/Waffen/Schwerter/Sonnenklinge.png': sonnenklinge,
  'assets/Ruestung/Drachenschuppenpanzer.png': drachenschuppenpanzer,
  'assets/Ruestung/Runenharnisch.png': runenharnisch,
  'assets/Ruestung/Titanenpanzer.png': titanenpanzer,
  'assets/Helme/Drachenhelm.png': drachenhelm,
  'assets/Helme/Runenkrone.png': runenkrone,
  'assets/Helme/KroneDesHochwaechters.png': kroneDesHochwaechters,
  'assets/Schuhe/Windlaeufer.png': windlaeufer,
  'assets/Schuhe/Drachenschuppenstiefel.png': drachenschuppenstiefel,
  'assets/Schuhe/StiefelDesTitanen.png': stiefelDesTitanen,
  'assets/Ringe/Sternenring.png': sternenring,
  'assets/Ringe/RingDerGlut.png': ringDerGlut,
  'assets/Ringe/RingDesErzdaemons.png': ringDesErzdaemons,
  'assets/Talismane/Phoenixfeder.png': phoenixfeder,
  'assets/Talismane/Drachenzahn.png': drachenzahn,
  'assets/Talismane/HerzDesTitanen.png': herzDesTitanen,
};

void main(List<String> args) {
  // `--vorschau <datei>` schreibt zusaetzlich alle Bilder nebeneinander
  // auf einen Bogen -- zum Ansehen, nicht fuer die App.
  final vorschauIndex = args.indexOf('--vorschau');
  if (vorschauIndex >= 0 && vorschauIndex + 1 < args.length) {
    File(args[vorschauIndex + 1]).writeAsBytesSync(vorschau());
  }

  for (final eintrag in stuecke.entries) {
    final l = Leinwand();
    eintrag.value(l);
    l.kontur_();
    final datei = File(eintrag.key);
    datei.parent.createSync(recursive: true);
    datei.writeAsBytesSync(png(l));
    stdout.writeln(eintrag.key);
  }
  stdout.writeln('${stuecke.length} Bilder, $art x $art auf $asset x $asset.');
}

/// Alle Stuecke auf einem Bogen, sechs je Zeile, mit dunklem Grund.
Uint8List vorschau() {
  const proZeile = 6;
  const rand = 2;
  const zelle = art + rand * 2;
  final zeilen = (stuecke.length + proZeile - 1) ~/ proZeile;
  final breite = proZeile * zelle;
  final hoehe = zeilen * zelle;
  final px = List<int>.filled(breite * hoehe, 0xFF2A2218);

  var i = 0;
  for (final zeichnung in stuecke.values) {
    final l = Leinwand();
    zeichnung(l);
    l.kontur_();
    final ox = (i % proZeile) * zelle + rand;
    final oy = (i ~/ proZeile) * zelle + rand;
    for (var y = 0; y < art; y++) {
      for (var x = 0; x < art; x++) {
        final c = l.at(x, y);
        if (c != 0) px[(oy + y) * breite + ox + x] = c;
      }
    }
    i++;
  }
  return pngRoh(px, breite, hoehe, 4);
}

// --- PNG ---------------------------------------------------------------
//
// Ein eigener Schreiber statt eines Pakets: Das Werkzeug soll ohne
// `pub add` laufen, und ein PNG mit einer einzigen Bildart braucht nur
// vier Bloecke und eine Pruefsumme.

Uint8List png(Leinwand l) {
  return pngRoh(l._px, art, art, asset ~/ art);
}

/// Schreibt ein Raster aus ARGB-Werten als PNG, jeden Bildpunkt
/// [faktor]-fach vergroessert.
Uint8List pngRoh(List<int> px, int breite, int hoehe, int faktor) {
  final b = breite * faktor;
  final h = hoehe * faktor;
  final zeilen = BytesBuilder();
  for (var y = 0; y < h; y++) {
    zeilen.addByte(0); // Filter: keiner.
    for (var x = 0; x < b; x++) {
      final argb = px[(y ~/ faktor) * breite + x ~/ faktor];
      zeilen.addByte((argb >> 16) & 0xFF);
      zeilen.addByte((argb >> 8) & 0xFF);
      zeilen.addByte(argb & 0xFF);
      zeilen.addByte((argb >> 24) & 0xFF);
    }
  }
  final daten = ZLibEncoder(level: 9).convert(zeilen.toBytes());

  final ihdr = BytesBuilder()
    ..add(_be32(b))
    ..add(_be32(h))
    ..addByte(8) // Bittiefe
    ..addByte(6) // RGBA
    ..addByte(0)
    ..addByte(0)
    ..addByte(0);

  final out = BytesBuilder()
    ..add(const <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    ..add(_block('IHDR', ihdr.toBytes()))
    ..add(_block('IDAT', daten))
    ..add(_block('IEND', const <int>[]));
  return out.toBytes();
}

List<int> _block(String typ, List<int> inhalt) {
  final typBytes = typ.codeUnits;
  final b = BytesBuilder()
    ..add(_be32(inhalt.length))
    ..add(typBytes)
    ..add(inhalt)
    ..add(_be32(_crc32(<int>[...typBytes, ...inhalt])));
  return b.toBytes();
}

List<int> _be32(int v) => <int>[
  (v >> 24) & 0xFF,
  (v >> 16) & 0xFF,
  (v >> 8) & 0xFF,
  v & 0xFF,
];

final List<int> _crcTabelle = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTabelle[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
