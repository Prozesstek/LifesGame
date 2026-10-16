# ADR-0075: Hundert Ebenen im selben Schritt

**Datum:** 16.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Die Grube hatte dreissig Stufen (ADR-0039, vorher die dreissig Sprossen
aus ADR-0032). Frederik schafft mit einer Kette von 27 Tagen Stufe 30
jedes Mal; oben war Schluss.

Am selben Tag ist der Fahrstuhl im Eingang weggefallen: Dort steht nur
noch die nächste Ebene.

Claude hatte vorgeschlagen, Ebene 100 so hart zu machen wie bisher
Stufe 30 und die Belohnung über alle hundert zu verteilen. Frederik:
„Ne baue das einfach mit den gleichen Abständen.“

## Entscheidung

**Es gibt hundert Stufen. Stufe 1 bis 30 bleiben Zahl für Zahl, wie sie
waren; darüber geht es im selben Schritt weiter.** Was geometrisch wuchs
(Leben, Angriff, Macht der Gegner), wächst je Stufe um denselben
Anteil; was linear wuchs (Verteidigung, Räume, Trollchance, Uhr,
Belohnung), um denselben Betrag.

Die Zahlen in `ActionBalance` gelten weiter für Stufe 1 und
`PitStage.referenceStage` (30). `PitStage.progress` ist dort 1 und
darüber grösser.

## Begründung

- Kein Spielstand muss umgerechnet werden; die Sperren im Laden (Episch
  ab 10, Legendär ab 20), die Errungenschaft „Sprosse 30“, die Sätze der
  Tagesgrube (11 bis 13) und alle gemessenen Siegquoten bleiben gültig.
- Es ist eine Zeile (`count`) und eine Bezugsgrösse, kein neues Modell.

## Gemessen

`dart run tool/pit_sim.dart 8`, mit einer neuen Spalte für den
stärksten denkbaren Helden (**Level 50**, beste Ausrüstung, legendäre
Kräfte, drei Fähigkeiten):

| Held | gewinnt sicher bis | letzte Stufe mit einem Sieg |
|---|---|---|
| Tag 60, Ausrüstung, drei Fähigkeiten | 29 | 30 (50 %) |
| **Level 50**, sonst ebenso | 37 | 41 (25 %) |

**Ab Stufe 42 gewinnt der Bot nie.** Der Bot ist dumm, die Quoten sind
eine untere Schranke — aber jede Stufe über 30 macht die Gegner um rund
ein Achtel stärker, der Held wächst um 4 % je Level und endet bei 50.
Stufe 100 ist rund tausendmal so stark wie Stufe 41. **Mit dem selben
Schritt ist die Grube praktisch bei 40 bis 45 zu Ende.**

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Stufe 100 so hart wie bisher 30, feiner dazwischen | Frederik wollte die gleichen Abstände |
| Summe der Belohnung gleich lassen | gehört zur verworfenen Alternative; die Belohnung wächst jetzt ebenso weiter (Stufe 100: 515 EP, 206 Gold; alle hundert zusammen 26.750 EP statt 2.775) |

## Konsequenzen

- **Die Wand liegt bei etwa 42**, auch mit Level 50. Die Ebenen darüber
  stehen da und lassen sich nicht schlagen.
- Die Summe der Belohnung (`LadderRewards.lifetimeXp`) ist zehnmal so
  gross, erreichbar ist davon nur, was vor der Wand liegt — bis Stufe 41
  rund 4.900 EP statt 2.775.
- Ab Stufe 30 wird jede Grube länger: Stufe 100 hätte zehn Räume statt
  fünf und knapp fünf Minuten auf der Uhr.
- Soll Stufe 100 erreichbar sein, braucht es einen **flacheren Schritt
  über 30** — eine Zahl in `PitStage`, gemessen mit `pit_sim`.
