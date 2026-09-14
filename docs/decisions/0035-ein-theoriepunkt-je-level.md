# ADR-0035: Ein Theoriepunkt je Level statt zwei

**Datum:** 14.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

[ADR-0019](0019-skillbaum-mit-vier-wurzeln.md) hat die Zahl aus ADR-0012
verdoppelt: zwei Theoriepunkte je Levelaufstieg. Die unangenehme Folge
stand dort selbst: 98 Punkte über ein Spielerleben für einen Startbaum aus
20 kostenpflichtigen Knoten, **ab Level 11 ist jeder weitere Punkt
wertlos**. Der Baum war damit eine Reihenfolge, keine Entscheidung. ADR-0019
nannte das einen Zwischenzustand mit Ablaufdatum.

## Entscheidung

Ein Levelaufstieg gibt **einen** Theoriepunkt. Ein Knoten kostet weiter
einen Punkt, die vier Wurzeln und das Handbuch weiter nichts. Die Zahl
steht als `TheoryPoints.perLevel` in `packages/progression` und nirgends
sonst.

## Begründung

Knappheit ist der Grund, warum es Punkte gibt. Mit einem je Level steht
der Startbaum ab Level 21 ganz offen statt ab Level 11. Bis dahin muss
man wählen, welches Gebiet zuerst dran ist, und genau diese Wahl sollte
der Baum laut ADR-0012 erzwingen.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Bei zwei Punkten bleiben, bis der Baum 40 Knoten hat | Der Auslöser aus ADR-0019 setzt Schreibarbeit voraus, die vor dem 30-Tage-Lauf nicht kommt. Bis dahin wäre der Baum im Test fast durchgehend offen. |
| Knoten teurer machen (2 Punkte) | Dieselbe Rechnung, aber mit mehr Zahlen an mehr Stellen: Knotenkosten stehen am Knoten, der Vorrat in `progression`. Eine Zahl zu ändern ist die kleinere Änderung. |

## Konsequenzen

| | Punkte gesamt | Knoten im Startbaum | Baum komplett offen ab |
|---|---|---|---|
| ADR-0019 (2 Punkte) | 98 | 20 | Level 11 |
| **ADR-0035 (1 Punkt)** | **49** | **20** | **Level 21** |

**Der Weg zum ersten Kampf bleibt offen.** Auf Level 3 geht der zweite
Fähigkeitsplatz auf; dort gibt es jetzt zwei Punkte statt vier, und ein
Knoten mit Fähigkeit kostet einen. `test/abilities_seam_test.dart` prüft
das weiter und bleibt grün.

**Bestehende Spielstände verlieren nichts, was sie haben.** Ausgegebene
Punkte werden aus den geöffneten Knoten gerechnet, nicht gespeichert
(ADR-0019). Ein Stand, der mehr Knoten geöffnet hat, als er jetzt Punkte
hätte, behält sie; `TheoryPoints.availableAt` zeigt dann 0 statt einer
negativen Zahl (ADR-0010: nachsichtig lesen). Neue Knoten gibt es für ihn
erst, wenn das Level aufgeholt hat.

**Die Balance-Simulation wird pessimistischer.** `tool/balance_sim.dart`
nimmt an, dass jeder Punkt in einen Knoten mit Fähigkeit geht. Mit halb so
vielen Punkten fallen dem simulierten Spieler Fähigkeiten später zu. Die
Zahlen in `state.md` sind nicht neu gerechnet; Balancing bleibt
zurückgestellt.

**Der Entwicklermodus** schenkt mit „Alles freischalten" weiter
`TheoryPoints.lifetimeTotal`, jetzt 49. Das reicht für den Startbaum.
