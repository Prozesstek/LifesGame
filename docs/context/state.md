# Projektstand

> Diese Datei ist die Antwort auf „Wo stehen wir gerade?".
> Am Ende jeder Arbeitssitzung aktualisieren. Alte Einträge unter „Verlauf"
> zusammenfassen, nicht löschen.
>
> Wohin es geht, steht in [`ziele.md`](ziele.md) — mit Terminen und mit der
> Liste dessen, was bis zum MVP ausdrücklich **nicht** angefasst wird.

**Zuletzt aktualisiert:** 26.08.2026, abends · AktivesBrett

---

## Phase

**Der MVP-Schnitt steht bis auf den Dungeon.** Lektion lesen → Vorlage
freischalten → täglich abhaken → Werte steigen → Gold sammeln → Ausrüstung
kaufen → nächsten Gegner schlagen. Alles davon überlebt jetzt einen
Neustart.

Seit dem 22.08. gibt es **eine** Sperre wieder, und sie ist gewollt:
Der **Kampf** wartet, bis das Handbuch durch ist
([ADR-0018](../decisions/0018-kampf-hinter-dem-handbuch.md)). Mit nur
einem Fähigkeitsslot wäre der erste Gegner unschlagbar.

```bash
flutter run -d chrome
```

## Fertig

- Produktkonzept (`konzept.md`)
- Tech-Stack ([ADR-0001](../decisions/0001-tech-stack.md))
- Architekturregel Kampflogik/Flame ([ADR-0002](../decisions/0002-kampflogik-ohne-flame.md))
- Kampflogik als eigenes Package ([ADR-0003](../decisions/0003-combat-als-eigenes-package.md))
- **`packages/combat`** — reine Dart-Kampflogik, 27 Tests grün:
  - 4 Move-Slots gemäß Konzept (erzeugen / verbrauchen / schwächen / stützen)
  - Timed Hits mit Deckel, Energie, Gift, Verteidigungssenkung, Heilung, Schild
  - **Drei Gegner** in `enemy.dart`, aufsteigend
    ([ADR-0009](../decisions/0009-kampfbalance-ueber-gegnerreihe.md))
  - Vollständiges Event-Vokabular als Naht zu Flame
  - Deterministisch per Seed → Balance-Simulation möglich
  - `termination_test.dart` sichert ab, dass Kämpfe **enden** — über
    Wertebereiche, die kein Beispielkampf abdeckt
- **`packages/theory`** — Skillbaum, Inhalte, Lernfortschritt, 50 Tests grün
  ([ADR-0004](../decisions/0004-theorie-als-eigenes-package.md)):
  - **17 Lektionen in 5 Zweigen**, jede mit 3 Abschnitten und 3 Fragen
    ([ADR-0007](../decisions/0007-theorie-als-skillbaum.md))
  - Zweige öffnet das **Charakterlevel**, Lektionen die Reihenfolge im Zweig
  - Bestehensgrenze 60 %; XP und Gold nur einmal je Lektion
  - Elf Lektionen schalten je eine Habit-Vorlage frei
  - `content_test.dart` prüft **Inhalt**, nicht Code
- **`packages/progression`** — Levelkurve, 11 Tests grün
  ([ADR-0006](../decisions/0006-levelkurve-als-eigenes-package.md))
- **`packages/habits`** — Gewohnheiten, Streaks, Charakterwerte, 63 Tests grün
  ([ADR-0008](../decisions/0008-gewohnheiten-als-eigenes-package.md)):
  - **11 Vorlagen**, jede mit Charakterwert, Zweig und Begründung
  - Vier Werte: Stärke → Angriff, Ausdauer → HP, Disziplin → Verteidigung,
    Klarheit → Energie
  - Streak-Multiplikator, Meilensteine bei 3/7/14/30/60 Tagen, Deckel x2
  - Höchstens **fünf** Gewohnheiten gleichzeitig
  - Erfahrung und Gold werden **abgeleitet**, nicht gezählt
- **`packages/gear`** — Ausrüstung, Preise, Inventar, 27 Tests grün
  ([ADR-0011](../decisions/0011-ausruestung-als-eigenes-package.md)):
  - **Sechs Plätze, neun Stücke in zwei Stufen.** Energie sitzt auf Ring und
    Talisman — das Konzept verlangt Ausrüstung, die Entscheidungen ändert
    und nicht nur Zahlen
  - **Gold wird abgeleitet:** Zufluss minus Preis des Besitzes. Kein
    gespeicherter Kontostand, deshalb auch kein Verkauf
  - `catalog_test.dart` prüft den Inhalt des Ladens wie `content_test.dart`
    die Lektionen
- **`packages/identity`** — Name und verdiente Titel, 28 Tests grün
  ([ADR-0014](../decisions/0014-titelkatalog-aus-drei-quellen.md)):
  - **Sieben Titel aus drei Quellen**: Streak-Tage, bestandene Lektionen,
    gesetzte Häkchen. Drei Spieler auf demselben Level können drei
    verschiedene Titel tragen — das ist der Zweck
  - Der Name wird **eingegeben**, der Titel nur **ausgewählt** aus dem,
    was verdient ist (ADR-0013)
  - Bedingung hängt an `longestStreak`, nicht an der laufenden Kette:
    ein verdienter Titel überlebt einen verpassten Tag
  - Der gespeicherte Titel ist eine Wahl, kein Nachweis — geprüft wird bei
    jeder Anzeige neu
  - `title_catalog_test.dart` prüft den Inhalt wie `catalog_test.dart` den
    Laden
- **Persistenz** ([ADR-0010](../decisions/0010-persistenz-hinter-einem-anschluss.md)):
  - `SaveStore` als Anschluss, `shared_preferences` als erste
    Implementierung, Drift passt später dahinter
  - Serialisierung liegt **in den Packages**, ist damit ohne Flutter testbar
  - Gelesen wird einmal vor `runApp`, geschrieben an genau einer Stelle
    (`SaveWatcher`)
  - Alle `fromJson` sind nachsichtig: Ein Formatfehler kostet nie den
    ganzen Stand
