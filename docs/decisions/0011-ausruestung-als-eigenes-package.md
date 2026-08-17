# ADR-0011: Ausrüstung als eigenes Package, Gold abgeleitet statt gezählt

**Datum:** 17.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Gold entstand täglich aus Häkchen und einmalig aus Lektionen — und
verschwand nie. Es war eine Zahl, die nur wuchs. Das Konzept nennt
Gewohnheiten und Theorie ausdrücklich „Einnahme" und alles Weitere
„Ausgabe" (Abschnitt 1); die zweite Hälfte fehlte vollständig.

Dazu kam ein zweites Problem aus [ADR-0009](0009-kampfbalance-ueber-gegnerreihe.md):
Der Charakter steht nach etwa einem Monat an allen vier Stat-Deckeln. Danach
bringen Gewohnheiten nur noch Erfahrung, der Charakter wird nicht mehr
stärker. Ein dritter Gegner, der erst mit Ausrüstung fällt, braucht
Ausrüstung.

## Entscheidung

`packages/gear` ist ein weiteres reines Dart-Package ohne Dependencies. Es
enthält die sechs Ausrüstungsplätze, den Katalog, alle Preise und das
Inventar (`Loadout`).

**Gold wird abgeleitet, nicht gezählt:** verfügbares Gold ist Zufluss aus
Theorie und Gewohnheiten minus der Summe der Preise des Besitzes. Es gibt
keinen gespeicherten Kontostand.

**Verkaufen gibt es nicht.**

Das Package kennt weder `package:habits` noch `package:combat`. Es liefert
einen `GearBonus`; die App addiert ihn in `equippedStatsProvider` auf die
Werte aus den Gewohnheiten.

## Begründung

**Eigenes Package**, aus demselben Grund wie bei den vier davor: Preise und
Boni sind Spielzahlen. Im Package lassen sie sich gegen den Gold-Zufluss
durchrechnen, ohne die App zu starten. `packages/gear/test/catalog_test.dart`
prüft den Inhalt des Ladens genauso, wie `content_test.dart` die Lektionen
prüft — eindeutige Ids, jedes Stück wirkt, jeder Platz hat etwas, teurer ist
auch besser.

**Gold abgeleitet**, weil es die dritte Anwendung derselben Entscheidung
ist: Theorie-XP wird abgeleitet, Habit-XP wird abgeleitet, jetzt auch Gold.
Ein gespeicherter Kontostand wäre eine zweite Wahrheit über dieselbe Sache,
und zwei Wahrheiten laufen irgendwann auseinander. Abgeleitet kann der
Goldstand auch nie negativ werden: Gekauft wird nur, was bezahlbar war.

**Kein Verkauf** ist die Folge davon. Rückkauf bräuchte eine
Verkaufshistorie, um die Ableitung zu erhalten — und damit genau die
Buchführung, die vermieden werden sollte. Der Preis ist tragbar, weil jedes
Stück einen eigenen Platz belegt: Man kauft nichts doppelt, und ein
Fehlkauf auf der ersten Stufe kostet etwa vier Tage.

**Gekauftes wird sofort angelegt**, weil ein gekauftes Stück, das nichts
tut, wie ein Fehler aussieht. Umrüsten kostet nichts; nur der Kauf kostet.

**Energie sitzt auf Ring und Talisman.** Das Konzept warnt ausdrücklich
davor, dass Ausrüstung nur Zahlen erhöht: „Ein Ring, der Energie schneller
füllt, erzeugt eine Entscheidung. +3 Angriff nicht." Energie ist im Kampf
die einzige taktische Ressource — ein Punkt mehr heißt, dass der
Wuchtschlag eine Runde früher bezahlbar ist. Deshalb ist der Ring das
teuerste Stück beider Stufen.

**`blockFor` gibt einen Grund zurück, kein `false`.** Ein ausgegrauter
Knopf ohne Erklärung ist die häufigste Art, jemanden ratlos zurückzulassen.
Der Laden schreibt deshalb hin, wie viel Gold fehlt — und in Tagen, nicht
nur in Zahlen.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Ausrüstung in `packages/habits` | Vermischt zwei Kurven, die getrennt einstellbar bleiben müssen. Der Stat-Deckel ist gewollt; Ausrüstung ist der Weg *darüber hinaus*. |
| Ausrüstung in `lib/` | Preise und Boni sind Spielzahlen. In `lib/` wären sie der Simulation und den Package-Tests entzogen — genau der Fehler, der bei den Gegnerwerten korrigiert wurde (ADR-0009). |
| Goldstand speichern statt ableiten | Zweite Wahrheit. Ein Fehler in einer Buchung wäre dauerhaft und nicht mehr nachvollziehbar. |
| Verkauf mit Teilerstattung | Bräuchte eine Verkaufshistorie, um Gold weiterhin ableiten zu können. Der Aufwand steht in keinem Verhältnis zum Nutzen bei sechs Plätzen. |
| Tränke und Wiederbelebung mit aufnehmen | Beide wirken erst, wenn HP zwischen Kämpfen nicht heilen — also im Dungeon. Ohne ihn wäre ein Trank ein Knopf ohne Situation. Bleibt für den Dungeon-Schritt notiert. |
| Ausrüstung als Drop aus Kämpfen | Das Konzept trennt die Quellen bewusst (Abschnitt 4): Shop ist planbar, Drops sind Varianz. Drops brauchen Drop-Tabellen und gehören zum Dungeon. |

## Konsequenzen

**Leichter:**

- Gold hat einen Zweck. Der Kreis aus Abschnitt 1 des Konzepts ist
  geschlossen: Einnahme aus Alltag und Lernen, Ausgabe im Laden.
- Der Charakter wächst über den Stat-Deckel hinaus, ohne dass die Kurve in
  `habits` angefasst werden muss.
- Der Bergwaechter ist ein erreichbares Ziel statt einer Wand.
- Der Charakterbildschirm kann zeigen, woher jede Zahl kommt — „18 Angriff,
  davon 3 aus Ausrüstung". Genau diese Aufteilung macht die Kernaussage des
  Spiels sichtbar.

**Schwerer:**

- Eine fünfte Kurve, die zu den anderen passen muss. `test/progression_test.dart`
  prüft das jetzt mit: Der Skillbaum allein darf den Laden nicht leer
  kaufen, und ein voller Satz muss in etwa einem Monat tragbar sein.
- Kein Verkauf heißt, dass ein Fehlkauf bleibt. Auf der zweiten Stufe
  (bis 740 Gold) ist das spürbar.
- `GearBonus` wiederholt die vier Charakterwerte, ohne `HabitStat` zu
  kennen. Die Übersetzung steht in `EquippedStats.bonusFor`. Kommt ein
  fünfter Wert dazu, sind es zwei Stellen statt einer — der Preis dafür,
  dass die Packages einander nicht kennen.
- Der Laden ist der erste Bildschirm, auf dem etwas **unwiderruflich**
  passiert. Bisher ließ sich alles zurücknehmen: ein Häkchen, eine Lektion,
  eine Gewohnheit.
