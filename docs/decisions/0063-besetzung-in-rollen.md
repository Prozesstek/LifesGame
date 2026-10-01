# ADR-0063: Die Besetzung spielt Rollen, die der Raum schreibt

**Datum:** 01.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik (Richtung), Claude (Ausgestaltung)

## Kontext

[ADR-0062](0062-waechter-und-besetzung-werden-gewuerfelt.md) hat drei
Dinge entschieden und das erste gebaut, die Wächter. Offen waren: fünf
neue Gegnerarten aus den übrigen Sprites, und dass **jede Grube eine
Besetzung** bekommt, gezogen je Lauf, auf jeder Stufe aus demselben Topf.

Offen war damit auch, *wie* eine Besetzung in eine Grube kommt. Die Räume
im Katalog sind von Hand geschrieben, mit festen Zeichen je Art; würfelte
man jeden Platz frei, wäre ihre Bauform (das Schützennest, das Nest der
Kobolde) verloren.

## Entscheidung

**Die Räume schreiben weiter Rollen, die Besetzung sagt, wer sie
spielt.** Ein Raum bleibt, was er ist; ausgetauscht wird, wer auf seinen
Plätzen steht.

| Rolle im Raum | Wer sie spielen kann |
|---|---|
| `e`, wer heranläuft | Fussvolk — und auf der Hälfte der Plätze Schleim, Grimlock oder niemand sonst |
| `s`, wer schiesst | Schütze oder Wächterauge |
| `k` und `f`, das Rudel | Kobold oder Fledermaus |
| in jedem zweiten Raum einer, auf einem Platz des Fussvolks | Kreischpilz oder Sporenpilz |

Das sind 3 × 2 × 2 × 2 = 24 Besetzungen. Troll und Wächter gehören nicht
dazu.

### Die fünf neuen Arten

Jede hat einen Grund, wie die sechs davor (`EnemyKind`):

| Art | Was sie tut | Der Grund für … |
|---|---|---|
| Schleim | langsam; zerfällt beim Tod in zwei schnelle Schleimlinge | … Flächenschaden |
| Grimlock | blind: bemerkt den Helden erst auf 70 statt 210 Punkte, schlägt anderthalbmal so hart | … hinzusehen, wohin man läuft |
| Kreischpilz | steht und schlägt nicht; kündigt 1,6 Sekunden lang einen Schrei an, der einen Raum weit alle weckt, auch durch Wände | … ihn zuerst zu fällen |
| Sporenpilz | hält Abstand, heilt alle 2,5 Sekunden Verletzte in seiner Nähe um 12 % ihres Lebens | … die Reihenfolge der Ziele |
| Wächterauge | hält Abstand; lädt 0,9 Sekunden einen Strahl auf, der dann die ganze Linie trifft | … den Schritt zur Seite |

## Begründung

**Das Fussvolk bleibt immer dabei.** Der Grimlock ist blind. Eine Grube
nur aus Grimlocks liesse sich bis zum Wächter durchschleichen, und der
zahlt beim Fallen den ganzen Topf (ADR-0041). Deshalb teilt sich der
zweite Nahkämpfer die Plätze mit dem Fussvolk, statt es zu ersetzen.

**Ersetzen, nicht dazustellen.** Wie beim Troll hängt die Zahl der
Gegner weiter nur an den Räumen. Die Uhr (ADR-0046) und der Topf sind an
dieser Zahl gemessen.

**Was im Lauf entsteht, zahlt nichts.** Die Schleimlinge zählen als
Gegner, damit „12 / 14 erledigt“ stimmt, aber nicht für den Topf, und sie
lassen keine Kugel fallen. Sonst wäre ein Schleim drei Gegner wert.

**Heilung ist ein Anteil des Lebens des Geheilten**, und kein Sporenpilz
heilt sich selbst, einen anderen Sporenpilz oder den Wächter. Heilung,
die mit dem Leben wuchs, hat im Rundenkampf einmal keinen Kampf mehr
enden lassen (`gotchas.md`). Hier ist sie so bemessen, dass ein frischer
Held einen Troll mehr als doppelt so schnell abträgt, wie ein Pilz ihn
heilt; `cast_enemies_test.dart` rechnet das nach.

