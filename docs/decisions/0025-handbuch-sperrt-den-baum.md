# ADR-0025: Das Handbuch sperrt den Baum, nicht den Kampf

**Datum:** 31.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

[Issue #21](https://github.com/Prozesstek/LifesGame/issues/21), Punkt 1:
„Das Handbuch muss irgendwie weg oder anders gemacht werden."

Beim Nachsehen ist es mehr als eine Platzierungsfrage. **Das Handbuch ist ein
zweites System neben dem Baum**, und zwar auf drei Ebenen:

| | Handbuch | Baum |
|---|---|---|
| Modell | `TheoryBranch` (`skill_tree.dart`) | `TheoryGraph` (`node_graph.dart`) |
| Bildschirm | `branch_screen.dart` — eine Liste | `skill_tree_screen.dart` — eine Zeichenfläche |
| Reihenfolge | verbindlich | frei, über Theoriepunkte |

Sichtbar ist davon **eine schmale Textzeile** über dem Baum: „Das Handbuch ·
offen ›". Und ausgerechnet dieses Nebending trägt die erste Bedingung der
Kampfsperre ([ADR-0018](0018-kampf-hinter-dem-handbuch.md), übernommen in
[ADR-0020](0020-kampf-haengt-am-moveset.md)).

**Das Missverhältnis ist der eigentliche Befund:** Was wichtig genug ist, um
den Kampf zu sperren, darf nicht wie Beiwerk aussehen.

Eine Randbedingung schließt den bequemsten Ausweg aus: **Drei der fünf
Lektionen schalten Habit-Vorlagen frei** (`Drei Aufgaben für morgen
festlegen`, `Zwei Minuten lesen`, `Abendnotiz`). Der Inhalt kann nicht
ersatzlos verschwinden, ohne den Tracker zu beschädigen.

## Entscheidung

**Das Handbuch bleibt eigenständig und muss vollständig bestanden werden — aber
es öffnet ab jetzt den Skillbaum statt des Kampfes.**

`combatUnlockedProvider` verliert `handbookDoneProvider` und prüft nur noch das
Moveset (mindestens zwei Moves, die zweite Bedingung aus ADR-0020).

Solange das Handbuch offen ist, **ist es der Theorie-Bildschirm**. Der Baum
erscheint erst danach.

## Begründung

**Die Sperre sitzt jetzt dort, wo sie inhaltlich hingehört.** Das Handbuch
erklärt, wie Gewohnheiten funktionieren; der Baum lehrt den Stoff. Erst
verstehen, wie das Spiel gemeint ist, dann lernen — das ist eine Reihenfolge,
die sich von selbst erklärt. „Erst das Handbuch, dann darfst du kämpfen" war
dagegen immer ein Umweg, den man begründen musste.

**Das Versteck löst sich ohne eine Zeile Layout.** Wenn hinter dem Baum nichts
zu holen ist, bevor das Handbuch durch ist, muss der Bildschirm auch nichts
anderes zeigen. Aus der 14-Pixel-Zeile über einem unbenutzbaren Baum wird der
Bildschirm selbst.

**Der Kampf bleibt trotzdem gesperrt.** Elf der fünfzehn wählbaren Fähigkeiten
hängen an Theorieknoten ([ADR-0022](0022-faehigkeiten-set-aus-der-vorlage.md)).
Ohne Baum gibt es keinen zweiten Move, und ohne zweiten Move keinen Kampf. Die
Bedingung aus ADR-0020 greift unverändert — sie braucht den Stellvertreter nur
nicht mehr.

**ADR-0018 wird damit umgehängt, nicht aufgelöst.** Die Aussage „das Handbuch
ist Pflicht, bevor es weitergeht" gilt weiter. Nur *wohin* es weitergeht, ist
eine andere Tür.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Handbuch als **Oberknoten** in den Graphen, die vier Gebiete darunter | Naheliegend und trotzdem falsch: Eine Anleitung stünde dann als Knoten zwischen Lektionen. Das Handbuch erklärt das *Spiel*, die anderen Seiten erklären die *Sache* — zwei verschiedene Dinge, die im selben Baum ununterscheidbar werden. |
| Die fünf Lektionen auf die vier Wurzeln verteilen | Der Einstiegsinhalt kostet dann Theoriepunkte. Wer das Spiel noch nicht verstanden hat, soll dafür nicht bezahlen. |
| Nur die Kampfsperre entfernen, sonst nichts ändern | Löst die halbe Beschwerde nicht. Das Handbuch bliebe Beiwerk — und wäre dann auch noch folgenlos. |
| Handbuch ganz streichen, Inhalt inklusive | Drei Habit-Vorlagen verlieren ihre Quelle (`habits_theory_test.dart` fällt sofort um), und das Spiel erklärt sich nicht mehr selbst. |
| Nur die **erste** Handbuchseite verlangen | Ein Kompromiss ohne Gewinn: Die Sperre wäre schwächer, das Handbuch weiter ein Sonderweg, und die Arithmetik unten stimmte nicht mehr. |

## Konsequenzen

**ADR-0018 ist abgelöst, ADR-0020 schrumpft auf eine Bedingung.**
`combatBlockReasonProvider` verliert den Handbuch-Fall und behält zwei: keine
Fähigkeit gelernt, und gelernt aber nicht angelegt.

**Die gemessene Arithmetik bleibt gültig und wird weiter geprüft.** Fünf
Lektionen geben 275 Erfahrung und damit Level 3 — vier Lektionen (220 XP)
reichen nicht. Auf Level 3 gibt es vier Theoriepunkte und den zweiten
Fähigkeitsslot. Diese Kette trägt jetzt den *Baumzugang* statt des
Kampfzugangs; `test/progression_test.dart` und `test/abilities_seam_test.dart`
bleiben unverändert wichtig.

**Das Parallelsystem verschwindet nicht — es wird befördert.** `TheoryBranch`
und `branch_screen.dart` bleiben im Code, es gibt weiterhin zwei Modelle für
„eine Seite mit drei Fragen". Das ist die unangenehme Folge dieser
Entscheidung. Tragbar ist sie, weil das Handbuch genau fünf Seiten hat und
nicht wachsen soll. **Sobald jemand es erweitern will, ist das der Moment, es
doch in den Graphen zu holen** — und diese Entscheidung hier neu zu treffen.

**Ein neuer Spieler sieht zuerst das Handbuch, dann den Baum.** Der Weg zum
ersten Kampf wird dadurch nicht länger als heute, nur erklärter. Ob er
insgesamt zu lang ist, zeigt der 30-Tage-Lauf (`ziele.md`, Ziel 7) und keine
Vermutung.

**Der Entwicklermodus umgeht die Sperre wie bisher** — er arbeitet auf einem
eigenen Spielstand ([ADR-0021](0021-entwicklermodus-mit-eigenem-spielstand.md))
und berührt diese Entscheidung nicht.
