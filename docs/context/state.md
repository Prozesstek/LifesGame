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

**Zuletzt aktualisiert:** 18.10.2026 · Frederik

---

## Übersicht: was steht

**Phase:** Testlauf (Ziel 7, 21.09.–20.10.2026). Alle Bauziele 1–6 und 8
sind erreicht; seit Teststart wurde trotzdem stark weitergebaut (siehe
„Offen“).

| Bereich | Stand | Wo nachlesen |
|---|---|---|
| **Gewohnheiten** | **ein Häkchen, das aufspringt, klingt und Münzen wirft**, Vorlagen und eigene, **Wochenplan je Gewohnheit**, **Koppeln zu Stapeln**, Streaks, **die fallen statt zu reißen**, **Tageskette**, Streak-Eis, Tagesform, Tagestruhe, **Tagesaufgaben**, Wochenrückblick, Auslöser „Wann machst du das?“, **Belohnung danach**, **Zeitziele als Timer**, Startvorlage | ADR-0028, -0036, -0043, -0044, -0052, -0055, -0064, -0065, -0066, -0067 |
| **Startseite** | sieben Kreise, **die nach und nach erscheinen**, Level-Abzeichen und Gold in einer Zeile, „Heute“ zum Abhaken, **am Anfang die Frage nach der ersten Gewohnheit** | ADR-0049, -0053, -0057, -0058, -0068 |
| **Wissensbaum** | **jede Seite eine Spielrunde wie bei Duolingo**, vier Wurzeln, Zwischenebenen, 63 Knoten, 15 angekündigte Überschriften, ein Punkt je Knoten, **neun Startpunkte**, **das Handbuch als fünf Knoten unter Gewohnheiten**, **direkt zur nächsten Seite**, Rückfrage des Tages, **falsche Antworten kommen noch einmal**, **Ring und Zähler an jedem Knoten, Gebietsbalken, „Weiterlesen“** | ADR-0019, -0045, -0050, -0051, -0055, -0056, -0061, -0070 |
| **Kampf** | die Grube: Echtzeit, 30 Stufen, gesteckte Räume, **elf Gegnerarten in gewürfelter Besetzung**, **vier Wächter, je Lauf gewürfelt**, Tor und Auftritt, Uhr, Beute je Gegner, **zwei Zeichen im ersten Lauf**, **die Tagesgrube: eine für alle, ein Versuch am Tag** | ADR-0039, -0041, -0046, -0062, -0063, -0069, -0072 |
| **Stärke** | Level und Seltenheit vervielfachen, Gewohnheiten addieren | ADR-0042 |
| **Ausrüstung** | Exemplare mit Würfen, Tagesladen, Beute mit Schlüsseln, Sets, Legendäre, Verkauf zu einem Viertel, **eigener Bereich mit allen 48 Stücken**, **Rahmen und Name in der Farbe der Seltenheit** | ADR-0029–0031, -0034, -0047, -0048, -0057 |
| **Fähigkeiten** | 29 Fähigkeiten und 8 Waffenzüge in der Grube, **zwei Ultimates auf eigenem Platz ab Level 15**, zwanzig Arten von Wirkung, eigener Bereich mit allen Werten | ADR-0022, -0049, -0073 |
| **Errungenschaften** | 20 Meilensteine, 8 Entdeckungen, 13 Titel | ADR-0033, -0073 |
| **Speicher** | lokal im Browser, **als Text sicherbar** | ADR-0010, -0054 |
| **Prototyp** | das Dorf, nur im Entwicklermodus | — |

**Tests:** App 830, dazu die acht Packages (theory 193, habits 324, gear
118, action_combat 331, progression 44, abilities 43, identity 25,
achievements 24). **In der CI laufen nur die App-Tests** — der Umbau,
der alle prüft, wartet auf den `workflow`-Scope (`verlauf.md`, 27.09.).

## Offen, gesammelt

**Die Richtung** (09.10., [ADR-0071](../decisions/0071-das-naechste-level.md)):
~~Tagesgrube~~ (gebaut am 11.10., ADR-0072), Lagerfeuer, Schatten,
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
später — zuerst wird das Konzept weiter ausgebaut.** Store bleibt auf
der Sperrliste in `ziele.md`. Offen bis dahin: Datenverlust, Erinnerung und Android-App, ~~der lange Weg
zum ersten Kampf~~ (gebaut, ADR-0068), ~~nur tägliche Gewohnheiten~~ (gebaut, ADR-0064),
Lizenzen der Assets, Fremde als Tester (mit der Tagesgrube ohne Store
möglich, ADR-0071). Die ganze Liste steht im Eintrag vom 02.10.

**Inhalt und Balance:**

- Gegenlesen: neun Einführungen und zwanzig Themen im Wissensbaum
  (Kraft, Ausdauer, Psychologie, Philosophie) — mit Gesundheitsaussagen.
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

## 18.10.2026, danach: eine Seite als Spielrunde

Frederik: „Ist sehr cool. Wie könnten wir das Lernen noch spannender
machen?“ Claude schlug vier Ideen vor — die Seite als Spielrunde, Seiten
werden golden, erst erinnern und dann wählen, ein Schrein in der Grube —
und empfahl die erste. Frederik: „Ja“. Gebaut als Prototyp, ohne
Fragerunde.

| Was | Wie |
|---|---|
| **Häppchen** | ein Abschnitt je Bildschirm, Striche oben, „Weiter“; der Knopf zu den Fragen steht erst auf dem letzten |
| **Jede Antwort klingt** | richtig klettert die Tonleiter des Häkchens, eine Stufe je Antwort in Folge; falsch zwei weiche Schläge abwärts, und die Leiter beginnt von vorn. Dazu Vibration |
| **Die Antwort bewegt sich** | die richtige springt auf, die falsche schüttelt den Kopf |
| **Das Urteil von unten** | grün oder rot, „Richtig“ oder „Nicht ganz“, die Erklärung und der Knopf — bis dahin ein Kasten unter den Antworten |
| **Der Balken oben** | springt mit jeder Antwort vor, die sitzt; eine falsche lässt ihn stehen, die zweite Runde füllt ihn |
| **Die Fragen schieben sich** | die neue von rechts herein, die alte nach links hinaus |
| **Das Ergebnis baut sich auf** | das Zeichen springt, Erfahrung und Gold zählen hoch, danach kommen die Knöpfe |
| **Drei von drei** | der Akkord löst die Leiter auf, Konfetti steigt aus der Mitte |

**Keine Zahl ändert sich.** Bestehen, Erfahrung, Gold und die zweite
Runde rechnen wie vorher.

**Ohne Rückfrage entschieden:**

- **Erst gezählt, dann gefeiert**: Errungenschaft, Aufstieg und neue
  Fähigkeit kommen, wenn Erfahrung und Gold fertig gezählt sind — wie
  beim Häkchen. Bis dahin geht es nicht zurück; wer es versucht, bekommt
  die Feier sofort. Sonst ginge ein Aufstieg verloren, dessen „vorher“
  nur auf dieser Seite steht.
- **Drei von drei klingen wie ein geschaffter Tag** (`TagGeschafft.wav`),
  zwei von drei wie bisher (`Win.mp3`).
- **Eine falsche Rückfrage klingt jetzt auch**, mit demselben Klang.
- **Nicht verschränkt**: Abschnitt und Frage stehen weiter getrennt
  (`lernen.md`, Punkt 4) — das wäre Schreibarbeit an jeder Seite.
- **„Richtig“ bleibt ein Wort**, kein wechselndes Lob (ADR-0060).

**Beim Ansehen gefunden** (gerendert in 390 × 844): Beim Schieben
standen alte und neue Frage in der Mitte halb übereinander; die alte
geht jetzt schneller und blendet aus. Und das Konfetti kam vom Knopf
ganz unten kaum über die untere Hälfte, es steigt jetzt aus der Mitte
(`AufstiegHost.konfetti(von:)`).

