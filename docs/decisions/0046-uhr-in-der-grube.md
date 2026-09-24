# ADR-0046: Eine Uhr in der Grube, auffüllbar über Zeitkugeln

**Datum:** 24.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Die Grube kannte keine Zeit. Wer gut kiten kann, zieht jede Traube im
Kreis, bis sie liegt, und kommt so durch Stufen, die er im direkten Kampf
nicht schaffen würde. Das wertet die Machtkurve ab (ADR-0042): Ein
schwacher Held ersetzt Stärke durch Geduld.

Frederik: „Zeitlimit für Dungeon (maybe durch random Zeitdrops
auffüllbar). Das soll verhindern, dass Leute, die extrem gut kiten
können, einfach durchgehen.“

## Entscheidung

Jede Stufe hat ein Limit: **45 s plus 25 s je Raum vor dem Wächter**
(`PitStage.timeLimitSeconds`, Stufe 1: 120 s, Stufe 30: 170 s). Läuft die
Uhr ab, ist der Lauf verloren; was gefallen ist, bleibt (ADR-0041).
Gefallene Gegner lassen zu **15 %** eine Zeitkugel fallen, die **8 s**
bringt, nie über das Limit hinaus. Der Wächter lässt keine fallen.

## Begründung

Das Limit ist am `PitBot` gemessen, der geradewegs durchgeht: Seine
gewonnenen Läufe brauchten höchstens rund 17 s je Raum, auf Stufe 30
insgesamt 87 s. Das Limit liegt bei etwa dem Doppelten. In 1.800 Läufen
der Simulation ist die Uhr kein einziges Mal abgelaufen. Wer kämpft,
merkt sie kaum; wer kitet, braucht ein Vielfaches.

**Nie über das Limit** heisst: auffüllen, nicht ansparen. Sonst kaufte
sich ein langsamer Anfang später ein Polster.

Die Uhr gibt es nur mit Stufe. Die Halle des Prototyps und die Tests
ohne Stufe laufen ohne sie.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Gegner werden mit der Zeit stärker | wirkt erst spät und unsichtbar; die Uhr sagt es vorher |
| Limit je Raum statt je Lauf | bestraft einen schweren Raum, statt den ganzen Lauf zu messen |
| Zeitkugeln unbegrenzt ansparen | ein früher Vorrat hebelte die Uhr aus |
| Kiten mechanisch erschweren (Gegner schneller) | trifft alle, nicht nur die Geduldigen |

## Konsequenzen

- Leichter: Die Machtkurve zählt wieder, eine Stufe über der eigenen
  Stärke ist nicht mehr nur eine Frage der Geduld.
- Schwerer: **Wer die Grube erkundet**, statt zum Wächter zu gehen, spürt
  die Uhr. Ob 25 s je Raum für einen Menschen reichen, der zum ersten Mal
  eine gebaute Grube sieht, sagt erst das Spielen, nicht der Bot.
- Die Zeitkugeln verbrauchen Würfe aus dem gesäten Zufall. Gebaute
  Läufe mit Stufe verlaufen dadurch anders als vorher, bei gleichem
  Startwert.
