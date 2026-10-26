# ADR-0091: Vorschläge für das nächste Kapitel

**Datum:** 26.10.2026
**Status:** Aktiv
**Entschieden von:** Prozesstek

## Kontext

Frederik: „Wenn ein Skillpunkt offen ist: Vorschläge für nächstes
Kapitel. So muss der Spieler selber nicht selber entscheiden, kann es
aber, wenn er will. Sonst wird ihm vorgeschlagen abhängig von dem, was er
gemacht hat.“

Bis dahin schlug der Baum **eine** Seite vor (ADR-0070,
`TheoryProgress.suggestedStep`): was offen und ungelesen ist, sonst den
nächsten Schritt auf dem Weg der Grundlagen. Wer die Grundlagen durch
hatte und einen Punkt frei, bekam nichts mehr — gerade dann, wenn der
Baum am größten ist. Was jemand gelesen oder abgehakt hatte, floss nicht
ein.

## Entscheidung

In einer Fragerunde, viermal wie empfohlen:

| Frage | Antwort |
|---|---|
| Woran orientiert er sich? | **Am Gelesenen und an den Gewohnheiten** |
| Wie viele? | **Bis zu drei, jeder mit seinem Grund als Zeichen** |
| Wo? | **Oben im Baum** statt der einen Kachel, und **in der Feier eines Aufstiegs** |
| Was tut ein Tipp? | **Öffnen und lesen**, der Preis steht vorher dran |

Die Regel steht in `packages/theory` (`TheoryVorschlaege.vorschlaege`),
in dieser Reihenfolge, jede Seite höchstens einmal:

1. **Schon offen**, ungelesen — kostet nichts,
2. **die Grundlagen**, solange der Weg nicht durch ist,
3. **weiter, wo du warst**: unter, neben und im Gebiet der zuletzt
   bestandenen Seite,
4. **passt zu deinen Gewohnheiten**: das Gebiet, in dem die Häkchen die
   meiste Erfahrung gebracht haben,
5. **ein neues Gebiet**: eine Wurzel, unter der nichts bestanden ist.

Vorgeschlagen wird nur, was offen ist oder sich mit den freien Punkten
öffnen lässt.

## Begründung

**Der erste ist der alte Vorschlag.** Wer nicht wählen will, nimmt ihn,
und der Mentor zeigt weiter auf ihn (ADR-0079). Ein Test geht den Weg der
Grundlagen Schritt für Schritt und prüft das.

**Drei statt einer**, weil „kann es aber, wenn er will“ eine Wahl
braucht. Mehr als drei wären der Baum selbst.

**„Zuletzt“ ohne Uhrzeit**: Der Spielstand hält keine Zeit, aber die
Reihenfolge, in der Seiten zuerst versucht wurden, überlebt das Speichern
(`TheoryProgress.passedInOrder`). Ein zweiter Versuch rückt eine Seite
nicht nach hinten — wer etwas nachliest, soll nicht dorthin geschickt
werden.

**Die Gewohnheiten kommen als Zahlen herein**, je Wurzel die Erfahrung
(`HabitTracker.xpIn`). `package:theory` kennt `package:habits` nicht;
zusammengeführt wird in `vorschlaegeProvider`.

**In der Feier eines Aufstiegs**, weil dort der Punkt entsteht. Dort ist
die Frage „wofür?“ am größten, und ein Tipp beantwortet sie.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Nur das Gelesene oder nur die Gewohnheiten | nicht gewählt — beides zusammen sagt mehr |
| Ein einziger, klügerer Vorschlag | keine Wahl |
| Auch auf der Startseite | nicht gewählt; die Startseite ist schon voll |
| Ein Tipp führt nur hin | ein Schritt mehr; der Preis steht ohnehin dran |

## Konsequenzen

- Oben im Baum stehen bis zu drei Kacheln; der Baum darunter ist rund
  80 Punkte niedriger. In 390 × 844 angesehen, die Kinderreihen passen.
- Nimmt man im Aufstieg einen Vorschlag, kommt die Feier einer neuen
  Fähigkeit erst nach der Seite.
- Ohne freien Punkt bleibt höchstens, was schon offen ist — wie vorher.
