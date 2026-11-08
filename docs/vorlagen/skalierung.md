# Skalierung: Angriffsschaden und Fähigkeitsstärke

> **Entwurf vom 08.11.2026** (Frederik mit Claude). Noch nicht gebaut,
> noch kein ADR. Erst lesen beide, dann wird gebaut — **vor dem
> geschlossenen Test**.

## Warum

Frederik, Level 30, viel Geist: „Jetzt hab ich zwar massig Mana aber
keinen Schaden.“ Seit ADR-0088 steigert jedes Gebiet einen Kampfwert,
und Geist steigert Mana. Jeder Schaden rechnet aber mit dem Angriff
(`Angriff × power`), und der kommt nur aus Körper. Wer viel lernt,
zaubert oft, aber schwach.

Vorbild ist **League of Legends**: Fähigkeiten skalieren mit
Angriffsschaden, mit Fähigkeitsstärke oder mit beidem, und Mana,
Abklingzeit und Manaregeneration kommen aus der Ausrüstung.

## Die Werte

| Wert | kommt aus | wirkt auf |
|---|---|---|
| **Angriffsschaden** (AS) | Körper, Ausrüstung | Grundangriff und der physische Anteil jeder Fähigkeit |
| **Fähigkeitsstärke** (FS) | **Geist** (statt Mana), Ausrüstung | der magische Anteil jeder Fähigkeit, Heilung und Schilde |
| **Leben** | Gesellschaft, Ausrüstung | wie heute |
| **Abwehr** | Wissenschaft, Ausrüstung | wie heute |
| **Mana** | Grundwert, der mit dem Level wächst, und Ausrüstung | Vorrat |
| **Manaregeneration** | Grundwert und Ausrüstung | Nachfluss je Sekunde |
| **Abklingzeit** | nur Ausrüstung, **höchstens 40 %** | alle Fähigkeiten, nicht die Ultimate |

Die Namen sind die des deutschen LoL-Clients (ADR-0094: Namen, die
Spieler schon kennen). Auf dem Bildschirm stehen sie mit Zeichen,
nicht ausgeschrieben (ADR-0060).

**Was bleibt:** Macht vervielfacht, die Gewohnheiten addieren
(ADR-0042). Level, Tagesform und `powerScale` wirken auf AS und FS wie
heute auf den Angriff. Die Seltenheit der **Waffe vervielfacht beide**.

## Die Formel

Heute: `Schaden = Angriff × power`.

Neu: `Schaden = (AS × as + FS × fs) × power`, mit `as + fs = 1`.

Weil die Anteile zusammen 1 ergeben, **bleibt jede Zahl gleich, solange
AS und FS gleich hoch sind** — ein frischer Charakter merkt nichts, und
`power` muss an keiner Fähigkeit neu gestellt werden. Erst wer ein Gebiet
bevorzugt, sieht den Unterschied: Mit viel Geist trifft ein Feuerball
hart und ein Kraftschlag schwach.

**Dauerschaden** rechnet genauso. **Heilung und Schilde** bleiben ein
Anteil des Lebens (sonst endet kein Lauf, `gotchas.md`) und werden mit
der Fähigkeitsstärke stärker: `Anteil × (FS / AS-und-FS-Mittel)`,
gedeckelt. Die genaue Kurve entscheidet `pit_sim`.

## Die Fähigkeiten

Vorschlag. `AS` = Angriffsschaden, `FS` = Fähigkeitsstärke, `—` = macht
keinen Schaden und skaliert nicht (Mana, Tempo, Ausweichen).

### Physisch

| Fähigkeit | AS | FS | Warum |
|---|---|---|---|
| Kraftschlag | 100 % | — | ein Schlag |
| Klingenwirbel | 100 % | — | Klingen |
| Zinseszins | 100 % | — | ein Schlag, der sich steigert |
| Fanghaken | 100 % | — | Haken und Schlag |
| Wiederkehr | 100 % | — | geworfene Klinge |
| Rammbock | 100 % | — | Ansturm |
| Schnappfalle | 100 % | — | Eisen |
| Falke | 100 % | — | ein Tier, das pickt |
| Kriegsschrei | 100 % | — | Stillstand und Kraft |
| Kampfrausch (passiv) | 100 % | — | macht den Helden stärker |
| Parade | 100 % | — | fängt den Schlag ab |
| Zehrung | 60 % | 40 % | Schlag mit Gift |
| Glutspur | 50 % | 50 % | Sturm, dahinter Feuer |

### Magie

| Fähigkeit | AS | FS | Warum |
|---|---|---|---|
| Funkenstoß | — | 100 % | ein Funke — **die erste für jeden** |
| Donnerkeil | — | 100 % | Blitz |
| Kettenblitz | — | 100 % | Blitz |
| Eisball | — | 100 % | Eis |
| Seelenraub | — | 100 % | heilt, was es anrichtet |
| Sternenfall | — | 100 % | Sterne |
| Vulkanbruch | — | 100 % | Lava |
| Frostnebel | — | 100 % | Eisfeld |
| Sandsturm | — | 100 % | Sturmfeld |
| Giftmoor | — | 100 % | Giftboden |
| Wurzelgriff | — | 100 % | Wurzeln |
| Rankenpeitsche | — | 100 % | Ranken |
| Spiegelbild | — | 100 % | Abbild |
| Steinschlag | 40 % | 60 % | Fels aus dem Nichts, trifft hart |

