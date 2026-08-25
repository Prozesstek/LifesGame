# ADR-0021: Der Entwicklermodus schenkt Zuschläge und arbeitet auf einem eigenen Spielstand

**Datum:** 25.08.2026
**Status:** Aktiv
**Entschieden von:** AktivesBrett

## Kontext

Testen dauert. Um zu sehen, wie der Charakterbildschirm auf Level 20
aussieht oder ob der Bergwächter mit voller Ausrüstung schlagbar ist,
müsste man dreißig Tage abhaken. Gebraucht wird ein Werkzeug, das
Erfahrung, Gold, Punkte, Fähigkeiten und Ausrüstung per Knopfdruck vergibt.

**Dabei stehen zwei bestehende Entscheidungen im Weg — beide zu Recht.**

**1. Es gibt keinen Ort, an den ein „+500 XP" schreiben könnte.** Erfahrung,
Level, Gold, Charakterwerte und Theoriepunkte sind alle *abgeleitet*
(ADR-0008, ADR-0011):

```dart
totalXp   = theory.totalXp + habits.totalXp
level     = LevelCurve.levelFor(totalXp)
gold      = (theory.totalGold + habits.totalGold) - loadout.spentGold
```

Der Grund dafür steht in ADR-0008: „Zwei Wahrheiten über denselben
Goldstand wären eine Fehlerquelle, die sich nie ganz schließen lässt."

**2. `ziele.md`, Ziel 7 verbietet genau dieses Werkzeug** für den
30-Tage-Nachweis: „Kein Sonderrecht, keine Testdaten, keine Abkürzung über
den Debugger." Ein Dev-Modus, der den echten Stand anfassen kann, macht den
Nachweis wertlos — und man merkt es womöglich erst hinterher.

## Entscheidung

**1. Zuschläge statt gefälschter Eingangsgrößen.** `DebugGrants` ist ein
eigenes Feld im Spielstand mit Bonus-XP, Bonus-Gold, Bonus-Punkten und
freigeschalteten Fähigkeiten. Die abgeleiteten Werte addieren es als
**benannten Summanden** dazu.

**2. Ein eigener Spielstand.** Der Modus schaltet auf den Schlüssel
`lifes_game.save.dev.v1` um. Solange er aktiv ist, liest und schreibt die
App den echten Stand **nicht**. Der Wechsel braucht einen Neustart.

**3. Nur im Debug-Build.** `devModeAvailable = kDebugMode`. Im Release ist
weder die Kachel noch der Bildschirm im Bündel.

**4. Die Herkunft bleibt sichtbar.** Der Charakterbildschirm zeigt eine
eigene Karte „Aus dem Entwicklermodus", sobald etwas geschenkt wurde.

**5. Kein Knopf setzt ein Level direkt.** „+1 Level" schenkt genau so viel
Erfahrung, wie bis zur nächsten Stufe fehlt.

**6. Charakterwerte werden nicht geschenkt.** Sie hängen an Häkchen je Stat;
sie zu schenken hieße, Häkchen und damit Streaks zu erfinden.

## Begründung

**Warum Zuschläge und nicht gefälschte Eingangsgrößen.** Die Alternative
wäre, so viele Lektionen als bestanden zu markieren, bis die Erfahrung
stimmt. Der Spielstand bliebe formal „eine Wahrheit" — aber er würde lügen:
Man sähe Lektionen als gelesen, die man nie gelesen hat. Ein benannter
Zuschlag ist ehrlicher als eine erfundene Vergangenheit.

**Warum das trotzdem eine Ausnahme von ADR-0008 ist, und warum sie tragbar
ist.** Es *gibt* jetzt einen zweiten Summanden. Drei Dinge halten ihn im
Zaum: Er ist im Release nicht vorhanden, er lebt nur im Dev-Stand, und er
ist einzeln sichtbar und mit einem Knopf auf 0 zu setzen. Die Fehlerquelle
aus ADR-0008 war ein *gespeicherter Kontostand, der von den Buchungen
abweicht* — hier weicht nichts ab, hier steht ein zusätzlicher Posten offen
daneben.

