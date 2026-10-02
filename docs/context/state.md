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

**Zuletzt aktualisiert:** 02.10.2026 · Frederik

---

## Übersicht: was steht

**Phase:** Testlauf (Ziel 7, 21.09.–20.10.2026). Alle Bauziele 1–6 und 8
sind erreicht; seit Teststart wurde trotzdem stark weitergebaut (siehe
„Offen“).

| Bereich | Stand | Wo nachlesen |
|---|---|---|
| **Gewohnheiten** | Vorlagen und eigene, **Wochenplan je Gewohnheit**, Streaks, **die fallen statt zu reißen**, **Tageskette**, Streak-Eis, Tagesform, Tagestruhe, **Tagesaufgaben**, Wochenrückblick, Auslöser „Wann machst du das?“, Startvorlage | ADR-0028, -0036, -0043, -0044, -0052, -0055, -0064 |
| **Startseite** | sieben Kreise, Level-Abzeichen und Gold in einer Zeile, „Heute“ zum Abhaken | ADR-0049, -0053, -0057, -0058 |
| **Wissensbaum** | vier Wurzeln, Zwischenebenen, 57 Knoten, 15 angekündigte Überschriften, ein Punkt je Knoten, Rückfrage des Tages, **falsche Antworten kommen noch einmal**, **Ring und Zähler an jedem Knoten, Gebietsbalken, „Weiterlesen“** | ADR-0019, -0045, -0050, -0051, -0055, -0056, -0061 |
| **Kampf** | die Grube: Echtzeit, 30 Stufen, gesteckte Räume, **elf Gegnerarten in gewürfelter Besetzung**, **vier Wächter, je Lauf gewürfelt**, Tor und Auftritt, Uhr, vier Dailies, Beute je Gegner | ADR-0039, -0040, -0041, -0046, -0062, -0063 |
| **Stärke** | Level und Seltenheit vervielfachen, Gewohnheiten addieren | ADR-0042 |
| **Ausrüstung** | Exemplare mit Würfen, Tagesladen, Beute mit Schlüsseln, Sets, Legendäre, Verkauf zu einem Viertel, **eigener Bereich mit allen 48 Stücken**, **Rahmen und Name in der Farbe der Seltenheit** | ADR-0029–0031, -0034, -0047, -0048, -0057 |
| **Fähigkeiten** | 19 Fähigkeiten und 8 Waffenzüge in der Grube, eigener Bereich mit allen Werten | ADR-0022, -0049 |
| **Errungenschaften** | 19 Meilensteine, 8 Entdeckungen, 13 Titel | ADR-0033 |
| **Speicher** | lokal im Browser, **als Text sicherbar** | ADR-0010, -0054 |
| **Prototyp** | das Dorf, nur im Entwicklermodus | — |

**Tests:** App 637, dazu die acht Packages (theory 174, habits 265, gear
117, action_combat 276, progression 42, abilities 36, identity 25,
achievements 24). **In der CI laufen nur die App-Tests** — der Umbau,
der alle prüft, wartet auf den `workflow`-Scope (Eintrag vom 27.09.).

## Offen, gesammelt

**Braucht euch beide:**

- ~~**Was der Testlauf misst.**~~ Entschieden am 27.09. (Frederik):
  **weiterbauen**. Der Testlauf ist damit ein Entwicklungsmonat; ob
  Ziel 7 neu formuliert wird, steht in `ziele.md` noch aus.
