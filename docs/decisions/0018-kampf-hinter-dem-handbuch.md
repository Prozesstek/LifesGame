# ADR-0018: Der Kampf öffnet sich erst nach dem Handbuch

**Datum:** 22.08.2026
**Status:** Ergänzt durch ADR-0020

> **Was ADR-0020 ändert:** Die Sperre hängt nicht mehr am Handbuch allein,
> sondern zusätzlich an der Zahl der Moves. Der Grund ist ADR-0019 — seit
> die vier wählbaren Fähigkeiten an Theorieknoten hängen, kann der zweite
> Slot aufgehen und leer bleiben.
> **Was hier gültig bleibt:** die Begründung und die Arithmetik. Fünf
> Lektionen geben Level 3, vier nicht, und mit einem Move steht der erste
> Gegner bei 0 %.
**Entschieden von:** Frederik

## Kontext

Mit [ADR-0017](0017-faehigkeitskatalog-aus-drei-quellen.md) hängt das
Moveset an den Fähigkeitsslots, und die öffnen sich laut
[ADR-0016](0016-faehigkeitsslots-vor-den-faehigkeiten.md) auf Level 1 /
3 / 6 / 10. Ein Charakter auf Level 1 hat damit **genau einen Move**: den
der Waffe.

Die Simulation hat gemessen, was das bedeutet — Tag-0-Werte gegen den
leichtesten Gegner:

| Moves | Siegquote |
|---|---|
| 1 (nur Waffe) | **0 %** |
| 2 | 100 % |

**Das ist kein knappes Rennen, sondern ein unmögliches.** Der Bogen allein
richtet rund 10,6 Schaden je Runde an, der Wegelagerer 15,3. Ohne einen
Move, der Energie *ausgibt*, fehlt der Auszahlungsmoment; die Länge des
Kampfes ändert daran nichts.

Gleichzeitig fiel beim Nachrechnen etwas auf, das die Antwort schon
enthielt: Der freie Zweig „Gewohnheiten" — das Handbuch der App, das laut
[ADR-0012](0012-theoriebaum-ueber-punkte.md) keinen Theoriepunkt kostet —
gibt genug Erfahrung für Level 3. Wer ihn liest, hat zwei Slots und
gewinnt. **Diese Reihenfolge ergab sich bereits von selbst — nur wusste sie
niemand, und nichts im Spiel sagte sie.**

## Entscheidung

**1. Die Kachel „Kampf" auf dem Startbildschirm ist gesperrt**, bis jede
Lektion des Zweigs „Gewohnheiten" bestanden ist.

**2. Die Kachel bleibt sichtbar** und nennt den Weg dorthin, statt zu
verschwinden.

**3. Die Bedingung ist der *abgeschlossene* Zweig**, nicht ein Level und
nicht eine Lektionszahl.

## Begründung

**Warum überhaupt eine Sperre und keine Warnung.** Der Kampfbildschirm
hätte auch sagen können „das wird nichts" — die Gegnerwahl hat bereits eine
Einschätzung. Aber eine Warnung vor einem Kampf, der zu **0 %** ausgeht,
ist keine Einschätzung, sondern eine Höflichkeitsform für „geht nicht". Wer
sie überliest, verliert seinen ersten Kampf und lernt daraus nichts über
das Spiel.

**Warum der abgeschlossene Zweig und nicht Level 3 direkt.** Beides führt
zum selben Ergebnis, aber nur eines davon ist erklärbar. „Lies das
Handbuch, dann kämpf" ist ein Satz, den ein Spieler versteht. „Erreiche
Level 3" ist eine Zahl, die er nicht beeinflussen kann, ohne zu wissen wie.

Der zweite Grund wiegt schwerer: Eine Levelsperre wäre wieder das, was
ADR-0012 gerade abgeschafft hat. Dort entfielen die Levelsperren an den
Theoriezweigen, weil eine Sperre eine Reihenfolge vorgibt, wo eine Wahl
stehen sollte. Hier ist eine Reihenfolge richtig — aber sie soll an einer
**Handlung** hängen, nicht an einem Zählerstand.

