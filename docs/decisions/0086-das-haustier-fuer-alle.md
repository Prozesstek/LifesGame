# ADR-0086: Das Haustier gibt es in jeder Fassung

**Datum:** 23.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Am 22.10. wurde das Haustier als Prototyp gebaut, **nur im
Entwicklermodus** (`devModeAvailable`): drei Eier, Wachstum an Tagen mit
Häkchen, Laune, Zubehör für Gold
([`docs/vorlagen/haustier.md`](../vorlagen/haustier.md)). Der ADR sollte
kommen, wenn beide es gespielt haben, und mit ihm die Frage, ob es in
den Store-Build geht.

Frederik am 23.10.: „ich hätte gerne das haustier auf der normalen
edition“.

## Entscheidung

Die Karte des Haustiers steht in jeder Fassung auf der Startseite über
„Heute“ — **sobald es eine Gewohnheit gibt**. Nur das Vorspulen der Tage
im Blatt bleibt dem Entwicklermodus.

## Begründung

Fortschritt, der nicht kämpft, ist der Grund für das Tier: Wer die
Grube nicht mag, soll trotzdem sehen, was seine Häkchen bewirken. Das
gilt im Store-Build mehr als im Entwicklermodus, und der Tester-Build
ab dem 26.10. ist die erste Gelegenheit, es an Fremden zu sehen.

**Erst mit der ersten Gewohnheit** (ohne Rückfrage entschieden): Davor
fragt die Startseite nach ihr, und der Mentor zeigt darauf (ADR-0079).
Drei Eier daneben wären die erste Wahl vor der ersten Gewohnheit — und
ein Ei wächst ohnehin erst mit einem Häkchen. Die Bedingung ist
`ErsterStart.fragtNachGewohnheit`, abgeleitet wie jeder Kreis.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Weiter nur im Entwicklermodus, bis beide gespielt haben | Frederik will es jetzt für alle |
| Von Anfang an, auch ohne Gewohnheit | stünde neben der ersten Frage des Mentors und lenkte von ihr ab |
| Erst nach dem ersten Häkchen | ein Schritt mehr als nötig; die Gewohnheit reicht, und dann sieht man das Ei, bevor man abhakt |
| Das Vorspulen auch im Store-Build | erfundene Tage gehören nicht in einen echten Stand (ADR-0021) |

## Konsequenzen

- **Zubehör kostet echtes Gold** im Store-Build. Das tat es auch vorher
  in jeder Fassung, nur sah es niemand. `runway_sim` zählt es weiter
  nicht.
- **Ungespielt**: Weder AktivesBrett noch ein Fremder hat das Tier
  gesehen; die Grafik ist gezeichnet, kein Paket.
- Wer das Tier vor dem 23.10. im Entwicklermodus auf dem echten Stand
  gewählt hat, behält es — der Stand war schon immer derselbe.
- Ein Ei mehr auf der Startseite verlängert sie; der Test-Build zeigt,
  ob „Heute“ dadurch zu tief rutscht.
