# ADR-0034: Episch und Legendär hängen an der Gegnerreihe

**Datum:** 14.09.2026
**Status:** Aktiv
**Entschieden von:** AktivesBrett
**Ergänzt:** [ADR-0029](0029-seltenheit-statt-preisleiter.md) (drei Stufen → fünf)

## Kontext

Der Wunsch: „Für jede Ausrüstung noch zwei Epics und ein Legendary." Also
achtzehn Stücke dazu, drei je Platz, und zwei neue Seltenheitsstufen.

Dagegen stand eine ausdrückliche Entscheidung. `GearRarity` hatte drei
Stufen, und der Kommentar sagte, warum:

> Episch und Legendär sind in `package:abilities` der Lohn für tiefen
> Fortschritt. Im Laden gibt es nichts zu erreichen, nur zu kaufen — dafür
> reichen drei.

Das stimmte am 08.09. Seit [ADR-0032](0032-gegnerreihe-statt-dungeon.md)
stimmt es nicht mehr: Die Gegnerreihe hat dreißig Sprossen, und der Laden
kann an ihr hängen.

Ein zweites Hindernis war die Preisrechnung. `catalog_test.dart` deckelt das
teuerste Stück bei 45 Tagen Gewohnheiten (1125 Gold); Selten liegt mit 1050
schon knapp darunter. Zwei Stufen darüber passen unter diesen Deckel nicht —
und ohne Deckel wären sie im 30-Tage-Lauf für niemanden erreichbar.

## Entscheidung

### 1. Fünf Stufen, und die beiden oberen sind verdient, nicht nur gekauft

Episch ab **Sprosse 10** der Gegnerreihe, Legendär ab **Sprosse 20**. Die
Stücke stehen im Laden, sichtbar und mit Preis, aber gesperrt — die Kachel
sagt „gesperrt", die Detailfläche „Verdient ab Gegner 10 der Reihe".

Die beiden Zahlen stehen in `GearGates`, an genau einer Stelle. Ob es die
Sprossen gibt, prüft `test/gear_gates_seam_test.dart` in der App — `gear`
kennt die Reihe nicht.

### 2. Die Sperre ist die Hürde, der Preis nur der zweite Schritt

Episch kostet 900 bis 1500, Legendär 1450 bis 2000 — mäßig über Selten,
nicht unbezahlbar. Wer Sprosse 20 geschafft hat, hat das Gold der Reihe
dazu. Die 45-Tage-Grenze gilt weiter, aber nur für die fünf offenen Stücke
je Platz; Legendär hat eine eigene bei 80 Tagen.

### 3. Warum 10 und 20, nicht 15 und 30

Sprosse 30 ist der letzte Gegner. Wer dort Legendäres freischaltet, hat
nichts mehr, wogegen er es tragen könnte. Ab Sprosse 20 bleiben zehn Gegner,
die den Kauf rechtfertigen — und Sprosse 20 ist der Bergwächter, der
Endgegner der alten Dreierreihe.

### 4. Die Sperre gilt beim Kauf, nicht beim Tragen

Geprüft wird in `Loadout.blockFor`, **vor** dem Gold: Wer ein gesperrtes
Stück ansieht, soll lesen, dass es verdient werden muss — nicht, dass es zu
teuer ist. Ein gekauftes Stück bleibt, was auch immer die Reihe später
sagt; dieselbe Trennung wie beim Titel (ADR-0014).

### 5. Kein Set-Teil, kein neuer Spielstand

Die achtzehn Stücke tragen keine `setId`: Ein Set soll in dreißig Tagen
erreichbar bleiben, und ein Teil hinter Sprosse 20 machte es bis dahin
unvollständig. Der Spielstand ist unverändert — die Sperre wird aus
`LadderProgress.highestDefeated` gerechnet, das es schon gibt.

### 6. Drei neue Waffenzüge, drei Rhythmen, die es noch nicht gab

Jede Waffe braucht einen eigenen Zug (ADR-0017), also drei neue in
`package:combat`:

| Waffe | Zug | Power | Energie | Was neu ist |
|---|---|---|---|---|
| Zweihänder | Spalter | 1,6 | +1 | der härteste Schlag, der langsamste Motor |
| Langbogen | Doppelschuss | 0,45 × 2 | +4 | zwei Tipps, zwei Chancen auf Perfect |
| Sonnenklinge | Sonnenhieb | 1,4 | +3 | der erste Waffenzug mit Perfect-Wirkung: entzündet |

Alle drei erzeugen Energie und kosten keine — die Regel aus ADR-0017 gilt
weiter, und die Sets wirken deshalb auch auf sie nicht (ADR-0030).

