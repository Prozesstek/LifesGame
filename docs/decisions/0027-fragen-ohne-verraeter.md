# ADR-0027: Die richtige Antwort darf sich nicht verraten

**Datum:** 31.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

[Issue #21](https://github.com/Prozesstek/LifesGame/issues/21) nennt es als
einen Punkt unter acht: „meistens ist die längste Antwort die richtige —
fixen". Nachgemessen über alle **29 Seiten und 87 Fragen** ist es der
schwerwiegendste Befund des Issues:

| | gemessen | Zufall wäre |
|---|---|---|
| richtige Antwort ist die längste | **71 / 87 — 81,6 %** | ~29 % |
| richtige Antwort über dem Längenschnitt | **82 / 87 — 94,3 %** | ~50 % |
| richtige Antwort steht an zweiter Stelle | **48 / 87 — 55,2 %** | ~33 % |
| richtige Antwort an **vierter** Stelle (bei 51 Fragen mit vier Antworten) | **0** | ~25 % |

**Wer das Muster erkennt, besteht jede Seite ohne zu lesen.** Damit trägt die
Theorie nichts mehr bei: Sie gibt Erfahrung, Gold, Theoriepunkte und
Habit-Vorlagen für eine Mustererkennung statt für Wissen. Das ist kein
Schönheitsfehler, sondern eine Lücke im Kern-Loop.

Die Ursache ist keine Nachlässigkeit, sondern ein Nebeneffekt des Schreibens:
**Die richtige Antwort ist lang, weil sie genau ist. Die falschen sind kurz,
weil sie hingeworfen sind.** Wer eine Frage schreibt, denkt über die richtige
Antwort nach und erledigt die anderen.

## Entscheidung

**Drei Regeln, geprüft von `packages/theory/test/question_fairness_test.dart`
über Graph *und* Handbuch:**

1. **Länge.** Die richtige Antwort weicht höchstens **20 %** vom
   Längendurchschnitt der falschen ab — nach oben wie nach unten.
2. **Keine Klammern** in einer Antwortmöglichkeit. Ein Zusatz in Klammern ist
   fast immer eine Präzisierung, und präzisiert wird die richtige Antwort.
3. **Stelle.** Kein `correctIndex` trägt mehr als **40 %** aller Fragen.

**Dazu wird beim Anzeigen gemischt:** `lesson_screen.dart` mischt die
Antwortmöglichkeiten je Frage, die Reihenfolge im Inhalt ist nur noch
Speicherform.

**Repariert wird über die falschen Antworten, nicht über die richtige.** Eine
falsche Antwort auf Länge zu bringen heißt, ihr einen echten Gedanken zu geben
— sie wird dadurch ein plausibler Irrtum statt einer Verlegenheitslösung. Die
richtige zu kürzen würde die Seite schlechter machen.

## Begründung

**Regel 1 zielt auf den Tell, nicht auf die Form.** Sie sagt nichts darüber,
wie lang eine Frage sein darf oder wie stark sich die falschen Antworten
untereinander unterscheiden — nur darüber, dass die richtige nicht heraussticht.
Eine Regel über die Spannweite aller Antworten hätte auch Fragen umgeschrieben,
in denen zufällig eine *falsche* Antwort lang ist.

**„Die richtige ist nie die längste" wäre falsch gewesen.** Daraus entsteht
sofort der umgekehrte Tell. Deshalb eine Abweichung nach beiden Seiten.

**Regel 3 bleibt, obwohl das Mischen sie überflüssig macht.** Sie ist die
Absicherung für den Fall, dass irgendwo ungemischt angezeigt wird — und sie
kostet beim Schreiben nichts, weil man die richtige Antwort ohnehin
irgendwohin setzen muss.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Nur mischen, Inhalt lassen | Mischen behebt die Stelle, nicht die Länge. Die längste Antwort bleibt die längste, egal wo sie steht. |
| Spannweite aller Antworten begrenzen | Schreibt 65 Fragen um statt 71, davon einige ohne Tell — und zwingt einsilbige Antworten („Energie", „Angriff") zu künstlicher Länge. |
| Die richtige Antwort kürzen | Macht die Seiten schlechter. Die Genauigkeit der richtigen Antwort ist der Wert der Lektion. |
| Alle Antworten auf exakt gleiche Länge | Lesbar geschriebene Sätze lassen sich nicht auf das Zeichen normen, ohne gestelzt zu klingen. |
| Freitext statt Multiple Choice | Ein anderes Spiel. Auswertung, Tippfehler, Formulierungsvarianten — nichts davon gehört in einen Habit-Tracker. |

## Konsequenzen

**71 der 87 Fragen bekommen neue falsche Antworten.** Das ist der Preis, und
er fällt einmal an. Die Seiten werden dabei besser: Ein plausibler Irrtum
prüft Verständnis, eine offensichtlich falsche Antwort prüft Lesefähigkeit.

**Fünf Fragen werden zusätzlich inhaltlich ersetzt** (Issue #21, Punkt 4).
Sie stehen alle auf den vier Wurzelseiten und fragen nach Spielmechanik statt
nach der Sache — „Auf welche Charakterwerte zahlt dieser Zweig ein?" prüft, ob
jemand die Spielanleitung gelesen hat, nicht ob er etwas über Schlaf weiß.

**Neue Seiten sind ab jetzt teurer zu schreiben.** Drei plausible falsche
Antworten kosten mehr Nachdenken als eine richtige plus zwei Platzhalter. Der
Test meldet es sofort, statt es durchgehen zu lassen — das ist gewollt.

**Der Test läuft über Handbuch und Graph.** `graph_content_test.dart` sieht nur
den Graphen; die fünf Handbuchseiten hätten die Regel sonst nicht erfüllen
müssen, obwohl sie jeder als Erstes liest.
