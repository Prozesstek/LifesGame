# ADR-0007: Theorie wird ein Skillbaum mit levelgebundenen Zweigen

**Datum:** 12.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Nach dem ersten Theoriezweig („Gewohnheiten", ADR-0005) stand die Frage, wie
Theorie insgesamt aussehen soll. Das Konzept nennt in Abschnitt 3.3 einen
„Skilltree mit mehreren Zweigen", warnt aber im selben Atemzug:

> Jeder Zweig kostet Wochen an Schreibarbeit. Mit **einem** Zweig starten, ihn
> komplett fertigstellen, Architektur für weitere offen halten.

Frederik hat entschieden, jetzt vier Zweige anzulegen — die Warnung war
bekannt und die Entscheidung fiel trotzdem so.

## Entscheidung

Die Theorie ist ein Skillbaum aus fünf Zweigen:

| Zweig | Ab Level | Lektionen |
|---|---|---|
| Gewohnheiten | offen von Anfang an | 5 |
| Körper | 2 | 3 |
| Geist | 3 | 3 |
| Wissenschaft | 4 | 3 |
| Gesellschaft | 5 | 3 |

Die Sperre hängt am **Charakterlevel**, nicht am Fortschritt im Baum. Innerhalb
eines Zweigs bleibt die Reihenfolge verbindlich.

## Begründung

**Warum Levelsperre statt Zweigsperre.** Ein Baum, der sich durch Lesen selbst
öffnet, belohnt Lesen. Ein Baum, der sich durch das Level öffnet, belohnt alles,
was Erfahrung bringt — und das sind laut Konzept zu 50 % die Habits. Die Sperre
zieht den Nutzer damit aus der Theorie heraus in den Tracker, statt ihn in einer
Leseschleife zu halten.

**Warum „Gewohnheiten" ohne Sperre.** Der Zweig erklärt, wie die App selbst
funktioniert (ADR-0005). Ihn hinter ein Level zu legen hieße, das Handbuch
wegzusperren. Er ist deshalb der Wurzelzweig und liefert zugleich die Erfahrung
für die erste Stufe.

**Warum drei Lektionen je neuem Zweig statt fünf.** Ein Kompromiss mit der
Warnung aus dem Konzept: Drei fertige Lektionen sind ein spielbarer Zweig, kein
Platzhalter — aber sie binden nicht vier mal fünf Lektionen Schreibarbeit, bevor
irgendjemand den Baum ausprobiert hat.

**Warum diese vier Themen.** Sie decken die Bereiche ab, in denen tägliche
Gewohnheiten überhaupt anfallen, und sie stützen sich gegenseitig: „Wissenschaft"
liefert das Werkzeug, um die Ratschläge aus „Körper" und „Geist" selbst zu
prüfen, „Gesellschaft" behandelt den Faktor, der die anderen drei überschreibt.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Zweige durch abgeschlossene Vorgängerzweige freischalten | Belohnt Lesen statt Habits; der Nutzer bliebe in der Theorie |
| Zweige durch Gold kaufen | Gold ist laut Konzept die Ausgabeseite für Ausrüstung; Wissen zu kaufen passt inhaltlich nicht |
| Alle Zweige sofort offen | Kein Grund zu leveln, und der Einstieg wäre eine Wand aus fünf Optionen |
| Erst „Gewohnheiten" auf zehn Lektionen ausbauen | Wäre konzepttreu gewesen, war aber nicht die Entscheidung |

## Konsequenzen

**Leichter:** Der Baum gibt dem Level einen Zweck — bisher war es eine Zahl ohne
Wirkung. Ein sechster Zweig ist eine neue Datei plus ein Eintrag in
`theoryTree`, sonst nichts.

**Schwerer, und das ist der ernste Teil:** Es liegen jetzt vier angefangene
Zweige im Repo statt einem fertigen. Genau davor warnt das Konzept. Wenn die
Schreibarbeit stockt, hat das Produkt vier halbe Themen statt eines ganzen —
und ein Nutzer, der einen Zweig durch hat, steht nach drei Lektionen vor dem
Ende. Wer hier weiterarbeitet, sollte einen Zweig zu Ende bringen, bevor ein
sechster dazukommt.

**Neue Kopplung:** Belohnungskurve (`packages/theory`) und Levelkurve
(`packages/progression`) müssen zusammenpassen, sonst wird der Baum zur
Sackgasse — alles Offene bestanden, aber zu wenig Erfahrung für den nächsten
Zweig. Das prüft `test/progression_test.dart` automatisch, für perfekte wie für
knapp bestandene Antworten. Wer eine Zahl in `rewards.dart` oder
`level_curve.dart` ändert, sieht dort sofort, ob der Baum noch aufgeht.

**Offen:** Erfahrung kommt bisher ausschließlich aus der Theorie. Damit öffnet
sich der Baum derzeit doch durch Lesen — die eigentliche Absicht greift erst,
wenn Habits einzahlen. Bis dahin ist die Levelsperre eine Vorbereitung, keine
wirksame Steuerung.
