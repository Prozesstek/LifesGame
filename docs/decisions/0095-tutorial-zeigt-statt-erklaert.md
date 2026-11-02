# ADR-0095: Das Tutorial zeigt, statt zu erklären

**Datum:** 02.11.2026
**Status:** Aktiv
**Entschieden von:** Frederik, in einer Fragerunde viermal wie empfohlen
**Ergänzt:** [ADR-0079](0079-der-mentor.md) (der Mentor; seine Schritte gelten weiter)

## Kontext

Der Mentor (ADR-0079) führt einen Neuen in fünf Schritten bis zum ersten Sieg.
Er sprach dabei in ganzen Sätzen und zeigte mit einem goldenen Ring auf sein
Ziel. Alles andere auf dem Bildschirm stand gleich hell daneben, und die
untere Holzleiste stand leer da, bis ihr erster Kreis kam.

Frederik: „Tutorial weiterausarbeiten (weniger anzeigen, mehr Visualisieren wo
was hingeht). wenn zum beispiel keiner der unteren buttons da ist kann das auch
erstmal ausgeblendet werden und mit einer animation dann eingeblendet werden.
Außerdem könnte ein gelber Punkt hinweisen wo es hingeht. (Sachen leicht
ausblenden oder dunkler machen die gerade nicht wichtig sind, Spotlight Effekt
etc)“

## Entscheidung

| Was | Wie |
|---|---|
| **Scheinwerfer** | ein dunkler Schleier über dem Bildschirm, nur das Ziel liegt im Licht (`Scheinwerfer`) |
| **Gelber Punkt** | pulsiert oben rechts am Ziel und bleibt dann stehen (`ZielPunkt`), an allen vier Orten; der Goldring ist weg |
| **Text** | ein paar Wörter statt Sätzen: „Geschafft? Hak es ab!“, „Ab in den Dungeon!“ |
| **Untere Leiste** | fehlt, bis ihr erster Kreis kommt, und fährt dann von unten herein (`EinblendLeiste`) |

**Der Schleier sperrt nichts.** Was im Dunkeln liegt, lässt sich weiter
antippen: Der Mentor zeigt, er sperrt nicht (ADR-0079).

## Begründung

- Ein Neuer liest kaum (ADR-0060). Licht und Punkt sagen „hier“, ohne dass man
  lesen muss; die Wörter sagen nur noch „was“.
- Der Schleier mit Loch ist das Muster, das Spieler aus Handyspielen kennen.
- Ein sperrender Schleier wäre härter geführt, nähme dem Spieler aber den Weg
  zurück, und ADR-0079 schließt ihn aus.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Text ganz weg | ohne ein Wort fehlt das „warum“ beim ersten Mal |
| nur andere Kreise abdunkeln | sanfter, aber Karten und Leisten stünden weiter gleich hell da |
| sperrender Schleier | widerspricht ADR-0079 |
| Punkt nur auf der Startseite | drinnen bliebe der alte Ring, zwei Sprachen für dieselbe Sache |
| Punkt plus Ring | doppelt |

## Konsequenzen

- **Ein Ziel meldet sich an** (`ScheinwerferZiel`), der Schleier fragt nicht
  selbst. Wer dem Mentor ein neues Ziel gibt, legt `Zeigefinger` darum; ein
  Ziel ohne Punkt, wie die Plätze der Fähigkeiten, nimmt `ScheinwerferZiel`.
- **Der Scheinwerfer steht immer in `MentorFlaeche`**, auch wenn der Mentor
  schweigt; ohne Ziel ist er unsichtbar. Fiele er weg, baute sich der
  Bildschirm darunter neu (`gotchas.md`).
- Die Kopfzeile eines Bildschirms (`AppBar`) liegt außerhalb und bleibt hell.
- Im Debug-Build hängt der Knopf des Entwicklermodus in der unteren Leiste;
  solange sie fehlt, steht er allein unten rechts.
- Der Beute-Dialog des ersten Siegs trägt den Punkt, aber keinen Schleier: Der
  Dialog dunkelt selbst ab.
