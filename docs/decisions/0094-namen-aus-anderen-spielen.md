# ADR-0094: Namen, die Spieler aus anderen Spielen kennen

**Datum:** 02.11.2026
**Status:** Aktiv
**Entschieden von:** Frederik, aus Claudes Vorschlagsliste; „Tagesdungeon“ und „Sprosse“ ohne Rückfrage von Claude

## Kontext

Nutzer beklagen, dass die App nicht intuitiv ist (`state.md`, 24.10.). Ein Teil
davon sind eigene Wörter, die man erst lernen muss: „Grube“, „Wächter“,
„Theoriepunkt“. Dazu kommt, dass dieselbe Sache mehrere Namen trug. Eine Etage
des Kampfs hieß im Eingang „Ebene“, drinnen „Stufe“ und in den
Errungenschaften „Sprosse“.

Frederik: „ich würde gerne manche Bereiche umbennenn sowie der Spieler sie aus
anderen Spielen kennt“. Aus der Liste gewählt hat er die fünf obersten,
„mit Talentpunkten statt Skillpunkten“.

## Entscheidung

Auf dem Bildschirm heißen jetzt:

| vorher | jetzt |
|---|---|
| die Grube | **der Dungeon** |
| Tagesgrube | **Tagesdungeon** |
| Ebene, Stufe, Sprosse (der Grube) | **Etage** |
| der Wächter | **der Boss** |
| Theoriepunkte, Skillbaum | **Talentpunkte, Talentbaum** |
| Tagesaufgaben | **Dailies** |

**Nur der Text auf dem Bildschirm ändert sich.** Bezeichner im Code
(`PitStage`, `DailyPit`, `BossKind`, `TheoryPoints`, `DailyQuests`), Schlüssel
der Tests, der Spielstand und alle früheren ADRs bleiben, wie sie sind.

## Begründung

- „Dungeon“, „Boss“, „Etage“ und „Dailies“ kennt jeder, der Diablo, Hades oder
  ein Handyspiel gespielt hat. Das Wort erklärt sich selbst.
- **Talent statt Skill**: Seit ADR-0085 heißen die vier Gebiets-Level
  „Skills“. Mit „Skillpunkten“ für den Baum hätte ein Wort zwei Bedeutungen.
- **Etage für alles**: Ein Wort für eine Sache. Das löst den Punkt „‚Stufe‘
  meint vier Dinge“ vom 24.10. für den Kampf. Skills, Haustier und die
  Stufen der Sammlung heißen weiter „Stufe“.
- **Tagesdungeon** ist ohne Rückfrage dazugekommen: Neben „Dungeon“ wäre
  „Tagesgrube“ ein Rest.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| auch die Bezeichner im Code umbenennen | großer Umbau ohne Nutzen für Spieler; ADRs und Gedächtnis sprechen von der Grube |
| Skillpunkte | doppelt belegt mit den Skills aus ADR-0085 |
| Verlies statt Dungeon | deutsch, aber weniger bekannt aus Spielen |

## Konsequenzen

- **Code und Bildschirm sprechen verschieden**: Im Code und in `CLAUDE.md`
  heißt es weiter „Grube“, auf dem Bildschirm „Dungeon“. Wer einen neuen Text
  schreibt, nimmt die Namen aus der Tabelle oben.
- Die Errungenschaften heißen jetzt „Zehn Etagen“ und „Zwanzig Etagen“.
  Ihre Ids bleiben, verdient bleibt verdient.
- Der geteilte Text der Tagesgrube beginnt jetzt mit „Tagesdungeon #…“.
- Der Kreis auf der Startseite hieß schon „Kampf“ und bleibt so.
- Der Prototyp der Grube im Entwicklermodus heißt weiter „Die Grube“.
