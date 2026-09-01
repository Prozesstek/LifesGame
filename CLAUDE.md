# Lifes Game

Habit-Tracker, dessen Fortschritt sich in einem rundenbasierten RPG auszahlt.
Vollständiges Produktkonzept: [`konzept.md`](konzept.md)

## Immer mitlesen

Diese Dateien werden bei jedem Sitzungsstart automatisch mitgeladen — nicht als
Link, sondern als Inhalt:

@docs/context/state.md
@docs/context/ziele.md
@docs/context/gotchas.md

`ziele.md` steht hier, weil eine Sitzung ohne Ziel in die falsche Richtung
arbeiten kann, ohne dass es jemandem auffällt — und weil dort steht, was
gerade **nicht** angefasst wird.

`konzept.md`, `README.md` und die ADRs unter `docs/decisions/` bleiben bewusst
Links: zu groß und zu selten geändert, um sie in jede Sitzung zu ziehen. Sie
werden gelesen, wenn die Arbeit sie berührt.

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
| Persistenz | `SaveStore` + shared_preferences | offline-first, Drift verschoben ([ADR-0010](docs/decisions/0010-persistenz-hinter-einem-anschluss.md)) |
| State | Riverpod | — |
| Animationen | Rive | Skills und Treffer |

**Architektur-Kernregel:** Kampflogik ist reines Dart **ohne Flame-Imports**.
Die Logik gibt Events aus, Flame spielt sie nur ab. Begründung: [ADR-0002](docs/decisions/0002-kampflogik-ohne-flame.md)

Diese Regel ist nicht nur Vereinbarung: `packages/combat` hat einen leeren
`dependencies`-Block, ein Flame-Import schlägt dort schlicht fehl ([ADR-0003](docs/decisions/0003-combat-als-eigenes-package.md)).

## Aufbau

