# ADR-0092: Der Gewohnheiten-Bildschirm zeigt oben die Gebiete, auf der Kachel Ertrag und Kette

**Datum:** 30.10.2026
**Status:** Aktiv; löst an der Kachel ab, was ADR-0085 dort festgelegt hat („der Skill vorne, die Kette als Bonus“)
**Entschieden von:** Frederik

## Kontext

Frederik: „Als erstes hat man oben die 4 Bereiche mit Farbe. Die
Gewohnheiten selber zeigen nur die Belohnung in XP und Gold an sowie die
aktuelle StreakAnzahl. Der Rest kann eigentlich alles weg.“

Auf einer Kachel standen bis dahin: Häkchen, Name, zweimal die Erfahrung
(Level und Gebiet), Gold, der Balken eines Tagesziels samt Text, die Zeile
mit dem Auslöser, der Skill des Gebiets, der Kettenbonus, die nächste
Kettenstufe, Timer oder Plus und das Kreuz. Über der Liste standen Level
und Gold, ein Platz für den Balken des Gebiets und ein Zähler „2 / 5“.

## Entscheidung

- **Oben stehen die vier Gebiete** als Kacheln in ihrer Farbe: Zeichen,
  Stufe, Name, Balken (`GebietsKacheln`). Sie stehen fest über der Liste.
  Ein Tipp sagt, was bis zur nächsten Stufe fehlt; gefiltert wird nicht.
- **Level und Gold wandern in die Titelzeile** (`StatusLeiste(klein: true)`).
- **Die Funken eines Häkchens fliegen in die Kachel seines Gebiets**. Dafür
  kann ein Flugziel jetzt sagen, wofür es steht (`FlugZielMarke.fuer`).
- **Die Kachel einer Gewohnheit zeigt** Erfahrung, Gold und die Kette **in
  Tagen**. Skill, Kettenbonus, nächste Stufe, zweite Erfahrungszahl, der
  Balken des Tagesziels und der Tipp mit den Tagen gesamt sind weg, ebenso
  der Zähler „2 / 5“ über der Liste.
- **Ein Tagesziel behält einen kleinen Stand**: „3/5“ mit Plus, die
  Restzeit mit dem Knopf zum Timer.
- **Die Zeile mit dem Auslöser und das Kreuz bleiben vorerst.** Frederik:
  „da überlegen wir uns noch was für“.

## Begründung

Die Gebiete gehören einmal oben hin, nicht auf jede Kachel: Dort wiederholte
sich dieselbe Stufe bei jeder Gewohnheit eines Gebiets.

Level und Gold ganz zu streichen hätte den Münzen und Funken ihr Ziel
genommen, und die Zahlen beim Abhaken steigen zu sehen ist der Moment, um
den es bei einem Häkchen geht (18.10.). In der Titelzeile sind die Gebiete
trotzdem der erste Inhalt.

Der Stand eines Tagesziels bleibt, weil sonst eine Funktion wegfiele: Eine
Menge ließe sich nicht mehr Schritt für Schritt füllen, und ein laufender
Timer wäre hier nicht zu sehen.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Level und Gold ganz weg | Münzen flögen nirgendwohin; beides stünde nur noch auf der Startseite |
| Tipp auf ein Gebiet filtert die Liste | lohnt erst bei vielen Gewohnheiten und muss sich wieder abschalten lassen |
| Ändern und Stoppen hinter langem Drücken oder drei Punkten | von Frederik vertagt, nicht verworfen |
| Tagesziele ganz weg, ein Tipp hakt ab | schrittweises Zählen wäre verloren |

## Konsequenzen

- **ADR-0085 sagt an der Kachel das Gegenteil**: Dort stand der Skill vorne,
  weil eine fallende Kette sich wie ein Verlust anfühlte. Jetzt steht wieder
  die Zahl der Tage auf der Kachel — und fällt sichtbar, von 45 auf 30. Der
  Skill steht dafür groß darüber und fällt nie. Ob das reicht, zeigt erst
  jemand, dessen lange Kette fällt.
- **Der Bonus der Kette steht auf diesem Bildschirm nirgends mehr**, nur
  noch in der größeren Erfahrungszahl. „Tage gesamt“ ist ganz weg von hier.
- **Der Host liegt jetzt um den ganzen Bildschirm** (`AufstiegHost` über dem
  `Scaffold`), sonst fänden die Münzen die Titelzeile nicht. Die große Flamme
  deckt damit auch die Titelzeile ab.
- **Der Balken des Gebiets (`GebietsBalken`) lebt nur noch auf der
  Startseite.** Dort fliegen die Funken weiter zu ihm.
- Stehen zwei Häkchen in zwei Gebieten gleichzeitig in der Luft, zieht die
  zuletzt getroffene Kachel kurz die Summe ab. Nur Darstellung, und nach der
  Landung stimmt es.
