"""Zeichnet die Bilder der zwölf Stücke aus ADR-0077.

Die übrigen Stücke tragen Bilder aus dem Raven-Paket (`assets/RAVEN.md`),
das nur auf Frederiks Rechner liegt. Diese zwölf sind deshalb
**gezeichnet**, mit denselben Werkzeugen wie AktivesBretts Fähigkeiten
(`tool/faehigkeit_icons.py`): Raster 32 × 32, Kontur, Licht und Schatten,
hart vergrössert auf 256 × 256.

Dazu kommen:

* zwei Bilder für die neuen Grundangriffe (Speerstich, Sichelhieb) unter
  `assets/Faehigkeiten/`,
* sechs Bilder für die Figur (`assets/character/Charakter_<Name>.png`):
  Rüstungen und Helme nehmen den **Umriss** von Lederwams und Lederkappe
  und färben ihn neu ein — so sitzen sie genau, ohne Pillow. Die zwei
  Waffen sind auf dem 64er-Raster der Figur gezeichnet.

Wer ein Bild ändern will, ändert hier die Form und lässt das Skript
laufen; die PNG-Dateien sind Ergebnis, nicht Quelle.

    py tool/item_icons.py

Nur Standardbibliothek.
"""

import math
import os
import struct
import sys
import zlib

sys.path.insert(0, os.path.dirname(__file__))
import faehigkeit_icons as fi  # noqa: E402

from faehigkeit_icons import (  # noqa: E402
    BRAUN, GOLD, KONTUR, SILBER, STAHL, VIOLETT, VIOLETT_HELL, WEISS, Bild,
    dunkler, farbe, heller,
)

WURZEL = os.path.join(os.path.dirname(__file__), '..', 'assets')

BLUT = farbe('a8305f')
BLUT_HELL = farbe('d65c8f')
NACHT = farbe('2e2340')
NACHT_HELL = farbe('4f3d6e')
EIS = farbe('8fd3f0')
EIS_HELL = farbe('dcf5ff')
IRRLICHT = farbe('c6f2b4')
LEDER = farbe('9a6a3e')
LEDER_HELL = farbe('c48a52')
MOOS = farbe('7a8a4a')
ROST = farbe('b0703a')
SCHIEFER = farbe('6a6f8e')
HANF = farbe('c9b07a')
FEDER = farbe('e8dcc4')


