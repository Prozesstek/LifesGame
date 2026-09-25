# ADR-0049: Die Fähigkeiten bekommen einen eigenen Bereich

**Datum:** 25.09.2026
**Status:** Aktiv
**Entschieden von:** AktivesBrett
**Ergänzt:** [ADR-0013](0013-charakter-als-kommandozentrale.md) (die Plätze
ziehen aus dem Charakter aus)

## Kontext

Die vier Fähigkeitsplätze standen seit dem 22.08. als Abschnitt im
Charakterbildschirm, zwischen den Werten und dem Ausrüstungsraster. Wer
einen belegen wollte, tippte einen Platz an und bekam ein Auswahlblatt —
und in dem Blatt stand **nur das Freigeschaltete**.

Das war so lange harmlos, wie es wenig zu holen gab. Heute hat der
Katalog **neunzehn** wählbare Fähigkeiten aus vier Quellen (Theorieknoten,
Streak-Marken, Errungenschaften, dazu acht Waffenzüge). Ein frischer
Charakter sieht davon **keine einzige**. Was man sich erarbeiten kann,
steht nirgends; die Liste wächst beim Spielen, ohne je ein Ziel gewesen
zu sein.

Dazu kam, dass das Blatt zu wenig sagte. Eine Zeile — „12 Mana · 1,5 s —
Ein Funke fliegt geradeaus." — reicht, um zwischen zwei bekannten
Fähigkeiten zu wählen, aber nicht, um eine unbekannte zu beurteilen.
Schaden, Reichweite, Umkreis, Dauer, Zielart und Seltenheit stehen alle
im Katalog und standen an keiner Oberfläche.

Und der Charakterbildschirm war lang geworden: Identität,
Errungenschaften, Beständigkeit, Macht, vier Werte, Fähigkeiten, sechs
Ausrüstungsplätze, Sets.

## Entscheidung

Die Fähigkeiten ziehen aus dem Charakter aus und bekommen einen eigenen
Bereich mit eigenem Kreis auf dem Startbildschirm. Dort stehen oben die
vier Plätze und darunter der **ganze** Katalog, nach Seltenheit
gruppiert — freigeschaltetes in Farbe, Gesperrtes grau. Antippen öffnet
ein Blatt, das **jede** Zahl der Fähigkeit nennt, auch bei den grauen.

## Begründung

**Ein Ziel, das man nicht sieht, ist keins.** Das ist im Projekt
dreimal dieselbe Entscheidung: Der gesperrte Kreis auf der Startseite
bleibt sichtbar und nennt beim Antippen den Weg
([ADR-0020](0020-kampf-haengt-am-moveset.md)), das gesperrte
Ausrüstungsstück steht im Laden mit Preis und Sprosse
([ADR-0034](0034-episch-und-legendaer-haengen-an-der-gegnerreihe.md)),
der gesperrte Fähigkeitsplatz nennt sein Level (ADR-0013). Nur die
Fähigkeiten selbst waren unsichtbar, bis sie da waren.

**Alle Werte, weil sie alle schon dastehen.** `PitAbility` hält Mana,
Abklingzeit, Art, Zielart, Wurfweite, Umkreis und eine Liste von
Wirkungen; `Ability` hält Seltenheit und Bedingung. Die Werte zu zeigen
war Leseweise, keine neue Zahl — und was sich ausrechnen lässt, wird
ausgerechnet: Neben dem Faktor steht die Zahl, die er beim eigenen
Angriffswert ergibt. Dieselbe Regel wie beim alten `move_help.dart`
und bei der Beständigkeits-Leiter („18 statt 15" schlägt „20 % mehr").

