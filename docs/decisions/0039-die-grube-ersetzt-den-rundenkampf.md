# ADR-0039: Die Grube ersetzt den Rundenkampf

**Datum:** 21.09.2026
**Status:** Aktiv
**Entschieden von:** Prozesstek (Issue #65, „wir haben uns für die Grube als Kampf entschieden“)

## Kontext

Am 20.09. entstand `packages/action_combat` als Prototyp: ein
Echtzeit-Kampf in einer Halle voller Gegner, neben dem Rundenkampf und
nur im Entwicklermodus erreichbar. Ausgelöst hat ihn ein Befund der
Simulation, nicht ein Geschmack: Der schwächste Gegner der Reihe braucht
auch nach zwei Monaten noch sieben Runden. `state.md` hielt damals fest,
dass zwei Fragen offen sind und beide in einen ADR gehören, bevor
weitergebaut wird: **die Richtung** und **die Potenz-Kurve**.

Die Richtung ist jetzt entschieden. Issue
[#65](https://github.com/Prozesstek/LifesGame/issues/65) sagt es in einem
Satz: „Das aktuelle Kampfsystem durch die Grube ersetzen." Dazu kommen
Vorgaben für später: Fähigkeiten über Mana und Abklingzeit, mit Effekten,
die Sets und Legendäre leicht verändern können; eine Halle, die sich bei
jedem Lauf ändert; ein Dungeon mit einem gut gestalteten Endgegner.

**Das Problem daran war nicht die Grube, sondern alles, was am alten
Kampf hängt.** Er ist in 23 Dateien der App verdrahtet. Drei Nähte
tragen dabei mehr als der Kampf selbst:

- Die **30 Sprossen** der Reihe. An ihnen hängen die Sperren für Episch
  und Legendär (ADR-0034), die Errungenschaften „höchste Sprosse" und
  „der Unbeugsame" (ADR-0033) und die einmalige Belohnung in den vier
  Kurven (ADR-0032).
- Die **Fähigkeiten** (ADR-0017, ADR-0022). Ihre Wirkung steht in
  `package:combat`, ihre Freischaltung in `package:abilities`: Knoten im
  Baum, Streak-Marken, Errungenschaften.
- **Waffen und Sets** (ADR-0029, ADR-0030) wirken auf Züge, und Züge gibt
  es in Echtzeit nicht.

## Entscheidung

**Die Grube ist der Kampf des Spiels.** Der Kampf-Kreis auf dem
Startbildschirm führt ab sofort in sie; der Rundenkampf ist nicht mehr
erreichbar und wird gelöscht, sobald nichts mehr an `package:combat`
hängt. Vier Einzelentscheidungen, alle am 21.09. getroffen:

1. **Aus den 30 Sprossen werden 30 Stufen der Grube.** Eine Grube,
   dreissig Schwierigkeitsstufen. Die erste Räumung einer Stufe zahlt
   einmal aus. `LadderProgress` bleibt dabei unverändert (höchste Stufe
   plus Niederlagen je Stufe), und damit auch Laden-Sperren,
   Errungenschaften und Kurven.
2. **Die Hallen entstehen aus Raumbausteinen.** Handgezeichnete Räume
   (`RoomCatalog`) werden je Lauf zufällig, aber **gesät**
   zusammengesteckt (`LevelBuilder`). Der Wächterraum ist immer der
   letzte. Derselbe Startwert ergibt dieselbe Karte.
3. **Die Fähigkeiten behalten Id, Icon und Freischaltung.** Nur die
   Wirkung wird für Echtzeit neu gebaut: Mana und Abklingzeit statt
   Energie und Timing-Leiste. Eingebaut wird nach und nach, wie #65 es
   verlangt. Der Energiewert des Charakters wird dabei zu Mana.
4. **Sofort ersetzen, später löschen.** Kein Parallelbetrieb.

## Begründung

**Zu 1.** Eine Reihe mit dreissig Zahlen ist genau das, was die
Laden-Sperren, zwei Errungenschaften und die Belohnung brauchen, und
wofür Issue #36 sie wollte: „17 / 30" gegen „21 / 30". Hinge das an
einem einzigen Dungeon, müsste man drei ADRs nacharbeiten, um am Ende
wieder eine Zahl zu zählen. So heisst die Zahl nur anders.

**Zu 2.** Eine feste Halle ist nach einer Woche auswendig gelernt, und
Ziel 7 verlangt dreissig Tage. Voll prozedurale Hallen haben keine Räume
mit Charakter und sind schwer abzustimmen. Bausteine haben beides: Ein
Raum wird geschrieben wie eine Lektion, die Reihenfolge würfelt. Gesät
ist die Karte aus demselben Grund wie die Welt (ADR-0002): Nur so lässt
sich eine Stufe ohne Bildschirm durchspielen. `tool/pit_sim.dart` tut
genau das.

**Zu 3.** Mit den Ids bleiben der Baum, die Streak-Marken und vier
Errungenschaften unverändert gültig. Ein neuer Satz Fähigkeiten hätte
alle drei Quellen neu verteilen müssen, und jeder Spielstand hätte seine
Auswahl verloren (ADR-0024). Die Wirkung *muss* dagegen neu gebaut
werden: Eine Timing-Leiste gibt es in Echtzeit nicht.

**Zu 4.** Die Grube parallel im Entwicklermodus zu lassen hiesse, dreissig
Tage lang den Kampf zu testen, den wir ersetzen wollen.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Ein einziger Dungeon ohne Stufen | Die Sperren, zwei Errungenschaften und die Belohnung verlören ihre Zahl. Drei ADRs zum Nacharbeiten, für dasselbe Ergebnis. |
| Stockwerke in *einem* Lauf (Diablo-Rift) | Eine neue Mechanik, und die Frage, ob zwischen Stockwerken geheilt wird, ist offen. Kann später aus den Stufen werden. |
| Voll prozedurale Hallen | Räume ohne Charakter, und schwer abzustimmen. |
| Neuer Fähigkeiten-Satz nur für die Grube | Freischaltung neu verteilen, und Spielstände verlören ihre Auswahl. |
| Parallelbetrieb bis zur Fertigstellung | Der Testlauf läuft auf dem Kampf, der ersetzt wird. |

## Konsequenzen

**Was gebaut ist (Schritt 1, dieser ADR):**

- `PitStage`: Faktor auf Leben und Angriff, Zuschlag auf Verteidigung,
  Räume vor dem Wächter. Die Zahlen stehen in `ActionBalance`
- `RoomCatalog` mit sieben Räumen, einem Startraum und zwei
  Wächterräumen; `LevelBuilder` steckt sie auf einem 4 × 4-Raster
  zusammen. `level_builder_test.dart` baut **jede Stufe mit vierzig
  Startwerten** und prüft jede Karte mit `Level.problems`
- `PitBot` liegt im Package statt im Beispiel, weil ihn jetzt zwei
  Stellen brauchen
- `PitScreen` spielt eine Stufe mit den echten Werten und trägt das
  Ergebnis über `LadderController.recordRun` ein
- Der Eingang (`LadderScreen`) zeigt „N / 30", die Stufe und die
  Belohnung statt eines Gegners
- `PitRunView` ist die eine Stelle für Spielfeld, Steuerung und
  Kopfzeile; der Prototyp im Entwicklermodus benutzt sie mit

**Was die Simulation sagt** (`dart run tool/pit_sim.dart 10`, Siegquote
des Bots):

| | Tag 0 | Tag 14 | Tag 30 | Tag 60 + bestes Gear |
|---|---|---|---|---|
| Stufe 1 | 70 % | 100 % | 100 % | 100 % |
| Stufe 5 | 20 % | 100 % | 100 % | 100 % |
| Stufe 10 | 0 % | 40 % | 100 % | 90 % |
| Stufe 15 | 0 % | 0 % | 60 % | 100 % |
| Stufe 20 | 0 % | 0 % | 0 % | 100 % |
| Stufe 30 | 0 % | 0 % | 0 % | 20 % |

Zum Vergleich die alte Reihe: Tag 30 ohne Ausrüstung stand auf
Sprosse 10 bei 27 %, Tag 60 voll ausgerüstet auf Sprosse 30 bei 62 %.
Die Grube ist unten etwas gnädiger und oben härter.

Der Bot weicht keinem Pfeil aus und benutzt nur zwei Knöpfe, die Zahlen sind also eine **untere** Schranke. Die
Stufenkurve ist nicht fein abgestimmt; das geschieht, wenn die
Fähigkeiten drin sind, die sie verschieben werden.

**Was bis zu den nächsten Schritten nicht wirkt, und das ist die
unangenehme Folge:**

- **Fähigkeiten.** In der Grube gibt es heute nur Sturmschritt und
  Rundumschlag. Die fünfzehn Fähigkeiten auf den Plätzen tun dort
  nichts, bis sie umgebaut sind.
- **Waffen und Sets.** Die Waffe zählt nur mit ihren Werten, ihr Zug
  nicht. Die drei Sets wirken gar nicht.
- **Die Sperre vor dem Kampf** (ADR-0020, ADR-0025) bleibt, obwohl ihr
  Grund weggefallen ist: Sie stand da, weil der Rundenkampf mit einem Zug
  unschlagbar war. In der Grube ist Stufe 1 mit den Werten von Tag 0
  schlagbar. Ob die Kette Handbuch → Baum → Fähigkeit → Kampf bleiben
  soll, entscheidet sich, wenn die Fähigkeiten wirken. Vorher sperrte
  eine Aufhebung nichts auf, was sich lohnt.

**Weiter offen:**

- **Die Potenz-Kurve.** Soll Macht vervielfachen statt addieren? Das
  berührt ADR-0008 und die vier Kurven und ist nicht Teil dieses ADR.
  Mana, Abklingzeiten und Set-Effekte sind die naheliegende Stelle für
  vervielfachende Macht, ohne die Werte-Kurve anzufassen.
- **Der Endgegner.** #65 will ihn „cool designt". Heute ist er ein
  grösserer Nahkämpfer in einem von zwei Wächterräumen.
- **`package:combat` löschen.** `LadderProgress` und `LadderRewards`
  wohnen noch dort und ziehen um, bevor es geht.

**Die nächsten Schritte, in dieser Reihenfolge:**

1. Mana als Ressource, Fähigkeiten als Katalog in `action_combat`
   (Schaden, Heilung, Werte ändern, Fläche), die ersten drei davon
2. Die übrigen Fähigkeiten nach und nach, dazu Waffe = Grundangriff
3. Sets und Legendäre als Veränderung einer Fähigkeit
4. Der Endgegner mit eigenen Angriffen
5. `package:combat` auflösen: Reihe und Belohnung umziehen, Rest löschen