## Begründung

**Warum nicht einfach teurer.** Bei 3500 bis 4000 Gold hätte niemand im
30-Tage-Lauf ein Legendär gesehen — 160 Tage Gewohnheiten. Die Stufen wären
Katalogeinträge ohne Spieler. Die Sperre macht sie in derselben Zeit
erreichbar, in der die Reihe gespielt wird, und gibt der Reihe einen Grund
mehr, weitergespielt zu werden.

**Warum die Reihe und nicht die Streak.** Die Fähigkeiten hängen schon an
der Streak (Sternenfall ab 60 Tagen). Hinge die Ausrüstung ebenfalls daran,
wäre die Reihe die einzige Quelle, die nichts freischaltet — ausgerechnet
die, die Gold zahlt. Mit der Sperre greifen Kampf und Laden ineinander:
Siege öffnen Stücke, Stücke gewinnen Siege.

**Warum die Sperre vor dem Gold kommt.** „Dafür reicht das Gold nicht" auf
einem Stück, das man gar nicht kaufen dürfte, führt in die Irre: Man spart,
und wenn das Gold da ist, ist der Knopf immer noch aus.

**Warum Legendär nicht *strikt* stärker ist als Episch.** Gemessen an Tag 30
über alle dreißig Gegner liegt die Sonnenklinge knapp unter dem Zweihänder
(87 % gegen 91 % auf Sprosse 23). Der Grund ist die Simulation: Der Bot
trifft zur Hälfte perfekt, der Brand zündet also nur jede zweite Runde. Ein
Mensch, der die Leiste trifft, hat mit der Sonnenklinge den härteren Zug
*und* Dauerschaden — das ist der legendäre Anteil, und er ist per Bauart
nicht simulierbar (`state.md` vom 08.09., derselbe Befund bei den Sets).
Die erste Fassung mit Power 1,2 lag deutlich darunter (63 %) und wurde
deshalb auf 1,4 gehoben.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Nur über den Preis (3500–4000) | Im 30-Tage-Lauf für niemanden erreichbar; die 45-Tage-Grenze müsste fallen |
| Freischalten über die Streak | Die Reihe bliebe die einzige Quelle, die nichts öffnet — ausgerechnet die, die Gold zahlt |
| Legendär ab Sprosse 30 | Der letzte Sieg schaltete Ausrüstung frei, die gegen nichts mehr getragen wird |
| Sperre erst beim Tragen | Ein gekauftes Stück, das nicht wirkt, sieht wie ein Fehler aus (dasselbe Argument wie bei ADR-0011, „gekauft wird angelegt") |
| Gesperrte Stücke ausblenden | Ein Ziel, das man nicht sieht, ist keins; die Reihe soll auf etwas hinführen |
| Set-Marken auf Episch/Legendär | Ein Set wäre bis Sprosse 20 unvollständig, und die 2er-Stufe das Einzige, was es je gibt |
| Die Sperre als Feld am Stück statt an der Stufe | Achtzehn Stücke, achtzehn Zahlen, und eine, die jemand vergisst; an der Stufe ist es eine Frage, eine Stelle |

## Konsequenzen

**Leichter:** 48 Stücke statt 27, ohne dass der Laden unübersichtlicher
wird — die Reiter je Platz (#35) tragen acht Kacheln in drei Reihen. Die
Reihe und der Laden greifen ineinander. Der Spielstand bleibt, wie er war.

**Schwerer:** `Loadout.buy` und `blockFor` haben einen dritten Parameter,
`highestRung`. Er hat einen Standardwert (0), und das ist die **sichere**
Richtung: Wer ihn vergisst, bekommt eine Sperre, nicht einen Bypass.
Tests, die den ganzen Katalog kaufen, müssen ihn setzen — drei haben es
beim Bauen sofort gemeldet.

**Der Entwicklermodus schaltet auch die Sperre ab** (`grant`), wie er das
Gold abschaltet. Bewusst: Er ist zum Ausprobieren da.

**Offen:**

- **Bilder.** Die achtzehn Stücke haben keine; die Kachel zeigt das
  Platz-Symbol. Frederiks 64×64-Stil ist die Vorgabe.
- **Ob 10 und 20 richtig liegen**, sagt der 30-Tage-Lauf. Zu früh wäre
  erkennbar daran, dass Selten übersprungen wird; zu spät daran, dass
  niemand je Episches trägt.
- **Die Balance der drei Waffen** ist gemessen, nicht tariert — wie alles
  andere seit dem 26.08.
