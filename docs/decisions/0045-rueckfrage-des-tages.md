# ADR-0045: Die Rückfrage des Tages — wiederholbare Erfahrung aus der Theorie

**Datum:** 23.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Die Theorie war der einzige Bereich ohne täglichen Grund, ihn zu öffnen.
Eine Lektion wird einmal gelesen, einmal abgefragt und nie wieder
angesehen. `docs/vorlagen/lernen.md` nennt das den Kernbefund („Eine App
über Wiederholung lehrt ohne Wiederholung") und schlägt als größten Hebel
die **Rückfrage des Tages** vor. Offen war dort, ob sie Erfahrung bringt:
Sie wäre die erste wiederholbare Erfahrungsquelle außerhalb der
Gewohnheiten. Genau diese Grenze hat ADR-0032 beim Kampf gezogen.

Vorgeschlagen war „Erfahrung ja, Gold nein". Frederik: „kann aber ruhig
Gold und XP geben."

## Entscheidung

Jeden Tag steht auf den Gewohnheiten **eine** Frage aus einer bestandenen
Seite (Handbuch oder Baum). Eine richtige Antwort bringt
`TheoryRewards.xpForReview` (10) Erfahrung und `goldForReview` (3) Gold,
einmal je Tag. Eine falsche bringt nichts und kostet nichts.

Richtig beantwortet, kommt die Seite nach 1, 3, 7 und dann immer 21 Tagen
wieder (`reviewIntervals`). Falsch beantwortet, kommt sie morgen wieder,
und die Reihe beginnt von vorn. Dran ist die Seite, die am längsten
fällig ist, eine nie gefragte vor allen.

Gespeichert wird eine Historie der Antworten (`ReviewLog`, ein neuer
Bereich im Spielstand). Fälligkeit, Erfahrung und Gold werden daraus
gerechnet.

## Begründung

- **Klein, damit die Kurven halten.** 10 Erfahrung sind gut ein Zehntel
  dessen, was fünf Gewohnheiten am Tag bringen. 3 Gold sind ein Achtel der
  25, auf die der Laden ausgelegt ist. Die Truhe (ADR-0044) legt schon
  rund 11 dazu.
- **Der Einwand aus ADR-0032 trifft hier nicht.** Dort ging es darum, dass
  man einen Kampf beliebig oft wiederholen und so Erfahrung sammeln könnte.
  Die Rückfrage kommt einmal am Tag, wie ein Häkchen, und lässt sich nicht
  beliebig oft spielen.
- **Eine Frage statt ein bis drei** (die Vorlage sagt 1–3). Zwanzig
  Sekunden neben fünf Häkchen sind die Obergrenze, ab der es nervt. Mehr
  lässt sich nachziehen, weniger nicht.
- **Auf den Gewohnheiten**, wie die Vorlage vorschlägt: Dort beginnt der
  Tag ohnehin.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Erfahrung ja, Gold nein (Vorschlag der Vorlage) | Frederik wollte beides, und bei 3 Gold ist der Laden nicht gefährdet. |
| Nur ein Beitrag zur Tagesform, keine Erfahrung | Zu wenig spürbar. Die Rückfrage soll sich wie ein Häkchen anfühlen. |
| Die Frage, die beim ersten Mal falsch war, zuerst | Dafür müsste `LessonRecord` die falschen Fragen mitschreiben, das tut er nicht. Jetzt rotiert die Frage innerhalb der Seite. Später möglich. |

## Konsequenzen

- **Der vierte wiederkehrende Zufluss** neben Häkchen, Truhe und Dailies.
  Er steht in `totalXpProvider`, `goldEarnedProvider` **und**
  `incomeWithoutAchievementsProvider`. Wer einen weiteren ergänzt, ergänzt
  alle drei.
- **Der Spielstand hat einen achten Bereich** (`reviews`). `SaveWatcher`
  schreibt ihn, ein Test prüft das.
- `progression_test.dart` rechnet die Rückfrage nicht mit. Seine Kurven
  sind für Erfahrung und Gold eine untere Schranke.
- Die Reihenfolge der Antworten wechselt täglich, sonst merkt man sich die
  Stelle statt der Antwort.
- Was „gefestigt" heißt, etwa eine Seite, die dreimal in Folge sitzt, ist
  noch nicht sichtbar. Die Zahl lässt sich aus dem `ReviewLog` rechnen, der
  Baum könnte sie zeigen.
