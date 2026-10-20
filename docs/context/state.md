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

**Zuletzt aktualisiert:** 20.10.2026 · Frederik

---

## Übersicht: was steht

**Phase:** Testlauf (Ziel 7, 21.09.–20.10.2026). Alle Bauziele 1–6 und 8
sind erreicht; seit Teststart wurde trotzdem stark weitergebaut (siehe
„Offen“). **Als Nächstes: Ziel 9, der Play Store am 20.11.** — die Frist,
die zählt, ist der 26.10. (zwölf Tester im geschlossenen Test).

| Bereich | Stand | Wo nachlesen |
|---|---|---|
| **Gewohnheiten** | **ein Häkchen, das aufspringt, klingt und Münzen wirft**, **das Lagerfeuer am Abend mit Truhe, Aufgaben, Rückfrage und „Morgen zuerst“**, Vorlagen und eigene, **Wochenplan je Gewohnheit**, **Koppeln zu Stapeln**, Streaks, **die fallen statt zu reißen**, **Tageskette**, Streak-Eis, Tagesform, Tagestruhe, **Tagesaufgaben**, Wochenrückblick, Auslöser „Wann machst du das?“, **Belohnung danach**, **Zeitziele als Timer**, Startvorlage | ADR-0028, -0036, -0043, -0044, -0052, -0055, -0064, -0065, -0066, -0067 |
| **Startseite** | sieben Kreise, **die nach und nach erscheinen**, **ein Mentor, der durch den ersten Start führt**, Level-Abzeichen und Gold in einer Zeile, „Heute“ zum Abhaken, **darunter das Lagerfeuer**, **am Anfang die Frage nach der ersten Gewohnheit** | ADR-0049, -0053, -0057, -0058, -0068, -0076, -0079 |
| **Wissensbaum** | **jede Seite eine Spielrunde wie bei Duolingo**, vier Wurzeln, Zwischenebenen, 63 Knoten, 15 angekündigte Überschriften, ein Punkt je Knoten, **ein Startpunkt, einer je Aufstieg**, **das Handbuch als fünf Knoten unter Gewohnheiten**, **direkt zur nächsten Seite**, Rückfrage des Tages, **falsche Antworten kommen noch einmal**, **Ring und Zähler an jedem Knoten, Gebietsbalken, „Weiterlesen“** | ADR-0019, -0045, -0050, -0051, -0055, -0056, -0061, -0070, -0078 |
| **Kampf** | die Grube: Echtzeit, 30 Stufen, gesteckte Räume, **elf Gegnerarten in gewürfelter Besetzung**, **vier Wächter, je Lauf gewürfelt**, Tor und Auftritt, Uhr, Beute je Gegner, **zwei Zeichen im ersten Lauf**, **die Tagesgrube: eine für alle, ein Versuch am Tag** | ADR-0039, -0041, -0046, -0062, -0063, -0069, -0072 |
| **Stärke** | Level und Seltenheit vervielfachen, Gewohnheiten addieren | ADR-0042 |
| **Ausrüstung** | Exemplare mit Würfen, Tagesladen, Beute mit Schlüsseln, Sets, Legendäre, Verkauf zu einem Viertel, **eigener Bereich mit allen 60 Stücken**, **Rahmen und Name in der Farbe der Seltenheit**, **Kräfte auf jeder Seltenheit, das Vampirset** | ADR-0029–0031, -0034, -0047, -0048, -0057, -0077 |
| **Fähigkeiten** | 39 Fähigkeiten und 8 Waffenzüge in der Grube, **vier Ultimates auf eigenem Platz ab Level 15**, **drei Passive ohne Knopf**, neunundzwanzig Arten von Wirkung, eigener Bereich mit allen Werten | ADR-0022, -0049, -0073, -0074 |
| **Errungenschaften** | 22 Meilensteine, 8 Entdeckungen, 13 Titel | ADR-0033, -0073, -0074 |
| **Speicher** | lokal im Browser, **als Text sicherbar** | ADR-0010, -0054 |
| **Prototyp** | das Dorf, nur im Entwicklermodus | — |

**Tests:** App 882, dazu die acht Packages (theory 204, habits 333, gear
120, action_combat 381, progression 44, abilities 43, identity 25,
achievements 24). **In der CI laufen nur die App-Tests** — der Umbau,
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

## 20.10.2026, danach: der Mentor führt durch den ersten Start

Frederik: „Super wäre natürlich noch ein klares Tutorial … Gewohnheit →
erste Theorie-Seite → erste Fähigkeit ausrüsten → Grube → erster
Gegenstand ausrüsten. Und das halt bisschen fester begleitend bei neuen
Nutzern mit Erklärung und Tooltips.“ In einer Fragerunde entschieden:
[ADR-0079](../decisions/0079-der-mentor.md).

| Frage | Antwort |
|---|---|
| Reihenfolge | **Frederiks**, gegen Claudes Empfehlung (Grube vor der Fähigkeit, ohne eine Zahl zu ändern) |
| Erste Fähigkeit | **für alle dieselbe, mit der ersten Seite** — „damit alle das gleiche Feeling haben“ |
| Wie fest | **Zeigefinger**: Kasten mit Satz, Ring ums Ziel, alles bleibt tippbar |
| Überspringen | **nein** |
| Wer erklärt | **eine Figur** — das Bild schickt Frederik |