| Pfad | Inhalt | Braucht |
|---|---|---|
| `packages/combat/` | Kampflogik, reines Dart, 80 Tests | nur Dart-SDK |
| `packages/combat/lib/src/enemy.dart` | die drei Gegner und ihre Werte | nur Dart-SDK |
| `packages/combat/lib/src/ability_moves.dart` | die **fünfzehn Fähigkeiten** und ihre Zahlen | nur Dart-SDK |
| `packages/combat/lib/src/environment.dart` | die vier Umgebungen | nur Dart-SDK |
| `packages/combat/lib/src/timing_rules.dart` | welche Timing-Werte gerade gelten | nur Dart-SDK |
| `packages/combat/lib/src/enemy_policy.dart` | wie der Gegner waehlt, samt Utility-Quote | nur Dart-SDK |
| `packages/combat/example/play.dart` | spielbarer Kampf im Terminal | nur Dart-SDK |
| `packages/combat/example/balance_sim.dart` | prüft die **Engine** — siehe Warnung unten | nur Dart-SDK |
| `packages/theory/` | Skillbaum-Graph, Inhalte, Lernfortschritt, reines Dart, 129 Tests | nur Dart-SDK |
| `packages/theory/lib/src/content/` | die Lektionen selbst — hier wird geschrieben | nur Dart-SDK |
| `packages/theory/lib/src/content/theory_graph_content.dart` | **der Baum selbst**: vier Wurzeln, wer an wem hängt | nur Dart-SDK |
| `packages/theory/lib/src/node_graph.dart` | Struktur des Graphen, `canOpen`, Gesundheitsprüfung | nur Dart-SDK |
| `packages/theory/lib/src/skill_tree.dart` | die alten flachen Zweige — trägt nur noch das Handbuch | nur Dart-SDK |
| `packages/progression/` | Levelkurve, Fähigkeitsslots, Theoriepunkte, reines Dart, 33 Tests | nur Dart-SDK |
| `packages/progression/lib/src/ability_slots.dart` | ab welchem Level welcher Slot aufgeht | nur Dart-SDK |
| `packages/progression/lib/src/theory_points.dart` | zwei Theoriepunkte je Aufstieg | nur Dart-SDK |
| `packages/habits/` | Gewohnheiten, Streaks, Charakterwerte, reines Dart, 71 Tests | nur Dart-SDK |
| `packages/habits/lib/src/catalog.dart` | die Vorlagen selbst — verknüpft mit Lektion und Stat | nur Dart-SDK |
| `packages/habits/example/curve_sim.dart` | 90 Tage Ertrag und Werte durchspielen | nur Dart-SDK |
| `packages/gear/` | Ausrüstung, Preise, Inventar, reines Dart, 27 Tests | nur Dart-SDK |
| `packages/gear/lib/src/catalog.dart` | die Ausrüstungsstücke selbst | nur Dart-SDK |
| `packages/gear/lib/src/prices.dart` | alle Preise | nur Dart-SDK |
| `packages/abilities/` | woher eine Fähigkeit kommt, reines Dart, 35 Tests | nur Dart-SDK |
| `packages/abilities/lib/src/ability_catalog.dart` | die Fähigkeiten und ihre Bedingungen | nur Dart-SDK |
| `packages/identity/` | Name und verdiente Titel, reines Dart, 28 Tests | nur Dart-SDK |
| `packages/identity/lib/src/title_catalog.dart` | die Titel und ihre Bedingungen | nur Dart-SDK |
| `tool/balance_sim.dart` | prüft das **Spiel**: Gegner gegen echten Werte-Pfad | nur Dart-SDK |
| `lib/main.dart` | App-Shell, Theme, lädt den Spielstand vor `runApp` | Flutter |
| `lib/home/home_screen.dart` | Startbildschirm, Weg zu allen Bereichen | Flutter |
| `lib/save/save_data.dart` | der ganze Spielstand als ein Wert | Flutter |
| `lib/save/save_store.dart` | der Anschluss, hinter dem die Speichertechnik liegt | Flutter |
| `lib/save/save_watcher.dart` | **die einzige Stelle, die schreibt** | Flutter |
| `lib/progression/level_provider.dart` | Level und Gold aus allen Quellen, **rechnet nicht** | Flutter |
| `lib/habits/habits_controller.dart` | Riverpod-Brücke Tracker ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/habits/habits_screen.dart` | Werte, Tagesliste, freigeschaltete Vorlagen | Flutter |
| `lib/gear/gear_controller.dart` | Riverpod-Brücke Inventar ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/gear/shop_screen.dart` | der Laden — der einzige Gold-Abfluss | Flutter |
| `lib/character/character_screen.dart` | Kopf, Beständigkeit, Werte mit Herkunft, Ausrüstungsraster | Flutter |
| `lib/character/widgets/consistency_card.dart` | die Streak-Zahlen und der Satz darunter | Flutter |
| `lib/character/widgets/ability_slots_row.dart` | die vier Fähigkeitsplätze, wählen und räumen | Flutter |
| `lib/character/abilities_controller.dart` | Riverpod-Brücke Fähigkeiten ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/character/identity_controller.dart` | Riverpod-Brücke Identität ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/character/ability_unlock.dart` | was neu ist und wohin es passt — reine Rechnung | Flutter |
| `lib/character/show_ability_unlock.dart` | die Feier, aufgerufen an genau zwei Stellen | Flutter |
| `lib/dev/dev_screen.dart` | Entwicklermodus, **nur im Debug-Build** | Flutter |
| `lib/dev/debug_grants.dart` | was der Dev-Modus verschenkt hat | Flutter |
| `lib/dev/save_slot.dart` | echter Stand vs. Dev-Stand | Flutter |
| `lib/ui/palette.dart` | alle Farben der App | Flutter |
| `lib/ui/phone_frame.dart` | zeigt die App im Browser in Handygröße | Flutter |
| `lib/combat/battle/fighter.dart` | die beiden gezeichneten Kämpfer | Flutter |
| `lib/combat/battle/projectile.dart` | fliegende Geschosse, z. B. der Pfeil | Flutter |
| `lib/combat/battle/move_animation.dart` | wie ein Move **aussieht** (nicht was er tut) | Flutter |
| `lib/combat/battle/floating_text.dart` | Schadens- und Heilungszahlen über den Kämpfern | Flutter |
| `lib/combat/combat_controller.dart` | Riverpod-Brücke Logik ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/combat/enemy_picker_screen.dart` | Gegnerwahl mit Einschätzung vor dem Kampf | Flutter |
| `lib/combat/battle_game.dart` | Flame-Darstellung, spielt nur Events ab | Flutter |
| `lib/combat/combat_screen.dart` | HUD: Statusleisten, Kachelleiste, Timing | Flutter |
| `lib/combat/move_help.dart` | was ein Zug tut, in Worten und echten Zahlen | Flutter |
| `lib/combat/move_icon.dart` | welches Bild zu einem Zug gehoert | Flutter |
| `lib/combat/widgets/timing_bar.dart` | Timed Hit als Eingabe (misst nur, wertet nicht) | Flutter |
| `lib/combat/widgets/environment_banner.dart` | die liegende Umgebung mit Restrunden | Flutter |
| `lib/combat/widgets/result_dialog.dart` | das Blatt am Ende eines Kampfes | Flutter |
| `lib/theory/theory_controller.dart` | Riverpod-Brücke Inhalt ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/theory/skill_tree_screen.dart` | vier Gebiete zum Wischen, Kopfzeile, Handbuch davor | Flutter |
| `lib/theory/widgets/tree_view.dart` | ein Gebiet: Startknoten unten, eine Ebene darüber | Flutter |
| `lib/theory/widgets/tree_layout.dart` | wo jeder Knoten sitzt — reine Rechnung, testbar | Flutter |
| `lib/theory/widgets/tree_painter.dart` | die Verbindungslinien | Flutter |
| `lib/theory/widgets/node_action_panel.dart` | der Knopf **über** dem Startknoten | Flutter |
| `lib/theory/widgets/node_state.dart` | in welchem Zustand ein Knoten ist — eine Stelle | Flutter |
| `lib/theory/branch_screen.dart` | nur noch das Handbuch: Reihenfolge statt Graph | Flutter |
| `lib/theory/lesson_screen.dart` | lesen → Fragen → Ergebnis | Flutter |

