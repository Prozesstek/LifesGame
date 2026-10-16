# ADR-0074: AktivesBretts zehn Fähigkeiten und zwei Ultimates

**Datum:** 16.10.2026
**Status:** Aktiv
**Entschieden von:** AktivesBrett, in zwei Fragerunden mit Claude
**Ergänzt:** [ADR-0073](0073-ultimate-mana-und-neue-arten.md) (die zweite
Hälfte von Issue #114)

## Kontext

Issue [#114](https://github.com/Prozesstek/LifesGame/issues/114) verlangt
von jedem Entwickler zehn Fähigkeiten und zwei Ultimates. Frederiks zwölf
sind mit ADR-0073 gebaut; AktivesBretts Zeilen in der Vorlage
[`faehigkeiten-2.md`](../vorlagen/faehigkeiten-2.md) waren leer.

ADR-0073 legt fest: **Gebaut wird, was eine Fähigkeit braucht.** Stacking
und Rage, Passiv, Unsichtbarkeit und Blink nutzte keine von Frederiks
zwölf; sie sollten kommen, sobald eine von AktivesBrett sie braucht.

Claude hat eine Liste vorgeschlagen, AktivesBrett hat sie übernommen —
mit **Spiegelbild als Episch** und den Ultimates **Bestform** und
**Rückspulen**.

## Entscheidung

**Die zehn:**

| Fähigkeit | Bausteine | Mana · Abkl. | Seltenheit | Quelle |
|---|---|---|---|---|
| Zinseszins | Stacking + Schlag | 10 · 2 s | Gewöhnlich | „Zwei Minuten reichen“ |
| Schattenschritt | Blink + Unsichtbarkeit | 18 · 9 s | Ungewöhnlich | „Warum keiner hilft“ |
| Kampfrausch | **Passiv**, Rage | – | Selten | „Gefühle regulieren“ |
| Kriegsschrei | Stun im Umkreis + Self-Buff | 24 · 15 s | Selten | „Wie ein Muskel wächst“ |
| Spiegelbild | Begleiter als Abbild | 28 · 22 s | **Episch** | „Sich selbst testen“ |
| Parade | Parade | 12 · 6 s | Ungewöhnlich | „Eine Überschrift ist keine Studie“ |
| Ruhepuls | **Passiv**, Mana | – | Gewöhnlich | „Schlaf & Regeneration“ |
| Kettenblitz | Kettenblitz | 22 · 6 s | Selten | „Medien & Information“ |
| Rammbock | Dash mit Aufprall | 20 · 9 s | Ungewöhnlich | „Technik vor Gewicht“ |
| Zweiter Atem | **Passiv**, einmal je Lauf | – | Episch | 7 Tage Kette |

**Die zwei Ultimates:** **Bestform** (acht Sekunden: Fähigkeiten +40 %,
kein Mana, Abklingzeit doppelt so schnell, Grundangriff +25 %, 40 %
weniger Schaden), über die neue Errungenschaft **„Sieben Tage in Form“**
(sieben Tagestruhen geöffnet). **Rückspulen** (zurück an Ort und Leben
von vor vier Sekunden, 1,5 s unverwundbar), über „Erinnerung ist kein
Video“.

**Gebaut sind dafür die fünf Arten aus ADR-0073, die noch fehlten**, und
vier neue:

| Art | Regel |
|---|---|
| Blink | nie durch eine Wand **oder das Tor**; ohne Ziel in Sicht dorthin, wohin der Held schaut |
| Unsichtbarkeit | Gegner handeln nicht, **der Wächter schon**; endet mit dem ersten eigenen Treffer, der härter trifft |
| Stacking | gezählt wird das Wirken, nicht der Schaden; mit Obergrenze |
| Rage | gezählt werden eingesteckte Treffer; mit Obergrenze; fällt ohne Treffer ab |
| Passiv | liegt auf einem Platz, **kein Knopf, kein Mana, keine Abklingzeit** |
| *neu:* Kettenblitz | springt nur auf Gegner, die vom Einschlag aus zu sehen sind, keinen zweimal |
| *neu:* Parade | fängt einen Treffer ganz ab, auch einen Pfeil; der Angreifer steht, der Wächter über die Leiste |
| *neu:* Bestform | ein Zustand auf Zeit; die Grenze des Grundangriffs gilt weiter |
| *neu:* Rückspulen | **nie über ein Tor zurück**, nie in einen Fels, nie mit weniger Leben als jetzt |

**Die Grenze des Grundangriffs ist jetzt eine Zahl**:
`ActionBalance.weaponBuffCap` = 1,25. Alles zusammen — Self-Buff, Rage,
Bestform — macht den Grundangriff höchstens so viel härter. ADR-0073
sagte „auf den Grundangriff nur leicht“, und am `SelfBuff` stand, ein
Test halte 1,25 fest; den Test gab es nicht. Jetzt gibt es Grenze und
Test.

## Begründung

**Bestform +40 % nur auf Fähigkeiten**, auf den Grundangriff +25 %
(AktivesBrett, nach Rückfrage): Ein Faktor auf das, was jede halbe
Sekunde fällt, entschiede den Kampf allein (ADR-0009). Kampfrausch fällt
unter dieselbe Grenze, obwohl er bis +40 % zählt.

**Der Wächter sieht durch die Unsichtbarkeit.** ADR-0073 fürchtete, wer
lange unsichtbar ist, schleiche bis zum Wächter, und der zahle den
ganzen Topf. Zwei Sekunden reichen dafür nicht; im Wächterraum aber, wo
er allein ist, gäbe es nichts zu umgehen — nur einen Wächter, der zwei
Sekunden nichts tut.

**Die Quellen verteilen sich über alle vier Wurzeln**: Körper und Geist
tragen zehn und elf von neunundzwanzig Knoten mit Fähigkeit,
Wissenschaft und Gesellschaft je vier. „Keines mehr als zwei Fünftel“
(`graph_content_test.dart`) hält; mit allen zehn unter Geist wäre es
gebrochen.

**„Sieben Tage in Form“ zählt Tagestruhen**, weil eine Truhe genau an
einem Tag aufgeht, an dem alles Fällige erledigt war — und diese Zahl
nur wachsen kann (ADR-0033). Sie liegt damit vor „Zehn Truhen“ und dem
Glückstrank; der Platz der Ultimate geht aber erst auf Level 15 auf.

**Die Bilder sind gezeichnet**, nicht aus dem Raven-Paket: Das Paket
liegt nur auf Frederiks Rechner. `tool/faehigkeit_icons.py` zeichnet sie
aus Formen; wer ein Raven-Bild lieber hat, legt es an dieselbe Stelle.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Bestform überall +40 % | bricht die Grenze des Grundangriffs (ADR-0009) |
| Bestform über 21 Tage Kette | AktivesBrett wollte die Tagesform als Quelle |
| Spiegelbild legendär | Legendär trägt bisher nur Sternenfall, ein Finisher; das Abbild schlägt mit halbem Grundangriff |
| Alle Quellen unter Geist | bricht „keines mehr als zwei Fünftel“ |
| Raven-Platzhalter, später getauscht | AktivesBrett: selbst zeichnen |
| Ein Passiv als ausgegrauter Knopf im Kampf | sähe aus wie ein Knopf, der nicht geht |

## Konsequenzen

- **Drei Passive** kosten je einen Platz ohne Knopf. Im Kampf steht ihr
  Bild, blasser, und nimmt keinen Tipp an.
- **`world.dart` wächst nicht weiter**: Der Zustand am Helden steht in
  `hero_states.dart`, die Ausführung in `effects.dart`.
- **Projektile kennen ihren Schützen** (`Projectile.ownerId`), sonst
  wüsste eine Parade nicht, wen sie stillstellt.
- **Die Simulation misst jede Fähigkeit einzeln**
  (`dart run tool/pit_sim.dart faehigkeiten`). Der Bot springt, pariert
  und spult nicht gezielt — die Zahlen sind eine untere Schranke.
- **Bestform ist gemessen zu stark**: Auf Stufe 13 (Tag 30) gewinnt der
  Bot mit ihr zu 100 %, ohne Ultimate zu 25 %, mit den anderen dreien
  zu 17 bis 42 %. Nicht nachgestellt; die Hebel sind die Dauer, die
  doppelte Abklingzeit und das freie Mana.
- **Nicht gespielt, nicht am Handy.** Ob die Parade mit 0,6 Sekunden zu
  knapp ist, ob drei Passive zu viel Platz kosten und ob Bestform sich
  wie eine Ultimate anfühlt, zeigt nur das Spielen.
- **Frederik hat diese Runde nicht gesehen.**