| Was | Wie |
|---|---|
| **Funkenstoß mit der ersten Seite** | neue Errungenschaft „Erste Seite“ (30 EP, 10 Gold, 5 Ruhm); „Die kleinste Dosis“ bringt ihn nicht mehr |
| **Zweiter Platz auf Level 2** | statt 3 — ein Häkchen und die erste Seite bringen mindestens 115 Erfahrung |
| **Der Weg** | Gewohnheit → abhaken → erste Seite → Fähigkeit anlegen → Grube → im Beute-Dialog „Anlegen“ |
| **Die Kreise** | in derselben Reihenfolge: Theorie mit dem Häkchen, Fähigkeiten mit der Seite, Kampf mit der angelegten Fähigkeit (oder einem Lauf, oder sieben Häkchen) |
| **Der Mentor** | ein Kasten auf Startseite, Baum, Fähigkeiten und Eingang; sein letzter Satz im Beute-Dialog des ersten Siegs. Er nimmt keinen Tipp an |
| **Der Ring** | um Fragekarte, „Heute“, „Weiterlesen“, die neue Fähigkeit, „Hinab“, „Anlegen“; pulsiert fünfmal und bleibt stehen |

**Abgeleitet, nicht gespeichert** (`ErsterStart.schritt`), wie die
Kreise seit ADR-0068: Wer schon weiter ist, sieht den Mentor nie.

**Ohne Rückfrage entschieden:**

- **Er heißt im Code Mentor**, nicht „Führer“: Das Wort ist im
  Deutschen zu belastet. Einen Namen auf dem Bildschirm hat er noch
  nicht.
- **Funkenstoß** als erste Fähigkeit, über eine Errungenschaft — sie
  vergeben schon Fähigkeiten, und auf Funkenstoß ist `pit_sim` gemessen.
- **Der erste Gegenstand ist kein eigener Schritt**: Das Spiel legt ihn
  ohnehin selbst an, wenn der Platz leer ist. Der Mentor spricht deshalb
  im Beute-Dialog und zeigt dort auf „Anlegen“.
- **Wer zuerst liest, wird zum Häkchen geschickt**: Auf Level 1 ist der
  zweite Platz zu.
- **Die Grube zeigt sich nach sieben Häkchen auch ohne Seite** — nicht
  zu sperren, aber nicht gleich.
- **Auf der Startseite steht der Kasten über der unteren Reihe**, in der
  leeren Mitte.

**Beim Ansehen gefunden** (gerendert in 390 × 844): Die Funkenstoß-Kachel
schrumpfte im Ring auf ihren Inhalt (`gotchas.md`), und oben auf der
Startseite deckte der Kasten Gewohnheiten und Theorie zu.

**Nebenbei behoben:** Unter einem zu teuren Knoten stand „Jeder
Levelaufstieg gibt zwei“ — seit ADR-0035 ist es einer.

Neu: `lib/mentor/` (drei Dateien), `test/mentor_test.dart` (16 Tests).
App 882 (vorher 863), achievements 24, abilities 43, progression 44,
theory 204 — die Pakete gleich in der Zahl. Startseite in fünf
Schritten, Baum, Fähigkeiten, Eingang und Beute gerendert und
angesehen. **Nicht am Handy, nicht im Browser gespielt.**

### Offen

- **Das Bild des Mentors** — und ob er einen Namen bekommt.
- **Die erste Grube ist leichter**: Wer folgt, geht mit Funkenstoß und
  auf Level 2 hinab. Nicht neu gemessen.
- Ob der Mentor in den Gewohnheiten, im Laden oder in der Ausrüstung
  auch etwas sagen soll — dort schweigt er bisher.
- Ob er sich nach dem ersten Sieg verabschieden soll; bisher endet er
  mit dem Satz zur Beute.
- AktivesBrett hat ADR-0079 nicht gesehen, auch nicht, dass der zweite
  Platz jetzt auf Level 2 aufgeht.

## 20.10.2026: ein Startpunkt statt neun

Frederik hat einen Bekannten spielen sehen: eine eigene Gewohnheit (10
Liegestütze) angelegt, abgehakt, damit Level 2 und **zehn Punkte** —
und dann in der Theorie **Körper komplett** gelesen, Wurzel und sechs
Themen. Die Grundlagen hat er nie gesehen. Frederik: „Mein Bauchgefühl
würde trotzdem nur ein Skillpunkt für Level 2 geben, da der Nutzer schon
so daran gewöhnt wird, dass ein Level ein Skillpunkt bringt.“
[ADR-0078](../decisions/0078-ein-startpunkt.md).

| | vorher (ADR-0070) | jetzt |
|---|---|---|
| Level 1 | 9 Punkte | **1** |
| Level 2 | 10 | **2** |
| Level 3, zweiter Fähigkeitsplatz | 11 | **3** — genau der Weg zur ersten Fähigkeit |
| ein Spielerleben | 58 | 50 |

**Ohne Rückfrage entschieden:** „ein Skillpunkt für Level 2“ gelesen
als: einer zum Start, einer je Aufstieg, auf Level 2 also zwei. Mit null
zum Start stünde die Theorie offen, und nichts ließe sich öffnen.