- **Flutter-App** (`lib/`) — 199 Tests grün, Web-Build läuft:
  - **Startbildschirm** mit allen fünf Bereichen. Der **Kampf** wartet,
    bis das Handbuch durch ist ([ADR-0018](../decisions/0018-kampf-hinter-dem-handbuch.md))
  - **Skillbaum**, **Theorie**, **Gewohnheiten** wie bisher
  - **Gegnerwahl** vor dem Kampf, mit Einschätzung („wird knapp")
  - **Kampf**: Flame-Darstellung, Statusleisten, Move-Buttons, Log, Timing
  - **Laden**: sechs Plätze, Preis, Wirkung, Begründung — und bei zu wenig
    Gold, wie viele Tage noch fehlen
  - **Charakter**: Name, verdienter Titel und Levelbalken im Kopf,
    **Beständigkeit** (laufende Kette, Bestwert, Häkchen), jeder Wert mit
    Herkunft („18 Angriff, davon 3 aus Ausrüstung"), **vier
    Fähigkeitsslots** — Slot 1 trägt die Waffenfähigkeit,
    die freien lassen sich belegen, Ausrüstung als 6er-Raster
  - `test/progression_test.dart` prüft, was kein Package allein kann: dass
    Belohnungs-, Habit-, Level- **und Preiskurve** zusammenpassen
  - `test/persistence_test.dart` prüft, dass ein Neustart nichts verliert

## Sitzung 26.08.2026: Das Fähigkeiten-Set

Fünfzehn Fähigkeiten aus einer Vorlage, in drei Schritten gebaut
([ADR-0022](../decisions/0022-faehigkeiten-set-aus-der-vorlage.md)).
Ziel 5 ist damit erfüllt. 209 App-Tests, combat 49, abilities 31.

### Was gebaut ist

- **Engine-Mechaniken**: `TimingSpec`, `Environment` mit vier Umgebungen,
  sieben neue Statuseffekte, dreizehn neue Wirkungen, `perfectEffects`,
  `perfectFactor`/`missFactor` je Move, Mehrfachtreffer
- **Der Katalog**: fünfzehn Fähigkeiten in `ability_moves.dart`, elf am
  Baum, vier an Streak-Marken. Sternenfall nur über sechzig Tage Kette
- **Die Timing-Leiste** liest ihre Werte aus der Fähigkeit; Klingenwirbel
  fragt dreimal
- **Die Gegner** benutzen sie mit: Wegelagerer Commons, Söldner bis
  Uncommon, Bergwächter bis Rare

### Drei Entscheidungen, die begründet gehören

**Feste Zahlen wurden in Multiplikatoren umgerechnet** (`power = Wert /
16`). Feste Zahlen hätten die Kopplung an die Gewohnheiten gekappt — genau
die Aussage, auf der das Produkt steht.

**Jede Fähigkeit hat einen eigenen Perfect-Faktor**, Basis- und
Waffenmoves nicht. ADR-0009 maß einen *pauschalen* Faktor auf jeden
Treffer; dieser hier kostet Energie und hängt an einem engen Fenster. Ein
Test hält fest, dass der Move, den man jede Runde drückt, bei +20 % bleibt.

**Timing ist eine Kampfregel**, keine Darstellung. `timing_rules.dart`
verrechnet Fähigkeit, Statuseffekte und Umgebung multiplikativ.

### Der Befund, der als Nächstes dran ist

**Der Bergwächter ist unschlagbar geworden.** Die Simulation:

| Gegner | Tag 0 | Tag 7 | Tag 14 | Tag 21 | Tag 30 | Tag 60 |
|---|---|---|---|---|---|---|
| Wegelagerer | 0 % | 94 % | 100 % | 100 % | 100 % | 100 % |
| Söldner | 0 % | 0 % | 0 % | 38 % | 100 % | 100 % |
| **Bergwächter** | 0 % | 0 % | 0 % | 0 % | **0 %** | **0 %** |

In ADR-0009 stand er bei 36 % an Tag 30 und 100 % an Tag 60.

> **Nachtrag 26.08., abends: die hier genannte Ursache war falsch.** Der
> Bergwächter trug Donnerkeil nicht — `EnemyBlueprint.loadout` wurde
> nirgends gelesen, er kämpfte mit dem Standard-Moveset und damit mit
> Kraftschlag (`power` 2,2). Die zweite Hälfte der Erklärung stimmt und
> war die eigentliche Ursache. Der Absatz bleibt stehen, weil die falsche
> Diagnose lehrreich ist; Details in `gotchas.md` und
> [ADR-0023](../decisions/0023-der-gegner-spielt-nach-denselben-regeln.md).

Die Ursache ist benannt: Er trägt jetzt Donnerkeil (`power` 2,125), während
die frühen Spielerfähigkeiten **schwächer sind als der Basisangriff** —
Funkenstoß hat 0,75 gegen 1,0 beim Bogenschuss und kostet zusätzlich
Energie. Das ist die Vorlage, ehrlich umgerechnet: Ihre Commons sind
Werkzeuge mit Perfect-Effekten, keine Schadensquellen.

**Balancing war ausdrücklich zurückgestellt.** Drei Hebel stehen bereit:
die Gegner-Sets, die `power`-Werte der Commons, oder der Nenner 16.

### Die Simulation hat vorher nichts gemessen

`_loadoutNach` fragte mit `AbilityProgress.empty()` — seit ADR-0019
schaltet ein leerer Fortschritt nichts frei, der simulierte Spieler kämpfte
an jedem Tag mit **einem** Move. Sie nimmt jetzt an, dass die Kette nie
reißt und jeder Theoriepunkt in einen Knoten mit Fähigkeit geht; beides
steht im Code und macht das Ergebnis zur oberen Schranke.

### Die Vorlage liegt jetzt im Repo

[`docs/vorlagen/faehigkeiten.md`](../vorlagen/faehigkeiten.md) — bis dahin
lag sie nur in einem Downloads-Ordner und existierte für den anderen
damit nicht, dasselbe Muster wie bei `Kampfsystem.docx`. Sie enthält die
fünfzehn Fähigkeiten samt Icon- und Animationsideen, die Timing-Referenz
und die Umgebungsregeln — dazu einen nachgeprüften Soll-Ist-Teil: welche
Zahlen ankommen (alle), welche drei Umrechnungen dazwischenliegen, und
fünf Stellen, an denen die Vorlage noch auf Antwort wartet.

`docs/vorlagen/` ist ab jetzt der Platz für solche Dokumente und steht im
Gedächtnis-Protokoll in `CLAUDE.md`.

### Der Gegner spielt jetzt nach denselben Regeln

Gemeldet war eine fehlende Timing-Leiste bei Frostnebel, Sandsturm und
Giftmoor. Die Ursache war klein; beim Nachprüfen kamen **vier weitere**
Befunde mit derselben Wurzel dazu
([ADR-0023](../decisions/0023-der-gegner-spielt-nach-denselben-regeln.md)).
Sechs Commits, 222 App-Tests (vorher 213), combat 78 (vorher 49).

| Befund | Wirkung, bevor er behoben war |
|---|---|
| Leiste nur bei `power > 0` | acht Fähigkeiten ohne Zeitfenster, vier Perfect-Wirkungen unerreichbar |
| Gegner bekam immer `TimedHit.none` | Wurzelgriff, Sandsturm und Donnerkeils Perfect-Wirkung gegen ihn **wirkungslos** |
| Gegner erhielt nur einen Tipp | sein Klingenwirbel traf einmal statt dreimal |
| Policy übersprang alles ohne Schaden | drei von sechs Zügen des Bergwächters tot |
| **`EnemyBlueprint.loadout` wurde nirgends gelesen** | *jeder* Gegner kämpfte mit dem Standard-Moveset |

**Der letzte wiegt am schwersten.** ADR-0022 Punkt 8 stand geschrieben und
galt im Code nicht — keine der fünfzehn Fähigkeiten wurde je von einem
Gegner gespielt. Der Fallstrick dazu steht in `gotchas.md`.

**Damit war die hier dokumentierte Ursache des Bergwächter-Befunds
falsch.** Weiter unten stand: „Er trägt jetzt Donnerkeil." Er trug ihn
nie. Die Erklärung klang plausibel, passte zu den Zahlen und war falsch.

### Was jetzt gilt

- **Ob getippt wird, entscheidet der Move** (`Move.hasTimingWindow`):
  Ändert Perfect etwas? Abgeleitet, nicht als Flag gesetzt.
- **Der Gegner würfelt eine Stelle auf der Leiste**, gewertet mit
  denselben Fenstern (`TimingSpec.judgeAt`). Ohne eine einzige neue Zahl.
- **Er greift manchmal zu Utility**: Wegelagerer 10 %, Söldner 20 %,
  Bergwächter 30 %. Mit vier Sperren gegen sichtbar verschwendete Runden.
- **Perfekt gelegt hält eine Umgebung eine Runde länger** — auch bei
  Vulkanbruch. Dafür kennt eine Umgebung jetzt ihre `totalTurns`; sonst
  liefe Giftmoors Steigerung rückwärts los.
- **Die liegende Umgebung steht im HUD**, mit Restrunden und Farbe für den
  Besitzer.
- **`Sammeln` und `Atemzug` bekommen keine Leiste** — sie haben keine
  Perfect-Wirkung, und ein Tipp ohne Auszahlung ist Reibung.

### Die neue Balance-Tabelle

| Gegner | Tag 0 | Tag 7 | Tag 14 | Tag 21 | Tag 30 | Tag 60 |
|---|---|---|---|---|---|---|
| Wegelagerer | 0 → **74 %** | 94 → **100 %** | 100 % | 100 % | 100 % | 100 % |
| Söldner | 0 % | 0 % | 0 % | 38 → **11 %** | 100 → **90 %** | 100 → **99 %** |
| Bergwächter | 0 % | 0 % | 0 % | 0 → **5 %** | 0 → **22 %** | 0 → **40 %** |

**Der Bergwächter ist nicht länger unschlagbar**, obwohl er jetzt
Donnerkeil trägt: Er steckt 30 % seiner Züge in Utility, und Donnerkeil
kostet 5 Energie — Kraftschlag konnte er öfter spielen.

**Die Spannweite zwischen perfektem und keinem Timing ist zurück:** 35
Punkte beim Wegelagerer an Tag 0, 46 beim Söldner an Tag 30, 33 beim
Bergwächter an Tag 60. Vorher stand dort fast überall 0 — das ist die
Aussage aus ADR-0009, wieder messbar.

### Nachgemeldet: ein Platz war belegt und kam nicht im Kampf an

Gemeldet mit Screenshot — vier Fähigkeiten angelegt, drei Knöpfe im
Kampf. Es fehlte *Kraftschlag*.

**Ursache: ADR-0022 hat ihn aus dem Katalog geworfen.** Die vier aus
ADR-0017 (Kraftschlag, Zehrung, Sammeln, Atemzug) sind nicht mehr
wählbar; in `package:combat` gibt es sie weiter. Ein Spielstand, der einen
davon hielt, zeigte ihn auf seinem Platz — `ability_slots_row.dart` fragt
`Moves.byId`, nicht den Katalog — und der Kampf ließ ihn weg. Der Platz
war dauerhaft blockiert, ohne Meldung.

Behoben über
[ADR-0024](../decisions/0024-abgeloeste-faehigkeiten-fallen-beim-laden-heraus.md):
`ChosenAbilities.fromJson` streicht Ids, die der Katalog nicht kennt. Der
Fall repariert sich beim nächsten Start von selbst.

**Die Tests haben es nicht gefunden, weil sie selbst veraltet waren:**
`chosen_abilities_test.dart` benutzte `mend` und `breath` als
Beispiel-Ids und bewies damit, dass abgelöste Ids das Laden überstehen.
Sie nehmen ihre Beispiele jetzt aus dem Katalog.

### Schadenszahlen über den Kämpfern

Treffer stehen rot über dem Kopf, Heilung grün mit Plus, ein ganz
geschluckter Schlag als „Geblockt". Schaden über Zeit trägt die Farbe
seiner Quelle: Gift lila, Giftboden dunkleres Lila, Brand orange, Eisfeld
hellblau, Sandsturm sandgelb, Lavafeld rot mit Funken um die Zahl.

**Zwei Entscheidungen, die nicht offensichtlich sind:**

Bei einem **teilweise** geblockten Schlag steht nur die Zahl da, die
durchkommt — „Geblockt" heißt dann auch wirklich geblockt. Ob der Block
vollständig war, sagt seit heute das Event (`DamageAbsorbed.complete`).
Die Darstellung soll das nicht aus der Eventliste erraten müssen; sie
müsste dafür vorausschauen und `ShieldBroke` überspringen.

**Was angezeigt wird, entscheidet eine reine Funktion**
(`damageReadoutFor` in `floating_text.dart`), nicht die Ereignisschleife
in Flame. Dieselbe Trennung wie bei `MoveAnimation`. Der Grund ist
praktisch: Im Flame-Code erreicht kein Test die Entscheidung, ohne ein
Spiel zu starten — als Funktion sind es zehn Zeilen Test.

**Nicht am Bild geprüft.** Der Browser ließ sich in der Sitzung nicht
anzeigen, ein Screenshot war nicht möglich. Was *angezeigt wird*, ist
getestet; wie es auf einem Handy **aussieht** — Größe, Versatz bei
Klingenwirbels vier Treffern, Lesbarkeit der Funken — muss jemand
ansehen.

### Langes Drücken erklärt einen Zug

Jeder Move-Knopf im Kampf trägt einen Tooltip: was der Zug tut, und was
ein perfekter Treffer daran ändert. Ausgelöst durch langes Drücken —
auf einem Handy gibt es kein Mausschweben, und ein „i" auf dem Knopf
nähme den Platz, den Name und Energiekosten schon brauchen. Der leere
Log nennt den Weg („Lange drücken erklärt ihn"), sonst fände ihn
niemand.

**Die Formulierungen kommen aus der Vorlage, die Zahlen nicht.**
`move_help.dart` setzt ein, was der Zug bei *diesem* Angriffswert
anrichtet: Donnerkeil sagt bei Angriff 13 etwas anderes als bei 20. Bei
genau 16 trifft er die Zahlen der Vorlage — ein Test hält das fest, und
damit auch die Umrechnung aus ADR-0022.

**Alle Zahlen sind flach**, also ohne Verteidigung, Streuung und Timing.
Deshalb steht überall „etwa". Gerechnet wird in `package:combat`
(`Move.flatDamage`, `flatFromFactor`), nicht im Bildschirm.

**Was abgelesen werden kann, wird abgelesen.** Steinhauts „−40 %" kommt
aus `ReduceIncoming(factor: 0.6)`, die Umgebungssätze bauen sich
vollständig aus `environment.dart`. Wer eine Zahl im Katalog ändert, muss
den Hilfetext nicht nachziehen — nur die Prosa drumherum ist
geschrieben.

### Das Bild ist der Knopf

Frostnebel, Sandsturm, Giftmoor und Vulkanbruch haben ein Pixel-Bild von
AktivesBrett (1024×1024 JPG, aus `Desktop\Lifes Game Mockup\`). Im Kampf
ist dieses Bild die **Kachel, die man drückt** — quadratisch, Name
darüber, Energiekosten unten rechts in der Ecke. **Alle Züge stehen in
einer Reihe**, höchstens 88 Pixel je Kachel.

**Die Kantenlänge kommt aus der verfügbaren Breite, nicht aus einer festen
Zahl.** Nur so ist die Kachel wirklich quadratisch und das Bild
vollständig zu sehen: Eine Zwischenfassung war 175 breit und 128 hoch und
schnitt die quadratische Vorlage oben und unten an.

**Die Obergrenze ist zugleich die Stellschraube für die Arena.** Die
Kachel ist quadratisch, ihre Breite ist also auch ihre Höhe — und was sie
nicht braucht, bleibt den beiden Kämpfern. Bei 88 passen alle vier Züge
nebeneinander; die zweite Reihe entfällt, und das sind rund 190 Pixel,
die das Kampffeld zurückbekommt. Wer die Kacheln größer will, nimmt sie
der Arena weg — beides steht in `move_icon.dart`.

Der erste Anlauf war ein kleines 28-Pixel-Icon *im* Textknopf. Ein
Entwurf von AktivesBrett hat gezeigt, dass etwas anderes gemeint war.

**Was dabei zu klären war, und wie:**

| Frage | Antwort |
|---|---|
| Die sechzehn Züge ohne Bild? | Gleich große Kachel mit dem **Namen darin** |
| Woher der Platz? | Der **Log ist entfallen** |
| Energiekosten? | Klein auf dem Bild, unten rechts |

**Der Waffenzug war der Grund für die erste Frage.** Er hat kein Bild und
ist der Zug, den man *jede Runde* drückt, um Energie aufzubauen. Eine
Kachelleiste, in der er ein leeres Feld wäre, hätte den Kampf
unbedienbar gemacht.

**Die Bilder liegen in dreifacher Kachelgröße** (384 × 384) in
`assets/abilities/`, freigestellt aus der Vorlage — die hat rund 40 %
dunklen Rand um den Rahmen. Dreifach, weil ein Handy mit dreifacher
Pixeldichte 128 logische Punkte auf 384 echte rechnet; bei den zuerst
abgelegten 128 × 128 wäre das Hochrechnen gewesen.

**Der Dateiname ist die Move-Id.** Ein neues Bild ist damit eine Datei
plus eine Zeile in `move_icon.dart`. `test/move_icon_test.dart` prüft
beide Nähte: dass die Id in `package:combat` ankommt, und dass die Datei
da **und in `pubspec.yaml` angemeldet** ist — Letzteres über
`rootBundle.load`, das nur findet, was angemeldet ist.

### Der Kampf endet mit einem Blatt — und ohne Belohnung

Am Ende steht jetzt ein Dialog: gewonnen oder verloren, gegen wen, nach
wie vielen Runden, und ein OK-Knopf.

**Die Frage dahinter war „gibt es eine Belohnung?" — und die Antwort ist
nein, mit Absicht.** Erfahrung und Gold kommen ausschließlich aus
Gewohnheiten und Theorie (`totalXpProvider`); der Kampf gibt nichts.
Das ist der Kern-Loop aus `konzept.md` Abschnitt 2: Der Kampf ist die
Stelle, an der sich Fortschritt **auszahlt**, nicht die, an der er
entsteht. Gäbe es XP fürs Gewinnen, könnte man Kämpfe grinden statt
Häkchen zu setzen — und die Aussage des Produkts wäre widerlegt. Beute
gehört laut Abschnitt 4 in den Dungeon (Ziel 6).

Das Blatt sagt das auch: „Erfahrung und Gold gibt es dafür nicht — sie
kommen aus deinen Gewohnheiten." Damit bleibt die Frage nicht offen.

**Ein Test hält es fest.** `result_dialog_test.dart` prüft, dass im Blatt
kein „+N" steht. Stünde dort eines Tages eine Belohnung, wäre das eine
Richtungsentscheidung und kein Textdetail — der Test zwingt sie ans
Licht.

### Was mit dem Log verloren ging

Zwei Dinge, beide bewusst in Kauf genommen:

**Es steht nirgends mehr, *was* passiert ist.** „Geblockt", „Gift wirkt",
„Eisfeld klingt aus" — die Zahlen über den Köpfen zeigen nur den Schaden,
nicht die Ursache. `EnvironmentSet`, `StatusApplied` und `MoveFailed`
haben jetzt gar keine Textform mehr im Bild.

**Der Hinweis auf den Tooltip ist weg.** Er stand im leeren Log („Lange
drücken erklärt ihn") und war die einzige Stelle, an der langes Drücken
überhaupt erwähnt wurde. Der Tooltip funktioniert weiter — man muss nur
wissen, dass es ihn gibt.

Der Log wird weiter geführt (`CombatSession.log`, `appendLog`), nur nicht
mehr gezeigt. Eine schmale Zeile mit dem jüngsten Ereignis wäre der
naheliegende Kompromiss: rund 20 Pixel statt 200, und sie könnte beides
tragen.

**Nicht am Bild geprüft**, wie das Übrige aus dieser Sitzung.

### Die App soll aufs Handy — Android wird eingerichtet

Entschieden am 26.08. von AktivesBrett: „Im Browser ist ja nur zum
Testen, aber es soll auf dem Handy laufen." Damit fällt **Android** von
der Sperrliste in `ziele.md`. Die Begründung trägt: Ziel 7 verlangt
30 Tage tägliches Spielen, und ein Browser-Tab wird seltener angetippt
als ein Symbol auf dem Startbildschirm.

**Der `android/`-Teil des Projekts ist vollständig** und war es schon:
`applicationId` `dev.prozesstek.lifes_game`, Gradle-Kotlin-DSL, und der
Release-Build signiert mit dem Debug-Schlüssel — ein APK zum Selbst-
Installieren braucht also **keinen** Keystore.

Zwei Kleinigkeiten sind nachgezogen: Die App heißt auf dem Startbildschirm
jetzt **„Lifes Game"** statt `lifes_game`, und das Hochformat steht auch
im Manifest. `main.dart` sperrt es zwar schon, aber erst wenn Flutter
läuft — ohne die Manifest-Zeile dreht sich der Startbildschirm kurz mit.

**Was auf diesem Rechner fehlt** (Stand `flutter doctor`):

| | Zustand |
|---|---|
| Android SDK | **fehlt ganz** („Unable to locate Android SDK") |
| Android Studio | nicht installiert |
| JDK 17 | fehlt — im PATH steht Java 1.8, zu alt für `sourceCompatibility 17` |
| `JAVA_HOME`, `ANDROID_HOME` | nicht gesetzt |

`CLAUDE.md` beschrieb bisher frekks Rechner („Android Studio da, aber
cmdline-tools fehlen"). Hier ist es weniger.

**Drei Schritte kann nur ein Mensch machen:** Android Studio installieren
(winget verlangt eine interaktive Zustimmung zu den Quellbedingungen),
die SDK-Lizenzen akzeptieren, und auf dem Handy die Installation aus
unbekannten Quellen erlauben. Danach ist `flutter build apk --release`
ein einzelner Befehl.

### Offen

**Der andere Fall ist weiter unsichtbar.** Eine Fähigkeit, die es im
Katalog gibt, deren Bedingung gerade aber nicht erfüllt ist, liegt
sichtbar auf ihrem Platz und fällt im Kampf heraus. Erreichbar über den
Entwicklermodus: schenken, anlegen, Zuschläge zurücksetzen. Das ist
Absicht aus ADR-0014 — ob der Charakterbildschirm es kenntlich machen
sollte, ist offen.

**Der Bergwächter erreicht auch an Tag 60 nur 40 %.** ADR-0009 wollte dort
100 %. Er ist jetzt der Gegner, der nie verlässlich fällt — vorher war er
der, der nie fiel. Besser, aber nicht fertig. Balancing bleibt
zurückgestellt; gemessen und gemeldet ist es.

**Alle Zahlen aus ADR-0009 und ADR-0022 sind neu zu messen.** Sie stammen
aus Kämpfen, in denen der Gegner nie zielte und immer dasselbe Moveset
hatte.

**Der simulierte Spieler benutzt weiter keine Utility.**
`tool/balance_sim.dart` steuert ihn mit derselben Policy, aber mit
`utilityChance` 0. Die Tabelle ist damit eine **untere** Schranke für den
Spieler und eine ehrliche für den Gegner.

**Die Umgebungen haben kein Bild.** Sie stehen jetzt im HUD, aber Lava,
Sandschleier und Nebel fehlen weiter. Dazu fällt `move_animation.dart` für
**alle** fünfzehn auf `melee` zurück — bei Steinhaut und Blütentau macht
die Figur dadurch einen Ausfallschritt auf den Gegner zu.

**Sternenfalls Marker springt nicht zurück.** Die Vorlage nennt das als
Teil seines Timings; `TimingSpec` kennt nur Geschwindigkeit und Fenster.

## Sitzung 25.08.2026: Entwicklermodus und ein stiller Kampf-Fehler

### Die Timing-Leiste wartet jetzt

Der Marker lief einmal durch und meldete dann „daneben" — der Zug war
entschieden, ohne dass der Spieler etwas getan hätte. Jetzt läuft er hin
und her, bis getippt wird (`repeat(reverse: true)`).

**Es gibt bewusst keine Frist.** Wer wartet, verliert nichts als Zeit. Ein
Zeitlimit hätte den Zug mit dem schlechtestmöglichen Ergebnis entschieden,
und das ist dieselbe Sorte Bestrafung fürs Zögern, die das Konzept bei den
Gewohnheiten ausschließt.

**Getippt wird überall.** Eine 34 Pixel hohe Leiste trifft man auf einem
Handy im Eifer nicht zuverlässig; die Tippfläche liegt deshalb über dem
ganzen Kampfbereich — aber **nicht** über der AppBar. Läge sie darüber,
wäre ein begonnener Zug eine Falle: Der Zurück-Pfeil sitzt dort, und man
käme aus dem Kampf nicht mehr heraus, ohne vorher zu tippen.

Vier Tests in `timing_bar_test.dart`, drei weitere in `combat_test.dart`. Einer davon prüft nicht nur, dass
nichts gemeldet wird, sondern auch, dass sich der Marker **noch bewegt**
(`hasScheduledFrame`) — sonst wäre er auch grün, wenn die Leiste stumm am
Rand stehen bliebe.

### Der Kampf war unbedienbar — behoben

`restart()` baute die Sitzung neu, ohne das Moveset zu setzen. Weil
`CombatSession.moves` einen leeren Standardwert hat, schwieg der Compiler —
und weil die **Gegnerwahl** `restart()` aufruft, hatte jeder über den
Startbildschirm begonnene Kampf **keinen einzigen Move-Knopf**. Der Weg
„Nochmal" nach einem Kampf ebenso.

Der Fehler kam mit dem Feld `moves` (Sitzung 22.08., „Fähigkeiten lassen
sich wählen"): `build()` bekam es, `restart()` wurde übersehen. Er lag
seither still da — gefunden hat ihn ein Screenshot, nicht die Testsuite.

Drei Tests halten es jetzt fest; zwei davon fallen ohne die Korrektur um.
Der Fallstrick dahinter steht in `gotchas.md`: Ein Standardwert im
Konstruktor macht ein vergessenes Feld unsichtbar.

Ein Werkzeug, das Erfahrung, Gold, Punkte, Fähigkeiten und Ausrüstung per
Knopfdruck vergibt ([ADR-0021](../decisions/0021-entwicklermodus-mit-eigenem-spielstand.md)).
189 Tests grün (vorher 177).

**Zwei bestehende Entscheidungen standen im Weg, beide zu Recht:**

1. **Es gibt keinen Ort für „+500 XP".** Erfahrung, Level, Gold und
   Theoriepunkte sind alle abgeleitet (ADR-0008, ADR-0011).
2. **Ziel 7 verbietet das Werkzeug** für den 30-Tage-Nachweis: „Kein
   Sonderrecht, keine Testdaten, keine Abkürzung über den Debugger."

**Die Lösung für beides:**

- **Zuschläge statt gefälschter Vergangenheit.** `DebugGrants` ist ein
  eigener, benannter Summand. Die Alternative — Lektionen als bestanden
  markieren, bis die Zahl stimmt — hätte den Stand lügen lassen und über
  erfundene Streaks auch Titel und Multiplikatoren verfälscht.
- **Ein eigener Spielstand** (`lifes_game.save.dev.v1`). Der echte Stand
  ist nicht bloß gemieden, sondern liegt hinter einem Schlüssel, den die
  App währenddessen gar nicht anfasst. Der Wechsel braucht einen Neustart.
- **Nur im Debug-Build.** Im Release ist weder Kachel noch Bildschirm im
  Bündel.
- **Die Herkunft bleibt sichtbar**: eine Karte „Aus dem Entwicklermodus"
  auf dem Charakterbildschirm, sobald etwas geschenkt wurde.

**Was der Modus kann:** Level (+1/+5), XP, Gold, Theorie- und
Fähigkeitspunkte — je mit festen Stufen und Freifeld. Einzelne oder alle
Items, einzelne oder alle Fähigkeiten. „Alles freischalten", „Zuschläge
zurücksetzen", „Dev-Stand komplett löschen".

**Drei Dinge, die beim Bauen auffielen:**

- **„+1 Level" gibt es nicht als gesetzten Wert.** Es schenkt genau die
  Erfahrung, die bis zur nächsten Stufe fehlt — der einzige Weg, der die
  Kurve nicht umgeht.
- **Ein geschenktes Item würde Gold *wegnehmen*.** `spentGold` steigt mit
  dem Besitz (ADR-0011); der Preis wird deshalb als Zuschlag mitgegeben.
- **Charakterwerte werden nicht geschenkt.** Sie hängen an Häkchen je Stat;
  sie zu schenken hieße, Streaks zu erfinden.

**Ein Importkreis hat Zeit gekostet:** `level_provider` rechnet die
Zuschläge ein, `gear_controller` braucht das verfügbare Gold — beide über
`lib/dev/` zu verbinden ließ die Typinferenz auf `num` zurückfallen, mit
vier Fehlern, die nach einem Tippfehler aussahen. Gelöst über
`spendableIncomeProvider`.

**Offen:** Fähigkeitspunkte werden gespeichert und angezeigt, wirken aber
nicht — das Feature aus ADR-0013 ist nicht gebaut.

## Sitzung 22.08.2026: der Charakter ist fertig, und der Kern-Loop
schließt sich

Vier Pull Requests, alle auf `main` (#9, #10, #13, #12). Drei Blöcke,
in dieser Reihenfolge gebaut — und ein Befund am Ende, der die
Richtung für morgen bestimmt.

### 1. Der Charakterbildschirm ist vollständig (#9)

Die drei kleinen Löcher aus ADR-0013 sind zu, plus die Slots aus
[ADR-0016](../decisions/0016-faehigkeitsslots-vor-den-faehigkeiten.md).

- **Die Streak steht endlich auf dem Charakterbildschirm.** Das war
  Loch 5 von fünf und das letzte offene. Drei Zahlen statt einer:
  laufende Kette, Bestwert, Häkchen gesamt.
- **`HabitTracker.currentBestStreak(today)`** ist neu — die
  längste **laufende** Kette über alle Gewohnheiten. Das Gegenstück
  zu `longestStreak`: Diese Zahl **darf** fallen, und das ist ihr
  Zweck. Gerechnet wird sie über `currentStreak`, damit die Regel
  „wann lebt eine Kette" nur an einer Stelle steht.
- **Der Satz unter den Zahlen trägt die Aussage.** Bei gerissener
  Kette steht dort „Der Bestwert bleibt — verpasste Tage nehmen nichts
  weg". Ohne ihn läse sich eine 0 wie ein Rückschritt, und das
  Konzept schließt Strafe fürs Verpassen aus (3.7, ADR-0008).
- **Levelbalken im Kopf**, wie in der ADR-0013-Skizze. Die Zahlen
  lagen fertig in `PlayerLevel` — es wurde nichts nachgerechnet.
- **Ausrüstung als 6er-Raster.** Das Ablegen ist ins Auswahlblatt
  gewandert; im Raster ist kein Platz für einen zweiten Knopf. Eine
  Kachel unterscheidet jetzt „leer" (gekauft, nicht angelegt) von
  „nichts gekauft".
- **`AbilitySlots` in `packages/progression`** — Slot 1 ab Level 1, die
  drei freien auf 3 / 6 / 10. Die Zahl liegt bei der Levelkurve, weil
  ein Slot das ist, was ein *Levelaufstieg gibt* (ADR-0012), nicht was
  eine Fähigkeit mitbringt.

**`test/phone_layout_test.dart` scrollt seither jeden Bildschirm
durch.** Vorher prüfte er nur, was über der Falz liegt: Was in einer
`ListView` darunter steht, wird nicht gebaut — und was nicht gebaut
wird, kann nicht überlaufen. Der Test hat damit den größeren Teil
jedes Bildschirms nie angesehen. Nachgeholt hat er nichts gefunden.

### 2. Fähigkeiten lassen sich wählen (#10, #13)

[ADR-0017](../decisions/0017-faehigkeitskatalog-aus-drei-quellen.md)
legt zwanzig Fähigkeiten aus drei Quellen fest. Gebaut sind die
**neun**, für die die Engine schon reicht — fünf Waffen plus
Kraftschlag, Zehrung, Sammeln, Atemzug. Der Weg **wählen → gespeichert
→ im Kampf spürbar** funktioniert.

- **`packages/abilities`** (siebtes Package) kennt weder `combat` noch
  `gear` noch `habits` — es hält Ids und Bedingungen. 26 Tests.
- **`test/abilities_seam_test.dart`** prüft die Naht, die kein Package
  allein prüfen kann: jede Move-Id kommt in `combat` an, jede
  Waffen-Id existiert im Laden, **jede Waffe im Laden bringt eine
  Fähigkeit mit**, und **jeder Waffenmove erzeugt Energie statt sie zu
  kosten**.
- **Slot 1 ist nie leer.** Ohne Waffe greift der Kurzbogen. Auf Level 1
  ist er der einzige offene Platz.
- **Das Moveset friert beim Kampfstart ein.** Wer mitten im Kampf die
  Waffe wechselt, würde sonst die Knöpfe unter dem eigenen Finger
  austauschen.
- **Der Waffenslot steht nicht im Spielstand** — er folgt aus der
  Ausrüstung.
- `packages/combat` bekam fünf neue Moves und `Moves.byId`, aber
  **keine neue Mechanik**.

### 3. Der Kampf wartet auf das Handbuch (#12)

Die Antwort auf den Befund unten
([ADR-0018](../decisions/0018-kampf-hinter-dem-handbuch.md)): Die
Kampf-Kachel ist gesperrt, bis jede Lektion des freien Zweigs
„Gewohnheiten" bestanden ist.

**Warum das die richtige Bedingung ist, und nicht irgendeine:** Das
Handbuch ist exakt so lang, dass es den zweiten Fähigkeitsslot öffnet.

| Lektionen | XP | Level |
|---|---|---|
| 4 | 220 | 2 |
| **5 (der ganze Zweig)** | **275** | **3** |

Level 3 braucht 225 XP. Vier Lektionen liegen fünf Punkte darunter.
Die Sperre fällt also genau in dem Moment, in dem der Spieler seinen
zweiten Move bekommt.

**Das ist gemessen, nicht entworfen.** Wer an `TheoryRewards`, an der
Levelkurve oder an der Länge des Zweigs dreht, kann den Zusammenhang
zerstören, ohne es zu merken. `test/progression_test.dart` hält ihn
deshalb fest — in beide Richtungen: dass fünf Lektionen reichen
**und** dass vier es nicht tun.

Die Kachel bleibt sichtbar und nennt den Weg („Erst das Handbuch:
noch 3 Lektionen in Gewohnheiten"), statt zu verschwinden.

### Der Befund, der die Sperre ausgelöst hat

`tool/balance_sim.dart` spielt jetzt das **gesperrte** Moveset statt
vier fester Moves. Mit Tag-0-Werten (ATK 13, HP 160, DEF 8, EN 8)
gegen den Wegelagerer:

| Moves | Siegquote |
|---|---|
| 1 (nur Waffe) | **0 %** |
| 2 | 100 % |
| 3 | 57 % |
| 4 | 57 % |

**Ein Move ist nicht knapp, sondern unmöglich.** Der Bogen allein
richtet rund 10,6 Schaden je Runde an, der Wegelagerer 15,3 — das
Rennen ist nicht zu gewinnen, egal wie lange es dauert. Ohne einen
Move, der Energie *ausgibt*, fehlt der Auszahlungsmoment.

**Zwei Zahlen aus derselben Tabelle, die stutzig machen sollten:**
Drei Moves sind *schlechter* als zwei. Das liegt an der Simulation,
nicht am Spiel: Sie steuert den Spieler mit `SimpleEnemyPolicy`, also
einem Bot, und der wählt mit mehr Möglichkeiten schlechter. Ein Mensch
entscheidet besser. **Die Werte für drei und vier Moves sind deshalb
pessimistisch** — die für einen Move nicht, dort gibt es nichts zu
entscheiden.

**Nebenbefund, gemessen:** Die Giftklingen-Teilung aus ADR-0017 hat
den Wegelagerer an Tag 0 von 61 % auf 45 % gedrückt (bei noch vier
festen Moves), den Bergwächter an Tag 30 von 34 % auf 39 % gehoben.
Beide Seiten haben die Schwächung verloren; früh trifft es den Spieler
härter, spät den Gegner. Sie kommt mit *Blöße finden* zurück, wenn die
elf übrigen Fähigkeiten gebaut sind.

## Der Kampf sieht jetzt aus wie ein Kampf — 21.08.2026

Zwei Rechtecke sind zwei gezeichnete Menschen geworden, und eine Runde
läuft ab statt gleichzeitig zu passieren
([ADR-0015](../decisions/0015-kampfdarstellung-ueber-eine-zeitachse.md)).

**Die Engine ist dabei unangetastet geblieben.** Kein Wert in
`packages/combat` wurde geändert, alle 27 Tests dort laufen unverändert. Das
war möglich, weil ADR-0002 die Naht schon vorgesehen hatte: Die Logik gibt
Events aus, die Darstellung verteilt sie über die Zeit.

- **Zeitachse in `battle_game.dart`**: erst spannen, dann fliegt der Pfeil,
  dann zuckt der Getroffene. Vorher war alles ein Frame
- **`move_animation.dart`** ordnet jeder Move-**Id** eine Animation zu — die
  Grenze zwischen „was ein Move tut" und „wie er aussieht"
- **Gezeichnete Figuren**, keine Assets. Rive ersetzt sie später, die
  Schnittstelle bleibt
- Der Basisangriff heißt **„Bogenschuss"** statt „Schlag". Nur der
  Anzeigetext, `power` und `energyDelta` unverändert
- Eingabe ist gesperrt, solange abgespielt wird

**Noch sichtbar falsch:** Die Lebensbalken springen sofort, während der
Pfeil noch fliegt. Die Zahlen stimmen, die Reihenfolge nicht.

## Das Zielgerät steht jetzt im Konzept — 21.08.2026

**Handy im Hochformat.** Das war bis heute nirgends im Repo festgehalten,
also gab es die Vorgabe für den jeweils anderen nicht. Steht jetzt in
`konzept.md` Abschnitt 5, mit der Begründung aus dem Kern-Loop: Ein Häkchen
wird im Vorbeigehen gesetzt, mit einer Hand.

- Die App legt sich beim Start auf Hochformat fest (`lib/main.dart`)
- `lib/ui/phone_frame.dart` zeigt sie im Browser in 390x844
- `test/phone_layout_test.dart` prüft jeden Bildschirm in diesem Format —
  **alle sieben liefen sofort durch**, die `maxWidth: 560`-Struktur war
  bereits richtig
- `start-app.bat` startet die App per Doppelklick, sucht sich einen freien
  Port und bleibt bei Fehlern offen stehen

## Die Kampfbalance trägt jetzt — anders als geplant

Der alte Befund („das umkämpfte Band ist zwei Angriffspunkte breit") war
richtig gemessen und falsch gedeutet. Die vorgeschlagene Abhilfe — HP
erhöhen, damit lange Kämpfe Multiplikatoren dämpfen — hätte das Problem
**verstärkt**: Längere Kämpfe mitteln den Zufall aus und machen den Ausgang
berechenbarer. Ein Rennen mit festen Werten kippt scharf, das liegt in der
Sache.

Die Lösung ist eine **Gegnerreihe**. Zu jedem Zeitpunkt ist einer knapp:

| Gegner | Tag 0 | Tag 7 | Tag 14 | Tag 21 | Tag 30 | Tag 60 |
|---|---|---|---|---|---|---|
| Wegelagerer | 62 % | 100 % | 100 % | 100 % | 100 % | 100 % |
| Soeldner | 0 % | 0 % | 4 % | 100 % | 100 % | 100 % |
| Bergwaechter | 0 % | 0 % | 0 % | 0 % | 36 % | 100 % |

Der erste Gegner ist **ab Tag eins schlagbar**. Vorher stand ein frischer
Charakter bei 0 %.

Die Spannweite zwischen keinem und perfektem Timing ist genau am
Schwellen-Gegner groß und daneben null — die gewünschte Aussage:
Gewohnheiten entscheiden, *ob* ein Kampf knapp wird, Timing entscheidet den
knappen Kampf.

Nachrechnen: `dart run tool/balance_sim.dart`. Details in ADR-0009.

## Der Stat-Deckel ist kein Problem mehr

Nach etwa einem Monat stehen alle vier Werte am Maximum (160–224 HP,
13–20 Angriff). Das bleibt so und ist gewollt — ohne Deckel überholt ein
alter Account jede Gegnerauslegung.

Bis zum 18.08. stand hier, der Charakter erstarre danach und der nächste
Schritt dagegen sei der Dungeon mit Drops. **Das gilt nicht mehr.** Mit
ADR-0012 und ADR-0013 wächst der Charakter über vier andere Wege weiter:
Theoriepunkte bis Level 50, Fähigkeitspunkte alle drei Level, Fähigkeiten
aus abgeschlossenen Baumknoten und Streak-Marken, Waffen als Spielstile.

## Konzeptrunde Charakter — 18.08.2026, entschieden, noch nichts gebaut

Der Charakter wurde vollständig durchgesprochen, bevor eine Zeile Code
entsteht. Zwei ADRs halten das Ergebnis:

**[ADR-0012](../decisions/0012-theoriebaum-ueber-punkte.md) — der Theoriebaum
wird ein echter Baum.** Zwei Wurzeln (Körper, Geist), beliebige Tiefe,
Knoten öffnen über **Theoriepunkte** statt über Levelsperren. Ein Punkt je
Levelaufstieg, ein Punkt je Knoten, unabhängig von der Tiefe. „Gewohnheiten"
bleibt frei — es ist das Handbuch. **ADR-0007 ist damit abgelöst.**

Der geplante Baum hat rund 45 Knoten. Der vorhandene Inhalt verteilt sich
sauber: Körpers drei Lektionen sind Schlaf, Sport und Ernährung — die
Aufspaltung war im Text längst vorweggenommen. Soziales und Wissenschaft
sind fertig, alles andere braucht Schreibarbeit.

**[ADR-0013](../decisions/0013-charakter-als-kommandozentrale.md) — der
Charakter wird eine Kommandozentrale.** Vier Fähigkeitsslots, drei frei
wählbar, einer von der Waffe bestimmt. Zwanzig Fähigkeiten aus Theoriebaum
(Knoten **abschließen**), Streak-Marken und Waffen. Fähigkeitspunkte alle
drei Level, umverteilbar. Name und Titel jetzt, Aussehen später.

> **Es wird nie eine Klassenwahl geben.** Jeder formt seinen Charakter durch
> seinen persönlichen Stil. Wo eine Klasse sichtbar werden soll, wird sie
> aus dem Verhalten abgeleitet, nie gewählt.

### Zwei Zahlen, die das Projekt bemessen

- **49 Knoten sind die harte Obergrenze.** `maxLevel` ist 50, also gibt es
  über ein Spielerleben genau 49 Theoriepunkte.
- **Ein voller Baum heißt rund 150 Lektionen.** Es gibt heute 17.

Der Engpass des Projekts ist damit vollständig die Schreibarbeit, nicht der
Code. Dagegen steht eine Regel: **Ein Knoten erscheint erst im Baum, wenn
sein Inhalt geschrieben ist.** Ein halber Knoten ist schlimmer als keiner —
für ihn wurde ein Punkt bezahlt.

### Eine Schieflage, die dabei auffiel

Die elf Habit-Vorlagen verteilen sich auf die vier Werte als 4 Klarheit,
3 Disziplin, **2 Ausdauer, 2 Stärke**. Die beiden Werte, die den Kampf am
direktesten entscheiden, haben die wenigsten Quellen — und beide hängen an
Körper. Der Ausbau von Körper repariert deshalb nicht nur den Baum.

## Sitzung 24.08.2026: Ziele, ADR-0019, und der Graph steht

**SMART-Ziele eingeführt** ([`ziele.md`](ziele.md)). Ziellinie ist nicht
mehr „MVP", sondern nachprüfbar: beide spielen 30 Tage täglich, ohne
abzubrechen. Sieben Ziele mit Terminen, dazu eine bindende Liste dessen,
was bis dahin **nicht** angefasst wird.

**Drei Issues vom selben Nachmittag haben die Ziele sofort umgeworfen** —
und das ist der eigentliche Befund des Tages: `state.md` allein reicht
nicht als Gedächtnis, wenn parallel Issues entstehen. Mittags stand der
Baumumbau noch auf der Sperrliste; abends ist er Ziel 2 mit Termin.

**[ADR-0019](../decisions/0019-skillbaum-mit-vier-wurzeln.md)** hält
fest, was Issue #16 gegenüber ADR-0012 ändert: vier Wurzeln statt zwei,
zwei Theoriepunkte je Level statt einem, **ein Knoten ist eine Seite mit
drei Fragen** statt eines Themas mit Lektionen. ADR-0012 steht auf
`Teilweise abgelöst`.

**Die Zahl, die den Termin 31.08. erst möglich macht:** Mit einem Knoten
= einer Seite kostet der Startbaum aus 20 Unterknoten **8 neue Seiten**,
nicht 60. Zwölf Knoten (Körper, Geist, Wissenschaft, Gesellschaft mit je
drei Lektionen) sind bereits geschrieben und wandern nur.

**Die Zahl, die dabei unangenehm ist:** 2 Punkte je Level ergeben über
`maxLevel` 50 insgesamt **98 Theoriepunkte** für 20 Knoten. Der Baum
steht ab Level 11 komplett offen — die Knappheit, die ADR-0012 wollte,
ist damit weg. Bewusst in Kauf genommen, mit Auslöser zum Nachjustieren
(ab 40 Knoten neu prüfen).

**Gebaut ist der Graph** in `packages/theory`, 17 neue Tests (jetzt 67):

- `TheoryNode` — Seite, Icon-Id, Eltern-Ids, Kosten, optionale Fähigkeit.
  Name und Zusammenfassung kommen von der Lektion, nicht doppelt
- `TheoryGraph` — Wurzeln, Kinder, Eltern, `canOpen`
- **Ein offener Elternknoten genügt** (ADR-0019), auch bei zwei Eltern
- `isHealthy` prüft vier Dinge: eindeutige Ids, keine Eltern-Id ins
  Leere, **kreisfrei**, mindestens eine Wurzel. Die Kreisprüfung ist der
  Preis dafür, dass die Struktur ein Graph ist und kein Baum

Das war der Zwischenstand am Nachmittag; Inhalte, Punkte, Persistenz
und Bildschirm kamen am selben Abend dazu — siehe unten.

### Der Skillbaum aus Issue #16 ist gebaut

**Ziel 2 ist bis auf einen Punkt erreicht** — sieben Tage vor dem
Termin. Der Baum aus [ADR-0019](../decisions/0019-skillbaum-mit-vier-wurzeln.md)
steht im Spiel.

| | vorher | jetzt |
|---|---|---|
| Struktur | 5 flache Zweige, Levelsperren | **4 Wurzeln, Graph, Punkte** |
| Knoten | 17 Lektionen | **24** (4 Wurzeln + 20 Unterknoten) |
| Seiten geschrieben | 17 | **29** (12 neue) |
| Tests `theory` | 50 | **109** |
| Tests `progression` | 23 | **33** |
| Tests App | 149 | **177** |

**Was neu ist:**

- `TheoryNode` / `TheoryGraph` in `packages/theory` — Eltern-Ids statt
  Listen, `canOpen`, und `isHealthy` mit vier Prüfungen: eindeutige Ids,
  keine Eltern-Id ins Leere, **kreisfrei**, mindestens eine Wurzel
- `TheoryPoints` in `packages/progression`, neben der Levelkurve —
  zwei Punkte je Aufstieg, `lifetimeTotal` 98
- **Zwölf neue Seiten**: vier Wurzel-Einführungen plus je zwei
  Unterknoten für Körper (Erholung, Stress), Geist (Motivation,
  Wiederholung), Wissenschaft (Stichprobe, Studien lesen) und
  Gesellschaft (Vergleich, Um Hilfe bitten)
- `skill_tree_screen.dart` neu: Handbuch plus vier Gebietskacheln;
  `root_screen.dart` zeigt die fünf Knoten eines Gebiets mit Punktepreis
- Geöffnete Knoten überleben den Neustart (`persistence_test.dart`)

**Drei Entscheidungen, die beim Bauen fielen:**

1. **Kostenlose Knoten gelten automatisch als offen.** Wurzeln und
   Handbuch kosten damit weder einen Punkt noch einen Klick und stehen
   nie im Spielstand. `openIdsIn()` fügt sie beim Prüfen dazu.
2. **Ausgegebene Punkte werden abgeleitet, nicht gezählt** — die Kosten
   stehen am Knoten. Ein entfernter Knoten gibt seinen Punkt zurück,
   statt den Stand unlesbar zu machen (wie beim Gold, ADR-0011).
3. **`availablePoints` wird in `openNode()` hineingereicht.** Der
   Punktestand hängt über das Level am Theoriefortschritt — also am
   eigenen Zustand des Notifiers. Ihn dort zu lesen wäre exakt der
   `CircularDependencyError` aus `gotchas.md`.

**Sechs alte Tests wurden ersetzt, nicht repariert.** Sie prüften
Levelsperren an Zweigen — genau das Verhalten, das ADR-0019 abschafft.
An ihrer Stelle stehen elf Tests für Graph, Punkte und Öffnen.

**Das Handbuch blieb unangetastet**, und damit auch ADR-0018: Es ist
weiter ein `TheoryBranch` mit verbindlicher Reihenfolge, steht außerhalb
des Graphen und öffnet den Kampf wie bisher.

### Der Baum wird gezeichnet, nicht aufgelistet

**Der erste Anlauf war falsch, und das Vorbild hat es gezeigt.** Gebaut
war zuerst eine Liste von Gebietskacheln, die in eine Liste von
Knotenkarten führte — funktional vollständig, aber kein Baum. Der Issue
verlangt einen „richtigen Skill-Tree" und hängt als Vorbild einen
Graphen mit Verbindungslinien an. Eine Liste kann die entscheidende
Aussage nicht treffen: dass *Stress* an Körper **und** Geist hängt.

Jetzt ist es eine Zeichenfläche:

- **`tree_layout.dart`** rechnet die Plätze aus — reine Funktion, kein
  Widget. Ein Band je Gebiet, die Wurzel oben mittig, die fünf Kinder
  darunter in einem flachen Bogen. **Von oben nach unten statt radial
  wie das Vorbild**, weil ein Handy im Hochformat Breite nicht hat und
  Höhe beliebig.
- **`tree_painter.dart`** zieht die Linien: durchgezogen zur eigenen
  Wurzel, **gestrichelt** quer ins andere Gebiet. Der Unterschied trägt
  die Aussage, sonst sähe eine Querverbindung aus wie eine normale.
- **`node_bubble.dart`** ist der Knoten als Kreis, Name darunter. Der
  ganze Knoten ist antippbar, nicht nur der Kreis — 52 Pixel sind auf
  einem Handy zu wenig.
- **`node_sheet.dart`** ist das Detailblatt an der Stelle des Panels aus
  dem Vorbild: Name, Zusammenfassung, Kosten, **eine** Handlung.
- `InteractiveViewer` mit Verschieben und Zoomen (0,4× bis 2,5×).
- `root_screen.dart` ist entfallen — es gibt jetzt einen Weg statt zwei.

**`test/tree_layout_test.dart`** prüft die Anordnung mit 13 Tests: jeder
Knoten hat genau einen Platz, keine zwei überlappen, nichts ragt heraus,
die Bänder folgen aufeinander. Das ist der Teil, der auf einem
Screenshot erst auffällt, wenn man an die richtige Stelle scrollt.

**Ein verbindender Knoten wird nur einmal platziert**, im Band seiner
ersten Wurzel. Die zweite Wurzel verbindet sich nach oben dorthin. Zwei
Positionen hätten bedeutet, dass eine der beiden Linien im Nichts endet.

### Ein Zählfehler, der beim Nachprüfen auffiel

`passedCountIn(theoryTree)` lief nur über die alten Zweige — nach dem
Umbau lagen aber **zwölf von neunundzwanzig** Seiten nur noch im
Graphen. Erfahrung und Gold stimmten (die hängen am einzelnen Ergebnis),
aber die **Titel** zählten zu wenig und der Startbildschirm zeigte
weiter „x / 17".

Behoben über `passedPagesProvider` und `totalPagesProvider`, die
Handbuch und Graph zusammenzählen. Drei Tests halten es fest. Dass sich
die beiden nicht überschneiden, prüft `graph_content_test.dart` — sonst
zählte etwas doppelt.

### Was der Layout-Test dabei gefunden hat

`phone_layout_test.dart` meldete 218 Pixel Überlauf im Kopf des
Bildschirms. Ursache war nicht der Baum, sondern eine Zeile aus zwei
Texten mit `Spacer` dazwischen: **Im Widget-Test ist jede Glyphe
quadratisch**, dadurch werden Texte dort deutlich breiter als real.
Beide Hälften dürfen jetzt schrumpfen (`Flexible` mit `ellipsis`) — was
auch bei großer Schrift auf einem echten Gerät richtig ist.

### Die Fähigkeiten hängen jetzt wirklich am Baum

`FromTheory` trägt seit heute eine **Knoten**-Id statt einer Zweig-Id,
und `FromStart` ist **ersatzlos entfallen** — sein eigener Kommentar
nannte ihn „ein Übergang, kein Entwurf". Die vier wählbaren Fähigkeiten
hängen an Schlaf, Bewegung, Ernährung und Erholung, alle vier unter
*Körper*. Bedingung ist **bestanden**, nicht bezahlt: Ein geöffneter
Knoten hat nur einen Punkt gekostet.

**Das riss eine Lücke, und sie ist geschlossen.** Fünf Tests fielen
sofort um, darunter einer im Naht-Test mit genau der richtigen
Begründung: „Sonst hätte ein frischer Charakter drei offene Slots und
nichts, was hineinpasst." Nach dem Handbuch ging der zweite Slot auf und
blieb leer — ein Move, und der Wegelagerer steht bei 0 %.

[ADR-0020](../decisions/0020-kampf-haengt-am-moveset.md) hängt die Sperre
deshalb ans **Moveset** statt ans Handbuch allein. Das Handbuch war nie
der Grund, nur ein Stellvertreter; seit ADR-0019 stimmt er nicht mehr.
Die Kachel unterscheidet drei Fälle:

| Zustand | Text |
|---|---|
| Handbuch offen | „Erst das Handbuch: noch N Lektionen" |
| keine Fähigkeit gelernt | „Erst eine Fähigkeit lernen — ein Knoten unter „Körper"" |
| gelernt, nicht angelegt | „Leg eine Fähigkeit auf einen freien Platz" |

Der dritte Fall ist kein Detail: Ohne ihn schickt die Kachel jemanden in
die Theorie zurück, wo er nichts mehr zu tun hat.

**Der Naht-Test hat eine neue Zusage.** Statt „ohne Fortschritt muss
etwas Wählbares da sein" prüft er jetzt: Auf der Stufe, auf der der
zweite Platz aufgeht, muss ein Knoten mit Fähigkeit **erreichbar und
bezahlbar** sein. Auf Level 3 sind das vier Punkte für einen Knoten, der
direkt an einer kostenlosen Wurzel hängt — der Weg ist offen in dem
Moment, in dem der Slot es ist.

### Offen aus dieser Sitzung

**Der Weg zum ersten Kampf ist länger geworden** — Handbuch, Knoten
öffnen und bestehen, Fähigkeit anlegen. Ob das zu lang ist, zeigt der
30-Tage-Lauf, nicht eine Vermutung.

**Die Balance ist nicht nachgerechnet.** `dart run tool/balance_sim.dart`
lief für diesen Umbau bewusst nicht — das war so abgesprochen. Wer das
nachholt, prüft vor allem, ob zwei Moves am Tag des ersten Kampfes noch
die 100 % aus ADR-0018 liefern.


**Issue #15 ist ungeklärt und blockiert AktivesBrett.** Die erste
Vermutung (er lief in die Handbuch-Sperre aus ADR-0018) ist widerlegt —
er hatte die Lektionen gemacht. Geprüft und in Ordnung: Branch-Id
`habits`, fünf Lektionen, Ids konsistent, `lessonCount ==
lessons.length`, 149 Tests grün. Offene Spuren: **Flutter 3.47.0 / Dart
3.13.0** auf seinem Rechner gegen 3.44.9 / 3.12.2 hier, und ob „Fragen
gemacht" auch „mit ≥ 60 % bestanden" heißt.

## Als Nächstes

**Der Charakterbildschirm ist fertig.** Von ADR-0013 fehlt nichts mehr
außer den Fähigkeitspunkten und den Knöpfen für Errungenschaften,
Streaks und Freunde. Der Kern-Loop schließt sich: Lektion — Vorlage —
Häkchen — Erfahrung — Gold — Ausrüstung — Fähigkeit — Kampf.

**Seit dem 24.08. ist diese Liste terminiert.** Welcher Punkt bis wann
fertig sein soll und woran das gemessen wird, steht in
[`ziele.md`](ziele.md). Die Zuordnung:

| Punkt hier | Ziel | Termin |
|---|---|---|
| — (Issue #15, Kampf startet nicht) | Ziel 1 | **26.08.2026** |
| 3 — Punkteökonomie und Baumumbau (Issue #16) | Ziel 2 | **31.08.2026** |
| 1 — Waffen als Sidegrades | Ziel 3 | 06.09.2026 |
| 8 — Tageswechsel | Ziel 4 | 06.09.2026 |
| 2 — Fähigkeiten (Issue #17 erweitert) | Ziel 5 | 13.09.2026 |
| 4 + 5 — Dungeon, Tränke | Ziel 6 | 20.09.2026 |
| 6, 7, 9, 10 | **zurückgestellt** | nach dem 30-Tage-Lauf |

**Punkt 3 ist am 24.08. von „zurückgestellt" nach vorne gerückt** — Issue
#16 hat ihm ein Datum gegeben, und [ADR-0019](../decisions/0019-skillbaum-mit-vier-wurzeln.md)
macht ihn deutlich kleiner als ADR-0012 ihn geplant hatte: Ein Knoten ist
jetzt **eine Seite**, nicht ein Thema mit drei Lektionen. Es fehlen dadurch
**acht** neue Seiten statt gut hundert.

Die Reihenfolge unten bleibt stehen, weil die Begründungen dort
ausführlicher sind als in `ziele.md`.

**1. Drei Waffen in den Laden — und dafür `catalog_test.dart`
umbauen.**

Entschieden am 22.08.: Die fünf Waffen sind **Alternativen zum
ähnlichen Preis**, keine Leiter. Man kauft die zweite Waffe für einen
anderen Rhythmus, nicht für mehr Zahlen — so wollte es ADR-0017
(„je ein Rhythmus").

**Das kollidiert mit einer bestehenden Regel.** `catalog_test.dart`
erzwingt heute „teurer muss auch besser sein" (ADR-0011). Für
Sidegrades gilt das nicht mehr. Der Test muss die Regel innerhalb
einer Preisstufe lockern, ohne sie zwischen den Stufen aufzugeben —
sonst ist der Laden wieder beliebig. Dafür braucht es einen ADR, weil
es eine Entscheidung von ADR-0011 zurücknimmt.

Erst danach ist ADR-0017s Kernaussage überhaupt überprüfbar: Heute
geben **beide** Klingen im Laden dieselbe Fähigkeit, die Waffe
bestimmt also nichts.

**2. Die elf übrigen Fähigkeiten** (ADR-0017). Sie brauchen zuerst
Arbeit in `packages/combat`: einen verallgemeinerten `StatModifier`,
in dem `DefenseDown` aufgeht, plus drei neue Mechaniken (anteilige
Heilung, eigene Schwächungen entfernen, Gift zünden).

Mit ihnen kommt auch *Blöße finden* zurück — die Schwächung, die
`Zehrung` bei der Teilung verloren hat.

**Und dann ist ADR-0018 neu zu prüfen:** Sobald eine Waffe mit anderem
Rhythmus den ersten Kampf allein tragen kann, wird aus der Sperre vor
dem Kampf Bevormundung statt Hilfe.

**3. Punkteökonomie und Baumumbau** (ADR-0012, ADR-0013): Baumstruktur
in `packages/theory` auf Knoten mit Kindern, Theoriepunkt je Stufe,
Fähigkeitspunkt auf jeder dritten. `AbilitySlots` ist der vorgesehene
Platz dafür und im Code als unvollständig markiert.

Der sichtbarste Teil ist die Baumdarstellung — `skill_tree_screen.dart`
zeigt heute eine Liste, ein Baum braucht etwas anderes. Und erst mit
echten Knoten bekommen die vier `FromStart`-Fähigkeiten ihre
Bedingung; heute sind sie von Anfang an offen, weil ihre Knoten
(Sport, Ernährung, Schlaf, Erholung) noch nicht existieren.

**4. Dungeon** — 4 Gegner plus Boss, HP heilt nicht dazwischen. Das
Stück, das im MVP-Schnitt noch fehlt. Offen bleibt die
Niederlagen-Regel (`konzept.md` Punkt 3): verfallener Eintritt plus
Neustart bestraft doppelt.

**5. Tränke und Wiederbelebung** — bewusst mit dem Dungeon zusammen.

**6. Kampfsystem-Umbau** — es liegt eine Design-Notiz von Frederik vor
(`Kampfsystem.docx`, **noch nicht im Repo** und am 22.08. auch nicht
auffindbar): Initiative über ein Minispiel mit drei Situationen,
Attacken in Angriff und Ausweichen geteilt, Kontern, dazu ein
Sparring-Tutorial beim Lieutenant, das in die Bibliothek und damit in
die Theorie überleitet. **Weiterhin nicht entschieden** — ADR-0015 hat
nur das Bild angefasst, ADR-0017 hat bewusst nichts davon
vorweggenommen.

**7. Lebensbalken an die Zeitachse hängen** — sie springen heute
sofort, während das Geschoss noch fliegt (ADR-0015).

**8. Tageswechsel bei laufender App** — `todayProvider` rechnet
sich nicht von selbst neu. Wer die App über Mitternacht offen lässt,
sieht bis zum Neustart den gestrigen Tag.

**9. Große Schrift bricht das Layout** — bei `textScaler` 2,0
läuft der Gewohnheiten-Bildschirm um 149 Pixel über, das
Ausrüstungsraster um 8,5. Projektweite Lücke, es gibt nirgends einen
Test dafür.

**10. Rive-Animationen** statt der gezeichneten Figuren in
`lib/combat/battle/fighter.dart`. Die Schnittstelle steht bereit.

**Balance ist bewusst zurückgestellt.** Erst fertig bauen, dann
tarieren. Mit drei aus fünfzehn plus Waffe wird sie ohnehin eine
Stichprobe statt einer Rechnung (ADR-0013).

## Signale, an denen Entscheidungen neu anstehen

Beides ist heute richtig und wird es nicht bleiben:

- **Persistenz:** Der komplette Stand wird bei jeder Änderung geschrieben.
  Bei drei Objekten irrelevant. Sobald der Dungeon Lauf-Historie mitbringt,
  braucht es Entprellen — oder tatsächlich Drift. Der Anschluss steht dafür
  bereit (ADR-0010).
- **Kein Verkauf im Laden:** tragbar bei sechs Plätzen und neun Stücken.
  Kommen Drops dazu, wird ein voller Rucksack ohne Ausgang unangenehm
  (ADR-0011).

## Aufgabenteilung

Es gibt jetzt **sieben** saubere Nähte, und keine kennt die andere:

| Package | liefert |
|---|---|
| `combat` | `CombatEvent`s, die Flame abspielt |
| `theory` | Inhalte und Lernfortschritt |
| `progression` | Levelkurve und Fähigkeitsslots |
| `habits` | Streaks und Charakterwerte |
| `gear` | Preise und Boni |
| `identity` | Name und verdiente Titel |
| `abilities` | woher eine Fähigkeit kommt |

Dazu der Speicher-Anschluss in `lib/save/`.

**Wo sie sich treffen, steht ein Test in der App**, weil kein Package
es allein prüfen kann: `habits_theory_test.dart`,
`abilities_seam_test.dart` und `progression_test.dart`. Wer eine Naht
anfasst, lässt sie laufen.

Damit lässt sich parallel arbeiten, ohne sich zu blockieren: Logik/Balance,
Darstellung, Inhalte, Ökonomie.

## Verlauf

- **21.08.2026** — Kampfdarstellung neu gebaut (ADR-0015): Zeitachse statt
  Alles-in-einem-Frame, zwei gezeichnete Menschen statt Rechtecken, ein
  Pfeil, der wirklich fliegt. `packages/combat` blieb dabei unangetastet —
  ADR-0002 hat sich ausgezahlt. Dazu das Zielgerät festgeschrieben: Handy
  im Hochformat, mit Rahmen für den Browser und einem Test, der jeden
  Bildschirm bei 390x844 prüft. Drei Fehler kamen dabei ans Licht, die
  grüne Tests nicht gefunden hatten — alle drei stehen in `gotchas.md`.
- **19.08.2026** — Name und Titel gebaut, das erste Stück aus dem
  Charakter-Konzept (ADR-0014). Sechstes Package `identity`: sieben Titel
  aus drei Quellen, verdient statt gewählt. Dabei `longestStreak` in
  `habits` ergänzt — die Bedingung an die laufende Kette zu hängen hätte
  einen verdienten Titel bei einem verpassten Tag gelöscht und damit
  `konzept.md` 3.7 verletzt. Zweiter Rechner im Team eingerichtet
  (Flutter 3.47.0 / Dart 3.13.0).
- **18.08.2026** — Konzeptrunde Charakter, kein Code. Theoriebaum wird ein
  echter Baum mit Punkten statt Levelsperren (ADR-0012, löst ADR-0007 ab),
  Charakter wird Kommandozentrale mit vier Fähigkeitsslots und ohne
  Klassenwahl (ADR-0013). Dabei zwei Dinge gefunden: Der vorhandene
  Körper-Inhalt hatte seine eigene Aufspaltung vorweggenommen, und die
  Habit-Vorlagen sind auf Stärke und Ausdauer zu dünn besetzt.
- **17.08.2026** — MVP bis auf den Dungeon geschlossen. Kampfbalance über
  eine Gegnerreihe gelöst (ADR-0009) und dabei zwei Fehler gefunden: einen
  Heal-Lock, der Kämpfe nicht enden ließ, und eine Simulation, die die
  falsche Größe maß. Persistenz hinter einem Anschluss statt Drift
  (ADR-0010) — der Fortschritt überlebt jetzt einen Neustart. Ausrüstung als
  fünftes Package, Gold bekommt einen Abfluss (ADR-0011). Charakter- und
  Ladenbildschirm gebaut, damit ist keine Kachel mehr gesperrt.
- **12.08.2026, abends** — Gewohnheiten gebaut und damit den Kern-Loop
  geschlossen (ADR-0008): fünftes Package mit Vorlagen-Katalog, Streaks,
  Belohnungs- und Stat-Kurve, dazu der Tracker-Bildschirm.
- **12.08.2026, nachmittags** — Theorie zum Skillbaum ausgebaut: vier neue
  Zweige, freigeschaltet über das Charakterlevel (ADR-0007). Levelkurve als
  eigenes Package (ADR-0006). Insgesamt 17 Lektionen und 51 Fragen.
- **12.08.2026, vormittags** — Startbildschirm gebaut, ersten Theoriezweig
  geschrieben (5 Lektionen), Fortschritts- und Belohnungslogik als eigenes
  Package (ADR-0004, ADR-0005). Farben in `lib/ui/palette.dart`.
- **11.08.2026** — Konzept in vier Fragerunden erarbeitet. Repo aufgesetzt,
  Gedächtnis-Struktur und ECC-Werkzeuge eingecheckt. Kampflogik
  implementiert, Balance-Simulation gebaut, erste Balance-Schwäche gefunden.
  Flutter-App mit spielbarem Kampfbildschirm.
