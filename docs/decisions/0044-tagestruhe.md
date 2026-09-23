# ADR-0044: Die Tagestruhe — und damit die Quelle des Streak-Eises

**Datum:** 23.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Die kritische Durchsicht vom 23.09. (siehe ADR-0043) fand keine einzige
**unvorhersehbare** Belohnung im Spiel. Der Topf in der Grube steht fest,
die Preise stehen fest, die Errungenschaften stehen im Katalog. Gerade der
variable Ertrag bringt Menschen dazu, wiederzukommen: die Kiste, die
meistens wenig und manchmal viel bringt.

Daneben war seit Issue #46 offen, **woher das Streak-Eis kommt**
(`StreakFreeze.lifetimeStock`, eines über das ganze Spiel).

## Entscheidung

Wer heute jede laufende Gewohnheit erledigt, öffnet eine **Tagestruhe**,
einmal je Tag. Ihr Inhalt wird aus dem Datum gewürfelt
(`DailyChest.forDay`):

| Stufe | Gewicht | Inhalt |
|---|---|---|
| Schlicht | 70 | 5 bis 10 Gold |
| Gut gefüllt | 20 | 15 bis 25 Gold |
| Streak-Eis | 8 | ein Eis und 5 Gold |
| Schatz | 2 | 60 Gold |

Gespeichert wird nur, an welchen Tagen geöffnet wurde. Gold und Eis werden
daraus gerechnet. Das Streak-Eis kommt ab jetzt aus der Truhe, dazu bleibt
das eine zum Start.

## Begründung

- **Variabel, aber berechenbar im Mittel.** Rund 11 Gold am Tag, knapp die
  Hälfte der 25, auf die der Laden ausgelegt ist. Das spürt man, aber es
  leert den Laden nicht. Ein Test hält die Spanne fest.
- **Aus dem Datum statt beim Öffnen gewürfelt.** Ein Neustart würfelt
  nicht neu, man kann also nicht so lange öffnen, bis ein Schatz kommt.
  Gespeichert werden muss nur, *dass* geöffnet wurde. Beide Spieler haben
  am selben Tag dieselbe Truhe, ein Schatz ist dann etwas, worüber man
  redet.
- **An „alles erledigt" gebunden.** Die Truhe belohnt den vollen Tag, nicht
  das einzelne Häkchen. Dafür gibt es die Tagesform (ADR-0043).
- **Das Eis aus der Truhe** löst Issue #46, ohne einen Laden oder eine
  Errungenschaft zu verbiegen. Wer dranbleibt, bekommt gut zwei Eis im
  Monat. Das Eis schützt also genau die Leute, die es verdienen.
- **Park–Miller statt `dart:math`**, dasselbe Verfahren wie bei den
  Dailies (ADR-0040): Die Folge ist auf jeder Plattform gleich, auch im
  Browser.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Ausrüstung als seltener Inhalt | Gold wird aus dem Besitz gerechnet (ADR-0011). Ein geschenktes Stück zöge seinen Preis vom Gold ab, wie im Entwicklermodus (ADR-0021). Das bräuchte eine eigene Historie für Geschenke. Später möglich. |
| Beim Öffnen würfeln und das Ergebnis speichern | Ein gespeicherter Ertrag ist eine zweite Wahrheit neben der Historie. Und ein Neustart vor dem Speichern würfelte neu. |
| Eine Truhe je Häkchen | Fünf kleine Truhen am Tag sind keine Überraschung mehr. Und das einzelne Häkchen trägt schon die Tagesform. |
| Das Eis im Laden kaufen | Dann wird Gold zur Versicherung einer Kette. Die Kette soll aber am Tun hängen, nicht am Geld. |

## Konsequenzen

- `HabitTracker.totalGold` enthält jetzt das Gold aus den Truhen. Es
  läuft ohne weitere Stelle in den Goldstand. `progression_test.dart`
  rechnet die Truhe **nicht** mit: Seine Kurven sind für das Gold eine
  untere Schranke.
- Man kann nur die Truhe von **heute** öffnen. Wer abends alles erledigt
  und erst am nächsten Morgen nachsieht, hat sie verpasst. Das ist bewusst
  so: Nachholen für gestern hieße, das „heute" aufzuweichen.
- Ein Häkchen zurückzunehmen nimmt eine geöffnete Truhe nicht zurück. Man
  könnte also abhaken, öffnen und zurücknehmen. Man hat die Gewohnheit
  dann aber auch erledigt, und ein zweites Mal geht es nicht.
- Das Bild ist Raven fc6 (`assets/Items/Truhe.png`).
