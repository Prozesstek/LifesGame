# Fallstricke

> Dinge, die überraschend waren oder Zeit gekostet haben. Ein Eintrag hier spart
> dem anderen im Team denselben Abend. Neueste oben.

## Im Widget-Test ist jede Glyphe quadratisch — Texte sind dort breiter

`phone_layout_test.dart` meldete 218 Pixel Überlauf in einer Zeile aus zwei
kurzen Texten mit `Spacer` dazwischen. Nachgerechnet passten die Sätze
bequem: rund 280 Pixel bei 358 verfügbaren.

Der Grund ist die Testschrift. Flutter rendert in Widget-Tests mit einer
Ersatzschrift, in der **jedes Zeichen so breit ist wie hoch**. Bei
`fontSize: 12` heißt das 12 Pixel je Buchstabe — „Aufstieg gibt 2 Punkte"
wird 264 statt 130 Pixel breit. Zwei solche Texte sprengen jede Zeile.

**Das ist kein falscher Alarm.** Dieselbe Zeile bricht auf einem echten
Gerät, sobald jemand die Schrift vergrößert — der Test nimmt das nur
vorweg. Die Lehre ist deshalb nicht „Test ignorieren", sondern:

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Flexible(child: Text(links, overflow: TextOverflow.ellipsis)),
    const SizedBox(width: 8),
    Flexible(child: Text(rechts, overflow: TextOverflow.ellipsis)),
  ],
)
```

**Regel:** Zwei Texte nebeneinander in einer `Row` brauchen beide
`Flexible` und `overflow`. `Spacer` hilft dabei nicht — er verteilt nur,
was übrig ist, und schrumpft nichts.

Nebenbei: Die Fehlermeldung nennt den Überlauf, aber nicht das Widget. Der
`debugCreator` steht im `informationCollector` der `FlutterErrorDetails` —
mit `FlutterError.onError` einsammeln, dann steht die ganze Kette da
(`Row ← Column ← Padding ← _Header ← …`). Ohne das sucht man im falschen
Bildschirmteil.

## Ein Widget, das sich über `kIsWeb` abschaltet, ist im Test unsichtbar

`PhoneFrame` zeigt die App im Browser in Handygröße und gab dafür bei
`!kIsWeb` einfach sein Kind zurück. In Widget-Tests ist `kIsWeb` **immer
falsch** — das Widget hat sich dort also selbst wegoptimiert. Ergebnis: Es
war vollständig ungetestet, obwohl es in einer Testdatei vorkam.

Aufgefallen ist es erst auf einem Screenshot: ein Überlauf von 5990 Pixeln
quer über den Bildschirm. Ursache war ein `Text` **oberhalb** von
`MaterialApp`, wo es weder `Directionality` noch einen Standard-Textstil
gibt. Alle 103 Tests waren dabei grün.

**Regel:** Plattformabfragen wie `kIsWeb` gehören in einen **Parameter mit
Standardwert**, nicht in eine feste Abfrage:

```dart
const PhoneFrame({required this.child, this.enabled = kIsWeb});
```

Dann prüft der Test `enabled: true`, und die App verhält sich unverändert.
Dieselbe Überlegung gilt für `Platform.isAndroid` und Freunde.

**Zweite Regel aus demselben Fall:** Was oberhalb von `MaterialApp` sitzt,
hat keine der Selbstverständlichkeiten darunter. `Text`, `Icon` und alles mit
Textrichtung brauchen dort ein eigenes `Directionality`.

## Netstat spricht Deutsch, `findstr "LISTENING"` nicht

`start-app.bat` sucht einen freien Port, um nicht auf einem belegten
abzustürzen. Die erste Fassung filterte die `netstat`-Ausgabe nach
`LISTENING`. Auf einem deutschen Windows steht dort **`ABHÖREN`**.

Der Filter fand deshalb nie etwas, hielt jeden Port für frei und wäre
zielsicher wieder auf dem belegten gelandet — mit demselben Absturz, den er
verhindern sollte.

**Regel:** In Skripten nicht auf übersetzte Ausgaben filtern. Die Adresse
steht in jeder Sprache gleich da:

```bat
netstat -ano | findstr ":%%P " >nul 2>nul
```

Gilt genauso für `tasklist`, `sc query` und `systeminfo`. Wo es geht,
lieber PowerShell mit Objekten (`Get-NetTCPConnection`) statt Text.

## Grüne Tests sagen nichts darüber, ob die App überhaupt startet

Alle 103 Tests waren grün, während die App im Browser eine schwarze Seite
zeigte. Kein Widerspruch, sondern eine Lücke: **Kein Test ruft `main()` auf.**
Die Widget-Tests pumpen `LifesGameApp` direkt, `main.dart` bleibt außen vor.

Alles, was vor `runApp` steht — Speicher öffnen, Orientierung festlegen,
irgendeine Initialisierung — ist damit ungeprüft. Genau dort hing die App:
`await SystemChrome.setPreferredOrientations(...)` kehrte im Desktop-Browser
nie zurück, weil es dort keine Bildschirmorientierung zu sperren gibt.
`runApp` wurde nie erreicht.

**Das Tückische war die Stille.** Kein Absturz, keine Ausnahme, nichts in der
Konsole — nur die Ladeskripte. Verraten hat es erst ein Blick ins DOM:

```js
document.querySelector('flutter-view, flt-glass-pane')  // null
document.querySelectorAll('canvas').length              // 0
```

Ist beides leer, obwohl die Seite fertig geladen ist, dann läuft nicht die
App falsch — dann läuft sie gar nicht.

**Zwei Regeln daraus:**

1. Vor `runApp` gehört nur, was nicht scheitern kann. Alles andere braucht
   `try`/`catch` oder gehört dahinter. `_openStore()` macht es richtig vor
   (ADR-0010), `_lockPortrait()` musste nachziehen.
2. Plattformaufrufe (`SystemChrome`, `path_provider`, Kanäle jeder Art) mit
   `kIsWeb` abschirmen, wenn sie im Browser sinnlos sind. „Wirkungslos" und
   „blockiert" sind im Web nicht dasselbe.

## Der Web-Server antwortet, lange bevor die App fertig gebaut ist

`flutter run -d web-server` liefert sofort eine Seite aus — HTTP 200, Titel
korrekt, alles sieht fertig aus. Die Dart-Kompilierung läuft zu dem Zeitpunkt
aber noch. Wer auf „antwortet der Server?" wartet, wartet auf das falsche
Signal und schaut dann auf eine leere Seite.

Sichtbar wird es nur in der Browser-Konsole:

```
Refused to execute script from 'http://localhost:8080/main.dart.js'
because its MIME type ('text/html') is not executable
```

Der Server schickt für `main.dart.js` die `index.html` zurück, weil das Bundle
noch nicht existiert. Kein Fehler, nur ein Zwischenzustand.

**Regel:** Auf das Bundle prüfen, nicht auf die Wurzel — und dabei **kein
`curl -I`** benutzen.

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/main.dart.js
```

