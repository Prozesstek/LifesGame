# Fähigkeiten-Set — die Vorlage

> **Herkunft:** von AktivesBrett geschrieben, am 26.08.2026 ins Repo gelegt.
> Sie ist die Grundlage von [ADR-0022](../decisions/0022-faehigkeiten-set-aus-der-vorlage.md).
>
> **Was sie ist:** die Absicht. Sie sagt, wie sich eine Fähigkeit anfühlen
> soll, wie sie aussieht und was sie wert ist.
>
> **Was sie nicht ist:** die Quelle der Wahrheit für die Zahlen im Spiel.
> Die stehen in `packages/combat/lib/src/ability_moves.dart` und
> `environment.dart`. Wo beide auseinandergehen, steht der Grund unten unter
> „Was davon im Spiel steht".
>
> **Warum sie hier liegt:** Sie lag bis zum 26.08. nur in einem
> Downloads-Ordner. Damit existierte sie für den jeweils anderen nicht —
> dasselbe Problem, das `state.md` bei `Kampfsystem.docx` beschreibt: „noch
> nicht im Repo" und am 22.08. auch nicht auffindbar. Dieser Ordner ist ab
> jetzt der Platz für solche Vorlagen.

---

## Die Vorlage

**Skala:** HP ~100 · Energie 0–10 · Timing-Leiste: `Speed` = Geschwindigkeit des Markers (1.0x = Standard), `Fenster` = Breite der Perfect-Zone in % der Leiste.
Je stärker die Fähigkeit, desto schneller der Marker und desto kleiner das Fenster.

