# Projektstand

> Diese Datei ist die Antwort auf „Wo stehen wir gerade?“ — und wird in
> jede Sitzung geladen. Deshalb bleibt sie **kurz**: oben die Übersicht,
> darunter die Einträge der letzten Tage.
>
> Am Ende jeder Arbeitssitzung einen Eintrag oben anfügen. **Einträge,
> die älter als etwa eine Woche sind, wandern wortgleich nach
> [`verlauf.md`](verlauf.md)** — dort wird nichts gekürzt, und sie wird
> nicht in jede Sitzung geladen.
>
> Wohin es geht, steht in [`ziele.md`](ziele.md) — mit Terminen und mit der
> Liste dessen, was bis zum MVP ausdrücklich **nicht** angefasst wird.

**Zuletzt aktualisiert:** 28.09.2026 · AktivesBrett

---

## Übersicht: was steht

**Phase:** Testlauf (Ziel 7, 21.09.–20.10.2026). Alle Bauziele 1–6 und 8
sind erreicht; seit Teststart wurde trotzdem stark weitergebaut (siehe
„Offen“).

| Bereich | Stand | Wo nachlesen |
|---|---|---|
| **Gewohnheiten** | Vorlagen und eigene, Streaks, **Tageskette**, Streak-Eis, Tagesform, Tagestruhe, **Tagesaufgaben**, Wochenrückblick, Auslöser „Wann machst du das?“, Startvorlage | ADR-0028, -0036, -0043, -0044, -0052, -0055 |
| **Startseite** | Figur mit Ausrüstung, sieben Kreise, „Heute“ zum Abhaken | ADR-0049, -0053, -0057 |
| **Wissensbaum** | vier Wurzeln, Zwischenebenen, 54 Knoten, 15 angekündigte Überschriften, ein Punkt je Knoten, Rückfrage des Tages, **falsche Antworten kommen noch einmal**, **Ring und Zähler an jedem Knoten, Gebietsbalken, „Weiterlesen“** | ADR-0019, -0045, -0050, -0051, -0055, -0056 |
| **Kampf** | die Grube: Echtzeit, 30 Stufen, gesteckte Räume, Wächter mit Tor und Auftritt, Uhr, vier Dailies, Beute je Gegner | ADR-0039, -0040, -0041, -0046 |
| **Stärke** | Level und Seltenheit vervielfachen, Gewohnheiten addieren | ADR-0042 |
| **Ausrüstung** | Exemplare mit Würfen, Tagesladen, Beute mit Schlüsseln, Sets, Legendäre, Verkauf zu einem Viertel, **eigener Bereich mit allen 48 Stücken** | ADR-0029–0031, -0034, -0047, -0048, -0057 |
| **Fähigkeiten** | 19 Fähigkeiten und 8 Waffenzüge in der Grube, eigener Bereich mit allen Werten | ADR-0022, -0049 |
| **Errungenschaften** | 19 Meilensteine, 8 Entdeckungen, 13 Titel | ADR-0033 |
| **Speicher** | lokal im Browser, **als Text sicherbar** | ADR-0010, -0054 |
| **Prototyp** | das Dorf, nur im Entwicklermodus | — |

**Tests:** App 605, dazu die acht Packages (theory 174, habits 227, gear
117, action_combat 206, progression 42, abilities 36, identity 25,
achievements 24). **In der CI laufen nur die App-Tests** — der Umbau,
der alle prüft, wartet auf den `workflow`-Scope (Eintrag vom 27.09.).

## Offen, gesammelt

**Braucht euch beide:**

- ~~**Was der Testlauf misst.**~~ Entschieden am 27.09. (Frederik):
  **weiterbauen**. Der Testlauf ist damit ein Entwicklungsmonat; ob
  Ziel 7 neu formuliert wird, steht in `ziele.md` noch aus.
- **Das Dorf** statt der Kreise? Braucht AktivesBrett und einen ADR.

**Inhalt und Balance:**

- Gegenlesen: neun Einführungen und zwanzig Themen im Wissensbaum
  (Kraft, Ausdauer, Psychologie, Philosophie) — mit Gesundheitsaussagen.
