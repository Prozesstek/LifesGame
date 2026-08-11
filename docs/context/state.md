# Projektstand

> Diese Datei ist die Antwort auf „Wo stehen wir gerade?".
> Am Ende jeder Arbeitssitzung aktualisieren. Alte Einträge unter „Verlauf"
> zusammenfassen, nicht löschen.

**Zuletzt aktualisiert:** 11.08.2026 · Frederik

---

## Phase

**Kampflogik steht und ist getestet. App-Schicht noch nicht begonnen.**

## Fertig

- Produktkonzept (`konzept.md`)
- Tech-Stack ([ADR-0001](../decisions/0001-tech-stack.md))
- Architekturregel Kampflogik/Flame ([ADR-0002](../decisions/0002-kampflogik-ohne-flame.md))
- Kampflogik als eigenes Package ([ADR-0003](../decisions/0003-combat-als-eigenes-package.md))
- **`packages/combat`** — reine Dart-Kampflogik, 23 Tests grün, Analyzer sauber:
  - 4 Move-Slots gemäß Konzept (erzeugen / verbrauchen / schwächen / stützen)
  - Timed Hits mit Deckel, Energie, Gift, Verteidigungssenkung, Heilung, Schild
  - Vollständiges Event-Vokabular als Naht zu Flame
  - Deterministisch per Seed → Balance-Simulation möglich
- **`packages/combat/example/balance_sim.dart`** — 2000 Kämpfe in 0,4 s

## Größte offene Frage: die Kampfbalance trägt noch nicht

Die Simulation hat ein Problem sichtbar gemacht, das im Konzept nicht absehbar war.
Gegner mit 18 ATK / 10 DEF, Held mit gleicher Verteidigung:

| Angriff des Helden | Siegquote |
|---|---|
| 12 | 0,0 % |
| 14 | 6,7 % |
| **16** | **52,8 %** |
| 18 | 97,4 % |
| 20 | 100 % |

**Das umkämpfte Band ist ganze zwei Angriffspunkte breit.** Darunter ist der Kampf
unmöglich, darüber geschenkt. Ein Spieler landet fast nie im spannenden Bereich.

Und der Timed-Hit-Deckel wirkt nicht wie gedacht. Bei identischem Angriffswert (18):

| Timing | Siegquote |
|---|---|
| nie getroffen | 55,6 % |
| immer perfekt | 100 % |

Die +50 % sind also kein Bonus am Rand, sondern entscheiden den Kampf allein.
Das widerspricht der Kernaussage des Konzepts („Habits sind der Hauptfaktor").

**Ursache** ist strukturell, kein Bug: Bei ~120 HP und ~18 Schaden dauert ein Kampf
nur etwa 7 Treffer. Über so wenige Runden schlägt jeder Multiplikator voll durch,
und Zufall mittelt sich nicht aus.

**Ansatzpunkte** (noch nicht entschieden):
1. HP deutlich erhöhen relativ zum Schaden → längere Kämpfe dämpfen Multiplikatoren
2. Timed-Hit-Deckel unter +50 % senken
3. Verteidigung stärker wirken lassen (`defenseSoftening` senken)

Alle drei sind eine Zeile in `packages/combat/lib/src/balance.dart` und danach ein
Simulationslauf. Genau dafür wurde das gebaut.

## Als Nächstes

1. **Balance-Frage oben klären** — mit der Simulation, nicht nach Gefühl.
2. **Flutter-SDK installieren.** Dart 3.12.2 ist da (per winget), Flutter fehlt noch.
   Danach `flutter create` im Repo-Wurzelverzeichnis.
3. **Offene Konzeptpunkte 1–3** (Streak-Deckel, Gold-Abflüsse, Niederlagen-Regel) —
   beeinflussen das Datenmodell, siehe `konzept.md` Abschnitt 6.
4. **Drift-Schema** für Habits, Streaks, Charakter, Inventar.
5. **Flame-Kampfbildschirm**, der die Events aus `packages/combat` abspielt.

## Aufgabenteilung

Noch nicht festgelegt. Die Naht ist jetzt konkret: `packages/combat` gibt
`CombatEvent`s aus, Flame spielt sie ab. Einer kann an Logik und Balance arbeiten,
der andere an Darstellung, ohne sich zu blockieren.

## Verlauf

- **11.08.2026** — Konzept in vier Fragerunden erarbeitet. Repo `Prozesstek/LifesGame`
  aufgesetzt, Gedächtnis-Struktur und geteilte ECC-Werkzeuge eingecheckt.
  Kampflogik implementiert und getestet, Balance-Simulation gebaut, erste
  Balance-Schwäche gefunden.
