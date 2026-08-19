# Projektstand

> Diese Datei ist die Antwort auf „Wo stehen wir gerade?".
> Am Ende jeder Arbeitssitzung aktualisieren. Alte Einträge unter „Verlauf"
> zusammenfassen, nicht löschen.

**Zuletzt aktualisiert:** 19.08.2026 · AktivesBrett

---

## Phase

**Der MVP-Schnitt steht bis auf den Dungeon.** Lektion lesen → Vorlage
freischalten → täglich abhaken → Werte steigen → Gold sammeln → Ausrüstung
kaufen → nächsten Gegner schlagen. Alles davon überlebt jetzt einen
Neustart.

Auf dem Startbildschirm ist **keine Kachel mehr gesperrt**.

```bash
flutter run -d chrome
```

## Fertig

- Produktkonzept (`konzept.md`)
- Tech-Stack ([ADR-0001](../decisions/0001-tech-stack.md))
- Architekturregel Kampflogik/Flame ([ADR-0002](../decisions/0002-kampflogik-ohne-flame.md))
- Kampflogik als eigenes Package ([ADR-0003](../decisions/0003-combat-als-eigenes-package.md))
- **`packages/combat`** — reine Dart-Kampflogik, 27 Tests grün:
  - 4 Move-Slots gemäß Konzept (erzeugen / verbrauchen / schwächen / stützen)
  - Timed Hits mit Deckel, Energie, Gift, Verteidigungssenkung, Heilung, Schild
  - **Drei Gegner** in `enemy.dart`, aufsteigend
    ([ADR-0009](../decisions/0009-kampfbalance-ueber-gegnerreihe.md))
  - Vollständiges Event-Vokabular als Naht zu Flame
  - Deterministisch per Seed → Balance-Simulation möglich
  - `termination_test.dart` sichert ab, dass Kämpfe **enden** — über
    Wertebereiche, die kein Beispielkampf abdeckt
- **`packages/theory`** — Skillbaum, Inhalte, Lernfortschritt, 50 Tests grün
  ([ADR-0004](../decisions/0004-theorie-als-eigenes-package.md)):
  - **17 Lektionen in 5 Zweigen**, jede mit 3 Abschnitten und 3 Fragen
    ([ADR-0007](../decisions/0007-theorie-als-skillbaum.md))
  - Zweige öffnet das **Charakterlevel**, Lektionen die Reihenfolge im Zweig
  - Bestehensgrenze 60 %; XP und Gold nur einmal je Lektion
  - Elf Lektionen schalten je eine Habit-Vorlage frei
  - `content_test.dart` prüft **Inhalt**, nicht Code
- **`packages/progression`** — Levelkurve, 11 Tests grün
  ([ADR-0006](../decisions/0006-levelkurve-als-eigenes-package.md))
- **`packages/habits`** — Gewohnheiten, Streaks, Charakterwerte, 63 Tests grün
  ([ADR-0008](../decisions/0008-gewohnheiten-als-eigenes-package.md)):
  - **11 Vorlagen**, jede mit Charakterwert, Zweig und Begründung
  - Vier Werte: Stärke → Angriff, Ausdauer → HP, Disziplin → Verteidigung,
    Klarheit → Energie
  - Streak-Multiplikator, Meilensteine bei 3/7/14/30/60 Tagen, Deckel x2
  - Höchstens **fünf** Gewohnheiten gleichzeitig
  - Erfahrung und Gold werden **abgeleitet**, nicht gezählt
- **`packages/gear`** — Ausrüstung, Preise, Inventar, 27 Tests grün
  ([ADR-0011](../decisions/0011-ausruestung-als-eigenes-package.md)):
  - **Sechs Plätze, neun Stücke in zwei Stufen.** Energie sitzt auf Ring und
    Talisman — das Konzept verlangt Ausrüstung, die Entscheidungen ändert
    und nicht nur Zahlen
  - **Gold wird abgeleitet:** Zufluss minus Preis des Besitzes. Kein
    gespeicherter Kontostand, deshalb auch kein Verkauf
  - `catalog_test.dart` prüft den Inhalt des Ladens wie `content_test.dart`
    die Lektionen