- Wie viel XP und Gold Theorie künftig bringt (ADR-0037, Punkt 1);
  welches Gebiet als Nächstes befüllt wird.
- Ob vier bis fünf Beutestücke am Tag das Inventar fluten;
  `runway_sim` zählt den Laden noch als Katalogsumme.
- Ob die Uhr in der Grube beim ersten Erkunden reicht.
- Der Weg zum ersten Kampf ist lang (Handbuch, drei Knoten, anlegen).

**Oberfläche, nicht am Handy geprüft:**

- Die Figur an vollen Tagen (rund 80 Punkte bei fünf offenen).
- Kopieren und Einfügen des Spielstands im Handy-Browser.
- Ob der kontrastreichere Boden die dunkle Fledermaus schluckt.
- Drei Reihen „Inhalt folgt“ im Baum: Versprechen oder Baustelle?

**Kleinere Lücken:**

- Der Gewohnheiten-Bildschirm zeigt die Werte im Alltagsmaßstab, der
  Charakter im Kampfmaßstab.
- Die Waffenzüge stehen nicht im Fähigkeiten-Katalog.
- „Gefestigte“ Seiten im Baum sind nicht zu sehen.
- Schuhe, Ring und Talisman zeigen sich nicht auf der Figur.
- Quelle und Urheber der Asset-Pakete fehlen in den HERKUNFT-Dateien.
- `world.dart` (1.754 Zeilen), `tracker.dart` (1.227) und
  `action_game.dart` (1.024) liegen über der 800-Zeilen-Grenze.

**Bewusst zurückgestellt** (Frederik, 27.09.): die tägliche Erinnerung
(APK oder Web-Push) und die Identität im Wochenrückblick.

---

## 28.09.2026, später: Moos und Risse im Boden der Grube

Frederiks zwei neue Bodenkacheln: derselbe Ziegelboden mit Moos und mit
Rissen (`BodenMoos.png`, `BodenRisse.png`). Sie liegen auf einzelnen
Flecken von 6 × 6 Feldern, genau über einer Kachel des Grundbodens, im
Mittel jeder dritte, aus dem Ort gewürfelt (`GrubeFiguren.fleckAt`).
Die Ziegel sind in allen drei Bildern dieselben, der Übergang ist
deshalb nahtlos. App 605.

**Angesehen als zusammengesetzte Vorschau, nicht im Spiel.** Moos und
Risse gehen bis an den Rand ihrer Kachel, deshalb liest man die Flecken
als Quadrate. Wer das weicher will, zeichnet die Ränder frei, der Code
bleibt dann, wie er ist.

## 28.09.2026: die Ausrüstung bekommt einen eigenen Bereich

Wunsch von AktivesBrett: ein Ausrüstungsfenster wie das der Fähigkeiten,
mit sechs Plätzen oben und allen Stücken darunter, gruppierbar, mit
Popup, und raus aus dem Charakter.
[ADR-0057](../decisions/0057-ausruestung-bekommt-einen-eigenen-bereich.md).
App 594 Tests (vorher 576).

**Vorher gefragt und entschieden:**

| Frage | Antwort |
|---|---|
| Was steht im Raster? | **der ganze Katalog**, besessene Stücke farbig, der Rest grau; mehrfach besessene mit „×2“ |
| Wonach ordnen? | **A–Z** (Standard), Platz, Seltenheit, Set |
| Das Inventar im Laden? | **bleibt**, das neue Fenster kann auch verkaufen |
| Der 7. Kreis? | **unten vier**, auf 64 statt 72 Punkte verkleinert |

| Was | Wo |
|---|---|
| Sechs Plätze, Set-Karte, 48 Stücke in vier Ordnungen | `lib/gear/equipment_screen.dart` |
| Das Blatt: Grundwerte, Wurfspanne, Seltenheitsfaktor, Kampfwirkung, Set mit beiden Stufen, Preis, Verkauf, Herkunft und **jedes eigene Exemplar** mit Anlegen, Ablegen, Verkaufen | `lib/gear/widgets/gear_sheet.dart` |
| Die Ordnungen, reine Rechnung, deutsches Alphabet | `lib/gear/gear_grouping.dart` |
| Verkaufen mit Rückfrage und Feier | `lib/gear/sell_flow.dart` |
| Kreise in beliebiger Größe | `HubCircle.size`, `HomeScreen.bottomCircleSize` |
| Das Grau für „noch nicht“, jetzt eine Stelle | `lib/ui/ausgegraut.dart` |