**Schichtregel:** Kampfregeln und Gegnerwerte nur in `packages/combat`,
Inhalte und Belohnungszahlen nur in `packages/theory`, die Levelkurve nur in
`packages/progression`, Streaks und Charakterwerte nur in `packages/habits`,
Preise und Ausrüstungsboni nur in `packages/gear`, Titel und ihre
Bedingungen nur in `packages/identity`, Freischaltbedingungen für
Fähigkeiten nur in `packages/abilities`. Die Controller reichen durch
und halten den laufenden Zustand. Sobald in `lib/` eine Spielzahl
berechnet wird, gehört sie in eines der sieben Packages.

```bash
# App
flutter pub get
flutter run -d chrome    # laufen lassen (Windows-Desktop geht mangels VS nicht)
flutter test             # 311 Tests
flutter analyze          # muss sauber sein

# Balance des Spiels prüfen -- die maßgebliche Simulation
dart run tool/balance_sim.dart         # Gegner gegen echten Werte-Pfad

# Kampflogik allein, ohne Flutter
cd packages/combat
dart test                              # 80 Tests
dart run example/play.dart             # Kampf im Terminal
dart run example/balance_sim.dart      # nur die Engine, siehe Warnung unten

# Gewohnheiten allein, ohne Flutter
cd packages/habits
dart test                              # 71 Tests
dart run example/curve_sim.dart        # 90 Tage Ertrag und Werte

# Theorie, Levelkurve, Ausrüstung allein, ohne Flutter
cd packages/theory      ; dart test    # 129 Tests, prüft auch den Inhalt
cd packages/progression ; dart test    # 33 Tests
cd packages/gear        ; dart test    # 27 Tests, prüft auch die Preise
cd packages/abilities   ; dart test    # 35 Tests
cd packages/identity    ; dart test    # 28 Tests, prüft auch die Titel
```

