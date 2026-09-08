# ADR-0032: Eine Gegnerreihe statt des Dungeons — und Belohnung genau einmal je Gegner

**Datum:** 08.09.2026
**Status:** Aktiv
**Entschieden von:** Prozesstek

## Kontext

Issue [#36](https://github.com/Prozesstek/LifesGame/issues/36) beschreibt
einen Bildschirm mit dreißig aufsteigenden Gegnern, einer
Fortschrittsanzeige „1 / 30", einem Platzhalterbild und einem
Kampf-Knopf. Zweck laut Issue: „Motivation / Vergleich zwischen den
Spielern während des Teststarts." Dazu ein Satz, der zwei bestehende
Entscheidungen berührt: **„Als Belohnung gibt es Gold und XP."**

Das kollidierte an zwei Stellen mit dem Repo.

**Erstens ist das nicht der Dungeon.** `konzept.md` 3.4 und Ziel 6 in
`ziele.md` beschreiben etwas anderes: vier Gegner plus Boss in *einem*
Lauf, HP heilt nicht dazwischen, Tränke und Wiederbelebung, Eintritt
kostet Gold, Niederlage heißt von vorn. `konzept.md` markiert die
Niederlagen-Regel dabei selbst als ungelöst: „Niederlage + verfallener
Eintritt bestraft doppelt, und man kann sich nicht hochgrinden, weil
Stärke aus echten Habits kommt."

**Zweitens gab der Kampf bis heute ausdrücklich nichts.** `konzept.md`
Abschnitt 2 macht ihn zur *Auszahlung* des Fortschritts, nicht zu seiner
Quelle. In `test/result_dialog_test.dart` stand dazu ein Test, der genau
für diesen Moment geschrieben worden war:

> „Stünde dort eines Tages ‚+50 XP', wäre das eine Richtungsentscheidung
> und kein Textdetail — dieser Test zwingt sie ans Licht."

Er ist mit diesem Issue ausgelöst worden. Das ist die Entscheidung.

## Entscheidung

**Die Gegnerreihe ersetzt den Dungeon als Ziel 6.** Dreißig Gegner,
aufsteigend, einer nach dem anderen; der Lauf-Dungeon mit Zermürbung,
Tränken und Eintrittsgeld wandert hinter den Teststart.

**Ein erstmals besiegter Gegner zahlt Erfahrung und Gold. Ein zweiter
Sieg gegen denselben Gegner zahlt nichts.**

## Begründung

**Zur Reihe statt zum Dungeon:** Sie dient Ziel 7 unmittelbar — die Zahl
„17 / 30" ist das, was zwei Spieler vergleichen, und genau das nennt das
Issue als Zweck. Sie braucht dafür keine neue Mechanik, nur einen Zähler
und eine Gegnerkurve. Der Dungeon braucht dagegen Tränke, Wiederbelebung,
eine Eintrittsökonomie **und** zuerst eine Entscheidung, die seit dem
ersten Konzeptentwurf offen ist. Zwischen dieser Entscheidung und dem
20.09. lagen zwölf Tage.

**Zur Belohnung:** Der Einwand aus `konzept.md` trifft nur
**wiederholbare** Belohnung. Er lautet vollständig: Gäbe es XP fürs
Gewinnen, könnte man Kämpfe grinden statt Häkchen zu setzen. Das setzt
voraus, dass sich derselbe Kampf beliebig oft auszahlen lässt.

Für eine einmalige Auszahlung je Gegner gibt es im Repo bereits ein
Vorbild, und zwar an der Stelle, die dem Kampf am nächsten liegt: Eine
Lektion in `package:theory` zahlt Erfahrung und Gold **einmal**, danach
nie wieder. Die Reihe verhält sich genauso. Der Gesamtbetrag steht
dadurch als Zahl fest und lässt sich nachrechnen —
`LadderRewards.lifetimeXp` sind 2775 Erfahrung und
`LadderRewards.lifetimeGold` 1110 Gold über dreißig Kämpfe.

Damit bleibt die Aussage des Produkts unangetastet: Der überwiegende Teil
der Werte kommt weiter aus Gewohnheiten und Theorie, und kein Kampf lässt
sich zur Dauerquelle machen.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Gar keine Belohnung, nur der Zähler | Wäre unverändert konzepttreu gewesen und hätte keinen ADR gebraucht. Ein gewonnener Kampf bliebe dann aber materiell folgenlos — und die Reihe soll dreißig Tage lang tragen. |
| Belohnung bei jedem Sieg | Genau der Fall, den `konzept.md` ausschließt: Der leichteste Gegner ließe sich in Dauerschleife schlagen. Die Aussage „was du im Alltag tust, macht deinen Charakter stark" wäre widerlegt. |
| Reihe **und** Dungeon bis zum 20.09. | Ehrlich terminiert heißt das: Der Dungeon fällt hinter den Termin. Dann lieber gleich so planen, statt es im Nachhinein festzustellen. |
| Die dreißig Gegner als sechs Läufe zu je fünf | Verbände beides, ist aber deutlich mehr als der Entwurf zeigt — und der Entwurf zeigt einen Gegner mit einem Knopf. |
| Durch geschlagene Gegner blättern und sie erneut kämpfen | Der Entwurf zeigt genau einen nächsten Gegner. Der Preis ist benannt: Wer hängenbleibt, hat einen Kampf im Spiel. |

## Konsequenzen

**Leichter:** Der Kampf hat zum ersten Mal einen Fortschritt, der über
einen einzelnen Kampf hinausreicht — und eine Zahl, die zwei Spieler
vergleichen können. Die Gegnerwahl entfällt und mit ihr eine Frage, die
der Spieler vor jedem Kampf beantworten musste.

**Schwerer:** `konzept.md` 3.4 und Ziel 6 beschreiben ab jetzt etwas,
das nicht gebaut wird; beide sind nachgezogen. Der Kampf zahlt in
`totalXpProvider` und `goldEarnedProvider` ein, also berührt er die vier
Kurven aus `progression_test.dart` — wer an `LadderRewards` dreht, lässt
diesen Test laufen.

**Unangenehm, und gemessen:** Die Reihe steigt in ihren *Werten* stetig,
in der gemessenen Siegquote aber nicht. Zwischen Sprosse 16 und 17
springt sie nach oben (2 % auf 32 % für einen Charakter ohne
Ausrüstung), weil dort das Moveset der Gegner von Uncommon auf Rare
wechselt und die Rare-Züge mehr Energie kosten, als die Gegner auf
dieser Stufe haben. Es ist derselbe Effekt, der beim Bergwächter schon
einmal auffiel (`state.md`, 26.08.: „Donnerkeil kostet 5 Energie —
Kraftschlag konnte er öfter spielen"). Behoben ist er nicht; Balancing
bleibt zurückgestellt, aber der Befund steht jetzt mit Zahlen da.

**Ebenfalls gemessen:** Ein voll ausgerüsteter Charakter an Tag 60
gewinnt gegen die Sprossen 1 bis 27 zu 100 % und gegen Sprosse 30 zu
62 %. Die Reihe ist damit erreichbar, wie das Issue es verlangt — aber
ihre obere Mitte ist für jemanden mit Ausrüstung flach. Nachzurechnen
mit `dart run tool/balance_sim.dart`, Abschnitt „Die Reihe".