**Ein Schrei ist keine Ankündigung.** `ActionWorld.telegraphs` enthält,
woraus man hinauslaufen muss, und der Bot tut genau das. Aus einem Schrei
läuft man nicht hinaus, man fällt den Pilz vorher. Er steht deshalb in
`ActionWorld.alarms` und ist im Bild gold statt rot. Der Strahl des
Wächterauges dagegen ist eine Ankündigung wie die des Wächters und wird
auch so gezeichnet.

**Eigene Würfel.** Die Besetzung zieht aus einem eigenen Generator, die
einzelnen Plätze aus einem zweiten. Die Karte zu einem Startwert ist
dieselbe wie vorher; `cast_test.dart` hält das fest.

## Gemessen

`dart run tool/pit_sim.dart 30`, neue Tabelle „Je Besetzung“: eine Rolle
fest, der Rest gewürfelt. Der Bot ist dumm, die Zahlen sind eine untere
Schranke.

| | Stufe 1, Tag 0 | Stufe 2, Tag 0 | Stufe 11, Tag 30 mit Fähigkeiten | Stufe 30, Tag 60 voll |
|---|---|---|---|---|
| **alles gewürfelt** | 93 % | 63 % | 80 % | 60 % |
| neben dem Fussvolk: niemand | 100 % | 67 % | 93 % | 67 % |
| neben dem Fussvolk: Schleim | 90 % | 57 % | 77 % | 53 % |
| neben dem Fussvolk: Grimlock | 97 % | 50 % | 87 % | 50 % |
| schiesst: Schütze | 93 % | 60 % | 87 % | 60 % |
| schiesst: Wächterauge | 100 % | 60 % | 90 % | 57 % |
| Rudel: Kobold | 93 % | 60 % | 90 % | 60 % |
| Rudel: Fledermaus | 93 % | 67 % | 80 % | 57 % |
| Sondergegner: niemand | 100 % | 63 % | 90 % | 57 % |
| Sondergegner: Kreischpilz | 90 % | 67 % | 90 % | 70 % |
| Sondergegner: Sporenpilz | 97 % | 63 % | 83 % | 67 % |

Vor diesem Schritt, nur mit gewürfelten Wächtern (ADR-0062, 24 Läufe):
92 %, 58 %, 88 %, 71 %. Die Besetzung hat die Grube im Ganzen kaum
härter gemacht; keine Art fällt aus der Reihe. Schleim und Grimlock
kosten am meisten, je etwa zehn bis fünfzehn Punkte gegenüber Fussvolk
allein. Nach der ersten Messung (Stufe 30: 45 %) wurden Grimlock (58 →
50 Leben, 15 → 14 Angriff) und Schleim (30 → 26 Leben) leicht
zurückgenommen.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Jeden Platz einzeln würfeln | Frederik: jede Grube soll ihre Besetzung haben. Und die Bauform der Räume ginge verloren. |
| Neue Arten kommen mit der Tiefe dazu | Frederik: alles ab Stufe 1 |
| Der zweite Nahkämpfer ersetzt das Fussvolk ganz | eine Grube nur aus Grimlocks wäre ein Spaziergang zum Wächter |
| Der Schrei als rote Ankündigung | Rot heisst „lauf hinaus“; hier wäre das die falsche Antwort |
| Der Sporenpilz heilt auch den Wächter | sein Leben ist der Balken, an dem man den Fortschritt liest |
| Neue Räume für die neuen Arten | nicht nötig, solange Rollen reichen; ein Raum kann die Zeichen `j g p m o` trotzdem fest setzen |

## Konsequenzen

- **Jede Grube sieht anders aus**, auch auf derselben Stufe.
- **Die neuen Arten wippen nur.** Das Paket hat je einen Streifen; ein
  Grimlock schlägt, ohne dass man ihn ausholen sieht.
- **Kein Klang.** Der Schrei ist nur zu sehen, nicht zu hören; die Grube
  hat bisher gar keine Kampfklänge.
- **Die Besetzung steht nirgends**, bevor man hinabsteigt. Wer wissen
  will, was kommt, sieht es im ersten Raum.
- **`pit_sim` braucht länger**: drei Tabellen statt einer.
- Oger, blauer Slaad und Sumpftroll-Verwandte sind weiter ungenutzt; sie
  böten sich als weitere Brocken neben dem Steintroll an.