- **`packages/identity`** — Name und verdiente Titel, 28 Tests grün
  ([ADR-0014](../decisions/0014-titelkatalog-aus-drei-quellen.md)):
  - **Sieben Titel aus drei Quellen**: Streak-Tage, bestandene Lektionen,
    gesetzte Häkchen. Drei Spieler auf demselben Level können drei
    verschiedene Titel tragen — das ist der Zweck
  - Der Name wird **eingegeben**, der Titel nur **ausgewählt** aus dem,
    was verdient ist (ADR-0013)
  - Bedingung hängt an `longestStreak`, nicht an der laufenden Kette:
    ein verdienter Titel überlebt einen verpassten Tag
  - Der gespeicherte Titel ist eine Wahl, kein Nachweis — geprüft wird bei
    jeder Anzeige neu
  - `title_catalog_test.dart` prüft den Inhalt wie `catalog_test.dart` den
    Laden
- **Persistenz** ([ADR-0010](../decisions/0010-persistenz-hinter-einem-anschluss.md)):
  - `SaveStore` als Anschluss, `shared_preferences` als erste
    Implementierung, Drift passt später dahinter
  - Serialisierung liegt **in den Packages**, ist damit ohne Flutter testbar
  - Gelesen wird einmal vor `runApp`, geschrieben an genau einer Stelle
    (`SaveWatcher`)
  - Alle `fromJson` sind nachsichtig: Ein Formatfehler kostet nie den
    ganzen Stand
