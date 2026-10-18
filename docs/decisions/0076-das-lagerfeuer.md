# ADR-0076: Das Lagerfeuer — der Tag endet an einer Stelle

**Datum:** 18.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik, in zwei Fragerunden mit Claude

## Kontext

[ADR-0071](0071-das-naechste-level.md) hat fünf Ideen festgehalten, jede
mit eigener Konzeptrunde vor dem Bau. Die erste, die Tagesgrube, steht
seit dem 11.10. ([ADR-0072](0072-die-tagesgrube.md)). Am 18.10. wählte
Frederik aus einer Liste von Vorschlägen die zweite: „Lagerfeuer find
ich cool“.

Das Lagerfeuer richtet sich **gegen die tägliche Pflicht**, die die
Durchsicht vom 02.10. als Grund zum Aufhören nennt. Bis dahin verfielen
um Mitternacht vier Dinge an drei Orten: die **Rückfrage des Tages** oben
in der Theorie, die **Truhe** und die **Tagesaufgaben** als zwei Karten
auf der Startseite (die Truhe dazu im Gewohnheiten-Bildschirm), und
sonntags und montags der **Wochenrückblick** im Charakter.

Die Fragen standen in der Vorlage
[`das-naechste-level.md`](../vorlagen/das-naechste-level.md), Abschnitt 2.

## Entscheidung

Ein **Lagerfeuer**: ein eigener Bildschirm bei Nacht, in dem Rückfrage,
Truhe, Tagesaufgaben und sonntags der Wochenrückblick an einer Stelle
liegen. Zum Schluss tippt man an, **was morgen zuerst drankommt**, und
ein Satz schickt einen weg: „Genug für heute. Leg das Handy weg.“ Es
erzeugt keine Zahl.

| Frage | Entschieden | wie empfohlen |
|---|---|---|
| Ab wann ist es da? | **Immer offen.** Ab 18 Uhr oder sobald alles erledigt ist, brennt es; vorher glimmt es nur | ja |
| Einziger Ort? | **Truhe und Aufgaben nur noch am Feuer.** Auf der Startseite wird aus zwei Karten eine; die Rückfrage steht am Feuer und bleibt zusätzlich in der Theorie | ja |
| Wann verfällt, was dort liegt? | **Um Mitternacht, wie bisher** | ja |
| Was macht „morgen zuerst“? | **Die Gewohnheit steht morgen oben in „Heute“, mit kleiner Flamme** | ja |
| Wie sieht es aus? | **Eigener Bildschirm bei Nacht**: Himmel, Sterne, ein gezeichnetes Feuer, das flackert, Funken | ja |
| Ein Begleiter am Feuer? | **Später, mit dem Haus** (Issue #88) | ja |
| Der Satz zum Schluss? | **„Genug für heute. Leg das Handy weg.“** | ja |

## Begründung

**Das Feuer sammelt, es erfindet nichts.** Keine neue Belohnung und keine
neue Regel: Was dort liegt, rechnet weiter an seiner Stelle
(`openDailyChest`, `claimDailyQuest`, `answerReview`). Deshalb verfällt
es auch weiter um Mitternacht. „Erst am nächsten Feuer“ hätte jeder
Regel, die an einem Tag hängt, eine Ausnahme gegeben.

**Immer offen, weil sonst Wartezeit entsteht.** Wer morgens alles
erledigt, soll seine Truhe nicht bis zum Abend liegen lassen müssen.
Der Abend bleibt trotzdem der Moment: Erst dann brennt es.

**Die Rückfrage an zwei Orten**, weil Lernende sie in der Theorie
erwarten, wo sie seit dem 28.09. steht (Issue #88). Es ist dieselbe
Stelle im Code, nur zweimal gezeigt.

**„Morgen zuerst“ ist ein Umsetzungsvorsatz** (Gollwitzer), der am
besten belegte einzelne Hebel der Verhaltensforschung, und passt zu
„Wann machst du das?“ ([ADR-0052](0052-ausloeser-und-startvorlage.md)).
Er ordnet nur die Tagesliste: Der Stapel der gewählten Gewohnheit steht
morgen vor allen anderen offenen, **als Ganzes**, damit kein Glied von
seinem Anker reißt ([ADR-0065](0065-gewohnheiten-koppeln.md)).

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Nur ab einer Uhrzeit offen | Wer morgens alles erledigt, wartet bis zum Abend |
| Nur offen, wenn alles erledigt ist | An Tagen, an denen man nicht alles schafft, gäbe es kein Feuer und damit auch keine Rückfrage |
| Auch die Rückfrage nur am Feuer | Ein Weg weniger zu ihr, für Lernende an der falschen Stelle |
| Zusätzlicher Weg, alles bleibt | Die Startseite bliebe so voll wie vorher; gegen die Pflicht hilft das nicht |
| Verfall erst am nächsten Feuer | Jede Regel, die an einem Tag hängt, bräuchte eine Ausnahme |
| Ein Blatt von unten statt eines Bildschirms | Fühlt sich wie ein Menü an, nicht wie ein Ort |
| Ein Begleiter schon jetzt | Er gehört zum Haus, und AktivesBrett soll ihn vorher sehen |

## Konsequenzen

- **Der Vorsatz ist ein neues Feld im Spielstand**: `HabitTracker._firstUp`,
  je Tag eine Gewohnheit, eine Historie wie die geöffneten Truhen. Eine
  Gewohnheit, die es nicht mehr gibt, fällt beim Laden heraus.
- **Truhe und Tagesaufgaben stehen nicht mehr auf der Startseite und
  nicht mehr im Gewohnheiten-Bildschirm.** Auf der Startseite zeigt die
  Karte des Feuers, was dort wartet, als Zeichen mit Zahl.
- **Wann es brennt, wird nur beim Neubau gelesen.** Steht die App um
  18 Uhr offen da, brennt es erst beim nächsten Neubau. Dafür gibt es
  keinen eigenen Takt.
- Der Wochenrückblick steht sonntags und montags am Feuer **und**
  weiter im Charakter (`WeekCard.istGross`, eine Stelle für beides).
- **Offen:** eine Erinnerung am Abend gibt es erst mit einer App
  (ADR-0071); der Begleiter kommt mit dem Haus; ein Klang des Feuers
  fehlt.
