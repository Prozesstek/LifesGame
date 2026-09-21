# Herkunft der Bilder in `assets/Grube/`

Aus Frederiks Download-Paket (`Desktop\Pixelart\Runtergeladen\Kampf`),
übernommen am 21.09.2026. **Die Lizenz hat Frederik geprüft** — sie
erlaubt die Verwendung im Spiel.

| Datei | Aus dem Paket |
|---|---|
| `Soldier_*.png` | `Characters/Soldier/Soldier/` — der Held |
| `Orc_*.png` | `Characters/Orc/Orc/` — das Fussvolk |
| `BloodshotEye.png` | `Characters/Basic Monster Animations/Bloodshot Eye/` — der Schütze |
| `CrushingCyclops.png` | `Characters/Basic Monster Animations/Crushing Cyclops/` — der Wächter |

Offen: **Quelle und Urheber** als Link nachtragen, damit die Lizenz auch
für den anderen nachprüfbar ist. Im Paket liegt keine Lizenzdatei.

Welche Datei wem gehört und wie viele Bilder ein Streifen hat, steht in
`lib/action/action_sprites.dart` (`GrubeFiguren`) — nicht in den
Dateinamen. `test/action_sprites_test.dart` liest die Dateien und prüft
die Zahlen nach.