**Im Charakter** bleiben die Werte mit ihrer Herkunft; statt Plätzen und
Set-Karte steht dort „Zur Ausrüstung“. Die Tests dazu sind aus
`character_test.dart` und `gear_test.dart` nach
`equipment_screen_test.dart` gewandert.

**Das Blatt liest den Spielstand selbst.** Wer darin anlegt oder
verkauft, sieht es sofort, ohne es zu schließen.

**Im Browser durchgespielt** (375 × 812), leer und mit allem
geschenkt: Kreise, Raster, Ordnungen, Blatt, Anlegen. **Nicht am Handy
angesehen.**

### Nachgereicht: Popup am Platz, Wechseln per Ziehen

AktivesBrett nach dem ersten Ansehen: Ein Tipp auf einen belegten Platz
öffnete nur die Auswahl, nicht die Werte. Und gewechselt werden soll
„wie in Clash Royale“, durch Halten und Ziehen.

| | Jetzt |
|---|---|
| Tipp auf einen belegten Platz | **das Blatt mit den Werten** des angelegten Stücks |
| Tipp auf einen leeren Platz | ein Satz, wie er sich füllt |
| Wechseln | ein besessenes Stück **halten**, die Fläche rollt zu den Plätzen, der passende leuchtet, die übrigen treten zurück; loslassen legt an, der falsche Platz nimmt nichts |
| Mehrfach besessen | das **beste Exemplar** (`Loadout.bestCopyOf`, neu in `gear`) |
| Das alte Auswahlblatt am Platz | **entfernt** |

Die Fläche ist kein `ListView` mehr: Beim Hochrollen während des Ziehens
verwarf die ListView sonst die Kachel, von der gezogen wird. gear 117
(vorher 112), App 598. Das Ziehen ist im Widget-Test gelaufen und im Browser bei 375 × 812
nachgestellt (Berührung halten, Ring aus dem Raster auf den Ring-Platz):
Hochrollen, Leuchten, grüner Rand, Anlegen. **Mit einem echten Finger
am Handy nicht.**

### Nachgereicht: dasselbe Ziehen für die Fähigkeiten

AktivesBrett: „dasselbe System mit dem lange drauf gehen und dann rein
ziehen auch für die Fähigkeiten“. Freigeschaltete Fähigkeiten lassen sich
jetzt auf die freien Plätze ziehen, gesperrte nicht. Der Waffenplatz
nimmt nichts an, und es leuchten nur die belegten Plätze plus der
nächste leere. **Dieselbe Grenze wie bei den Platz-Knöpfen im Blatt**,
weil `ChosenAbilities` keine Lücken hält. Die Knöpfe im Blatt bleiben.

**Wie sich das Ziehen anfühlt, steht jetzt an einer Stelle**
(`lib/ui/halten_und_ziehen.dart`): der Zustand eines Platzes, das Bild
unter dem Finger, Leuchten und Zurücktreten, das Hochrollen. Die
Ausrüstung ist darauf umgestellt. Der Fähigkeiten-Bildschirm ist dafür
kein `ListView` mehr. Getestet im Widget-Test (Anlegen, Ersetzen, Lücke,
Waffenplatz, Gesperrtes), App 603, und im Browser bei 375 × 812
nachgestellt: Sammeln gehalten, der leere Platz leuchtet, Waffenplatz
und gesperrte treten zurück, Loslassen legt es auf Platz 2. Der Satz
unter den Plätzen sagt jetzt „halten und hierher ziehen“ statt
„antippen“. **Mit einem Finger am Handy nicht.**

### Offen

- **Zwei Verkaufswege**: `sellWithConfirm` und `ShopScreen._sell` tun
  dasselbe, weil der Laden nicht angefasst werden sollte. Auf Dauer
  gehört der Laden auf `sellWithConfirm` umgestellt.
- **Lange Namen brechen mitten im Wort um** („Bernsteinamulet-t“), bei
  9 Punkten Schrift in einer 77 Punkte breiten Kachel.
