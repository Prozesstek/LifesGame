# ADR-0003: Kampflogik als eigenes Dart-Package statt als Ordner

**Datum:** 11.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

[ADR-0002](0002-kampflogik-ohne-flame.md) verlangt, dass die Kampflogik keine
Flame-Imports enthaelt. Als reine Vereinbarung ist das eine Disziplinregel, und
Disziplinregeln halten genau so lange, bis jemand unter Zeitdruck "nur schnell"
etwas importiert. Der ADR benennt diese Versuchung sogar selbst.

## Entscheidung

Die Kampflogik liegt in `packages/combat/` als eigenstaendiges Dart-Package mit
eigener `pubspec.yaml`, deren `dependencies`-Block **leer** ist. Die App wird das
Package spaeter per Pfad einbinden.

## Begründung

Damit ist ADR-0002 keine Vereinbarung mehr, sondern eine Eigenschaft des
Build-Systems: Ein `import 'package:flame/...'` in `packages/combat/` schlaegt
fehl, weil die Abhaengigkeit schlicht nicht existiert. Der Analyzer meldet es
sofort, nicht erst im Review.

Zweiter Vorteil: `dart test` laeuft ohne Flutter-Toolchain. Die 23 Tests dieses
Packages brauchen kein SDK ausser Dart selbst — das hat sich beim Aufsetzen
direkt ausgezahlt, als noch kein Flutter installiert war.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Ordner `lib/domain/combat/` in der App | Nichts haelt einen Flame-Import auf. Die Regel bliebe reine Selbstdisziplin. |
| Lint-Regel gegen verbotene Imports | Funktioniert, ist aber Zusatzkonfiguration, die jemand abschalten kann. Eine fehlende Dependency kann man nicht abschalten. |
| Eigenes Git-Repo fuer die Logik | Trennung ja, aber Versionierung und Pfade fuer ein Zweierteam unnoetig kompliziert. |

## Konsequenzen

**Leichter:** Die Architekturgrenze ist maschinell gesichert. Balance-Tests laufen
in Millisekunden. Wer an der Logik arbeitet, braucht kein Flutter.

**Schwerer:** Ein zweites `pubspec.yaml` will gepflegt werden, und die App muss
das Package per `path:` einbinden. Wer eine geteilte Hilfsfunktion zwischen App
und Logik will, muss sich entscheiden, wo sie hingehoert — was in der Sache gut
ist, sich im Moment aber wie Reibung anfuehlt.
