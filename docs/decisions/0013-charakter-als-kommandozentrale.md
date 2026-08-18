# ADR-0013: Der Charakter wird eine Kommandozentrale, und er hat keine Klasse

**Datum:** 18.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Der Charakterbildschirm war der letzte Bildschirm des MVP und der dünnste. Er
zeigte Level, Gold, vier Werte mit ihrer Herkunft und sechs Ausrüstungsplätze —
korrekt, aber es war eine Zahlenliste mit einem grauen Personen-Symbol.

Beim Durchgehen fielen fünf Löcher auf:

1. **Das Level war der prominenteste Wert und der wirkungsloseste** — gelöst mit
   [ADR-0012](0012-theoriebaum-ueber-punkte.md).
2. **Der Charakter war nach etwa 35 Tagen fertig gebaut.** Alle vier Stat-Deckel
   liegen bei 35–40 Häkchen. Danach änderte sich auf dem Bildschirm nichts mehr.
3. **Die „4 aktiven Fähigkeiten" aus `konzept.md` 3.1 existierten nie.** Die vier
   Moves stehen fest in `packages/combat`; der Charakter besitzt sie nicht.
4. **Es gab kein Ich** — kein Name, kein Aussehen, keine Geschichte.
5. **Die Streak, der emotional stärkste Wert der App, kam auf dem
   Charakterbildschirm nicht vor** — obwohl dort „Alles hier kommt aus dem, was
   du getan hast" steht.

## Entscheidung

### Zweck und Abgrenzung

Der Charakterbildschirm ist die **Kommandozentrale**. Die Trennung zum
Startbildschirm ist inhaltlich, nicht technisch:

| Bildschirm | Zeigt |
|---|---|
| Start | **was ich tue** — Gewohnheiten, Theorie, Kampf, Laden |
| Charakter | **wer ich bin** — Werte, Fähigkeiten, Ausrüstung, Errungenschaften, Streaks, Freunde |

### Fähigkeiten

**Vier Slots. Drei frei wählbar, einer wird von der getragenen Waffe bestimmt.**
Die Slots öffnen sich bei Level 3 / 6 / 10.

**Zwanzig Fähigkeiten** insgesamt. Sie kommen aus drei Quellen:

| Quelle | Bedingung |
|---|---|
| Theoriebaum | einen Knoten **abschließen** (alle Lektionen bestanden) |
| Gewohnheiten | Streak-Marken 7 / 14 / 30 / 60 Tage |
| Waffen | jede Waffe bringt ihre eigene mit |
| Errungenschaften | später, vorerst zurückgestellt |

**Einmal verdient heißt behalten.** Eine Fähigkeit aus einer Streak-Marke bleibt,
auch wenn die Kette reißt.

**Fähigkeitspunkte** gibt es auf jedem dritten Levelaufstieg. Sie werten
Fähigkeiten auf und sind **umverteilbar**, gegen Gold.

### Identität

**Name jetzt** — Texteingabe beim ersten Start.

**Titel jetzt** — verdient, steht neben dem Namen: „der Beständige" nach 30 Tagen
Streak, „der Wissbegierige" nach dem fünften abgeschlossenen Knoten.

**Aussehen später** — braucht Grafik, Rive steht zuerst für den Kampf an.

**Klasse nie.** Siehe Begründung.

### Aufbau des Bildschirms

```
Frederik, der Beständige
Level 12 · 340 Gold
████████████░░░░░░  210 / 425 bis Level 13
● 2 Theoriepunkte    ● 1 Fähigkeitspunkt
─────────────────────────────────────────
WERTE IM KAMPF        vier Zeilen mit Herkunft
─────────────────────────────────────────
FÄHIGKEITEN           vier Slots nebeneinander,
                      Slot 1 trägt das Waffensymbol,
                      gesperrte zeigen „ab Level 10"
─────────────────────────────────────────
AUSRÜSTUNG            6er-Raster, antippen zum Wechseln
─────────────────────────────────────────
[Errungenschaften] [Streaks] [Freunde] [Zum Laden]
```

## Begründung

**Warum es nie eine Klassenwahl geben wird.** Das ist die wichtigste Festlegung
in diesem Dokument. Der Kern der App ist, dass *echtes Verhalten* bestimmt, wer
der Charakter ist. Eine Klasse, die man in der ersten Minute in einem Menü
anklickt, gibt die Antwort, bevor die App ihre Frage stellen konnte.

> **Jeder formt seinen Charakter durch seinen persönlichen Stil.**

Die Unterscheidung entsteht ohnehin: Wer tief in Körper steckt und
Stärke-Gewohnheiten fährt, *ist* der Kämpfer — das steht bereits in seinen Daten.
Wo eine Klasse sichtbar werden soll, wird sie **abgeleitet**, nie gewählt.

**Warum die Waffe den vierten Slot bestimmt.** `konzept.md` 3.1 fordert seit dem
ersten Tag: „Ausrüstung sollte Ressourcen beeinflussen, nicht nur Zahlen erhöhen.
Ein Ring, der Energie schneller füllt, erzeugt eine Entscheidung. +3 Angriff
nicht." Eine Waffe, die eine Fähigkeit mitbringt, ist kein Zahlenaufschlag mehr,
sondern ein Spielstil. Nebenbei entsteht ein Gold-Abfluss, ohne dass wir einen
erfinden mussten: Es lohnt sich, mehrere Waffen zu besitzen und zu wechseln.

