# ADR-0028: Eigene Gewohnheiten — mit Platz aus dem Baum, aber ohne Schlupfloch

**Datum:** 06.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik (Prozesstek), umgesetzt mit Claude

## Kontext

Issue [#28](https://github.com/Prozesstek/LifesGame/issues/28) verlangt, was
ein Habit-Tracker eigentlich können muss: **eigene** Gewohnheiten. Fünf je
Spieler, angelegt über einen Knopf, mit Name, Charakterwert,
Schwierigkeitsgrad, einem Ziel wahlweise in Zeit oder Menge und einer
Priorität, die ausdrücklich „für eigene Wertung wichtig, für Spiel
unwichtig" ist.

Das kollidiert mit zwei Sätzen, die bis heute im Code standen. In
`habit.dart`:

> Die Vorlagen sind Inhalt, kein Nutzerzustand: Der Spieler wählt aus
> ihnen aus, erfindet aber keine eigenen.

Und in `konzept.md` 3.7: jede Vorlage ist **fest** mit einer Lektion und
einem Stat verknüpft. Die Kette „erst verstehen, dann verfolgen" ist der
Grund, warum es den Theoriebaum überhaupt gibt — eine Gewohnheit, die man
sich selbst ausdenkt, überspringt ihn.

Der schärfere Punkt ist aber der Schwierigkeitsgrad. Wer ihn selbst setzt,
spricht sich selbst eine Belohnung zu. Und die Erfahrung pro Tag ist keine
freie Größe: `test/progression_test.dart` prüft, dass **vier** Kurven
zusammenpassen — Theorie-Belohnung, Häkchen-Ertrag, Levelkurve und Preise.
Ein frei wählbarer Multiplikator darauf ist kein Feature, sondern ein
Regler am Spielgleichgewicht.

## Entscheidung

Eigene Gewohnheiten gibt es, und sie zählen wie jede andere. Vier Regeln
halten sie zusammen:

1. **Ein Platz je freigeschalteter Vorlage.** Wer *n* Vorlagen aus dem Baum
   hat, darf *n* eigene anlegen (`HabitRewards.customSlotsFor`). Ohne
   Handbuch keine eigene Gewohnheit.
2. **Die Schwierigkeit ist eine feste, schmale Spanne** auf die Erfahrung:
   leicht ×0,8, mittel ×1,0, schwer ×1,3. Sie wirkt **nicht** auf Gold —
   dieselbe Trennung, die schon beim Streak gilt.
3. **Ein Tagesziel füllt sich schrittweise** und zahlt erst aus, wenn es
   voll ist. Menge in Einerschritten, Zeit in Fünf-Minuten-Schritten.
4. **Die Priorität bewegt keine Zahl.** Sie ordnet die Tagesliste, sonst
   nichts.

Dazu: **Wert, Schwierigkeit und Ziel stehen mit dem Anlegen fest.** Name,
Begründung und Priorität lassen sich nachbessern. Gelöscht wird gar nichts
— eine eigene Gewohnheit lässt sich stoppen, nicht entfernen.

Die Obergrenze von fünf gleichzeitig laufenden Gewohnheiten bleibt, und
Vorlagen und Eigene teilen sich diese fünf Plätze.

## Begründung

**Warum ein Platz je Vorlage und nicht einfach fünf von Anfang an.** Der
Baum verlöre sonst seine Rolle für die Gewohnheiten vollständig: Wer sich
alles selbst ausdenken kann, hat keinen Grund mehr, eine Lektion zu lesen.
So bleibt der Baum der Motor, aber was am Ende auf der Liste steht,
entscheidet der Spieler. Der leere Bildschirm sagt das jetzt auch: die
erste Lektion bringt beides mit, den Eintrag **und** den Platz.

**Warum die Spanne schmal ist, und warum sie überhaupt existiert.** Ein
Grad, der gar nichts tut, wäre eine Beschriftung — der Issue verlangt
mehr. Ein frei eingegebener Faktor wäre ein Schlupfloch. Drei feste Stufen
mit ±30 % sind nachgerechnet und bleiben es: `progression_test.dart` misst
seit heute alle drei Fälle.

| Tagesliste | bis Level 10 | bis Level 50 |
|---|---|---|
| fünf Vorlagen (= mittel) | 18 Tage | 240 Tage |
| fünf eigene, alle „leicht" | 22 Tage | 297 Tage |
| fünf eigene, alle „schwer" | 15 Tage | 188 Tage |

Der schnellste denkbare Weg ist 22 % schneller als der bisherige. Das ist
eine Farbe, kein Schlupfloch — und es steht als Test da, damit die nächste
Änderung an einer der Zahlen es meldet.

**Warum Gold außen vor bleibt.** `HabitRewards.goldPerCheck` folgt schon
dem Streak bewusst nicht, damit eine lange Kette keine Abkürzung durch den
Laden wird. Ein selbst gesetzter Grad wäre eine noch kürzere.

**Warum halb getan nicht zählt.** Ein Tagesziel, das anteilig ausschüttet,
macht die Streak wertlos — sie ist die Aussage „an diesem Tag stand es".
Drei von fünf Gläsern sind kein Tag.

**Warum Teilfortschritt nicht in den nächsten Tag wandert.** Sonst summierte
sich eine Woche halber Tage zu einem geschenkten Häkchen. Ein Tag ist ein
Tag; das ist dieselbe Regel, aus der `Day` entstanden ist.

**Warum sich Wert, Schwierigkeit und Ziel nicht ändern lassen.** Erfahrung
und Charakterwerte werden aus der Historie **gerechnet**, nicht mitgezählt
(ADR-0008). Wer die Schwierigkeit nachträglich hochsetzte, schriebe damit
jedes Häkchen der Vergangenheit um — und sein Level stiege rückwirkend.
Name und Priorität dürfen sich ändern, weil sie in keiner Rechnung
vorkommen. Die Trennlinie ist also nicht „wichtig / unwichtig", sondern
**„erzeugt eine Zahl / erzeugt keine"**, und sie steht als eine Methode da:
`CustomHabit.editable`.

**Warum es kein Löschen gibt.** Eine gelöschte Gewohnheit ließe ihre
Häkchen ohne Charakterwert zurück — die Historie wäre da, aber keinem Wert
mehr zuzuordnen. Stoppen tut, was gemeint ist, und hält sich an dieselbe
Zusage wie `deactivate` seit ADR-0008: Was einmal getan wurde, ist getan.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Schwierigkeit ohne Wirkung, nur Beschriftung | Der Issue verlangt sie als Eigenschaft der Gewohnheit, nicht als Etikett. Und ein Feld ohne Wirkung wächst später heimlich in die Rechnung hinein — genau davor warnt `gotchas.md`. |
| Frei eingebbarer Faktor | Ein Regler am Spielgleichgewicht in der Hand dessen, der ihn gewinnen will. |
| Schwierigkeit auf die Stat-Kurve statt auf Erfahrung | Hätte die Kampfbalance verschoben statt das Tempo — die teurere der beiden Folgen, weil dort drei Gegner eingestellt sind (ADR-0009). |
| Fünf eigene Plätze von Anfang an | Der Baum verlöre seine Rolle für die Gewohnheiten. Ziel 2 hat ihn gerade erst zur Entscheidung gemacht. |
| Eigene Gewohnheiten in den Katalog schreiben | Der Katalog ist Inhalt und wird von `habits_theory_test.dart` gegen die Lektionen geprüft. Nutzerdaten dort hinein hieße, beide Prüfungen aufzugeben. |
| Tagesziel nur als Text auf der Kachel | Ausdrücklich verworfen: „5 Gläser Wasser" ist über den Tag verteilt und wird über den Tag verteilt abgehakt. Ein Zähler ist der Punkt. |
| Anteilige Auszahlung bei halb gefülltem Ziel | Macht die Streak wertlos. |
| Eigene Gewohnheiten löschbar machen | Ihre Häkchen wären keinem Charakterwert mehr zuzuordnen. |

## Konsequenzen

**Leichter:** Der Tracker taugt jetzt als Tracker. Was jemand tatsächlich
täglich tut, muss nicht mehr zufällig unter den elf Vorlagen stehen — das
war die größte Reibung vor dem 30-Tage-Lauf (Ziel 7).

**Der Katalog ist entlastet.** „Mehr Gewohnheiten" heißt ab jetzt nicht
mehr zwingend „mehr Lektionen schreiben". Der Engpass des Projekts liegt
weiter auf der Schreibseite, aber nicht mehr an dieser Stelle.

**`HabitTracker` hält jetzt Inhalt und Nutzerzustand zugleich.** Er löst
eine Id über `definitionFor` auf — erst Katalog, dann eigene. Das ist eine
Stelle mehr Verantwortung, aber **eine** Stelle: Genau die Verdopplung, die
in `gotchas.md` unter „Zwei Stellen, die dieselbe Frage beantworten"
steht, ist damit vermieden.

**Der Spielstand ist gewachsen und nicht mehr trivial klein.** Bis heute
waren es Ids und Tage; jetzt stehen Objekte darin, die der Nutzer selbst
geschrieben hat. `progress` und `custom` werden nur geschrieben, wenn sie
belegt sind — ein Stand ohne eigene Gewohnheiten sieht aus wie vorher.
Das Signal aus `state.md` („irgendwann braucht es Entprellen oder Drift")
rückt damit ein Stück näher.

**`HabitTemplate` ist keine eigenständige Sache mehr, sondern ein Fall von
`Habit`.** Wer die Tagesliste anfasst, hat es mit dem `sealed` Obertyp zu
tun — kommt eine dritte Herkunft dazu, meldet der Compiler jede Stelle.
Der Preis ist eine Umbenennung: `activeTemplates` heißt jetzt
`activeHabits`.

**Zwei Griffe auf einer Kachel sind einer mehr als vorher.** Die Kachel
selbst hakt ganz ab, das Plus füllt um einen Schritt. Ob das auf einem
Handy im Alltag verwechselt wird, sagt der 30-Tage-Lauf, nicht eine
Vermutung. Wer ohnehin weiß, dass der Tag steht, tippt einmal auf die
Kachel und ist fertig.

**Unangenehm:** Die Schwierigkeit ist nachträglich nicht mehr zu ändern.
Wer sich beim Anlegen vertut, kann die Gewohnheit nur stoppen und eine
neue anlegen — und verliert damit ihre Streak. Das ist der Preis für
abgeleitete Werte, und er wird spürbar sein. Fällt er im 30-Tage-Lauf
tatsächlich zur Last, ist die saubere Lösung nicht „doch änderbar", sondern
den Grad je Häkchen mitzuschreiben — und das ist eine eigene Entscheidung.
