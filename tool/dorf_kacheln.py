"""Zeichnet die groben Kacheln und Gebäude des Dorf-Prototyps.

Aufruf aus dem Projektordner:  python tool/dorf_kacheln.py
Braucht Pillow. Schreibt nach assets/Dorf/ und überschreibt, was dort liegt.

Alles wird auf einem 16er-Raster gezeichnet (ein Feld = 16 × 16 Bildpunkte)
und hart auf das Doppelte vergrössert — ein Feld ist in der Welt 32 Punkte
gross, wie in der Grube. Die Türen sitzen im Bild genau dort, wo sie in der
Karte stehen (`lib/village/village_map.dart`): wer die Karte ändert, prüft
hier die Tür-Spalten.

Bewusst grob: ein Platzhalter, bis es echte Zeichnungen gibt.
"""

import os
import random

from PIL import Image, ImageDraw

ZIEL = os.path.join(os.path.dirname(__file__), "..", "assets", "Dorf")
F = 16  # ein Feld im Raster
ZOOM = 2

# Erdige Töne, passend zu Leder und Pergament der App.
GRAS = (86, 125, 58)
GRAS_DUNKEL = (66, 101, 44)
GRAS_HELL = (112, 150, 72)
WEG = (196, 164, 108)
WEG_DUNKEL = (164, 132, 82)
WEG_HELL = (220, 192, 140)
KONTUR = (40, 26, 14)
BLATT = (44, 88, 40)
BLATT_HELL = (70, 120, 56)
STAMM = (104, 68, 36)
STEIN = (150, 146, 138)
STEIN_DUNKEL = (110, 106, 100)
STEIN_HELL = (184, 180, 170)
HOLZ = (150, 98, 54)
HOLZ_DUNKEL = (112, 70, 36)
HOLZ_HELL = (186, 130, 76)
DACH_BLAU = (70, 88, 140)
DACH_BLAU_DUNKEL = (50, 64, 108)
DACH_ROT = (158, 62, 48)
DACH_ROT_DUNKEL = (120, 44, 34)
PERGAMENT = (232, 196, 140)
FENSTER = (250, 214, 120)
DUNKEL = (24, 18, 14)
FELS = (122, 106, 88)
FELS_DUNKEL = (90, 76, 62)
FELS_HELL = (156, 138, 116)
TRANSPARENT = (0, 0, 0, 0)


def neu(felder_x, felder_y, grund=TRANSPARENT):
    return Image.new("RGBA", (felder_x * F, felder_y * F), grund)


def speichern(bild, name):
    os.makedirs(ZIEL, exist_ok=True)
    gross = bild.resize((bild.width * ZOOM, bild.height * ZOOM), Image.NEAREST)
    gross.save(os.path.join(ZIEL, name))


def tupfen(d, w, h, farben, anzahl, seed):
    r = random.Random(seed)
    for _ in range(anzahl):
        d.point((r.randrange(w), r.randrange(h)), fill=r.choice(farben))


def gras(seed):
    b = neu(1, 1, GRAS)
    d = ImageDraw.Draw(b)
    tupfen(d, F, F, [GRAS_DUNKEL, GRAS_HELL], 22, seed)
    return b


def weg():
    b = neu(1, 1, WEG)
    d = ImageDraw.Draw(b)
    tupfen(d, F, F, [WEG_DUNKEL, WEG_HELL], 18, 7)
    return b


def baum():
    b = gras(3)
    d = ImageDraw.Draw(b)
    d.rectangle((7, 10, 8, 15), fill=STAMM)
    d.ellipse((1, 0, 14, 12), fill=BLATT, outline=KONTUR)
    d.ellipse((4, 2, 9, 6), fill=BLATT_HELL)
    return b


def fenster(d, x, y):
    d.rectangle((x, y, x + 3, y + 3), fill=FENSTER, outline=KONTUR)
    d.line((x + 2, y, x + 2, y + 3), fill=KONTUR)


def tuer(d, feld_x, feld_y, farbe=HOLZ_DUNKEL):
    x = feld_x * F + 4
    y = feld_y * F + 5
    d.rectangle((x, y, x + 7, feld_y * F + 15), fill=farbe, outline=KONTUR)
    d.point((x + 5, y + 6), fill=FENSTER)


def buecherei():
    """4 × 3 Felder, Tür in Spalte 1 der unteren Reihe."""
    b = neu(4, 3)
    d = ImageDraw.Draw(b)
    # Mauer aus hellem Stein
    d.rectangle((1, 18, 62, 47), fill=STEIN, outline=KONTUR)
    for y in range(22, 47, 6):
        d.line((2, y, 61, y), fill=STEIN_DUNKEL)
    # Blaues Dach
    d.polygon([(0, 20), (32, 2), (63, 20)], fill=DACH_BLAU, outline=KONTUR)
    d.line((8, 16, 55, 16), fill=DACH_BLAU_DUNKEL)
    # Ein aufgeschlagenes Buch als Schild
    d.rectangle((26, 9, 37, 15), fill=PERGAMENT, outline=KONTUR)
    d.line((31, 9, 31, 15), fill=KONTUR)
    fenster(d, 40, 26)
    fenster(d, 52, 26)
    fenster(d, 40, 36)
    tuer(d, 1, 2)
    return b


