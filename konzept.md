# Habit-RPG — Konzeptstand

Stand: 11.08.2026 · zusammengefasst aus vier Fragerunden

---

## 1. Kernidee

Ein Habit-Tracker, dessen Fortschritt sich in einem rundenbasierten RPG
auszahlt. Was der Nutzer im echten Leben tut, bestimmt, wie stark sein
Charakter ist. Theorie-Inhalte zur Selbstverbesserung sind fest in den
Fortschritt eingebaut, nicht danebengestellt.

**Fortschrittsquellen:** 50 % Habits · 30 % Theorie · 20 % Kämpfe

> **Offene Empfehlung:** Kämpfe sollten kein Level geben, sondern Gold
> und Items. Sonst kann man den Habit-Teil umgehen, indem man grindet.
> Habits und Theorie = Einnahme, Kämpfe = Ausgabe.

---

## 2. Kern-Loop

```
Habit abhaken  ─┐
Theorie lernen ─┼──► Stats + Gold ──► Ausrüstung ──► Dungeon ──► Drops ─┐
                │                                                       │
                └───────────────────────────────────────────────────────┘
```

Tägliche Sitzung: 1–2 Minuten Abhaken, optional 3–5 Minuten Theorie,
optional 8–12 Minuten Dungeon.

---

## 3. Systeme

### 3.1 Charakter

Der Charakterbildschirm ist die **Kommandozentrale**
([ADR-0013](docs/decisions/0013-charakter-als-kommandozentrale.md)). Die
Trennung zum Startbildschirm ist inhaltlich: Start zeigt **was ich tue**,
Charakter zeigt **wer ich bin**.

- Name und verdienter Titel, Level, Gold, offene Punkte
- 4 Charakterwerte, jeweils mit Herkunft (Alltag / Ausrüstung)
- **4 Fähigkeitsslots** — drei frei wählbar, einer von der getragenen Waffe
  bestimmt; offen ab Level 3 / 6 / 10
- 6 Ausrüstungs-Slots (Waffe, Rüstung, Helm, Schuhe, Ring, Talisman)
- Wege zu Errungenschaften, Streaks, Freunden und in den Laden

> **Es gibt keine Klassenwahl, und es wird nie eine geben.**
> Jeder formt seinen Charakter durch seinen persönlichen Stil. Eine Klasse,
> die man in der ersten Minute in einem Menü anklickt, gibt die Antwort,
> bevor die App ihre Frage stellen konnte. Wo eine Klasse sichtbar werden
> soll, wird sie aus dem tatsächlichen Verhalten **abgeleitet**.

**Fähigkeiten:** 20 Stück. Sie kommen aus dem Theoriebaum (einen Knoten
**abschließen**, nicht öffnen), aus Streak-Marken bei 7 / 14 / 30 / 60 Tagen
und aus Waffen; später zusätzlich aus Errungenschaften. Einmal verdient
heißt behalten — auch wenn die Streak reißt (siehe 3.7). Fähigkeitspunkte
kommen auf jedem dritten Levelaufstieg und sind gegen Gold umverteilbar.

**Identität:** Name und Titel jetzt, Aussehen später. Der Titel ist der
kürzeste Weg zwischen dem, was jemand tut, und dem, was sein Charakter ist.

**Levelkurve:** linear steigend — Stufe 2 kostet 100 Erfahrung, jede
weitere 25 mehr als die vorige. Bewusst nicht exponentiell: Fortschritt
kommt aus echten Gewohnheiten und lässt sich nicht grinden, deshalb dürfen
späte Stufen nicht unerreichbar werden
([ADR-0006](docs/decisions/0006-levelkurve-als-eigenes-package.md)).
Jeder Aufstieg gibt einen Theoriepunkt, jeder dritte zusätzlich einen
Fähigkeitspunkt (3.3).

**Empfehlung:** Ausrüstung sollte Ressourcen beeinflussen, nicht nur
Zahlen erhöhen. Ein Ring, der Energie schneller füllt, erzeugt eine
Entscheidung. „+3 Angriff" nicht.

> Zweimal übernommen: Energie sitzt auf Ring und Talisman (3.5), und die
> **Waffe bestimmt den vierten Fähigkeitsslot**. Damit ist eine Waffe kein
> Zahlenaufschlag mehr, sondern ein Spielstil — und es lohnt sich, mehrere
> zu besitzen und zu wechseln.

### 3.2 Kampfsystem
Rundenbasiert, 4 Moves, keine Typen-Effektivität. Timed Hits als
Skill-Element: Tap im richtigen Moment → Schadensbonus, gedeckelt bei
**+20 %**.

