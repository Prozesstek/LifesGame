# ADR-0020: Der Kampf hängt am Moveset, nicht mehr am Handbuch allein

**Datum:** 24.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

[ADR-0018](0018-kampf-hinter-dem-handbuch.md) sperrt den Kampf, bis der freie
Zweig „Gewohnheiten" durch ist. Der Grund war nie das Handbuch selbst, sondern
eine gemessene Zahl: **Mit einem einzigen Move ist der erste Gegner nicht
knapp, sondern unschlagbar** — 0 % Siegquote in der Simulation, 100 % mit
zweien.

Das Handbuch war dafür ein **Stellvertreter**, und er hat gestimmt, weil zwei
Dinge gleichzeitig zutrafen:

1. Die fünf Lektionen geben 275 Erfahrung und damit Level 3 — die Stufe, auf
   der der zweite Fähigkeitsslot aufgeht (ADR-0016).
2. In diesen Slot passte **immer** etwas: Kraftschlag, Zehrung, Sammeln und
   Atemzug waren `FromStart`, also von Anfang an offen.

Punkt 2 gilt seit [ADR-0019](0019-skillbaum-mit-vier-wurzeln.md) nicht mehr.
Die vier hängen jetzt an Theorieknoten unter *Körper*. Damit kann der zweite
Slot aufgehen und **leer bleiben** — und das Handbuch allein wäre wieder die
Einladung zu einem Kampf, den niemand gewinnen kann.

## Entscheidung

**Der Kampf öffnet sich, wenn zwei Bedingungen erfüllt sind:**

1. Das Handbuch ist durchgearbeitet (unverändert aus ADR-0018).
2. Das Moveset umfasst mindestens **zwei** Moves.

Die Zahl steht als `minMovesForCombat` in `lib/combat/combat_controller.dart`,
neben der Begründung.

**Die Kachel nennt weiterhin den Weg statt der Absage** — und sie
unterscheidet drei Fälle:

| Zustand | Text |
|---|---|
| Handbuch offen | „Erst das Handbuch: noch N Lektionen in Gewohnheiten" |
| keine Fähigkeit gelernt | „Erst eine Fähigkeit lernen — ein Knoten unter „Körper"" |
| gelernt, aber nicht angelegt | „Leg eine Fähigkeit auf einen freien Platz (Charakter)" |

## Begründung

**Die neue Bedingung ist die alte, nur direkt ausgesprochen.** ADR-0018 wollte
verhindern, dass jemand mit einem Move antritt. Es hat das über einen Umweg
getan, weil der Umweg damals zuverlässig war. Jetzt ist er es nicht mehr —
also wird die Bedingung selbst geprüft.

**Der dritte Fall ist kein Detail.** Wer die Fähigkeit gelernt, aber nicht auf
einen Platz gelegt hat, würde von einem Hinweis auf die Theorie dorthin
zurückgeschickt, wo er nichts mehr zu tun hat. Das ist die Sorte Sackgasse,
die einen Spieler kostet.

**Drei Schritte statt einem — bewusst.** Handbuch, Knoten, Platz belegen. Das
ist mehr Aufwand als vorher, und es ist der Preis dafür, dass Fähigkeiten
überhaupt etwas kosten (ADR-0019). Ohne ihn wäre der Theoriebaum für den Kampf
folgenlos.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Bei ADR-0018 bleiben (nur Handbuch) | Der Stellvertreter stimmt nicht mehr. Der Spieler stünde mit einem Move vor einem Gegner, den die Simulation bei 0 % ausweist. |
| Eine Fähigkeit wieder `FromStart` lassen | Ein Sicherheitsnetz, das die Entscheidung aus ADR-0019 halb zurücknimmt. Dann hinge eine von vier an nichts, und niemand wüsste später, warum. |
| Auf „mindestens eine Fähigkeit gelernt" prüfen statt aufs Moveset | Prüft die falsche Größe. Wer gelernt, aber nicht angelegt hat, ginge trotzdem mit einem Move in den Kampf. |
| Den zweiten Slot automatisch belegen | Nimmt dem Spieler die Wahl, die ADR-0013 zum Kern des Charakters erklärt. |

## Konsequenzen

**Der Weg zum ersten Kampf ist länger geworden.** Vorher: fünf Lektionen.
Jetzt: fünf Lektionen, ein Theorieknoten öffnen und bestehen, eine Fähigkeit
auf einen Platz legen. Ob das zu lang ist, zeigt der 30-Tage-Lauf
(`docs/context/ziele.md`, Ziel 7) — vorher ist es eine Vermutung.

**Die Arithmetik aus ADR-0018 bleibt gültig und wird weiter geprüft.** Fünf
Lektionen geben Level 3, vier nicht. `test/progression_test.dart` hält das
fest. Neu dazu kommt: Auf Level 3 gibt es vier Theoriepunkte, ein Knoten
kostet einen, und die vier Fähigkeitsknoten hängen direkt an einer kostenlosen
Wurzel — der Weg ist also bezahlbar in dem Moment, in dem der Slot aufgeht.
Das prüft `test/abilities_seam_test.dart`.

**Zwei Provider mehr in `lib/`, und sie enthalten eine Regel.** `combatUnlocked`
und `combatBlockReason` stehen damit an der Grenze dessen, was die Schichtregel
aus `CLAUDE.md` erlaubt. Sie bleiben dort, weil die Bedingung drei Packages
verbindet (`theory`, `abilities`, `combat`) und keines davon die anderen
kennen darf — dieselbe Begründung wie bei den sechs Zusammenlauf-Providern.

**Wenn die elf übrigen Fähigkeiten kommen** (ADR-0017), wird die Sperre
milder: Mehr Quellen heißt mehr Wege zum zweiten Move. Die Bedingung bleibt
richtig, sie greift nur seltener.