Kommt `200`, ist der Build durch; vorher `404` oder die `index.html`.

Der Zusatz mit `-I` ist wichtig und hat beim zweiten Mal wieder Zeit gekostet:
Der Entwicklungsserver ist ein `package:shelf` und beantwortet **HEAD-Anfragen
falsch**. `curl -I` auf die Wurzel liefert 404, obwohl `curl` mit GET dieselbe
Adresse mit 200 und der richtigen `index.html` beantwortet — und für
`main.dart.js` meldet HEAD `text/plain`, GET dagegen `application/javascript`.
Wer den Content-Type über HEAD prüft, hält einen fertigen Build für kaputt.

Im Terminal ist das verlässlichste Signal ohnehin die Zeile
`is being served at`. Solange dort `Waiting for connection from debug service`
steht, läuft der Build noch. Der erste braucht ein bis zwei Minuten, jeder
weitere ist deutlich schneller.

## Heilung als Anteil der maximalen HP macht Kämpfe unendlich

„Sammeln" heilte 25 % der maximalen HP. Schaden dagegen ist ein Vielfaches des
**Angriffswerts**. Solange beide Größen zufällig zusammenpassten, fiel nichts
auf. Als der HP-Pool angehoben wurde (100–140 → 160–224), heilte sich jede
Seite schneller, als die andere zuschlagen konnte.

Sichtbar wurde das nicht als Absturz und nicht als Endlosschleife, sondern als
**Unsinn in den Zahlen**: Die Siegquote *sank*, wenn der Spieler stärker wurde.
Bei Tag 7 standen 80 % ohne Timing gegen 31 % mit gemischtem Timing. Mehr
Schaden trieb den Gegner nur früher unter die Heilschwelle, wo er dann festsaß.

**Zwei Ursachen, beide nötig:**

1. Die *Höhe* — behoben, indem Heilung und Schild am Angriffswert hängen
   (`healFactorOfAttack`, `shieldFactorOfAttack`). Damit sind Heilen und
   Schlagen dieselbe Einheit, und das Verhältnis überlebt jede Poolgröße.
   Gift war schon immer so gebaut.
2. Die *Häufigkeit* — die Policy heilte jede zweite Runde. Behoben durch eine
   einzige Bedingung: heilen nur, wenn kein Schild mehr steht. Da „Sammeln"
   immer auch einen Schild setzt und der zwei Runden hält, begrenzt das die
   Heilrate auf etwa jede dritte Runde — **zustandslos**, die Policy muss sich
   nichts merken.

