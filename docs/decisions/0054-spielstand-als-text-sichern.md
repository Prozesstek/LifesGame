# ADR-0054: Den Spielstand als Text sichern

**Datum:** 27.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Eine kritische Durchsicht der App hat das Risiko mit dem größten Schaden
gefunden: **Der Spielstand liegt nur im Speicher des Browsers**
(`shared_preferences`, ADR-0010), und es gibt keine Sicherung. Wer die
Browserdaten löscht, verliert jede Streak und jedes Häkchen. Manche
Browser räumen Website-Daten sogar von selbst, wenn eine Seite eine
Weile nicht geöffnet wurde — das trifft genau den Spieler, der nach
einer Pause zurückkommt.

Für ein Spiel, dessen ganzer Wert die angesammelte Historie ist
(ADR-0008), ist das der teuerste mögliche Fehler, und er kündigt sich
nicht an.

## Entscheidung

**Der Stand lässt sich als Text kopieren und wieder einfügen**, unten
auf dem Charakter-Bildschirm. Einfügen fragt nach, zeigt beide Stände in
einer Zeile, legt den alten in die Zwischenablage und **startet die App
von innen neu** mit dem eingefügten Stand.

## Begründung

**Text statt Datei oder Server.** Eine Notiz auf dem Handy ist die
einfachste Ablage, die jeder schon hat. Ein Server widerspräche dem
Grundsatz, dass die App mit niemandem redet (ADR-0010); ein
Datei-Download ist im Browser am Handy umständlich.

**Einlesen ist streng, anders als beim Start** (`SaveData.tryImport`).
Beim Start ist Nachsicht richtig: Ein halb lesbarer Stand ist besser als
keiner. Beim Einfügen wäre sie gefährlich: Ein falsch kopierter Text
würde zu einem leeren Stand und ersetzte den echten. Verlangt wird ein
JSON-Objekt mit Versionsnummer, und keine aus einer neueren App.

**Ein Neustart von innen statt „bitte neu laden“.** Der Dev-Modus
schreibt beim Umschalten nur den Speicher und bittet um ein Neuladen.
Für einen Import reicht das nicht: Tippt jemand vorher noch ein Häkchen,
schreibt die laufende App ihren alten Stand über den eingefügten.
`SpielstandHost` in `main.dart` baut deshalb den `ProviderScope` mit
neuem Schlüssel neu; kein alter Controller überlebt.

**Der alte Stand wandert in die Zwischenablage.** Ein Irrtum ist so ein
Einfügen entfernt, nicht verloren.

**Export und Speichern lesen dieselbe Stelle** (`currentSave` in
`save_watcher.dart`). Ein zwischengeschalteter Provider lieferte beim
Speichern noch den alten Stand und ist deshalb eine einfache Funktion.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Sicherung auf einem Server | Die App hat keinen und soll keinen brauchen |
| Datei herunterladen | Am Handy im Browser umständlich, und wohin sie fällt, weiß danach niemand |
| Automatische Sicherung | Wohin, ohne Server? Die Zwischenablage ohne Zutun zu überschreiben wäre übergriffig |
| Nachsichtiges Einlesen wie beim Start | Ein Tippfehler löschte den Fortschritt |

## Konsequenzen

- Sichern ist Handarbeit. Wer es nie tut, ist so ungeschützt wie vorher.
  Eine Erinnerung daran gibt es nicht.
- Ein kopierter Stand ist lesbarer Text mit allem, was jemand getan hat.
  Wer ihn weitergibt, gibt seine Historie weiter.
- Auch der Dev-Stand lässt sich so kopieren; eingefügt wird immer in den
  Stand, der gerade läuft.
