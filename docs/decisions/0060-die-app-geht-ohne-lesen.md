# ADR-0060: Die App geht ohne Lesen

**Datum:** 29.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Frederik: „Ich würde gerne so viel Schrift wie möglich entfernen, eine
App muss ohne Lesen funktionieren (natürlich Theorie etc bleibt drin).“

Über die Bildschirme verteilt standen Überschriften („Deine sechs
Plätze“, „Werte im Kampf“), erklärende Sätze („Sechs Stücke, jeden Tag
neu gewürfelt …“, „Halte unten ein Stück gedrückt …“), Beschriftungen
(„Tage am Stück“, „nichts gekauft“, „ab Level 6“) und Knöpfe mit Wörtern
(„Kaufen“, „Öffnen“, „Hinab“). Jede Zeile war mit einem guten Grund
dazugekommen; zusammen machten sie aus einem Spiel ein Formular.

## Entscheidung

Vier Regeln, in einer Fragerunde entschieden:

| Frage | Antwort |
|---|---|
| Was bleibt stehen? | **Namen und Zahlen.** Namen von Dingen (Gewohnheit, Stück, Fähigkeit, Knoten, Titel) und Zahlen mit ihrem Zeichen. Sätze, Überschriften und Beschriftungen gehen oder werden Zeichen |
| Wohin kommt die Erklärung? | **Beim Antippen.** Blätter und Dialoge, die man selbst öffnet, dürfen erklären; wo es kein Blatt gibt, sagt ein Tooltip auf Tipp den Satz |
| Wie lernt man „halten und ziehen“? | **Leuchten.** Ein leerer Platz, auf den etwas passt, leuchtet dreimal auf (`PlatzLaedtEin`) |
| Wie wird gebaut? | **Ein PR** über alle Bildschirme |

Die Theorie — Lektionen, Fragen, Handbuch — ist ausgenommen, ebenso die
Titel der Bildschirme und die Namen der Bereiche auf der Startseite.

## Begründung

Ein Satz auf dem Bildschirm wird einmal gelesen und danach übersehen,
steht aber jeden Tag da. Ein Zeichen wird nach dem ersten Mal
wiedererkannt. Wer mehr wissen will, tippt — und hat damit gesagt, dass
er jetzt lesen will.

**Der Satz verschwindet nicht, er wandert.** Was gesehen wird, ist ein
Zeichen; was der Vorleser sagt, steht weiter ganz da (`Semantics`,
`semanticLabel`, `semanticsLabel`). Dadurch finden die Tests die Stellen
weiter über ihren Satz, und die App bleibt mit Vorleser bedienbar.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Radikal: auch Bildschirmtitel und die Namen unter den Kreisen weg | Namen sind keine Erklärung, sie sind das Ding. Ein Kreis ohne Namen muss man einmal antippen, um zu wissen, wohin er führt — das ist Lesen mit mehr Schritten |
| Nur die Fließtext-Sätze weg | Ließe „Tage am Stück“, „nichts gekauft“, „ab Level 6“ stehen, also genau das, was man täglich sieht |
| Ein ?-Knopf je Bildschirm | Sammelt die Erklärung weit weg von dem, was sie erklärt |
| Eine animierte Hand, die das Ziehen vormacht | Braucht einen gespeicherten Zustand „schon gesehen“; das Leuchten sagt dasselbe ohne |
| Nirgends mehr erklären, auch nicht in Blättern | Die Werte einer Fähigkeit oder eines Stücks sind ohne Satz nicht zu verstehen, und wer das Blatt öffnet, will sie wissen |

## Konsequenzen

- **Eine Tabelle für die Zeichen der Werte**: Hantel für Stärke und
  Angriff, Herz für Ausdauer und Leben, Schild für Disziplin und Abwehr,
  Tropfen für Klarheit und Mana (`lib/habits/stat_icon.dart`). Wer ein
  neues Zeichen für einen Wert braucht, nimmt es dort.
- **Ruhm** steht überall als dasselbe Zeichen (`lib/ui/ruhm_zahl.dart`).
- **Tests suchen seltener nach Text.** Knöpfe ohne Wort tragen einen
  `Key` (`DailyQuestsCard.abholenKey`, `DailyChestCard.oeffnenKey`,
  `ShopItemTile.kaufenKey`, `LadderScreen.hinabKey`,
  `LadderScreen.etageKey`), der Rest wird über `bySemanticsLabel`,
  `byIcon` oder `byTooltip` gefunden.
- **Das Leuchten läuft dreimal, nicht endlos**, sonst hinge
  `pumpAndSettle` in jedem Test mit einem freien Platz. Ein Hinweis, der
  nach dem Tippen als SnackBar kommt, ist nach drei Sekunden weg — ein
  Test, der danach sucht, darf nicht bis zur Ruhe pumpen.
- **Zeichen müssen gelernt werden.** Ob Uhr-mit-Pfeil für „nächste Stufe
  der Kette“ oder der Kompass für „neue Stufe“ ohne Erklärung verstanden
  werden, zeigt erst das Spielen.
- **Nicht angefasst** in diesem Schritt: die Feiern (Aufstieg,
  Errungenschaft, Fähigkeit), die Beute des Wächters, der Wochenrückblick,
  die Formulare (eigene Gewohnheit, Auslöser), die Seltenheits-Marken
  („Gewöhnlich“, „Selten“) und die Rückmeldungen als SnackBar.