Neu: `antwort_klang.dart`, `lese_haeppchen.dart`, `antwort_leiste.dart`,
`runden_balken.dart`, `tool/lern_klaenge.py`, `Falsch.wav`. App 830
(vorher 825). **Nicht gehört, nicht gespielt, nicht am Handy.**

### Offen

- Ob der dumpfe Klang bei falsch freundlich klingt oder nach Strafe.
- Kurze Abschnitte stehen allein auf einem Bildschirm mit viel Leere
  darunter.
- Wer eine Seite nur nachschlagen will, blättert jetzt statt zu rollen.
- **Die anderen drei Ideen**: Seiten werden golden (die Stufen der
  Rückfrage sichtbar am Knoten), erst erinnern und dann wählen, ein
  Schrein in der Grube. Der Schrein braucht eine Konzeptrunde und einen
  ADR — er berührt die Balance der Grube und die Tagesgrube.

## 18.10.2026: der Häkchen-Moment — abhaken wie bei Duolingo

Frederik: „Können wir das abhaken von Gewohnheiten noch befriedigender
machen wie bei DioLingo?“ Gebaut ohne Fragerunde als Prototyp.

| Was | Wie |
|---|---|
| **Der Kreis springt** | grün über seine Grösse hinaus und zurück, dahinter ein Blitz, ein Ring nach aussen, acht Striche; nur beim Setzen, nicht beim Zurücknehmen (`HaekchenKreis`, Kachel und „Heute“) |
| **Die Tonleiter des Tages** | jedes Häkchen klingt eine Stufe höher als das davor, fünf Stufen pentatonisch; das letzte Fällige löst den Akkord auf. Ein Punkt Stärke klingt wie bisher anders |
| **Die Flamme zündet** | mit dem ersten Häkchen des Tages: sie schiesst hoch, glüht, Funken steigen, die Zahl der Tageskette rollt eins weiter, dazu ein Fauchen |
| **Münzen fliegen** | auf der Startseite platzen Münzen und Funken am Finger auf und fliegen zur Goldzahl und zum Balken; die Zahl steigt mit jeder, die ankommt, und das Ziel springt kurz auf |
| **Konfetti** | wenn der Tag geschafft ist, vom Finger aus über den ganzen Bildschirm, dazu ein kräftigerer Stoss |
| **Erst landen, dann feiern** | Errungenschaft, Aufstieg und neue Fähigkeit kommen, wenn die letzte Münze gelandet ist — vorher deckte der Aufstieg den Balken zu, der ihn gerade füllt |

**Keine Zahl ändert sich.** Was fliegt, hat der Tracker schon gezählt;
die Leiste zieht nur ab, was noch unterwegs ist (`BeuteFlug`, wie der
Goldregen der Grube). Münze und Funke stehen jetzt an einer Stelle für
beide (`MuenzBild`).

**Ohne Rückfrage entschieden:**

- **`Success.mp3` klingt nicht mehr beim Häkchen**, nur noch bei der
  richtigen Rückfrage. Die Leiter ist gerechnet
  (`tool/haekchen_klaenge.py`), Platzhalter wie die Klänge der Grube.
- **Fünf Stufen**, weil höchstens fünf Gewohnheiten laufen; darüber
  bleibt es die oberste.
- **Ein Punkt Stärke hat den Vorrang** vor dem Akkord, wenn beides auf
  einmal fällt.
- **Auf dem Gewohnheiten-Bildschirm fliegt nichts**: Dort gibt es keine
  Leiste oben, nur die Zahlen steigen auf. Kreis, Ton und Konfetti gibt
  es dort auch.
- **Die Leiste unten bleibt**, obwohl sie jetzt dreimal sagt, was
  aufsteigt und fliegt — Tests halten sie fest, und sie trägt „Jetzt:
  Kaffee“ (ADR-0066).

**Beim Nachsehen gefunden:** Der Kommentar „im Browser passiert nichts“
stimmte nicht. Flutter macht im Browser aus `HapticFeedback` ein
`navigator.vibrate` — auf einem Android-Handy vibriert das Häkchen also
schon immer, auf dem iPhone nicht.

**Beim Ansehen gefunden** (gerendert in 390 × 844): Die Münzen hingen zu
lange hinter den aufsteigenden Zahlen, sie heben jetzt schneller ab; und
der Aufstieg deckte Münzen und Konfetti sofort zu. Eine Feier mit festem
Zeitgeber lief dabei in ein Rennen mit `pumpAndSettle` (`gotchas.md`);
sie hängt jetzt am Takt des Hosts.

Neu: `haekchen_moment.dart`, `haekchen_kreis.dart`, `beute_flug.dart`,
`konfetti.dart`, `muenz_bild.dart`, `sprung.dart`,
`tool/haekchen_klaenge.py`, sieben Klänge, `test/haekchen_moment_test.dart`.
App 825 (vorher 809). **Nicht gehört, nicht gespielt, nicht am Handy.**

Gemergt am 18.10. als PR #122. **Die erste Auslieferung fiel in der CI
um**, 37 rote Tests, hier alle grün: Die Flamme legte ihren Controller
erst im `dispose` an, und die CI läuft auf einem älteren Flutter
(`gotchas.md`). Behoben direkt auf `main`.

### Offen

- **Wie die Leiter klingt**, weiß niemand — und ob fünf Glocken am Morgen
  nach einer Woche nerven.
- Die Leiste unten: raus für ein gewöhnliches Häkchen?
- Steigt das Level mitten im Flug, wartet das Abzeichen auf die Funken,
  der Aufstieg aber erscheint erst danach — ob das als ein Moment oder
  als zwei gelesen wird.
- Wer direkt nach dem Abhaken einen Bereich öffnet, sieht die Feier erst
  beim Zurückkommen: Der Host läuft dahinter nicht weiter.
- Der Gewohnheiten-Bildschirm hat keine Leiste, zu der etwas fliegen
  könnte.

## 16.10.2026, spät: der Schlund glüht

Frederik: „Was hälst du davon wenn wir Glow machen beim Eingang also
dass das mythisch aussieht.“ Gebaut ohne Fragerunde.

In der leeren Mitte des Eingangs liegt jetzt ein Schlund: ein dunkles
Loch mit glühendem Rand, ein Schein, der atmet (2,4 s), Glut, die
aufsteigt, und die Zahl der Ebene davor, in derselben Farbe
nachleuchtend.

| Ebene | Farbe | warum |
|---|---|---|
| 1–9 | Feuer | — |
| 10–19 | violett | ab hier fällt Episches (`GearGates.epicRung`) |
| 20–30 | golden | ab hier Legendäres |
| 31–100 | blutrot, mehr Glut, ein zweiter Hitzering | jenseits des alten Endes (ADR-0075) |

Violett und Gold sind die Ränder der Seltenheiten
(`RarityBadge.rahmenOf`), keine neuen Farben. **In Tests atmet er
nicht** (`test/flutter_test_config.dart`): Eine Animation ohne Ende
liesse `pumpAndSettle` nie zur Ruhe kommen. Wer Bewegung im System
abgeschaltet hat, sieht ihn ebenfalls still.

App 799 (vorher 795). Alle vier Tiefen in 390 × 844 gerendert und
nebeneinander angesehen; die Zahl sass zu dicht am Rand und steht jetzt
höher. **Nicht am Handy** — ob die Weichzeichnung dort ruckelt, ist
offen.

Gemergt am 16.10. als PR #121.

## 16.10.2026, abends: hundert Ebenen im selben Schritt