**Balance ändern heißt simulieren, nicht raten.** Alle Stellschrauben stehen in
`packages/combat/lib/src/balance.dart`, die Gegnerwerte in `enemy.dart`. Eine
Zahl ändern, `dart run tool/balance_sim.dart` laufen lassen, Siegquoten
vergleichen. Steht eine Zahl im Kampfcode statt in `balance.dart`, ist das ein
Bug.

**Es gibt zwei Simulationen, und sie beantworten verschiedene Fragen.**
`tool/balance_sim.dart` ist die maßgebliche: Sie sieht `combat` **und**
`habits` und spielt die echte Werte-Kurve gegen alle Gegner. Die Simulation
im Combat-Package bewegt dagegen einen Wert und hält die übrigen fest — das
tut das Spiel nie, und genau diese Verwechslung hat den ersten
Balance-Befund des Projekts falsch gedeutet ([ADR-0009](docs/decisions/0009-kampfbalance-ueber-gegnerreihe.md)).
Sie bleibt nützlich für Fragen an die Engine allein.

**Ein Kampf muss enden.** `packages/combat/test/termination_test.dart` prüft
das über Wertebereiche, die kein Beispielkampf abdeckt. Der Anlass war real:
Heilung als Anteil der maximalen HP wuchs mit dem HP-Pool mit, während der
Schaden gleich blieb — ab einer bestimmten Größe endete kein Kampf mehr.
Details in `docs/context/gotchas.md`.

**Theorie schreiben heißt testen lassen.** Eine neue Seite kommt nach
`packages/theory/lib/src/content/`, ein neuer Knoten zusätzlich in
`theoryGraph` (`theory_graph_content.dart`) — danach `dart test`.
`graph_content_test.dart` läuft über den ganzen Graphen und prüft den Inhalt
mit: eindeutige Ids, genau drei Fragen, gültige `correctIndex`, keine
doppelten Antworten. Und die Struktur: keine Eltern-Id ins Leere,
**kreisfrei**, jede Wurzel mit mindestens fünf Kindern.

Was eine Seite einbringt, steht ausschließlich in `rewards.dart`. **Zweige
haben keine Levelsperren mehr** — geöffnet wird über Theoriepunkte
([ADR-0019](docs/decisions/0019-skillbaum-mit-vier-wurzeln.md)). Ein Knoten
kostet einen Punkt, die vier Wurzeln kosten nichts.

**Gewohnheiten ändern heißt ebenfalls simulieren.** Alle Zahlen —
Erfahrung je Häkchen, Streak-Meilensteine, Deckel, Stat-Kurve — stehen in
`packages/habits/lib/src/rewards.dart`. Eine ändern, `curve_sim.dart` laufen
lassen, die 90-Tage-Tabelle vergleichen. Neue Vorlagen kommen nach
`catalog.dart` und brauchen eine Lektion mit passendem `unlocksHabit` —
sonst schlägt `test/habits_theory_test.dart` fehl.

**Ausrüstung ändern heißt gegen den Gold-Zufluss rechnen.** Alle Preise
stehen in `packages/gear/lib/src/prices.dart`. Das Package kennt `habits`
nicht und muss den Zufluss deshalb annehmen (25 Gold am Tag); dass die
Annahme stimmt, prüft `test/progression_test.dart` in der App. Neue Stücke
kommen nach `catalog.dart` und werden von `catalog_test.dart` automatisch
mitgeprüft — jedes Stück muss wirken, jeder Platz braucht eines, und teurer
muss auch besser sein.

