# ADR-0064: Wochenplan je Gewohnheit, und eine Kette, die fällt statt zu reißen

**Datum:** 02.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik (in zwei Fragerunden mit Claude)

## Kontext

Eine kritische Durchsicht vor einer möglichen Veröffentlichung
(`state.md`, 02.10.2026) nannte zwei Dinge, die am Kern liegen und nicht
an der Verpackung:

- **Jede Gewohnheit war täglich.** „Dreimal die Woche Training“ oder „nur
  werktags“ ging nicht. Ein geplanter Ruhetag riss die Kette genauso wie
  ein vergessener Tag.
- **Ein verpasster Tag setzte die Kette auf null.** Das Streak-Eis
  (ADR-0036) fällt nur aus etwa jeder zwölften Truhe und deckt nur
  gestern. `konzept.md` 3.7 sagt „Verpassen wird nicht bestraft“ — der
  Verlust einer 45-Tage-Kette an einem Tag ist eine Strafe.

An der stillen Annahme „heute ist alles dran“ hingen die Kette je
Gewohnheit, die Tageskette, die Truhe, die Tagesform, die Tagesaufgaben
und über die Erfahrung die Levelkurve. Je später sie fällt, desto mehr
hängt daran — deshalb jetzt, vor weiterem Ausbau.

## Entscheidung

1. **Eine Gewohnheit hat feste Wochentage** (Standard: alle sieben). An
   den anderen Tagen steht sie nicht in „Heute“, lässt sich nicht
   abhaken und zählt weder für Truhe noch Tagesform noch Aufgaben.
2. **Die Kette zählt erledigte fällige Tage**, nicht Kalendertage. Ein
   Tag außerhalb des Plans trägt sie, verlängert sie aber nicht — dieselbe
   Regel wie beim Streak-Eis.
3. **Ein verpasster fälliger Tag lässt die Kette auf die Stufe darunter
   fallen**, nicht auf null: aus 45 werden 30, aus 10 werden 7, aus 7
   werden 3, unter 3 bleibt nichts. Jeder weitere verpasste Tag kostet
   wieder eine Stufe. Das gilt für die Kette je Gewohnheit und für die
   Tageskette.
4. **Ein Ruhetag** — ein Tag, an dem nichts fällig ist — trägt die
   Tageskette, verlängert sie nicht, und gibt weder Truhe noch Tagesform.
5. **Wer seltener plant, bekommt weniger**: Jedes Häkchen zahlt wie
   bisher, es gibt keinen Ausgleich für seltenere Gewohnheiten.
6. **Stoppen friert die Kette ein.** Eine gestoppte Gewohnheit pausiert
   ab morgen; ihre Kette steht, bis sie wieder läuft.

## Begründung

**Feste Wochentage statt „x-mal die Woche“.** Jede abhängige Regel fragt
„ist das heute dran?“. Feste Tage geben darauf eine Antwort an einer
Stelle (`HabitTracker.isDueOn`), und Truhe, Tagesform und Aufgaben
bleiben, wie sie sind. „Dreimal die Woche, egal wann“ hat keine Antwort
auf „ist heute alles erledigt?“.

**Der Plan ist eine Historie, kein Feld** (`HabitPlan`). Ketten und
Erfahrung werden aus der Vergangenheit gerechnet. Stünde nur der Plan von
heute da, schriebe jede Änderung die Vergangenheit um, und das Level
könnte nachträglich fallen. Gespeichert wird „ab Tag X gelten diese
Wochentage“; eine Pause ist ein Eintrag ohne Tage.

**Eine Änderung gilt ab morgen.** Sonst nimmt man abends den heutigen Tag
aus dem Plan und öffnet die Truhe ohne Häkchen. Nur eine Gewohnheit ohne
ein einziges Häkchen bekommt ihren Plan sofort. Aus demselben Grund gilt
Stoppen ab morgen, und eine heute gestoppte, offene Gewohnheit zählt
heute weiter als fällig (`dueIdsOn`).

**Stufe darunter, streng.** Wer genau auf einer Stufe steht, verliert
sie; sonst kostete ein verpasster Tag auf der höchsten Stufe nie wieder
etwas. Der Preis steht unter Konsequenzen.

**Kein Ausgleich für seltenere Gewohnheiten.** Der Schwierigkeitsgrad
(ADR-0028) ist die eine, gemessene Stellschraube für „das hier ist mehr
wert“. Ein zweiter Faktor am Rhythmus machte „einmal die Woche“ zum
bequemsten Weg zu voller Belohnung.

**Nicht fällig heißt nicht abhakbar.** Ein freiwilliges Häkchen am
falschen Tag, das die Kette verlängert, wäre der Weg zu einer Kette, die
an sechs von sieben Tagen nicht fallen kann.

## Gemessen

`dart run example/curve_sim.dart`, 90 Tage, fünf Gewohnheiten:

