# ADR-0012: Der Theoriebaum wird ein echter Baum und öffnet sich über Theoriepunkte

**Datum:** 18.08.2026
**Status:** Teilweise abgelöst durch ADR-0019
**Entschieden von:** Frederik

> **Was ADR-0019 ändert:** vier Wurzeln statt zwei, zwei Theoriepunkte je
> Level statt einem, ein Knoten ist eine Seite mit drei Fragen statt eines
> Themas mit Lektionen, vier Fähigkeiten aus dem Baum statt acht.
> **Was hier gültig bleibt:** beliebige Tiefe, Punkte statt Levelsperren,
> ein Punkt je Knoten unabhängig von der Tiefe, das freie Handbuch, keine
> Klassenwahl.

## Kontext

Der MVP steht bis auf den Dungeon. Beim Durchgehen des Charakterkonzepts fielen
drei Dinge zusammen auf:

**Das Level war ab Stufe 5 folgenlos.** Es öffnete die Theoriezweige (ADR-0007),
und das war seine einzige Aufgabe. Der letzte Zweig hing an Level 5, erreicht
etwa am siebten Tag. Jeder weitere Aufstieg war ein Zahlenwechsel ohne Wirkung —
ausgerechnet beim prominentesten Wert auf dem Charakterbildschirm.

**Der Baum war kein Baum.** Fünf gleichrangige Zweige nebeneinander, jeder eine
geordnete Liste. Es gab nichts zu entscheiden: Wer levelt, bekommt alles, nur in
festgelegter Reihenfolge.

**Der Charakterbildschirm soll eine Kommandozentrale werden** — Werte, Level,
Ausrüstung, Fähigkeitsslots, später Errungenschaften und Streaks. Damit braucht
das Level etwas, das es dort auszuteilen hat.

## Entscheidung

**1. Die Theorie wird ein echter Baum mit beliebiger Tiefe.** Zwei Wurzeln,
Körper und Geist. Jeder Knoten kennt seine Kinder; nichts im Code kennt die
Tiefe. Ein neuer Knoten ist eine Datei plus ein Eintrag beim Elternknoten.

**2. Ein Knoten ist ein Thema mit Lektionen**, keine Einzellektion. Ihn zu
öffnen kostet **einen Theoriepunkt** — unabhängig von der Tiefe. Innerhalb des
Knotens bleibt die Reihenfolge der Lektionen verbindlich. Ein Knoten braucht
seinen Elternknoten.

**3. Ein Levelaufstieg gibt:**

| Aufstieg | gibt |
|---|---|
| jeder | 1 Theoriepunkt |
| jeder dritte (3, 6, 9, …) | 1 Fähigkeitspunkt |
| Level 3 / 6 / 10 | Fähigkeitsslot 2 / 3 / 4 |

**4. Die Levelsperren an den Zweigen entfallen.** Der Punkt ersetzt sie. Wer
will, geht ab dem dritten Tag tief in Körper statt breit in alles.

**5. „Gewohnheiten" bleibt frei** und kostet keinen Punkt. Der Zweig erklärt,
wie die App funktioniert (ADR-0005) — das Handbuch gehört nicht hinter eine
Sperre.

**6. Ein Knoten erscheint erst im Baum, wenn sein Inhalt geschrieben ist.**

## Der Baum

```
Gewohnheiten  (frei, das Handbuch der App)

Körper
├── Sport ───────── Kraft · Ausdauer · Beweglichkeit
├── Ernährung ───── Was · Wann · Trinken
├── Schlaf ──────── Rhythmus · Abendroutine
├── Substanzen ──── Koffein · Alkohol
├── Erholung ────── Stress · Pausen
└── Haltung ─────── Rücken · Mobilität

Geist
├── Aufmerksamkeit ── Digitale Hygiene · Tiefe Arbeit
├── Psychologie ───── Emotionen · Impulse und Sucht
├── Lernen ────────── Gedächtnis · Lesen
├── Entscheidungen ── Denkfehler · Planen
├── Soziales ──────── Beziehungen · Konflikt
├── Wissenschaft ──── Selbstversuche
└── Sinn & Werte ──── Ideengeschichte · Rückblick
```

Etwa 45 Knoten. Wo der vorhandene Inhalt landet:

