# ADR-0004: Theorie-Inhalte als eigenes Dart-Package

**Datum:** 12.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Der Theorieteil sollte gebaut werden. Das Konzept nennt ihn ausdrücklich das
größte Projektrisiko — und zwar kein technisches: Jeder Zweig kostet Wochen an
Schreibarbeit, nicht an Programmierarbeit.

Damit stellte sich die Frage, wo die Inhalte liegen. Der naheliegende Ort wäre
`lib/theory/` gewesen, direkt neben den Bildschirmen, die sie anzeigen.

## Entscheidung

Lektionstexte, Fragen, Bestehensgrenze und Belohnungslogik liegen in
`packages/theory` — einem reinen Dart-Package ohne Dependencies, analog zu
`packages/combat`. `lib/theory/` enthält nur die Darstellung.

## Begründung

Wer Inhalte schreibt, arbeitet anders als wer Bildschirme baut. Er schreibt
lange Texte, achtet auf Verständlichkeit und macht dabei genau zwei Sorten
Fehler: Zahlendreher im `correctIndex` und doppelte Lektions-Ids. Beide fallen
beim Durchklicken kaum auf.

Als eigenes Package lässt sich beides mit `dart test` in einer halben Sekunde
prüfen, ohne Flutter, ohne laufende App, ohne Emulator. `habits_content_test.dart`
tut genau das: Es prüft nicht Code, sondern Inhalt.

Der zweite Grund ist derselbe wie bei der Kampflogik: Was eine Lektion einbringt,
ist eine Spielzahl. Spielzahlen gehören nicht in Widgets. Alle stehen in
`TheoryRewards`.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Inhalte in `lib/theory/` neben den Screens | Tests brauchen dann `flutter test`; die Trennung zwischen Inhalt und Darstellung verwischt, sobald es eng wird |
| Inhalte als JSON/YAML im `assets/`-Ordner | Kein Compiler, der Tippfehler findet; ein falscher Schlüssel fällt erst zur Laufzeit auf. Der Vorteil — Inhalte ohne Neubau ändern — zählt erst bei Cloud-Inhalten, und die sind laut Konzept raus |
| Inhalte in `packages/combat` mit unterbringen | Zwei Themen in einem Package; `combat` soll die Kampfbalance bleiben |

## Konsequenzen

**Leichter:** Lektionen schreiben und prüfen, ohne die App zu starten. Ein
zweiter Zweig ist eine neue Datei in `lib/src/content/`, sonst nichts. Die
Belohnungszahlen stehen an einem Ort und lassen sich wie die Kampfbalance
gezielt drehen.

**Schwerer:** Ein drittes Package im Repo, das beim Aufsetzen `dart pub get`
braucht. Und: Inhalte lassen sich nicht ohne neuen Build ändern — ein
Tippfehler im Text erfordert ein Deployment. Das ist der Preis dafür, dass der
Compiler mitliest.
