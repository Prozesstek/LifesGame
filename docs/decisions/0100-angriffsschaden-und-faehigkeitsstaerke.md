# ADR-0100: Angriffsschaden und Fähigkeitsstärke

**Datum:** 08.11.2026
**Status:** Aktiv
**Entschieden von:** Frederik
**Ergänzt:** ADR-0088 (Geist steigert nicht mehr Mana), ADR-0039 (Mana kommt aus dem Level)

## Kontext

Frederik, Level 30, viel Geist: „Jetzt hab ich zwar massig Mana aber
keinen Schaden.“ Seit ADR-0088 steigert jedes Gebiet einen Kampfwert,
und Geist steigerte Mana. Jeder Schaden des Helden rechnete aber mit dem
Angriff (`Angriff × power`), und der kam nur aus Körper.

Frederik wollte es wie das Item-System von League of Legends: Fähigkeiten
skalieren mit Angriffsschaden, Fähigkeitsstärke oder beidem, und Mana,
Manaregeneration und Abklingzeit kommen aus der Ausrüstung. Die Vorlage
[`skalierung.md`](../vorlagen/skalierung.md) haben er und Claude am
08.11.2026 durchgesprochen, die Einteilung hat er abgenommen („Find ich
alles gut so“).

## Entscheidung

1. **Geist steigert die Fähigkeitsstärke**, mit derselben Kurve wie der
   Angriff (13 bis 20). Die Tagesform von Geist hebt sie.
2. **Jede Fähigkeit trägt einen Anteil** `fs` (0 bis 1). Schaden ist
   `power × ((1 − fs) × AS + fs × FS)`; ohne eigene Fähigkeitsstärke gilt
   der Angriff, sodass jede Zahl gleich bleibt, solange beide gleich sind.
   Heilung und Schutz wachsen mit `FS / AS`, gedeckelt bei 0,75 bis 1,5.
   Umgerechnet wird beim Betreten der Grube über die Veränderungen der
   Sets (`PitSkalierung`), die Welt kennt nur das Ergebnis.
3. **Mana, Nachfluss und Schlagtempo kommen aus dem Level**
   (`ActionBalance.energyAt`: 8 bis 12, dieselbe Spanne wie vorher die
   Klarheit) und aus der Ausrüstung.
4. **Die Ausrüstung bekommt drei Werte**: Fähigkeitsstärke,
   Manaregeneration, Abklingzeit (höchstens 40 %). Energie heißt Mana.
   Alte Exemplare eines geänderten Stücks gelten beim Laden mit 100 %.
5. **Zauberwaffen** (Frederik: „Ja find ich super“): Ein Stab schlägt
   mit der Fähigkeitsstärke (`PitWeapon.fs`). Vier neue Stäbe —
   Eichenstab, Wanderstab, Runenstab, Sternenstab —, mit dem Kriegsstab
   einer je Seltenheit.

## Begründung

Gemessen mit `dart run tool/pit_sim.dart skalierung` (Tag 30, volle
Ausrüstung, Stufe 24):

| Held | ohne Zauberwaffen | mit |
|---|---|---|
| Körper, Klinge, Schläge | 75 % | 75 % |
| Geist, Magie | 0 % (Stufe 25) | **83 %** |

Ohne die Stäbe blieb ein Geist-Spieler immer hinten, auch mit
Fähigkeitsstärke an der Ausrüstung: **Den Lauf entscheidet der
Grundangriff** (ADR-0009). Erst wenn die Waffe mitzieht, wählt man mit
seinem Gebiet auch eine Spielweise.

## Konsequenzen

- **Rückwirkend für jeden Stand.** Wer viel Körper hat und Magie trägt,
  wird schwächer; wer viel Geist hat und einen Stab trägt, stärker.
- **Abklingzeit tragen nur die teuersten Ringe** (Ring der Glut, Ring
  des Erzdämons): An einem günstigeren Stück machte sie es „besser“ als
  das teurere derselben Seltenheit (`catalog_test.dart`).
- Die Stäbe tragen umgefärbte Bilder des Kriegsstabs — Platzhalter, bis
  eigene gezeichnet sind.
- Die Waffe hat jetzt vierzehn Stücke, acht offene und sechs verdiente.
- Das Blatt jeder Fähigkeit und Waffe sagt, womit sie skaliert; der
  Charakter zeigt die Fähigkeitsstärke als vierten Wert.
