# ADR-0016: Die Fähigkeitsslots werden vor den Fähigkeiten gebaut, und sie liegen bei der Levelkurve

**Datum:** 22.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

[ADR-0013](0013-charakter-als-kommandozentrale.md) legte vier Fähigkeitsslots
fest, die auf Level 3 / 6 / 10 aufgehen, und
[ADR-0012](0012-theoriebaum-ueber-punkte.md) trug dieselben Stufen in die
Tabelle „Was ein Levelaufstieg gibt" ein. Beide ADRs führen die **Fähigkeiten
selbst** ausdrücklich als offenen Punkt: „Welche zwanzig Fähigkeiten es sind,
was sie kosten und was sie tun" ist nicht entschieden.

Damit stand die Frage, ob sich der Slot-Teil überhaupt vorziehen lässt. Die
naheliegende Antwort ist nein — ein Behälter ohne Inhalt ist kein Feature.

Dazu kam eine zweite Frage, die beim Bauen sofort auftauchte: **Wo liegt die
Zahl 3 / 6 / 10?** Ein Fähigkeits-Package gibt es nicht, und `lib/` ist laut
`CLAUDE.md` für Spielzahlen gesperrt.

## Entscheidung

**1. Die Slots werden vor den Fähigkeiten gebaut** und sichtbar gemacht — offen
oder gesperrt, mit der Stufe, ab der sie aufgehen. Was in ihnen liegt, bleibt
unentschieden.

**2. Die Schwellen liegen in `packages/progression`**, in
`lib/src/ability_slots.dart`. Nicht in einem neuen Package, nicht in `lib/`.

**3. Slot 1 steht ab Level 1 offen und zeigt die getragene Waffe.** Er ist der
Slot, den laut ADR-0013 die Waffe bestimmt.

**4. Ein offener Slot sagt „leer", und darunter steht, dass die Fähigkeiten
noch fehlen.** Der Bildschirm behauptet nicht, fertig zu sein.

**5. Nichts davon wird gespeichert.** Der Zustand eines Slots ergibt sich aus
Level und angelegter Waffe.

## Begründung

**Warum die Slots vor ihrem Inhalt.** ADR-0013 hat die Regel dafür schon
formuliert, dort für den gesperrten vierten Slot: „Ein Startbildschirm, der nur
zeigt, was schon fertig ist, verschweigt, worum es geht." Ein Spieler auf Level
2 soll sehen, dass auf Level 3 etwas aufgeht. Ohne das ist ein Levelaufstieg
eine Zahl, die sich ändert — und genau das war Loch 1 aus ADR-0013.

Der zweite Grund ist ehrlicher: **Die zwanzig Fähigkeiten sind eine
Konzeptentscheidung, die Slots sind es nicht.** Sie sind seit ADR-0013
entschieden, zweimal. Sie deshalb liegen zu lassen, bis der große
unentschiedene Block fällt, hieße entschiedene Arbeit an unentschiedene zu
koppeln.

**Warum `packages/progression` und kein neues Package.** Ein Slot ist nichts,
was eine Fähigkeit mitbringt — er ist das, was ein *Levelaufstieg gibt*. Genau
so steht es in der Tabelle von ADR-0012, neben Theoriepunkt und
Fähigkeitspunkt. Er gehört deshalb neben die Kurve, die bestimmt, wann dieser
Aufstieg kommt. Ein eigenes Package für vier Zahlen wäre außerdem das, wovor
YAGNI warnt: Struktur für etwas, das es noch nicht gibt.

Die Probe darauf ist, dass `ability_slots_test.dart` die Schwellen **gegen die
Levelkurve** prüfen kann, ohne ein zweites Package zu kennen: dass alle vier
unter `maxLevel` liegen, und dass der letzte früh genug kommt, um noch jemanden
zu erreichen.

**Warum Slot 1 die Waffe zeigt, statt „leer" zu sagen.** Es ist die einzige
Aussage, die dieser Bildschirm heute schon vollständig machen kann. Was in Slot
1 landet, ist laut ADR-0013 keine Wahl, sondern folgt aus der Ausrüstung — und
das lässt sich zeigen, bevor eine einzige Fähigkeit existiert. Ein Slot, der
„leer" sagt, obwohl eine Waffe angelegt ist, wäre falsch.

**Warum nichts gespeichert wird.** Es gibt noch keine Wahl zu speichern. Ein
leeres Feld im Spielstand anzulegen, das später gefüllt wird, wäre eine zweite
Wahrheit über etwas, das sich vollständig aus Level und Waffe ergibt — dieselbe
Fehlerquelle, die bei Gold und Titeln vermieden wurde (ADR-0011, ADR-0014).

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Auf die zwanzig Fähigkeiten warten | Koppelt entschiedene Arbeit an einen unentschiedenen Block; der Levelaufstieg bleibt solange folgenlos |
| Die vier bestehenden Moves aus `packages/combat` in die Slots legen | Täuscht eine Entscheidung vor, die nicht gefallen ist — welcher Move in welchem Slot, und welcher an der Waffe hängt |
| Ein eigenes `packages/abilities` nur für die Schwellen | Vier Zahlen rechtfertigen kein Package; und die Schwellen sind eine Eigenschaft des Levels, nicht der Fähigkeit |
| Die Zahlen in `lib/character/` | `CLAUDE.md` ist eindeutig: Spielzahlen gehören in ein Package |
| Gesperrte Slots ausblenden | Widerspricht der Hausregel aus ADR-0013 — was fehlt, ist eine Information |
| Slot 1 erst mit der ersten Waffe zeigen | Der Platz existiert unabhängig davon, ob etwas darin liegt; sonst wäre unklar, wofür eine Waffe gut ist |
| Slots im Spielstand mitschreiben | Es gibt keine Wahl zu speichern; ein leeres Feld auf Vorrat wäre eine zweite Wahrheit |

## Konsequenzen

**Leichter:** Der Levelaufstieg hat auf dem Charakterbildschirm wieder eine
sichtbare Folge, und zwar bis Level 10. Wenn die Fähigkeiten kommen, ist der
Platz für sie gebaut und getestet — es fehlt nur der Inhalt und die Wahl.

**Schwerer:** Der Bildschirm zeigt jetzt drei Plätze, die „leer" sagen. Das ist
vertretbar, solange der Satz darunter erklärt, warum — aber es ist ein
Versprechen mit Frist. Bleibt es lange stehen, wird aus „kommt noch" ein
sichtbarer Rest.

**`AbilitySlots` ist bewusst unvollständig.** ADR-0012 nennt drei Dinge, die ein
Aufstieg gibt: Theoriepunkt je Stufe, Fähigkeitspunkt auf jeder dritten, Slots
auf 3 / 6 / 10. Nur die Slots stehen dort. Die beiden Punktarten gehören
daneben, sobald sie gebaut werden — nicht woanders hin.

**Offen und unverändert:** Welche zwanzig Fähigkeiten es gibt, was sie tun, was
sie kosten, welche Waffe welche mitbringt. Diese Entscheidung nimmt davon nichts
vorweg — sie baut nur den Platz.