**Gerechnet:** Ein Häkchen und die erste Seite geben genau 100
Erfahrung (15 + 30 für „Erster Schritt“ + 55), also Level 2 und den
Punkt für die nächste Seite. Ohne Häkchen bleibt man nach der ersten
Seite stehen — gewollt. `runway_sim`, Tag 60: Level 29 wie vorher, aber
28 Seiten statt 37 und 4.061 Gold statt 4.286.

**Alte Stände**: Wer seine neun Punkte ausgegeben hat, behält alles
Gelesene, bekommt aber die nächsten acht Aufstiege keinen freien Punkt.
Das trifft eure beiden Stände und den des Bekannten.

App 863, progression 44, beide unverändert in der Zahl.

### Offen

- **Das Tutorial**: Frederik wünscht sich einen festen Weg für neue
  Spieler — Gewohnheit, erste Seite, erste Fähigkeit, Grube, erster
  Gegenstand, mit Erklärung und Tooltips. Die Konzeptrunde läuft.
- Ob alte Stände ihre acht Punkte zurückbekommen sollen.
- AktivesBrett hat ADR-0078 nicht gesehen.

## 19.10.2026, spät: jede Seite ist gesetzt

Frederik: „machs bei allen anderen, ich hab die Kraft-Seite schon
durchgelesen bei mir.“ Alle 58 übrigen Seiten haben jetzt Betonung und
einen Merksatz, wie die fünf Kraft-Seiten.

| | |
|---|---|
| **Betont** | je Abschnitt ein bis drei Stellen, 175 Abschnitte |
| **Merksatz** | genau einer je Seite, 58 neue; ein Test hält „genau einer“ fest |
| **Der Text** | Wort für Wort derselbe — ein Skript hat jeden Abschnitt gegen den alten verglichen, ohne die Zeichen |

**Die Merksätze sind neu geschrieben**, aber sie fassen nur zusammen,
was auf der Seite steht; keiner bringt eine neue Behauptung. Gegengelesen
hat sie niemand. Betroffen sind auch die alten Zweige (Körper, Geist,
Wissenschaft, Gesellschaft), deren Seiten im Graphen hängen.

theory 204 (vorher 203), App 863. **Nicht am Handy angesehen.**

## 19.10.2026, abends: der Lesetext schreibt sich

Frederik: „ich hätte gerne, dass bei dem Theorie-Teil die Lerntexte
nach und nach geschrieben werden … also mit Animation und mit
verschiedenen Textgrößen und Formatierung noch mehr gespielt werden.“
Gebaut ohne Fragerunde als Prototyp.

| Was | Wie |
|---|---|
| **Die Überschrift fällt herein** | 22 Punkte, schiebt sich in 0,28 s von unten ins Bild |
| **Wort für Wort** | rund 40 ms je Wort, jedes blendet über drei Wörter ein; ein Abschnitt steht nach zwei bis drei Sekunden |
| **Ein Tipp zeigt alles** | auf den Text; zurückgeblättert schreibt sich nichts noch einmal |
| **Drei Größen** | der erste Satz 18 und halbfett, der Rest 16, ein Merksatz 20 und fett auf eigener Fläche mit Balken, die aufspringt |
| **Betont** | fett, in der Farbe der Seite |

**Der Inhalt bekommt zwei Zeichen** (`Lesetext` in `packages/theory`):
`**betont**` und ein ganzer Absatz in `==…==` als Merksatz. Ein Test
prüft jede Seite auf offene Zeichen. **Gesetzt sind bisher nur die fünf
Kraft-Seiten**, wie bei Rätsel und Fall: je zwei bis drei Betonungen
und ein Merksatz. Die Merksätze sagen nichts Neues, sie stehen so oder
fast so schon auf der Seite. Alle anderen Seiten schreiben sich auch,
mit großem erstem Satz, aber ohne Betonung und Merksatz.

**Ohne Rückfrage entschieden:** Wort für Wort statt Buchstabe für
Buchstabe — schneller, als man liest, damit niemand wartet. Der Text
steht von Anfang an im Layout, nur durchsichtig: Nichts springt, und
der Vorleser bekommt ihn ganz. Kein Klang je Wort. Wer Bewegung im
System abgeschaltet hat, bekommt alles sofort.

theory 203 (vorher 197), App 863 (vorher 857). Die erste Kraft-Seite
in 390 × 844 gerendert und angesehen, mitten im Schreiben und fertig.
**Nicht am Handy, nicht gespielt.**

### Offen

- Ob 40 ms je Wort sich richtig anfühlen oder ungeduldig machen.
- Ob die übrigen 58 Seiten Betonung und Merksatz bekommen — Schreibarbeit
  wie bei Rätsel und Fall, am besten in einem Zug.

## 19.10.2026, danach: die App wird store-fähig

Frederik: „ja leg los mit dem Code“. Der Code-Teil aus
[`play-store.md`](../vorlagen/play-store.md), soweit er ohne euch geht:

| Was | Wie |
|---|---|
| **Zurück fragt nach** | auch in der Grube, nicht nur in der Tagesgrube: „Lauf abbrechen?“, der Lauf hält an. Eine Stelle für beide (`lauf_verlassen.dart`) |
| **Tablets** | `PhoneFrame` zeigt die App ab 600 dp kürzester Seite im Rahmen, quer verkleinert (`gotchas.md`) |
| **Startbild** | Lederfarbe statt Weiß, ab Android 12 auch im Startbild des Systems |
| **Signieren** | `build.gradle.kts` liest `android/key.properties`; ohne sie wie bisher der Debug-Schlüssel |

