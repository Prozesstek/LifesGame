# ADR-0070: Das Handbuch steht im Baum

**Datum:** 07.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik (in zwei Fragerunden mit Claude)

## Kontext

Seit [ADR-0069](0069-die-grube-erklaert-sich-im-ersten-lauf.md) führt
nach einer Niederlage das Buch „Stärker werden“ in die Theorie. Dort
stand das Handbuch, und der Stand davor, aus dem Code gelesen:

- **Fünf Lektionen in fester Reihenfolge**, rund 1.700 Wörter und 15
  Fragen. Erst wenn alle bestanden waren, zeigte der Bildschirm den Baum
  ([ADR-0025](0025-handbuch-sperrt-den-baum.md)). Bis zur ersten
  Fähigkeit kamen Wurzel, Zwischenebene und Thema dazu: **acht Seiten**.
- **Zwei Systeme für dasselbe**: `TheoryBranch` mit eigenem Bildschirm
  neben `TheoryGraph`. ADR-0025 nannte das „die unangenehme Folge“ und
  setzte die Frist selbst: „Sobald jemand es erweitern will, ist das der
  Moment, es doch in den Graphen zu holen.“
- **Dasselbe Buch an zwei Stellen**: Seit
  [ADR-0061](0061-der-baum-waechst-aus-dem-gelesenen.md) steht im Baum
  ein Knoten „Gewohnheiten“ mit den vier Regeln aus *Die 1%-Methode*.
  Vier der fünf Handbuch-Seiten stammen aus demselben Buch.
- **Veraltetes auf dem Bildschirm**: „Nutzbar, sobald der Habits-Bereich
  steht“ unter den freigeschalteten Vorlagen; der Titel „Gewohnheiten“
  doppelt zum Knoten.

## Entscheidung

1. **Die fünf Seiten sind Knoten unter *Gewohnheiten*.** Der eigene
   Handbuch-Bildschirm entfällt, der Baum ist immer offen.
2. **Sie kosten wie alles einen Punkt.** Kein Knoten im Baum ist
   kostenlos. Dafür **beginnt jeder mit neun Punkten** statt mit einem
   (`TheoryPoints.atStart`).
3. **Sie sind ins Buch einsortiert**: „Zwei Minuten reichen“ ist Regel 3,
   „Mach es einfach“, und hängt unter „Die vier Regeln“. Die anderen
   vier hängen direkt unter *Gewohnheiten*.
4. **Nach einer bestandenen Seite geht es direkt zur nächsten**: Auf dem
   Ergebnis steht ein Knopf mit ihrem Namen. Ist ihr Knoten noch zu,
   öffnet der Tipp ihn, und der Preis steht auf dem Knopf.

Frederik hat alle vier Punkte gewählt, zwei davon gegen die Empfehlung:
„Handbuch in den Baum holen“ statt „nur die erste Lektion sperren“, und
„je einen Punkt, mehr Startpunkte“ statt „kostenlos“.

**Ohne Rückfrage entschieden**, weil es sonst nicht aufgeht:

- **Neun, weil der Weg neun kostet**: Geist, Selbstentwicklung,
  Gewohnheiten, Die vier Regeln und die fünf Seiten
  (`theoryBasicsPath`). In der Frage stand „etwa neun: drei für den Weg,
  fünf für die Seiten, einer frei“. Der freie ist mit der Einsortierung
  „Die vier Regeln“ geworden. Dass beide Zahlen dieselbe bleiben, prüft
  `test/abilities_seam_test.dart`.
- **Der Baum schlägt den Weg vor, zwingt aber nicht.** Solange nichts
  offen und ungelesen ist, steht bei „Weiterlesen“ der nächste Schritt
  des Wegs, mit Preis. Wer selbst etwas geöffnet hat, bekommt das
  vorgeschlagen und nicht den Weg.
- **Die nächste Seite ist die nächste im Buch**: ein Durchgang in der
  Reihenfolge des Graphen, einmal herum. Was offen herumliegt, drängt
  sich nicht vor (`TheoryProgress.nextAfter`).
