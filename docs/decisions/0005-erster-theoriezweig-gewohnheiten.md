# ADR-0005: Erster Theoriezweig ist „Gewohnheiten"

**Datum:** 12.08.2026
**Status:** Aktiv — erweitert durch [ADR-0007](0007-theorie-als-skillbaum.md)
**Entschieden von:** Frederik

> Die Wahl des Zweigs gilt unverändert. Die Empfehlung „nur ein Zweig, dafür
> komplett" wurde noch am selben Tag durch ADR-0007 überholt — dort steht,
> warum und mit welchem Risiko.

## Kontext

Offener Punkt 4 des Konzepts: „Ersten Theoriezweig auswählen." Das Konzept legt
sich bewusst auf **einen** Zweig fest, der komplett fertig wird, statt drei
angefangene. Nur war nicht entschieden, welcher.

Denkbar waren mehrere Richtungen aus dem Feld Selbstverbesserung: Gewohnheiten,
Schlaf, Fokus und Aufmerksamkeit, Ernährung, Stoizismus.

## Entscheidung

Der erste Zweig heißt „Gewohnheiten" und hat fünf Lektionen: Systeme statt
Vorsätze, die Gewohnheitsschleife, die Zwei-Minuten-Regel, „nie zweimal
hintereinander", identitätsbasierte Gewohnheiten.

## Begründung

Dieser Zweig erklärt genau das, was die App vom Nutzer verlangt. Wer lernt,
warum eine Zwei-Minuten-Gewohnheit stabiler ist als ein großer Vorsatz, versteht
im selben Moment, warum der Tracker kleine tägliche Häkchen zählt. Theorie und
Anwendung fallen zusammen, statt nebeneinanderzustehen — genau die Forderung aus
Abschnitt 1 des Konzepts.

Ein Schlaf- oder Ernährungszweig wäre inhaltlich sinnvoll, aber er erklärt das
Produkt nicht. Er wäre Lesestoff neben einem Tracker.

Dazu kommt: Zwei der fünf Lektionen liefern die Begründung für Mechaniken, die
ohnehin gebaut werden müssen. „Nie zweimal hintereinander" ist die Erklärung für
die Streak-Regel aus Abschnitt 3.7 (verpasste Tage werden nicht bestraft, der
Bonus fehlt einfach). Damit rechtfertigt der Inhalt die Spielregel, statt sie zu
kommentieren.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Schlaf | Inhaltlich stark, aber erklärt nicht, wie die App funktioniert |
| Fokus / Aufmerksamkeit | Dasselbe, plus schwerer in tägliche Habits übersetzbar |
| Stoizismus | Am weitesten weg von messbaren täglichen Handlungen |
| Mit drei Zweigen parallel starten | Genau das, wovor das Konzept warnt |

## Konsequenzen

**Leichter:** Der Zweig liefert die Habit-Vorlagen gleich mit — drei der fünf
Lektionen schalten eine frei (`Lesson.unlocksHabit`). Wenn der Habits-Bereich
gebaut wird, sind erste Vorlagen samt Begründung schon da.

**Schwerer:** Der Zweig ist damit ein Stück weit Produkt-Tutorial. Wenn sich die
Mechanik ändert — etwa die Streak-Regel — muss Lektion 4 mitgeändert werden.
Inhalt und Spielregel sind hier absichtlich gekoppelt; das hat einen Preis.

Fünf Lektionen sind ein Anfang, kein fertiger Zweig. Ob es dabei bleibt,
entscheidet sich, wenn jemand ihn am Stück durchgespielt hat.
