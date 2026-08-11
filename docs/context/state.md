# Projektstand

> Diese Datei ist die Antwort auf „Wo stehen wir gerade?".
> Am Ende jeder Arbeitssitzung aktualisieren. Alte Einträge unter „Verlauf"
> zusammenfassen, nicht löschen.

**Zuletzt aktualisiert:** 11.08.2026 · Frederik

---

## Phase

**Konzept abgeschlossen, Implementierung noch nicht begonnen.**
Es existiert kein Dart-Code. Das Repo enthält bisher Konzept, Entscheidungen
und die geteilte Claude-Code-Konfiguration.

## Fertig

- Produktkonzept steht in Grundzügen (`konzept.md`, vier Fragerunden)
- Tech-Stack entschieden ([ADR-0001](../decisions/0001-tech-stack.md))
- Architekturregel Kampflogik/Flame entschieden ([ADR-0002](../decisions/0002-kampflogik-ohne-flame.md))
- Repo aufgesetzt: Gedächtnis-Struktur, geteilte Claude-Werkzeuge, `.gitignore`

## In Arbeit

Nichts. Nächste Sitzung startet bei „Als Nächstes".

## Als Nächstes

Reihenfolge ist eine Empfehlung, kein Gesetz:

1. **Flutter-SDK installieren** (beide Rechner) und `flutter create` im Repo ausführen.
   Blockiert alles Weitere. Auf Frederiks Rechner ist `flutter` aktuell nicht im PATH.
2. **Offene Konzeptpunkte 1–3 klären** (Streak-Deckel, Gold-Abflüsse, Niederlagen-Regel).
   Das sind Balance-Entscheidungen, die die Datenmodelle beeinflussen — besser vor
   dem Schema entscheiden. Siehe `konzept.md` Abschnitt 6.
3. **Datenmodell + Drift-Schema** für Habits, Streaks, Charakter, Inventar.
4. **Kampflogik als reines Dart** inkl. Tests — vor jeder Flame-Zeile.
5. **Flame-Kampfbildschirm** als Widget, konsumiert die Events aus 4.

## Aufgabenteilung

Noch nicht festgelegt. Vorschlag: einer nimmt Habit-/Tracker-Seite (Drift, Riverpod,
Screens), der andere die Kampfseite (reine Logik, dann Flame). Berührungspunkt ist
allein das Event-Interface aus ADR-0002 — das früh gemeinsam festlegen.

## Verlauf

- **11.08.2026** — Konzept in vier Fragerunden erarbeitet und in `konzept.md`
  zusammengefasst. Repo `Prozesstek/LifesGame` angelegt, Gedächtnis-Struktur
  aufgesetzt, ECC-Werkzeuge fürs Team eingecheckt.
