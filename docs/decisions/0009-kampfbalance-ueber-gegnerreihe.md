# ADR-0009: Balance über eine Gegnerreihe statt über einen Gegner

**Datum:** 17.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Die Balance-Simulation hatte einen Befund geliefert, der wie ein
Einstellungsfehler aussah (`docs/context/state.md`, Stand 12.08.):

| Angriff des Helden | Siegquote |
|---|---|
| 14 | 6,7 % |
| 16 | 52,8 % |
| 18 | 97,4 % |

**Das umkämpfte Band war zwei Angriffspunkte breit.** Dazu kam, dass
perfektes Timing bei gleichen Werten von 56 % auf 100 % Siegquote hob — die
+50 % aus dem Konzept entschieden den Kampf allein, statt ein Bonus am Rand
zu sein.

Die damalige Vermutung lautete: Die Kämpfe sind zu kurz (etwa sieben
Treffer), über so wenige Runden schlägt jeder Multiplikator voll durch.
Vorgeschlagen war, die HP zu erhöhen, damit sich Multiplikatoren dämpfen.

**Diese Vermutung war falsch, und zwar in beide Richtungen.**

Ein Kampf mit beidseitig festen Werten ist ein Rennen. Wer schneller
Schaden macht, gewinnt; der Zufall (±5 % Streuung) verschiebt das Ergebnis
nur am Rand. Längere Kämpfe mitteln den Zufall stärker aus und machen den
Ausgang damit **berechenbarer**, nicht offener — das Band wird schmaler,
nicht breiter. Und ein pauschaler Schadensmultiplikator wie der Timed Hit
wirkt in einem Rennen über jede Länge gleich: 20 % mehr Schaden sind 20 %
weniger Zeit, egal ob der Kampf fünf oder fünfzig Runden dauert.

Zwei weitere Dinge kamen beim Nachmessen ans Licht:

1. **Die Simulation maß die falsche Größe.** Sie variierte den Angriff und
   hielt die übrigen Werte fest. Das Spiel bewegt nie einen Wert allein —
   Gewohnheiten heben Angriff, HP, Verteidigung und Energie gemeinsam.
2. **Heilung konnte Kämpfe unendlich machen.** Sie war als Anteil der
   maximalen HP definiert (25 %), Schaden dagegen als Vielfaches des
   Angriffswerts. Sobald die HP-Pools wuchsen, heilte sich jede Seite
   schneller als die andere zuschlagen konnte. Sichtbar wurde das als
   Unsinn: Siegquoten, die *sanken*, wenn der Spieler stärker wurde.

## Entscheidung

Vier Änderungen, drei davon in `balance.dart`:

1. **Es gibt eine Gegnerreihe statt eines Gegners** —
   `packages/combat/lib/src/enemy.dart` mit `Wegelagerer`, `Soeldner` und
   `Bergwaechter`. Jeder ist so gesetzt, dass er an einem bestimmten Punkt
   des Gewohnheits-Pfads knapp wird. Die Gegnerwerte standen bis dahin im
   Controller und waren damit der Simulation nicht zugänglich.
2. **Heilung und Schild hängen am Angriffswert**, nicht mehr an den
   maximalen HP (`healFactorOfAttack`, `shieldFactorOfAttack`). Zusätzlich
   heilt die Gegner-Policy nur noch, wenn kein Schild mehr steht.
3. **Der Timed-Hit-Deckel sinkt von +50 % auf +20 %.**
4. **`defenseSoftening` sinkt von 100 auf 45**, und der HP-Pool in
   `packages/habits` steigt von 100–140 auf 160–224.

Die maßgebliche Simulation ist ab jetzt `tool/balance_sim.dart` im
Wurzelverzeichnis — die einzige Stelle, die `package:combat` und
`package:habits` zugleich sieht und deshalb mit dem echten Werte-Pfad
rechnen kann.

## Begründung

**Die Gegnerreihe ist die eigentliche Entscheidung.** Ein breites Band an
spannenden Kämpfen lässt sich nicht in einen Gegner einstellen — es folgt
aus der Sache, dass ein Rennen mit festen Werten scharf kippt. Es entsteht
nur aus mehreren Gegnern, von denen zu jedem Zeitpunkt einer knapp ist. Das
Ergebnis ist eine Diagonale statt einer Schwelle:

| Gegner | Tag 0 | Tag 7 | Tag 14 | Tag 21 | Tag 30 | Tag 60 |
|---|---|---|---|---|---|---|
| Wegelagerer | 62 % | 100 % | 100 % | 100 % | 100 % | 100 % |
| Soeldner | 0 % | 0 % | 4 % | 100 % | 100 % | 100 % |
| Bergwaechter | 0 % | 0 % | 0 % | 0 % | 36 % | 100 % |

