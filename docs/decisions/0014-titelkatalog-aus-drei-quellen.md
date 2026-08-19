# ADR-0014: Der Titelkatalog steht, und er speist sich aus drei Quellen

**Datum:** 19.08.2026
**Status:** Aktiv
**Entschieden von:** AktivesBrett

## Kontext

[ADR-0013](0013-charakter-als-kommandozentrale.md) legte fest, dass der
Charakter Name und Titel bekommt: Name eingegeben, Titel **verdient**. Was
offen blieb, stand dort ausdrücklich als offener Punkt: „Der Titel-Katalog und
seine Bedingungen."

Ohne Katalog ist die Entscheidung nicht baubar. Ein Bildschirm mit einem Knopf
„Titel wählen", hinter dem nichts steht, ist schlimmer als kein Knopf.

Dazu kam eine zweite Frage, die beim Bauen sofort auftauchte: An **welcher**
Streak hängt ein Streak-Titel? Die laufende Kette ist die naheliegende Antwort
und die falsche.

## Entscheidung

**1. Sieben Titel, drei Quellen.** Streak-Tage, bestandene Lektionen, gesetzte
Häkchen — je Quelle aufsteigend:

| Titel | Bedingung | Quelle |
|---|---|---|
| der Entschlossene | 3 Tage am Stück | Streak |
| der Beständige | 30 Tage am Stück | Streak |
| der Unbeirrbare | 60 Tage am Stück | Streak |
| der Wissbegierige | 5 bestandene Lektionen | Theorie |
| der Belesene | 12 bestandene Lektionen | Theorie |
| der Verlässliche | 50 Häkchen | Menge |
| der Unermüdliche | 200 Häkchen | Menge |

**2. Die Bedingung hängt an der längsten je gelaufenen Kette**
(`HabitTracker.longestStreak`), nicht an der laufenden.

**3. Ein sechstes Package, `packages/identity`.** Reines Dart, leerer
`dependencies`-Block wie die anderen fünf. Es kennt weder `habits` noch
`theory`; die App reicht drei Zahlen als `TitleStats` herein.

**4. Der gespeicherte Titel ist eine Wahl, kein Nachweis.** Ob er getragen
wird, entscheidet `Identity.titleFor` bei **jeder** Anzeige neu gegen den
Fortschritt.

## Begründung

**Warum drei Quellen und nicht nur Streaks.** Ein Katalog nur für Streaks
würde belohnen, wer lange dabei ist; einer nur für Lektionen, wer viel liest.
Nebeneinander sagen die Titel etwas über den **Stil** — und genau das ist laut
ADR-0013 ihr Sinn: Wo eine Klasse sichtbar wird, wird sie aus dem Verhalten
abgeleitet, nie gewählt. Drei Spieler mit demselben Level können drei
verschiedene Titel tragen.

**Warum die längste und nicht die laufende Kette.** Das ist die eigentliche
Entscheidung dieses Dokuments. ADR-0013 sagt „einmal verdient heißt behalten",
und `konzept.md` 3.7 sagt „verpasste Habits werden nicht bestraft — der Bonus
fehlt einfach". Ein Titel, der bei einem Grippetag verschwindet, verletzt
beides. Er wäre auch genau der erhöhte Einsatz, wegen dem der
Streak-Multiplikator bei x2 gedeckelt wurde, damit „Nutzer nicht aufgeben statt
neu anzufangen" (ADR-0008).

Die Folge ist eine Eigenschaft, die sich testen lässt und getestet wird:
**Mehr Fortschritt nimmt nie einen Titel weg.**

**Warum ein eigenes Package und nicht `lib/`.** Die Schwellen sind Spielzahlen.
`CLAUDE.md` ist da eindeutig: „Sobald in `lib/` eine Spielzahl berechnet wird,
gehört sie in eines der Packages." Der leere `dependencies`-Block macht die
Schichtregel erzwingbar statt nur vereinbart (ADR-0003).

**Warum die Wahl im Spielstand nicht geprüft wird, sondern beim Anzeigen.**
Zwei Wahrheiten darüber, was jemand geschafft hat, wären dieselbe Fehlerquelle,
die bei Gold und Erfahrung schon vermieden wurde (ADR-0008, ADR-0011). Ein von
Hand bearbeiteter Spielstand kann so keinen unverdienten Titel einbringen — und
umgekehrt bleibt eine Wahl erhalten, statt beim Laden still gelöscht zu werden.

**Warum „der Wissbegierige" an Lektionen hängt und nicht an Knoten.**
ADR-0013 nennt „den fünften abgeschlossenen Knoten". Knoten gibt es noch nicht;
der Baum wird erst mit [ADR-0012](0012-theoriebaum-ueber-punkte.md) zu einem.
Bis dahin zählen Lektionen. Beim Umbau wandert die Bedingung mit, der Titel
bleibt — der Kommentar dazu steht im Katalog.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Titel frei eintippbar | Widerspricht dem Kern der App: Verhalten bestimmt den Charakter, nicht ein Textfeld (ADR-0013) |
| Bedingung an der **laufenden** Streak | Ein verpasster Tag nähme einen verdienten Titel weg — bestraft Verpassen, verletzt `konzept.md` 3.7 |
| Verdiente Titel im Spielstand mitschreiben | Zweite Wahrheit über den Fortschritt; genau die Fehlerquelle, die bei Gold vermieden wurde |
| Titel in `packages/habits` unterbringen | Titel hängen auch an der Theorie; `habits` dürfte `theory` dafür kennen müssen |
| Nur ein Titel je Quelle | Zu wenig Abstufung: Nach dem ersten Erreichen passiert Monate nichts mehr |
| Titel automatisch setzen, sobald verdient | Nimmt die Aussage weg. Welchen man trägt, ist die einzige Aussage, die der Spieler hier trifft |

## Konsequenzen

**Leichter:** Der Charakterbildschirm hat jetzt einen Kopf, der etwas über den
Spieler sagt statt nur Zahlen zu summieren. Ein neuer Titel ist ein Eintrag in
`title_catalog.dart` — `title_catalog_test.dart` prüft ihn automatisch mit
(eindeutige Id, lesbare Bedingung, mindestens eine Schwelle, Monotonie).

**Schwerer:** Es gibt jetzt eine sechste Kurve, die zu den vier bestehenden
passen muss. Die Schwellen sind **nicht** gegen die Levelkurve simuliert —
anders als Preise und Belohnungen, für die `progression_test.dart` das tut. Bei
sieben Titeln ohne mechanische Wirkung ist das vertretbar; sobald ein Titel
etwas *bewirkt*, ist es das nicht mehr.

**`longestStreak` ist neu in `packages/habits`** und damit eine öffentliche
Zusage: Sie darf nie sinken.

**Offen:** Ob ein Titel später etwas bewirken soll. Heute ist er reine
Aussage — und solange das so bleibt, braucht er keine Balance.
