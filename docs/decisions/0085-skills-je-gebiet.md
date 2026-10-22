# ADR-0085: Skills je Gebiet — was bleibt, wenn die Kette fällt

**Datum:** 22.10.2026
**Status:** Aktiv
**Entschieden von:** Prozesstek

## Kontext

Frederik: „Jemand der 30 Tage eine Streak aufrecht erhält hat ein
höheres Gefühl als jemand der 100 mal 25 Tage Streaks hatte. Und das
spiegelt die Realität auch nicht wieder. Stattdessen bleiben dir
Gewohnheiten Streaks und je länger sie ist umso mehr XP gibt sie. Aber
nicht nur das Charakter Level sondern auch eigene Skills. So hat Sport
seinen eigenen Skill in welche Theorie einzahlen als auch die
Gewohnheiten die dazu passen. Dadurch kann sich mehr mit anderen
verglichen werden und wir verlieren keine Spieler nachdem sie eine 300
Tage Streak verloren haben.“

Was der Code an diesem Tag tat:

1. **Eine verlorene 300-Tage-Kette kostete keine Erfahrung.** Sie fiel
   nur auf die Stufe darunter (300 → 60, ADR-0064), und der Bonus blieb
   bei ×2. Weh tat nur die Zahl: Kachel und Charakter zeigten „Tage am
   Stück“.
2. **Ab Tag 60 brachte eine längere Kette nichts mehr** — der Bonus war
   bei ×2 gedeckelt (`konzept.md` 3.7).
3. **Das Level endet bei 50**, mit fünf Gewohnheiten nach 188 bis 240
   Tagen; die vier Charakterwerte sind nach 32 bis 40 Häkchen voll. Wer
   300 Tage spielt, hatte nichts mehr, das wächst, außer der Zahl seiner
   Kette — genau der Spieler, den man so verliert.

## Entscheidung

**Jedes der vier Gebiete des Baums bekommt einen Skill**: Körper, Geist,
Wissenschaft, Gesellschaft (`SkillArea`, gleich benannt wie die
Wurzeln). Ein Skill ist ein Level von 1 bis 100, das nur wächst
(`SkillCurve`). In ihn zahlt ein:

| Quelle | Wie viel | Antwortet |
|---|---|---|
| ein Häkchen | dieselbe Erfahrung wie fürs Level, mit Kette und Schwierigkeit | `HabitTracker.xpIn` |
| eine bestandene Seite unter der Wurzel | ihre Erfahrung; eine Seite in zwei Gebieten zählt in beiden | `TheoryProgress.xpInArea` |
| eine richtige Rückfrage | ihre Erfahrung, im Gebiet ihrer Seite | `ReviewLog.xpFor` |

Grube, Errungenschaften und Truhe gehören zu keinem Gebiet und zählen
nur fürs Level. **Das Level bleibt, wie es ist**: Ein Häkchen zahlt
zweimal, einmal fürs Level und einmal für seinen Skill.

In zwei Fragerunden entschieden, siebenmal wie empfohlen:

| Frage | Antwort |
|---|---|
| Welche Skills? | **die vier Gebiete des Baums** — Sport heißt Körper |
| Was bringt ein Skill? | **die Zahl und je drei Titel** bei 10, 25 und 50 |
| Wächst der Kettenbonus über 60 Tage? | **ja, langsam**: 100 Tage ×2,2, 180 ×2,4, 365 ×2,6 |
| Was steht vorne? | **der Skill**; die Kette als Flamme mit ihrem Bonus |
| Wie schnell? | **zügig, Ende bei 100** |
| Wie vergleicht man? | **Teilen-Knopf im Charakter**, ein Text wie bei der Tagesgrube |
| Wann? | **jetzt, vor dem Teststart** (26.10.) |

**Einmal dagegen**: Für eigene Gewohnheiten von vor den Skills empfahl
Claude, das Gebiet aus dem Wert abzuleiten (Stärke und Ausdauer →
Körper, Disziplin und Klarheit → Geist). Frederik: **einmal fragen.**
Die Startseite zeigt dafür eine Karte über „Heute“, eine Gewohnheit nach
der anderen, bis jede ein Gebiet hat (`GebietFrageKarte`).

## Begründung

**Die Kette misst Gleichmäßigkeit, der Skill misst Menge.** Beides ist
etwas wert, aber nur eins davon fällt. Was vorne steht, bestimmt das
Gefühl: Wer nach 300 Tagen einen verpasst, sieht jetzt „Körper 61“ und
eine Flamme, die eine Stufe kleiner brennt — nicht „180“ statt „300“.

