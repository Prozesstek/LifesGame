# ADR-0017: Zwanzig Fähigkeiten, und die Waffe ist der Motor

**Datum:** 22.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

[ADR-0013](0013-charakter-als-kommandozentrale.md) legte vier
Fähigkeitsslots fest und zwanzig Fähigkeiten aus drei Quellen — ließ aber
ausdrücklich offen: „Welche zwanzig Fähigkeiten es sind, was sie kosten und
was sie tun." [ADR-0016](0016-faehigkeitsslots-vor-den-faehigkeiten.md) baute
die Plätze und schrieb denselben Punkt erneut als offen fest.

Damit stand seit zwei Entscheidungen ein Bildschirm da, auf dem drei Plätze
„leer" sagen. Der Satz darunter erklärt das, aber er hat eine Frist: Bleibt er
lange stehen, wird aus „kommt noch" ein sichtbarer Rest.

Beim Ausdenken traten zwei Zwänge zutage, die die Liste bestimmt haben und die
vorher niemand ausgesprochen hatte.

**Der erste ist hart:** Auf Level 1 ist nur Slot 1 offen, und der gehört der
Waffe (ADR-0016). Eine Waffenfähigkeit, die Energie *kostet*, wäre für einen
frischen Charakter unbezahlbar — er stünde mit einer einzigen Fähigkeit da, die
er nie einsetzen kann.

**Der zweite ist eine Grenze:** Die Engine kennt heute vier Effekte — Gift,
Verteidigung runter, sich heilen, sich schützen. Zwanzig Fähigkeiten allein
daraus wären zwanzig Abwandlungen von vier Ideen.

## Entscheidung

### 1. Die Aufteilung: 5 Waffen, 4 Streak-Marken, 11 Theorieknoten

### 2. Waffenfähigkeiten erzeugen ausnahmslos Energie

Alle fünf sind Energie-Erzeuger mit eigenem Charakter. Keine kostet Energie.

| Waffe | Fähigkeit | Power | Energie | Wirkung |
|---|---|---|---|---|
| Kurzbogen | Bogenschuss | 1,0 | +3 | — |
| Schwert | Hieb | 1,3 | +2 | — |
| Dolch | Doppelstich | 0,5 | +4 | — |
| Streitkolben | Wuchtstoß | 0,9 | +3 | Verteidigung runter |
| Stab | Sammelschlag | 0,6 | +5 | — |

### 3. Streak-Marken geben Widerstandsfähigkeit

| Marke | Fähigkeit | Power | Energie | Wirkung |
|---|---|---|---|---|
| 7 Tage | Zweiter Wind | 0 | −4 | heilt |
| 14 Tage | Standhalten | 0 | −3 | Schild + eigene Verteidigung hoch |
| 30 Tage | Durchbeißen | 1,4 | −3 | Schaden, heilt anteilig davon |
| 60 Tage | Unbeirrt | 0 | −5 | eigener Angriff hoch, entfernt eigene Schwächungen |

### 4. Theoriefähigkeiten klingen nach ihrem Knoten

| Knoten | Fähigkeit | Power | Energie | Wirkung |
|---|---|---|---|---|
| Sport | Kraftschlag | 2,2 | −6 | — |
| Ernährung | Zehrung | 0,4 | −3 | Gift |
| Schlaf | Sammeln | 0 | −4 | heilt + Schild |
| Substanzen | Rausch | 1,9 | −4 | **eigene** Verteidigung sinkt |
| Erholung | Atemzug | 0 | +4 | kleine Heilung |
| Haltung | Fester Stand | 0 | −2 | eigene Verteidigung hoch, lange |
| Aufmerksamkeit | Fokus | 0 | +5 | — |
| Psychologie | Blöße finden | 0,6 | −3 | Verteidigung **und** Angriff des Gegners runter |
| Lernen | Muster erkennen | 1,0 | −2 | eigener Angriff hoch, 2 Runden |
| Entscheidungen | Richtiger Moment | 2,6 | −8 | — |
| Wissenschaft | Reaktion | 1,2 | −4 | zündet vorhandenes Gift sofort |