| Knoten | vorhandene Lektion |
|---|---|
| Sport | „Die kleinste Dosis, die wirkt" |
| Ernährung | „Essen ist ein Umgebungsproblem" |
| Schlaf | „Schlaf ist keine verlorene Zeit" |
| Aufmerksamkeit | „Aufmerksamkeit ist die eigentliche Währung" |
| Psychologie | „Gedanken sind keine Tatsachen", „Unbehagen aushalten" |
| Soziales | alle drei aus „Gesellschaft" — **fertig** |
| Wissenschaft | alle drei — **fertig** |
| Lernen | — (Vorlage „Zwei Minuten lesen" wartet dort) |
| Entscheidungen | — (Vorlage „Drei Aufgaben für morgen" wartet dort) |
| Sinn & Werte | — (Vorlage „Abendnotiz" wartet dort) |

## Begründung

**Warum Punkte statt Levelsperren.** Eine Sperre gibt eine Reihenfolge vor, ein
Punkt erzwingt eine Wahl. Und diese Wahl hat bereits mechanisches Gewicht, ohne
dass wir etwas dafür bauen müssten: **11 der 17 Lektionen schalten je eine
Habit-Vorlage frei, und es dürfen nur fünf Gewohnheiten gleichzeitig laufen.**
„Welchen Weg gehe ich im Baum" heißt damit automatisch „welches Werkzeug bekomme
ich für den Alltag".

**Warum ein flacher Preis statt Preis nach Tiefe.** Der erste Entwurf sah teurere
Knoten in größerer Tiefe vor. Verworfen, weil die Levelkurve bereits bremst — bei
150 XP am Tag kostet ein Punkt auf Level 10 zwei Tage, auf Level 20 vier, auf
Level 40 sieben. Ein Aufschlag nach Tiefe wäre eine zweite Bremse auf dieselbe
Sache gewesen.

Die Folge ist wichtig: **Nicht der Preis begrenzt den Baum, sondern seine
Größe.** Er ist genau so lange interessant, wie er ungeöffnete Knoten hat.

**Warum ein Knoten ein Thema ist und keine Lektion.** Auf Lektionsebene wäre
jeder Punkt eine Mikroentscheidung, und ein Spieler müsste für dieselbe Lektion
zweimal bezahlen — einmal mit dem Punkt, einmal mit dem Bestehen. Auf Themenebene
ist der Punkt eine Richtungsentscheidung, und drinnen liest man frei.

**Warum diese Knoten und nicht andere.** Ein Knoten verdient seinen Platz, wenn
er drei Lektionen trägt, ohne den Nachbarn zu wiederholen, **mindestens eine
täglich abhakbare Gewohnheit hervorbringt** und auf einen der vier Charakterwerte
einzahlt. Die zweite Bedingung ist die schärfste: Ein Thema ohne tägliche
Handlung ist ein Essay, kein Knoten.

**Warum der Ausbau von Körper dringender ist als der von Geist.** Die elf
Vorlagen verteilen sich heute so:

| Wert | Kampfwirkung | Vorlagen |
|---|---|---|
| Klarheit | Energie | 4 |
| Disziplin | Verteidigung | 3 |
| Ausdauer | Lebenspunkte | 2 |
| Stärke | Angriff | 2 |

Die beiden Werte, die den Kampf am direktesten entscheiden, haben die wenigsten
Quellen — und beide hängen an Körper. Sport, Ernährung, Erholung und Haltung
reparieren damit nicht nur den Baum, sondern eine Schieflage im Kern-Loop.

**Warum Ideengeschichte unter Sinn & Werte hängt und kein eigener Hauptast ist.**
Sie ist der einzige geplante Knoten ohne eigene Gewohnheit und verletzt damit die
zweite Bedingung. Als Vertiefung für die, die schon drin sind, trägt sie
trotzdem — als Einstiegsast wäre sie ein Essay am Anfang des Wegs.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Levelsperren beibehalten (ADR-0007) | Ab Level 5 folgenlos, und der Baum bietet keine Entscheidung |
| Preis steigt mit der Tiefe | Doppelte Bremse — die Levelkurve verlangsamt sich bereits von selbst |
| Punkte auf Lektionsebene statt Themenebene | Zweimal bezahlen für dieselbe Lektion; Mikroentscheidungen statt Richtung |
| Punkte reichlich vergeben (2 je Aufstieg) | Macht aus der Wahl wieder eine Reihenfolge |
| Fünf flache Zweige lassen und nur inhaltlich ausbauen | Der Inhalt hatte die Aufspaltung längst vorweggenommen — Körpers drei Lektionen sind Schlaf, Sport und Ernährung |
| „Geschichte" als eigener Hauptast | Keine tägliche Handlung; als Ideengeschichte unter Sinn & Werte stärker |

## Konsequenzen

**Leichter:** Das Level hat wieder eine Aufgabe, und zwar dauerhaft statt bis
Stufe 5. Der Baum wächst durch Anhängen, nicht durch Umbauen. Übrige Punkte
sammeln sich an — wenn ein neuer Knoten erscheint, können alle ihn sofort öffnen.
Das macht aus dem Nachliefern von Inhalt ein Ereignis statt einer Bringschuld.

**Schwerer, und das ist der ernste Teil:** Der Engpass ist jetzt vollständig die
Schreibarbeit. Zwei Zahlen dazu:

- **Der Baum hat eine harte Obergrenze von 49 Knoten.** `maxLevel` ist 50, also
  gibt es über ein Spielerleben genau 49 Theoriepunkte. Mehr kann niemand öffnen,
  solange Punkte nur aus Leveln kommen.
- **Ein Baum dieser Größe heißt rund 150 Lektionen.** Es gibt heute 17.

Das ist der ehrliche Maßstab des Projekts, und er liegt komplett auf der
Schreibseite. `konzept.md` nennt genau das das größte Projektrisiko und
ausdrücklich kein technisches. Diese Entscheidung vergrößert es.

**Umbau in `packages/theory`:** `SkillTree` und `TheoryBranch` werden zu einer
Knotenstruktur mit Kindern. `unlockLevel` entfällt. Die Zuordnung
Lektion → Habit-Vorlage muss den Umzug überstehen, sonst schlägt
`test/habits_theory_test.dart` fehl — sie ist die Naht zwischen zwei Packages.

**Persistenz:** Die geöffneten Knoten und die ausgegebenen Punkte sind neuer
Speicherinhalt. Geschrieben wird ausschließlich in `lib/save/save_watcher.dart`
(ADR-0010).

**Oberfläche:** `skill_tree_screen.dart` zeigt heute eine Liste von Zweigen. Ein
Baum mit Verästelung und Tiefe braucht eine andere Darstellung — das ist der
sichtbarste Teil der Arbeit und derjenige, den diese Entscheidung nicht löst.

**Ablösung:** ADR-0007 ist damit vollständig überholt.

**Offen:** Woher die Fähigkeiten kommen, die mit den Fähigkeitspunkten
aufgewertet werden, ist noch nicht entschieden. Die Punkte und Slots stehen, ihr
Inhalt nicht.
