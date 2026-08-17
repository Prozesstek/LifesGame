# ADR-0010: Persistenz hinter einem Anschluss, Drift verschoben

**Datum:** 17.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

`TheoryController` und `HabitsController` hielten alles im Speicher. Wer
die Seite neu lud, fing bei null an. Bei der Theorie war das verschmerzbar,
bei Gewohnheiten nicht: **Eine Streak, die einen Neustart nicht übersteht,
ist keine Streak.** Damit war Persistenz vom „als Nächstes" zum Blocker
geworden.

[ADR-0001](0001-tech-stack.md) hatte Drift (SQLite) als Persistenzschicht
festgelegt — vor dem ersten Datenmodell und damit auf Verdacht.

Beim Umsetzen zeigte sich, wie klein der Stand tatsächlich ist. Zu
speichern sind drei Dinge:

- Theorie-Fortschritt: je Lektion ein Datensatz aus vier Zahlen
- laufende Gewohnheiten: eine geordnete Liste von Ids
- Häkchen: je Gewohnheit eine Menge von Tagen

Erfahrung, Gold, Level und Charakterwerte gehören ausdrücklich **nicht**
dazu — sie werden abgeleitet ([ADR-0008](0008-gewohnheiten-als-eigenes-package.md)).
Es gibt keine Beziehungen, keine Abfragen, keine Sortierung, keine Migration
über Tabellen. Es gibt einen Wert.

Dazu kam ein praktischer Umstand: Entwickelt wird gegen Chrome. Drift
braucht dort zusätzlich `sqlite3.wasm` und einen Worker als Assets im
`web/`-Verzeichnis — zwei Binärdateien, die eingecheckt und mit der
Drift-Version synchron gehalten werden müssen.

## Entscheidung

Persistenz läuft über einen schmalen Anschluss: `SaveStore` mit `read()` und
`write()`, dazu `SaveData` als ein Wert für den ganzen Stand. Die erste
Implementierung ist `SharedPreferencesSaveStore` — ein JSON-String unter
einem Schlüssel.

Die Serialisierung liegt **in den Packages**, bei den Daten, denen sie
gehört: `TheoryProgress.toJson`, `HabitTracker.toJson`, `Loadout.toJson`.
Sie ist damit reines Dart und ohne Flutter testbar.

Gelesen wird **einmal vor `runApp`**. Geschrieben wird an genau einer
Stelle: `SaveWatcher` hört auf die drei Zustands-Provider.

Drift ist damit nicht abgelehnt, sondern verschoben. Kommt es, entsteht
eine zweite Implementierung von `SaveStore`, und `main.dart` wählt sie aus.

## Begründung

**Der Anschluss ist der eigentliche Inhalt der Entscheidung.** Er kostet
zwei Methoden und macht die Wahl der Technik reversibel. Ohne ihn wäre
„erst einfach, später Drift" ein Versprechen; mit ihm ist es eine
Änderung an einer Datei.

**Drift jetzt wäre Aufwand ohne Gegenwert.** Codegen, `build_runner`,
Migrationen und zwei Binär-Assets für drei Schlüssel-Wert-Paare. Der Nutzen
von SQLite — Abfragen über viele Datensätze — entsteht erst, wenn es etwas
abzufragen gibt. Beim jetzigen Stand wird ohnehin alles auf einmal gelesen.

**Serialisierung gehört ins Package**, weil sie zum Datenmodell gehört und
nicht zur Technik dahinter. Ein Round-Trip-Test läuft damit ohne Flutter,
in Millisekunden, und deckt genau den Fall ab, der sonst erst beim echten
Neustart auffällt.

**Lesen vor `runApp`** erspart jedem Bildschirm einen Ladezustand für
Daten, die längst im Speicher liegen — und vor allem das kurze Aufblitzen
eines leeren Standes, das für einen Nutzer wie verlorener Fortschritt
aussieht. Der Preis ist ein `async main`, sonst nichts.

**Schreiben an einer Stelle**, weil sonst jeder neue Bereich eine weitere
Gelegenheit mitbrächte, das Speichern zu vergessen. In `SaveWatcher.build`
stehen drei Zeilen untereinander; wer einen vierten Bereich baut, sieht
sofort, wo er ihn einträgt.

**Alle `fromJson` sind nachsichtig, nicht streng.** Unbekannte Ids und
unlesbare Tage werden übersprungen, kaputtes JSON ergibt einen leeren
Stand. Das ist keine Bequemlichkeit: Der teuerste Fehler dieser Schicht ist
verlorener Fortschritt. Ein halb lesbarer Stand ist immer besser als eine
Ausnahme beim Start. Die Gegenprobe leisten Tests, nicht Ausnahmen —
`persistence_test.dart` in `habits`, `theory`, `gear` und in der App.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Drift jetzt, wie in ADR-0001 geplant | Codegen, Migrationen und zwei wasm-Assets für einen Wert ohne Beziehungen. Der Nutzen entsteht erst mit Abfragen, die es nicht gibt. |
| `shared_preferences` direkt in den Controllern | Jeder Controller kennt dann den Speicher, und der Wechsel zu Drift fasst jeden einzeln an. Der Anschluss kostet zwei Methoden und nimmt genau das weg. |
| Eine eigene Datei über `path_provider` | Funktioniert auf Web nicht ohne Weiteres und löst kein Problem, das `shared_preferences` offen lässt. |
| Serialisierung in `lib/` statt in den Packages | Dann wären die Round-Trip-Tests Flutter-Tests, und `package:habits` könnte seinen eigenen Stand nicht prüfen. |
| Asynchron laden mit Ladezustand je Bildschirm | Ladezustände für Daten, die in Millisekunden da sind. Jeder Controller würde asynchron, jeder Test aufwendiger. |
| Strenges Parsen mit Ausnahmen | Ein Formatfehler kostet dann den gesamten Fortschritt — die schlimmste mögliche Folge in genau dieser Schicht. |

## Konsequenzen

**Leichter:**

- Der Fortschritt überlebt einen Neustart. Der Blocker ist weg.
- Die Technik ist austauschbar, ohne dass ein Controller, ein Bildschirm
  oder ein Test sich ändert.
- Round-Trip-Tests laufen ohne Flutter und decken die Nachsicht beim Laden
  ausdrücklich mit ab.
- Ein einzelner JSON-String lässt sich zum Fehlersuchen ausgeben, kopieren
  und weitergeben.

**Schwerer:**

- `main()` ist asynchron. Tests, die `LifesGameApp` direkt bauen, müssen
  `savedGameProvider` überschreiben statt sich auf `main()` zu verlassen.
- Der ganze Stand wird bei **jeder** Änderung komplett geschrieben. Bei der
  jetzigen Größe irrelevant; sobald der Stand wächst (Dungeon-Läufe,
  Historie), braucht es entweder Entprellen oder tatsächlich Drift. Das ist
  das Signal, an dem die Entscheidung neu ansteht.
- `SaveWatcher` muss im Widget-Baum hängen. Vergisst man ihn, läuft alles
  normal — nur gespeichert wird nichts. Dagegen steht ein Test
  (`test/persistence_test.dart`, „ein Häkchen landet im Speicher").
- `shared_preferences` bringt Plattform-Kanäle mit. Widget-Tests laufen
  deshalb über `InMemorySaveStore`, nicht über den echten Speicher.