**Warum ein zweiter Spielstand und nicht nur eine Markierung.** Eine
Markierung („dieser Stand wurde verändert") wäre bequemer und würde die
Verfälschung nachweisbar machen. Sie verhindert sie aber nicht. Bei einem
Ziel, das ausdrücklich „keine Testdaten" verlangt, ist die technische
Trennung das Richtige: Der echte Stand liegt hinter einem Schlüssel, den die
App währenddessen gar nicht anfasst.

**Warum der Wechsel einen Neustart braucht.** Der Stand wird einmal vor
`runApp` gelesen (ADR-0010), und jeder Controller baut seinen
Anfangszustand daraus. Einen davon im Betrieb auszutauschen hieße, alle
gleichzeitig zurückzusetzen — mit dem Risiko, dass einer es nicht mitbekommt
und Daten des einen Standes in den anderen schreibt.

**Warum `DevActions` neben `DevController` steht.** Ein Notifier, der einen
abgeleiteten Wert liest, in den sein eigener Zustand eingeht, erzeugt einen
`CircularDependencyError` — der Fall aus `gotchas.md`, der bei
`goldProvider` schon einmal zugeschlagen hat. Alles, was mehrere Bereiche
zugleich anfasst oder eine abgeleitete Zahl braucht, steht deshalb in einer
Klasse über `ref` statt als Methode am Notifier.

**Warum kein achtes Package.** Die Schichtregel verlangt Spielzahlen in den
Packages. Ein Zuschlag ist aber keine Spielregel, sondern eine Eingabe — wie
der Name (ADR-0013). Die Regeln, die er benutzt (Levelkurve, Preise,
Fähigkeitsbedingungen), stehen unverändert in ihren Packages.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Eingangsgrößen fälschen (Lektionen, Häkchen) | Der Spielstand lügt über die Vergangenheit; erfundene Streaks verfälschen Titel und Multiplikatoren |
| Nur zur Laufzeit, nicht gespeichert | Nach jedem Neustart weg — für längere Abläufe unbrauchbar |
| Echter Stand mit Kennzeichen | Verhindert die Verfälschung nicht, macht sie nur nachweisbar; Ziel 7 verlangt mehr |
| Echter Stand ohne Kennzeichen | Am Ende der 30 Tage nicht mehr feststellbar, ob nachgeholfen wurde |
| Versteckte Geste statt Debug-Build | Der Modus wäre auch im Release vorhanden, nur schwerer zu finden |
| Level direkt setzen | Es gibt kein gespeichertes Level; ein gesetztes wäre die zweite Wahrheit, die ADR-0008 ausschließt |
| Charakterwerte schenken | Hieße Häkchen erfinden und damit Streaks erfinden |

## Konsequenzen

**Leichter:** Späte Zustände sind in Sekunden erreichbar. „Alles
freischalten" öffnet jeden Knoten, besteht jede Seite, schenkt jedes Stück
und jede Fähigkeit — der Endgame-Zustand zum Ansehen.

**Schwerer, und das ist der ernste Teil:** Jede abgeleitete Zahl hat jetzt
einen zweiten Summanden. `dev_mode_test.dart` hält deshalb die wichtigste
Zusage fest: **Ohne Zuschläge ist jede Formel identisch mit der vorherigen.**
Wer eine dieser Stellen anfasst, lässt den Test laufen.

**Der Importkreis war ein echter Fallstrick.** `level_provider` rechnet die
Zuschläge ein, `gear_controller` braucht das verfügbare Gold — beide über
`lib/dev/` zu verbinden ließ die Typinferenz auf `num` zurückfallen. Gelöst
über `spendableIncomeProvider` in `level_provider`, sodass
`gear_controller` nichts aus `lib/dev/` importiert.

**Offen:** Fähigkeitspunkte werden gespeichert und angezeigt, wirken aber
nicht — das Feature aus ADR-0013 ist nicht gebaut. Der Knopf ist da, damit
er beim Nachziehen nicht nachträglich in den Spielstand eingreifen muss.
