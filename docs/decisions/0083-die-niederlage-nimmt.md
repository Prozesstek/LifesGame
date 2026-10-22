# ADR-0083: Die Niederlage nimmt, was gefallen ist — und zeigt drei Wege

**Datum:** 22.10.2026
**Status:** Aktiv
**Entschieden von:** Prozesstek

## Kontext

Frederik: „ich würde es gerne so machen, dass wenn man einen Lauf
verliert man kein Gold und kein XP und keine Items bekommt. Stattdessen
bekommt man eine Animation wie diese Sachen einem wieder weggenommen
werden und vielleicht 3 Tipps wie man seinen Charakter stärker machen
kann, damit der Lose Screen nicht so traurig aussieht.“

Bis dahin galt ADR-0041: Erfahrung und Gold fallen je Gegner, und **ein
verlorener Lauf behält, was gefallen ist** (`LadderProgress.partial`).
Der nächste Versuch spielte nur noch um den Rest des Topfs. Items gab es
schon vorher nur nach einem Sieg, als Beute des Wächters (ADR-0048).

Das Blatt „Niederlage“ zeigte entweder diese Teilbeute oder gar nichts,
dazu nach dem ersten Lauf das Buch (ADR-0069).

## Entscheidung

**Nur ein Sieg zahlt, und dann den ganzen Topf.** Eine Niederlage bucht
nichts außer, dass verloren wurde (`LadderProgress.bookRun`). Im Lauf
regnet es weiter Münzen und Funken; geht er verloren, **nimmt die Grube
sie zurück**, wo sie gesammelt wurden: Die Kasse zählt herunter und
glüht rot, der Balken läuft zurück, ein Aufstieg im Lauf fällt wieder
ab, Münzen und Funken springen vom Helden weg und verlöschen
(`BeuteRegen.verliere`). Dazu klingt der Ton einer falschen Antwort.
Erst dann kommt das Blatt.

**Das Blatt zeigt drei Tipps aus dem eigenen Stand**
(`StaerkerWerden.tipps`), jeder ein Knopf in seinen Bereich, an die
Stelle der Grube wie das Buch:

| Reihenfolge | Tipp | wenn |
|---|---|---|
| 1 | Ein Fähigkeitsplatz ist leer | ein offener Platz ist leer und es gibt eine Fähigkeit dafür |
| 2 | Im Rucksack liegt ein besseres Stück | ein nicht getragenes Exemplar ist besser (`Loadout.vergleiche`) |
| 3 | Theoriepunkte sind frei | mindestens einer |
| 4 | Noch n Häkchen bis In Form | heute ist noch etwas fällig |
| 5 | Im Laden ist etwas Besseres bezahlbar | ein Angebot ist besser und kaufbar |

Reicht das nicht für drei, füllen allgemeine Sätze auf (Häkchen, Seiten,
Laden). **Nie zwei Tipps in denselben Bereich.**

In einer Fragerunde entschieden: die Animation **in der Grube**, nicht
im Blatt; die Tipps **aus dem Spielstand und antippbar**, nicht aus
einer festen Liste. Beides wie empfohlen.

## Begründung

**Die Animation gehört dorthin, wo gesammelt wurde.** Kasse und Balken
haben den ganzen Lauf mitgezählt; dort zurückzuzählen erzählt, was
passiert, ohne einen Satz. Im Blatt wäre es eine zweite Rechnung an
einer anderen Stelle.

**Tipps aus dem Stand führen irgendwohin.** Ein allgemeiner Rat („Mach
Häkchen“) stimmt immer und hilft selten. Ein leerer Platz oder ein
besseres Stück im Rucksack ist ein Fehler, den man in zehn Sekunden
behebt — und genau der, den ein Neuer nach dem ersten verlorenen Lauf
nicht sieht. Was sofort und umsonst hilft, steht deshalb vorn.

**Die Summe bleibt dieselbe.** Wer eine Stufe schafft, bekommt genau den
Topf, den sie vorher insgesamt brachte (ADR-0032, ADR-0041). Es ändert
sich nur, wer ihn bekommt: nicht mehr, wer oft verliert.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Wegnehmen im Ergebnisblatt (Zahlen zählen dort auf null) | weniger Aufwand, aber getrennt von dem Ort, an dem man gesammelt hat |
| Feste Liste von Ratschlägen | passt oft nicht zum Stand, führt nirgends hin |
| Im Lauf gar nichts mehr fallen lassen | der Goldregen (16.10.) ist das, was den Lauf belohnend macht; er bleibt, nur als Versprechen |
| Alte Teilbeute (`partial`) bei der nächsten Niederlage streichen | sie ist längst in der Erfahrung gezählt — ein Level fiele nachträglich |

## Konsequenzen

- **Alte Stände behalten, was sie in verlorenen Läufen gesammelt
  haben.** `partial` wird gelesen und beim Sieg aufgelöst, aber nie mehr
  größer. Wer schon etwas gesammelt hat, spielt um den Rest.
- **Verlieren wird teurer.** Ein Spieler, der eine Stufe zehnmal
  versucht, hatte bisher am Ende denselben Topf, aber verteilt über zehn
  Läufe. Jetzt zahlt nur der zehnte. `runway_sim` rechnet nur mit Siegen,
  seine Zahlen ändern sich nicht.
- **„Abbrechen“ und „verlieren“ sind jetzt gleich**: Beides bringt
  nichts. Der Satz der Rückfrage („Was bisher gefallen ist, geht
  verloren“) stimmte schon und stimmt weiter.
- **Die Tagesgrube ist nicht berührt**: Sie zahlt nur Ruhm, und
  antreten zählt (ADR-0072).
- **Das Buch nach dem ersten Lauf bleibt** (ADR-0069): Es steht weiter
  neben „Nochmal“, wer das Blatt mit „Weiter“ schließt.
- `konzept.md` 3.7 („das Spiel bestraft nicht“): Es nimmt nichts, was
  man schon hatte — nur, was im Lauf in Aussicht stand. Die Fußnote des
  Blatts sagt das so, und `lauf_ergebnis_test.dart` hält fest, dass dort
  kein „verlierst“ steht.

`loot_test.dart`, `loot_app_test.dart`, `beute_regen_test.dart` („die
Niederlage nimmt“), `staerker_werden_test.dart`,
`lauf_ergebnis_test.dart`, `erster_lauf_test.dart`.
