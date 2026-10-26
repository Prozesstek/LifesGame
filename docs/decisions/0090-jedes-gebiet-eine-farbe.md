# ADR-0090: Jedes Gebiet hat eine Farbe

**Datum:** 26.10.2026
**Status:** Aktiv
**Entschieden von:** Prozesstek

## Kontext

Frederik: „Hinter jedem Theorie-Gebiet eine Farbe — auch bei Charakter
und Gewohnheiten verwenden, also wirklich alles, was irgendwie mit den
Gebieten zu tun hat, wird mit der gleichen Farbe eingefärbt.“

Bis dahin hatte kein Gebiet eine Farbe. Der Baum färbte nach dem
**Zustand** eines Knotens (bestanden grün, offen Akzent, kaufbar gold,
gesperrt grau), die Lese-Seite betonte im Akzent. Der Balken des
Gebiets, die Funken zu ihm und „+33 EP Körper“ waren für alle vier
Gebiete dasselbe Grün (ADR-0085). Nur das Haustier hatte eine eigene
Tabelle für seine Prägung: Rot, Violett, Blau, Grün.

Seit ADR-0085 gehört jede Gewohnheit zu einem Gebiet und seit ADR-0088
auch jeder Kampfwert. Die vier Gebiete stehen damit an rund zwanzig
Stellen — Baum, Lesen, Kachel, „Heute“, Anlegen, Leiste, Charakter,
Errungenschaften, Haustier, Statistik —, aber man erkennt sie nur am
Zeichen.

Die Schwierigkeit: Fast jede Farbe hat in der App schon eine Bedeutung.
Rot heißt Gegner und Verlust, Grün heißt erledigt und bestanden, Gold
heißt Gold, kaufbar und legendär, dazu die Farben der Seltenheiten.

## Entscheidung

In einer Fragerunde entschieden, viermal wie empfohlen:

| Frage | Antwort |
|---|---|
| Welche Farben? | **Körper Glut, Geist Blau, Wissenschaft Violett, Gesellschaft Rosa** — kein Rot, Grün oder Gold |
| Der Baum? | **Die Farbe des Gebiets statt Grün**: Bestanden ist der Knoten gefüllt, offen hat er einen Rand in der Farbe; Ring, Linien, Überblick und Kopf ebenso. Kaufbar bleibt gold, Gesperrtes grau, „alles darunter“ gold |
| Die Kampfwerte? | **Ja, außer in der Grube**: Hantel, Tropfen, Schild und Herz in der Farbe ihres Gebiets; die Balken für Leben und Mana in der Grube bleiben |
| Eine Gewohnheit? | **Streifen und Zeichen**: ein Streifen am linken Rand, Zeichen und Skill in der Farbe. Das Häkchen bleibt grün — es heißt erledigt |

Die Farben stehen in der `Palette`, je ein Ton für Pergament und einer
für Leder. Wer welche trägt, steht an **einer** Stelle:
`GebietFarbe` in `lib/skills/gebiet_farbe.dart`, neben `gebietZeichen`.

## Begründung

**Kein Rot, kein Grün, kein Gold**, weil eine Farbe mit zwei
Bedeutungen keine mehr hat. Eine Gewohnheit aus Gesellschaft in Grün
sähe abgehakt aus, bevor sie es ist; eine Seite aus Körper in Rot wie
ein Verlust. Deshalb nicht die Farben des Haustiers, obwohl sie schon
da waren.

**Geist ist blau**, weil Geist das Mana steigert (ADR-0088) und Mana
schon blau ist. Auf Leder ist es derselbe Ton; so sagt die Farbe einmal
dasselbe, statt sich zu widersprechen. Gesellschaft ist rosa wie das
Herz für Leben, aus demselben Grund.

**Der Zustand eines Knotens bleibt ablesbar**, auch ohne Grün: Gefüllt
heißt bestanden, ein Rand heißt offen, und das kleine Zeichen am Knoten
sagt es seit ADR-0056 ohnehin — „Zeichen statt nur Farbe“.

**Ein Knoten trägt die Farbe des Gebiets, in dem man ihn sieht.**
*Stress* hängt an Körper und an Geist; unter Geist ist er blau. Außerhalb
des Baums — die nächste Seite, die Rückfrage — trägt er die Farbe seines
Zuhauses, der Wurzel seines ersten Elternteils
(`TheoryGraph.rootIdsOf`).

**Die Grube bleibt, wie sie ist**, weil man dort Farben in
Sekundenbruchteilen liest und die Balken für Leben und Mana überall so
aussehen.

**Das Häkchen bleibt grün**, weil es eine Aussage über heute ist, nicht
über das Gebiet.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Die Farben des Haustiers (Rot, Violett, Blau, Grün) | Rot heißt Gegner, Grün heißt erledigt |
| Erst eine Farbtafel ansehen | nicht gewählt — die Vorschau jedes Blocks zeigt sie am echten Bildschirm |
| Dazu der Grund des Baums je Gebiet getönt | nicht gewählt |
| Im Baum nur Kopf und Überblick einfärben | nicht gewählt — „wirklich alles“ |
| Kampfwerte auch in der Grube einfärben | Lebensbalken in Rosa und Blau statt der vertrauten Farben, mitten im Kampf |
| Kampfwerte nicht einfärben | seit ADR-0088 ist jeder Wert ein Gebiet; dann sähe man es ihm nicht an |
| Das Häkchen in der Farbe des Gebiets | dann sagte nur noch Stempel und Grau, ob etwas erledigt ist |
| Den ganzen Zettel tönen | schlechter lesbar, und Erledigtes ist schwerer zu erkennen |

## Konsequenzen

- **Grün heißt nur noch erledigt** — im Baum, im Balken des Gebiets und
  bei den Funken zum Gebiet steht es nicht mehr.
- **Der Akzent verschwindet aus dem Baum fast ganz.** Er trägt dort nur
  noch einen Baum, dessen Wurzel kein Gebiet ist, und den gibt es nur
  in Tests.
- **Körper liegt nah am Akzent**: Glut und gebranntes Leder sind beide
  orange-braun. Im Baum steht der Akzent nicht mehr daneben; wo beide
  zusammen auftauchen, unterscheidet sie die Sättigung.
- Eine Farbe mehr je Bildschirm. `test/gebiet_farbe_test.dart` hält
  fest, dass jede auf ihrem Grund lesbar ist, dass keine zwei Gebiete
  sich eine teilen und dass keins Grün, Rot, Gold oder den Akzent trägt.
- Gebaut in drei Blöcken mit eigener Vorschau: Baum und Lesen;
  Gewohnheiten, Häkchen und Startseite; Charakter, Kampfwerte,
  Errungenschaften, Haustier und Statistik.