**Vier Gebiete statt feinerer** (Kraft, Ausdauer, Schlaf …), weil jeder
dieselben haben muss, um sich zu vergleichen, und weil jede Seite des
Baums schon heute zu genau einem davon gehört. Vorlagen kennen ihr
Gebiet über ihre Lektion; nur eine eigene Gewohnheit muss es sagen. Die
vier Werte (Stärke, Ausdauer …) wären die andere naheliegende Wahl
gewesen, aber sie messen, was im Kampf wirkt, nicht, worin man lebt —
„eine echte Frage stellen“ ist Stärke.

**Titel statt Kampfwirkung.** Ein Skill ohne Deckel im Kampf hätte die
Deckel aus ADR-0008 und ADR-0042 aufgehoben und die Grube neu messen
lassen. Titel werden schon abgeleitet und gelten rückwirkend
(ADR-0033); ein Skill wächst nur, also nimmt ihn nichts zurück.

**Der Kettenbonus darf wieder wachsen**, weil der Einwand aus
`konzept.md` 3.7 („bei ×3 geben Nutzer auf“) seit ADR-0064 nicht mehr in
voller Stärke gilt: Eine Kette fällt nur eine Stufe, ein Jahr Kette
behält nach einem verpassten Tag ×2,4. Und was sie eingebracht hat,
bleibt im Skill.

**Ohne Deckel bei 100?** Nein: Ein Ende, das man sieht, ist ein Ziel.
Bei einer Gewohnheit täglich liegt es bei gut dreieinhalb Jahren.

## Gemessen

Eine Gewohnheit täglich, ohne Seiten (`test/skills_test.dart`):

| Skill | nach |
|---|---|
| 10 | 50 Tagen |
| 25 | 159 Tagen |
| 50 | 425 Tagen |
| 100 | 1307 Tagen |

Mit Seiten und mehreren Gewohnheiten im Gebiet geht es schneller. Die
Kurve: Stufe 2 kostet 100 wie beim Level, jede weitere 8 mehr
(`SkillCurve.stepXp`, beim Level 25).

**Das Level kommt durch die neuen Kettenstufen früher**: fünf Vorlagen
täglich auf Level 50 nach 223 Tagen statt 240, fünf „schwere“ nach 179
statt 188 (`test/progression_test.dart`). Bis Tag 60 ändert sich nichts
— `runway_sim`, `pit_sim` und die Tagesgrube rechnen mit Tag 0 bis 60.

**Die Errungenschaften zahlen mehr**: 2880 Erfahrung, 960 Gold und 570
Ruhm über ein Spielerleben statt 1860, 620 und 410 — über Jahre
verteilt, weil Skill 50 erst nach gut einem Jahr kommt.

## Ohne Rückfrage entschieden

- **Die Titel heißen** der Rüstige, der Gestählte, der Unverwüstliche
  (Körper), der Wache, der Gesammelte, der Weise (Geist), der
  Neugierige, der Forscher, der Gelehrte (Wissenschaft), der Zugewandte,
  der Vertraute, der Ratgeber (Gesellschaft). Stufen klein, mittel,
  groß wie die übrigen Meilensteine.
- **Ein eigener Reiter „Gebiete“** in den Errungenschaften: Ein Skill
  wächst aus Gewohnheiten und Theorie und gehört keinem Kreis allein.
  Er bringt Titel, keine Fähigkeit.
- **Ein Gesamtlevel**, die Summe der vier — die Zahl zum Vergleichen.
- **Die Kachel** zeigt oben das Zeichen des Gebiets mit seinem Level
  und einem Strich bis zur nächsten Stufe, darunter die Flamme mit dem
  Bonus („×2,4“), darunter die nächste Stufe der Kette. **Die Tage am
  Stück stehen nur noch im Tipp**, zusammen mit den Tagen gesamt dieser
  Gewohnheit.
- **Im Charakter** steht die Karte der Skills über der Beständigkeit.
- **Im Baum** steht der Skill des Gebiets neben seinem Namen.
- **Das Gebiet einer eigenen Gewohnheit steht ab dem Anlegen fest**,
  wie Wert und Schwierigkeit (`CustomHabit.withArea` setzt es nur, wenn
  keins da ist). Ein Wechsel verschöbe die Historie, und ein Skill
  fiele; ein Titel ginge verloren.
- **Das Formular und die erste Frage** fragen das Gebiet mit, Körper
  vorgewählt. Die Vorschläge der ersten Frage haben ihr Gebiet fest.
- **Eine Seite mit zwei Eltern** („Stress“ an Körper und Geist) zählt
  für beide Skills, wie sie schon für beide Gebiete zählt
  (`isAreaComplete`). Fürs Level zählt sie einmal.
- **Der geteilte Text** nennt Name und Titel, Gesamtlevel, die vier
  Skills und die längste Kette, nicht die laufende.

## Nachtrag, am selben Tag: man sieht, dass es zweimal zählt

Frederik nach dem ersten Stand: „ich hätte gerne eine Animation und
besser ausgeschildert, dass bei der Gewohnheit XP zu dem Charakter Level
und Level des Gebietes dazu kommt.“ Gebaut ohne Fragerunde:

