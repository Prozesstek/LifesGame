"""Macht aus einem Bild der KI (ComfyUI, 1024 x 1024) ein Sprite.

Aufruf (Python mit Pillow):

    python tool/sprite_verpixeln.py eingabe.png assets/.../Name.png

Vier Schritte:

1. **Freistellen.** Der Hintergrund wird von den Rändern aus geflutet:
   Was der Randfarbe ähnlich ist und daran hängt, wird durchsichtig, auch
   der helle Schatten unter den Füßen. Was dem Grund sehr nah ist, fällt
   auch weg, wenn es eingeschlossen ist (zwischen Bogen und Sehne).
2. **Zuschneiden und verkleinern** auf ``--hoehe`` Bildpunkte (58), weich
   gemittelt, unten mittig in 64 x 64.
3. **Farben** auf ``--farben`` (24) zusammenlegen, ohne Rastern.
4. **Umriss** von einem Bildpunkt, ohne Ecken -- außer um feine helle
   Linien wie eine Sehne, die sonst zur dicken Doppellinie würde.

Abgelegt wird 64 x 64 hart auf 256 x 256 vergrößert, wie alles
Gezeichnete (``PixelArt``); ``--klein`` schreibt 64 x 64.

Die Bilder kommen aus ComfyUI mit SDXL Base 1.0 (OpenRAIL++) und der
LoRA ``nerijs/pixel-art-xl`` (CreativeML OpenRAIL-M); beide erlauben, die
Bilder kommerziell zu nutzen. ComfyUI liegt nicht im Repo.
"""
import argparse
from collections import deque
from PIL import Image


def freistellen(im, toleranz=38):
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    rand = [px[x, 0] for x in range(w)] + [px[x, h - 1] for x in range(w)]
    grund = tuple(sorted(c[i] for c in rand)[len(rand) // 2] for i in range(3))

    def hintergrund(c, y):
        # nah am Grund, oder hell und farblos (Schatten, Verlauf)
        if sum(abs(c[i] - grund[i]) for i in range(3)) < toleranz:
            return True
        farblos = max(c[:3]) - min(c[:3]) < 14
        # Im unteren Fünftel liegt der Schatten unter den Füßen: Dort zählt
        # auch Dunkleres, solange es farblos ist und am Grund hängt
        return farblos and (sum(c[:3]) > 3 * 120
                            or (y > h * 0.8 and sum(c[:3]) > 3 * 40))

    weg = [[False] * h for _ in range(w)]
    q = deque((x, y) for x in range(w) for y in (0, h - 1))
    q.extend((x, y) for y in range(h) for x in (0, w - 1))
    while q:
        x, y = q.popleft()
        if weg[x][y] or not hintergrund(px[x, y], y):
            continue
        weg[x][y] = True
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not weg[nx][ny]:
                q.append((nx, ny))
    for x in range(w):
        for y in range(h):
            c = px[x, y]
            # Eingeschlossener Grund (zwischen Bogen und Sehne) zählt mit,
            # aber nur, was dem Grund sehr nah ist
            if weg[x][y] or sum(abs(c[i] - grund[i]) for i in range(3)) < 18:
                px[x, y] = (0, 0, 0, 0)
    return im


def auf64(im, farben=24, hoehe=58, seite=64):
    im = im.crop(im.getbbox())
    f = hoehe / max(im.size)
    klein = im.resize((max(1, round(im.width * f)), max(1, round(im.height * f))),
                      Image.BOX)
    # Alpha hart machen, Farben auf eine Palette bringen
    a = klein.getchannel("A").point(lambda v: 255 if v > 140 else 0)
    rgb = klein.convert("RGB").quantize(farben, method=Image.MEDIANCUT,
                                        dither=Image.Dither.NONE).convert("RGB")
    rgb.putalpha(a)
    bild = Image.new("RGBA", (seite, seite))
    bild.paste(rgb, ((seite - rgb.width) // 2, seite - rgb.height - 3), rgb)
    return bild


def umriss(im, farbe=(26, 16, 22, 255)):
    """Legt einen Bildpunkt Umriss außen um alles Deckende (ohne Ecken).

    Feine helle Linien (die Sehne) bekommen keinen: Ein heller, farbloser
    Bildpunkt mit höchstens drei deckenden Nachbarn ist Linie, nicht Fläche.
    """
    w, h = im.size
    px = im.load()
    voll = {(x, y) for x in range(w) for y in range(h) if px[x, y][3]}

    def linie(x, y):
        r, g, b, _ = px[x, y]
        nachbarn = sum((x + dx, y + dy) in voll for dx in (-1, 0, 1)
                       for dy in (-1, 0, 1) if dx or dy)
        return max(r, g, b) - min(r, g, b) < 30 and max(r, g, b) > 110             and nachbarn <= 3

    flaeche = {q for q in voll if not linie(*q)}
    for x, y in [(x + dx, y + dy) for x, y in flaeche
                 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]:
        if 0 <= x < w and 0 <= y < h and (x, y) not in voll:
            px[x, y] = farbe
    return im

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("eingabe"); p.add_argument("ausgabe")
    p.add_argument("--farben", type=int, default=24)
    p.add_argument("--hoehe", type=int, default=58)
    p.add_argument("--ohne-umriss", action="store_true")
    p.add_argument("--klein", action="store_true",
                   help="64 x 64 statt 256 x 256 schreiben")
    a = p.parse_args()
    bild = auf64(freistellen(Image.open(a.eingabe)), a.farben, a.hoehe)
    if not a.ohne_umriss:
        bild = umriss(bild)
    if not a.klein:
        bild = bild.resize((256, 256), Image.NEAREST)
    bild.save(a.ausgabe)
