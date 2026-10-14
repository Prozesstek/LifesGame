# Fähigkeiten, zweite Runde — die Vorlage

> **Herkunft:** angelegt am 14.10.2026 nach der Fragerunde zu Issue
> [#114](https://github.com/Prozesstek/LifesGame/issues/114). Die Regeln
> stehen in [ADR-0073](../decisions/0073-ultimate-mana-und-neue-arten.md).
>
> **Was sie ist:** der Platz, an dem beide Entwickler ihre Fähigkeiten
> eintragen — **zehn Fähigkeiten und zwei Ultimates je Person**. Gebaut
> wird erst, was hier steht.
>
> **Was sie nicht ist:** die Quelle der Wahrheit für die Zahlen. Die
> stehen nach dem Bau am Eintrag in
> `packages/action_combat/lib/src/pit_ability.dart`. Mana und
> Abklingzeit hier sind Absicht; gestellt werden sie mit
> `dart run tool/pit_sim.dart`.
>
> **Die erste Vorlage** ([`faehigkeiten.md`](faehigkeiten.md)) wurde für
> den Rundenkampf geschrieben. Diese gilt für die Grube.

---

## Die Bausteine

Eine Fähigkeit ist eine Liste von Bausteinen. **Jeder Baustein darf in
jede Fähigkeit**, auch in eine Ultimate (ADR-0073).

**Schaden ist immer ein Vielfaches des Angriffs**, Heilung ein Anteil
des Lebens — nie eine feste Zahl. Eine feste Zahl wäre auf Stufe 30
zehnmal zu klein (`CLAUDE.md`).

### Die neun, die es gibt

| Baustein | Werte | Beispiel |
|---|---|---|
| Geschoss | Wucht × Angriff, Reichweite, Anteil Lebensraub | Funkenstoß, Seelenraub |
| Schlag | Wucht × Angriff, Reichweite | Kraftschlag |
| Rundumschlag | Wucht × Angriff, Umkreis | Klingenwirbel, Sternenfall |
| Heilen | Anteil des Lebens | Blütentau |
| Mana | Menge | Aurastrom |
| Schadensminderung | Faktor, Sekunden | Steinhaut |
| Zurückwerfen | Anteil, Sekunden — nur Nahkampf | Prisma-Barriere |
| Verlangsamen | Umkreis, Faktor, Sekunden | Zeitdehnung |
| Dauerschaden | Umkreis, Angriff je Sekunde, Sekunden | Giftmoor |

### Die zehn neuen

| Baustein | Was er tut | Grenze, die immer gilt |
|---|---|---|
| **Dash** | der Held stürmt eine Strecke in eine Richtung | stoppt an der Wand |
| **Blink** | der Held ist sofort woanders | nie durch eine Wand oder das Tor |
| **Stun** | Gegner stehen still, Sekunden | der Wächter ist immun |
| **Self-Buff** | ein Wert des Helden steigt um einen Faktor, Sekunden | auf den Grundangriff nur leicht |
| **Stacking / Rage** | jede Wiederholung macht die nächste stärker — oder, als Rage, jeder Treffer, den der Held einsteckt | gezählt, nicht am Schaden gemessen; mit Obergrenze |
| **Passiv** | wirkt dauernd, ohne Knopf | kostet den Platz |
| **Hook** | zieht einen Gegner zum Helden | nicht den Wächter, nicht durch Wände |
| **Unsichtbarkeit** | Gegner sehen den Helden nicht | kurz; endet beim ersten Angriff |
| **Begleiter** | eine Figur kämpft für den Helden | höchstens einer zugleich, lebt auf Zeit; seine Kills zahlen nichts und laden die Ultimate nicht |
| **Terrain** | eine Wand entsteht | verschwindet nach Sekunden; nie im Gang zum Tor |

### Wie gezielt wird

| Ziel | Bedeutet |
|---|---|
| selbst | wirkt beim Drücken auf den Helden |
| Richtung | Geschoss oder Schlag geradeaus; daneben ist daneben |
| um den Helden | ein Kreis um ihn |
| Bereich | ein Kreis, abgesetzt bis zur Wurfweite, auch hinter eine Wand |

**Farben:** funke, blitz, seele, klinge, natur, eis, sand, gift, zeit,
lava, stern, schutz. **Rot gehört dem Wächter.**

---

## Die Regeln der Ultimate

- **Kein Mana, keine Abklingzeit.** Sie lädt sich auf: jeder besiegte
  Gegner etwa ein Achtel, Treffer am Wächter auch. Jeder Lauf beginnt
  leer.
- Ein eigener Platz ab **Level 15**, und eine Ultimate liegt nur dort.
- **Keine Seltenheit**, ein goldener Doppelrand.
- **Quelle:** Baum, Kette oder Errungenschaft — nie die Grube.
  **Mindestens eine** der vier muss auf Level 15 über einen Knoten im
  Baum erreichbar sein.

## Mana

Mana ist die **Bremse** (ADR-0073): Wer alle drei Fähigkeiten im Takt
drückt, soll nach etwa 10 bis 15 Sekunden leer sein. Teure Fähigkeiten
dürfen deshalb kurze Abklingzeiten haben — bezahlt wird mit Mana. Ein
frischer Held hat 40; mehr darf keine kosten.

---

## Frederik

### Fähigkeiten

| # | Name | Bausteine | Ziel | Mana | Abklingzeit | Seltenheit | Quelle | Farbe | Icon / Animation |
|---|---|---|---|---|---|---|---|---|---|
| 1 | | | | | | | | | |
| 2 | | | | | | | | | |
| 3 | | | | | | | | | |
| 4 | | | | | | | | | |
| 5 | | | | | | | | | |
| 6 | | | | | | | | | |
| 7 | | | | | | | | | |
| 8 | | | | | | | | | |
| 9 | | | | | | | | | |
| 10 | | | | | | | | | |

### Ultimates

| # | Name | Bausteine | Ziel | Quelle | Icon / Animation |
|---|---|---|---|---|---|
| U1 | | | | | |
| U2 | | | | | |

## AktivesBrett

### Fähigkeiten

| # | Name | Bausteine | Ziel | Mana | Abklingzeit | Seltenheit | Quelle | Farbe | Icon / Animation |
|---|---|---|---|---|---|---|---|---|---|
| 1 | | | | | | | | | |
| 2 | | | | | | | | | |
| 3 | | | | | | | | | |
| 4 | | | | | | | | | |
| 5 | | | | | | | | | |
| 6 | | | | | | | | | |
| 7 | | | | | | | | | |
| 8 | | | | | | | | | |
| 9 | | | | | | | | | |
| 10 | | | | | | | | | |

### Ultimates

| # | Name | Bausteine | Ziel | Quelle | Icon / Animation |
|---|---|---|---|---|---|
| U1 | | | | | |
| U2 | | | | | |