- **Die Marke „Gewöhnlich“ ist auf Leder kaum zu lesen**, im
  Ausrüstungs- wie im Fähigkeiten-Bildschirm. Ihre Farben sind für
  Pergament gewählt.
- **Kaufen geht dort nicht.** Das Blatt sagt, wenn ein Stück heute im
  Laden liegt, führt aber nicht direkt zum Angebot.

## 27.09.2026, zuletzt: Überblick im Wissensbaum

Frederik: „Man weiß schwer, wie viele der Unterpunkte man schon gemacht
hat.“ Ein gerendertes Bild zeigte den Grund: Eine Zwischenebene
leuchtete grün, sobald ihre Einführung gelesen war, und sah fertig aus.
[ADR-0056](../decisions/0056-ueberblick-im-wissensbaum.md).

| Was | Wie |
|---|---|
| **Ring und Zähler** | um jeden Knoten mit Unterpunkten, „2 / 5“ unter dem Namen; gold erst, wenn alles darunter geschafft ist |
| **Zeichen am Kreis** | ✓ bestanden, Buch offen, „1“ kaufbar, Schloss mit Uhr zu teuer, Schloss unerreichbar; Legende hinter dem Fragezeichen |
| **Vier Gebiete oben** | statt der Punkte, je mit Balken und Stand, antippen springt hin |
| **Weiterlesen** | die offene, ungelesene Seite, einen Tipp entfernt |

Gerechnet wird in `TheoryProgress.progressBelow` und `nextToRead`, nicht
mehr im Bildschirm. **Beim Ansehen gefunden:** Die Wurzel zeigte 7 / 19,
der Balken oben 8 / 20 — eine Wurzel zählt ihre eigene Seite jetzt mit.

theory 174 (vorher 165), App 576. **Nicht am Handy angesehen**,
gerendert in 390 × 844.

## 27.09.2026, spät: drei Dinge von Duolingo

Auf die Frage, wie sich das Konzept mit Duolingo als Vorbild verfeinern
lässt; Frederik hat drei Vorschläge gewählt und entschieden:
**weiterbauen** statt einfrieren.
[ADR-0055](../decisions/0055-tageskette-aufgaben-und-wiederholen.md).

| Was | Wie |
|---|---|
| **Tageskette** | Tage mit mindestens einem Häkchen, als Flamme in „Heute“ auf der Startseite; blass, solange heute nichts abgehakt ist. Die Leiter auf dem Gewohnheiten-Bildschirm heißt jetzt „Kette je Gewohnheit“, ohne Flamme |
| **Zweite Runde** | Falsch Beantwortetes kommt am Ende der Lektion noch einmal, neu gemischt, bis es sitzt. Gewertet wird der erste Durchgang |
| **Tagesaufgaben** | drei am Tag, immer eine zum Abhaken; abholen bringt einen Schlüssel. Nie aus der Grube (ADR-0048). Auf der Startseite ein Hinweis, sobald etwas abzuholen ist |

**Beim Ansehen gefunden** (gerendert in 390 × 844 mit echter Schrift):
Der Knopf „Abholen“ als Holzplanke drückte den Text weg — jetzt ein
kleiner eigener Knopf. Und ein **alter** Fehler: Die Namen der Werte
brachen mitten im Wort um („Ausda|uer“). Behoben.

habits 227 (vorher 205), App 570. **Nicht am Handy angesehen.**

## 27.09.2026, abends: Sicherung, CI, Aufräumen

Nach einer kritischen Durchsicht der ganzen App (Frederik: „gehe
kritisch auf alles ein“). Die drei Punkte, die ohne Absprache gingen:

| Was | Wie |
|---|---|
| **Spielstand sichern** | Kopieren und Einfügen als Text, unten am Charakter. Einfügen ist streng (`SaveData.tryImport`), fragt nach, legt den alten Stand in die Zwischenablage und startet die App von innen neu (`SpielstandHost`, [ADR-0054](../decisions/0054-spielstand-als-text-sichern.md)) |
| **CI** | **vorbereitet, noch nicht hochgeladen**: `pages.yml` soll auch **Pull Requests** prüfen und die **Tests aller acht Packages** ausführen — rund 800, die bisher nie in der CI liefen. Der Zugang aus der Claude-Sitzung darf keine Workflow-Dateien ändern (fehlender `workflow`-Scope) |
| **Aufräumen** | gemergte Branches gelöscht, Issue #63 geschlossen, diese Datei zusammengefasst |