def speichern(bild, pfad):
    """Schreibt [bild] nach [pfad], hart vergrössert auf 256 × 256."""
    raster = len(bild.px)
    faktor = fi.GROESSE // raster
    roh = bytearray()
    for y in range(fi.GROESSE):
        roh.append(0)
        for x in range(fi.GROESSE):
            c = bild.px[y // faktor][x // faktor]
            roh.extend(c if c is not None else (0, 0, 0, 0))
    with open(pfad, 'wb') as f:
        f.write(fi._png(fi.GROESSE, fi.GROESSE, bytes(roh)))
    return pfad


# --- Die Ladenbilder, 32 × 32 ---

def langspeer():
    b = Bild()
    b.strich(4, 28, 23, 9, 1.8, BRAUN)
    b.vieleck(((21, 11), (24, 4), (29, 3), (28, 8), (21, 13)), SILBER)
    b.linie(21, 9, 25, 13, 2.2, STAHL)
    b.linie(9, 24, 6, 27, 2.4, LEDER_HELL)
    return b.fertig()


def blutsichel():
    b = Bild()
    # Die Klinge beginnt, wo der Griff endet, und biegt sich über ihn.
    b.ring(19, 13, 9, 3.2, SILBER, 150, 15)
    b.ring(19, 13, 7.6, 1.2, BLUT_HELL, 165, 5)
    b.strich(7, 29, 12, 18, 2.4, NACHT_HELL)
    b.linie(6, 30, 8, 28, 2.6, BLUT)
    b.kreis(27, 23, 1.5, BLUT_HELL)
    b.kreis(25, 27, 1.1, BLUT)
    return b.fertig()


def _mantel(b, aussen, innen=None):
    b.vieleck(((9, 4), (23, 4), (27, 28), (16, 30), (5, 28)), aussen)
    b.vieleck(((12, 4), (20, 4), (16, 9)), innen or dunkler(aussen, 0.4))


def flickenmantel():
    b = Bild()
    _mantel(b, HANF)
    for x0, y0, x1, y1, c in ((8, 10, 14, 16, MOOS), (17, 9, 23, 15, ROST),
                              (10, 18, 16, 25, SCHIEFER),
                              (18, 19, 24, 26, MOOS)):
        b.rechteck(x0, y0, x1, y1, c)
    for x, y in ((14, 12), (16, 12), (16, 22), (17, 17), (11, 17)):
        b.setze(x, y, KONTUR)
    return b.fertig()


def nachtmantel():
    b = Bild()
    _mantel(b, NACHT, BLUT)
    b.vieleck(((6, 2), (10, 4), (9, 9)), NACHT_HELL)
    b.vieleck(((26, 2), (22, 4), (23, 9)), NACHT_HELL)
    b.linie(16, 10, 16, 29, 1.2, BLUT_HELL)
    return b.fertig()


def _haube(b, c):
    b.kreis(16, 16, 10, c)
    b.rechteck(6, 16, 27, 22, c)


def falkenhaube():
    b = Bild()
    _haube(b, LEDER)
    b.vieleck(((13, 20), (19, 20), (16, 27)), GOLD)
    b.linie(9, 19, 23, 19, 1.4, LEDER_HELL)
    b.strich(22, 9, 29, 2, 2.2, FEDER)
    return b.fertig()


def fledermaushaube():
    b = Bild()
    b.vieleck(((7, 12), (9, 1), (14, 9)), NACHT_HELL)
    b.vieleck(((25, 12), (23, 1), (18, 9)), NACHT_HELL)
    _haube(b, NACHT)
    b.linie(10, 18, 14, 18, 1.4, BLUT_HELL)
    b.linie(18, 18, 22, 18, 1.4, BLUT_HELL)
    return b.fertig()


def _stiefel(b, c):
    b.vieleck(((10, 4), (19, 4), (19, 22), (28, 24), (28, 29), (8, 29)), c)


def hasenlaeufer():
    b = Bild()
    _stiefel(b, LEDER_HELL)
    # Zwei Hasenohren, die über den Schaft ragen.
    for x in (12, 17):
        b.linie(x, 6, x - 1, 0, 3.2, HANF)
        b.linie(x, 5, x - 1, 1, 1.0, BLUT_HELL)
    b.linie(10, 6, 19, 6, 1.4, BRAUN)
    b.linie(8, 26, 28, 26, 1.2, BRAUN)
    return b.fertig()


def schattenstiefel():
    b = Bild()
    _stiefel(b, NACHT)
    b.linie(10, 8, 19, 8, 1.6, BLUT_HELL)
    b.linie(8, 27, 28, 27, 1.2, NACHT_HELL)
    return b.fertig()


def _ring(b, c):
    b.ring(16, 19, 8.5, 3.4, c)


def seelenring():
    b = Bild()
    _ring(b, SILBER)
    b.kreis(16, 10, 4.6, VIOLETT)
    b.kreis(15, 9, 1.6, VIOLETT_HELL)
    for x, y in ((8, 5), (24, 4), (27, 11)):
        b.kreis(x, y, 1.2, VIOLETT_HELL)
    return b.fertig()


def frostreif():
    b = Bild()
    _ring(b, EIS)
    for i in range(6):
        w = math.radians(i * 60)
        b.linie(16, 9, 16 + math.cos(w) * 6, 9 + math.sin(w) * 6, 1.4, EIS_HELL)
    b.kreis(16, 9, 2.4, WEISS)
    return b.fertig()


def echostein():
    b = Bild()
    b.kreis(16, 17, 8, SCHIEFER)
    b.kreis(14, 15, 2.6, heller(SCHIEFER, 0.4))
    b.ring(16, 17, 11, 1.2, VIOLETT_HELL, 300, 60)
    b.ring(16, 17, 14, 1.2, VIOLETT_HELL, 310, 50)
    b.ring(16, 17, 11, 1.2, VIOLETT_HELL, 120, 240)
    b.ring(16, 17, 14, 1.2, VIOLETT_HELL, 130, 230)
    return b.fertig()


def irrlichtamulett():
    b = Bild()
    b.ring(16, 6, 9, 1.2, GOLD, 20, 160)
    b.kreis(16, 20, 6.5, GOLD)
    b.kreis(16, 20, 4.2, dunkler(IRRLICHT, 0.5))
    for x, y in ((14, 18), (18, 19), (16, 22)):
        b.kreis(x, y, 1.3, IRRLICHT)
    for x, y in ((6, 26), (27, 14), (25, 28)):
        b.kreis(x, y, 1.5, IRRLICHT)
    return b.fertig()


# --- Die zwei Grundangriffe, 32 × 32 ---

def speerstich():
    b = Bild()
    # Schräg nach vorn gestossen, die Spitze trifft in einen Stern.
    for x0, y0, x1, y1 in ((2, 20, 9, 13), (5, 26, 13, 18), (11, 29, 17, 23)):
        b.linie(x0, y0, x1, y1, 1.2, WEISS)
    b.strich(4, 28, 21, 11, 1.8, BRAUN)
    for t in (0.35, 0.45):
        x, y = 4 + 17 * t, 28 - 17 * t
        b.linie(x - 1.2, y - 1.2, x + 1.2, y + 1.2, 1.4, LEDER_HELL)
    b.vieleck(((19, 10), (25, 3), (29, 3), (28, 7), (21, 13)), SILBER)
    for i in range(4):
        w = math.radians(45 + i * 90)
        b.linie(28, 4, 28 + math.cos(w) * 4, 4 + math.sin(w) * 4, 1, GOLD)
    return b.fertig()


def sichelhieb():
    b = Bild()
    b.ring(16, 18, 12, 2.6, WEISS, 190, 350)
    b.ring(16, 18, 9, 1.4, BLUT_HELL, 200, 340)
    b.vieleck(((25, 7), (30, 11), (24, 13)), SILBER)
    b.strich(22, 14, 26, 24, 2.2, NACHT_HELL)
    return b.fertig()


# --- Die Figur, 64 × 64 ---

def _lies(pfad):
    """Ein PNG als 64 × 64 Pixel (jeder vierte), RGBA oder None."""
    with open(pfad, 'rb') as f:
        daten = f.read()
    pos, idat = 8, b''
    breite = hoehe = 0
    while pos < len(daten):
        laenge, = struct.unpack('>I', daten[pos:pos + 4])
        art = daten[pos + 4:pos + 8]
        inhalt = daten[pos + 8:pos + 8 + laenge]
        pos += 12 + laenge
        if art == b'IHDR':
            breite, hoehe, tiefe, typ = struct.unpack('>IIBB', inhalt[:10])
            assert tiefe == 8 and typ == 6, (pfad, tiefe, typ)
        elif art == b'IDAT':
            idat += inhalt
    roh = zlib.decompress(idat)
    zeile = breite * 4
    vorher = bytearray(zeile)
    pixel = []
    i = 0
    for _ in range(hoehe):
        filt = roh[i]
        i += 1
        z = bytearray(roh[i:i + zeile])
        i += zeile
        for x in range(zeile):
            a = z[x - 4] if x >= 4 else 0
            o = vorher[x]
            c = vorher[x - 4] if x >= 4 else 0
            if filt == 1:
                z[x] = (z[x] + a) & 255
            elif filt == 2:
                z[x] = (z[x] + o) & 255
            elif filt == 3:
                z[x] = (z[x] + (a + o) // 2) & 255
            elif filt == 4:
                p = a + o - c
                pa, pb, pc = abs(p - a), abs(p - o), abs(p - c)
                z[x] = (z[x] + (a if pa <= pb and pa <= pc
                                else (o if pb <= pc else c))) & 255
        pixel.append(z)
        vorher = z
    schritt = breite // 64
    return [[tuple(pixel[y * schritt][x * schritt * 4:x * schritt * 4 + 4])
             if pixel[y * schritt][x * schritt * 4 + 3] > 0 else None
             for x in range(64)] for y in range(64)]


def _umgefaerbt(vorlage, rampe, flicken=None):
    """Der Umriss von [vorlage], die Helligkeit auf [rampe] abgebildet —
    dunkel bis hell. [flicken] färbt einzelne Felder anders ein."""
    licht = [sum(c[:3]) for row in vorlage for c in row if c is not None]
    tief, hoch = min(licht), max(licht)
    bild = Bild()
    bild.px = [[None] * 64 for _ in range(64)]
    for y, row in enumerate(vorlage):
        for x, c in enumerate(row):
            if c is None:
                continue
            anteil = (sum(c[:3]) - tief) / max(1, hoch - tief)
            stufe = rampe[min(len(rampe) - 1, int(anteil * len(rampe)))]
            if flicken:
                stufe = flicken(x, y, stufe)
            bild.px[y][x] = stufe
    return bild


def _figur_ruestungen():
    vorlage = _lies(os.path.join(WURZEL, 'character',
                                 'Charakter_Lederwams.png'))
    nacht = _umgefaerbt(vorlage, (KONTUR, NACHT, NACHT_HELL, BLUT))

    def flicken(x, y, stufe):
        if stufe in (KONTUR,):
            return stufe
        feld = ((x // 6) + (y // 6)) % 4
        return (MOOS, ROST, SCHIEFER, HANF)[feld]

    flick = _umgefaerbt(vorlage, (KONTUR, BRAUN, HANF, HANF), flicken)
    return {'Nachtmantel': nacht, 'Flickenmantel': flick}


def _figur_helme():
    vorlage = _lies(os.path.join(WURZEL, 'character',
                                 'Charakter_Lederkappe.png'))
    falke = _umgefaerbt(vorlage, (KONTUR, BRAUN, LEDER, LEDER_HELL))
    for x, y in ((40, 4), (41, 3), (42, 2), (43, 1), (41, 4), (42, 3)):
        falke.px[y][x] = FEDER
    fleder = _umgefaerbt(vorlage, (KONTUR, NACHT, NACHT_HELL, NACHT_HELL))
    for dx in range(3):
        for dy in range(3 - dx):
            fleder.px[2 + dy + dx][24 + dx] = NACHT_HELL
            fleder.px[2 + dy + dx][39 - dx] = NACHT_HELL
    return {'Falkenhaube': falke, 'Fledermaushaube': fleder}


def _figur_waffen():
    alt = fi.RASTER
    fi.RASTER = 64
    try:
        speer = Bild()
        speer.linie(41, 52, 54, 16, 2.0, BRAUN)
        speer.vieleck(((52, 18), (55, 9), (58, 16)), SILBER)
        speer.fertig(licht=False)

        sichel = Bild()
        sichel.linie(42, 46, 47, 31, 2.2, NACHT_HELL)
        sichel.ring(52, 32, 7, 2.2, SILBER, 190, 30)
        sichel.ring(52, 32, 5.8, 0.8, BLUT_HELL, 200, 20)
        sichel.fertig(licht=False)
    finally:
        fi.RASTER = alt
    return {'Langspeer': speer, 'Blutsichel': sichel}


LADEN = {
    'Waffen/Speere/Langspeer': langspeer,
    'Waffen/Sicheln/Blutsichel': blutsichel,
    'Ruestung/Flickenmantel': flickenmantel,
    'Ruestung/Nachtmantel': nachtmantel,
    'Helme/Falkenhaube': falkenhaube,
    'Helme/Fledermaushaube': fledermaushaube,
    'Schuhe/Hasenlaeufer': hasenlaeufer,
    'Schuhe/Schattenstiefel': schattenstiefel,
    'Ringe/Seelenring': seelenring,
    'Ringe/Frostreif': frostreif,
    'Talismane/Echostein': echostein,
    'Talismane/Irrlichtamulett': irrlichtamulett,
}

ZUEGE = {
    'Speerstich': speerstich,
    'Sichelhieb': sichelhieb,
}

if __name__ == '__main__':
    for name, zeichne in LADEN.items():
        pfad = os.path.join(WURZEL, *name.split('/')) + '.png'
        os.makedirs(os.path.dirname(pfad), exist_ok=True)
        print(speichern(zeichne(), pfad))
    for name, zeichne in ZUEGE.items():
        pfad = os.path.join(WURZEL, 'Faehigkeiten', name + '.png')
        print(speichern(zeichne(), pfad))
    figur = {**_figur_ruestungen(), **_figur_helme(), **_figur_waffen()}
    for name, bild in figur.items():
        pfad = os.path.join(WURZEL, 'character', 'Charakter_' + name + '.png')
        print(speichern(bild, pfad))
