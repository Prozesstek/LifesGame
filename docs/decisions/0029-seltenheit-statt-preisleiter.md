# ADR-0029: Seltenheit tritt neben den Preis — „teurer ist besser" gilt nur noch innerhalb einer Stufe

**Datum:** 07.09.2026
**Status:** Aktiv
**Entschieden von:** AktivesBrett

## Kontext

Der Laden soll wachsen: fünf Stücke je Platz statt der heutigen ein bis
zwei, Waffen mit eigener Fähigkeit, Sets mit Boni. Das ist der Inhalt, den
Ziel 3 verlangt und den ein 30-Tage-Lauf braucht — mit neun Stücken ist
nach zwei Wochen alles gesehen.

**Eine bestehende Regel steht dem im Weg.** ADR-0011 hat den Laden mit
einer harten Zusage abgesichert, geprüft in `catalog_test.dart`:

> Auf demselben Platz heißt teurer auch besser.

Die Regel ist gut und hat einen Grund: Ohne sie kann ein Laden unbemerkt
beliebig werden, und eine Kaufentscheidung wird zur Falle. Sie setzt aber
voraus, dass **alle** Stücke eines Platzes auf einer Leiter liegen.

Genau das sollen sie nicht mehr. Drei der geplanten Änderungen brechen die
Leiter:

| Änderung | Warum die Leiter bricht |
|---|---|
| Fünf Waffen als *Sidegrades* (Ziel 3) | Gleicher Preis, verschiedener Rhythmus — keine ist „besser" |
| Set-Teile | Ein Stück kann allein schwächer sein und im Set stärker |
| Fähigkeit am Stück | Ihr Wert steht in keiner der vier Statuszahlen |

## Entscheidung

**Jedes Ausrüstungsstück bekommt eine Seltenheit** — `GearRarity` mit drei
Stufen: Gewöhnlich, Ungewöhnlich, Selten.

**Die Regel aus ADR-0011 gilt weiter, aber nur innerhalb einer Stufe.**
Zwei gewöhnliche Stücke auf demselben Platz: teurer heißt besser. Ein
seltenes Stück darf gegenüber einem gewöhnlichen in reinen Zahlen
schwächer sein.

## Begründung

**Die Regel bleibt dort, wo sie schützt.** Zwei Stücke derselben Stufe auf
demselben Platz sind vergleichbar — dort wäre ein teureres, schwächeres
Stück weiterhin eine Falle, und der Test fängt sie weiterhin. Zwischen den
Stufen ist der Vergleich dagegen gar nicht mehr eindimensional: Was ein
Set-Bonus oder eine Fähigkeit wert ist, lässt sich nicht in Angriff und
Leben ausdrücken.

**Drei Stufen, nicht fünf.** `package:abilities` hat fünf, weil dort etwas
zu *erreichen* ist — Sternenfall kommt über sechzig Tage Kette. Im Laden
gibt es nichts zu erreichen, nur zu kaufen. Fünf Stufen wären eine
Feinheit ohne Unterschied.

**Ein eigener Typ, kein Import.** `package:gear` kennt `package:abilities`
nicht und soll es nicht kennen — dieselbe Überlegung wie bei `GearBonus`,
das die vier Charakterwerte bewusst dupliziert statt sie aus
`package:habits` zu holen. Sonst hinge die Preisliste an der Levelkurve
und umgekehrt.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Regel ersatzlos streichen | Der Laden kann dann unbemerkt beliebig werden. Genau davor schützt der Test, und der Schutz ist innerhalb einer Stufe weiterhin richtig |
| „Gesamtwert" statt Bonus prüfen — Statuspunkte plus ein angerechneter Wert für Fähigkeit und Set | Verlangt, eine Fähigkeit in Punkten zu beziffern. Diese Zahl könnte niemand belegen, und ein Test, der auf einer erfundenen Zahl steht, prüft nichts |
| Seltenheit aus `package:abilities` importieren | Koppelt zwei Packages, die heute nichts voneinander wissen. Und die beiden Begriffe bedeuten Verschiedenes: Dort hängt Seltenheit an der Quelle, hier am Preis und am Set |
| Fünf Stufen wie bei den Fähigkeiten | Episch und Legendär sind der Lohn für tiefen Fortschritt. Ein Laden verkauft nichts Legendäres |

## Konsequenzen

**Der Laden kann Sidegrades tragen.** Fünf Waffen zum ähnlichen Preis mit
je eigener Fähigkeit sind ab jetzt möglich, ohne dass ein Test dagegen
steht — das war die Voraussetzung für Ziel 3.

**Die Seltenheit ist im Bild sichtbar**, mit den gewohnten Farben aus
Rollenspielen: grau, grün, blau. Niemand muss sie lernen.

**Unangenehm:** Zwischen den Stufen gibt es keine automatische Prüfung
mehr. Ob ein seltenes Stück seinen Preis wert ist, entscheidet ab jetzt
ein Mensch — und ein Fehler dort fällt erst beim Spielen auf. Der Preis
für Sidegrades ist, dass „besser" keine Zahl mehr ist.

**Noch offen:** Ob die Seltenheit auch etwas über die *Verfügbarkeit*
sagen soll — heute ist jedes Stück im Laden jederzeit kaufbar, die
Seltenheit ist nur ein Etikett auf Preis und Wirkung. Sobald der Dungeon
Beute bringt (Ziel 6), bekommt sie dort ihre zweite Bedeutung.
