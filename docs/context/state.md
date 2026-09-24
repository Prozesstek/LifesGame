# Projektstand

> Diese Datei ist die Antwort auf „Wo stehen wir gerade?".
> Am Ende jeder Arbeitssitzung aktualisieren. Alte Einträge unter „Verlauf"
> zusammenfassen, nicht löschen.
>
> Wohin es geht, steht in [`ziele.md`](ziele.md) — mit Terminen und mit der
> Liste dessen, was bis zum MVP ausdrücklich **nicht** angefasst wird.

**Zuletzt aktualisiert:** 24.09.2026 · Frederik

---

## 24.09.2026: Exemplare, Tagesladen, Beute mit Schlüsseln, Bestzeiten

[ADR-0048](../decisions/0048-exemplare-tagesladen-und-beute.md), in
einer Konzeptrunde Frage für Frage entschieden, dann gebaut. Vorbild
Diablo, Grundsatz Frederiks: **Gewohnheiten und Theorie bleiben der
Hauptpunkt; wer mehr spielt, darf, wird dadurch aber nicht übertrieben
stärker, sondern verbessert sich selbst.**

| Was | Wie |
|---|---|
| **Exemplare** | Jedes Stück hat eigene Werte, **jeder einzeln 85–115 %** gewürfelt, im Kampfmassstab (+11 statt +1,1) |
| **Tagesladen** | sechs Angebote, eins je Platz, aus dem Datum gewürfelt; Preis nach Seltenheit, nicht nach Wurf |
| **Beute** | Der Wächter lässt ein Stück fallen: beim **ersten Sieg** auf einer Stufe immer, sonst gegen einen **Schlüssel** (gefragt, nicht automatisch) |
| **Schlüssel** | einer je Häkchen, bestandener Seite, richtiger Rückfrage; höchstens **10** |
| **Tiefer heisst besser** | Stufe 1–9: nie Episch; ab 10 Episch 7 %; ab 20 Legendär 5 % |
| **Verkaufen** | ein **Viertel** des Katalogpreises; Knopf „alles Schlechtere verkaufen" (nie Set-Teile, Episches, Legendäres, fremde Waffen) |
| **Bestzeiten** | je Stufe, auf dem Eingang zur Grube; dort jetzt auch **jede geschaffte Stufe wählbar** |
| **Übernahme** | Jedes besessene Stück wird ein Exemplar mit 100 %, Gold bleibt gleich |

**Warum der Grundsatz hält:** Die **Zahl** der Würfe hängt nur an
Gewohnheiten und Theorie (Schlüssel), die **Güte** an der Tiefe — und wie
tief man kommt, entscheiden Level und Werte plus das eigene Können.

**Gemessen** mit `tool/runway_sim.dart` (Bot-Reichweite, also eher
spät): rund 270 Stücke in 60 Tagen, das erste Seltene um Tag 7, das
erste Epische an **Tag 27 im Laden, Tag 29 als Beute** — knapp im Test —,
das erste Legendäre um Tag 48.

