# ADR-0024: Abgelöste Fähigkeiten fallen beim Laden aus dem Spielstand

**Datum:** 26.08.2026
**Status:** Aktiv
**Entschieden von:** AktivesBrett

## Kontext

Gemeldet mit Screenshot: Vier Fähigkeitsplätze belegt, der Charakter­bildschirm
sagt „Alle vier Plätze offen und belegt" — im Kampf stehen **drei** Knöpfe.
Es fehlt *Kraftschlag*.

Nachgestellt und bestätigt:

```
gespeichert:  [heavy_attack, steinhaut, sandsturm]
im Kampf:     [basic_attack, steinhaut, sandsturm]
im Katalog?   heavy_attack -> false
als Move?     heavy_attack -> true  (Kraftschlag)
```

**Die Ursache liegt in ADR-0022.** Mit dem Fähigkeiten-Set aus der Vorlage
wurde `AbilityCatalog.choosable` ausgetauscht: Die vier aus ADR-0017 —
Kraftschlag, Zehrung, Sammeln, Atemzug — fielen heraus. In `package:combat`
existieren sie weiter (die Gegner benutzen sie), im Katalog der wählbaren
nicht mehr.

Ein Spielstand, der einen davon auf einem freien Platz hielt, behielt ihn.
Und dann antworten zwei Stellen verschieden auf dieselbe Frage:

| Stelle | Frage | Antwort |
|---|---|---|
| `ability_slots_row.dart` | Was liegt auf diesem Platz? | `Moves.byId('heavy_attack')` → **Kraftschlag** |
| `activeMovesProvider` | Was geht in den Kampf? | nicht im Katalog → **fällt heraus** |

Der Platz war damit dauerhaft blockiert: sichtbar belegt, im Kampf
wirkungslos, ohne Meldung. Dass es den Spieler traf und nicht die
Testsuite, ist derselbe Fall wie zuletzt beim Gegner-Moveset.

## Entscheidung

**`ChosenAbilities.fromJson` streicht Move-Ids, die der Katalog nicht
kennt.** Ein Spielstand, der so eine Id hält, verliert sie beim nächsten
Laden; der Platz wird frei und lässt sich neu belegen.

## Begründung

**Das nimmt eine Regel aus ADR-0014 zurück, aber nur zur Hälfte.** Dort
steht: Der Spielstand hält eine *Wahl*, geprüft wird beim Zusammenstellen —
„eine Wahl bleibt erhalten, statt beim Laden still gelöscht zu werden".
Diese Regel ist gut und bleibt. Sie trägt aber nur, solange die Wahl
zurückkommen kann. Es sind zwei verschiedene Fragen:

| Frage | Hängt ab von | Kann zurückkommen? | Geprüft |
|---|---|---|---|
| Ist sie **verdient**? | vom Fortschritt | ja — Streak wächst, Knoten wird bestanden | beim Zusammenstellen |
| **Gibt es sie überhaupt**? | nur vom Katalog | **nein** — der Katalog ist Programmcode | beim Laden |

Eine unverdiente Fähigkeit stehen zu lassen ist Nachsicht. Eine Id stehen
zu lassen, die es im Programm nicht mehr gibt, ist ein blockierter Platz
auf unbestimmte Zeit.

**Beim Laden und nicht beim Anzeigen**, weil es sonst wieder zwei Stellen
wären: Der Charakterbildschirm müsste filtern, der Kampf filtert ohnehin,
und die nächste Ansicht müsste daran denken. Nach dem Laden enthält
`ChosenAbilities` nur noch Ids, die der Katalog kennt — danach kann keine
Ansicht mehr etwas anderes behaupten.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Platz sichtbar lassen, als ungültig markiert | Ehrlicher und erklärend, aber es bleibt ein Zustand, den jede neue Ansicht kennen muss. Und der Spieler kann mit „Kraftschlag ist weg" nichts anfangen, was er nicht schon beim Neubelegen erfährt |
| Platz einfach als leer zeigen, Id im Stand lassen | Verschiebt genau die Inkonsistenz, die den Fehler ausgemacht hat: Was gespeichert ist und was gezeigt wird, wären wieder zweierlei |
| Erst im Kampf filtern (Ist-Zustand) | Genau der gemeldete Fehler |
| Die vier alten wieder in den Katalog aufnehmen | Macht ADR-0022 rückgängig. Kraftschlag hat weder Timing-Werte noch Seltenheit noch eine Quelle im Baum |

## Konsequenzen

**Der gemeldete Fall repariert sich beim nächsten Start von selbst.** Wer
Kraftschlag liegen hatte, findet den Platz frei vor und kann ihn neu
belegen.

**Eine Streichung im Katalog ist ab jetzt eine Entscheidung mit Folgen für
Spielstände** — sie löscht stillschweigend Wahlen. Das steht als Warnung
am Katalog selbst.

**Der Entwicklermodus ist nicht betroffen**, obwohl der Fehler dort
auffiel: Er schenkt Freischaltungen, keine Move-Ids, die es nicht gibt.

**Unangenehm:** Ein Spieler bekommt keine Meldung darüber, dass ihm etwas
weggeräumt wurde. Bei einer Fähigkeit, die es nicht mehr gibt, ist wenig
zu erklären — aber es ist eine stille Änderung an fremden Daten, und das
ist der Preis dieser Entscheidung.

**Offen und ausdrücklich nicht mitgelöst:** Der *andere* Fall bleibt
unsichtbar. Eine Fähigkeit, die im Katalog steht, deren Bedingung gerade
aber nicht erfüllt ist, liegt weiter sichtbar auf ihrem Platz und fällt
im Kampf heraus. Erreichbar über den Entwicklermodus — Fähigkeit
schenken, anlegen, Zuschläge zurücksetzen. Das ist Absicht aus ADR-0014;
ob der Charakterbildschirm es kenntlich machen sollte, ist eine offene
Frage.