**Beim Bauen gefunden:** Ein abgeleiteter Provider für den aktuellen
Stand lieferte dem `SaveWatcher` im Moment des Speicherns noch den
alten — zwei Tests fielen um. `currentSave` ist deshalb eine Funktion.

App 559. **Nicht am Handy angesehen**, insbesondere nicht, ob Kopieren
und Einfügen im Browser des Handys die Zwischenablage erreichen.

### Offen aus der Durchsicht — braucht euch beide

**Der Testlauf misst etwas, das sich täglich ändert.** Seit dem 21.09.
kamen 83 Commits und +35.000 Zeilen, darunter ein neues Kampfsystem.
Ziel 7 fragt nach Abbruch aus Langeweile, und gezählt wird nichts. Zu
entscheiden: Funktionen einfrieren und zählen — oder den Testlauf
ehrlich einen Entwicklungsmonat nennen und die Ziellinie neu setzen.

Weiter offen, nicht dringend: der lange Weg zum ersten Kampf, drei
Dateien über 800 Zeilen (`world.dart` 1.754), ungelesene Theorie-Inhalte.

## 27.09.2026, zuletzt: neuer Boden in der Grube

Frederiks neue Ziegel ersetzen `assets/Grube/Boden.png` (256 × 256,
nahtlos, geprüft an einer 2 × 2 gelegten Vorschau). Sie haben sechzehn
Reihen statt etwa elf; die Kachel liegt deshalb über **sechs** Felder
statt vier (`GrubeFiguren.bodenFelder`), damit die Ziegel im Spiel so
groß bleiben wie vorher. Der neue Boden hat **mehr Kontrast** — ob die
dunkle Fledermaus darauf noch liest, zeigt das Spielen. Angesehen als
skalierte Vorschau, nicht in der Grube.

## 27.09.2026, danach: „Heute“ auf der Startseite

[ADR-0053](../decisions/0053-heute-auf-der-startseite.md), Punkt 2 aus
der Durchsicht. Zwischen Figur und unterer Kreisreihe steht eine Karte
mit den **offenen** Gewohnheiten und ihrem Auslöser; ein Tipp hakt ab.
Erledigtes schrumpft auf „2 erledigt“, ist alles erledigt, weist die
Karte auf die Truhe.

| Was | Wo |
|---|---|
| Die Karte | `lib/home/widgets/today_card.dart` |
| Der Ablauf eines Häkchens, jetzt **eine Stelle** für beide Orte | `lib/habits/habit_check_flow.dart` (aus `habits_screen.dart` gezogen) |

**Die Figur gibt den Platz ab**: bei fünf offenen nur rund 80 Punkte
hoch, bei drei rund 110, mit jedem Häkchen wieder mehr. Ob das zu klein
ist, ist die offene Frage. Angesehen als gerendertes
Bild in 390 × 844 mit Roboto, **nicht am Handy**. Der Layout-Test baut
die Startseite jetzt mit fünf offenen Gewohnheiten **und** Auslösern.
App 546.

**Zurückgestellt** (Frederik, 27.09.: „nicht so wichtig“): die tägliche
Erinnerung (APK oder Web-Push) und die Identität im Wochenrückblick.
Beide stehen unten unter „Offen aus der Durchsicht“.

## 27.09.2026: „Wann machst du das?“ und die erste Gewohnheit ab Start

Nach einer Durchsicht der ganzen App nach den vier Gesetzen der
Verhaltensänderung (Frederik, mit einem Foto aus *Die 1%-Methode*):
Die Belohnung ist die Stärke der App, der **Auslöser** fehlt fast ganz.
Frederik hat zwei der fünf Vorschläge gewählt,
[ADR-0052](../decisions/0052-ausloeser-und-startvorlage.md).

