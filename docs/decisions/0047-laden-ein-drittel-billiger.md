# ADR-0047: Der Laden wird ein Drittel billiger

**Datum:** 24.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Im 30-Tage-Test (Tag 4) meldet Frederik: „Der Laden ist auf jeden Fall zu
teuer, und gerade passiert am Tag nicht viel ausser alle Dailies machen,
weil ich weder ein Level aufsteige noch neue Items kaufen kann.“

Die Preise wurden auf **25 Gold am Tag** ausgelegt, das Gold aus fünf
Gewohnheiten (ADR-0011, ADR-0029). Seitdem sind Truhe (ADR-0044),
Dailies (ADR-0040) und Rückfrage (ADR-0045) dazugekommen, und
`tool/runway_sim.dart` rechnet für einen fleissigen Spieler rund 80 Gold
am Tag. Trotzdem lag das nächste Stück, das man will, weit weg: ein
Ungewöhnliches 5 bis 10 Tage, ein Episches 11 bis 19.

## Entscheidung

Jeder Preis sinkt auf **zwei Drittel**, gerundet auf zehn
(`GearPrices`). Die Reihenfolge innerhalb jedes Platzes bleibt, die
Sperren von Episch und Legendär (ADR-0034) bleiben unverändert.

## Begründung

Der Laden ist der Hebel, der jeden Tag wirkt, ohne etwas anderes zu
verschieben. Mehr Aufstiege wären der andere Weg; jeder Aufstieg bringt
aber einen Theoriepunkt, und der Baum wäre dann schon um Tag 20 leer
statt um Tag 33.

Ein Drittel statt der Hälfte: Frederik wollte vorsichtig anfangen. Bei
rund 80 Gold am Tag kommt damit etwa alle 1 bis 3 Tage ein
Gewöhnliches, alle 3 bis 7 ein Ungewöhnliches, und ein Episches
(600 bis 1.000) liegt im Test erreichbar.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Alles halbieren | stärker als nötig für den ersten Schritt; nachlegen geht immer |
| Nur Selten, Episch, Legendär billiger | hilft beim Ziel, nicht beim Alltag, und der Alltag war die Klage |
| Levelkurve flacher | leert den Baum zu früh (Theoriepunkte) |
| Mehr Gold ausschütten | dieselbe Wirkung, aber an vielen Stellen statt an einer |

## Konsequenzen

- **Wer schon gekauft hat, bekommt ein Drittel zurück.** Gold wird aus
  dem Besitz gerechnet (ADR-0011), ein billiger gewordenes Stück zählt
  also rückwirkend billiger. Das ist gewollt und betrifft beide
  Testspieler gleich.
- Die Untergrenze in `catalog_test.dart` („ein voller Satz zu billig,
  keine Entscheidung“) ist von 24 auf 14 Tage Gewohnheiten gesenkt.
- Offen bleibt die zweite Hälfte der Klage: Auch Aufstiege werden
  seltener. Das löst der Laden nicht.