> Ursprünglich waren +50 % vorgesehen. Die Simulation zeigte, dass das den
> Kampf allein entscheidet — bei gleichen Werten 56 % Siegquote ohne Timing
> gegen 100 % mit perfektem. Gesenkt mit
> [ADR-0009](docs/decisions/0009-kampfbalance-ueber-gegnerreihe.md).

**Gegner sind eine Reihe, kein einzelner.** Drei Stufen, jede an einem
anderen Punkt des Gewohnheits-Pfads knapp. Der Grund ist grundsätzlich: Ein
Kampf mit beidseitig festen Werten ist ein Rennen und kippt scharf von
„unmöglich" auf „geschenkt". Ein breites Band spannender Kämpfe lässt sich
deshalb nicht in einen Gegner einstellen — es entsteht nur aus mehreren.

Vorgeschlagene Move-Archetypen mit kleiner Energieleiste:

| Slot | Rolle | Energie |
|------|-------|---------|
| 1 | Basisangriff | erzeugt |
| 2 | Starker Angriff | verbraucht viel |
| 3 | Debuff (Gift, Verteidigung senken) | mittel |
| 4 | Utility (Heilung, Schild) | mittel |

### 3.3 Theorie / Skilltree
Text plus Multiple-Choice-Fragen, verknüpft mit Habit-Vorlagen. Innerhalb
eines Knotens ist die Reihenfolge der Lektionen verbindlich: Lektion n+1
öffnet sich mit bestandener Lektion n.

**Der Baum ist ein echter Baum** mit zwei Wurzeln und beliebiger Tiefe. Er
wird nach unten hin immer spezieller. Knoten öffnen sich über
**Theoriepunkte**, die es bei jedem Levelaufstieg gibt — ein Punkt, ein
Knoten, unabhängig von der Tiefe
([ADR-0012](docs/decisions/0012-theoriebaum-ueber-punkte.md)):

```
Gewohnheiten  (frei — das Handbuch der App)

Körper                          Geist
├── Sport                       ├── Aufmerksamkeit
├── Ernährung                   ├── Psychologie
├── Schlaf                      ├── Lernen
├── Substanzen                  ├── Entscheidungen
├── Erholung                    ├── Soziales
└── Haltung                     ├── Wissenschaft
                                └── Sinn & Werte ── Ideengeschichte
```

Ein Knoten ist ein **Thema mit Lektionen**, keine Einzellektion; innerhalb
bleibt die Reihenfolge verbindlich. Ein Knoten braucht seinen Elternknoten.
Ein Knoten erscheint erst, wenn sein Inhalt geschrieben ist.

**Ein Knoten verdient seinen Platz nur**, wenn er drei Lektionen trägt,
mindestens eine täglich abhakbare Gewohnheit hervorbringt und auf einen der
vier Charakterwerte einzahlt. Die mittlere Bedingung ist die schärfste: Ein
Thema ohne tägliche Handlung ist ein Essay, kein Knoten.

**Was ein Levelaufstieg gibt:**

| Aufstieg | gibt |
|---|---|
| jeder | 1 Theoriepunkt |
| jeder dritte | 1 Fähigkeitspunkt |
| Level 3 / 6 / 10 | Fähigkeitsslot 2 / 3 / 4 |

> **Größtes Projektrisiko — und es ist kein technisches.**
> Der geplante Baum hat rund 45 Knoten, also etwa **150 Lektionen**. Es gibt
> heute 17. Das ist der ehrliche Maßstab des Projekts, und er liegt komplett
> auf der Schreibseite.
>
> Die Obergrenze ist hart: `maxLevel` ist 50, also gibt es über ein
> Spielerleben genau **49 Theoriepunkte** und damit nie mehr als 49 öffenbare
> Knoten.
>
> Die Regel dagegen ist die Erscheinungsregel: Ein Knoten kommt erst in den
> Baum, wenn sein Inhalt steht. Ein halber Knoten ist schlimmer als keiner —
> für ihn wurde ein Punkt bezahlt.

### 3.4 Dungeon
4 Gegner + 1 Boss, etwa 8–12 Minuten.

- **HP heilt nicht zwischen den Kämpfen** → Zermürbung erzeugt echte
  Entscheidungen (Trank jetzt oder für den Boss aufsparen?)
- Niederlage: Dungeon von vorn
- Zugang kostet Gold

> **Konflikt:** Niederlage + verfallener Eintritt bestraft doppelt, und
> man kann sich nicht hochgrinden, weil Stärke aus echten Habits kommt.
> Ohne ein Wiederbelebungs-Item wird das zur Abwärtsspirale.

