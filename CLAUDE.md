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
| `packages/theory/` | Skillbaum-Graph, Inhalte, Lernfortschritt, reines Dart, 208 Tests | nur Dart-SDK |
| `packages/theory/lib/src/review.dart` | die **Rückfrage des Tages**: welche Seite fällig ist, und in welchem Abstand sie wiederkommt ([ADR-0045](docs/decisions/0045-rueckfrage-des-tages.md)) | nur Dart-SDK |
| `packages/theory/lib/src/content/` | die Lektionen selbst — hier wird geschrieben | nur Dart-SDK |
| `packages/theory/lib/src/content/theory_graph_content.dart` | **der Baum selbst**: vier Wurzeln, Zwischenebenen, Themen, wer an wem hängt — die **angekündigten** Überschriften (`theoryPlaceholders`) und der **Weg der Grundlagen** (`theoryBasicsPath`) | nur Dart-SDK |
| `packages/theory/lib/src/content/area_pages.dart` | die Einführungsseiten der **Zwischenebenen** ([ADR-0050](docs/decisions/0050-zwischenebenen-und-angekuendigte-gebiete.md)) | nur Dart-SDK |
| `packages/theory/lib/src/content/kraft_pages.dart` | die Themen unter **Kraft & Muskulatur** — das erste befüllte Gebiet, und **die Probe für Rätsel und Fall** (18.10.): jede Seite öffnet mit einem Rätsel (`Lesson.teaser`), ihre zweite Frage ist eine Situation | nur Dart-SDK |
| `packages/theory/lib/src/content/ausdauer_pages.dart` | **Ausdauer & Fitness**: Einführung und fünf Themen | nur Dart-SDK |
| `packages/theory/lib/src/content/philosophie_pages.dart` | **Philosophie**: Einführung, Stoizismus, Ethik, Fehlschlüsse, Sokrates, Existenzialismus | nur Dart-SDK |
| `packages/theory/lib/src/content/gewohnheiten_pages.dart` | **Gewohnheiten** unter Selbstentwicklung: Überkapitel → vier Regeln → je Regel eine Seite (bisher: offensichtlich, attraktiv), **aus dem Gelesenen** ([ADR-0061](docs/decisions/0061-der-baum-waechst-aus-dem-gelesenen.md)) | nur Dart-SDK |
| `packages/theory/lib/src/content/habits_lessons.dart` | die fünf Seiten des **früheren Handbuchs** — seit [ADR-0070](docs/decisions/0070-das-handbuch-steht-im-baum.md) Knoten unter Gewohnheiten, „Zwei Minuten reichen“ als Regel 3 | nur Dart-SDK |
| `packages/theory/lib/src/content/psychologie_pages.dart` | **Psychologie**: fünf Themen an Experimenten — Asch, Milgram, Bystander, Loftus, Gefühle | nur Dart-SDK |
| `packages/theory/lib/src/lesetext.dart` | **wie ein Abschnitt gesetzt wird**: `**betont**` und ein Absatz in `==…==` als Merksatz, mehr Zeichen gibt es nicht; jede Seite wird auf offene Zeichen geprüft | nur Dart-SDK |
| `packages/theory/lib/src/placeholder.dart` | eine Überschrift **ohne Seite** — grau, „Inhalt folgt", nicht zu öffnen | nur Dart-SDK |
| `packages/theory/lib/src/node_graph.dart` | Struktur des Graphen, `canOpen`, Gesundheitsprüfung | nur Dart-SDK |
| `packages/theory/lib/src/skill_tree.dart` | die alten flachen Zweige — nur noch Behälter der Lektionen, **gezählt wird der Graph** | nur Dart-SDK |
| `packages/progression/` | Levelkurve, Fähigkeitsslots, Theoriepunkte, **Machtkurve**, **Skill-Kurve**, reines Dart, 52 Tests | nur Dart-SDK |
| `packages/progression/lib/src/level_up.dart` | was ein **Aufstieg** bringt — Macht, Theoriepunkte, Plätze | nur Dart-SDK |
| `packages/progression/lib/src/ability_slots.dart` | ab welchem Level welcher Slot aufgeht — und der **Platz der Ultimate** auf Level 15 ([ADR-0073](docs/decisions/0073-ultimate-mana-und-neue-arten.md)) | nur Dart-SDK |
| `packages/progression/lib/src/power_curve.dart` | was ein Level im Kampf **vervielfacht** ([ADR-0042](docs/decisions/0042-macht-vervielfacht.md)) | nur Dart-SDK |
| `packages/progression/lib/src/theory_points.dart` | ein Theoriepunkt je Aufstieg ([ADR-0035](docs/decisions/0035-ein-theoriepunkt-je-level.md)), **einer zum Start** ([ADR-0078](docs/decisions/0078-ein-startpunkt.md)) | nur Dart-SDK |
| `packages/progression/lib/src/skill_curve.dart` | die Kurve der **Skills** ([ADR-0085](docs/decisions/0085-skills-je-gebiet.md)): 1 bis 100, Stufe 2 kostet 100, jede weitere 8 mehr; das Gesamtlevel | nur Dart-SDK |
| `packages/habits/` | Gewohnheiten, Streaks, Charakterwerte, reines Dart, 345 Tests | nur Dart-SDK |
| `packages/habits/lib/src/catalog.dart` | die Vorlagen selbst — verknüpft mit Lektion und Stat | nur Dart-SDK |
| `packages/habits/lib/src/habit.dart` | `Habit`, Vorlage und **eigene** Gewohnheit, Grad, Ziel | nur Dart-SDK |
| `packages/habits/lib/src/plan.dart` | der **Wochenplan** einer Gewohnheit: an welchen Wochentagen sie fällig ist, **als Historie** — und wann sie pausiert ([ADR-0064](docs/decisions/0064-wochenplan-und-kette-die-faellt.md)) | nur Dart-SDK |
| `packages/habits/lib/src/stack.dart` | **Gewohnheiten koppeln**: wie die Tagesliste zu Stapeln geordnet wird, was „jetzt dran“ ist, und dass kein Kreis entsteht ([ADR-0065](docs/decisions/0065-gewohnheiten-koppeln.md)) | nur Dart-SDK |
| `packages/habits/lib/src/timer.dart` | der **Timer** eines Zeitziels: ein Zeitpunkt, kein Zähler — gerechnet wird aus der Startzeit ([ADR-0067](docs/decisions/0067-zeitziele-als-timer.md)) | nur Dart-SDK |
| `packages/habits/lib/src/streak_rule.dart` | **wie eine Kette läuft**: erledigt, getragen, verpasst — eine Stelle für Kette, Tageskette und Erfahrung | nur Dart-SDK |
| `packages/habits/lib/src/skill_area.dart` | die **vier Gebiete** ([ADR-0085](docs/decisions/0085-skills-je-gebiet.md)): Körper, Geist, Wissenschaft, Gesellschaft — gleich benannt wie die Wurzeln des Baums | nur Dart-SDK |
| `packages/habits/lib/src/daily_form.dart` | die **Tagesform**: was heute abgehakt ist, macht heute stärker ([ADR-0043](docs/decisions/0043-tagesform.md)) | nur Dart-SDK |
| `packages/habits/lib/src/daily_chest.dart` | die **Tagestruhe**: aus dem Datum gewürfelt, einmal je erledigtem Tag ([ADR-0044](docs/decisions/0044-tagestruhe.md)) | nur Dart-SDK |
| `packages/habits/lib/src/daily_quests.dart` | die **drei Tagesaufgaben**: aus dem Datum gewürfelt, Stand aus der Historie, ein Schlüssel je abgeholter ([ADR-0055](docs/decisions/0055-tageskette-aufgaben-und-wiederholen.md)) | nur Dart-SDK |
| `packages/habits/lib/src/week_summary.dart` | der **Wochenrückblick**: was eine Woche gebracht hat, aus der Historie | nur Dart-SDK |
| `packages/habits/lib/src/streak_freeze.dart` | das **Streak-Eis** und wie viele es davon gibt | nur Dart-SDK |
| `packages/habits/example/curve_sim.dart` | 90 Tage Ertrag und Werte durchspielen | nur Dart-SDK |
| `packages/gear/` | Ausrüstung, Preise, Inventar aus **Exemplaren**, Tagesladen, Beute samt **Kaskade** (ADR-0083), **Vergleich und Schloss**, reines Dart, 137 Tests | nur Dart-SDK |
| `packages/gear/lib/src/catalog.dart` | die Ausrüstungsstücke selbst | nur Dart-SDK |
| `packages/gear/lib/src/prices.dart` | alle Preise | nur Dart-SDK |
| `packages/gear/lib/src/set_catalog.dart` | die **vier Sets** und ihre Wirkung — drei offene, dazu das verdiente **Vampirset** ([ADR-0077](docs/decisions/0077-ausruestung-mit-kraeften.md)) | nur Dart-SDK |
| `packages/gear/lib/src/gates.dart` | ab welcher Sprosse Episch und Legendär kaufbar sind | nur Dart-SDK |
| `packages/gear/lib/src/rolls.dart` | **wie gewürfelt wird**: Werte 85–115 %, Seltenheit je Stufe, der Tagesladen, die Beute ([ADR-0048](docs/decisions/0048-exemplare-tagesladen-und-beute.md)) | nur Dart-SDK |
| `packages/gear/lib/src/copy.dart` | ein **Exemplar**: Katalogstück plus gespeicherte Werte | nur Dart-SDK |
| `packages/gear/lib/src/keys.dart` | die **Schlüssel** zur Beute — höchstens zehn, der Überhang verfällt beim Einsetzen | nur Dart-SDK |
| `lib/gear/copy_text.dart` | wie ein Exemplar sich beschreibt — Werte **untereinander**, mit Unterschied zum Getragenen in Klammern (`CopyText.lines`) | Flutter |
| `lib/gear/widgets/copy_stats.dart` | zeigt das: eine Zeile je Wert, „(+2)“ grün, „(−3)“ rot — Laden, Inventar, Beute, Charakter | Flutter |
| `lib/combat/widgets/loot_dialog.dart` | die Beute des Wächters: fragen, ob ein Schlüssel sie öffnet, und zeigen, was fiel | Flutter |
| `lib/combat/widgets/loot_reveal.dart` | wie die Truhe aufgeht: Schlüssel ins Schloss, aufplatzen in der Farbe der Seltenheit, das Stück springt heraus — **läuft einmal und hält an** | Flutter |
| `lib/gear/weapon_ability_line.dart` | was eine Waffe an Fähigkeit mitbringt — reine Rechnung | Flutter |
| `lib/gear/widgets/rarity_badge.dart` | die Seltenheit als Marke — **die einzige Farbtabelle**, auch für Fähigkeiten; zwei Spalten: Schriftton (`colorOf`, Marke und Name) und Rahmenton (`rahmenOf`, der Rand um ein Stück) | Flutter |
| `packages/abilities/` | woher eine Fähigkeit kommt, reines Dart, 43 Tests | nur Dart-SDK |
| `packages/abilities/lib/src/ability_catalog.dart` | die Fähigkeiten und ihre Bedingungen — und die **Ultimates** (`ultimates`), die nie unter den wählbaren stehen | nur Dart-SDK |
| `packages/identity/` | Name und verdiente Titel (nur der Wortlaut), reines Dart, 25 Tests | nur Dart-SDK |
| `packages/identity/lib/src/title_catalog.dart` | die **fünfundzwanzig** Titel und ihr Wortlaut — Bedingungen stehen woanders | nur Dart-SDK |
| `packages/achievements/` | Errungenschaften, reines Dart, 25 Tests | nur Dart-SDK |
| `packages/achievements/lib/src/catalog.dart` | die **34 Meilensteine und 8 Entdeckungen** samt Bedingungen — „Erste Seite“ bringt jedem Funkenstoß ([ADR-0079](docs/decisions/0079-der-mentor.md)), je Gebiet drei Titel bei 10, 25 und 50 ([ADR-0085](docs/decisions/0085-skills-je-gebiet.md)) | nur Dart-SDK |
| `packages/achievements/lib/src/rewards.dart` | was eine Stufe einbringt — Erfahrung, Gold, Ruhm | nur Dart-SDK |
| `packages/achievements/lib/src/stats.dart` | die Zahlen, die hereingereicht werden — **jede darf nur steigen** | nur Dart-SDK |
| `packages/action_combat/` | **die Grube — der Kampf des Spiels** ([ADR-0039](docs/decisions/0039-die-grube-ersetzt-den-rundenkampf.md)), Echtzeit, reines Dart, 406 Tests | nur Dart-SDK |
| `packages/action_combat/lib/src/ladder.dart` | wie weit jemand gekommen ist, und was eine Stufe einbringt | nur Dart-SDK |
| `packages/action_combat/lib/src/bestiarium.dart` | **wie oft welche Art und welcher Wächter fiel** — die Gegner der Sammlung, in Stufen (1, 10, 100; Wächter 1, 5, 25), gespeichert in der Reihe ([ADR-0080](docs/decisions/0080-die-sammlung.md)) | nur Dart-SDK |
| `packages/action_combat/lib/src/balance.dart` | alle Stellschrauben der Grube, Fähigkeiten und Stufen eingeschlossen | nur Dart-SDK |
| `packages/action_combat/lib/src/pit_ability.dart` | was eine Fähigkeit **in der Grube tut** — Mana, Abklingzeit, Wirkungen als Daten; dazu die vier **Ultimates**, die drei **Passive** und die Passive der **Ausrüstung** (ADR-0077) |
| `packages/action_combat/lib/src/effects.dart` | **die eine Stelle, die jede Wirkung ausführt** — Sturm, Haken, Strudel, Stillstand samt Stun-Leiste, Self-Buff, Zufall, Bumerang ([ADR-0073](docs/decisions/0073-ultimate-mana-und-neue-arten.md)) | nur Dart-SDK |
| `packages/action_combat/lib/src/summons.dart` | was der Held in die Welt setzt: Fallen, der Begleiter (auch das **Spiegelbild**), der Fels | nur Dart-SDK |
| `packages/action_combat/lib/src/hero_states.dart` | **was am Helden abläuft** ([ADR-0074](docs/decisions/0074-aktivesbretts-faehigkeiten.md)): Rage, Ruhepuls, zweiter Atem, Unsichtbarkeit, Parade, Bestform, Stacking, Kettenblitz, Blink, Rückspulen — und **die Grenze des Grundangriffs** (`_heroFactor`) | nur Dart-SDK |
| `packages/action_combat/lib/src/gear_powers.dart` | **was die Ausrüstung am Helden tut** ([ADR-0077](docs/decisions/0077-ausruestung-mit-kraeften.md)): Lebensraub und Blutpakt, Frostreif, Irrlichter, Flickwerk, Falkenblick, Hasenlauf, Seelenernte, Echo — und die Grundangriffe Speer und Sichel | nur Dart-SDK |
| `packages/action_combat/lib/src/item_drops.dart` | **Beute in der Grube** ([ADR-0083](docs/decisions/0083-beute-in-der-grube.md)): die erste Stufe der Kaskade — *ob* ein Gegner etwas fallen lässt —, am Boden liegen, hinlaufen, einsammeln. Was es ist, weiß die Grube nicht | nur Dart-SDK |
| `packages/action_combat/lib/src/entwickler.dart` | **nur Entwicklermodus**: Gegner beschwören und Funde legen, auf dem Weg des Spiels (`EntwicklerWerkzeug`) — der Wächter ist ausgenommen | nur Dart-SDK |
| `packages/action_combat/lib/src/daily_pit.dart` | **die Tagesgrube** ([ADR-0072](docs/decisions/0072-die-tagesgrube.md)): Startwert aus dem Datum, sieben Sätze je Wochentag, Raumzeile, die Versuche als Historie, Ruhm | nur Dart-SDK |
| `packages/action_combat/lib/src/aim.dart` | **wohin eine Fähigkeit wirkt** — Selbstzielen, Skillshot, abgesetzte Flächen, Vorschau | nur Dart-SDK |
| `packages/action_combat/lib/src/pit_modifier.dart` | wie **Sets und Kräfte der Ausrüstung** Fähigkeiten verändern — und alle Kräfte selbst (`PitGearPowers`); eine Kraft am Helden kommt als `GrantPassive` (ADR-0077) | nur Dart-SDK |
| `packages/action_combat/lib/src/boss.dart` | **die vier Wächter** ([ADR-0062](docs/decisions/0062-waechter-und-besetzung-werden-gewuerfelt.md)): was jeder kann, was er ankündigt, Wut | nur Dart-SDK |
| `packages/action_combat/lib/src/pit_weapon.dart` | was die **Waffe** aus dem Grundangriff macht — Bogen schiesst, Spalter trifft alle | nur Dart-SDK |
| `packages/action_combat/lib/src/stage.dart` | die **hundert Stufen** — wie aus einer Stufe ein Faktor wird; die Zahlen gelten für 1 und 30, darüber im selben Schritt weiter ([ADR-0075](docs/decisions/0075-hundert-ebenen.md)) | nur Dart-SDK |
| `packages/action_combat/lib/src/room_catalog.dart` | die **Räume**, aus denen jede Grube gesteckt wird — hier wird geschrieben | nur Dart-SDK |
| `packages/action_combat/lib/src/level_builder.dart` | steckt die Räume gesät zu einer Grube zusammen, würfelt Wächter und Besetzung | nur Dart-SDK |
| `packages/action_combat/lib/src/cast.dart` | die **Besetzung** einer Grube: welche Arten in diesem Lauf die Rollen spielen ([ADR-0063](docs/decisions/0063-besetzung-in-rollen.md)) | nur Dart-SDK |
| `packages/action_combat/lib/src/enemies.dart` | was Kreischpilz, Sporenpilz, Wächterauge und Schleim **tun** — und die Werte der fünf neuen Arten | nur Dart-SDK |
| `packages/action_combat/lib/src/level_catalog.dart` | die feste Halle des Prototyps, nur noch im Entwicklermodus | nur Dart-SDK |
| `packages/action_combat/example/headless_run.dart` | spielt eine Halle ohne Bildschirm durch, mit drei Machtstufen | nur Dart-SDK |
| `lib/action/` | die Darstellung dazu — Figuren, Steuerkreuz, Kopfzeile | Flutter |
| `lib/action/pit_screen.dart` | ein Lauf durch eine Stufe — **die einzige Stelle**, die ein Ergebnis in die Reihe trägt | Flutter |
| `lib/action/lauf_verlassen.dart` | **die Rückfrage, bevor ein Lauf verlassen wird** — Grube und Tagesgrube; auf Android ist „Zurück“ eine Geste vom Rand, und das Steuerkreuz nimmt den ganzen Bildschirm | Flutter |
| `lib/action/daily_pit_screen.dart` | der **eine Lauf des Tages** durch die Tagesgrube — trägt ein, wie er ausging; „Zurück“ fragt nach und hält den Lauf an | Flutter |
| `lib/action/pit_run_view.dart` | Spielfeld, Steuerung, Kopfzeile, **Tasten** — geteilt mit dem Prototyp | Flutter |
| `lib/action/lauf_zeichen.dart` | **die Zeichen des ersten Laufs**: Geister-Steuerkreuz bis zum ersten Schritt, Waffe in drehenden Pfeilen beim ersten Schlag — reine Rechnung, ein Stand je Lauf ([ADR-0069](docs/decisions/0069-die-grube-erklaert-sich-im-ersten-lauf.md)) | Flutter |
| `lib/action/lauf_zeichen_view.dart` | zeichnet sie über dem Spielfeld, **nimmt keinen Tipp an** und läuft aus der Zeit des Laufs | Flutter |
| `lib/action/pit_beute.dart` | **was ein Fund ist** (ADR-0083): würfelt beim Fallen mit `GearLoot.cascade` aus Ebene, Startwert des Laufs und Nummer des Fundes — reine Rechnung | Flutter |
| `lib/action/beute_am_boden.dart` | zeichnet Funde am Boden, **ein Feld groß**: den **Umriss** des Platzes (`GearIcons.gruppeFor`) im Rand der Seltenheit, Episches im Schein, **Legendäres unter einer Lichtsäule** — nur Darstellung | Flutter |
| `lib/action/beute_regen.dart` | **der Goldregen**: was ein Gegner bringt, fliegt als Münzen und Funken zum Helden, dazu Kasse, Balken und Aufstieg — reine Rechnung, **nur Darstellung dessen, was die Welt schon gezahlt hat**; nach einer Niederlage **nimmt er alles zurück** samt der eingesammelten Funde (`verliere`, [ADR-0084](docs/decisions/0084-die-niederlage-nimmt.md)) | Flutter |
| `lib/action/staerker_werden.dart` | **drei Tipps nach einer Niederlage** aus dem eigenen Stand — leerer Platz, Besseres im Rucksack, freie Punkte, Häkchen bis In Form, Laden; nie zwei in denselben Bereich — reine Rechnung | Flutter |
| `lib/action/staerker_werden_provider.dart` | trägt die Zahlen dafür zusammen, **rechnet nichts** | Flutter |
| `lib/action/beute_bild.dart` | zeichnet Münzen und Funken | Flutter |
| `lib/action/beute_anzeige.dart` | die Kasse oben, der Erfahrungsbalken unten, das Level in der Mitte, wenn es mitten im Lauf steigt | Flutter |
| `lib/action/kampfgefuehl.dart` | **wie laut das Bild auf die Welt antwortet**: Trefferstopp, Beben, roter Rand bei wenig Leben, und wie dicht Klänge folgen dürfen — reine Rechnung, ändert keine Zahl des Kampfes | Flutter |
| `lib/action/minimap.dart` | die **Karte oben links** — was gesehen ist, bleibt aufgedeckt; nur Darstellung | Flutter |
| `lib/action/hero_power.dart` | womit der Held in die Grube geht — Werte, Level, Seltenheit, **eine Stelle** | Flutter |
| `lib/action/neue_arten_bild.dart` | wie Falle, Begleiter, Haken-Faden, Eis, Stillstand und die Kerben des Wächters im Bild stehen — **nur Darstellung** | Flutter |
| `lib/action/pit_tints.dart` | welche Farbe die Fläche einer Fähigkeit trägt — **eine Tabelle** | Flutter |
| `lib/action/pit_text.dart` | Name, Beschreibung **und alle Werte** einer Fähigkeit oder Waffe — **eine Stelle** für alle Bildschirme | Flutter |
| `lib/action/action_sprites.dart` | wer in der Grube wie aussieht — Bild je Gegnerart und je Wächter (`forBoss`), **eine Tabelle** | Flutter |
| `lib/action/boss_text.dart` | wie die vier Wächter heißen, und die Zeile unter dem Namen beim Auftritt | Flutter |
| `lib/action/gegner_text.dart` | wie die Gegnerarten heißen — **eine Tabelle** | Flutter |
| `lib/sammlung/sammlung.dart` | **die Sammlung** ([ADR-0080](docs/decisions/0080-die-sammlung.md)): was in welchem Reiter steht und **woher es kommt** — reine Rechnung, eine Stelle | Flutter |
| `lib/sammlung/sammlung_screen.dart` | sechs Reiter mit Prozent — Ausrüstung, Fähigkeiten, Gegner, Titel, Seiten und die **Errungenschaften, die hier eingezogen sind**; ein Fragezeichen sagt auf Tipp, woher | Flutter |
| `lib/sammlung/sammlung_knopf.dart` | der Weg hinein, oben rechts in Ausrüstung und Fähigkeiten | Flutter |
| `lib/sammlung/figur_bild.dart` | eine Figur der Grube als stehendes Bild, auf sie zugeschnitten | Flutter |
| `packages/haustier/` | **das Haustier** (`docs/vorlagen/haustier.md`, seit [ADR-0086](docs/decisions/0086-das-haustier-fuer-alle.md) in jeder Fassung): drei Arten, Level und Stufen aus Tagen mit Häkchen, Laune, Zubehör und Preise, der gespeicherte Stand; reines Dart, 21 Tests | nur Dart-SDK |
| `lib/haustier/haustier_controller.dart` | Riverpod-Brücke Haustier ↔ UI, **enthält keine Regeln**; Tage, Stufe, Laune und Prägung abgeleitet; der Kauf bekommt das Gold von außen | Flutter |
| `lib/haustier/widgets/haustier_bild.dart` | **wie das Tier aussieht** — gezeichnet, atmet, blinzelt, schläft, springt; **die eine Stelle**, die ein Grafikpaket ersetzt; in Tests still (`HaustierBild.lebt`) | Flutter |
| `lib/haustier/widgets/haustier_schmuck.dart` | Hüte, Halsschmuck, Spielzeug und die Prägung — ausgelagert aus dem Bild | Flutter |
| `lib/haustier/widgets/haustier_karte.dart` | das Tier über „Heute“ auf der Startseite, ohne Ei die Wahl zwischen dreien — **erst, wenn es eine Gewohnheit gibt** (ADR-0086) | Flutter |
| `lib/haustier/widgets/haustier_blatt.dart` | das Blatt: Name, Stufen, Zubehör kaufen und anlegen, im Entwicklermodus Tage vorspulen | Flutter |
| `lib/skills/skills.dart` | **die Skills je Gebiet** ([ADR-0085](docs/decisions/0085-skills-je-gebiet.md)): Häkchen, Seiten und Rückfragen eines Gebiets zusammengezählt, dazu das Gesamtlevel — **eine Stelle**, die Errungenschaften rechnen dasselbe | Flutter |
| `lib/skills/skills_provider.dart` | `skillsProvider`, und welches Gebiet zuletzt abgehakt wurde (`zuletztGebietProvider`, nur Darstellung) | Flutter |
| `lib/skills/gebiet_zeichen.dart` | das Zeichen eines Gebiets — **das seiner Wurzel im Baum**, keine eigene Tabelle | Flutter |
| `lib/skills/skill_text.dart` | der Text zum Teilen: Name, Gesamtlevel, vier Skills, längste Kette — reine Rechnung | Flutter |
| `lib/skills/widgets/skill_karte.dart` | die Skills im Charakter, **über** der Kette, mit Teilen-Knopf | Flutter |
| `lib/skills/widgets/skill_abzeichen.dart` | ein Skill als kleine Marke — **eine Stelle** für Kachel und Kopf des Baums | Flutter |
| `lib/skills/widgets/gebiets_balken.dart` | **der zweite Balken** unter dem Level: blendet ein, wenn ein Häkchen seine grünen Funken wirft — dieselbe Erfahrung zählt fürs Level und fürs Gebiet; liegt immer da, damit die Funken ein Ziel haben | Flutter |
| `lib/skills/widgets/gebiet_frage_karte.dart` | die **einmalige Frage** nach dem Gebiet einer alten eigenen Gewohnheit, über „Heute“ | Flutter |
| `tool/runway_sim.dart` | **wann geht was aus?** 60 Tage eines fleissigen Spielers: Level, Baum, Stufen, Gold gegen den Laden | nur Dart-SDK |
| `tool/pit_sim.dart` | prüft die **Grube**: Stufe für Stufe gegen den echten Werte-Pfad, bis keine Spalte mehr gewinnt | nur Dart-SDK |
| `tool/tagesgrube_sim.dart` | misst die **sieben Sätze der Tagesgrube**: auf welcher Stufe jeder gleich schwer ist, ohne Form und in Form | nur Dart-SDK |
| `lib/main.dart` | App-Shell, Theme, lädt den Spielstand vor `runApp` | Flutter |
| `lib/home/home_screen.dart` | Startbildschirm **vor dem Berg** (`assets/UI/Berg.jpg`): **sieben** Kreise in zwei Holzrahmen, unten vier kleinere, dazwischen Statusleiste und „Heute“ ([ADR-0058](docs/decisions/0058-figur-in-die-ausruestung.md)); **die Kreise kommen nach und nach** (`Aufgedeckt`) | Flutter |
| `lib/home/erster_start.dart` | **der erste Start**: welcher Kreis wann erscheint, welcher leuchtet und **bei welchem Schritt der Mentor steht** (`Schritt`) — reine Rechnung aus Zahlen, die nur wachsen ([ADR-0068](docs/decisions/0068-erster-start-deckt-die-bereiche-auf.md), [ADR-0079](docs/decisions/0079-der-mentor.md)) | Flutter |
| `lib/mentor/mentor.dart` | **der Mentor**: was er bei welchem Schritt an welchem Ort sagt — **eine Tabelle** (`Mentor.satz`), dazu sein Bild (`Mentor.bild`, noch ein Platzhalter) | Flutter |
| `lib/mentor/mentor_kasten.dart` | sein Kasten über einem Bildschirm (`MentorFlaeche`) — **nimmt keinen Tipp an** | Flutter |
| `lib/mentor/zeigefinger.dart` | der Ring um das, worauf er zeigt (`Zeigefinger`, `ZeigeRing`) — pulsiert fünfmal und bleibt stehen | Flutter |
| `lib/home/erster_start_provider.dart` | trägt die Zahlen dafür zusammen, **rechnet nichts** | Flutter |
| `lib/home/widgets/erste_gewohnheit.dart` | **die erste Frage** „Was willst du jeden Tag tun?“ — steht statt „Heute“, solange es keine Gewohnheit gibt | Flutter |
| `lib/home/widgets/status_leiste.dart` | **Level und Gold oben rechts**: das Abzeichen in einem Ring, der die Erfahrung zeigt (`LevelRing`), daneben das Gold, links davon der Balken des Gebiets (`GebietsBalken`); der Satz zur Erfahrung kommt erst auf Tipp auf den Ring; zeigt, was **angekommen** ist — was noch fliegt, zieht sie ab; **auch oben auf dem Gewohnheiten-Bildschirm** | Flutter |
| `lib/home/widgets/hub_circle.dart` | ein Bereich als runder Knopf, samt Sperrgrund | Flutter |
| `lib/home/widgets/today_card.dart` | **„Heute“** auf der Startseite: alle Gewohnheiten von heute, erledigte durchgestrichen, ein Tipp je Häkchen ([ADR-0053](docs/decisions/0053-heute-auf-der-startseite.md)); was am Feuer als Erstes gewählt wurde, trägt eine **Flamme**; rechts das grüne Zeichen des Gebiets | Flutter |
| `lib/lagerfeuer/lagerfeuer_screen.dart` | **das Lagerfeuer** ([ADR-0076](docs/decisions/0076-das-lagerfeuer.md)): Rückfrage, Truhe, Tagesaufgaben, sonntags der Wochenrückblick, „Morgen zuerst“ und der Satz, der wegschickt — **Truhe und Aufgaben gibt es nur hier** | Flutter |
| `lib/lagerfeuer/am_feuer.dart` | **was am Feuer wartet** und ob es brennt (ab 18 Uhr oder Tag geschafft) — reine Rechnung, erzeugt keine Zahl | Flutter |
| `lib/lagerfeuer/am_feuer_provider.dart` | trägt das zusammen, **rechnet nichts** | Flutter |
| `lib/lagerfeuer/widgets/feuer_bild.dart` | Himmel, Scheite, Flammen, Funken; brennt oder glimmt; **flackert in Tests nicht** (`test/flutter_test_config.dart`) | Flutter |
| `lib/lagerfeuer/widgets/lagerfeuer_karte.dart` | das Feuer auf der Startseite, unter „Heute“: was wartet, als Zeichen mit Zahl | Flutter |
| `lib/lagerfeuer/widgets/morgen_zuerst.dart` | was morgen zuerst drankommt — Knöpfe in der Reihenfolge **ohne** Vorsatz, damit nichts springt | Flutter |
| `lib/gear/widgets/character_figure.dart` | die Figur — **samt Rüstung, Waffe und Helm** (`overlays`, deckungsgleich auf 256 × 256), im Ausrüstungs-Bildschirm zwischen den Plätzen | Flutter |
| `lib/save/save_data.dart` | der ganze Spielstand als ein Wert | Flutter |
| `lib/save/save_store.dart` | der Anschluss, hinter dem die Speichertechnik liegt | Flutter |
| `lib/save/save_watcher.dart` | **die einzige Stelle, die schreibt** — und `currentSave`, was geschrieben und exportiert wird | Flutter |
| `lib/save/widgets/save_transfer_card.dart` | **den Stand als Text sichern** und einfügen, samt Neustart von innen ([ADR-0054](docs/decisions/0054-spielstand-als-text-sichern.md)) | Flutter |
| `lib/habits/day_watcher.dart` | hält „heute" über Mitternacht aktuell — **muss** in `main.dart` hängen | Flutter |
| `lib/progression/level_provider.dart` | Level und Gold aus allen Quellen, **rechnet nicht** | Flutter |
| `lib/habits/habits_controller.dart` | Riverpod-Brücke Tracker ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/habits/habits_screen.dart` | oben die Leiste der Startseite, **„Heute“** darunter, darunter „Neue Gewohnheit“ und die Reiter Eigene / Vorerstellte ([ADR-0059](docs/decisions/0059-gewohnheiten-nur-noch-heute.md)) | Flutter |
| `lib/habits/habit_check_flow.dart` | **was ein Häkchen auslöst** — Klang, Feiern, aufsteigende Zahlen, fliegende Münzen; **die Erfahrung fliegt zweimal**, zum Level und grün zum Gebiet ([ADR-0085](docs/decisions/0085-skills-je-gebiet.md)); **eine Stelle** für Startseite und Gewohnheiten; gefeiert wird, **wenn die Münzen gelandet sind** | Flutter |
| `lib/habits/haekchen_moment.dart` | **was ein Häkchen gerade bedeutet**: das wievielte des Tages, ob es die Flamme zündet, ob der Tag geschafft ist — und welcher Ton der **Tonleiter des Tages** dran ist; reine Rechnung, erzeugt keine Zahl | Flutter |
| `lib/habits/widgets/haekchen_kreis.dart` | der Kreis, der beim Abhaken **aufspringt** — Blitz, Ring, acht Striche; nur beim Setzen; **eine Stelle** für Kachel und „Heute“ | Flutter |
| `lib/habits/widgets/habit_countdown.dart` | zeigt den Timer und tickt, solange er läuft — **eine Stelle** für Blatt, Kachel und „Heute“ (`HabitClock`) | Flutter |
| `lib/habits/widgets/habit_timer_sheet.dart` | das Blatt mit dem Ring: Start, Pause, „schon erledigt“ — meldet nur, **hakt nicht ab** | Flutter |
| `lib/habits/week_review_screen.dart` | der Wochenrückblick, der sich aufbaut — sonntags und montags gross angekündigt | Flutter |
| `lib/habits/widgets/custom_habit_sheet.dart` | das Formular für eine eigene Gewohnheit | Flutter |
| `lib/habits/daily_quests_provider.dart` | die Aufgaben von heute — setzt nur die Rückfrage ein, **rechnet nichts** | Flutter |
| `lib/habits/widgets/daily_quests_card.dart` | die Aufgaben **als Anschlagtafel**, jede ein Steckbrief: Zeichen, Satz, Kästchen, Schlüssel; ein Tipp aufs Blatt holt ab — **am Lagerfeuer** (ADR-0076) | Flutter |
| `lib/habits/widgets/cue_dialog.dart` | **„Wann machst du das?“** — der Auslöser einer Gewohnheit ([ADR-0052](docs/decisions/0052-ausloeser-und-startvorlage.md)) **, ihre Wochentage, woran sie gekoppelt ist und was es danach gibt** ([ADR-0066](docs/decisions/0066-versuchungsbuendel.md)) | Flutter |
| `lib/habits/cue_text.dart` | wie der Auslöser auf dem Bildschirm steht — Satz oder „Nach: …“; **eine Stelle** für Kachel und Startseite | Flutter |
| `lib/habits/widgets/weekday_picker.dart` | sieben Kreise Mo bis So; wie die Wochentage heißen — **eine Tabelle** (`Wochentage`) | Flutter |
| `lib/habits/widgets/streak_freeze_card.dart` | der Knopf, der gestern deckt — nur wenn es etwas zu retten gibt | Flutter |
| `lib/gear/gear_controller.dart` | Riverpod-Brücke Inventar ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/gear/shop_screen.dart` | der Laden: **nur kaufen**, sechs Angebote am Tag — Besessenes steht in der Ausrüstung (Issue #88) | Flutter |
| `lib/gear/equipment_screen.dart` | **die Ausrüstung** ([ADR-0057](docs/decisions/0057-ausruestung-bekommt-einen-eigenen-bereich.md)): sechs Plätze, darunter **der Rucksack** — jedes Exemplar eine Kachel mit Pfeil und Schloss, in vier Ordnungen, Aufräumen je Seltenheit ([ADR-0081](docs/decisions/0081-der-rucksack-und-das-schloss.md)); **gewechselt wird per Ziehen** | Flutter |
| `lib/gear/widgets/gear_sheet.dart` | das Blatt eines Stücks: alle Werte, **jedes eigene Exemplar**, anlegen, ablegen, verkaufen, **sperren** | Flutter |
| `lib/gear/gear_grouping.dart` | wie der Katalog geordnet wird: A–Z, Platz, Seltenheit, Set; reine Rechnung | Flutter |
| `lib/gear/sell_flow.dart` | **der einzige Weg zu verkaufen**: ein Exemplar, alles Schlechtere einer Seltenheit **oder die Auswahl mit Häkchen**, mit Rückfrage und Feier | Flutter |
| `lib/gear/verkauf_auswahl.dart` | **was ein Häkchen bekommen darf** (nie Angelegtes oder Gesperrtes) und was die Auswahl bringt — reine Rechnung, eine Stelle für Siegerblatt und Rucksack (ADR-0083) | Flutter |
| `lib/gear/widgets/verkauf_leiste.dart` | Auswahl an/aus und „Verkaufen“ mit Anzahl und Gold | Flutter |
| `lib/gear/widgets/shop_item_cell.dart` | ein Exemplar als Kachel im Raster — wählt, kauft nicht; im Laden mit dem Zeichen der Sammlung, wenn man das Stück schon einmal hatte | Flutter |
| `lib/character/character_screen.dart` | Kopf, Beständigkeit, Werte mit Herkunft, Wege zu Ausrüstung und Fähigkeiten | Flutter |
| `lib/character/widgets/consistency_card.dart` | die Streak-Zahlen und der Satz darunter | Flutter |
| `lib/character/abilities_screen.dart` | **die Fähigkeiten** ([ADR-0049](docs/decisions/0049-faehigkeiten-bekommen-einen-eigenen-bereich.md)): vier Plätze, darunter **nur die eigenen** ([ADR-0082](docs/decisions/0082-nur-eigene-faehigkeiten.md)), **ein Raster ohne Überschriften** in drei Ordnungen; **Platz antippen, dann eine Fähigkeit** — oder ziehen | Flutter |
| `lib/character/faehigkeit_ordnung.dart` | wie die eigenen Fähigkeiten geordnet stehen: Seltenheit, A bis Z, Art — reine Rechnung | Flutter |
| `lib/character/widgets/ability_sheet.dart` | das Blatt mit **allen** Werten — es kann auch gesperrte, aufgerufen wird es seit ADR-0082 nur für eigene | Flutter |
| `lib/character/widgets/ability_slots_row.dart` | die vier Fähigkeitsplätze — zeigt nur, wählt nicht | Flutter |
| `lib/character/widgets/ultimate_platz.dart` | der Platz der Ultimate und ihr **goldener Doppelrand** (`UltimateRand`) — eine Stelle für Platz, Kachel und Blatt | Flutter |
| `lib/character/abilities_controller.dart` | Riverpod-Brücke Fähigkeiten ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/character/identity_controller.dart` | Riverpod-Brücke Identität ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/character/ability_unlock.dart` | was neu ist und wohin es passt — reine Rechnung | Flutter |
| `lib/character/show_ability_unlock.dart` | die Feier, aufgerufen an genau zwei Stellen | Flutter |
| `lib/progression/show_level_up.dart` | die Feier eines **Aufstiegs** — nach den Errungenschaften, vor den Fähigkeiten | Flutter |
| `lib/village/village_map.dart` | **das Dorf (Prototyp)**: Karte als Text, Wege, Laufen, Türen, reines Dart, ohne Bildschirm testbar | Flutter |
| `lib/village/village_screen.dart` | das Dorf im Entwicklermodus: Tippen geht hin, Ziehen steuert, **hinein nur über den Knopf am Gebäude**, „Heute“ immer einen Tipp entfernt | Flutter |
| `lib/village/house_screen.dart` | **das eigene Haus**: Pokale, Titel, Ausrüstung und Gold aus Truhen, alles abgeleitet (`HouseView`) | Flutter |
| `tool/figur_ausruestung.py` | legt Rüstungen und Waffen aus dem Laden **verkleinert** auf die Figur — Platzhalter, die Helme sind gezeichnet (Python mit Pillow) | Python |
| `tool/dorf_kacheln.py` | zeichnet die groben Dorfkacheln nach `assets/Dorf/` (Python mit Pillow) | Python |
| `tool/item_icons.py` | **zeichnet** die zwölf Stücke aus ADR-0077, ihre zwei Grundangriffe und ihre sechs Bilder auf der Figur — Rüstung und Helm als umgefärbter Umriss von Lederwams und Lederkappe (nur Standardbibliothek) | Python |
| `tool/faehigkeit_icons.py` | **zeichnet** die zwölf Bilder zu AktivesBretts Fähigkeiten nach `assets/Faehigkeiten/` — aus Formen, nicht aus dem Raven-Paket (nur Standardbibliothek) | Python |
| `tool/kampf_klaenge.py` | **rechnet** die zehn Klänge der Grube nach `assets/Sound/` — Platzhalter, die dem Projekt gehören (nur Standardbibliothek) | Python |
| `tool/haekchen_klaenge.py` | **rechnet** die **Tonleiter des Tages**: fünf Stufen, der Akkord, wenn der Tag geschafft ist, das Fauchen der Flamme — mit den Helfern aus `kampf_klaenge.py` | Python |
| `tool/lern_klaenge.py` | **rechnet** den Klang einer **falschen Antwort** — zwei weiche Schläge abwärts, die nicht strafen | Python |
| `lib/dev/dev_screen.dart` | Entwicklermodus, **nur im Debug-Build** | Flutter |
| `lib/dev/debug_grants.dart` | was der Dev-Modus verschenkt hat — Erfahrung, Gold, Punkte, Fähigkeiten **und Kampfwerte** (im Kampfmassstab, als eigener Summand in `heroPowerProvider`) | Flutter |
| `lib/dev/grube_werkbank.dart` | **die Werkbank in der Grube**, nur auf dem Dev-Stand: Funde jeder Seltenheit vor den Helden legen, Gegner jeder Art beschwören; der Lauf steht still, solange sie offen ist | Flutter |
| `lib/dev/save_slot.dart` | echter Stand vs. Dev-Stand | Flutter |
| `lib/audio/sound_effects.dart` | welcher Klang zu welchem Moment gehört — **eine Tabelle**, in Tests stumm | Flutter |
| `lib/ui/holz.dart` | Planke, Rahmen, Balken, Knopf aus dem UI-Paket — **über das Theme**, nicht je Knopf; `HolzKarte`, `HolzDialog`, `HolzBlatt` für jede Fläche, `HolzGruppe` um die Kreise der Startseite | Flutter |
| `lib/ui/aufstieg.dart` | **Zahlen steigen dort auf, wo getippt wurde** — der Host merkt sich den Finger; von dort **fliegen Münzen und Funken zur Leiste** (`fliege`) und platzt das **Konfetti** (`konfetti`) | Flutter |
| `lib/ui/beute_flug.dart` | **Münzen zur Goldzahl, Funken zum Balken, grüne Funken zum Gebiet** — reine Rechnung; ein Ziel meldet sich mit `FlugZielMarke` an | Flutter |
| `lib/ui/konfetti.dart` | das Konfetti, wenn der Tag geschafft ist — gesät, reine Rechnung | Flutter |
| `lib/ui/muenz_bild.dart` | wie eine fliegende Münze und ein Funke aussehen — **eine Stelle** für den Goldregen der Grube und das Häkchen | Flutter |
| `lib/ui/sprung.dart` | **wie etwas aufspringt** — eine gedämpfte Feder für Häkchen und Flamme | Flutter |
| `lib/ui/druck.dart` | **jeder Knopf gibt nach** — `Druck` für Eigenes, `Druck.builder` im Theme | Flutter |
| `lib/ui/palette.dart` | alle Farben der App — **zwei Untergründe, zwei Sätze** | Flutter |
| `lib/ui/level_abzeichen.dart` | das Level als Abzeichen; **welcher Rahmen zu welchem Level gehört** (`LevelRahmen`, je zehn Level einer) | Flutter |
| `lib/ui/ausgegraut.dart` | wie „noch nicht“ aussieht: eine Stelle für Fähigkeiten und Ausrüstung | Flutter |
| `lib/ui/anschlagtafel.dart` | **die Anschlagtafel**: dunkle Bretter im Holzrahmen, oben ein Schild — gezeichnet auf dem Raster der Bildpunkte; dazu der `Steckbrief` mit Reißzwecke, Risskante und Stempel, der **nur beim Abholen aufschlägt** | Flutter |
| `lib/ui/wackeln.dart` | **was sich gerade wählen lässt, wackelt kurz** und behält einen goldenen Rand (Issue #138) — endet von selbst | Flutter |
| `lib/ui/halten_und_ziehen.dart` | **Halten und Ziehen** wie beim Deckbau: Zustand eines Platzes, Bild unter dem Finger, Hochrollen, **Aufleuchten** eines freien Platzes (`PlatzLaedtEin`). Eine Stelle für Ausrüstung und Fähigkeiten | Flutter |
| `lib/habits/stat_icon.dart` | welches **Zeichen** zu welchem Wert gehört — Hantel, Herz, Schild, Tropfen; **eine Tabelle** ([ADR-0060](docs/decisions/0060-die-app-geht-ohne-lesen.md)) | Flutter |
| `lib/ui/ruhm_zahl.dart` | Ruhm als Zeichen mit Zahl, überall dasselbe | Flutter |
| `lib/ui/on_dark.dart` | klammert ein, was auf Leder statt Pergament steht | Flutter |
| `lib/ui/pixel_art.dart` | eine Zeichnung fester Größe — **und ob hart oder weich skaliert wird** | Flutter |
| `lib/ui/gold_icon.dart` | die Goldmünze, überall dieselbe | Flutter |
| `lib/ui/phone_frame.dart` | zeigt die App im Browser in Handygröße — **und auf Tablets**, wo Android das Hochformat seit targetSdk 36 nicht mehr einhält | Flutter |
| `lib/combat/ladder_controller.dart` | Riverpod-Brücke Reihe ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/combat/ladder_screen.dart` | der Eingang zur Grube: oben die **Tagesgrube**, darunter **„Ebene 18“** — nur die nächste, kein Fahrstuhl mehr —, Belohnung als Zeichen, „Hinab" | Flutter |
| `lib/combat/widgets/eingangs_glut.dart` | **der Schlund im Eingang**: glüht in der Farbe dessen, was unten fällt — Feuer, ab 10 episch, ab 20 legendär, über 30 blutrot (`GlutStufe`); atmet in Tests nicht (`test/flutter_test_config.dart`) | Flutter |
| `lib/combat/daily_pit_controller.dart` | Riverpod-Brücke Tagesgrube ↔ UI, **enthält keine Regeln**; `dailyConditionProvider` sagt, in welcher Verfassung es heute hinabginge | Flutter |
| `lib/combat/widgets/tagesgrube_karte.dart` | die Tagesgrube im Eingang: Satz des Tages, Verfassung, „Hinab“ — **trägt den Versuch ein, bevor der Lauf beginnt**; danach Ergebnis und Teilen | Flutter |
| `lib/combat/widgets/tagesgrube_ergebnis.dart` | das Blatt am Ende der Tagesgrube: Raumzeile, Zeit, Verfassung, Tageskette, Ruhm, Teilen | Flutter |
| `lib/combat/widgets/raumzeile.dart` | die Raumzeile als Bild — gezeichnet, nicht als Emoji; dieselben Felder wie im Text | Flutter |
| `lib/combat/tagesgrube_text.dart` | **der Text zum Teilen** — reine Rechnung, verrät weder Karte noch Satz | Flutter |
| `lib/combat/widgets/teilen_knopf.dart` | kopiert einen Text und bleibt auf „Kopiert“ stehen | Flutter |
| `lib/combat/widgets/tagesform_kreis.dart` | die **Tagesform als Blitz**, der sich mit jedem Häkchen auflädt; Tipp zeigt, was sie bringt | Flutter |
| `lib/combat/move_icon.dart` | welches Bild zu einer Fähigkeit oder Waffe gehört | Flutter |
| `lib/gear/gear_icon.dart` | welches Bild zu einem Ausrüstungsstück gehört | Flutter |
| `lib/combat/widgets/lauf_ergebnis.dart` | das Blatt am Ende eines Laufs: „Sieg“ grün oder „Niederlage“ rot, Ebene und Zeit, XP und Gold gleiten herein, die Funde — **nach einer Niederlage statt dessen drei Tipps**, jeder ein Knopf in seinen Bereich (ADR-0084) —, zuletzt „Weiter“ | Flutter |
| `lib/combat/widgets/siegerblatt_funde.dart` | **die Funde im Siegerblatt** (ADR-0083): drehen sich nacheinander um, **das Seltenste zuletzt**, Pfeil gegen das Getragene, Tipp öffnet das Blatt, Häkchen verkaufen | Flutter |
| `lib/theory/theory_controller.dart` | Riverpod-Brücke Inhalt ↔ UI, **enthält keine Regeln** | Flutter |
| `lib/theory/skill_tree_screen.dart` | vier Gebiete zum Wischen, Kopfzeile — **immer offen**, schlägt den Weg der Grundlagen vor | Flutter |
| `lib/theory/widgets/tree_view.dart` | ein Gebiet: Startknoten unten, eine Ebene darüber | Flutter |
| `lib/theory/widgets/tree_layout.dart` | wo jeder Knoten sitzt — reine Rechnung, testbar | Flutter |
| `lib/theory/widgets/tree_painter.dart` | die Verbindungslinien | Flutter |
| `lib/theory/widgets/node_action_panel.dart` | der Knopf **über** dem Startknoten | Flutter |
| `lib/theory/widgets/tree_overview.dart` | **der Überblick**: vier Gebiete mit Stand, „Weiterlesen“, Legende ([ADR-0056](docs/decisions/0056-ueberblick-im-wissensbaum.md)) | Flutter |
| `lib/theory/widgets/node_state.dart` | in welchem Zustand ein Knoten ist — eine Stelle | Flutter |
| `lib/theory/lesson_screen.dart` | lesen → Fragen → Ergebnis → **direkt zur nächsten Seite**; seit dem 18.10. **eine Spielrunde**: Klang und Vibration je Antwort, Balken oben, Konfetti bei drei von drei, **gefeiert wird, wenn gezählt ist** | Flutter |
| `lib/theory/antwort_klang.dart` | **wie eine Antwort klingt**: richtig klettert die Tonleiter, eine Stufe je Antwort in Folge; falsch klingt dumpf — reine Rechnung | Flutter |
| `lib/theory/widgets/lese_haeppchen.dart` | der Text **in Häppchen**: ein Abschnitt je Bildschirm, Striche oben, „Weiter“ | Flutter |
| `lib/theory/widgets/schreib_text.dart` | **ein Abschnitt schreibt sich**: Überschrift fällt herein, dann Wort für Wort, ein Tipp zeigt alles; erster Satz groß, Merksatz am größten | Flutter |
| `lib/theory/widgets/antwort_leiste.dart` | **das Urteil von unten**: grün oder rot, die Erklärung, der Knopf weiter | Flutter |
| `lib/theory/widgets/runden_balken.dart` | der Balken oben, der mit jeder Antwort **vorspringt**, die sitzt | Flutter |
| `lib/theory/widgets/review_section.dart` | die **Rückfrage des Tages** oben in der Theorie — eine Zeile, die aufklappt | Flutter |
| `lib/theory/review_flow.dart` | was eine Antwort auf die Rückfrage auslöst | Flutter |

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
flutter test             # 982 Tests
flutter analyze          # muss sauber sein

# Balance der Grube prüfen -- seit ADR-0039 die maßgebliche Simulation
dart run tool/pit_sim.dart             # Stufe für Stufe, bis zur Wand
dart run tool/pit_sim.dart mana        # nur: wie oft ein Platz am Mana hängt
dart run tool/pit_sim.dart faehigkeiten  # nur: was jede Fähigkeit einzeln trägt
dart run tool/pit_sim.dart ausruestung   # nur: was jede Kraft der Ausrüstung trägt
dart run tool/pit_sim.dart beute         # nur: wie viel Ausrüstung je Lauf fällt
dart run tool/runway_sim.dart          # wann einem fleissigen Spieler was ausgeht
dart run tool/tagesgrube_sim.dart      # die sieben Sätze der Tagesgrube, je Stufe

# Die Grube allein, ohne Flutter
cd packages/action_combat
dart test                              # 406 Tests
dart run example/headless_run.dart     # eine Halle ohne Bildschirm

# Gewohnheiten allein, ohne Flutter
cd packages/habits
dart test                              # 345 Tests
dart run example/curve_sim.dart        # 90 Tage Ertrag und Werte

# Theorie, Levelkurve, Ausrüstung allein, ohne Flutter
cd packages/theory      ; dart test    # 208 Tests, prüft auch den Inhalt
cd packages/progression ; dart test    # 52 Tests
cd packages/gear        ; dart test    # 137 Tests, prüft Preise, Sets, Würfel, Laden, Beute, Vergleich, Schloss und Übernahme
cd packages/abilities   ; dart test    # 43 Tests
cd packages/identity    ; dart test    # 25 Tests, prüft nur noch den Wortlaut
cd packages/achievements; dart test    # 25 Tests, prüft den ganzen Katalog
cd packages/haustier    ; dart test    # 21 Tests
```

**Der Kampf ist seit [ADR-0039](docs/decisions/0039-die-grube-ersetzt-den-rundenkampf.md)
die Grube.** Echtzeit, hundert Stufen ([ADR-0075](docs/decisions/0075-hundert-ebenen.md)), jede Karte neu gesteckt. Der
Rundenkampf ist gelöscht. Die Regeln der Grube stehen an je einer
Stelle:

| Frage | Antwortet |
|---|---|
| Wie hart ist eine Stufe? | `PitStage` — die Zahlen in `ActionBalance` |
| Wie lange hat ein Lauf? | `PitStage.timeLimitSeconds`, auffüllbar über Zeitkugeln ([ADR-0046](docs/decisions/0046-uhr-in-der-grube.md)) |
| Wie sieht die Grube aus? | `LevelBuilder.build(stage, seed)` aus `RoomCatalog`, **gesät** |
| Was bringt ein Lauf ein? | `LadderController.recordRun` — einmal je Stufe |
| Was tut eine Fähigkeit in der Grube? | `PitAbilities` — **dieselbe Id** wie in `abilities`, sonst wirkt sie nicht |
| Welche Plätze gehen mit? | `activeMovesProvider`, gefiltert in `ActionWorld` — was die Grube nicht kennt, fällt heraus |
| Wie schlägt der Held? | `PitWeapons` — über den **Waffenzug** (`AbilityCatalog.weaponMoves`), nicht die Item-Id |
| Was kann der Held im Kampf? | Grundangriff der Waffe (von selbst) und die drei Plätze — **keine** Grundfähigkeiten; auf der Tastatur 1–3 (`PitRunView`) |
| Was ändern Sets und Kräfte? | `pitModifiersFor` in `lib/gear/set_effects.dart` — rechnet nichts, übersetzt nur |
| Welche Kraft trägt ein Stück? | `GearItem.power` (Id) → `PitGearPowers` (Wirkung) — seit ADR-0077 auf **jeder** Seltenheit; ein Set über `SetPerk.powers` |

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

**Eine Kraft am Helden ist ein Passiv**
([ADR-0077](docs/decisions/0077-ausruestung-mit-kraeften.md)):
Lebensraub, Frostreif, Irrlichter und die übrigen stehen als
`PitPassive` neben Kampfrausch und Ruhepuls, und die Ausrüstung bringt
sie als `GrantPassive` mit — derselbe Weg wie jede andere Veränderung,
`apply` lässt die Fähigkeiten dabei, wie sie sind. `ActionWorld` sammelt
die Passive der Plätze und der Ausrüstung an einer Stelle, ausgeführt
wird in `gear_powers.dart`. **Jede Heilung ausser dem Lebensraub geht
über `_healHero`**: Dort macht der Blutpakt des vollen Vampirsets sie zu
Schaden am nächsten Gegner. Wer eine neue Heilung baut und `_hero.hp`
selbst setzt, heilt am Blutpakt vorbei. **Der Lebensraub rechnet am
ganzen Schlag**, nicht an dem, was der Gegner noch an Leben hatte
(`_afterHeroHit` bekommt den ungekappten Schaden) — sonst heilt der
letzte Schlag auf einen fast Toten fast nichts.
`ausruestung_kraefte_test.dart`.

Eine Wirkung ist ein **Datum** (`PitEffect`, `sealed`), keine Methode:
Eine neue Art trägt man dort ein, und der Analyzer zeigt auf die eine
Stelle in `effects.dart`, die sie ausführt. Das ist die Naht, an der Sets
und Legendäre später eine Fähigkeit verändern. Seit [ADR-0073](docs/decisions/0073-ultimate-mana-und-neue-arten.md)
und [ADR-0074](docs/decisions/0074-aktivesbretts-faehigkeiten.md)
sind es neununddreißig Fähigkeiten und vier Ultimates aus neunundzwanzig
Arten; `test/pit_test.dart` hält fest, dass jede lernbare Fähigkeit und
jede Waffe im Laden in der Grube etwas tut.

**Ein Passiv hat keinen Knopf** (`PitAbility.isPassive`: alle Wirkungen
sind `PitPassive`). Es liegt auf einem Platz, kostet nichts, klingt nicht
ab und wirkt den ganzen Lauf; im Kampf steht sein Bild blasser und nimmt
keinen Tipp an.

**Der Grundangriff hat eine Grenze**: Alle Stärkungen zusammen —
Self-Buff, Kampfrausch, Bestform — machen ihn höchstens
`ActionBalance.weaponBuffCap` (1,25) härter. Fähigkeiten trifft sie
nicht. Ein Faktor auf das, was jede halbe Sekunde fällt, entschiede
sonst den Kampf allein (ADR-0009). `aktivesbrett_arten_test.dart`.

**Ab Level 15 gibt es die Ultimate**
([ADR-0073](docs/decisions/0073-ultimate-mana-und-neue-arten.md)):
ein eigener Platz, kein Mana, keine Abklingzeit. Sie lädt an
Ereignissen, nie am Schaden — sonst wäre sie spät dauernd voll.

| Frage | Antwortet |
|---|---|
| Ist der Platz offen? | `AbilitySlots.ultimateOpenAt` — Level 15 |
| Welche geht mit in die Grube? | `activeUltimateProvider` — gewählt, verdient, Platz offen; die einzige Stelle |
| Woran lädt sie? | `ActionBalance.ultimatePerKill` (ein Achtel) und `ultimatePerBossHit`; nicht, was im Lauf entsteht oder ein Begleiter tötet |
| Wie sieht sie aus? | `UltimateRand` — goldener **Doppel**rand, keine Seltenheit; im Kampf gross in der Ecke, Taste 4 |

**Eine Ultimate liegt nie auf einem der drei Plätze**: `PitAbilities.byId`
und `AbilityCatalog.byMoveId` finden sie nicht, nur `ultimateById`.
Stillstand trifft den Wächter über eine **Stun-Leiste** (drei Kerben,
erst der dritte wirkt, halb so lang, und bricht seine Ankündigung ab);
`neue_arten_test.dart` hält die Regeln der neuen Arten fest.

**Elf Gegnerarten** (`EnemyKind`), jede mit einem Grund, der an ihrem
Eintrag steht: Fussvolk `e`, Schütze `s`, Kobold `k` (schneller als der
Held), Fledermaus `f` (beisst und flattert davon, `_batActs`), Troll `t`
(gross, zäh, setzt meist der Zufallsbau — auf tieferen Stufen öfter),
der Wächter `B`, **allein in seinem Raum**, und seit
[ADR-0063](docs/decisions/0063-besetzung-in-rollen.md) Schleim `j`
(zerfällt in zwei Schleimlinge), Grimlock `g` (blind, schlägt hart),
Kreischpilz `p` (weckt den Raum), Sporenpilz `m` (heilt die anderen) und
Wächterauge `o` (Strahl, als Linie angekündigt). Welches Zeichen welche
Art setzt, steht in `Level.symbols`.

**Wer in einer Grube steht, sagt ihre Besetzung** (`PitCast`, je Lauf
gewürfelt, auf jeder Stufe aus demselben Topf). Die Räume im Katalog
schreiben in **Rollen**, die Besetzung sagt, wer sie spielt:

| Rolle im Raum | Wer sie spielen kann | Antwortet |
|---|---|---|
| `e`, wer heranläuft | Fussvolk — und auf der Hälfte der Plätze Schleim, Grimlock oder niemand sonst | `PitCast.secondMelee` |
| `s`, wer schiesst | Schütze oder Wächterauge | `PitCast.ranged` |
| `k` und `f`, das Rudel | Kobold oder Fledermaus | `PitCast.swarm` |
| in jedem zweiten Raum einer, auf einem Platz des Fussvolks | Kreischpilz oder Sporenpilz | `PitCast.special` |

**Das Fussvolk bleibt immer dabei**: Eine Grube nur aus blinden Grimlocks
liesse sich bis zum Wächter durchschleichen, und der zahlt den ganzen
Topf. Die Besetzung **ersetzt, sie stellt nicht dazu**, und sie hat
eigene Würfel, damit sie die Karte nicht verschiebt (`cast_test.dart`).
`PitCast.classic` lässt jeden Raum, wie er geschrieben ist. Eine neue Art
braucht: einen Eintrag in `EnemyKind` mit ihrem Grund, ein Zeichen in
`Level.symbols`, Werte in `ActionBalance`, ein Bild in `GrubeFiguren` und
einen Platz in einer der vier Listen in `PitCast` — der Analyzer zeigt
auf die Schalter dazwischen.

**Was im Lauf entsteht, zahlt nichts** (`ActionEntity.lootless`): Die
Schleimlinge zählen als Gegner, aber nicht für den Topf und lassen keine
Kugel fallen — sonst hinge der Ertrag einer Stufe daran, wie oft etwas
zerfällt. **Heilung der Gegner ist ein Anteil des Lebens des Geheilten**,
nie des Heilers, und kein Sporenpilz heilt sich selbst, einen anderen
Sporenpilz oder den Wächter. **Ein Schrei ist keine Ankündigung**
(`ActionWorld.alarms`, nicht `telegraphs`): Er schadet nicht, und aus ihm
läuft man nicht hinaus, man fällt den Pilz vorher. Im Bild ist er gold.
Wer an einer Art dreht, liest die dritte Tabelle von `pit_sim` („Je
Besetzung“).

**Ein Gegner kommt nur aus zwei Gründen:** Er sieht den
Helden (im Umkreis `aggroRadius` **und** ohne Wand dazwischen), oder er
wurde von ihm getroffen, dann auch von weiter weg (`_enemiesAct`,
`aggro_test.dart`). Durch eine Wand bemerkt ihn niemand — ausser ein
Kreischpilz hat geschrien: Der Schrei geht durch Wände.

**Die Uhr läuft, und sie ist gegen das Kiten**
([ADR-0046](docs/decisions/0046-uhr-in-der-grube.md)). Jede Stufe hat
ein Limit, gemessen am Bot mit etwa doppeltem Puffer; läuft es ab, ist
der Lauf verloren (`RunEnded.timedOut`). Zeitkugeln füllen auf, nie über
das Limit. Ohne Stufe gibt es keine Uhr. Wer an `timeBaseSeconds` oder
`timePerRoomSeconds` dreht, lässt `clock_test.dart` und `pit_sim` laufen.

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

**Es gibt vier Wächter, und jeder Lauf würfelt einen**
([ADR-0062](docs/decisions/0062-waechter-und-besetzung-werden-gewuerfelt.md)):
Zyklop, Zweikopf, Schlund, Sumpftroll (`BossKind`). Für die Simulation
sind alle `EnemyKind.endgegner`; welcher es ist, steht an der Karte
(`Level.boss`), gewürfelt in `LevelBuilder.bossFor` mit **eigenem
Würfel**, damit der Wächter die Karte nicht verschiebt. Eine
handgeschriebene Halle hat ohne Angabe den Zyklopen. Leben, Angriff und
Größe teilen sich alle vier, verschieden ist, was sie tun:

| Frage | Antwortet |
|---|---|
| Welcher Wächter wartet? | `Level.boss`, im Lauf `ActionWorld.bossKind` |
| Was wählt er als Nächstes? | `_zyklopWaehlt` und seine drei Geschwister in `boss.dart` |
| Was kann er auf dieser Stufe? | `_BossLage.kenntZweiten` / `kenntDritten` — dieselben zwei Stufen für alle |
| Wie sieht er aus, wie heißt er? | `GrubeFiguren.forBoss`, `BossText` |

Ein fünfter Wächter ist ein Eintrag in `BossKind`; der Analyzer zeigt
dann auf jede Stelle, die ihn kennen muss. **Eine Fläche kann dem Helden
schaden** (`_Zone.hostile`, die Pfütze des Sumpftrolls): Sie trifft nie
die Gegner, liegt kürzer als ihre Abklingzeit und ist im Bild grün mit
rotem Rand. Wer an einem Wächter dreht, liest die zweite Tabelle von
`pit_sim` („Je Wächter“).

**Jeder Angriff des Wächters ist angekündigt** (`TelegraphView`: ein Ring
oder eine Linie, die sich füllt) und lässt sich durch Laufen umgehen — es
gibt keinen Sturmschritt mehr. Wer einen Angriff dazubaut, gibt ihm eine
Ankündigung, die länger dauert als der Weg hinaus; `boss_test.dart` prüft
das für jeden Ring, und dass keiner um den Wächter bis an die Wand seines
Raums reicht. Welche Angriffe er kennt, hängt an der Stufe
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

**Seit [ADR-0050](docs/decisions/0050-zwischenebenen-und-angekuendigte-gebiete.md)
hat der Baum drei Ebenen:** Wurzel → **Zwischenebene** („Kraft &
Muskulatur", ein Punkt, eine Einführungsseite) → Thema. Seit
[ADR-0061](docs/decisions/0061-der-baum-waechst-aus-dem-gelesenen.md)
darf ein Thema eigene Kinder haben (Gewohnheiten → Die vier Regeln →
Mach es offensichtlich). Überschriften
ohne Inhalt stehen als `TheoryPlaceholder` grau im Bild und lassen sich
nicht öffnen. **Wer eine befüllt**, nimmt sie aus `theoryPlaceholders`
und trägt sie mit **derselben Id** als Knoten ein — samt Einführungsseite
in `area_pages.dart`.

**Jeder Knoten kostet einen Punkt, auch die Wurzeln**
([ADR-0051](docs/decisions/0051-wurzeln-kosten-einen-punkt.md)) **und
das frühere Handbuch** ([ADR-0070](docs/decisions/0070-das-handbuch-steht-im-baum.md)).
Kein Knoten ist kostenlos: Er wäre von Anfang an offen und zöge seine
Eltern mit auf. **Zum Start gibt es einen Punkt, jeder Aufstieg bringt
einen** ([ADR-0078](docs/decisions/0078-ein-startpunkt.md),
`TheoryPoints.atStart`): Ein Level ist ein Punkt, vom ersten Tag an.
Bis dahin gab es neun, so viel wie der **Weg der Grundlagen** kostet
(`theoryBasicsPath`: Geist, Selbstentwicklung, Gewohnheiten, Die vier
Regeln und die fünf Seiten), und ein Neuer las auf Level 2 mit zehn
Punkten ein ganzes Gebiet am Stück.

| Frage | Antwortet |
|---|---|
| Was schlägt der Baum als Nächstes vor? | `TheoryProgress.suggestedStep` — erst lesen, was offen ist, sonst der nächste Schritt auf dem Weg der Grundlagen |
| Welche Seite kommt nach dieser? | `TheoryProgress.nextAfter` — die nächste im Buch, offen oder bezahlbar; ein Durchgang, einmal herum |
| Wie viele Seiten sind bestanden? | `passedPagesProvider` — **nur der Graph**; die flachen Zweige dazuzuzählen zählt doppelt |

**Offen ist, was gekauft, bestanden oder einziger Eltern eines Offenen
ist** (`TheoryProgress.openIdsIn`, `TheoryGraph.withSoleParents`). Damit
behalten alte Stände alles, ohne dass der Spielstand umgeschrieben wird.
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
kostet einen Punkt, seit ADR-0051 auch jede Wurzel.

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

Die Regeln zu eigenen Gewohnheiten, die im Code an je einer Stelle
stehen und dort bleiben müssen:

| Frage | Antwortet |
|---|---|
| Wie viele eigene darf jemand anlegen? | `HabitRewards.customSlotsFor` — ein Platz je freigeschalteter Vorlage |
| Was ändert der Schwierigkeitsgrad? | `HabitDifficulty.xpFactor` — nur Erfahrung, nie Gold |
| Was darf sich nachträglich ändern? | `CustomHabit.editable` — nur, was keine Zahl erzeugt |
| In welcher Reihenfolge steht die Tagesliste? | `HabitTracker.stackOn` → `HabitStacks.order` — Gekoppeltes unter seinem Anker; **Stapel** mit Offenem oben, ganz erledigte unten, je nach Priorität |
| Woran hängt eine Gewohnheit? | `HabitTracker.anchorFor` — höchstens ein Anker, nie im Kreis (`canAnchor`); **Satz oder Anker**, `setAnchor` und `setCue` ersetzen einander ([ADR-0065](docs/decisions/0065-gewohnheiten-koppeln.md)) |
| Was ist jetzt dran? | `StackedHabit.isCued` — selbst offen, der Anker abgehakt; erzeugt keine Zahl und sperrt nichts |
| Was kommt heute zuerst? | `HabitTracker.firstUpOn` — am Abend davor am Lagerfeuer gewählt; sein **Stapel** steht vor allen offenen, erzeugt keine Zahl ([ADR-0076](docs/decisions/0076-das-lagerfeuer.md)) |
| Wann kommt eine Gewohnheit dran? | `HabitTracker.cueFor` — eine Zeile Text, für Vorlagen **und** eigene, erzeugt keine Zahl ([ADR-0052](docs/decisions/0052-ausloeser-und-startvorlage.md)) |
| Was gibt es danach? | `HabitTracker.treatFor` — eine Zeile Text neben Satz **oder** Anker, erzeugt keine Zahl; beim Abhaken sagt `sayHabitFeedback` „Jetzt: …“ ([ADR-0066](docs/decisions/0066-versuchungsbuendel.md)) |
| Wie läuft ein Zeitziel? | `HabitTracker.startTimer`, `pauseTimer`, `settleTimer` — aus der Startzeit, höchstens einer, Minuten bleiben stehen ([ADR-0067](docs/decisions/0067-zeitziele-als-timer.md)) |
| Was tut ein Tipp auf eine Gewohnheit? | `tapHabit` in `habit_check_flow.dart` — ein offenes Zeitziel öffnet den Timer, alles andere hakt ab |
| Welche Vorlage ist ab Start offen? | `HabitCatalog.starter` — Zwei Minuten lesen, samt Platz für eine eigene; die einzige Vorlage mit Timer |
| Wie lang ist die Tageskette? | `HabitTracker.currentDayStreak` — Tage mit mindestens einem Häkchen, dieselbe Eis-Regel ([ADR-0055](docs/decisions/0055-tageskette-aufgaben-und-wiederholen.md)) |
| Welche Aufgaben gibt es heute? | `DailyQuests.forDay` — nie aus der Grube, sonst kämen Schlüssel aus dem Spielen (ADR-0048); gezählt wird, was heute fällig ist |

**Seit [ADR-0064](docs/decisions/0064-wochenplan-und-kette-die-faellt.md) hat jede Gewohnheit einen
Wochenplan, und eine Kette fällt, statt zu reißen.** Gezählt werden
erledigte **fällige** Tage. Ein Tag außerhalb des Plans, eine Pause und
ein Streak-Eis tragen die Kette, verlängern sie aber nicht; ein
verpasster fälliger Tag lässt sie auf die **Stufe darunter** fallen
(45 → 30, 10 → 7, 7 → 3), jeder weitere wieder eine. Ein Tag, an dem
nichts fällig ist, ist ein **Ruhetag**: keine Truhe, keine Tagesform.

| Frage | Antwortet |
|---|---|
| Ist die Gewohnheit heute dran? | `HabitTracker.isDueOn` — die einzige Stelle; Tagesliste, Truhe, Tagesform, Aufgaben und Ketten fragen dort |
| Was ist heute zu erledigen? | `HabitTracker.dueIdsOn` — was läuft und fällig ist, **und** was heute gestoppt wurde |
| Wie läuft eine Kette? | `StreakRule.walk` — vorwärts durch die Tage; was ein Tag bedeutet, sagt `HabitTracker._habitDay` |
| Wohin fällt sie? | `HabitRewards.streakAfterMiss` — die Stufe **streng** darunter |
| Ab wann gilt ein neuer Plan? | `HabitTracker.weekdaysChangeFrom` — ab morgen; sofort nur, solange nichts abgehakt ist |
| Was passiert beim Stoppen? | `HabitTracker.deactivate` — Pause ab morgen, die Kette steht still; `activate(today:)` beendet sie |

**Der Plan ist eine Historie** (`HabitPlan`: „ab Tag X gelten diese
Wochentage“), kein Feld. Sonst schriebe jede Änderung die Vergangenheit
um, und das Level könnte nachträglich fallen. Wer an der Kettenregel
dreht, lässt `week_plan_test.dart` und `curve_sim.dart` laufen — die
Tabelle im ADR ist gemessen.

**Seit [ADR-0085](docs/decisions/0085-skills-je-gebiet.md) hat jedes Gebiet einen Skill, und er steht vorne.** Die
Kette misst Gleichmäßigkeit und kann fallen, der Skill misst Menge und
wächst nur. Ein Häkchen zahlt seine Erfahrung zweimal: fürs Level und für
den Skill seines Gebiets — und das sieht man: Die Funken teilen sich am
Finger, ein Strom fliegt zum Level, ein grüner zum Balken des Gebiets
darunter. Über 60 Tage steigt der Kettenbonus langsam weiter (100 Tage
×2,2, 180 ×2,4, 365 ×2,6).

| Frage | Antwortet |
|---|---|
| Zu welchem Gebiet gehört eine Gewohnheit? | `Habit.area` — eine Vorlage im Katalog, eine eigene beim Anlegen, eine alte **einmal** gefragt (`HabitTracker.assignArea`, `GebietFrageKarte`) |
| Was zahlt in einen Skill ein? | `Skills.aus` — `HabitTracker.xpIn`, `TheoryProgress.xpInArea`, `ReviewLog.xpFor`; Grube, Errungenschaften und Truhe nicht |
| Wie schnell steigt er? | `SkillCurve` — eine Gewohnheit täglich: 10 nach 50 Tagen, 50 nach 425, 100 nach 1307 |
| Was bringt er? | je Gebiet drei Titel bei 10, 25 und 50 (`AchievementArea.gebiete`); im Kampf nichts |
| Wo sieht man ihn? | Kachel (`SkillAbzeichen`, `RewardLine`), Leiste (`GebietsBalken`), Charakter (`SkillKarte`), Kopf des Baums, „Heute“ |

**Ein Skill darf nur wachsen** — sonst nähme er einen Titel zurück.
Deshalb lässt sich das Gebiet einer eigenen Gewohnheit nur setzen, wenn
sie keins hat, nie wechseln. Wer an der Kurve oder den Kettenstufen
dreht, lässt `flutter test test/skills_test.dart` und
`test/progression_test.dart` laufen.

**Das Streak-Eis deckt einen Tag, verlängert die Kette aber nicht**
([ADR-0036](docs/decisions/0036-streak-eis-als-gegenstand.md)). Drei
Regeln stehen an je einer Stelle:

| Frage | Antwortet |
|---|---|
| Trägt ein gedeckter Tag die Kette? | `HabitTracker._habitDay` — die einzige Stelle; `streakEndingAt`, `longestStreak` und `totalXp` fragen dort |
| Wie viele Eis hat jemand? | `StreakFreeze.lifetimeStock` plus die Eis aus geöffneten Truhen, minus die Historie der gedeckten Tage |
| Welcher Tag lässt sich noch retten? | `HabitTracker.rescuableDay` — immer nur gestern, und nur wenn dort etwas fällig war, dessen Kette noch stand |

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
Gewohnheiten erreichen Level 50 in 179 Tagen statt in 223 (seit den
Kettenstufen über 60 Tage, [ADR-0085](docs/decisions/0085-skills-je-gebiet.md); vorher 188 und 240). Wer an
`HabitDifficulty` dreht, lässt `flutter test test/progression_test.dart`
laufen — dort steht die Spanne als Test.

**Ausrüstung ändern heißt gegen den Gold-Zufluss rechnen.** Alle Preise
stehen in `packages/gear/lib/src/prices.dart`. Das Package kennt `habits`
nicht und muss den Zufluss deshalb annehmen (25 Gold am Tag); dass die
Annahme stimmt, prüft `test/progression_test.dart` in der App. Neue Stücke
kommen nach `catalog.dart` und werden von `catalog_test.dart` automatisch
mitgeprüft — jedes Stück muss wirken, jeder Platz führt zehn (sechs offene, vier verdiente), und teurer
muss **innerhalb einer Seltenheit** auch besser sein ([ADR-0029](docs/decisions/0029-seltenheit-statt-preisleiter.md)).

**Seit [ADR-0048](docs/decisions/0048-exemplare-tagesladen-und-beute.md)
besitzt man Exemplare, keine Katalogstücke.** Jedes hat eigene,
gewürfelte Werte (85–115 % je Wert) im **Kampfmassstab**
(`GearBonus.combatScale` = `ActionBalance.powerScale`, eine Naht, die
`test/loot_and_shop_test.dart` hält). In den Kampf gehen sie als eigener
Summand (`ActionStats.gearAttack` usw.), sonst verschwände der Wurf in
der Rundung. Der Laden verkauft **sechs Angebote am Tag**, aus dem Datum
und der tiefsten Stufe gewürfelt (`DailyShop`). **Seit
[ADR-0083](docs/decisions/0083-beute-in-der-grube.md) fällt Beute in
der Grube selbst**, über eine **Kaskade** in vier Stufen: *ob* etwas
fällt (die Grube, `ActionBalance.itemDropChance` — der Wächter immer),
welcher Platz, welche Seltenheit (beim Wächter eine Stufe höher), welches
Stück (`GearLoot.cascade`). Die Grube meldet nur die Nummer des Fundes;
was es ist, würfelt `PitBeute` aus dem Startwert des Laufs. **Hinlaufen
sammelt ein**, was am Ende noch liegt, ist weg — und **seit
[ADR-0084](docs/decisions/0084-die-niederlage-nimmt.md) behält nur ein
Sieg das Eingesammelte**; nach einer Niederlage fliegt es im Bild mit
weg. Ein **Schlüssel** — einer je Häkchen, Seite und richtiger
Rückfrage (`earnedKeysProvider`), höchstens zehn (`GearKeys`) — öffnet
nach einem Sieg einen Extra-Wurf. Die Tagesgrube wirft nichts.
Wer an der Kaskade dreht, lässt `dart run tool/pit_sim.dart beute` und
`tool/runway_sim.dart` laufen.

| Frage | Antwortet |
|---|---|
| Was steht zum Verkauf? | `dailyOffersProvider` → `DailyShop.offersFor` |
| Was fällt in der Grube? | erst `ActionBalance.itemDropChance` (ob), dann `GearLoot.cascade` (Platz, Seltenheit, Stück) |
| Was ist ein Schlüssel wert? | ein Extra-Wurf auf der Kaskade nach dem Lauf (`GearController.takeKeyLoot`) |
| Wie viele Schlüssel? | `availableKeysProvider` — verdient minus verbraucht, gedeckelt |
| Was ist Ausschuss? | `Loadout.junkOf(seltenheit)` — nicht getragen, **nicht gesperrt** und nicht besser als das Getragene; seit ADR-0081 ohne Ausnahmen, dafür gibt es das Schloss |
| Ist es besser? | `Loadout.vergleiche` — erst die Seltenheit, dann die Summe der Werte; ein leerer Platz macht alles besser |

**Verkauf bringt ein Viertel**, egal ob gekauft oder erbeutet
(`GearPrices.refundShare`); bei der Hälfte wäre Beute eine Goldquelle
aus dem Spielen. Gold bleibt eine Rechnung aus zwei **Historien**:
alles je Erworbene samt bezahltem Preis, alles Verkaufte samt Erlös
(`Loadout.spentGold`). Jede Methode baut einen neuen `Loadout` über
`_copyWith`, das kein Feld vergessen kann; `loadout_test.dart` geht den
Weg kaufen → verkaufen → Schlüssel → kaufen → anlegen → ablegen. Alte
Stände (mit `ownedIds`) werden beim Laden übernommen: jedes Stück ein
Exemplar mit 100 %, frühere Verkäufe zum alten Satz.

**Sets ändern heißt: den Set-Katalog anfassen, nicht die Engine.** Alle
vier stehen in `packages/gear/lib/src/set_catalog.dart`, welche Stücke
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
**Lebensraub ist kein solcher Faktor** (ADR-0077): Er heilt, statt mehr
Schaden zu machen, und gilt deshalb auch für den Grundangriff.

**Das Vampirset ist das erste verdiente Set** (ADR-0077): Seine vier
Teile sind episch, also erst ab Sprosse zehn zu haben. Ein Set ist ganz
offen oder ganz verdient (`set_catalog_test.dart`), und die Preisregeln
der Sets — gleich teuer, im ersten Monat erreichbar — gelten für die
drei offenen (`GearSets.open`).

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
Alle neununddreißig und die vier Ultimates stehen in `packages/action_combat/lib/src/pit_ability.dart`,
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

**Die Grube ist nie gesperrt**
([ADR-0068](docs/decisions/0068-erster-start-deckt-die-bereiche-auf.md)).
Bis dahin hing sie am Moveset, Waffe plus eine Fähigkeit (ADR-0020);
gemessen war das im Rundenkampf, und in der Grube ist Stufe 1 mit der
Waffe allein schlagbar. Nur ihr Kreis kommt seit
[ADR-0079](docs/decisions/0079-der-mentor.md) später.

**Dafür kommen die Bereiche nach und nach, und der Mentor sagt, was
dran ist** (ADR-0079). Die Startseite fragt zuerst nach einer
Gewohnheit, jeder Kreis erscheint, wenn es dort etwas zu tun gibt, und
der nächste trägt einen Punkt. Der Weg: Gewohnheit, abhaken, erste
Seite (sie bringt jedem **Funkenstoß** über die Errungenschaft „Erste
Seite“), Fähigkeit anlegen (der zweite Platz geht **auf Level 2** auf),
Grube, und im Beute-Dialog des ersten Siegs „Anlegen“:

| Frage | Antwortet |
|---|---|
| Welcher Kreis steht da? | `ErsterStart.aus` — Theorie mit dem ersten Häkchen, Fähigkeiten mit der ersten Seite, Kampf mit der ersten angelegten Fähigkeit (oder einem Lauf, oder sieben Häkchen), Laden mit dem ersten bezahlbaren Stück, Ausrüstung mit dem ersten Stück, Charakter mit Level 2 |
| Wo steht der Mentor? | `ErsterStart.schritt` — erledigt ist ein Schritt, wenn er getan ist oder ein späterer, der ihn braucht; null nach dem ersten Sieg |
| Was sagt er hier? | `Mentor.satz(schritt, ort)` — eine Tabelle; ein Bildschirm legt `MentorFlaeche` um sich und `Zeigefinger` um sein Ziel |
| Welcher leuchtet? | `ErsterStart.leuchtet` — der Kreis des Schritts, höchstens einer |
| Woher kommen die Zahlen? | `ersterStartProvider`, das meiste aus `achievementStatsProvider` |
| Erklärt sich die Grube noch? | `ErsterStart.grubeErklaertSich` — bis die erste Stufe geschafft ist ([ADR-0069](docs/decisions/0069-die-grube-erklaert-sich-im-ersten-lauf.md)) |

**Abgeleitet, nie gespeichert, und jede Zahl darf nur wachsen** — sonst
verschwände ein Kreis wieder. Ein neuer Bereich braucht einen Eintrag in
`Bereich` und eine Bedingung dort. **Tests, die von einem leeren Stand
aus einen Kreis antippen**, überschreiben `ersterStartProvider` mit
`ErsterStart.allesOffen` — dann schweigt auch der Mentor;
`test/mentor_test.dart` geht den Weg vom leeren Stand bis zur ersten
Fähigkeit. **Seine Sätze sind die Ausnahme von ADR-0060**: Er erklärt
ohne Antippen, weil er nach dem ersten Sieg für immer schweigt. Sein
Kasten nimmt keinen Tipp an — der Mentor zeigt, er sperrt nicht.

**Die Grube erklärt sich, bis die erste Stufe geschafft ist**
([ADR-0069](docs/decisions/0069-die-grube-erklaert-sich-im-ersten-lauf.md)): ein
Geister-Steuerkreuz, das mit dem ersten Schritt geht, und die Waffe in
zwei drehenden Pfeilen beim ersten Schlag. Nach einer Niederlage steht
neben „Nochmal“ das Buch und führt in die Theorie. Was ein Lauf davon
zeigt, steht in `LaufZeichen`; `ActionGame` meldet nur Weg und Schlag.
**Ein neues Zeichen nimmt keinen Tipp an und hat keinen eigenen Takt** —
es liegt über dem Steuerkreuz und läuft aus `ActionWorld.elapsed`.
`test/erster_lauf_test.dart`.

**Das Handbuch sperrt nichts mehr** ([ADR-0070](docs/decisions/0070-das-handbuch-steht-im-baum.md)).
Seine fünf Seiten stehen als Knoten unter *Gewohnheiten*, der Baum ist
immer offen, und einen eigenen Handbuch-Bildschirm gibt es nicht. Bis
dahin hing daran erst der Kampf (ADR-0018), dann der Baum (ADR-0025).
**Niemand muss die Grundlagen lesen**: Der Baum schlägt den Weg vor,
solange nichts offen ist, und wer seine Punkte woanders ausgibt, hat
gewählt.

Die Arithmetik hat sich zweimal verschoben und wird weiter geprüft.
Früher gab das Handbuch kostenlos 275 Erfahrung und damit Level 3, die
Stufe des zweiten Fähigkeitsplatzes. Seit ADR-0078 muss gelten: Die
erste Seite ist vom Start weg bezahlbar, und **ein Häkchen plus diese
Seite bringen den ersten Aufstieg** und damit den Punkt für die nächste.
Wer an `TheoryRewards`, `HabitRewards`, der Levelkurve, den kleinen
Errungenschaften oder den Startpunkten dreht, lässt
`flutter test test/progression_test.dart` laufen. Wer an den
Fähigkeitsquellen oder den Theoriepunkten dreht, zusätzlich
`flutter test test/abilities_seam_test.dart` — dort steht, dass auf der
Stufe, auf der der zweite Platz aufgeht, ein Knoten mit Fähigkeit
erreichbar und bezahlbar sein muss. **Dort ist seit ADR-0078 kein Punkt
Luft**: drei Punkte auf Level 3, drei für Wurzel, Zwischenebene und
Thema.

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
*wiederholbarer* Belohnung. Die Grube hat hundert Stufen, jede zahlt
einmal, und der Gesamtbetrag steht deshalb als Zahl fest
(`LadderRewards.lifetimeXp`). Wer daran dreht, lässt
`flutter test test/progression_test.dart` laufen — der Kampf hängt jetzt
mit in den vier Kurven.

**Seit [ADR-0072](docs/decisions/0072-die-tagesgrube.md) gibt es einen
Kampf des Tages: die Tagesgrube** — dieselbe Grube für alle, ein Versuch
am Tag, und sie zahlt **nur Ruhm**. Die vier Stufen des Tages aus
ADR-0040 gibt es nicht mehr; eine geschaffte Stufe zahlt nichts, an
keinem Tag. Was ein Stand mit Dailies verdient hat, bleibt als Historie
in `LadderProgress` und zählt weiter (`dailies_test.dart`), sonst fiele
nachträglich ein Level.

| Frage | Antwortet |
|---|---|
| Welche Grube ist heute dran? | `DailyPit.seedFor(tag)` → `LevelBuilder`; Karte, Wächter und Besetzung folgen aus dem Datum |
| Womit geht der Held hinab? | `DailyPit.loadoutFor(tag)` — sieben Sätze, Montag bis Sonntag, jeder mit **gemessener** Stufe |
| Wie stark ist er? | `PitPower.dailyHero(inForm:)` — für alle derselbe, die Werte stehen in `ActionBalance` |
| Ist jemand in Form? | `dailyConditionProvider` → `HabitTracker.isDayComplete`; ja oder nein, ein Ruhetag ist es nicht |
| Wann ist der Versuch gebraucht? | `DailyPitLog.start` — **mit dem Hinabsteigen**; der Eintrag steht als „abgebrochen“, bis `finish` ihn überschreibt |
| Was bringt er? | `DailyPitRewards` — antreten 1, Sieg 3, Sieg in Form 5 |
| Wie lief es je Raum? | `ActionWorld.damageByRoom` → `DailyRun.marksOf` |
| Was steht im geteilten Text? | `TagesgrubeText.teilen` |
| Ab wann ist sie zu sehen? | `ErsterStart.zeigtTagesgrube` — nach dem ersten Lauf |

**Ein Tag hat einen Eintrag, also gibt es keinen Platz für einen zweiten
Versuch.** Die Karte im Eingang trägt ihn ein, *bevor* sie die Seite des
Laufs öffnet — sonst reichte Neuladen. Verfassung und Tag gelten vom
Hinabsteigen: Wer danach abhakt, war nicht in Form, und wer um 23:59
hinabsteigt, hat gestern gekämpft.

**Wer einen Satz, den Einheitshelden oder `dailyFormBonus` ändert, lässt
`dart run tool/tagesgrube_sim.dart` laufen** und stellt die Stufe nach:
Gesucht ist die, auf der der Bot ohne Form etwa jeden zweiten Lauf
gewinnt und in Form fast jeden. Die Grube hat eine scharfe Kante — zwei
Stufen trennen „fast immer“ von „fast nie“.

**Wer den Bau der Grube ändert, ändert die Tagesgrube mit.**
`daily_pit_test.dart` hält die Karte eines Tages als Zahl fest; fällt
der Test um, gehört die neue Zahl hinein, und er läuft danach auch im
Browser (`dart test -p chrome test/daily_pit_test.dart`) — nur so gilt
„dieselbe Grube für alle“ auf jedem Gerät.

**Seit [ADR-0041](docs/decisions/0041-beute-je-gegner.md) fällt der
Betrag je Gegner** — derselbe Topf, anders ausgeschüttet. Die Reihe
reicht der Welt den **Rest** des Topfs (`LadderProgress.potFor`), die
Welt zahlt je Kill ihren Teil (`LootDropped`, 70 % aufs Fussvolk, der
Wächter füllt auf), und `LadderProgress.bookRun` bucht am Ende — gekappt
auf den Topf. **Seit [ADR-0084](docs/decisions/0084-die-niederlage-nimmt.md)
zahlt nur ein Sieg**, dann den ganzen Topf: Eine Niederlage nimmt im Bild
zurück, was gefallen ist (`BeuteRegen.verliere`), und bucht nichts.
Was alte Stände in verlorenen Läufen gesammelt haben (`partial`), zählt
weiter und wächst nie mehr. **Mehr als der Topf zählt nie**: Wer daran
rührt, lässt `loot_test.dart` laufen.

**Der Kern-Loop verbindet alle acht Packages.** Lektion (`theory`) schaltet
Vorlage frei (`habits`), Häkchen erzeugt Erfahrung (`progression`),
Charakterwerte und Gold, Gold kauft Ausrüstung (`gear`), die Waffe bringt
den Grundangriff mit, der Baum die Fähigkeiten (`abilities`), Werte plus Ausrüstung plus Fähigkeiten
gehen in die Grube (`action_combat`), und alles zusammen verdient
Errungenschaften (`achievements`), die Titel (`identity`) und sieben
Fähigkeiten vergeben — darunter Funkenstoß, die erste für jeden.

Es gibt genau **achtzehn** Stellen, an denen etwas zusammenläuft:

| Provider | führt zusammen |
|---|---|
| `totalXpProvider` | Erfahrung aus Theorie, Gewohnheiten, Reihe, Errungenschaften **und Rückfragen** (ADR-0045) |
| `goldProvider` | Gold aus allen Quellen |
| `equippedStatsProvider` | Kampfwerte aus Gewohnheiten und Ausrüstung |
| `achievementStatsProvider` | **die breiteste** — alle vier Bereiche für die Errungenschaften |
| `earnedTitleIdsProvider` | welche Titel verdient sind (ADR-0033) |
| `abilityProgressProvider` | Waffe, Streak, Theorie **und Errungenschaft** für die Freischaltung |
| `activeMovesProvider` | die Ids, mit denen in die Grube gegangen wird — Waffenzug zuerst |
| `activeUltimateProvider` | die Ultimate dazu — Level, Freischaltung und Wahl (ADR-0073) |
| `availableTheoryPointsProvider` | Level und Baum — freie Theoriepunkte |
| `passedPagesProvider` | bestandene Seiten — **der Graph ist die ganze Wahrheit** (ADR-0070) |
| `ersterStartProvider` | welche Bereiche die Startseite zeigt (ADR-0068) |
| `amFeuerProvider` | was am Lagerfeuer wartet — Rückfrage, Truhe, Aufgaben — und ob es brennt (ADR-0076) |
| `activeSetsProvider` | welche Ausrüstungs-Sets wirken (ADR-0030) |
| `ladderProvider` | wie weit die Grube gegangen ist (ADR-0032, ADR-0039) |
| `heroPowerProvider` | Werte, Level, Seltenheit **und Tagesform** zur Stärke in der Grube (ADR-0042, ADR-0043) |
| `fameProvider` | Ruhm aus Errungenschaften **und der Tagesgrube** (ADR-0072) |
| `sammelEintraegeProvider` | **die Sammlung** — je Besessenes, Gelerntes, Bestiarium, Titel und Seiten (ADR-0080) |
| `skillsProvider` | **die Skills je Gebiet** — Häkchen, Seiten und Rückfragen (ADR-0085) |

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
ADR-0019 zu wenig zählt** — die meisten Seiten liegen nur im Graphen.
Seit ADR-0070 liegt **jede** Seite im Graphen, auch die fünf des
früheren Handbuchs; sie stehen zusätzlich noch im flachen Zweig. Wer
bestandene Seiten braucht, nimmt diesen Provider und zählt weder
`theoryTree` noch einen Zweig dazu, sonst zählt er doppelt.

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

**Die App geht ohne Lesen** ([ADR-0060](docs/decisions/0060-die-app-geht-ohne-lesen.md)).
Auf den Bildschirmen stehen Namen und Zahlen mit ihrem Zeichen, keine
Sätze, Überschriften oder Beschriftungen; die Theorie ist ausgenommen.
Was erklärt werden muss, kommt **beim Antippen** — im Blatt, im Dialog
oder als `Tooltip` mit `triggerMode: TooltipTriggerMode.tap`. Der Satz
bleibt für den Vorleser (`semanticLabel`, `semanticsLabel`,
`Semantics`), und Knöpfe ohne Wort tragen einen `Key`, damit Tests sie
finden. **Wer einen neuen Satz auf einen Bildschirm schreibt, fragt
zuerst, ob ein Zeichen reicht.**

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

Diese sieben Orte sind das geteilte Gedächtnis. Sie zu pflegen ist Teil der Arbeit,
nicht Nacharbeit:

| Datei | Enthält | Wann aktualisieren |
|---|---|---|
| `konzept.md` | Produktvision, Systeme, MVP-Schnitt | wenn sich das Produkt ändert |
| `docs/context/state.md` | Was fertig ist, woran gerade gearbeitet wird, was als Nächstes kommt | am Ende jeder Arbeitssitzung |
| `docs/context/verlauf.md` | Die Einträge aus `state.md`, die älter als etwa eine Woche sind — wortgleich, **nicht** in jede Sitzung geladen | wenn `state.md` wächst: alte Einträge dorthin verschieben |
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
