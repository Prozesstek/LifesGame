# ADR-0006: Levelkurve als eigenes Package

**Datum:** 12.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Der Skillbaum (ADR-0007) braucht ein Charakterlevel, um Zweige freizugeben.
Ein Level gab es bisher nicht — nur Erfahrungspunkte aus der Theorie.

Damit stellte sich die Frage, wo die Umrechnung von Erfahrung in Level
hingehört. Naheliegend wären `packages/theory` gewesen (dort entsteht die
Erfahrung) oder ein Riverpod-Provider in `lib/`.

## Entscheidung

Die Levelkurve liegt in `packages/progression`, einem eigenen reinen
Dart-Package ohne Dependencies. `lib/progression/level_provider.dart` schlägt
dort nur nach und rechnet nicht selbst.

## Begründung

Das Level gehört nicht der Theorie. Laut Konzept speisen sich 50 % des
Fortschritts aus Habits, 30 % aus Theorie und 20 % aus Kämpfen. Läge die
Kurve in `packages/theory`, müsste der Habits-Teil später auf ein
Theorie-Package zugreifen, um zu wissen, welches Level er erzeugt hat. Das ist
die falsche Richtung.

Ein Provider in `lib/` scheidet aus demselben Grund aus wie bei der
Kampfbalance: Eine Kurve ist eine Spielzahl. Als Package lässt sie sich
durchrechnen, ohne die App zu starten — der Test „jede Schwelle ergibt exakt
ihr Level" läuft über alle fünfzig Stufen in Millisekunden.

Die Kurve selbst steigt **linear**, nicht exponentiell: Fortschritt kommt aus
echten Gewohnheiten und lässt sich nicht durch Grinden beschleunigen. Eine
exponentielle Kurve würde die späteren Stufen schlicht unerreichbar machen.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Kurve in `packages/theory` | Macht die Theorie zum Besitzer des Charakterlevels; Habits müssten später darauf zugreifen |
| Nur ein Riverpod-Provider in `lib/` | Spielzahl im Widget-Layer, gegen die Schichtregel; nicht ohne Flutter testbar |
| Level aus der Anzahl bestandener Lektionen statt aus XP | Hätte funktioniert, aber nur solange Theorie die einzige Quelle ist — genau das soll sie nicht bleiben |

## Konsequenzen

**Leichter:** Habits und Kämpfe können später Erfahrung beisteuern, ohne dass
sich an der Kurve etwas ändert. Erweitert wird an genau einer Stelle
(`totalXpProvider`), nicht an fünf.

**Schwerer:** Ein viertes Package im Repo. Und eine Frage, die keines der
Packages allein beantworten kann: ob Belohnungskurve und Levelkurve so
zusammenpassen, dass der Baum spielbar bleibt. Dafür gibt es jetzt
`test/progression_test.dart` in der App — der einzige Ort, an dem beide
zusammenkommen. Der Test spielt den Baum Stufe für Stufe durch und schlägt
Alarm, wenn er zur Sackgasse wird.