| Was | Wie |
|---|---|
| **Zwei Ströme** | ein Häkchen wirft seine Funken zweimal: wie bisher zum Level-Balken, und grün zum Balken des Gebiets (`FlugZiel.gebiet`), derselbe Betrag |
| **Der zweite Balken** | liegt unter dem Level-Balken, mit Zeichen, Name und Stufe des Gebiets; blendet ein, sobald seine Funken fliegen, füllt sich mit jedem, der ankommt, und verblasst knapp zwei Sekunden nach der Landung (`GebietsBalken`) |
| **Aufsteigende Zahlen** | unter „+33 EP +5 G“ eine grüne Zeile „+33 EP Körper“ mit dem Zeichen des Gebiets; steigt dabei der Skill, eine dritte: „Körper 35!“ |
| **Die Kachel** | die Erfahrung steht zweimal da: „✦ +33“ fürs Level, grün „🏃 +33“ fürs Gebiet, dann das Gold |
| **„Heute“** | rechts an jeder Zeile das grüne Zeichen des Gebiets |
| **Gewohnheiten-Bildschirm** | bekommt oben die Leiste der Startseite — dort flog bis dahin nichts, weil es kein Ziel gab (`state.md`, 18.10.) |

**Ohne Rückfrage entschieden:**

- **Grün ist die Farbe der Gebiete**, im Funken, im Balken und in der
  Zeile. Das Level bleibt in seiner Farbe; zwei Ströme in derselben Farbe
  sähen aus wie einer.
- **Der Balken des Gebiets liegt immer da, nur unsichtbar**, und jeder
  Teil hat eine feste Breite. `AufstiegHost.fliege` nimmt den Ort eines
  Ziels beim Werfen; ein Balken, der erst danach erscheint oder sich mit
  dem Namen verschiebt, ließe die Funken danebenfliegen.
- **Die Leiste ist dafür zwölf Punkte höher**, der Level-Balken steht
  weiter in ihrer Mitte.
- **Die Ertragszeile der Kachel schrumpft als Ganzes**, statt eine Zahl
  abzuschneiden: Auf der Kachel mit Timer standen sonst zweimal „+…“
  (beim Ansehen gefunden).
- **Kein eigener Klang** für die grünen Funken: Sie klingen wie die
  Funken des Levels, gedrosselt wie diese.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Ein Skill je Gewohnheit („Liegestütze 34“) | Trifft den Fall 100 × 25 am genauesten, aber die Theorie kann nirgends einzahlen, und vergleichen lässt sich nur dieselbe Gewohnheit. Die Tage gesamt einer Gewohnheit stehen dafür im Tipp der Kachel |
| Die vier Werte als Skills | Messen, was im Kampf wirkt; für die Theorie bräuchte es eine Tabelle Seite → Wert |
| Feinere Gebiete (~10) | Viele stehen noch als „Inhalt folgt“ im Baum, eine eigene Gewohnheit wählte aus zehn |
| Der Skill wirkt im Kampf | Hebt die Deckel aus ADR-0008 und ADR-0042 auf |
| Das Gebiet alter Gewohnheiten aus dem Wert | Claudes Empfehlung; Frederik will fragen. Eine soziale Gewohnheit landete sonst in Geist |
| Das Gebiet jederzeit ändern | Ein Skill fiele, ein Titel ginge verloren (ADR-0033, Punkt 3) |
| Ein Skill ohne Ende | Ein Ende, das man sieht, ist ein Ziel |

## Konsequenzen

- **Eine Zahl, die nur wächst, steht vorne.** Der Verlust einer langen
  Kette kostet einen Bonus, nicht das Gefühl, alles sei weg.
- **Vergleichen geht ohne Server**: „Körper 34“ und ein Gesamtlevel,
  als Text kopiert. Eine Rangliste braucht weiter einen Server.
- **Ein Häkchen auf einer alten Gewohnheit ohne Gebiet zählt für keinen
  Skill, bis sie gefragt ist** — danach rückwirkend ganz.
- **Die Kette wirkt stärker als vorher**: Nach einem Jahr ×2,6 statt ×2.
  Das Level kommt früher, der Laden bekommt kein Gold mehr (der Bonus
  wirkt nur auf Erfahrung).
- **Die Grube ist unberührt.** Wer will, dass ein Skill dort wirkt,
  braucht einen neuen ADR und `pit_sim`.
- **Zweiundvierzig Errungenschaften, fünfundzwanzig Titel.** Die
  Sammlung zählt sie mit.
- **Es gibt achtzehn Stellen, an denen etwas zusammenläuft**:
  `skillsProvider` ist dazugekommen. Die Errungenschaften nehmen
  dieselbe Rechnung (`Skills.aus`), damit Titel und Anzeige nie
  verschiedene Level sehen.
