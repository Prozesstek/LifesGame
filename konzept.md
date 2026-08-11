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

**Empfehlung:** Ausrüstung sollte Ressourcen beeinflussen, nicht nur
Zahlen erhöhen. Ein Ring, der Energie schneller füllt, erzeugt eine
Entscheidung. „+3 Angriff" nicht.

### 3.2 Kampfsystem
Rundenbasiert, 4 Moves, keine Typen-Effektivität. Timed Hits als
Skill-Element (Tap im richtigen Moment → Schadensbonus, gedeckelt bei
etwa +50 %, damit Habits der Hauptfaktor bleiben).

Vorgeschlagene Move-Archetypen mit kleiner Energieleiste:

| Slot | Rolle | Energie |
|------|-------|---------|
| 1 | Basisangriff | erzeugt |
| 2 | Starker Angriff | verbraucht viel |
| 3 | Debuff (Gift, Verteidigung senken) | mittel |
| 4 | Utility (Heilung, Schild) | mittel |

### 3.3 Theorie / Skilltree
Text plus Multiple-Choice-Fragen, mehrere Zweige, verknüpft mit
Habit-Vorlagen.

> **Größtes Projektrisiko — und es ist kein technisches.**
> Jeder Zweig kostet Wochen an Schreibarbeit. Mit **einem** Zweig
> starten, ihn komplett fertigstellen, Architektur für weitere offen
> halten.

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
Ausrüstung, Dungeon-Zugänge.

**Fehlend, dringend empfohlen:** Tränke, Wiederbelebung, Streak-Schutz.

### 3.6 Gegner
Offen. Braucht: Move-Set, Stats, Drop-Tabelle, Timing-Muster für die
Timed Hits.

### 3.7 Habits (= Daily Quests)
Aus Vorlagen wählbar, jede Vorlage fest verknüpft mit Stats und einem
Theoriezweig.

**Streak-System:** Streaks erzeugen XP-Multiplikatoren, die bei
Meilensteinen steigen. Verpasste Habits werden nicht bestraft — der
Bonus fehlt einfach.

> **Empfehlung:** Multiplikator bei etwa x2 deckeln. Bei x3 wird der
> Verlust einer langen Streak so schmerzhaft, dass Nutzer aufgeben
> statt neu anzufangen.

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

1. Multiplikator-Deckel und Streak-Meilenstein-Kurve festlegen
2. Gold-Abflüsse erweitern (Tränke, Wiederbelebung, Streak-Schutz)
3. Niederlagen-Regel entschärfen
4. Ersten Theoriezweig auswählen
5. Errungenschaften definieren
6. Gegner-Design: Move-Sets und Drop-Tabellen
7. Timed-Hit-Fenster in Millisekunden festlegen
8. Onboarding: erste Sitzung bis zum ersten Kampf

---

## 7. Vorschlag MVP-Schnitt

**Drin:** Habits aus Vorlagen · Streaks · Stats · 1 Theoriezweig ·
Kampf mit 4 Moves und Timed Hits · 1 Dungeon · Shop mit Ausrüstung und
Tränken

**Raus für später:** mehrere Theoriezweige · Errungenschaften ·
Drop-Tabellen · Kosmetik · Cloud-Sync

Ziel des MVP: Beantwortet die Frage, ob sich der Kampf gut genug
anfühlt, um am nächsten Tag wieder Habits abzuhaken. Alles andere ist
Ausbau.
