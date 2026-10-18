"""Erzeugt die Klänge einer Seite im Wissensbaum nach `assets/Sound/`.

**Eine richtige Antwort braucht keinen eigenen Klang**: Sie klettert die
Tonleiter des Häkchens hinauf (`tool/haekchen_klaenge.py`), eine Stufe
je richtiger Antwort in Folge. Was fehlte, ist der Klang, wenn es nicht
stimmt.

Der darf nicht strafen. Zwei weiche, tiefe Schläge abwärts, wie ein
„hm“ — man hört, dass es nicht saß, und nicht, dass man versagt hat.
Dumpf statt glockig, damit er sich von der Leiter unterscheidet.

**Platzhalter**, gerechnet wie die Klänge der Grube. Wer bessere hat,
legt sie unter demselben Namen ab oder ändert die Zeile in
`SoundEffect` (`lib/audio/sound_effects.dart`).

Aufruf, aus dem Wurzelverzeichnis:

    python tool/lern_klaenge.py

Braucht nur die Standardbibliothek und die Helfer aus
`tool/kampf_klaenge.py` daneben.
"""

import math

from kampf_klaenge import ZIEL, _Ton, _klang, schreibe


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


KLAENGE = {
    "Falsch": falsch,
}


def main():
    ZIEL.mkdir(parents=True, exist_ok=True)
    for name, bauen in KLAENGE.items():
        pfad = schreibe(name, bauen())
        print(f"{pfad.name}: {pfad.stat().st_size} Bytes")


if __name__ == "__main__":
    main()
