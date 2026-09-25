"""Legt Rüstungen und Waffen aus dem Laden auf die Figur der Startseite.

Aufruf aus dem Projektordner (Python mit Pillow):

    python tool/figur_ausruestung.py

Schreibt je Stück eine Datei ``assets/character/Charakter_<Name>.png``,
256 × 256 wie ``Charakter.png`` und deckungsgleich darüber. Die Helme
dort sind von Hand gezeichnet und werden hier **nicht** angefasst.

**Warum erzeugt und nicht gezeichnet.** Die Ladenbilder sind 64 Pixel
gross, ein Oberkörper auf der Figur 26. Hart verkleinert fällt dabei gut
jeder zweite Pixel weg; hier wird deshalb weich verkleinert und jeder
Pixel danach auf die nächste Farbe des Originals zurückgelegt. So bleiben
die Farben des Stücks, nur die Form wird gröber. Das sind Platzhalter,
bis es gezeichnete gibt — wer eine Datei von Hand ersetzt, nimmt das
Stück hier aus der Liste, sonst überschreibt der nächste Lauf sie.

Zwei Stücke sind nachgebessert:

* **Kettenpanzer** — im Laden als Knäuel gezeichnet. Er bekommt den
  Umriss des Schuppenpanzers und ein eigenes Kettenmuster in seinen
  Farben.
* **Plattenharnisch** — schmaler gesetzt, sonst steht er als Kasten da.

Jede Rüstung bringt **Beine** mit: die Hautpixel der Beine in ihren
Farben, siehe ``beine()``. Die Füsse bleiben frei für Schuhe.
"""

from collections import Counter
from pathlib import Path

from PIL import Image

RAUM = 64  # gezeichnetes Raster
FAKTOR = 4  # abgelegt als 256 × 256
FIGUR = Path("assets/character")

# Wohin ein Stück auf der Figur kommt, im 64er-Raster: links, oben,
# rechts, unten. Die Rüstung reicht bis unter den Helm.
RUMPF = (19, 23, 45, 48)
RUMPF_SCHMAL = (21, 24, 43, 48)
HAND = (38, 26, 56, 48)

RUESTUNGEN = {
    "Lederwams": RUMPF,
    "GesteppteWams": RUMPF,
    "Schuppenpanzer": RUMPF,
    "Kettenpanzer": RUMPF,  # Sonderfall, siehe kettenpanzer()
    "Plattenharnisch": RUMPF_SCHMAL,
    "Drachenschuppenpanzer": RUMPF,
    "Runenharnisch": RUMPF,
    "Titanenpanzer": RUMPF,
}

WAFFEN = [
    "Boegen/Kurzbogen",
    "Schwerter/Uebungsklinge",
    "Kolben/Streitkolben",
    "Schwerter/GeschliffeneKlinge",
    "Staebe/Kriegsstab",
    "Schwerter/Zweihaender",
    "Boegen/Langbogen",
    "Schwerter/Sonnenklinge",
]


def zeichnung(pfad: Path) -> Image.Image:
    """Das Ladenbild im 64er-Raster, auf seinen Inhalt zugeschnitten."""
    bild = Image.open(pfad).convert("RGBA").resize((RAUM, RAUM), Image.NEAREST)
    return bild.crop(bild.getbbox())


def farben(bild: Image.Image) -> list[tuple[int, int, int]]:
    return sorted({p[:3] for p in bild.get_flattened_data() if p[3] > 0})


def verkleinern(bild: Image.Image, breite: int, hoehe: int) -> Image.Image:
    """Weich verkleinern, dann jeden Pixel auf eine Originalfarbe legen."""
    palette = farben(bild)
    weich = bild.resize((breite, hoehe), Image.BOX)
    aus = Image.new("RGBA", (breite, hoehe))
    for y in range(hoehe):
        for x in range(breite):
            r, g, b, a = weich.getpixel((x, y))
            if a < 110:
                continue
            naechste = min(
                palette,
                key=lambda c: (c[0] - r) ** 2 + (c[1] - g) ** 2 + (c[2] - b) ** 2,
            )
            aus.putpixel((x, y), naechste + (255,))
    return aus