### 5. Die vier heutigen Moves gehen in der Liste auf

Bogenschuss, Kraftschlag, Sammeln und Zehrung sind die bestehenden Moves. Das
Spiel bleibt während des Umbaus spielbar.

**Mit einer Änderung:** Die heutige „Giftklinge" macht Gift *und* Verteidigung
runter. Das wird getrennt — Ernährung gibt Gift, Psychologie gibt die
Schwächung.

### 6. Gebaut wird in zwei Stufen

**Zuerst die neun Fähigkeiten, die die Engine schon kann** — die fünf Waffen
plus Kraftschlag, Zehrung, Sammeln, Atemzug. Ohne eine Zeile Änderung in
`packages/combat`.

**Danach die elf übrigen**, zusammen mit der Engine-Arbeit.

### 7. Kein Kontern, kein Ausweichen, keine Initiative

## Begründung

**Warum die Waffe der Energiemotor ist.** Es ist keine Geschmacksfrage, sondern
folgt aus ADR-0016: Slot 1 steht ab Level 1 allein. Was darin liegt, muss ohne
Vorbedingung funktionieren, sonst ist der erste Kampf eines neuen Spielers eine
Sackgasse.

Der Nebeneffekt ist der eigentliche Gewinn: Die Waffe bestimmt damit den
**Rhythmus** des ganzen Builds. Wer den Stab trägt (+5), kann sich „Richtiger
Moment" (−8) leisten; wer das Schwert trägt (+2), kommt selten dorthin und
schlägt dafür jede Runde härter zu. Genau das forderte `konzept.md` 3.1 und
ADR-0013 zitierte es: „Ausrüstung sollte Ressourcen beeinflussen, nicht nur
Zahlen erhöhen." Eine Waffe ist damit kein Zahlenaufschlag mehr — und sie ist
es, ohne dass wir dafür eine Mechanik erfinden mussten.

**Warum die Theoriefähigkeit nach ihrem Knoten klingt.** Das ist der Kern der
App, buchstäblich gemacht. `konzept.md` und ADR-0013 sagen: „Jeder formt seinen
Charakter durch seinen persönlichen Stil", und „wo eine Klasse sichtbar wird,
wird sie abgeleitet, nie gewählt." Wenn der Knoten *Substanzen* eine Fähigkeit
gibt, die kurzfristig stark macht und verwundbar zurücklässt, dann ist das
Thema eine Mechanik geworden statt eines Vortrags. Wer tief in Körper steckt,
kämpft nachweislich anders als wer in Geist steckt — und das steht dann nicht
im Konzept, sondern im Kampflog.

**Warum die Zahlen so und nicht anders.** Sie sind an den vier bestehenden
Moves ausgerichtet: Energie 8 bis 12, Basisangriff +3, Wuchtschlag −6. Der
Rhythmus „zweimal aufbauen, einmal zuschlagen" bleibt der Takt; „Richtiger
Moment" (−8) ist bewusst darüber und braucht drei Runden Vorlauf.

**Warum die Giftklinge geteilt wird.** Ein Move, der Gift *und* Schwächung
macht, nimmt zwei der elf Theorieplätze ihre Aufgabe weg. Getrennt entsteht
außerdem die erste echte Kombination im Spiel: erst *Zehrung*, dann *Reaktion*
zündet das Gift. Das ist ein Grund, zwei bestimmte Knoten zusammen zu gehen —
und damit eine Entscheidung im Baum, die vorher keine war.

**Warum erst die neun kostenlosen.** Das eigentliche Risiko ist nicht die
Liste, sondern dass heute nichts eine Fähigkeit *aufnehmen* kann: keine
Auswahl, kein Speichern, kein Weg nach `_freshFight()`. Diese Verkabelung ist
unabhängig davon, welche zwanzig es sind. Steht sie, sind die übrigen elf
Einträge in einem Katalog. Andersherum wäre teuer: erst die Engine umbauen und
danach feststellen, dass drei Slots zu wenig oder zu viel sind.

