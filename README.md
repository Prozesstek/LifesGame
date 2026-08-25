# Lifes Game

Ein Habit-Tracker, dessen Fortschritt sich in einem rundenbasierten RPG auszahlt.
Was du im echten Leben tust, bestimmt, wie stark dein Charakter ist.

**Status:** Der Kern-Loop läuft und ist spielbar — Knoten öffnen, Seite lesen,
Gewohnheit freischalten, täglich abhaken, Werte steigen, Gold sammeln,
Ausrüstung kaufen, Fähigkeit lernen, nächsten Gegner schlagen. Der
Fortschritt überlebt einen Neustart.

Seit dem 24.08. ist die Theorie ein **gezeichneter Skillbaum**: vier Wurzeln
mit je fünf Knoten, geöffnet über Theoriepunkte statt über Levelsperren
([ADR-0019](docs/decisions/0019-skillbaum-mit-vier-wurzeln.md)). Vier
Fähigkeiten hängen daran.

**Was als Nächstes ansteht, steht nicht mehr hier**, sondern in
[`docs/context/ziele.md`](docs/context/ziele.md) — mit Terminen und mit der
Liste dessen, was bis zum MVP ausdrücklich *nicht* angefasst wird. Kurz: die
Waffen als Alternativen, die elf übrigen Fähigkeiten, dann der Dungeon.
Wo wir stehen: [`docs/context/state.md`](docs/context/state.md).

## Für Mitentwickler: erste Schritte

```bash
git clone https://github.com/Prozesstek/LifesGame.git
cd LifesGame

# Die ganze App (Flutter-SDK noetig, Dart 3.12.2 oder neuer):
flutter pub get
flutter run -d chrome              # oder einfach start-app.bat doppelklicken
flutter test                       # 199 Tests
flutter analyze                    # muss sauber sein

# Balance des Spiels nachrechnen (Gegner gegen echten Werte-Pfad):
dart run tool/balance_sim.dart

# Die Packages laufen einzeln, ohne Flutter — dafuer reicht das Dart-SDK:
#   winget install --id Google.DartSDK --exact
cd packages/combat
dart test                          # 29 Tests
dart run example/play.dart         # Kampf im Terminal spielen
dart run example/balance_sim.dart  # prüft die Engine, nicht das Spiel

cd packages/habits
dart test                          # 71 Tests
dart run example/curve_sim.dart    # 90 Tage Gewohnheiten durchspielen

cd packages/gear
dart test                          # 27 Tests, prüft auch die Preise

cd packages/theory
dart test                          # 109 Tests, prüft auch den Inhalt

cd packages/identity
dart test                          # 28 Tests, prüft auch die Titel
```

Windows-Desktop-Builds brauchen Visual Studio mit C++-Workload und sind hier nicht
eingerichtet — entwickelt wird gegen Chrome.

Achtung: Die VS-Code-Erweiterungen „Dart" und „Flutter" installieren **kein** SDK,
nur Editor-Werkzeug. Siehe [`docs/context/gotchas.md`](docs/context/gotchas.md).

Danach in dieser Reihenfolge lesen — es sind zusammen keine 15 Minuten:

1. **[`konzept.md`](konzept.md)** — was wir bauen und warum es funktionieren soll
2. **[`docs/context/state.md`](docs/context/state.md)** — wo wir gerade stehen, was als Nächstes ansteht
3. **[`docs/decisions/`](docs/decisions/)** — warum der Stack so aussieht, wie er aussieht

Flutter-SDK installieren: <https://docs.flutter.dev/get-started/install>
Danach `flutter doctor` bis alles grün ist.

## Was wo liegt

| Pfad | Inhalt | Tests |
|---|---|---|
| `packages/combat` | Kampfregeln und drei Gegner, reines Dart ohne Flame | 29 |
| `packages/theory` | Skillbaum-Graph: 29 Seiten, 87 Fragen, Lernfortschritt | 109 |
| `packages/progression` | Levelkurve, Fähigkeitsslots, Theoriepunkte | 33 |
| `packages/habits` | 11 Gewohnheits-Vorlagen, Streaks, Charakterwerte | 71 |
| `packages/gear` | 9 Ausrüstungsstücke auf 6 Plätzen, Preise, Inventar | 27 |
| `packages/abilities` | woher eine Fähigkeit kommt und wann sie offen ist | 28 |
| `packages/identity` | 7 verdiente Titel aus drei Quellen, Name | 28 |
| `tool/balance_sim.dart` | die maßgebliche Balance-Simulation | — |
| `lib/` | Flutter-App: Start, Skillbaum, Tracker, Kampf, Laden, Charakter | 199 |