Frederik: „Grubelevel bis 100“, und auf Claudes Vorschlag, Stufe 100 so
hart zu machen wie bisher 30: „Ne baue das einfach mit den gleichen
Abständen, ich hab zurzeit ne 27 Tage Streak und schaff Level 30
immer.“ [ADR-0075](../decisions/0075-hundert-ebenen.md).

| Was | Wie |
|---|---|
| **Stufe 1–30** | Zahl für Zahl wie vorher; kein Stand wird umgerechnet |
| **Stufe 31–100** | derselbe Schritt weiter: Gegner je Stufe rund ein Achtel stärker, alle vier Stufen ein Raum mehr, die Belohnung wächst weiter um 5 EP und 2 Gold |
| **`pit_sim`** | eine Spalte für Level 50; eine Spalte hört auf, sobald sie zweimal bei null steht |

**Gemessen** (`pit_sim`, 8 Läufe je Feld): **Ab Stufe 42 gewinnt der
Bot nie, auch mit Level 50**, bester Ausrüstung und drei Fähigkeiten;
sicher bis 37, mit Tag-60-Werten bis 29. Der Bot ist eine untere
Schranke, aber Stufe 100 ist rund tausendmal so stark wie Stufe 41.

App 795, action_combat 331, beide unverändert in der Zahl: drei Tests
nahmen 30 als Ende an und prüfen jetzt die Bezugsstufe.

Gemergt am 16.10. als PR #120.

### Offen

- **Soll Stufe 100 erreichbar sein?** Dann braucht es einen flacheren
  Schritt über 30 — eine Zahl, gemessen mit `pit_sim`.
- Die Summe der Belohnung ist zehnmal so gross; erreichbar ist bis zur
  Wand etwa das Doppelte von vorher.
- Ab Stufe 31 sind die Gruben länger als alles bisher (Stufe 100: zehn
  Räume, knapp fünf Minuten). Nicht gespielt.

---

## 16.10.2026, danach: der Eingang zeigt nur noch die nächste Ebene

Frederik: „Kampf Anzeige mit welches Level kann raus (Fahrstuhlmodus)
Aktuelles wird angezeigt, 2/30 weg (Ebene 2 dafür) und der Balken kann
auch darunter weg.“

| Vorher | Jetzt |
|---|---|
| „2 / 30“ mit Balken | **„Ebene 3“**, gross in der Mitte — die Ebene, in die „Hinab“ führt |
| der Fahrstuhl: alle Stufen zum Wählen, mit Bestzeit | weg |

**Ohne Rückfrage entschieden:** Angezeigt wird die **nächste** Ebene,
nicht die zuletzt geschaffte — der eine Knopf darunter führt dorthin.
In der Grube und im Ergebnis heisst es weiter „Stufe“.

**Was damit wegfällt:** Eine geschaffte Ebene lässt sich nicht mehr
wählen. Damit lassen sich **Schlüssel nicht mehr einsetzen** — sie
öffneten die Beute nur bei einem weiteren Sieg auf einer geschafften
Stufe (ADR-0048), und jeder Lauf ist jetzt ein erster. Bestzeiten werden
weiter gespeichert, aber nirgends mehr gezeigt.

App 795 (vorher 797): die drei Tests des Schachts sind weg, einer kam
dazu. Den Eingang in 390 × 844 gerendert und angesehen. **Nicht am
Handy.**

Gemergt am 16.10. als PR #119.

### Offen

- **Wofür Schlüssel jetzt da sind.**
- **„Grubelevel bis 100“** — nicht gebaut, braucht Entscheidungen zu
  Belohnung, Sperren im Laden, Errungenschaften, Tagesgrube und alten
  Ständen.

## 16.10.2026: der Goldregen — Beute fliegt zum Helden

Frederik: Man rennt durch die Grube, sie soll mehr Dopamin bringen; der
Kampf zeigt, wie weit man gekommen ist, und muss sich belohnend
anfühlen. „Lass als erstes anfangen mit dem Goldregen und XP muss sich
auch geil anfühlen.“ Gebaut ohne Fragerunde als Prototyp.

| Was | Wie |
|---|---|
| **Münzen** | ein Gegner wirft drei bis vierzehn, der Wächter einen Brunnen aus sechzehn bis achtundvierzig; sie springen, drehen sich, rollen aus und fliegen nach einer halben Sekunde zum Helden |
| **Funken** | Erfahrung als glühende Punkte in der Farbe des Balkens auf der Startseite, mit Spur |
| **Kasse** | oben neben der Zeit, zählt, was **angekommen** ist, und springt bei jeder Münze auf |
| **Balken** | unten am Rand: Level und Erfahrung bis zum nächsten, mit allem aus dem Lauf |
| **Aufstieg** | steigt das Level mitten im Lauf, springt das Abzeichen gross in die Mitte, ein goldener Ring geht um den Helden |
| **Klang** | drei neue, gerechnet: Münze, Funke, Aufstieg |
| **Ende** | das Ergebnis wartet, bis der Brunnen eingesammelt ist, höchstens 1,6 s |

**Keine Zahl ändert sich.** Was fliegt, hat die Welt schon gezahlt
(`LootDropped`, ADR-0041); ein Stück, das nie ankommt, kostet nichts.
Die Zahl „+7 EP +3 G“ über dem Gegner und in der Kopfzeile ist dafür
weg. Tagesgrube und Prototyp zeigen den Regen ohne Balken.

**Beim Nachsehen im Code gefunden, nicht geändert:** Der Wächter füllt
den Topf auf (`world.dart`, ADR-0041). Wer an allem vorbeirennt, bekommt
mit ihm denselben Betrag. **Das ist der Grund fürs Durchrennen**, nicht
die fehlende Beute. Und eine geschaffte Stufe zahlt nichts mehr, dort
regnet es also nicht.

**Die Beträge sind klein**: Stufe 1 zahlt 20 EP und 8 Gold im ganzen
Lauf. Der Regen macht daraus mehr Münzen, aber nicht mehr Gold.

Neu: `beute_regen.dart`, `beute_bild.dart`, `beute_anzeige.dart`,
`test/beute_regen_test.dart`, drei Klänge. App 807 (vorher 797). Regen,
Flug und Aufstieg in 390 × 844 gerendert und angesehen, mit Würfeln
statt Figuren. Dabei gefunden: Die Kasse war auf heller Wand nicht zu
lesen und steht jetzt auf einem dunklen Schild; der Brunnen streute zu
weit. **Nicht gespielt, nicht gehört, nicht am Handy.**

Gemergt am 16.10. als PR #118, nach #119 bis #121; alle vier zusammen:
App 809, action_combat 331.

### Offen

- **Der Wächter füllt nicht mehr auf** — der nächste Schritt; ändert die
  Verteilung, nicht die Summe.
- **Was ein Lauf auf einer geschafften Stufe bringt**: Sterne je Stufe
  (Claudes Empfehlung) oder ein Tagesbeutel. Nicht entschieden.
- Ob das Rasseln der Münzen im Brunnen nervt.
- Der Balken unten liegt dicht unter den Fähigkeitsknöpfen.

## 15.10.2026, danach: die Knöpfe zeigen, was abklingt

