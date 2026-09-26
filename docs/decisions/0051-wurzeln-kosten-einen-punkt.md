# ADR-0051: Die Wurzeln kosten einen Punkt

**Datum:** 26.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Nachdem das Gerüst aus [ADR-0050](0050-zwischenebenen-und-angekuendigte-gebiete.md)
stand, wollte Frederik, dass auch die vier Wurzeln — Körper, Geist,
Wissenschaft, Gesellschaft — einen Theoriepunkt kosten. Bis dahin waren
sie kostenlos (ADR-0019: „der Einstieg in ein Gebiet darf nichts
kosten").

Das hat eine Folge für die Kette zum ersten Kampf (ADR-0018, ADR-0020):
Das Handbuch führt genau auf Level 3, dort geht der zweite
Fähigkeitsplatz auf, und die Grube öffnet sich erst, wenn eine Fähigkeit
angelegt ist. Der Weg zur ersten Fähigkeit war nach ADR-0050 zwei Punkte
lang (Zwischenebene, Thema), und Level 3 gab zwei. Mit der Wurzel sind es
drei.

## Entscheidung

1. **Jede Wurzel kostet einen Punkt**, wie jeder andere Knoten.
2. **Jeder Charakter beginnt mit einem Theoriepunkt**
   (`TheoryPoints.atStart`). Level 1 hat einen, Level 3 hat drei, über
   ein Spielerleben sind es 50 statt 49.
3. **Die Übernahme alter Stände ist eine allgemeine Regel statt einer
   Liste.** Ein Knoten gilt als offen, wenn
   - er im Spielstand steht (bezahlt),
   - er nichts kostet,
   - **seine Seite bestanden ist** — lesen ging nur, solange er offen
     war, oder
   - **er der einzige Eltern eines offenen Knotens ist**
     (`TheoryGraph.withSoleParents`) — ein Kind mit einem Eltern ließ sich
     nur über diesen öffnen.

   Das ersetzt `TheoryNode.legacyOpenedBy` und `TheoryGraph.strayGrants`
   aus ADR-0050.

## Begründung

**Warum ein Startpunkt und nicht die Grube eine Stufe später.** Die
Kette Handbuch → Level 3 → zweiter Platz → Grube ist gemessen (ADR-0018)
und wird in `progression_test.dart` und `abilities_seam_test.dart`
gehalten. Ein geschenkter Punkt hält sie, ohne an Levelkurve, Slots oder
Handbuch zu drehen. Die Wahl bleibt echt: Mit einem Punkt öffnet man
**eine** Wurzel.

**Warum die allgemeine Regel.** Mit kostenpflichtigen Wurzeln hätte die
Liste aus ADR-0050 eine zweite Stufe gebraucht: Wer Schlaf offen hatte,
bekam Schlaf & Regeneration geschenkt — aber nicht Körper. Die Regel
„einziger Eltern eines Offenen ist offen" deckt jede Tiefe ab, braucht
keine Pflege, wenn neue Themen dazukommen, und ist für neue Spieler
wirkungslos, weil sie ohnehin über den Eltern gehen mussten. „Bestanden
heißt offen" hält die Wurzelseiten offen, die fast jeder schon gelesen
hat, als sie noch nichts kosteten.

**Warum Stress und Vergleich weiter nichts schenken.** Sie haben zwei
Eltern; ob Schlaf & Regeneration oder Geist offen war, lässt sich nicht
sagen. Wer nur Stress über Geist geöffnet hatte, behält Stress — Geist
selbst hat er fast sicher gelesen und behält es über die zweite Regel.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Die erste Fähigkeit erst auf Level 4 | Das Handbuch allein reichte dann nicht mehr für den ersten Kampf; der zweite Platz ginge leer auf |
| Zweiter Platz erst auf Level 4 | dreht an `AbilitySlots` und am Zusammenhang aus ADR-0018 |
| `legacyOpenedBy` um eine Stufe erweitern | eine Liste, die mit jedem neuen Thema gepflegt werden will — und bei jeder vergessenen Zeile einen Punkt kostet |

## Konsequenzen

- **Der befüllte Baum kostet 32 Punkte** und steht ab Level 32 ganz
  offen. `runway_sim`: an Tag 30 sind 20 statt 23 Knoten offen, gelesen
  ist der Baum an Tag 58 statt Tag 50.
- **Wer die Wurzel noch nicht gelesen hat und nichts darunter offen hat,
  zahlt jetzt einen Punkt dafür.** Für uns zwei im Test betrifft das
  höchstens eine Wurzel, die keiner angesehen hat.
- `TheoryNode.isFree` gibt es weiter, im Graphen ist aber kein Knoten
  mehr frei. Das Handbuch ist kein Knoten und bleibt kostenlos.
- ADR-0019 ist in diesem Punkt abgelöst; ADR-0050 in der Frage, wie alte
  Stände übernommen werden.