**Der erste Android-Build auf diesem Rechner** lief durch:
`app-release.aab`, 57 MB, mit dem Debug-Schlüssel. Flutter meldet
„failed to strip debug symbols“ — dafür fehlen die cmdline-tools. Gradle
hat SDK Platform 35 beim Bauen selbst nachgeladen.

**Ohne Rückfrage entschieden:** Wer die Grube abbricht, verliert, was
gefallen ist — gebucht wird nur am Ende eines Laufs, wie bisher. Im
Rahmen auf dem Tablet hält sich die App weiter für so groß wie das
Tablet, wie im Browser.

App 857 (vorher 850). **Nicht am Handy, nicht am Tablet, das Startbild
nicht gesehen.**

## 19.10.2026: der Play Store am 20.11.

Frederik: „Wir wollen bald die App in den Android Store kriegen um
Feedback zu sammeln. Was müssen wir dafür noch machen?“ Claude hat das
Repo durchgesehen und eine Liste geschrieben, danach Frederik: „Wir
wollen am 20.11 in den Store, halt das fest.“ **Nichts gebaut.**

Neu ist **Ziel 9** in `ziele.md`; „Store, Icons der App“ ist von der
Sperrliste. Die Liste zum Abhaken, mit Terminen:
[`docs/vorlagen/play-store.md`](../vorlagen/play-store.md).

**Der Befund:** Ein neues privates Play-Konto darf erst öffentlich, wenn
ein geschlossener Test mit mindestens zwölf Testern vierzehn Tage am
Stück gelaufen ist; danach prüft Google den Produktionszugang, nach
eigener Angabe meist in bis zu sieben Tagen. Für den 20.11. heißt das:
**Bis Mo 26.10. müssen zwölf Tester eingeschrieben sein.** Der Test ist
zugleich die Feedbackrunde.

**Beim Nachsehen gefunden:**

- Auf diesem Rechner wurde noch nie ein Android-Build gebaut;
  `flutter doctor` meldet fehlende cmdline-tools und nicht akzeptierte
  Lizenzen.
- Der Release-Build signiert mit dem Debug-Schlüssel, das Startsymbol
  ist das Flutter-Logo, das Startbild hell.
- **Ein Wisch vom linken Rand beendet einen Lauf in der Grube**: Das
  Steuerkreuz nimmt den ganzen Bildschirm ein, und `PitScreen` hat kein
  `PopScope`. Im Browser fällt das nicht auf.
- Mit targetSdk 36 hält Android das Hochformat auf Tablets nicht mehr
  ein.
- Die Vorschauen in 390 × 844 taugen nicht als Screenshots für den
  Store: Die lange Seite darf höchstens doppelt so lang sein wie die
  kurze.
- Schon in Ordnung: targetSdk 36, NDK 28, keine Internet-Berechtigung,
  kein Entwicklermodus im Release-Build.

**Danach am selben Tag:** Das Studio heißt **FRENO Studios** — „Lifes
Game Studio“ war zu nah an „Life Games Studio“. Das Konto ist
angelegt; die Bestätigung der Identität läuft.

**Aufgeräumt:** Die Einträge vom 04. bis 11.10. stehen jetzt wortgleich
in [`verlauf.md`](verlauf.md).

### Offen

- **„In den Store“ ist als öffentlich gelesen**, nicht bestätigt. Ist
  der Start der Feedbackrunde gemeint, rückt alles um gut drei Wochen.
- AktivesBrett hat nicht zugestimmt — der Store stand auf der
  Sperrliste, die beide bindet.
- Zu entscheiden bis Mi 21.10.: wem das Konto gehört, der endgültige
  Name (die Paket-Id ist nach dem ersten Upload fest), Spiel oder App,
  Erinnerung, Absturzberichte, große Schrift.
- Ein ADR fehlt mit Absicht, bis diese Fragen entschieden sind.

## 19.10.2026: zwölf Stücke mit Kräften und das Vampirset

AktivesBrett: zehn neue Items, zwei je Kategorie, erst als Ideen. Dazu
eigene Vorgaben: ein Ring mit Eisaura, ein Amulett mit Kugeln, die
Gegner suchen, und ein Vampirset aus vier Teilen. Nach dem Durchsehen:
„Dann mach jetzt.“ [ADR-0077](../decisions/0077-ausruestung-mit-kraeften.md).

| Stück | Platz | Seltenheit | Kraft |
|---|---|---|---|
| Langspeer | Waffe | Ungewöhnlich | Speerstich: alle in einer Linie |
| Blutsichel | Waffe | Episch, Vampir | Sichelhieb: alle im Bogen; Lebensraub 4 % |
| Flickenmantel | Rüstung | Selten | Schild nach 3 s ohne Treffer |
| Nachtmantel | Rüstung | Episch, Vampir | Lebensraub 3 % |
| Falkenhaube | Helm | Ungewöhnlich | +5 % kritisch, je kritischem +3 Mana |
| Fledermaushaube | Helm | Episch, Vampir | Lebensraub 2 % |
| Hasenläufer | Schuhe | Gewöhnlich | nach jedem Kill kurz schneller |
| Schattenstiefel | Schuhe | Episch, Vampir | Lebensraub 3 % |
| Seelenring | Ring | Selten | Mana je Kill |
| **Frostreif** | Ring | Legendär | Eiskreis, bremst und friert |
| Echostein | Talisman | Selten | jede vierte Fähigkeit noch einmal, halb |
| **Amulett der Irrlichter** | Talisman | Legendär | alle 5 s ein Irrlicht, bis 3, sucht Gegner |

