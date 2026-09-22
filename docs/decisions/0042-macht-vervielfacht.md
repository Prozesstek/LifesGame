# ADR-0042: Macht vervielfacht — Level und Seltenheit multiplizieren, alle Kampfzahlen mal zehn

**Datum:** 22.09.2026
**Status:** Aktiv — ergänzt ADR-0008 (Werte aus Gewohnheiten, additiv und gedeckelt)
**Entschieden von:** Prozesstek

## Kontext

Frederik: „Generell will ich die Spanne nach oben vergrössern … so wie
Diablo. Dadurch fühlt sich jeder Fortschritt gewaltiger an, als wenn
Schaden nur um 1 steigt."

Das ist die **Potenz-Kurve**, die seit dem 20.09. in `state.md` als
offene Frage stand. Der Befund von damals: Der Angriff wuchs über ein
ganzes Spielerleben von 13 auf etwa 30 — die Gewohnheiten gedeckelt
(ADR-0008), die Ausrüstung als feste Boni. Ein Level tat im Kampf gar
nichts. Der Prototyp „mit Potenz" hatte gezeigt, dass sich die Grube
erst mit einem vervielfachenden Faktor mächtig anfühlt; das Feld
`ActionStats.damageMultiplier` stand dafür bereit, mit 1 belegt.

Vorgeschlagen waren drei Schritte: **B** breitere Streuung und kritische
Treffer (am selben Tag gebaut), **A** grössere Zahlen, **C**
multiplizieren statt addieren. Dieser ADR ist A und C.

## Entscheidung

- **C:** Jedes Level vervielfacht Angriff, Leben und Verteidigung mit
  1,04 (`PowerCurve`). Die Seltenheit der **Waffe** vervielfacht den
  Angriff, die der **Rüstung** das Leben — gewöhnlich ×1 bis legendär
  ×2,2 (`GearRarity.powerFactor`). Die Stufen der Grube wachsen
  entsprechend mit, von ×1 auf Stufe 1 bis ×5 auf Stufe 30
  (`PitStage.powerFactor`).
- **A:** Alle Kampfzahlen stehen mal zehn (`ActionBalance.powerScale`),
  für Held und Gegner gleich.
- Die Gewohnheiten und die Boni der Ausrüstung **bleiben additiv**. Sie
  sind die Grundlage, auf die vervielfacht wird.

Zusammengesetzt wird an einer Stelle, `PitPower.hero`; die App fragt
`heroPowerProvider`, und zwar die Grube, der Prototyp und der
Charakterbildschirm.

## Begründung

**Ein Häkchen behält seinen Wert.** Würden die Gewohnheiten selbst
vervielfachen, hinge der Wert eines Häkchens davon ab, wann es gesetzt
wird. So bleibt ein Punkt Stärke ein Punkt Stärke — und das Level, das
die Häkchen über die Erfahrung heben, macht ihn grösser. Die Kette
Gewohnheit → Erfahrung → Level → Macht wird damit enger, nicht lockerer.

**Nur Waffe und Rüstung.** Sechs Faktoren übereinander wüchsen schneller,
als eine Stufe nachkommen kann, und machten jeden Platz zu einer Frage
der Seltenheit statt der Wirkung. Zwei Plätze tragen die Macht, vier die
Eigenschaften.

**Die Gegner wachsen im selben Takt.** Ohne `stagePowerLast` wäre ab der
Mitte alles geschenkt. Mit ×5 auf Stufe 30 bleibt die Kurve der Siege
in `pit_sim` in derselben Form wie vorher — gemessen, siehe unten.

**Mal zehn, weil erst dann die Spanne zu sehen ist.** Mit Angriff 13
ist die Streuung von 60 bis 140 % die Frage „8 oder 18"; mit 130 ist es
eine Zahl, die man liest. Und ein Level mehr ist +5 statt +0,5.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Nur die Anzeige mal zehn | Ändert kein Verhältnis — Fortschritt fühlte sich weiter wie +1 an, nur mit einer Null dahinter |
| Den Deckel aus ADR-0008 heben | Dann wüchsen Werte ohne Ende aus Häkchen, und der Wert eines Häkchens hinge am Zeitpunkt |
| Jede Seltenheit auf jedem Platz vervielfacht | Sechs Faktoren übereinander — keine Stufe käme nach |
| Level vervielfacht nur den Schaden | Der Held würde zur Glaskanone; Gegner, die mitwachsen, fielen ihn in zwei Schlägen |

## Konsequenzen

**Gemessen** (`dart run tool/pit_sim.dart`):

| | Angriff | Leben | Faktor |
|---|---|---|---|
| Tag 0 | 141 | 1.731 | ×1,08 |
| Tag 30 | 316 | 3.597 | ×1,67 |
| Tag 60 + Ausrüstung | 1.654 | 18.449 | ×5,0 |

Tag 60 schlägt fast zwölfmal so hart wie Tag 0 (vorher gut doppelt). Die
Siegquoten je Stufe liegen dabei, wo sie vorher lagen: Tag 0 schafft
Stufe 1, Tag 30 mit Fähigkeiten etwa Stufe 11, voll ausgerüstet Stufe 30
zu rund 60 %.

- **Das Level zählt jetzt im Kampf.** Die Simulation rechnet es nur aus
  Gewohnheiten und Handbuch — Baum, Reihe und Errungenschaften brächten
  mehr. Ihre Quoten sind weiter eine untere Schranke.
- **Die Stufen sind nicht nachgestellt**, nur mitgewachsen. `stagePowerLast`
  ist die eine Zahl dafür.
- **Jede feste Zahl im Kampf ist jetzt zehnmal zu klein.** Es gibt heute
  keine — Heilung ist ein Anteil, Dauerschaden ein Vielfaches des
  Angriffs, `minDamage` ist 1. Wer eine feste Zahl einführt, rechnet mit
  `powerScale`.
- Der Charakterbildschirm zeigt über den Werten eine Karte
  „Angriff · Leben · Abwehr" mit den Faktoren dahinter. Nicht am Gerät
  angesehen.
- Im Laden steht noch nicht, dass eine Waffe oder Rüstung ihre Seltenheit
  vervielfacht. Wer es wissen will, sieht es heute nur am Charakter.