- **Das Dorf** statt der Kreise? Frederik lehnt es ab (Issue #88) und
  will stattdessen das **Haus** ausbauen (Möbel, Haustiere). Braucht
  AktivesBrett und einen ADR.

**Vor einer Veröffentlichung** (Durchsicht vom 02.10.). **Entschieden
am 02.10. (Frederik): Ziel ist eine Android- und iOS-App, aber erst
später — zuerst wird das Konzept weiter ausgebaut.** Store bleibt auf
der Sperrliste in `ziele.md`. Offen bis dahin: Datenverlust, Erinnerung und Android-App, der lange Weg
zum ersten Kampf, ~~nur tägliche Gewohnheiten~~ (gebaut, ADR-0064),
Lizenzen der Assets, Fremde als Tester. Die ganze Liste steht im Eintrag vom 02.10.

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
- `world.dart` (1.754 Zeilen), `tracker.dart` (1.557) und
  `action_game.dart` (1.024) liegen über der 800-Zeilen-Grenze.

**Bewusst zurückgestellt** (Frederik, 27.09.): die tägliche Erinnerung
(APK oder Web-Push) und die Identität im Wochenrückblick.

---

## 02.10.2026, zuletzt: Wochenplan, und Ketten fallen statt zu reißen

Der erste Konzeptpunkt aus der Durchsicht unten, in zwei Fragerunden mit
Frederik entschieden und gebaut:
[ADR-0064](../decisions/0064-wochenplan-und-kette-die-faellt.md).

| Was | Wie |
|---|---|
| **Wochentage je Gewohnheit** | sieben Kreise im Dialog „Wann machst du das?“; Standard jeden Tag. Was heute nicht dran ist, steht nicht in „Heute“ und lässt sich nicht abhaken |
| **Kette** | zählt erledigte fällige Tage; freie Tage tragen sie, verlängern sie nicht |
| **Verpasst** | die Kette fällt auf die Stufe darunter (45 → 30, 10 → 7, 7 → 3), jeder weitere verpasste Tag wieder eine. Gilt auch für die Tageskette |
| **Ruhetag** | nichts fällig: keine Truhe, keine Tagesform, die Tageskette steht still |
| **Ertrag** | jedes Häkchen zahlt wie bisher; wer seltener plant, bekommt weniger |
| **Stoppen** | Pause ab morgen, die Kette bleibt stehen, bis die Gewohnheit wieder läuft |
| **Planänderung** | gilt ab morgen; sofort nur, solange nichts abgehakt ist |

**Der Plan ist eine Historie** („ab Tag X gelten diese Wochentage“),
sonst schriebe jede Änderung Erfahrung und Level der Vergangenheit um.
Neu in `habits`: `plan.dart`, `streak_rule.dart`. In der App:
`weekday_picker.dart`, auf dem Gewohnheiten-Bildschirm ein Abschnitt für
Laufendes, das heute nicht fällig ist (ändern, stoppen), auf der
Startseite ein Zeichen für den Ruhetag.

**Ohne Rückfrage entschieden**, weil es sonst nicht aufgeht:

- **„Stufe darunter“ ist streng**: Wer genau auf 7 steht, fällt auf 3.
  Die Folge: Wer jeden zweiten Tag abhakt, hält seine Stufe, steigt
  aber nicht (8 → 7 → 8).
- **Die Tageskette bekommt dieselbe Regel.**
- **Eine heute gestoppte, offene Gewohnheit zählt heute weiter als
  fällig** — sonst wäre Stoppen der Knopf für die Truhe.
- **Alte Stände:** Was gestoppt war, pausiert seit dem Tag nach seinem
  letzten Häkchen. Frühere Lücken zählen rückwirkend als Rückfall, es
  gibt also etwas mehr Erfahrung als bisher, nie weniger.

**Gemessen** (`curve_sim`, 90 Tage, fünf Gewohnheiten): Der fleißige
Spieler bleibt bei 11.865 XP, „5 von 7 ohne Plan“ bei 4.980. Neu:
**Montag bis Freitag geplant 7.965**, **ein Tag je Woche fehlt 7.920**
(vorher 6.540). Die Obergrenze, auf die Levelkurve und Laden gerechnet
sind, bewegt sich nicht.

habits 265 (vorher 227), App 637 (vorher 625). Gewohnheiten-Bildschirm,
Dialog und Startseite gerendert in 390 × 844 und angesehen; dabei
gefunden und behoben: Der Auslöser wurde neben den Wochentagen auf drei
Wörter gekürzt, und sieben feste Kreise wären auf einem schmalen Handy
übergelaufen. **Nicht am Handy, nicht im Browser gespielt.**

### Offen

- **Eine Woche krank bleibt ein Totalverlust** (sechs verpasste Tage),
  wenn man nicht am Tag vorher stoppt. Frederik hat „jeder verpasste Tag
  eine Stufe“ gewählt; ob das im Alltag zu hart ist, zeigt das Spielen.
- **Verschieben geht nicht**: Montag geplant, Dienstag gemacht heißt
  Montag verpasst.
- An einem Ruhetag sind auch die Dailies der Grube zu (sie hängen an
  einem Häkchen).
- Die Kachel zeigt „noch 2“ bis zur nächsten Stufe; bei drei Tagen die
  Woche sind das Häkchen, keine Tage.
- Der Wochenrückblick kennt keinen Ruhetag.
- Wochentage wählt man erst im Dialog nach dem Anlegen, nicht im
  Formular einer eigenen Gewohnheit.
- `tracker.dart` ist auf 1.557 Zeilen gewachsen.

## 02.10.2026, danach: kritische Durchsicht vor einer Veröffentlichung

Frederik hat die neuen Gegner, Besetzungen und Wächter gespielt („ist
super“) und gefragt: Was hat die Konkurrenz voraus, und was demotiviert
Spieler, wenn das jetzt auf den Markt geht? **Entschieden ist nichts**,
das hier ist die Liste. Die Aussagen über Habitica, Duolingo und Finch
stammen aus Claudes Wissen, nicht aus frischer Recherche.

**Der Befund in einem Satz:** Es scheitert nicht am Spiel, sondern an
allem drumherum — ein gutes Spiel für zwei Erbauer, noch kein Produkt
für Fremde.

| Was der Konkurrenz voraus ist | Stand bei uns |
|---|---|
| Erinnerungen | keine; seit dem 27.09. zurückgestellt |
| Konto und Sync | Stand im Browser-Speicher, Sicherung als Text (ADR-0054); Browserdaten löschen heißt alles verlieren |
| Echte App | Web auf GitHub Pages, Android nicht eingerichtet, Startsymbol ist das Flutter-Logo, kein Widget, kein iOS |
| Soziales | nichts |
| Flexible Gewohnheiten | jede Gewohnheit ist täglich (`habit.dart`); „dreimal die Woche“ geht nicht, ein Ruhetag reißt die Kette |
| Sprache, Zugänglichkeit | nur deutsch, kein Übersetzungsgerüst; große Schrift auf der Sperrliste |
| Messung | keine Analytik, keine Absturzmeldungen |
| Politur | Level-Rahmen und Rüstung auf der Figur sind Platzhalter, neun Gegner und drei Wächter wippen nur |

**Was Spieler demotiviert:**

- **Der Weg zum ersten Kampf**: Handbuch, drei Knoten, anlegen. Wer
  wegen des Kampfs kommt, muss zuerst lesen.
- **Zu viele Systeme ohne Erklärung**: zwölf Dinge von XP bis
  Tagesladen, und seit ADR-0060 stehen fast nur Zeichen da.
- **Tägliche Pflichtlast**: Abhaken, Truhe, Aufgaben, Rückfrage, vier
  Dailies, Laden — alles verfällt um Mitternacht.
- **Kettenverlust**: Eis nur aus etwa jeder zwölften Truhe, deckt nur
  gestern. Eine Woche krank heißt alles weg.
- **Der Kampf verlangt Geschick**: Stufe 2 an Tag 0 bei 58 % für den
  Bot. Wer abgehakt hat und am Daumen scheitert, fühlt sich bestraft.
- **Der Inhalt endet**: Baum um Tag 50–58 gelesen, 30 Stufen zahlen
  einmal, Level 50 nach 188–240 Tagen.
- **Schummeln ist gratis**: Ein Häkchen ist eine Behauptung.

**Rechtlich offen:** Lizenzen der Asset-Pakete (Quelle und Urheber
fehlen in HERKUNFT), ungelesene Gesundheitsaussagen im Baum, und die
Gewohnheiten-Seiten folgen dem Aufbau von *Die 1%-Methode*.

**Was besser ist als bei den anderen:** Der Kampf ist ein echtes Spiel,
Lernen gehört zur Schleife, keine Werbung, alles offline.

**Vorgeschlagene Reihenfolge** (Claude, nicht beschlossen):

1. Datenverlust ausschließen (Konto oder automatische Sicherung).
2. Android-App mit Erinnerung.
3. Erster Kampf in den ersten zwei Minuten, Handbuch danach.
4. Wochenrhythmus für Gewohnheiten, großzügigere Eis-Regel.
5. Lizenzen und Inhalte klären.
6. Fünf bis zehn Fremde spielen lassen und zählen, wer an Tag 7 noch
   da ist — **vor** jeder weiteren Funktion.

## 02.10.2026: offene Tagesaufgaben stehen als Satz da

Frederik: „Die täglichen Aufgaben müssen natürlich auch lesbar sein,
wenn sie noch nicht abgehakt sind.“ Seit ADR-0060 stand eine offene
Aufgabe nur als Zeichen mit Balken da, der Satz kam erst auf Tipp; am
30.09. bekam nur die **abgeholte** ihren Satz zurück.

Jetzt steht der Satz in jeder Zeile: offen fett über dem Balken (bis
zwei Zeilen), rechts der Stand oder der Knopf zum Abholen; abgeholt wie
bisher grau und durchgestrichen. Der Tooltip ist damit weg, ebenso
`DailyQuest.habitName` in `habits` — der Name steht im Satz.

Das ist eine zweite Ausnahme von ADR-0060 neben der Theorie: Eine
Aufgabe ist ein Satz, kein Wert mit Zeichen.

App 625 (vorher 623), habits 227. **Nicht angesehen**, weder gerendert
noch am Handy — die Karte ist mit drei offenen Aufgaben rund 40 Punkte
höher als vorher.

## 01.10.2026, zuletzt: fünf neue Gegner, jede Grube mit eigener Besetzung

Die zwei übrigen Teile von ADR-0062, gebaut in einem Schritt.
[ADR-0063](../decisions/0063-besetzung-in-rollen.md) hält fest, wie.

| Neu | Was es tut | Der Grund für … |
|---|---|---|
| **Schleim** | langsam; zerfällt beim Tod in zwei schnelle Schleimlinge | … Flächenschaden |
| **Grimlock** | blind, bemerkt den Helden erst aus nächster Nähe; schlägt hart | … hinzusehen, wohin man läuft |
| **Kreischpilz** | steht; kündigt einen Schrei an, der den Raum weckt, auch durch Wände | … ihn zuerst zu fällen |
| **Sporenpilz** | hält Abstand und heilt die anderen | … die Reihenfolge der Ziele |
| **Wächterauge** | lädt einen Strahl auf, als Linie angekündigt | … den Schritt zur Seite |

**Die Besetzung** (`PitCast`, je Lauf gewürfelt, auf jeder Stufe aus
demselben Topf): Die Räume schreiben weiter Rollen, die Besetzung sagt,
wer sie spielt — neben dem Fussvolk Schleim, Grimlock oder niemand;
Schütze oder Wächterauge; Kobold oder Fledermaus; Kreischpilz oder
Sporenpilz in etwa jedem zweiten Raum. 24 Besetzungen, die Karte zu
einem Startwert bleibt dieselbe.

**Ohne Rückfrage entschieden**, weil es sonst nicht aufgeht:

- **Das Fussvolk bleibt immer dabei.** Eine Grube nur aus blinden
  Grimlocks liesse sich bis zum Wächter durchschleichen, und der zahlt
  den ganzen Topf.
- **Schleimlinge zahlen nichts** und lassen keine Kugel fallen.
- **Der Sporenpilz heilt nie sich selbst, einen anderen Sporenpilz oder
  den Wächter.**
- **Der Schrei ist gold, nicht rot**, und steht nicht bei den
  Ankündigungen: Aus ihm läuft man nicht hinaus.

**Gemessen** (`pit_sim`, 30 Läufe, neue Tabelle „Je Besetzung“): alles
gewürfelt Stufe 1 an Tag 0 **93 %**, Stufe 2 **63 %**, Stufe 30 voll
ausgerüstet **60 %** — fast wie vor der Besetzung (92, 58, 71). Keine
Art fällt aus der Reihe; Schleim und Grimlock kosten je zehn bis
fünfzehn Punkte gegenüber Fussvolk allein. Die ganze Tabelle steht im
ADR.

action_combat 276 (vorher 233), App 623. Die neuen Arten, der Schrei,
der Strahl und das Zerfallen als Bild aus dem echten Renderer angesehen,
**nicht gespielt und nicht am Handy**.

### Offen

- ~~Ob sich die Besetzungen im Spielen so verschieden anfühlen, wie die
  Zahlen gleich sind.~~ Gespielt am 02.10. (Frederik): „ist super“.
- **Kein Klang**: Der Schrei ist nur zu sehen.
- Die Besetzung steht nirgends, bevor man hinabsteigt.
- Die neuen Arten wippen nur, wie Kobold und Troll.
- Oger und blauer Slaad sind weiter ungenutzt.
- `world.dart` ist weiter über der Grenze; das Neue liegt in
  `enemies.dart` und `cast.dart`.

## 01.10.2026, danach: vier Wächter, je Lauf gewürfelt

Frederik fragte, ob noch Gegner-Sprites übrig sind (elf, im
Download-Paket), und wollte daraus: neue Gegner und Wächter, **gewürfelt**
statt nach Stufen gestaffelt.
[ADR-0062](../decisions/0062-waechter-und-besetzung-werden-gewuerfelt.md),
drei Entscheidungen: eigene Angriffe je Wächter, je Grube eine
**Besetzung** aus Gegnerarten, alles ab Stufe 1. **Gebaut ist der erste
Teil, die Wächter.**

| Wächter | Erster Angriff | Ab Stufe 4 | Ab Stufe 8, in Wut |
|---|---|---|---|
| Zyklop (wie bisher) | Bodenstoß | Felswurf | Ansturm |
| **Zweikopf** | Bodenstoß, danach ein zweiter, größerer Ring | zwei Brocken nacheinander | — |
| **Schlund** | springt dorthin, wo der Held steht | spuckt | springt zweimal |
| **Sumpftroll** | wirft Gift, das als Pfütze liegen bleibt | Bodenstoß | drei Pfützen |

Welcher kommt, würfelt `LevelBuilder.bossFor` aus dem Startwert, mit
eigenem Würfel. Name und Zeile beim Auftritt stehen in
`lib/action/boss_text.dart`, die Pfütze ist grün mit rotem Rand.

**Gemessen, nicht geschätzt** (`pit_sim`, neue Tabelle „Je Wächter“):
Stufe 1 an Tag 0 zwischen 92 und 100 %, Stufe 30 voll ausgerüstet
zwischen 50 und 75 %. Der erste Entwurf lag weit daneben (Zweikopf 3 von
40 auf Stufe 30); die drei Ursachen stehen im ADR.

action_combat 233 (vorher 206), App 622. Jeder Wächter als Bild aus dem
echten Renderer angesehen, **nicht gespielt und nicht am Handy**.

### Offen

- ~~**Die neuen Gegnerarten** und **die Besetzung je Grube**~~ —
  gebaut, siehe oben.
- Stufe 2 an Tag 0 ist für den Bot härter geworden (58 % statt 83 %).
- Bestzeiten sagen nicht, gegen welchen Wächter sie gelaufen sind.
- Die drei neuen Wächter wippen nur; sie haben weder Schlag noch Tod als
  Bild.
- ~~Ob der Sprung des Schlunds sich fair anfühlt, zeigt erst das
  Spielen.~~ Gespielt am 02.10. (Frederik), keine Beanstandung.

## 01.10.2026: Stücke tragen Rahmen und Namen ihrer Seltenheit

Frederik: „Items besser erkennbar machen, also mit der Seltenheit:
Rahmen in der Farbe der Seltenheit und den Namen in der Farbe.“ Drei
Varianten als Bild verglichen (farbiger Name, dunkles Namensschild,
getönte Fläche), gewählt: **Rahmen und Name farbig, überall bei
Ausrüstung, die Wort-Marke bleibt.**

| Wo | Was |
|---|---|
| Katalog in der Ausrüstung | Rahmen 2 Punkte in der Stufe, Name fett in der Stufe; nicht Besessenes bleibt grau, sein Rahmen blass |
| Die sechs Plätze | belegt: Rahmen und Name des getragenen Stücks |
| Laden | jede Kachel ebenso; **die Wahl ist ein heller Ring außen herum**, statt den Rahmen umzufärben; Name in der Detailkarte farbig |
| Blatt eines Stücks | Name farbig, das Bild im Rahmen |
| Beute des Wächters | Name farbig, das Leuchten im Rahmenton |

**Die Farbtabelle hat jetzt zwei Spalten** (`RarityBadge`): Schriftton
(`colorOf`) und Rahmenton (`rahmenOf`). Der Grund ist gemessen: Das
bisherige Gold hatte auf Pergament 2,4 : 1 und wäre als Name nicht
lesbar gewesen. Der Schriftton für Legendär ist deshalb ein gebranntes
Gold (4,5 : 1), der Rahmen ein leuchtendes. `rarity_test.dart` hält
beide Grenzen fest.

**Nebenwirkung:** Die Marke „Legendär“ und der Rahmen legendärer
Fähigkeiten sind damit ebenfalls dunkler — dieselbe Tabelle. Der
Fähigkeiten-Bildschirm selbst ist nicht angefasst (AktivesBrett).
**Geändert:** „Angelegt“ färbt den Rahmen im Katalog nicht mehr um; das
sagt nur noch der Haken.

Damit ist der offene Punkt aus ADR-0060 beantwortet: Die Seltenheit
steht als Farbe **und** weiter als Wort in der Marke.

App 620. Gerendert in 390 × 844 (Ausrüstung, Katalog, Laden, Blatt),
die Beute nicht; **nicht am Handy**.

### Offen

- „Gewöhnlich“ als Name sieht fast aus wie normale Tinte, und das
  gebrannte Gold liegt nah am Akzent („Angelegt“). Der Rahmen trägt den
  Unterschied.
- Fette Namen brechen im Katalog weiter mitten im Wort um.
- Ob die Fähigkeiten dasselbe bekommen sollen.

## 30.09.2026, zuletzt: das Blatt nach einem Sieg

Frederiks Vorgabe, gebaut als `SiegBlatt` (`lib/combat/widgets/sieg_blatt.dart`):
oben **„Sieg“ in Grün**, darunter ruhig „Ebene: 12“ und die Zeit mit Uhr
(Stern bei neuer Bestzeit), dann **XP und Gold untereinander** — sie
gleiten nacheinander herein und blenden von Grün in ihre Farbe —,
zuletzt mittig **„Weiter“**. Ein zweiter Sieg zeigt keine Beute; der
Tipp auf „Sieg“ sagt warum. Die Zahl der Gegner steht nicht mehr da.
Danach die **Niederlage** im selben Aufbau: „Niederlage“ in Rot, Uhr
durchgestrichen, wenn die Zeit abgelaufen ist. **Neu:** Was in einem
verlorenen Lauf gefallen ist, steht jetzt da — gebucht wurde es schon
immer (ADR-0041), das alte Blatt hat es verschwiegen. Beides heisst
jetzt `LaufErgebnis` (`lauf_ergebnis.dart`); `CombatResultDialog` und
sein Test sind gelöscht, ihre Zusagen stehen in `lauf_ergebnis_test.dart`.

PR #97, #98. App 612. Der Sieg gerendert in 390 × 844, die Niederlage
nicht; **beides nicht am Handy**.

## 30.09.2026, danach: Startseite — Truhe und lesbare Aufgaben

Frederik, als Nachtrag zu ADR-0060:

| Was | Wie |
|---|---|
| **Abgeholte Tagesaufgaben** | statt ✓ und vollem Balken steht der Satz da, grau und durchgestrichen — vorher war nicht mehr zu sehen, was es war |
| **Tagestruhe** | auch auf der Startseite, direkt unter „Heute“; geöffnet wird über `openDailyChest` (`habit_check_flow.dart`), eine Stelle für beide Bildschirme |
| **„Heute“ zeigt auch Erledigtes** | abgehakte Gewohnheiten bleiben stehen, grau und durchgestrichen, unter den offenen — auch wenn alles geschafft ist; ein Tipp nimmt das Häkchen zurück. Vorher schrumpfte Erledigtes auf „✓ 2“ (ADR-0053) |

PR #94, #95, #96. App 611. **Nicht am Handy angesehen.**

## 30.09.2026: der Baum wächst aus dem Gelesenen

Frederik liest wieder täglich (*Die 1%-Methode*) und will, was er liest,
als Theorie in die App bringen — als Überblick über das eigene Wissen
und als Wissen für andere. [ADR-0061](../decisions/0061-der-baum-waechst-aus-dem-gelesenen.md).

| Knoten | Hängt an | Inhalt |
|---|---|---|
| **Gewohnheiten** | Selbstentwicklung | was eine Gewohnheit ist, ein Prozent am Tag |
| **Die vier Regeln** | Gewohnheiten | offensichtlich, attraktiv, einfach, befriedigend — und umgedreht |
| **Mach es offensichtlich** | Die vier Regeln | Thorndikes Kantine, Wasserflasche und Gemüse sichtbar hinstellen, Handy aus dem Blick |

Damit ist der Baum zum ersten Mal tiefer als drei Ebenen; die
Oberfläche konnte das schon. `gewohnheiten_pages.dart`. Beim Schreiben
hat `question_fairness_test` eine Frage erwischt, deren richtige Antwort
die längste war — umformuliert.

theory 174, App 610. **Nicht gegengelesen, nicht am Handy angesehen.**

### Offen

- Regeln 2–4 (attraktiv, einfach, befriedigend) als eigene Seiten, sobald
  sie gelesen sind.
- Ob der Weg (Wurzel → Selbstentwicklung → Gewohnheiten → Regeln →
  Seite, fünf Punkte) zu teuer ist für das, was man eigentlich lesen will.

## 29.09.2026: die App geht ohne Lesen

Frederik: „so viel Schrift wie möglich entfernen, eine App muss ohne
Lesen funktionieren (natürlich Theorie etc bleibt drin)“. In einer
Fragerunde entschieden, [ADR-0060](../decisions/0060-die-app-geht-ohne-lesen.md):
**Namen und Zahlen bleiben**, Erklärungen kommen **beim Antippen**, wo
etwas hingezogen werden kann, **leuchtet** der Platz, alles in **einem
PR**.

| Bildschirm | Was ging, was jetzt dasteht |
|---|---|
| Startseite | „Heute“ → Liste-Zeichen; „1 erledigt“ → ✓ 1; Tagesaufgaben als Zeichen je Art mit Balken, Satz auf Tipp; „Abholen“ → +1 Schlüssel |
| Gewohnheiten | „Wann machst du das?“ → Wecker; „x1,2 in 1 Tag“ → Uhr 1 → x1,2; Reiter als Person / Buch; Wert und Grad als Zeichen und Punkte; Hinweissätze weg; Streak-Eis und Truhe ohne Satz |
| Charakter | Werte als Hantel, Herz, Schild, Tropfen, Herkunft als ✓ und Rucksack; Beständigkeit als Flamme, Stern, Haken; Überschriften weg; drei Wege als Zeichen; „Spielstand sichern“ als Diskette mit zwei Knöpfen |
| Ausrüstung | Überschriften und Sätze weg; leere Plätze nur als Umriss, der aufleuchtet, wenn etwas passt; Ordnungen als vier Zeichen; Rucksack 12 / 48 |
| Fähigkeiten | Überschriften und Satz unter den Plätzen weg; gesperrt trägt das Level-Abzeichen, frei leuchtet auf |
| Laden | Einleitung weg; Preis als Münze; Kaufen als Wagen mit Preis; Sperre als Schloss mit Stufe, fehlendes Gold rot |
| Grube | „Stufe 12“ → 12; „neu“ → Kompass; Bestzeit mit Uhr; „Hinab“ → Doppelpfeil; Tagesform zeigt die Zeichen der Werte statt „Abwehr +10 %“ |
| Ergebnis eines Laufs | Pokal oder Gesicht, Stufe, Gegner, Zeit als Zeichen, Beute als Zahlen; Regeln auf Tipp |
| Theorie | „gesamt 17 von 59“ weg; Rückfrage als Fragezeichen mit +10 / +3; „Weiterlesen:“ und „Zurück zu“ weg, Name bleibt; „Inhalt folgt“ → Sanduhr |

**Neu:** `lib/habits/stat_icon.dart` (ein Zeichen je Wert, eine
Tabelle), `lib/ui/ruhm_zahl.dart`, `PlatzLaedtEin` in
`lib/ui/halten_und_ziehen.dart`. In `habits`: `DailyQuest.habitName`,
damit die Aufgabe „Hol nach …“ ohne ihren Satz auskommt.

**Beim Ansehen gefunden** (gerendert in 390 × 844 mit Roboto): Der
Pfeil „→“ fehlt in der Schrift und stand als Kästchen da — jetzt ein
Zeichen. Bestwert und Errungenschaften trugen denselben Pokal.

App 610, habits 227, alle grün. **Nicht am Handy angesehen**, und nicht
angefasst: Feiern, Beute des Wächters, Wochenrückblick, Formulare,
Seltenheits-Marken, SnackBars.

### Offen

- Ob die Zeichen ohne Erklärung verstanden werden (Uhr für die nächste
  Kettenstufe, Kompass für „neu“, Rucksack für „aus der Ausrüstung“).
- Die Seltenheit steht noch als Wort in der Marke — als Farbe allein?
- Die Feiern und die Beute haben noch ganze Sätze.

## 28.09.2026, ganz zuletzt: der Laden kauft nur noch

Vierter Block aus Issue #88, „Laden und Ausrüstung doppelt sich“. Der
Reiter „Inventar“ im Laden konnte anlegen und verkaufen — dasselbe wie
das Blatt in der Ausrüstung (ADR-0057).

| Was | Wo jetzt |
|---|---|
| Kaufen, sechs Angebote am Tag | Laden, ohne Reiter |
| Anlegen, Ablegen, Verkaufen | Ausrüstung, im Blatt eines Stücks (wie bisher) |
| Alles Schlechtere verkaufen | Ausrüstung, über „Alle Stücke“, nur wenn es etwas zu räumen gibt |
| Verkaufen im Code | **ein** Weg, `lib/gear/sell_flow.dart` |

**Das hebt eine Entscheidung aus ADR-0057 auf**: Dort sollte das
Inventar im Laden bleiben (AktivesBrett). Frederik hat es mit Issue #88
anders entschieden. `ShopItemTile` hat seinen Inventar-Zweig verloren.
App 610.

## 28.09.2026, zuletzt: der Eingang der Grube wird ein Fahrstuhl

Dritter Block aus Issue #88. Frederik hat gewählt: Schacht statt Bild,
Schlüssel als Zeichen mit Zahl.

| Vorher | Jetzt |
|---|---|
| Karte „Heute · noch 3 von 4“ mit vier Kacheln | ein **Stern** vor jeder Stufe des Tages, gold, solange sie zahlt |
| Leiste „Geschaffte Stufen · Bestzeiten“ | **alle 30 Stufen untereinander** im Schacht, 30 oben, mit Bestzeit; die nächste heißt „neu“, darüber Schlösser |
| leeres Bild, „Stufe 1“ mit Faktoren | Tippen wählt, „Hinab“ fährt zur gewählten |
| zwei Sätze zu Belohnung und Schlüsseln | ✨ +55  ● +22, Schlüssel ×1 (Tipp erklärt) |
| Tagesform als Satz | der Blitz-Kreis; voll steht dort nur „In Form“ |

Keine neuen Daten: Bestzeiten gab es schon (`LadderProgress.bestTimes`),
offen ist dieselbe Grenze wie vorher. **Beim Ansehen gefunden:**
Schlüssel und Blitz in einer Zeile liefen mit echter Schrift um 100
Punkte über — der Blitz schrumpft jetzt (`gotchas.md`, dritter Fall
dieser Art). App 610. Gerendert in 390 × 844, **nicht am Handy**.

## 28.09.2026, spät: der Gewohnheiten-Bildschirm zeigt nur noch „Heute“

Zweiter Block aus Issue #88, durchgesprochen und entschieden mit
Frederik: [ADR-0059](../decisions/0059-gewohnheiten-nur-noch-heute.md).
Über der Tagesliste standen sechs Karten; jetzt steht sie oben.

| Was | Wohin |
|---|---|
| **Werte** (Stärke …) | weg — stehen im Charakter unter „Werte im Kampf“ |
| **Kette je Gewohnheit** | weg; an jeder Kachel steht jetzt klein die nächste Stufe („x1,4 in 2 Tagen“) |
| **Tagesform** | als Blitz-Kreis an den Eingang der Grube, der sich mit jedem Häkchen auflädt; Tipp zeigt die Karte |
| **Tagesaufgaben** | auf die Startseite unter „Heute“, dort wird auch abgeholt |
| **Rückfrage des Tages** | oben in die Theorie, als Zeile, die aufklappt |
| **Deine Woche** | in den Charakter unter „Beständigkeit“ |
| **Vorlagen** | Reiter „Eigene“ / „Vorerstellte“, darüber „Neue Gewohnheit“ statt des schwebenden Knopfs |

Streak-Eis und Tagestruhe bleiben, beide hängen am Häkchen.

**Beim Bauen gefunden:** Die Rückfrage aufgeklappt nahm auf dem Handy
ein Drittel der Theorie, der Layout-Test fand den Baum nicht mehr —
sie beginnt jetzt immer als Zeile. Und wer noch keine eigene hat,
landet im Reiter „Vorerstellte“; dort stand der Knopf zum Anlegen
nicht, er steht jetzt über beiden.

App 607 (Wertekacheln, Leiter und ihre Tests sind entfallen). Gerendert
in 390 × 844, **nicht am Handy**.

## 28.09.2026, abends: die Figur zieht in die Ausrüstung

Frederik wollte die Startseite umbauen:
[ADR-0058](../decisions/0058-figur-in-die-ausruestung.md).

| Was | Wie |
|---|---|
| **Figur** | im Ausrüstungs-Bildschirm zwischen den Plätzen, drei links (Helm, Rüstung, Schuhe), drei rechts (Waffe, Ring, Talisman) |
| **Level** | ein rundes Abzeichen mit der Zahl darin; je zehn Level ein Rahmen, Holz, Bronze, Silber, Gold, Edelstein, dazu 0 bis 8 Nieten |
| **Gold** | nur Münze und Zahl, ohne das Wort |
| **Balken** | bleibt; „x von y Erfahrung“ erst auf Tipp |
| **„Heute“** | bekommt den Platz der Figur und rollt, statt überzulaufen |

Die Rahmen sind **gemalt, nicht gezeichnet** — Platzhalter, bis es
Bilder gibt; welcher zu welchem Level gehört, steht in `LevelRahmen`.
Damit ist der offene Punkt „die Figur an vollen Tagen“ erledigt.

**Beim Ansehen gefunden** (gerendert in 390 × 844 mit Roboto): Die
Plätze wurden nur so breit wie ihr Inhalt, und Holz und Bronze sahen
gleich aus — jetzt füllen die Plätze die Spalte, und jede Stufe hat
mehr Nieten als die davor. App 610. **Nicht am Handy angesehen.**
Ohne Gewohnheiten bleibt unter „Heute“ viel Leder frei.

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

- ~~**Zwei Verkaufswege**~~: erledigt am 28.09., der Laden verkauft
  nicht mehr (Eintrag oben).
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
