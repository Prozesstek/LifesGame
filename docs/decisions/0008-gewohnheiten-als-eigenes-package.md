# ADR-0008: Gewohnheiten als eigenes Package, Erfahrung abgeleitet statt gezählt

**Datum:** 12.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Nach Kampf, Theorie und Levelkurve fehlte das Stück, um das es im Konzept
eigentlich geht: die Gewohnheiten. Ohne sie war der Kern-Loop offen — der
Angriffswert des Helden stand fest auf 16, und Erfahrung kam allein aus dem
Lesen. Damit war auch die Levelsperre des Skillbaums wirkungslos: Sie sollte
den Nutzer aus der Theorie in den Tracker ziehen (ADR-0007), öffnete sich
aber wieder durchs Lesen.

Drei Fragen standen an:

1. Wohin gehört die Logik — in `lib/`, in ein bestehendes Package, in ein neues?
2. Wie werden Erfahrung und Gold festgehalten?
3. Woher weiß eine Gewohnheit, welche Lektion sie freigeschaltet hat?

## Entscheidung

`packages/habits` ist ein weiteres reines Dart-Package ohne Dependencies. Es
enthält den Vorlagen-Katalog, die Streak-Regeln, alle Belohnungszahlen und
die Umrechnung von Häkchen in Kampfwerte.

Erfahrung und Gold werden aus der Häkchen-Historie **abgeleitet**, nicht
mitgezählt. `packages/habits` und `packages/theory` kennen einander nicht;
sie treffen sich über den Wortlaut der Gewohnheit, geprüft von
`test/habits_theory_test.dart`.

## Begründung

**Eigenes Package**, aus demselben Grund wie bei Kampf und Levelkurve: Die
Streak-Kurve und die Stat-Kurve sind Spielzahlen, und Spielzahlen wollen
durchgerechnet werden, nicht angenommen. `example/curve_sim.dart` spielt
90 Tage in drei Verhaltensmustern durch, ohne dass Flutter startet — genau
so, wie `balance_sim.dart` es für den Kampf tut. Ein leerer
`dependencies`-Block macht das dauerhaft: Wer hier Flutter importieren will,
scheitert am Package, nicht an einer Vereinbarung.

**Abgeleitet statt gezählt** ist die Entscheidung, die am weitesten trägt.
Ein versehentliches Häkchen muss sich zurücknehmen lassen — das ist bei
einem Tracker keine Ausnahme, sondern Alltag. Mit einem laufenden Zähler
hieße das, jede Rücknahme auch rückwärts zu buchen, inklusive des
Multiplikators, der an diesem Tag galt. Zwei Wege, die auseinanderlaufen
können. Wird stattdessen jedes Mal aus der Historie gerechnet, kann es keine
Abweichung geben: `uncheck` entfernt einen Tag, und die Erfahrung ist weg.
Dieselbe Entscheidung hatte `TheoryProgress` schon getroffen.

**Verbindung über den Namen** statt über eine Abhängigkeit: Eine Lektion
sagt `unlocksHabit: 'Zwei Minuten lesen'`, der Katalog kennt eine Vorlage
dieses Namens. Keines der beiden Packages muss das andere importieren. Der
Preis ist ein Text, der an zwei Stellen stimmen muss — und genau deshalb
prüft ein Test beide Richtungen: jede Lektion findet ihre Vorlage, jede
Vorlage genau eine Lektion.

Drei Zahlen sind Produktentscheidungen und stehen deshalb ausdrücklich in
`rewards.dart`:

- **Streak-Deckel x2** — das Konzept empfiehlt ihn (Abschnitt 3.7). Bei x3
  wird der Verlust einer langen Kette so schmerzhaft, dass Nutzer aufgeben
  statt neu anzufangen. Damit ist der offene Punkt 1 aus dem Konzept
  entschieden.
- **Gold ohne Multiplikator** — der Streak stärkt den Charakter, nicht die
  Geldbörse. Sonst wird eine lange Kette zur Abkürzung durch den Shop.
- **Höchstens fünf Gewohnheiten gleichzeitig** — ohne Grenze hakt man alle
  elf Vorlagen an und keine davon ab. Die Grenze hält außerdem die Erfahrung
  pro Tag berechenbar, worauf die Levelkurve angewiesen ist.

Die Kette stirbt erst, wenn der Tag vorbei ist, nicht beim Aufwachen: Wer
heute noch nicht abgehakt hat, behält die Streak von gestern. Das Konzept
verlangt, dass Verpassen keine Strafe ist — sie morgens früh zu löschen wäre
eine.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Habits-Logik in `lib/` als Riverpod-Notifier | Spielzahlen im Widget-Layer, gegen die Schichtregel; die Streak-Kurve wäre nur mit laufender App prüfbar |
| In `packages/theory` mit einbauen | Macht die Theorie zum Besitzer der Gewohnheiten; die Abhängigkeit läuft in die falsche Richtung — Vorlagen sind kein Lernstoff |
| `packages/habits` hängt von `packages/theory` ab | Hätte die Namensdopplung gespart, aber die Gewohnheiten an die Inhalte gekettet. Ein Zweig lässt sich dann nicht mehr umschreiben, ohne den Tracker anzufassen |
| Erfahrung beim Abhaken addieren und speichern | Rücknahme eines Häkchens erzwingt eine zweite, rückwärts laufende Rechnung; zwei Wege, die auseinanderlaufen können |
| `DateTime` direkt als Tagesschlüssel | Zwei Häkchen am selben Tag hätten verschiedene Werte, und lokale Datumsarithmetik verschluckt bei Zeitumstellung einen Tag. Deshalb ein eigener `Day`-Typ, der intern in UTC rechnet |
| Jede Gewohnheit zahlt anteilig auf mehrere Werte ein | Beim Abhaken wäre nicht mehr zu sehen, wofür man es tut. Eine Vorlage, ein Wert |

## Konsequenzen

**Leichter:** Der Kern-Loop des Konzepts ist geschlossen — Abhaken erhöht
Werte, Werte entscheiden Kämpfe. Die Levelsperre des Skillbaums wirkt jetzt
so, wie ADR-0007 sie gemeint hat. Und die Balance ist simulierbar statt
geraten: `example/curve_sim.dart` beantwortet in einer halben Sekunde, was
90 Tage Nutzung ergeben.

**Schwerer:** Ein fünftes Package, und eine dritte Naht, die niemand allein
prüfen kann. `test/progression_test.dart` bewacht sie jetzt mit: Häkchen →
Erfahrung → Level → offene Zweige. Der Test hält das Tempo in einem Korridor
(drei bis einundzwanzig Tage bis zum letzten Zweig), damit ein Dreh an einer
Zahl nicht unbemerkt das Spiel umbaut.

**Unangenehm:** Die Simulation zeigt, dass alle vier Kampfwerte nach etwa
einem Monat am Deckel stehen. Danach bringen Gewohnheiten nur noch Erfahrung
und Gold, keine Stärke mehr. Das ist bewusst so — solange die Kampfbalance
ungeklärt ist (`docs/context/state.md`), wäre ein weiter offener Wertebereich
gefährlicher als ein Deckel. Es heißt aber, dass der Langzeit-Anreiz an
Ausrüstung und Dungeon hängt, und beide gibt es noch nicht.
