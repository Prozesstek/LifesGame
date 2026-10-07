# ADR-0069: Die Grube erklärt sich im ersten Lauf

**Datum:** 07.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik (in einer Fragerunde mit Claude)

## Kontext

[ADR-0068](0068-erster-start-deckt-die-bereiche-auf.md) schickt einen
neuen Spieler nach dem ersten Häkchen in die Grube und führte selbst als
offen: „Die Grube selbst erklärt nichts.“ Der Stand davor, aus dem Code
gelesen:

- **Laufen:** Das Steuerkreuz entsteht erst dort, wo der Daumen aufsetzt
  (`ActionJoystick`). Wer nicht weiß, dass man zieht, sieht eine stehende
  Figur.
- **Angreifen:** Im ersten Lauf liegt keine Fähigkeit auf einem Platz,
  also steht kein einziger Knopf da. Der Held schlägt von selbst, aber
  das sagt niemand.
- **Niederlage:** Danach standen „Nochmal“ und „Zurück“ da. Dass Lesen
  stärker macht, stand nur als Leuchten auf der Startseite, zwei Tipps
  entfernt.

## Entscheidung

1. **Zwei Zeichen im Lauf, ohne Wort und ohne Anhalten.**
   - Ein **Geister-Steuerkreuz** links unten: ein Finger zieht reihum in
     alle vier Richtungen. Es blendet aus, sobald der Held anderthalb
     Felder gelaufen ist.
   - Mit dem **ersten Schlag** des Helden steht vier Sekunden lang seine
     Waffe in zwei drehenden Pfeilen über ihm: Das läuft von selbst.
2. **Sie bleiben, bis die erste Stufe geschafft ist** — nicht nur im
   allerersten Lauf. Abgeleitet aus der Reihe
   (`ErsterStart.grubeErklaertSich`), kein Feld im Spielstand.
3. **Eine Niederlage zeigt den Weg:** Solange keine Stufe geschafft ist,
   steht zwischen „Nochmal“ und „Zurück“ das Buch, „Stärker werden“. Es
   führt in die Theorie und tritt an die Stelle der Grube.

Frederik hat Form, Inhalt, Dauer und die Niederlage in der Fragerunde
gewählt. Die Uhr und „Rot heißt weg“ hat er ausdrücklich **nicht**
gewählt; sie bekommen kein Zeichen.

**Ohne Rückfrage entschieden**, weil es sonst nicht aufgeht:

- **Die Zeichen nehmen keinen Tipp an.** Das Geisterkreuz liegt, wo der
  linke Daumen aufsetzt; das echte Steuerkreuz darunter bekommt die
  Geste.
- **Sie laufen aus der Zeit des Laufs**, nicht aus einem eigenen Takt.
- **Der Geisterdaumen zieht reihum.** Immer nach rechts hieße „lauf nach
  rechts“.
- **Das Zeichen am Helden weicht der Kopfzeile aus:** Steht er dicht
  unter ihr, sitzt es unter ihm statt über ihm.
- **Das Buch ersetzt die Grube im Stapel**, damit „Zurück“ aus der
  Theorie zum Eingang führt und nicht in den verlorenen Lauf.
- **„Zurück“ und das Buch tragen die Farben für Leder.** Die Farben des
  Themes sind für Pergament gewählt und waren auf dem abgedunkelten
  Spielfeld kaum zu lesen.

## Begründung

**Im Lauf statt davor**, weil ein Blatt vor dem Abstieg erklärt, bevor es
etwas zu sehen gibt, und Sätze zurückbringt, die
[ADR-0060](0060-die-app-geht-ohne-lesen.md) entfernt hat. Ein Zeichen in
dem Moment, in dem es zählt, braucht kein Wort.

**Bis zum ersten Sieg**, weil genau der Spieler die Hilfe braucht, der
den ersten Lauf verloren hat. Die Bedingung ist dieselbe Art Zahl wie in
ADR-0068: Die tiefste geschaffte Stufe wächst nur. Die Zeichen kommen
deshalb nie zurück, und unsere beiden Stände sehen sie nicht.

**Die Niederlage als Frage:** ADR-0068 stellt den Kampf vor die Theorie,
damit man weiß, wofür man liest. Das Buch steht jetzt dort, wo die Frage
entsteht.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Ein Blatt mit drei Zeichen vor dem ersten Lauf | erklärt vor dem Sehen; wer es wegtippt, steht wie vorher da |
| Ein eigener Übungsraum vor Stufe 1 | neue Regeln im Package und ein Lauf, der nichts zahlt |
| Jedes Zeichen, bis man es einmal getan hat | braucht gespeicherte Schritte; ADR-0068 hat das ausgeschlossen |
| Erster Lauf ohne Uhr | ändert eine Kampfregel ([ADR-0046](0046-uhr-in-der-grube.md)) |
| Zeichen auch für Uhr und Ankündigungen des Wächters | von Frederik nicht gewählt |

## Konsequenzen

- Neu: `lib/action/lauf_zeichen.dart` (die Regel je Lauf, reines Dart),
  `lib/action/lauf_zeichen_view.dart` (die Darstellung). `ActionGame`
  nimmt die Zeichen als Parameter und meldet ihnen Weg und Schlag; der
  Prototyp im Entwicklermodus gibt keine mit.
- `ErsterStartStand` kennt `stufenGeschafft`. **Es bleiben dreizehn
  Stellen, an denen etwas zusammenläuft.**
- `PitScreen` liest jetzt `ersterStartProvider` und baut sich deshalb
  neu, sobald ein Lauf gebucht ist. Dabei kam ein alter Fehler hoch:
  Flame ruft im Bau `update(0)`, und der Bildzähler weckte die Kopfzeile
  mitten im Layout (`gotchas.md`). Gezählt wird jetzt nur, wenn Zeit
  vergangen ist.
- Ein drittes Zeichen ist ein Feld in `LaufZeichen` und ein Zweig in
  `LaufZeichenView`.

### Offen

- **Nicht gespielt, nicht am Handy.** Gerendert in 390 × 844 und
  angesehen sind das Geisterkreuz, das Zeichen am Helden und die
  Niederlage mit Buch.
- Ob zwei drehende Pfeile um die Waffe als „von selbst“ gelesen werden.
- Die Uhr, die Zeitkugeln, das Tor und die Ankündigungen des Wächters
  erklärt weiter nichts.
- Wer mit einer Fähigkeit in die Grube geht, erfährt nicht, dass Halten
  und Ziehen zielt.
- Das Buch führt ins Handbuch, und das ist fünf Lektionen lang, bevor
  der Baum aufgeht.
