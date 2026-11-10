"""Legt die Zeichen der Kreise auf der Startseite nach `assets/UI/`.

**Warum eigene Zeichen** (28.10.2026, Frederik: „passendere Icons
wählen, vielleicht gucken, was der Spieler aus anderen Spielen gelernt
hat“). Die Kreise trugen Systemzeichen — eine Karate-Figur für den
Kampf, eine Ladenfront mit Markise, ein Profil-Männchen —, glatt und
modern zwischen Holz und Pixeln. Jetzt trägt jeder, was ein Spieler aus
RPGs kennt:

| Kreis | Zeichen | woher |
|---|---|---|
| Gewohnheiten | Schriftrolle mit Haken — die Quest | seit 04.11.2026 `tool/pixel/kreis_gewohnheiten.px.js` (pxl), nicht mehr hier |
| Kampf | zwei gekreuzte Schwerter | seit 04.11.2026 `tool/pixel/kreis_kampf.px.js` (pxl), nicht mehr hier |
| Statistik | Balken mit Pfeil | seit 08.11. in `tool/pixel/kreis_statistik.px.js` |
| Laden | ein Lederbeutel voller Gold | seit 08.11. in `tool/pixel/kreis_laden.px.js` |
| Fähigkeiten | ein Zauberbuch mit Flammensiegel | seit 08.11. in `tool/pixel/kreis_faehigkeiten.px.js` |
| Ausrüstung | ein Plattenharnisch mit Goldbeschlag | seit 10.11. in `tool/pixel/kreis_ausruestung.px.js` |
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

from PIL import Image

ZIEL = Path(__file__).resolve().parent.parent / "assets" / "UI"
RAVEN = Path.home() / (
    "Desktop/Pixelart/Runtergeladen/Free - Raven Fantasy Icons/Separated Files/64x64"
)
SEITE = 256

def raven(ordner, nummer):
    return Image.open(ordner / f"fc{nummer}.png").convert("RGBA")


def gross(bild):
    return bild.resize((SEITE, SEITE), Image.NEAREST)


def main():
    ordner = Path(sys.argv[1]) if len(sys.argv) > 1 else RAVEN
    zeichen = {
        "Kreis_Charakter": raven(ordner, 1911),
    }
    ZIEL.mkdir(parents=True, exist_ok=True)
    for name, bild in zeichen.items():
        pfad = ZIEL / f"{name}.png"
        gross(bild).save(pfad)
        print(f"{pfad.name}: {pfad.stat().st_size} Bytes")


if __name__ == "__main__":
    main()
