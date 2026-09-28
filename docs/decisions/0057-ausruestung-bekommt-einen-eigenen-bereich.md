# ADR-0057: Die Ausrüstung bekommt einen eigenen Bereich

**Datum:** 28.09.2026
**Status:** Aktiv
**Entschieden von:** AktivesBrett
**Ergänzt:** [ADR-0049](0049-faehigkeiten-bekommen-einen-eigenen-bereich.md)
(dasselbe für die Ausrüstung), [ADR-0013](0013-charakter-als-kommandozentrale.md)
(die Plätze ziehen aus dem Charakter aus)

## Kontext

Der Wunsch: ein Ausrüstungsfenster, das dem Fähigkeiten-Bildschirm
ähnelt: sechs Plätze oben, alle Stücke darunter, gruppierbar, mit
Popup, und die Ausrüstung raus aus dem Charakter.

Was es dafür gab, lag an drei Stellen verteilt. Im **Charakter** standen
die sechs Plätze und die Set-Karte. Im **Laden** unter „Heute" die sechs
Angebote des Tages, unter „Inventar" jedes eigene Exemplar, je Platz ein
Reiter. **Den Katalog selbst** (48 Stücke) sah man nirgends: Was es noch
zu holen gibt, war nicht zu erfahren, außer es lag zufällig heute im
Laden.

Seit [ADR-0048](0048-exemplare-tagesladen-und-beute.md) besitzt man
außerdem **Exemplare**: Dasselbe Stück kann man mehrmals haben, jedes
mit eigenem Wurf.

## Entscheidung

Die Ausrüstung bekommt einen eigenen Bildschirm mit eigenem Kreis auf
der Startseite, gebaut wie der Fähigkeiten-Bildschirm:

1. **Oben die sechs Plätze**, darunter die Set-Karte, wenn etwas
   anliegt. **Antippen eines belegten Platzes öffnet das Blatt mit den
   Werten** des angelegten Stücks, ein leerer Platz sagt, wie er sich
   füllt. Das Auswahlblatt, das bis dahin am Platz hing, gibt es nicht
   mehr.
2. **Gewechselt wird per Ziehen, wie beim Deckbau in Clash Royale.** Ein
   besessenes Stück im Katalog kurz gedrückt halten, der Bildschirm
   rollt nach oben zu den Plätzen, der passende Platz leuchtet, die
   anderen treten zurück. Loslassen darüber legt es an, auf einem
   falschen Platz fliegt es zurück. Hat man es mehrfach, kommt das
   **beste Exemplar** drauf (`Loadout.bestCopyOf`, der höchste Wurf); ein
   bestimmtes anderes legt man im Blatt einzeln an.
3. **Darunter der ganze Katalog**, jedes Stück einmal: besessene farbig,
   der Rest grau, gesperrte (Episch/Legendär vor ihrer Stufe) mit
   Schloss, mehrfach besessene mit „×2".
4. **Vier Ordnungen**: A–Z (Standard), nach Platz, nach Seltenheit, nach
   Set. Die Wahl gehört zur Ansicht, nicht zum Spielstand.
5. **Antippen öffnet ein Blatt** mit allem, was es über das Stück gibt:
   Grundwerte, Wurfspanne, was die Seltenheit im Kampf vervielfacht,
   Kampfwirkung (Waffenzug, legendäre Kraft), Set mit beiden Stufen,
   Preis, Verkaufserlös, und woher es kommt. Darunter **jedes eigene
   Exemplar** mit seinem Wurf gegen das Getragene, und je Exemplar
   Anlegen, Ablegen und Verkaufen.
6. **Im Charakter** bleiben die Werte mit ihrer Herkunft; statt der
   Plätze steht dort ein Knopf „Zur Ausrüstung".
7. **Das Inventar im Laden bleibt**, unangetastet.

## Begründung

**Der Katalog und nicht das Inventar**, aus demselben Grund wie bei den
Fähigkeiten: Ein Ziel, das man nicht sieht, ist keins. Das Inventar
zeigt nur, was man hat, und das gibt es im Laden schon. Die Exemplare
gehen dabei nicht verloren, sie stehen im Blatt, eines unter dem
anderen, weil man sie genau dort vergleichen will.