**Das Vampirset**: zwei Teile heilen je Kill; mit allen vier blutet man
jede Sekunde 2 % — **immer**, auch ohne Gegner —, der Lebensraub zählt
doppelt, ein Fünftel davon trifft zusätzlich, und **keine andere
Heilung heilt**: Heilfähigkeiten, Heilkugeln, Kill-Heilung, zweiter
Atem und Rückspulen treffen stattdessen den nächsten Gegner.

**Kräfte gibt es jetzt auf jeder Seltenheit**, nicht nur auf Legendär.
Eine Kraft am Helden ist ein Passiv wie Kampfrausch und kommt als
`GrantPassive` in die Welt; `PitLegendaries` heißt jetzt
`PitGearPowers`, `GearItem.legendaryPower` jetzt `power`.

**Fragen vor dem Bau**, sieben Antworten: Blutpakt **immer**, nicht nur
im Kampf (gegen Claudes Empfehlung — „ich probiere es mal aus und sage,
ob es zu schwer ist“); der Raub-Schaden erst mit allen vier (gegen die
Empfehlung); Kill-Heilung und Heilkugeln werden zu Schaden; Kräfte auf
jeder Seltenheit; die Bilder zeichnet Claude.

**Ohne Rückfrage entschieden** (die ganze Liste steht im ADR): zwölf
statt zehn, weil sechs Plätze mal zwei zwölf sind; das Vampirset episch
und damit das **erste verdiente Set**; Frostreif und Irrlichter
legendär; Lebensraub nur mit eigener Hand; das Echo wiederholt nur
Treffer.

**Gemessen** (`dart run tool/pit_sim.dart ausruestung 40`, Tag 30,
Bogen, Funkenstoß, Steinhaut, Blütentau; Stufe 13, ohne Kraft 18 %):
Frostreif 30 %, Irrlichter 38 %, Flickwerk 40 %, Falkenblick 40 %,
Hasenlauf 15 %, Seelenernte 25 %, Echo 25 %. Speerstich und Sichelhieb
ohne Kraft schlagen wie der Bogen (je 18 %). Das Vampirset mit der
Sichel: ein Teil 43 %, zwei Teile 63 %, **alle vier 28 %** — der Bot
heilt nicht gezielt und läuft nie zur nächsten Kugel. Auf Stufe 11 kommt er mit vollem Set in
neun von zehn Läufen durch. **Zwei Teile sind der stärkste Sprung**
(63 %) — Lebensraub und Kill-Heilung ohne Preis.

**Nachgestellt nach der ersten Messung:** Falkenblick hatte 6 % und
5 Mana und hob Stufe 13 auf 58 %, mehr als jede andere Kraft, auf einer
ungewöhnlichen Haube; jetzt 5 % und 3 Mana. Der Sichelhieb hatte ×0,75
und kam auf 3 %; jetzt ×0,9.

**Beim Bauen gefunden:** In `assets/RAVEN.md` stand der Absatz zu
AktivesBretts Fähigkeitsbildern (ADR-0074) mitten in der Tabelle und
zerriss sie. Er steht jetzt darunter.

Neu: `gear_powers.dart`, `ausruestung_kraefte_test.dart` (24 Tests),
`tool/item_icons.py`, zwanzig Bilder (zwölf im Laden, zwei
Grundangriffe, sechs auf der Figur). App 850 (vorher 848), action_combat
381 (vorher 357), gear 120 (vorher 118). Die Bilder als Kontaktbogen und
auf der Figur angesehen. **Nicht gespielt, nicht am Handy, nicht im
Browser.**

### Offen

- **Ob der Blutpakt zu hart ist** — AktivesBrett spielt ihn und sagt es.
  Die Hebel: der Abzug (2 %), der Faktor auf den Lebensraub (×2), der
  Anteil als Schaden (ein Fünftel), oder der Abzug nur im Kampf.
- Das Amulett der Irrlichter ist nach Zahlen der beste Talisman und
  steht damit in der Spalte „beste Ausrüstung“ der großen
  `pit_sim`-Tabelle; die ist nicht neu gemessen.
- **Seelenraub trifft mit dem Blutpakt praktisch doppelt**: Seine
  Heilung (der ganze Schaden) wird zu Schaden am nächsten Gegner. Das
  folgt der Regel, ist aber vielleicht nicht gewollt.
- Die neuen Kräfte haben keinen eigenen Klang.
- Issue #115 will auch zwei Ring- und zwei Amulettplätze und Werte, die
  mit dem Level wachsen — nicht gebaut.
- **Frederik hat ADR-0077 nicht gesehen**, auch nicht, dass Kräfte jetzt
  auf jeder Seltenheit sitzen.

## 18.10.2026, zuletzt: das Spiegelbild bleibt stehen

AktivesBrett nach dem ersten Spielen seiner Fähigkeiten (ADR-0074): „Der
Klon ist mit an dir dran, das soll so nicht. Er soll da stehen bleiben,
wo man die Fähigkeit gedrückt hat, und mit angreifen.“

