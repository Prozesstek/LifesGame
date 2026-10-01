# ADR-0062: Wächter und Besetzung werden gewürfelt

**Datum:** 01.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Im Download-Paket lagen elf Monster ungenutzt (`assets/Grube/HERKUNFT.md`
nennt das Paket). Der Vorschlag dazu war, den Wächter alle zehn Stufen
wechseln zu lassen und neue Gegnerarten mit der Tiefe einzuführen.
Frederik wollte es anders: „ich fände es cooler, wenn die Wächter random
wechseln und die Gegner auch.“

Bis dahin stand auf allen dreißig Stufen derselbe Zyklop, und welche
Gegner in einem Raum stehen, legte allein der Raumkatalog fest. Die Karte
war jedes Mal neu, die Aufgabe darin nicht.

## Entscheidung

Drei Dinge, in einer Fragerunde entschieden:

1. **Der Wächter wird je Lauf gewürfelt**, aus vier, jeder mit eigenen
   Angriffen.
2. **Jede Grube bekommt eine Besetzung**: Je Lauf werden einige
   Gegnerarten aus dem Pool gezogen, statt jeden Platz einzeln zu würfeln.
3. **Alles ab Stufe 1.** Die Tiefe regelt, wie stark ein Gegner ist und
   was ein Wächter kann, nicht, wer überhaupt vorkommt.

Gebaut ist mit diesem ADR der erste Punkt. Die neuen Gegnerarten und die
Besetzung folgen als eigene Schritte.

### Die vier Wächter

| Wächter | Erster Angriff (ab Stufe 1) | Zweiter (ab Stufe 4) | Dritter (ab Stufe 8, in Wut) |
|---|---|---|---|
| Zyklop | Bodenstoß | Felswurf | Ansturm |
| Zweikopf (Ettin) | Bodenstoß, danach ein zweiter, größerer Ring | zwei Brocken kurz nacheinander, der zweite neu gezielt | — |
| Schlund (Slaad) | Sprung: der Ring liegt am Landeplatz | spuckt | springt zweimal hintereinander |
| Sumpftroll | Giftwurf: der Ring liegt am Aufschlag, danach bleibt eine Pfütze | Bodenstoß | drei Pfützen statt einer |

Leben, Angriff, Verteidigung, Größe und Wut teilen sich alle vier.

## Begründung

**Eigene Angriffe statt nur anderem Aussehen.** Ein Wächter, der nur
anders aussieht, fühlt sich nach dem dritten Lauf gleich an. Mit eigenen
Angriffen muss man beim Auftritt hinsehen, wer da fällt.

**Die Treppe bleibt.** Dass ein Wächter mit der Tiefe dazulernt, hat
einen gemessenen Grund (`ActionBalance.bossThrowFromStage`): Mit allen
Angriffen schaffte ein frischer Charakter Stufe 1 nur zu 40 %. „Alles ab
Stufe 1“ heißt deshalb: jeder Wächter kann auf Stufe 1 kommen, aber nur
mit seinem ersten Angriff.

**Ein eigener Würfel für den Wächter.** `LevelBuilder.bossFor` zieht
nicht aus dem Generator der Karte. Sonst hätte jeder Startwert nach
dieser Änderung eine andere Grube ergeben als vorher, und derselbe
Startwert je Wächter eine andere (`gotchas.md`, „Ein Generator je
Rolle“).

**Die Regel der Ankündigung gilt für alle.** Jeder Ring dauert länger
als der Weg hinaus, und kein Ring um den Wächter reicht bis an die Wand
seines Raums. Beides steht als Test in `boss_test.dart`.

## Gemessen

`dart run tool/pit_sim.dart 24`, der Bot ist dumm, die Zahlen sind eine
untere Schranke.

| | Zyklop | Zweikopf | Schlund | Sumpftroll |
|---|---|---|---|---|
| Stufe 1, Tag 0 | 100 % | 100 % | 92 % | 100 % |
| Stufe 30, Tag 60 mit Ausrüstung und Fähigkeiten | 63 % | 50 % | 67 % | 75 % |

Über alle Wächter gewürfelt: Stufe 1 an Tag 0 jetzt 92 % (vorher 100 %),
Stufe 2 58 % (vorher 83 %), Stufe 30 voll ausgerüstet 71 % (vorher 67 %).
Der Anfang ist damit etwas härter geworden.

Der erste Entwurf lag weit daneben: Zweikopf 3 von 40 und Schlund 6 von
40 auf Stufe 30, gegen 27 für den Zyklopen. Drei Ursachen, alle behoben:
Der zweite Ring des Zweikopfs (140) reichte im zehn Felder hohen Raum
oben und unten bis an die Wand; wer aus ihm hinauslief, stand genau auf
Wurfweite und bekam sofort zwei Brocken; und der Schlund sprang in Wut
praktisch ohne Pause.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Wächter wechselt alle zehn Stufen | Frederik: gewürfelt ist reizvoller. Fest hieße auch, dass man die Stufen 1 bis 10 nie gegen einen anderen spielt. |
| Nur anderes Aussehen | schnell gebaut, aber nach wenigen Läufen ohne Wirkung |
| Neue Wächter erst ab einer Tiefe | Frederik: alles ab Stufe 1 |
| Jeden Gegnerplatz einzeln würfeln | jede Grube sähe ähnlich durcheinander aus; eine Besetzung gibt einem Lauf ein Gesicht |
| Die Pfütze trifft auch den Troll | dann wäre Stehenbleiben die beste Antwort |

## Konsequenzen

- **Bestzeiten je Stufe sind weniger vergleichbar.** Wer den Sumpftroll
  zieht, läuft anders als gegen den Zyklopen. Die Liste im Fahrstuhl
  sagt nicht, gegen wen eine Zeit gelaufen wurde.
- **`pit_sim` hat eine zweite Tabelle**, je Wächter mit festem Bau. Wer
  an einem Wächter dreht, liest dort, ob er aus der Reihe fällt.
- **Flächen können jetzt dem Helden schaden** (`_Zone.hostile`). Die
  Pfütze liegt kürzer als ihre Abklingzeit, damit ein Nahkämpfer an den
  Troll herankommt.
- **Der Bot weicht besser aus**: Er prüft, ob der Weg aus einem Ring
  frei ist, und verlässt Giftpfützen. Dadurch haben sich auch die Zahlen
  gegen den Zyklopen leicht bewegt.
- **Die drei neuen Wächter wippen nur**, wie Kobold und Troll: Das Paket
  hat für sie einen Streifen, keinen Schlag und keinen Tod.
- `chase_test.dart` baut seine Gruben fest mit dem Zyklopen. Ein Schlund,
  der in die Traube springt, schiebt Verfolger beiseite, und der Test
  hielt das für Hängenbleiben.
