# ADR-0048: Exemplare mit gewürfelten Werten, ein Tagesladen und Beute mit Schlüsseln

**Datum:** 24.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik, in einer Konzeptrunde Frage für Frage

## Kontext

Im 30-Tage-Test (Tag 4) passierte am Tag wenig ausser den Dailies: kein
Aufstieg, kein Kauf (ADR-0047). Der Laden war vollständig vorhersehbar —
man sparte und kaufte einen Katalog ab. Frederik, mit Diablo als Vorbild:
„Das gleiche Item droppt öfters, aber mit zufälligen Stats … der Shop
droppt eine tägliche Auswahl, aber man kriegt auch über den Dungeon was.“

Und der Grundsatz dazu: **Gewohnheiten und Theorie bleiben der
Hauptpunkt.** Wer mehr spielen will, soll das können, dadurch aber nicht
übertrieben stärker werden, sondern sich selbst verbessern.

## Entscheidung

**1. Exemplare mit gewürfelten Werten.** Ein Stück im Besitz ist kein
Katalog-Id mehr, sondern ein Exemplar: Katalogstück plus eigene Werte.
Jeder Bonus wird **einzeln gewürfelt, 85 bis 115 %** des Katalogwerts.
Set, legendäre Kraft und Seltenheitsfaktor bleiben fest. Die Boni rechnen
und zeigen im **Kampfmassstab** (× `ActionBalance.powerScale`, also ×10),
damit ±15 % sichtbare Zahlen sind; das Verhältnis zu allem anderen bleibt.

**2. Ein Tagesladen.** Sechs Angebote am Tag, **eins je Platz**, jedes ein
fertig gewürfeltes Exemplar, aus dem Datum gewürfelt. Kein fester
Set-Händler: Ein Set-Teil will erjagt sein. Der Preis hängt an der
Seltenheit, nicht am Wurf — ein Glückswurf ist ein Schnäppchen.

**3. Beute mit Schlüsseln.** Jedes Häkchen, jede bestandene Seite und
jede richtig beantwortete Rückfrage gibt einen **Schlüssel**, höchstens
**10** auf Vorrat. Fällt der Wächter, öffnet ein Schlüssel seine Beute:
ein gewürfeltes Exemplar. Der **erste Sieg** auf einer Stufe bringt immer
eins, ohne Schlüssel. Ohne Schlüssel läuft man trotzdem — für Bestzeit
und Übung.

**4. Tiefer heisst besser.** Die Seltenheit der Beute hängt an der Stufe;
dieselbe Tabelle gilt im Laden nach der tiefsten geschafften Stufe:

| Stufe | Gewöhnlich | Ungewöhnlich | Selten | Episch | Legendär |
|---|---|---|---|---|---|
| 1–9 | 70 | 25 | 5 | – | – |
| 10–19 | 40 | 35 | 18 | 7 | – |
| 20–30 | 20 | 35 | 25 | 15 | 5 |

Die Sperren aus ADR-0034 (Episch ab Stufe 10, Legendär ab 20) stecken
damit in der Tabelle. Der Wurf bleibt immer 85 bis 115 %.

**5. Verkaufen bringt 25 %** des Katalogpreises, egal ob gekauft oder
erbeutet. Das Inventar behält alles, ohne Grenze; ein Knopf verkauft
alles Schlechtere auf einmal.

**6. Übernahme ohne Verlust.** Jedes heute besessene Stück wird ein
Exemplar mit genau 100 %. Gold bleibt eine Rechnung aus einer Historie
(ADR-0011): Käufe halten den bezahlten Preis, Verkäufe den Erlös.
Übernommene Stücke zählen mit ihrem Katalogpreis, frühere Verkäufe mit
ihrer alten Rechnung. Exemplare werden mit ihren Werten gespeichert,
nicht nur mit einem Startwert.

## Begründung

**Die Zahl der Würfe hängt nur an Gewohnheiten und Theorie** (Schlüssel).
Das ist der Grundsatz als Regel: Grinden geht, aber die Würfe verdient
man sich woanders. **Die Güte der Würfe hängt an der Tiefe**, und wie
tief man kommt, entscheiden Level und Werte — also wieder die
Gewohnheiten — plus das eigene Können. Wer besser spielt, kommt ein paar
Stufen tiefer; mehr nicht.

**Aus dem Datum gewürfelt** heisst: nichts zu speichern, und beide sehen
denselben Laden, solange sie gleich weit sind. Das ist bewusst
aufgeweicht, sobald einer tiefer ist: Wo beim einen ein Episches liegt,
sieht der andere unter Stufe 10 ein Seltenes.

**25 % statt 50 % beim Verkauf**, weil erbeutete Stücke nichts kosten.
Bei 50 % wären fünf bis acht Stücke am Tag eine Goldquelle aus dem
Spielen, grösser als die Gewohnheiten, und der Laden wieder Nebensache.
ADR-0031 ist damit teilweise abgelöst.

**Gespeicherte Werte statt Startwert**, weil sich die Würfelregel ändern
wird; ein Stück, das man hat, soll sich dabei nicht ändern.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Ein Qualitätswert je Stück statt einzelner Werte | übersichtlicher, aber Frederik wollte Diablo; mit Zahlen ×10 tragen einzelne Würfe |
| Fester Set-Händler neben dem Tagesladen | nimmt dem Set-Teil die Jagd, und die ist der Punkt |
| Jeder Lauf droppt | der Vielspieler jagte Sets zehnmal schneller — Gewohnheiten wären Nebensache |
| Verkauf bleibt bei 50 % | Beute würde zur Goldquelle |
| Exemplar als Id plus Startwert | eine spätere Würfelregel änderte alte Stücke |

## Konsequenzen

- Die Ausrüstung hat zum ersten Mal **Nutzerzustand mit Zufall**. Er wird
  beim Entstehen gewürfelt und dann nur noch gespeichert.
- `Loadout` hält Exemplare statt Ids; alles, was einen neuen `Loadout`
  baut, muss die Historie weitergeben (dieselbe Falle wie `soldIds`,
  ADR-0031).
- Die Kurven (ADR-0047) sind neu zu rechnen: Beute ist Ausrüstung ohne
  Gold. `tool/runway_sim.dart` sagt danach, wann das erste Epische kommt.
- Die Zahlen der Tabelle sind ein Anfang, nicht gemessen.
