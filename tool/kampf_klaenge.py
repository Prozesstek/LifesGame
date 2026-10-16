"""Erzeugt die acht Klänge der Grube nach `assets/Sound/`.

**Platzhalter.** Die Klänge sind gerechnet, nicht aufgenommen: Rauschen,
ein paar Sinus- und Rechteckwellen, eine Hüllkurve. Damit gehören sie
dem Projekt, und es gibt keine Lizenz zu klären. Wer bessere hat, legt
sie unter demselben Namen ab oder ändert die Zeile in `SoundEffect`
(`lib/audio/sound_effects.dart`).

Aufruf, aus dem Wurzelverzeichnis:

    python tool/kampf_klaenge.py

Braucht nur die Standardbibliothek. Der Zufall ist gesät: Zwei Läufe
ergeben dieselben Dateien.
"""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
ZIEL = Path(__file__).resolve().parent.parent / "assets" / "Sound"


def _huelle(t, dauer, anstieg=0.004, schaerfe=4.0):
    """Schneller Anstieg, dann exponentiell aus."""
    if t < anstieg:
        return t / anstieg
    return math.exp(-schaerfe * (t - anstieg) / dauer)


def _gleiten(von, bis, anteil):
    """Tonhöhe von `von` nach `bis`, im Verhältnis statt in Hertz."""
    return von * (bis / von) ** anteil


def _klang(dauer, stimme, laut):
    """Rechnet `stimme(t, anteil)` über die Dauer aus."""
    n = int(RATE * dauer)
    werte = [stimme(i / RATE, i / n) for i in range(n)]
    spitze = max(abs(w) for w in werte) or 1.0
    # Die letzten Millisekunden auf null ziehen, sonst knackt das Ende.
    aus = int(RATE * 0.008)
    for i in range(aus):
        werte[n - 1 - i] *= i / aus
    return [w / spitze * laut for w in werte]


class _Ton:
    """Eine Welle, deren Tonhöhe sich ändern darf, ohne zu springen."""

    def __init__(self):
        self.phase = 0.0

    def sinus(self, hertz):
        self.phase += 2 * math.pi * hertz / RATE
        return math.sin(self.phase)

    def rechteck(self, hertz):
        return 1.0 if self.sinus(hertz) >= 0 else -1.0


class _Rauschen:
    """Weisses Rauschen, mit einem einfachen Tiefpass gedämpft."""

    def __init__(self, saat, weich):
        self.zufall = random.Random(saat)
        self.weich = weich
        self.wert = 0.0

    def naechstes(self):
        roh = self.zufall.uniform(-1, 1)
        self.wert += (roh - self.wert) * self.weich
        return self.wert


def treffer():
    """Der Held trifft: ein kurzer, dumpfer Schlag. Der häufigste Klang
    der Grube, deshalb der kürzeste und leiseste."""
    dauer = 0.07
    ton, rauschen = _Ton(), _Rauschen(1, 0.55)

    def stimme(t, anteil):
        h = _huelle(t, dauer, schaerfe=6)
        schlag = ton.sinus(_gleiten(210, 90, anteil))
        return h * (0.6 * schlag + 0.7 * rauschen.naechstes())

    return _klang(dauer, stimme, 0.38)


def getroffen():
    """Der Held wird getroffen: tiefer und rauer als der eigene Schlag,
    damit man beide nicht verwechselt."""
    dauer = 0.16
    ton, rauschen = _Ton(), _Rauschen(2, 0.25)

    def stimme(t, anteil):
        h = _huelle(t, dauer, schaerfe=5)
        brummen = ton.rechteck(_gleiten(170, 60, anteil))
        return h * (0.5 * brummen + 0.6 * rauschen.naechstes())

    return _klang(dauer, stimme, 0.5)


def gefallen():
    """Ein Gegner fällt: ein Schlag, der nach unten wegsackt."""
    dauer = 0.24
    ton, tief, rauschen = _Ton(), _Ton(), _Rauschen(3, 0.4)

    def stimme(t, anteil):
        h = _huelle(t, dauer, schaerfe=4.5)
        sacken = ton.sinus(_gleiten(520, 70, anteil))
        grund = tief.sinus(_gleiten(130, 45, anteil))
        knall = rauschen.naechstes() * math.exp(-anteil * 9)
        return h * (0.55 * sacken + 0.5 * grund + 0.8 * knall)

    return _klang(dauer, stimme, 0.55)


