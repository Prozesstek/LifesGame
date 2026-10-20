# ADR-0082: Nur eigene Fähigkeiten, Platz antippen und wählen

**Datum:** 20.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik (Issue #138)
**Ergänzt:** [ADR-0049](0049-faehigkeiten-bekommen-einen-eigenen-bereich.md), [ADR-0080](0080-die-sammlung.md)

## Kontext

Issue #138 (Frederik): „Es werden nur die Fähigkeiten angezeigt, welche
man aktuell besitzt […] Außerdem gibt es die Möglichkeit eine Fähigkeit
auszurüsten durch klicken auf den Platz und dann auf eine Fähigkeit.
Dabei shaken die Fähigkeiten dann leicht, damit der Nutzer erkennt dass
er was auswählen kann.“

Bis dahin zeigte der Bildschirm alle 39 Fähigkeiten und die
Ultimates, Gesperrtes grau, und ein Tipp auf eine graue öffnete ihr
Blatt mit allen Werten (ADR-0049: „Ein Ziel, das man nicht sieht, ist
keins“). Ein leerer Platz sagte nur, man solle eine Fähigkeit dorthin
ziehen.

## Entscheidung

- **Im Raster steht nur, was freigeschaltet ist**, Fähigkeiten wie
  Ultimates. Was es sonst gibt und woher, steht in der Sammlung.
- **Platz antippen, dann eine Fähigkeit**: Ein offener Platz (2 bis 4)
  wird gewählt, alles Eigene wackelt kurz und behält einen goldenen
  Rand, ein Tipp auf eine Fähigkeit legt sie dorthin. Ein zweiter Tipp
  auf den Platz bricht ab. Ziehen und das Blatt gehen weiter.
- **Der Waffenplatz** zeigt weiter seine Werte; er wird nicht gewählt.

## Begründung

- **Ein Platz wählt jetzt auch, wenn er belegt ist**: Wer auf einen
  belegten Platz tippt, will meist tauschen. Was die Fähigkeit darauf
  kann, zeigt ihr Blatt unten im Raster.
- **Das Wackeln endet** nach vier Schwüngen, der Rand bleibt: Dauernd
  wackelnde Kacheln wären unruhig, und `pumpAndSettle` käme nie zur
  Ruhe.
- **Nur, was dorthin passt, wackelt**: dieselbe Regel wie beim Ziehen,
  die belegten Plätze plus der nächste leere. Ein Platz weiter hinten
  sagt, welcher zuerst dran ist.

## Konsequenzen

- **Das volle Blatt einer gesperrten Fähigkeit ist nicht mehr zu
  sehen.** Die Sammlung zeigt bei einem Fragezeichen nur, woher es
  kommt (ADR-0080). Das Blatt kann es weiter (`AbilityCard` mit
  `unlocked: false`), aufgerufen wird es von keinem Bildschirm mehr.
  Wenn das fehlt: Die Sammlung könnte bei Fähigkeiten das volle Blatt
  öffnen.
- Ohne eigene Fähigkeit schickt ein Platz in die Sammlung.
- Der Mentor zeigt im Raster weiter auf die eine neue Fähigkeit
  (ADR-0079); dort steht ohnehin nur sie.