- **Flutter-App** (`lib/`) — 90 Tests grün, Web-Build läuft:
  - **Startbildschirm** mit allen fünf Bereichen, keiner mehr gesperrt
  - **Skillbaum**, **Theorie**, **Gewohnheiten** wie bisher
  - **Gegnerwahl** vor dem Kampf, mit Einschätzung („wird knapp")
  - **Kampf**: Flame-Darstellung, Statusleisten, Move-Buttons, Log, Timing
  - **Laden**: sechs Plätze, Preis, Wirkung, Begründung — und bei zu wenig
    Gold, wie viele Tage noch fehlen
  - **Charakter**: Name und verdienter Titel im Kopf, jeder Wert mit
    Herkunft („18 Angriff, davon 3 aus Ausrüstung"), sechs Plätze zum
    Umrüsten
  - `test/progression_test.dart` prüft, was kein Package allein kann: dass
    Belohnungs-, Habit-, Level- **und Preiskurve** zusammenpassen
  - `test/persistence_test.dart` prüft, dass ein Neustart nichts verliert

## Die Kampfbalance trägt jetzt — anders als geplant

Der alte Befund („das umkämpfte Band ist zwei Angriffspunkte breit") war
richtig gemessen und falsch gedeutet. Die vorgeschlagene Abhilfe — HP
erhöhen, damit lange Kämpfe Multiplikatoren dämpfen — hätte das Problem
**verstärkt**: Längere Kämpfe mitteln den Zufall aus und machen den Ausgang
berechenbarer. Ein Rennen mit festen Werten kippt scharf, das liegt in der
Sache.

Die Lösung ist eine **Gegnerreihe**. Zu jedem Zeitpunkt ist einer knapp:

| Gegner | Tag 0 | Tag 7 | Tag 14 | Tag 21 | Tag 30 | Tag 60 |
|---|---|---|---|---|---|---|
| Wegelagerer | 62 % | 100 % | 100 % | 100 % | 100 % | 100 % |
| Soeldner | 0 % | 0 % | 4 % | 100 % | 100 % | 100 % |
| Bergwaechter | 0 % | 0 % | 0 % | 0 % | 36 % | 100 % |

Der erste Gegner ist **ab Tag eins schlagbar**. Vorher stand ein frischer
Charakter bei 0 %.

Die Spannweite zwischen keinem und perfektem Timing ist genau am
Schwellen-Gegner groß und daneben null — die gewünschte Aussage:
Gewohnheiten entscheiden, *ob* ein Kampf knapp wird, Timing entscheidet den
knappen Kampf.

Nachrechnen: `dart run tool/balance_sim.dart`. Details in ADR-0009.

## Der Stat-Deckel ist kein Problem mehr

Nach etwa einem Monat stehen alle vier Werte am Maximum (160–224 HP,
13–20 Angriff). Das bleibt so und ist gewollt — ohne Deckel überholt ein
alter Account jede Gegnerauslegung.

Bis zum 18.08. stand hier, der Charakter erstarre danach und der nächste
Schritt dagegen sei der Dungeon mit Drops. **Das gilt nicht mehr.** Mit
ADR-0012 und ADR-0013 wächst der Charakter über vier andere Wege weiter:
Theoriepunkte bis Level 50, Fähigkeitspunkte alle drei Level, Fähigkeiten
aus abgeschlossenen Baumknoten und Streak-Marken, Waffen als Spielstile.

## Konzeptrunde Charakter — 18.08.2026, entschieden, noch nichts gebaut

Der Charakter wurde vollständig durchgesprochen, bevor eine Zeile Code
entsteht. Zwei ADRs halten das Ergebnis:

**[ADR-0012](../decisions/0012-theoriebaum-ueber-punkte.md) — der Theoriebaum
wird ein echter Baum.** Zwei Wurzeln (Körper, Geist), beliebige Tiefe,
Knoten öffnen über **Theoriepunkte** statt über Levelsperren. Ein Punkt je
Levelaufstieg, ein Punkt je Knoten, unabhängig von der Tiefe. „Gewohnheiten"
bleibt frei — es ist das Handbuch. **ADR-0007 ist damit abgelöst.**

Der geplante Baum hat rund 45 Knoten. Der vorhandene Inhalt verteilt sich
sauber: Körpers drei Lektionen sind Schlaf, Sport und Ernährung — die
Aufspaltung war im Text längst vorweggenommen. Soziales und Wissenschaft
sind fertig, alles andere braucht Schreibarbeit.

**[ADR-0013](../decisions/0013-charakter-als-kommandozentrale.md) — der
Charakter wird eine Kommandozentrale.** Vier Fähigkeitsslots, drei frei
wählbar, einer von der Waffe bestimmt. Zwanzig Fähigkeiten aus Theoriebaum
(Knoten **abschließen**), Streak-Marken und Waffen. Fähigkeitspunkte alle
drei Level, umverteilbar. Name und Titel jetzt, Aussehen später.

> **Es wird nie eine Klassenwahl geben.** Jeder formt seinen Charakter durch
> seinen persönlichen Stil. Wo eine Klasse sichtbar werden soll, wird sie
> aus dem Verhalten abgeleitet, nie gewählt.

### Zwei Zahlen, die das Projekt bemessen

- **49 Knoten sind die harte Obergrenze.** `maxLevel` ist 50, also gibt es
  über ein Spielerleben genau 49 Theoriepunkte.
- **Ein voller Baum heißt rund 150 Lektionen.** Es gibt heute 17.

Der Engpass des Projekts ist damit vollständig die Schreibarbeit, nicht der
Code. Dagegen steht eine Regel: **Ein Knoten erscheint erst im Baum, wenn
sein Inhalt geschrieben ist.** Ein halber Knoten ist schlimmer als keiner —
für ihn wurde ein Punkt bezahlt.

### Eine Schieflage, die dabei auffiel

Die elf Habit-Vorlagen verteilen sich auf die vier Werte als 4 Klarheit,
3 Disziplin, **2 Ausdauer, 2 Stärke**. Die beiden Werte, die den Kampf am
direktesten entscheiden, haben die wenigsten Quellen — und beide hängen an
Körper. Der Ausbau von Körper repariert deshalb nicht nur den Baum.

## Als Nächstes

Reihenfolge offen. Vom Charakter-Konzept ist **Name und Titel gebaut**
(ADR-0014), der Rest steht noch aus.

1. **Charakter weiterbauen** (ADR-0012, ADR-0013): Baumstruktur in
   `packages/theory` auf Knoten mit Kindern umbauen, Punkteökonomie,
   Fähigkeitsslots. Der sichtbarste Teil ist die Baumdarstellung —
   `skill_tree_screen.dart` zeigt heute eine Liste, ein Baum braucht etwas
   anderes. Name und Titel sind aus dieser Liste heraus.
2. **Die zwanzig Fähigkeiten festlegen** — Wirkung, Energiekosten,
   Aufwertungspfad, Zuordnung zu Waffen. Ohne sie sind die Slots leer.
3. **Dungeon** — 4 Gegner plus Boss, HP heilt nicht dazwischen. Das Stück,
   das im MVP-Schnitt noch fehlt. Offen bleibt die Niederlagen-Regel
   (`konzept.md` Punkt 3): verfallener Eintritt plus Neustart bestraft
   doppelt.
4. **Tränke und Wiederbelebung** — bewusst mit dem Dungeon zusammen.
5. **Kampfsystem-Umbau** — es liegt eine Design-Notiz von Frederik vor
   (`Kampfsystem.docx`, noch nicht im Repo): Initiative über ein Minispiel
   mit drei Situationen, Attacken in Angriff und Ausweichen geteilt,
   Kontern, dazu ein Sparring-Tutorial beim Lieutenant, das in die
   Bibliothek und damit in die Theorie überleitet. Nicht entschieden.
6. **Tageswechsel bei laufender App** — `todayProvider` rechnet sich nicht
   von selbst neu. Wer die App über Mitternacht offen lässt, sieht bis zum
   Neustart den gestrigen Tag. Ein Wecker auf Mitternacht behebt das.
7. **Rive-Animationen** statt der Rechtecke in `battle_game.dart`.

**Balance ist bewusst zurückgestellt.** Erst fertig bauen, dann tarieren.
Mit drei aus zwanzig Fähigkeiten plus Waffe wird sie ohnehin eine
Stichprobe statt einer Rechnung.

## Signale, an denen Entscheidungen neu anstehen

Beides ist heute richtig und wird es nicht bleiben:

- **Persistenz:** Der komplette Stand wird bei jeder Änderung geschrieben.
  Bei drei Objekten irrelevant. Sobald der Dungeon Lauf-Historie mitbringt,
  braucht es Entprellen — oder tatsächlich Drift. Der Anschluss steht dafür
  bereit (ADR-0010).
- **Kein Verkauf im Laden:** tragbar bei sechs Plätzen und neun Stücken.
  Kommen Drops dazu, wird ein voller Rucksack ohne Ausgang unangenehm
  (ADR-0011).

## Aufgabenteilung

Es gibt jetzt fünf saubere Nähte: `packages/combat` gibt `CombatEvent`s aus,
die Flame abspielt — `packages/theory` liefert Inhalte — `packages/progression`
die Levelkurve — `packages/habits` Streaks und Charakterwerte —
`packages/gear` Preise und Boni. Dazu der Speicher-Anschluss in `lib/save/`.

Damit lässt sich parallel arbeiten, ohne sich zu blockieren: Logik/Balance,
Darstellung, Inhalte, Ökonomie.

## Verlauf

- **19.08.2026** — Name und Titel gebaut, das erste Stück aus dem
  Charakter-Konzept (ADR-0014). Sechstes Package `identity`: sieben Titel
  aus drei Quellen, verdient statt gewählt. Dabei `longestStreak` in
  `habits` ergänzt — die Bedingung an die laufende Kette zu hängen hätte
  einen verdienten Titel bei einem verpassten Tag gelöscht und damit
  `konzept.md` 3.7 verletzt. Zweiter Rechner im Team eingerichtet
  (Flutter 3.47.0 / Dart 3.13.0).
- **18.08.2026** — Konzeptrunde Charakter, kein Code. Theoriebaum wird ein
  echter Baum mit Punkten statt Levelsperren (ADR-0012, löst ADR-0007 ab),
  Charakter wird Kommandozentrale mit vier Fähigkeitsslots und ohne
  Klassenwahl (ADR-0013). Dabei zwei Dinge gefunden: Der vorhandene
  Körper-Inhalt hatte seine eigene Aufspaltung vorweggenommen, und die
  Habit-Vorlagen sind auf Stärke und Ausdauer zu dünn besetzt.
- **17.08.2026** — MVP bis auf den Dungeon geschlossen. Kampfbalance über
  eine Gegnerreihe gelöst (ADR-0009) und dabei zwei Fehler gefunden: einen
  Heal-Lock, der Kämpfe nicht enden ließ, und eine Simulation, die die
  falsche Größe maß. Persistenz hinter einem Anschluss statt Drift
  (ADR-0010) — der Fortschritt überlebt jetzt einen Neustart. Ausrüstung als
  fünftes Package, Gold bekommt einen Abfluss (ADR-0011). Charakter- und
  Ladenbildschirm gebaut, damit ist keine Kachel mehr gesperrt.
- **12.08.2026, abends** — Gewohnheiten gebaut und damit den Kern-Loop
  geschlossen (ADR-0008): fünftes Package mit Vorlagen-Katalog, Streaks,
  Belohnungs- und Stat-Kurve, dazu der Tracker-Bildschirm.
- **12.08.2026, nachmittags** — Theorie zum Skillbaum ausgebaut: vier neue
  Zweige, freigeschaltet über das Charakterlevel (ADR-0007). Levelkurve als
  eigenes Package (ADR-0006). Insgesamt 17 Lektionen und 51 Fragen.
- **12.08.2026, vormittags** — Startbildschirm gebaut, ersten Theoriezweig
  geschrieben (5 Lektionen), Fortschritts- und Belohnungslogik als eigenes
  Package (ADR-0004, ADR-0005). Farben in `lib/ui/palette.dart`.
- **11.08.2026** — Konzept in vier Fragerunden erarbeitet. Repo aufgesetzt,
  Gedächtnis-Struktur und ECC-Werkzeuge eingecheckt. Kampflogik
  implementiert, Balance-Simulation gebaut, erste Balance-Schwäche gefunden.
  Flutter-App mit spielbarem Kampfbildschirm.
