# ADR-0079: Der Mentor führt durch den ersten Start

**Datum:** 20.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik, in einer Fragerunde mit Claude
**Löst teilweise ab:** [ADR-0068](0068-erster-start-deckt-die-bereiche-auf.md) (die Reihenfolge „Kampf früh“; dass die Kreise nach und nach kommen und alles abgeleitet ist, gilt weiter)
**Ergänzt:** [ADR-0078](0078-ein-startpunkt.md), [ADR-0060](0060-die-app-geht-ohne-lesen.md) (eine Ausnahme)

## Kontext

Am 19.10. hat ein Bekannter Frederiks das Spiel zum ersten Mal gespielt
(ADR-0078). Seit ADR-0068 erschienen die Kreise der Startseite zwar nach
und nach, und der nächste trug einen Punkt. Gesagt hat aber niemand
etwas. Er hakte ab, las ein ganzes Gebiet und kam an der Stelle, auf
die es ankommt, nie vorbei: an den Grundlagen.

Frederik: „Super wäre natürlich noch ein klares Tutorial … 1. Gewohnheit
— eigene Gewohnheit oder custom Gewohnheit → Theorie, erste Theorie-Seite
→ erste Fähigkeit ausrüsten → Grube → erster Gegenstand ausrüsten. Und
das halt bisschen fester begleitend bei neuen Nutzern mit Erklärung und
Tooltips.“

Mit den Zahlen von ADR-0078 ging diese Reihenfolge nicht auf: Der zweite
Fähigkeitsplatz öffnete auf Level 3, und nach Gewohnheit und erster
Seite steht man auf Level 2.

## Entscheidung

In einer Fragerunde entschieden:

| Frage | Antwort |
|---|---|
| Reihenfolge | **Frederiks**: Gewohnheit, abhaken, erste Seite, Fähigkeit anlegen, Grube, Beute anlegen |
| Die erste Fähigkeit | **Für alle dieselbe, mit der ersten Seite** — „damit alle das gleiche Feeling haben“ |
| Wie fest | **Zeigefinger**: Ein Kasten sagt, was dran ist, ein Ring markiert das Ziel; alles andere bleibt tippbar |
| Überspringen | **Nein** |
| Wer erklärt | **Eine Figur**, ein NPC. Das Bild schickt Frederik |

Gebaut daraus:

1. **Funkenstoß kommt mit der ersten Seite**, welche es auch ist: über
   die neue Errungenschaft **„Erste Seite“** (klein: 30 Erfahrung, 10
   Gold, 5 Ruhm). Bis dahin hing er an „Die kleinste Dosis, die wirkt“.
2. **Der zweite Fähigkeitsplatz öffnet auf Level 2**, nicht mehr auf 3
   (`AbilitySlots.unlockLevels`: 1, 2, 6, 10). Ein Häkchen und die erste
   Seite bringen mindestens 115 Erfahrung (100 braucht Level 2), auch
   mit der Startvorlage und einer Seite, die nur knapp bestanden ist.
3. **`ErsterStart` kennt einen Schritt** (`Schritt`: gewohnheit,
   abhaken, ersteSeite, faehigkeitAnlegen, grube). Er wird aus dem Stand
   abgeleitet wie alles in ADR-0068; ein Schritt ist erledigt, wenn er
   getan ist oder ein späterer, der ihn braucht.
4. **Die Kreise kommen in dieser Reihenfolge**: Theorie mit dem ersten
   Häkchen, Fähigkeiten mit der ersten Seite, Kampf mit der ersten
   angelegten Fähigkeit. Wer schon gekämpft hat oder sieben Häkchen hat,
   sieht die Grube trotzdem.
5. **Der Mentor** (`lib/mentor/`) spricht auf Startseite, Baum,
   Fähigkeiten und Eingang zur Grube. Was er wo sagt, steht in einer
   Tabelle (`Mentor.satz`). Sein letzter Satz kommt im Beute-Dialog des
   ersten Siegs, mit einem Ring um „Anlegen“.

## Begründung

