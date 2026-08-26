# ADR-0023: Der Gegner spielt nach denselben Regeln wie der Spieler

**Datum:** 26.08.2026
**Status:** Aktiv
**Entschieden von:** AktivesBrett

## Kontext

Gemeldet war eine fehlende Timing-Leiste: Frostnebel, Sandsturm und
Giftmoor lösten sofort aus. Die Ursache war klein — `combat_screen.dart`
öffnete das Zeitfenster nur bei `power > 0`, eine Regel aus der Zeit der
vier Moves. Beim Nachprüfen kamen vier weitere Befunde dazu, und alle
hatten dieselbe Wurzel: **Der Gegner wurde nie so behandelt wie der
Spieler.**

| Befund | Wirkung |
|---|---|
| Acht Fähigkeiten ohne Leiste | vier Perfect-Wirkungen unerreichbar |
| Gegner bekam immer `TimedHit.none` | Wurzelgriff, Sandsturm und Donnerkeils Perfect-Wirkung gegen ihn **wirkungslos** |
| Gegner erhielt nur einen Tipp | sein Klingenwirbel traf einmal statt dreimal |
| `SimpleEnemyPolicy` übersprang alles ohne Schaden | drei von sechs Zügen des Bergwächters tot |
| **`EnemyBlueprint.loadout` wurde nirgends gelesen** | *jeder* Gegner kämpfte mit dem Standard-Moveset |