Der erste Gegner ist **ab Tag eins knapp schlagbar**. Vorher stand ein
frischer Charakter bei 0 % — er konnte nicht verlieren lernen, er konnte
nur verlieren.

**Der gesenkte Timed-Hit-Deckel** bleibt trotzdem richtig, aber aus einem
anderen Grund als gedacht. Er verkleinert nicht den Effekt im knappen
Kampf — dort entscheidet jeder Multiplikator — sondern die *Breite* des
Bereichs, in dem Timing überhaupt kippen kann. Die Simulation zeigt genau
das: Die Spannweite zwischen keinem und perfektem Timing ist am
Schwellen-Gegner groß und daneben null. Das ist die gewünschte Aussage:
**Gewohnheiten entscheiden, ob ein Kampf knapp wird; Timing entscheidet den
knappen Kampf.**

**Heilung am Angriffswert** koppelt Heilen und Schlagen an dieselbe
Einheit. Das Verhältnis bleibt damit erhalten, egal wie groß die HP-Pools
später werden — eine Eigenschaft, die spätestens der Dungeon-Boss braucht.
Gift war schon immer so gebaut (`poisonDamageFactor`); die Heilung war die
Ausnahme.

**`defenseSoftening` auf 45** macht Disziplin zu einer zweiten Achse: Der
Sprung von 8 auf 14 Verteidigung senkte den erlittenen Schaden vorher um
5 %, jetzt um 11 %. Noch kleinere Werte wurden probiert und verworfen — bei
20 sinkt der Schaden so weit, dass Heilung ihn überholt.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| HP stark erhöhen, damit lange Kämpfe Multiplikatoren dämpfen (der alte Vorschlag) | Beruht auf einem Denkfehler. Längere Kämpfe mitteln den Zufall aus und machen den Ausgang berechenbarer — das Band wird schmaler. Der Multiplikator wirkt über jede Länge gleich. |
| Einen einzelnen Gegner weiter feinjustieren | Die Schärfe des Umschlags liegt in der Sache, nicht in den Zahlen. Jede Einstellung verschiebt die Schwelle nur, sie verbreitert sie nicht. |
| Timed Hit ganz streichen | Nimmt dem Kampf die einzige Eingabe, die in der Sekunde stattfindet. Das Konzept nennt ihn ausdrücklich als Skill-Element. |
| Timed Hit gibt Energie statt Schaden | Reizvoll, weil ein Ressourcenbonus nicht linear in die Siegquote geht. Zu weit vom Konzept entfernt für diesen Schritt — bleibt als Option notiert. |
| Heilung deckeln (n-mal pro Kampf) | Bräuchte Zustand in der Policy und damit reproduzierbare Kämpfe aufgeben. Die Schild-Bedingung erreicht dasselbe zustandslos. |

## Konsequenzen

**Leichter:**

- Zu jedem Zeitpunkt gibt es einen Gegner, der sich lohnt. Der Kampf hört
  nicht nach einer Woche auf, interessant zu sein.
- Gegnerwerte stehen im Package und sind damit simulierbar. Der Controller
  enthält keine Spielzahlen mehr — die Schichtregel aus `CLAUDE.md` gilt
  jetzt auch hier.
- Der Dungeon hat seine Gegner schon. `EnemyBlueprint` trägt ein eigenes
  Moveset, ohne dass Engine oder Policy etwas davon wissen müssen.
- `packages/combat/test/termination_test.dart` sichert dauerhaft ab, dass
  Kämpfe enden — über Wertebereiche, die kein Beispielkampf abdeckt.

**Schwerer:**

- Die HP-Zahlen haben sich verschoben (100–140 → 160–224). Wer alte
  Screenshots oder Notizen liest, findet andere Werte.
- Der Timed-Hit-Deckel weicht vom Konzept ab (dort +50 %). `konzept.md`
  Abschnitt 3.2 ist entsprechend nachgezogen.
- Es gibt jetzt zwei Simulationen mit unterschiedlichem Zweck.
  `packages/combat/example/balance_sim.dart` prüft die Engine,
  `tool/balance_sim.dart` prüft das Spiel. Die Trennung ist im Kopf der
  Datei erklärt, aber sie ist eine Stelle mehr, an der man die falsche
  erwischen kann.
- Wer die Stat-Kurve in `packages/habits/lib/src/rewards.dart` anfasst,
  verschiebt die ganze Diagonale. Das war vorher schon so, ist jetzt aber
  über drei Gegner sichtbar statt über einen.