def hoehle():
    """4 × 3 Felder, Höhleneingang in Spalte 2 der unteren Reihe."""
    b = neu(4, 3)
    d = ImageDraw.Draw(b)
    d.polygon(
        [(0, 47), (4, 20), (14, 8), (30, 2), (46, 6), (58, 18), (63, 47)],
        fill=FELS,
        outline=KONTUR,
    )
    d.polygon([(14, 12), (28, 6), (26, 16)], fill=FELS_HELL)
    d.polygon([(44, 14), (56, 22), (50, 34)], fill=FELS_DUNKEL)
    tupfen(d, 64, 48, [FELS_DUNKEL, FELS_HELL], 40, 11)
    # Der Eingang: ein dunkler Bogen
    x = 2 * F
    d.ellipse((x + 1, 30, x + 14, 52), fill=DUNKEL, outline=KONTUR)
    d.rectangle((x + 1, 41, x + 14, 47), fill=DUNKEL)
    # Zwei Fackeln
    for fx in (x - 2, x + 16):
        d.rectangle((fx, 36, fx + 1, 42), fill=STAMM)
        d.rectangle((fx, 33, fx + 1, 35), fill=(240, 150, 50))
    return b


def laden():
    """3 × 3 Felder, Tür in Spalte 1 der unteren Reihe."""
    b = neu(3, 3)
    d = ImageDraw.Draw(b)
    d.rectangle((1, 16, 46, 47), fill=HOLZ, outline=KONTUR)
    for x in range(6, 46, 6):
        d.line((x, 17, x, 46), fill=HOLZ_DUNKEL)
    d.polygon([(0, 18), (24, 3), (47, 18)], fill=DACH_ROT_DUNKEL, outline=KONTUR)
    # Gestreifte Markise
    for i, x in enumerate(range(2, 46, 5)):
        d.rectangle(
            (x, 18, x + 4, 23),
            fill=DACH_ROT if i % 2 == 0 else PERGAMENT,
        )
    d.line((1, 23, 46, 23), fill=KONTUR)
    # Eine Münze als Schild
    d.ellipse((20, 7, 27, 14), fill=(224, 176, 60), outline=KONTUR)
    fenster(d, 34, 30)
    tuer(d, 1, 2)
    return b


def zuhause():
    """3 × 3 Felder, Tür in Spalte 1 der unteren Reihe."""
    b = neu(3, 3)
    d = ImageDraw.Draw(b)
    d.rectangle((3, 18, 44, 47), fill=PERGAMENT, outline=KONTUR)
    # Fachwerk
    for x in (3, 16, 31, 44):
        d.line((x, 18, x, 47), fill=HOLZ_DUNKEL, width=2)
    d.line((3, 30, 44, 30), fill=HOLZ_DUNKEL, width=2)
    d.polygon([(0, 20), (24, 2), (47, 20)], fill=HOLZ, outline=KONTUR)
    d.line((6, 16, 41, 16), fill=HOLZ_DUNKEL)
    # Schornstein
    d.rectangle((34, 4, 39, 12), fill=STEIN_DUNKEL, outline=KONTUR)
    fenster(d, 34, 22)
    fenster(d, 6, 22)
    tuer(d, 1, 2, farbe=HOLZ)
    return b


def brett():
    """1 × 2 Felder: oben das Brett, unten der Platz davor (die Tür)."""
    b = neu(1, 2)
    d = ImageDraw.Draw(b)
    d.rectangle((3, 8, 4, 18), fill=STAMM)
    d.rectangle((11, 8, 12, 18), fill=STAMM)
    d.rectangle((1, 1, 14, 11), fill=HOLZ_HELL, outline=KONTUR)
    # Zettel
    d.rectangle((3, 3, 6, 7), fill=PERGAMENT)
    d.rectangle((8, 4, 12, 9), fill=PERGAMENT)
    d.point((4, 5), fill=(80, 140, 60))
    return b


def main():
    speichern(gras(1), "gras.png")
    speichern(gras(2), "gras2.png")
    speichern(weg(), "weg.png")
    speichern(baum(), "baum.png")
    speichern(buecherei(), "buecherei.png")
    speichern(hoehle(), "hoehle.png")
    speichern(laden(), "laden.png")
    speichern(zuhause(), "zuhause.png")
    speichern(brett(), "brett.png")


if __name__ == "__main__":
    main()