**Die Kernregel:** Spielzahlen liegen in den Packages, nie in `lib/`. Die
Controller reichen durch und rechnen nicht. Wird in `lib/` eine Spielzahl
berechnet, gehört sie in eines der sieben Packages — Begründung in
[ADR-0002](docs/decisions/0002-kampflogik-ohne-flame.md) und
[ADR-0003](docs/decisions/0003-combat-als-eigenes-package.md).

**Balance ändern heißt simulieren, nicht raten.** Jedes Package hat seine
Zahlen an einer Stelle (`balance.dart`, `rewards.dart`, `level_curve.dart`,
`prices.dart`). Eine Zahl ändern, `dart run tool/balance_sim.dart` laufen
lassen, Ergebnis vergleichen.

Wichtig dabei: `tool/balance_sim.dart` ist die maßgebliche Simulation, weil
sie als einzige mehrere Packages zugleich sieht und deshalb mit dem echten
Werte-Pfad rechnet. Die Simulation im Combat-Package bewegt einen Wert und
hält die übrigen fest — das tut das Spiel nie, und genau diese Verwechslung
hat den ersten Balance-Befund des Projekts falsch gedeutet
([ADR-0009](docs/decisions/0009-kampfbalance-ueber-gegnerreihe.md)).

## Wer hier arbeitet

Zwei Entwickler: **[@Prozesstek](https://github.com/Prozesstek)** (Frederik)
und **[@AktivesBrett](https://github.com/AktivesBrett)**, beide mit
Schreibrechten.

## Wie dieses Repo sein Gedächtnis behält

Wir arbeiten beide mit Claude Code. Claude vergisst zwischen Sitzungen alles, und
lokale Notizen auf einem Rechner sieht der andere nie. Deshalb liegt der gesamte
Kontext **im Repo** und wandert über Git mit:

| Datei | Beantwortet |
|---|---|
| `CLAUDE.md` | Wird von Claude Code automatisch geladen. Stack, Regeln, Konventionen. |
| `konzept.md` | Was bauen wir? |
| `docs/context/state.md` | Wo stehen wir? |
| `docs/context/ziele.md` | Wo wollen wir hin, bis wann — und was bleibt liegen? |
| `docs/decisions/NNNN-*.md` | Warum ist das so? |
| `docs/context/gotchas.md` | Worüber bin ich schon gestolpert? |

**Die Regel:** Wer arbeitet, aktualisiert am Ende `state.md`. Freitags werden
in `ziele.md` die Ist-Spalten nachgetragen — eine Zahl, die sich eine Woche
nicht bewegt hat, ist das Signal. Wer eine Entscheidung
trifft, die man in drei Monaten hinterfragen würde, schreibt einen ADR
(Vorlage in `docs/decisions/TEMPLATE.md`). Alles andere veraltet von selbst.

ADRs werden nie umgeschrieben. Eine überholte Entscheidung bekommt den Status
`Abgelöst durch ADR-NNNN` — so bleibt nachvollziehbar, was wir mal geglaubt haben.

## Werkzeuge

`.claude/` bringt eine kuratierte Auswahl aus [ECC](https://github.com/affaan-m/ECC) 2.2.0 mit:
Flutter-/Dart-Agents, Review-Commands und Coding-Rules. Du bekommst sie beim Clone
automatisch — **nichts zu installieren.**

- `/flutter-review` — Review auf Widget-Praxis, State Management, Performance
- `/flutter-build` — Analyzer- und Build-Fehler inkrementell fixen
- `/flutter-test` — Tests laufen lassen und Fehler beheben

Deine persönlichen Permission-Freigaben landen in `.claude/settings.local.json`.
Die Datei ist gitignored — sie ist deine, nicht unsere.

## Konventionen

- `dart format` vor jedem Commit (Zeilenlänge 80)
- Commits: `<type>: <beschreibung>` — `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`
- Größere Änderungen über Branch + PR, damit der andere den Kontext mitbekommt
- Spiellogik-Tests laufen ohne Renderer — siehe [ADR-0002](docs/decisions/0002-kampflogik-ohne-flame.md)