**Der Kampfmassstab musste mitkommen.** Die Werte aus dem Alltag sind
klein (Angriff 13–20), und erst `ActionStats.combatAttack` nahm alles mal
zehn; ein Wurf von 1,1 wäre auf 1 gerundet worden. Die Ausrüstung geht
jetzt als eigener Summand in `ActionStats` (`gearAttack` usw.). Die
Werte-Karten am Charakter zeigen seitdem den Kampfmassstab („180 Alltag
· +11 Ausrüstung"). **Der Gewohnheiten-Bildschirm zeigt die Werte noch
klein** — ein eigener Umbau, bewusst nicht mitgemacht.

gear 112 (vorher 90), action_combat 206, App 503. **Nicht angesehen**,
weder im Browser noch am Handy. Nicht getestet: der Weg durch einen
gewonnenen Lauf bis zum Beute-Blatt (die Teile sind getestet, die
Verdrahtung in `PitScreen._beute` nur gelesen).

**Offen:** Die Zahlen der Tabelle sind ein Anfang. Ob 4 bis 5 Stücke am
Tag das Inventar überfluten, sagt das Spielen; der Knopf für Ausschuss
ist die Antwort, falls ja. `runway_sim` zählt den Laden noch als
Katalogsumme („Laden offen"), was seit dem Tagesladen wenig sagt.

## 24.09.2026: der Laden ein Drittel billiger

[ADR-0047](../decisions/0047-laden-ein-drittel-billiger.md). Frederik
nach vier Testtagen: „Der Laden ist auf jeden Fall zu teuer, und gerade
passiert am Tag nicht viel ausser alle Dailies machen.“ Jeder Preis ist
jetzt zwei Drittel des alten, gerundet auf zehn.

| | vorher | jetzt |
|---|---|---|
| Gewöhnlich | 100–320 | 70–210 |
| Ungewöhnlich | 400–880 | 270–590 |
| Selten | 720–1.050 | 480–700 |
| Episch | 900–1.500 | 600–1.000 |
| Legendär | 1.450–2.000 | 970–1.330 |

**Wer schon gekauft hat, bekommt ein Drittel zurück**, weil Gold aus dem
Besitz gerechnet wird. `catalog_test.dart` hat eine gesenkte Untergrenze
(14 statt 24 Tage Gewohnheiten für den billigsten Satz). gear 90, App 501.

**Die Levelkurve bleibt vorerst, wie sie ist** (Frederik, 24.09.). Die
zweite Hälfte der Klage, dass auch Aufstiege selten werden, wird erst
wieder angefasst, wenn sie nach den neuen Preisen im Test noch stört.
Mehr Aufstiege leerten den Baum zu früh.

## 24.09.2026: Wann geht was aus? Nichts, aber es wird dünner

Gerechnet mit `tool/runway_sim.dart`: ein Spieler, der jeden Tag alles
erledigt (fünf Gewohnheiten, Truhe, bis zu zwei Seiten, Rückfrage, eine
neue Stufe soweit er kommt, vier Dailies). Die Reichweite in der Grube
stammt aus `pit_sim`, ist also eine untere Schranke. Errungenschaften
zählen nicht mit.

| Tag | Level | Baum | Stufe | Gold verdient |
|---|---|---|---|---|
| 1 | 4 | 4 / 25 | 1 | 217 |
| 10 | 11 | 14 / 25 | 4 | 982 |
| 20 | 16 | 19 / 25 | 8 | 1.704 |
| 30 | 20 | 23 / 25 | 12 | 2.474 |
| 35 | 23 | **25 / 25** | 15 | 2.917 |

**Innerhalb der 30 Tage geht nichts aus.** Der Baum ist an Tag 33
gelesen, die Werte sind an Tag 35 am Deckel, die Grube reicht weit
darüber hinaus. **Der Laden ist das Gegenteil von leer:** Er kostet
zusammen 40.230 Gold, verdient sind an Tag 30 rund 2.500. Man besitzt
dann ungefähr alle Gewöhnlichen (zusammen 2.340) und nicht viel mehr.
Episch ist ab Stufe 10 offen (etwa Tag 25), kostet aber 900 bis 1.500
Gold bei rund 80 Gold am Tag.

**Das Risiko ist das Tempo, nicht das Ende.** In Woche 1 kommen etwa acht
Aufstiege, neun Seiten und drei Stufen. In Woche 4 sind es zwei
Aufstiege, zwei Seiten, drei Stufen und ein Kauf alle ein bis zwei
Wochen. Das Neue wird ungefähr um den Faktor vier seltener. Wenn im Test
Langeweile kommt, dann in Woche 3 und 4, und sie käme aus dieser
Ausdünnung.

Nicht entschieden, nur gemessen. Die Hebel wären Preise, die Levelkurve
oder mehr Inhalt (Letzteres steht auf der Sperrliste).

## 24.09.2026: alles am Handy durchgespielt

Frederik hat alles, was hier als „nicht angesehen“ stand, am Handy
durchgespielt, auch die Neuerungen dieser Sitzung aus der Web-Fassung
auf `main`. Die Vermerke unten sind durchgestrichen, nicht gelöscht:

| Bereich | durchgespielt |
|---|---|
| Gewohnheiten | Erledigtes rutscht nach unten, Wucht beim Häkchen, Tagesform, Tagestruhe, Wochenrückblick, Rückfrage des Tages |
| Fortschritt | Levelaufstieg, Macht-Karte am Charakter |
| Oberfläche | jeder Knopf gibt nach, Holzrahmen, Klänge |
| Dorf | das Dorf und das eigene Haus |
| Grube | Skillshots und Flächen, Tor und Auftritt des Wächters, Fledermaus, Steinwände, Lebensbalken, Minimap, Uhr mit Zeitkugeln |

**Weiter offen**, weil es nicht am Ansehen hing: die Entscheidung übers
Dorf (braucht AktivesBrett und einen ADR), „gefestigte“ Seiten im Baum,
die Seltenheit im Laden, und ob die Uhr beim ersten Erkunden reicht.

## Sitzung 24.09.2026: Fledermaus, Stein und die neue Figur

Drei Zeichnungen von Frederik, alle 64 × 64 gezeichnet und als
256 × 256 abgelegt. action_combat 203 (vorher 186), App 501 (vorher 486).

| Bild | wird |
|---|---|
| **Fledermaus** | eine **sechste Gegnerart** (`EnemyKind.flatterer`, `f`), kein neues Bild für den Kobold |
| **Stein** | die **Wände der Grube** und der **Felswurf** des Wächters, der jetzt rollt |
| **Figur** | die Figur auf der Startseite (`Charakter.png` ersetzt) |

**Die Fledermaus greift an und zieht sich wieder zurück.** Sie kommt im
Zickzack, schneller als der Kobold (165), beisst und flattert danach
0,7 s lang davon. Dann kommt sie wieder. 12 Leben, 7 Angriff. Wer nur
den Grundangriff hat, trifft sie selten. Mit Funke, Fläche oder Bogen
erwischt man sie. Die Zahlen stehen in `ActionBalance.flatterer…`, das
Verhalten in `ActionWorld._batActs`. Sie kommt in einem neuen Raum vor,
der **Grotte**: vier Fledermäuse, vier Fussvolk.

**Der Stein** steht als Block auf seinem Feld und ragt ein Stück ins Feld
darüber, das gibt der Wand Höhe. Gezeichnet wird nur der Ausschnitt,
in dem der Stein liegt (`GrubeFiguren.steinAusschnitt`). Ein Test misst
ihn an der Datei nach. Der Felsbrocken trägt dafür `isBoulder`.

Frederiks Bilder werden in der Grube auf ein Sechstel verkleinert und
deshalb **weich** skaliert (`Figure.smooth`), nicht hart wie die
Paketfiguren. Sonst fielen Bildpunkte weg.

**`pit_sim` nachgerechnet**, zehn Läufe je Feld: Das meiste liegt im
Rauschen. Oben ist es etwas härter: voll ausgerüstet mit Fähigkeiten
schafft der Bot Stufe 30 zu 20 % statt 60 %. Das kann an der Grotte
liegen oder am Rauschen, nachgestellt ist nichts.

~~**Nicht im Spiel angesehen**, nur als zusammengesetzte Vorschau in
Spielgrösse.~~ ✓ *Am 24.09. am Handy gespielt.* Die Fledermaus ist dunkel auf dunklem Boden, sie liest sich
dort, aber knapp.

**Nachgereicht: ein Lebensbalken über dem Helden.** Er ist in der
Grube immer zu sehen, auch bei vollem Leben. Er ist breiter und dicker
als der eines Gegners und dunkel umrandet. Ab einem Drittel wird er
golden, nicht rot, denn Rot gehört dem Wächter (`ActionGame.heroBarColor`).
App 490.

**Und eine Karte oben links** (`lib/action/minimap.dart`), rechts davon
die Balken. Sie zeigt nur, was der Held schon gesehen hat: Alles im
Umkreis von sechs Feldern wird aufgedeckt und bleibt es. Gegner stehen
als Punkte darauf, aber nur in diesem Umkreis. Sonst verriete die Karte,
was hinter den Wänden wartet. Der schlafende Wächter fehlt, wie im Bild.
Das Aufgedeckte ist Darstellung, keine Spielregel, und steht deshalb
nicht in `action_combat`. App 495.

**Gegner kommen nicht mehr durch Wände** (Frederik: „werden zu früh aus
Räumen gepullt“). Bisher reichte es, näher als 210 Punkte zu sein, auch
mit einer Wand dazwischen, und der Nachbarraum lief los. Jetzt kommt ein
Gegner nur, wenn er den Helden **sieht** oder von ihm **getroffen**
wurde. Eine Stelle: `ActionWorld._enemiesAct`, geprüft über `_canSee`.
`aggro_test.dart` hält es fest. Zwei Tests in `chase_test.dart` setzten
das Bemerken durch die Wand voraus. Dort sieht der Gegner den Helden
jetzt zuerst, und dann versteckt sich der Held. `pit_sim` liegt im
Rauschen, eher einen Hauch leichter. action_combat 196.

**Eine Uhr in der Grube** ([ADR-0046](../decisions/0046-uhr-in-der-grube.md)),
gegen das Kiten. Jede Stufe hat 45 s plus 25 s je Raum (Stufe 1: 2:00,
Stufe 30: 2:50). Läuft die Uhr ab, ist der Lauf verloren, das Blatt sagt
„Die Zeit ist um“, und was gefallen ist, bleibt. Gefallene Gegner lassen
zu 15 % eine **Zeitkugel** fallen (Sanduhr in der Farbe der Zeit), die
8 s bringt, nie über das Limit. Die Uhr steht rechts in der Kopfzeile
und wird unter 15 s golden.

Gemessen am Bot, der geradewegs durchgeht: höchstens rund 17 s je Raum,
das Limit ist etwa das Doppelte. **In 1.800 Läufen von `pit_sim` ist die
Uhr kein einziges Mal abgelaufen.** Die Quoten liegen im Rauschen, die
Zeitkugeln verbrauchen allerdings Zufallswürfe, damit laufen Läufe
anders als vorher. action_combat 203, App 501.

Offen: ob 25 s je Raum für jemanden reichen, der eine Grube zum ersten
Mal erkundet. Das sagt nur das Spielen.

**Die Figur ist nur auf der Startseite.** In der Grube und im Dorf läuft
weiter der Soldat, weil er sechs Bewegungsstreifen hat und die neue
Figur ein Bild.

## Sitzung 23.09.2026, Nachtrag: das Dorf, als Prototyp

Frederiks Idee: Statt der Kreise läuft die Figur wie in der Grube durch
ein Dorf, mit einer Bücherei für die Theorie, einer Höhle für die Grube
und einem eigenen Haus. **Gebaut als Prototyp im Entwicklermodus**
(„Das Dorf (Prototyp)“). Die Startseite mit den Kreisen bleibt, bis ihr
beide gespielt habt. Danach kommt ein ADR, weil die Startseite beiden
gehört.

| Ort | führt zu |
|---|---|
| Bücherei | Theorie (Skillbaum) |
| Höhle | die Grube, mit derselben Sperre wie der Kampf-Kreis |
| Laden | Laden |
| Brett | Gewohnheiten |
| Zuhause | Charakter; später der Ort für Trophäen und Titel |

**Zwei Regeln, damit es dem Häkchen nicht schadet:** Antippen führt hin
(die Figur läuft selbst, Ziehen steuert, am Rechner WASD), und „Heute
2/5“ oben rechts öffnet die Gewohnheiten, ohne irgendwohin zu laufen.

Die Karte ist Text wie die Räume der Grube (`lib/village/village_map.dart`,
reines Dart). Die Figur ist der Soldat aus der Grube. **Die Kacheln und
Gebäude sind grob selbst gezeichnet** (`tool/dorf_kacheln.py`, Python mit
Pillow, 16er-Raster doppelt vergrössert), Platzhalter, bis es echte gibt.
App 478. ~~**Nicht im Browser angesehen**, nur die zusammengesetzte Karte
als Bild.~~ ✓ *Am 24.09. am Handy gespielt.*

**Nachgezogen nach dem ersten Ansehen** (Frederik): Die Karte ist jetzt
**hochkant**, 12 × 17 Felder, und passt damit ganz in die Breite eines
Handys, vorher lag die Hälfte außerhalb. Und **niemand geht mehr von
selbst hinein**: Wer vor einer Tür steht, bekommt einen kleinen Knopf
„Bücherei betreten“ mitten auf dem Gebäude. Ein zweiter Tipp auf das
Gebäude tut dasselbe. App 480.

**Das eigene Haus** ist gebaut (Frederik: „bau mal Punkt 2“). Ein Raum
zum Herumlaufen wie das Dorf, und alles darin wächst von selbst mit:

| Ding | zeigt | antippen |
|---|---|---|
| Trophäenregal | ein Pokal je verdienter Errungenschaft, „9/27“ | Errungenschaften |
| Titelwand | ein Banner je Titel, „4/13“ | Liste der Titel |
| Rüstungsständer | die Bilder von Helm, Rüstung und Waffe, die angelegt sind | Charakter (nur Durchgang, AktivesBrett baut dort) |
| Schatztruhe | ein Goldhaufen aus dem Gold der Tagestruhen, ein Schatz funkelt | Liste der Schätze |
| Ausgang | — | zurück ins Dorf |

Alles abgeleitet (`HouseView`), nichts im Spielstand. `VillageGame`
zeichnet jetzt beide Szenen (Gras und Bäume draussen, Dielen und Wände
drinnen); was in einem Ding liegt, zeichnet `paintHouse` über den Haken
`decorate`. Grob gezeichnet wie das Dorf. App 486. ~~Angesehen als
gerendertes Testbild, nicht am Handy.~~ ✓ *Am 24.09. am Handy gespielt.*

Offen: Die Dorfkarte ist fest und wächst nicht mit. Das Haus wächst nicht
selbst (Hütte zu Haus), nur sein Inhalt.

## Sitzung 23.09.2026, Nachtrag: die Rückfrage des Tages

[ADR-0045](../decisions/0045-rueckfrage-des-tages.md), Punkt 1 aus
`docs/vorlagen/lernen.md`. **AktivesBrett baut gerade den Item- und den
Ability-Screen**, deshalb ist hier nichts davon angefasst.

| | |
|---|---|
| Was | jeden Tag eine Frage aus einer bestandenen Seite, als Karte auf den Gewohnheiten, direkt dort zu beantworten |
| Richtig | +10 Erfahrung, +3 Gold (steigen auf), die Seite kommt nach 1, 3, 7, dann 21 Tagen wieder |
| Falsch | nichts, keine Strafe, die Seite kommt morgen wieder |
| Welche | die am längsten fällige, eine nie gefragte vor allen; die Antworten stehen jeden Tag in anderer Reihenfolge |

Neuer Bereich im Spielstand: `reviews` (`ReviewLog`, eine Historie).
`SaveWatcher` schreibt ihn, ein Test hält das fest. Erfahrung und Gold
laufen durch alle drei Zufluss-Provider. theory 148, App 462.
~~**Nicht angesehen.**~~ ✓ *Am 24.09. am Handy gespielt.* Offen: „gefestigte" Seiten im Baum zeigen.

## Sitzung 23.09.2026, Nachtrag: der Levelaufstieg wird gefeiert

Bis heute passierte beim Aufstieg nichts Sichtbares, obwohl er seit
ADR-0042 der grösste Sprung im Spiel ist. Jetzt kommt ein Blatt: „Level 7"
springt hoch, darunter kommt Zeile für Zeile, was es bringt: im Kampf
4 % stärker, ein Theoriepunkt, ein neuer Fähigkeitsplatz, auf 50 das
Höchstlevel. Dazu der lange Klang und eine kräftige Vibration.

Die Zahlen rechnet `LevelUp.between` in `packages/progression`, aus den
Kurven, die es gibt. Gefeiert wird an den vier Stellen, an denen schon
gefeiert wird (Häkchen, Lektion, Lauf, Kauf und Verkauf), **nach den
Errungenschaften und vor den Fähigkeiten**. Kein Beobachter, der von
selbst horcht, sonst feierte er auch beim Laden und im Entwicklermodus.

progression 41, App 457. **Nicht getestet:** dass jede der vier Stellen
die Feier wirklich auslöst. Getestet sind das Blatt und `showLevelUp`
selbst, die Verdrahtung ist nur gelesen. ~~**Nicht angesehen.**~~ ✓ *Am 24.09. am Handy gespielt.*

## Sitzung 23.09.2026, Nachtrag: das Buch auf der Theorie

Frederik hat alles aus dieser Sitzung gespielt („sehr coole Änderungen").
Der Theorie-Kreis auf der Startseite trägt jetzt ein gezeichnetes Buch
statt des Baum-Icons: `assets/UI/Buch.png`, 64 × 64 gezeichnet, als
256 × 256 abgelegt. Es ist `Book.png` aus Frederiks Download-Ordner
(`Desktop\Pixelart\Runtergeladen`). **Die Herkunft fehlt**, wie bei den
anderen Paketen. `HubCircle.symbol` legt eine Zeichnung auf die
Knopffläche, fehlt sie, steht wieder das Icon da. App 454.

## Sitzung 23.09.2026, Nachtrag: der Wochenrückblick

Aus der „Wochenkarte zum Teilen" wurde auf Frederiks Wunsch zuerst etwas
für einen selbst: „Am Ende der Woche sieht man seinen Fortschritt der
Woche nochmal auf einen Blick." **Geteilt wird noch nichts**, das wäre
ein Bild samt Teilen-Menü und damit ein neues Paket.

| | |
|---|---|
| Was | sieben Tagespunkte (leer, abgehakt, golden mit Truhe), Häkchen, Erfahrung und Gold der Woche, gewonnene Punkte, Truhen samt Schatz, beste Kette, Vergleich zur Vorwoche |
| Wie | baut sich auf: Die Tage springen nacheinander auf, die Zahlen zählen hoch |
| Wann | sonntags goldene Karte „Deine Woche", montags „Deine letzte Woche", sonst eine Zeile „Diese Woche: 3 / 7 Tage · Rückblick" |
| Ton | sagt, was die Woche war, nie, was sie nicht war; weniger als die Vorwoche heisst „die nächste zählt neu" |

Gerechnet in `HabitTracker.weekOf`; die Erfahrung der Woche zählt die
Kette über die Wochengrenze mit (`xpBetween`, dieselbe Rechnung wie
`totalXp`). **Ein voller Tag ist einer mit geöffneter Truhe**, weil
„alles erledigt" rückwirkend nicht bestimmbar ist. Nichts Neues im
Spielstand. habits 191, App 453. ~~**Nicht angesehen.**~~ ✓ *Am 24.09. am Handy gespielt.*

## Sitzung 23.09.2026, zuallerletzt: Wucht beim Häkchen

Der dritte Punkt aus der Durchsicht. Das Häkchen war der Moment, der am
wenigsten zurückgab. Jetzt:

| | |
|---|---|
| **Zahlen steigen auf** | „+18 EP +5 G", ein gewonnener Punkt, die Tagesform: dort, wo getippt wurde (`AufstiegHost`), auch wenn die Kachel im selben Moment nach unten rutscht |
| **Die Werte-Kachel antwortet** | sie pulst, wenn ein Häkchen auf ihren Wert einzahlt; fällt ein Punkt, springt sie deutlicher und ihr Rand leuchtet grün |
| **Ein Klang für den Punkt** | `SoundEffect.statPunkt`, **vorerst dieselbe Datei wie die Lektion** — es gibt keine weitere |
| **Ring auf der Startseite** | um den Gewohnheiten-Kreis, „3/5", voll golden mit Häkchen |

App 448. Alle Animationen enden von selbst, `pumpAndSettle` bleibt
brauchbar. ~~**Nicht angesehen.**~~ ✓ *Am 24.09. am Handy gespielt.*

Offen aus der Durchsicht blieb danach nur die **Wochenkarte**, siehe
den Nachtrag oben.

## Sitzung 23.09.2026, ganz am Ende: die Tagestruhe

[ADR-0044](../decisions/0044-tagestruhe.md), der zweite Punkt aus der
Durchsicht. **Issue #46 ist damit entschieden:** Das Streak-Eis kommt aus
der Truhe.

| Stufe | Gewicht | Inhalt |
|---|---|---|
| Schlicht | 70 | 5 bis 10 Gold |
| Gut gefüllt | 20 | 15 bis 25 Gold |
| Streak-Eis | 8 | ein Eis und 5 Gold |
| Schatz | 2 | 60 Gold |

Die Truhe erscheint, sobald heute jede laufende Gewohnheit erledigt ist,
mit „Öffnen". Beim Öffnen springt sie auf, der Inhalt steigt herein, der
Klang ist bei allem über „schlicht" der Errungenschaftsklang. Danach
bleibt eine schmale Karte „Tagestruhe: +18 Gold". Vorher nennt die
Tagesform-Karte sie als Ziel („… und die Tagestruhe").

Aus dem Datum gewürfelt, für beide gleich, gespeichert wird nur der Tag
des Öffnens. Im Mittel rund 11 Gold am Tag. `progression_test.dart`
rechnet die Truhe nicht mit. Bild: Raven fc6. habits 182, App 441.
~~**Nicht angesehen.**~~ ✓ *Am 24.09. am Handy gespielt.* Issue #46 auf GitHub ist noch nicht kommentiert.

## Sitzung 23.09.2026, zum Schluss: die Tagesform

[ADR-0043](../decisions/0043-tagesform.md), nach einer kritischen
Durchsicht: Das Abhaken war der schwächste Moment des Spiels, und nach dem
Deckel der Stat-Kurve spürte man die Gewohnheiten im Kampf kaum noch.
Frederik: „Gewohnheiten sollen die ausgewählten Stats auch direkt
erhöhen", zusammen mit dem Vorschlag eines Tagesbonus.

| | |
|---|---|
| Ein Häkchen | heute **+10 %** auf den Wert seiner Gewohnheit: Stärke → Angriff, Ausdauer → Leben, Disziplin → Abwehr, Klarheit → Mana |
| Alles erledigt | **In Form**: +10 % auf alle vier obendrauf |
| Wie lange | bis Mitternacht, abgeleitet, nie gespeichert |
| Wo sichtbar | Karte über der Tagesliste, Meldung beim Abhaken („Angriff heute +10 %", „In Form!"), Machtkarte am Charakter, Eingang zur Grube |

habits 169, action_combat 186, App 439. `pit_sim` unverändert: Sein Bot
geht ohne Häkchen des Tages hinein. ~~**Nicht angesehen.**~~ ✓ *Am 24.09. am Handy gespielt.*

Aus derselben Durchsicht sind Tagestruhe und Wucht beim Häkchen gleich
danach gebaut, siehe oben; offen ist nur noch die Wochenkarte.

## Sitzung 23.09.2026, ganz zuletzt: jeder Knopf gibt nach

Auf Frederiks Wunsch: „Animation bei allen Button Pressed, wirklich bei
allen." Ein Druck sinkt schnell ein (70 ms) und federt beim Loslassen
zurück (220 ms, leicht über das Ziel hinaus). Kleine Knöpfe sinken
deutlicher ein, breite Kacheln nur um wenige Punkte. Eine Stelle:
`lib/ui/druck.dart`.

| Was | Wie |
|---|---|
| Holzplanke, Holzknopf (auch Zurück in der Kopfzeile) | im eigenen Hintergrund (`holz.dart`) |
| `TextButton`, `OutlinedButton` | über das Theme (`main.dart`) |
| Bereichskreise, Kacheln, Laden, Baum, Fragen, Listen in Blättern, Chips, der schwebende Knopf | in `Druck` gelegt, 27 Stellen in 20 Dateien |
| die drei Plätze in der Grube | am eigenen Halte-Zustand; bleibt eingedrückt, solange man zielt |

**Der Innerste gewinnt:** Das Plus auf einer Gewohnheit sinkt ein, die
Karte darum nicht (`DruckSperre`). **Wer scrollt, drückt nicht:** Wandert
der Finger über die Toleranz hinaus, federt die Fläche zurück.

**Nicht angefasst:** die Schalter im Entwicklermodus (bewegen sich schon
selbst) und das Steuerkreuz der Grube (kein Knopf). App 435 (vorher
426). ~~**Nicht angesehen**, weder im Browser noch am Handy. Ob 0,9 bis
0,97 sich richtig anfühlt, sagt nur das Gerät.~~ ✓ *Am 24.09. am Handy gespielt.* Die Zahlen stehen oben in
`Druck`.

## Sitzung 23.09.2026, zuletzt: Erledigtes rutscht nach unten

Auf Frederiks Wunsch: „oben die offenen, unten die, die man am Tag schon
gemacht hat." Die Tagesliste kommt jetzt aus
`HabitTracker.dailyListOn(day)` — offene zuerst, erledigte danach, in
jeder Hälfte nach Priorität wie bisher. Am nächsten Tag ist wieder alles
offen und steht in der alten Reihenfolge. Jede Kachel trägt ihre Id als
Schlüssel, damit der Sprung des Häkchens mit der Gewohnheit wandert.

Die Kachel **springt**, sie gleitet nicht — eine Animation beim
Umsortieren gibt es nicht. habits 162, App 426. ~~**Nicht angesehen.**~~ ✓ *Am 24.09. am Handy gespielt.*

## Sitzung 23.09.2026, danach: getroffen heisst bemerkt

Auf Frederiks Ansage: „Sobald Gegner Damage kriegen, haben sie Aggro auf
den Spieler." Vorher bemerkte ein Gegner den Helden nur im Umkreis von
210 Punkten — ein Funke aus 250 liess ihn stehen, und man konnte ihn
gefahrlos abtragen. Jetzt kommt jeder, der verwundet ist, egal woher der
Schaden kam (Geschoss, Fläche, Dauerschaden). Eine Stelle:
`ActionWorld._enemiesAct`. action_combat 185.

`pit_sim` nachgerechnet: Die Kurve liegt, wo sie lag — Tag 30 bis Stufe
10/11, voll ausgerüstet mit Fähigkeiten Stufe 30 zu 58 %. Der Bot
schiesst selten aus der Ferne, der Effekt ist dort klein.

## Sitzung 23.09.2026: Zielen über Wände hinweg

Auf Frederiks Ansage: „Das Aimen von Fähigkeiten darf durch Wände gehen,
aber nicht die Fähigkeit an sich."

| | vorher | jetzt |
|---|---|---|
| Bereich absetzen | zurückgenommen vor die Wand | landet, wo gezielt — bis `castRange` |
| Geschoss einer Fähigkeit | bleibt an der Wand hängen | **unverändert** |
| Vorschaulinie eines Geschosses | lief schon durch Wände | unverändert |
| Kurz tippen | zielt nur auf Gegner in Sicht | unverändert |

Eine Zwischenfassung liess auch Geschosse durch Wände fliegen — das war
falsch verstanden und ist zurückgenommen. action_combat 183 (vorher
182). ~~**Nicht angesehen**~~ ✓ *Am 24.09. am Handy gespielt.* `pit_sim` nicht neu gerechnet — der Bot zielt
nie von Hand und trägt keinen Bereich.

## Sitzung 22.09.2026, abends: Macht vervielfacht

[ADR-0042](../decisions/0042-macht-vervielfacht.md), Schritt A und C der
Spanne. action_combat 182, gear 90, progression 36, App 424.

| | vorher | jetzt |
|---|---|---|
| Level im Kampf | wirkt nicht | ×1,04 je Level auf Angriff, Leben, Abwehr |
| Seltenheit | nur ihre festen Boni | Waffe ×1 bis ×2,2 auf Angriff, Rüstung auf Leben |
| Kampfzahlen | wie die Werte | **mal zehn** |
| Stufen | Leben ×3,4, Angriff ×2,5 auf 30 | dazu ×1 bis ×5 auf Leben, Angriff, Abwehr |
| Gewohnheiten, Boni | additiv, gedeckelt | **unverändert** |

**Gemessen:** Tag 0 geht mit 141 Angriff und 1.731 Leben hinein, Tag 60
voll ausgerüstet mit 1.654 und 18.449 — fast zwölfmal so hart statt gut
doppelt. Die Siegquoten je Stufe liegen, wo sie lagen.

Der Charakter zeigt über den Werten eine Karte „Angriff · Leben · Abwehr"
mit den Faktoren. ~~**Nicht angesehen.**~~ ✓ *Am 24.09. am Handy gespielt.* Im Laden steht noch nicht, dass
Waffe und Rüstung ihre Seltenheit vervielfachen.

## Sitzung 22.09.2026, ganz zuletzt: die vier Stufen des Tages

Auf Frederiks Wunsch, wie die Fraktal-Dailies in Guild Wars 2
([ADR-0040](../decisions/0040-vier-dailies-je-tag.md)). action_combat 169
(vorher 156), App 420 (vorher 416).

| | |
|---|---|
| Welche | vier aus dem Geschafften: eine leichte, zwei mittlere, eine von oben — aus dem Datum gewürfelt, für beide gleich |
| Was | ein **Viertel** des Erstsiegs, einmal je Stufe und Tag |
| Wann | **nur an Tagen mit einem Häkchen** — sonst steht dort „erst ein Häkchen setzen" |
| Wo | eine Karte auf dem Eingang zur Grube, antippen führt hinein |

**Eingefroren beim ersten Gebrauch**: Wer mittags eine neue Stufe
schafft, behält seine vier. Gespeichert als Historie
(`LadderProgress.dailyClears`), Erfahrung und Gold werden gerechnet.

**Gegen die Kurven nicht nachgerechnet.** Um Stufe 15 bringen vier
Dailies rund 90 Erfahrung und 36 Gold am Tag, ganz oben höchstens 158
und 64 — der Laden, ausgelegt auf 25 Gold am Tag aus Gewohnheiten,
bekommt damit um Stufe 15 gut das Doppelte (61 statt 25) und leert sich entsprechend schneller. `progression_test.dart` weiss
davon noch nichts.

**Beim Bauen gemeldet:** `LadderProgress` hatte optionale Felder mit
Standardwert — die Bauform aus `gotchas.md`, die schon zweimal ein Feld
verschluckt hat. `defeat` und `recordDefeat` gehen jetzt über `copyWith`.

### Die Spanne, erster Schritt: Streuung und Krits

Frederik: „min Damage und max Damage liegen weiter auseinander, so wie
Diablo." Von drei vorgeschlagenen Schritten (B Streuung und Krits,
A grössere Zahlen, C multiplizieren statt addieren) ist **B gebaut**:

| | vorher | jetzt |
|---|---|---|
| Streuung eines Heldenschlags | 85–115 % | **60–140 %** |
| Kritisch | 0 % | **8 %**, doppelter Schaden, gross und golden |
| Streuung der Gegner | 85–115 % | unverändert — sonst wird Sterben Lotterie |

`pit_sim`: etwa eine Stufe leichter, am deutlichsten oben (Tag 60 +
Ausrüstung, Stufe 25: 8 % → 42 %). Das sind die Krits, im Mittel rund
8 % mehr Schaden; die Streuung allein verschiebt den Mittelwert nicht.
**A und C sind danach gebaut**, siehe unten.

### Erfahrung und Gold je Gegner

[ADR-0041](../decisions/0041-beute-je-gegner.md). Jede Stufe hat einen
**Topf** — ihren Erstsieg, als Daily ihr Viertel. Jeder Kill zahlt seinen
Teil („+7 EP  +3 G" über dem Gegner, mitlaufend in der Kopfzeile), der
Wächter füllt auf. **Ein verlorener Lauf behält, was gefallen ist**, der
nächste kann nur noch den Rest holen. In der Summe genau wie vorher.

action_combat 177 (vorher 169), App 422 (vorher 420). ~~Nicht angesehen.~~ ✓ *Am 24.09. am Handy gespielt.*

## Sitzung 22.09.2026, zuletzt: Skillshots, und niemand hängt mehr

Auf Frederiks Wünsche: „Fähigkeiten mithilfe von AOE-Einfärbungen
erkenntlich machen und länger halten macht Skillshot aus Sachen", „so
was wie Eisfeld oder Zeitdehnung sollen AOE-Skillshots werden", und:
„Gegner bleiben öfter an Ecken hängen". action_combat 156 (vorher 138),
App 416 (vorher 412).

### Niemand hängt mehr

Gemessen statt geraten: Ein unverwundbarer Held läuft durch gebaute
Gruben, gezählt wird, wer ihm folgt, einen Weg hätte und eine Sekunde
lang nicht vorankommt. **Drei Ursachen**, nacheinander gefunden:

| Ursache | Wer | Abhilfe |
|---|---|---|
| An einer Ecke wurde die blockierte Achse **verworfen** — man glitt nicht um die Kante | alle | `_slide` bewegt und **drückt dann aus der Wand**; an einer Ecke zeigt das schräg |
| Troll und zwei Fussvolk wollten zum selben Wegpunkt, das Wegschieben hielt alle fest | Stau im Durchgang | wer 0,6 s auf der Stelle tritt, geht 0,8 s **durch Verbündete** |
| Das Wegfeld kennt keine Körperbreite — der Troll (36 Punkte) wurde in Gänge von einem Feld geschickt | Troll | **zweites Wegfeld** für breite Figuren: nur Felder in freien 2 × 2-Blöcken |

In 60 Gruben (Stufe 1, 15, 30) vorher 10 Hänger je 30, jetzt keiner.
`chase_test.dart` hält das fest.

### Skillshots

| Art | Fähigkeiten | Tippen | Halten und Ziehen |
|---|---|---|---|
| selbst | Steinhaut, Aurastrom, Blütentau, Prisma, Sammeln, Atemzug | wirkt beim Drücken | — |
| Richtung | Funkenstoß, Donnerkeil, Seelenraub, Kraftschlag, Zehrung | zielt auf den nächsten Gegner | Linie oder Kegel, **daneben ist daneben** |
| um den Helden | Klingenwirbel | wirkt | Kreis zeigt, was er erfasst |
| **Bereich** | Wurzelgriff, **Frostnebel (Eisfeld)**, Sandsturm, Giftmoor, **Zeitdehnung**, Vulkanbruch, Sternenfall | setzt sich auf den nächsten Gegner | Kreis absetzen, bis 220–260 weit |

**Eine abgesetzte Fläche bleibt liegen** und bremst oder verbrennt jeden,
der hineinläuft, solange sie liegt — in ihrer Farbe am Boden. Vorher
traf sie einmal, wer gerade im Umkreis stand.

**Am Rechner:** Taste 1–3 halten, mit der Maus zielen, loslassen.

**Tippen ohne Ziel kostet nichts, ein gezielter Wurf immer.** Ein
Geschoss fliegt jetzt genau seine Reichweite weit (vorher vier Sekunden
lang) — sonst wäre die Vorschau kürzer als der Funke.

### Was sich an Zahlen geändert hat

- **Zeitdehnung** traf alles in 600 Punkten Umkreis. Abgesetzt wäre das
  der ganze Bildschirm; jetzt 170. Deutlich schwächer, nicht
  nachgestellt.
- Bereiche sitzen jetzt dort, wo man sie hinsetzt, nicht am Helden.
- `pit_sim` liegt im Rauschen — **misst die Flächen aber nicht**: Der Bot
  trägt Funkenstoß, Steinhaut und Blütentau, keinen Bereich, und er
  zielt immer selbst, trifft also nie daneben.

### ~~Nicht angesehen~~ Am 24.09. am Handy gespielt ✓

Weder im Browser noch am Handy. Offen, und nur am Gerät zu klären: ob
80 Punkte Zug für die volle Weite passen, ob die Totzone von 12 Punkten
Tippen und Ziehen sauber trennt, ob man einen Wurf abbrechen können
muss (heute nicht — Loslassen wirkt immer).

## Sitzung 22.09.2026, danach: Tor, Auftritt, Sieg am Wächter

Auf Frederiks Wünsche: „Bossraum ist nur Boss und der Raum schließt
sich", dann: „der Dungeon ist fertig, wenn der Boss tot ist" und „eine
Art Entry … erst dann den HP-Balken und Namen wie bei Dark Souls".
Allein im Raum war der Wächter seit #74 schon.

| | |
|---|---|
| **Sieg** | wenn der Wächter fällt — wer draussen noch steht, zählt nicht |
| **Tor** | der Gang in den Wächterraum, wo er dessen Felsrand kreuzt, zwei Felder (`=`) |
| Zu | sobald der Held **ganz** im Raum steht und niemand im Durchgang; geht nie wieder auf |
| Draussen | wer keinen Weg mehr hat, bleibt stehen statt gegen das Gitter zu drücken |
| **Vorher** | der Wächter schläft — unsichtbar, unberührbar, untätig |
| **Auftritt** | 2,4 s: fällt aus 420 Punkten herab, landet mit Ring und Beben, brüllt |
| Name und Balken | erst ab der Landung; der Balken läuft voll, Name klein darüber |
| Schriftzug | „DER WÄCHTER · Hüter der Tiefe" in der Mitte, blendet ein und aus |

**Unberührbar ist ein Feld, keine Ausnahme je Stelle.**
`ActionEntity.untouchable` lässt `takeDamage` nichts abziehen, und
Zielwahl, Geschosse, Flächentreffer, Schieben und das Handeln der Gegner
lassen die Figur aus. Der Bot sieht den schlafenden Wächter nicht und
läuft deshalb über `sleepingBossAt` zu ihm, wenn niemand sonst da ist.

**Der Renderer weiss vom Fallen nichts.** Die Welt meldet den Wächter
beim Auftritt höher, als er steht; der Renderer zeichnet, was er sieht.

**Die Grube wird dadurch in der Mitte leichter** (`pit_sim`): Tag 14
kommt bis Stufe 7 statt 6, Tag 30 mit Fähigkeiten bis 14 statt 13 —
man muss nicht mehr jeden Raum räumen. Anfang und Spitze bleiben. Nicht
nachgestellt.

action_combat 138 (vorher 124), App 412.

**„Hüter der Tiefe" ist ausgedacht**, ohne Vorlage — ändern ist eine
Zeile in `pit_run_view.dart`. ~~**Nicht angesehen**, weder im Browser noch
am Handy.~~ ✓ *Am 24.09. am Handy gespielt.* Kein Klang zu Tor oder Landung.

## Sitzung 22.09.2026: Gegner laufen gerade

Auf Frederiks Frage: „Kann es sein, dass Gegner rechtwinklig und nicht
euklidisch zum Spieler laufen?" Ja. Das Wegfeld (`FlowField`) kennt nur
vier Richtungen, und geradeaus ging es nur unter 46 Punkten Abstand.
Jeder Gegner lief deshalb Treppen, **auch im offenen Raum**.

**Jetzt gilt:** Wer mit seiner ganzen Breite in Luftlinie zum Helden
passt, läuft direkt (`ActionWorld._canPass`, strenger als die
Sichtlinie). Sonst folgt er dem Feld, steuert aber den weitesten der
nächsten acht Wegpunkte an, den er noch ohne Wand erreicht
(`FlowField.pathFrom`, `ActionBalance.chaseLookaheadTiles`). Um Ecken
geht es damit schräg statt über Eck.

`test/chase_test.dart` hält es fest; der Test im offenen Saal ist mit dem
alten Code rot. action_combat 124 (vorher 121), App 412.

**Nebenbei:** „eine eingesammelte Kugel heilt" hing an einem einzigen
Startwert und fiel mit den neuen Laufwegen um. Er läuft jetzt über fünf.

**Die Balance bewegt sich nicht messbar** (`pit_sim`, Tag 0 auf Stufe 1
mit 100 Läufen: 72 % statt 74 %). Nicht angefasst: Der Test-Bot in
`bot.dart` läuft weiter über das Feld, also in Treppen.

## Sitzung 21.09.2026, noch später: der Wächter kann etwas

Schritt 4 aus [ADR-0039](../decisions/0039-die-grube-ersetzt-den-rundenkampf.md),
auf Frederiks Wunsch („den Boss im Endraum alleine haben und mit coolen
Fähigkeiten"). Baut auf #73 auf. action_combat 121 (vorher 109), App 412.

**Allein im Endraum** — beide Wächterräume ohne Leibwächter und Schützen.

| Angriff | ab Stufe | Ankündigung | Wirkung |
|---|---|---|---|
| **Bodenstoss** | 1 | roter Ring füllt sich, 1,0 s | wer drinsteht: Angriff × 1,8 |
| **Felswurf** | 4 | der Brocken selbst — gross und langsam | Angriff × 1,2, ausweichen seitlich |
| **Ansturm** | 8, nur bei Wut | rote Linie, 0,8 s | rennt bis zur Wand, Angriff × 1,8 |
| **Wut** | immer | Balken „Der Wächter · wütend" | unter halbem Leben: Abklingzeiten × 1/1,5 |

**Jeder Angriff lässt sich durch Laufen umgehen** — seit #73 gibt es
keinen Sturmschritt. Der Ring füllt sich länger, als der Held braucht, um
aus ihm herauszulaufen; ein Test hält das fest. Der Bot läuft aus
angekündigten Zonen heraus, einem Felswurf weicht er nicht aus.

**Warum er mit der Tiefe dazulernt:** Mit allen drei Angriffen von
Anfang an schaffte ein frischer Charakter Stufe 1 nur noch zu 40 % statt
90 % — sein allererster Kampf. Jetzt wieder 90 %.

**Was die Simulation sagt** (`pit_sim`, gegenüber #73): Die Mitte ist
härter (Tag 30 auf Stufe 10: 10 % statt 50 %), **die Spitze nicht mehr
geschenkt**: voll ausgerüstet mit Fähigkeiten und allen Legendären Stufe
30 zu 50 % statt 100 %. Die offene Frage von #69 („Legendäre machen die
Spitze zu leicht") ist damit nebenbei beantwortet.

**Nicht gebaut:** eigene Bilder für die Angriffe — der Zyklop hat nur
einen Streifen „steht". Ring, Linie und Welle zeichnet der Code.

## Sitzung 21.09.2026, ganz zum Schluss: keine Grundfähigkeiten mehr

Auf Frederiks Ansage: „Der Rundumschlag und der Dash sollten nicht als
Grundfähigkeiten im Kampf verfügbar sein." Im Kampf gibt es jetzt nur
noch den **Grundangriff der Waffe** und die **drei Plätze** (1–3).

**Ganz entfernt**, nicht nur ausgeblendet: `ActionAbility`,
`AbilitySpec`, die Abklingzeiten, die Sturmschritt-Bewegung, der
Rundum-Treffer, das Ereignis `AbilityUsed`, die zwei festen Knöpfe und
die Tasten 4, Leertaste und Umschalt. Ein Test hält fest, dass diese
Tasten nichts mehr tun. action_combat 109 (vorher 120 — die Tests der
beiden Fähigkeiten), App 412.

**Geblieben**: der goldene Ring. Er erscheint jetzt bei jeder Fähigkeit
mit Flächentreffer (Klingenwirbel, Wurzelgriff, Vulkanbruch, Sternenfall),
so gross wie ihre Reichweite — dort fehlte bisher jede Rückmeldung.

Der Prototyp im Entwicklermodus trägt jetzt drei feste Fähigkeiten
(Funkenstoß, Klingenwirbel, Blütentau) statt „alle".

**Die Grube wird dadurch in der Mitte etwas härter** (`pit_sim`): Tag 30
auf Stufe 10 von 70 auf 50 %, mit drei Fähigkeiten auf Stufe 13 von 40
auf 10 %. Anfang und Spitze bleiben. Nicht nachgestellt.

**Offen**: Ausweichen gibt es jetzt nicht mehr. Wer es wieder will,
bekommt es als lernbare Fähigkeit — eine neue Wirkung in `PitEffect`,
kein fester Knopf.

## Sitzung 21.09.2026, zum Schluss: Holzrahmen um alles

Auf Frederiks Wunsch („beim UI um alles so einen Holzrahmen, dass das
einheitlich aussieht"). 412 App-Tests, unverändert.

Drei Bauteile in `lib/ui/holz.dart`, alle aus demselben Rahmenbild:

| | wofür | wo |
|---|---|---|
| `HolzKarte` | jede Pergamentfläche | 21 Karten: Charakter, Gewohnheiten, Laden, Theorie, Start, Grube, Errungenschaften, Entwicklermodus |
| `HolzDialog` | jeder Dialog, hängend am Seil | Name, Titel, Verkaufen, Entwicklermodus, Ergebnisblatt |
| `HolzBlatt` | jedes Blatt von unten | Fähigkeit wählen, Ausrüstung wählen, eigene Gewohnheit |

`HolzKarte` kann ihre Kante färben — grün beim Abhaken, Akzent bei einer
verdienten Errungenschaft und beim Streak-Eis. **Ausgenommen** sind
Kacheln in Rastern, Knöpfe und Kreise.

**Zwei Dinge, die dabei aufgefallen sind:**

- Ein `AlertDialog` im hängenden Rahmen bekam unbegrenzte Höhe und brach
  mit einer Liste darin ab („does not support returning intrinsic
  dimensions"). `HolzDialog` begrenzt die Höhe — aus dem Platz, nicht
  aus `MediaQuery`: Im Browser meldet die das ganze Fenster, `PhoneFrame`
  zeigt aber nur 844 Punkte, und der Rahmen lief dort um 256 über.
- Der Rahmen kostet 24 Punkte Breite. Die Kampfwert-Zeilen im Charakter
  liefen darum über und dürfen jetzt schrumpfen.

**Angesehen** als gerendertes Testbild (Charakter, Gewohnheiten, Start),
mit Ersatzschrift und ohne App-Theme. ~~**Nicht am Handy angesehen.**~~ ✓ *Am 24.09. am Handy gespielt.*

## Sitzung 21.09.2026, danach: zwei neue Gegnerarten

Auf Frederiks Wunsch („Fledermäuse, die schneller sind, und mal
zwischendurch größere, stärkere Gegner"). action_combat 120 (vorher 111).

| | Kobold `k` | Troll `t` |
|---|---|---|
| Bild | Red Cap aus dem Paket | Stone Troll aus dem Paket |
| Tempo | **155** — schneller als der Held (120) | 44 |
| Leben / Angriff | 16 / 6 | 180 / 18 |
| Besonderes | kommt im Rudel | lässt sich nicht stossen, lässt **immer** eine Heilkugel |
| Wo | zwei Bausteine („Nest", „Höhle"), einer in der „Halle" | ersetzt Fussvolk: 15 % je Raum auf Stufe 1, 60 % auf Stufe 30 |

**Eine Fledermaus gibt es im Paket nicht** — der Kobold steht an ihrer
Stelle. Kommt eine Zeichnung, ist es eine Zeile in `GrubeFiguren`.

**Was der erste Test gefunden hat:** Bei Tempo 135 holte der Kobold
einen weglaufenden Helden nie ein. Der Held schlägt im Laufen von selbst,
und der Rückstoss (9 Punkte je Schlag) frass den Vorsprung von 15 Punkten
je Sekunde auf. Jetzt 155.

**Die Kurve bleibt, wo sie war** (`pit_sim`): Tag 14 kommt etwas weniger
weit, der Rest liegt im Rauschen von zehn Läufen je Feld.

## Sitzung 21.09.2026, zuletzt: der Rundenkampf ist gelöscht

Schritt 5 aus [ADR-0039](../decisions/0039-die-grube-ersetzt-den-rundenkampf.md),
auf Frederiks Ansage „Alles, was den Rundenkampf betrifft, kann raus".
#66 bis #69 sind auf `main`, die Web-Fassung ist gebaut.

**Weg:** `packages/combat` (Engine, 30 Gegner, Umgebungen, Timing),
Kampfbildschirm, Timing-Leiste, Umgebungsbanner, Flame-Darstellung der
Kämpfer, Zughilfe, Gegnerbilder-Tabelle, `tool/balance_sim.dart` und
rund 90 Tests, die nur ihn prüften. **PR #60 und #62 geschlossen** —
beide bauten am Rundenkampf.

**Umgezogen:** `LadderProgress` und `LadderRewards` nach
`packages/action_combat` (samt Tests), die Kampfsperre nach
`lib/action/pit_gate.dart`. `activeMovesProvider` liefert jetzt Ids statt
Züge; Namen und Beschreibungen kommen aus `lib/action/pit_text.dart`.

| | vorher | jetzt |
|---|---|---|
| App-Tests | 502 | **408** |
| action_combat | 101 | **111** (Reihe dazu) |
| Packages | 9 | **8** |

**ADR-0003, 0009, 0015 und 0023** stehen auf „Abgelöst durch ADR-0039",
**0022 und 0030** auf „teilweise" — ihre Ids und Arten gelten weiter.

**Stehen gelassen:** #61 (Laden graut aus) — betrifft nicht den
Rundenkampf.

## Sitzung 21.09.2026, später: Sets und legendäre Kräfte

Schritt 3 aus [ADR-0039](../decisions/0039-die-grube-ersetzt-den-rundenkampf.md).
Eigener Branch über #68. 498 App-Tests (vorher 491), action_combat 101
(vorher 89), gear 88.

**Wie es gebaut ist:** Eine Veränderung (`PitModifier`, `sealed`) nimmt
eine Fähigkeit und gibt eine neue zurück — mehr Schaden, mehr
Dauerschaden, billiger, stärkerer Schutz, kürzere Abklingzeit oder
zusätzliche Wirkungen. Die Welt sieht nur das Ergebnis und braucht für
Sets keine Zeile.

**Die drei Sets in der Grube:**

| Set | wirkt auf | 2 Teile | 4 Teile |
|---|---|---|---|
| Eiserner Wille | Angriff | +10 % Schaden | +25 % |
| Sturmruf | Umgebung | −5 Mana | −10 Mana |
| Ruhiger Stand | Schutz | +25 % Heilung, Schutz hält länger | +60 % |

Sturmruf rechnet seinen Energie-Rabatt zum selben Kurs um wie der
Vorrat (1 Energie = 5 Mana, `ActionBalance.manaPerEnergy`). Ruhiger
Stand hat ein neues Feld `SetPerk.protectionFactor` bekommen — seine
Timing-Werte bedeuten in Echtzeit nichts. Der Laden zeigt beim Set jetzt
„Schutz und Heilung 60 % stärker" statt der Leiste.

**Die sechs legendären Kräfte**, je eine am Stück
(`GearItem.legendaryPower`), die Wirkung in `PitLegendaries`:

| Stück | Kraft | tut |
|---|---|---|
| Sonnenklinge | Sonnenglut | jeder Dauerschaden ×1,5 |
| Titanenpanzer | Steinerne Haut | Steinhaut und Sammeln werfen ein Drittel zurück |
| Krone des Hochwächters | Weitblick | alle Abklingzeiten −20 % |
| Stiefel des Titanen | Beben | Kraftschlag und Wurzelgriff treffen und bremsen alles in der Nähe |
| Ring des Erzdämons | Erzhunger | jede Fähigkeit ein Drittel billiger |
| Herz des Titanen | Lebensquell | Heilung und Schutz ×1,5 |

Der Laden nennt die Kraft unter dem Stück, und die Waffenzeile
beschreibt jetzt den Grundangriff in der Grube („Grundangriff: Hieb —
×1,25 Schaden") statt der Energie im Rundenkampf.

### Nachgereicht: Tasten

Auf dem Rechner liegen die Angriffe jetzt auf der Zahlenreihe: **1–3
die Plätze, 4 der Rundumschlag**, auch im Nummernblock. Leertaste und
Umschalt (Sturmschritt) bleiben. Dabei kam heraus, dass **Flames
Spielfeld Tasten verschlucken konnte**, sobald es den Fokus hatte
(`gotchas.md`). Wann es ihn hatte, ist nicht geklärt — WASD ging beim
Spielen offenbar, im Test ging gar nichts. `test/pit_keys_test.dart`
hält die Belegung jetzt fest.

### Offen

- **Mit allen sechs Kräften wird Stufe 30 leicht**: 90 % statt 20 %
  (`pit_sim`, Spalte „T60+G+F", der Bot trägt dort sechs legendäre
  Stücke). Das ist der Endstand des Spiels und darf leichter sein — ob
  so viel, ist eine Frage, keine Messung. Der wahrscheinliche Hebel ist
  Erzhunger zusammen mit Weitblick.
- **Die Simulation rechnet keine Sets**, weil die besten Stücke je Platz
  keines bilden.

## Sitzung 21.09.2026, nachts: alle Fähigkeiten, die Waffe, die Kurve

Schritt 2 aus [ADR-0039](../decisions/0039-die-grube-ersetzt-den-rundenkampf.md)
ist damit ganz. Eigener Branch über #67. 491 App-Tests (vorher 489),
action_combat 89 (vorher 73).

**Alle neunzehn Fähigkeiten wirken in der Grube**, gebaut aus neun
Arten von Wirkung: Geschoss (mit Lebensraub), Nahschlag, Rundumschlag,
Heilung, Mana, Schadensminderung, Zurückwerfen, Verlangsamen,
Dauerschaden. Vulkanbruch ist zum Beispiel Rundumschlag plus
Dauerschaden, Wurzelgriff Rundumschlag plus Verlangsamen.
Gegner zeigen es an: blauer Ring verlangsamt, oranger Punkt brennt.

**Die Waffe ist der Grundangriff** (`PitWeapons`):

| Waffe | Grube |
|---|---|
| Kurzbogen | schiesst, schwach, Reichweite 190 |
| Übungsklinge | Hieb, ×1,25 |
| Streitkolben | ×1,6, langsam |
| Geschliffene Klinge | zwei Stiche |
| Kriegsstab | +3 Mana je Treffer |
| Zweihänder | trifft **alles** in Reichweite, langsam |
| Langbogen | zwei Pfeile, Reichweite 230 |
| Sonnenklinge | jeder Treffer brennt nach |

**Sichtlinie**: Funken, Blitze und Pfeile zielen nur auf Gegner, die man
sieht. Der offene Punkt aus der letzten Sitzung (Funke verpufft an der
Wand) ist damit erledigt.

**Die Stufen sind neu abgestimmt**, wie in ADR-0039 für diesen Moment
vorgesehen. Vorher räumte ein ausgerüsteter Bot mit dem richtigen
Waffenzug Stufe 30 auch ohne Fähigkeiten zu 90 %. Jetzt
(`dart run tool/pit_sim.dart 10`):

| | Tag 0 | Tag 14 | Tag 30 | Tag 30 + 3 F. | Tag 60 + Gear | + 3 F. |
|---|---|---|---|---|---|---|
| Stufe 1 | 70 % | 100 % | 100 % | 100 % | 100 % | 100 % |
| Stufe 10 | 0 % | 0 % | 70 % | 100 % | 90 % | 100 % |
| Stufe 13 | 0 % | 0 % | 0 % | 50 % | 100 % | 100 % |
| Stufe 25 | 0 % | 0 % | 0 % | 0 % | 20 % | 100 % |
| Stufe 30 | 0 % | 0 % | 0 % | 0 % | 0 % | 20 % |

**Die Spitze braucht beides, Ausrüstung und Fähigkeiten.** Leben ×3,4
und Angriff ×2,5 auf Stufe 30 statt ×2,1 und ×1,8.

### Offen

- **Tag 0 ist mit dem Kurzbogen schwächer als mit der Faust** (Stufe 3:
  20 % statt 50 %). Ein frischer Spieler hat Stufe 1 und 2; das reicht
  für den Anfang, ist aber eine gemessene Verschiebung.
- **Energie tut weiter zweierlei** (Mana und Schlagtempo).
- ~~**Nicht am Handy gespielt**, wie alles aus dieser Nacht.~~ ✓ *Am 24.09. am Handy gespielt.*

## Sitzung 21.09.2026, spät: Mana und die ersten drei Fähigkeiten

Schritt 2 aus [ADR-0039](../decisions/0039-die-grube-ersetzt-den-rundenkampf.md),
auf eigenem Branch über #66. 489 App-Tests (vorher 485), action_combat
73 (vorher 58).

| Fähigkeit | Art | Mana | Abklingzeit | Wirkung |
|---|---|---|---|---|
| Funkenstoß | Schaden | 12 | 1,5 s | Geschoss auf den nächsten Gegner, Angriff × 1,2 |
| Steinhaut | Wert | 20 | 12 s | 5 s lang 40 % weniger Schaden, goldener Ring |
| Blütentau | Heilung | 30 | 14 s | ein Viertel der vollen Gesundheit |

**Mana kommt aus der Energie**: 5 je Punkt (Tag 0: 40), dazu 4 + 0,25 je
Punkt pro Sekunde. **Eine Wirkung ist ein Datum** (`PitEffect`), damit
Sets und Legendäre sie später verändern können, statt Sonderfälle in die
Welt zu schreiben. Die Plätze kommen aus `activeMovesProvider`;
Fähigkeiten, die die Grube noch nicht kennt, fallen still heraus.
Auf der Tastatur 1, 2, 3.

**Was die Simulation dazu sagt** (`tool/pit_sim.dart`, Spalten „+F"):
Tag 30 kommt mit allen dreien bis etwa Stufe 17 statt 15. **Voll
ausgerüstet mit allen dreien räumt der Bot jede Stufe, auch 30** — ohne
Fähigkeiten waren es dort 20 %. Einmal nachgeregelt (Funkenstoß
schwächer), ohne dass sich das oben bewegt hat. Die Stufenkurve wird neu
abgestimmt, wenn mehr Fähigkeiten drin sind — jetzt wäre es Tarieren an
einem halben Katalog.

### Offen

- **Energie tut zweierlei**: Mana *und* weiterhin Schlagtempo. Das war
  vorher schon so und ist nicht angefasst; entschieden werden sollte es
  mit der Potenz-Kurve.
- **Der Funke zielt in Luftlinie** und bleibt an Wänden hängen. Hinter
  einer Wand verpufft er samt Mana.
- ~~**Nicht am Handy gespielt.**~~ ✓ *Am 24.09. am Handy gespielt.* Drei Platzknöpfe über den zwei festen —
  ob das neben dem Steuerkreuz Platz hat, sagt erst ein Gerät.

## Sitzung 21.09.2026, abends: die Grube ist der Kampf

**Entschieden und gebaut, Schritt 1 von 5**
([ADR-0039](../decisions/0039-die-grube-ersetzt-den-rundenkampf.md),
Issue [#65](https://github.com/Prozesstek/LifesGame/issues/65)). Der
Kampf-Kreis führt jetzt in die Grube, der Rundenkampf ist nicht mehr
erreichbar. 485 App-Tests (vorher 481), action_combat 58 (vorher 47).

Vier Entscheidungen, jede mit der Empfehlung getroffen:

| Frage | Antwort |
|---|---|
| Was wird aus den 30 Sprossen? | **30 Stufen der Grube** — `LadderProgress` bleibt, damit auch Laden-Sperren, Errungenschaften und Belohnung |
| Wie entstehen die Hallen? | **Räume, gesät zusammengesteckt** — sieben Räume, zwei Wächterräume |
| Was wird aus den Fähigkeiten? | **Id, Icon, Freischaltung bleiben**, die Wirkung wird für Mana und Abklingzeit neu gebaut |
| Übergang? | **Sofort ersetzen**, `packages/combat` später löschen |

| Was | Wo |
|---|---|
| Dreissig Stufen: Leben, Angriff, Verteidigung, Räume | `PitStage`, Zahlen in `ActionBalance` |
| Jede Grube neu, aus Räumen | `RoomCatalog`, `LevelBuilder` — 1200 Karten im Test geprüft |
| Ein Lauf trägt sich ein | `LadderController.recordRun`, gerufen nur aus `PitScreen` |
| Eingang „N / 30", Stufe, „Hinab" | `LadderScreen` |
| Simulation über alle Stufen mit echter Werte-Kurve | `dart run tool/pit_sim.dart` |

**Was die Simulation sagt:** Tag 0 schafft Stufe 1 zu 70 %, Tag 30 kommt
bis etwa Stufe 15, voll ausgerüstet an Tag 60 steht Stufe 30 bei 20 %.
Das ist die Form der alten Reihe, unten gnädiger und oben härter.
**Nicht abgestimmt** — die Fähigkeiten werden es verschieben.

### Offen, und bewusst so

- **Die fünfzehn Fähigkeiten tun in der Grube nichts.** Dort gibt es nur
  Sturmschritt und Rundumschlag. Sie sind Schritt 2.
- **Waffenzug und Sets wirken nicht.** Die Waffe zählt nur mit ihren
  Werten.
- **Die Kampfsperre (ADR-0020) bleibt**, obwohl Stufe 1 mit Tag-0-Werten
  schlagbar ist. Entschieden wird das, wenn die Fähigkeiten wirken.
- **Die Potenz-Kurve** ist weiter offen.
- ~~**Nicht am Handy gespielt.** Tests und Layout bei 390 × 844 sind
  grün; wie sich eine gesteckte Grube spielt, muss jemand ansehen.~~ ✓ *Am 24.09. am Handy gespielt.*

### Als Nächstes

1. Mana und ein Fähigkeiten-Katalog in `action_combat`, die ersten drei
2. Die übrigen Fähigkeiten, Waffe = Grundangriff
3. Sets und Legendäre als Veränderung einer Fähigkeit
4. Der Endgegner mit eigenen Angriffen
5. `package:combat` auflösen

## Sitzung 21.09.2026: alles auf main — Bilder, Klänge, Holz

Acht PRs an einem Tag gemergt, in dieser Reihenfolge: #52 Lern-Vorlage,
#58 ADR-0037, #53 Levelsperre raus, #50 Ertrag sichtbar, #55 Raven-Icons,
#56 Klänge, #57 Holz-Stil, #51 die Grube. **481 App-Tests.**

| Was | Wo |
|---|---|
| **Jeder Zug und jedes Ausrüstungsstück hat ein Bild** — 27 + 48, alle aus dem Raven-Paket (64 × 64) | `assets/RAVEN.md` sagt, welche Nummer hinter welcher Datei steht |
| **Vier Klänge**: Häkchen, Lektion, Sieg, Errungenschaft | `SoundEffect` in `lib/audio/sound_effects.dart`; in Tests stumm |
| **Holz-Stil**: Planke, Holzknopf, Balken, hängender Rahmen | `lib/ui/holz.dart`, über das Theme |
| **Levelsperre der Zweige entfernt** — `unlockLevel` wurde nirgends mehr gelesen | — |
| **Neuer Knoten „Was ist Psychologie"** unter Aufmerksamkeit, der erste auf Ebene 2 | Startbaum ab Level 22 ganz offen statt 21 |
| **ADR-0037**: der Wissensbaum als Endziel (Issue #54) | gebaut wird nach dem Test |

**Entfernt:** `tool/gear_icons_gen.dart` (hätte die Raven-Bilder
überschrieben) und fünf alte Waffenzeichnungen, die nirgends mehr
eingetragen waren.

**Neue Abhängigkeit:** `audioplayers` — nach dem Pull einmal
`flutter pub get`.

**Push aus der Claude-Sitzung geht jetzt**: mit `gh` als
Credential-Helper je Befehl, ohne die globale Git-Konfiguration zu ändern.

### Offen

- **Die Grube ist gemergt, aber nicht entschieden.** Sie bleibt im
  Entwicklermodus. Der ADR zur Richtung fehlt, und AktivesBrett hat sie
  noch nicht gespielt.
- **Quelle und Urheber** der drei Pakete (Raven, UI-Bundle, Kampf-Figuren)
  fehlen in den HERKUNFT-Dateien — die Lizenzen hat Frederik geprüft, für
  den anderen nachprüfbar sind sie so nicht.
- ~~**Nicht am Gerät angehört**: die Klänge. Nicht am Handy angesehen: der
  Holz-Stil — nur in der lokalen Vorschau im Browser und als Testbild.~~ ✓ *Am 24.09. am Handy gespielt.*
- **ADR-0037** hat fünf offene Punkte, darunter die Belohnung fürs
  Vertiefen und wer ~340 Seiten schreibt.

## Sitzung 21.09.2026: die Grube bekommt Figuren

Die Würfel sind Figuren geworden — aus Frederiks Download-Paket, Lizenz
von ihm geprüft (`assets/Grube/HERKUNFT.md`). 484 App-Tests.

| Wer | Bild | Bewegt sich |
|---|---|---|
| Held | Soldat | steht, läuft, zwei Schläge, zuckt, fällt |
| Fussvolk | Ork | dasselbe |
| Schütze | Blutauge | schwebt (ein Streifen) |
| Wächter | Zyklop, fünffach | schwebt (ein Streifen) |

**Die Simulation ist unberührt.** Pose und Blickrichtung entstehen im
Renderer aus dem, was die Welt ohnehin meldet — Bewegung, `AttackSwung`,
`HitLanded`, `EntityDied` (`lib/action/figure_state.dart`). Solange die
Bilder laden, stehen dort die alten Würfel; ein Lauf wartet nicht darauf.

**Die Richtung ist weiter nicht entschieden.** Frederik neigt zur Grube
als *dem* Kampf; die Gegnerbilder für die Reihe sind deshalb
zurückgestellt. Der ADR steht aus, und AktivesBrett hat noch nicht
gespielt.

**Nicht gebaut:** Boden und Wände sind weiter gezeichnet — das Paket hat
keine Kacheln. Die Geschosse des Auges sind Punkte, keine Bilder.

## Sitzung 20.09.2026, abends: ein Echtzeit-Prototyp und eine Lern-Vorlage

Nach dem Teststart. Zwei Dinge, die beide **keine Entscheidung** sind —
ein Prototyp und ein Entwurf. 471 App-Tests (vorher 461), das neue
Package 28.

### Der Befund, der beides ausgelöst hat

Die Frage war, ob sich der Kampf im Diablo-Stil besser anfühlen würde.
Die Simulation hat zuerst etwas anderes gezeigt: **Der schwächste Gegner
der Reihe braucht auch nach zwei Monaten noch sieben Runden.**

| Runden gegen den Wegelagerer | Tag 0 | Tag 14 | Tag 30 | Tag 60 |
|---|---|---|---|---|
| | 10,6 | 9,4 | 7,6 | **7,1** |

Über ein ganzes Spielerleben wird der erste Gegner um ein Drittel
schneller besiegt. Die Ursache ist nicht die Rundenbasiertheit, sondern
der **Werte-Deckel**: Der Angriff wächst von 13 auf 20, also um 54 %,
und ist nach etwa einem Monat am Ende (ADR-0008). Dazu stimmt ADR-0009
die Reihe bewusst so ab, dass jede Sprosse knapp bleibt — es gibt also
per Konstruktion nichts, das man hinter sich lässt.

**Daraus folgt: Kein Kampfsystem fühlt sich nach Diablo an, solange die
Macht additiv und gedeckelt wächst.** Echtzeit löst davon genau einen
Teil — dass zwanzig Gegner keine zwanzig Runden kosten.

### `packages/action_combat` — der Prototyp

Neuntes Package, reines Dart mit leerem `dependencies`-Block wie die
anderen acht. Es steht **neben** `package:combat`, nicht an seiner
Stelle; beide kennen einander nicht.

- **Fester Zeitschritt, gesäter Zufall, keine Wanduhr.** Damit bleibt ein
  ganzer Lauf ohne Renderer simulierbar — dieselbe Naht wie ADR-0002,
  und der Grund, warum es ein eigenes Package ist
- **Die Halle ist eine Textkarte** (`# . @ e B`), 46 × 34, vier Räume,
  26 Fussvolk und ein Wächter. `Level.problems` prüft sie wie
  `TheoryGraph.isHealthy`: geschlossen, genau ein Endgegner, **jeder
  Gegner vom Start aus erreichbar**
- **Wegfindung über ein Flutfeld** vom Helden aus — eine Flutfüllung für
  alle statt einer Suche je Gegner
- **Darstellung mit Flame, ohne Komponentenbaum**: Würfel,
  Schachbrettboden, Lebensbalken, aufsteigende Schadenszahlen.
  Steuerkreuz oder WASD, geschlagen wird von selbst
- Erreichbar **nur über den Entwicklermodus**, also nur im Debug-Bau

`dart run example/headless_run.dart`:

| Stufe | ATK | Ausgang | Dauer | je Gegner | HP übrig |
|---|---|---|---|---|---|
| Tag 0 | 13 | gefallen | 32 s | 2,5 s | 0 % |
| Decke heute | 30 | geschafft | 58 s | 2,2 s | 82 % |
| mit Potenz | 30 | geschafft | 48 s | 1,8 s | 96 % |

**„Mit Potenz" gibt es im Spiel nicht** — dieselben Werte, aber Schaden
mal drei und kritische Treffer. Der Knopf existiert, damit sich der
Unterschied **spüren** lässt statt nur ausrechnen.

Und die Zahlen sagen schon etwas: „je Gegner" bewegt sich kaum, weil der
Bot die meiste Zeit **läuft**. Der Machtzuwachs zeigt sich hier als
Überleben, nicht als Tempo.

### Zwei Dinge, die der kopflose Lauf gefunden hat

**Ohne Wegfindung kam der Bot über zwei Gegner nicht hinaus** — alles
blieb an der ersten Ecke stehen. Im Browser hätte man das als „fühlt
sich komisch an" abgetan.

**Der Nachhol-Deckel war zu niedrig.** Bei fünf Schritten verlor ein Bild
von 100 ms jedes Mal einen Schritt, und die Welt lief dauerhaft langsamer
als die Uhr. Der allererste Test des Packages hat genau das gemeldet.

### Nachgelegt: Knöpfe, Bogenschützen, Heilkugeln

Nach dem ersten Spielen ausgebaut — aus Laufen-und-Draufhalten wird ein
Kampf. 472 App-Tests, action_combat 47 (vorher 28).

| | Was |
|---|---|
| **Sturmschritt** | Ein Satz nach vorn, viermal Tempo, **kein Schaden** — er ist der Ausweg, nicht der zweite Angriff |
| **Rundumschlag** | ×1,5 auf alles im Umkreis, 5 Sekunden Abklingzeit |
| **Fünf Fernkämpfer** | Bleiben auf Abstand, weichen zurück, schiessen — Geschosse bleiben an Wänden hängen |
| **Heilkugeln** | 28 % Quote, 8 % der vollen Gesundheit, fliegen aus 64 Punkten zu |

Dazu Rückstoss auf Treffer (nicht auf den Helden, nicht auf den
Wächter), Trefferblitz, ein Ring bei Tod und Rundumschlag.

**Ein Fehler, den der erste Testlauf gefunden hat:** Der Fernkämpfer
schoss weiter, als er sah — 230 Reichweite gegen 210
Aufmerksamkeitsradius. Er stand da und liess sich beschiessen. Jeder
Gegner bemerkt jetzt spätestens auf seiner eigenen Reichweite.

| Stufe | Ausgang | Dauer | je Gegner | Kugeln | HP übrig |
|---|---|---|---|---|---|
| Tag 0 | gefallen | 32 s | 2,0 s | 3 | 0 % |
| Decke heute | geschafft | 71 s | 2,6 s | 5 | 57 % |
| **mit Potenz** | geschafft | 53 s | 2,0 s | 7 | **89 %** |

**Die Schützen haben die Halle deutlich härter gemacht** — „Decke heute"
kam vorher mit 82 % durch. Erwartbar: Der Bot weicht keinem Pfeil aus.

**Drei Zahlen sind geraten, nicht gemessen:** fünf Sekunden Abklingzeit
auf den Rundumschlag (bei drei wird er die Dauerlösung), fünf
Fernkämpfer, und die Position der Knöpfe unten rechts.


Beide Fassungen sind gespielt und für gut befunden — von **einem** von
zwei Entwicklern. Damit ist die Frage „fühlt sich das besser an"
beantwortet und die Frage „wird das Projekt das" offen. Zwei Dinge sind
jetzt entscheidbar und keines davon entschieden:

- **Die Potenz-Kurve.** „Mit Potenz" ist die Stufe, die sich am besten
  spielt, und die es im Spiel nicht gibt. Soll Macht vervielfachen statt
  zu addieren? Das berührt ADR-0008 und die vier Kurven.
- **Die Richtung.** Wird der Echtzeit-Kampf *der* Kampf, oder bleibt er
  ein zweiter Modus neben der Gegnerreihe? Davon hängt ab, was mit
  `packages/combat` und den dreissig Sprossen passiert.

Beides gehört in einen ADR, bevor weitergebaut wird — sonst entsteht
nebenbei eine Entscheidung, die niemand getroffen hat.

### `docs/vorlagen/lernen.md` — eigener Branch

> Liegt auf `docs/vorlage-lernen` und hängt an nichts von hier. Sie
> gehört zu dieser Sitzung, nicht zu diesem Prototyp.


Eine Konzeptrunde zum Lernen, nichts davon gebaut. Der Befund in einem
Satz: **Eine App über Wiederholung lehrt ohne Wiederholung** — eine
Lektion wird einmal gelesen, einmal abgefragt und nie wieder angesehen.

Fünf Vorschläge, nach Kosten sortiert; zwei davon sind fast nur
Verdrahtung („Wann machst du das?" am Lektionsende, Optionen erst nach
dem Nachdenken). Die **Rückfrage des Tages** braucht einen ADR: Sie
brächte zum ersten Mal wiederholbare Erfahrung ins Spiel — genau die
Grenze, die ADR-0032 beim Kampf gezogen hat.

Ausdrücklich **nicht** vorgeschlagen: mehr Belohnung aufs Lernen. Was
fehlt, ist sichtbare **Kompetenz**, nicht sichtbarer Ertrag.

### Offen

- **Gespielt hat ihn nur einer von zwei.** Beide Fassungen sind für gut
  befunden — von Frederik. Eine Richtungsänderung am Kampf, die einer
  allein gut findet, ist keine Entscheidung, sondern eine Vorliebe.
- **Kein ADR zum Echtzeit-Kampf.** Fällt die Antwort am Ende nein aus,
  ist es ein `git revert` von drei Commits.
- **Nichts ist gepusht.** Drei Branches liegen lokal; für AktivesBrett
  existiert bis dahin nichts davon — derselbe Fall wie
  `Kampfsystem.docx`.
- **Die Potenz-Kurve ist die eigentliche Frage** und in keiner der beiden
  Vorlagen entschieden: Soll Macht vervielfachen statt zu addieren — und
  wird der Kampf damit zur Quelle von Macht statt zu ihrer Auszahlung
  (`konzept.md` Abschnitt 2)?
- Drei Feedback-Issues stehen noch: **#47 Fähigkeiten, #48 Kampf,
  #49 Shop**.

## Sitzung 20.09.2026: das Abhaken zahlt sichtbar aus

Issue [#46](https://github.com/Prozesstek/LifesGame/issues/46) („Feedback
Gewohnheiten") gebaut — drei von vier Punkten vollständig, der vierte als
Gegenstand ohne Quelle. 461 App-Tests (vorher 449), habits 161 (vorher
130).

Es ist das erste von **vier** Feedback-Issues vom 20.09. (#46
Gewohnheiten, #47 Fähigkeiten, #48 Kampf, #49 Shop). Sie sind kein
MVP-Schnitt mehr, sondern Material für den Testlauf.

### Was die Kachel jetzt sagt

Bis heute stand auf einer Gewohnheits-Kachel der Multiplikator („3 ·
x1,2") und sonst nichts über den Ertrag. Richtig, aber ohne Maßstab: Was
x1,2 in Erfahrung bedeutet, stand nirgends.

Jetzt steht unter jedem Namen eine Zeile mit zwei Zahlen — **vor** dem
Tippen, was es bringt, danach, was es gebracht hat („Heute +18 · +5").
Gerechnet wird das in `HabitTracker.xpForNextCheck`, nicht im Bildschirm;
die Kachel bekommt fertige Zahlen.

Dazu poppt der Kreis beim Abhaken auf, die Kachel bekommt einen grünen
Rand, und auf dem Handy gibt es einen kurzen Stoß. Die Rückmeldung unten
trägt jetzt ein Zeichen und drei Sekunden statt zwei.

### „Stats sofort erhöhen" — der Balken, nicht die Kurve

Ein Punkt Stärke kostet fünf Häkchen (`StatCurve`). Vier von fünf Malen
bewegte sich die Zahl über der Liste also nicht, und der Zusammenhang
zwischen Abhaken und Charakter war unsichtbar.

Jede Wertekachel hat jetzt einen Balken, der sich bei **jedem** Häkchen
bewegt, und wenn der Punkt fällt, sagt es die Leiste: „+15 Erfahrung ·
+5 Gold · +1 Stärke".

**Die Kurve selbst ist unangetastet.** Sie feiner zu machen ginge auch
gar nicht: Stärke hat über ein Spielerleben sieben Punkte zu vergeben,
und an dieser Spanne hängt die Balance-Simulation. Die Änderung ist
Anzeige, keine Zahl — `progression_test.dart` läuft unverändert.

### Die Beständigkeits-Leiter

Über der Tagesliste steht jetzt eine Karte mit allen fünf Meilensteinen:
erreichte in Gold, der nächste umrandet, dazu ein Satz mit echten Zahlen
— „Noch 3 Tage bis x1,2 — dann bringt jedes Häkchen 18 statt 15
Erfahrung. Gold bleibt gleich."

Dieselbe Regel wie bei den Hilfetexten im Kampf: Was sich ausrechnen
lässt, wird ausgerechnet. „20 % mehr" ist eine Behauptung, „18 statt 15"
eine Zahl.

Sie rechnet mit der **besten laufenden Kette** über alle Gewohnheiten.
Je Gewohnheit wäre genauer und stünde fünfmal untereinander.

### Das Streak-Eis — gebaut, Quelle offen

[ADR-0036](../decisions/0036-streak-eis-als-gegenstand.md). Ein
Gegenstand, kein Nachlass: Er deckt **einen Kalendertag für alle
Gewohnheiten**, die Kette läuft darüber hinweg und wird dabei **nicht
länger**. Eine Kette über dreißig Kalendertage mit einem Eis darin ist
neunundzwanzig lang.

| | |
|---|---|
| Wann sichtbar | nur, wenn gestern nichts steht und vorgestern eine Kette endet |
| Was es kostet | ein Eis; der Vorrat wird aus der Historie gerechnet, nicht gespeichert |
| Was es **nicht** gibt | Erfahrung, Gold, Charakterwerte — die hängen weiter nur an Häkchen |
| Wie viele es gibt | **eines**, über das ganze Spiel — die offene Zahl |

**Woher die Eis kommen, ist bewusst nicht entschieden** („mach den
Gegenstand, die Quelle überlegen wir dann"). Sie steht als eine Zahl da,
`StreakFreeze.lifetimeStock`. Eine echte Quelle — Laden, Errungenschaft,
Meilenstein — ändert vier Kurven und gehört in eine eigene Runde.

**Eine Regel steht an genau einer Stelle:** Ob eine Kette über eine Lücke
läuft, beantwortet `HabitTracker._continues`. `streakEndingAt`,
`longestStreak` und `totalXp` fragen alle dort — stünde sie dreimal da,
zeigte die Kachel irgendwann eine andere Kette an, als die Erfahrung
unterstellt.

Die Errungenschaften bleiben monoton (ADR-0033): Ein Eis kann den
Bestwert nur heben. Und die, die auf Aktivität zählen, sehen es gar
nicht — „Der Unbeugsame" ist mit Eis nicht zu kaufen.

### Ein Layout-Fehler, der seit dem 12.08. im Code lag

`phone_layout_test.dart` baute seinen Stand mit allem — nur abgehakt war
nie etwas. Damit war der Zugewinn auf jedem Charakterwert null, die
zweite Zahl in der Wertekachel (`if (bonus > 0)`) wurde nie gebaut, und
was nicht gebaut wird, kann nicht überlaufen.

Sobald der Stand zwei Tage Häkchen bekam, lief sie über: `224` neben
`+64` in einem Viertel der Bildschirmbreite, 18 Pixel zu viel. Es ist
der dritte Fall derselben Sorte (`LevelCard`, `HubTile`, jetzt
`_StatCell`) und steht in `gotchas.md` — samt der allgemeineren Lehre:
Eine Testvorlage muss jeden bedingten Zweig der Oberfläche einmal
auslösen.

### Nicht am Bild geprüft

Wie immer bei Oberflächenarbeit: 461 Tests laufen, alle Layouts bei
390 × 844 ohne Überlauf, Analyzer sauber. Wie es **aussieht**, muss
jemand ansehen:

- Ob die Ertragszeile auf fünf Kacheln untereinander als Information
  liest oder als Lärm — die Untertexte sind aus genau diesem Grund
  einmal geflogen (Issue #35).
- Ob die Leiter mit fünf Sprossen auf 390 Pixeln noch lesbar ist.
- Ob die Streak-Eis-Karte am richtigen Tag auftaucht. Sie erscheint nur
  bei einer echten Lücke, und die entsteht im Test nur künstlich.

### Offen

- **Drei Feedback-Issues stehen noch**: #47 Fähigkeiten, #48 Kampf, #49
  Shop.
- **Die Quelle der Streak-Eis.** Bis dahin ist das Eis nach einmaligem
  Gebrauch weg — das ist im 30-Tage-Lauf sichtbar und genau die
  Rückmeldung, die die Entscheidung braucht.
- **Die Balance ist nicht neu gerechnet.** Es gibt keine neue Zahl, die
  sie berührt: Das Eis erzeugt nichts, die Stat-Kurve ist unverändert.

## Sitzung 14.09.2026, abends: nach dem Sieg zurück, ein Punkt je Level

Zwei kleine Änderungen, 449 App-Tests (vorher 447), progression 33.

### Nach einem Sieg geht es zurück zur Reihe

Das Ergebnisblatt bleibt, wie es war. Nach „OK" (und nach einer
Errungenschafts-Feier) schließt sich der Kampf, und die Reihe zeigt schon
den nächsten Gegner. Bis dahin stand man vor „Nochmal" — und das setzte
**denselben** Gegner neu auf, den man gerade geschlagen hatte, gegen den
ein zweiter Sieg nichts einbringt (ADR-0032).

**Eine Niederlage bleibt im Kampf.** Dort ist „Nochmal" der richtige
nächste Schritt. `test/combat_exit_test.dart` prüft beide Fälle und geht
den ganzen Weg: Zug, Leiste, Blatt, Feier, zurück.

### Ein Theoriepunkt je Level statt zwei

[ADR-0035](../decisions/0035-ein-theoriepunkt-je-level.md), löst Punkt 3
von ADR-0019 ab. 49 Punkte über ein Spielerleben statt 98, der Startbaum
steht ab Level 21 offen statt ab Level 11. Der Weg zum ersten Kampf bleibt
frei: Auf Level 3 gibt es zwei Punkte, ein Knoten mit Fähigkeit kostet
einen (`abilities_seam_test.dart`).

**Die Balance ist nicht neu gerechnet.** `tool/balance_sim.dart` gibt dem
simulierten Spieler jetzt halb so viele Fähigkeiten aus dem Baum; die
Tabellen weiter unten stammen noch aus der alten Rechnung.

### Ein roter Test hat die Web-App blockiert — behoben

`character_test.dart` → „das Auswahlblatt zeigt Bild und Set jedes
Stücks" war seit dem Merge von #45 rot, und weil `pages.yml` erst testet
und dann baut, ist **seit #44 keine Web-Fassung mehr veröffentlicht
worden**.

Ursache: #45 entstand vor #44. Sein Aufbau `mitBeidenWaffen()` kaufte
„alle Waffen" ohne `highestRung` — seit ADR-0034 greift dann die Sperre,
und die drei verdienten Waffen fehlten still. Genau der Fall, vor dem
`CLAUDE.md` bei `GearGates` warnt. Jeder PR war für sich grün; rot wurde
erst der gemergte Stand.

## Sitzung 14.09.2026: Episch und Legendär — verdient, nicht gekauft

Der Wunsch war „zwei Epics und ein Legendary je Ausrüstung". Gebaut sind
**achtzehn Stücke, zwei neue Stufen und eine Sperre**
([ADR-0034](../decisions/0034-episch-und-legendaer-haengen-an-der-gegnerreihe.md)).
445 App-Tests (vorher 437), gear 88 (vorher 77), combat 130.

### Was gebaut ist

- **48 Stücke statt 27.** Acht je Platz: fünf offene (2 · 2 · 1, ADR-0029)
  und drei verdiente (2 · 1). Ein Reiter trägt acht Kacheln in drei Reihen
- **Zwei Stufen, die an der Gegnerreihe hängen:** Episch ab Sprosse 10,
  Legendär ab Sprosse 20 (`GearGates`). Gesperrte Stücke stehen sichtbar
  im Laden, mit Preis; die Kachel sagt „gesperrt", die Detailfläche nennt
  die Sprosse
- **Drei neue Waffenzüge** in `package:combat`: Spalter (1,6 / +1),
  Doppelschuss (0,45 × 2 / +4), Sonnenhieb (1,4 / +3, Perfect entzündet).
  Jeder ein Rhythmus, den es unter den fünf ersten nicht gab
- **Lila und Gold** als Marke — die Konvention, die niemand erklären muss

### Drei Entscheidungen, die begründet gehören

**Verdient statt teurer.** `GearRarity` hatte ausdrücklich drei Stufen,
„weil es im Laden nichts zu erreichen gibt". Seit der Gegnerreihe gibt es
das. Der andere Weg — Legendär für 4000 Gold — hätte im 30-Tage-Lauf
niemand gesehen, das wären 160 Tage Gewohnheiten.

**Sprosse 20, nicht 30.** Die dreißigste ist der letzte Gegner; wer dort
freischaltet, hat nichts mehr, wogegen er es trägt. Ab 20 bleiben zehn.

**Die Sperre vor dem Gold.** Ein gesperrtes Stück sagt „verdient ab Gegner
10", nicht „zu teuer" — sonst spart jemand auf einen Knopf, der danach
immer noch aus ist.

### Was die Simulation dazu sagt

Der Waffenvergleich läuft jetzt über alle dreißig Gegner. Tag 30, drei
Sprossen als Ausschnitt:

| Waffe | Sprosse 20 | Sprosse 23 | Sprosse 25 |
|---|---|---|---|
| Übungsklinge | 96 % | 24 % | 5 % |
| **Zweihänder** (Episch) | 100 % | **91 %** | **61 %** |
| **Sonnenklinge** (Legendär) | 100 % | 87 % | 59 % |

**Die Sonnenklinge liegt knapp unter dem Zweihänder, und das ist die
Simulation, nicht das Spiel.** Der Bot trifft zur Hälfte perfekt, der Brand
zündet also nur jede zweite Runde. Ein Mensch, der die Leiste trifft, hat
den härteren Zug *und* Dauerschaden. Die erste Fassung mit Power 1,2 lag
bei 63 % — deutlich unter dem Episch — und ist deshalb auf 1,4 gehoben.

**Was auffällt:** Ein Spieler an Tag 30 mit Übungsklinge kommt bis Sprosse
22, mit Zweihänder bis 26. Die verdienten Waffen verschieben die Grenze um
etwa vier Sprossen — das ist die Größenordnung, die eine Sperre
rechtfertigt, ohne die Reihe zu entwerten.

### Beim Bauen gemeldet

`Loadout.buy` hat einen dritten Parameter, `highestRung`, mit
Standardwert 0. **Das ist die sichere Richtung** (`gotchas.md`, Eintrag
zum Standardwert): Wer ihn vergisst, bekommt eine Sperre, keinen Bypass.
Drei Tests, die den ganzen Katalog kaufen, haben es sofort gemeldet —
`ever_owned_test` zählte plötzlich zwölf statt fünfzehn Stücke.

### Offen

- ~~**Keine Bilder**~~ — **nachgeliefert am selben Tag.** Alle achtzehn
  haben eins, **erzeugt statt gemalt**: `tool/gear_icons_gen.dart`
  zeichnet sie aus Rechtecken, Scheiben und Linien auf 32 × 32 mit einer
  dunklen Kontur, bewusst gröber als Frederiks 64er („ganz simpel").
  Wer eines ändern will, ändert die Form im Werkzeug, nicht ein PNG.
  Dabei ist ein Test gefallen, der „größer als 1000 Bytes" prüfte —
  flache Flächen komprimieren darunter. Er prüft jetzt Signatur und
  Kantenlänge, was er hätte von Anfang an tun sollen.
- **Ob 10 und 20 richtig liegen**, sagt der 30-Tage-Lauf.
- **Nicht am Bild geprüft.** „Krone des Hochwächters" ist jetzt der
  längste Name im Laden; der Layout-Test läuft bei 390 × 844 ohne Überlauf.

## Sitzung 12.09.2026: Errungenschaften sind gebaut

**Ziel 8 ist erfüllt**, acht Tage vor dem Termin — und ohne Schnitt: Die
Entdeckungen sind mit drin. Damit sind alle sieben Bauziele erreicht, und
vor dem 30-Tage-Lauf steht nichts mehr offen.

435 App-Tests (vorher 407), combat 130 (115), theory 143 (129), habits 130
(114), gear 77 (64), identity 25 (28 — die alten prüften Bedingungen, die
es dort nicht mehr gibt), achievements 24 (neu).

### Das achte Package

`packages/achievements`, reines Dart mit leerem `dependencies`-Block wie
die anderen sieben. Es kennt keines von ihnen; die App reicht Zahlen
herein (`AchievementStats`), genau wie bei `TitleStats` und
`AbilityProgress`.

**19 Meilensteine und 8 Entdeckungen**, die Zahlen aus ADR-0033 stimmen
auf den Punkt: 1680 Erfahrung, 560 Gold, 385 Ruhm über ein Spielerleben.
Das steht jetzt nicht mehr nur im ADR, sondern als Test im Katalog — wer
eine Stufe verschiebt, sieht dort, dass der ADR nachzuziehen ist.

**Eine Bedingung ist eine Messung, kein Schalter.** Jeder Eintrag nennt
eine Zahl aus dem Stand und einen Zielwert. Der Fortschritt („37 / 50")
fällt damit von selbst ab; eine Bedingung, die nur `true` oder `false`
kennt, könnte einen Meilenstein nicht anzeigen, ohne die Regel ein
zweites Mal zu formulieren.

### Was sich am Bestehenden geändert hat

| Vorher | Jetzt |
|---|---|
| `CharacterTitle` trug seine Schwellen, `TitleStats` reichte drei Zahlen | `identity` hält nur noch **Wortlaut**, die Bedingung steht in `achievements` |
| 7 Titel | **13** — sechs neue aus Entdeckungen |
| `AbilitySource` hatte drei Fälle | vier, mit `FromAchievement` |
| 15 wählbare Fähigkeiten | **19** — Kraftschlag, Zehrung, Sammeln und Atemzug sind zurück |
| `LadderProgress` hielt nur den höchsten Sieg | dazu **Niederlagen je Sprosse** |
| `LessonRecord` hielt nur das beste Ergebnis | dazu **gescheiterte Versuche** |

**Der `sealed`-Typ hat sich ausgezahlt.** `FromAchievement` dazuzunehmen
hat den Analyzer sofort auf die eine Stelle gezeigt, die alle Quellen
aufzählt (`ability_unlock_sheet.dart`). Ohne `sealed` hätte dort still
„Aus der Theorie" gestanden.

### Vier Entscheidungen, die im ADR offen waren

**Die Seltenheit der vier Rückkehrer** steht jetzt, nach dem, was ein Zug
tut: Kraftschlag `rare` (mit `power` 2,2 der härteste Einzelschlag im
Spiel), Zehrung und Sammeln `uncommon` (Werkzeuge wie die übrigen),
Atemzug `common` (er *erzeugt* Energie, statt sie zu kosten).

**Die Schwellen der Bedingungen liegen in `lib/achievements/`**
(`AchievementThresholds`), nicht in den Packages, die sie beantworten.
„Drei Niederlagen" ist keine Kampfregel und „drei Tage Pause" keine
Streak-Regel — `combat` und `habits` liefern nur die Frage, die Zahl
kommt von der Errungenschaft.

**Der Stoiker rechnet über alle Gewohnheiten zusammen**, nicht je
einzelne. Die Frage dahinter ist „hat jemand aufgehört und wieder
angefangen", und aufgehört hat man, wenn gar nichts mehr kommt — nicht,
wenn eine von fünf Ketten reißt.

**Gefeiert wird an vier Stellen**: Lektion, Häkchen, Kampfende, Kauf und
Verkauf. Immer **Errungenschaft zuerst, Fähigkeit danach** — eine
Errungenschaft kann eine Fähigkeit mitbringen, und andersherum stünde die
Fähigkeit da, bevor gesagt wäre, woher sie kommt.

### Der Fehler, der dabei aufgefallen ist

**Eine bestandene Seite schloss den halben Baum wieder.**
`TheoryProgress.submit` gab den zweiten Konstruktorparameter
(`_openedNodeIds`) nicht weiter; weil er einen Standardwert hat, schwieg
der Compiler. Wirkung im Spiel: Wer einen Knoten für einen Theoriepunkt
öffnete und dann seine Seite bestand, bei dem ging der Knoten wieder zu.

Es ist **zeichengleich** der Fallstrick, der seit dem 25.08. in
`gotchas.md` steht — damals `CombatSession.moves`. Der Eintrag dort hat
einen Nachtrag bekommen. Fünf Tests in
`packages/theory/test/achievement_traces_test.dart` halten es jetzt fest.

Der Fehler lag seit ADR-0019 (24.08.) im Code. Gefunden hat ihn kein
Test, sondern das Nachlesen beim Anschließen der Errungenschaften.

### Ein Zirkelbezug, der beinahe entstanden wäre

Errungenschaften im Laden zahlen Gold, und ob sie verdient sind, hängt am
Inventar — `goldProvider` zeigt damit über die Errungenschaften wieder
auf `loadoutProvider`. Der `GearController` darf ihn beim Kauf deshalb
nicht mehr lesen; das ist genau der `CircularDependencyError` aus
`gotchas.md`, den `spendableIncomeProvider` schon einmal aufgelöst hat.

Gelöst wie damals: Der Controller bringt seinen eigenen Beitrag selbst
mit (`incomeWithoutAchievementsProvider` plus
`achievementStatsWithLoadout(ref, state)`). Ein Test in
`achievements_seam_test.dart` geht den Kaufweg und fiele ohne die
Auflösung um.

### Zwei Tests, die das Gegenteil dessen bewiesen, was sie meinten

`chosen_abilities_test.dart` und `persistence_test.dart` benutzten
`heavy_attack` als Beispiel für „eine Id, die es nicht mehr gibt". Mit
ADR-0033 gibt es ihn wieder — die Tests waren grün und wertlos. Beide
nehmen jetzt eine erfundene Id. **Das ist der zweite Eintrag aus
`gotchas.md`, der sich in dieser Sitzung wiederholt hat**, und er stand
dort seit dem 26.08. genau für diesen Fall.

### Was der erste Kauf jetzt kostet

Er zieht nicht mehr nur ab: „Erster Kauf" zahlt 10 Gold zurück. Über ein
Spielerleben sind es 85 Gold aus den vier Laden-Errungenschaften. Das ist
gewollt und in `progression_test.dart` sowie `gear_test.dart` als eigener
Summand sichtbar, statt die Zahlen stillschweigend größer zu machen.

### Nicht am Bild geprüft

Wie immer bei Oberflächenarbeit: 435 Tests laufen, alle Layouts bei
390 × 844 ohne Überlauf, Analyzer sauber. Wie es **aussieht**, muss
jemand ansehen:

- Ob die ???-Einträge als „da ist noch etwas" lesen oder als kaputt.
- Ob das Feierblatt nach einem Kauf im Laden stört — es kommt jetzt über
  den Laden, und beim ersten Kauf immer.
- Ob „Ruhm" neben dem Gold im Kopf des Charakters als Zahl zum
  Vergleichen liest und nicht als zweite Währung.

### Drei Dateien nachgezogen

Sie lagen seit Tagen im Arbeitsverzeichnis und hatten mit Ziel 8 nichts
zu tun; eingecheckt sind sie trotzdem, damit der Baum sauber ist:

| Datei | Was |
|---|---|
| `assets/character/hero.png` | gelöscht — seit dem 10.09. von `Charakter.png` abgelöst und nirgends gelesen |
| `assets/Gold.pxo` | gelöscht — **die einzige `.pxo` im Repo**, also die einzige Bearbeitungsdatei. `Gold.png` bleibt |
| `Logo.png` | neu im Wurzelordner, 1,1 MB, **nirgends eingebaut** |

**Zwei Vorbehalte, die bestehen bleiben.** Mit `Gold.pxo` ist die
Pixelorama-Quelle der Goldmünze aus dem Baum verschwunden — die
Zeichnung bleibt, das Bearbeitbare nicht (zurückholen geht über die
Historie). Und `Logo.png` ist angemeldet, ohne dass irgendwo entschieden
wäre, wofür es steht: App-Symbole stehen in `ziele.md` auf der
Sperrliste.

### Offen

**Die Balance ist nicht neu gerechnet worden.** `tool/balance_sim.dart`
läuft unverändert durch, kennt die Errungenschaften aber nicht: Ihr
simulierter Spieler bekommt weder die 1680 Erfahrung noch Kraftschlag.
Die Tabelle ist damit weiter eine untere Schranke.

**Kraftschlag ist mit `power` 2,2 stärker als die frühen Commons.** Er
kommt erst auf Sprosse 10, wenn der Charakter ohnehin trägt — aber
ADR-0033 nennt das selbst als unangenehmen Punkt, und er bleibt es.

## Sitzung 11.09.2026, nachmittags: Errungenschaften entschieden, nicht gebaut

Issue [#41](https://github.com/Prozesstek/LifesGame/issues/41) als
Konzeptrunde durchgegangen, Ergebnis in
[ADR-0033](../decisions/0033-errungenschaften-aus-der-historie.md) und als
**Ziel 8** mit Termin 20.09. in `ziele.md`. Die Entscheidungen stehen
zusätzlich als Kommentar im Issue. Keine Zeile Code.

### Was entschieden ist

- **Aus der Historie abgeleitet**, nicht gezählt. Wirkt rückwirkend, und
  jede Bedingung hängt an einer Größe, die nie fällt.
- **Zwei Arten:** Meilensteine sind sichtbar und zahlen einmalig
  Erfahrung, Gold und Ruhm; Entdeckungen stehen als ??? da und zahlen nur
  Ruhm und meist einen Titel.
- **Ruhm** ist ein Stand zum Vergleichen, kein Zahlungsmittel.
- **Die sieben Titel werden Belohnung**, sechs neue kommen dazu.
  ADR-0014 ist damit teilweise abgelöst.
- **Kraftschlag, Zehrung, Sammeln, Atemzug kommen zurück**, je über einen
  Meilenstein.
- **Zwei neue Spuren:** Niederlagen je Sprosse, gescheiterte Versuche je
  Lektion.
- **Sortiert nach Spielbereichen**, erreichbar vom Charakter aus.
- Erster Satz: **19 Meilensteine, 8 Entdeckungen**, 1680 Erfahrung und
  560 Gold über ein Spielerleben.

### Drei Befunde aus dem Abgleich

**Viele Beispiele aus dem Issue brauchen Daten, die es nicht gibt.** Ein
Häkchen kennt keine Uhrzeit, Lektion und Reihe halten keine Fehlschläge,
Bedienung wird nicht festgehalten. Frühaufsteher, Opportunist, „Shop
geöffnet" und Mentor sind deshalb nicht im ersten Satz.

**„Alles erledigt" ist rückwirkend nicht bestimmbar.**
`HabitTracker.isDayComplete` vergleicht mit der *heutigen* Liste
laufender Gewohnheiten. Die Bedingungen heißen deshalb „mindestens drei
Häkchen".

**ADR-0024 hatte das Zurückholen der vier alten Fähigkeiten ausdrücklich
verworfen.** Aufgefallen ist das erst beim Aufschreiben, nach der
Entscheidung. Die drei Einwände von dort sind in ADR-0033 einzeln
beantwortet; ADR-0024 hat einen Vermerk im Status.

### Nebenwirkung

Die Namen der Entdeckungen stehen im ADR und im Issue — für uns zwei als
Tester sind sie damit keine Überraschung mehr. Ihre Bedingungen stehen
nur im ADR.

### Als Nächstes

~~Bauen in dieser Reihenfolge: `packages/achievements` mit Katalog und
Tests → die zwei Spuren → Titel und Fähigkeiten umhängen → Belohnung in
den Kurven → Bildschirm und Feier.~~ — **erledigt am 12.09.**, in genau
dieser Reihenfolge. Der Bildschirm ist ohne vorherige Abstimmung
entstanden; er folgt dem Laden (vier Reiter, Liste darunter).

## Sitzung 11.09.2026: die App übersteht Mitternacht

**Ziel 4 ist erfüllt**, fünf Tage nach Termin. 407 App-Tests (vorher 401).

`todayProvider` las die Uhr einmal und behielt den Tag. Wer die App über
Mitternacht offen ließ, hakte auf dem gestrigen Tag ab — im 30-Tage-Lauf
passiert das garantiert, und eine grundlos gerissene Streak ist der
schlimmste Fehler, den dieses Spiel kennt (`konzept.md` 3.7).

### Was gebaut ist

- **`clockProvider`** in `habits_controller.dart`: die Uhr als Provider.
  Nur so kann ein Test sie über Mitternacht schieben — `tester.pump`
  spult Timer vor, nicht das Datum. Die vielen
  `todayProvider.overrideWithValue` in den Tests gelten unverändert.
- **`lib/habits/day_watcher.dart`**: hängt in `main.dart` direkt unter dem
  `SaveWatcher` und sieht auf die Uhr — genau um Mitternacht, sonst jede
  Minute, und sofort, wenn die App wieder in den Vordergrund kommt.
  Neu gerechnet wird nur, wenn wirklich ein anderer Tag anbricht.
- **`test/day_watcher_test.dart`**, sechs Tests. Der wichtigste geht den
  ganzen Weg: gestern abgehakt, Uhr über Mitternacht, die Kachel ist
  wieder leer, ein Tipp landet auf dem neuen Tag, die Streak steht auf 2.

### Zwei Entscheidungen

**Ein Widget, kein Timer im Provider.** Ein Timer im Provider lebt so
lange wie der Container — und `habits_test.dart`, `theory_test.dart` und
`ability_unlock_test.dart` entsorgen ihren Container erst im `tearDown`.
Der Timer wäre dort noch offen, wenn Flutter nach dem Test auf offene
Timer prüft. Ein Widget endet mit dem Baum. Der Preis ist derselbe wie
beim `SaveWatcher`: Es muss in `main.dart` hängen, sonst tut es nichts.

**Jede Minute, nicht nur ein Wecker auf Mitternacht.** Ein einzelner
Wecker verpasst zwei Fälle: Ein schlafendes Handy lässt Timer nicht
verlässlich weiterlaufen, und wer Zeitzone oder Uhr umstellt, verschiebt
Mitternacht, nachdem der Wecker gestellt war. Ein Blick auf die Uhr je
Minute kostet nichts, und die Oberfläche baut dabei nur neu, wenn sich
der Tag tatsächlich geändert hat.

### Nicht auf einem Gerät geprüft

Tests und Analyzer sind grün. Ob ein Android-Handy nach einer Nacht im
Hintergrund beim Aufwecken wirklich „zurück im Vordergrund" meldet,
zeigt erst das APK. Tut es das nicht, stimmt der Tag spätestens eine
Minute später — ein Häkchen in genau dieser Minute landete dann noch auf
dem alten.

## Sitzung 10.09.2026: acht Fähigkeiten, zwei Waffen und die Figur

Elf neue Zeichnungen, alle im 64 × 64-Stil. Alle elf sind eingebaut.
401 App-Tests (vorher 399).

| Zeichnung | Wo sie steht |
|---|---|
| `Faehigkeiten/` — Funkenstoß, Steinhaut, Wurzelgriff, Aurastrom, Blütentau, Klingenwirbel, Frostnebel, Prisma-Barriere | Kampfkachel, Fähigkeitsplatz auf dem Charakter, Auswahlblatt |
| `Waffen/Boegen/Kurzbogen.png` | Kurzbogen, im Laden und am Platz |
| `Waffen/Staebe/Kampfstab.png` | Kriegsstab, ebenso |
| `character/Charakter.png` | die Figur auf dem Startbildschirm |

**Die acht Fähigkeiten sind genau Nummer 1 bis 8 der Vorlage**, also
alle Commons und Uncommons. Vier kamen als „Untitled" an; zugeordnet
sind sie über das Motiv **und** die Uhrzeit im Dateinamen, die der
Reihenfolge der Vorlage folgt.

### `MoveIcons` hält jetzt Pfade

Dieselbe Umstellung wie am 09.09. bei `GearIcons`: Die Datei musste
heißen wie die Move-Id, gezeichnet wird aber „Funkenstoß" und nicht
`funkenstoss`. Die Tabelle entscheidet, der Dateiname nicht.

Auf der Kampfkachel geht das Bild jetzt über `PixelArt` statt über
`Image.asset` mit fester Glättung. Der alte Kommentar dort sprach noch
von Bildern in dreifacher Kachelgröße, die gibt es seit dem 64er-Format
nicht mehr.

### Drei Entscheidungen ohne Rückfrage

- **Die Grundfigur ersetzt `hero.png`**, obwohl sie noch keine Kleidung
  trägt. Sie ist die erste Figur im Stil des Rests; `hero.png` war
  1024 × 1536 und passte nicht dazu. ~~Die alte Datei liegt weiter unter
  `assets/character/`~~ — **am 12.09. gelöscht**; zurückholen geht über
  die Git-Historie. Der Schalter dafür ist weiterhin eine Zeile
  (`CharacterStage.assetPath`).
- **Der „Kampfstab" ist der Kriegsstab**, obwohl er als Speer mit
  Eisenspitze gezeichnet ist. Es ist der einzige Stab im Katalog.
- **Die Namenszeile über einer Bildkachel ist kein Knopf.** Getippt wird
  das Bild. Drei Kampftests tippten bisher auf den Namen und tun das
  jetzt auf die Kachel.

### Nicht am Bild geprüft

Tests und Analyzer sind grün, wie es aussieht, muss jemand ansehen:

- Ob die Energiemarke unten rechts auf der Kachel etwas Wichtiges
  verdeckt. Die Zeichnungen haben transparenten Rand, aber nicht überall
  gleich viel.
- Ob die unbekleidete Figur auf dem Startbildschirm als Absicht liest.
- Ob man im Kampf auf den Namen über der Kachel tippt und sich wundert,
  dass nichts passiert.

### Offen

- **Sieben Fähigkeiten ohne Bild**: Donnerkeil bis Sternenfall.
- **Der Streitkolben** ist die einzige Waffe ohne Zeichnung.
- `NormalesSchwert.png` und `RustedSword.png` stellen weiter nichts dar.
- `Icon.png` (App-Symbol-Entwurf) und `image.png` (Vorbild aus Issue #16)
  liegen im Wurzelordner und sind **bewusst nicht** eingebaut: App-Symbole
  stehen auf der Sperrliste in `ziele.md`, und das Vorbild ist ein
  fremder Screenshot.
- ~~`assets/Gold.pxo` ist im Arbeitsverzeichnis gelöscht — nicht in dieser
  Sitzung, und nicht mit eingecheckt.~~ — **am 12.09. eingecheckt.**

## Sitzung 09.09.2026: die ersten Zeichnungen sind drin

Sieben Bilder lagen unter `assets/` und waren nirgends angemeldet. Jetzt
sind sie im Spiel — soweit es dafür etwas gibt, das sie darstellen
können. Und die App hat danach ihre Farben von ihnen übernommen.
399 App-Tests (vorher 378).

| Zeichnung | Wo sie steht |
|---|---|
| `UI/ButtonBG.png` | die vier Bereichskreise des Startbildschirms |
| `UI/CharacterButton.png` | der fünfte, der Charakterkreis |
| `Items/Gold.png` | unter der Figur und im Kopf des Ladens |
| `Waffen/Schwerter/WoodenSword.png` | Übungsklinge, im Laden und am Platz |
| `Waffen/Schwerter/Katana.png` | Geschliffene Klinge, ebenso |
| `Waffen/Schwerter/NormalesSchwert.png` | **nirgends** — siehe unten |
| `Waffen/Schwerter/RustedSword.png` | **nirgends** |

**Zwei Klingen finden kein Stück.** Von den fünf Waffen des Katalogs sind
nur zwei Klingen; die drei anderen sind Bogen, Streitkolben und Stab. Ein
Schwertbild auf den Streitkolben zu legen hieße, im Laden etwas anderes
zu zeigen, als man kauft — und die Waffe ist seit dem 08.09. der Platz,
der Kämpfe entscheidet. Es fehlt also entweder ein Bild je Waffenart
oder ein sechstes und siebtes Klingen-Stück; Letzteres wäre eine
Katalogänderung und keine Zeichenarbeit.

### Die Ordner heißen nach der Zeichnung, nicht nach der Id

`GearIcons` hielt bisher Dateinamen und setzte `assets/gear/` davor —
die Datei musste heißen wie die Item-Id. Das geht nicht mehr: Gezeichnet
wird eine *Klinge*, eingesetzt wird sie als *Übungsklinge*, und beim
Malen gibt es die Id noch gar nicht. Die Tabelle hält deshalb jetzt
**Pfade**, und die Zeichnungen bleiben nach Art sortiert. Was welches
Stück darstellt, entscheidet weiterhin genau diese eine Tabelle.

### Der Fehler, den man nicht sieht, sondern rechnet

Alles Gezeichnete liegt auf 64 × 64, abgelegt als 256 × 256. Bei einer
Kampfkachel (88 Punkte) ist `FilterQuality.none` richtig. Bei der
Goldmünze mit 18 Punkten ist es **falsch**: 64 gezeichnete Bildpunkte auf
18 echten, hart skaliert fällt jeder dritte weg. Übrig bliebe keine
kleinere Münze, sondern eine zerfressene.

`move_icon.dart` benennt genau diesen Fall seit dem 27.08. als den
schlimmeren — er stand nur nirgends im Code. Jetzt steht er in
`lib/ui/pixel_art.dart` als eine Zeile: Ab [PixelArt.artSize] echten
Pixeln hart, darunter weich. `test/pixel_art_test.dart` hält die Grenze
fest.

**Nebenbei ist damit eine Dreifachnennung weg.** `artSize` und
`assetSize` standen wortgleich in `MoveIcons`, `GearIcons` und
`EnemyIcons`. Seit eine Entscheidung daran hängt, darf es sie nur noch
einmal geben.

**Und eine Zweifachnennung.** `EquipmentSlotTile._iconFor` war
zeichengleich mit `GearIcons.fallbackFor` — der Fall aus `gotchas.md`,
und er wäre still passiert: Laden und Charakterbildschirm hätten
dasselbe Stück verschieden gezeichnet.

### Und dann die ganze App in denselben Ton

Die gezeichnete Knopffläche lag als Fremdkörper auf einem blaugrauen
Dunkeldesign. Entschieden wurde die mittlere von drei Möglichkeiten:
**Pergamentflächen auf Leder.** Nicht dunkles Leder mit warmen Akzenten
(zu wenig), nicht alles hell (die Arena hat helle Figuren und hätte neu
gedacht werden müssen).

**Zwei Farben sind gemessen, nicht gewählt.** `Palette.surface` und
`Palette.text` stehen so in `ButtonBG.png` — die Zeichnung gibt den Ton
vor, statt sich einzufügen.

**Es gibt jetzt zwei Untergründe, und jede Bedeutung hat für beide einen
Wert.** Die Bildschirme legen Pergament auf Leder; die Arena ist selbst
dunkel, weil zwei helle Figuren darauf stehen. Was auf Pergament lesbar
ist, verschwindet auf Leder — deshalb `accent` **und** `accentOnDark`,
`gold` **und** `goldOnDark`.

| Untergrund | Fläche | Schrift |
|---|---|---|
| Pergament | `surface` `#E8C48C` | `text` `#372200`, `textDim`, `muted` |
| Leder | `background` `#17110A` | `textOnDark`, `textOnDarkDim` |

**Was das an Arbeit war:** 43 Stellen mit hartem `Colors.white` (28
wurden Tinte, 11 helles Off-White, 4 Pergament auf gefülltem Akzent) und
34 rohe Farbwerte, die in die Palette gewandert sind. Dazu das Theme:
`Brightness.light`, obwohl der Grund dunkel ist — die Helligkeit
entscheidet, welche Farbe ein `Text` **ohne** eigene Angabe bekommt, und
der steht fast immer auf Pergament.

**Drei Stellen sind bewusst anders:**

- **Die Arena ist kein Pergament**, sondern ein Blick in die Welt. Sie
  behält den dunklen Grund und bekommt einen Pergamentrahmen. Auf Beige
  wären die beiden hellen Kämpfer verschwunden.
- **Die Lektion ist ganz Pergament.** Ein Fließtext über die volle Höhe
  ist eine Buchseite und braucht keinen Rahmen, der ihn zur Karte macht.
- **Kampf, Baum und Handbuch behalten eine dunkle Kopfzeile**, weil sie
  dort in die Fläche übergeht statt darüber zu liegen.

**`lib/ui/on_dark.dart` ist die Antwort auf den unangenehmsten Fehler
dieser Art.** Ein `Text` ohne eigene Farbe wird jetzt Tinte — in der
Arena und auf der Baumfläche ist das genau falsch herum, und das Ergebnis
ist unsichtbarer Text: kein Absturz, keine Meldung, nichts im Log. `OnDark`
klammert einen ganzen Bereich ein, statt jeden Text einzeln zu färben und
beim nächsten den einen zu vergessen.

### Der Test, der die Sitzung zusammenfasst

`test/palette_test.dart` misst Kontraste nach WCAG — 4,5 für Schrift,
3,0 für Flächen. Er hat sofort vier zu schwache Werte gefunden
(`textDim`, `accent`, `success`, `gold` standen zwischen 3,25 und 4,32)
und zwei Seltenheitsfarben dazu.

Zwei seiner Prüfungen sehen wie Spitzfindigkeit aus und sind es nicht:
Ein Pergamentwert **darf nicht** als Schrift auf Leder taugen, und
umgekehrt. Genau diese Verwechslung erzeugt den Fehler — wer im Kampf
`Palette.text` nimmt statt `Palette.textOnDark`, schreibt mit Tinte auf
Leder.

### Nicht am Bild geprüft

Wie immer bei Oberflächenarbeit: 399 Tests laufen, alle Layouts bei
390 × 844 ohne Überlauf, `flutter build web` steht. Wie es **aussieht**,
muss jemand ansehen. Drei Punkte besonders:

- Ob ein gesperrter Kreis mit 45 % Deckkraft noch als gesperrt liest.
  Die alte Sperre färbte grau; eine Zeichnung lässt sich nicht umfärben,
  ohne sie zu ruinieren, also trägt das Schloss unten rechts die Aussage
  jetzt allein.
- Ob die Arena mit ihrem Pergamentrahmen als eingesetzt wirkt oder als
  Loch.
- Ob die gezeichneten Kämpfer und die Flame-Farben zum neuen Ton passen.
  Sie sind **nicht** angefasst worden: `fighter.dart`,
  `projectile.dart`, `floating_text.dart` und `battle_game.dart` haben
  weiter ihre eigenen Werte. Das war Absicht — die Figuren sind Inhalt,
  nicht Oberfläche.

## Sitzung 08.09.2026, tagsüber: der Laden wächst

> **Seit PR [#33](https://github.com/Prozesstek/LifesGame/pull/33) auf
> `main`.** Die Überschrift hieß bis zum Abend „Läuft gerade" — der
> Branch `feat/items-und-sets` ist gemergt, alle vier Schritte plus
> Verkauf sind drin.

Vier Schritte, einzeln prüfbar. Auslöser war der Wunsch nach mehr Inhalt:
Mit neun Stücken ist der Laden nach zwei Wochen gesehen, und Ziel 7
verlangt dreißig Tage.

| Schritt | Inhalt | Stand |
|---|---|---|
| 1 | Seltenheit je Stück | **fertig** |
| 2 | Fünf Stücke je Platz | **fertig**, außer Waffe |
| 3 | Fünf Waffen mit eigener Fähigkeit (= Ziel 3) | **fertig** |
| 4 | Sets und Set-Boni | **fertig** |
| + | Verkauf im Laden (nachgereicht) | **fertig** |

### Was Schritt 1 und 2 gebracht haben

**27 Stücke statt 9.** Fünf je Platz — zwei gewöhnliche, zwei
ungewöhnliche, ein seltenes — auf allen Plätzen außer der Waffe.

**Die Waffe hinkt mit Absicht hinterher.** `abilities_seam_test.dart`
verlangt, dass **jede Waffe im Laden eine Fähigkeit mitbringt**; eine
neue Klinge ohne Fähigkeit lässt den Test umfallen. Der Test erzwingt
damit, dass Schritt 3 die Waffen samt Fähigkeiten bringt — genau
richtig, denn der Waffenslot ist auf Level 1 der einzige offene
(ADR-0016).

**Eine Regel musste weichen** ([ADR-0029](../decisions/0029-seltenheit-statt-preisleiter.md)):
ADR-0011 sicherte zu, dass auf demselben Platz teurer auch besser heißt.
Das setzt eine Leiter voraus — und Sidegrade-Waffen, Set-Teile und
Fähigkeiten am Stück brechen sie. Die Regel gilt jetzt **innerhalb einer
Seltenheit**, wo sie noch schützt.

**Die Preise bleiben am Gold-Zufluss gemessen.** Zwei Grenzen prüft
`catalog_test.dart`: Ein voller Satz der billigsten Stücke muss in etwa
einem Monat tragbar sein (heute 33,6 Tage), und das teuerste Einzelstück
ebenso (der Aderring mit 1050 Gold, also 42 Tage).

### Zwei Layout-Fehler, die dabei aufgefallen sind

Beide dieselbe Wurzel wie der Eintrag in `gotchas.md`: **zwei Texte
nebeneinander in einer `Row`, von denen keiner schrumpfen kann.**

Der Layout-Test kauft im Aufbau **jedes** Stück des Katalogs. Mit 27
statt 9 Stücken wurde das Gold tief negativ, der Text damit länger — und
prompt liefen `LevelCard` (dort stand ein `Spacer` zwischen zwei festen
Texten) und `HubTile` über. Beide schrumpfen jetzt mit `Flexible` und
`ellipsis`.

**Der Aufbau selbst bleibt so**, obwohl er einen unerreichbaren Zustand
erzeugt — im Spiel prüft `Loadout.buy` das Gold, man kann sich nicht
überkaufen. Als Belastungsprobe hat er sich gerade bewährt.

### Was Schritt 3 gebracht hat — und damit Ziel 3

**Fünf Waffen, fünf verschiedene Züge.** Bis heute gaben *beide* Klingen
im Laden `sword_strike`; die Waffe bestimmte nichts, und der Slot, der auf
Level 1 als einziger offen ist (ADR-0016), war Dekoration.

| Waffe | Seltenheit | Preis | Zug | Power | Energie |
|---|---|---|---|---|---|
| Kurzbogen | gewöhnlich | 140 | Bogenschuss | 1,0 | +3 |
| Übungsklinge | gewöhnlich | 240 | Hieb | 1,3 | +2 |
| Streitkolben | ungewöhnlich | 620 | Wuchtstoß | 0,9 | +3, Verteidigung runter |
| Geschliffene Klinge | ungewöhnlich | 760 | Doppelstich | 0,5 | +4 |
| Kriegsstab | selten | 980 | Sammelschlag | 0,6 | +5 |

Die Tabelle ist die aus [ADR-0017](../decisions/0017-faehigkeitskatalog-aus-drei-quellen.md),
Punkt 2 — sie stand seit dem 22.08. geschrieben da und galt im Code nicht.
Neue Zahlen in `packages/combat` gab es dafür keine.

**Der Kurzbogen trägt denselben Zug wie der Rückfall**, und das ist
Absicht: ADR-0017 zählt ihn unter die fünf Waffen, und „den Bogen hat
jeder" ist genau der Grund, warum er auch der Rückfall ist. Gekauft gibt
er Angriff statt eines neuen Rhythmus — der ruhigste Einstieg, den der
Laden hat.

**Der Laden sagt jetzt, was eine Waffe mitbringt.** Eine Zeile je Waffe
(„Bringt Hieb mit — ×1,3 Schaden, +2 Energie je Runde"), zusammengesetzt
von `weaponAbilityLine` in `lib/gear/`. Ohne sie wäre der Kauf blind:
Fünf Rhythmen sind nur dann eine Entscheidung, wenn man vor dem Kauf
sieht, welchen man bekommt.

### Der Befund: die Waffe entscheidet — zu einseitig

`tool/balance_sim.dart` hat einen Abschnitt dazubekommen, der genau die
Behauptung prüft, auf der Ziel 3 steht. Siegquote je Waffe, mit
Waffenbonus und Waffenzug, gemischtes Timing:

| Waffe | Söldner Tag 21 | Bergwächter Tag 21 | Söldner Tag 30 | Bergwächter Tag 30 |
|---|---|---|---|---|
| Kurzbogen | 40 % | 8 % | 99 % | 33 % |
| **Übungsklinge** | **100 %** | **66 %** | **100 %** | **96 %** |
| Streitkolben | 82 % | 14 % | 100 % | 47 % |
| Geschliffene Klinge | 4 % | 3 % | 41 % | 12 % |
| Kriegsstab | 11 % | 4 % | 62 % | 16 % |

**Die gute Hälfte:** Die Waffe entscheidet Kämpfe. 4 % gegen 100 % auf
demselben Gegner am selben Tag — der Waffenslot ist keine Dekoration
mehr.

**Die schlechte:** Es ist kein Sidegrade, sondern eine Rangfolge, und die
zweitbilligste Waffe steht oben. Wer 980 Gold für den Kriegsstab
ausgibt, kämpft schlechter als mit den 240 der Übungsklinge.

**Die Ursache ist bekannt und steht seit dem 26.08. hier:** Die frühen
Spielerfähigkeiten sind schwächer als der Basisangriff. Energie zu
erzeugen lohnt nur, wenn es etwas gibt, wofür man sie ausgibt — und an
Tag 21 hat der simulierte Spieler Funkenstoß (Power 0,75) und zwei
weitere Commons. Der Waffenbefund ist damit kein neuer, sondern derselbe
aus einer zweiten Richtung.

**Zwei Einschränkungen der Messung**, beide schon bekannt: Der simulierte
Spieler wird von `SimpleEnemyPolicy` gesteuert und benutzt keine Utility
(`utilityChance` 0). Mit mehr Möglichkeiten wählt ein Bot schlechter —
die energiestarken Waffen sind also **unter**bewertet, wie schon bei „drei
Moves sind schlechter als zwei" (22.08.).

**Balancing bleibt zurückgestellt.** Gemessen und gemeldet ist es; die
Hebel sind dieselben drei wie am 26.08.: die `power`-Werte der Commons,
die Gegner-Sets, oder der Nenner 16.

**Was der Laden trotzdem schon tut:** Der `why`-Text jeder teuren Waffe
sagt es ausdrücklich. Beim Kriegsstab steht „Wer nur zuschlagen will, ist
mit der halb so teuren Übungsklinge besser bedient", bei der
Geschliffenen Klinge „sie lohnt sich erst, wenn auf den freien Plätzen
etwas liegt, das Energie kostet". Eine Falle, die sich selbst benennt,
ist keine mehr — aber sie bleibt eine, bis die Zahlen stimmen.

### Was Schritt 4 gebracht hat: drei Sets

[ADR-0030](../decisions/0030-sets-wirken-auf-eine-art-von-faehigkeit.md).
348 App-Tests (vorher 336), gear 51 (vorher 31), combat 96 (vorher 80).

**Kein neues Stück.** Von den fünf Stücken auf Waffe, Rüstung, Helm und
Schuhe tragen drei eine Set-Marke, zwei keine — drei Sets à vier Teile
gehen damit genau auf. Ring und Talisman gehören zu keinem Set, sonst
hieße „Set voll" auch „die ganze Ausrüstung steht fest".

| Set | Wirkt auf | 2 Teile | 4 Teile | voll |
|---|---|---|---|---|
| Eiserner Wille | Angriffs-Fähigkeiten | +10 % Schaden | +25 % | 1880 |
| Sturmruf | Umgebungen | −1 Energie | −2 Energie | 1870 |
| Ruhiger Stand | Schutz und Heilung | Leiste ×0,85 / ×1,25 | ×0,7 / ×1,6 | 1840 |

**Jedes Set wirkt auf genau eine Art.** Bei „alles gleich" gäbe es eine
richtige Antwort — das Set mit der größten Zahl. So hängt die Antwort
daran, was auf den Fähigkeitsplätzen liegt, und damit am Skillbaum und an
den Streaks.

**Ein Set wirkt nicht auf den Waffenzug**, obwohl der als Angriff zählt.
Das ist ADR-0009 ein zweites Mal: Ein Faktor auf den Zug, den man jede
Runde drückt, entscheidet den Kampf allein.

**Der Spielstand ist unverändert.** Was aktiv ist, wird aus dem Getragenen
abgeleitet — wie das Gold (ADR-0011) und die Erfahrung (ADR-0008). Sets
überleben einen Neustart, weil die Ausrüstung es tut.

**Die 2er-Stufe ist in 10 bis 19 Tagen erreichbar, die 4er in rund 75.**
Beides prüft `set_catalog_test.dart`. Die volle Stufe liegt bewusst
jenseits des 30-Tage-Laufs: Der Laden soll danach noch etwas zu wollen
übrig lassen.

### Was die Simulation dazu sagt — und was sie nicht sagen kann

`_setvergleich` in `tool/balance_sim.dart` misst denselben Spieler mit und
ohne Set-Wirkung. Rundenzahl statt Siegquote, weil die Quote sättigt:

| Set | Wegelagerer | Söldner | Bergwächter |
|---|---|---|---|
| Eiserner Wille | 5,3 → 5,3 | 10,8 → 10,8 | 10,4 → 10,4 |
| **Sturmruf** | 5,0 → 5,0 | **6,2 → 5,3** | **8,0 → 7,2** |
| Ruhiger Stand | 7,1 → 7,1 | 19,2 → 19,2 | 16,1 → 16,1 |

**Nur Sturmruf ist messbar, und die beiden Nullen liegen an der
Simulation, nicht an den Sets:**

- *Ruhiger Stand* macht die Leiste breiter und langsamer. Der simulierte
  Spieler **tippt aber nicht** — sein Timing kommt aus einer gewichteten
  Münze (`timingSkill`), nie aus `TimingSpec.judgeAt`. Eine breitere
  Leiste kann für ihn nichts ändern.
- *Eiserner Wille* verstärkt Angriffs-Fähigkeiten. Die drei, die dem
  Spieler an Tag 30 zuerst zufallen, sind schwächer als sein Waffenzug,
  und `SimpleEnemyPolicy` wählt sie deshalb nicht. **Derselbe Befund wie
  beim Waffenvergleich, aus einer dritten Richtung.**

**Und ein Befund, der über die Sets hinausgeht: Gegen drei Gegner ist ein
volles Set Überfluss.** Die Siegquote steht mit vier Set-Stücken überall
auf 100 %. Der Platz eines Sets ist der Dungeon (Ziel 6), wo HP zwischen
den Kämpfen nicht heilen und jede gesparte Runde zählt.

### Nachgeliefert: der Laden verzeiht jetzt

[ADR-0031](../decisions/0031-verkauf-als-versenkte-kosten.md). 355
App-Tests (vorher 348), gear 64 (vorher 51).

**Ein Verkauf bringt die Hälfte, die andere Hälfte bleibt ausgegeben.**
Das war der Grund, warum ADR-0011 den Verkauf ausgeschlossen hatte — und
der Grund ist mit 27 Stücken, fünf Sidegrade-Waffen und drei Sets
weggefallen: Ein Fehlgriff kostet bis zu 1050 Gold, also 42 Tage, und war
nicht zu korrigieren.

**Der Fehler, der beinahe von selbst passiert wäre:** Gold ist abgeleitet
(Zufluss minus Preis des Besitzes). Ein Stück aus dem Besitz zu nehmen
gibt deshalb **von selbst den vollen Preis zurück** — man hätte dafür
nichts bauen müssen. Genau das wäre falsch gewesen: Der Laden wäre
folgenlos, jede Kaufentscheidung widerrufbar und damit keine.

**Und es ist trotzdem keine zweite Wahrheit.** Gespeichert wird
`Loadout.soldIds`, eine **Historie** — dieselbe Bauform wie die Häkchen
und wie `ownedIds` selbst. Was daraus fürs Gold folgt, wird gerechnet
(`lostGold`). Ein gespeicherter Goldstand könnte von der Rechnung
abweichen; eine Historie *ist* die Rechnung.

**Verkaufen legt ab**, und ein Set verliert damit sofort sein Teil. Im
Laden steht der Knopf da, wo sonst „Kaufen" steht, davor eine Rückfrage
mit beiden Zahlen: was zurückkommt und was ein Rückkauf kostet. Ein Kauf
lässt sich ohne Verlust rückgängig machen, ein Verkauf nicht.

### Offen aus Schritt 4

**Nicht am Bild geprüft.** Set-Karte und Laden-Marke laufen im Test bei
390 × 844 ohne Überlauf. Wie drei Set-Zeilen untereinander auf einem Handy
**aussehen**, muss jemand ansehen.

---

## Phase

**Der MVP-Schnitt steht.** Lektion lesen → Vorlage freischalten →
täglich abhaken → Werte steigen → Gold sammeln → Ausrüstung kaufen →
nächsten Gegner der Reihe schlagen. Alles davon überlebt einen Neustart.

Seit dem 08.09. ist der letzte offene Punkt zu — allerdings anders als
geplant: Ziel 6 war der Dungeon und ist jetzt die **Gegnerreihe** aus
dreißig Stufen ([ADR-0032](../decisions/0032-gegnerreihe-statt-dungeon.md)).
Der Dungeon steht auf der Sperrliste in `ziele.md`.

Damit ist auch eine Entscheidung gefallen, die seit dem ersten
Konzeptentwurf stand: **Der Kampf zahlt jetzt Erfahrung und Gold — genau
einmal je Gegner.**

Seit dem 06.09. hat die Kette einen Abzweig: Jede freigeschaltete Vorlage
gibt zusätzlich einen Platz für eine **eigene** Gewohnheit
([ADR-0028](../decisions/0028-eigene-gewohnheiten.md)). Der Baum bleibt
der Motor, aber was am Ende auf der Tagesliste steht, entscheidet der
Spieler.

Seit dem 22.08. gibt es **eine** Sperre wieder, und sie ist gewollt:
Der **Kampf** wartet, bis das Handbuch durch ist
([ADR-0018](../decisions/0018-kampf-hinter-dem-handbuch.md)). Mit nur
einem Fähigkeitsslot wäre der erste Gegner unschlagbar.

```bash
flutter run -d chrome
```

## Sitzung 08.09.2026, abends: Oberfläche und die Gegnerreihe

Zwei Issues an einem Abend. 378 App-Tests (vorher 355), combat 115
(vorher 96).

### Issue [#35](https://github.com/Prozesstek/LifesGame/issues/35): das Layout

Drei Bildschirme nach den Entwürfen umgebaut.

**Der Startbildschirm ist kein Menü mehr.** Die Figur steht in der Mitte,
die fünf Bereiche liegen als Kreise darum, Level und Gold sitzen unter
der Figur. Fünf Kacheln untereinander haben funktioniert und nichts
erzählt — ein Habit-Tracker, dessen Startseite aussieht wie ein
Einstellungsmenü, muss seine Aussage jeden Tag neu behaupten.

Der Sperrgrund des Kampfes hat auf einem Kreis keinen Platz mehr. Er ist
nicht weg, er kommt beim Antippen — ADR-0020 nennt ihn ausdrücklich
wichtig, und alle drei Fälle sind erhalten.

**Der Laden hat Reiter.** Ein Platz je Reiter, darunter das Raster und
eine Detailfläche. Mit siebenundzwanzig Stücken war er eine Rolle von
rund fünftausend Pixeln: Wer Ringe vergleichen wollte, scrollte an vier
Plätzen vorbei und hatte den ersten vergessen, bevor er den letzten sah.

**Die Gewohnheiten haben einen schwebenden Knopf und keine Untertexte
mehr.** Die **Zahlen** sind geblieben und nach rechts gewandert: die
Kette als Marke neben dem Namen, der Stand eines Tagesziels an seinem
Balken. Sie mitzunehmen wäre aus einer Layout-Änderung eine
Produktänderung geworden — die Streak ist der Grund, morgen
wiederzukommen (`konzept.md` 3.7).

**Vorbereitet, nicht gebaut:** `GearIcons` und `EnemyIcons` halten die
Plätze für Item- und Gegnerbilder frei, gebaut wie `MoveIcons` — Datei
ablegen, eine Zeile ergänzen, der Test greift ab dann von selbst. Die
übrigen Designs aus dem Issue (Button, Background, Abilities) sind
Grafikarbeit und stehen aus.

### Issue [#36](https://github.com/Prozesstek/LifesGame/issues/36): dreißig Gegner

**Ziel 6 ist umgeschrieben und erfüllt**
([ADR-0032](../decisions/0032-gegnerreihe-statt-dungeon.md)). Das Issue
beschreibt nicht den Dungeon, sondern eine Reihe: dreißig Gegner,
aufsteigend, „1 / 30" und ein Kampf-Knopf. Der Dungeon steht jetzt auf
der Sperrliste in `ziele.md`.

**Die drei alten Gegner sind Stützstellen geblieben.** Ihre Werte sind in
ADR-0009 gemessen worden; sie zu überschreiben hätte die einzigen
belastbaren Zahlen des Projekts entwertet. Die Reihe wächst *zwischen*
ihnen — Wegelagerer auf Sprosse 1, Söldner auf 6, Bergwächter auf 20,
dazu eine neue Spitze auf 30.

**Die Werte sind gerechnet, nicht getippt.** Eine Tabelle mit dreißig
Zeilen lässt sich nicht „stetig steigend" halten, ohne dass es jemand
nachrechnet; `enemy_ladder_test.dart` tut das, und bei einer Tabelle
hätte er nichts zu prüfen gehabt außer Tippfehlern. Er hat sofort etwas
gefunden: Die Utility-Quote fiel von Sprosse 6 auf 7, weil die
Stützstellen ihre eigene tragen und eine Formel daneben lief.

### Die Entscheidung, die ein Test erzwungen hat

Das Issue sagt: „Als Belohnung gibt es Gold und XP." Dagegen stand
`konzept.md` Abschnitt 2 — der Kampf ist die *Auszahlung* des
Fortschritts, nicht seine Quelle — und ein Test, der genau dafür
geschrieben worden war:

> „Stünde dort eines Tages ‚+50 XP', wäre das eine Richtungsentscheidung
> und kein Textdetail — dieser Test zwingt sie ans Licht."

**Er hat funktioniert.** Die Entscheidung ist kleiner ausgefallen, als er
annahm: Belohnung ja, aber **einmal je Gegner**. Der alte Einwand trifft
nur wiederholbare Belohnung; eine Lektion in `package:theory` zahlt
ebenfalls, und ebenfalls genau einmal. Der Gesamtbetrag steht damit als
Zahl fest: 2775 Erfahrung und 1110 Gold über dreißig Kämpfe.

Der Test ist nicht gelöscht, sondern umgeschrieben: Er bewacht jetzt die
Grenze statt des Verbots — ein zweiter Sieg zahlt nichts, eine Niederlage
erst recht nicht.

### Was die Simulation sagt

`tool/balance_sim.dart` hat einen Abschnitt „Die Reihe" bekommen. Er
beantwortet die Frage, die das Issue ausdrücklich stellt.

| | Tag 30, ohne Ausrüstung | Tag 60, voll ausgerüstet |
|---|---|---|
| Sprosse 1–5 | 100 % | 100 % |
| Sprosse 10 | 27 % | 100 % |
| Sprosse 20 (Bergwächter) | 18 % | 100 % |
| Sprosse 27 | 0 % | 100 % |
| **Sprosse 30** | **0 %** | **62 %** |

**Sprosse 30 ist erreichbar**, wie das Issue es verlangt — und die
Simulation ist dabei pessimistisch für den Spieler: Ihr Bot tippt
gemischt und benutzt keine Utility.

**Die Spitze hat drei Anläufe gebraucht.** Bei 300 HP gewann ein
ausgerüsteter Charakter gegen *alle* dreißig zu 100 %, bei 1000 HP gegen
keinen ab Sprosse 26. Sie steht jetzt bei 460 HP, 25 Angriff, 15
Verteidigung — gemessen, nicht geraten.

### Zwei Befunde, die offen bleiben

**Die Reihe steigt in ihren Werten stetig, in der Siegquote nicht.**
Zwischen Sprosse 16 und 17 springt sie nach oben (2 % auf 32 % ohne
Ausrüstung), weil dort das Gegner-Moveset von Uncommon auf Rare wechselt
und die Rare-Züge mehr Energie kosten, als die Gegner dort haben. Es ist
derselbe Effekt wie beim Bergwächter am 26.08. („Donnerkeil kostet 5
Energie — Kraftschlag konnte er öfter spielen"). Balancing bleibt
zurückgestellt, aber der Befund steht mit Zahlen da.

**Die obere Mitte ist für einen Ausgerüsteten flach.** Sprosse 21 bis 27
stehen alle auf 100 %. Sieben Kämpfe ohne Spannung — die Kurve müsste
dort früher steiler werden.

**Nicht am Bild geprüft.** Beide Issues sind Oberflächenarbeit; alle
Layouts laufen im Test bei 390 × 844 ohne Überlauf und `flutter build
web` steht, aber wie es auf einem Handy **aussieht**, muss jemand
ansehen.

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
  - **Gold wird abgeleitet:** Zufluss minus Preis des Besitzes und minus
    versenkter Verkäufe. Kein gespeicherter Kontostand (ADR-0031)
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
  - ~~**Gegnerwahl** vor dem Kampf, mit Einschätzung („wird knapp")~~ —
    am 08.09. durch die **Gegnerreihe** ersetzt
    ([ADR-0032](../decisions/0032-gegnerreihe-statt-dungeon.md)). Die
    Einschätzung ist mit ihr weggefallen: Sie stützte eine Wahl, und die
    gibt es nicht mehr
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

## Sitzung 06.09.2026: Eigene Gewohnheiten

Issue [#28](https://github.com/Prozesstek/LifesGame/issues/28) gebaut:
Der Tracker nimmt jetzt auf, was jemand **tatsächlich** täglich tut, statt
nur das, was zufällig unter den elf Vorlagen steht
([ADR-0028](../decisions/0028-eigene-gewohnheiten.md)). 322 App-Tests
(vorher 311), habits 114 (vorher 71).

### Was gebaut ist

- **`CustomHabit`** neben `HabitTemplate`, beide unter dem `sealed` Obertyp
  **`Habit`**. Die Tagesliste, die Streak-Rechnung und der Speicher kennen
  nur noch diesen Typ
- **Ein Knopf** auf dem Gewohnheiten-Bildschirm, dahinter ein Formular:
  Name, Charakterwert, Schwierigkeit, Tagesziel (Menge oder Zeit),
  Priorität, freiwillige Begründung
- **Tagesziele mit Zähler:** „3 / 5 Gläser" mit Balken auf der Kachel. Das
  Plus füllt um einen Schritt, die Kachel selbst hakt ganz ab
- **Schwierigkeit** als Faktor auf die Erfahrung — leicht ×0,8, mittel
  ×1,0, schwer ×1,3, **nie** auf Gold
- **Priorität** sortiert die Tagesliste und sonst gar nichts
- Alles davon überlebt einen Neustart, angefangene Tage eingeschlossen

### Vier Entscheidungen, die begründet gehören

**Ein Platz je freigeschalteter Vorlage.** Der Skillbaum bleibt damit der
Motor — ohne Lektion keine eigene Gewohnheit —, aber was am Ende auf der
Liste steht, entscheidet der Spieler. Fünf freie Plätze von Anfang an
hätten den Baum für die Gewohnheiten bedeutungslos gemacht, sieben Tage
nachdem Ziel 2 ihn zur Entscheidung gemacht hat.

**Die Schwierigkeit ist eine schmale, feste Spanne, weil sie der Spieler
selbst setzt.** Ein frei eingebbarer Faktor wäre ein Regler am
Spielgleichgewicht in der Hand dessen, der ihn gewinnen will. Gemessen:

| Tagesliste | bis Level 10 | bis Level 50 |
|---|---|---|
| fünf Vorlagen (= mittel) | 18 Tage | 240 Tage |
| fünf eigene, alle „leicht" | 22 Tage | 297 Tage |
| fünf eigene, alle „schwer" | 15 Tage | **188 Tage** |

Der schnellste denkbare Weg ist 22 % schneller als der bisherige — eine
Farbe, kein Schlupfloch. `progression_test.dart` misst alle drei Fälle
seither mit; wer an `HabitDifficulty` dreht, sieht es dort.

**Halb getan ist nicht getan.** Ein Tagesziel zahlt erst aus, wenn es voll
ist, und Teilfortschritt wandert nicht in den nächsten Tag. Anteilig
auszuschütten machte die Streak wertlos — sie ist die Aussage „an diesem
Tag stand es". Und eine Woche halber Tage summierte sich sonst zu einem
geschenkten Häkchen.

**Was eine Zahl erzeugt, lässt sich nicht mehr ändern.** Wert,
Schwierigkeit und Ziel stehen mit dem Anlegen fest; Name, Begründung und
Priorität nicht. Der Grund ist ADR-0008: Erfahrung und Charakterwerte
werden aus der Historie *gerechnet*. Wer die Schwierigkeit nachträglich
hochsetzte, schriebe jedes Häkchen der Vergangenheit um und stiege
rückwirkend im Level. Die Trennlinie steht als eine Methode da,
`CustomHabit.editable`.

**Gelöscht wird nichts.** Eine eigene Gewohnheit lässt sich stoppen wie
eine Vorlage — ihre Häkchen bleiben und damit die Charakterwerte. Gelöscht
wären sie keinem Wert mehr zuzuordnen.

### Was der Umbau am Bestehenden geändert hat

- `activeTemplates` heißt **`activeHabits`**, dazu kam
  `activeHabitsByPriority`
- `HabitTracker` löst eine Id an **einer** Stelle auf
  (`definitionFor`) — erst Katalog, dann eigene. Das ist bewusst dieselbe
  Vorsichtsmaßnahme wie in `gotchas.md` unter „Zwei Stellen, die dieselbe
  Frage beantworten"
- Der Spielstand hat zwei neue Abschnitte, `custom` und `progress`, und
  schreibt beide **nur, wenn sie belegt sind** — ein Stand ohne eigene
  Gewohnheiten sieht aus wie vorher
- Die 71 vorhandenen Package-Tests liefen **unverändert** durch. Das war
  das Ziel: Vorlagen sind immer „mittel" und haben kein Ziel, also rechnet
  jede alte Zahl wie vorher

### Offen

**Zwei Griffe auf einer Kachel.** Die Kachel hakt ganz ab, das Plus füllt
um einen Schritt. Ob das auf einem Handy im Alltag verwechselt wird, sagt
der 30-Tage-Lauf, nicht eine Vermutung.

**Nicht am Bild geprüft.** Alle Layouts laufen im Test bei 390 × 844 ohne
Überlauf, das Formular eingeschlossen. Wie das Blatt mit offener Tastatur
**aussieht**, muss jemand ansehen.

**Der Katalog ist nicht gewachsen.** Die Überschrift von Issue #28 lautet
„Mehr Gewohnheiten hinzufügen"; die beiden Unterpunkte beschreiben eigene
Gewohnheiten, und die sind gebaut. Weitere **Vorlagen** brauchen je eine
Lektion mit passendem `unlocksHabit` (`habits_theory_test.dart` erzwingt
das) und sind damit Schreibarbeit, kein Code. Elf Vorlagen auf
neunundzwanzig Seiten — die Schieflage aus der Konzeptrunde vom 18.08.
(zu wenig Stärke und Ausdauer) ist damit nicht behoben, aber entschärft:
Wer Kraftsport treibt, legt ihn jetzt selbst an.

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

### Die Kachel ist der Knopf

Jeder Zug ist eine **quadratische Kachel, die man drückt** — alle in
einer Reihe, höchstens 88 Pixel, Energiekosten unten rechts in der Ecke.
Ohne Bild trägt die Kachel ihren Namen.

**Bilder gab es zwischendurch und gibt es gerade nicht.** Vier
Pixelgrafiken für Frostnebel, Sandsturm, Giftmoor und Vulkanbruch waren
eingebaut und sind am 27.08. auf Wunsch wieder heraus — das Format ist
geblieben. Die Vorlagen liegen weiter unter
`Desktop\Lifes Game Mockup\Fähigkeiten\`, nicht im Repo.

Der Weg zurück steht in `move_icon.dart` und ist drei Schritte lang:
Datei nach `assets/abilities/` (benannt wie die Move-Id, 384 Pixel), den
Ordner in `pubspec.yaml` eintragen — die Zeile steht dort auskommentiert
bereit — und eine Zeile in `MoveIcons`. Die Prüfungen in
`move_icon_test.dart` laufen heute über eine leere Menge und greifen ab
der ersten Zeile wieder.

**Die Kantenlänge kommt aus der verfügbaren Breite, nicht aus einer festen
Zahl.** Nur so ist die Kachel wirklich quadratisch. Eine Zwischenfassung
war 175 breit und 128 hoch und schnitt die quadratischen Vorlagen oben
und unten an.

**Die Namenszeile über der Kachel erscheint nur, wenn in der Reihe
überhaupt ein Bild vorkommt.** Sonst stünde über jeder Kachel ein leerer
Streifen — der Name steht ja schon darin.

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
| 8 — Tageswechsel | Ziel 4 | ~~06.09.2026~~ **erledigt 11.09.** |
| 2 — Fähigkeiten (Issue #17 erweitert) | Ziel 5 | 13.09.2026 |
| 4 + 5 — Dungeon, Tränke | Ziel 6 | 20.09.2026 |
| — Errungenschaften (Issue #41, ADR-0033) | Ziel 8 | 20.09.2026 |
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

~~**8. Tageswechsel bei laufender App**~~ — **erledigt am 11.09.**
`lib/habits/day_watcher.dart` rechnet „heute" um Mitternacht, jede
Minute und beim Zurückkehren in den Vordergrund neu.

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
- ~~**Kein Verkauf im Laden**~~ — **erledigt am 08.09.** ([ADR-0031](../decisions/0031-verkauf-als-versenkte-kosten.md)).
  Das Signal war eingetreten: Mit 27 Stücken, fünf Sidegrade-Waffen und
  drei Sets war ein Fehlgriff bis zu 42 Tage teuer und nicht zu
  korrigieren.

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