| # | Name | Schaden / Heilung / Wert | Effekt | Timing (Speed · Fenster) | Energie | Icon-Idee | Seltenheit | Animationsidee |
|---|------|--------------------------|--------|--------------------------|---------|-----------|------------|----------------|
| 1 | Funkenstoß | 12 Schaden | Perfect: 18 Schaden + 20 % Chance auf Brand (3 HP/Runde, 2 Runden) | 1.0x · 24 % | 1 | Kleine orange Funkenflamme auf dunklem Kreis | Common | Kämpfer schnippt mit den Fingern, drei Funken fliegen im Bogen, kleiner Aufprallblitz. Bei Perfect wird der Funke zur Stichflamme. |
| 2 | Steinhaut | Schutz | Eingehender Schaden −40 % für 1 Runde. Perfect: −60 % und 5 Schaden werden zurückgeworfen | 0.8x · 28 % | 2 | Graue Schildplatte aus Felsbrocken | Common | Gesteinsplatten schieben sich aus dem Boden hoch und schließen sich mit einer Staubwolke um den Kämpfer. |
| 3 | Wurzelgriff | 9 Schaden | Gegner-Perfect-Fenster −25 % für 2 Runden. Perfect: 3 Runden | 1.1x · 20 % | 2 | Braune Ranke, die einen Knöchel umschlingt | Common | Wurzeln brechen durch den Boden und greifen zu, kurzer Kamera-Ruckler beim Zupacken. |
| 4 | Aurastrom | +3 Energie | Perfect: +5 Energie und die nächste Fähigkeit kostet 1 Energie weniger | 1.3x · 18 % | 0 | Blau leuchtende Spirale | Common | Kämpfer atmet ein, blaue Lichtpartikel strömen von außen in die Brust, kurzer Energiepuls. |
| 5 | Blütentau | 20 Heilung | Perfect: 28 Heilung und entfernt einen negativen Statuseffekt | 1.2x · 18 % | 3 | Rosa Blüte mit Wassertropfen | Uncommon | Blütenblätter regnen von oben herab und lösen sich beim Berühren in grünes Licht auf. |
| 6 | Klingenwirbel | 3 × 7 Schaden | Drei Tipps nacheinander, jeder Perfect gibt +50 % auf diesen Treffer. Alle drei perfekt = vierter Bonustreffer | 1.4x pro Tipp · 14 % | 4 | Drei gekreuzte Windklingen | Uncommon | Kämpfer dreht sich um die eigene Achse, drei Luftschnitte hinterlassen weiße Bögen in der Luft. |
| 7 | Frostnebel | Umgebung, 3 Runden | **Eisfeld:** beide Leisten laufen mit 0.85x, Gegner verliert 3 HP/Runde und regeneriert 1 Energie weniger | 0.9x · 22 % | 4 | Hellblauer Nebelschwaden über einem Eiskristall | Uncommon | Atemwolke breitet sich als Bodennebel über die Arena aus, die Bildschirmränder frieren langsam an. |
| 8 | Prisma-Barriere | Schutz / Reflexion | Wirft 30 % des erlittenen Schadens zurück, 2 Runden. Perfect: 50 % | 1.0x · 16 % | 4 | Sechseckiges Lichtprisma | Uncommon | Schwebende Glasscherben ordnen sich zu einer Kuppel, Licht bricht sich in Regenbogenfarben. |
| 9 | Donnerkeil | 34 Schaden | Perfect: 48 Schaden und der Gegner bekommt in der nächsten Runde keinen Timing-Bonus | 1.8x · 9 % | 5 | Gezackter gelber Speer | Rare | Bildschirm wird kurz dunkel, ein Aufblitzen, dann Einschlag mit Weißblende und Screenshake. |
| 10 | Sandsturm | Umgebung, 3 Runden | **Sandsturm:** Gegner-Perfect-Fenster −30 %, Gegner verliert 4 HP/Runde, eigene Angriffe +15 % Schaden | 1.5x · 15 % | 5 | Gelbbrauner Wirbel mit Sandkörnern | Rare | Wind zieht auf, Sandschleier fegt von rechts ins Bild, danach wehen dauerhaft Partikel über das HUD. |
| 11 | Seelenraub | 18 Schaden | Heilt 100 % des zugefügten Schadens. Perfect: 150 % und stiehlt 2 Energie | 1.6x · 12 % | 5 | Violetter Totenkopf mit aufsteigendem Faden | Rare | Ein schwarzer Faden schießt zum Gegner und zieht leuchtende Seelenwölkchen zurück in den Kämpfer. |
| 12 | Giftmoor | Umgebung, 4 Runden | **Giftboden:** Gegner verliert 5 HP/Runde, steigend um +2 pro Runde; Heilung des Gegners wirkt nur halb | 1.4x · 14 % | 6 | Grüne Blase auf sumpfiger Fläche | Rare | Der Boden verfärbt sich dunkelgrün, Blasen steigen auf und platzen, Schwaden ziehen über die Arena. |
| 13 | Zeitdehnung | Support | Eigene Leiste läuft 2 Runden mit 0.5x (viel leichter zu treffen) und Perfect-Treffer geben zusätzlich +15 % Schaden | 2.0x · 10 % | 6 | Sanduhr mit blauem Riss | Epic | Bild entsättigt kurz, Uhrzeiger drehen rückwärts, blaue Zeitringe pulsieren um den Kämpfer. |
| 14 | Vulkanbruch | 38 Schaden + Umgebung, 3 Runden | **Lavafeld:** Gegner verliert 6 HP/Runde, alle Angriffe beider Seiten richten +25 % Schaden an, Heilung wirkt nur halb | 2.2x · 7 % | 8 | Aufbrechender Krater mit Lavariss | Epic | Der Boden reißt auf, eine Lavasäule schießt hoch, danach fällt dauerhaft Asche und der Boden glüht. |
| 15 | Sternenfall | 60 Schaden | Perfect: 85 Schaden und ignoriert alle Schutzeffekte. Verfehlt: nur 24 Schaden | 3.0x · 4 % (Marker springt einmal zurück) | 10 | Goldener Komet mit Sternenschweif | Legendary | Kamera fährt in den Nachthimmel, ein Meteor durchbricht die Wolken, Einschlag mit Weißblende und Schockwellenring. |

### Timing-Leiste — Referenz

| Speed | Gefühl | Typisches Fenster | Passt zu |
|-------|--------|-------------------|----------|
| 0.5x – 0.9x | sehr gemütlich | 22–28 % | Schutz, Support, Umgebungs-Setup |
| 1.0x – 1.3x | Standard | 16–24 % | Basisangriffe, Heilung |
| 1.4x – 1.8x | flott | 9–15 % | starke Rare-Angriffe |
| 2.0x – 2.4x | hektisch | 6–10 % | Epic-Fähigkeiten |
| 3.0x+ | brutal | ≤ 5 % | Legendary-Finisher |

### Umgebungs-Regeln (Vorschlag)

- Es ist immer nur **eine** Umgebung aktiv. Eine neue überschreibt die alte sofort.
- Die Rundenzahl läuft am Ende jeder Runde herunter, der Schaden über Zeit wird ebenfalls am Rundenende abgerechnet.
- Umgebungen wirken auf **beide** Kämpfer, außer der Effekt sagt ausdrücklich etwas anderes. Der Ersteller profitiert, der Gegner leidet.
- Umgebungen, die die Leiste beeinflussen (Frostnebel, Sandsturm), stapeln sich mit Fähigkeits-Effekten multiplikativ. Sinnvolle Grenzen: Speed nie unter 0.4x, Fenster nie unter 3 %.

