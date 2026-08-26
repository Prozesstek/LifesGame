# ADR-0022: Das Fähigkeiten-Set kommt als Multiplikatoren ins Spiel, mit eigenem Timing je Fähigkeit

**Datum:** 26.08.2026
**Status:** Aktiv
**Entschieden von:** AktivesBrett

## Kontext

Es lag eine Vorlage vor: fünfzehn Fähigkeiten mit Name, Schaden, Effekt,
Timing, Energiekosten und Seltenheit, dazu vier Umgebungen und deren
Regeln. Sie füllt Ziel 5 aus `ziele.md` (Issue #17) und löst den
Zwischenstand aus ADR-0017 ab, der neun von zwanzig Fähigkeiten hatte.

**Die Vorlage trifft an drei Stellen auf gemessene Entscheidungen:**

1. **Sie nennt festen Schaden** (12, 34, 60). Die Engine rechnet
   `power × Angriffswert`, und der Angriffswert kommt aus den Gewohnheiten
   (13 bis 20).
2. **Ihre Perfect-Boni liegen bei +40 bis +50 %.** ADR-0009 hat den
   Timed-Hit-Deckel gemessen auf +20 % gesenkt, mit der Begründung: Ein
   pauschaler Faktor entscheidet den Kampf allein.
3. **Sie rechnet mit HP ~100.** Im Spiel sind es 160–224 beim Spieler und
   120–230 bei den Gegnern.

## Entscheidung

**1. Feste Zahlen werden in Multiplikatoren umgerechnet.**

```
power = Wert der Vorlage / 16
```

16 ist der mittlere Angriffswert eines Spielers. Bei genau diesem Wert
trifft jede Fähigkeit ihre Zahl auf den Punkt; die Rangfolge der fünfzehn
bleibt bei jedem Angriffswert erhalten, weil alle denselben Nenner teilen.

**2. Jede Fähigkeit bekommt einen eigenen Perfect-Faktor** (`perfectFactor`
am Move). Basisangriff und alle Waffenmoves lassen ihn auf `null` und
bleiben beim Deckel aus `Balance`.

**3. Schaden über Zeit ist ein Vielfaches des Angriffswerts**, nie eine
feste HP-Zahl und nie ein Anteil der maximalen HP.

**4. Verfehlen bestraft nur dort, wo die Vorlage es sagt** — allein
Sternenfall (`missFactor` 0,4).

**5. Timing ist eine Kampfregel.** Geschwindigkeit und Fensterbreite stehen
als `TimingSpec` am Move; `timing_rules.dart` verrechnet sie multiplikativ
mit Statuseffekten und Umgebung, begrenzt durch die Werte der Vorlage
(Speed 0,4×–4,0×, Fenster ≥ 3 %).

**6. Seltenheit ist ein Etikett.** Freigeschaltet wird weiter über die
Quellen aus ADR-0013.

**7. Elf Fähigkeiten hängen am Baum, vier an Streak-Marken.** Sternenfall
— die einzige legendäre — kommt ausschließlich über sechzig Tage Kette.

**8. Die Gegner benutzen sie mit**, gestaffelt: Wegelagerer nur Commons,
Söldner bis Uncommon, Bergwächter bis Rare. Epic und Legendary bleiben dem
Spieler.

**9. Die vier bisher wählbaren Fähigkeiten** (Kraftschlag, Zehrung,
Sammeln, Atemzug) sind nicht mehr wählbar.

## Begründung

**Warum Multiplikatoren und nicht die festen Zahlen.** Feste Zahlen wären
näher an der Vorlage und leichter vorherzusagen. Sie kappen aber die
Kopplung, auf der das ganze Produkt steht: `konzept.md` verspricht „Was du
im Alltag tust, macht deinen Charakter stark". Ein Sternenfall, der 60
Schaden macht, egal ob jemand dreißig Tage abgehakt hat oder null, nimmt
den Gewohnheiten genau dort die Wirkung, wo sie sichtbar sein soll.

**Warum der eigene Perfect-Faktor ADR-0009 nicht umkehrt.** Dort wurde ein
*pauschaler* Faktor auf jeden Treffer gemessen — 56 % Siegquote ohne
Timing gegen 100 % mit perfektem. Dieser Faktor gilt je Fähigkeit, kostet
Energie und hängt an einem engen Fenster: Sternenfall hat 4 % bei 3,0×.
Der Bonus ist verdient, nicht geschenkt. Entscheidend ist, dass der Move,
den man **jede Runde** drückt, weiter bei +20 % bleibt — genau dort galt
die Messung. `abilities_mechanics_test.dart` hält das fest.

**Warum Dauerschaden am Angriffswert hängt.** Feste HP wirken bei 120 und
bei 230 HP völlig verschieden. Anteile der maximalen HP haben schon einmal
dafür gesorgt, dass Kämpfe nicht mehr endeten (`gotchas.md`, ADR-0009).
Gift rechnet seit jeher so.

**Warum das Timing in `package:combat` liegt.** Wie schwer ein Treffer ist,
entscheidet mit, was eine Fähigkeit wert ist — das ist eine Regel, keine
Darstellung. Läge es im Bildschirm, müsste dieser Statuseffekte und
Umgebungen auswerten und damit Spielregeln kennen (ADR-0002).

**Warum nach Gebiet und nicht nach Tiefe verteilt.** Der Baum ist genau
eine Ebene tief: Alle zwanzig Unterknoten hängen direkt an den vier
Wurzeln und kosten je einen Punkt (ADR-0019). Eine Staffelung nach Tiefe
gibt es nicht zu holen. Was früh von spät trennt, ist die **Energie**:
Vulkanbruch kostet 8, Sternenfall 10, und das Maximum kommt aus Klarheit.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Feste Schadenszahlen wie in der Vorlage | Kappt die Kopplung an die Gewohnheiten — die Kernaussage des Produkts |
| Sockel plus Skalierung (`6 + 0,4 × ATK`) | Zwei Zahlen je Fähigkeit, und die ganze Balance müsste neu gefahren werden |
| Perfect-Deckel für alle beibehalten | Nimmt schweren Fähigkeiten ihren Reiz; ein 4-%-Fenster ohne höheren Lohn ist nur Ärger |
| Perfect-Faktor auch für Basis- und Waffenmoves | Genau der gemessene Fall aus ADR-0009 — Dauerbonus auf den Move, den man immer drückt |
| Seltenheit als eigenes Freischaltsystem | Löst ADR-0017 ab, ohne dass ein Problem dazu drängt |
| Legendary im Baum | Ausdrücklich anders entschieden: Sternenfall belohnt Durchhalten, nicht Lesen |
| Gegner ohne die neuen Fähigkeiten | Umgebungen wirken laut Vorlage auf beide Seiten — einseitig wäre die halbe Mechanik |
| Timing-Werte im Bildschirm | Der Bildschirm müsste Statuseffekte und Umgebungen auswerten (ADR-0002) |

## Konsequenzen

**Leichter:** Eine neue Fähigkeit ist ein Eintrag in `ability_moves.dart`
plus einer in `ability_catalog.dart`. Die Engine muss dafür nicht
angefasst werden — dreizehn Wirkungen, vier Umgebungen und der
Mehrfachtreffer stehen bereit.

**Ziel 5 ist erfüllt:** fünfzehn wählbare Fähigkeiten statt vier, mit Art,
Seltenheit und eigenem Timing.

**Schwerer, und das ist der ernste Teil:** Die Balance ist **nicht**
nachgezogen. Bewusst zurückgestellt, aber die Simulation zeigt eine klare
Verschiebung gegenüber ADR-0009:

| Gegner | Tag 0 | Tag 7 | Tag 14 | Tag 21 | Tag 30 | Tag 60 |
|---|---|---|---|---|---|---|
| Wegelagerer | 0 % | 94 % | 100 % | 100 % | 100 % | 100 % |
| Söldner | 0 % | 0 % | 0 % | 38 % | 100 % | 100 % |
| **Bergwächter** | 0 % | 0 % | 0 % | 0 % | **0 %** | **0 %** |

**Der Bergwächter ist unschlagbar geworden.** In ADR-0009 stand er bei
36 % an Tag 30 und 100 % an Tag 60. Die Ursache ist benannt und nicht
geheimnisvoll: Er trägt jetzt Donnerkeil (`power` 2,125) und Seelenraub,
während die Fähigkeiten, die der Spieler früh bekommt, **schwächer sind
als sein Basisangriff** — Funkenstoß hat 0,75 gegen 1,0 beim Bogenschuss
und kostet zusätzlich Energie.

Das ist kein Fehler in der Umsetzung, sondern die Vorlage, ehrlich
umgerechnet: Ihre Commons sind Werkzeuge mit Perfect-Effekten, keine
Schadensquellen. Wer das tarieren will, hat drei Hebel — die Gegner-Sets,
die `power`-Werte der Commons, oder den Nenner 16.

**Die Simulation hat vorher nichts gemessen.** `_loadoutNach` fragte mit
`AbilityProgress.empty()`, und seit ADR-0019 schaltet ein leerer
Fortschritt nichts frei — der simulierte Spieler kämpfte an jedem Tag mit
einem einzigen Move. Sie nimmt jetzt an, dass die Kette nie reißt und
jeder Theoriepunkt in einen Knoten mit Fähigkeit geht; beide Annahmen
stehen im Code und machen das Ergebnis zur **oberen** Schranke.

**Offen:** Die Umgebungen haben noch kein Bild. Beim Setzen leuchten beide
Kämpfer kurz auf; Lava, Sandschleier und Nebel aus den Animationsideen der
Vorlage fehlen.
