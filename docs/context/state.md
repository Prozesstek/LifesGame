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

**Zuletzt aktualisiert:** 28.10.2026 · Frederik

---

## Übersicht: was steht

**Phase:** Testlauf (Ziel 7, 21.09.–20.10.2026). Alle Bauziele 1–6 und 8
sind erreicht; seit Teststart wurde trotzdem stark weitergebaut (siehe
„Offen“). **Als Nächstes: Ziel 9, der Play Store am 20.11.** — die Frist,
die zählt, ist der 26.10. (zwölf Tester im geschlossenen Test).

| Bereich | Stand | Wo nachlesen |
|---|---|---|
| **Gewohnheiten** | **neue über einen grünen Plus-Knopf, eine Frage nach der anderen**, **Skills je Gebiet, die nur wachsen — die Erfahrung fliegt zum Level und zum Gebiet**, **ein Häkchen, das aufspringt, klingt und Münzen wirft**, **das erste des Tages lässt die Flamme groß in der Mitte einen Tag höher ticken**, **das Lagerfeuer am Abend mit Truhe, Aufgaben, Rückfrage und „Morgen zuerst“**, Vorlagen und eigene, **Wochenplan je Gewohnheit**, **Koppeln zu Stapeln**, Streaks, **die fallen statt zu reißen**, **Tageskette**, Streak-Eis, Tagesform, Tagestruhe, **Tagesaufgaben**, Wochenrückblick, Auslöser „Wann machst du das?“, **Belohnung danach**, **Zeitziele als Timer**, Startvorlage | ADR-0028, -0036, -0043, -0044, -0052, -0055, -0064, -0065, -0066, -0067, -0085, -0089 |
| **Startseite** | **vor dem Berg**, acht Kreise mit Namen in zwei Holzrahmen, **die nach und nach erscheinen**, **ein Mentor, der durch den ersten Start führt**, Level-Abzeichen und Gold in einer Zeile, „Heute“ zum Abhaken, **darunter das Lagerfeuer**, **am Anfang die Frage nach der ersten Gewohnheit** | ADR-0049, -0053, -0057, -0058, -0068, -0076, -0079, -0087 |
| **Wissensbaum** | **jede Seite eine Spielrunde wie bei Duolingo**, **gelesen wird in einem Buch, das sich umblättern lässt**, vier Wurzeln, Zwischenebenen, 63 Knoten, 15 angekündigte Überschriften, ein Punkt je Knoten, **ein Startpunkt, einer je Aufstieg**, **das Handbuch als fünf Knoten unter Gewohnheiten**, **direkt zur nächsten Seite**, Rückfrage des Tages, **falsche Antworten kommen noch einmal**, **Ring und Zähler an jedem Knoten, Gebietsbalken, „Weiterlesen“** | ADR-0019, -0045, -0050, -0051, -0055, -0056, -0061, -0070, -0078 |
| **Kampf** | die Grube: Echtzeit, 30 Stufen, **nur ein Sieg zahlt, eine Niederlage nimmt zurück und zeigt drei Wege**, gesteckte Räume, **elf Gegnerarten in gewürfelter Besetzung**, **vier Wächter, je Lauf gewürfelt**, Tor und Auftritt, Uhr, Beute je Gegner, **zwei Zeichen im ersten Lauf**, **die Tagesgrube: eine für alle, ein Versuch am Tag** | ADR-0039, -0041, -0046, -0062, -0063, -0069, -0072 |
| **Stärke** | Level und Seltenheit vervielfachen, Gewohnheiten addieren, **das Gebiet bestimmt den Kampfwert** | ADR-0042, -0088 |
| **Ausrüstung** | Exemplare mit Würfen, Tagesladen, Beute mit Schlüsseln, Sets, Legendäre, Verkauf zu einem Viertel, **eigener Bereich mit allen 60 Stücken**, **Rahmen und Name in der Farbe der Seltenheit**, **Kräfte auf jeder Seltenheit, das Vampirset** | ADR-0029–0031, -0034, -0047, -0048, -0057, -0077 |
| **Fähigkeiten** | 39 Fähigkeiten und 8 Waffenzüge in der Grube, **vier Ultimates auf eigenem Platz ab Level 15**, **drei Passive ohne Knopf**, neunundzwanzig Arten von Wirkung, eigener Bereich mit allen Werten | ADR-0022, -0049, -0073, -0074 |
| **Errungenschaften** | 22 Meilensteine, 8 Entdeckungen, 13 Titel — **in der Sammlung**, mit Ausrüstung, Fähigkeiten, Gegnern (in Stufen), Titeln und Seiten | ADR-0033, -0073, -0074, -0080 |
| **Speicher** | lokal im Browser, **als Text sicherbar** | ADR-0010, -0054 |
| **Haustier** | drei Eier, wächst an Tagen mit Häkchen, Zubehör für Gold — **in jeder Fassung** | ADR-0086, [`haustier.md`](../vorlagen/haustier.md) |
| **Statistik** | Woche, Monat, Jahr, Gesamt mit Blättern; Raster, Balken, Kurve, Wochentage, je Gewohnheit, Rekorde, Jahresrückblick — **nur Gewohnheiten** | ADR-0087 |
| **Prototyp** | das Dorf, nur im Entwicklermodus | — |

**Tests:** App 1040, dazu die acht Packages (theory 218, habits 374, gear
137, action_combat 406, progression 52, abilities 43, identity 25,
achievements 25) und der Prototyp `haustier` (21). **In der CI laufen nur die App-Tests** — der Umbau,
der alle prüft, wartet auf den `workflow`-Scope (`verlauf.md`, 27.09.).

## Offen, gesammelt

**Die Richtung** (09.10., [ADR-0071](../decisions/0071-das-naechste-level.md)):
~~Tagesgrube~~ (gebaut am 11.10., ADR-0072), ~~Lagerfeuer~~ (gebaut am
18.10., ADR-0076), Schatten,
Saisons, Seilschaft — nach und nach, jede mit eigener Konzeptrunde. Die
Fragen dafür stehen in der Vorlage
[`das-naechste-level.md`](../vorlagen/das-naechste-level.md).

