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
- Level, Gold, Stats
- 6 Ausrüstungs-Slots (Waffe, Rüstung, …)
- 4 aktive Fähigkeiten

**Levelkurve:** linear steigend — Stufe 2 kostet 100 Erfahrung, jede
weitere 25 mehr als die vorige. Bewusst nicht exponentiell: Fortschritt
kommt aus echten Gewohnheiten und lässt sich nicht grinden, deshalb dürfen
späte Stufen nicht unerreichbar werden
([ADR-0006](docs/decisions/0006-levelkurve-als-eigenes-package.md)).
Das Level öffnet die Zweige des Skilltrees (3.3).

**Empfehlung:** Ausrüstung sollte Ressourcen beeinflussen, nicht nur
Zahlen erhöhen. Ein Ring, der Energie schneller füllt, erzeugt eine
Entscheidung. „+3 Angriff" nicht.

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
Text plus Multiple-Choice-Fragen, mehrere Zweige, verknüpft mit
Habit-Vorlagen. Ein Zweig ist eine geordnete Folge von Lektionen;
Lektion n+1 öffnet sich mit bestandener Lektion n.

**Der Baum** besteht aus einem Wurzelzweig und vier Themenzweigen. Die
Themenzweige öffnen sich über das **Charakterlevel**, nicht über gelesene
Lektionen — so belohnt der Baum alles, was Erfahrung bringt, und nicht nur
Lesen ([ADR-0007](docs/decisions/0007-theorie-als-skillbaum.md)):

| Zweig | Ab Level | Inhalt |
|---|---|---|
| Gewohnheiten | offen | wie Verhalten entsteht und abreißt — erklärt zugleich die App |
| Körper | 2 | Schlaf, Bewegung, Essen |
| Geist | 3 | Aufmerksamkeit, Gedanken, Impulse |
| Wissenschaft | 4 | Belege prüfen, Selbstversuche |
| Gesellschaft | 5 | Umfeld, Zugehörigkeit, Grenzen |

> **Größtes Projektrisiko — und es ist kein technisches.**
> Jeder Zweig kostet Wochen an Schreibarbeit. Die ursprüngliche Empfehlung
> lautete: mit **einem** Zweig starten, ihn komplett fertigstellen. Anders
> entschieden — es liegen jetzt vier angefangene Zweige mit je drei
> Lektionen vor. Das Risiko bleibt bestehen: Wer weiterarbeitet, sollte
> einen Zweig zu Ende bringen, bevor ein sechster dazukommt.

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
Tag berechenbar, worauf die Levelkurve angewiesen ist.

### 3.8 Errungenschaften
Offen.

---

## 4. Ausrüstungsquellen — Rollen trennen

| Quelle | Charakter | Rolle |
|--------|-----------|-------|
| Shop | verlässlich, planbar | Grundversorgung, Mittelmaß |
| Drops | zufällig | Aufregung, Varianz |
| Theorie-Meilensteine | einzigartig, unverkäuflich | Prestige |

---

## 5. Tech-Stack

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
