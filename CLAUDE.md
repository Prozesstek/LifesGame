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
| Kampf (die Grube) | Flame | nur als eingebettetes Widget |
| Persistenz | `SaveStore` + shared_preferences | offline-first, Drift verschoben ([ADR-0010](docs/decisions/0010-persistenz-hinter-einem-anschluss.md)) |
| State | Riverpod | — |
| Animationen | Rive | Skills und Treffer |

**Architektur-Kernregel:** Kampflogik ist reines Dart **ohne Flame-Imports**.
Die Logik gibt Events aus, Flame spielt sie nur ab. Begründung: [ADR-0002](docs/decisions/0002-kampflogik-ohne-flame.md)

Diese Regel ist nicht nur Vereinbarung: `packages/action_combat` hat einen
leeren `dependencies`-Block, ein Flame-Import schlägt dort schlicht fehl.
Sie galt vorher für den Rundenkampf in `packages/combat` ([ADR-0003](docs/decisions/0003-combat-als-eigenes-package.md));
der ist seit [ADR-0039](docs/decisions/0039-die-grube-ersetzt-den-rundenkampf.md)
durch die Grube ersetzt und gelöscht.

## Aufbau

| Pfad | Inhalt | Braucht |
|---|---|---|
| `packages/theory/` | Skillbaum-Graph, Inhalte, Lernfortschritt, reines Dart, 148 Tests | nur Dart-SDK |
| `packages/theory/lib/src/review.dart` | die **Rückfrage des Tages**: welche Seite fällig ist, und in welchem Abstand sie wiederkommt ([ADR-0045](docs/decisions/0045-rueckfrage-des-tages.md)) | nur Dart-SDK |
| `packages/theory/lib/src/content/` | die Lektionen selbst — hier wird geschrieben | nur Dart-SDK |
| `packages/theory/lib/src/content/theory_graph_content.dart` | **der Baum selbst**: vier Wurzeln, wer an wem hängt | nur Dart-SDK |
| `packages/theory/lib/src/node_graph.dart` | Struktur des Graphen, `canOpen`, Gesundheitsprüfung | nur Dart-SDK |
| `packages/theory/lib/src/skill_tree.dart` | die alten flachen Zweige — trägt nur noch das Handbuch | nur Dart-SDK |
| `packages/progression/` | Levelkurve, Fähigkeitsslots, Theoriepunkte, **Machtkurve**, reines Dart, 41 Tests | nur Dart-SDK |
| `packages/progression/lib/src/level_up.dart` | was ein **Aufstieg** bringt — Macht, Theoriepunkte, Plätze | nur Dart-SDK |
| `packages/progression/lib/src/ability_slots.dart` | ab welchem Level welcher Slot aufgeht | nur Dart-SDK |
| `packages/progression/lib/src/power_curve.dart` | was ein Level im Kampf **vervielfacht** ([ADR-0042](docs/decisions/0042-macht-vervielfacht.md)) | nur Dart-SDK |
| `packages/progression/lib/src/theory_points.dart` | ein Theoriepunkt je Aufstieg ([ADR-0035](docs/decisions/0035-ein-theoriepunkt-je-level.md)) | nur Dart-SDK |
| `packages/habits/` | Gewohnheiten, Streaks, Charakterwerte, reines Dart, 191 Tests | nur Dart-SDK |
| `packages/habits/lib/src/catalog.dart` | die Vorlagen selbst — verknüpft mit Lektion und Stat | nur Dart-SDK |
| `packages/habits/lib/src/habit.dart` | `Habit`, Vorlage und **eigene** Gewohnheit, Grad, Ziel | nur Dart-SDK |
| `packages/habits/lib/src/daily_form.dart` | die **Tagesform**: was heute abgehakt ist, macht heute stärker ([ADR-0043](docs/decisions/0043-tagesform.md)) | nur Dart-SDK |
| `packages/habits/lib/src/daily_chest.dart` | die **Tagestruhe**: aus dem Datum gewürfelt, einmal je erledigtem Tag ([ADR-0044](docs/decisions/0044-tagestruhe.md)) | nur Dart-SDK |
| `packages/habits/lib/src/week_summary.dart` | der **Wochenrückblick**: was eine Woche gebracht hat, aus der Historie | nur Dart-SDK |
| `packages/habits/lib/src/streak_freeze.dart` | das **Streak-Eis** und wie viele es davon gibt | nur Dart-SDK |
| `packages/habits/example/curve_sim.dart` | 90 Tage Ertrag und Werte durchspielen | nur Dart-SDK |
| `packages/gear/` | Ausrüstung, Preise, Inventar, reines Dart, 90 Tests | nur Dart-SDK |
| `packages/gear/lib/src/catalog.dart` | die Ausrüstungsstücke selbst | nur Dart-SDK |
| `packages/gear/lib/src/prices.dart` | alle Preise | nur Dart-SDK |
| `packages/gear/lib/src/set_catalog.dart` | die **drei Sets** und ihre Wirkung | nur Dart-SDK |
| `packages/gear/lib/src/gates.dart` | ab welcher Sprosse Episch und Legendär kaufbar sind | nur Dart-SDK |
| `lib/gear/weapon_ability_line.dart` | was eine Waffe an Fähigkeit mitbringt — reine Rechnung | Flutter |
| `lib/gear/widgets/rarity_badge.dart` | die Seltenheit als Marke, samt Farben | Flutter |
| `packages/abilities/` | woher eine Fähigkeit kommt, reines Dart, 36 Tests | nur Dart-SDK |
| `packages/abilities/lib/src/ability_catalog.dart` | die Fähigkeiten und ihre Bedingungen | nur Dart-SDK |
| `packages/identity/` | Name und verdiente Titel (nur der Wortlaut), reines Dart, 25 Tests | nur Dart-SDK |
| `packages/identity/lib/src/title_catalog.dart` | die **dreizehn** Titel und ihr Wortlaut — Bedingungen stehen woanders | nur Dart-SDK |
| `packages/achievements/` | Errungenschaften, reines Dart, 24 Tests | nur Dart-SDK |
| `packages/achievements/lib/src/catalog.dart` | die **19 Meilensteine und 8 Entdeckungen** samt Bedingungen | nur Dart-SDK |
| `packages/achievements/lib/src/rewards.dart` | was eine Stufe einbringt — Erfahrung, Gold, Ruhm | nur Dart-SDK |
| `packages/achievements/lib/src/stats.dart` | die Zahlen, die hereingereicht werden — **jede darf nur steigen** | nur Dart-SDK |
| `packages/action_combat/` | **die Grube — der Kampf des Spiels** ([ADR-0039](docs/decisions/0039-die-grube-ersetzt-den-rundenkampf.md)), Echtzeit, reines Dart, 186 Tests | nur Dart-SDK |
| `packages/action_combat/lib/src/ladder.dart` | wie weit jemand gekommen ist, und was eine Stufe einbringt | nur Dart-SDK |
| `packages/action_combat/lib/src/balance.dart` | alle Stellschrauben der Grube, Fähigkeiten und Stufen eingeschlossen | nur Dart-SDK |
| `packages/action_combat/lib/src/pit_ability.dart` | was eine Fähigkeit **in der Grube tut** — Mana, Abklingzeit, Wirkungen als Daten | nur Dart-SDK |
| `packages/action_combat/lib/src/dailies.dart` | **die vier Stufen des Tages** — gewürfelt aus dem Datum ([ADR-0040](docs/decisions/0040-vier-dailies-je-tag.md)) | nur Dart-SDK |
| `packages/action_combat/lib/src/aim.dart` | **wohin eine Fähigkeit wirkt** — Selbstzielen, Skillshot, abgesetzte Flächen, Vorschau | nur Dart-SDK |
| `packages/action_combat/lib/src/pit_modifier.dart` | wie **Sets und legendäre Kräfte** Fähigkeiten verändern — und die sechs Kräfte selbst | nur Dart-SDK |
| `packages/action_combat/lib/src/boss.dart` | **der Wächter**: Bodenstoss, Felswurf, Ansturm, Wut — und was er ankündigt | nur Dart-SDK |
| `packages/action_combat/lib/src/pit_weapon.dart` | was die **Waffe** aus dem Grundangriff macht — Bogen schiesst, Spalter trifft alle | nur Dart-SDK |
| `packages/action_combat/lib/src/stage.dart` | die **dreissig Stufen** — wie aus einer Stufe ein Faktor wird | nur Dart-SDK |
| `packages/action_combat/lib/src/room_catalog.dart` | die **Räume**, aus denen jede Grube gesteckt wird — hier wird geschrieben | nur Dart-SDK |
| `packages/action_combat/lib/src/level_builder.dart` | steckt die Räume gesät zu einer Grube zusammen | nur Dart-SDK |
| `packages/action_combat/lib/src/level_catalog.dart` | die feste Halle des Prototyps, nur noch im Entwicklermodus | nur Dart-SDK |
| `packages/action_combat/example/headless_run.dart` | spielt eine Halle ohne Bildschirm durch, mit drei Machtstufen | nur Dart-SDK |
| `lib/action/` | die Darstellung dazu — Figuren, Steuerkreuz, Kopfzeile | Flutter |
| `lib/action/pit_screen.dart` | ein Lauf durch eine Stufe — **die einzige Stelle**, die ein Ergebnis in die Reihe trägt | Flutter |
| `lib/action/pit_run_view.dart` | Spielfeld, Steuerung, Kopfzeile, **Tasten** — geteilt mit dem Prototyp | Flutter |
| `lib/action/pit_gate.dart` | ob die Grube offensteht, und warum nicht | Flutter |
| `lib/action/hero_power.dart` | womit der Held in die Grube geht — Werte, Level, Seltenheit, **eine Stelle** | Flutter |
| `lib/action/pit_tints.dart` | welche Farbe die Fläche einer Fähigkeit trägt — **eine Tabelle** | Flutter |
| `lib/action/pit_text.dart` | Name und Beschreibung einer Fähigkeit oder Waffe — **eine Stelle** für alle Bildschirme | Flutter |
| `lib/action/action_sprites.dart` | wer in der Grube wie aussieht — Bild je Gegnerart, **eine Tabelle** | Flutter |
| `tool/pit_sim.dart` | prüft die **Grube**: alle dreissig Stufen gegen den echten Werte-Pfad | nur Dart-SDK |
| `lib/main.dart` | App-Shell, Theme, lädt den Spielstand vor `runApp` | Flutter |
| `lib/home/home_screen.dart` | Startbildschirm: Figur in der Mitte, fünf Kreise darum | Flutter |
| `lib/home/widgets/hub_circle.dart` | ein Bereich als runder Knopf, samt Sperrgrund | Flutter |
| `lib/home/widgets/character_stage.dart` | die Figur und ihre Zahlen | Flutter |
| `lib/save/save_data.dart` | der ganze Spielstand als ein Wert | Flutter |
| `lib/save/save_store.dart` | der Anschluss, hinter dem die Speichertechnik liegt | Flutter |
| `lib/save/save_watcher.dart` | **die einzige Stelle, die schreibt** | Flutter |
| `lib/habits/day_watcher.dart` | hält „heute" über Mitternacht aktuell — **muss** in `main.dart` hängen | Flutter |
| `lib/progression/level_provider.dart` | Level und Gold aus allen Quellen, **rechnet nicht** | Flutter |
| `lib/habits/habits_controller.dart` | Riverpod-Brücke Tracker ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/habits/habits_screen.dart` | Werte, Tagesliste, Vorlagen, eigene Gewohnheiten | Flutter |
| `lib/habits/week_review_screen.dart` | der Wochenrückblick, der sich aufbaut — sonntags und montags gross angekündigt | Flutter |
| `lib/habits/widgets/custom_habit_sheet.dart` | das Formular für eine eigene Gewohnheit | Flutter |
| `lib/habits/widgets/streak_ladder_card.dart` | was eine Kette einbringt, als Leiter | Flutter |
| `lib/habits/widgets/streak_freeze_card.dart` | der Knopf, der gestern deckt — nur wenn es etwas zu retten gibt | Flutter |
| `lib/gear/gear_controller.dart` | Riverpod-Brücke Inventar ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/gear/shop_screen.dart` | der Laden: Reiter je Platz, Raster, Detailfläche | Flutter |
| `lib/gear/widgets/shop_item_cell.dart` | ein Stück als Kachel im Raster — wählt, kauft nicht | Flutter |
| `lib/character/character_screen.dart` | Kopf, Beständigkeit, Werte mit Herkunft, Ausrüstungsraster | Flutter |
| `lib/character/widgets/consistency_card.dart` | die Streak-Zahlen und der Satz darunter | Flutter |
| `lib/character/widgets/ability_slots_row.dart` | die vier Fähigkeitsplätze, wählen und räumen | Flutter |
| `lib/character/abilities_controller.dart` | Riverpod-Brücke Fähigkeiten ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/character/identity_controller.dart` | Riverpod-Brücke Identität ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/character/ability_unlock.dart` | was neu ist und wohin es passt — reine Rechnung | Flutter |
| `lib/character/show_ability_unlock.dart` | die Feier, aufgerufen an genau zwei Stellen | Flutter |
| `lib/progression/show_level_up.dart` | die Feier eines **Aufstiegs** — nach den Errungenschaften, vor den Fähigkeiten | Flutter |
| `lib/village/village_map.dart` | **das Dorf (Prototyp)**: Karte als Text, Wege, Laufen, Türen, reines Dart, ohne Bildschirm testbar | Flutter |
| `lib/village/village_screen.dart` | das Dorf im Entwicklermodus: Tippen geht hin, Ziehen steuert, **hinein nur über den Knopf am Gebäude**, „Heute“ immer einen Tipp entfernt | Flutter |
| `tool/dorf_kacheln.py` | zeichnet die groben Dorfkacheln nach `assets/Dorf/` (Python mit Pillow) | Python |
| `lib/dev/dev_screen.dart` | Entwicklermodus, **nur im Debug-Build** | Flutter |
| `lib/dev/debug_grants.dart` | was der Dev-Modus verschenkt hat | Flutter |
| `lib/dev/save_slot.dart` | echter Stand vs. Dev-Stand | Flutter |
| `lib/audio/sound_effects.dart` | welcher Klang zu welchem Moment gehört — **eine Tabelle**, in Tests stumm | Flutter |
| `lib/ui/holz.dart` | Planke, Rahmen, Balken, Knopf aus dem UI-Paket — **über das Theme**, nicht je Knopf; `HolzKarte`, `HolzDialog`, `HolzBlatt` für jede Fläche | Flutter |
| `lib/ui/aufstieg.dart` | **Zahlen steigen dort auf, wo getippt wurde** — der Host merkt sich den Finger | Flutter |
| `lib/ui/druck.dart` | **jeder Knopf gibt nach** — `Druck` für Eigenes, `Druck.builder` im Theme | Flutter |
| `lib/ui/palette.dart` | alle Farben der App — **zwei Untergründe, zwei Sätze** | Flutter |
| `lib/ui/on_dark.dart` | klammert ein, was auf Leder statt Pergament steht | Flutter |
| `lib/ui/pixel_art.dart` | eine Zeichnung fester Größe — **und ob hart oder weich skaliert wird** | Flutter |
| `lib/ui/gold_icon.dart` | die Goldmünze, überall dieselbe | Flutter |
| `lib/ui/phone_frame.dart` | zeigt die App im Browser in Handygröße | Flutter |
| `lib/combat/ladder_controller.dart` | Riverpod-Brücke Reihe ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/combat/ladder_screen.dart` | der Eingang zur Grube: „17 / 30", Stufe, „Hinab" | Flutter |
| `lib/combat/move_icon.dart` | welches Bild zu einer Fähigkeit oder Waffe gehört | Flutter |
| `lib/gear/gear_icon.dart` | welches Bild zu einem Ausrüstungsstück gehört | Flutter |
| `lib/combat/widgets/result_dialog.dart` | das Blatt am Ende eines Laufs | Flutter |
| `lib/theory/theory_controller.dart` | Riverpod-Brücke Inhalt ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/theory/skill_tree_screen.dart` | vier Gebiete zum Wischen, Kopfzeile, Handbuch davor | Flutter |
| `lib/theory/widgets/tree_view.dart` | ein Gebiet: Startknoten unten, eine Ebene darüber | Flutter |
| `lib/theory/widgets/tree_layout.dart` | wo jeder Knoten sitzt — reine Rechnung, testbar | Flutter |
| `lib/theory/widgets/tree_painter.dart` | die Verbindungslinien | Flutter |
| `lib/theory/widgets/node_action_panel.dart` | der Knopf **über** dem Startknoten | Flutter |
| `lib/theory/widgets/node_state.dart` | in welchem Zustand ein Knoten ist — eine Stelle | Flutter |
| `lib/theory/branch_screen.dart` | nur noch das Handbuch: Reihenfolge statt Graph | Flutter |
| `lib/theory/lesson_screen.dart` | lesen → Fragen → Ergebnis | Flutter |

