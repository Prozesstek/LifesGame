"""Erzeugt die Klänge einer Seite im Wissensbaum nach `assets/Sound/`.

**Eine richtige Antwort braucht keinen eigenen Klang**: Sie klettert die
Tonleiter des Häkchens hinauf (`tool/haekchen_klaenge.py`), eine Stufe
je richtiger Antwort in Folge. Was fehlte, ist der Klang, wenn es nicht
stimmt.

Der darf nicht strafen. Zwei weiche, tiefe Schläge abwärts, wie ein
„hm“ — man hört, dass es nicht saß, und nicht, dass man versagt hat.
Dumpf statt glockig, damit er sich von der Leiter unterscheidet.

**Das Umblättern** (`Blaettern`) raschelt: helles Rauschen, das in
Körnern knistert, anschwillt und mit einem weichen Klapp ausläuft, wenn
das Blatt liegt.

**Platzhalter**, gerechnet wie die Klänge der Grube. Wer bessere hat,
legt sie unter demselben Namen ab oder ändert die Zeile in
`SoundEffect` (`lib/audio/sound_effects.dart`).

Aufruf, aus dem Wurzelverzeichnis:

    python tool/lern_klaenge.py

Braucht nur die Standardbibliothek und die Helfer aus
`tool/kampf_klaenge.py` daneben.
"""

import math

import random

from kampf_klaenge import ZIEL, _Rauschen, _Ton, _klang, schreibe


class _Holz:
    """Ein gedämpfter Schlag: Grundton und eine schwache Oktave, beide
    schnell verklungen — eher Holz als Metall."""

    def __init__(self, hertz, abklingen):
        self.hertz = hertz
        self.abklingen = abklingen
        self.grund = _Ton()
        self.oktave = _Ton()

    def wert(self, t):
        if t < 0:
            return 0.0
        anschlag = min(1.0, t / 0.006)
        grund = math.exp(-t / self.abklingen) * self.grund.sinus(self.hertz)
        oktave = math.exp(-2.5 * t / self.abklingen) * self.oktave.sinus(
            self.hertz * 2
        )
        return anschlag * (grund + 0.25 * oktave)


def falsch():
    """Eine falsche Antwort: G4, dann Es4 — eine große Terz abwärts, der
    zweite Schlag länger. Leiser als jeder Ton der Leiter."""
    dauer = 0.4
    erst = _Holz(392.0, abklingen=0.06)
    dann = _Holz(311.1, abklingen=0.13)
    versatz = 0.09

    def stimme(t, anteil):
        return 0.8 * erst.wert(t) + dann.wert(t - versatz)

    return _klang(dauer, stimme, 0.32)


def blaettern():
    """Ein Blatt wird umgeschlagen: Papier schleift gut eine Viertel-
    sekunde, dann klappt es leise auf. Leiser als jede Antwort."""
    dauer = 0.42
    schleifen = _Rauschen(saat=71, weich=0.55)
    klapp = _Rauschen(saat=72, weich=0.06)
    koerner = random.Random(73)
    knistern = [1.0]

    def stimme(t, anteil):
        # Alle paar Millisekunden ein neues Korn: Papier knistert, es
        # rauscht nicht gleichmässig.
        if koerner.random() < 0.004:
            knistern[0] = koerner.uniform(0.35, 1.0)
        # Anschwellen bis 0,16 s, dann auslaufen.
        if t < 0.16:
            huelle = (t / 0.16) ** 1.5
        else:
            huelle = math.exp(-(t - 0.16) / 0.07)
        papier = huelle * knistern[0] * schleifen.naechstes()
        # Der Klapp, wenn das Blatt liegt: tief und kurz.
        dt = t - 0.26
        unten = 0.0
        if dt >= 0:
            unten = 2.2 * math.exp(-dt / 0.035) * min(1.0, dt / 0.004)
        return papier + unten * klapp.naechstes()

    return _klang(dauer, stimme, 0.22)


KLAENGE = {
    "Falsch": falsch,
    "Blaettern": blaettern,
}


def main():
    ZIEL.mkdir(parents=True, exist_ok=True)
    for name, bauen in KLAENGE.items():
        pfad = schreibe(name, bauen())
        print(f"{pfad.name}: {pfad.stat().st_size} Bytes")


if __name__ == "__main__":
    main()
