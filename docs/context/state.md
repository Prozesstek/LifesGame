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

**Zuletzt aktualisiert:** 09.10.2026 · Frederik

---

## Übersicht: was steht

**Phase:** Testlauf (Ziel 7, 21.09.–20.10.2026). Alle Bauziele 1–6 und 8
sind erreicht; seit Teststart wurde trotzdem stark weitergebaut (siehe
„Offen“).

| Bereich | Stand | Wo nachlesen |
|---|---|---|
| **Gewohnheiten** | Vorlagen und eigene, **Wochenplan je Gewohnheit**, **Koppeln zu Stapeln**, Streaks, **die fallen statt zu reißen**, **Tageskette**, Streak-Eis, Tagesform, Tagestruhe, **Tagesaufgaben**, Wochenrückblick, Auslöser „Wann machst du das?“, **Belohnung danach**, **Zeitziele als Timer**, Startvorlage | ADR-0028, -0036, -0043, -0044, -0052, -0055, -0064, -0065, -0066, -0067 |
| **Startseite** | sieben Kreise, **die nach und nach erscheinen**, Level-Abzeichen und Gold in einer Zeile, „Heute“ zum Abhaken, **am Anfang die Frage nach der ersten Gewohnheit** | ADR-0049, -0053, -0057, -0058, -0068 |
| **Wissensbaum** | vier Wurzeln, Zwischenebenen, 63 Knoten, 15 angekündigte Überschriften, ein Punkt je Knoten, **neun Startpunkte**, **das Handbuch als fünf Knoten unter Gewohnheiten**, **direkt zur nächsten Seite**, Rückfrage des Tages, **falsche Antworten kommen noch einmal**, **Ring und Zähler an jedem Knoten, Gebietsbalken, „Weiterlesen“** | ADR-0019, -0045, -0050, -0051, -0055, -0056, -0061, -0070 |
| **Kampf** | die Grube: Echtzeit, 30 Stufen, gesteckte Räume, **elf Gegnerarten in gewürfelter Besetzung**, **vier Wächter, je Lauf gewürfelt**, Tor und Auftritt, Uhr, vier Dailies, Beute je Gegner, **zwei Zeichen im ersten Lauf** | ADR-0039, -0040, -0041, -0046, -0062, -0063, -0069 |
| **Stärke** | Level und Seltenheit vervielfachen, Gewohnheiten addieren | ADR-0042 |
| **Ausrüstung** | Exemplare mit Würfen, Tagesladen, Beute mit Schlüsseln, Sets, Legendäre, Verkauf zu einem Viertel, **eigener Bereich mit allen 48 Stücken**, **Rahmen und Name in der Farbe der Seltenheit** | ADR-0029–0031, -0034, -0047, -0048, -0057 |
| **Fähigkeiten** | 19 Fähigkeiten und 8 Waffenzüge in der Grube, eigener Bereich mit allen Werten | ADR-0022, -0049 |
| **Errungenschaften** | 19 Meilensteine, 8 Entdeckungen, 13 Titel | ADR-0033 |
| **Speicher** | lokal im Browser, **als Text sicherbar** | ADR-0010, -0054 |
| **Prototyp** | das Dorf, nur im Entwicklermodus | — |

**Tests:** App 716, dazu die acht Packages (theory 193, habits 324, gear
118, action_combat 276, progression 42, abilities 36, identity 25,
achievements 24). **In der CI laufen nur die App-Tests** — der Umbau,
der alle prüft, wartet auf den `workflow`-Scope (`verlauf.md`, 27.09.).

## Offen, gesammelt

**Die Richtung** (09.10., [ADR-0071](../decisions/0071-das-naechste-level.md)):
Tagesgrube, Lagerfeuer, Schatten, Saisons, Seilschaft — nach und nach,
jede mit eigener Konzeptrunde. Die Fragen dafür stehen in der Vorlage
[`das-naechste-level.md`](../vorlagen/das-naechste-level.md).

**Braucht euch beide:**

- ~~**Was der Testlauf misst.**~~ Entschieden am 27.09. (Frederik):
  **weiterbauen**. Der Testlauf ist damit ein Entwicklungsmonat; ob
  Ziel 7 neu formuliert wird, steht in `ziele.md` noch aus.