| Was | Wie |
|---|---|
| **Auslöser** | jede Gewohnheit kann eine Zeile tragen, „nach dem Zähneputzen“. Gefragt wird beim Starten, mit sechs Vorschlägen zum Antippen; „Später“ lässt die Frage auf der Kachel stehen |
| Wo er steht | unten auf der Kachel, nur solange sie offen ist; antippen ändert ihn |
| Gespeichert | `HabitTracker.cueFor`, Abschnitt `cues`, erzeugt keine Zahl |
| **Startvorlage** | „Zwei Minuten lesen“ ist ab Start offen, samt Platz für eine eigene |
| Weg | der leere Bildschirm „Noch keine Gewohnheit freigeschaltet“ — er ist unerreichbar |

**Was der Test gefunden hat:** Die erste Fassung setzte die Zeile unter
den Namen, und dort lag sie genau in der Mitte der Kachel. Ein Tipp in
die Mitte, der übliche zum Abhaken, öffnete den Dialog. Sie steht jetzt
unten.

habits 205 (vorher 191), App 540 (vorher 535). **Nicht angesehen**,
weder im Browser noch am Handy.

### Offen aus der Durchsicht

1. *(zurückgestellt)* **Eine tägliche Erinnerung** — der größte Hebel. Die Web-Fassung
   kann sie ohne Server nicht verlässlich schicken; das braucht das APK
   oder Web-Push. Entscheidung steht aus.
2. ~~**„Heute“ auf der Startseite**~~ — gebaut, siehe oben.
3. *(zurückgestellt)* **Identität im Wochenrückblick**: „23-mal gelesen — so sieht ein
   Leser aus“ (Handbuch-Lektion „Wer du sein willst“).
4. Grundsatz für alles Neue: Jede Spielmechanik führt zurück zum
   Häkchen, wie die Schlüssel.

## 26.09.2026: der Wissensbaum bekommt Zwischenebenen

Frederik: „Ich würde gerne den Theorie-Teil überarbeiten" — das Zielbild
aus [ADR-0037](../decisions/0037-der-wissensbaum-als-endziel.md) /
Issue #54, **mitten im Testlauf** statt danach. Die offenen Punkte in
einer Fragerunde entschieden, festgehalten in
[ADR-0050](../decisions/0050-zwischenebenen-und-angekuendigte-gebiete.md).
Die Sperre „Baum über 24 Knoten" in `ziele.md` ist aufgehoben.

**Erster Schritt, auf Frederiks Wunsch: alle Überschriften als Gebiet,
um Wirkung und Navigation zu sehen. Inhalt kommt später.**

| Was | Wie |
|---|---|
| Zwischenebene | zwischen Wurzel und Thema; **ein Punkt**, eine Einführungsseite |
| Befüllt | 8: Kraft & Muskulatur, Ernährung, Schlaf & Regeneration, Psychologie, Selbstentwicklung, Wissenschaftliches Denken, Beziehungen, Medien & Information |
| Angekündigt | 17, grau mit „Inhalt folgt", nicht zu öffnen (`TheoryPlaceholder`) |
| Stand am Ende der Sitzung | **10 befüllt, 15 angekündigt** — Ausdauer & Fitness und Philosophie kamen dazu |
| Die 21 alten Knoten | einsortiert; wer einen offen hatte, behält Zwischenebene und Wurzel darüber ohne Punkt |
| Punkte | einer je Level, **dazu einer zum Start** |
| Wurzeln | **kosten jetzt auch einen Punkt** ([ADR-0051](../decisions/0051-wurzeln-kosten-einen-punkt.md)) |

**Sieben neue Einführungsseiten, Entwürfe von Claude — noch nicht
gegengelesen.** `packages/theory/lib/src/content/area_pages.dart`.
„Wissenschaftliches Denken" steht nicht in #54: Die fünf alten
Wissenschaftsthemen sind Methode und passten unter keine der sechs
Überschriften. „Was ist Psychologie" heisst jetzt „Psychologie" und ist
die Seite ihrer Zwischenebene.

**Was die Simulation dazu sagt** (`runway_sim`): Bis Tag 35 ändert sich
nichts, der Baum ist erst an **Tag 50 statt Tag 33** gelesen. Die Punkte
sind der Engpass, nicht die Seiten. Neue Seiten verlängern also das Ende
und füllen nicht die Wochen 3 und 4. Wer das will, dreht an den Punkten.