**Ein eigener Bereich statt eines längeren Charakters.** Der Katalog
braucht neunzehn Kacheln und fünf Überschriften. Unter dem
Ausrüstungsraster wäre das der zweite Bildschirm im ersten — und der
Charakter ist die Stelle für *Zurechenbarkeit* („18 Angriff, davon 3 aus
Ausrüstung"), nicht für einen Katalog.

**Der Knopf sagt vorher, was er überschreibt.** Das Blatt bietet die
Plätze einzeln an, mit dem Namen dessen, was dort liegt. Ein
„Anlegen", das den nächsten freien Platz nimmt, wäre kürzer — aber
sobald alle belegt sind, ersetzt es blind.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Den Abschnitt im Charakter lassen und nur das Auswahlblatt erweitern | Löst die Hälfte: Die Werte wären da, der Überblick über das Gesperrte nicht — das Blatt hängt an einem Platz, nicht am Katalog |
| Gesperrte ausblenden, bis sie verdient sind | Genau der Zustand, der abgelöst wird. Ein Katalog, der nur zeigt, was man hat, ist eine Bestandsliste |
| Nach Quelle gruppieren (Theorie / Streak / Errungenschaft) | Die Quelle sagt, wo man sie herbekommt, nicht was sie taugt — und sie steht ohnehin im Blatt. Die Seltenheit ordnet nach Stärke |
| Eine Liste mit Zahlen je Zeile statt eines Rasters | Neunzehn Zeilen scrollen; ein Raster zeigt alle fünf Stufen auf einem Bildschirm, und die Zahlen stehen eine Berührung entfernt |
| Ein Knopf „Anlegen" auf den nächsten freien Platz | Ersetzt blind, sobald alle drei belegt sind |
| Alle offenen Plätze als Knöpfe anbieten | `ChosenAbilities` hält keine Lücken: „Platz 4" bei leerem Platz 2 landet in Wahrheit auf Platz 2. Angeboten wird deshalb nur, was das Modell trägt — die belegten plus der nächste leere |
| Ein gezeichnetes Symbol für den neuen Kreis bestellen | Es gibt neunzehn gezeichnete Fähigkeiten; Sternenfall sitzt mittig und symmetrisch auf einem runden Knopf |

## Konsequenzen

**Leichter:** Der Katalog ist zum ersten Mal ein Ziel statt einer
Überraschung — gerade für einen frischen Charakter, der noch nichts
hat. Der Charakterbildschirm wird um einen Abschnitt kürzer. Die Werte
einer Fähigkeit stehen an genau einer Stelle (`pitAbilityStats` in
`lib/action/pit_text.dart`) und werden aus der `sealed`-Liste der
Wirkungen gelesen: Eine neue Art von Wirkung ist ein Compilerfehler
dort, kein stilles Loch im Blatt.

**Schwerer:** Sechs Kreise auf dem Startbildschirm statt fünf. Die
untere Reihe trägt jetzt drei; am Handy geprüft ist das noch nicht.

**`RarityBadge` hat einen zweiten Konstruktor bekommen.** Es gibt zwei
Aufzählungen mit denselben fünf Stufen — `GearRarity` für Ausrüstung,
`Rarity` in `package:abilities` für Fähigkeiten. Die Marke nimmt jetzt
Nummer und Wortlaut statt eines der beiden Typen; die Farbtabelle bleibt
damit **eine**. `rarity_test.dart` hält fest, dass beide Reihen gleich
lang sind und dieselbe Stufe gleich heißt — verschiebt sich das, bekäme
„Selten" bei den Fähigkeiten die Farbe von „Episch", ohne eine einzige
Meldung.

**Der Weg vom Charakter bleibt** als Knopf neben „Zum Laden". Wer seinen
Charakter ansieht, sucht die Fähigkeiten dort, und der Kreis auf der
Startseite hilft ihm in dem Moment nicht.

**Der Kreis ist nie gesperrt**, obwohl auf Level 1 nur der Waffenplatz
offen ist. Das ist Absicht und dieselbe Begründung wie oben: Der
Bildschirm zeigt vor allem, was es zu holen gibt, und das ist genau
dann am nützlichsten, wenn man noch nichts hat.

**Offen:**

- **Nicht am Handy angesehen.** Die Layouts laufen bei 390 × 844 ohne
  Überlauf, aber ob vier Kacheln je Reihe mit zweizeiligen Namen
  („Prisma-Barriere") als Raster lesen oder als Gedränge, sagt erst ein
  Gerät. Dasselbe für die dritte Kachel in der unteren Kreisreihe.
- **Die Waffenzüge stehen nicht im Katalog darunter**, nur auf Platz 1.
  Acht weitere Kacheln, die man nicht wählen kann, wären eine zweite
  Art von Eintrag im selben Raster — wer die Waffe vergleichen will,
  tut das im Laden, wo sie etwas kostet.
