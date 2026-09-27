# ADR-0052: Der Auslöser gehört an die Gewohnheit, und die erste ist ab Start offen

**Datum:** 27.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Eine Durchsicht der App nach den vier Gesetzen der Verhaltensänderung
(offensichtlich, attraktiv, einfach, befriedigend) zeigte ein Gefälle:
Die Belohnung ist stark (Wucht beim Häkchen, Truhe, Leiter,
Wochenrückblick), der **Auslöser** fehlt fast ganz. Zwei Befunde davon
waren billig zu beheben:

1. **Das Handbuch lehrt den Auslöser, die App setzt ihn nicht um.** Die
   Lektion „Die Schleife hinter jeder Gewohnheit" sagt „Der Auslöser ist
   der Hebel" und „Ankoppeln statt neu erfinden". Eine Gewohnheit hatte
   aber kein Feld für *wann* oder *nach was*. `docs/vorlagen/lernen.md`
   nennt genau das („Wann machst du das?") als Vorschlag mit dem größten
   Verhaltenseffekt — gebaut war er nicht.
2. **Die erste Sitzung endete mit Lesen, nicht mit einem Häkchen.** Jede
   Vorlage kam aus einer Lektion (ADR-0028). Ein neuer Spieler sah einen
   leeren Gewohnheiten-Bildschirm mit dem Weg zum Skillbaum, und der
   Knopf für eigene Gewohnheiten war ausgeblendet.

## Entscheidung

**Jede Gewohnheit kann einen Auslöser tragen** — eine Zeile Text wie
„nach dem Zähneputzen". Gefragt wird, sobald eine Gewohnheit auf die
Tagesliste kommt; „Später" lässt die Frage auf der Kachel stehen, wo sie
sich jederzeit beantworten oder ändern lässt.

**„Zwei Minuten lesen" ist von Anfang an offen** (`HabitCatalog.starter`)
und bringt wie jede Vorlage einen Platz für eine eigene Gewohnheit mit.

## Begründung

**Ein Auslöser ist die am besten belegte einzelne Technik** für
Vorsätze: An eine Situation gebunden, werden sie deutlich zuverlässiger
umgesetzt. Er kostet eine Zeile auf der Kachel und einen Dialog.

**Text, keine Uhrzeit.** „Nach dem Zähneputzen" koppelt an etwas, das
ohnehin passiert — eine Uhrzeit bräuchte eine Erinnerung, und die gibt
es nicht (siehe Konsequenzen).

**Er steht im Tracker, nicht am `CustomHabit`.** Vorlagen gehören dem
Katalog, ihr Auslöser dem Spieler. Eine Map je Id deckt beide Arten ab.
Er erzeugt keine Zahl und darf sich deshalb jederzeit ändern — anders
als Schwierigkeit und Ziel (`CustomHabit.editable`).

**Die Startvorlage ist die kleinste im Katalog.** Zwei Minuten lesen ist
die Zwei-Minuten-Regel in Reinform — genau die Größe, die niemand an Tag
eins ablehnt. Ihre Lektion schaltet sie weiter frei, dann eben ein
zweites Mal.

**Die Zeile steht unten auf der Kachel.** Die erste Fassung setzte sie
unter den Namen. Dort lag sie in der Mitte der Kachel, wo man zum
Abhaken hintippt, und ein Häkchen wurde zum Dialog. Aufgefallen ist das
im Test.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Auslöser als Pflichtfeld | Ein Pflichtfeld vor dem ersten Häkchen ist genau die Reibung, die Punkt 2 wegnimmt |
| Uhrzeit statt Text | Ohne Benachrichtigung wirkungslos, und „nach dem Frühstück" ist verlässlicher als „8:15" |
| Frage am Ende jeder Lektion (Vorschlag aus `lernen.md`) | Die Lektion schaltet frei, gestartet wird woanders. Gefragt wird deshalb beim Starten, dem Moment der Entscheidung |
| Alle Handbuch-Vorlagen ab Start offen | Nähme dem Handbuch seinen Zweck; eine reicht für das erste Häkchen |
| Den leeren Bildschirm behalten | Er ist mit der Startvorlage unerreichbar und ist entfernt |

## Konsequenzen

- Der Spielstand hat einen neuen Abschnitt `cues` im Habit-Tracker, nur
  geschrieben, wenn belegt. Alte Stände laden unverändert; Unbekanntes
  fällt beim Laden heraus.
- Ein neuer Spieler hat ab Tag eins **eine Vorlage und einen eigenen
  Platz**. Er verdient damit ab dem ersten Tag Erfahrung aus Häkchen —
  eine Vorlage mehr als bisher, die vier Kurven sind unverändert grün.
- `customSlotsProvider` ist nie mehr 0.
- **Offen bleibt der eigentliche Auslöser außerhalb der App**: eine
  tägliche Erinnerung. Die Web-Fassung kann sie ohne Server nicht
  verlässlich schicken; das braucht das Android-APK oder Web-Push. Das
  ist eine eigene Entscheidung.