- **Eine feste erste Fähigkeit macht den Weg planbar.** Mit einer
  Fähigkeit am Knoten müsste der Mentor in ein bestimmtes Gebiet
  schicken. So darf die erste Seite jede sein, und er sagt trotzdem
  dasselbe.
- **Funkenstoß** ist der Einstieg, auf den alles schon gemessen ist:
  `pit_sim` rechnet seine Spalten mit ihm, und er ist ein einfacher
  Schuss nach vorn.
- **Eine Errungenschaft statt einer neuen Art von Quelle.**
  Errungenschaften vergeben schon Fähigkeiten (ADR-0033), und „Erste
  Seite“ steht dann auch im Bildschirm der Errungenschaften.
- **Abgeleitet, nicht gespeichert** (ADR-0068): Wer schon weiter ist,
  sieht den Mentor nie, und ein eingefügter Stand braucht keine
  Übernahme. Weil nicht übersprungen werden kann, braucht es auch nichts,
  was gespeichert werden müsste.
- **Das Häkchen folgt nicht aus der Seite.** Wer zuerst liest, steht auf
  Level 1, und dort ist der zweite Platz zu. Der Mentor schickt ihn erst
  zum Häkchen; sonst zeigte er auf einen Platz, der nicht aufgeht.
- **Der erste Gegenstand ist kein eigener Schritt.** Das Spiel legt ihn
  von selbst an, wenn der Platz leer ist (`Loadout._add`), und der
  Beute-Dialog hat „Anlegen“ schon. Ein Schritt „leg ihn an“ wäre im
  Moment des Siegs bereits erledigt.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Grube vor der Fähigkeit, ohne eine Zahl zu ändern | Claudes Empfehlung. Frederik wollte seine Reihenfolge, und mit fester erster Fähigkeit geht sie auf. |
| Schleier: alles dunkel bis auf den einen Knopf | Am festesten, aber wer etwas anderes will, kommt nicht hin. Frederik: „Zeigefinger finde ich gut.“ |
| Überspringen-Knopf | Frederik: „Nein.“ |
| Neutraler Text ohne Figur | Frederik will einen NPC, der durchführt. |
| Der Name „Führer“ | Im Deutschen zu belastet, um als Name auf dem Bildschirm oder im Code zu stehen. |

## Konsequenzen

- **Die Ausnahme von ADR-0060 ist der Mentor.** Seine Sätze stehen auf
  dem Bildschirm, ohne dass man tippt. Das geht nur, weil er nach dem
  ersten Sieg für immer schweigt. Kein Satz ist länger als 130 Zeichen
  (`mentor_test.dart`).
- **Sein Kasten nimmt keinen Tipp an.** Er deckt einen Streifen zu, aber
  was darunter liegt, bleibt erreichbar. Auf der Startseite steht er
  über der unteren Reihe der Kreise in der leeren Mitte.
- **Das Bild fehlt.** Bis Frederik die Figur schickt, steht ein
  gezeichneter Kopf da. Das Bild kommt nach `assets/Mentor/`, der Pfad
  nach `Mentor.bild`.
- **Die erste Grube ist leichter.** Wer dem Mentor folgt, geht mit
  Funkenstoß und auf Level 2 hinab, nicht mit der Waffe allein auf
  Level 1. Der Bot stand dort bei 67 % (Eintrag vom 07.10.). Neu
  gemessen ist das nicht.
- **„Die kleinste Dosis, die wirkt“ bringt keine Fähigkeit mehr.** Im
  Baum tragen jetzt 28 Knoten eine, nicht 29.
- **Der zweite Platz auf Level 2** gilt für alle, nicht nur für Neue.
  Wer auf Level 2 steht, hat ab sofort einen Platz mehr.
- **ADR-0078 rechnete mit genau 100 Erfahrung** für ein Häkchen und die
  erste Seite. Mit der Errungenschaft sind es 130; der Aufstieg kommt
  damit sicherer, nicht später.
- **Der Kampf-Kreis kommt später** als seit ADR-0068: nach der ersten
  angelegten Fähigkeit statt mit dem ersten Häkchen. Die Grube selbst
  ist weiter nie gesperrt; wer eine Woche abhakt und nichts liest, sieht
  sie trotzdem (`ErsterStart.haekchenFuerKampf`).
