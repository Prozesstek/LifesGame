# ADR-0056: Überblick im Wissensbaum

**Datum:** 27.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Frederik: „Bei dem Theorie-Teil weiß man schwer, wie viele der
Unterpunkte man schon gemacht hat, und generell der Überblick könnte
noch besser sein.“ Ein gerendertes Bild des Baums mit etwas Fortschritt
zeigte vier Ursachen:

1. **Grün hieß „diese Seite gelesen“, nicht „fertig“.** Eine
   Zwischenebene leuchtete grün, sobald ihre Einführung bestanden war,
   und sah fertig aus, obwohl vier von fünf Themen fehlten.
2. **Kein Zwischenstand an den Knoten** — erst beim Hineingehen, und
   dann nur für diese eine Ebene.
3. **Die Zustände unterschieden sich fast nur durch Farbe**: kaufbar, zu
   teuer, nicht erreichbar waren drei Beigetöne.
4. **Die Kopfzeile zählte, sagte aber nicht, wo**: vier Punkte zeigten
   die Seite, nicht den Stand.

## Entscheidung

1. **Ein Ring um jeden Knoten mit Unterpunkten**, dazu „2 / 5“ unter dem
   Namen. Gold erst, wenn die Seite **und** alles darunter geschafft ist.
2. **Ein Zeichen am Kreis für den Zustand**: ✓ bestanden, Buch offen, „1“
   kaufbar, Schloss mit Uhr zu teuer, Schloss unerreichbar. Dazu eine
   Legende hinter dem Fragezeichen.
3. **Vier Gebiete oben statt der Punkte**, je mit Balken und Stand;
   antippen springt hin.
4. **„Weiterlesen“**: Gibt es eine geöffnete, noch nicht gelesene Seite,
   steht sie oben, einen Tipp entfernt — erst im offenen Gebiet gesucht,
   dann überall.

## Begründung

**Grün bleibt „Seite gelesen“, der Ring sagt den Rest.** Das Grün
umzudeuten hätte jeden alten Eindruck umgeworfen; ein Ring daneben
ergänzt, statt zu ersetzen.

**Eine Wurzel zählt sich mit, eine Zwischenebene nicht.** An einer
Zwischenebene soll „2 / 5“ ihre Themen zählen, nicht ihre Einführung. Die
Wurzel ist das Gebiet selbst; oben im Balken zählt ihre Seite mit, und
unten muss dieselbe Zahl stehen. Die erste Fassung zeigte 8 / 20 oben
und 7 / 19 an der Wurzel.

**Gerechnet wird im Package** (`TheoryProgress.progressBelow`,
`nextToRead`), nicht im Bildschirm. Bis hierhin zählte der Bildschirm
das Gebiet selbst (`_passedIn`); mit Ring, Balken und „Weiterlesen“
wären es drei Stellen geworden.

**Die Legende zeigt dieselben Zeichen** (`NodeStateBadge`), keine
zweite Zeichnung.

**„Weiterlesen“ nimmt die Wahl nicht weg.** Der Baum bleibt eine
Entscheidung (ADR-0037); wer nicht wählen will, muss es nicht.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Grün erst bei „alles darunter“ | Deutet eine eingeübte Farbe um; eine gelesene Seite sähe ungelesen aus |
| Eine Listenansicht als Umschalter | Größter Umbau; erst prüfen, ob Ring und Balken reichen |
| Der Zähler im Kreis statt darunter | Verdrängt das Symbol, an dem man den Knoten erkennt |
| Das Fragezeichen als `IconButton` | Das Theme macht daraus eine Holzplanke, die wie der Hauptknopf aussieht |

## Konsequenzen

- Ein Knoten mit zwei Eltern (Stress, Vergleich) zählt in beiden
  Gebieten mit, wie schon vorher in der Kopfzeile.
- Angekündigte Überschriften zählen nirgends mit; ein neues Gebiet lässt
  die Zahlen wachsen, sobald es befüllt ist.
- Die Kopfzeile ist höher geworden; der Baum darunter hatte oben ohnehin
  leeren Platz.
