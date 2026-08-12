# Lifes Game

Ein Habit-Tracker, dessen Fortschritt sich in einem rundenbasierten RPG auszahlt.
Was du im echten Leben tust, bestimmt, wie stark dein Charakter ist.

**Status:** Der Kern-Loop steht und ist spielbar — Lektion lesen, Gewohnheit
freischalten, täglich abhaken, Werte steigen, Kampf wird gewinnbar. Es fehlen
Dungeon, Shop und die Persistenz: Zurzeit überlebt **kein** Fortschritt einen
Neustart. Details in [`docs/context/state.md`](docs/context/state.md).

## Für Mitentwickler: erste Schritte

```bash
git clone https://github.com/Prozesstek/LifesGame.git
cd LifesGame

# Die ganze App (Flutter-SDK noetig, Dart 3.12.2 oder neuer):
flutter pub get
flutter run -d chrome
flutter test                       # 54 Tests
flutter analyze                    # muss sauber sein

# Die Packages laufen einzeln, ohne Flutter — dafuer reicht das Dart-SDK:
#   winget install --id Google.DartSDK --exact
cd packages/combat
dart test                          # 23 Tests
dart run example/play.dart         # Kampf im Terminal spielen
dart run example/balance_sim.dart  # 2000 simulierte Kämpfe

cd packages/habits
dart test                          # 52 Tests
dart run example/curve_sim.dart    # 90 Tage Gewohnheiten durchspielen
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
| `packages/combat` | Kampfregeln, reines Dart ohne Flame | 23 |
| `packages/theory` | 17 Lektionen in 5 Zweigen, 51 Fragen, Lernfortschritt | 43 |
| `packages/progression` | Levelkurve | 11 |
| `packages/habits` | 11 Gewohnheits-Vorlagen, Streaks, Charakterwerte | 52 |
| `lib/` | Flutter-App: Startbildschirm, Skillbaum, Tracker, Kampf | 54 |

**Die Kernregel:** Spielzahlen liegen in den Packages, nie in `lib/`. Die
Controller reichen durch und rechnen nicht. Wird in `lib/` eine Spielzahl
berechnet, gehört sie in eines der vier Packages — Begründung in
[ADR-0002](docs/decisions/0002-kampflogik-ohne-flame.md) und
[ADR-0003](docs/decisions/0003-combat-als-eigenes-package.md).

**Balance ändern heißt simulieren, nicht raten.** Jedes Package hat seine
Zahlen an einer Stelle (`balance.dart`, `rewards.dart`, `level_curve.dart`),
und die beiden wichtigsten haben eine Simulation daneben. Eine Zahl ändern,
Simulation laufen lassen, Ergebnis vergleichen.

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
| `docs/decisions/NNNN-*.md` | Warum ist das so? |
| `docs/context/gotchas.md` | Worüber bin ich schon gestolpert? |

**Die Regel:** Wer arbeitet, aktualisiert am Ende `state.md`. Wer eine Entscheidung
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
