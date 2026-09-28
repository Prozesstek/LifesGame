# ADR-0058: Die Figur zieht in die Ausrüstung

**Datum:** 28.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Seit Issue #35 stand die Figur in der Mitte der Startseite, darunter
Level, Gold und ein Satz zur Erfahrung (`CharacterStage`, `LevelCard`).
Mit „Heute“ (ADR-0053) gab sie an vollen Tagen Platz ab: bei fünf
offenen Gewohnheiten blieben rund 80 Punkte, und ob das zu klein ist,
stand seitdem als offener Punkt in `state.md`. Die Ausrüstung hat seit
ADR-0057 einen eigenen Bildschirm, in dem die sechs Plätze als Raster
standen — ohne die Figur, die sie trägt.

## Entscheidung

Die Figur steht im Ausrüstungs-Bildschirm zwischen den sechs Plätzen,
drei links, drei rechts. Auf der Startseite bleibt eine Zeile:
Level als Abzeichen mit der Zahl darin, der Balken, Münze und Zahl.
„Heute“ bekommt den Rest. Der Satz zur Erfahrung kommt erst auf Tipp
auf den Balken. Je zehn Level trägt das Abzeichen einen anderen Rahmen.

## Begründung

Die Startseite ist der Ort, an dem abgehakt wird; die Figur dort wurde
genau dann klein, wenn es viel abzuhaken gab. Neben den Plätzen zeigt
sie, was angelegt ist, und ein Platz und das, was er an der Figur
ändert, stehen nebeneinander. Die Zahlen brauchen ihre Wörter nicht:
Die Münze sagt „Gold“, das Abzeichen „Level“.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Figur über dem Raster der Plätze | längere Seite, und Platz und Figur stehen weiter auseinander |
| Level und Gold als Kopfzeile über den oberen Kreisen | liest sich wie die Statusleiste eines Menüs; die Zeile zwischen Kreisen und „Heute“ gehört zum Inhalt |
| Rahmen erst als Zeichnung | hätte die Umstellung an Bilder gebunden; die Tabelle `LevelRahmen` nimmt sie später an einer Stelle auf |

## Konsequenzen

- Die Startseite zeigt die Figur nicht mehr. Wer sehen will, was sie
  trägt, geht in die Ausrüstung.
- Die Rahmen sind gemalt (`lib/ui/level_abzeichen.dart`). Unterschieden
  werden sie durch Farbe **und** Nietenzahl, damit sie auch ohne Farbe
  lesbar sind.
- Ohne Gewohnheiten steht unter „Heute“ viel leere Fläche.
- `CharacterStage` heißt jetzt `CharacterFigure` und liegt unter
  `lib/gear/widgets/`; `LevelCard` ist entfallen.