- **Das Dorf** statt der Kreise? Frederik lehnt es ab (Issue #88) und
  will stattdessen das **Haus** ausbauen (Möbel, Haustiere). Braucht
  AktivesBrett und einen ADR.
- **Die fünf Ideen** aus ADR-0071 hat AktivesBrett nicht gesehen.

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
- `world.dart` (1.754 Zeilen), `tracker.dart` (1.858) und
  `action_game.dart` (1.024) liegen über der 800-Zeilen-Grenze.

**Bewusst zurückgestellt** (Frederik, 27.09.): die tägliche Erinnerung
(APK oder Web-Push) und die Identität im Wochenrückblick.

---

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
- Ob die vier Dailies in der Tagesgrube aufgehen (ADR-0040).
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

## 03.10.2026: „Mach es attraktiv“ — eine Belohnung je Gewohnheit

Frederik: „Können wir ‚eine Gewohnheit muss attraktiv sein‘ irgendwie
einbauen?“ Vier Wege vorgeschlagen, in einer Fragerunde gewählt: das
**Versuchungsbündel**,
[ADR-0066](../decisions/0066-versuchungsbuendel.md). Vorher gemergt:
PR #103 (Wochenplan) und #104 (Koppeln).

| Was | Wie |
|---|---|
| **Eintragen** | im Dialog „Wann machst du das?“ ein Feld „Und danach gönnst du dir:“, fünf Vorschläge zum Antippen |
| **Vorfreude** | auf der Kachel und in „Heute“ steht die Belohnung mit einem Geschenk, solange die Gewohnheit offen ist |
| **Einlösen** | beim Abhaken steht unten drei Sekunden „Jetzt: Kaffee“ |
| **Keine Zahl** | Erfahrung, Gold und Ketten ändern sich nicht (`treat_test.dart`) |

Sie steht neben Satz **und** Anker: nach X mache ich Y, danach gönne
ich mir Z.

**Beim Ansehen gefunden** (gerendert in 390 × 844 mit Roboto): Im
Dialog lag das neue Feld erst nach zwei Bildschirmen Rollen, weil sechs
Vorschläge in sechs Zeilen umbrachen. Die Vorschläge stehen jetzt in
einer Zeile zum Wischen, das Feld ist ohne Rollen zu sehen.

habits 298 (vorher 285), App 656 (vorher 646). Kachel, Dialog,
Startseite und das Häkchen gerendert und angesehen. **Nicht am Handy,
nicht im Browser gespielt.**

**Dazu die Theorie-Seite „Mach es attraktiv“** (Frederik: „Theorie
Seite auch bauen“), als Knoten unter „Die vier Regeln“: Vorfreude statt
Belohnung, das Versuchungsbündel, die Menschen um einen herum, umdeuten
und umdrehen. Der Baum hat damit 58 Knoten. **Anders als bei Regel 1
kommt der Inhalt nicht aus Frederiks Notizen, sondern von Claude** nach
dem Aufbau des Kapitels — gegenlesen. `question_fairness_test` hat zwei
zu kurze richtige Antworten erwischt, beide angeglichen.

### Offen

- Die Seite „Mach es attraktiv“ ist nicht gegengelesen; die Aussage
  über Dopamin ist vereinfacht.
- Die App gibt die Belohnung nicht und prüft sie nicht; ob „Jetzt: …“
  trägt, zeigt das Spielen.
- „Jetzt: …“ steht in der Leiste unten, nicht bei den aufsteigenden
  Zahlen am Finger — dort wäre ein langer Satz übergelaufen.
- Die Wochentage, der Auslöser, der Anker und die Belohnung stehen in
  **einem** Dialog; er ist voll.

## 02.10.2026, ganz zuletzt: Gewohnheiten koppeln

Frederik: „Ich fände es noch cool, wenn man Gewohnheiten aneinander
koppeln kann wie im Buch *Die 1%-Methode*.“ In einer Fragerunde
entschieden: [ADR-0065](../decisions/0065-gewohnheiten-koppeln.md).
Gebaut **auf dem Wochenplan-Branch** (PR #103), weil beides denselben
Dialog umbaut.

| Was | Wie |
|---|---|
| **Koppeln** | im Dialog „Wann machst du das?“ stehen unter den Textvorschlägen die anderen laufenden Gewohnheiten; eine antippen macht sie zum Anker |
| **Anzeigen** | die gekoppelte steht in „Heute“ eingerückt unter ihrem Anker, auf der Kachel „Nach: Zähne putzen“; Stapel beliebiger Länge |
| **Auslösen** | ist der Anker abgehakt, leuchtet die nächste dreimal auf und behält eine farbige Kante, bis sie erledigt ist |
| **Kein Schloss, keine Zahl** | alles bleibt jederzeit abhakbar; Erfahrung, Gold und Ketten ändern sich nicht (`stack_test.dart` hält das fest) |

**Ohne Rückfrage entschieden**, weil es sonst nicht aufgeht:

- **Satz oder Anker, nie beides** — der eine ersetzt den anderen.
- **Ein Stapel bleibt zusammen**: Er steht oben, solange ein Glied offen
  ist, und wandert als Ganzes nach unten. Sonst rutschte der abgehakte
  Anker von seiner offenen Folge weg.
- **Fehlt der Anker** (gestoppt, heute nicht fällig), steht die
  gekoppelte ohne Einrückung da; die Kopplung bleibt gespeichert.
- **Kein Kreis**: Was einen schlösse, steht im Dialog nicht zur Wahl.
- **Eingerückt wird höchstens drei Stufen.**

Neu: `packages/habits/lib/src/stack.dart`, `lib/habits/cue_text.dart`.
habits 285 (vorher 265), App 646 (vorher 637). Stapel, Dialog und
Startseite gerendert in 390 × 844 und angesehen; dabei behoben: Der
gewählte Anker im Dialog trug das blasse Rosa von Material statt der
Farben der App. **Nicht am Handy, nicht im Browser gespielt.**

### Offen

- Ob das Aufleuchten reicht oder zu leise ist; es hat keinen Klang.
- Die Priorität ordnet nur noch Stapel untereinander: Eine „wichtige“
  Gewohnheit unter einem „nebenbei“-Anker steht unter ihm.
- Die Theorie-Seite „Mach es offensichtlich“ nennt die Kopplung nicht.
- `tracker.dart` ist auf 1.652 Zeilen gewachsen.

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

---

Ältere Einträge: [`verlauf.md`](verlauf.md).
