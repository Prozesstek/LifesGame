# Lifes Game

Habit-Tracker, dessen Fortschritt sich in einem rundenbasierten RPG auszahlt.
Vollständiges Produktkonzept: [`konzept.md`](konzept.md)

## Team

Zwei Entwickler, geteiltes Repo. Es gibt **kein** gemeinsames Gedächtnis
außerhalb dieses Repos — was nicht committed ist, existiert für den anderen nicht.

## Stack

| Ebene | Technologie | Regel |
|---|---|---|
| App-Shell, alle Tracker-Screens | Flutter / Dart | — |
| Kampfbildschirm | Flame | nur als eingebettetes Widget |
| Persistenz | Drift (SQLite) | offline-first, keine Cloud im MVP |
| State | Riverpod | — |
| Animationen | Rive | Skills und Treffer |

**Architektur-Kernregel:** Kampflogik ist reines Dart **ohne Flame-Imports**.
Die Logik gibt Events aus, Flame spielt sie nur ab. Begründung: [ADR-0002](docs/decisions/0002-kampflogik-ohne-flame.md)

Diese Regel ist nicht nur Vereinbarung: `packages/combat` hat einen leeren
`dependencies`-Block, ein Flame-Import schlägt dort schlicht fehl ([ADR-0003](docs/decisions/0003-combat-als-eigenes-package.md)).

## Aufbau

| Pfad | Inhalt | Braucht |
|---|---|---|
| `packages/combat/` | Kampflogik, reines Dart, 23 Tests | nur Dart-SDK |
| `packages/combat/example/play.dart` | spielbarer Kampf im Terminal | nur Dart-SDK |
| `packages/combat/example/balance_sim.dart` | Balance-Simulation, 2000 Kämpfe in 0,4 s | nur Dart-SDK |
| `lib/combat/combat_controller.dart` | Riverpod-Brücke Logik ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/combat/battle_game.dart` | Flame-Darstellung, spielt nur Events ab | Flutter |
| `lib/combat/combat_screen.dart` | HUD: Statusleisten, Move-Buttons, Log | Flutter |
| `lib/combat/widgets/timing_bar.dart` | Timed Hit als Eingabe (misst nur, wertet nicht) | Flutter |

**Schichtregel:** Kampfregeln nur in `packages/combat`. Der Controller reicht Züge
durch und hält den laufenden Kampf, Flame spielt Events ab. Sobald in `lib/`
eine Spielzahl berechnet wird, gehört sie nach `packages/combat`.

```bash
# App
flutter pub get
flutter run -d chrome    # laufen lassen (Windows-Desktop geht mangels VS nicht)
flutter test             # 6 Tests
flutter analyze          # muss sauber sein

# Kampflogik allein, ohne Flutter
cd packages/combat
dart test                              # 23 Tests
dart run example/play.dart             # Kampf im Terminal
dart run example/balance_sim.dart      # Balance prüfen
```

**Balance ändern heißt simulieren, nicht raten.** Alle Stellschrauben stehen in
`packages/combat/lib/src/balance.dart`. Eine Zahl ändern, `balance_sim.dart`
laufen lassen, Siegquoten vergleichen. Steht eine Zahl im Kampfcode statt in
`balance.dart`, ist das ein Bug.

## Gedächtnis-Protokoll

Diese vier Dateien sind das geteilte Gedächtnis. Sie zu pflegen ist Teil der Arbeit,
nicht Nacharbeit:

| Datei | Enthält | Wann aktualisieren |
|---|---|---|
| `konzept.md` | Produktvision, Systeme, MVP-Schnitt | wenn sich das Produkt ändert |
| `docs/context/state.md` | Was fertig ist, woran gerade gearbeitet wird, was als Nächstes kommt | am Ende jeder Arbeitssitzung |
| `docs/decisions/NNNN-*.md` | **Warum** eine Entscheidung so fiel | sobald eine Entscheidung fällt, die man in drei Monaten hinterfragen würde |
| `docs/context/gotchas.md` | Fallstricke, die Zeit gekostet haben | sobald etwas unerwartet war |

**Für Claude:** Am Ende jeder Sitzung, in der etwas Substanzielles passiert ist:
`docs/context/state.md` aktualisieren. Bei einer Richtungsentscheidung zusätzlich
einen ADR anlegen (Vorlage: `docs/decisions/TEMPLATE.md`, fortlaufend nummeriert).
Niemals ADRs nachträglich umschreiben — überholte Entscheidungen bekommen den
Status `Abgelöst durch ADR-NNNN`.

**Nicht ins Repo gehört:** persönliche Permissions (`.claude/settings.local.json`,
ist gitignored), lokale Claude-Memory-Dateien unter `~/.claude/projects/`, IDE-Kram.

## Werkzeuge im Repo

`.claude/` enthält eine kuratierte Auswahl aus [ECC](https://github.com/affaan-m/ECC) 2.2.0.
Beide Entwickler bekommen sie beim Clone automatisch — keine Installation nötig.

- **Agents:** `flutter-reviewer`, `dart-build-resolver`, `code-reviewer`, `security-reviewer`, `planner`, `architect`, `tdd-guide`
- **Commands:** `/flutter-review`, `/flutter-build`, `/flutter-test`
- **Skills:** `dart-flutter-patterns`, `flutter-dart-code-review`
- **Rules:** `.claude/rules/ecc/dart/` greift automatisch bei `*.dart`, `pubspec.yaml`, `analysis_options.yaml`

## Konventionen

- `dart format` vor jedem Commit, Zeilenlänge 80
- Commits: `<type>: <beschreibung>` — `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`
- Kein Direkt-Push auf `main` bei größeren Änderungen — Branch + PR, damit der andere den Kontext sieht
- Tests für Spiellogik laufen ohne Renderer (reine Dart-Tests), `flame_test` nur wo unvermeidbar

## Setup-Status

Flutter 3.44.9 (Dart 3.12.2) liegt unter `C:\Users\frekk\flutter`, `flutter\bin`
steht im User-PATH.

Build-Ziele auf diesem Rechner:

| Ziel | Status |
|---|---|
| Web (Chrome/Edge) | funktioniert — Standard für die Entwicklung |
| Android | Android Studio da, aber `cmdline-tools` fehlen und Lizenzen sind nicht akzeptiert |
| Windows-Desktop | geht nicht, Visual Studio mit C++-Workload fehlt |

Achtung: Die VS-Code-Erweiterungen `dart-code.dart-code` und `dart-code.flutter`
installieren **kein** SDK. Siehe [`docs/context/gotchas.md`](docs/context/gotchas.md).

Aktueller Stand und nächste Schritte: [`docs/context/state.md`](docs/context/state.md).
