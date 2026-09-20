# ADR-0036: Das Streak-Eis ist ein Gegenstand, kein Nachlass

**Datum:** 20.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Issue [#46](https://github.com/Prozesstek/LifesGame/issues/46) fordert vier
Dinge für die Gewohnheiten, drei davon Anzeige. Das vierte ist eine
Produktentscheidung: „Streaks auf Eis einführen, welche es ermöglichen dass
man ein Tag ausfallen lassen kann ohne die Streak zu reißen."

Der Wunsch ist begründet. Die Streak ist laut `konzept.md` 3.7 der Grund,
morgen wiederzukommen, und genau deshalb ist ihr Verlust der teuerste
Moment des Spiels. Ein Tag mit Grippe, eine Nachtschicht, eine Reise — und
eine Kette von dreißig Tagen steht wieder bei eins. ADR-0008 hat den
Multiplikator bei x2 gedeckelt, weil bei x3 „der Verlust einer langen
Streak so schmerzhaft wird, dass Nutzer aufgeben statt neu anzufangen".
Derselbe Gedanke, eine Stufe weiter gedacht, führt zum Eis.

Dagegen steht, was eine Streak *aussagt*. Eine Kette, die einen Fehltag von
selbst verzeiht, heißt nicht mehr „dreißig Tage am Stück", sondern
„irgendwann in den letzten vierzig Tagen". Damit wäre sie als Zahl wertlos
— und mit ihr die Titel, die daran hängen (ADR-0013), und die vier
Fähigkeiten an Streak-Marken (ADR-0022).

## Entscheidung

Das Streak-Eis ist ein **knapper Gegenstand**, der einen einzelnen
Kalendertag deckt. Der gedeckte Tag trägt die Kette weiter, **verlängert
sie aber nicht**: Eine Kette über dreißig Kalendertage mit einem Eis darin
ist neunundzwanzig lang. Erfahrung, Gold und Charakterwerte hängen
weiterhin ausschließlich an echten Häkchen.

Ein Eis deckt einen **Tag**, nicht eine Gewohnheit — es wirkt auf alle
Gewohnheiten dieses Tages zugleich.

**Woher die Eis kommen, ist bewusst noch nicht entschieden.** Bis dahin
gibt es eines über das ganze Spiel (`StreakFreeze.lifetimeStock`).

## Begründung

**Knappheit ist die ganze Antwort.** Was ein Eis rettet, kostet ein Eis.
Solange es weniger Eis als Fehltage gibt, bleibt die Kette eine Aussage
über Beständigkeit und wird trotzdem nicht von einem einzelnen schlechten
Tag zerstört. Dieselbe Bauform hat sich beim Verkauf im Laden bewährt
(ADR-0031): Ein Fehlgriff ist korrigierbar, aber nicht folgenlos.

**Der gedeckte Tag zählt nicht mit**, und das ist der Punkt, an dem die
Zahl ehrlich bleibt. Würde er mitzählen, ließen sich Meilensteine — und
über sie Titel und Fähigkeiten — mit Eis kaufen statt verdienen. So
bewahrt das Eis nur, was schon da war.

**Ein Tag statt einer Gewohnheit**, weil die Rückmeldung „ein Tag
ausfallen lassen" heißt. Wer krank im Bett liegt, hakt gar nichts ab; ihm
fünf Eis abzunehmen wäre genau die Strafe, die das Eis verhindern soll.

**Nur gestern lässt sich decken.** Wer heute merkt, dass gestern nichts
steht, soll reagieren können; wer nach zwei Wochen zurückkommt, soll seine
Kette nicht rückwirkend zusammenkaufen. Das Eis verzeiht einen Aussetzer,
es ersetzt kein Aufhören.

**Der Vorrat wird abgeleitet, nicht gezählt.** Gespeichert wird die
Historie der gedeckten Tage; wie viele Eis übrig sind, ergibt sich daraus
— dieselbe Entscheidung wie bei Gold (ADR-0011), Erfahrung (ADR-0008) und
den versenkten Verkäufen (ADR-0031). Ein gespeicherter Bestand könnte von
der Historie abweichen, eine Historie *ist* der Bestand.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Die Kette verzeiht jeden n-ten Fehltag von selbst | Dann sagt „30 Tage am Stück" nichts mehr aus, und die Titel und Fähigkeiten, die daran hängen, auch nicht. Es gäbe zudem nichts zu entscheiden — die Regel wirkt ohne Zutun. |
| Der gedeckte Tag zählt als Häkchen | Meilensteine, Titel und vier Fähigkeiten wären damit käuflich statt verdient. Und ein Eis brächte Erfahrung für einen Tag, an dem nichts getan wurde. |
| Ein Eis je Gewohnheit statt je Tag | Fünf Gewohnheiten, ein Krankheitstag, fünf Eis — die Kosten steigen genau dort, wo jemand am wenigsten kann. Dazu eine zweite Zahl in der Oberfläche, die niemand im Kopf behält. |
| Jeder Fehltag der Vergangenheit lässt sich decken | Wer nach drei Wochen zurückkommt, kaufte sich seine alte Kette zurück. Das Eis soll einen Aussetzer verzeihen, nicht ein Aufhören rückgängig machen. |
| Die Quelle gleich mitentscheiden (Laden, Meilenstein, Errungenschaft) | Der Auftrag war ausdrücklich „mach den Gegenstand, die Quelle überlegen wir dann". Eine Quelle ändert vier Kurven (`progression_test.dart`) und gehört in eine eigene Runde. |

## Konsequenzen

**Eine Regel steht an genau einer Stelle.** Ob eine Kette von einem Tag
zum nächsten durchläuft, beantwortet `HabitTracker._continues` —
`streakEndingAt`, `longestStreak` und `totalXp` fragen alle dort. Stünde
die Regel dreimal da, zeigte die Kachel irgendwann eine andere Kette an,
als die Erfahrung unterstellt.

**Der Bestwert kann durch ein Eis steigen, nie fallen.** `longestStreak`
rechnet über dieselbe Regel und überbrückt gedeckte Tage mit. Die
Errungenschaften bleiben damit monoton (ADR-0033, Punkt 3) — ein Eis kann
niemandem etwas wegnehmen, das er schon hatte.

**Die Errungenschaften, die auf Aktivität zählen, bleiben unberührt.**
`daysWithAtLeast`, `longestRunWithAtLeast` und `comebackStreakAfterPause`
rechnen weiter nur über echte Häkchen. „Der Unbeugsame" lässt sich nicht
mit Eis erkaufen.

**Die vier Kurven sind nicht neu gerechnet.** Ein Eis erzeugt keine
Erfahrung und kein Gold; es hält nur einen Multiplikator am Leben, den
jemand schon verdient hatte. `progression_test.dart` läuft unverändert
durch. Über ein Spielerleben verschiebt ein einziges Eis den Ertrag um
wenige Prozent eines Tages — messbar wäre das erst bei einem Vorrat, der
sich nachfüllt.

**Die offene Frage steht als eine Zahl da.** `StreakFreeze.lifetimeStock`
ist heute 1. Kommt später eine echte Quelle (Laden, Errungenschaft,
Meilenstein), gehört sie in `packages/habits` und nicht in die Oberfläche
— wie viele Eis jemand hat, ist eine Regel der Gewohnheiten. Solange die
Quelle nicht entschieden ist, ist das Eis verbraucht, sobald es einmal
benutzt wurde; das ist im 30-Tage-Lauf sichtbar und genau die
Rückmeldung, die die Entscheidung braucht.