**Fähigkeiten ändern heißt: den Katalog anfassen, nicht die Engine.**
Alle fünfzehn stehen in `packages/combat/lib/src/ability_moves.dart`, ihre
Bedingungen in `packages/abilities` ([ADR-0022](docs/decisions/0022-faehigkeiten-set-aus-der-vorlage.md)).
Feste Zahlen aus einer Vorlage werden mit `power = Wert / 16` umgerechnet —
sonst hängt die Fähigkeit nicht mehr am Angriffswert und damit nicht mehr
an den Gewohnheiten. Dauerschaden ist immer ein Vielfaches des
Angriffswerts, nie eine feste HP-Zahl.

Die Vorlage selbst liegt seit dem 26.08. im Repo:
[`docs/vorlagen/faehigkeiten.md`](docs/vorlagen/faehigkeiten.md). Sie sagt,
was eine Fähigkeit **sein soll** — Wirkung, Timing, Icon, Animation. Sie ist
nicht die Quelle der Wahrheit für die Zahlen (das ist der Katalog), aber sie
hält fest, was davon noch fehlt und warum drei Umrechnungen dazwischen
liegen.

**Der eigene Perfect-Faktor gilt nur für Fähigkeiten.** Basisangriff und
Waffenmoves lassen `perfectFactor` auf `null` und bleiben beim Deckel aus
`balance.dart` — dort galt die Messung aus ADR-0009. Wer das ändert, lässt
`cd packages/combat ; dart test` laufen; ein Test hält es fest.

**Der Gegner spielt nach denselben Regeln wie der Spieler**
([ADR-0023](docs/decisions/0023-der-gegner-spielt-nach-denselben-regeln.md)).
Er tippt (eine zufällige Stelle, gewertet mit denselben Fenstern), er kann
perfekt treffen, und er greift manchmal zu Schutz oder Umgebung — mit einer
Quote je Gegner in `enemy.dart`. Zwei Regeln stehen deshalb an genau einer
Stelle, und dort müssen sie bleiben:

| Frage | Antwortet |
|---|---|
| Wird bei diesem Zug getippt? | `Move.hasTimingWindow` |
| Was ist eine Stelle auf der Leiste wert? | `TimingSpec.judgeAt` |

`hasTimingWindow` ist **abgeleitet**, nicht gesetzt: Wer einer Fähigkeit
eine Perfect-Wirkung gibt, gibt ihr damit auch die Leiste. Wer eine ohne
Perfect-Wirkung baut, bekommt bewusst keine — *Sammeln* und *Atemzug* sind
genau dieser Fall.

**Ein Feld am Gegner, das Verhalten steuern soll, braucht einen Test auf
das Verhalten.** `EnemyBlueprint.loadout` wurde jahrelang gepflegt und
nirgends gelesen; jeder Gegner kämpfte mit dem Standard-Moveset, und die
Staffelung aus ADR-0022 galt im Code nicht. Details in `gotchas.md`.

**Der Kampf hängt am Moveset, und das ist eine gemessene Zahl.**
Mit nur einem Move ist der erste Gegner unschlagbar (0 % in der
Simulation), mit zweien sicher (100 %). Seit
[ADR-0025](docs/decisions/0025-handbuch-sperrt-den-baum.md) ist das die
**einzige** Bedingung: `combatUnlockedProvider` fragt nur noch das
Moveset.

**Das Handbuch sperrt dafür den Baum.** Solange es offen ist, *ist* es
der Theorie-Bildschirm. Die Kette greift damit unverändert — ohne
Handbuch kein Baum, ohne Baum keine zweite Fähigkeit, ohne zweite
Fähigkeit kein Kampf. Sie steht nur nicht mehr an zwei Stellen.

Das Handbuch war nie der Grund, immer ein Stellvertreter, und das war
kein Zufall: Die fünf Lektionen geben 275 Erfahrung und damit Level 3 —
die Stufe, auf der der zweite Fähigkeitsslot aufgeht (vier Lektionen
reichen **nicht**, 220 XP). Bis ADR-0019 passte in den Slot immer etwas,
weil vier Fähigkeiten von Anfang an offen waren; seit sie an
Theorieknoten hängen, kann er aufgehen und leer bleiben.