**Warum die Streak-Fähigkeit bleibt, wenn die Kette reißt.** `konzept.md` 3.7
sagt ausdrücklich: „Verpasste Habits werden nicht bestraft — der Bonus fehlt
einfach." Und der Multiplikator wurde bei x2 gedeckelt, weil bei höherem Einsatz
„Nutzer aufgeben statt neu anzufangen" (ADR-0008). Eine Fähigkeit, die beim
Abriss verschwindet, wäre genau der Einsatz, vor dem diese Entscheidung schützen
sollte — ein Grippetag würde einen Kampf-Move kosten.

**Warum Fähigkeitspunkte umverteilbar sind.** Ohne Umverteilung wäre die freie
Wahl der drei Slots eine Falle: Wer vier Punkte in eine Fähigkeit investiert hat,
wechselt sie nie wieder, egal wie interessant die Alternative ist. Die Freiheit
stünde auf dem Papier und wäre nach zwei Wochen zugemauert.

**Warum Fähigkeiten am Abschließen eines Knotens hängen und nicht am Öffnen.**
Das ist der einzige Anreiz im ganzen Spiel, ein Thema **fertig** zu machen.
`konzept.md` warnt vor genau dem Gegenteil — halb angefangene Zweige —, und
bisher zieht nichts dagegen. Am Öffnen zu hängen würde das falsche Verhalten
belohnen: breit aufmachen, nichts zu Ende bringen.

**Warum die offenen Punkte ganz oben stehen.** Ein nicht ausgegebener
Theoriepunkt ist der stärkste Grund, die App noch einmal zu öffnen. Er gehört an
die auffälligste Stelle und zusätzlich als Zähler auf die Charakter-Kachel des
Startbildschirms.

**Warum der gesperrte vierte Slot sichtbar bleibt.** Hausregel, schon im
Startbildschirm formuliert: „Ein Startbildschirm, der nur zeigt, was schon fertig
ist, verschweigt, worum es geht."

**Warum Ausrüstung ein Raster wird.** Vier Werte plus vier Fähigkeiten plus sechs
Plätze plus Knöpfe sind vierzehn Zeilen. Als 6er-Raster braucht die Ausrüstung
ein Sechstel des Platzes, und der Bildschirm bleibt überblickbar.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Klassenwahl beim Start | Nimmt der App ihre eigene Frage vorweg; widerspricht dem Kern |
| Fester Satz von vier Fähigkeiten, nur aufwertbar | Die Slots wären Behälter, keine Entscheidung |
| Alle vier Slots frei wählbar | Die Waffe bliebe ein Zahlenaufschlag; `konzept.md` 3.1 fordert das Gegenteil |
| Streak-Fähigkeit an die laufende Kette gebunden | Bestraft verpasste Tage; widerspricht 3.7 und ADR-0008 |
| Fähigkeitspunkte fest vergeben | Macht die freie Wahl der drei Slots wertlos |
| Fähigkeit beim **Öffnen** eines Knotens | Belohnt Breite statt Abschluss — genau das Projektrisiko |
| Aussehen jetzt statt Titel | Titel kosten Zeichenketten, Aussehen kostet Grafik; gleiche Wirkung auf Identität |
| Ausrüstung auf einen eigenen Bildschirm auslagern | Widerspricht der Kommandozentrale — man will beim Einstellen alles sehen |

## Konsequenzen

**Loch 2 ist zu.** Der Charakter erstarrt nicht mehr an Tag 35: Theoriepunkte
laufen bis Level 50, Fähigkeitspunkte alle drei Level, dazu neue Fähigkeiten aus
abgeschlossenen Knoten und Streak-Marken sowie Waffen als Spielstile. `state.md`
notierte dafür bisher „der nächste Schritt ist der Dungeon mit Drops" — das
stimmt nicht mehr.

**`packages/combat` wird umgebaut.** Vier fest verdrahtete Moves werden zu einer
Zusammenstellung aus zwanzig. Die Kampflogik bleibt reines Dart ohne
Flame-Imports (ADR-0002) — daran ändert sich nichts.

**Der Laden braucht mehr Waffen.** Heute gibt es zwei. Wenn die Waffe den vierten
Slot bestimmt, sind vier bis fünf nötig, und die Preisrechnung aus ADR-0011
bekommt eine Dimension mehr: Eine Waffe kauft man künftig nicht nur für Angriff.

**Neuer Speicherinhalt:** Name, Titel, gewählte Fähigkeiten, verdiente
Fähigkeiten, gesetzte Fähigkeitspunkte. Geschrieben wird ausschließlich in
`lib/save/save_watcher.dart` (ADR-0010).

**Balance wird eine Stichprobe statt einer Rechnung.** Drei aus zwanzig plus
Waffe sind über tausend Kombinationen; `tool/balance_sim.dart` prüft heute einen
Fall. **Auf Wunsch zurückgestellt** — erst fertig bauen, dann tarieren.

**Offen:**

- Welche zwanzig Fähigkeiten es sind, was sie kosten und was sie tun.
- Der Titel-Katalog und seine Bedingungen.
- **Freunde** braucht als Einziges einen Server. Alles andere läuft offline.

**Zukunftsnotiz, keine Anforderung:** Eine Streak-Fähigkeit könnte mit der
laufenden Streak stärker werden — verdient bleibt verdient, aber die Kette
verstärkt sie. Damit hätte die Streak eine Wirkung über den XP-Multiplikator
hinaus, ohne dass ein Abriss etwas wegnimmt.
