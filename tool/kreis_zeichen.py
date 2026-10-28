"""Legt die Zeichen der Kreise auf der Startseite nach `assets/UI/`.

**Warum eigene Zeichen** (28.10.2026, Frederik: „passendere Icons
wählen, vielleicht gucken, was der Spieler aus anderen Spielen gelernt
hat“). Die Kreise trugen Systemzeichen — eine Karate-Figur für den
Kampf, eine Ladenfront mit Markise, ein Profil-Männchen —, glatt und
modern zwischen Holz und Pixeln. Jetzt trägt jeder, was ein Spieler aus
RPGs kennt:

| Kreis | Zeichen | woher |
|---|---|---|
| Gewohnheiten | Schriftrolle mit Haken — die Quest | Raven fc305, Haken gezeichnet |
| Kampf | zwei gekreuzte Schwerter | Raven fc721 |
| Statistik | drei Balken, die steigen | gezeichnet |
| Laden | ein Münzbeutel | Raven fc158, die Münze fc131 |
| Fähigkeiten | ein Runenstein, der blau leuchtet | Raven fc326, umgefärbt |
| Ausrüstung | ein Rucksack — das Inventar | gezeichnet, Raven hat keinen |
| Charakter | ein Helm — der Charakterbogen | Raven fc1911 |

Die Theorie behält Frederiks Buch (`assets/UI/Buch.png`).

Raven liegt nur auf Frederiks Rechner (`assets/RAVEN.md`); der Pfad
lässt sich als erstes Argument übergeben. Alles wird hart auf
256 × 256 vergrößert, das Format aller Zeichnungen (`PixelArt`).

    python tool/kreis_zeichen.py ["<Pfad zu Raven/Separated Files/64x64>"]

Braucht Pillow.
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw

ZIEL = Path(__file__).resolve().parent.parent / "assets" / "UI"
RAVEN = Path.home() / (
    "Desktop/Pixelart/Runtergeladen/Free - Raven Fantasy Icons/Separated Files/64x64"
)
SEITE = 256

# Die Kontur der Raven-Bilder, ein dunkles Braunrot.
KONTUR = (40, 22, 24, 255)


def raven(ordner, nummer):
    return Image.open(ordner / f"fc{nummer}.png").convert("RGBA")


def gross(bild):
    return bild.resize((SEITE, SEITE), Image.NEAREST)


def mit_haken(bild):
    """Ein grüner Haken unten rechts auf der Rolle — erledigt, wie im
    Kreis eines Häkchens. Auf dem 64er-Raster, ohne Kantenglättung."""
    bild = bild.copy()
    malen = ImageDraw.Draw(bild)
    punkte = [(36, 46), (43, 53), (58, 36)]
    malen.line(punkte, fill=KONTUR, width=10, joint="curve")
    malen.line(punkte, fill=(84, 160, 64, 255), width=5, joint="curve")
    malen.line([(37, 45), (43, 51)], fill=(140, 210, 104, 255), width=1)
    return bild


def mit_muenze(beutel, muenze):
    """Eine Goldmünze vorn am Beutel — sonst ist er nur ein Sack."""
    bild = beutel.copy()
    klein = muenze.crop(muenze.getbbox()).resize((26, 26), Image.NEAREST)
    bild.alpha_composite(klein, (34, 34))
    return bild


def leuchtend(rune):
    """Die Kerbe der Rune leuchtet blau wie Mana — ein Stein mit Kraft,
    nicht bloß ein Stein."""
    farben = {
        (52, 55, 51, 255): (120, 210, 255, 255),
        (82, 84, 81, 255): (64, 140, 214, 255),
    }
    bild = rune.copy()
    for x in range(bild.width):
        for y in range(bild.height):
            neu = farben.get(bild.getpixel((x, y)))
            if neu is not None:
                bild.putpixel((x, y), neu)
    return bild


class Raster:
    """Ein 32er-Raster zum Zeichnen: Flächen setzen, dann rundherum die
    Kontur — dieselbe Machart wie `tool/item_icons.py`."""

    def __init__(self):
        self.punkte = {}

    def flaeche(self, x0, y0, x1, y1, farbe):
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                self.punkte[(x, y)] = farbe

    def punkt(self, x, y, farbe):
        self.punkte[(x, y)] = farbe

    def ohne(self, *orte):
        for ort in orte:
            self.punkte.pop(ort, None)

    def bild(self):
        bild = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
        for (x, y), farbe in self.punkte.items():
            bild.putpixel((x, y), farbe)
        # Die Kontur: jeder leere Punkt neben einem gesetzten.
        for x in range(32):
            for y in range(32):
                if (x, y) in self.punkte:
                    continue
                nachbarn = ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))
                if any(n in self.punkte for n in nachbarn):
                    bild.putpixel((x, y), KONTUR)
        return bild


def rucksack():
    """Ein Lederrucksack: Griff oben, Klappe mit goldener Schnalle,
    vorn eine Tasche, links Licht, rechts Schatten."""
    leder = (150, 92, 52, 255)
    licht = (190, 128, 76, 255)
    schatten = (110, 64, 36, 255)
    klappe = (124, 72, 40, 255)
    klappe_licht = (160, 100, 58, 255)
    gold = (236, 186, 76, 255)
    gold_schatten = (170, 118, 40, 255)

    r = Raster()
    # Der Griff: ein Bogen über der Klappe.
    for x in range(13, 19):
        r.punkt(x, 3, schatten)
    r.punkt(12, 4, schatten)
    r.punkt(19, 4, schatten)
    r.punkt(12, 5, schatten)
    r.punkt(19, 5, schatten)
    # Der Körper, unten und oben abgerundet.
    r.flaeche(7, 8, 24, 27, leder)
    r.ohne((7, 8), (24, 8), (7, 27), (24, 27))
    r.flaeche(7, 9, 8, 26, licht)
    r.flaeche(23, 9, 24, 26, schatten)
    # Die Klappe, unten rund, mit Licht an der Kante.
    r.flaeche(8, 7, 23, 15, klappe)
    r.ohne((8, 7), (23, 7))
    r.flaeche(9, 16, 22, 16, klappe)
    r.flaeche(9, 8, 22, 8, klappe_licht)
    # Die Schnalle mitten auf der Klappe.
    r.flaeche(14, 13, 17, 17, gold)
    r.flaeche(15, 14, 16, 16, KONTUR)
    r.punkt(17, 17, gold_schatten)
    r.punkt(14, 17, gold_schatten)
    # Die Tasche vorn: dunkler, mit Naht.
    r.flaeche(10, 19, 21, 25, schatten)
    r.flaeche(10, 19, 21, 19, KONTUR)
    r.flaeche(11, 20, 20, 20, leder)
    for x in range(11, 21, 2):
        r.punkt(x, 24, klappe_licht)
    return r.bild()


def balken():
    """Drei Balken, die steigen, auf einem Boden — der Verlauf."""
    gruen = (84, 160, 64, 255)
    licht = (140, 210, 104, 255)
    dunkel = (52, 112, 44, 255)
    boden = (150, 92, 52, 255)

    r = Raster()
    for x0, oben in ((6, 18), (13, 12), (20, 6)):
        r.flaeche(x0, oben, x0 + 4, 24, gruen)
        r.flaeche(x0, oben, x0, 24, licht)
        r.flaeche(x0 + 4, oben, x0 + 4, 24, dunkel)
        r.flaeche(x0, oben, x0 + 4, oben, licht)
    r.flaeche(4, 26, 27, 27, boden)
    return r.bild()


def main():
    ordner = Path(sys.argv[1]) if len(sys.argv) > 1 else RAVEN
    zeichen = {
        "Kreis_Gewohnheiten": mit_haken(raven(ordner, 305)),
        "Kreis_Kampf": raven(ordner, 721),
        "Kreis_Statistik": balken(),
        "Kreis_Laden": mit_muenze(raven(ordner, 158), raven(ordner, 131)),
        "Kreis_Faehigkeiten": leuchtend(raven(ordner, 326)),
        "Kreis_Ausruestung": rucksack(),
        "Kreis_Charakter": raven(ordner, 1911),
    }
    ZIEL.mkdir(parents=True, exist_ok=True)
    for name, bild in zeichen.items():
        pfad = ZIEL / f"{name}.png"
        gross(bild).save(pfad)
        print(f"{pfad.name}: {pfad.stat().st_size} Bytes")


if __name__ == "__main__":
    main()
