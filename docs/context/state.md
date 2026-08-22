# Projektstand

> Diese Datei ist die Antwort auf „Wo stehen wir gerade?".
> Am Ende jeder Arbeitssitzung aktualisieren. Alte Einträge unter „Verlauf"
> zusammenfassen, nicht löschen.

**Zuletzt aktualisiert:** 22.08.2026 · Frederik

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
- **Flutter-App** (`lib/`) — 149 Tests grün, Web-Build läuft:
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

## Als Nächstes

**Der Charakterbildschirm ist fertig.** Von ADR-0013 fehlt nichts mehr
außer den Fähigkeitspunkten und den Knöpfen für Errungenschaften,
Streaks und Freunde. Der Kern-Loop schließt sich: Lektion — Vorlage —
Häkchen — Erfahrung — Gold — Ausrüstung — Fähigkeit — Kampf.

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