**Danach auf Frederiks Wunsch: die Wurzeln kosten einen Punkt**
(ADR-0051). Damit der zweite Fähigkeitsplatz auf Level 3 nicht leer
aufgeht, beginnt jeder mit einem Theoriepunkt. Der Weg zur ersten
Fähigkeit — Wurzel, Zwischenebene, Thema — kostet drei, Level 3 gibt
drei; `abilities_seam_test.dart` rechnet den ganzen Weg. Alte Stände
behalten alles über eine Regel statt einer Liste: offen ist, was
gekauft, bestanden oder einziger Eltern eines Offenen ist.
`runway_sim` danach: an Tag 30 sind 20 Knoten offen, gelesen ist der
Baum an Tag 58.

**Und das erste Gebiet ist befüllt: Kraft & Muskulatur.** Fünf neue
Themen neben „Die kleinste Dosis, die wirkt": Wie ein Muskel wächst,
Wie nah ans Versagen, Den Plan bauen, Technik vor Gewicht, Muskelkater
und Pausen (`kraft_pages.dart`). Die Zahlen darin — etwa 1,6 g Eiweiß
je Kilo, zehn und mehr harte Sätze je Muskel und Woche, null bis drei
Wiederholungen in Reserve — sind als Größenordnung formuliert. Keine
neue Fähigkeit, keine Gewohnheitsvorlage.

**Dann Ausdauer & Fitness**, vorher grau angekündigt, jetzt ein Gebiet
mit Einführung und fünf Themen: Das Herz als Motor, VO₂max, Locker und
lang, Intervalltraining, Woher die Energie kommt (`ausdauer_pages.dart`).
Damit ist die alte Schieflage bei Stärke und Ausdauer zumindest in der
Theorie angegangen — Gewohnheitsvorlagen gibt es dafür weiter keine
neuen.

**Dann Psychologie**, fünf Themen neben Aufmerksamkeit und Wiederholen,
jedes an einem Versuch aufgehängt: Die Macht der Mehrheit (Asch),
Gehorsam (Milgram), Warum keiner hilft (Bystander), Erinnerung ist kein
Video (Loftus), Gefühle regulieren (Gross). Wo ein Befund später
eingeschränkt wurde, steht das dabei — die 38 Zeugen im Fall Genovese
sind als Übertreibung benannt (`psychologie_pages.dart`).

**Dann Philosophie**, vorher grau angekündigt: Einführung und fünf
Themen — Was in deiner Macht steht (Epiktet, Mark Aurel), Folgen,
Pflichten, Charakter (Utilitarismus, Kant, Aristoteles), Fehlschlüsse
erkennen, Fragen statt behaupten (Sokrates), Freiheit und Sinn (Sartre,
Camus). `philosophie_pages.dart`.

**Damit ist der Baum größer als ein Spielerleben:** 54 Knoten gegen 50
Theoriepunkte über 50 Level. Das ist das Zielbild aus ADR-0037 — man
kann nicht alles lernen, man wählt. `theory_points_test.dart` hält das
jetzt als Zusage fest. In 60 Tagen sind 33 offen (`runway_sim`).

theory 165 (vorher 148), progression 42, App 535. **Nicht angesehen**, weder im Browser
noch am Handy — ob drei Reihen Überschriften mit „Inhalt folgt" als
Versprechen lesen oder als Baustelle, sagt nur das Bild.

### Offen

- **Gegenlesen** der neun Einführungsseiten und der zwanzig Themen
  (Kraft, Ausdauer, Psychologie, Philosophie).
- **Wie viel XP und Gold** Theorie künftig bringt (ADR-0037, Punkt 1).
- **Welches Gebiet als Nächstes befüllt wird.** Körper fehlen noch
  Körperkontrolle und Biologie des Körpers; in Geist stehen Geschichte
  und Kreativität noch grau, Gesellschaft und Wissenschaft haben die
  meisten leeren Überschriften.
- Eine Ankündigung antippen tut nichts. Ob man dort eine Zeile „kommt
  noch" erwartet, zeigt das Spielen.

---

Ältere Einträge: [`verlauf.md`](verlauf.md).
