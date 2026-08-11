# ADR-0001: Flutter + Flame + Drift + Riverpod

**Datum:** 11.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Die App ist zu 80 % ein klassischer Tracker (Listen, Formulare, Fortschrittsanzeigen)
und zu 20 % ein Spiel (rundenbasierter Kampf mit Animationen und Timing-Eingabe).
Diese Mischung passt in keine der üblichen Schubladen: eine reine Game-Engine macht
die Tracker-Screens mühsam, ein reines UI-Framework macht den Kampf mühsam.

Zusätzlich: die App muss offline funktionieren. Habits werden auch ohne Netz abgehakt.

## Entscheidung

Flutter als App-Shell für alle Tracker-Screens, Flame ausschließlich für den
Kampfbildschirm als eingebettetes Widget. Drift (SQLite) für Persistenz, Riverpod
für State Management, Rive für Skill- und Treffer-Animationen.

## Begründung

Flame ist eine Flame-*auf*-Flutter-Engine, kein Konkurrent dazu. `GameWidget` lässt
sich in einen normalen Widget-Baum einsetzen, und Overlays erlauben normales Flutter-UI
über der Spielfläche. Damit bekommt man beide Welten ohne Bruch: Formulare bleiben
Widgets, der Kampf bekommt eine echte Game-Loop.

Drift statt reinem `sqflite`, weil typsichere Queries und Migrationen bei einem
Datenmodell mit Habits, Streaks, Inventar und Charakterfortschritt schnell zum
Unterschied zwischen wartbar und nicht wartbar werden.

Offline-first ist keine Optimierung, sondern Kernanforderung: ein Habit-Tracker, der
ohne Netz nicht abhaken kann, wird nicht benutzt.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Reines Flutter, Kampf mit `CustomPainter` + `AnimationController` | Machbar, aber Game-Loop, Kollisionen und Timing müsste man von Hand bauen. Genau das ist Flames Kernkompetenz. |
| Unity oder Godot für die ganze App | Tracker-UI in einer Game-Engine ist schmerzhaft: kein natives Look-and-Feel, kein einfaches Formular-Handling, deutlich größere Binaries. |
| Cloud-first mit Firebase | Widerspricht offline-first und erzeugt Kosten sowie Datenschutzfragen für ein MVP, dessen Kernfrage rein spielmechanisch ist. |
| `sqflite` roh statt Drift | Handgeschriebenes SQL ohne Typsicherheit; Migrationen werden bei wachsendem Schema zur Fehlerquelle. |

## Konsequenzen

**Leichter:** Ein Sprachraum (Dart) für alles. Tracker-Screens sind gewöhnliche
Flutter-Arbeit. Der Kampf bekommt eine echte Engine, ohne dass das Gesamtprojekt
zur Game-Engine-Anwendung wird.

**Schwerer:** Zwei mentale Modelle im selben Projekt — Widget-Baum und Component-Baum.
Wer nur einen Teil kennt, versteht den anderen nicht sofort. Die Grenze zwischen
beiden muss diszipliniert bleiben, sonst franst sie aus. Diese Disziplin ist der
Gegenstand von [ADR-0002](0002-kampflogik-ohne-flame.md).

**Offen:** Cloud-Sync ist bewusst aus dem MVP heraus. Kommt er später, muss das
Drift-Schema Konfliktauflösung vertragen. Kein Blocker, aber beim Schema-Entwurf
mitdenken.
