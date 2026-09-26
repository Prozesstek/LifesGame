# ADR-0050: Zwischenebenen und angekündigte Gebiete

**Datum:** 26.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

[ADR-0037](0037-der-wissensbaum-als-endziel.md) hat den Wissensbaum aus
Issue [#54](https://github.com/Prozesstek/LifesGame/issues/54) als
Zielbild festgehalten und den Bau auf die Zeit **nach** dem 30-Tage-Lauf
gelegt. Fünf Punkte ließ er offen.

Am 26.09., im Testlauf, wollte Frederik die Theorie überarbeiten. Die
Punkte wurden der Reihe nach entschieden. Ein Befund aus
`tool/runway_sim.dart` sprach dafür, jetzt zu bauen: Der alte Baum war an
Tag 33 durchgelesen, und das Neue wird ab Woche 3 dünner (`state.md`,
24.09.).

Frederiks Wunsch für den ersten Schritt: **„alle Überschriften als Gebiet,
um zu gucken, wie es wirkt und wie die Navigation funktioniert — Inhalt
kommt später."**

## Entscheidung

Der Baum bekommt eine **Zwischenebene** zwischen Wurzel und Thema, und
alle Überschriften aus Issue #54 stehen im Bild — befüllt oder als
Ankündigung.

| Frage | Entschieden |
|---|---|
| Wann? | **jetzt, schrittweise** — die Sperre „Baum über 24 Knoten" fällt |
| Kostet die Zwischenebene einen Punkt? | **ja**, wie jeder Knoten |
| Braucht sie eine Seite? | **ja**, eine Einführung ins Gebiet mit drei Fragen |
| Wer schreibt? | **Claude entwirft, Frederik liest gegen** |
| Muss ein Knoten eine Gewohnheit bringen? | **nein** (ADR-0037 bestätigt) |
| Woher kommen Punkte? | **weiter nur einer je Level** (ADR-0035) |
| Die 21 alten Knoten? | **unter die Zwischenebenen einsortiert** |
| Überschriften ohne Inhalt? | **sichtbar, grau, „Inhalt folgt", nicht zu öffnen** |
| Belohnung fürs Vertiefen? | **tiefere Seiten plus Rückfrage des Tages** (ADR-0045) — keine weitere wiederholbare Belohnung |
| Wie viel XP und Gold? | **noch offen** — wird gerechnet, sobald neuer Inhalt kommt |

### Die Einsortierung

| Gebiet | Zwischenebene | Themen |
|---|---|---|
| Körper | Kraft & Muskulatur | Die kleinste Dosis, die wirkt |
| | Ernährung | Essen ist ein Umgebungsproblem |
| | Schlaf & Regeneration | Schlaf, Erholung, Stress (auch unter Geist) |
| Geist | Psychologie | Aufmerksamkeit, Wiederholen |
| | Selbstentwicklung | Gedanken, Unbehagen, Motivation |
| Wissenschaft | Wissenschaftliches Denken | Quelle, Ursache, Selbsttest, Stichprobe, Studie |
| Gesellschaft | Beziehungen | Umfeld, Zugehörigkeit, Nein sagen, Um Hilfe bitten |
| | Medien & Information | Vergleich (auch unter Geist) |

**„Wissenschaftliches Denken" steht nicht in Issue #54.** Die fünf
Wissenschaftsthemen sind Methode, keine Physik oder Chemie; sie brauchten
eine eigene Überschrift. **„Was ist Psychologie"** war schon eine
Einführung und ist die Seite der Zwischenebene Psychologie geworden.

Siebzehn Überschriften sind angekündigt: Ausdauer & Fitness,
Körperkontrolle, Biologie des Körpers, Philosophie, Geschichte,
Kreativität, Kommunikation, Arbeit & Karriere, Wirtschaft & Finanzen,
Recht & Staat, Gesellschaft & Kultur, Physik, Chemie, Biologie,
Mathematik, Technologie & Informatik, Erde & Universum.

## Begründung

**Warum die Zwischenebene einen Punkt kostet.** Frederiks Entscheidung,
gegen die Empfehlung: Ein Gebiet zu betreten soll selbst eine Wahl sein.
Das passt zu ADR-0037, Grundsatz 1, und macht die Knappheit spürbar —
wer in „Kraft & Muskulatur" zwei Themen lernt, zahlt drei Punkte.

**Warum die Ankündigung eine eigene Art ist (`TheoryPlaceholder`) und
kein Knoten ohne Seite.** Eine Seite, die fehlen darf, hätte jede Stelle
berührt, die Seiten zählt, belohnt oder abfragt: Rückfrage des Tages,
Errungenschaften, Theoriepunkte, `passedPagesProvider`. Eine eigene Art
steht nur im Bild. Wird eine Überschrift befüllt, wird sie ein Knoten
**mit derselben Id**.

**Warum die Übernahme abgeleitet ist und nicht gespeichert.** Wer Schlaf
schon bezahlt hat, hätte nach dem Umbau einen offenen Knoten unter einer
geschlossenen Zwischenebene. `TheoryNode.legacyOpenedBy` sagt: Diese
Zwischenebene gilt als offen, wenn eines dieser Kinder offen ist — ohne
Punkt, weil sie nicht im Spielstand steht. Ein neuer Spieler kann diese
Kinder nur **über** die Zwischenebene öffnen und hat sie dann bezahlt; die
Schenkung greift also nur bei alten Ständen.

**Warum Stress und Vergleich nicht in der Übernahme stehen.** Beide
behalten die Wurzel Geist als zweiten Weg. Stünden sie in der Übernahme,
könnte ein neuer Spieler sie über Geist öffnen und bekäme die
Zwischenebene geschenkt. `strayGrants` und ein Test in
`graph_content_test.dart` halten fest, dass nur Kinder mit genau einem
Eltern schenken dürfen.

**Warum die acht Einführungsseiten jetzt geschrieben sind, obwohl
„Inhalt kommt später".** Die Kette zum ersten Kampf (ADR-0020) läuft über
Knoten mit Fähigkeit — und die hängen jetzt unter Zwischenebenen. Ohne
deren Seiten käme ein neuer Spieler nicht an eine Fähigkeit.
`abilities_seam_test.dart` rechnet jetzt den ganzen Weg: Zwischenebene
plus Thema kostet zwei Punkte, Level 3 gibt genau zwei.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Nach dem 20.10. bauen, wie ADR-0037 sagte | Frederik will jetzt sehen, wie es wirkt; der Befund aus `runway_sim` spricht dafür |
| Zwischenebene kostenlos, wie die Wurzeln | Frederiks Entscheidung: das Betreten eines Gebiets soll etwas kosten |
| Zwischenebene ohne Seite, nur als Tür | Dann kaufte der Punkt nichts außer Zugang |
| Alte Knoten direkt an der Wurzel lassen | saubere Migration, aber eine gemischte Struktur; Frederik wollte einsortieren |
| Übernahme als Migration in den Spielstand schreiben | ein drittes Feld in `TheoryProgress` und eine Versionsmarke; abgeleitet reicht und kann nicht auseinanderlaufen |
| Ankündigungen nur im Entwicklermodus | Der Zweck ist, dass man die Größe des Baums sieht |
| Punkte zusätzlich aus der Rückfrage | zweite Quelle, die gerechnet werden müsste; erst messen, ob zwei Seiten die Woche zu wenig sind |

## Konsequenzen

- **32 Knoten statt 25, 37 Seiten statt 30, 28 Punkte für den ganzen
  Baum statt 21.** Sieben neue Einführungsseiten, Entwürfe von Claude —
  **noch nicht gegengelesen**. Jede steht in
  `packages/theory/lib/src/content/area_pages.dart`.
- **Der Baum ist an Tag 50 statt an Tag 33 durchgelesen** (`runway_sim`).
  Bis Tag 35 ändert sich nichts: Die Punkte sind der Engpass, nicht die
  Seiten. Neue Seiten verlängern also das Ende, sie füllen nicht die
  Wochen 3 und 4 — dafür bräuchte es mehr Punkte oder billigere Wege.
- **Der Weg zu jeder Fähigkeit im Baum kostet einen Punkt mehr.** Auf
  Level 3 geht es noch genau auf.
- **Ein neues Thema zu schreiben heißt:** eine Seite in `content/`, ein
  Knoten in `theory_graph_content.dart` unter seiner Zwischenebene. Wer
  eine angekündigte Überschrift befüllt, nimmt sie aus
  `theoryPlaceholders` heraus und trägt sie mit derselben Id als Knoten
  ein — samt Einführungsseite.
- **ADR-0037 bleibt das Zielbild.** Offen bleiben Punkt 1 (wie viel XP und
  Gold) und das Schreiben von rund 300 Seiten. Die Regel „ein Knoten
  erscheint erst, wenn seine Seite steht" gilt weiter für **Knoten** —
  eine Ankündigung ist keiner und lässt sich nicht öffnen.
