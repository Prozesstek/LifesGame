# ADR-0102: Die Tagestruhe kommt von selbst

**Datum:** 11.11.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Die Tagestruhe (ADR-0044) wartete seit ADR-0076 nur am Lagerfeuer: Wer
alles abgehakt hatte, musste wissen, dass dort eine Truhe steht, hingehen
und auf „Öffnen“ tippen. Der Moment, für den sie gebaut ist — der Tag ist
geschafft —, ging ohne sie vorbei.

Frederik: „Tagestruhe kommt automatisch wenn man alles abgehakt hat mit
Seltenheit wie bei DuoLingo oder Clash Royale durch Tippen.“

## Entscheidung

Nach dem letzten Häkchen des Tages steht die Truhe groß in der Mitte
(`TruheOeffnen`). **Drei Tipps**: Sie wackelt, leuchtet stärker und
klingt höher; beim dritten springt sie in der Farbe ihrer **Seltenheit**
auf. Die vier Stufen heißen Gewöhnlich, Selten, Episch, Legendär
(`ChestTier.label`, Farben aus `RarityBadge`) — **Gewicht und Gold sind
dieselben wie vorher**. Die Seltenheit sieht man erst beim Aufgehen.

Gebucht wird beim dritten Tipp. Wer vorher schließt oder die App
verlässt, findet sie am Lagerfeuer, wo sie genauso aufgeht. Wie das
Feuer kommt sie erst ab Level 3, im Tutorial nicht.

## Begründung

Die vier Fragen wurden alle wie empfohlen beantwortet:

| Frage | Entschieden |
|---|---|
| Seltenheit | nur umbenennen — die Wirtschaft bleibt unberührt (`runway_sim`) |
| Wann sichtbar | erst beim Aufgehen — mehr Spannung |
| Wie oft tippen | drei Mal |
| Weggetippt | wartet am Feuer, ab Level 3 |

Die Reihenfolge nach dem letzten Häkchen: Flamme und Konfetti, **dann die
Truhe**, dann Errungenschaften, Aufstieg, Fähigkeiten und „Morgen
zuerst“. Die Truhe ist der Lohn des Tages; was danach kommt, erzählt
davon.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Höhere Truhen bringen mehr (Schlüssel, Ausrüstung) | ändert die Goldkurve; braucht eine eigene Runde mit `runway_sim` |
| Seltenheit vorher sichtbar (wie Clash Royale) | weniger Spannung beim Tippen |
| Ein Tipp öffnet sofort | kein Aufbau, kein Moment |
| Truhe nur noch automatisch, nicht mehr am Feuer | wer sie wegtippt, verlöre sie |
| Schon im Tutorial | unterbräche den Weg des Mentors |

## Konsequenzen

- ADR-0076 („Truhe und Aufgaben gibt es nur am Feuer“) gilt für die
  Truhe nicht mehr; das Feuer ist ihr zweiter Ort.
- Nach dem letzten Häkchen steht ein Dialog mehr. Tests, die den Tag
  schaffen und danach weitermachen, tippen sie auf (`test/truhe_helfer.dart`).
- Die Klänge sind vorhandene Platzhalter: Töne der Tonleiter beim
  Tippen, beim Aufgehen je nach Seltenheit Sieg, Errungenschaft oder
  Legendär.
- Das Gold zählt in der Mitte hoch, es fliegt nicht zur Leiste.
