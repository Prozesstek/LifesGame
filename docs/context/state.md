# Projektstand

> Diese Datei ist die Antwort auf „Wo stehen wir gerade?".
> Am Ende jeder Arbeitssitzung aktualisieren. Alte Einträge unter „Verlauf"
> zusammenfassen, nicht löschen.

**Zuletzt aktualisiert:** 12.08.2026 · Frederik

---

## Phase

**Der Kern-Loop des Konzepts ist geschlossen.** Lektion lesen → Vorlage
freischalten → täglich abhaken → Werte steigen → Kampf wird gewinnbar. Dungeon
und Shop fehlen noch — sie stehen als gesperrte Kacheln auf dem
Startbildschirm, damit sichtbar bleibt, wohin es geht.

```bash
flutter run -d chrome
```

## Fertig

- Produktkonzept (`konzept.md`)
- Tech-Stack ([ADR-0001](../decisions/0001-tech-stack.md))
- Architekturregel Kampflogik/Flame ([ADR-0002](../decisions/0002-kampflogik-ohne-flame.md))
- Kampflogik als eigenes Package ([ADR-0003](../decisions/0003-combat-als-eigenes-package.md))
- **`packages/combat`** — reine Dart-Kampflogik, 23 Tests grün, Analyzer sauber:
  - 4 Move-Slots gemäß Konzept (erzeugen / verbrauchen / schwächen / stützen)
  - Timed Hits mit Deckel, Energie, Gift, Verteidigungssenkung, Heilung, Schild
  - Vollständiges Event-Vokabular als Naht zu Flame
  - Deterministisch per Seed → Balance-Simulation möglich
- **`packages/combat/example/play.dart`** — spielbarer Kampf im Terminal.
- **`packages/combat/example/balance_sim.dart`** — 2000 Kämpfe in 0,4 s
- **`packages/theory`** — Skillbaum, Inhalte und Lernfortschritt, reines Dart,
  43 Tests grün ([ADR-0004](../decisions/0004-theorie-als-eigenes-package.md)):
  - **17 Lektionen in 5 Zweigen**, jede mit 3 Abschnitten und 3 Fragen
    ([ADR-0007](../decisions/0007-theorie-als-skillbaum.md)):
    Gewohnheiten (5, offen) · Körper (3, ab Level 2) · Geist (3, ab 3) ·
    Wissenschaft (3, ab 4) · Gesellschaft (3, ab 5)
  - Zweige öffnet das **Charakterlevel**, Lektionen die Reihenfolge im Zweig
  - Bestehensgrenze 60 %; XP und Gold nur einmal je Lektion, ein besserer
    zweiter Versuch zahlt die Differenz, ein schlechterer nimmt nichts weg
  - Elf Lektionen schalten je eine Habit-Vorlage frei
    (`Lesson.unlocksHabit`)
  - `content_test.dart` prüft **Inhalt**, nicht Code, und läuft über den
    ganzen Baum: eindeutige Ids, gültige `correctIndex`, keine doppelten
    Antworten, Erklärung überall da. Ein neuer Zweig wird automatisch mitgeprüft
- **`packages/progression`** — Levelkurve, reines Dart, 11 Tests grün
  ([ADR-0006](../decisions/0006-levelkurve-als-eigenes-package.md)):
  linear steigend (Stufe 2 kostet 100 XP, jede weitere 25 mehr), Maximum 50
- **`packages/habits`** — Gewohnheiten, Streaks und Charakterwerte, reines
  Dart, 52 Tests grün
  ([ADR-0008](../decisions/0008-gewohnheiten-als-eigenes-package.md)):
  - **11 Vorlagen**, jede mit einem Charakterwert, einem Zweig und einer
    Begründung; jede kommt aus genau einer Lektion
  - Vier Werte, die den Kampf speisen: Stärke → Angriff, Ausdauer → HP,
    Disziplin → Verteidigung, Klarheit → Energie
  - Streak-Multiplikator mit Meilensteinen bei 3/7/14/30/60 Tagen, gedeckelt
    bei **x2** wie im Konzept empfohlen. Gold folgt dem Streak bewusst nicht
  - Höchstens **fünf** Gewohnheiten gleichzeitig — sonst hakt man alles an
    und nichts ab
  - Erfahrung und Gold werden aus der Historie **abgeleitet**, nicht gezählt.
    Ein Häkchen zurücknehmen nimmt auch den Ertrag zurück, ohne zweite
    Rechnung
  - Eigener `Day`-Typ statt `DateTime` — siehe `gotchas.md`
  - `example/curve_sim.dart` spielt 90 Tage in drei Verhaltensmustern durch
