# ADR-0053: „Heute" auf der Startseite

**Datum:** 27.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Aus derselben Durchsicht wie [ADR-0052](0052-ausloeser-und-startvorlage.md):
Das Häkchen ist die eine Handlung, die jeden Tag passieren soll. Auf der
Startseite war es einer von sechs gleich großen Kreisen, neben Laden,
Kampf und Fähigkeiten, und kostete immer einen Tipp plus einen
Bildschirmwechsel. Der Auslöser aus ADR-0052 sagt jetzt *wann*; in dem
Moment soll das Abhaken ein Tipp sein.

## Entscheidung

**Zwischen Figur und unterer Kreisreihe steht eine Karte „Heute"** mit
den offenen Gewohnheiten und ihrem Auslöser. Ein Tipp auf eine Zeile
hakt ab. Erledigtes schrumpft auf eine Zeile („2 erledigt“); ist alles
erledigt, weist die Karte auf die Tagestruhe. Kopf und Hinweise führen
zum Gewohnheiten-Bildschirm.

**Abgehakt wird über eine Stelle** (`lib/habits/habit_check_flow.dart`):
Klang, Stoß, Feiern, aufsteigende Zahlen und die Leiste unten, gleich
für Startseite und Gewohnheiten-Bildschirm.

## Begründung

**Die Figur gibt Platz ab, nicht die Kreise.** Die Startseite scrollt
nicht (seit Issue #35), und die Figur ist das einzige, das mit dem Platz
wächst. Mit fünf offenen Gewohnheiten wird sie kleiner, bleibt aber
erkennbar; mit jedem Häkchen bekommt sie Platz zurück. Das ist ein
schöner Nebeneffekt: Die Figur wächst, je mehr erledigt ist.

**Nur, was offen ist.** Fünf abgehakte Zeilen verlangten nichts mehr und
nähmen der Figur Platz. Eine Zeile „erledigt" hält den Fortschritt
sichtbar, ohne ihn auszubreiten.

**Ein Tipp hakt ganz ab, auch bei einem Tagesziel.** Das ist dieselbe
Geste wie auf der Kachel. Schrittweises Füllen, Auslöser ändern und
Vorlagen starten bleiben auf dem Gewohnheiten-Bildschirm; die Karte ist
für den Moment, nicht für die Verwaltung.

**Eine Stelle für den Ablauf.** Das Abhaken hängt an fünf Folgen
(Errungenschaften, Aufstieg, Fähigkeiten, Schlüssel, Tagesform). Eine
zweite Kopie für die Startseite wäre der Fall aus `gotchas.md`, bei dem
zwei Stellen dieselbe Frage verschieden beantworten.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Die Gewohnheiten als größter Kreis | Bleibt ein Tipp plus Bildschirmwechsel |
| Alle Gewohnheiten zeigen, erledigte durchgestrichen | Fünf Zeilen, die nichts mehr verlangen, auf Kosten der Figur |
| Die Truhe direkt auf der Startseite öffnen | Braucht die Enthüllung des Gewohnheiten-Bildschirms ein zweites Mal; ein Tipp führt hin |
| Das Plus für Tagesziele auch auf der Karte | Zwei Griffe je Zeile auf engem Raum; die Kachel hat Platz dafür |

## Konsequenzen

- Die Figur ist an vollen Tagen deutlich kleiner. Gemessen am
  gerenderten Bild bei 390 × 844: rund 80 Punkte hoch bei fünf offenen
  Gewohnheiten, rund 110 bei drei. Ob das am Handy noch trägt, ist die
  offene Frage dieser Entscheidung.
- Der Kreis „Gewohnheiten" samt Ring bleibt. Er ist jetzt der Weg zur
  Verwaltung, die Karte der zum Abhaken.
- Wer den Ablauf eines Häkchens ändert, ändert ihn für beide Orte.