**Schichtregel:** Kampfregeln, Gegnerwerte, Fähigkeiten- und Waffenwirkung
und die Belohnung der Stufen nur in `packages/action_combat`,
Inhalte und Belohnungszahlen nur in `packages/theory`, die Levelkurve nur in
`packages/progression`, Streaks und Charakterwerte nur in `packages/habits`,
Preise, Ausrüstungsboni **und Set-Wirkungen** nur in `packages/gear`,
der **Wortlaut** der Titel nur in
`packages/identity`, Freischaltbedingungen für Fähigkeiten nur in
`packages/abilities`, Bedingungen und Belohnungen von Errungenschaften —
**und damit auch die Bedingungen der Titel** — nur in
`packages/achievements` ([ADR-0033](docs/decisions/0033-errungenschaften-aus-der-historie.md)).
Die Controller reichen durch und halten den laufenden Zustand. Sobald in
`lib/` eine Spielzahl berechnet wird, gehört sie in eines der **acht**
Packages.

```bash
# App
flutter pub get
flutter run -d chrome    # laufen lassen (Windows-Desktop geht mangels VS nicht)
flutter test             # 480 Tests
flutter analyze          # muss sauber sein

# Balance der Grube prüfen -- seit ADR-0039 die maßgebliche Simulation
dart run tool/pit_sim.dart             # 30 Stufen gegen echten Werte-Pfad

# Die Grube allein, ohne Flutter
cd packages/action_combat
dart test                              # 186 Tests
dart run example/headless_run.dart     # eine Halle ohne Bildschirm

# Gewohnheiten allein, ohne Flutter
cd packages/habits
dart test                              # 191 Tests
dart run example/curve_sim.dart        # 90 Tage Ertrag und Werte

# Theorie, Levelkurve, Ausrüstung allein, ohne Flutter
cd packages/theory      ; dart test    # 148 Tests, prüft auch den Inhalt
cd packages/progression ; dart test    # 41 Tests
cd packages/gear        ; dart test    # 90 Tests, prüft Preise, Sets, Verkauf und die Sperre
cd packages/abilities   ; dart test    # 36 Tests
cd packages/identity    ; dart test    # 25 Tests, prüft nur noch den Wortlaut
cd packages/achievements; dart test    # 24 Tests, prüft den ganzen Katalog
```