---

## Was davon im Spiel steht

**Stand 26.08.2026.** Nachgeprüft gegen `ability_moves.dart`,
`environment.dart` und `move_animation.dart`, Zeile für Zeile.

### Die Zahlen stimmen — alle fünfzehn

Schaden, Effekt, Timing und Energiekosten jeder Fähigkeit sind übernommen.
Auch die vier Umgebungen stimmen bis auf die Stelle: Eisfeld 0.85x und −1
Energie, Sandsturm −30 % Fenster und +15 % eigener Schaden, Giftboden +2
Steigerung und halbe Heilung, Lavafeld +25 % für beide und halbe Heilung.

Drei Umrechnungen liegen zwischen Vorlage und Code, alle drei in
[ADR-0022](../decisions/0022-faehigkeiten-set-aus-der-vorlage.md) begründet:

| Vorlage sagt | Im Code steht | Warum |
|---|---|---|
| feste Zahlen (12, 34, 60) | `power = Wert / 16` | Feste Zahlen hängen nicht am Angriffswert — und damit nicht an den Gewohnheiten. Das ist die Kernaussage des Produkts. |
| Perfect-Boni +40 bis +50 % | eigener `perfectFactor` je Fähigkeit | ADR-0009 hat den **pauschalen** Deckel auf +20 % gemessen. Basisangriff und Waffenmoves bleiben dort; eine Fähigkeit mit engem Fenster und Energiekosten verdient mehr. |
| Dauerschaden als feste HP | Vielfaches des Angriffswerts | Feste HP wirken bei 120 und bei 230 HP völlig verschieden. Anteile der maximalen HP haben schon einmal Kämpfe unendlich gemacht (`gotchas.md`). |

Die Skala der Vorlage (HP ~100) passt ebenfalls nicht: Im Spiel sind es
160–224 beim Spieler und 120–230 bei den Gegnern.

### Fünf Stellen, an denen die Vorlage noch auf Antwort wartet

**1. Acht Fähigkeiten bekommen keine Timing-Leiste.** `combat_screen.dart`
öffnet das Zeitfenster nur bei `power > 0`. Steinhaut, Aurastrom,
Blütentau, Prisma-Barriere, Frostnebel, Sandsturm, Giftmoor und
Zeitdehnung lösen sofort aus. Vier Perfect-Wirkungen aus der Vorlage sind
dadurch unerreichbar (Steinhaut −60 %, Aurastrom +5, Blütentau 28 plus
Cleanse, Prisma-Barriere 50 %). **Die Engine kann es bereits** — sie wertet
`perfectEffects` unabhängig vom Schaden aus. Es fehlt allein die Eingabe.

**2. Die Icon-Ideen sind nicht gebaut.** Keine der fünfzehn hat ein Icon;
in `ziele.md` stand das von vornherein auf der Schnittliste.

**3. Die Animationsideen sind nicht gebaut.** `move_animation.dart` kennt
vier Ids (`basic_attack`, `heavy_attack`, `poison_strike`, `mend`) und
fällt für **alle** fünfzehn auf `melee` zurück. Sichtbare Folge: Bei
Steinhaut und Blütentau macht die Figur einen Ausfallschritt auf den
Gegner zu. Die Umgebungen lassen beim Setzen nur beide Kämpfer kurz
aufleuchten — Lava, Sandschleier und Nebel fehlen.

**4. Sternenfalls Marker springt nicht zurück.** Die Vorlage nennt das als
Teil seines Timings; `TimingSpec` kennt nur Geschwindigkeit und Fenster.

**5. Vier Fähigkeiten haben in der Vorlage keine Perfect-Wirkung** —
Frostnebel, Sandsturm, Giftmoor und Zeitdehnung. Sobald sie eine Leiste
bekommen (Punkt 1), muss entschieden werden, was ein perfekter Treffer
dort bewirkt: nichts, eine Runde mehr, oder etwas anderes. **Offen, noch
nicht entschieden.**

### Und ein Befund, den die Vorlage ausgelöst hat

Der **Bergwächter ist unschlagbar geworden** — 0 % Siegquote an jedem Tag,
auch Tag 60. Er trägt seit dem Set Donnerkeil (`power` 2,125), während die
frühen Spielerfähigkeiten schwächer sind als der Basisangriff: Funkenstoß
hat 0,75 gegen 1,0 beim Bogenschuss und kostet zusätzlich Energie.

Das ist die Vorlage, ehrlich umgerechnet — ihre Commons sind Werkzeuge mit
Perfect-Effekten, keine Schadensquellen. Zahlen und Hebel stehen in
`docs/context/state.md`.
