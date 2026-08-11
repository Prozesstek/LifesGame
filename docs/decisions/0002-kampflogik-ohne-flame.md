# ADR-0002: Kampflogik als reines Dart, Flame nur als Abspieler

**Datum:** 11.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Der Kampf ist das Element, an dem das ganze Konzept hängt: Wenn er sich nicht gut
anfühlt, hakt niemand am nächsten Tag Habits ab. Er wird also oft geändert, oft
gebalanced und muss oft getestet werden.

Gleichzeitig ist er das Einzige, was in Flame läuft. Wenn Spielregeln in
Flame-`Component`-Klassen wandern, braucht jeder Test eine laufende Game-Loop.
Balance-Änderungen werden dann teuer, obwohl sie inhaltlich trivial sind.

## Entscheidung

Die gesamte Kampflogik — Schadensberechnung, Energie, Statuseffekte, Zugreihenfolge,
Siegbedingung — liegt in reinem Dart **ohne einen einzigen Flame-Import**. Sie nimmt
Eingaben entgegen und gibt eine Liste von Events aus. Flame liest diese Events und
spielt sie ab.

## Begründung

Die Trennung fällt entlang der Frage „Ändert sich das aus Balance-Gründen oder aus
Darstellungsgründen?". Balance-Code ohne Engine-Abhängigkeit lässt sich in
Millisekunden testen — man kann tausend Kämpfe simulieren, um zu prüfen, ob ein
Streak-Multiplikator von x2 den Boss trivialisiert. Mit Engine im Test geht das nicht.

Der Event-Strom ist zusätzlich die natürliche Naht für die Aufgabenteilung im Team:
Einer kann an der Logik arbeiten, der andere an der Darstellung, solange beide sich
auf das Event-Interface geeinigt haben.

Nebeneffekt: Timed Hits bleiben sauber modellierbar. Die Logik bekommt „Treffer kam
im Fenster, Faktor 1,4" als Eingabe — dass das Fenster in Flame gemessen wurde,
interessiert sie nicht.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Logik direkt in Flame-`Component`s | Der bequeme Weg, und genau der, der Balance-Tests unbezahlbar macht. Jeder Test bräuchte eine Game-Loop. |
| Logik im Riverpod-Provider | Testbar, aber koppelt Spielregeln an das State-Management-Framework. Ein Wechsel oder eine Simulation außerhalb der App wäre unnötig schwer. |

## Konsequenzen

**Leichter:** Kampfregeln sind mit gewöhnlichen `dart test`-Tests abgedeckt. Balance
lässt sich per Simulation über viele Durchläufe prüfen, statt sie zu erfühlen.
Klare Arbeitsteilung im Zweierteam.

**Schwerer:** Es braucht ein explizites, gepflegtes Event-Vokabular
(`DamageDealt`, `EnergyChanged`, `StatusApplied`, …). Das ist zusätzliche Arbeit
und zusätzliche Disziplin — die Versuchung, „nur schnell" in der Flame-Komponente
zu rechnen, kommt garantiert.

**Regel bei Zweifel:** Wenn Code eine Zahl bestimmt, gehört er in die Logik. Wenn er
bestimmt, wie eine Zahl aussieht oder klingt, gehört er in Flame.
