# ADR-0077: Ausrüstung mit Kräften — zwölf Stücke und das Vampirset

**Datum:** 19.10.2026
**Status:** Aktiv
**Entschieden von:** AktivesBrett, in zwei Fragerunden mit Claude
**Ergänzt:** [ADR-0034](0034-episch-und-legendaer-haengen-an-der-gegnerreihe.md),
[ADR-0039](0039-die-grube-ersetzt-den-rundenkampf.md) (legendäre Kräfte),
Issue [#115](https://github.com/Prozesstek/LifesGame/issues/115)

## Kontext

Issue #115 („Neue Items“) verlangt zwei Stücke je Kategorie und
Legendäre und Sets, die Fähigkeiten verändern. AktivesBrett brachte zwei
eigene Ideen mit — einen Ring mit Eisaura und ein Amulett, das Kugeln
beschwört — und ein Vampirset mit vier Teilen; den Rest sollte Claude
vorschlagen.

Bis hierher trug **nur ein legendäres Stück eine Kraft** (ADR-0039), und
jede Kraft veränderte Fähigkeiten (`PitModifier`). Was AktivesBrett
wollte — eine Aura, Kugeln, Lebensraub, Schaden über Zeit am Helden —
wirkt aber auf den Helden, nicht auf eine Fähigkeit.

## Entscheidung

**Zwölf Stücke, zwei je Platz; jedes trägt eine Kraft.** Kräfte gibt es
damit auf jeder Seltenheit (AktivesBrett: „ja das finde ich gut, dass
nicht nur legendäre Items Fähigkeiten haben“).

| Stück | Platz | Seltenheit | Kraft |
|---|---|---|---|
| Langspeer | Waffe | Ungewöhnlich | Grundangriff Speerstich: trifft alle in einer Linie, reicht doppelt so weit |
| **Blutsichel** | Waffe | Episch, Vampir | Grundangriff Sichelhieb: schnell, ×0,9, alle im Bogen von 120°; Lebensraub 4 % |
| Flickenmantel | Rüstung | Selten | 3 s ohne Treffer: Schild aus 10 % des Lebens |
| **Nachtmantel** | Rüstung | Episch, Vampir | Lebensraub 3 % |
| Falkenhaube | Helm | Ungewöhnlich | +5 % kritische Treffer, je kritischem +3 Mana |
| **Fledermaushaube** | Helm | Episch, Vampir | Lebensraub 2 % |
| Hasenläufer | Schuhe | Gewöhnlich | nach jedem Kill 2 s ×1,3 so schnell |
| **Schattenstiefel** | Schuhe | Episch, Vampir | Lebensraub 3 % |
| Seelenring | Ring | Selten | +8 Mana je Kill |
| *Frostreif* | Ring | Legendär | Eiskreis (60) um den Helden: bremst auf 70 %, 0,1 × Angriff je Sekunde; der Wächter halb so stark gebremst |
| Echostein | Talisman | Selten | jede vierte Fähigkeit mit Schaden trifft noch einmal, halb so hart |
| *Amulett der Irrlichter* | Talisman | Legendär | alle 5 s ein Irrlicht, höchstens 3; sie kreisen, suchen Gegner in Sicht bis 160 und zerplatzen (1,2 × Angriff, Umkreis 40) |

Kursiv: AktivesBretts Ideen. Fett: das Vampirset.

**Das Vampirset** (AktivesBrett, alle Zahlen außer den 2 % von Claude):

| Stufe | Wirkung |
|---|---|
| jedes Teil | Lebensraub: ein Anteil des Schadens mit eigener Hand heilt, zusammen 12 % |
| 2 Teile | **Blutdurst**: jeder Kill heilt 3 % des Lebens |
| 4 Teile | **Blutpakt**: jede Sekunde −2 % Leben, **immer**, auch ohne Gegner; der Lebensraub zählt doppelt; ein Fünftel dessen, was er heilen **könnte**, trifft den Gegner zusätzlich — auch bei vollem Leben; **sonst heilt nichts**: Heilfähigkeiten, Heilkugeln, die Kill-Heilung, der zweite Atem und das Rückspulen treffen stattdessen den nächsten Gegner in Sicht mit genau dem Betrag |

**Die Naht**: Eine Kraft am Helden ist ein neues `PitPassive` (wie
Kampfrausch und Ruhepuls), das die Ausrüstung über einen neuen
`PitModifier` mitbringt, `GrantPassive`. `PitModifiers.apply` lässt jede
Fähigkeit dabei unverändert; `ActionWorld` sammelt die Passive der
Plätze und der Ausrüstung an einer Stelle. Ausgeführt wird in
`gear_powers.dart`. Die sechs legendären Kräfte und die neuen stehen in
**einer** Liste, `PitGearPowers` (vorher `PitLegendaries`), und das Feld
am Stück heißt `GearItem.power` (vorher `legendaryPower`). Ein Set
bringt Kräfte über `SetPerk.powers` mit.

## Begründung

**Drei Fragen vor dem Bau**, beantwortet von AktivesBrett:

- **Wann blutet der Blutpakt?** Immer, nicht nur im Kampf — Claude
  hatte „nur im Kampf“ empfohlen, weil man sonst auf dem Weg zwischen
  den Räumen stirbt. AktivesBrett: „du sollst immer Schaden bekommen …
  ich probiere es mal aus und sage, ob es zu schwer ist.“
- **Der Raub-Schaden erst mit allen vier**, nicht je Teil (gegen Claudes
  Empfehlung): Einzelne Teile heilen nur.
- **Kill-Heilung und Heilkugeln werden mit vier Teilen zu Schaden**
  (beide wie empfohlen): eine Regel für alles, was nicht Lebensraub ist.

**Ohne Rückfrage entschieden:**

- **Die Seltenheiten**: das Vampirset episch, Frostreif und Irrlichter
  legendär. Das Vampirset ist das **erste verdiente Set** — man braucht
  Heilfähigkeiten, die es zu Schaden machen kann, und die gibt es früh
  nicht. Ein Set ist ganz offen oder ganz verdient, nie halb (Test).
- **Zwölf statt zehn**: Sechs Plätze mal zwei sind zwölf; AktivesBrett
  hatte zehn gesagt und „2 pro Kategorie“ gemeint.
- **Eine umgeleitete Heilung trifft den nächsten Gegner in Sicht bis
  240**, sonst verpufft sie. Der Treffer selbst lädt keine Ultimate und
  raubt kein Leben; fällt der Gegner daran, zählt der Kill wie ein
  eigener.
- **Der Blutpakt ist kein Treffer**: kein Kampfrausch, kein Flickwerk,
  und Unverwundbarkeit schützt nicht vor ihm.
- **Lebensraub nur mit eigener Hand**: Grundangriff und Fähigkeiten,
  nicht Dauerschaden, nicht Begleiter, nicht Irrlichter.
- **Irrlichter fliegen über Wände**, suchen aber nur, was der Held sieht
  (wie Falke und Pflanze, ADR-0073); ihre Kills laden die Ultimate
  nicht. Jedes sucht einen anderen Gegner, solange es genug gibt.
- **Das Echo wiederholt nur Treffer**, nicht Heilung, Mana, Sprünge oder
  Flächen — sonst wäre jede vierte Atemzug-Ladung umsonst.
- **Lebensraub trifft auch den Grundangriff.** „Ein Set wirkt nie auf den
  Grundangriff“ meinte Schadensfaktoren; Lebensraub vervielfacht keinen
  Schaden, er heilt. Der Raub-Schaden des Blutpakts ist ein Fünftel von
  24 %, also rund 5 % des Schadens obendrauf — weit unter der Grenze von
  `weaponBuffCap` (25 %).

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Kräfte nur auf Legendären, alles andere als Zahlen | AktivesBrett will Kräfte auf jeder Seltenheit |
| Eine zweite Naht neben `PitModifier` für Kräfte am Helden | zwei Wege in die Welt; `GrantPassive` nutzt den einen, den Sets und Kräfte schon gehen |
| Blutpakt nur im Kampf | AktivesBrett: immer |
| Raub-Schaden je Teil | AktivesBrett: erst mit allen vier |
| Heilkugeln fallen mit vollem Set nicht mehr | dann lohnte Einsammeln nicht; als Schaden lohnt es |
| Vampirset offen kaufbar wie die anderen drei | ohne Heilfähigkeiten bleibt vom Pakt nur der Abzug |

## Konsequenzen

- **Zehn Stücke je Platz, sechs offene, vier verdiente.** Die alte Form
  (2–2–1, 2–1) ist jetzt Untergrenze; Rüstung, Ring und Talisman haben
  zwei seltene, Ring und Talisman zwei legendäre.
- **Das Amulett der Irrlichter ist nach Zahlen der beste Talisman** und
  zieht damit in die Spalte „beste Ausrüstung“ von `pit_sim` ein.
- **Ein Set kann jetzt Kräfte tragen**, nicht nur Faktoren: Wer ein Set
  baut, das auf den Helden wirkt, gibt ihm `SetTarget.held` und Kräfte.
- **Seelenraub trifft mit dem Blutpakt praktisch doppelt**: Er heilt um
  seinen ganzen Schaden, und der Pakt macht diese Heilung zu Schaden am
  nächsten Gegner. Das folgt der Regel „was heilt, trifft“ und ist nicht
  abgefangen.
- **Jede neue Heilung geht über `_healHero`**, sonst heilt sie am
  Blutpakt vorbei.
- **Gezeichnet, nicht Raven**: zwölf Ladenbilder, zwei Bilder für die
  Grundangriffe, sechs für die Figur (`tool/item_icons.py`). Rüstungen
  und Helme auf der Figur sind umgefärbte Umrisse von Lederwams und
  Lederkappe.
- **Gemessen** (`dart run tool/pit_sim.dart ausruestung 40`): siehe
  `state.md`, Eintrag vom 19.10.
- **Nicht gespielt, nicht am Handy.** Ob der Blutpakt zu hart ist, will
  AktivesBrett selbst ausprobieren.
- **Frederik hat diese Runde nicht gesehen.**
