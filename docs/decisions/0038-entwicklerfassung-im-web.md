# ADR-0038: Eine Entwicklerfassung im Web

**Datum:** 21.09.2026
**Status:** Aktiv — ergänzt ADR-0021
**Entschieden von:** Frederik

## Kontext

Der Entwicklermodus existiert nur im Debug-Build (ADR-0021). Die
Web-Fassung auf GitHub Pages ist ein Release-Build — dort gibt es ihn
nicht. Damit ist alles, was nur über den Entwicklermodus erreichbar ist,
am Handy unerreichbar: vor allem die Grube, der Echtzeit-Prototyp.
Android lässt sich auf dem Entwicklungsrechner noch nicht bauen.

Frederik: „Ich will gerne mobil ausprobieren können."

## Entscheidung

Pages liefert **zwei Fassungen** aus:

| Adresse | Was | Entwicklermodus |
|---|---|---|
| `/LifesGame/` | die normale Fassung, für den 30-Tage-Lauf | **nein** |
| `/LifesGame/dev/` | die Entwicklerfassung | **ja**, mit „DEV"-Band oben rechts |

Die Entwicklerfassung ist ein Release-Build mit
`--dart-define=ENTWICKLERFASSUNG=true`. Sie hat einen **eigenen Speicher**
(`SharedPreferences.setPrefix`).

## Begründung

**Warum ein eigener Speicher.** Beide Fassungen liegen auf derselben
Adresse und damit im selben `localStorage`. Der Entwicklermodus merkt sich
dort, welcher Spielstand aktiv ist (ADR-0021). Ohne eigenen Präfix könnte
eine Umschaltung in der Entwicklerfassung die normale Fassung beim
nächsten Start auf den Dev-Stand umstellen — ausgerechnet der Fall, den
ADR-0021 ausschließen wollte. Mit eigenem Präfix sehen die beiden
Fassungen einander nicht.

**Warum das Band.** Am Handy sehen beide Fassungen gleich aus. Wer im
falschen Fenster ist, hält seinen Fortschritt für verloren.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Entwicklermodus in der normalen Fassung | widerspricht ADR-0021 und Ziel 7 — dort soll es kein Werkzeug geben, das Erfahrung und Gold verschenkt |
| Nur die Grube in der normalen Fassung | das wäre eine Richtungsentscheidung über den Kampf, die noch nicht gefallen ist |
| Android-APK mit Debug-Build | auf dem Rechner fehlen `cmdline-tools` und Lizenzen; der Weg über Pages geht heute |

## Konsequenzen

- **Ziel 7 bleibt unberührt.** Die normale Fassung ändert sich nicht, und
  die Entwicklerfassung kann ihren Stand nicht lesen und nicht schreiben.
- **Wer die Entwicklerfassung zum Home-Bildschirm hinzufügt**, bekommt ein
  zweites Symbol mit demselben Namen. Das Band unterscheidet sie erst
  nach dem Öffnen.
- **Der Pages-Lauf baut zweimal** und dauert entsprechend länger.
- `devModeAvailable` ist jetzt `kDebugMode || isDevBuild`. Wer eine Stelle
  hinter den Entwicklermodus legt, prüft weiter nur diesen einen Wert.