Der letzte wiegt am schwersten: [ADR-0022](0022-faehigkeiten-set-aus-der-vorlage.md)
Punkt 8 („Wegelagerer nur Commons, Söldner bis Uncommon, Bergwächter bis
Rare") stand geschrieben und galt im Code nicht. Keine der fünfzehn
Fähigkeiten wurde je von einem Gegner gespielt.

Damit war auch die dokumentierte Ursache des Bergwächter-Befunds falsch:
In `state.md` und ADR-0022 steht, er sei unschlagbar, *weil* er Donnerkeil
trägt. Er trug ihn nie — er schlug mit Kraftschlag zu, `power` 2,2 gegen
Donnerkeils 2,125.

## Entscheidung

**Der Gegner spielt nach denselben Regeln wie der Spieler.** Er tippt, er
kann perfekt treffen, er benutzt Schutz und Umgebungen, und er kämpft mit
dem Moveset, das an seinem Bauplan steht.

Im Einzelnen:

1. **Ob getippt wird, entscheidet der Move**, nicht der Bildschirm:
   `Move.hasTimingWindow` fragt „ändert Perfect an diesem Zug etwas?".
   Abgeleitet aus `dealsDamage`, `perfectFactor` und `perfectEffects` —
   nicht als Flag gesetzt.
2. **Der Gegner würfelt eine Stelle auf der Leiste**, gewertet mit
   denselben Fenstern (`TimingSpec.judgeAt`).
3. **Er greift manchmal zu Utility**, mit einer Quote je Gegner:
   Wegelagerer 10 %, Söldner 20 %, Bergwächter 30 %.
4. **Perfekt gelegt hält eine Umgebung eine Runde länger.** Das gilt für
   die vier, für die die Vorlage keine Perfect-Wirkung nennt, und für
   Vulkanbruch.
5. **`Sammeln` und `Atemzug` bekommen keine Leiste.** Sie haben keine
   Perfect-Wirkung.

## Begründung

**Zielgenauigkeit über die Fenster statt über eine Quote je Gegner.** Ein
Zug mit 24 % Fenster wird in etwa 24 % der Fälle perfekt getroffen, einer
mit 4 % fast nie — die Staffelung steckt bereits in `TimingSpec`. Eine
eigene Trefferquote je Gegner wäre ein zweiter Satz Zahlen neben den
Fenstern, der mit ihnen auseinanderlaufen kann. Und nur so wirken die
Fähigkeiten, die das gegnerische Fenster verengen: `effectiveTiming`
rechnet Wurzelgriff und Sandsturm ohnehin schon ein.

**Utility gewürfelt statt gerechnet.** Eine Policy, die den besten
Utility-Zug ausrechnet, macht die Gegner berechenbar. Das Konzept lässt
interessante Gegner aus Werten und Move-Sets entstehen, nicht aus schlauer
Suche. Herausgefiltert wird nur, was offensichtlich verschwendet wäre —
heilen bei über 80 % HP, die eigene Umgebung nachlegen, einen stehenden
Schutz stapeln, Energie sammeln bei vollem Balken. Ohne diese vier Sperren
liest sich der Zufall als Fehler statt als Charakter.

**Die Quote gehört an den Gegner, nicht an die Policy.** Die Policy bleibt
zustandslos und `const` — das ist die Voraussetzung dafür, dass ein Kampf
bei gleichem Seed reproduzierbar bleibt. Zufall und Quote werden
hereingereicht.

**Eine Runde länger statt gar nichts.** Ein Zeitfenster ohne jede
Auszahlung wäre reine Reibung: Der Spieler müsste tippen und bekäme
nichts. Die Alternative — die vier ohne Leiste lassen — hätte bedeutet,
dass `hasTimingWindow` nicht mehr aus den Daten ableitbar ist und als
Flag gepflegt werden müsste.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Gegner-Trefferquote je Gegner (15/30/40 %) | Zweiter Satz Zahlen neben den Fenstern; läuft mit ihnen auseinander |
| Fenster mal Geschick-Faktor je Gegner | Dieselbe Gefahr, nur kleiner. Verworfen, weil die Fenster allein bereits eine Staffelung liefern |
| Perfect bewirkt bei den vier nichts | Pflichttipp ohne Auszahlung; `hasTimingWindow` wäre nicht mehr ableitbar |
| Perfect senkt die Energiekosten | Wirkt bei Giftmoor (6 EN) ganz anders als bei Frostnebel (4 EN) — eine Regel mit ungleicher Wirkung |
| Auch `Sammeln` und `Atemzug` mit Leiste | Sie haben nichts zu gewinnen; ein Tipp ohne Wirkung ist Reibung |
| Rein zufällige Utility-Wahl ohne Sperren | Der Gegner heilt bei vollen HP — das liest sich als Fehler |
| Policy hält Zufall und Quote selbst | Zerstört Zustandslosigkeit und damit die Reproduzierbarkeit per Seed |

## Konsequenzen

**Die Balance hat sich deutlich verschoben, und überwiegend zum Guten.**
Gemessen mit `dart run tool/balance_sim.dart`:

| Gegner | Tag 0 | Tag 7 | Tag 14 | Tag 21 | Tag 30 | Tag 60 |
|---|---|---|---|---|---|---|
| Wegelagerer | 0 → **74 %** | 94 → **100 %** | 100 % | 100 % | 100 % | 100 % |
| Söldner | 0 % | 0 % | 0 % | 38 → **11 %** | 100 → **90 %** | 100 → **99 %** |
| Bergwächter | 0 % | 0 % | 0 % | 0 → **5 %** | 0 → **22 %** | 0 → **40 %** |

**Der Bergwächter ist nicht länger unschlagbar** — obwohl er jetzt
Donnerkeil trägt. Er steckt 30 % seiner Züge in Utility, und Donnerkeil
kostet 5 Energie; Kraftschlag konnte er öfter spielen.

**Die Spannweite zwischen perfektem und keinem Timing ist zurück:** 35
Punkte beim Wegelagerer an Tag 0, 46 beim Söldner an Tag 30, 33 beim
Bergwächter an Tag 60. Vorher stand dort fast überall 0. Das ist die
Aussage aus [ADR-0009](0009-kampfbalance-ueber-gegnerreihe.md) —
Gewohnheiten entscheiden, *ob* ein Kampf knapp wird, Timing entscheidet
den knappen.

**Unangenehme Folgen:**

- **Der Bergwächter erreicht auch an Tag 60 nur 40 %.** ADR-0009 wollte
  dort 100 %. Er ist jetzt der Gegner, der nie verlässlich fällt — vorher
  war er der, der nie fiel. Das ist eine Verbesserung, aber kein
  erreichtes Ziel.
- **Der Söldner ist bei Tag 21 von 38 % auf 11 % gefallen.** Er hat
  Blütentau und Prisma-Barriere und benutzt beides jetzt.
- **Alle Zahlen aus ADR-0009 und ADR-0022 sind neu zu messen.** Sie
  stammen aus Kämpfen, in denen der Gegner nie zielte und immer dasselbe
  Moveset hatte.
- **Der simulierte Spieler benutzt weiter keine Utility.**
  `tool/balance_sim.dart` steuert ihn mit derselben Policy, aber mit
  `utilityChance` 0. Die Tabelle ist damit eine **untere** Schranke für
  den Spieler und eine ehrliche für den Gegner. Das zu ändern würde die
  Bedeutung der ganzen Simulation verschieben und gehört in eine eigene
  Runde.
- **`chooseMove` hat vier Angaben mehr.** Alle optional, wer sie wegläßt
  bekommt das alte Verhalten — aber jede Test-Policy musste ihre Signatur
  nachziehen.

**Balancing bleibt zurückgestellt.** Gemessen und gemeldet ist es hiermit.