- **Gezählt wird nur noch der Graph.** Die fünf Seiten stehen jetzt im
  Graphen und im Zweig; wer beide zusammenzählt, zählt sie doppelt.
  `handbookProvider` und alles daran ist gelöscht.
- **Die Lektions-Ids bleiben.** Eine bestandene Seite ist offen, ohne
  dass ihr Knoten bezahlt wurde (ADR-0051), also behalten alte Stände
  alles ohne Übernahme.
- **Die Einführung „Gewohnheiten“ ist umgeschrieben.** Sie verwies auf
  das Handbuch als etwas, das man schon gelesen hat; jetzt steht sie
  davor.
- **Der Kreis der Fähigkeiten erscheint wie bisher**, wenn die fünf
  Seiten bestanden sind oder eine Fähigkeit gelernt ist. Sonst
  verschwände er bei Ständen, die ihn über das Handbuch bekommen hatten.
- **`pit_sim` rechnet Tag 0 jetzt auf Level 1.** Bis dahin lag dort das
  Handbuch mit 275 Erfahrung, also Level 3 schon im ersten Lauf.

## Begründung

**Ein System statt zwei.** Jede Zählung musste bisher „Handbuch und
Graph“ sagen und hat es mindestens einmal vergessen
(`passedCountIn(theoryTree)`, `gotchas.md`). Mit fünf Knoten mehr ist
der Graph die ganze Wahrheit.

**Punkte statt Ausnahme.** Ein kostenloser Knoten ist von Anfang an
offen, und die Regel „ein offener Knoten hält seinen einzigen Eltern
offen“ hätte Geist, Selbstentwicklung und Gewohnheiten mit aufgezogen:
drei geschenkte Knoten, eine Wurzel ohne Preis und Frostnebel für den
ersten Punkt. Mit Startpunkten bleibt die Regel aus
[ADR-0051](0051-wurzeln-kosten-einen-punkt.md) ganz, und wohin die neun
gehen, ist eine Wahl.

**Der Weg zur ersten Fähigkeit wird kürzer.** Wurzel, Zwischenebene und
Thema kosten drei Punkte, und die gibt es vom Start weg. Anlegen lässt
sie sich ab Level 3 (225 Erfahrung), also nach etwa vier fehlerfrei
bestandenen Seiten statt nach acht.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Nur die erste Lektion sperrt den Baum | Claudes Empfehlung; kleinster Eingriff, lässt aber zwei Systeme stehen. Von Frederik nicht gewählt. |
| Alle fünf wie bisher, nur der Bildschirm besser | lässt die acht Seiten vor der ersten Fähigkeit |
| Baum sofort offen, Handbuch daneben | wer es auslässt, steht nach der Wurzel ohne Punkt da |
| Die fünf kostenlos, der Weg mit offen | Claudes Empfehlung nach der ersten Runde; macht Geist zur einzigen Wurzel ohne Preis. Von Frederik nicht gewählt. |
| Alle fünf nebeneinander unter Gewohnheiten | lässt Regel 3 ohne Seite, obwohl es sie gibt |
| Als Kette, Reihenfolge bleibt verbindlich | braucht eine neue Regel im Modell |

## Konsequenzen

- **ADR-0025 ist abgelöst.** Aus ADR-0051 gilt weiter, dass jeder Knoten
  einen Punkt kostet; die Zahl der Startpunkte ist neu.
- Der Baum hat **63 Knoten** (vorher 58), ein Spielerleben **58 Punkte**
  (vorher 50). Er bleibt größer als das, was man öffnen kann (ADR-0037);
  `theory_points_test.dart` hält das fest.
- Gelöscht: `lib/theory/branch_screen.dart`,
  `lib/theory/widgets/lesson_tile.dart`, `handbookProvider`,
  `handbookDoneProvider`, `handbookRemainingProvider`.
- Neu in `theory`: `theoryBasicsPath`, `TheoryStep`,
  `TheoryProgress.nextAfter`, `nextOnPath`, `suggestedStep`. In der App:
  `suggestedStepProvider`, `stepAfterLessonProvider`, `PunktPreis`.
