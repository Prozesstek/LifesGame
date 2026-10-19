"""Zeichnet die Bilder zu AktivesBretts zwölf Fähigkeiten (ADR-0074).

Die übrigen Fähigkeiten tragen Bilder aus dem Raven-Paket
(`assets/RAVEN.md`). Das Paket liegt nur auf Frederiks Rechner; diese
zwölf sind deshalb **gezeichnet** — aus Kreisen, Vielecken und Linien
auf einem Raster von 32 × 32, mit dunkler Kontur, Licht oben links und
Schatten unten rechts, damit sie neben den Raven-Bildern nicht flach
wirken. Gespeichert wird hart vergrössert auf 256 × 256, das Format
aller Zeichnungen im Projekt (`PixelArt`).

Wer ein Bild ändern will, ändert hier die Form und lässt das Skript
laufen; die PNG-Dateien sind Ergebnis, nicht Quelle.

    py tool/faehigkeit_icons.py

Nur Standardbibliothek (zlib, struct) — kein Pillow nötig.
"""

import math
import os
import struct
import zlib

RASTER = 32
GROESSE = 256
ZIEL = os.path.join(os.path.dirname(__file__), '..', 'assets', 'Faehigkeiten')

KONTUR = (38, 22, 43, 255)


def farbe(hexwert, alpha=255):
    hexwert = hexwert.lstrip('#')
    return (int(hexwert[0:2], 16), int(hexwert[2:4], 16), int(hexwert[4:6], 16), alpha)


def heller(c, f=0.35):
    return tuple(min(255, int(k + (255 - k) * f)) for k in c[:3]) + (c[3],)


def dunkler(c, f=0.3):
    return tuple(int(k * (1 - f)) for k in c[:3]) + (c[3],)


class Bild:
    def __init__(self):
        self.px = [[None] * RASTER for _ in range(RASTER)]

    def setze(self, x, y, c):
        if 0 <= x < RASTER and 0 <= y < RASTER:
            self.px[y][x] = c

    def kreis(self, cx, cy, r, c):
        for y in range(RASTER):
            for x in range(RASTER):
                if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                    self.setze(x, y, c)

    def ring(self, cx, cy, r, breite, c, von=0.0, bis=360.0):
        for y in range(RASTER):
            for x in range(RASTER):
                d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
                if abs(d - r) > breite / 2:
                    continue
                w = math.degrees(math.atan2(y + 0.5 - cy, x + 0.5 - cx)) % 360
                if von <= bis and not (von <= w <= bis):
                    continue
                if von > bis and not (w >= von or w <= bis):
                    continue
                self.setze(x, y, c)

    def vieleck(self, punkte, c):
        for y in range(RASTER):
            for x in range(RASTER):
                if _innen(x + 0.5, y + 0.5, punkte):
                    self.setze(x, y, c)

    def linie(self, x0, y0, x1, y1, breite, c):
        laenge = math.hypot(x1 - x0, y1 - y0) or 1
        for y in range(RASTER):
            for x in range(RASTER):
                px, py = x + 0.5, y + 0.5
                t = ((px - x0) * (x1 - x0) + (py - y0) * (y1 - y0)) / laenge ** 2
                t = max(0.0, min(1.0, t))
                qx, qy = x0 + t * (x1 - x0), y0 + t * (y1 - y0)
                if math.hypot(px - qx, py - qy) <= breite / 2:
                    self.setze(x, y, c)

    def strich(self, x0, y0, x1, y1, breite, c):
        """Eine Linie mit eigener Kontur — für alles, was über einer
        anderen Fläche liegt und sonst mit ihr verschwömme."""
        self.linie(x0, y0, x1, y1, breite + 2, KONTUR)
        self.linie(x0, y0, x1, y1, breite, c)

    def rechteck(self, x0, y0, x1, y1, c):
        for y in range(y0, y1):
            for x in range(x0, x1):
                self.setze(x, y, c)

    def fertig(self, licht=True):
        """Licht, Schatten, dann die Kontur um alles Gezeichnete."""
        if licht:
            neu = [row[:] for row in self.px]
            for y in range(RASTER):
                for x in range(RASTER):
                    c = self.px[y][x]
                    if c is None or c == KONTUR:
                        continue
                    oben = self._leer(x, y - 1) or self._leer(x - 1, y)
                    unten = self._leer(x, y + 1) or self._leer(x + 1, y)
                    if oben and not unten:
                        neu[y][x] = heller(c, 0.3)
                    elif unten and not oben:
                        neu[y][x] = dunkler(c, 0.25)
            self.px = neu
        kontur = []
        for y in range(RASTER):
            for x in range(RASTER):
                if self.px[y][x] is not None:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < RASTER and 0 <= ny < RASTER:
                        n = self.px[ny][nx]
                        if n is not None and n != KONTUR:
                            kontur.append((x, y))
                            break
        for x, y in kontur:
            self.px[y][x] = KONTUR
        return self

    def _leer(self, x, y):
        if not (0 <= x < RASTER and 0 <= y < RASTER):
            return True
        return self.px[y][x] is None

    def speichern(self, name):
        faktor = GROESSE // RASTER
        roh = bytearray()
        for y in range(GROESSE):
            roh.append(0)
            for x in range(GROESSE):
                c = self.px[y // faktor][x // faktor]
                roh.extend(c if c is not None else (0, 0, 0, 0))
        pfad = os.path.join(ZIEL, name + '.png')
        with open(pfad, 'wb') as f:
            f.write(_png(GROESSE, GROESSE, bytes(roh)))
        return pfad


def _innen(x, y, punkte):
    innen = False
    j = len(punkte) - 1
    for i in range(len(punkte)):
        xi, yi = punkte[i]
        xj, yj = punkte[j]
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
            innen = not innen
        j = i
    return innen


def _png(breite, hoehe, roh):
    def chunk(art, daten):
        return (struct.pack('>I', len(daten)) + art + daten
                + struct.pack('>I', zlib.crc32(art + daten) & 0xFFFFFFFF))
    kopf = struct.pack('>IIBBBBB', breite, hoehe, 8, 6, 0, 0, 0)
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', kopf)
            + chunk(b'IDAT', zlib.compress(roh, 9)) + chunk(b'IEND', b''))