**Regel:** Wenn eine Zahl als Anteil einer anderen definiert ist, prüfen, ob
beide dieselbe Einheit haben. `packages/combat/test/termination_test.dart`
prüft das jetzt dauerhaft — und zwar skalenfrei: Die **Summe** beider HP-Balken
muss sinken. Eine Rundenzahl taugt dafür nicht, weil ein Kampf bei großen Pools
zu Recht lange dauert.

## Ein Zufallsgenerator für Seeds und Eingaben macht Spalten unvergleichbar

Die Balance-Simulation zog Kampf-Seeds und Timing-Würfe aus **einem** `Random`.
Weil längere Kämpfe mehr Würfe verbrauchen, verschob die Timing-Spalte alle
folgenden Seeds — jede Spalte simulierte am Ende andere Kämpfe.

Gemerkt hat man es an einem unmöglichen Ergebnis (31 % Siegquote mit Timing
gegen 80 % ohne). Das war hier ein Glücksfall, weil der Widerspruch grob war.
Bei kleineren Verschiebungen sieht so ein Fehler wie ein Balance-Befund aus.

**Regel:** Ein Generator je Rolle. In `tool/balance_sim.dart` heißen sie
`seeds` und `timing`. Dann bekommt jede Spalte dieselben Kämpfe, und der
Unterschied zwischen ihnen ist tatsächlich der Unterschied, den man messen
wollte.

Zweite Lehre aus demselben Lauf: Die alte Simulation variierte **einen** Wert
und hielt die übrigen fest. Das Spiel bewegt nie einen Wert allein. Der
ursprüngliche Befund „das umkämpfte Band ist zwei Angriffspunkte breit" kam aus
genau dieser Verwechslung.

## Ein Provider, der sich über eine Ecke selbst liest

`goldProvider` rechnet Zufluss minus Besitz und liest dafür `loadoutProvider`.
Der `GearController` wollte beim Kauf wissen, wie viel Gold da ist — und las
`goldProvider`. Riverpod bricht das mit `CircularDependencyError` ab, und die
Fehlermeldung nennt nur `Provider<int>#d5f5b`, nicht die Kette.

Der Kreis ist echt und kein Riverpod-Detail: Der Controller fragt nach einer
Zahl, in die sein eigener Zustand eingeht.

**Lösung:** die Zahl *vor* dem eigenen Beitrag lesen und ihn selbst abziehen —
`goldEarnedProvider` minus `state.spentGold`. Dasselbe Ergebnis, kein Kreis.

**Regel:** Wenn ein abgeleiteter Wert den eigenen Zustand enthält, darf ein
Notifier ihn nicht lesen. Er braucht die Quelle davor.

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

## Ein Multiplikator wirkt über jede Kampflänge gleich — anders als hier stand

> **Dieser Eintrag stand ursprünglich mit der umgekehrten Aussage hier.** Er
> bleibt stehen, weil der Denkfehler naheliegend ist und jemand sonst denselben
> Weg noch einmal geht.

Die Timed-Hit-Grenze von +50 % klang im Konzept nach einem Randbonus. In der
Simulation entschied sie den Kampf komplett: 55 % Siegquote ohne Timing gegen
100 % mit perfektem Timing, bei gleichen Werten.

**Die alte Erklärung lautete:** Bei ~7 Treffern pro Kampf spart ein
1,5-Multiplikator zwei ganze Runden — je kürzer der Kampf, desto brutaler wirke
jeder Prozentsatz. Daraus folgte der Vorschlag, die HP zu erhöhen.

**Das stimmt nicht.** Ein Kampf mit festen Werten ist ein Rennen. Ein
pauschaler Schadensmultiplikator verkürzt die eigene Zeit um denselben Anteil,
egal ob das Rennen fünf oder fünfzig Runden dauert. Was sich mit der Länge
ändert, ist der **Zufall**: Über mehr Runden mittelt sich die Streuung aus, der
Ausgang wird berechenbarer — das umkämpfte Band wird also *schmaler*, nicht
breiter. Längere Kämpfe hätten das Problem verstärkt.

**Was tatsächlich hilft:** mehrere Gegner statt eines. Dann ist zu jedem
Zeitpunkt einer knapp, und Timing entscheidet genau dort — was die gewünschte
Aussage ergibt: Gewohnheiten entscheiden, *ob* ein Kampf knapp wird, Timing
entscheidet den knappen Kampf. Begründung und Zahlen in
[ADR-0009](../decisions/0009-kampfbalance-ueber-gegnerreihe.md).

**Regel, die bleibt:** Eine Simulation, die einen Wert bewegt und die anderen
festhält, beantwortet nicht die Frage, die das Spiel stellt.

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