### 3.5 Shop
Ausrüstung über sechs Plätze, in zwei Stufen. Gebaut, siehe
[ADR-0011](docs/decisions/0011-ausruestung-als-eigenes-package.md).

**Gold wird abgeleitet, nicht gezählt:** Zufluss aus Theorie und
Gewohnheiten minus Preis des Besitzes. Deshalb gibt es keinen Verkauf — er
bräuchte eine Verkaufshistorie und damit eine zweite Wahrheit.

Die Empfehlung, Ausrüstung solle Ressourcen beeinflussen statt nur Zahlen
(Abschnitt 3.1), ist übernommen: Energie sitzt auf Ring und Talisman, und
der Ring ist auf beiden Stufen das teuerste Stück.

**Noch offen:** Tränke, Wiederbelebung, Streak-Schutz — bewusst zusammen mit
dem Dungeon. Zwischen Einzelkämpfen sind die HP ohnehin voll; ein Trank
wäre ein Knopf ohne Situation.

### 3.6 Gegner
Offen. Braucht: Move-Set, Stats, Drop-Tabelle, Timing-Muster für die
Timed Hits.

### 3.7 Habits (= Daily Quests)
Aus Vorlagen wählbar, jede Vorlage fest verknüpft mit einem Stat und einem
Theoriezweig. Gebaut, siehe
[ADR-0008](docs/decisions/0008-gewohnheiten-als-eigenes-package.md).

**Dazu eigene Gewohnheiten**, seit dem 06.09. und
[ADR-0028](docs/decisions/0028-eigene-gewohnheiten.md). Ein Tracker, in
den man nicht schreiben kann, was man tatsächlich tut, ist keiner. Vier
Regeln halten sie im Rahmen:

- **Ein Platz je freigeschalteter Vorlage.** Der Baum bleibt der Motor —
  ohne Lektion keine eigene Gewohnheit. Aber was am Ende auf der Liste
  steht, entscheidet der Spieler.
- **Der Schwierigkeitsgrad ist eine feste, schmale Spanne** auf die
  Erfahrung (leicht ×0,8, mittel ×1,0, schwer ×1,3) und wirkt **nicht**
  auf Gold. Er wird selbst gesetzt; frei eingebbar wäre er ein Regler am
  Spielgleichgewicht.
- **Ein Tagesziel** in Menge oder Minuten füllt sich über den Tag und
  zahlt erst voll aus. Halb getan ist nicht getan — sonst wäre die Streak
  nichts mehr wert.
- **Die Priorität ordnet nur die Liste.** Sie ist ausdrücklich für die
  eigene Wertung und bewegt keine Zahl im Spiel.

Wert, Schwierigkeit und Ziel stehen mit dem Anlegen fest: Erfahrung und
Charakterwerte werden aus der Historie gerechnet, eine nachträgliche
Änderung schriebe die Vergangenheit um.

**Vier Werte**, jeder mit einer Wirkung im Kampf:

| Wert | Kampf | Beispielvorlage |
|---|---|---|
| Stärke | Angriff | Zehn Minuten am Stück gehen |
| Ausdauer | Lebenspunkte | Feste Aufstehzeit |
| Disziplin | Verteidigung | Drei Aufgaben für morgen festlegen |
| Klarheit | Energie | Fünf Minuten still sitzen |

**Streak-System:** Streaks erzeugen XP-Multiplikatoren, die bei
Meilensteinen steigen (3 / 7 / 14 / 30 / 60 Tage). Verpasste Habits werden
nicht bestraft — der Bonus fehlt einfach, und die Kette stirbt erst, wenn
der Tag vorbei ist, nicht beim Aufwachen.

Der Multiplikator ist bei **x2 gedeckelt** — die Empfehlung wurde
übernommen: Bei x3 wird der Verlust einer langen Streak so schmerzhaft, dass
Nutzer aufgeben statt neu anzufangen. **Gold folgt dem Streak bewusst
nicht**, sonst wird eine lange Kette zur Abkürzung durch den Shop.

**Höchstens fünf Gewohnheiten gleichzeitig.** Ohne Grenze hakt man alle
Vorlagen an und keine davon ab; außerdem hält die Grenze die Erfahrung pro
Tag berechenbar, worauf die Levelkurve angewiesen ist. Vorlagen und eigene
Gewohnheiten teilen sich diese fünf Plätze — anlegen und täglich verfolgen
sind zwei verschiedene Grenzen.