def kettenpanzer(breite: int, hoehe: int) -> Image.Image:
    """Umriss des Schuppenpanzers, gefüllt mit einem Kettenmuster."""
    form = verkleinern(
        zeichnung(Path("assets/Ruestung/Schuppenpanzer.png")), breite, hoehe
    )
    kontur, dunkel, mittel, hell = (46, 28, 44), (114, 78, 99), (134, 113, 140), (149, 173, 180)

    def drin(x: int, y: int) -> bool:
        return 0 <= x < breite and 0 <= y < hoehe and form.getpixel((x, y))[3] > 0

    aus = Image.new("RGBA", (breite, hoehe))
    for y in range(hoehe):
        for x in range(breite):
            if not drin(x, y):
                continue
            rand = not all(drin(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            # Die dunklen Linien des Schuppenpanzers trennen Arme und
            # Rumpf — ohne sie wird der Panzer ein Poncho.
            r, g, b, _ = form.getpixel((x, y))
            linie = 0.3 * r + 0.59 * g + 0.11 * b < 60
            if rand or linie:
                farbe = kontur
            elif x > breite - 5:
                farbe = dunkel  # Schatten rechts
            elif not drin(x, y - 2):
                farbe = hell  # Licht auf den Schultern
            else:
                farbe = mittel if (x + y) % 2 == 0 else dunkel
            aus.putpixel((x, y), farbe + (255,))
    return aus


HAUT = (255, 212, 165)  # Hautfarbe der Grundfigur
# Hüfte und Beine: ab Zeile 44, damit zwischen Rüstung und Hose keine
# Haut durchscheint — je nach Rüstung endet der Rumpf früher. Nur
# zwischen den Händen (Spalte 25 bis 38), Arme und Hände bleiben Haut.
BEINE = range(44, 59)
HUEFTE = range(25, 39)


def hell(c: tuple[int, int, int]) -> float:
    return 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]


def beine(ruestung: Image.Image, kette: bool) -> Image.Image:
    """Hosen in den Farben der Rüstung: die Hautpixel der Beine.

    Die häufigste Farbe der Rüstung (ohne Kontur) füllt das Bein, links
    liegt der nächsthellere Ton, rechts der nächstdunklere — so haben die
    Beine dasselbe Licht wie der Rumpf. Die Kontur der Figur bleibt.
    """
    figur = Image.open(FIGUR / "Charakter.png").convert("RGBA").resize((RAUM, RAUM), Image.NEAREST)
    zaehler = Counter(p[:3] for p in ruestung.get_flattened_data() if p[3] > 0)
    palette = sorted(zaehler, key=hell)
    innen = [c for c in palette if hell(c) >= 60] or palette
    haupt = max(innen, key=lambda c: zaehler[c])
    i = palette.index(haupt)
    licht, schatten = palette[min(i + 1, len(palette) - 1)], palette[max(i - 1, 0)]

    def haut(x: int, y: int) -> bool:
        p = figur.getpixel((x, y))
        return p[3] > 0 and p[:3] == HAUT

    aus = Image.new("RGBA", (RAUM, RAUM))
    for y in BEINE:
        for x in HUEFTE:
            if not haut(x, y):
                continue
            if not haut(x - 1, y):
                farbe = licht
            elif not haut(x + 1, y):
                farbe = schatten
            elif kette and (x + y) % 2:
                farbe = schatten
            else:
                farbe = haupt
            aus.putpixel((x, y), farbe + (255,))
    return aus


def ablegen(
    stueck: Image.Image,
    feld: tuple[int, int, int, int],
    name: str,
    darunter: Image.Image | None = None,
) -> None:
    links, oben, _, _ = feld
    raster = Image.new("RGBA", (RAUM, RAUM))
    if darunter is not None:
        raster.alpha_composite(darunter)
    raster.alpha_composite(stueck, (links, oben))
    ebene = raster.resize((RAUM * FAKTOR, RAUM * FAKTOR), Image.NEAREST)
    ziel = FIGUR / f"Charakter_{name}.png"
    ebene.save(ziel)
    print(ziel)


def main() -> None:
    for name, feld in RUESTUNGEN.items():
        breite, hoehe = feld[2] - feld[0], feld[3] - feld[1]
        if name == "Kettenpanzer":
            stueck = kettenpanzer(breite, hoehe)
        else:
            stueck = verkleinern(zeichnung(Path(f"assets/Ruestung/{name}.png")), breite, hoehe)
        ablegen(stueck, feld, name, darunter=beine(stueck, kette=name == "Kettenpanzer"))

    for pfad in WAFFEN:
        breite, hoehe = HAND[2] - HAND[0], HAND[3] - HAND[1]
        stueck = verkleinern(zeichnung(Path(f"assets/Waffen/{pfad}.png")), breite, hoehe)
        ablegen(stueck, HAND, pfad.split("/")[1])


if __name__ == "__main__":
    main()