**Der Kampf ist seit [ADR-0039](docs/decisions/0039-die-grube-ersetzt-den-rundenkampf.md)
die Grube.** Echtzeit, dreissig Stufen, jede Karte neu gesteckt. Der
Rundenkampf ist gelöscht. Die Regeln der Grube stehen an je einer
Stelle:

| Frage | Antwortet |
|---|---|
| Wie hart ist eine Stufe? | `PitStage` — die Zahlen in `ActionBalance` |
| Wie sieht die Grube aus? | `LevelBuilder.build(stage, seed)` aus `RoomCatalog`, **gesät** |
| Was bringt ein Lauf ein? | `LadderController.recordRun` — einmal je Stufe |
| Was tut eine Fähigkeit in der Grube? | `PitAbilities` — **dieselbe Id** wie in `abilities`, sonst wirkt sie nicht |
| Welche Plätze gehen mit? | `activeMovesProvider`, gefiltert in `ActionWorld` — was die Grube nicht kennt, fällt heraus |
| Wie schlägt der Held? | `PitWeapons` — über den **Waffenzug** (`AbilityCatalog.weaponMoves`), nicht die Item-Id |
| Was kann der Held im Kampf? | Grundangriff der Waffe (von selbst) und die drei Plätze — **keine** Grundfähigkeiten; auf der Tastatur 1–3 (`PitRunView`) |
| Was ändern Sets und Legendäre? | `pitModifiersFor` in `lib/gear/set_effects.dart` — rechnet nichts, übersetzt nur |
| Welche Kraft trägt ein legendäres Stück? | `GearItem.legendaryPower` (Id) → `PitLegendaries` (Wirkung) |

