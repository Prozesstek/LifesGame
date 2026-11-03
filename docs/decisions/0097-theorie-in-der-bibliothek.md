# ADR-0097: Die Theorie in der Bibliothek, der Mentor fragt ab

**Datum:** 03.11.2026
**Status:** Aktiv
**Entschieden von:** Frederik, mit einem Bild als Vorlage; drei Rückfragen wie empfohlen
**Ergänzt:** den Lesebildschirm vom 18.10. (Spielrunde) und 23.10. (Buch)

## Kontext

Frederik, mit einem Bild einer Bibliothek in Pixelart (Kamin, Regale, Sessel):

> Hintergrund bei Theorie einfügen (gemütlich, bibliothek, dunkles holz warmes
> holz). In Theorie Einheit: Weiter button weg, anzeigen durch icon dass es
> swipbar ist. In die richtung es weiter gehen kann eselsohr unten hin. Oben
> die balken weg und lieber darunter buchseiten mit 1/3 etc anzeigen. […] Buch
> öffnen animation und auch bei zurück/fertig buch schließ animation. Am rand
> erkennbar und auf welcher seite man ist. Richtiges buchfeeling

und danach:

> Am ende der seiten schließt sich das buch. Danach fragt der mentor einen ab.
> Er ist dann sichtbar mit der frage unter ihm antworten richtig im Holzbuttons
> Style. Antworten werden beim ersten mal klicken eingeloggt dann kommt unten der
> button Antworten und der charakter sagt das zum Mentor. Dialogstil.
> Hintergrund weiterhin bibliothek. Oben balken weg

Bis dahin lag die Seite auf Pergament über den ganzen Bildschirm, oben Striche
beim Lesen und ein Balken bei den Fragen, unten „Weiter“; eine Antwort zählte
mit dem ersten Tipp, das Urteil kam als Leiste von unten.

## Entscheidung

1. **Baum und Seite liegen vor der Bibliothek** (`assets/UI/Bibliothek.jpg`,
   Frederiks Bild, `Bibliothek`).
2. **Das Buch** klappt beim Öffnen auf und vor dem Zurück zu. Kein „Weiter“,
   keine Striche: Ein **Eselsohr** unten zeigt die Richtung und blättert auf
   Tipp, darunter steht „1 / 3“ mit einem Wisch-Zeichen. **Am Rand** zeigen
   Seitenkanten links das Gelesene, rechts den Rest. Über die letzte Seite
   hinaus klappt das Buch zu.
3. **Der Mentor fragt ab** (`MentorDialog`): oben er mit der Frage, darunter
   die Antworten als Holzknöpfe. Ein Tipp wählt nur, erst „Antworten“ zählt.
   Dann sagt die **eigene Figur samt Ausrüstung** die Antwort, und der Mentor
   antwortet — „Richtig!“ oder „Nicht ganz.“, die richtige Antwort und die
   Erklärung. Darunter „Weiter“ oder „Auswerten“. Kein Balken oben.
4. **Auch das Rätsel stellt der Mentor**, bevor das Buch aufgeht; danach
   „Buch öffnen“.

## Begründung

- Frederiks Rückfragen, je wie empfohlen: Der Mentor antwortet mit Urteil und
  Erklärung (statt nur Farbe); das Rätsel bleibt und stellt er; die Figur ist
  die eigene mit Ausrüstung.
- **Erst wählen, dann antworten** nimmt den Fehltipp heraus: Bis dahin zählte
  der erste Tipp, auch ein versehentlicher.
- Klang, Vibration, die zweite Runde für falsche Antworten (ADR-0055) und die
  Wertung bleiben, wie sie waren — nur der Zeitpunkt wandert vom Tipp auf
  „Antworten“.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Das Blatt auf das leere letzte umschlagen, dann Fragen (bisher) | Gewünscht: Das Buch schließt sich |
| Fortschritt als Balken behalten | Ausdrücklich: Balken weg |
| Antwort sofort beim ersten Tipp zählen | Ausdrücklich: erst „Antworten“ |

## Konsequenzen

- `RundenBalken`, `AntwortLeiste` und `QuestionCard` sind gelöscht; die
  Rückfrage des Tages hat ihre eigene Karte und ist nicht betroffen.
- **Eine Antwort braucht zwei Tipps statt einem.** Bei drei Fragen sind das drei
  Tipps mehr je Seite.
- Wie viele Fragen noch kommen, steht nur als „Frage 1 von 3“ in der Blase.
- Die Bibliothek ist ein gemaltes Bild, kein Pixelraster: Sie wird weich
  skaliert. Ihre Herkunft steht hier und in `state.md`: Frederiks Datei.
- Die Ergebnisseite liegt jetzt in einer Holzkarte vor der Bibliothek.