Die Arithmetik gilt weiter und wird weiter geprüft: Wer an
`TheoryRewards`, der Levelkurve oder der Länge des Zweigs dreht, lässt
`flutter test test/progression_test.dart` laufen. Wer an den
Fähigkeitsquellen oder den Theoriepunkten dreht, zusätzlich
`flutter test test/abilities_seam_test.dart` — dort steht, dass auf der
Stufe, auf der der zweite Platz aufgeht, ein Knoten mit Fähigkeit
erreichbar und bezahlbar sein muss.

**Vier Kurven müssen zusammenpassen.** Belohnung (`theory/rewards.dart`),
Häkchen-Ertrag (`habits/rewards.dart`), Level
(`progression/level_curve.dart`) und Preise (`gear/prices.dart`) hängen
zusammen: Passen sie nicht, wird der Baum zur Sackgasse — oder er öffnet sich
in zwei Tagen komplett, oder der Laden ist leer gekauft, bevor er interessant
wird. `flutter test test/progression_test.dart` spielt alles durch und meldet
genau das. Wer eine dieser Zahlen ändert, lässt diesen Test laufen.

**Der Kern-Loop verbindet alle sieben Packages.** Lektion (`theory`) schaltet
Vorlage frei (`habits`), Häkchen erzeugt Erfahrung (`progression`),
Charakterwerte und Gold, Gold kauft Ausrüstung (`gear`), die Waffe bringt
eine Fähigkeit mit (`abilities`), Werte plus Ausrüstung plus Fähigkeiten
gehen in den Kampf (`combat`), Streaks und Lektionen verdienen Titel
(`identity`).

Es gibt genau **neun** Stellen, an denen etwas zusammenläuft:

| Provider | führt zusammen |
|---|---|
| `totalXpProvider` | Erfahrung aus Theorie und Gewohnheiten |
| `goldProvider` | Gold aus allen Quellen |
| `equippedStatsProvider` | Kampfwerte aus Gewohnheiten und Ausrüstung |
| `titleStatsProvider` | die drei Zahlen hinter den Titeln |
| `abilityProgressProvider` | Waffe, Streak und Theorie für die Freischaltung |
| `activeMovesProvider` | das Moveset, mit dem gekämpft wird |
| `availableTheoryPointsProvider` | Level und Baum — freie Theoriepunkte |
| `passedPagesProvider` | bestandene Seiten aus Handbuch **und** Graph |
| `combatUnlockedProvider` | ob der Kampf offensteht (ADR-0020) |

**`passedPagesProvider` gibt es, weil `passedCountIn(theoryTree)` seit
ADR-0019 zu wenig zählt** — zwölf von neunundzwanzig Seiten liegen nur
im Graphen. Wer bestandene Seiten braucht, nimmt diesen Provider und
nicht den Baum.

`activeMovesProvider` ist die einzige Stelle, an der die Freischaltbedingung
für Fähigkeiten **gilt** — der Spielstand hält eine Wahl, geprüft wird
beim Zusammenstellen. In den Kampf gehen sie ausschließlich über
`_freshFight()` in `combat_controller.dart`, und das Moveset friert dort
beim Start ein.

**Fähigkeiten hängen an Ids, und Ids können ins Leere zeigen.**
`packages/abilities` kennt weder `combat` noch `gear` — es hält nur
Move-Ids und Waffen-Ids. Was daraus wird, prüft
`test/abilities_seam_test.dart` in der App: jede Move-Id kommt in
`combat` an, jede Waffe im Laden bringt eine Fähigkeit mit, und jeder
Waffenmove **erzeugt** Energie. Der letzte Punkt ist keine Kosmetik:
Auf Level 1 ist nur der Waffenslot offen
([ADR-0017](docs/decisions/0017-faehigkeitskatalog-aus-drei-quellen.md)).