| | vorher | jetzt |
|---|---|---|
| Wo es steht | lief neben dem Helden mit | erscheint neben ihm und **bleibt dort** (`Companion.stationary`) |
| Wovon es schlägt | Reichweite der Waffe plus Abstand, vom Helden aus gedacht | Reichweite der Waffe, **von seinem Platz aus** |
| Im Bild | machte die Haltung des Helden nach, lief also im Stand | **eigene Haltung**: steht, dreht sich zum Ziel, holt aus, wenn es trifft |

Es greift weiter nur an, was der Held sieht (ADR-0073, wie Falke und
Pflanze) — wer weit wegläuft, lässt es untätig stehen. Steht neben dem
Helden eine Wand, erscheint es auf ihm.

Vorher `main` hereingeholt (Lagerfeuer, Lernen als Runde, hundert
Ebenen); Konflikte nur in `CLAUDE.md` und `state.md`. App 848,
action_combat 357. **Nicht im Browser angesehen, nicht am Handy.**

### Offen

- Ob das Abbild untätig stehen soll, wenn der Held den Raum verlässt,
  oder auch ohne seinen Blick angreifen darf.
- Die übrigen neun Fähigkeiten und die Ultimates sind nicht gespielt;
  Bestform ist weiter zu stark (Eintrag vom 16.10.).

## 18.10.2026, spät: das Lagerfeuer — der Tag endet an einer Stelle

Frederik: „Mir gefällt der aktuelle Stand richtig gut. Was fällt dir
allgemein noch so ein?“ Aus sechs Vorschlägen: „Lagerfeuer find ich
cool“ — die zweite Idee aus ADR-0071. In zwei Fragerunden entschieden,
alle sieben Fragen wie empfohlen:
[ADR-0076](../decisions/0076-das-lagerfeuer.md).

| Was | Wie |
|---|---|
| **Ein Ort bei Nacht** | eigener Bildschirm: Himmel, Sterne, ein gezeichnetes Feuer, das flackert, Funken |
| **Immer offen** | ab 18 Uhr oder sobald alles erledigt ist, brennt es; vorher glimmt es nur |
| **Was dort liegt** | die Rückfrage, die Truhe, die Tagesaufgaben, sonntags und montags der Wochenrückblick |
| **Nur dort** | Truhe und Aufgaben stehen nicht mehr auf der Startseite und nicht im Gewohnheiten-Bildschirm; die Rückfrage bleibt zusätzlich in der Theorie |
| **Auf der Startseite** | unter „Heute“ eine Karte: ein kleines Feuer und, was wartet, als Zeichen mit Zahl |
| **Morgen zuerst** | die morgen fälligen Gewohnheiten als Knöpfe; die gewählte steht morgen oben in „Heute“, mit einer Flamme — ein Vorsatz, keine Zahl |
| **Zum Schluss** | „Genug für heute. Leg das Handy weg.“ |

**Keine Zahl ändert sich**, und alles verfällt weiter um Mitternacht.
Neu im Spielstand ist nur der Vorsatz (`firstUp`, je Tag eine
Gewohnheit, eine Historie wie die Truhen).

**Ohne Rückfrage entschieden:**

- **Der Vorsatz zieht seinen ganzen Stapel nach vorn**, wenn er an einer
  anderen Gewohnheit hängt — ein Glied allein risse von seinem Anker.
  Erledigt wandert er nach unten wie jede andere.
- **Die Knöpfe stehen in der Reihenfolge ohne Vorsatz**, sonst spränge
  der gewählte beim Tippen nach vorn.
- **Gezählt wird, was verfällt**: Rückfrage, Truhe, Aufgaben. Wochenrückblick
  und Vorsatz zählen nicht, sonst stünde die Zahl den ganzen Abend da.
- **Die Karte erscheint mit dem ersten Häkchen**, wie vorher die
  Tagesaufgaben (ADR-0068).
- **Die Flamme steht nur in „Heute“ auf der Startseite**, nicht auf den
  Kacheln des Gewohnheiten-Bildschirms; die Reihenfolge gilt in beiden.
- **Ob es brennt, wird beim Neubau gelesen**, ohne eigenen Takt: Steht
  die App um 18 Uhr offen da, brennt es erst beim nächsten Tipp.

**Beim Bauen gefunden:** Am Feuer verschmolzen die Beschriftungen für
den Vorleser zu einem Satz — Feuer, Truhe und Aufgaben in einem Knoten,
weil die Liste nur einen Eintrag hat. Jeder Teil hat jetzt seinen
eigenen. **Beim Ansehen gefunden** (gerendert in 390 × 844): Auf der
Startseite stand „Lagerf…“, weil sich das Wort den Platz mit einem
`Spacer` teilte.

Neu: `lib/lagerfeuer/` mit sechs Dateien, `HabitTracker.firstUpOn` und
`setFirstUp`, `WeekCard.istGross`, `test/lagerfeuer_test.dart`,
`first_up_test.dart`. habits 333 (vorher 324), App 843 (vorher 834).
Startseite abends und morgens, das Feuer brennend und glimmend
gerendert und angesehen. **Nicht am Handy, nicht im Browser gespielt.**

### Offen

- **Ob es am Abend wirklich eine Minute ist** oder ob man trotzdem
  tagsüber an drei Stellen sucht.
