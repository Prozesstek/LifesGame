# ADR-0067: Zeitziele laufen als Timer

**Datum:** 04.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik (in einer Fragerunde mit Claude)

## Kontext

Die Sitzung begann bei Regel 3 aus *Die 1%-Methode*, „Mach es einfach“.
Zwei Vorschläge dazu (eine kleine Fassung je Gewohnheit, die voll zählt
oder die Kette nur trägt) hat Frederik beide abgelehnt, drei weitere
(Wiederholungen zählen, Ziel in Stufen, Vorbereiten) nicht aufgegriffen.
Stattdessen: „Ich glaub ich fände erstmal gut, wenn die Zeit-Sachen als
richtiger Timer angezeigt werden.“

Bis dahin war ein Zeitziel („20 Minuten“) ein Balken mit einem Plus, das
je Tipp fünf Minuten dazulegte. Die Zeit lief nirgends; man trug sie
nach. Zeitziele gab es nur an eigenen Gewohnheiten, Vorlagen hatten
bewusst kein Ziel.

## Entscheidung

1. **Ein Zeitziel läuft als Timer.** Statt des Plus trägt die Kachel
   einen Knopf zum Timer. Er öffnet ein Blatt mit einem Ring, der
   herunterzählt, Start und Pause.
2. **Gerechnet wird aus der Startzeit, nicht aus Ticks.** Der Timer
   läuft weiter, wenn das Blatt zu ist, die App im Hintergrund liegt
   oder neu lädt. Auf der Kachel und in „Heute“ steht die Restzeit.
3. **Bei null hakt er von selbst ab**, mit allem, was ein Häkchen von
   Hand auslöst. War die App zu, passiert das beim Zurückkommen.
4. **Was gelaufen ist, bleibt stehen.** Wer nach 12 von 20 Minuten
   anhält, hat 12 Minuten Fortschritt; der nächste Start macht mit den
   restlichen 8 weiter.
5. **Von Hand geht weiter**, über „schon erledigt“ im Blatt.
6. **Der Tipp auf eine offene Zeit-Gewohnheit öffnet den Timer** und
   hakt nicht mehr ab, auf der Kachel wie in „Heute“.
7. **Die Startvorlage „Zwei Minuten lesen“ bekommt zwei Minuten** — als
   einzige Vorlage.
8. **Es läuft nur ein Timer.** Ein zweiter Start hält den ersten an.
9. **Keine neue Zahl:** Erfahrung, Gold und Ketten ändern sich nicht.

Punkte 4, 5, 7 und 8 hat Frederik in der Fragerunde gewählt, jeweils
gegen eine strengere oder weitere Fassung (Zeit verfällt beim Abbruch;
nur der Timer zählt; Vorlagen bleiben ein Tipp; mehrere gleichzeitig).

## Begründung

**Startzeit statt Ticks**, weil ein Browser im Hintergrund seine Timer
drosselt und ein Handy sie anhält. Ein Zähler, der jede Sekunde eins
hochzählt, bliebe genau dann stehen, wenn man liest statt aufs Handy zu
sehen. Gespeichert wird deshalb ein Zeitpunkt (`HabitTimer.runningSince`),
und die Oberfläche fragt mit der Uhr von jetzt.

**Minuten bleiben stehen**, weil das Modell es schon so hielt: Ein Ziel
füllt sich über den Tag (`_progress`). Der Timer ist damit kein zweiter
Fortschritt, sondern eine andere Art, denselben zu füllen. Unter einer
Minute bleibt der Rest am Timer selbst, damit eine Pause keine
angefangene Minute kostet.

**„Schon erledigt“ bleibt**, weil die App ein Häkchen ohnehin nicht
prüft, und weil das meiste, was Zeit dauert, ohne Handy passiert.

**Nur die Startvorlage**, weil sie die Zeit im Namen trägt und die erste
Gewohnheit jedes neuen Spielers ist — der Timer ist damit vom ersten Tag
an zu sehen. Das hebt „Vorlagen haben kein Ziel“ (ADR-0028) für eine
Vorlage auf, aber nur in der Hälfte, die nichts kostet: Eine Dauer
ändert, **wie** abgehakt wird, nicht, was ein Häkchen bringt.
`timer_test.dart` hält fest, dass der Ertrag derselbe ist wie bei jeder
anderen Vorlage.

**Der Timer liegt im Tracker**, nicht daneben: Er wird mit ihm
gespeichert, und `check`, `uncheck` und `deactivate` räumen ihn mit ab.
Ein Timer neben dem Tracker wäre die zweite Stelle, die wissen müsste,
ob eine Gewohnheit heute erledigt ist (`gotchas.md`).

## Konsequenzen

- **Ohne Rückfrage entschieden**, weil es sonst nicht aufgeht:
  - **Über Mitternacht gehört die Zeit dem Tag des Starts.** Wer um
    23:50 zwanzig Minuten liest, hat gestern gelesen
    (`HabitTracker.timerDayFor`). Das ist die eine Stelle, an der ein
    Häkchen nachträglich auf einen vergangenen Tag fällt.
  - **Ein zweiter Start kostet den ersten seinen Rest** unter einer
    Minute; die ganzen Minuten behält er.
  - **Ein laufender Timer ist eine Behauptung wie ein Häkchen.** Wer
    startet und die App schließt, ist nach Ablauf abgehakt.
  - **Das Plus gibt es für Zeit nicht mehr**, nur noch für Mengen.
- **Die Web-Fassung klingelt nicht**, wenn der Browser im Hintergrund
  ist. Der Klang kommt beim Zurückkommen. Eine Meldung bei null kann
  erst die Android-App.
- **Abgerechnet wird, wo eine Anzeige steht**: Kachel, „Heute“ oder
  Blatt. Wer in der Grube ist, während der Timer abläuft, bekommt Häkchen
  und Tagesform erst zurück auf der Startseite.
- Wer „Zwei Minuten lesen“ bisher mit einem Tipp abhakte, braucht jetzt
  zwei: Tipp, dann „schon erledigt“ — oder er lässt die zwei Minuten
  laufen.
- Die Regel 3 selbst („Mach es einfach“) hat weiter weder Mechanik noch
  Theorie-Seite.
- `HabitTracker` trägt ein Feld mehr (`_timer`), im Spielstand der
  Abschnitt `timer`.
