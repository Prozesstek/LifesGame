# ADR-0099: Der Holzrahmen auf Gehrung, gemalt statt gedehnt, in vier Arten

**Datum:** 04.11.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Frederik will alle fremden Sprites durch eigene ersetzen
(`docs/vorlagen/eigene-sprites.md`). Der Rahmen um jede Karte und jeden
Dialog war ein Ausschnitt aus `UIBundleFree` (`Rahmen.png`, 71 × 67), per
`centerSlice` gedehnt: die Ecken fest, Balken und Mitte gestreckt.

Ein erster eigener Entwurf blieb beim Dehnen. Frederik: „Wieso dehnen wir es
überhaupt, kriegen wir es auch anders hin? Vllt mehr so trapez mäßig.“
Gedehnte Pixel werden breit, deshalb durfte auf den Balken keine feine
Maserung stehen.

## Entscheidung

Der Rahmen ist **gemalt** (`GehrungsMaler`, `lib/ui/gehrung.dart`): vier
Leisten als Trapeze, die in den Ecken auf 45° aneinanderstoßen, Licht von
oben links. Jeder Bildpunkt wird für die jeweilige Größe ausgerechnet; nichts
wird gedehnt.

In einer Fragerunde gewählt, alle vier Details:

| Art | Wo | Was |
|---|---|---|
| **Holz** | Alltag, ohne Angabe | Messing-Eckbeschläge (L mit zwei Nieten), Splitter, Risse, Astlöcher, Moos unten |
| **Ranken** | Theorie, Lesen, Statistik, Jahresrückblick | wie Holz, dazu Efeu aus der Ecke oben links |
| **Eisen** | Dungeon-Eingang, Ergebnis eines Laufs, Tagesdungeon, „Lauf verlassen“ | dunkleres Holz, Eisenecken, Nietreihen |
| **Messing** | Aufstieg, Errungenschaft, neue Fähigkeit, Beute, Truhe | Messing-Einlage innen, Ziernägel |

Ein Bildschirm legt `RahmenOrt(art: …)` um sich; jede `HolzKarte` darin
fragt dort. Ein Dialog liegt in einer eigenen Route und sagt seine Art selbst
(`HolzDialog(art: …)`).

## Begründung

**Malen statt dehnen** hält jedes Pixel gleich groß, bei jeder Breite. Die
Maserung darf fein sein, und die Gehrung gibt dem Rahmen Tiefe, die ein
gedehntes Bild nicht hat.

**Die Details setzt ein Zufall mit festem Startwert aus der Größe.** Jede
Karte sieht anders aus, aber bei jedem Bild gleich; kein Flackern beim
Neuzeichnen.

**Die Art sagt, wo man ist.** Ranken, Eisen und Messing nur an ihren Orten,
damit sie etwas bedeuten und der Alltag ruhig bleibt.

**Ausgerechnet wird je Größe einmal.** Eine Karte zeichnet sich bei jedem
Bild neu, wenn sie animiert (Abhaken). Der Maler merkt sich die fertigen
Flächen, höchstens 64.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Eigenes Bild, weiter gedehnt (64 × 64, Eisenecken) | Gezeigt und verworfen: gestreckte Mitte ohne Maserung, Ecken bei 1:1 zu klein |
| Kacheln statt Dehnen, aus einem Bild | Hätte die Wiederholung alle 16 Pixel gezeigt; gerechnet gibt es keine Wiederholung |
| Ein Rahmen für alles | Frederik wählte Arten je Ort |

## Konsequenzen

- `Rahmen.png` ist gelöscht, ebenso `Holz.rahmen`, `rahmenMitte` und
  `rahmenBild`.
- **Noch am selben Tag folgten die übrigen Teile** (Frederik: „alles aus
  einem Guss“): Planke, Knopf, Seil und Balken sind ebenfalls gemalt
  (`lib/ui/holz_teile.dart`), mit denselben Farben (`HolzTon`) und
  derselben Maserung. Der Knopf dreht gedrückt sein Licht um; die Rinne
  des Balkens sitzt jetzt mittig. `assets/UI/Holz/` ist ganz gelöscht —
  vom UI-Paket ist nichts mehr im Spiel.
- Die Anschlagtafel („Heute“, Dailies) malt denselben Rahmen.
- **Ein neuer Bildschirm ist Holz, solange er nichts sagt.** Wer Theorie oder
  Dungeon baut, legt `RahmenOrt` um ihn; wer einen Belohnungs-Dialog baut,
  gibt `HolzDialog` `art: RahmenArt.messing`.
- Bei 1:1 auf Karten sind die Details bewusst leise. Am deutlichsten wirken
  sie in Dialogen (doppelte Größe).
- Nicht am Handy geprüft, auch nicht, wie schnell das erste Ausrechnen auf
  einem alten Gerät ist.