**Kurz tippen zielt selbst, halten zielt von Hand.** Jede Fähigkeit
trägt ein `PitAim`: `selbst` (Heilung, Schutz, Mana — wirkt beim
Drücken), `richtung` (Geschoss fliegt genau seine Reichweite, Schlag
trifft im Kegel davor), `umDenHelden` (Klingenwirbel) oder `bereich` —
abgesetzt bis `castRange`, auch hinter eine Wand. **Gezielt wird über
Wände hinweg, gewirkt nicht hindurch**: Ein Bereich landet, wo man
hinzeigt, ein Geschoss bleibt an der Wand hängen. **Was ein Bereich an
Bremsen und Dauerschaden trägt, bleibt als Fläche liegen** und wirkt auf
jeden, der hineinläuft (Eisfeld, Giftboden). `ActionWorld.cast` zielt
selbst und kostet ohne Ziel nichts, `castAt` wirkt dorthin und kostet
immer — ein verfehlter Skillshot ist verfehlt. Was die Vorschau zeigt,
rechnet `aimPreview` aus derselben Stelle (`aim.dart`); der Renderer
zeichnet nur. Rot ist dem Wächter vorbehalten, die Farben der Flächen
stehen in der Palette. `aim_test.dart` und `test/pit_aim_test.dart`.

**Figuren gleiten um Ecken, und breite nehmen breite Wege.** `_slide`
bewegt erst und drückt dann aus der Wand, statt eine blockierte Achse zu
verwerfen. Für Figuren breiter als ein Feld (Troll, Wächter) gibt es ein
zweites Wegfeld, in dem nur Felder in freien 2 × 2-Blöcken zählen; wer
im Gedränge auf der Stelle tritt, geht kurz durch Verbündete hindurch.
`chase_test.dart` läuft durch gebaute Gruben und zählt Verfolger, die
hängen — es müssen null sein.

**Ein Set oder eine Kraft verändert Daten, nicht die Welt.**
`PitModifiers.apply` nimmt eine Fähigkeit und gibt eine neue zurück;
`world.dart` sieht nur das Ergebnis. Die Art einer Fähigkeit
(`PitKind`: Angriff, Umgebung, Schutz) steht am Eintrag — auf sie
wirken die Sets.

Eine Wirkung ist ein **Datum** (`PitEffect`, `sealed`), keine Methode:
Eine neue Art trägt man dort ein, und der Analyzer zeigt auf die eine
Stelle in `world.dart`, die sie ausführt. Das ist die Naht, an der Sets
und Legendäre später eine Fähigkeit verändern. Alle neunzehn Fähigkeiten
sind aus neun Arten gebaut; `test/pit_test.dart` hält fest, dass jede
lernbare Fähigkeit und jede Waffe im Laden in der Grube etwas tut.

**Fünf Gegnerarten** (`EnemyKind`): Fussvolk `e`, Schütze `s`, Kobold `k`
(schneller als der Held), Troll `t` (gross, zäh, setzt meist der
Zufallsbau — auf tieferen Stufen öfter) und der Wächter `B`, **allein in
seinem Raum**. **Wer Schaden nimmt, hat den Helden bemerkt** — auch aus
einer Entfernung, in der er ihn sonst nie sähe (`_enemiesAct`).

**Die Grube ist geschafft, wenn der Wächter fällt** — nicht erst, wenn
jeder Gegner liegt (`ActionWorld._checkEnd`). Nur eine Halle ohne
Wächter, die es nur in Tests gibt, muss man leer räumen.

**Hinter dem Helden fällt das Tor zu, und dann tritt der Wächter auf.**
`LevelBuilder` macht den Gang in den Wächterraum zum Tor (`=` in der
Karte). Bis dahin **schläft** der Wächter unsichtbar und unberührbar
(`ActionEntity.untouchable`). `ActionWorld._updateGate` schliesst das
Tor, sobald der Held ganz drin ist und niemand im Durchgang steht; es
geht nie wieder auf. Dann fällt der Wächter herab
(`ActionBalance.bossEntranceSeconds`), und **erst mit seiner Landung**
gibt es `bossView` — Name und Balken erscheinen wie in Dark Souls, der
Balken läuft über `bossBarFill` voll. Eine Halle ohne Tor hat keinen
Auftritt; dort ist er von Anfang an da. `gate_test.dart` hält alles
fest.

**Jeder Angriff des Wächters ist angekündigt** (`TelegraphView`: ein Ring
oder eine Linie, die sich füllt) und lässt sich durch Laufen umgehen — es
gibt keinen Sturmschritt mehr. Wer einen Angriff dazubaut, gibt ihm eine
Ankündigung, die länger dauert als der Weg hinaus; `boss_test.dart` prüft
das für den Bodenstoss. Welche Angriffe er kennt, hängt an der Stufe
(`bossThrowFromStage`, `bossChargeFromStage`). Ihre Zahlen
stehen in `ActionBalance`, ihr Bild in `GrubeFiguren`.

Ein neuer Raum kommt nach `room_catalog.dart`, genau 14 × 10, und
`level_builder_test.dart` baut danach jede Stufe mit vierzig Startwerten
und prüft jede Karte. Wer an den Stufen dreht, lässt
`dart run tool/pit_sim.dart` laufen.

