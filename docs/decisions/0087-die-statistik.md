# ADR-0087: Die Statistik der Gewohnheiten

**Datum:** 23.10.2026
**Status:** Aktiv
**Entschieden von:** AktivesBrett

## Kontext

Issue #139 „Statistik“: „Claude mach einfach geilen scheiß, mit Monat
Jahr und Wochenansicht mindestens und bau bitte noch ein paar coole
Graphen ein und so.“

Es gab bis dahin nur den Wochenrückblick (eine Woche, sonntags und
montags) und die Zahlen im Charakter. Wie eine Gewohnheit über Monate
läuft, an welchem Wochentag man nachlässt, welcher Monat der beste war —
das stand nirgends.

**Was ein Datum trägt**, ist die Grenze: jedes Häkchen je Gewohnheit und
Tag, Mengen und Minuten je Tag, Streak-Eis, Truhen, Aufgaben, Rückfragen,
die Tagesgrube und seit ADR-0064 der Wochenplan als Verlauf. **Ohne
Datum** sind bestandene Seiten, Läufe in der Grube, Käufe und
Errungenschaften.

## Entscheidung

In vier Fragerunden entschieden, alles wie empfohlen bis auf drei
Punkte (unten):

| Frage | Antwort |
|---|---|
| Wo | **ein eigener Kreis**, oben als **vierter großer** neben Gewohnheiten, Theorie, Kampf |
| Ab wann | **mit dem ersten Häkchen** |
| Was | **nur Gewohnheiten** — kein Verlauf von Erfahrung, Gold, Skills oder Grube |
| Zeiträume | Woche, Monat, Jahr, **Gesamt**, mit Blättern zurück |
| Ebene | gesamt **und** je Gewohnheit: ein Tipp auf ihren Ring öffnet ihre Statistik |
| Graphen | Kalender-Raster, Balken, Kurve der Quote mit der Kette, Ringe je Gewohnheit, Wochentage |
| Technik | **fl_chart** (MIT) für Balken und Kurve; das Raster ist selbst gezeichnet |
| Text | Zahlen und Zeichen, was sie bedeuten, auf Tipp (ADR-0060) |
| Bewegung | beim Öffnen und Blättern bauen sich die Graphen auf; ohne Bewegung im System sofort |
| Quote | **erledigt / fällig**; Ruhetage und Pausen grau, Streak-Eis blau, zählt nicht als erledigt |
| Mengen | Summe und Schnitt je fälligem Tag, die Balken zeigen dann die Menge |
| Extras | Rekorde, Vergleich mit den **gleichen Tagen davor**, Jahresrückblick |
| Raster | Jahr wie bei GitHub (quer zu rollen), Gesamt je Jahr eine Zeile mit zwölf Monaten |
| Jahresrückblick | vom **20.12. bis 7.1.** angekündigt, sonst über einen Knopf in der Jahresansicht; Häkchen, Quote, perfekte Wochen, Raster, Gewohnheit des Jahres, Mengen, Vorjahr |
| Gestoppte | zählen mit, stehen grau unter den laufenden |
| Farbe | **Grün wie das Häkchen**, je kräftiger, je mehr erledigt |

**Gegen Claudes Empfehlung:** der Kreis oben statt unten als fünfter
kleiner, mit dem ersten Häkchen statt nach sieben Tagen, und fl_chart
statt selbst zeichnen.

## Begründung

**Fällig heißt fällig nach dem Plan, der damals galt** — dieselbe Regel
wie die Tageskette (`HabitTracker.wasDueOn`). Wer seinen Plan ändert,
ändert nicht die Vergangenheit; so wie die Kette sich nicht nachträglich
umschreibt (ADR-0064), tut es die Quote auch nicht. Ein Tag mit Eis
zählt nicht als erledigt, weil er auch die Kette nur trägt, nicht
verlängert (ADR-0036).

**Der Vergleich nimmt die gleichen Tage davor**: Am Mittwoch zählt
Montag bis Mittwoch gegen Montag bis Mittwoch der Vorwoche. Gegen die
ganze Vorwoche sähe jeder Montag schlecht aus.

**Schlechter steht gedämpft da, nicht rot.** Die Statistik sagt, was
war; sie straft nicht (`konzept.md` 3.7).

**Die Rechnung steht in `packages/habits`** (`statistik.dart`), weil
dort Ketten und Gewohnheiten stehen (Schichtregel). Die App zeigt nur.

**Ein bester Monat braucht sieben fällige Tage**, eine Gewohnheit des
Jahres vierzehn — sonst gewönne der erste Tag mit 1 von 1.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Erfahrung, Gold, Skills im Verlauf | AktivesBrett: nur Gewohnheiten. Seiten und Grube haben ohnehin kein Datum |
| Kreis unten als fünfter kleiner | AktivesBrett wollte ihn oben |
| Erst nach sieben Tagen mit Häkchen | AktivesBrett: mit dem ersten Häkchen |
| Selbst zeichnen | AktivesBrett: fl_chart. Das Raster ist trotzdem gezeichnet — fl_chart hat keins |
| Eis zählt als erledigt | widerspräche der Kette |
| Gleitend (letzte 7/30/365 Tage) | Kalenderwoche, -monat und -jahr mit Blättern |
| Teilen | nicht gewählt |

## Konsequenzen

- **Acht Kreise auf der Startseite**; die obere Reihe hat vier und wird
  am schmalen Handy etwas kleiner (höchstens 72 Punkte).
- **fl_chart 1.3.0** ist die erste Bibliothek für Graphen im Projekt. Sie
  verlangt Flutter 3.27.4 oder neuer; die CI läuft auf 3.44.9.
- **Mengen sind auf erledigten Tagen das Ziel**, nicht mehr: Beim
  Abhaken fällt der Zähler weg (`HabitTracker.progressOn`). Wer an einem
  Tag 40 statt 20 Minuten las, steht mit 20 da.
- **Je Ansicht wird jeder Tag einmal gerechnet** (`StatRechnung` merkt
  ihn sich). Im Jahresrückblick rechnet je Gewohnheit eine eigene
  Rechnung — bei Jahren Daten und vielen Gewohnheiten nicht gemessen.
- **Nicht gespielt, nicht am Handy.**