| Spieler | XP nach 90 Tagen | vorher |
|---|---|---|
| jeden Tag alle fünf | 11.865 | 11.865 |
| 5 von 7 Tagen, ohne Plan | 4.980 | 4.980 |
| jeden zweiten Tag | 3.375 | 3.375 |
| **Montag bis Freitag geplant, jeden davon** | **7.965** | nicht möglich (wie „5 von 7“: 4.980) |
| **ein Tag je Woche fehlt** | **7.920** | 6.540 |

Die Obergrenze — der fleißige Spieler, auf den Levelkurve und Laden
gerechnet sind — bewegt sich nicht. Was sich bewegt, ist die Mitte: Wer
plant oder selten vergisst, behält mehr.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| „x-mal die Woche“, frei verteilt | Keine Antwort auf „ist heute alles erledigt?“; Truhe und Tagesform bräuchten eine neue Regel, die Kette eine zweite Zeiteinheit (Wochen). |
| Ausgleich bei der Erfahrung für seltenere Gewohnheiten | Zweite Stellschraube neben dem Grad; „einmal die Woche“ würde der bequemste Weg. |
| Ruhetag zählt wie erledigt | Dann lohnt es sich, möglichst viele freie Tage einzuplanen. |
| Je angefangene Woche Lücke eine Stufe | Von Claude empfohlen, von Frederik verworfen: Jeder verpasste Tag soll etwas kosten. |
| Eine Lücke kostet immer genau eine Stufe | Drei Monate weg kosteten so viel wie ein Tag. |
| Nur mehr Streak-Eis | Der Absturz auf null bliebe möglich. |
| Freiwilliges Häkchen an nicht fälligen Tagen | Zweiter Bereich in „Heute“, und die Kette wüchse ohne Risiko. Lässt sich nachrüsten, wenn „verschoben“ zu oft als „verpasst“ zählt. |
| Gestoppte Gewohnheit verfällt wie verpasst | Urlaub bräuchte dann etwas Eigenes; Stoppen ist die geplante Pause. |

## Konsequenzen

**Leichter:**

- Realistische Pläne (Training Mo/Mi/Fr, Lesen werktags) bauen eine Kette
  auf wie tägliche.
- Ein vergessener Tag kostet eine Stufe statt allem.
- Urlaub: Gewohnheiten stoppen, Ketten bleiben stehen.
- Die Frage „wie läuft eine Kette?“ steht an einer Stelle (`StreakRule`),
  die Frage „ist das heute dran?“ an einer (`isDueOn`).

**Schwerer, und bewusst so:**

- **Wer jeden zweiten Tag abhakt, hält seine Stufe, steigt aber nicht.**
  Aus 8 wird 7, aus 7 wieder 8. Die Stufe misst damit, was jemand
  aufgebaut hat, nicht, ob er gerade jeden Tag dabei ist.
- **Eine Woche krank bleibt teuer:** Sechs verpasste fällige Tage am
  Stück setzen jede Kette auf null. Die Antwort darauf ist Stoppen — das
  muss man aber am Tag vorher tun.
- **Wer vorausplant, verliert nichts.** Heute Abend morgen aus dem Plan
  zu nehmen ist ein Ruhetag ohne Abzug. Geplante Lücken sind frei,
  vergessene kosten.
- **Verschieben geht nicht.** Montag geplant, Dienstag gemacht: Montag
  ist verpasst, Dienstag nicht abhakbar.
- **An einem Ruhetag gibt es keine Truhe, keine Tagesform, keine Aufgabe
  zum Abhaken und keine Dailies der Grube** (die hängen an einem Häkchen,
  ADR-0040).
- **Eine offene Gewohnheit zu stoppen kostet die Truhe des Tages.** Sie
  bleibt heute fällig, steht aber nicht mehr in der Liste.
- **Alte Stände ändern sich leicht nach oben:** Frühere Lücken zählen
  rückwirkend als Rückfall statt als Neustart; es gibt etwas mehr
  Erfahrung als bisher, nie weniger. Was in einem alten Stand gestoppt
  war, pausiert seit dem Tag nach seinem letzten Häkchen.
- `tracker.dart` ist weiter gewachsen (rund 1.560 Zeilen). Plan und
  Kettenregel liegen in `plan.dart` und `streak_rule.dart`.

**Offen:**

- Ob „verschoben = verpasst“ im Alltag zu hart ist.
- Die Kachel sagt „noch 2“ bis zur nächsten Stufe — bei einer
  Gewohnheit mit drei Tagen die Woche sind das Häkchen, keine Tage.
- Der Wochenrückblick kennt keinen Ruhetag; er zeigt ihn wie einen Tag
  ohne Häkchen.
- Wochentage werden erst im Dialog „Wann machst du das?“ gewählt, nicht
  schon im Formular einer eigenen Gewohnheit.
