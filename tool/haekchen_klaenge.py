"""Erzeugt die Klänge des Häkchens nach `assets/Sound/`.

**Die Tonleiter des Tages.** Jedes Häkchen eines Tages klingt eine Stufe
höher als das davor — fünf Töne, so viele Gewohnheiten laufen höchstens
(`HabitRewards.maxActiveHabits`). Das letzte Fällige löst den Akkord
auf, in dem die Leiter steht. Pentatonisch in C-Dur: Wer schnell
hintereinander abhakt, hört eine Melodie, und keine zwei Stufen beißen
sich.

**Platzhalter**, gerechnet wie die Klänge der Grube: Sinuswellen mit
Obertönen und einer Hüllkurve, damit sie dem Projekt gehören. Wer
bessere hat, legt sie unter demselben Namen ab oder ändert die Zeile in
`SoundEffect` (`lib/audio/sound_effects.dart`).

Aufruf, aus dem Wurzelverzeichnis:

    python tool/haekchen_klaenge.py

Braucht nur die Standardbibliothek und die Helfer aus
`tool/kampf_klaenge.py` daneben.
"""

import math
import random

from kampf_klaenge import ZIEL, _Rauschen, _Ton, _gleiten, _huelle, _klang, schreibe

# Die Leiter: G5, A5, C6, D6, E6 — und davor E5 als Auftakt der ersten.
LEITER = (659.3, 784.0, 880.0, 1046.5, 1174.7, 1318.5)

# Grundton, Oktave, Duodezime und ein leicht schiefer vierter Teilton,
# der die Glocke nach Metall statt nach Flöte klingen lässt. Je höher,
# desto leiser und desto schneller verklungen.
_TEILTOENE = ((1.0, 1.0, 1.0), (2.0, 0.45, 1.8), (3.0, 0.2, 2.6), (4.2, 0.08, 3.5))


class _Glocke:
    """Ein angeschlagener Ton mit seinen Obertönen."""

    def __init__(self, hertz, abklingen):
        self.hertz = hertz
        self.abklingen = abklingen
        self.toene = [_Ton() for _ in _TEILTOENE]

    def wert(self, t):
        if t < 0:
            return 0.0
        anschlag = min(1.0, t / 0.003)
        summe = 0.0
        for (faktor, anteil, schnell), ton in zip(_TEILTOENE, self.toene):
            summe += anteil * math.exp(-schnell * t / self.abklingen) * ton.sinus(
                self.hertz * faktor
            )
        return anschlag * summe


def ton(stufe):
    """Das Häkchen Nummer `stufe` (1 bis 5): ein kurzer Auftakt auf der
    Stufe darunter, dann die eigene, die nachklingt. Die zwei Töne sind
    der Schritt nach oben, den man hört."""
    dauer = 0.5
    auftakt = _Glocke(LEITER[stufe - 1], abklingen=0.09)
    haupt = _Glocke(LEITER[stufe], abklingen=0.32)
    versatz = 0.055

    def stimme(t, anteil):
        return 0.55 * auftakt.wert(t) + haupt.wert(t - versatz)

    return _klang(dauer, stimme, 0.42)


def tag_geschafft():
    """Das letzte Fällige des Tages: die Leiter hinauf bis zum hohen C,
    dann der C-Dur-Akkord, der stehen bleibt. Länger als jedes Häkchen,
    kürzer als die Fanfare einer Errungenschaft."""
    schritt = 0.065
    lauf = [_Glocke(h, abklingen=0.14) for h in (1046.5, 1318.5, 1568.0)]
    akkord = [_Glocke(h, abklingen=0.7) for h in (523.3, 659.3, 784.0, 2093.0)]
    einsatz = schritt * len(lauf)
    dauer = einsatz + 1.1

    def stimme(t, anteil):
        summe = sum(0.6 * g.wert(t - i * schritt) for i, g in enumerate(lauf))
        summe += sum(
            (0.5 if i == 3 else 0.8) * g.wert(t - einsatz)
            for i, g in enumerate(akkord)
        )
        return summe

    return _klang(dauer, stimme, 0.55)


def kette():
    """Das erste Häkchen des Tages zündet die Flamme: ein Fauchen, das
    aufreißt, und ein weicher Stoß darunter. Kein Ton — er liegt über
    dem Ton des Häkchens und soll sich nicht mit ihm reiben."""
    dauer = 0.42
    rauschen = _Rauschen(7, 0.05)
    grund = _Ton()

    def stimme(t, anteil):
        # Der Tiefpass öffnet sich: aus dem Brummen wird ein Fauchen.
        rauschen.weich = 0.04 + 0.5 * min(1.0, anteil * 2.2)
        h = _huelle(t, dauer, anstieg=0.06, schaerfe=3.2)
        stoss = grund.sinus(_gleiten(90, 180, anteil)) * math.exp(-anteil * 6)
        return h * (0.9 * rauschen.naechstes() + 0.5 * stoss)

    return _klang(dauer, stimme, 0.32)


def kette_steigt():
    """Die große Flamme in der Mitte: Die Zahl der Tageskette springt
    einen Tag höher. Vier Glocken die Leiter hinauf, die letzte klingt
    nach, darüber ein Knistern wie Funken. Heller als ein Häkchen,
    kürzer als der Akkord eines geschafften Tages."""
    schritt = 0.06
    lauf = [
        _Glocke(h, abklingen=a)
        for h, a in ((784.0, 0.12), (1046.5, 0.12), (1318.5, 0.14), (1568.0, 0.55))
    ]
    knistern = _Rauschen(13, 0.6)
    # Neun Knackser, immer weiter auseinander — gesät, nicht gewürfelt.
    zufall = random.Random(29)
    knackser = [
        0.04 + 0.06 * i * (1 + 0.15 * i) + zufall.uniform(0, 0.03) for i in range(9)
    ]
    dauer = schritt * 3 + 0.8

    def stimme(t, anteil):
        summe = sum(
            (0.5 if i < 3 else 0.85) * g.wert(t - i * schritt)
            for i, g in enumerate(lauf)
        )
        # Jeder Knackser ist ein Hauch Rauschen, nach ein paar
        # Millisekunden vorbei.
        knack = sum(math.exp(-(t - k) * 140) for k in knackser if t >= k)
        return summe + 0.4 * knistern.naechstes() * knack

    return _klang(dauer, stimme, 0.45)


KLAENGE = {
    **{f"Ton{stufe}": (lambda s=stufe: ton(s)) for stufe in range(1, 6)},
    "TagGeschafft": tag_geschafft,
    "Kette": kette,
    "KetteSteigt": kette_steigt,
}


def main():
    ZIEL.mkdir(parents=True, exist_ok=True)
    for name, bauen in KLAENGE.items():
        pfad = schreibe(name, bauen())
        print(f"{pfad.name}: {pfad.stat().st_size} Bytes")


if __name__ == "__main__":
    main()
