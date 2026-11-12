# ADR-0103: Ein gelber Punkt für Neues

**Datum:** 11.11.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Frederik: „Immer wo es etwas Neues gibt wird ein gelber Punkt angezeigt
(z.B. Rückfrage offen bei Theorie, neue Fähigkeiten oder Items etc)“.

Den gelben Punkt gab es schon (`ZielPunkt`, ADR-0095), aber nur für den
Mentor im Tutorial. Nach dem Tutorial sagte nichts, wo sich etwas
geändert hat.

## Entscheidung

Jedes Neue hat eine **Marke** (`rueckfrage:<Tag>`, `faehigkeit:<Id>`,
`stueck:<uid>` …), gerechnet in `neuMarkenProvider`. Ein Kreis trägt den
Punkt, solange eine seiner Marken nicht gesehen ist:

| Ort | Marke |
|---|---|
| Theorie | Rückfrage offen; ein Talentpunkt frei (je Level eine) |
| Kampf | Tagesdungeon heute offen |
| Fähigkeiten | jede freigeschaltete Fähigkeit |
| Laden | jeder Tag |
| Ausrüstung | jedes Exemplar |
| Lagerfeuer | was dort heute wartet |

**Beim Öffnen des Kreises** gilt alles dort als gesehen. **Innen** tragen
neue Fähigkeiten und Stücke einen kleinen Punkt, bis sie angetippt sind;
Angelegtes nie. Im Tutorial steht kein Punkt — dort zeigt der Mentor mit
demselben.

Gespeichert wird, **was gesehen ist** (`SaveData.neu`, `NeuGesehen`), und
nur, was es noch gibt.

## Begründung

Gewählt wurden alle Auslöser, „weg beim Öffnen des Kreises“ (gegen die
Empfehlung „wenn erledigt“) und „innen am Neuen“.

Gespeichert werden muss es: Abgeleitet ließe sich nur sagen, *dass* es
etwas gibt, nicht, ob man es schon gesehen hat. Ohne Speicher stünden
nach jedem Neustart überall Punkte.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Punkt bleibt, bis erledigt | nicht gewählt — man soll ihn wegklicken können |
| Nur am Kreis | nicht gewählt — innen fände man das Neue nicht |
| Nur für die Sitzung merken | nach jedem Neustart wieder alles neu |

## Konsequenzen

- **Ein Stand von vor dem Punkt** hat kein `neu`: Dann gilt alles, was er
  schon hat, als gesehen (`NeuGesehenController.build`). Sonst stünden
  nach dem Update überall Punkte.
- **Eine Ausnahme von „gespeichert wird, was der Nutzer getan hat“**
  (`SaveData`): Gesehenes ist kein Ergebnis, sondern Anzeige. Es steht in
  `lib/`, weil kein Package Anzeige kennt.
- Der Export trägt das Feld mit (`save_transfer_test.dart` vergleicht
  ohne es).
- Laden und Kampf tragen fast täglich einen Punkt, die Theorie nach jedem
  Aufstieg. Ob das zu viel ist, zeigt das Spielen.
- Ein freier Fähigkeitsplatz trägt keinen Punkt, nur neue Fähigkeiten.
