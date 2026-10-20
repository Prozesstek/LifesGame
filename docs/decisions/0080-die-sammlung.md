# ADR-0080: Die Sammlung

**Datum:** 20.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik, in zwei Fragerunden mit Claude
**Ergänzt:** [ADR-0033](0033-errungenschaften-aus-der-historie.md) (die Errungenschaften ziehen um), [ADR-0049](0049-faehigkeiten-bekommen-einen-eigenen-bereich.md), [ADR-0057](0057-ausruestung-bekommt-einen-eigenen-bereich.md)

## Kontext

Issue #137 (Ausrüstung) und #138 (Fähigkeiten), beide von Frederik:
Die beiden Bildschirme sollen nur noch zeigen, was man **hat**. Was es
sonst gibt, steht in einer **Sammlung**: „Da gibt es die Kategorien:
Ausrüstung, Fähigkeiten, Gegner etc. mit Prozentzahl wieviel man
bekommen hat.“ Was man noch nie hatte, ist ein Fragezeichen, „und diese
füllt sich nach und nach“.

Bis dahin zeigten Ausrüstung (ADR-0057) und Fähigkeiten (ADR-0049) den
ganzen Katalog, Nicht-Besessenes grau. Die Errungenschaften hatten einen
eigenen Bildschirm vom Charakter aus (ADR-0033). Welche Gegner jemand
besiegt hat, stand nirgends.

## Entscheidung

| Frage | Antwort |
|---|---|
| Welche Reiter | Ausrüstung, Fähigkeiten, **Gegner und Wächter, Titel, Seiten, Errungenschaften** |
| Was ein Fragezeichen verrät | Bild und Name verdeckt, **ein Tipp sagt, woher** |
| Die Errungenschaften | **ziehen ganz um**; die Karte im Charakter führt in die Sammlung |
| Wann ein Gegner gesammelt ist | **in Stufen**: „1 mal besiegt, 10 mal besiegt etc.“ |
| Wo es hineingeht | ein Knopf oben rechts in Ausrüstung und Fähigkeiten |

Gebaut daraus:

- `lib/sammlung/`: der Bildschirm mit sechs Reitern, je einer mit
  Prozent, und oben die ganze Sammlung in einer Zahl. Was in welchem
  Reiter steht und woher es kommt, rechnet `Sammlung` an einer Stelle.
- **Das Bestiarium** (`packages/action_combat`, `Bestiarium`): wie oft
  jede Art und jeder Wächter fiel, gespeichert im Stand der Reihe
  (`LadderProgress.bestiarium`). Grube und Tagesgrube zählen beide.
- **Stufen**: Gegner bei 1, 10 und 100 Siegen, Wächter bei 1, 5 und 25.
  Jede Stufe ist ein Stern und zählt in die Prozente.
- **Die Errungenschaften** sind jetzt eine Ansicht
  (`ErrungenschaftenAnsicht`) im letzten Reiter, nicht mehr ein eigener
  Bildschirm.

## Begründung

- **Die Ausrüstung zählt „je besessen“**, wie die Errungenschaften
  (`Loadout.everOwnedIds`): Wer ein Stück verkauft, verliert es nicht
  aus der Sammlung. Sonst bestrafte das Aufräumen das Sammeln.
- **Abgeleitet, wo es geht.** Ausrüstung, Fähigkeiten, Titel, Seiten
  und Errungenschaften stehen schon im Stand; neu gespeichert wird nur
  das Bestiarium, weil Siege je Art nirgends standen.
- **Im Stand der Reihe, nicht als neuer Bereich**: So braucht der
  Spielstand keinen neuen Eintrag in `SaveWatcher`, und das Bestiarium
  wird mit der Reihe gespeichert und eingefügt.
- **Wächter in kleineren Schritten**: Er fällt einmal je gewonnenem
  Lauf, ein Gegner zwanzigmal.
- **Ohne den Schleimling**: Er entsteht nur aus einem Schleim und steht
  in keinem Raum (ADR-0063). Was im Lauf entsteht, zählt nicht, wie beim
  Topf.
- **Eine Entdeckung verrät sich auch hier nicht** (ADR-0033): Ihr Titel
  sagt beim Tipp nur, dass es eine Entdeckung ist.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Fragezeichen ganz verdeckt | Man wüsste nicht, wo man suchen soll. |
| Umriss als Schatten sichtbar | Frederik wählte den Hinweis auf Tipp. |
| Errungenschaften als Kategorie neben dem alten Bildschirm | Zwei Stellen für dieselbe Liste. |
| Gegner „einmal gesehen“ | Weniger verdient; Frederik wollte Stufen. |
| Ein achter Kreis auf der Startseite | Die untere Reihe ist voll. |

## Konsequenzen

- **Das Bestiarium zählt erst ab jetzt.** Jeder Stand, auch eurer,
  fängt bei den Gegnern bei null an.
- **Ein abgebrochener Lauf zählt nicht**, wie er auch nichts einbringt;
  gebucht wird am Ende.
- Die Reiter stehen in zwei Reihen, nicht in einer Zeile, die man
  wischt: Sonst lägen am Handy drei außerhalb des Bildes.
- Ausrüstung und Fähigkeiten zeigen bis zu ihrem eigenen Umbau (#137,
  #138) weiter den ganzen Katalog; der Knopf zur Sammlung steht schon da.
- „10 Ruhm“ oben in den Errungenschaften stand dunkelbraun auf dunklem
  Leder und ist jetzt in den Farben für dunklen Grund.