Frederik: „Wenn Fähigkeiten auf Cooldown sind mach ein sweep, dim the
icon und zeig einen cooldown und indicate the return.“ Gebaut ohne
Fragerunde, auf demselben Branch (PR #117).

| Was | Wie |
|---|---|
| **Sweep** | das dunkle Tortenstück gab es schon; dazu eine helle Kante wie ein Uhrzeiger |
| **Ausgegraut** | das Bild in Graustufen und blasser, solange es abklingt |
| **Zahl** | die Sekunden in der Mitte, aufgerundet; unter einer Sekunde mit einer Stelle („0,6“) |
| **Zurück** | der Knopf leuchtet golden auf, ein Ring springt nach aussen, 0,45 s |

Der Glanz läuft in der Zeit des Laufs (`ActionWorld.elapsed`), er hält
also mit dem Trefferstopp an. Die Restzeit kommt aus der Welt
(`slotCooldownLeft`), die Anzeige rechnet nur (`AbklingAnzeige`). Der
alte Satz „Im Kampf liest niemand Ziffern“ ist damit überholt.

Gemergt am 15.10. als PR #117, zusammen mit den Fähigkeiten.

App 797 (vorher 791), action_combat 331 (vorher 330). Die Knöpfe in
allen vier Zuständen gerendert und angesehen. Dabei gefunden: Die Zahl
lag zuerst unter dem Tortenstück und war mit abgedunkelt. **Nicht
gespielt, nicht am Handy.**

### Offen

- Ob die Zahl auf den kleinen Knöpfen im Bogen (50 Punkte) am Handy
  lesbar ist.
- Die Ultimate hat keinen Glanz, wenn sie voll ist; sie zeigt es nur
  über den Ring.

## 15.10.2026: die Fähigkeiten sind gebaut — zwölf neue, zwei davon Ultimates

Nach einem Absturz von Frederiks Rechner. Die Datei von ADR-0073 lag
danach nur noch als Nullbytes auf der Platte und ist aus dem letzten
Commit wiederhergestellt; was nach 19:39 am 14.10. daran geändert
wurde, ist verloren. Dann Frederik: „Lass die Fähigkeiten bauen.“
Gebaut ohne Fragerunde, die Vorgaben standen in ADR-0073 und in der
Vorlage.

| Was | Wie |
|---|---|
| **Elf neue Arten** | Sturm mit Spur, Haken, Strudel, Self-Buff, Zufall, Bumerang, Falle, Begleiter, Fels, Ranke, Eisball mit Zerspringen — in `effects.dart` und `summons.dart`, nicht in `world.dart` |
| **Stillstand** | Gegner stehen und holen nicht aus; der Wächter hat eine Stun-Leiste aus drei Kerben |
| **Die Ultimate** | eigener Platz ab Level 15, lädt ein Achtel je Kill und ein Achtzigstel je Treffer am Wächter; im Kampf gross in der Ecke mit Ladering, die drei anderen im Bogen; Taste 4 |
| **Fähigkeiten-Bildschirm** | ein Platz mit goldenem Doppelrand unter den vier, die zwei Ultimates als eigene Gruppe; gezogen oder übers Blatt |
| **Frederiks zwölf** | alle im Katalog, mit Quelle, Bild und Blatt |
| **Glückstrank** | über eine neue Errungenschaft „Zehn Truhen“ |
| **Mana** | `dart run tool/pit_sim.dart mana` misst, wie oft ein Platz am Mana hängt |

**Ohne Rückfrage entschieden** (die ganze Liste steht in der Vorlage):

- **Die Knoten der Baum-Quellen**, darunter die Wassergrube an
  „Erholung ist Teil der Arbeit“ — drei Punkte, auf Level 15 sicher
  erreichbar; ein Test hält das fest.
- **Fanghaken ist ein Haken ohne Blink**: Das Ende ist dasselbe.
- **Zwei Regeln weichen Frederiks Quellen**: Körper und Geist tragen je
  sieben Fähigkeiten (bisher höchstens drei je Gebiet), und die
  Gewohnheiten vergeben zwei über Errungenschaften (bisher eine je
  Bereich).
- **Die Tagesgrube bleibt ohne Ultimate**, und ihre sieben Sätze bleiben
  die alten neunzehn — neue Sätze bräuchten eine neue Messung.

**Gemessen** (Bot, Tag 30 ohne Ausrüstung):

- **Mana bremst früh, spät kaum**: drei Angriffe im Takt hängen an
  Tag 0 und 30 in 62–67 % der Zeit am Mana, an Tag 60 mit Ausrüstung in
  18 %. **Nicht nachgestellt** — das ändert jede Siegquote und die
  Tagesgrube.
- **Die Ultimate** ist nach etwa 16 s voll und kommt rund dreimal je
  Lauf. Auf Stufe 13 hebt sie die Siegquote um 20 bis 37 Punkte.

Neu: `effects.dart`, `summons.dart`, `neue_arten_bild.dart`,
`ultimate_platz.dart`, `neue_arten_test.dart`, zwölf Bilder aus Raven.
App 791 (vorher 789), action_combat 330 (vorher 305). Bildschirm und
Grube in 390 × 844 gerendert und angesehen, **die Grube mit Würfeln
statt Figuren. Nicht gespielt, nicht am Handy.**

### Offen

- **Mana als Bremse stellen** — oder lassen. ADR-0073 sagt „zuerst
  messen“; das ist geschehen, die Entscheidung nicht.
- **Dreimal je Lauf** ist für einen „Moment“ vielleicht zu oft. Ein
  Achtel je Kill ist geschätzt.
- Die Bilder sind Platzhalter aus Raven; ein Falke war nicht dabei.
- Die neuen Wirkungen haben keine eigenen Klänge und keine Animation,
  nur Ringe, Fäden und Punkte.
- `world.dart` ist auf 1.936 Zeilen gewachsen, obwohl die Wirkungen
  ausgezogen sind.
- AktivesBrett hat weder ADR-0073 noch die Vorlage gesehen; seine zehn
  und zwei fehlen.

## 14.10.2026: Fähigkeiten — Ultimate, Mana als Bremse, zehn neue Arten

Frederik: „Guck dir Fähigkeiten an“ — Issue #114. In einer Fragerunde
entschieden, **nichts gebaut**:
[ADR-0073](../decisions/0073-ultimate-mana-und-neue-arten.md).

| Was | Wie |
|---|---|
| **Ultimate** | eigener Platz ab Level 15; kein Mana, lädt durch Kills und Treffer am Wächter; jeder Lauf beginnt leer |
| **Im Kampf** | groß in der Ecke, die drei anderen kleiner im Bogen darum; vor Level 15 bleibt die Reihe |
| **Bild** | goldener Doppelrand, keine Seltenheit — Gold allein hieße Legendär |
| **Quelle** | Baum, Kette, Errungenschaft; eine auf Level 15 im Baum erreichbar; nie aus der Grube |
| **Mana** | wird die Bremse, die Abklingzeit verhindert nur Dauerfeuer; **zuerst messen** |
| **Neue Arten** | Dash, Blink, Stun, Self-Buff, Stacking/Rage, Passiv, Hook, Unsichtbarkeit, Begleiter, Terrain — **jede in jeder Fähigkeit** |

Sechsmal wie empfohlen. **Einmal dagegen:** Claude wollte Begleiter und
Terrain den Ultimates vorbehalten; Frederik will alle Arten für alles.
Dafür haben beide Grenzen bekommen (einer zugleich, Wände auf Zeit).

Neu: die Vorlage [`faehigkeiten-2.md`](../vorlagen/faehigkeiten-2.md) —
je Entwickler zehn Fähigkeiten und zwei Ultimates, mit allen Bausteinen
und Regeln. **Frederiks Ideen gehen wir Stück für Stück durch**, dann
wird in drei Blöcken gebaut: Messung und Ultimate-Platz, die zehn Arten,
die Fähigkeiten.

**Der Fähigkeiten-Bildschirm ist frei** (Frederik): AktivesBrett baut
dort nicht mehr.

### Offen

- Frederiks zehn Fähigkeiten und zwei Ultimates.
- AktivesBrett hat ADR-0073 und die Vorlage nicht gesehen; seine zehn
  und zwei fehlen.
- Ob die Tagesgrube eine Ultimate bekommt.
- Alle Zahlen der Ultimate (ein Achtel je Kill, 76 und 50 Punkte) sind
  geschätzt.
- Issue #115 „Neue Items“ ist nicht angesehen.

## 13.10.2026: Kampfgefühl — die Grube antwortet lauter

Frederik schickte den Block als Auftrag: Die Welt meldet schon alles
(`HitLanded`, `EntityDied`, `AbilityCast`), der Renderer antwortete nur
zu leise. Gebaut ohne Fragerunde, die Vorgaben standen im Auftrag.

| Was | Wie |
|---|---|
| **Klang** | fünf neue: der Held trifft, wird getroffen, ein Gegner fällt, eine Fähigkeit, eine Ankündigung |
| **Trefferstopp** | fällt ein Gegner oder sitzt ein kritischer Treffer, stehen Welt und Bild 50 ms; danach 150 ms keiner |
| **Beben** | kurz und klein (0,18 s, 3 Punkte), wenn der Held getroffen wird; die Landung des Wächters bleibt die stärkere |
| **Roter Rand** | unter 25 % Leben, kräftiger mit jedem Verlust, mit ruhigem Puls aus der Zeit des Laufs |

**Keine Zahl des Kampfes ändert sich.** Während des Stopps vergeht in
der Welt keine Zeit, also zahlt ihn auch die Uhr des Laufs nicht.

**Ohne Rückfrage entschieden:**

- **Die Klänge sind gerechnet, nicht aufgenommen**
  (`tool/kampf_klaenge.py`: Rauschen, Sinus, Hüllkurve). Auf der Platte
  lag nichts für den Kampf, und so gibt es keine Lizenz zu klären. Es
  sind Platzhalter; tauschen ist eine Datei oder eine Zeile in
  `SoundEffect`.
- **Fünf Klänge statt vier**: „getroffen“ kam dazu, sonst klänge der
  eigene Schlag wie der kassierte.
- **Ein Tick Dauerschaden löst nichts aus**, weder Klang noch Beben —
  sonst wäre die Pfütze des Sumpftrolls ein Dauerton.
- **Jeder Klang höchstens einmal je Bild und nie dichter als 70 ms**;
  ein Kill schluckt den Treffer, der ihn gebracht hat (`KampfKlang`).
- **Die Ankündigung wird gezählt**, nicht gemeldet: Stehen mehr
  Ankündigungen da als im Bild davor, holt jemand aus. Die Welt bekam
  dafür kein neues Ereignis.
- **`ActionGame` verlangt den Klang als Pflichtfeld.** Mit einem stillen
  Standard bliebe ein Lauf stumm, sobald eine Stelle ihn vergisst
  (`gotchas.md`, zweimal).
- **Der Schrei des Kreischpilzes und der Tod des Helden** haben weiter
  keinen Klang.

Neu: `lib/action/kampfgefuehl.dart` (reine Rechnung),
`tool/kampf_klaenge.py`, fünf Dateien unter `assets/Sound/`,
`test/kampfgefuehl_test.dart`.

App 789 (vorher 768). Der rote Rand gerendert in 390 × 844 und
angesehen, mit Würfeln statt Figuren. **Kein Klang gehört, nicht
gespielt, nicht am Handy.**

### Offen

- **Wie die Klänge klingen**, weiß niemand. Der Treffer fällt etwa jede
  halbe Sekunde; ist er zu laut oder zu spitz, nervt er nach einer
  Minute.
- **Verzögerung im Browser**: Je Klang gibt es einen Player, und ein
  neuer Start schneidet den alten ab. Ob das am Handy knackt oder
  nachhängt, zeigt nur das Gerät.
- Ob 50 ms Stopp bei jedem Kill gut sind oder im Gedränge stören.
- Es gibt keinen Schalter „Ton aus“ — bisher klang die App nur bei
  Häkchen und Feiern, jetzt klingt sie dauernd.
- Rot war in der Grube dem Wächter vorbehalten. Der Rand ist keine
  Fläche in der Welt, aber dieselbe Farbfamilie.
- Die vier älteren Klänge (`Success.mp3`, `Win*.mp3`) haben weiter keine
  Herkunft im Repo.

## 11.10.2026, danach: die Tagesgrube — eine Grube für alle, ein Versuch am Tag

Frederik: „Tagesgrube lets go.“ Die erste der fünf Ideen aus ADR-0071,
in zwei Fragerunden entschieden und gebaut:
[ADR-0072](../decisions/0072-die-tagesgrube.md).

| Was | Wie |
|---|---|
| **Dieselbe Grube für alle** | der Startwert kommt aus dem Datum, daraus Karte, Wächter und Besetzung |
| **Ein Held für alle** | die Werte eines fleißigen Spielers an Tag 30; je Wochentag ein fester Satz aus Waffe und drei Fähigkeiten |
| **In Form** | alles Fällige erledigt: +25 % auf alle vier Werte, ja oder nein; ein Ruhetag geht ohne Aufschlag |
| **Ein Versuch** | zählt mit dem Start; wer mittendrin schließt, hat abgebrochen; „Zurück“ fragt nach und hält den Lauf an |
| **Nur Ruhm** | antreten 1, Sieg 3, Sieg in Form 5 — weder Erfahrung noch Gold, keine Beute |
| **Der Text** | Raumzeile, Zeit, Form, Tageskette und die Adresse, in die Zwischenablage |
| **Wo** | im Eingang der Grube ganz oben, sobald jemand einmal unten war |
| **Die Dailies** | gestrichen (ADR-0040 abgelöst); was sie gezahlt haben, zählt weiter |

Achtmal entschieden, siebenmal wie empfohlen. **Bei den Dailies gegen
Claudes Empfehlung**: Sie lautete, sie eine Woche neben der Tagesgrube
stehen zu lassen.

**Gemessen:**

- **Die Grube hat eine scharfe Kante.** Derselbe Held gewinnt Stufe 11
  zu 92 % und Stufe 13 zu 8 %; ein Viertel mehr auf alle Werte macht
  aus den 8 % 96 %. Deshalb reicht ein Viertel als Aufschlag.
- **Die sieben Sätze** stehen auf Stufe 11 bis 13
  (`tool/tagesgrube_sim.dart`, 40 Läufe je Feld). Ohne Form gewinnt der
  Bot zwischen 20 % (Sonntag) und 78 % (Donnerstag), im Mittel jeden
  zweiten Lauf; in Form jeden. Ein Sieg dauert ihm rund eine Minute.
- **Ohne Dailies** (`runway_sim`, fleißiger Spieler): an Tag 30 Level 18
  statt 21 und 1.991 Gold statt 2.482; an Tag 60 Level 29 statt 33,
  37 Seiten statt 41, 4.286 Gold statt 5.759. Nicht ausgeglichen.
- **Dieselbe Grube auf jedem Gerät:** Ein Test hält die Karte vom 12.10.
  als Zahl fest. Er läuft in der VM und im Browser
  (`dart test -p chrome`), beide ergeben dieselbe.

**Beim Ansehen gefunden** (gerendert in 390 × 844 mit Roboto):

- **Die Raumzeile war „dunkel, dunkel, dunkel“.** Die Farben der Palette
  sind für Schrift gemacht; als Feld wurde das Gold ein Braun. Sie hat
  jetzt drei eigene Farben und einen Rand.
- Das Zeichen der Form hing am Titel statt am rechten Rand.
- **Breite Dialoge deckten die Kante ihres Holzrahmens zu**, links und
  rechts eine Lücke so hoch wie der Text. Das traf jeden Dialog mit
  einem Satz und ist jetzt in `HolzRahmen` behoben (`gotchas.md`).

Neu: `packages/action_combat/lib/src/daily_pit.dart`,
`tool/tagesgrube_sim.dart`, `lib/action/daily_pit_screen.dart`,
`lib/combat/daily_pit_controller.dart`, `tagesgrube_text.dart` und vier
Widgets unter `lib/combat/widgets/`. Die Karte kennt jetzt ihre Räume
(`Level.rooms`), die Welt zählt den Schaden je Raum. Gelöscht:
`dailies.dart`, `dailiesUnlockedProvider`, `todayDailiesProvider` und
die Sterne im Fahrstuhl.

App 768 (vorher 736), action_combat 305 (vorher 276). Eingang in fünf
Zuständen, beide Rückfragen, beide Ergebnisblätter und der Lauf
gerendert und angesehen, **der Lauf mit Würfeln statt Figuren. Nicht
gespielt, nicht am Handy.**

Gemergt am 11.10. als PR #112, zusammen mit #110 und #111.

### Offen

- **Wie schwer sie für Menschen ist.** Der Bot ist eine untere Schranke;
  ob „ohne Form“ ein fairer Kampf ist oder eine Wand, zeigt das Spielen.
- **Teilen geht über die Zwischenablage**, nicht über das Teilen-Blatt
  des Handys. Das sind am Handy drei Schritte statt einem, und es ist
  dort nicht geprüft.
- Die Startseite zeigt nicht, dass die Tagesgrube heute noch offen ist;
  man findet sie erst im Eingang der Grube.
- Ob ein Blitz mit einer Zahl daneben als „noch 2 offen“ gelesen wird.
- **Schlüssel**: Beute fiel bisher nebenbei bei den vier Dailies. Jetzt
  muss man dafür eine geschaffte Stufe von sich aus noch einmal spielen.
- Die Stufen sind grob: Donnerstag ist ohne Form deutlich leichter als
  Sonntag. Genauer ginge es nur über eigene Werte je Satz.
- Ein Deploy mitten am Tag kann die Grube für den Rest des Tages ändern,
  wenn er am Bau der Grube etwas ändert.
- ~~`konzept.md` kennt die Tagesgrube nicht.~~ Das stimmte nicht:
  Abschnitt 8 nannte sie seit PR #110 als ungebaut. Nach dem Merge
  nachgezogen.
- Die Dialoge im hängenden Rahmen füllen die ganze Höhe des Bildschirms,
  auch wenn sie zwei Zeilen tragen. Das war vorher schon so.
- AktivesBrett hat ADR-0072 nicht gesehen.

## 11.10.2026: Schadenszahlen, die man lesen kann

Frederik schickte ein Reel über Schadenszahlen in einem Roguelike
(„damage numbers that feel good and don't break your game“). Die Zahlen
der Grube stiegen gerade hoch, waren immer gleich groß und stapelten
sich. Als Prototyp gebaut, dann „Sehr gut mach das“: PR #111.

| Aus dem Reel | In der Grube |
|---|---|
| Punch bei der Geburt | die Zahl erscheint 1,6-fach und setzt sich in 0,12 s |
| Bogen, Seiten wechseln | Treffer fliegen abwechselnd links und rechts im Wurf; Heilung, Zeit und Beute steigen weiter gerade |
| erst am Ende verblassen | voll sichtbar bis 70 % der Lebenszeit, vorher 50 % |
| eine Farbe je Sache | neu: Dauerschaden ist violett |
| Größe folgt dem Schaden | gemessen am Schnitt der letzten zwölf Treffer des Helden, 0,8- bis 1,6-fach |
| ein kritischer Treffer als Moment | größer, schräg, zittert 0,3 s — kritische gibt es weiter nur im Prototyp |
| zusammenzählen | Treffer auf denselben Gegner binnen 0,3 s werden eine Summe |
| nie zu viele | höchstens 40 zugleich |

**Anders als im Reel:** Zusammengezählt wird nur 0,3 s lang, nicht
solange die Zahl in der Luft ist — der Grundangriff fällt etwa jede
halbe Sekunde, sonst stünde über jedem Gegner nur eine wachsende Summe.
Dauerschaden ist violett und nicht giftgrün, weil Grün die Heilung ist.
Und die Zahlen werden nicht wiederverwendet; bei höchstens 40 lohnt es
nicht.

`HitLanded` trägt dafür ein Pflichtfeld `overTime`, das nur die Anzeige
liest. Die Rechnung steht in `lib/action/damage_popup.dart`
(`DamagePopup`, `HitAverage`, `DamagePopups`).

App 736 (vorher 716). **Nicht angesehen**, weder gerendert noch
gespielt. Gemergt am 11.10. als PR #111.

### Offen

- Ob Bogen, Größe und das Fenster von 0,3 s sich gut anfühlen.

## 09.10.2026: das nächste Level — fünf Ideen, nach und nach

Frederik fragte, was das Konzept auf das nächste Level bringt und Erfolg
sichert. Claude hat fünf Ideen vorgeschlagen, Frederik: „finde alle Ideen
super, halt die auf jeden Fall fest, das bauen wir nach und nach.“ Die
Richtung steht in [ADR-0071](../decisions/0071-das-naechste-level.md),
die Einzelheiten und die Fragen für die Konzeptrunden in der Vorlage
[`docs/vorlagen/das-naechste-level.md`](../vorlagen/das-naechste-level.md).

| Idee | in einem Satz |
|---|---|
| **Tagesgrube** | dieselbe Grube für alle, aus dem Datum gesät, ein Versuch, ein Einheitsheld; stärker macht nur, ob man heute in Form ist; danach ein Text zum Teilen, wie bei Wordle |
| **Lagerfeuer** | abends eine Minute für Rückfrage, Truhe, Aufgaben und Wochenrückblick statt fünf Dingen, die um Mitternacht verfallen |
| **Schatten** | ganz unten wartet man selbst, wie man vor 30 Tagen war; die vier Wächter werden innere Gegner |
| **Saisons** | sechs Wochen, ein Thema aus einem gelesenen Buch: Seiten, Vorlagen, ein Wächter, etwas fürs Haus |
| **Seilschaft** | zwei bis vier an einem Seil; wer einen fälligen Tag verpasst, wird einmal die Woche gehalten; der erste Server |

**Positionierung:** das Spiel, das dich wegschickt. **Grundsatz:**
weniger Systeme, die enger zusammenhängen — vier der fünf bündeln, was
es schon gibt. **Nichts davon ist gebaut**; jede Idee bekommt vor dem
Bau ihre Konzeptrunde.

**Beim Nachsehen im Code gefunden**, beides steht in der Vorlage:

- **Die Tagesgrube ist fast da.** Karte, Wächter und Besetzung kommen
  schon aus dem Startwert; nur `PitScreen._neuerLauf` würfelt ihn frei.
- **Der Schatten kann nicht an den Werten von damals hängen**: Sie sind
  nach 32 bis 40 Häkchen je Wert gedeckelt. Und nicht jede Erfahrung
  trägt ein Datum — Häkchen und Rückfragen schon, Seiten und erste Siege
  nicht.

Dabei aufgeräumt: Die Einträge vom 26.09. bis 01.10. stehen jetzt
wortgleich in [`verlauf.md`](verlauf.md).

### Offen

- Reihenfolge (Tagesgrube, Lagerfeuer, Schatten, Saisons, Seilschaft)
  und Messlatte (zehn Fremde, zwei Wochen, drei teilen noch) sind
  Claudes Vorschlag, nicht ausdrücklich bestätigt.
- ~~Ob die vier Dailies in der Tagesgrube aufgehen (ADR-0040).~~
  Entschieden am 11.10.: Sie gehen (ADR-0072).
- AktivesBrett hat ADR-0071 nicht gesehen.

## 07.10.2026, danach: das Handbuch steht im Baum

Frederik: „Ja“ zum Handbuch als nächstem Block. In zwei Fragerunden
entschieden, zweimal gegen Claudes Empfehlung:
[ADR-0070](../decisions/0070-das-handbuch-steht-im-baum.md).

| Was | Wie |
|---|---|
| **Kein Handbuch-Bildschirm mehr** | die fünf Seiten sind Knoten unter *Gewohnheiten*, der Baum ist immer offen |
| **Sie kosten einen Punkt** | nichts im Baum ist kostenlos; dafür beginnt jeder mit **neun Punkten** statt einem |
| **Ins Buch einsortiert** | „Zwei Minuten reichen“ ist Regel 3 unter „Die vier Regeln“, die anderen vier hängen unter *Gewohnheiten* |
| **Direkt zur nächsten** | nach einer bestandenen Seite steht ein Knopf mit der nächsten; ist sie noch zu, öffnet der Tipp sie, der Preis steht darauf |
| **Der Baum schlägt vor** | solange nichts offen ist, steht bei „Weiterlesen“ der nächste Schritt zu den Grundlagen: zuerst „Geist“, ein Punkt |

**Ohne Rückfrage entschieden**, weil es sonst nicht aufgeht:

- **Neun, weil der Weg neun kostet**: Geist, Selbstentwicklung,
  Gewohnheiten, Die vier Regeln und die fünf Seiten
  (`theoryBasicsPath`). Ein Test hält beide Zahlen zusammen.
- **Gezählt wird nur noch der Graph.** Die fünf Seiten stehen im Graphen
  und im alten Zweig; beides zusammen zählte sie doppelt.
- **Alte Stände behalten alles** und bekommen acht Punkte dazu. Wer das
  Handbuch bestanden hatte, hat die Seiten und ihren Weg offen, ohne
  dafür bezahlt zu haben.
- **Die Einführung „Gewohnheiten“ ist umgeschrieben**: Sie verwies auf
  das Handbuch als schon Gelesenes und steht jetzt davor.
- **Der Kreis der Fähigkeiten erscheint wie bisher** (fünf Seiten
  bestanden oder eine Fähigkeit gelernt).

Gelöscht: `branch_screen.dart`, `lesson_tile.dart`, `handbookProvider`
und die zwei Provider daran. ADR-0025 ist abgelöst.

**Gemessen** (`runway_sim`, fleißiger Spieler): an Tag 60 sind 41 Seiten
gelesen statt 38, Level und Gold bleiben praktisch gleich. Die acht
Punkte mehr stehen gegen fünf Seiten, die vorher nichts kosteten.

**Dabei gefunden: Der erste Lauf ist härter, als ADR-0068 sagt.** Die
93 % für Stufe 1 an Tag 0 enthielten die 275 Erfahrung des Handbuchs,
also Level 3. Seit ADR-0068 geht es aber vor jeder Seite hinab. Auf
Level 1 gemessen (`pit_sim`, 12 Läufe je Feld): **Stufe 1 bei 67 %,
Stufe 2 bei 17 %** (vorher 92 % und 75 %); je Wächter zwischen 42 %
(Schlund) und 100 % (Sumpftroll). Das ist keine Folge dieses Umbaus,
sondern eine Annahme der Simulation, die seit gestern nicht mehr
stimmte; `pit_sim` rechnet Tag 0 jetzt auf Level 1. **Nicht
nachgestellt**, Balance ist zurückgestellt.

**Beim Ansehen gefunden** (gerendert in 390 × 844): Der Preis auf dem
Knopf zur nächsten Seite ging im Holz unter, er ist jetzt hell.

theory 193 (vorher 174), App 716 (vorher 707). Der Baum eines neuen
Stands, *Gewohnheiten* mit den neuen Knoten, „Die vier Regeln“ und das
Ergebnis mit dem Knopf gerendert und angesehen. **Nicht gespielt, nicht
am Handy.**

Gemergt am 07.10. als PR #109, zusammen mit #107 und #108.

### Offen

- **Stufe 1 am ersten Tag** gewinnt der Bot in zwei von drei Läufen. Ob
  das als erster Eindruck trägt, und ob eine Niederlage dort jetzt zu
  oft kommt, zeigt das Spielen.
- Neun Punkte auf einmal sind eine große Wahl beim ersten Blick auf den
  Baum. Der Vorschlag führt, erklärt aber nicht, warum.
- Ein Tipp auf den Knopf zur nächsten Seite gibt einen Punkt aus, ohne
  Rückfrage.
- Wer die neun Punkte woanders ausgibt, hat die drei Vorlagen aus den
  Grundlagen und ihre Plätze für eigene Gewohnheiten erst später.
- Die umgeschriebene Einführung „Gewohnheiten“ ist nicht gegengelesen.
- `konzept.md` zeigt den Baum noch mit zwei Wurzeln und dem Handbuch
  davor.
- AktivesBrett hat weder ADR-0068 noch -0069 noch diesen gesehen.

## 07.10.2026: die Grube erklärt sich im ersten Lauf

Frederik: „bau gerne weiter“. Der nächste Block war die Lücke, die
ADR-0068 selbst offen ließ: Wer nach dem ersten Häkchen hinabsteigt,
sah eine stehende Figur und keinen Knopf. In einer Fragerunde
entschieden:
[ADR-0069](../decisions/0069-die-grube-erklaert-sich-im-ersten-lauf.md).

| Was | Wie |
|---|---|
| **Laufen** | ein Geister-Steuerkreuz links unten, ein Finger zieht reihum in alle vier Richtungen; weg nach anderthalb Feldern |
| **Schlägt von selbst** | beim ersten Schlag steht vier Sekunden die Waffe in zwei drehenden Pfeilen über dem Helden |
| **Wie lange** | bis die erste Stufe geschafft ist, abgeleitet aus der Reihe; unsere Stände sehen nichts davon |
| **Niederlage** | solange keine Stufe geschafft ist, steht neben „Nochmal“ das Buch „Stärker werden“ und führt in die Theorie |

**Nicht gewählt** (Frederik): Zeichen für die Uhr und für „Rot heißt
weg“.

**Ohne Rückfrage entschieden**, weil es sonst nicht aufgeht:

- **Die Zeichen nehmen keinen Tipp an**; das echte Steuerkreuz liegt
  darunter.
- **Das Zeichen am Helden weicht der Kopfzeile aus** und sitzt dann
  unter ihm.
- **Das Buch ersetzt die Grube im Stapel**: „Zurück“ aus der Theorie
  führt zum Eingang, nicht in den verlorenen Lauf.
- **„Zurück“ nach einer Niederlage trägt jetzt die Farbe für Leder.**

**Beim Bauen gefunden, ein alter Fehler:** Flame ruft im Bau
`update(0)`, und der Bildzähler weckte die Kopfzeile mitten im Layout.
Das geschah nach jeder Niederlage, nur im Debug-Build sichtbar, und kein
Test ging durch eine Niederlage (`gotchas.md`).

**Beim Ansehen gefunden** (gerendert in 390 × 844): Das Zeichen am
Helden lag unter der Kopfzeile, wenn die Kamera am Rand der Grube
anhält. Und der neue Knopf war in den Farben des Themes auf Leder kaum
zu lesen.

Neu: `lib/action/lauf_zeichen.dart`, `lauf_zeichen_view.dart`,
`test/erster_lauf_test.dart`. App 707 (vorher 691). Geisterkreuz,
Zeichen am Helden und die Niederlage mit Buch gerendert und angesehen,
**mit Würfeln statt Figuren. Nicht gespielt, nicht am Handy.**

Gemergt am 07.10. als PR #108.

### Offen

- Ob zwei drehende Pfeile um die Waffe als „von selbst“ gelesen werden.
- Uhr, Zeitkugeln, Tor und die Ankündigungen des Wächters erklärt weiter
  nichts.
- Wer mit einer Fähigkeit hinabsteigt, erfährt nicht, dass Halten und
  Ziehen zielt.
- Steht der Held am oberen Rand der Grube, liegt er selbst unter der
  Kopfzeile; der Zähler „0 / 17 erledigt“ ist auf heller Wand schwer zu
  lesen. Beides älter als dieser Block.
- AktivesBrett hat weder ADR-0068 noch diesen gesehen.

## 06.10.2026: der erste Start — Frage, dann Kreis für Kreis

Frederik: „weiter an der UX und UI arbeiten“, aus vier Blöcken gewählt:
**der erste Start**. In drei Fragerunden entschieden:
[ADR-0068](../decisions/0068-erster-start-deckt-die-bereiche-auf.md).

| Was | Wie |
|---|---|
| **Die erste Frage** | statt „Heute“ steht „Was willst du jeden Tag tun?“: sechs Vorschläge (ein Tipp legt an) und ein Feld für Eigenes mit den vier Werten als Zeichen |
| **Kreise nach und nach** | Kampf mit dem ersten Häkchen, Theorie nach dem ersten Lauf, Fähigkeiten mit dem Handbuch, Laden mit dem ersten bezahlbaren Stück, Ausrüstung mit dem ersten Stück, Charakter mit Level 2; jeder wächst an seinem Platz heran |
| **Der nächste leuchtet** | ein Punkt am Kreis und drei Pulse: Kampf, dann Theorie, dann Fähigkeiten |
| **Kampf früh** | die Grube ist nie mehr gesperrt, Stufe 1 geht mit der Waffe allein (`pit_sim` Tag 0: 93 % für den Bot) |
| **Abgeleitet** | kein Feld im Spielstand; eure Stände und jeder eingefügte sehen sofort alles |

**Ohne Rückfrage entschieden**, weil es sonst nicht aufgeht:

- **Die Frage ist eine Karte, kein Dialog.**
- **Der erste Vorschlag startet die Startvorlage**; die anderen und das
  freie Feld verbrauchen den einen Platz für eine eigene Gewohnheit.
- **Die Theorie kommt auch ohne Kampf**, mit dem dritten Häkchen.
- **„Ich habe schon einen Stand“ steht in der ersten Frage** — Einfügen
  gab es sonst nur im Charakter, und der kommt erst mit Level 2.
- **Tagesaufgaben stehen erst ab dem ersten Häkchen da.**

Gelöscht: `lib/action/pit_gate.dart`, `combatUnlockedProvider` und der
Satz am gesperrten Kreis; auch die Höhle im Dorf ist offen. ADR-0020 ist
abgelöst, das Handbuch sperrt weiter den Baum (ADR-0025).

**Beim Ansehen gefunden** (gerendert in 390 × 844 mit Roboto): Der
Leuchtring sah aus wie der Fortschrittsring der Gewohnheiten daneben,
jetzt ist es ein Punkt. Die Vorschläge standen mit doppeltem Abstand
untereinander.

App 691 (vorher 670), gear 118 (vorher 117). Die Frage, das Feld für
Eigenes und die Startseite nach dem ersten Häkchen und nach dem ersten
Lauf gerendert und angesehen. **Nicht gespielt, nicht am Handy.**

### Offen

- Ob Stufe 1 am ersten Tag für einen Menschen so leicht ist wie für den
  Bot, und was eine Niederlage im allerersten Lauf auslöst.
- ~~**Die Grube erklärt nichts**~~: Laufen und Schlagen seit ADR-0069;
  Uhr und Tor weiter ohne Einführung.
- ~~Das Handbuch ist weiter fünf Lektionen lang, bevor der Baum
  aufgeht.~~ Seit ADR-0070 steht es im Baum.
- Auslöser, Wochentage und Belohnung fragt am ersten Tag niemand von
  selbst; das geht erst über die Kachel.
- Level 2 für den Charakter und drei Häkchen für die Theorie sind
  gesetzt, nicht gemessen.
- AktivesBrett hat das nicht gesehen; die Kette aus ADR-0020/-0025 war
  eine gemeinsame Linie.

## 04.10.2026: Zeitziele laufen als Timer

Die Sitzung begann bei Regel 3, „Mach es einfach“. Zwei Vorschläge für
eine **kleine Fassung** je Gewohnheit (zählt voll / trägt nur die Kette)
hat Frederik abgelehnt („find ich beides nicht so gut“), drei weitere
(Wiederholungen zählen, Ziel in Stufen, Vorbereiten) nicht aufgegriffen.
Stattdessen: „wenn die Zeit-Sachen als richtiger Timer angezeigt
werden“. In einer Fragerunde entschieden:
[ADR-0067](../decisions/0067-zeitziele-als-timer.md).

| Was | Wie |
|---|---|
| **Starten** | eine Zeit-Gewohnheit trägt statt des Plus einen Timer-Knopf; ein Tipp auf sie öffnet das Blatt mit dem Ring |
| **Laufen** | gerechnet aus der Startzeit, nicht aus Ticks: läuft weiter, wenn das Blatt zu ist, die App im Hintergrund liegt oder neu lädt; Restzeit auf der Kachel und in „Heute“ |
| **Fertig** | bei null von selbst abgehakt, mit Klang und aufsteigenden Zahlen; war die App zu, beim Zurückkommen |
| **Anhalten** | was gelaufen ist, bleibt als Minuten stehen, der nächste Start macht dort weiter |
| **Von Hand** | „schon erledigt“ im Blatt |
| **Startvorlage** | „Zwei Minuten lesen“ läuft zwei Minuten, als einzige Vorlage |
| **Nur einer** | ein zweiter Start hält den ersten an |
| **Keine Zahl** | Erfahrung, Gold und Ketten ändern sich nicht (`timer_test.dart`) |

**Ohne Rückfrage entschieden**, weil es sonst nicht aufgeht:

- **Über Mitternacht gehört die Zeit dem Tag des Starts**: Wer um 23:50
  zwanzig Minuten liest, hat gestern gelesen.
- **Ein laufender Timer ist eine Behauptung wie ein Häkchen**: Wer
  startet und die App schließt, ist nach Ablauf abgehakt.
- **Das Plus „+5 Minuten“ gibt es nicht mehr**, nur noch für Mengen.
- Ein zweiter Start kostet den ersten seinen Rest unter einer Minute.

Neu: `packages/habits/lib/src/timer.dart`,
`lib/habits/widgets/habit_countdown.dart`, `habit_timer_sheet.dart`. Der
Ablauf eines Häkchens steht jetzt an einer Stelle für Tipp, Plus und
Timer (`_mitFeier` in `habit_check_flow.dart`).

habits 324 (vorher 298), App 670 (vorher 656). Blatt, Kacheln und
Startseite gerendert in 390 × 844 und angesehen, nichts gefunden.
**Nicht am Handy, nicht im Browser gespielt** — und gerade hier zählt
das: Ob der Timer eine Nacht im Hintergrund eines Handy-Browsers
übersteht, zeigt nur das Gerät.

### Offen

- **Regel 3 selbst hat weiter weder Mechanik noch Theorie-Seite.**
- **Kein Klang im Hintergrund**: Die Web-Fassung meldet null erst beim
  Zurückkommen. Eine Meldung kann erst die Android-App.
- Abgerechnet wird nur, wo eine Anzeige steht (Kachel, „Heute“, Blatt).
  Wer in der Grube ist, bekommt Häkchen und Tagesform erst danach.
- „Zwei Minuten lesen“ kostet von Hand jetzt zwei Tipps statt einem.
- Angehalten mitten in einer Minute zeigt die Kachel „12 / 20 Minuten“,
  das Blatt „07:20“.
- Eigene Gewohnheiten bekommen ihr Zeitziel nur beim Anlegen; eine
  bestehende ohne Ziel bekommt keinen Timer (ADR-0028).
- `tracker.dart` ist auf 1.858 Zeilen gewachsen.

---

Ältere Einträge: [`verlauf.md`](verlauf.md).