# --- Farben, an die Flächen der Grube angelehnt (`Palette.tint…`) ---

SILBER = farbe('c9d2dc')
STAHL = farbe('8c97a6')
GOLD = farbe('f2c14e')
BRAUN = farbe('8a5a32')
VIOLETT = farbe('8f5fc9')
VIOLETT_HELL = farbe('c4a6ec')
LAVA = farbe('f07a2a')
GLUT = farbe('ffd04a')
BLITZ = farbe('f4ec7a')
BLAU = farbe('6fa8f0')
ZEIT = farbe('9fa8f0')
GRUEN = farbe('6cc45a')
WEISS = farbe('f4f1ea')
SAND = farbe('d9b26a')
SCHUTZ = farbe('e0b65b')


def zinseszins():
    b = Bild()
    # Drei Säulen, die wachsen — davor die Klinge.
    for x, h in ((16, 6), (21, 10), (26, 14)):
        b.rechteck(x, 28 - h, x + 4, 28, GOLD)
    b.strich(5, 26, 19, 8, 3.2, SILBER)
    b.vieleck(((18, 6), (22, 4), (20, 9)), SILBER)
    b.linie(3, 22, 9, 28, 2.6, GOLD)
    b.linie(4, 27, 2, 29, 2.4, BRAUN)
    return b.fertig()


def schattenschritt():
    b = Bild()
    # Eine Gestalt, die eben noch woanders war: Streifen dahinter.
    for y, laenge in ((12, 9), (18, 12), (24, 8)):
        b.linie(3, y, 3 + laenge, y, 2, VIOLETT_HELL)
    b.kreis(21, 8, 4, VIOLETT)
    b.vieleck(((14, 28), (28, 28), (25, 13), (17, 13)), VIOLETT)
    return b.fertig()


def kampfrausch():
    b = Bild()
    b.kreis(16, 16, 12.5, farbe('4a2230'))
    for dx in (-6, 0, 6):
        b.strich(11 + dx, 24, 18 + dx, 8, 2.6, LAVA)
    return b.fertig()


def kriegsschrei():
    b = Bild()
    # Ein Horn, aus dem drei Bögen schallen.
    b.vieleck(((4, 20), (16, 13), (18, 21), (6, 24)), BRAUN)
    b.vieleck(((15, 11), (20, 9), (21, 25), (16, 23)), GOLD)
    for r in (5, 8.5, 12):
        b.ring(19, 17, r, 1.8, BLITZ, 300, 60)
    return b.fertig()