- **Alte Stände bekommen acht Punkte dazu**, und wer das Handbuch
  bestanden hatte, hat die fünf Seiten und ihren Weg offen, ohne dafür
  bezahlt zu haben. Das ist mehr, als ein neuer Stand je hat; die
  sichere Richtung, und es betrifft unsere beiden.
- **Niemand muss die Grundlagen lesen.** Wer die neun Punkte woanders
  ausgibt, bekommt sie erst mit den Aufstiegen zurück. Die drei
  Vorlagen, die an den Seiten hängen, und damit drei Plätze für eigene
  Gewohnheiten gibt es dann entsprechend später.

### Gemessen

`runway_sim`, der fleißige Spieler (zwei Seiten am Tag, am ersten
sieben):

| | vorher | jetzt |
|---|---|---|
| Seiten gelesen an Tag 30 | 25 (20 Knoten und das Handbuch) | 28 |
| Seiten gelesen an Tag 60 | 38 (33 von 58 Knoten und das Handbuch) | 41 von 63 |
| Level an Tag 60 | 33 | 33 |
| Gold an Tag 60 | 5.684 | 5.759 |

Drei Seiten mehr in 60 Tagen, sonst bewegt sich nichts: Die acht
Punkte mehr stehen gegen fünf Seiten, die vorher nichts kosteten.

`progression_test.dart` rechnet den Weg der Grundlagen: Er gibt genug
Erfahrung für den zweiten Fähigkeitsplatz, danach ist ein Punkt frei,
für den es eine Fähigkeit gibt, und auf dem ganzen Weg ist jeder
nächste Knoten bezahlbar.

**Der erste Lauf ist härter als in ADR-0068 angegeben.** Dort steht
Stufe 1 an Tag 0 bei 93 % für den Bot. Diese Zahl enthielt die 275
Erfahrung des Handbuchs, also Level 3; nach ADR-0068 geht es aber vor
jeder Seite hinab. Auf Level 1 gemessen (`pit_sim`, 12 Läufe je Feld):

| Stufe | Tag 0 mit Handbuch (Level 3) | Tag 0 ohne (Level 1) |
|---|---|---|
| 1 | 92 % | 67 % |
| 2 | 75 % | 17 % |
| 3 | 8 % | 0 % |

Je Wächter liegt Stufe 1 zwischen 42 % (Schlund) und 100 %
(Sumpftroll). Das ist kein Ergebnis dieses Umbaus, sondern eine Annahme
der Simulation, die seit ADR-0068 nicht mehr stimmte. Der Bot ist dumm, die
Quoten sind eine untere Schranke.

### Offen

- **Nicht gespielt, nicht am Handy.** Gerendert in 390 × 844 und
  angesehen sind der Baum eines neuen Stands, *Gewohnheiten* mit den
  neuen Knoten, „Die vier Regeln“ und das Ergebnis mit dem Knopf zur
  nächsten Seite.
- **Stufe 1 am ersten Tag** steht für den Bot bei rund zwei von drei
  Läufen. Ob das als erster Eindruck trägt, zeigt das Spielen; Balance
  ist zurückgestellt.
- Neun Punkte auf einmal sind eine große Wahl für jemanden, der den
  Baum zum ersten Mal sieht. Der Vorschlag führt, erklärt aber nicht,
  warum.
- Ein Tipp auf den Knopf zur nächsten Seite gibt einen Punkt aus, ohne
  Rückfrage. Der Preis steht darauf.
- Die umgeschriebene Einführung „Gewohnheiten“ ist nicht gegengelesen.
- `TheoryBranch` und die fünf flachen Zweige bleiben als Behälter der
  Lektionen im Package; ihre Reihenfolge sperrt nichts mehr.
- AktivesBrett hat das nicht gesehen. ADR-0025 war Frederiks
  Entscheidung, die Kette davor (ADR-0018, -0020) eine gemeinsame.