**Fähigkeiten** (14.10., [ADR-0073](../decisions/0073-ultimate-mana-und-neue-arten.md)):
Ultimate, neue Arten und Frederiks zehn und zwei **gebaut am 15.10.**
(PR #117, gemergt am 15.10.). Offen: **Mana als
Bremse ist gemessen, nicht gestellt**, und AktivesBrett fehlt in
[`faehigkeiten-2.md`](../vorlagen/faehigkeiten-2.md).

**Braucht euch beide:**

- **Zehn Fähigkeiten und zwei Ultimates von AktivesBrett** in die
  Vorlage (ADR-0073).

- ~~**Was der Testlauf misst.**~~ Entschieden am 27.09. (Frederik):
  **weiterbauen**. Der Testlauf ist damit ein Entwicklungsmonat; ob
  Ziel 7 neu formuliert wird, steht in `ziele.md` noch aus.
- **Das Dorf** statt der Kreise? Frederik lehnt es ab (Issue #88) und
  will stattdessen das **Haus** ausbauen (Möbel, Haustiere). Braucht
  AktivesBrett und einen ADR.
- **Die fünf Ideen** aus ADR-0071 hat AktivesBrett nicht gesehen —
  und nicht, dass für die Tagesgrube die Dailies gestrichen sind
  (ADR-0072).
- **Die Messlatte der Tagesgrube** (zehn Fremde, nach zwei Wochen teilen
  noch drei) ist Claudes Vorschlag. Als Ziel in `ziele.md` braucht sie
  einen Termin und eine Bestätigung.

**Vor einer Veröffentlichung** (Durchsicht vom 02.10.). **Entschieden
am 02.10. (Frederik): Ziel ist eine Android- und iOS-App, aber erst
später — zuerst wird das Konzept weiter ausgebaut.** ~~Store bleibt auf
der Sperrliste in `ziele.md`.~~ **Seit dem 19.10. Ziel 9: am 20.11. im
Play Store** ([`play-store.md`](../vorlagen/play-store.md)). Offen bis dahin: Datenverlust, Erinnerung und Android-App, ~~der lange Weg
zum ersten Kampf~~ (gebaut, ADR-0068), ~~nur tägliche Gewohnheiten~~ (gebaut, ADR-0064),
Lizenzen der Assets, Fremde als Tester (mit der Tagesgrube ohne Store
möglich, ADR-0071). Die ganze Liste steht in `verlauf.md`, Eintrag
vom 02.10.

**Inhalt und Balance:**

- Gegenlesen: neun Einführungen und zwanzig Themen im Wissensbaum
  (Kraft, Ausdauer, Psychologie, Philosophie) — mit Gesundheitsaussagen.
  **Dass es nötig ist, zeigte der 18.10.**: Auf „Wie nah ans Versagen“
  stand das Gegenteil des Richtigen (Eintrag vom 18.10.).
  Dazu die Einführung „Gewohnheiten“, am 07.10. umgeschrieben.
- **Der erste Lauf ist härter als gedacht**: Stufe 1 auf Level 1 steht
  für den Bot bei 67 %, nicht bei 93 % (Eintrag vom 07.10.).
- Wie viel XP und Gold Theorie künftig bringt (ADR-0037, Punkt 1);
  welches Gebiet als Nächstes befüllt wird.
- Ob vier bis fünf Beutestücke am Tag das Inventar fluten;
  `runway_sim` zählt den Laden noch als Katalogsumme.
- Ob die Uhr in der Grube beim ersten Erkunden reicht.
- ~~Der Weg zum ersten Kampf ist lang~~ — seit ADR-0068 geht es nach
  dem ersten Häkchen in die Grube. Ob Stufe 1 am ersten Tag für einen
  Menschen so leicht ist wie für den Bot, ist nicht gespielt.
- **Ohne Dailies fehlt rund ein Viertel des Goldes** (ADR-0072): an
  Tag 60 Level 29 statt 33 und 4.286 Gold statt 5.759. Nicht
  ausgeglichen.
- **Wie schwer die Tagesgrube für Menschen ist**, weiß niemand. Der Bot
  gewinnt ohne Form je nach Wochentag 20 % bis 78 %, in Form immer.

**Oberfläche, nicht am Handy geprüft:**

- Kopieren und Einfügen des Spielstands im Handy-Browser — und damit
  auch das Teilen der Tagesgrube, das denselben Weg nimmt.
- Ob der kontrastreichere Boden die dunkle Fledermaus schluckt.
- **Die fünf Klänge der Grube hat niemand gehört** (13.10.): gerechnet,
  nicht aufgenommen, und ob sie im Handy-Browser ohne Verzögerung
  kommen, ist offen.
- Drei Reihen „Inhalt folgt“ im Baum: Versprechen oder Baustelle?

**Kleinere Lücken:**

- Der Gewohnheiten-Bildschirm zeigt die Werte im Alltagsmaßstab, der
  Charakter im Kampfmaßstab.
- Die Waffenzüge stehen nicht im Fähigkeiten-Katalog.
- „Gefestigte“ Seiten im Baum sind nicht zu sehen.
- Schuhe, Ring und Talisman zeigen sich nicht auf der Figur.
- Quelle und Urheber der Asset-Pakete fehlen in den HERKUNFT-Dateien.
- `world.dart` (1.936 Zeilen), `tracker.dart` (1.858) und
  `action_game.dart` (1.222) liegen über der 800-Zeilen-Grenze.

**Bewusst zurückgestellt** (Frederik, 27.09.): die tägliche Erinnerung
(APK oder Web-Push) und die Identität im Wochenrückblick.

---

## 28.10.2026, danach: Zeichen, die Spieler aus anderen Spielen kennen

Frederik: „UI: passendere Icons wählen (vielleicht gucken was der
Spieler aus anderen Spielen gelernt hat)“. Claude schlug eine Tabelle
vor, Frederik: „ja leg los find ich alles gut“.

| Kreis | vorher | jetzt |
|---|---|---|
| Gewohnheiten | Haken im Kreis (Systemzeichen) | **Schriftrolle mit Haken** — die Quest |
| Kampf | Karate-Figur | **gekreuzte Schwerter**, wie auf „Hinab“ |
| Statistik | Liniendiagramm | **drei Balken, die steigen** |
| Laden | Ladenfront mit Markise | **Münzbeutel** |
| Fähigkeiten | Sternenfall | **Runenstein, der blau leuchtet** |
| Ausrüstung | Plattenharnisch | **Rucksack** — das Inventar |
| Charakter | Profil-Männchen (`CharacterButton.png`) | **Helm** — der Charakterbogen |
| Theorie | Frederiks Buch | bleibt |

Alles im Pixelstil statt als Systemzeichen: fünf aus Raven, Rucksack
und Balken gezeichnet (`tool/kreis_zeichen.py`, Raven hat keinen
Rucksack). **Angriff ist jetzt ein Schwert statt einer Hantel** —
gezeichnet, ein Schwert gibt es unter den Systemzeichen nicht
(`StatIcon`).

**Ein Bereich, ein Zeichen**: Dieselben Bilder stehen jetzt auch auf den
Tipps nach einer Niederlage und auf den drei Planken im Charakter
(`lib/ui/bereich_zeichen.dart`, eine Tabelle). Bis dahin standen dort
Schild, Ladenfront und Glitzer.

**Eine Korrektur an Claudes Vorschlag:** Er nannte Schild und Glitzer
auf der Startseite doppelt belegt. Dort lagen aber schon Harnisch und
Sternenfall — die Systemzeichen waren nur der Ersatz. Doppelt waren sie
auf den Planken im Charakter und bei den Tipps.

Neu: sieben Bilder `assets/UI/Kreis_*.png`, `lib/ui/bereich_zeichen.dart`,
`tool/kreis_zeichen.py`, ein Test, dass jeder Kreis ein eigenes
gezeichnetes Zeichen trägt. App 1040 (vorher 1039). Startseite und
Charakter in 390 × 844 gerendert und angesehen. **Nicht am Handy.**
`CharacterButton.png` liegt noch im Repo, gebraucht wird es nicht mehr.

### Offen

- Der vorgeschlagene Test: drei Tester sehen die Kreise **ohne Namen**
  und sagen, was dahinter ist.
- Der Rucksack ist gezeichnet und wirkt neben den Raven-Bildern
  schlichter.
- **AktivesBrett hat es nicht gesehen.**

## 28.10.2026: die Flamme tickt groß in der Mitte

Frederik: „ich hätte gerne, dass immer wenn die erste Gewohnheit am Tag
abgehakt wird in der Mitte des Screens die Flamme einen Tag höher tickt
und ne coole Animation ist so wie bei Duolingo“. Gebaut ohne Fragerunde
als Prototyp.

| Was | Wie |
|---|---|
| **Wann** | beim ersten Häkchen des Tages, auf der Startseite und im Gewohnheiten-Bildschirm — wo die kleine Flamme auf „Heute“ schon zündet |
| **Die Flamme** | gezeichnet, groß in der Mitte: glimmt erst grau, zündet dann — springt auf, ein Ring geht nach außen, Funken platzen —, flackert, Funken steigen |
| **Die Zahl** | die alte steigt hinaus, die neue springt von unten herein; am allerersten Tag springt die Eins einfach auf |
| **Die Woche** | Mo bis So darunter: was die Kette getragen hat, brennt mit Haken, Streak-Eis blau, heute fängt mit einem Ring Feuer |
| **Klang** | neu `KetteSteigt.wav`: vier Glocken hinauf mit Knistern, wenn die Zahl umspringt, dazu ein kräftiger Stoß; das Fauchen beim Tipp bleibt |
| **Dauer** | 2,6 s, dann blendet sie aus und steigt wie Rauch; **ein Tipp blendet sofort aus** und hakt nichts darunter ab |
| **Danach** | Errungenschaft, Aufstieg und Fähigkeit warten, bis sie aus ist; Münzen und Konfetti fliegen über sie, die aufsteigenden Zahlen liegen darunter |

**Ohne Rückfrage entschieden:**

- **Ein dunkler Schleier**, zum Rand hin heller: Die Leiste oben bleibt
  zu sehen, damit man die Münzen ankommen sieht.
- **Keine Sätze** (ADR-0060): Flamme, Zahl, Wochentage. „7 Tage am
  Stück“ steht nur für den Vorleser.
- **Ein Tipp blendet aus, statt durchzugehen**: Sonst hakte ein zweiter
  schneller Tipp eine Gewohnheit ab, die unter der Flamme liegt.
- **Wer abhakt, zurücknimmt und wieder abhakt, sieht sie noch einmal** —
  wie die kleine Flamme auf „Heute“. Gezählt wird ohnehin nur einmal.
- **Die Woche zeigt Häkchen, nicht Fälliges**: Ein Ruhetag steht leer da,
  obwohl er die Kette trägt.

**Beim Ansehen gefunden** (gerendert in 390 × 844, fünf Zeitpunkte): Die
aufsteigenden „+15 EP …“ lagen genau auf der Zahl, weil „Heute“ mitten
auf der Startseite liegt; sie steigen jetzt unter der Flamme. Und der
Schleier war zu blass.

Neu: `lib/habits/tages_flamme.dart`, `lib/habits/widgets/tages_flamme_feier.dart`,
`AufstiegHost.zeigeInDerMitte`, `SoundEffect.ketteSteigt`,
`test/tages_flamme_test.dart` (7). App 1039 (vorher 1032). Beim Aufräumen
sind die Einträge vom 13. bis 20.10. nach `verlauf.md` gezogen. **Nicht
gehört, nicht am Handy.**

### Offen

- Ob 2,6 s jeden Morgen zu lang sind — oder ob sie bei Meilensteinen
  (7, 30, 100 Tage) größer feiern soll als an einem gewöhnlichen Tag.
- Ob die kleine Flamme auf „Heute“ daneben noch nötig ist.
- **AktivesBrett hat es nicht gesehen.**

## 26.10.2026, danach: Vorschläge für das nächste Kapitel

Frederik: „Wenn ein Skillpunkt offen ist: Vorschläge für nächstes
Kapitel. So muss der Spieler selber nicht selber entscheiden, kann es
aber, wenn er will.“ In einer Fragerunde, viermal wie empfohlen:
[ADR-0091](../decisions/0091-vorschlaege-fuers-naechste-kapitel.md).

**Die Lücke vorher:** Ein Vorschlag, und wer die Grundlagen durch hatte,
bekam gar keinen mehr.

| Was | Wie |
|---|---|
| **Bis zu drei** | jeder mit seinem Grund als Zeichen: schon offen (Buch), Grundlagen (Hut), weiter, wo du warst (Pfeil), passt zu deinen Gewohnheiten (Häkchen), neues Gebiet (Kompass) |
| **Der erste** | ist der alte Vorschlag; auf ihn zeigt der Mentor |
| **Wo** | oben im Baum statt der einen Kachel, und in der Feier eines Aufstiegs unter dem neuen Punkt |
| **Ein Tipp** | öffnet und liest; der Preis steht dran |

**Ohne Rückfrage entschieden:** „Zuletzt gelesen“ ist die Seite, die
zuletzt **zum ersten Mal** versucht und bestanden wurde — eine Uhrzeit
steht nirgends. Die Gewohnheiten zählen mit der Erfahrung ihrer Häkchen
je Gebiet. Jede Kachel trägt die Farbe ihres Gebiets (ADR-0090).

Neu: `packages/theory/lib/src/vorschlag.dart`,
`lib/theory/vorschlag_flow.dart`, `vorschlag_test.dart` (8),
`test/vorschlaege_test.dart` (2). App 1030 (vorher 1028), theory 218
(vorher 210). Fünf Tests gingen von einer Kachel aus und nehmen jetzt
die erste. Baum und Aufstieg in 390 × 844 gerendert und angesehen.
**Baut auf #165 auf. Nicht am Handy.**

### Offen

- Ob drei Kacheln oben den Baum zu weit nach unten drücken — am Handy
  ansehen.
- **AktivesBrett hat ADR-0091 nicht gesehen.**

## 26.10.2026: jedes Gebiet eine Farbe

Frederik: „Hinter jedem Theorie-Gebiet eine Farbe — auch bei Charakter
und Gewohnheiten verwenden, also wirklich alles, was irgendwie mit den
Gebieten zu tun hat, wird mit der gleichen Farbe eingefärbt.“ In einer
Fragerunde entschieden, viermal wie empfohlen:
[ADR-0090](../decisions/0090-jedes-gebiet-eine-farbe.md).

| Gebiet | Farbe | auf Pergament | auf Leder |
|---|---|---|---|
| Körper | Glut | `#93360B` | `#FF8A3D` |
| Geist | Blau, wie Mana | `#234F8C` | `#7FA8D9` |
| Wissenschaft | Violett | `#5E2E94` | `#B78EEB` |
| Gesellschaft | Rosa, wie das Herz | `#8E2559` | `#EE8DBE` |

**Kein Rot, Grün oder Gold** — die heißen schon Gegner, erledigt und
Gold. Gebaut in drei Blöcken mit je einem PR.

### Block 1: Baum und Lesen

| Was | Wie |
|---|---|
| **Knoten** | bestanden gefüllt in der Farbe des Gebiets, offen mit einem Rand darin; kaufbar bleibt gold, Gesperrtes grau, „alles darunter“ gold |
| **Ring, Linien, Zeichen am Knoten** | in der Farbe des Gebiets statt Grün und Akzent |
| **Kopf** | Stand und Skill-Abzeichen in der Farbe; die vier Kacheln darunter jede in ihrer eigenen |
| **„Weiterlesen“** | in der Farbe des Gebiets der vorgeschlagenen Seite — sie kann woanders liegen |
| **Die Seite** | betonte Wörter, Merksatz, die Striche beim Lesen und der Balken bei den Fragen; ob eine Antwort sitzt, bleibt grün und rot |
| **Rückfrage des Tages** | Buch und Rand in der Farbe ihrer Seite |

**Ein Knoten trägt die Farbe des Gebiets, in dem man ihn sieht**:
*Stress* ist unter Geist blau, unter Schlaf & Regeneration glut.
Außerhalb des Baums die seines Zuhauses, der Wurzel seines ersten
Elternteils (`TheoryGraph.rootIdsOf`, neu).

Neu: `lib/skills/gebiet_farbe.dart`, `lib/theory/widgets/seiten_farbe.dart`,
`test/gebiet_farbe_test.dart` (10). App 1019 (vorher 1009; mit #162 zusammen 1021), theory 210
(vorher 208). Alle vier Gebiete, die Legende und eine Seite aus Geist in
390 × 844 gerendert und angesehen. **Nicht am Handy** — auch die
anderen Blöcke nicht.

### Block 2: Gewohnheiten, Häkchen und Startseite

| Was | Wie |
|---|---|
| **Kachel und Zettel** | ein Streifen am linken Rand in der Farbe des Gebiets, erledigt blass; Zeichen, Skill und „+15“ fürs Gebiet ebenso. **Das Häkchen bleibt grün** |
| **Das Häkchen** | die Funken zum Gebiet, „+15 EP Geist“, der Aufstieg des Skills, der Punkt eines Werts und die Tagesform eines Werts steigen in der Farbe auf; „In Form“ bleibt im Akzent |
| **Der Balken des Gebiets** | neben dem Level-Ring in seiner Farbe statt Grün |
| **Die Wahl** | beim Anlegen, auf der Startseite und bei der Frage nach dem Gebiet alter Gewohnheiten trägt jedes Zeichen seine Farbe |

Neu: `lib/skills/widgets/gebiet_streifen.dart`, `Steckbrief.streifen`.
App 1023 (vorher 1019). Startseite, ein Häkchen mitten im Flug, die
Gewohnheiten und die Wahl beim Anlegen in 390 × 844 gerendert und
angesehen.

### Block 3: Charakter, Kampfwerte, Errungenschaften, Haustier, Statistik

| Was | Wie |
|---|---|
| **Kampfwerte** | Hantel, Herz, Schild und Tropfen in der Farbe ihres Gebiets (`StatIcons.colorOf`), auch in der Tagesform; **die Grube bleibt, wie sie ist** |
| **Charakter** | die vier Skills mit Zeichen und Balken in ihrer Farbe; bei jedem Wert das Zeichen seines Gebiets darin |
| **Errungenschaften** | die zwölf Titel der Gebiete: Rand, Pokal und Balken in der Farbe; dafür nennt jeder sein Gebiet (`Achievement.skillAreaId`) |
| **Haustier** | die Prägung nimmt die eine Tabelle; seine eigenen vier Farben sind weg |
| **Statistik** | über alle bleibt sie grün; die einer Gewohnheit trägt die Farbe ihres Gebiets (`StatTon`), auch der gewählte Zeitraum; jeder Ring in der Übersicht in seiner |

App 1028 (vorher 1023), achievements 25 (unverändert, ein Test prüft
mehr). Charakter, Errungenschaften, Statistik über alle und für eine
Gewohnheit und vier Prägungen in 390 × 844 gerendert und angesehen.

**Die drei PRs** (#163, #164, #165) bauen aufeinander auf und werden in
dieser Reihenfolge gemergt.

### Offen

- Körper liegt nah am Akzent; im Baum steht der nicht mehr daneben.
- **In der Statistik von Geist** sind erledigte Tage blau und Tage mit
  Streak-Eis hellblau — nicht mit einem Eis-Tag angesehen.
- In der Grube trägt nichts die Farbe eines Gebiets, auch nicht die
  Leiste der Fähigkeiten, deren Mana aus Geist kommt.
- **AktivesBrett hat ADR-0090 nicht gesehen.**

## 26.10.2026: Schwerter auf „Hinab“, im Blatt nur das angetippte Exemplar

AktivesBrett schickte ein Schwert-Icon: „das packst du da hin, wo man
beim Kampfmenü ganz unten drauf klickt … zur Zeit sind da nur zwei
Pfeile“. Und: „in dem Item-Menü, wenn man auf ein Item klickt … die
anderen Items raus“. In zwei Fragerunden entschieden, alle sechs Fragen
wie empfohlen.

| Was | Wie |
|---|---|
| **Die Schwerter** | zwei gekreuzte Schwerter statt der zwei Pfeile, auf „Hinab“ im Eingang **und** in der Tagesgrube; hell wie die Schrift auf dem Holzknopf |
| **Nachgezeichnet** | die Vorlage hat keine bekannte Herkunft; das Zeichen ist aus Linien gerechnet (`SchwerterZeichen`) und gehört dem Projekt |
| **Das Blatt eines Stücks** | zeigt nur noch das Exemplar, das angetippt wurde — im Rucksack, auf dem Platz, im Siegerblatt; die anderen desselben Stücks nicht mehr. Aus der Sammlung: nur die Werte |
| **Die Anzahl** | „2 Mal im Besitz.“ bleibt als Info |
| **Verkauft** | geht das Blatt zu, sobald auch eine Feier dazu vorbei ist |
| **Die Knöpfe** | danach, auf AktivesBretts Wunsch: Ablegen, Verkaufen und Sperren sind Holzplanken wie Anlegen, nicht mehr bloßer Text |

**Beim Bauen gefunden:** Verkaufen im Blatt lief über den Kontext des
Exemplars. Ist es verkauft, verschwindet es samt Kontext — die Feier des
Verkaufs fand ihren Bildschirm dann nicht mehr. Das war schon vorher
so, jetzt läuft der Verkauf über das Blatt.

Neu: `lib/combat/widgets/schwerter_zeichen.dart`,
`test/schwerter_zeichen_test.dart`. App 1011 (vorher 1009). Die
Schwerter groß neben der Vorlage und im Eingang gerendert und angesehen.
**Nicht am Handy.**

## 25.10.2026, danach: eine Frage nach der anderen (Block B)

Der zweite Teil von Frederiks Wunsch: „Neue Gewohnheiten werden über
einen grünen kreisförmigen [Knopf] mit einem Plus unten rechts
hinzugefügt … immer nur eine Frage auf einmal.“ In einer Fragerunde
entschieden, dreimal wie empfohlen:
[ADR-0089](../decisions/0089-eine-frage-nach-der-anderen.md).

| Was | Wie |
|---|---|
| **Plus-Knopf** | grün, rund, unten rechts auf dem Gewohnheiten-Bildschirm — der einzige Weg zu einer neuen |
| **Erstes Blatt** | „Eigene erstellen“ (mit freien Plätzen) oder „Vorlage“; Vorlage klappt auf: „Deine“ (pausierte eigene) und „Von der App“ |
| **Eigene** | Name → Gebiet (mit dem Kampfwert, ADR-0088) → Schwierigkeit → Tagesziel → Wann → Tage → Danach |
| **Vorlage** | nur Wann → Tage → Danach; eine pausierte mit Auslöser startet sofort |
| **Bedienung** | eine Wahl führt mit einem Tipp weiter, ein Feld mit „Weiter“, freiwillige Fragen haben „Ohne“; oben Striche, zurück und schließen |
| **Weg** | „Warum?“, „Wie wichtig?“, die Reiter Eigene / Vorerstellte, die Kopplung als eigene Frage |

**Angelegt wird erst am Ende**; wer abbricht, hat nichts verändert. Bis
dahin legte das Formular an, und den Dialog danach konnte man
wegklicken.

**Ohne Rückfrage entschieden:** Wann vor Tagen vor Danach; Vorgaben
„jeden Tag“, „mittel“, „nur abhaken“; bei voller Liste endet eine eigene
nach dem Tagesziel und wartet unter „Deine“; die erste Frage auf der
Startseite bleibt, wie sie ist (ADR-0068). Der Dialog „Wann machst du
das?“ bleibt fürs Ändern einer laufenden.

**Beim Ansehen gefunden** (gerendert in 390 × 844, jedes Blatt): Auf
„Wann machst du das?“ mit Vorschlägen und Kopplungen rutschte „Weiter“
unter den Rand. Kopf und Knöpfe stehen jetzt fest, nur die Frage rollt;
ein Test in `phone_layout_test.dart` geht jeden Schritt am Handy durch.

Neu: `gewohnheit_anlegen.dart`, `anlegen_ergebnis.dart`,
`anlegen_teile.dart`, `test/gewohnheit_anlegen_test.dart` (10).
Gelöscht: `custom_habit_sheet.dart`, `habit_template_tile.dart`. App
1009 (vorher 999). **Nicht am Handy.**

### Offen

- **Pausierte eigene sieht man nur noch im Ausklappmenü** — wer eine
  sucht, muss wissen, dass sie dort liegt.
- Ob „Eigene oder Vorlage“ als erster Schritt nötig ist, oder ob der
  Name mit Vorlagen als Vorschlägen reicht (wie auf der Startseite).
- Der Plus-Knopf hat auf dem dunklen Leder einen dunklen Schatten-Ring.
- **AktivesBrett hat ADR-0089 nicht gesehen.**

## 25.10.2026: der Kampfwert folgt dem Gebiet

Frederik will das Anlegen einer Gewohnheit umbauen (grüner Plus-Knopf,
eine Frage nach der anderen) und fragte: „Können wir irgendwelche von
diesen Fragen noch wegmachen, weil sie sich doppeln?“ Auf „Wert“ und
„Gebiet“, die wie eine Frage klingen: „Können wir nicht sagen abhängig
von Gebiet wird ein anderer Kampfwert erhöht?“
[ADR-0088](../decisions/0088-der-kampfwert-folgt-dem-gebiet.md).
Das ist **Block A**; der Plus-Knopf und die Fragen kommen als Block B.

| Gebiet | steigert |
|---|---|
| Körper | Angriff |
| Geist | Mana |
| Wissenschaft | Abwehr |
| Gesellschaft | Leben |

**Für alle Gewohnheiten und rückwirkend** — so gewählt, gegen Claudes
Empfehlung (ab einem Stichtag, Bisheriges bleibt). Die Werte heißen auf
den Bildschirmen nur noch Angriff, Leben, Abwehr und Mana; Stärke,
Ausdauer, Disziplin und Klarheit stehen nur noch im Spielstand.

| Wo | Was |
|---|---|
| Startseite, erste Frage | nur noch das Gebiet, daneben das Zeichen des Werts, der daraus folgt |
| Frage nach dem Gebiet alter Gewohnheiten | „Körper · Angriff“ und so weiter; sie verschiebt jetzt Skill **und** Wert |
| Formular einer eigenen | „Worauf zahlt es ein?“ ist weg |
| Charakter | bei jedem Wert das Zeichen seines Gebiets statt des Häkchens |
| Aufsteigende Zahl, Tagesform, Wochenrückblick | „+1 Angriff“ statt „+1 Stärke“ |

**Gemessen** (`pit_sim`, Bot mit den ersten fünf Vorlagen — drei aus
Geist, zwei aus Körper): An Tag 14 stärker (Stufe 7 zu 42 % statt 8 %),
ab Tag 30 **etwa eine Stufe schwächer** (Tag 30: Stufe 9 statt 10, Level
50: 38 statt 39). Ihm fehlen Leben und Abwehr. Nicht nachgestellt.

Neu: `SkillArea.kampfwert`, `HabitStat.gebiet`,
`CustomHabit.statOhneGebiet`; weg: `HabitStat.combatLabel`,
`DailyFormText.pitNameOf`, der Wert an den Vorlagen. habits 374 (vorher
366), App 999 (unverändert). Startseite und Charakter in 390 × 844
gerendert und angesehen. **Nicht am Handy.**

### Offen

- **Bestehende Stände verlieren Werte**: Wer keine Gewohnheit in
  Gesellschaft hat, verliert seinen Lebensbonus, ohne Wissenschaft den
  Abwehrbonus. Das trifft auch eure Stände.
- **Abwehr kommt nur aus Wissenschaft**, und dort gibt es eine Vorlage.
- Die Ausrüstung sagt weiter „Lebenspunkte“, „Verteidigung“, „Energie“.
- **AktivesBrett hat ADR-0088 nicht gesehen.**

## 24.10.2026, danach: das Haustier steht in der Leiste

Frederik: „Ich würde gerne das Haustier ohne Rahmen in die gleiche
Ebene wie das Level und Gold, aber auf die linke Seite machen.“ Das
Tier steht jetzt oben links auf der Startseite, auf einer Höhe mit
Level-Ring und Gold, ohne Holzrahmen; die Marke mit seinem Level hängt
daneben, ein Tipp öffnet weiter sein Blatt. „Heute“ rückt dafür nach
oben.

**Ohne Rückfrage entschieden:** Die **Wahl der Eier bleibt eine Karte**
über „Heute“ — drei Eier passen nicht in eine Zeile. Das Tier ist 80
Punkte groß: Bei 64 war ein junges Tier kleiner als der Ring daneben.
Der Gewohnheiten-Bildschirm zeigt die Leiste weiter ohne Tier.

In 390 × 844 gerendert und angesehen. **Nicht am Handy.**

## 24.10.2026: die Kreise tragen wieder ihre Namen

Frederik: „Uns ist aufgefallen, dass Nutzer der App die Intuitivität
beklagen.“ Zuerst nur Recherche, was Intuitivität im Game Design
ausmacht. Danach: „Die Texte unter den Kreisen können wir erstmal
wieder einführen.“

Die acht Kreise der Startseite tragen wieder ihren Namen darunter, wie
bis zum 23.10. Das entfernte ADR-0060 nicht: Dort sind die Namen der
Bereiche ausdrücklich ausgenommen („ein Kreis ohne Namen … ist Lesen mit
mehr Schritten“). Auch die Nielsen Norman Group sagt, ein Zeichen
braucht einen sichtbaren Namen, weil kaum eines eine feste Bedeutung
hat. Vier große Kreise mit Namen passen oben: Sie brauchen 352 Punkte,
und im Rahmen über die ganze Breite bleiben 358. Der Kasten des Mentors
lässt die 20 Punkte für die Namen frei. Ein Test prüft, dass jeder Kreis
seinen Namen zeigt.

### Offen: was die Intuitivität sonst kostet (Vermutungen, nicht gemessen)

- **23 Tooltips öffnen sich nur auf Tipp**, und nichts zeigt an, dass
  hinter einer Zahl ein Satz steht.
- **„Stufe“ meint mindestens vier Dinge**: die Grube, einen Skill, das
  Haustier und die Gegner der Sammlung. Dieselbe Grube heißt im Eingang
  „Ebene“ und drinnen „Stufe“.
- **Rund zehn Arten von Belohnung**, jede mit eigener Regel: Erfahrung,
  Gold, Ruhm, Theoriepunkte, Schlüssel, Streak-Eis, vier Skills und die
  Tagesform.
- **Der Mentor schweigt nach dem ersten Sieg.** Lagerfeuer, Tagesgrube,
  Sets, Sammlung, Ultimate und Haustier erscheinen ohne Einführung.
- **Ob ein Neuer sagen kann, wie Häkchen in der Grube stärker machen**,
  weiß niemand.
- Vorschlag: fünf Neue beim ersten Spielen beobachten, laut denkend und
  ohne Hilfe — mit den Testern ab 26.10.

## 23.10.2026, ganz zum Schluss: das Haustier nur mit Level

Frederik schickte eine Skizze (das Tier, unten rechts eine kleine
Marke): „Bei Haustier nur Level drunter anzeigen“. Die Karte auf der
Startseite zeigt jetzt nur noch das Tier, mittig, und sein Level als
dunkle Marke unten rechts. **Name, Stufe und der Balken bis zum
nächsten Level** stehen nur noch im Blatt, das ein Tipp öffnet; der
Name bleibt für den Vorleser.

**Ohne Rückfrage entschieden:** Die Marke ist dunkel mit Holzkante,
nicht das Level-Abzeichen des Spielers — sonst stünden zwei gleiche
Abzeichen mit verschiedenen Zahlen auf einer Seite.

In 390 × 844 gerendert und angesehen. App 999, unverändert (ein Test
prüft jetzt Marke statt Name). **Nicht am Handy.**

## 23.10.2026, ganz zuletzt: Tagesaufgaben und „Heute“ als Anschlagtafel

Frederik: „Dailies als Tafel mäßig. Also mit so einem dunklen
Holzhintergrund und vielleicht den einzelnen Dailies als Steckbrief.
Bisschen wie ein Ankündigungsboard in einer Gemeinde“. Gebaut ohne
Fragerunde.

| Was | Wie |
|---|---|
| **Die Tafel** | dunkle, senkrechte Bretter mit Maserung und Nägeln im Holzrahmen der Karten — gezeichnet auf dem Raster der Bildpunkte, damit sie neben Rahmen und Planke nicht weich aussieht |
| **Das Schild** | eine Planke oben auf dem Rahmen, darauf Fahne und „1 / 3“ |
| **Steckbriefe** | je Aufgabe ein Blatt mit Messing-Reißzwecke, leicht schief, unten abgerissen: oben das Zeichen wie das Bild auf einem Steckbrief, darunter der Satz, Kästchen zum Ankreuzen, unter dem Strich die Belohnung |
| **Abholen** | ein Tipp aufs ganze Blatt; die Belohnung wird dafür zum braunen Knopf |
| **Abgeholt** | ein grüner Stempel mit Häkchen schlägt oben rechts aufs Bild, das Blatt wird dunkler; wer die Tafel öffnet, sieht ihn liegen |

**Ohne Rückfrage entschieden:** drei Blätter nebeneinander, auch wenn
heute nur zwei hängen (dann bleibt Platz); **Messing statt Rot** für
die Reißzwecken, weil Rot Gegner heißt; die Bretter dunkler als der
Rahmen, ihre Farben stehen in der Palette.

**Beim Ansehen gefunden** (gerendert in 390 × 844, auch am Feuer und
mitten im Stempeln):

- **Der Stempel schlug nie auf**: Beim Abholen fiel die Hülle des
  Knopfs weg, das Blatt baute sich neu und hatte den Stempel von
  Anfang an (`gotchas.md`). Ein Test hält es fest und fällt ohne die
  Korrektur um.
- Die Maserung hing unten aus dem Rahmen.
- „Hol nach, was gestern liegen blieb: …“ schnitt längere Namen ab;
  ein Blatt darf jetzt sieben Zeilen haben.
- **Der Titel „Lagerfeuer“ stand seit dem 18.10. in Tinte auf dem
  Nachthimmel** und war kaum zu lesen. Jetzt hell.

**Danach** (Frederik: „die Gewohnheiten aber eigentlich auch“), in
einer Fragerunde beide Male wie empfohlen: **„Heute“ auf der Startseite
ist jetzt auch eine Tafel**, jede Gewohnheit ein **Zettel
untereinander** — nicht als Steckbrief im Raster, damit „Wann“ lesbar
bleibt und Gekoppeltes eingerückt unter seinem Anker steht. Das Schild
trägt „Heute“, die Flamme der Tageskette und den Stand und führt wie
vorher der Kopf zu den Gewohnheiten. Abgehakt bleibt der Kreis, dazu
schlägt ein kleiner Stempel auf; Durchstreichen und das Zeichen des
Gebiets fallen auf erledigten Zetteln weg. Der Gewohnheiten-Bildschirm
bleibt, wie er ist — er wäre der nächste Block.

**Beim Rendern gefunden — ein Fehler seit ADR-0079:** Der Ring des
Mentors um „Heute“ fiel nach dem ersten Häkchen weg, und dabei baute
sich die ganze Karte neu. Beim allerersten Häkchen überhaupt sprang
deshalb der Kreis nicht auf und die Flamme zündete nicht; jetzt läge
der Stempel sofort da. Der Ring blendet jetzt aus, statt wegzufallen
(`ZeigeRing.sichtbar`); ein Test fällt ohne die Korrektur um.

App 999 (vorher 997). Startseite mit vier Gewohnheiten, einer
gekoppelten und zwei erledigten in 390 × 844 gerendert und angesehen.
**Nicht am Handy.**

### Offen

- **Der Gewohnheiten-Bildschirm** als Tafel — eigener Block, wenn die
  Startseite gefällt.
- Ein kleines Dach über der Tafel, wie am Gemeindehaus — wenn sie noch
  mehr nach Dorf aussehen soll.
- Ob drei schmale Blätter am Handy lesbar sind (zwölf Punkte Schrift).
- „Heute“ ist höher als vorher: Mit fünf Gewohnheiten rollt die
  Startseite früher.

## 23.10.2026, abends: die Seite ist ein Buch

AktivesBrett: „wenn man sich eine Seite bei Theorie durchliest, kannst
du so machen, dass die Seite aussieht wie eine Seite aus einem Buch und
auch so eine Animation hat, wenn man auf die nächste Seite geht oder
eben eine Seite zurück … und der Text erscheint ja so smooth und
stückweise, das bitte beibehalten.“ In zwei Fragerunden entschieden,
viermal wie empfohlen, einmal dagegen.

| Was | Wie |
|---|---|
| **Umblättern** | das Blatt dreht sich in 3D am Rücken (linker Rand), die freie Kante kommt dem Auge entgegen, es dunkelt und wirft einen Schatten auf die Seite darunter |
| **Steuerung** | der Finger zieht das Blatt mit — halb losgelassen fällt es zurück, ein schneller Wisch schlägt um; nach rechts legt sich die vorige Seite wieder darüber; „Weiter“ blättert per Animation |
| **Buch** | **ein aufgeschlagenes Buch**: ein Ledereinband mit eingeprägter Linie, darin das Blatt, rechts und unten die Kanten der übrigen Seiten, links wölbt sich das Papier in den Rücken |
| **Papier** | heller als das Pergament, cremefarben, mit Fasern und Flecken (`Palette.papier`) |
| **Klang** | ein Rascheln mit leisem Klapp, gerechnet (`tool/lern_klaenge.py`), dazu ein leichtes Tippen |
| **Zu den Fragen** | „Fragen beantworten“ schlägt das letzte Blatt auf ein leeres um, dann kommen die Fragen wie bisher |
| **Der Text** | schreibt sich weiter Wort für Wort — **sobald das Blatt liegt**; zurückgeblättert steht er ganz da |

**Ohne Rückfrage entschieden:** Das Blatt schlägt bis 90° um und steht
dann auf der Kante, statt auf die linke Seite hinüberzufallen — am
Handy gibt es links keine zweite Seite. Die Striche oben bleiben, eine
Seitenzahl oder Initiale kam nicht dazu (nicht gewählt). Wer Bewegung im
System abgeschaltet hat, blättert ohne Animation.

**Erst Papier über den ganzen Bildschirm**, so gewählt — gegen Claudes
Empfehlung, ein Blatt auf Leder. AktivesBrett danach am Bildschirm:
„sieht halt noch nicht aus wie eine Buchseite“. In einer zweiten Runde
gewählt: das aufgeschlagene Buch und helleres Papier mit Struktur;
Buchschrift, Seitenzahl und Initiale nicht.

Neu: `lib/theory/widgets/umblaettern.dart`, `assets/Sound/Blaettern.wav`,
`test/buchseite_test.dart` (5). Der `PageView` der Häppchen ist weg. App
997 (vorher 991). Ruhend, mitten im Umblättern und halb zurückgezogen
in 390 × 844 gerendert und angesehen. **Nicht gehört, nicht am Handy.**

### Offen

- Wie das Rascheln klingt — und ob es nach zwanzig Seiten nervt.
- Ob die Perspektive am Handy-Browser flüssig läuft.
- Frederik hat es nicht gesehen.

## 23.10.2026: die Statistik (#139)

AktivesBrett: das Statistik-Ticket — Issue #139: „Claude mach einfach
geilen scheiß, mit Monat Jahr und Wochenansicht mindestens und bau bitte
noch ein paar coole Graphen ein und so.“ In vier Fragerunden entschieden:
[ADR-0087](../decisions/0087-die-statistik.md).

| Was | Wie |
|---|---|
| **Wo** | ein eigener Kreis, oben als vierter großer, **mit dem ersten Häkchen** |
| **Zeiträume** | Woche, Monat, Jahr, Gesamt — mit Blättern zurück, nie über heute hinaus |
| **Quote** | erledigt durch fällig nach dem Plan, der damals galt; Ruhetage grau, Streak-Eis blau, zählt nicht als erledigt |
| **Vergleich** | ▲/▼ in Prozentpunkten gegen **die gleichen Tage davor**; schlechter gedämpft, nicht rot |
| **Graphen** | Kalender-Raster (Jahr wie bei GitHub), Balken, Kurve der Quote mit der Kette, Wochentage mit dem stärksten in Gold, ein Ring je Gewohnheit |
| **Je Gewohnheit** | ein Tipp auf den Ring öffnet dieselbe Statistik für sie; mit Ziel auch Summe und Schnitt |
| **Rekorde** | längste Kette, perfekte Wochen, bester Monat, meiste Häkchen an einem Tag, Häkchen insgesamt |
| **Jahresrückblick** | baut sich auf, vom 20.12. bis 7.1. angekündigt, sonst ein Knopf in der Jahresansicht |
| **Bewegung** | beim Öffnen und Blättern wachsen die Balken, die Kurve zeichnet sich, die Kästchen füllen sich |

**Gegen Claudes Empfehlung:** der Kreis oben (statt unten als fünfter
kleiner), ab dem ersten Häkchen (statt nach sieben Tagen) und **fl_chart**
(statt selbst zeichnen). Das Raster ist trotzdem gezeichnet: fl_chart hat
keins.

**Ohne Rückfrage entschieden:** Ein bester Monat braucht sieben fällige
Tage, die Gewohnheit des Jahres vierzehn. Ein Tipp aufs Raster zeigt den
Tag darunter, statt 365 Tooltips zu bauen.

**Beim Mergen:** Auf `main` stehen die Kreise seit heute ohne Namen in
zwei Holzrahmen vor dem Berg. Damit passen vier große oben ohne
Verkleinerung; die Rechnung dafür ist wieder weg.

**Beim Ansehen gefunden** (gerendert in 390 × 844 mit echter Schrift): Im
Jahresraster standen die Monate als Kästchen — der Maler nahm nicht die
Schrift der App (`gotchas.md`); an der Jahreskurve stand „JJ“, und
„100 %“ brach um.

**Eine Lücke, die bleibt:** Auf einem erledigten Tag steht bei Mengen das
Ziel, nicht mehr — beim Abhaken fällt der Zähler weg. Wer 40 statt 20
Minuten las, steht mit 20 da.

Neu: `packages/habits/lib/src/statistik.dart`, `lib/statistik/` (sechs
Dateien), `statistik_test.dart` (21), `test/statistik_screen_test.dart`
(10), fl_chart 1.3.0. App 991 (vorher 981), habits 366 (vorher 345).
Alle Zeiträume, eine Gewohnheit, die Ankündigung, der Jahresrückblick und
die Startseite gerendert und angesehen. **Nicht gespielt, nicht am
Handy.**

### Offen

- **Frederik hat ADR-0087 nicht gesehen** — es gibt jetzt acht Kreise.
- AktivesBrett hat ADR-0084, -0085 und -0086 von Frederik nicht gesehen
  (die Niederlage nimmt, Skills je Gebiet, das Haustier für alle).
- Mengen über dem Ziel werden nicht gespeichert.
- Wie schnell der Jahresrückblick bei Jahren voller Daten rechnet, ist
  nicht gemessen.

## 23.10.2026, zuletzt: die Kreise ohne Namen

Frederik: „ich würde die texte unten den buttons entfernen“. Die sieben
Kreise der Startseite tragen nur noch ihr Zeichen (ADR-0060: die App
geht ohne Lesen). Der Name bleibt für den Vorleser und als Schlüssel
für Tests (`HubCircle.keyFor`); 16 Tests suchen den Kreis jetzt darüber
statt über den Text.

**Danach** (Frederik: „dass die Button mit den Holzrahmen unten und oben
abschließen … Sie sollen sozusagen unten und oben einen rahmen bilden“):
Die beiden Holzrahmen gehen jetzt über die ganze Breite und sitzen
bündig am oberen und unteren Rand; hinter Statusleiste und Gestenleiste
des Handys liegt nur Holz (`_Leiste` mit `SafeArea` innen). Level und
Gold stehen darunter, rechts über „Heute“. Der Kasten des Mentors lässt
jetzt auch oben Platz (`MentorFlaeche.obenFrei`).

In 390 × 844 gerendert und angesehen, auch mit Statusleiste. App 981, unverändert. **Nicht am
Handy.** Offen: ob Laden und Kampf ohne Namen zu erkennen sind — ein
neuer Spieler sieht beide zum ersten Mal ohne Wort.

## 23.10.2026, danach: der Berg hinter der Startseite

Frederik schickte ein Bild (ein verschneiter Berg, Pixelart): „können
wir das als Hintergrund für den Startscreen nehmen, vielleicht mit
bisschen weniger transparenz? Und außerdem fände ich so eine Art
Holzrahmen um die Button gruppen oben und unten cool“.

| Was | Wie |
|---|---|
| **Hintergrund** | `assets/UI/Berg.jpg`, aus Frederiks Bild: unten der dunkle Streifen abgeschnitten, auf 880 × 1017 verkleinert (4,7 MB → 170 KB); füllt den Bildschirm, mittig beschnitten |
| **Schleier** | ein Viertel Leder darüber (`HomeScreen.bergSchleier`), damit Karten davor stehen |
| **Holzrahmen** | `HolzGruppe` um die drei Kreise oben und die vier unten: der Rahmen der Karten, innen abgedunkeltes Holz statt Pergament |
| **Rand** | die Startseite hat seitlich 12 statt 20 Punkte, sonst passten die vier unteren Kreise samt Rahmen nicht |

**Ohne Rückfrage entschieden:** „weniger Transparenz“ gelesen als: der
Berg kräftig, nur leicht abgedunkelt. Wer ihn heller oder dunkler will,
dreht an `bergSchleier` (0 bis 1).

In 390 × 844 gerendert und angesehen. App 981, unverändert. **Nicht am
Handy.**

### Offen

- Die Herkunft des Bildes steht nur hier: Frederiks Datei vom Desktop.
- Andere Bildschirme liegen weiter auf Leder.

## 23.10.2026: das Haustier für alle

Frederik: „ich hätte gerne das haustier auf der normalen edition“.
[ADR-0086](../decisions/0086-das-haustier-fuer-alle.md).

| Was | Wie |
|---|---|
| **Startseite** | die Karte des Tiers über „Heute“ in jeder Fassung, auch im Store-Build |
| **Wann** | erst, wenn es eine Gewohnheit gibt — vorher fragt die Startseite nach ihr, und der Mentor zeigt darauf |
| **Vorspulen** | bleibt im Entwicklermodus |

**Ohne Rückfrage entschieden:** „erst mit der ersten Gewohnheit“, damit
die drei Eier nicht neben der ersten Frage des Mentors stehen.

App 981 (vorher 980): ein Test, dass ein leerer Stand kein Ei zeigt.
**Nicht gespielt, nicht am Handy, nicht gerendert.**

### Offen

- **AktivesBrett hat es nicht gesehen** — es geht jetzt mit in den
  Tester-Build am 26.10.
- Zubehör zieht im Store-Build echtes Gold ab; `runway_sim` zählt es
  nicht.
- Ob „Heute“ mit der Karte darüber zu tief rutscht.

## 22.10.2026, zuletzt: Level und Gold oben rechts, der Balken als Ring

Frederik: „ich hätte glaube gerne das Level und Gold beim Startbildschirm
oben rechts und vielleicht der Levelbalken als Kreis darum.“ Gebaut ohne
Fragerunde.

| Was | Wie |
|---|---|
| **Oben rechts** | das Level-Abzeichen in einem Ring, der sich mit der Erfahrung bis zum nächsten Level füllt, daneben das Gold — über den Kreisen |
| **Der Ring** | die Funken eines Häkchens fliegen hinein; ein Tipp sagt, wie viel noch fehlt |
| **Das Gebiet** | der grüne Balken blendet beim Häkchen links neben dem Ring ein (ADR-0085) |
| **Weg** | die Leiste als Karte zwischen den Kreisen und „Heute“; „Heute“ und das Haustier rücken nach oben |
| **Gewohnheiten** | oben dieselbe Zeile, damit beide Bildschirme gleich aussehen |

Startseite und Gewohnheiten in 390 × 844 gerendert, auch mitten im Flug.
Ein Test hält fest, dass der Ring rechts und über den Kreisen steht. App
980 (vorher 979). **Baut auf #149 (Haustier) auf. Nicht am Handy.**

## 22.10.2026, spät: ein Haustier — Prototyp im Entwicklermodus

Frederik: „Nicht jede Spielergruppe will sich über den Kampf vergleichen.
Wir brauchen andere Möglichkeiten Fortschritt zu zeigen wie z.B.
Haustiere … oder zum Beispiel ein eigenes Haus oder Dorf was ausgebaut
werden kann.“ In zwei Fragerunden entschieden, siebenmal wie empfohlen,
einmal dagegen (drei Eier statt eines Drachen). Das Konzept steht in
[`docs/vorlagen/haustier.md`](../vorlagen/haustier.md); **der ADR kommt,
wenn ihr beide es gespielt habt.**

| Was | Wie |
|---|---|
| **Drei Eier** | Drache, Eule, Katze — gewählt wird einmal, über „Heute“ auf der Startseite |
| **Wachsen** | an Tagen mit Häkchen, nie zurück: Level 2 nach 1 Tag, 10 nach 45, 27 nach 351; sechs Stufen vom Ei bis „Uralt“ |
| **Laune** | schläft nachts, wartet ohne Häkchen, munter mit einem, spielt „In Form“, ruht am Ruhetag — **es leidet nie** |
| **Sprung** | mit jedem Häkchen von heute |
| **Prägung** | ab „Ausgewachsen“ das stärkste Gebiet: Stirnband, Punkt, Brille oder Herz (ADR-0085) |
| **Zubehör** | zehn Stücke auf drei Plätzen, sieben für Gold (25 bis 120), drei an Stufen verdient |
| **Gold** | Zubehör ist der zweite Abfluss: Leiste und Laden der Ausrüstung ziehen es ab |

**Nur im Entwicklermodus** (`devModeAvailable`): im Debug-Build und in
der Entwicklerfassung unter `/LifesGame/dev/`. Der Store-Build kennt es
nicht. Im Blatt lassen sich dort Tage vorspulen, um spätere Stufen
anzusehen; gespeichert wird davon nichts.

**Das Bild ist gezeichnet** (Formen, nicht Pixel), damit es atmen,
blinzeln, schlafen und springen kann. **Beim Ansehen gefunden:** Die
Prägung am Kopf lag hinter dem Kopf, und die „Z“ des Schlafs erschienen
als Kästchen — jetzt Linien.

Neu: `packages/haustier` (21 Tests), `lib/haustier/` (vier Dateien),
`test/haustier_test.dart` (12). App 979 (vorher 967). Alle Arten und
Stufen, die Startseite und das Blatt in 390 × 844 gerendert und
angesehen. **Nicht gespielt, nicht am Handy.**

### Offen

- **Spielen**, dann der ADR — und ob es in den Store-Build geht.
- **AktivesBrett hat es nicht gesehen.**
- Zubehör konkurriert mit Ausrüstung um Gold; `runway_sim` zählt es
  nicht.
- Ein Grafikpaket mit drei Tieren in sechs Stufen — oder gezeichnet
  bleiben.
- Das Haus als sein Zuhause ist der nächste Schritt.

## 22.10.2026, abends: Skills je Gebiet — was bleibt, wenn die Kette fällt

Frederik: „Jemand der 30 Tage eine Streak aufrecht erhält hat ein
höheres Gefühl als jemand der 100 mal 25 Tage Streaks hatte … So hat
Sport seinen eigenen Skill in welche Theorie einzahlen als auch die
Gewohnheiten die dazu passen. Dadurch kann sich mehr mit anderen
verglichen werden und wir verlieren keine Spieler nachdem sie eine 300
Tage Streak verloren haben.“ In zwei Fragerunden entschieden, siebenmal
wie empfohlen, einmal dagegen:
[ADR-0085](../decisions/0085-skills-je-gebiet.md).

**Der Befund vorher:** Eine verlorene 300-Tage-Kette kostete schon keine
Erfahrung (300 → 60, ×2 blieb), weh tat nur die Zahl auf der Kachel. Ab
Tag 60 brachte eine längere Kette nichts mehr, und bei Level 50 ist nach
188 bis 240 Tagen Schluss.

| Was | Wie |
|---|---|
| **Vier Skills** | Körper, Geist, Wissenschaft, Gesellschaft — die Wurzeln des Baums; 1 bis 100, wachsen nur |
| **Was einzahlt** | Häkchen (mit Kette und Grad), bestandene Seiten des Gebiets, richtige Rückfragen; das Level bekommt alles weiter |
| **Die Kette** | wächst über 60 Tage weiter: 100 Tage ×2,2, 180 ×2,4, 365 ×2,6 |
| **Titel** | je Gebiet drei, bei 10, 25 und 50 — zwölf neue, im Reiter „Gebiete“ der Errungenschaften |
| **Vorne steht der Skill** | auf der Kachel Zeichen und Stufe, darunter die Flamme mit dem Bonus; die Tage am Stück im Tipp, dazu die Tage gesamt |
| **Charakter** | Gesamtlevel, die vier Skills, ein Teilen-Knopf — über der Kette |
| **Baum** | der Skill des Gebiets neben seinem Namen |
| **Alte eigene Gewohnheiten** | fragen **einmal** nach ihrem Gebiet, auf der Startseite über „Heute“ — **gegen Claudes Empfehlung** (aus dem Wert ableiten) |

**Danach, auf Frederiks Wunsch** („eine Animation und besser
ausgeschildert, dass … XP zu dem Charakter Level und Level des Gebietes
dazu kommt“): Die Funken eines Häkchens teilen sich, ein Strom fliegt zum
Level, ein grüner zum **Balken des Gebiets**, der dafür unter dem
Level-Balken einblendet und danach verblasst. Unter „+33 EP +5 G“ steigt
grün „+33 EP Körper“ auf, die Kachel nennt die Erfahrung zweimal, und
„Heute“ trägt rechts das Zeichen des Gebiets. **Der Gewohnheiten-
Bildschirm hat jetzt oben die Leiste** — die Lücke vom 18.10. ist zu.

**Gemessen** (eine Gewohnheit täglich, ohne Seiten): Skill 10 nach 50
Tagen, 25 nach 159, 50 nach 425, 100 nach 1307. Durch die neuen
Kettenstufen kommt **Level 50 früher**: fünf Vorlagen nach 223 Tagen
statt 240, fünf „schwere“ nach 179 statt 188. Bis Tag 60 ändert sich
nichts. Die Errungenschaften zahlen über ein Spielerleben 2880 Erfahrung
und 960 Gold statt 1860 und 620 — über Jahre verteilt.

**Ohne Rückfrage entschieden** (die ganze Liste im ADR): die zwölf
Titelnamen; ein eigener Reiter „Gebiete“; eine Seite in zwei Gebieten
zählt für beide Skills; das Gebiet einer eigenen Gewohnheit steht ab dem
Anlegen fest; Grün als Farbe der Gebiete.

**Beim Ansehen gefunden** (gerendert in 390 × 844, auch mitten im
Flug): Auf der Kachel mit Timer standen beide Erfahrungszahlen als
„+…“; die Zeile schrumpft jetzt als Ganzes.

Neu: `skill_area.dart`, `skill_curve.dart`, `lib/skills/` (acht
Dateien), `skill_area_test.dart`, `skill_curve_test.dart`,
`area_xp_test.dart`, `test/skills_test.dart`. App 967 (vorher 951),
habits 345 (333), theory 208 (204), progression 52 (44), achievements
25 (24). **Nicht gespielt, nicht am Handy, nicht gehört.**

### Offen

- **Die Namen der zwölf Titel** sind Claudes Vorschlag — gegenlesen.
- **AktivesBrett hat ADR-0085 nicht gesehen**: Die Kachel zeigt jetzt
  den Skill statt der Tage, und der Kettenbonus geht bis ×2,6.
- Ob der Balken des Gebiets am Handy lesbar ist — Name und Stufe stehen
  in zehn Punkten.
- Ob Skill 10 nach 50 Tagen zu langsam ist; mit Seiten geht es schneller.
- Vergleichen geht nur über den kopierten Text. Eine Rangliste braucht
  einen Server.

## 22.10.2026: die Niederlage nimmt — und zeigt drei Wege

Frederik: „wenn man einen Lauf verliert [soll] man kein Gold und kein XP
und keine Items bekommen. Stattdessen … eine Animation wie diese Sachen
einem wieder weggenommen werden und vielleicht 3 Tipps wie man seinen
Charakter stärker machen kann.“ In zwei Fragerunden entschieden: [ADR-0084](../decisions/0084-die-niederlage-nimmt.md).

| Was | Wie |
|---|---|
| **Nur ein Sieg zahlt** | dann den ganzen Topf; eine Niederlage bucht nur, dass verloren wurde. Bis dahin behielt sie, was gefallen war (ADR-0041) |
| **Items** | was in der Grube eingesammelt wurde (ADR-0083, seit dem 21.10.), fliegt mit weg und kommt nicht in den Rucksack; **gegen AktivesBretts Entscheidung** dort („man behält sie“), auf Frederiks Wunsch |
| **Schlüssel** | öffnen den Extra-Wurf **nur noch nach einem Sieg** (ADR-0083: nach jedem Lauf) |
| **In der Grube** | die Kasse zählt herunter und glüht rot, der Balken läuft zurück, ein Aufstieg im Lauf fällt ab, Münzen und Funken springen vom Helden weg und verlöschen; dazu der Ton einer falschen Antwort. Erst dann kommt das Blatt |
| **Drei Tipps** | aus dem Stand: leerer Fähigkeitsplatz, Besseres im Rucksack, freie Punkte, Häkchen bis In Form, Besseres im Laden; sonst allgemeine Sätze. Jeder ein Knopf in seinen Bereich, an die Stelle der Grube |

**Ohne Rückfrage entschieden:**

- **Alte Teilbeute bleibt**: Was ein Stand in verlorenen Läufen schon
  gesammelt hat, ist längst Erfahrung; es zu streichen ließe ein Level
  fallen. Es wächst nur nicht mehr.
- **Die Tagesgrube bleibt, wie sie ist**: Sie zahlt nur Ruhm, antreten
  zählt.
- **Was sofort und umsonst hilft, steht vorn** (Platz, Rucksack), dann
  was kostet (Punkte, Häkchen, Gold). Nie zwei Tipps in denselben
  Bereich.
- **Das Buch nach dem ersten Lauf bleibt** neben „Nochmal“.

**Beim Mergen gefunden:** Während des Baus kam AktivesBretts Beute in
der Grube nach `main` (#145), mit eigenem ADR-0083 — daher ist dieser
ADR-0084. Frederik hat danach entschieden: Auch die Funde gehen, der
Schlüssel nur nach einem Sieg. ADR-0083 trägt den Vermerk.

**Beim Ansehen gefunden** (gerendert in 390 × 844): Der Balken wurde
beim Zurücklaufen weiß statt rot; jetzt glüht auch die Füllung rot.

Neu: `staerker_werden.dart`, `staerker_werden_provider.dart`,
`test/staerker_werden_test.dart`. App 951 (vorher 934), action_combat
406 (vorher 407: zwei Tests zur Teilbeute wurden einer). Blatt und Grube
mitten im Nehmen gerendert und angesehen, die Grube mit Würfeln. **Nicht
gespielt, nicht am Handy, nicht gehört.**

### Offen

- **Verlieren ist jetzt teurer**: Wer eine Stufe oft versucht, bekam
  den Topf bisher über alle Läufe verteilt. `runway_sim` rechnet nur
  mit Siegen und merkt davon nichts.
- Ob 1,4 Sekunden Nehmen plus Ausklingen zu lang sind, wenn man nur
  „Nochmal“ drücken will.
- **AktivesBrett hat ADR-0084 nicht gesehen** — und dass seine
  Entscheidung „eingesammelt bleibt“ damit gekippt ist.

## 21.10.2026, nachts: der Entwicklermodus bekommt Kampfwerte, Ebenen und eine Werkbank

AktivesBrett: „dass man sich Stats geben kann … und dass man zu einem
bestimmten Level vorspringen kann und dass man in dem Level Items und
Gegner beschwören kann … ich möchte testen, wie Legendarys aussehen,
ohne die ganze Zeit Gegner töten zu müssen, und schauen, wie viel
Schaden ich an bestimmten Gegnern mache.“

| Was | Wie |
|---|---|
| **Kampfwerte** | Knöpfe für Angriff, Leben, Abwehr und Mana im Dev-Bildschirm; im Kampfmassstab wie der Wurf eines Stücks, danach mal Level, Seltenheit und Tagesform. Oben steht, was der Held im Kampf hat |
| **Ebene wählen** | Feld „Ebene“ mit **Hinab** (ein Lauf dort, die Reihe bleibt, Beute fällt) und **Dorthin** (die Reihe so gesetzt, dass die Ebene die nächste ist) |
| **Werkbank in der Grube** | ein Kolben oben rechts hält den Lauf an und öffnet ein Blatt: ein Fund jeder Seltenheit vor den Helden, ein Gegner jeder Art zwei, drei Felder in Blickrichtung |

**Ohne Rückfrage entschieden:**

- **Die Werkbank gibt es nur auf dem Dev-Stand** (ADR-0021): Was sie
  legt, landet beim Einsammeln im Rucksack, und erfundene Beute gehört
  nicht in den echten Stand. Wer sie nicht sieht, schaltet im
  Entwicklermodus auf den Dev-Stand um.
- **Der Wächter lässt sich nicht beschwören** — sein Verhalten hängt
  daran, dass es genau einen gibt und er in seinem Raum steht.
- **Ein beschworener Gegner ist ein ganz normaler**: Werte der Stufe,
  zählt für die Sammlung, lässt Beute fallen.
- **„Dorthin“ zahlt, was darunter liegt**, weil die Reihe ihre
  Belohnung aus der höchsten Stufe ableitet; zurückspringen nimmt es
  wieder weg. Nur im Dev-Stand gedacht, gesperrt ist es nicht.
- **Ein gewünschter Fund würfelt trotzdem** Platz und Werte — nur die
  Seltenheit steht fest (`GearLoot.cascade(rarity:)`).

Neu: `packages/action_combat/lib/src/entwickler.dart`,
`lib/dev/grube_werkbank.dart`, `entwickler_test.dart` (6),
`test/grube_werkbank_test.dart` (2). App 934 (vorher 929),
action_combat 407 (vorher 401), gear 137 (vorher 136). **Nicht im
Browser angesehen, nicht gespielt.**

## 21.10.2026, ganz zuletzt: die Würfel hingen zusammen, die Säule ist ein Strahl

AktivesBrett: „in einem Level habe ich 3 Legendarys bekommen und in den
nächsten 5 nicht mal ein Lilanes. Irgendwas scheint da nicht richtig zu
sein“ — und die Säule über Legendärem soll „viel größer, heller und
dünner“ sein.

**Es war ein Fehler.** Jeder Fund hatte seinen eigenen Würfel mit einem
Startwert im gleichen Abstand zum vorigen, und der Würfel ist linear:
Die Funde eines Laufs fielen gemeinsam (`gotchas.md`). Gemessen über
4000 Läufe mit sechs Funden auf Ebene 22:

| Legendäre je Lauf | erwartet | vorher | jetzt |
|---|---|---|---|
| keins | 74 % | 90 % | 74 % |
| eins | 23 % | 1 % | 23 % |
| zwei | 3 % | 1 % | 3 % |
| drei | 0,2 % | 8 % | 0,1 % |

Die Gewichte selbst stimmten und bleiben: auf Ebene 20 bis 30 je Fund
5 % legendär und 15 % episch, auf 10 bis 19 7 % episch, darunter weder
noch; der Wächter würfelt eine Stufe höher. **Der Laden hatte dasselbe**,
schwächer: Tage mit nur zwei Seltenheiten kamen doppelt so oft. Behoben
ist es im Würfel selbst (`GearDice` mischt den Startwert), deshalb
**sieht der Laden heute andere Angebote** als vor dem Update.

**Die Säule** ist jetzt 420 Punkte hoch statt 140, ein weißgoldener
Kern von gut zwei Punkten in einem schmalen goldenen Schein, voll bis
über die Hälfte. Gerendert und angesehen.

gear 136 (vorher 133): der Würfel rechnet im Browser wie in der VM
(auch mit `dart test -p chrome` geprüft), Funde eines Laufs und Angebote
eines Tages hängen nicht zusammen. **Nicht gemessen:** Tagestruhe,
Tagesaufgaben und Tagesgrube säen ihre Würfel auf dieselbe Art.

## 21.10.2026, zuletzt: Lebensraub am ganzen Schlag, Funde ein Feld groß

AktivesBrett nach dem Spielen: „beim Life steal ist es wichtig, das ich
auch wirklich so viel schaden mache wie ich kann und nicht nur wie die
Gegner Leben haben“ — mit dem Vampirset heilte man sich teils nicht
genug. Und die Funde am Boden sollen größer sein.

| Was | Wie |
|---|---|
| **Lebensraub** | rechnet am **ungekappten** Schlag: 2000 auf einen Gegner mit 200 raubt aus 2000. Beim Blutpakt auch der Schaden aus dem Raub |
| **Funde am Boden** | der Umriss 32 Punkte, ein Feld und die Hälfte der 64er-Zeichnung; der Rahmen 36 mit zwei Punkten Luft (vorher 14 und 18) |

In einer Frage entschieden: ein Feld groß statt 64 Punkte, und weiter
der Umriss in der Farbe der Seltenheit statt der echten Zeichnung.

**Gemessen** (`pit_sim ausruestung 40`, Stufe 13, Sichel): ein Teil
45 % (vorher 43 %), zwei Teile 63 % (63 %), **alle vier 55 %
(vorher 28 %)**. Der Blutpakt ist damit nicht mehr schwächer als zwei
Teile ohne Preis — knapp darunter. Die übrigen Kräfte unverändert.

action_combat 401 (vorher 400): ein Test, dass ein angeschlagener
Gegner denselben Raub bringt. Ein alter Test ging davon aus, dass der
Raub allein nie mehr als drei Prozent heilt; er vergleicht jetzt mit
demselben Lauf ohne Kill-Heilung. Die Funde in Stufen gerendert und
angesehen. **Nicht gespielt.**

## 21.10.2026, danach: das Siegerblatt und Verkaufen mit Häkchen (Block 2 von #136)

AktivesBrett: „ok mach block 2“. Gebaut nach der Skizze im Ticket und
den Antworten aus den Fragerunden zu
[ADR-0083](../decisions/0083-beute-in-der-grube.md).

| Was | Wie |
|---|---|
| **Die Funde drehen sich um** | erst liegt jeder da wie am Boden — der Umriss seines Platzes in der Farbe der Seltenheit —, dann dreht sich eine Kachel nach der anderen, **das Seltenste zuletzt**, mit Klang; Legendäres mit seinem eigenen und einem goldenen Schein |
| **Pfeil gegen das Getragene** | grün hoch, rot runter, braun gleich — wie im Rucksack |
| **Antippen** | öffnet das Blatt des Stücks: anlegen, sperren, alle Werte |
| **Häkchen** | ein Knopf schaltet auf Auswahl; ein Tipp setzt ein Häkchen, „Verkaufen“ zeigt Anzahl und Gold der Auswahl, mit Rückfrage. **Dasselbe im Rucksack** der Ausrüstung |
| **Am Boden** | statt eines Zeichens der Umriss eines Schwerts, Stiefels, Rings … in der Farbe der Seltenheit |

**Ohne Rückfrage entschieden:**

- **Der beste Fund springt nur noch beim ersten Sieg überhaupt auf.**
  Das Siegerblatt zeigt jeden Fund mit Pfeil, ein Dialog danach sagte
  dasselbe noch einmal; beim ersten Sieg erklärt er, was eine Truhe ist.
- **Kein Häkchen auf Angelegtem und Gesperrtem**, dort steht auch kein
  Kreis. Verkauftes verschwindet aus dem Siegerblatt.
- **Der Umriss ist ein gewöhnliches Stück des Platzes**, ganz in der
  Farbe der Seltenheit gefüllt (`GearIcons.gruppeFor`) — man sieht
  „ein Schuh“, nicht welcher.
- **Beim Ziehen im Rucksack** gilt: Solange die Auswahl an ist, zieht
  man nichts auf einen Platz.

Neu: `lib/gear/verkauf_auswahl.dart` (die Regel, reine Rechnung),
`lib/gear/widgets/verkauf_leiste.dart`,
`lib/combat/widgets/siegerblatt_funde.dart`,
`test/verkauf_mit_haekchen_test.dart` (10). App 929 (vorher 919). Das
Siegerblatt in 390 × 844 gerendert und angesehen, mitten im Aufdecken
und mit Auswahl; dabei gefunden: Angelegtes trug einen leeren Kreis,
und ein Laufmännchen stand für Schuhe. **Nicht gespielt, nicht am
Handy.**

### Offen

- Ob das Aufdecken (gut eine Sekunde Vorlauf, dann ein Drittel Sekunde
  je Kachel) bei sechs Funden zu lang ist.
- Der Rucksack hat keine Grenze; ob Verkaufen mit Häkchen reicht,
  zeigt das Spielen.
- Frederik hat ADR-0083 nicht gesehen.

## 21.10.2026: Beute in der Grube — die Kaskade (Block 1 von #136)

AktivesBrett: „ich möchte das Ticket 136 Loot System angehen“. Das
Ticket: Items fallen in der Grube, nicht nur am Ende; Legendäres sticht
hervor; am Boden nur die Gruppe mit dem Rand der Seltenheit, am Ende
das Stück; ein „Cascading Drop System“. Dazu eine Skizze des
Siegerblatts und ein Bild aus Summoners War (Verkaufen mit Häkchen). In
vier Fragerunden entschieden:
[ADR-0083](../decisions/0083-beute-in-der-grube.md). Gebaut in zwei
Blöcken; dies ist der erste.

| Was | Wie |
|---|---|
| **Die Kaskade** | Würfel in Stufen: *ob* (13 % je Gegner, 30 % bei zähen, der Wächter immer), welcher Platz, welche Seltenheit (Wächter eine Stufe höher), welches Stück |
| **Am Boden** | das Zeichen des Platzes im Rand der Seltenheit; Episches im violetten Schein, **Legendäres unter einer goldenen Lichtsäule** mit eigenem Klang |
| **Einsammeln** | hinlaufen; was am Ende liegt, ist weg; **eingesammelt bleibt auch nach einer Niederlage**; die Wächterbeute kommt von selbst |
| **Nach dem Lauf** | die Funde im Ergebnisblatt als Kacheln; nach einem Sieg springt der beste auf; dann fragt der **Schlüssel**: ein Extra-Wurf |
| **Tagesgrube** | wirft nichts |

**Gemessen** (`dart run tool/pit_sim.dart beute 40`, Tag 30): In
gewonnenen Läufen fallen auf Ebene 1 und 5 im Schnitt 4,3 Stücke, auf
Ebene 10 5,3 — das Ziel waren 4 bis 6. Der Bot läuft keinem Fund nach
und holt gut die Hälfte.

**Ohne Rückfrage entschieden:**

- **Die Grube kennt keine Ausrüstung**: Sie meldet nur die Nummer des
  Fundes, die App würfelt den Rest (`PitBeute`). Die Uid trägt den
  Startwert des Laufs, sonst wäre der zweite Lauf auf derselben Ebene
  am selben Tag schon „besessen“.
- **Ein eigener Würfel für die Beute**, damit sie keinen kritischen
  Treffer verschiebt (Test).
- **Gewürfelt wird beim Fallen**, damit Rand und Lichtsäule stimmen.
- **Der Schlüssel fragt nach jedem Lauf**, auch nach einer Niederlage.
- **Bis zum neuen Siegerblatt** springt nach einem Sieg der beste Fund
  auf (wie vorher die Wächterbeute) — dort legt man an.

Neu: `item_drops.dart`, `beute_in_der_grube_test.dart` (8),
`GearLoot.cascade` mit fünf Tests, `lib/action/pit_beute.dart`,
`beute_am_boden.dart`, `test/pit_beute_test.dart` (7), zwei Klänge
(`Fund`, `Legendaer`). `takeLoot` ist weg (`takeRunLoot`,
`takeKeyLoot`). App 919 (vorher 911), action_combat 400 (vorher 392),
gear 133 (vorher 128). **Nicht gespielt, nicht am Handy, nicht im
Browser angesehen.**

### Offen

- ~~**Block 2**~~ (gebaut, Eintrag darüber): das Siegerblatt nach der Skizze — Kacheln drehen sich um,
  das Seltenste zuletzt, Pfeil gegen das Getragene, Antippen öffnet das
  Blatt, **Häkchen und „Verkaufen“ mit dem Gold der Auswahl**; dazu das
  Verkaufen mit Häkchen im Rucksack.
- Ob vier bis sechs Stücke je Lauf den Rucksack zu schnell füllen.
- Werte, die mit der Tiefe wachsen (#115), sind nicht gebaut.
- Frederik hat ADR-0083 nicht gesehen.

---

Ältere Einträge: [`verlauf.md`](verlauf.md).
