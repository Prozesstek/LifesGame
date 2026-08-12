# Lifes Game

Habit-Tracker, dessen Fortschritt sich in einem rundenbasierten RPG auszahlt.
Vollständiges Produktkonzept: [`konzept.md`](konzept.md)

## Team

Zwei Entwickler, geteiltes Repo: **@Prozesstek** (Frederik) und
**@AktivesBrett**, beide mit Schreibrechten auf
[`Prozesstek/LifesGame`](https://github.com/Prozesstek/LifesGame).

Es gibt **kein** gemeinsames Gedächtnis außerhalb dieses Repos — was nicht
committed ist, existiert für den anderen nicht.

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
| `packages/theory/` | Skillbaum, Inhalte, Lernfortschritt, reines Dart, 43 Tests | nur Dart-SDK |
| `packages/theory/lib/src/content/` | die Lektionen selbst — hier wird geschrieben | nur Dart-SDK |
| `packages/theory/lib/src/skill_tree.dart` | welche Zweige es gibt und ab welchem Level | nur Dart-SDK |
| `packages/progression/` | Levelkurve, reines Dart, 11 Tests | nur Dart-SDK |
| `packages/habits/` | Gewohnheiten, Streaks, Charakterwerte, reines Dart, 52 Tests | nur Dart-SDK |
| `packages/habits/lib/src/catalog.dart` | die Vorlagen selbst — verknüpft mit Lektion und Stat | nur Dart-SDK |
| `packages/habits/example/curve_sim.dart` | 90 Tage Ertrag und Werte durchspielen | nur Dart-SDK |
| `lib/main.dart` | App-Shell und Theme | Flutter |
| `lib/home/home_screen.dart` | Startbildschirm, Weg zu allen Bereichen | Flutter |
| `lib/progression/level_provider.dart` | Level und Gold aus allen Quellen, **rechnet nicht** | Flutter |
| `lib/habits/habits_controller.dart` | Riverpod-Brücke Tracker ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/habits/habits_screen.dart` | Werte, Tagesliste, freigeschaltete Vorlagen | Flutter |
| `lib/ui/palette.dart` | alle Farben der App | Flutter |
| `lib/combat/combat_controller.dart` | Riverpod-Brücke Logik ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/combat/battle_game.dart` | Flame-Darstellung, spielt nur Events ab | Flutter |
| `lib/combat/combat_screen.dart` | HUD: Statusleisten, Move-Buttons, Log | Flutter |
| `lib/combat/widgets/timing_bar.dart` | Timed Hit als Eingabe (misst nur, wertet nicht) | Flutter |
| `lib/theory/theory_controller.dart` | Riverpod-Brücke Inhalt ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/theory/skill_tree_screen.dart` | der Baum: alle Zweige und ihre Levelsperren | Flutter |
| `lib/theory/branch_screen.dart` | Zweig-Übersicht mit Fortschritt und Lektionssperren | Flutter |
| `lib/theory/lesson_screen.dart` | lesen → Fragen → Ergebnis | Flutter |

**Schichtregel:** Kampfregeln nur in `packages/combat`, Inhalte und
Belohnungszahlen nur in `packages/theory`, die Levelkurve nur in
`packages/progression`, Streaks und Charakterwerte nur in `packages/habits`.
Die Controller reichen durch und halten den laufenden Zustand. Sobald in
`lib/` eine Spielzahl berechnet wird, gehört sie in eines der vier Packages.

```bash
# App
flutter pub get
flutter run -d chrome    # laufen lassen (Windows-Desktop geht mangels VS nicht)
flutter test             # 54 Tests
flutter analyze          # muss sauber sein

# Kampflogik allein, ohne Flutter
cd packages/combat
dart test                              # 23 Tests
dart run example/play.dart             # Kampf im Terminal
dart run example/balance_sim.dart      # Balance prüfen

# Gewohnheiten allein, ohne Flutter
cd packages/habits
dart test                              # 52 Tests
dart run example/curve_sim.dart        # 90 Tage Ertrag und Werte

# Theorie und Levelkurve allein, ohne Flutter
cd packages/theory      ; dart test    # 43 Tests, prüft auch den Inhalt
cd packages/progression ; dart test    # 11 Tests
```

**Balance ändern heißt simulieren, nicht raten.** Alle Stellschrauben stehen in
`packages/combat/lib/src/balance.dart`. Eine Zahl ändern, `balance_sim.dart`
laufen lassen, Siegquoten vergleichen. Steht eine Zahl im Kampfcode statt in
`balance.dart`, ist das ein Bug.

**Theorie schreiben heißt testen lassen.** Neue Lektionen kommen nach
`packages/theory/lib/src/content/`, ein neuer Zweig zusätzlich in
`theoryTree` (`skill_tree.dart`) — danach `dart test`. Die Tests laufen über
den ganzen Baum und prüfen den Inhalt mit: eindeutige Ids, gültige
`correctIndex`, keine doppelten Antworten. Was eine Lektion einbringt, steht
ausschließlich in `rewards.dart`, ab welchem Level ein Zweig offen ist am
Zweig selbst (`unlockLevel`).

**Gewohnheiten ändern heißt ebenfalls simulieren.** Alle Zahlen —
Erfahrung je Häkchen, Streak-Meilensteine, Deckel, Stat-Kurve — stehen in
`packages/habits/lib/src/rewards.dart`. Eine ändern, `curve_sim.dart` laufen
lassen, die 90-Tage-Tabelle vergleichen. Neue Vorlagen kommen nach
`catalog.dart` und brauchen eine Lektion mit passendem `unlocksHabit` —
sonst schlägt `test/habits_theory_test.dart` fehl.

**Drei Kurven müssen zusammenpassen.** Belohnung (`theory/rewards.dart`),
Häkchen-Ertrag (`habits/rewards.dart`) und Level
(`progression/level_curve.dart`) hängen zusammen: Passen sie nicht, wird der
Baum zur Sackgasse — oder er öffnet sich in zwei Tagen komplett und die
Levelsperre ist Deko. `flutter test test/progression_test.dart` spielt beides
durch und meldet genau das. Wer eine dieser Zahlen ändert, lässt diesen Test
laufen.

**Der Kern-Loop verbindet alle vier Packages.** Lektion (`theory`) schaltet
Vorlage frei (`habits`), Häkchen erzeugt Erfahrung (`progression`) und
Charakterwerte, die Werte gehen in den Kampf (`combat`). Die einzige Stelle,
an der Erfahrung zusammenläuft, ist `totalXpProvider`; die einzige, an der
Werte in den Kampf gehen, ist `_freshFight()` in `combat_controller.dart`.

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
