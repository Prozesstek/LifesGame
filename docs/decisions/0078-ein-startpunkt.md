# ADR-0078: Ein Startpunkt — ein Level, ein Punkt

**Datum:** 20.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik, nach dem ersten Spiel eines Fremden
**Löst teilweise ab:** [ADR-0070](0070-das-handbuch-steht-im-baum.md) (die neun Startpunkte; alles andere dort gilt weiter)

## Kontext

Seit ADR-0070 begann jeder mit **neun** Theoriepunkten, genau so vielen,
wie der Weg der Grundlagen kostet. Die Idee: Wer nichts anderes kauft,
liest die Grundlagen am Stück, und wer die Punkte woanders ausgibt, „hat
gewählt“.

Am 19.10. hat ein Bekannter Frederiks das Spiel zum ersten Mal gespielt.
Er legte eine eigene Gewohnheit an (10 Liegestütze), hakte sie ab, stand
damit auf Level 2 und hatte **zehn Punkte**. Dann ging er in die Theorie
und las **Körper komplett** durch: Wurzel und sechs Themen, sieben
Punkte. Die Grundlagen, die erklären, wie die App gedacht ist, hat er
nie gesehen.

Das war die Wahl, die ADR-0070 erlaubt. Frederiks Einwand war ein
anderer: Ein Aufstieg bedeutete dabei nichts. Zehn Punkte auf Level 2
sagen „Punkte sind einfach da“, nicht „Punkte bekommt man fürs
Aufsteigen“.

## Entscheidung

**Zum Start gibt es einen Punkt, jeder Aufstieg bringt einen.** Auf
Level 1 hat man also einen, auf Level 2 zwei, auf Level 3 drei
(`TheoryPoints.atStart`).

## Begründung

- **Man lernt die Regel am ersten Tag.** Der eine Punkt reicht für die
  erste Seite. Ein Häkchen und diese Seite bringen zusammen genau 100
  Erfahrung (15 für das Häkchen, 30 für „Erster Schritt“, 55 für eine
  fehlerfreie Seite), also Level 2 und den Punkt für die nächste Seite.
  `progression_test.dart` hält diesen Moment fest.
- **Die erste Fähigkeit kommt nicht später als ihr Platz.** Der zweite
  Fähigkeitsplatz geht auf Level 3 auf. Dort gibt es drei Punkte, und
  genau so viel kostet der kürzeste Weg zu einer Fähigkeit (Wurzel,
  Zwischenebene, Thema, ADR-0051). Auf dem Weg der Grundlagen liegt so
  einer: Geist → Selbstentwicklung → Gedanken (Frostnebel).
- **Ein Punkt, nicht null.** Mit null Punkten stünde die Theorie am
  Anfang offen da, aber nichts darin ließe sich öffnen.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Neun lassen (ADR-0070) | Der beobachtete Fall: ein ganzes Gebiet am Stück, und ein Aufstieg bedeutet nichts. |
| Sechs Startpunkte | Claudes erster Vorschlag, die kleinste Zahl, mit der man die Grundlagen ohne Pause liest. Frederik: „nur ein Skillpunkt für Level 2“. Mit sechs wären es auf Level 2 immer noch sieben. |
| Zwei zum Start | Dann wären es auf Level 2 drei, und vom Start weg reichte es schon für eine Fähigkeit, deren Platz erst auf Level 3 aufgeht. |
| Null zum Start | Die Theorie stünde offen, aber nichts ließe sich öffnen. |

## Konsequenzen

- **Die Grundlagen liest man nicht mehr am ersten Tag.** Nach jeder
  Seite wartet die nächste auf den nächsten Aufstieg; wer nicht abhakt,
  kommt nach ein, zwei Seiten nicht weiter. Das ist gewollt: Der Punkt kommt aus
  dem Level, nicht aus dem Lesen allein. Der Baum schlägt den nächsten
  Schritt nur vor, wenn er bezahlbar ist (`nextOnPath`), und schweigt
  sonst.
- **Auf Level 3 ist kein Punkt Luft.** Wer den zweiten Platz früher
  aufgehen lässt oder einen Knoten auf den kürzesten Weg zu einer
  Fähigkeit legt, bricht `abilities_seam_test.dart`.
- **Ein Spielerleben hat 50 Punkte statt 58.** Der Baum hat 63 Knoten,
  die Knappheit aus ADR-0037 wird größer.
- **`runway_sim`, Tag 60:** Level 29 wie vorher, aber 28 gelesene Seiten
  statt 37 und 4.061 Gold statt 4.286. Weniger Seiten zahlen weniger
  Gold. Nicht ausgeglichen, wie schon das Viertel aus ADR-0072.
- **Alte Stände verlieren Punkte, aber nichts Gelesenes.** Ein Stand,
  der seine neun Startpunkte ausgegeben hat, hat jetzt acht mehr
  ausgegeben, als er verdient hat. Offenes bleibt offen (ADR-0019), die
  Anzeige steht bei null (`TheoryPoints.availableAt`), und **die
  nächsten acht Aufstiege bringen keinen freien Punkt**. Betroffen sind
  die Stände der beiden Entwickler und des einen Bekannten. Fremde gibt
  es vor dem geschlossenen Test (Ziel 9) noch keine.
- **Ein Tutorial ist damit nicht gebaut.** Frederik wünscht sich einen
  festen Weg für neue Spieler: Gewohnheit, erste Seite, erste Fähigkeit,
  Grube, erster Gegenstand. Der kommt mit eigener Konzeptrunde und baut
  auf ADR-0068 auf.
