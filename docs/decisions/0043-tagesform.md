# ADR-0043: Die Tagesform — heutige Häkchen stärken heute ihren Wert

**Datum:** 23.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Eine kritische Durchsicht am 23.09. hat zwei Schwächen im Kern-Loop
gefunden:

1. **Das Abhaken war der schwächste Moment des Spiels.** In der Grube gibt
   es Krits, Beute und einen Wächter mit Auftritt, beim Häkchen nur
   „+15 · +5". Der Kern-Loop sagt aber, dass das Häkchen die eigentliche
   Handlung ist.
2. **Nach etwa einem Monat spürt man die Gewohnheiten im Kampf kaum noch.**
   Die Stat-Kurve ist gedeckelt (ADR-0008). Ab dann wächst die Macht fast
   nur noch über Level und Ausrüstung (ADR-0042).

Frederik wollte beides zusammen: einen Bonus für heute **und** dass jede
Gewohnheit den Wert erhöht, den sie trägt.

## Entscheidung

Jedes heutige Häkchen einer laufenden Gewohnheit vervielfacht **heute** den
Kampfwert ihres Charakterwerts um `HabitRewards.formPerCheck` (10 %):
Stärke den Angriff, Ausdauer das Leben, Disziplin die Abwehr, Klarheit das
Mana. Ist jede laufende Gewohnheit erledigt, heißt das **In Form**, und
`HabitRewards.formAllDone` (10 %) kommt auf alle vier dazu.

Die Tagesform wird abgeleitet (`HabitTracker.formOn`), nie gespeichert,
und um Mitternacht ist sie weg. Zusammengesetzt wird sie wie alles andere
in `PitPower.hero`.

## Begründung

- **Ein Faktor, kein Punkt.** Er wirkt auch am Deckel der Stat-Kurve. Die
  Gewohnheit bleibt jeden Tag im Kampf spürbar, nicht nur im ersten Monat.
- **Der eigene Wert statt eines allgemeinen Schadensbonus.** Wer Laufen
  abhakt, sieht sein Leben steigen. Die Verbindung zwischen Alltag und
  Figur wird konkret statt pauschal.
- **Nur ein Bonus, nie ein Abzug.** Ein Tag ohne Häkchen kämpft mit den
  Werten, die er hat (`konzept.md` 3.7: keine Strafe fürs Verpassen).
- **An den Tag gebunden, wie die Dailies (ADR-0040).** Das Häkchen macht
  den Kampf *heute* besser. Das ist ein Grund, zuerst abzuhaken und dann
  hinabzusteigen, statt umgekehrt.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Ein Schadensbonus je Häkchen, egal welcher Wert | Pauschal. Die Frage „was bringt *diese* Gewohnheit" bliebe offen. |
| Die Stat-Kurve feiner machen (ein Punkt je Häkchen) | Sie hängt an der Balance und am Deckel aus ADR-0008. Am Deckel wäre das Problem 2 wieder da. |
| Ein dauerhafter Bonus aus der Streak | Die Streak trägt schon den Erfahrungsmultiplikator. Ein zweiter Lohn auf dieselbe Zahl macht einen Fehltag teurer, genau das schließt 3.7 aus. |

## Konsequenzen

- Fünf Häkchen auf einem Wert plus „In Form" ergeben höchstens +60 % auf
  diesen Wert, gewöhnlich eher +20 bis +30 %. Das kommt zu Level und
  Seltenheit dazu.
- **`pit_sim` kennt die Tagesform nicht.** Sein Bot geht ohne Häkchen des
  Tages hinein, die Quoten dort sind für die Tagesform eine untere
  Schranke.
- Wer die Grube vor dem Abhaken betritt, kämpft ohne Form. Die Werte
  frieren beim Betreten ein (`PitScreen`), ein Häkchen während des Laufs
  wirkt also erst im nächsten.
- Eine Gewohnheit zu stoppen nimmt ihr heutiges Häkchen aus der Form. Sonst
  wäre Stoppen ein Knopf ohne Preis.
- Die Zahlen stehen in `packages/habits/lib/src/rewards.dart`. Wer daran
  dreht, rechnet gegen die Stufenkurve (`dart run tool/pit_sim.dart`).