def spiegelbild():
    b = Bild()
    b.linie(16, 3, 16, 29, 1.4, BLAU)
    for x, c in ((9, SILBER), (23, heller(BLAU, 0.45))):
        b.kreis(x, 9, 4, c)
        b.vieleck(((x - 5, 27), (x + 5, 27), (x + 3, 14), (x - 3, 14)), c)
    return b.fertig()


def parade():
    b = Bild()
    b.vieleck(((6, 6), (26, 6), (25, 18), (16, 28), (7, 18)), SCHUTZ)
    b.vieleck(((10, 9), (22, 9), (21, 17), (16, 23), (11, 17)), heller(SCHUTZ, 0.25))
    b.strich(2, 2, 14, 14, 2.4, SILBER)
    # Funken, wo die Klinge abprallt.
    for dx, dy in ((16, 14), (13, 17), (18, 11)):
        b.setze(dx, dy, WEISS)
    return b.fertig()


def ruhepuls():
    b = Bild()
    b.kreis(11, 12, 6.5, ZEIT)
    b.kreis(21, 12, 6.5, ZEIT)
    b.vieleck(((4.8, 14), (27.2, 14), (16, 27)), ZEIT)
    pfad = ((3, 16), (11, 16), (13, 12), (16, 20), (19, 14), (21, 16), (29, 16))
    for (x0, y0), (x1, y1) in zip(pfad, pfad[1:]):
        b.linie(x0, y0, x1, y1, 1.6, WEISS)
    return b.fertig()


def kettenblitz():
    b = Bild()
    # Ein Blitz, und zwei kleine, auf die er weiterspringt.
    b.vieleck(((18, 1), (7, 16), (14, 16), (10, 30), (24, 12), (17, 12),
               (22, 1)), BLITZ)
    b.strich(24, 20, 29, 26, 1.6, heller(BLITZ, 0.3))
    b.strich(6, 22, 2, 28, 1.6, heller(BLITZ, 0.3))
    return b.fertig()


def rammbock():
    b = Bild()
    for y in (10, 16, 22):
        b.linie(2, y, 7, y, 1.4, SAND)
    b.rechteck(9, 12, 22, 20, BRAUN)
    b.linie(12, 12, 12, 20, 1, dunkler(BRAUN, 0.3))
    b.linie(17, 12, 17, 20, 1, dunkler(BRAUN, 0.3))
    b.vieleck(((21, 10), (27, 12), (29, 16), (27, 20), (21, 22)), STAHL)
    return b.fertig()


def zweiter_atem():
    b = Bild()
    b.ring(16, 16, 11, 3.6, GRUEN, 200, 160)
    b.rechteck(14, 9, 18, 23, WEISS)
    b.rechteck(9, 14, 23, 18, WEISS)
    return b.fertig()


def bestform():
    b = Bild()
    for i in range(8):
        w = math.radians(i * 45 + 22.5)
        b.linie(16, 16, 16 + math.cos(w) * 14, 16 + math.sin(w) * 14, 1.6, BLITZ)
    zacken = []
    for i in range(10):
        r = 12 if i % 2 == 0 else 5.2
        w = math.radians(-90 + i * 36)
        zacken.append((16 + math.cos(w) * r, 16 + math.sin(w) * r))
    b.vieleck(zacken, GOLD)
    b.kreis(16, 16, 3, heller(GOLD, 0.5))
    return b.fertig()


def rueckspulen():
    b = Bild()
    b.kreis(16, 16, 10, WEISS)
    b.ring(16, 16, 11.5, 2.2, ZEIT, 310, 210)
    # Die Spitze des Pfeils, der rückwärts läuft — gegen die Uhr.
    b.vieleck(((8, 3), (3, 9), (10, 10)), ZEIT)
    b.linie(16, 16, 16, 9, 1.6, farbe('4a4f8a'))
    b.linie(16, 16, 11, 19, 1.6, farbe('4a4f8a'))
    return b.fertig()


BILDER = {
    'Zinseszins': zinseszins,
    'Schattenschritt': schattenschritt,
    'Kampfrausch': kampfrausch,
    'Kriegsschrei': kriegsschrei,
    'Spiegelbild': spiegelbild,
    'Parade': parade,
    'Ruhepuls': ruhepuls,
    'Kettenblitz': kettenblitz,
    'Rammbock': rammbock,
    'ZweiterAtem': zweiter_atem,
    'Bestform': bestform,
    'Rueckspulen': rueckspulen,
}

if __name__ == '__main__':
    for name, zeichne in BILDER.items():
        print(zeichne().speichern(name))
