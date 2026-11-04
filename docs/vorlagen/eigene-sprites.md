# Eigene Sprites statt fremder

> **Ziel** (Frederik, 04.11.2026): „Ich würde gerne alle externen Sprites
> ersetzen durch eigene.“ Diese Liste wird abgehakt. Wer ein Bild ersetzt,
> hakt es **im selben Commit** ab.

## Regeln

- **64 × 64 zeichnen, als 256 × 256 ablegen** (4×, hart vergrößert), wie
  jedes Bild im Projekt (`PixelArt`).
- Gezeichnet mit **pxl** ([claude-pxl](https://github.com/crsolver/claude-pxl),
  MIT). Die Quelle liegt unter `tool/pixel/<name>.px.js`, das PNG an der
  Stelle des alten, oder unter neuem Namen samt Eintrag in der Tabelle
  (`GearIcons`, `MoveIcons`, `GrubeFiguren` …).
- **Eigenes Design**, keine Nachzeichnung des alten Bildes und keine Kopie
  aus einem anderen Spiel. Name und Rolle des Stücks bleiben.
- Ersetztes fliegt aus `assets/` und aus `RAVEN.md` bzw. der HERKUNFT-Datei.
  Ist ein Paket ganz ersetzt, fliegt auch seine HERKUNFT-Datei.

## Stand

| Bereich | fremd | ersetzt |
|---|---|---|
| Kreise der Startseite | 5 | 1 |
| Items (Truhe, Schlüssel) | 2 | 0 |
| Waffen | 8 | 1 |
| Rüstung, Helme, Schuhe, Ringe, Talismane | 40 | 0 |
| Fähigkeiten | 39 | 0 |
| Ausrüstung auf der Figur | 24 | 0 |
| Holz-Oberfläche | 6 | 0 |
| Dungeon: Held, Gegner, Bosse | 15 Figuren (25 Dateien) | 0 |
| **Summe** | **139** | **2** |

Die Zahlen werden beim Abhaken nachgezogen.

---

## 1. Kreise der Startseite (`assets/UI/`)

Am meisten gesehen — zuerst. Erzeugt bisher von `tool/kreis_zeichen.py`;
ein ersetztes Zeichen kommt dort heraus.

- [x] Gewohnheiten — Quest-Rolle (`tool/pixel/kreis_gewohnheiten.px.js`, PR #189)
- [ ] Kampf — gekreuzte Schwerter (Raven fc721)
- [ ] Laden — Münzbeutel (Raven fc158 + fc131)
- [ ] Fähigkeiten — Runenstein (Raven fc326)
- [ ] Charakter — Helm (Raven fc1911)

## 2. Items (`assets/Items/`)

- [ ] Truhe — die Tagestruhe (fc6)
- [ ] Schlüssel — zur Beute (fc77)

## 3. Waffen (`assets/Waffen/`)

- [ ] Kurzbogen (fc1781)
- [ ] Übungsklinge (fc1777)
- [ ] Streitkolben (fc1702)
- [ ] Geschliffene Klinge (fc1732)
- [ ] Kriegsstab (fc1712)
- [ ] Zweihänder (fc1736)
- [x] Langbogen → Wurzelbogen (`tool/pixel/bogen_verwachsen.px.js`, PR #190; das alte `Langbogen.png` muss noch weg)
- [ ] Sonnenklinge (fc1681)

## 4. Rüstung (`assets/Ruestung/`)

- [ ] Lederwams (fc1974)
- [ ] Gestepptes Wams (fc1969)
- [ ] Schuppenpanzer (fc1921)
- [ ] Kettenpanzer (fc2058)
- [ ] Plattenharnisch (fc2049)
- [ ] Drachenschuppenpanzer (fc1925)
- [ ] Runenharnisch (fc1877)
- [ ] Titanenpanzer (fc1927)

## 5. Helme (`assets/Helme/`)

- [ ] Lederkappe (fc1965)
- [ ] Eisenhaube (fc2052)
- [ ] Schuppenhaube (fc1905)
- [ ] Visierhelm (fc2053)
- [ ] Turnierhelm (fc1917)
- [ ] Drachenhelm (fc1909)
- [ ] Runenkrone (fc1837)
- [ ] Krone des Hochwächters (fc1911)

## 6. Schuhe (`assets/Schuhe/`)

- [ ] Feste Stiefel (fc1990)
- [ ] Genagelte Stiefel (fc1985)
- [ ] Schienbeinschutz (fc1937)
- [ ] Stahlbeinlinge (fc1951)
- [ ] Schwere Schienen (fc2057)
- [ ] Windläufer (fc2045)
- [ ] Drachenschuppenstiefel (fc1941)
- [ ] Stiefel des Titanen (fc1950)

## 7. Ringe (`assets/Ringe/`)

- [ ] Schlichter Ring (fc1843)
- [ ] Kupferring (fc1844)
- [ ] Taktring (fc1847)
- [ ] Siegelring (fc2185)
- [ ] Aderring (fc2186)
- [ ] Sternenring (fc1846)
- [ ] Ring der Glut (fc1845)
- [ ] Ring des Erzdämons (fc2062)

## 8. Talismane (`assets/Talismane/`)

- [ ] Glasperle (fc168)
- [ ] Flusskiesel (fc216)
- [ ] Bernsteinamulett (fc1848)
- [ ] Silberamulett (fc1851)
- [ ] Runenamulett (fc2182)
- [ ] Phönixfeder (fc1815)
- [ ] Drachenzahn (fc230)
- [ ] Herz des Titanen (fc2141)

## 9. Fähigkeiten (`assets/Faehigkeiten/`)

Die lernbaren:

- [ ] Funkenstoß (fc994)
- [ ] Steinhaut (fc664)
- [ ] Wurzelgriff (fc1067)
- [ ] Aurastrom (fc980)
- [ ] Blütentau (fc969)
- [ ] Klingenwirbel (fc1004)
- [ ] Frostnebel (fc1015)
- [ ] Prisma-Barriere (fc1024)
- [ ] Donnerkeil (fc1025)
- [ ] Sandsturm (fc1031)
- [ ] Seelenraub (fc1052)
- [ ] Giftmoor (fc809)
- [ ] Zeitdehnung (fc737)
- [ ] Vulkanbruch (fc999)
- [ ] Sternenfall (fc1047)
- [ ] Kraftschlag (fc1005)
- [ ] Zehrung (fc1063)
- [ ] Sammeln (fc1042)
- [ ] Atemzug (fc1040)
- [ ] Glutspur (fc1000)
- [ ] Fanghaken (fc393)
- [ ] Glückstrank (fc960)
- [ ] Wiederkehr (fc1019)
- [ ] Schnappfalle (fc128)
- [ ] Falke (fc1818)
- [ ] Steinschlag (fc209)
- [ ] Rankenpeitsche (fc1071)
- [ ] Rückenwind (fc725)
- [ ] Eisball (fc1009)
- [ ] Wassergrube (fc786)
- [ ] Fleischfressende Pflanze (fc263)

Die Grundangriffe der Waffen:

- [ ] Bogenschuss (fc2155)
- [ ] Hieb (fc727)
- [ ] Wuchtstoß (fc1044)
- [ ] Doppelstich (fc721)
- [ ] Sammelschlag (fc985)
- [ ] Spalter (fc1022)
- [ ] Doppelschuss (fc1011)
- [ ] Sonnenhieb (fc1038)

## 10. Ausrüstung auf der Figur (`assets/character/Charakter_*.png`)

Verkleinerte Raven-Bilder (`tool/figur_ausruestung.py`), deckungsgleich
über `Charakter.png`. Am besten **mit dem Stück zusammen** neu zeichnen,
sonst trägt die Figur das alte Bild.

- [ ] Kurzbogen · [ ] Übungsklinge · [ ] Streitkolben · [ ] Geschliffene Klinge
- [ ] Kriegsstab · [ ] Zweihänder · [ ] Langbogen (→ Wurzelbogen) · [ ] Sonnenklinge
- [ ] Lederwams · [ ] Gestepptes Wams · [ ] Schuppenpanzer · [ ] Kettenpanzer
- [ ] Plattenharnisch · [ ] Drachenschuppenpanzer · [ ] Runenharnisch · [ ] Titanenpanzer
- [ ] Lederkappe · [ ] Eisenhaube · [ ] Schuppenhaube · [ ] Visierhelm
- [ ] Turnierhelm · [ ] Drachenhelm · [ ] Runenkrone · [ ] Krone des Hochwächters

## 11. Holz-Oberfläche (`assets/UI/Holz/`, aus `UIBundleFree`)

Sitzt auf jeder Karte, jedem Dialog, jedem Knopf. Wer sie tauscht, prüft
`lib/ui/holz.dart` (wo gedehnt wird) und `test/palette_test.dart`.

- [ ] Planke
- [ ] Rahmen
- [ ] Seil
- [ ] Balken
- [ ] Knopf
- [ ] Knopf gedrückt

## 12. Dungeon (`assets/Grube/`, aus dem Kampf-Paket)

**Der größte Brocken: Das sind animierte Streifen**, keine Einzelbilder.
Wie viele Bilder ein Streifen hat, steht in `GrubeFiguren`
(`lib/action/action_sprites.dart`), und `test/action_sprites_test.dart`
prüft es nach. Neue Streifen brauchen dieselbe Bildzahl oder einen
neuen Eintrag dort.

- [ ] Held — Soldat (6 Streifen: Stehen, Laufen, Angriff 1 und 2, Treffer, Tod)
- [ ] Fussvolk — Ork (6 Streifen)
- [ ] Schütze — Bloodshot Eye
- [ ] Kobold — Red Cap
- [ ] Troll — Stone Troll
- [ ] Schleim — Death Slime
- [ ] Schleimling — Ochre Jelly
- [ ] Grimlock — Blinded Grimlock
- [ ] Kreischpilz — Shrieker Mushroom
- [ ] Sporenpilz — Fungal Myconid
- [ ] Wächterauge — Ocular Watcher
- [ ] Boss Zyklop — Crushing Cyclops
- [ ] Boss Zweikopf — Humongous Ettin
- [ ] Boss Schlund — Crimson Slaad
- [ ] Boss Sumpftroll — Swamp Troll

---

## Schon eigen — bleibt

- Zwölf Fähigkeiten von AktivesBrett, Speerstich und Sichelhieb
  (`tool/faehigkeit_icons.py`, `tool/item_icons.py`)
- Die zwölf Stücke aus ADR-0077 und ihre sechs Bilder auf der Figur
- Kreise Ausrüstung (Rucksack) und Statistik (Balken)
- Das Dorf (`tool/dorf_kacheln.py`)
- Frederiks Zeichnungen: Buch, Stein, Fledermaus, die drei Böden

## Herkunft klären

Nicht in einer HERKUNFT-Datei, vermutlich eigen — **bitte bestätigen**:

- [ ] `character/Charakter.png` — die Grundfigur (seit 10.09.)
- [ ] `Items/Gold.png` — die Goldmünze (seit 09.09.)
- [ ] `UI/ButtonBG.png` — der Grund der Kreise (seit 09.09.)
- [ ] `UI/Berg.jpg`, `UI/Bibliothek.jpg` — „Frederiks Bild“; selbst gemacht, erzeugt oder geladen?
- [ ] `Mentor/Mentor.png`, `Mentor/Mentor_Kopf.png` — ebenso

## Aufräumen

- [ ] `UI/CharacterButton.png` — wird nicht mehr gebraucht (seit 28.10.)
- [ ] `Waffen/Boegen/Langbogen.png` — ersetzt durch den Wurzelbogen

## Nicht auf dieser Liste

Die vier Klänge `Success.mp3`, `Win.mp3`, `Win_2.mp3`, `Win_3.mp3` sind
ebenfalls fremd und ohne festgehaltene Lizenz (`assets/Sound/HERKUNFT.md`)
— aber keine Sprites.