**A–Z als Standard** auf ausdrücklichen Wunsch: „damit man alle Items
einfach so sehen kann." Sortiert wird nach deutschem Alphabet
(`sortKey`), sonst stünde „Übungsklinge" hinter „Zweihänder".

**Ziehen statt Auswahlblatt**, auf ausdrücklichen Wunsch nach dem
ersten Ansehen: Ein Tipp auf ein angelegtes Stück soll zeigen, was es
kann, nicht eine Liste zum Wechseln. Ziehen macht dazu sichtbar, *wohin*
etwas gehört, bevor man loslässt. **Halten, nicht sofort ziehen**, damit
Rollen und Antippen bleiben, wie sie waren. Und die Fläche ist kein
`ListView` mehr, sondern hält alle 48 Kacheln gebaut: Eine ListView
verwirft beim Hochrollen die Kachel, von der gezogen wird.

**Verkaufen auch hier**, obwohl der Laden es schon kann: Wer im Blatt
zwei Würfe desselben Stücks nebeneinander sieht, will den schlechteren
dort loswerden und nicht erst den Bildschirm wechseln.

**Die Kreise der unteren Reihe werden kleiner** (64 statt 72 Punkte).
Vier Kreise mit Namen brauchen bei 72 Punkten 352 Punkte Breite, ein
Handy hat nach dem Rand 335. `HubCircle` hat dafür eine Größe bekommen,
Zeichen und Symbol schrumpfen mit.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Nur die eigenen Exemplare im Raster | Das ist das Inventar im Laden ein zweites Mal, und der Katalog bliebe unsichtbar |
| Umschalter „Meine / Alle" | Zwei Ansichten für eine Frage; die Exemplare stehen ohnehin im Blatt |
| Inventar aus dem Laden nehmen | Greift in Frederiks Laden ein; gewünscht war, dass er bleibt |
| Oben vier Kreise, unten drei | Dann wären die Kreise für Gewohnheiten und Theorie, die täglichen, die kleineren |
| Das Auswahlblatt am Platz behalten | War die erste Fassung; ein Tipp auf ein angelegtes Stück sollte seine Werte zeigen, nicht eine Liste |
| Beim Ziehen fragen, welches Exemplar | Ein Dialog mitten im Ziehen bricht die Geste; wer ein bestimmtes will, legt es im Blatt an |
| Ziehen ohne Halten | Dann ließe sich die Fläche nicht mehr rollen, ohne versehentlich ein Stück mitzunehmen |
| Ein neu gezeichnetes Zeichen für den Kreis | Der Plattenharnisch aus dem Laden sitzt mittig und sagt „Ausrüstung", ohne Zeichenarbeit |

## Konsequenzen

**Leichter:** Alle 48 Stücke sind zum ersten Mal an einer Stelle zu
sehen, samt dem, was sie im Kampf tun. Doppelte Exemplare lassen sich
dort vergleichen, wo sie zusammen stehen. Der Charakter wird noch einmal
kürzer und ist jetzt, was sein Kommentar schon immer sagte: Werte und
ihre Herkunft.

**Schwerer:** Sieben Kreise auf der Startseite, unten kleiner als oben.

**Zwei Verkaufswege.** `sellWithConfirm` in `lib/gear/sell_flow.dart`
und `ShopScreen._sell` tun dasselbe, weil der Laden nicht angefasst
werden sollte. Wer an einem dreht, sieht beim anderen nach; auf Dauer
gehört der Laden auf `sellWithConfirm` umgestellt.

**Das Grau hat jetzt eine Stelle** (`lib/ui/ausgegraut.dart`) für
Fähigkeiten und Ausrüstung. Vorher stand es im Fähigkeiten-Bildschirm.

**Offen:**

- **Nicht am Handy angesehen.** Die Layouts laufen bei 390 × 844 ohne
  Überlauf; ob 48 Kacheln mit zweizeiligen Namen („Krone des
  Hochwächters") lesbar bleiben, sagt ein Gerät.
- **Das Ziehen ist nur im Test gelaufen**, nicht mit einem Finger. Ob
  die Haltezeit (Flutters Standard, eine halbe Sekunde) sich richtig
  anfühlt und das Hochrollen nicht zu schnell ist, sagt ein Gerät.
- **Kaufen geht hier nicht.** Das Blatt sagt, wenn ein Stück heute im
  Laden liegt, führt aber nicht direkt zum Angebot.