- Das Feuer hat keinen Klang; ein Knistern beim Öffnen läge nahe.
- Eine Erinnerung am Abend gibt es erst mit einer App (ADR-0071).
- Der Begleiter kommt mit dem Haus — das braucht AktivesBrett.
- AktivesBrett hat ADR-0076 nicht gesehen: Truhe und Aufgaben sind von
  der Startseite verschwunden.

## 18.10.2026, abends: Rätsel und Fälle — die Probe an Kraft

Frederik: „Wie könnten wir den Inhalt von Theorie noch interessanter
machen?“ Der Befund: Fast jede der 63 Seiten hat dieselbe Form, drei
sachliche Absätze, dann drei Fragen, die einen Satz aus dem Text
abfragen. Lebendig sind die Seiten, die von etwas ausgehen — die
Experimente der Psychologie, Frederiks Beispiele bei den Gewohnheiten.
Claude schlug vier Ideen vor und empfahl zwei davon zusammen, als Probe
an einem Gebiet. Frederik: „Ja gerne“.

| Was | Wie |
|---|---|
| **Das Rätsel vor der Seite** | eine Szene mit Schätzfrage, bevor man liest („Zwei Gruppen trainieren … wer baut mehr Muskeln auf?“); daneben ist braun mit Glühbirne und „Überraschend, oder?“, nicht rot; gut geschätzt klingt den ersten Ton der Leiter |
| **Es zählt nicht** | nicht für Bestehen, Erfahrung oder Rückfrage; gespeichert wird nichts; „Nochmal“ fängt bei den Fragen an |
| **Die zweite Frage ist ein Fall** | Jana, Max, Lea, Tom und Nina haben ein Problem, und die Frage ist, was sie tun — statt einen Satz wiederzuerkennen |
| **Wo** | alle fünf Themen unter Kraft & Muskulatur, die Einführung nicht |

Neu ist ein Feld: `Lesson.teaser`, eine `Question`, die vor dem Lesen
steht. Ein Test hält fest, dass jede Kraft-Seite eins hat, und prüft
jedes Rätsel wie eine Frage.

**Beim Schreiben gefunden — ein Fehler im Inhalt:** Auf „Wie nah ans
Versagen“ stand, Anfänger schätzten ihre Reserve „zu hoch“ ein, und die
richtige Antwort lautete „Zu hoch, sie hören zu früh schon auf“. Das
widerspricht sich: Wer zu früh aufhört, schätzt seine Reserve zu
**niedrig** ein, und so zeigen es auch die Studien dazu. Text und Frage
sind korrigiert. Die Seite stand so seit dem 26.09. im Spiel.

**Ohne Rückfrage entschieden:**

- **Kraft als Probe**, weil es das trockenste Gebiet ist: Dort sieht man
  den Unterschied am deutlichsten.
- **Die zweite Frage wird der Fall**, auf jeder Seite dieselbe Stelle,
  und ihre richtige Antwort bleibt an derselben Stelle wie vorher — die
  Verteilung aus ADR-0027 bleibt, wie sie war.
- **Die Fälle haben Namen**, keine Du-Form: eine kleine Geschichte statt
  einer Prüfungsfrage.
- **Ein Rätsel darf ein Fakt der Seite vorwegnehmen**, den eine Frage
  danach noch einmal abfragt — das Wiederholen ist gewollt.

Fünf Rätsel und zwei Seiten gerendert in 390 × 844 und angesehen.
theory 197 (vorher 193), App 834 (vorher 830). **Nicht gespielt, nicht
am Handy, nicht gegengelesen.**

Gemergt am 18.10. als PR #125. Er hieß zuerst #124 und zeigte auf den
Branch von #123; der Merge von #123 löschte diesen Branch, und GitHub
schloss #124, statt ihn auf `main` umzustellen.

### Offen

- **Ob die Probe trägt**: Frederik liest die fünf Seiten. Wenn ja,
  bekommen alle 63 Rätsel und Fall — Schreibarbeit, Seite für Seite.
- Die Rätsel stützen sich auf Studien („so kam es in Studien mit genau
  diesem Aufbau heraus“), nennen aber keine. Ob eine Quelle dazugehört.
- Die übrigen Ideen: „Heute ausprobieren“ am Ende jeder Seite, und
  Frederiks Bücher und Videos als Quelle für die grauen Gebiete.

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

Gemergt am 18.10. als PR #123; die CI lief diesmal im ersten Anlauf
durch.

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

## 16.10.2026: AktivesBretts zehn Fähigkeiten und zwei Ultimates

Die zweite Hälfte von Issue #114. Claude hat zehn Fähigkeiten und zwei
Ultimates vorgeschlagen, die die Bausteine aus ADR-0073 nutzen, die
Frederiks zwölf liegen liessen; AktivesBrett hat sie übernommen,
**Spiegelbild auf Episch** gesetzt und **Bestform** und **Rückspulen**
als Ultimates gewählt.
[ADR-0074](../decisions/0074-aktivesbretts-faehigkeiten.md), die Liste
in der Vorlage [`faehigkeiten-2.md`](../vorlagen/faehigkeiten-2.md).