### 3.8 Errungenschaften
Offen. Sie sollen später eine dritte Quelle für Fähigkeiten sein (3.1) und
bekommen einen eigenen Weg von der Kommandozentrale aus. Bewusst
zurückgestellt, bis die zwanzig Fähigkeiten stehen.

### 3.9 Freunde
Offen, und der einzige geplante Teil, der einen **Server** braucht — alles
andere läuft offline (ADR-0010). Steht als Weg auf der Kommandozentrale,
ohne dass damit über Umfang oder Zeitpunkt entschieden wäre.

---

## 4. Ausrüstungsquellen — Rollen trennen

| Quelle | Charakter | Rolle |
|--------|-----------|-------|
| Shop | verlässlich, planbar | Grundversorgung, Mittelmaß |
| Drops | zufällig | Aufregung, Varianz |
| Theorie-Meilensteine | einzigartig, unverkäuflich | Prestige |

---

## 5. Tech-Stack

**Zielgerät: Handy im Hochformat.** Das ist keine Vorliebe, sondern folgt
aus dem Kern-Loop: Ein Häkchen wird im Vorbeigehen gesetzt, mit einer Hand,
mehrmals am Tag. Was man dafür erst aufklappen muss, wird nicht benutzt.

Querformat ist deshalb ausdrücklich **kein** Ziel — es wäre kein zweites
Layout, sondern ein zweites Produkt: Der Kampfbildschirm stapelt Gegner,
Log und vier Knöpfe untereinander, die Tagesliste lebt vom Scrollen. Die
App legt sich beim Start auf Hochformat fest (`lib/main.dart`).

Entwickelt wird trotzdem gegen **Chrome**, weil Android auf keinem der
beiden Rechner eingerichtet ist. Damit man das Zielformat dabei sieht,
zeigt `lib/ui/phone_frame.dart` die App im Browser in Handygröße, und
`test/phone_layout_test.dart` prüft jeden Bildschirm bei 390x844.

- **Flutter / Dart** — App-Shell, alle Tracker-Screens
- **Flame** — nur der Kampfbildschirm, als eingebettetes Widget
- **Drift (SQLite)** — lokale Daten, offline-first
- **Riverpod** — State Management
- **Rive** — Skill- und Treffer-Animationen

**Architekturregel:** Kampflogik als reines Dart ohne Flame-Imports.
Die Logik gibt nur Events aus, Flame spielt sie ab.

---

## 6. Offene Punkte

1. ~~Multiplikator-Deckel und Streak-Meilenstein-Kurve festlegen~~ —
   erledigt, siehe 3.7 und ADR-0008
2. ~~Gold-Abflüsse schaffen~~ — Ausrüstung erledigt, siehe 3.5 und ADR-0011.
   Offen bleiben Tränke, Wiederbelebung und Streak-Schutz; sie gehören zum
   Dungeon
3. Niederlagen-Regel entschärfen
4. ~~Ersten Theoriezweig auswählen~~ — erledigt, siehe 3.3 und ADR-0005/0007
5. Errungenschaften definieren
6. Gegner-Design: Move-Sets und Drop-Tabellen
7. Timed-Hit-Fenster in Millisekunden festlegen (der Deckel selbst ist mit
   ADR-0009 entschieden)
8. Onboarding: erste Sitzung bis zum ersten Kampf
9. **Die zwanzig Fähigkeiten festlegen** — Wirkung, Energiekosten,
   Aufwertungspfad, und welche an welcher Waffe hängt (3.1, ADR-0013)
10. **Titel-Katalog** — welche Titel es gibt und woran sie hängen
11. **Inhalt für die neuen Baumknoten** — der Engpass des Projekts, siehe
    den Risikokasten in 3.3

---

## 7. Vorschlag MVP-Schnitt

**Drin:** Habits aus Vorlagen · Streaks · Stats · 1 Theoriezweig ·
Kampf mit 4 Moves und Timed Hits · 1 Dungeon · Shop mit Ausrüstung und
Tränken

**Stand 17.08.2026:** alles davon gebaut außer dem Dungeon — und damit außer
den Tränken, die ohne ihn wirkungslos wären. Statt einem Theoriezweig gibt es
fünf (ADR-0007), statt einem Gegner drei (ADR-0009).

**Raus für später:** mehrere Theoriezweige · Errungenschaften ·
Drop-Tabellen · Kosmetik · Cloud-Sync

Ziel des MVP: Beantwortet die Frage, ob sich der Kampf gut genug
anfühlt, um am nächsten Tag wieder Habits abzuhaken. Alles andere ist
Ausbau.