**Macht vervielfacht, die Gewohnheiten addieren**
([ADR-0042](docs/decisions/0042-macht-vervielfacht.md)). Was aus
Häkchen und Ausrüstungsboni kommt, bleibt additiv und gedeckelt
(ADR-0008); im Kampf vervielfachen es das **Level** (`PowerCurve`, 1,04
je Level) und die **Seltenheit** von Waffe (Angriff) und Rüstung (Leben)
(`GearRarity.powerFactor`). Die Stufen wachsen mit (`PitStage.powerFactor`,
bis `stagePowerLast`), und alle Kampfzahlen stehen mal
`ActionBalance.powerScale`. Zusammengesetzt wird nur in `PitPower.hero`;
die Welt und jede Anzeige nehmen `ActionStats.combatAttack` und die
anderen `combat…`. **Dazu die Tagesform** ([ADR-0043](docs/decisions/0043-tagesform.md)):
Jedes heutige Häkchen vervielfacht heute den Wert seiner Gewohnheit
(Stärke → Angriff, Ausdauer → Leben, Disziplin → Abwehr, Klarheit →
Mana), alles erledigt heißt „In Form" und hebt alle vier. Die Regel steht
in `HabitTracker.formOn`, die Zahlen in `HabitRewards`, der Wortlaut in
`lib/habits/daily_form_text.dart`. **Eine feste Zahl im Kampf ist ein Bug** — sie wäre
zehnmal zu klein.

**Balance ändern heißt simulieren, nicht raten.** Alle Stellschrauben der
Grube stehen in `packages/action_combat/lib/src/balance.dart`, die Zahlen
einer Fähigkeit oder Waffe an ihrem Eintrag. Eine Zahl ändern,
`dart run tool/pit_sim.dart` laufen lassen, die Siegquoten je Stufe
vergleichen. Der Bot dort ist dumm — die Quoten sind eine **untere**
Schranke. Steht eine Zahl in `world.dart` statt in `balance.dart`, ist das
ein Bug.

**Ein Lauf muss enden.** `effects_and_weapons_test.dart` spielt jede Waffe
und jede Fähigkeit einmal durch. Der Anlass stammt aus dem Rundenkampf:
Heilung, die mit dem Leben wuchs, liess dort keinen Kampf mehr enden
(`gotchas.md`). Heilung ist deshalb auch in der Grube ein Anteil, und
Dauerschaden ein Vielfaches des Angriffs.

**Theorie schreiben heißt testen lassen.** Eine neue Seite kommt nach
`packages/theory/lib/src/content/`, ein neuer Knoten zusätzlich in
`theoryGraph` (`theory_graph_content.dart`) — danach `dart test`.
`graph_content_test.dart` läuft über den ganzen Graphen und prüft den Inhalt
mit: eindeutige Ids, genau drei Fragen, gültige `correctIndex`, keine
doppelten Antworten. Und die Struktur: keine Eltern-Id ins Leere,
**kreisfrei**, jede Wurzel mit mindestens fünf Kindern.

Was eine Seite einbringt, steht ausschließlich in `rewards.dart`, und
dort auch die **Rückfrage des Tages** ([ADR-0045](docs/decisions/0045-rueckfrage-des-tages.md)):
eine Frage am Tag aus einer bestandenen Seite, richtig beantwortet mit
Erfahrung und Gold. Die Seite kommt dann nach 1, 3, 7 und 21 Tagen
wieder. Gespeichert wird `ReviewLog`, eine Historie. Ihr Zufluss steht in
`totalXpProvider`, `goldEarnedProvider` **und**
`incomeWithoutAchievementsProvider`, fehlt er in einem, rechnet der
Laden mit anderem Gold als die Anzeige. **Zweige
haben keine Levelsperren mehr** — geöffnet wird über Theoriepunkte
([ADR-0019](docs/decisions/0019-skillbaum-mit-vier-wurzeln.md)). Ein Knoten
kostet einen Punkt, die vier Wurzeln kosten nichts.

**Gewohnheiten ändern heißt ebenfalls simulieren.** Alle Zahlen —
Erfahrung je Häkchen, Streak-Meilensteine, Deckel, Stat-Kurve — stehen in
`packages/habits/lib/src/rewards.dart`. Eine ändern, `curve_sim.dart` laufen
lassen, die 90-Tage-Tabelle vergleichen. Neue Vorlagen kommen nach
`catalog.dart` und brauchen eine Lektion mit passendem `unlocksHabit` —
sonst schlägt `test/habits_theory_test.dart` fehl.

**Der Katalog ist Inhalt, der Tracker ist Nutzerzustand — und seit
[ADR-0028](docs/decisions/0028-eigene-gewohnheiten.md) hält der Tracker
auch Gewohnheiten.** Eine Id wird an **einer** Stelle aufgelöst:
`HabitTracker.definitionFor`, erst Katalog, dann eigene. Wer eine Id in
etwas Anzeigbares verwandelt, fragt dort — sonst entsteht der Fall aus
`gotchas.md`, bei dem zwei Stellen dieselbe Frage verschieden beantwortet
haben.

Drei Regeln zu eigenen Gewohnheiten, die im Code an je einer Stelle
stehen und dort bleiben müssen:

| Frage | Antwortet |
|---|---|
| Wie viele eigene darf jemand anlegen? | `HabitRewards.customSlotsFor` — ein Platz je freigeschalteter Vorlage |
| Was ändert der Schwierigkeitsgrad? | `HabitDifficulty.xpFactor` — nur Erfahrung, nie Gold |
| Was darf sich nachträglich ändern? | `CustomHabit.editable` — nur, was keine Zahl erzeugt |
| In welcher Reihenfolge steht die Tagesliste? | `HabitTracker.dailyListOn` — offene oben, erledigte unten, je nach Priorität |

**Das Streak-Eis deckt einen Tag, verlängert die Kette aber nicht**
([ADR-0036](docs/decisions/0036-streak-eis-als-gegenstand.md)). Drei
Regeln stehen an je einer Stelle:

| Frage | Antwortet |
|---|---|
| Läuft die Kette über diese Lücke? | `HabitTracker._continues` — die einzige Stelle; `streakEndingAt`, `longestStreak` und `totalXp` fragen dort |
| Wie viele Eis hat jemand? | `StreakFreeze.lifetimeStock` plus die Eis aus geöffneten Truhen, minus die Historie der gedeckten Tage |
| Welcher Tag lässt sich noch retten? | `HabitTracker.rescuableDay` — immer nur gestern, und nur wenn dort eine Kette endet |

