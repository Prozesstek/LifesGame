# Fallstricke

> Dinge, die überraschend waren oder Zeit gekostet haben. Ein Eintrag hier spart
> dem anderen im Team denselben Abend. Neueste oben.

## GridView mit childAspectRatio kann Widgets unsichtbar machen

Die vier Move-Buttons lagen zuerst in einem `GridView.count` mit
`childAspectRatio: 4.2`. Das koppelt die **Zellenhöhe an die Fensterbreite**: Auf
einem breiten Fenster werden die Zellen so hoch, dass die zweite Reihe aus dem
Sichtbereich rutscht. Weil GridView faul baut, existierten „Giftklinge" und
„Sammeln" dann gar nicht im Widget-Baum — nicht nur unsichtbar, sondern nicht
gebaut.

Auf dem Handy wäre es vermutlich nie aufgefallen. Gefunden hat es der Widget-Test,
der einfach prüft, ob alle vier Move-Namen da sind.

**Regel:** Bei fester Höhe keine `childAspectRatio`-Grids. Zeilen mit `Expanded`
sind bei jeder Breite verlässlich.

## Windows-Desktop-Builds brauchen Visual Studio

`flutter devices` listet „Windows (desktop)" auch dann, wenn der Build gar nicht
funktioniert. Dafür braucht es Visual Studio mit dem Workload „Desktop development
with C++" (mehrere GB). Ist hier nicht installiert.

Entwickelt wird deshalb gegen **Chrome** (`flutter run -d chrome`). Für Android
fehlen noch die `cmdline-tools` und die akzeptierten Lizenzen
(`flutter doctor --android-licenses`).

## PowerShell 5.1 verschluckt sich an `2>&1` bei Flutter

`flutter --version 2>&1` wirft einen `NativeCommandError` und Exit-Code 255,
obwohl der Befehl erfolgreich war. Grund: PowerShell 5.1 verpackt jede
stderr-Zeile eines nativen Programms in einen ErrorRecord — und Flutter schreibt
Fortschrittsmeldungen („Building flutter tool...") auf stderr.

Einfach **nicht umleiten**, dann läuft alles normal.

## Kurze Kämpfe verstärken jeden Multiplikator

Die Timed-Hit-Grenze von +50 % klang im Konzept nach einem Randbonus. In der
Simulation entscheidet sie den Kampf komplett (55 % Siegquote ohne Timing gegen
100 % mit perfektem Timing, bei gleichen Stats).

Der Grund ist nicht der Bonus selbst, sondern die Kampflänge: Bei ~7 Treffern pro
Kampf spart ein 1,5-Multiplikator zwei ganze Runden. Faustregel für alles Weitere:
**Je kürzer der Kampf, desto brutaler wirkt jeder Prozentsatz.** Wer Balance
anfassen will, sollte zuerst über die Kampflänge nachdenken, nicht über den
Multiplikator.

Details und Zahlen in `docs/context/state.md`.

## Die VS-Code-Erweiterungen sind nicht das SDK

`dart-code.dart-code` und `dart-code.flutter` im VS-Code-Marktplatz zu installieren
fühlt sich an, als hätte man Dart und Flutter installiert. Hat man nicht — das sind
nur Editor-Werkzeuge (Syntax, Debugger, Autovervollständigung). Auf der Platte lag
danach weder `dart.exe` noch `flutter.bat`.

Prüfen statt annehmen:

```powershell
dart --version
flutter --version
```

Dart-SDK nachinstallieren: `winget install --id Google.DartSDK --exact`
Flutter gibt es nicht über winget — manueller Download von
<https://docs.flutter.dev/get-started/install/windows>.

## Nach einer SDK-Installation braucht es eine neue Shell

winget schreibt den PATH, aber bereits laufende Terminals (und laufende
Claude-Code-Sitzungen) haben den alten PATH im Speicher. `dart` wird dort weiterhin
nicht gefunden, obwohl es installiert ist. Neues Terminal öffnen — oder das Binary
direkt über seinen vollen Pfad aufrufen.

## Formatter und Lint können sich widersprechen

`dart format` bricht lange Aufrufe so um, dass die Lint-Regel
`require_trailing_commas` anschließend meckert. `dart format` erneut laufen zu
lassen behebt es **nicht** — es ist ein stabiler Zustand, den beide Werkzeuge
unterschiedlich bewerten.

Lösung: den Ausdruck kürzer machen (Zwischenvariable), statt gegen den Formatter
zu kämpfen.
