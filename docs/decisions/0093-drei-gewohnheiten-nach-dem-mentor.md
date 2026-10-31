# ADR-0093: Drei eigene Gewohnheiten nach dem Mentor

**Datum:** 31.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik, die Umsetzung ohne Rückfrage von Claude
**Ergänzt:** [ADR-0028](0028-eigene-gewohnheiten.md) (ein Platz je Vorlage; das gilt weiter)

## Kontext

Eine eigene Gewohnheit braucht einen Platz, und einen Platz gibt es nur je
freigeschalteter Vorlage (ADR-0028). Seit es nur noch einen Startpunkt gibt
(ADR-0078), sind Seiten knapp, und nur elf Seiten bringen überhaupt eine
Vorlage. Wer den Mentor hinter sich hat, hat deshalb in der Regel genau einen
Platz: den der Startvorlage.

Frederik: „dann würde ich gerne, dass man nach dem Tutorial die Möglichkeit
hat 3 Gewohnheiten schon zu haben“.

## Entscheidung

**Der erste Sieg in der Grube bringt zwei Plätze für eigene Gewohnheiten.**
Mit dem Platz der Startvorlage sind das drei. Jede weitere Vorlage bringt wie
bisher einen dazu (`HabitRewards.tutorialSlots`).

Der Mentor sagt es in seinem letzten Satz im Beute-Dialog.

## Begründung

- **„Nach dem Tutorial“ heißt: wenn der Mentor schweigt.** Das ist der erste
  Sieg (`ErsterStart.mentorFertig`). Die Frage hat damit eine Stelle, und
  gespeichert wird nichts: Ein Stand, der schon gewonnen hat, bekommt die
  Plätze beim nächsten Start. `customSlotsProvider` fragt nicht
  `ersterStartProvider`: Der liest den Tracker, und `addCustom` liest die
  Plätze, das wäre ein Kreis (`gotchas.md`).
- **Dazugezählt, nicht als Mindestzahl.** Bei „mindestens drei“ brächten die
  ersten zwei Vorlagen aus dem Baum keinen Platz, und ADR-0028 macht genau
  diesen Platz zum Grund, sie zu lesen.
- **Erst danach, nicht von Anfang an.** Der Mentor führt durch **eine**
  Gewohnheit. Und der Baum bleibt für jeden weiteren Platz der Motor.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Mindestens drei Plätze | Die ersten zwei Vorlagen brächten keinen Platz. |
| Drei Gewohnheiten fertig anlegen | „Die Möglichkeit“ war gefragt. Vorgegebene Gewohnheiten wären etwas, das jemand nicht tut, und sie drückten auf die Quote und die Truhe. |
| Plätze schon zum Start | Der Mentor fragt nach einer Gewohnheit, und drei Plätze lüden am ersten Tag zu mehr ein, als jemand durchhält. |

## Konsequenzen

- **Alle Stände mit einem Sieg bekommen die zwei Plätze rückwirkend**, auch
  die der Entwickler.
- **Bis zu 13 Plätze statt 11.** Die Grenze von fünf laufenden Gewohnheiten
  bleibt; die Kurven rechnen ohnehin mit fünf.
- **Früher mehr Erfahrung und Gold**: Wer gleich drei führt, steigt schneller
  auf. Das ist nicht gemessen: `runway_sim` spielt Vorlagen, keine eigenen.
- **Wer die erste Stufe nicht schafft, bleibt bei einem Platz**, solange er
  keine weitere Vorlage liest.
- **Der Satz nennt „zwei weitere“, keine Gesamtzahl**: Wer schon Vorlagen
  freigeschaltet hat, hat mehr als drei.