**Die Quelle der Eis ist die Tagestruhe** ([ADR-0044](docs/decisions/0044-tagestruhe.md),
Issue #46). Wer heute jede laufende Gewohnheit erledigt, öffnet eine
Truhe, deren Inhalt **aus dem Datum gewürfelt** ist (`DailyChest.forDay`):
meist ein paar Münzen, manchmal mehr, gut jede zwölfte ein Streak-Eis,
selten ein Schatz. Die Stufen und ihr Gewicht stehen als `ChestTier` in
`rewards.dart`. Gespeichert wird nur, **an welchen Tagen** geöffnet wurde
(`openedChests`), Gold und Eis werden daraus gerechnet. Das Gold steckt
in `HabitTracker.totalGold` und läuft damit ohne weitere Stelle in den
Goldstand. Im Mittel sind es rund 11 Gold am Tag, knapp die Hälfte der 25,
auf die der Laden ausgelegt ist: Wer an den Gewichten dreht, lässt
`daily_chest_test.dart` laufen.

Der Grad ist gemessen, nicht geschätzt: Fünf „schwere" eigene
Gewohnheiten erreichen Level 50 in 188 Tagen statt in 240. Wer an
`HabitDifficulty` dreht, lässt `flutter test test/progression_test.dart`
laufen — dort steht die Spanne als Test.

**Ausrüstung ändern heißt gegen den Gold-Zufluss rechnen.** Alle Preise
stehen in `packages/gear/lib/src/prices.dart`. Das Package kennt `habits`
nicht und muss den Zufluss deshalb annehmen (25 Gold am Tag); dass die
Annahme stimmt, prüft `test/progression_test.dart` in der App. Neue Stücke
kommen nach `catalog.dart` und werden von `catalog_test.dart` automatisch
mitgeprüft — jedes Stück muss wirken, jeder Platz führt acht (fünf offene, drei verdiente), und teurer
muss **innerhalb einer Seltenheit** auch besser sein ([ADR-0029](docs/decisions/0029-seltenheit-statt-preisleiter.md)).

**Verkauf gibt es seit [ADR-0031](docs/decisions/0031-verkauf-als-versenkte-kosten.md),
und die Hälfte bleibt versenkt.** Der Satz steht als
`GearPrices.refundShare`. Wer das anfasst, muss den Grund kennen: Gold ist
abgeleitet, also gäbe ein Verkauf **von selbst den vollen Preis zurück** —
das Stück fällt einfach aus `spentGold` heraus. Der zweite Summand
(`Loadout.lostGold`, gerechnet aus `soldIds`) ist das, was das verhindert.

`soldIds` ist eine **Historie**, kein Kontostand — dieselbe Bauform wie
die Häkchen. Ein gespeicherter Goldstand könnte von der Rechnung
abweichen, eine Historie *ist* die Rechnung. Und sie muss von jeder
Methode weitergereicht werden, die ein neues `Loadout` baut; wer eine
vergisst, verschenkt Gold. Ein Test in `loadout_test.dart` geht deshalb
den Weg verkaufen → kaufen → anlegen → ablegen.

**Sets ändern heißt: den Set-Katalog anfassen, nicht die Engine.** Alle
drei stehen in `packages/gear/lib/src/set_catalog.dart`, welche Stücke
dazugehören steht als `setId` **am Stück** ([ADR-0030](docs/decisions/0030-sets-wirken-auf-eine-art-von-faehigkeit.md)).
Drei Regeln bleiben an je einer Stelle:

| Frage | Antwortet |
|---|---|
| Welche Art von Fähigkeit ist das? | `PitAbility.kind` |
| Was ändert ein Set in der Grube? | `pitModifiersFor` — übersetzt `SetPerk` in `PitModifier` |
| Welche Sets liegen an? | `Loadout.activeSets` — gezählt, nie gespeichert |

Ein Set wirkt nie auf den **Grundangriff**: Der ist keine Fähigkeit,
sondern die Waffe. Ein Faktor auf das, was jede halbe Sekunde fällt,
entschiede den Kampf allein (ADR-0009, einmal im Rundenkampf gemessen).

**Die Waffe ist dabei der Sonderfall.** Sie ist der einzige Platz, dessen
Stück den **Grundangriff** bestimmt (`PitWeapons`), und keine zwei
schlagen gleich. Eine neunte Waffe braucht deshalb einen neunten Zug in
`PitWeapons` — sonst fällt `test/abilities_seam_test.dart` um.

**Episch und Legendär sind verdient, nicht nur gekauft**
([ADR-0034](docs/decisions/0034-episch-und-legendaer-haengen-an-der-gegnerreihe.md)).
Die zwei Sprossen stehen in `GearGates` — eine Frage, eine Stelle — und
`Loadout.blockFor` prüft sie **vor** dem Gold. Der dritte Parameter
`highestRung` hat den Standardwert 0, und das ist die sichere Richtung:
Wer ihn vergisst, bekommt eine Sperre, keinen Bypass. Tests, die den
ganzen Katalog kaufen, setzen ihn auf `GearGates.legendaryRung`. Dass
die Sprossen in der Reihe existieren, prüft
`flutter test test/gear_gates_seam_test.dart`.

**Fähigkeiten ändern heißt: den Katalog anfassen, nicht die Welt.**
Alle neunzehn stehen in `packages/action_combat/lib/src/pit_ability.dart`,
ihre Bedingungen in `packages/abilities` ([ADR-0022](docs/decisions/0022-faehigkeiten-set-aus-der-vorlage.md), ADR-0039).
Schaden ist immer `Angriff × power` — sonst hängt die Fähigkeit nicht mehr
am Angriffswert und damit nicht mehr an den Gewohnheiten. Dauerschaden ist
ein Vielfaches des Angriffs, Heilung ein Anteil des Lebens, nie eine
feste Zahl.

Die Vorlage selbst liegt seit dem 26.08. im Repo:
[`docs/vorlagen/faehigkeiten.md`](docs/vorlagen/faehigkeiten.md). Sie sagt,
was eine Fähigkeit **sein soll** — Wirkung, Icon, Animation. Sie wurde für
den Rundenkampf geschrieben; ihre Timing-Angaben gelten in der Grube
nicht. Quelle der Wahrheit für die Zahlen ist der Katalog.

**Ein Feld, das Verhalten steuern soll, braucht einen Test auf das
Verhalten.** Im Rundenkampf wurde `EnemyBlueprint.loadout` lange gepflegt
und nirgends gelesen (`gotchas.md`). Deshalb prüft `pit_test.dart`, dass
eine Stufe die Gegner **wirklich** härter macht, nicht nur, dass der
Faktor steigt.

**Die Grube hängt am Moveset** — Waffe plus eine Fähigkeit
(`lib/action/pit_gate.dart`). Gemessen wurde die Zahl im Rundenkampf, wo
ein einzelner Zug den ersten Gegner unschlagbar machte. In der Grube ist
Stufe 1 auch ohne Fähigkeit schlagbar; die Sperre bleibt, weil sie die
Kette trägt, und ADR-0039 vermerkt sie als offen. Seit
[ADR-0025](docs/decisions/0025-handbuch-sperrt-den-baum.md) ist sie die
**einzige** Bedingung.

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

**Der Kampf zahlt seit [ADR-0032](docs/decisions/0032-gegnerreihe-statt-dungeon.md)
ein — aber genau einmal je Stufe.** Bis dahin gab er ausdrücklich
nichts: `konzept.md` Abschnitt 2 macht ihn zur Auszahlung des
Fortschritts, nicht zu seiner Quelle. Der Einwand galt jedoch nur
*wiederholbarer* Belohnung. Die Grube hat dreißig Stufen, jede zahlt
einmal, und der Gesamtbetrag steht deshalb als Zahl fest
(`LadderRewards.lifetimeXp`). Wer daran dreht, lässt
`flutter test test/progression_test.dart` laufen — der Kampf hängt jetzt
mit in den vier Kurven.

**Seit [ADR-0040](docs/decisions/0040-vier-dailies-je-tag.md) zahlen vier
Stufen des Tages noch einmal** — ein Viertel des Erstsiegs
(`LadderRewards.dailyShare`), einmal je Stufe und Tag, und **nur an Tagen
mit einem Häkchen** (`dailiesUnlockedProvider`). Welche vier, würfelt
`PitDailies.forDay` aus dem Datum; `LadderProgress` friert sie beim
ersten Gebrauch ein und hält die geschafften als Historie. Die
Obergrenze je Tag steht als `maxDailyXpPerDay` und `maxDailyGoldPerDay`.
Wer an `dailyShare` dreht, rechnet gegen die 25 Gold am Tag, auf die der
Laden ausgelegt ist.

**Seit [ADR-0041](docs/decisions/0041-beute-je-gegner.md) fällt der
Betrag je Gegner** — derselbe Topf, anders ausgeschüttet. Die Reihe
reicht der Welt den **Rest** des Topfs (`LadderProgress.potFor`), die
Welt zahlt je Kill ihren Teil (`LootDropped`, 70 % aufs Fussvolk, der
Wächter füllt auf), und `LadderProgress.bookRun` bucht am Ende — gekappt
auf den Topf. Ein verlorener Lauf behält, was gefallen ist. **Mehr als
der Topf zählt nie**: Wer daran rührt, lässt `loot_test.dart` laufen.

**Der Kern-Loop verbindet alle acht Packages.** Lektion (`theory`) schaltet
Vorlage frei (`habits`), Häkchen erzeugt Erfahrung (`progression`),
Charakterwerte und Gold, Gold kauft Ausrüstung (`gear`), die Waffe bringt
den Grundangriff mit, der Baum die Fähigkeiten (`abilities`), Werte plus Ausrüstung plus Fähigkeiten
gehen in die Grube (`action_combat`), und alles zusammen verdient
Errungenschaften (`achievements`), die Titel (`identity`) und vier
Fähigkeiten vergeben.

Es gibt genau **dreizehn** Stellen, an denen etwas zusammenläuft:

| Provider | führt zusammen |
|---|---|
| `totalXpProvider` | Erfahrung aus Theorie, Gewohnheiten, Reihe, Errungenschaften **und Rückfragen** (ADR-0045) |
| `goldProvider` | Gold aus allen Quellen |
| `equippedStatsProvider` | Kampfwerte aus Gewohnheiten und Ausrüstung |
| `achievementStatsProvider` | **die breiteste** — alle vier Bereiche für die Errungenschaften |
| `earnedTitleIdsProvider` | welche Titel verdient sind (ADR-0033) |
| `abilityProgressProvider` | Waffe, Streak, Theorie **und Errungenschaft** für die Freischaltung |
| `activeMovesProvider` | die Ids, mit denen in die Grube gegangen wird — Waffenzug zuerst |
| `availableTheoryPointsProvider` | Level und Baum — freie Theoriepunkte |
| `passedPagesProvider` | bestandene Seiten aus Handbuch **und** Graph |
| `combatUnlockedProvider` | ob die Grube offensteht (ADR-0020) |
| `activeSetsProvider` | welche Ausrüstungs-Sets wirken (ADR-0030) |
| `ladderProvider` | wie weit die Grube gegangen ist (ADR-0032, ADR-0039) |
| `heroPowerProvider` | Werte, Level, Seltenheit **und Tagesform** zur Stärke in der Grube (ADR-0042, ADR-0043) |

**Zwei davon lösen einen Zirkelbezug auf, und das ist kein Zufall.**
Errungenschaften im Laden zahlen Gold, und ob sie verdient sind, hängt
am Inventar — `goldProvider` zeigt damit über die Errungenschaften
wieder auf `loadoutProvider`. Der `GearController` darf ihn beim Kauf
deshalb nicht lesen (`gotchas.md`). Er nimmt stattdessen
`incomeWithoutAchievementsProvider` und legt seinen eigenen Anteil über
`achievementStatsWithLoadout` selbst dazu — dieselbe Auflösung wie
seinerzeit beim Abzug von `spentGold`.

**Errungenschaften werden abgeleitet, nie gezählt** (ADR-0033). Wer eine
neue einträgt, bekommt sie rückwirkend: Ein Stand, der die Bedingung
längst erfüllt, hat sie beim nächsten Start. Drei Regeln stehen deshalb
an je einer Stelle:

| Frage | Antwortet |
|---|---|
| Ist sie verdient? | `Achievement.isEarnedBy` — eine Messung gegen ein Ziel |
| Welche Schwelle gilt? | `AchievementThresholds` in `lib/achievements/` |
| Welcher Titel ist verdient? | `AchievementCatalog.earnedTitleIdsBy` |

**Jede Zahl in `AchievementStats` darf nur steigen.** Eine, die fallen
kann, macht eine Errungenschaft zurücknehmbar — deshalb steht dort die
längste Kette statt der laufenden, „je besessen" statt „getragen", die
höchste Stufe statt der nächsten. Wer eine ergänzt, lässt
`flutter test test/achievements_seam_test.dart` laufen.

**`passedPagesProvider` gibt es, weil `passedCountIn(theoryTree)` seit
ADR-0019 zu wenig zählt** — zwölf von neunundzwanzig Seiten liegen nur
im Graphen. Wer bestandene Seiten braucht, nimmt diesen Provider und
nicht den Baum.

`activeMovesProvider` ist die einzige Stelle, an der die Freischaltbedingung
für Fähigkeiten **gilt** — der Spielstand hält eine Wahl, geprüft wird
beim Zusammenstellen. In die Grube gehen sie ausschließlich über
`PitScreen._neuerLauf`, und die Plätze frieren dort beim Betreten ein.

**Fähigkeiten hängen an Ids, und Ids können ins Leere zeigen.**
`packages/abilities` kennt weder `action_combat` noch `gear` — es hält nur
Move-Ids und Waffen-Ids. Was daraus wird, prüfen
`test/abilities_seam_test.dart` und `test/pit_test.dart` in der App: jede
lernbare Id wirkt in der Grube, jede Waffe im Laden wird ein
Grundangriff, **keine zwei schlagen gleich**, und kein Waffenzug ist
zugleich eine Fähigkeit. Auf Level 1 ist nur der Waffenplatz offen
([ADR-0017](docs/decisions/0017-faehigkeitskatalog-aus-drei-quellen.md)).

**Der Entwicklermodus ist nur im Debug-Build vorhanden** und arbeitet auf
einem **eigenen Spielstand** ([ADR-0021](docs/decisions/0021-entwicklermodus-mit-eigenem-spielstand.md)).
Die Ausnahme ist die **Entwicklerfassung** unter `/LifesGame/dev/` — ein
Release-Build mit Entwicklermodus und eigenem Speicher, damit sich
Prototypen am Handy ausprobieren lassen ([ADR-0038](docs/decisions/0038-entwicklerfassung-im-web.md)).
Er schenkt Zuschläge als benannten Summanden, statt Lektionen oder Häkchen
zu erfinden. Wer an einer abgeleiteten Zahl dreht, lässt
`flutter test test/dev_mode_test.dart` laufen — dort steht die Zusage, dass
**ohne** Zuschläge jede Formel unverändert ist.

**Jede Pergamentfläche liegt im Holzrahmen** (`HolzKarte`), jeder
Dialog in `HolzDialog`, jedes Blatt von unten in `HolzBlatt`. Ein
`Container` mit `Palette.surface` und runden Ecken ist die Form von vorher
— stünden beide nebeneinander, sähe man genau den Bruch, den das
schliesst. Ausgenommen sind Kacheln in Rastern, Knöpfe und Kreise: Zwölf
Punkte Holz wären dort dicker als der Inhalt. Der Rahmen kostet eine
Karte 24 Punkte Breite; wer eine Zeile hineinlegt, gibt ihren Texten
`Flexible` (`gotchas.md`).

**Jeder Knopf gibt nach, wenn man ihn drückt** (`lib/ui/druck.dart`).
Planke, Holzknopf, `TextButton` und `OutlinedButton` tun es über das
Theme. Alles Eigene mit `InkWell` oder `GestureDetector`, also Kreise,
Kacheln, Knoten und `ListTile`s, liegt in einem `Druck`. **Wer eine neue
Tippfläche baut, legt sie in `Druck`**, sonst ist sie die eine, die nicht
nachgibt. Liegt ein Theme-Knopf in einer Fläche mit `Druck`, kommt er in
eine `DruckSperre`, sonst sinkt die ganze Fläche mit ihm ein
(`HabitCheckTile`). `test/druck_test.dart`.

**Die App hat zwei Untergründe, und jede Bedeutung hat für beide einen
Wert.** Pergamentflächen (`Palette.surface`) liegen auf dunklem Leder
(`Palette.background`); die Kampfarena und die Baumfläche sind selbst
dunkel. Schrift darauf ist `text`/`textDim`/`muted` beziehungsweise
`textOnDark`/`textOnDarkDim`, Bedeutungen sind `accent` und
`accentOnDark` und so fort. **Die beiden Grundfarben sind aus
`assets/UI/ButtonBG.png` abgelesen**, nicht gewählt.

Das Theme ist deshalb `Brightness.light`, obwohl der Grund dunkel ist:
Die Helligkeit entscheidet, welche Farbe ein `Text` **ohne** eigene
Angabe bekommt, und der steht fast immer auf Pergament. Wo ein Bereich
auf Leder liegt, klammert `OnDark` ihn ein — sonst entsteht unsichtbarer
Text, und der meldet sich nie. Wer eine Farbe ändert, lässt
`flutter test test/palette_test.dart` laufen; dort stehen die
Kontrastgrenzen als Zusage.

**Alles Gezeichnete liegt auf 64 × 64 und wird als 256 × 256 abgelegt.**
Die beiden Zahlen stehen in `PixelArt`; `MoveIcons` und `GearIcons`
lesen sie dort. Eine Zeichnung fester Größe kommt über
`PixelArt` ins Bild und nicht über `Image.asset` — dort hängt die
Entscheidung „hart oder weich skalieren" an einer Zahl, und unterhalb der
Zeichengröße ist hart der schlimmere Fall: Bildpunkte fallen dann einfach
weg. Wer daran dreht, lässt `flutter test test/pixel_art_test.dart`
laufen.

Welche Datei zu welchem Ding gehört, steht in je einer Tabelle:

| Frage | Antwortet |
|---|---|
| Welches Bild trägt ein Ausrüstungsstück? | `GearIcons` — Item-Id → **Pfad** |
| Welches Bild trägt ein Zug? | `MoveIcons` |
| Welche Fläche trägt ein Bereichskreis? | `HubCircleImage` |

**Die Zeichnungen liegen nach Art sortiert** (`assets/Waffen/Schwerter/`,
`assets/Items/`, `assets/UI/`), nicht nach Id. Beim Malen gibt es die Id
noch gar nicht, und ein Bild kann sein Stück wechseln — die Zuordnung
gehört deshalb in die Tabelle und nicht in den Dateinamen.

**Fortschritt überlebt einen Neustart, aber nur über eine Stelle.**
Geschrieben wird ausschließlich in `lib/save/save_watcher.dart`. Wer einen
achten Bereich baut, trägt ihn dort ein — sonst funktioniert alles, nur
gespeichert wird nichts. Serialisierung gehört ins jeweilige Package
(`toJson`/`fromJson`), nicht nach `lib/`. Alle `fromJson` sind bewusst
nachsichtig: Unbekanntes wird übersprungen, nie geworfen ([ADR-0010](docs/decisions/0010-persistenz-hinter-einem-anschluss.md)).

**„Heute" stimmt nach Mitternacht, aber auch nur über eine Stelle.**
`todayProvider` liest die Uhr einmal. Dass der Tag wechselt, besorgt
`lib/habits/day_watcher.dart`, und das hängt wie der `SaveWatcher` in
`main.dart` — Tests, die `LifesGameApp` ohne ihn pumpen, bleiben auf dem
Tag des Starts stehen, und das ist dort gewollt. Wer „heute" braucht,
liest `todayProvider`, nie `DateTime.now()`. Wer daran dreht, lässt
`flutter test test/day_watcher_test.dart` laufen.

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
| `docs/vorlagen/` | Entwürfe, aus denen gebaut wird — Fähigkeiten, Lernen, später das Kampfsystem | sobald eine Vorlage entsteht, **bevor** danach gebaut wird |

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