def faehigkeit():
    """Eine Fähigkeit wird gewirkt: ein heller Zug nach oben."""
    dauer = 0.28
    ton, quinte, rauschen = _Ton(), _Ton(), _Rauschen(4, 0.8)

    def stimme(t, anteil):
        h = _huelle(t, dauer, anstieg=0.02, schaerfe=3.5)
        hertz = _gleiten(330, 880, anteil)
        zug = ton.sinus(hertz) + 0.45 * quinte.sinus(hertz * 1.5)
        hauch = rauschen.naechstes() * (1 - anteil)
        return h * (zug + 0.25 * hauch)

    return _klang(dauer, stimme, 0.42)


def ankuendigung():
    """Der Wächter holt aus: zwei tiefe Stösse. Eine Warnung, kein
    Treffer — deshalb ein Ton und kein Rauschen."""
    dauer = 0.3
    ton = _Ton()

    def stimme(t, anteil):
        # Zwei Stösse, der zweite eine kleine Terz tiefer.
        zweiter = t >= dauer / 2
        lokal = t - dauer / 2 if zweiter else t
        h = _huelle(lokal, dauer / 2, anstieg=0.006, schaerfe=5)
        hertz = 196 if zweiter else 233
        welle = ton.sinus(hertz)
        return h * (welle + 0.3 * (1.0 if welle >= 0 else -1.0))

    return _klang(dauer, stimme, 0.45)


def muenze():
    """Eine Münze kommt an: das klassische Pling, zwei helle Töne kurz
    hintereinander, der zweite eine Quarte höher. Fällt im Brunnen des
    Wächters dutzendfach — deshalb kurz und nicht zu laut."""
    dauer = 0.13
    ton = _Ton()

    def stimme(t, anteil):
        zweiter = t >= 0.045
        lokal = t - 0.045 if zweiter else t
        h = _huelle(lokal, dauer, anstieg=0.002, schaerfe=5)
        hertz = 1319 if zweiter else 988
        welle = ton.sinus(hertz)
        # Ein Hauch Rechteck macht es metallisch statt flötig.
        return h * (welle + 0.25 * (1.0 if welle >= 0 else -1.0))

    return _klang(dauer, stimme, 0.3)


def funke():
    """Ein Funke Erfahrung kommt an: ein weicher Zug nach oben, leiser
    als die Münze, damit beide zusammen nicht scheppern."""
    dauer = 0.07
    ton = _Ton()

    def stimme(t, anteil):
        h = _huelle(t, dauer, anstieg=0.004, schaerfe=4)
        return h * ton.sinus(_gleiten(1100, 1760, anteil))

    return _klang(dauer, stimme, 0.22)


def aufstieg():
    """Ein Level mitten im Lauf: vier Töne aufwärts, C-Dur, der letzte
    klingt nach. Der seltenste Klang der Grube, deshalb der längste."""
    schritt = 0.075
    noten = (523, 659, 784, 1047)
    dauer = schritt * (len(noten) - 1) + 0.4
    ton, quinte = _Ton(), _Ton()

    def stimme(t, anteil):
        index = min(int(t / schritt), len(noten) - 1)
        lokal = t - index * schritt
        letzte = index == len(noten) - 1
        h = _huelle(lokal, 0.4 if letzte else schritt * 2, schaerfe=3.5)
        hertz = noten[index]
        return h * (ton.sinus(hertz) + 0.35 * quinte.sinus(hertz * 1.5))

    return _klang(dauer, stimme, 0.5)


KLAENGE = {
    "Treffer": treffer,
    "Getroffen": getroffen,
    "Gefallen": gefallen,
    "Faehigkeit": faehigkeit,
    "Ankuendigung": ankuendigung,
    "Muenze": muenze,
    "Funke": funke,
    "Aufstieg": aufstieg,
}


def schreibe(name, werte):
    pfad = ZIEL / f"{name}.wav"
    with wave.open(str(pfad), "wb") as datei:
        datei.setnchannels(1)
        datei.setsampwidth(2)
        datei.setframerate(RATE)
        datei.writeframes(
            b"".join(struct.pack("<h", int(w * 32767)) for w in werte)
        )
    return pfad


def main():
    ZIEL.mkdir(parents=True, exist_ok=True)
    for name, bauen in KLAENGE.items():
        pfad = schreibe(name, bauen())
        print(f"{pfad.name}: {pfad.stat().st_size} Bytes")


if __name__ == "__main__":
    main()
