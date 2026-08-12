# Fallstricke

> Dinge, die überraschend waren oder Zeit gekostet haben. Ein Eintrag hier spart
> dem anderen im Team denselben Abend. Neueste oben.

## Lokale `DateTime`-Arithmetik verschluckt bei Zeitumstellung einen Tag

Ein Tracker rechnet ständig mit Tagen: „war gestern abgehakt?", „wie lang ist
die Kette?". Naheliegend wäre `DateTime.now().subtract(Duration(days: 1))`.
Das ist falsch. In lokaler Zeit hat der Tag der Zeitumstellung 23 oder 25
Stunden — `Duration(days: 1)` sind aber immer exakt 24. Am Umstellungstag
landet man dadurch auf demselben oder auf dem übernächsten Tag, und eine
Streak reißt ohne Grund.

Zweites Problem derselben Wurzel: Zwei Häkchen am selben Tag zu
unterschiedlichen Uhrzeiten sind als `DateTime` nicht gleich. Als Schlüssel
in einer Map taugt `DateTime` deshalb nicht.

Lösung in `packages/habits/lib/src/day.dart`: ein eigener `Day`-Typ ohne
Uhrzeit, der intern in **UTC** rechnet (dort hat jeder Tag 24 Stunden) und
nur zur Anzeige lokal bleibt. `day_test.dart` prüft das ausdrücklich am
25.10.2026.

## Riverpod 3 exportiert `Override` nicht

`overrides: <Override>[...]` in einem `ProviderContainer` sieht richtig aus
und schlägt mit „'Override' isn't a type" fehl. Der Typ existiert in
`package:riverpod`, wird aber von `flutter_riverpod` nicht re-exportiert.

Einfach die Typangabe weglassen — `overrides: [foo.overrideWithValue(x)]`
wird korrekt inferiert. Nebenwirkung: Der Fehler bricht den Compiler für den
**ganzen** Testlauf ab, nicht nur für die eine Datei. Wer plötzlich
unerklärliche „The Dart compiler exited unexpectedly" in fremden Testdateien
sieht, sucht den echten Fehler weiter oben in der Ausgabe.

## `pumpAndSettle` läuft im Kampfbildschirm in den Timeout

Der Test „Kampf führt zum Kampfbildschirm" hing 10 Sekunden und schlug dann mit
`pumpAndSettle timed out` fehl. Der Grund ist kein Bug: `GameWidget` von Flame
rendert dauerhaft weiter, es gibt also nie einen Frame, nach dem nichts mehr
ansteht. `pumpAndSettle` wartet aber genau darauf.

**Regel:** Überall dort, wo ein Flame-Widget im Baum sein kann, mit `pump()`
arbeiten — einmal für den Start der Navigation, einmal mit einer Dauer für das
Ende der Übergangsanimation:

```dart
await tester.pump();
await tester.pump(const Duration(seconds: 1));
```

`pumpAndSettle` bleibt für alles andere richtig.

## Widget-Tests laufen in einem 800x600-Fenster

Lektionstexte und lange Antwortmöglichkeiten sind höher als das Standardfenster
im Test. Was in einer `ListView` außerhalb des Sichtbereichs liegt, wird gar
nicht gebaut — `find.text(...)` findet dann nichts, und der Test schlägt fehl,
obwohl die App in Ordnung ist.

Lösung steht in `test/test_view.dart` (`useTallView`): Fenstergröße hochsetzen
und per `addTearDown` zurücksetzen. Alternative wäre `scrollUntilVisible`, das
macht die Tests aber deutlich unleserlicher.

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
