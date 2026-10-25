# ADR-0089: Eine neue Gewohnheit, eine Frage nach der anderen

**Datum:** 25.10.2026
**Status:** Aktiv
**Entschieden von:** Prozesstek

## Kontext

Frederik: „Neue Gewohnheiten werden über einen grünen kreisförmigen
[Knopf] mit einem Plus unten rechts hinzugefügt. Das ganze soll mehr
proaktiv abgefragt werden, also 1: Eigene erstellen oder Vorlagen (dort
ist dann ein Dropdown-Menü ausklappbar mit bereits erstellten eigenen
Gewohnheiten oder welche von der App). Danach wird man nach dem Namen
gefragt, dann wird man gefragt, wodrin es einzahlt etc. Damit es nicht
so erschlagend wirkt. Außerdem werden so was wie Wochentage und
Gewohnheitskoppeln schon beim Erstellen abgefragt, aber immer nur eine
Frage auf einmal. Können wir irgendwelche von diesen Fragen noch
wegmachen, weil sie sich doppeln?“

So sah es aus: Auf dem Gewohnheiten-Bildschirm stand unter „Heute“ ein
Knopf mit einer Zahl und darunter zwei Reiter, „Eigene“ und
„Vorerstellte“ (Issue #88). Der Knopf öffnete ein Formular mit sieben
Fragen auf einem Blatt — Name, Wert, Gebiet, Schwierigkeit, Tagesziel,
Priorität, Warum —, und nach dem Anlegen fragte ein Dialog weitere vier:
Auslöser oder Kopplung, Wochentage, Belohnung. Elf Fragen in zwei
Blöcken. Am 24.10. hatten Nutzer die Intuitivität beklagt.

## Entscheidung

Ein **grüner, runder Plus-Knopf** unten rechts ist der einzige Weg zu
einer neuen Gewohnheit. Dahinter fragt ein Blatt **eine Sache nach der
anderen**:

- **Eigene**: Eigene oder Vorlage → Name → Gebiet → Schwierigkeit →
  Tagesziel → Wann (Satz **oder** Kopplung) → Wochentage → Belohnung
- **Vorlage** oder pausierte eigene: Auswahl im Ausklappmenü („Deine“,
  „Von der App“) → Wann → Wochentage → Belohnung
- **Pausierte eigene mit Auslöser**: Auswahl, fertig

Weg sind „Warum?“, „Wie wichtig?“, die Wahl des Werts (ADR-0088) und die
Reiter auf dem Bildschirm.

## Begründung

**Was sich doppelte, fällt weg:**

| Frage | Warum sie weg ist |
|---|---|
| Warum? (freiwillig) | wurde gespeichert, aber nirgends angezeigt |
| Wie wichtig ist es dir? | sortierte nur die Liste — das tun Offenes oben, Stapel (ADR-0065) und „Morgen zuerst“ (ADR-0076); nachträglich ändern ließ sie sich nirgends |
| Worauf zahlt es ein? | das Gebiet bestimmt den Kampfwert (ADR-0088) |
| Kopplung als eigene Frage | dieselbe Frage wie „Wann?“: Satz und Anker ersetzen einander schon im Tracker |
| Reiter „Eigene“ / „Vorerstellte“ | zeigten dasselbe wie die Vorlagen hinter dem Plus-Knopf |
| Bei Vorlagen: Name, Gebiet, Schwierigkeit, Ziel | stehen bei einer Vorlage fest |

**Eine Wahl führt mit einem Tipp weiter**, ein Feld mit „Weiter“. Wo die
Frage freiwillig ist (Wann, Belohnung), steht „Ohne“ daneben. Die
Vorgaben sind so gesetzt, dass jeder Schritt mit einem Tipp erledigt
ist: jeden Tag, mittel, nur abhaken.

**Angelegt wird erst am Ende.** Bis dahin legte das Formular an, und der
Dialog danach konnte man wegklicken. Jetzt hat, wer abbricht, nichts
verändert.

**Die Knöpfe stehen fest, nur die Frage rollt** — beim Rendern
gefunden: Auf „Wann machst du das?“ mit Vorschlägen und vier Kopplungen
rutschte „Weiter“ am Handy unter den Rand.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Schritt 1 und Name zusammen („Was willst du tun?“ mit Vorlagen als Vorschlägen, wie die erste Frage auf der Startseite) | ein Schritt weniger, aber nicht, was Frederik beschrieben hat |
| Kopplung und Satz als zwei Schritte | beantworten dieselbe Frage; Frederik: ein Schritt |
| Die Reiter behalten, zum Stöbern ohne Anlegen | Vorlagen an zwei Orten; Frederik: weg |
| Priorität behalten | Frederik: weg |
| Die erste Frage auf der Startseite durch den Ablauf ersetzen | dort zählt das erste Häkchen, nicht das Formular (ADR-0068): ein Tipp legt an |

## Konsequenzen

- **Neu**: `GewohnheitAnlegen` (das Blatt, kennt keine Provider),
  `anlegen_ergebnis.dart` (`EigeneAngelegt`, `VorlageGestartet`,
  `Einrichtung`), `anlegen_teile.dart` (Kopf, Wahl, Feld, Vorschläge).
  Angelegt, gestartet und eingerichtet wird in
  `HabitsScreen._neueGewohnheit`.
- **Gelöscht**: `CustomHabitSheet`, `HabitTemplateTile` und auf dem
  Bildschirm die Reiter, die ruhende Kachel und der Knopf mit der Zahl.
- **Der Dialog „Wann machst du das?“ bleibt** für das Ändern einer
  laufenden Gewohnheit (Zeile auf der Kachel, Kachel „nicht heute“).
- **Priorität und Warum bleiben im Spielstand** und in
  `HabitsController.addCustom`. Was alte Gewohnheiten dort haben, wirkt
  weiter; neue bekommen „normal“ und nichts.
- **Pausierte eigene stehen nur noch im Ausklappmenü** unter „Deine“.
  Auf dem Bildschirm sieht man sie nicht mehr.
- **Bei voller Liste** (fünf laufen) endet eine eigene nach dem
  Tagesziel und wartet unter „Deine“; Vorlagen stehen matt da und sagen
  beim Antippen, warum.