**Warum kein Kontern.** Frederiks Design-Notiz (`Kampfsystem.docx`) ist laut
ADR-0015 ausdrücklich **nicht** entschieden. Eine Fähigkeit „weicht dem
nächsten Angriff aus" hätte diese Entscheidung durch die Hintertür getroffen —
danach wäre Ausweichen im Spiel, ohne dass jemand darüber entschieden hat.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Waffen bringen beliebige Fähigkeiten mit, auch teure | Ein frischer Charakter hätte auf Level 1 eine Fähigkeit, die er nicht bezahlen kann |
| Der Energie-Erzeuger ist eine feste fünfte Fähigkeit außerhalb der Slots | Nimmt der Waffe ihre Rolle zurück und macht aus vier Slots faktisch fünf |
| Zwanzig Fähigkeiten allein aus den vier vorhandenen Effekten | Zwanzig Abwandlungen von vier Ideen; die Slots wären Behälter statt Entscheidungen |
| Fähigkeiten thematisch frei von ihrem Knoten | Verschenkt genau die Aussage, für die es den Theoriebaum gibt |
| Alle zwanzig auf einmal bauen | Bindet die Engine-Arbeit an eine Auswahl-Mechanik, die sich noch nicht bewährt hat |
| Ausweichen/Kontern als Fähigkeit einbauen | Nimmt eine ausdrücklich offene Entscheidung vorweg (ADR-0015) |
| Giftklinge unverändert lassen | Zwei der elf Theorieplätze hätten keine eigene Aufgabe mehr |

## Konsequenzen

**Leichter:** Die Slots aus ADR-0016 bekommen Inhalt, und der Satz „die
Fähigkeiten kommen noch" kann weg. Die Waffe wird zum Spielstil, ohne dass
dafür eine neue Mechanik nötig war.

**Schwerer — die Engine-Rechnung, ehrlich:** Sieben der zwanzig brauchen etwas,
das `packages/combat` heute nicht kann.

Vier davon sind dieselbe Bauform wie das vorhandene `DefenseDown` — ein Faktor
auf einen Wert für N Runden. Sie werden **ein** verallgemeinerter
`StatModifier(wert, faktor, runden)`, in dem `DefenseDown` aufgeht.

Drei sind wirklich neu: anteilige Heilung am Schaden (*Durchbeißen*), eigene
Schwächungen entfernen (*Unbeirrt*), Gift vorzeitig zünden (*Reaktion*).

Summe: **ein verallgemeinerter Statuseffekt und drei neue Mechaniken.**

**Der Laden braucht drei Waffen mehr.** Heute gibt es zwei. Ihre Preise müssen
gegen den Gold-Zufluss passen (ADR-0011) — und eine Waffe kauft man künftig
nicht mehr für Angriff, sondern für ihren Rhythmus. Das ist eine Dimension
mehr in der Preisrechnung.

**Balance wird eine Stichprobe.** ADR-0013 hat das vorhergesagt: Drei aus
fünfzehn plus Waffe sind über zweitausend Kombinationen; `tool/balance_sim.dart`
prüft heute einen Fall. **Keine Zahl in diesem Dokument ist simuliert.** Sie
sind am bestehenden Moveset ausgerichtet, mehr nicht.

**Offen:**

- **Der Aufwertungspfad.** ADR-0013 fordert Fähigkeitspunkte, die aufwerten und
  gegen Gold umverteilbar sind. Vorschlag als Ausgangspunkt, nicht entschieden:
  drei Stufen je Fähigkeit, ein Punkt gibt +15 % Power oder +1 Runde Dauer.
- **Ob fünfzehn wählbare Fähigkeiten für drei Slots zu viele sind.** Erst wenn
  das Auswählen läuft, lässt sich das beurteilen.
- **Die Punkteökonomie** aus [ADR-0012](0012-theoriebaum-ueber-punkte.md) ist
  weiterhin Voraussetzung: Ohne Fähigkeitspunkte gibt es nichts aufzuwerten.
