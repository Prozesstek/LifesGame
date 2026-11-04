# ADR-0098: Die Level-Roadmap, und Extras warten auf ein Level

**Datum:** 04.11.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Frederik: „Mein Ziel ist es jetzt so eine Art Level Roadmap zu machen. Das
man sieht was z.B. beim nächsten Levelup passiert und bestimmte Bereiche
auch erst mit einem bestimmten Level freigeschalten werden. z.B. Haustiere
erst ab Level 5“.

Bis dahin brachte ein Level einen Talentpunkt, 4 % Macht, auf 2, 6 und 10
einen Fähigkeitsplatz, auf 15 die Ultimate und alle zehn Level einen neuen
Rahmen. Auf Level 3, 4, 5, 7 und 8 bis 14 kam nichts Sichtbares. Bereiche
gingen nur über **Taten** auf (ADR-0068, ADR-0079), und was ein Aufstieg
bringen würde, sah man erst, wenn er kam.

Gemessen mit `runway_sim`: Ein fleißiger Spieler steht an Tag 1 auf Level
2, an Tag 5 auf 6, an Tag 10 auf 9, an Tag 20 auf 14.

## Entscheidung

In einer Fragerunde, viermal wie empfohlen:

1. **Nur Extras hängen am Level.** Der Weg des Mentors bleibt an Taten.
   | Level | Extra |
   |---|---|
   | 3 | Lagerfeuer (Truhe, Dailies, „Morgen zuerst“) |
   | 4 | Tagesdungeon |
   | 5 | Haustier |
   | 7 | Statistik |
   | 10 | Sammlung samt Errungenschaften |

   Die Zahlen stehen in `LevelExtra` (`packages/progression`), gelesen
   in `ErsterStart.aus`.
2. **Ein Tipp auf den Level-Ring öffnet die Roadmap**: oben die Erfahrung
   bis zum nächsten Level und was jedes Level bringt, darunter die
   Meilensteine als Pfad. Die Feier eines Aufstiegs nennt, was aufgeht,
   und darunter blass das nächste Ziel („Level 6 · Fähigkeitsplatz 3“).
3. **Was ein Stand schon hat, behält er**: ein gewähltes Ei, etwas am
   Lagerfeuer, ein Versuch in der Tagesgrube.
4. **Nach Level 15 wird später gefüllt.** Bis dahin zeigt die Roadmap dort
   nur die Rahmen und das Höchstlevel.

## Begründung

Der Mentor-Weg erklärt sich über Taten, und ein Level-Riegel davor hätte
ihn verlängert. Die Extras dagegen standen ab dem ersten Tag ohne
Erklärung da, oft alle auf einmal (`state.md`, 24.10.: „Der Mentor
schweigt nach dem ersten Sieg“). Hängen sie am Level, hat jeder Aufstieg
bis 10 etwas zu zeigen, und sie kommen einzeln.

Die Roadmap rechnet nichts Neues: `LevelUp.between` kannte Plätze und
Punkte schon, dazu kommen `extras` und `opensUltimate`. Eine Stelle
(`LevelRoadmap.gewinne`) beantwortet „was bringt dieses Level“ für Blatt
und Feier.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Alles über Level (auch Laden, Ausrüstung …) | Zwei Regeln würden zu einer, aber ADR-0068/0079 müssten umgebaut werden, und der Mentor zeigte auf Bereiche, die noch zu sind |
| Nur das Haustier | Die Roadmap hätte zwischen 2 und 10 fast nichts zu zeigen |
| Ein eigener Kreis für die Roadmap | Ein neunter Kreis für etwas, das zum Level gehört; der Ring ist dort, wo man nach dem Level sucht |
| Alte Stände wieder sperren | Ein Haustier, das wieder verschwindet, ist schlimmer als eines, das fehlt (dieselbe Regel wie ADR-0033, ADR-0068) |

## Konsequenzen

- **Statistik und Sammlung halten nichts, was jemand besitzt**, und werden
  deshalb nicht behalten: Ein alter Stand unter Level 7 verliert den Kreis
  der Statistik, unter Level 10 den Weg in die Sammlung, bis er dort ist.
  Das trifft Tester, die seit dem 26.10. spielen und noch tief stehen.
- **Errungenschaften sind bis Level 10 nicht anzusehen**, sie wohnen seit
  ADR-0080 in der Sammlung. Ihre Feier kommt weiter.
- **Die Truhe der ersten Tage fällt weg**: Wer Level 3 erst am zweiten Tag
  erreicht, hat die Truhe des ersten nie gesehen. Etwas weniger Gold und
  Eis am Anfang; `runway_sim` zählt das nicht.
- Der Ring hat keinen Tooltip mehr; der Satz zur Erfahrung steht oben in
  der Roadmap.
- Ein neues Extra ist ein Eintrag in `LevelExtra` und eine Zeile in
  `LevelRoadmap.extra`; der Analyzer zeigt auf den Schalter.
