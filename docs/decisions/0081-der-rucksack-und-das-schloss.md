# ADR-0081: Der Rucksack und das Schloss

**Datum:** 20.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik, in der Fragerunde zu ADR-0080
**Ergänzt:** [ADR-0048](0048-exemplare-tagesladen-und-beute.md), [ADR-0057](0057-ausruestung-bekommt-einen-eigenen-bereich.md), [ADR-0080](0080-die-sammlung.md)

## Kontext

Issue #137 (Frederik): „Inventar wie bei Diablo etc. mit allen was man
aktuell hat. […] beim Inventar die Besser/Schlechter/Gleich Anzeige mit
Pfeilen bei den Items sowie einen Alles verkaufen Knopf nach Seltenheit
für Items die schlechter sind. Möglichkeit Items zu locken um Items
davon auszuschließen.“

Bis dahin stand unter den sechs Plätzen der ganze Katalog, ein Stück je
Kachel mit „×2“, wenn man es mehrfach hatte. „Alles Schlechtere
verkaufen“ war ein Knopf für alles und ließ Set-Teile, Episches,
Legendäres und fremde Waffen immer liegen (Issue #88), weil ihr Wert
nicht in der Zahl steckt.

## Entscheidung

| Frage | Antwort |
|---|---|
| Wie steht das Inventar da | **jedes Exemplar eine Kachel**, wie bei Diablo |
| Was „Alles verkaufen“ anfasst | **alles Schlechtere außer Gesperrtes**, auch Episches, Legendäres, Set-Teile und fremde Waffen |

Gebaut daraus:

- **Der Rucksack**: was man hat und nicht trägt, eine Kachel je
  Exemplar, in den vier Ordnungen von vorher. Gezogen wird genau das
  Exemplar, das man hält; was man nie hatte, steht in der Sammlung.
- **Der Pfeil** (`Loadout.vergleiche`): grün hoch, wenn es besser ist
  als das Getragene, braun gleich, rot runter. **Erst die Seltenheit,
  dann die Summe der Werte.** Ein leerer Platz macht alles besser.
- **Aufräumen je Seltenheit** (`Loadout.junkOf`): ein Knopf für jede
  Seltenheit, in der etwas liegt, das nicht besser ist als das
  Getragene, mit Zahl und Erlös.
- **Das Schloss** (`Loadout.toggleLock`), im Blatt eines Stücks je
  Exemplar. Gesperrtes lässt sich weder einzeln noch beim Aufräumen
  verkaufen; das Paket hält das fest, nicht nur der Bildschirm.

## Begründung

- **Seltenheit vor Summe**, weil Waffe und Rüstung im Kampf mit ihrer
  Seltenheit vervielfachen (ADR-0042); ein paar Punkte Wurf wiegen das
  nicht auf. Dieselbe Regel galt schon für den Ausschuss.
- **„Nicht besser“ statt „schlechter“** beim Aufräumen, wie bisher:
  Ein zweites Exemplar mit genau demselben Wurf bringt nichts.
- **Keine Ausnahmen mehr**, weil es jetzt das Schloss gibt: Wer ein
  Set-Teil oder eine andere Waffe behalten will, sperrt sie, statt dass
  das Spiel es für alle entscheidet.
- **Das Schloss gilt im Paket**: `sellAll` lässt Gesperrtes liegen, egal
  wer es hereinreicht. Ein Knopf, der es vergisst, kann nichts kaputt
  machen.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Je Stück eine Kachel mit Zahl | Pfeil und Schloss gehören zu einem Exemplar, nicht zu einem Katalogstück. |
| Aufräumen wie bisher, ohne Episches, Set-Teile, fremde Waffen | Frederik wählte „alles Schlechtere außer Gesperrtes“; das Schloss übernimmt den Schutz. |

## Konsequenzen

- **Wer bisher auf die Ausnahmen gezählt hat, muss sperren**: Ein
  episches Stück unter einem legendären auf demselben Platz liegt jetzt
  beim Aufräumen mit im Korb. Die Rückfrage nennt Zahl und Erlös.
- Gespeichert wird neu, was gesperrt ist (`locked` im `Loadout`), nur
  wenn etwas gesperrt ist; ein alter Stand liest sich unverändert.
- Ein Exemplar lässt sich nicht mehr über das Katalogstück ziehen
  („das beste kommt drauf“); man zieht das, das man meint.
- Das Blatt eines Stücks, das man nicht hat, öffnet man nur noch aus der
  Sammlung — dort aber nur für Gesammeltes; ein Fragezeichen zeigt nur,
  woher.
