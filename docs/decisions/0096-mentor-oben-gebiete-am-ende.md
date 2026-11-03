# ADR-0096: Der Mentor steht oben, die Gebiete kommen am Ende

**Datum:** 03.11.2026
**Status:** Aktiv
**Entschieden von:** Frederik, Issue #183 mit Skizze; zwei Rückfragen wie empfohlen
**Ergänzt:** [ADR-0079](0079-der-mentor.md), [ADR-0095](0095-tutorial-zeigt-statt-erklaert.md)

## Kontext

Issue #183 („Tutorialscreen 1“), mit einer Skizze auf dem ersten Bildschirm:

> Was willst du jeden Tag tun entfernen · Mentor im gesamten Tutorial über dem
> Text anordnen. (Man liest von oben nach unten) · Plus in grün einfärben ·
> Stats Symbole recht von der Gewohnheit entfernen. · Die Gebietslevel müssen
> irgendwo kurz erklärt werden (ans Ende) · Freund anrufen entfernen · „etwas
> eigenes“ muss erkennbar anklickbar sein · Ich habe schon einen Stand
> rauswerfen · Erst mentor dann nach einander reinfliegen lassen (animation)

Bis dahin stand der Kasten des Mentors meist **unten**, über dem Inhalt
schwebend, gegenüber seinem Ziel. Auf der Startseite stand die Frage zweimal da
(Mentor und Überschrift der Karte), neben jedem Vorschlag das Zeichen seines
Kampfwerts, ohne dass irgendwo stand, was es bedeutet.

## Entscheidung

1. **Der Mentor steht immer oben**, im Fluss des Bildschirms (`MentorZeile`):
   Er schiebt den Inhalt nach unten, statt ihn zuzudecken. `KastenLage` gibt es
   nicht mehr. Auf der Startseite steht er in derselben Spalte wie die erste
   Frage und rückt mit ihr in die Mitte.
2. **Die erste Karte** hat keine Überschrift mehr, zwei Vorschläge (Zwei
   Minuten lesen, Spazieren gehen), „Etwas Eigenes“ als Zeile wie die anderen,
   rechts je ein grünes Plus, keine Kampfwert-Zeichen, kein „Ich habe schon
   einen Stand“. Die Zeilen fliegen nach dem Mentor nacheinander von unten
   herein.
3. **Ein neuer letzter Schritt, `Schritt.gebiete`**: Nach dem ersten Sieg sagt
   der Mentor auf der Startseite „Gewohnheiten füllen ihr Gebiet, jedes stärkt
   im Kampf. Leg eine zweite an!“, und der Kreis der Gewohnheiten liegt im
   Licht. Er bleibt, bis je zwei verschiedene Gewohnheiten liefen.

## Begründung

- **Oben, weil man von oben nach unten liest** (Frederik). Der Kasten muss dafür
  im Licht liegen; er meldet sich als **Begleiter** beim Scheinwerfer an — er
  liegt im Licht, wenn ein anderes Ziel den Schleier aufzieht, zieht aber
  allein keinen auf.
- **Die Gebiete am Ende**, weil sie vorher nichts bedeuten: Wer noch keine
  Gewohnheit hat, kann mit Angriff, Mana, Abwehr und Leben nichts anfangen.
  Nach dem ersten Sieg hat er gekämpft und zwei neue Plätze bekommen
  (ADR-0093) — der Satz erklärt beides und gibt den nächsten Schritt.
- **Abgeleitet, nicht gespeichert** (ADR-0068): Das Ende hängt an einer Zahl,
  die nur wächst — Gewohnheiten, die je liefen (abgehakt, mit Plan oder eigene).
  Ein „gesehen“-Flag hätte einen neuen Teil im Spielstand gebraucht.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Kasten oben, aber weiter schwebend | Er deckte Level, Gold oder den Anfang der Liste zu |
| Erklärung unten in der ersten Karte | Gefragt war „ans Ende“; am Anfang ist es eine Zeile mehr zum Lesen |
| Erklärung im Beute-Dialog des ersten Siegs | Dort steht schon die Beute und die zwei Plätze |
| Den Stand-Import klein auf der Startseite lassen | Frederik: rauswerfen. Einfügen geht im Charakter |

## Konsequenzen

- **Ein eingefügter Stand braucht jetzt Level 2**: Der einzige Weg zum
  Einfügen ist der Charakter, und dessen Kreis kommt mit Level 2. Wer umzieht,
  legt kurz eine Gewohnheit an, hakt ab und fügt dann ein.
- **Der Mentor spricht nach dem ersten Sieg noch einmal.** Wer schon zwei
  Gewohnheiten hatte, hört ihn nicht; wer bei einer bleibt, hört ihn, bis er
  eine zweite anlegt — er sperrt dabei nichts.
- `ErsterStart.mentorFertig` heißt weiter „erster Sieg“: Die Plätze für
  Gewohnheiten hängen daran (ADR-0093), nicht am letzten Satz.
- Der Satz der Gebiete ist mit zwölf Wörtern länger als die acht aus ADR-0095;
  der Test lässt ihn wie `ersteBeute` zu.
