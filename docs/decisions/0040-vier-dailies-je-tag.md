# ADR-0040: Vier Stufen des Tages zahlen noch einmal — gedeckelt und nur mit Häkchen

**Datum:** 22.09.2026
**Status:** Aktiv — ergänzt ADR-0032 (dort: Belohnung genau einmal je Stufe)
**Entschieden von:** Prozesstek

## Kontext

Frederik: „4 random Dungeonstufen pro Tag können nochmal für Gold und XP
gespielt werden. Ähnlich wie bei Guild Wars 2 Fraktale der Nebel
Dailies."

Das berührt eine Grenze, die bewusst gezogen war. ADR-0032 lässt den
Kampf zahlen, aber **genau einmal je Stufe**; `konzept.md` Abschnitt 2
macht ihn zur *Auszahlung* des Fortschritts, nicht zu seiner Quelle.
Der Einwand dort galt ausdrücklich *wiederholbarer* Belohnung: Wer Kämpfe
grinden kann, braucht keine Gewohnheiten.

Dazu die Zahlen: Eine Stufe zahlt beim ersten Sieg 20 bis 165 Erfahrung
und 8 bis 66 Gold. Ein Tag mit fünf Häkchen bringt 75 bis 150 Erfahrung
und 25 Gold — und auf diese 25 Gold ist der Laden ausgelegt
(`package:gear`). Vier Dailies zum vollen Betrag um Stufe 15 brächten
rund 360 Erfahrung und 144 Gold am Tag: fast sechsmal das Gold der
Gewohnheiten.

## Entscheidung

Jeden Tag gibt es vier Stufen des Tages. Jede zahlt **einmal am Tag ein
Viertel** ihres Erstsieg-Betrags — aber **nur an Tagen mit mindestens
einem Häkchen**. Gewürfelt wird aus dem Datum, aus dem, was man geschafft
hat: eine leichte, zwei mittlere, eine von ganz oben. Die vier werden für
den Tag eingefroren, sobald sie zum ersten Mal gebraucht werden.

## Begründung

**Gedeckelt ist nicht grindbar.** Der Einwand aus ADR-0032 trifft
Belohnung ohne Obergrenze. Vier am Tag sind eine Obergrenze — dieselbe
Bauform wie die Gewohnheiten, die auch nur einmal am Tag zahlen.

**Ein Viertel hält die Grössenordnung.** Um Stufe 15 sind es rund 90
Erfahrung und 36 Gold am Tag, also etwa ein Tag Gewohnheiten, nicht ein
Vielfaches. Ganz oben (vier Stufen um 30) höchstens 158 Erfahrung und
64 Gold (`LadderRewards.maxDailyXpPerDay`, `maxDailyGoldPerDay`).

**Die Häkchen-Bedingung hält die Richtung.** Der Kampf zahlt nur an
Tagen, an denen die Gewohnheit schon stattgefunden hat — er bleibt die
Auszahlung. Wer nichts abhakt, darf trotzdem spielen; es bringt nur
nichts ein.

**Aus dem Datum, für beide gleich.** Wer gleich weit ist, spielt am
selben Tag dieselben vier. Ziel 7 lebt davon, dass zwei Spieler etwas zu
vergleichen haben. Gewürfelt wird mit einem eigenen Park-Miller-Würfel
statt `dart:math`, dessen Folge zwischen Browser und Android nicht
zugesagt ist.

**Eingefroren, weil sie am Fortschritt hängen.** Wer mittags eine neue
Stufe schafft, verschöbe sonst die Bänder und hätte plötzlich andere
vier vor sich — halb erledigt, halb neu.

**Eine Historie, kein Kontostand.** Gespeichert wird, welche Stufe an
welchem Tag als Daily geschafft wurde (`LadderProgress.dailyClears`);
Erfahrung und Gold werden daraus gerechnet, wie bei Häkchen und
Verkäufen (ADR-0008, ADR-0031).

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Voller Erstsieg-Betrag | Fast sechsmal das Gold eines Gewohnheitstags — der Kampf würde zur Hauptquelle, der Laden in Wochen leer gekauft |
| Nur Gold, keine Erfahrung | Frederik wollte beides; und Erfahrung ist über die Levelkurve ohnehin gedeckelter als Gold |
| Ohne Häkchen-Bedingung | Dann ersetzt der Kampf an faulen Tagen die Gewohnheit — genau der Fall aus `konzept.md` Abschnitt 2 |
| Vier feste Stufen 1–30 für alle | Ein Spieler auf Stufe 6 hätte meist kein einziges spielbares Daily |
| Beliebig wiederholbar, mit abnehmendem Ertrag | Grinden mit Umweg; und schwer zu erklären |

## Konsequenzen

- **Die vier Kurven bekommen einen fünften Zufluss.** Über 30 Tage
  bringen die Dailies grob so viel Gold wie die Gewohnheiten. Der Laden
  leert sich damit schneller als in `test/progression_test.dart`
  angenommen — **dort nicht nachgerechnet**; die Obergrenze je Tag steht
  aber als Zahl im Package und ist getestet.
- Wer an einem Tag nichts abhakt und spielt, sieht „erst ein Häkchen
  setzen". Das ist eine Sperre mit Grund, keine ohne.
- Der Spielstand wächst um einen Eintrag je Tag. Bei dreissig Tagen
  unerheblich; bei Jahren wäre es eine Liste, die man zusammenfassen
  könnte, ohne die Rechnung zu ändern.
- Zwei Spieler auf **verschiedenen** Stufen haben verschiedene vier —
  gleich sind nur die relativen Plätze. Wer vergleichen will, vergleicht,
  wie viele von vier.