### Schutz und Hilfe

| Fähigkeit | skaliert mit | Was |
|---|---|---|
| Blütentau | FS | Heilung |
| Sammeln | FS | Heilung und Schutz |
| Atemzug | FS | Heilung (das Mana bleibt fest) |
| Steinhaut | FS | weniger Schaden |
| Prisma-Barriere | FS | wirft zurück |
| Glückstrank | FS | Zufall: Kraft, Tempo, Schutz, Heilung |
| Aurastrom | — | Mana |
| Ruhepuls (passiv) | — | Mana |
| Zeitdehnung | — | Tempo der Gegner |
| Rückenwind | — | Tempo |
| Schattenschritt | — | Ausweichen |
| Zweiter Atem (passiv) | — | einmal je Lauf |

### Ultimates

| Ultimate | AS | FS |
|---|---|---|
| Wassergrube | — | 100 % |
| Fleischfressende Pflanze | — | 100 % |
| Bestform | macht Fähigkeiten härter, skaliert selbst nicht | |
| Rückspulen | — | — |

**Zählung:** 13 physisch, 14 Magie, 12 Schutz und Hilfe. Die zwei
Gruppen, die Schaden machen, sind damit gleich gross.

### Grundangriff

Alle elf Waffenzüge skalieren **nur mit Angriffsschaden**, wie in LoL.
Ein Faktor auf das, was jede halbe Sekunde fällt, entscheidet den Kampf
allein (ADR-0009); ihn an beide Werte zu hängen, machte Geist dort
genauso stark wie Körper. Die Grenze `weaponBuffCap` bleibt.

**Offen:** Soll der Kriegsstab als Zauberstab einen Teil seines Schlags
aus der Fähigkeitsstärke nehmen?

## Die Ausrüstung

`maxEnergy` (heute an 27 der 60 Stücke) wird zu **Mana**. Dazu kommen
drei neue Zeilen: **Fähigkeitsstärke**, **Abklingzeit** und
**Manaregeneration**. Vorschlag, wer sie bekommt:

| Platz | heute | neu |
|---|---|---|
| Waffe | Angriff | Angriff; **Kriegsstab** und **Sonnenklinge** zusätzlich Fähigkeitsstärke |
| Rüstung, Helm, Schuhe | Leben, Abwehr | wie heute; Runenharnisch, Runenkrone, Windläufer bekommen Abklingzeit |
| Ring | Energie, etwas Leben | **Mana und Manaregeneration**, die epischen und legendären Fähigkeitsstärke |
| Talisman | Angriff, Leben, Energie | Hälfte AS, Hälfte **FS**, dazu Mana; Runenamulett und Phönixfeder Abklingzeit |

Bestehende Exemplare behalten ihren Wurf: Ihre Energie wird Mana, und
die neuen Zeilen bekommen sie zum Wurf 100 %. Die Preise bleiben, solange
`catalog_test.dart` „teurer ist besser“ innerhalb einer Seltenheit hält.

## Was Geist heute sonst noch tut

Energie bestimmt heute auch das **Schlagtempo** des Grundangriffs
(`attackCooldown`). Vorschlag: Das Tempo hängt künftig an einem
Grundwert, der mit dem Level wächst, und an Ausrüstung („Angriffstempo“
an Bogen und Schuhen). Sonst schlüge ein Geist-Spieler schneller, ohne
dass es zu seinen Fähigkeiten passt.

## Folgen

- **Rückwirkend für jeden Stand**, wie ADR-0088. Wer viel Körper hat
  und Magie trägt, wird schwächer; wer viel Geist hat, stärker. Das
  trifft auch AktivesBretts Stand.
- **Mana wird knapper** für jeden, der keine Ringe trägt. Die Bremse aus
  ADR-0073 wird damit eine Frage der Ausrüstung.
- Die Tagesform von Geist hebt künftig die Fähigkeitsstärke statt Mana.
- Charakter, Kampfwerte, das Blatt jeder Fähigkeit, das Blatt jedes
  Stücks und die Tipps nach einer Niederlage zeigen die neuen Werte.

## Was gemessen wird

- `dart run tool/pit_sim.dart` mit drei Bots: nur Körper, nur Geist,
  gemischt — **keiner darf auf einer Stufe weit hinter den anderen
  liegen**.
- `dart run tool/pit_sim.dart mana`: wie oft ein Platz am Mana hängt,
  ohne Ringe und mit.
- `dart run tool/pit_sim.dart ausruestung`: was die neuen Zeilen tragen.
- `tool/runway_sim.dart` und `test/progression_test.dart`: die vier
  Kurven.

## Offen

1. Die Einteilung der Fähigkeiten oben — **vor allem AktivesBretts
   zwölf** (ADR-0074).
2. Ob der Kriegsstab einen Teil aus der Fähigkeitsstärke nimmt.
3. Die Kurve, mit der Heilung und Schilde an der Fähigkeitsstärke
   wachsen.
4. Wie viel Mana und Tempo der Grundwert je Level bringt — aus `pit_sim`.