**Warum die Zahl aufgeht, und das ist der eigentliche Fund.** Das Handbuch
ist exakt so lang, dass es den zweiten Slot öffnet:

| Lektionen | XP | Level |
|---|---|---|
| 4 | 220 | 2 |
| **5 (der ganze Zweig)** | **275** | **3** |

Level 3 braucht 225 XP. Vier Lektionen liegen fünf Punkte darunter, fünf
darüber. **Die Sperre ist damit keine erfundene Hürde, sondern genau die
Bedingung, die den ersten Kampf gewinnbar macht** — sie fällt in dem
Moment, in dem der Spieler den zweiten Move bekommt.

Das ist ein Zufall, kein Entwurf, und er sollte als solcher behandelt
werden: Wer an `TheoryRewards`, an der Levelkurve oder an der Länge des
Zweigs dreht, kann ihn zerstören. Deshalb steht die Zusammenhang-Prüfung in
`test/progression_test.dart`, wo die vier Kurven ohnehin gegeneinander
gehalten werden.

**Warum die Kachel sichtbar bleibt.** Hausregel des Startbildschirms, schon
zweimal formuliert (ADR-0013, ADR-0016): „Ein Startbildschirm, der nur
zeigt, was schon fertig ist, verschweigt, worum es geht." Ein Habit-Tracker,
der einen Kampf verspricht, muss den Kampf zeigen — sonst fehlt der Grund,
das Handbuch überhaupt zu lesen.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Slot 2 schon auf Level 1 öffnen | Nimmt dem ersten Levelaufstieg seine Wirkung und widerspricht ADR-0012/0016; die Sperre löst dasselbe, ohne eine Entscheidung zurückzunehmen |
| Den ersten Gegner schwächer machen | Rührt an die über die Simulation austarierte Gegnerreihe (ADR-0009) und macht den Kampf für **alle** leichter, nicht nur für Level-1-Spieler |
| Nur warnen statt sperren | Eine Warnung vor 0 % ist eine Höflichkeitsform für „geht nicht"; wer sie überliest, verliert und lernt nichts |
| An Level 3 sperren statt an den Zweig | Dieselbe Wirkung, aber nicht erklärbar — und es wäre die Levelsperre zurück, die ADR-0012 abgeschafft hat |
| An eine Lektionszahl sperren | Ein halb gelesener Zweig ist genau das Verhalten, vor dem `konzept.md` warnt; ADR-0013 macht das Abschließen bewusst zum Anreiz |
| Kachel ausblenden statt sperren | Verschweigt, worum es im Spiel geht — und damit den Grund, das Handbuch zu lesen |

## Konsequenzen

**Leichter:** Der erste Kampf ist gewinnbar, ohne dass eine Zahl im
Kampfsystem angefasst wurde. Der freie Theoriezweig bekommt eine Aufgabe
über das Erklären hinaus — er ist jetzt der Einstieg, und das Handbuch
liest sich nicht mehr optional.

**Schwerer:** Das Spiel hat eine Sperre mehr, und sie steht vor dem
sichtbarsten Teil. Wer die App öffnet, um zu kämpfen, muss erst lesen. Das
ist beabsichtigt, aber es ist eine Wette darauf, dass die fünf Lektionen
kurz genug sind.

**Ein Zufall trägt jetzt Gewicht.** Dass fünf Lektionen genau Level 3
ergeben, ist nicht entworfen, sondern gemessen. Wer `TheoryRewards`, die
Levelkurve oder die Länge des Zweigs ändert, muss
`test/progression_test.dart` laufen lassen — dort ist die Bedingung
festgeschrieben.

**Offen:** Ob die Sperre bleiben kann, wenn die elf übrigen Fähigkeiten aus
ADR-0017 gebaut sind. Dann könnte eine Waffe mit anderem Rhythmus den
ersten Kampf auch allein tragen — und die Sperre wäre wieder Bevormundung
statt Hilfe. Nachzurechnen, sobald es mehr als eine Waffenfähigkeit gibt.