- **Flutter-App** (`lib/`) — 54 Tests grün, Web-Build läuft:
  - **Startbildschirm** mit allen fünf Bereichen des Konzepts, drei davon
    sichtbar gesperrt; Level, XP-Balken und Gold im Kopf
  - **Skillbaum**: alle fünf Zweige, gesperrte nennen ihre Stufe („ab Level 3")
    und den nächsten Zweig als Ziel
  - **Theorie**: Zweig-Übersicht mit Fortschrittsbalken und Lektionssperren,
    Lektionsbildschirm lesen → Fragen einzeln → Ergebnis
  - **Gewohnheiten**: Werte-Zeile, Tagesliste zum Abhaken mit Streak und
    Multiplikator, freigeschaltete Vorlagen mit ihrer Begründung. Ohne
    bestandene Lektion weist der Bildschirm zum Skillbaum statt leer zu sein
  - **Kampf**: Flame-Darstellung, Statusleisten, Move-Buttons, Log, Timing-Leiste
  - `lib/ui/palette.dart` hält die Farben, `combat_controller.dart`,
    `theory_controller.dart`, `habits_controller.dart` und
    `level_provider.dart` reichen nur durch und enthalten keine Regeln
  - `test/progression_test.dart` prüft, was kein Package allein kann: dass
    Belohnungs-, Habit- und Levelkurve zusammen keinen Sackgassen-Baum
    ergeben und das Tempo im Korridor bleibt
  - `test/habits_theory_test.dart` prüft die Naht zwischen Skillbaum und
    Vorlagen in beide Richtungen

## Bekannte Lücke: nichts überlebt einen Neustart — jetzt dringend

`TheoryController` und `HabitsController` halten alles im Speicher. Wer die
Seite neu lädt, fängt bei null an. Bei der Theorie war das verschmerzbar
(Lektionen kann man wiederlesen). Bei Gewohnheiten ist es das nicht: **Eine
Streak, die einen Neuladen nicht übersteht, ist keine Streak.** Damit ist
Drift von „als Nächstes" zu „blockiert das Feature" geworden.

Gut daran: Das Datenmodell steht jetzt vollständig, und es war der Grund,
warum das Schema in einem Stück entstehen sollte. Zu persistieren sind
Theorie-Fortschritt (`LessonRecord` je Lektions-Id), laufende Gewohnheiten
(geordnete Id-Liste) und die Häkchen (Id + Tag, `Day.toString()` ist bereits
ein brauchbarer Schlüssel). Erfahrung, Gold und Charakterwerte gehören
**nicht** in die Datenbank — sie werden abgeleitet (ADR-0008).

## Größte offene Frage: die Kampfbalance trägt noch nicht

Die Simulation hat ein Problem sichtbar gemacht, das im Konzept nicht absehbar war.
Gegner mit 18 ATK / 10 DEF, Held mit gleicher Verteidigung:

| Angriff des Helden | Siegquote |
|---|---|
| 12 | 0,0 % |
| 14 | 6,7 % |
| **16** | **52,8 %** |
| 18 | 97,4 % |
| 20 | 100 % |

**Das umkämpfte Band ist ganze zwei Angriffspunkte breit.** Darunter ist der Kampf
unmöglich, darüber geschenkt. Ein Spieler landet fast nie im spannenden Bereich.

Und der Timed-Hit-Deckel wirkt nicht wie gedacht. Bei identischem Angriffswert (18):

| Timing | Siegquote |
|---|---|
| nie getroffen | 55,6 % |
| immer perfekt | 100 % |

Die +50 % sind also kein Bonus am Rand, sondern entscheiden den Kampf allein.
Das widerspricht der Kernaussage des Konzepts („Habits sind der Hauptfaktor").

**Ursache** ist strukturell, kein Bug: Bei ~120 HP und ~18 Schaden dauert ein Kampf
nur etwa 7 Treffer. Über so wenige Runden schlägt jeder Multiplikator voll durch,
und Zufall mittelt sich nicht aus.

**Ansatzpunkte** (noch nicht entschieden):
1. HP deutlich erhöhen relativ zum Schaden → längere Kämpfe dämpfen Multiplikatoren
2. Timed-Hit-Deckel unter +50 % senken
3. Verteidigung stärker wirken lassen (`defenseSoftening` senken)

Alle drei sind eine Zeile in `packages/combat/lib/src/balance.dart` und danach ein
Simulationslauf. Genau dafür wurde das gebaut.

**Neu seit ADR-0008: Die Frage ist nicht mehr theoretisch.** Der Angriffswert
steht nicht mehr fest auf 16, sondern kommt aus den Gewohnheiten und wandert
von 13 nach 20 — quer durch das ganze Band. Ein frischer Spieler steht bei 13
und kann den Gegner nicht schlagen; das ist gewollt, aber nur solange der Weg
nach oben sich nicht wie eine Wand anfühlt. Die Stat-Kurve wurde deshalb
bewusst eng gehalten (alle vier Werte wachsen, nicht nur der Angriff), sie ist
aber ein Provisorium, bis die Balance geklärt ist. **Wer die Kampfbalance
anfasst, muss `packages/habits/lib/src/rewards.dart` mit anfassen.**

## Zweite offene Frage: die Werte stehen nach einem Monat am Deckel

`dart run example/curve_sim.dart` im Habits-Package, 90 Tage, fünf
Gewohnheiten:

| Verhalten | Tag 7 | Tag 30 | Tag 90 |
|---|---|---|---|
| jeden Tag alle fünf | ATK 14 · HP 105 | ATK 19 · HP 135 | ATK 20 · HP 140 |
| fünf von sieben Tagen | ATK 14 · HP 105 | ATK 17 · HP 125 | ATK 20 · HP 140 |
| jeden zweiten Tag | ATK 13 · HP 100 | ATK 16 · HP 115 | ATK 20 · HP 140 |

Nach etwa einem Monat sind alle vier Werte am Maximum. Danach bringen
Gewohnheiten nur noch Erfahrung und Gold — der Charakter wird nicht mehr
stärker. Für den MVP ist das vertretbar (er soll beantworten, ob man am
nächsten Tag wiederkommt, nicht ob man im vierten Monat noch dabei ist), aber
es heißt: **Der Langzeit-Anreiz hängt an Ausrüstung und Dungeon**, und beide
gibt es noch nicht. Die Alternative — Deckel anheben — geht erst, wenn klar
ist, wie breit das umkämpfte Band wirklich sein soll.

## Als Nächstes

1. **Drift-Schema** für Theorie-Fortschritt, laufende Gewohnheiten und
   Häkchen — in einem Stück, siehe Lücke oben. Ist jetzt der Blocker: eine
   Streak ohne Persistenz ist keine.
2. **Balance-Frage klären** — Kampf und Stat-Kurve zusammen, siehe oben.
   Beides sind Zeilen in `balance.dart` und `rewards.dart` plus je ein
   Simulationslauf.
3. **Charakter-Bildschirm** — die Kachel ist noch gesperrt, die Werte gibt es
   inzwischen. `CharacterStats` liefert bereits alles Nötige.
4. **Shop und Ausrüstung** — der einzige Gold-Abfluss fehlt noch komplett,
   und ohne ihn hat Gold keinen Zweck.
5. **Offene Konzeptpunkte 2–3** (Gold-Abflüsse, Niederlagen-Regel). Punkt 1
   (Streak-Deckel) ist mit ADR-0008 entschieden, Punkt 4 (erster
   Theoriezweig) mit ADR-0005/0007.

Bei der Theorie gilt ab jetzt: **einen Zweig zu Ende bringen, bevor ein
sechster dazukommt.** Vier angefangene Zweige sind schon einer zu viel für die
Warnung im Konzept — die Begründung dafür steht in ADR-0007.

Später, kein MVP-Blocker: Rive-Animationen statt der Rechtecke in `battle_game.dart`,
Dungeon mit 4 Gegnern und Boss, Shop.

## Aufgabenteilung

Noch nicht festgelegt. Es gibt jetzt vier saubere Nähte: `packages/combat` gibt
`CombatEvent`s aus, die Flame abspielt — `packages/theory` liefert Inhalte, die
die Screens nur anzeigen — `packages/progression` liefert die Levelkurve —
`packages/habits` liefert Streaks und Charakterwerte. Damit lässt sich parallel
arbeiten, ohne sich zu blockieren: Logik/Balance, Darstellung, Inhalte,
Persistenz.

## Verlauf

- **12.08.2026, abends** — Gewohnheiten gebaut und damit den Kern-Loop
  geschlossen (ADR-0008): fünftes Package mit Vorlagen-Katalog, Streaks,
  Belohnungs- und Stat-Kurve, dazu der Tracker-Bildschirm. Erfahrung und Gold
  kommen jetzt aus Theorie **und** Gewohnheiten, die Kampfwerte des Helden
  ebenfalls. Die Kurven-Simulation hat den Stat-Deckel nach einem Monat
  sichtbar gemacht.
- **12.08.2026, nachmittags** — Theorie zum Skillbaum ausgebaut: vier neue
  Zweige (Körper, Geist, Wissenschaft, Gesellschaft) mit je drei Lektionen,
  freigeschaltet über das Charakterlevel (ADR-0007). Dafür eine Levelkurve als
  viertes Package angelegt (ADR-0006). Insgesamt 17 Lektionen und 51 Fragen.
- **12.08.2026, vormittags** — Startbildschirm gebaut, alle Bereiche des
  Konzepts sichtbar gemacht. Ersten Theoriezweig gewählt und geschrieben
  (5 Lektionen, 15 Fragen), Fortschritts- und Belohnungslogik als eigenes
  Package (ADR-0004, ADR-0005). Farben in `lib/ui/palette.dart`
  zusammengezogen.
- **11.08.2026** — Konzept in vier Fragerunden erarbeitet. Repo `Prozesstek/LifesGame`
  aufgesetzt, Gedächtnis-Struktur und geteilte ECC-Werkzeuge eingecheckt.
  Kampflogik implementiert und getestet, Balance-Simulation gebaut, erste
  Balance-Schwäche gefunden. Flutter-App mit spielbarem Kampfbildschirm.