**Der Entwicklermodus ist nur im Debug-Build vorhanden** und arbeitet auf
einem **eigenen Spielstand** ([ADR-0021](docs/decisions/0021-entwicklermodus-mit-eigenem-spielstand.md)).
Er schenkt Zuschläge als benannten Summanden, statt Lektionen oder Häkchen
zu erfinden. Wer an einer abgeleiteten Zahl dreht, lässt
`flutter test test/dev_mode_test.dart` laufen — dort steht die Zusage, dass
**ohne** Zuschläge jede Formel unverändert ist.

**Fortschritt überlebt einen Neustart, aber nur über eine Stelle.**
Geschrieben wird ausschließlich in `lib/save/save_watcher.dart`. Wer einen
sechsten Bereich baut, trägt ihn dort ein — sonst funktioniert alles, nur
gespeichert wird nichts. Serialisierung gehört ins jeweilige Package
(`toJson`/`fromJson`), nicht nach `lib/`. Alle `fromJson` sind bewusst
nachsichtig: Unbekanntes wird übersprungen, nie geworfen ([ADR-0010](docs/decisions/0010-persistenz-hinter-einem-anschluss.md)).

## Gedächtnis-Protokoll

Diese sechs Orte sind das geteilte Gedächtnis. Sie zu pflegen ist Teil der Arbeit,
nicht Nacharbeit:

| Datei | Enthält | Wann aktualisieren |
|---|---|---|
| `konzept.md` | Produktvision, Systeme, MVP-Schnitt | wenn sich das Produkt ändert |
| `docs/context/state.md` | Was fertig ist, woran gerade gearbeitet wird, was als Nächstes kommt | am Ende jeder Arbeitssitzung |
| `docs/context/ziele.md` | **Wohin** es geht: Ziellinie, SMART-Ziele mit Termin, und was ausdrücklich *nicht* dazugehört | freitags die Ist-Spalten; bei Zielwechsel sofort |
| `docs/decisions/NNNN-*.md` | **Warum** eine Entscheidung so fiel | sobald eine Entscheidung fällt, die man in drei Monaten hinterfragen würde |
| `docs/context/gotchas.md` | Fallstricke, die Zeit gekostet haben | sobald etwas unerwartet war |
| `docs/vorlagen/` | Entwürfe, aus denen gebaut wird — Fähigkeiten, später das Kampfsystem | sobald eine Vorlage entsteht, **bevor** danach gebaut wird |

**Eine Vorlage, die nur auf einem Rechner liegt, existiert für den anderen
nicht.** Genau das ist bei `Kampfsystem.docx` passiert: In `state.md` steht
seit dem 22.08., dass sie „noch nicht im Repo" und nicht auffindbar ist —
und deshalb ist der Kampfsystem-Umbau bis heute unentschieden. Dem
Fähigkeiten-Set ist es beinahe genauso ergangen. Deshalb gilt: Wer nach
einem Dokument baut, legt das Dokument zuerst hierher.

`state.md` und `ziele.md` sind ein Paar und dürfen sich nie widersprechen:
Was in `ziele.md` als erreicht gilt, steht in `state.md` unter „Fertig". Die
Reihenfolge unter „Als Nächstes" folgt den Zielen, nicht umgekehrt.

**Für Claude:** Am Ende jeder Sitzung, in der etwas Substanzielles passiert ist:
`docs/context/state.md` aktualisieren. Bei einer Richtungsentscheidung zusätzlich
einen ADR anlegen (Vorlage: `docs/decisions/TEMPLATE.md`, fortlaufend nummeriert).
Niemals ADRs nachträglich umschreiben — überholte Entscheidungen bekommen den
Status `Abgelöst durch ADR-NNNN`.

Wird eine Aufgabe angefangen, die in `ziele.md` unter „Was **nicht** im MVP
ist" steht, ist das ein Grund nachzufragen — nicht, sie stillschweigend zu
erledigen.

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