| Fähigkeit | was sie tut |
|---|---|
| Zinseszins | Schlag, jede Wiederholung binnen 4 s ein Fünftel härter, bis 5-mal |
| Schattenschritt | Sprung, 2 s unsichtbar, der erste Treffer daraus ×1,5 |
| Kampfrausch | **passiv**: je eingesteckten Treffer +4 %, bis 10-mal |
| Kriegsschrei | wer nah steht, steht still; 6 s +20 % |
| Spiegelbild | 10 s ein Abbild mit dem eigenen Grundangriff, halber Schaden |
| Parade | 0,6 s offen, fängt einen Treffer ganz ab, der Angreifer steht |
| Ruhepuls | **passiv**: ohne eigenen Treffer kommt Mana 40 % schneller |
| Kettenblitz | springt auf bis zu drei weitere, je ein Viertel schwächer |
| Rammbock | Sturm, der trifft, zur Seite wirft und festhält |
| Zweiter Atem | **passiv**, einmal je Lauf: unter 20 % Leben heilt er 25 % |
| *Bestform* | Ultimate, 8 s: Fähigkeiten +40 % ohne Mana, Abklingzeit doppelt so schnell |
| *Rückspulen* | Ultimate: zurück an Ort und Leben von vor 4 s, kurz unverwundbar |

**Drei Fragen vor dem Bau**, alle wie empfohlen beantwortet: Die Bilder
zeichnet Claude (das Raven-Paket liegt nur bei Frederik); Bestform trifft
mit Fähigkeiten +40 %, mit dem Grundangriff nur +25 %; ihre Quelle ist
die neue Errungenschaft **„Sieben Tage in Form“** (sieben Tagestruhen).

**Beim Bauen gefunden:**

- **Die Grenze des Grundangriffs stand nur im Kommentar.** Am
  `SelfBuff` hiess es, ein Test halte 1,25 fest — es gab keinen. Jetzt
  ist sie eine Zahl (`ActionBalance.weaponBuffCap`) für alle Stärkungen
  zusammen, mit Test.
- **Ein Kettenblitz brach den Lauf ab**: Er legt beim Einschlag ein
  neues Geschoss nach, mitten im Durchlaufen der Liste. Die Schleife
  geht jetzt über eine Kopie.
- **Python schreibt unter Windows CRLF.** Die Patch-Skripte hatten
  vierzehn Dateien umgestellt; zurückgesetzt, bevor etwas eingecheckt
  war.

| Was | Wo |
|---|---|
| Zehn Fähigkeiten, zwei Ultimates, neun neue Arten | `pit_ability.dart` |
| Was am Helden abläuft, und die Grenze des Grundangriffs | `hero_states.dart` (neu) |
| Ausführung, Rammbock, Kettenblitz | `effects.dart`, `world.dart` |
| Ein Passiv ohne Knopf im Kampf | `ability_buttons.dart` |
| Schatten, Abbild, Parade, Bestform, Glut im Bild | `action_game.dart`, `neue_arten_bild.dart` |
| Bedingungen und Knoten | `ability_catalog.dart`, `theory_graph_content.dart` |
| Die zwölf Bilder | `tool/faehigkeit_icons.py` → `assets/Faehigkeiten/` |
| Je Fähigkeit messen | `dart run tool/pit_sim.dart faehigkeiten` |

**Gemessen** (`pit_sim faehigkeiten`, Tag 30, 12 Läufe je Feld, statt
Funkenstoß neben Steinhaut und Blütentau): Auf Stufe 11 gewinnt der Bot
mit jeder der zehn zu 83 bis 100 %, wie mit allen anderen. Auf Stufe 13
liegen sie zwischen 8 % (Schattenschritt, Kriegsschrei, Spiegelbild,
Rammbock) und **50 % (Kampfrausch)**, Funkenstoß bei 25 % — im Feld der
übrigen 29. Der Bot springt, pariert und zielt nicht; wer das kann,
liegt darüber.

**Bestform ist der Ausreisser**: Zu Funkenstoß, Steinhaut und Blütentau
dazu gewinnt der Bot Stufe 13 zu **100 %**, ohne Ultimate zu 25 %,
mit Rückspulen zu 42 %, mit Frederiks Wassergrube zu 17 % und der
Pflanze zu 33 %. Acht Sekunden ohne Mana bei doppelt so schneller
Abklingzeit sind für den Bot ein Dauerfeuer. **Nicht nachgestellt** —
eine Entscheidung für euch beide.

App 802 (vorher 797), action_combat 355 (vorher 331). **Nicht gespielt,
nicht am Handy, nicht im Browser angesehen** — die Bilder nur als Datei.

### Offen

- **Bestform ist zu stark** (Stufe 13: 100 % statt 25 %). Die Hebel:
  kürzer als acht Sekunden, Abklingzeit nicht doppelt so schnell, oder
  Mana nur zum halben Preis statt umsonst.
- **Ob die Parade mit 0,6 s zu knapp ist**, und ob man sie im Gedränge
  überhaupt gezielt drückt.
- **Drei Passive kosten drei Plätze.** Wer alle drei trägt, hat keinen
  Knopf mehr ausser der Ultimate.
- **„Sieben Tage in Form“ kommt vor „Zehn Truhen“**: die Ultimate früher
  als der Glückstrank. Der Platz geht ohnehin erst auf Level 15 auf.
- **Die Bilder sind gezeichnet** und sehen neben den Raven-Bildern
  anders aus. Wer eins tauschen will, legt ein Bild an dieselbe Stelle.
- **Frederik hat ADR-0074 nicht gesehen.**

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

---

Ältere Einträge: [`verlauf.md`](verlauf.md).
