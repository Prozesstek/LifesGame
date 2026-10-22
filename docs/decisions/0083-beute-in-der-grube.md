# ADR-0083: Beute in der Grube — die Kaskade

**Datum:** 21.10.2026
**Status:** Aktiv — in zwei Punkten abgelöst durch ADR-0084: Eingesammeltes behält nur ein Sieg, und der Schlüssel öffnet nur nach einem Sieg
**Entschieden von:** AktivesBrett, in vier Fragerunden mit Claude
**Ergänzt:** [ADR-0048](0048-exemplare-tagesladen-und-beute.md) (Beute und
Schlüssel), [ADR-0041](0041-beute-je-gegner.md) (Gold je Gegner)
**Issue:** [#136 „Loot System“](https://github.com/Prozesstek/LifesGame/issues/136)

## Kontext

Bis hierher warf nur der Wächter ein Stück, und nur nach einem Sieg
(ADR-0048). Seit es nur noch die nächste Ebene gibt (16.10.), ist jeder
Lauf ein erster Sieg auf seiner Ebene — Schlüssel brauchte man nie mehr.

Issue #136 will: Gegenstände fallen **in der Grube**, nicht nur am Ende;
Legendäres sticht hervor; am Boden sieht man nur die **Gruppe** (einen
Schuh), mit dem Rand in der Farbe der Seltenheit, und erst am Ende,
welcher Schuh es ist; ein **Cascading Drop System**. Dazu zwei Bilder:
eine Skizze des Siegerblatts (XP, Gold, drei Kacheln mit Pfeilen,
„Weiter“, unten ein Kasten mit Gold) und ein Ausschnitt aus Summoners
War, wo man Runen mit Häkchen auswählt und gesammelt verkauft.

## Entscheidung

**Die Kaskade würfelt in Stufen, jede mit eigener Tabelle**
(AktivesBrett: „Würfel in Stufen“):

| Stufe | Frage | Wo |
|---|---|---|
| 1 | **Ob** etwas fällt — 13 % je Gegner, 30 % bei zähen (Troll, Grimlock), der Wächter immer | `ActionBalance.itemDropChance`, Grube |
| 2 | **Welcher Platz** — alle gleich | `GearRolls.slotWeights` |
| 3 | **Welche Seltenheit** — nach der Ebene, beim Wächter eine Stufe höher, soweit die Ebene sie erlaubt | `GearRolls.weightsFor`, `oneUp` |
| 4 | **Welches Stück** und welche Werte | `GearRolls.pick`, `rollBonus` |

Stufe 1 steht in der Grube, weil nur sie weiß, wer zäh ist; die Stufen
2 bis 4 in `package:gear` (`GearLoot.cascade`), weil die Grube keine
Ausrüstung kennt. Verbunden sind beide über die **Nummer des Fundes**:
Die Grube meldet `ItemDropped(nth)`, die App würfelt mit dem Startwert
des Laufs und dieser Nummer, was es ist (`PitBeute`).

**In der Grube:**

- **Hinlaufen** sammelt ein, mit einem kleinen Magneten. **Was am Ende
  noch liegt, ist weg.** Die Beute des Wächters muss man nicht holen:
  Mit ihm endet der Lauf.
- **Eingesammelt bleibt eingesammelt**, auch nach einer Niederlage. Wer
  mittendrin abbricht, verliert alles, wie beim Gold.
- **Am Boden die Gruppe**: das Zeichen des Platzes im Rand der
  Seltenheit. Episches liegt in einem violetten Schein, **Legendäres
  unter einer goldenen Lichtsäule mit eigenem Klang**.
- **Die Tagesgrube wirft nichts** — sie zahlt nur Ruhm (ADR-0072).
- **Schlüssel öffnen nach einem Lauf einen Extra-Wurf** auf der Kaskade,
  nach Sieg und Niederlage. So bleibt Abhaken die Quelle von mehr Beute
  (ADR-0048).

**Nach dem Lauf**, in zwei Schritten gebaut:

1. *(PR #144)* Die Funde gehen in den Rucksack und stehen im
   Ergebnisblatt als Kacheln; nach einem Sieg springt der beste Fund auf
   (Truhe, Vergleich, Anlegen), danach fragt der Schlüssel.
2. *(PR danach)* Das Siegerblatt nach der Skizze: Kacheln, die sich
   nacheinander umdrehen, das Seltenste zuletzt; der Pfeil gegen das
   Getragene; Antippen öffnet das Blatt des Stücks; **Häkchen und
   „Verkaufen“ mit dem Gold der Auswahl** — und dasselbe Verkaufen mit
   Häkchen im Rucksack.

**Werte bleiben, wie sie sind** (85–115 % des Katalogs); dass sie mit
der Tiefe wachsen, wie #115 es wollte, wäre ein eigener Schritt. **Der
Rucksack hat keine Grenze.**

## Begründung

**Vier bis sechs Stücke je Lauf** (AktivesBretts Wahl, gegen Claudes
Empfehlung von zwei bis drei). Gemessen mit
`dart run tool/pit_sim.dart beute 40` (Tag 30): In gewonnenen Läufen
fallen auf Ebene 1 und 5 im Schnitt 4,3 Stücke, auf Ebene 10 5,3. Der
Bot läuft keinem Fund nach und holt davon gut die Hälfte; wer hinläuft,
holt fast alles.

**Die Nummer des Fundes statt einer Ausrüstung in der Grube**: Die
Grube bleibt ohne Abhängigkeit (ADR-0002), und derselbe Startwert ergibt
dieselbe Beute. Die Uid trägt den Startwert des Laufs
(`beute-<ebene>-r<lauf>-<n>`), sonst wäre der zweite Lauf auf derselben
Ebene am selben Tag schon „besessen“ und fiele heraus.

**Ein eigener Würfel für die Beute** (`_lootRng`): Ob etwas fällt, soll
keinen kritischen Treffer und keine Kugel verschieben. Ein Test hält
fest, dass derselbe Lauf mit und ohne Beute dieselben Treffer hat.

**Gewürfelt wird beim Fallen**, nicht beim Einsammeln: Der Rand am Boden
und die Lichtsäule müssen schon wissen, was es ist.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Kaskade als Bild (eins nach dem anderen platzt heraus) | AktivesBrett meinte die Würfel in Stufen |
| Ein Drop zieht den nächsten | dito |
| Funde fliegen von selbst zum Helden | AktivesBrett: hinlaufen |
| Bei Niederlage alles weg | AktivesBrett: man behält sie |
| Beute auch in der Tagesgrube | dann wäre sie nicht mehr für alle gleich |
| Schlüssel streichen | Abhaken soll weiter Beute bringen (ADR-0048) |
| Werte wachsen mit der Tiefe | ein eigener Schritt, nicht dieses Ticket |
| Grenze für den Rucksack | AktivesBrett: keine; dafür Aufräumen und Verkaufen mit Häkchen |

## Konsequenzen

- **Die Grube bekommt einen Schalter** (`ActionWorld.dropsItems`): Nur
  `PitScreen` setzt ihn. `ActionGame` prüft im Debug, dass eine Grube
  mit Beute auch jemanden hat, der sie würfelt (`funde`).
- **`takeLoot` ist weg**; an seine Stelle treten `takeRunLoot` (die
  Funde des Laufs) und `takeKeyLoot` (der Extra-Wurf). `GearLoot.drop`
  bleibt für `runway_sim`.
- **Der Rucksack wächst schneller.** Ob vier bis sechs Stücke je Lauf
  zu viel sind, stand schon vorher als offen in `state.md`.
- **Zwei neue Klänge**, gerechnet in `tool/kampf_klaenge.py`: `Fund`
  und `Legendaer`.
- **Der beste Fund springt nur noch beim ersten Sieg überhaupt auf**
  (Schritt 2): Das Siegerblatt zeigt jetzt jeden Fund, und ein Dialog
  danach sagte dasselbe noch einmal. Beim ersten Sieg bleibt er, weil er
  erklärt, was eine Truhe ist.
- **Am Boden und auf der Rückseite steht ein Umriss**, kein Zeichen:
  das Bild eines gewöhnlichen Stücks des Platzes
  (`GearIcons.gruppeFor`), ganz in der Farbe der Seltenheit.
- **Verkaufen mit Häkchen hat eine Regel an einer Stelle**
  (`VerkaufAuswahl`): Angelegtes und Gesperrtes bekommt kein Häkchen,
  und was nicht mehr verkäuflich ist, fällt aus der Auswahl. Der Erlös
  ist ein Viertel wie bei jedem Verkauf (`GearPrices.refundShare`).
- **Nicht gespielt, nicht am Handy.**
- **Frederik hat diese Runde nicht gesehen.**
