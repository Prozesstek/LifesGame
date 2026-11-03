# Zufriedenheit: sehen, was man geschafft hat

> **Vorlage, noch nicht gebaut.** Konzeptrunde vom 03.11.2026 mit
> Frederik. Gebaut wird danach, Block für Block, jeder mit ADR.
> AktivesBrett hat sie noch nicht gesehen.

## Der Anlass

Frederik: „Zufriedenheit fehlt: Statistiken überarbeiten,
Wochenrückblick am Montag wird einem angezeigt und man sieht wieviel
Minuten/Stunden man was gemacht hat: Vergleich mit sinnlosen
Tätigkeiten, Prozent ggüber anderen Spielern. Kampf gegen sich selbst
von vor 7 Tagen?, Vergleich mit anderen (dauert aber noch)“

Gelesen als: Das Spiel zahlt jedes Häkchen in Erfahrung, Gold und
Funken aus. Was fehlt, ist der Blick zurück, **was die Häkchen im Leben
bedeuten**: „Ich habe diese Woche drei Stunden gelesen.“ Das ist die
Zufriedenheit, die bleibt, wenn die Münzen gelandet sind.

## Was heute im Weg steht

| Lücke | Wo |
|---|---|
| **Fast keine Gewohnheit kennt ihre Dauer.** Nur Zeitziele haben Minuten, und auch dort steht auf einem erledigten Tag das Ziel, nicht die echte Zeit. | `HabitGoal`, `state.md` 23.10. |
| **Der Wochenrückblick öffnet sich nicht von selbst**, er liegt als Karte im Charakter und sonntags am Lagerfeuer. | `WeekCard`, `WeekReviewScreen` |
| **Ohne Server gibt es keine anderen Spieler**, also keine echte Prozentzahl. | ADR-0010 |
| **Das Level von vor 7 Tagen ist nicht rechenbar**: Seiten und erste Siege tragen kein Datum. | `das-naechste-level.md`, Schatten |

## Die Entscheidungen

### 1. Jede Gewohnheit bekommt eine Dauer (geschätzt)

- **Vorlagen bringen sie mit** (Zwei Minuten lesen: 2, Spazieren gehen:
  etwa 20 …, eine Tabelle im Katalog).
- **Eine eigene fragt beim Anlegen**: 5, 15, 30, 60 Minuten — eine
  Frage mehr im Blatt aus ADR-0089, mit Vorgabe, ein Tipp.
- **Alte Gewohnheiten werden einmal gefragt**, wie beim Gebiet
  (`GebietFrageKarte`).
- **Ein Zeitziel zählt seine echte Zeit**, sobald sie gespeichert wird
  (heute nur das Ziel — Lücke aus `state.md` 23.10. schließen).
- **Die Dauer erzeugt keine Zahl im Spiel.** Keine Erfahrung, kein Gold,
  kein Kampfwert — sonst lohnt es sich, „60 Minuten“ zu wählen. Sie ist
  nur Anzeige, und darf sich deshalb jederzeit ändern
  (`CustomHabit.editable`). Eine geänderte Dauer gilt rückwirkend; ob
  sie wie der Wochenplan eine Historie braucht, ist offen.

### 2. Der Vergleich in Einheiten, nicht in Statistik

„3 Std. 20 gelesen — so lang wie 4 Folgen einer Serie.“ Eine feste
Tabelle von Einheiten, gewählt nach Größe der Zeit:

| ab | Einheit |
|---|---|
| wenige Minuten | 30-Sekunden-Videos |
| ~45 Min. | Folgen einer Serie |
| ~2 Std. | Spielfilme |
| viele Stunden | Staffeln, ganze Tage |

**Keine Behauptung über andere Leute**, nichts, was eine Quelle braucht.
Ton: stolz, nicht belehrend — die Einheit zeigt, wie viel Zeit es war,
nicht, dass Serien schlecht sind.

### 3. Statt Prozent gegen andere: Aussagen aus Studien

Bis es einen Server gibt, **keine Prozentzahl gegen andere Spieler** —
sie wäre ausgedacht. Stattdessen belegte Einordnungen an der passenden
Stelle, zum Beispiel:

| Wann | Aussage | Quelle (gegenlesen!) |
|---|---|---|
| Kette um Tag 66 | Im Schnitt wird eine Gewohnheit nach etwa 66 Tagen automatisch, je nach Mensch zwischen 18 und 254. | Lally u. a. 2010, *European Journal of Social Psychology* |
| nach einem verpassten Tag | Ein verpasster Tag hat dort den Weg zur Gewohnheit kaum gebremst. | dieselbe Studie |
| Tag 7 / 30 | Von Neujahrsvorsätzen halten nach einer Woche etwa drei Viertel, nach einem Monat gut die Hälfte. | Norcross u. a. 2002, *Journal of Clinical Psychology* |
| Gewohnheit mit Auslöser | Wer vorher festlegt, wann und wo, setzt einen Vorsatz deutlich öfter um. | Gollwitzer & Sheeran 2006, Metaanalyse |

**Jede Aussage wird vor dem Einbau an der Quelle geprüft**, wie die
Gesundheitsaussagen im Baum (`state.md`, „Gegenlesen“). Die Zahlen oben
sind aus dem Gedächtnis und noch nicht nachgeschlagen. Eine Aussage über
*andere* Menschen wird nie zu „du bist besser als X %“ — die Studie
misst andere Leute unter anderen Bedingungen.

### 4. Der Wochenrückblick öffnet sich montags von selbst

- **Montags beim ersten Öffnen**, einmal je Woche, über der Startseite,
  für die Woche davor.
- Wer ihn schließt, findet ihn weiter im Charakter und am Lagerfeuer.
- **Gespeichert wird nur, welche Woche schon gezeigt wurde** — die
  einzige neue Zahl im Spielstand; alles andere ist abgeleitet.
- Nicht in der ersten Woche (es gibt keine Woche davor), nicht vor dem
  Ende des Mentors.
- Inhalt neu: **die Zeit je Gebiet und Gewohnheit** samt Einheit (1, 2),
  die Woche gegen die Woche davor, eine Aussage aus 3, wenn sie passt.

### 5. Die Statistik: weniger, aber klarer

- **Oben drei große Zahlen**, der Rest auf Tipp oder weiter unten.
  Welche drei, ist offen (Vorschlag: Quote, Kette, Zeit).
- **Belege aus Studien** an der passenden Stelle (3).
- Was heute an Graphen da ist (ADR-0087), bleibt erreichbar, wird aber
  nicht mehr alles auf einmal gezeigt.

### Später

- **Der Kampf gegen sich selbst** (Schatten, 7 oder 30 Tage) bekommt eine
  eigene Runde. Vorbereiten lässt er sich schon: **das Level jeden Tag
  mitschreiben**, dann ist „du vor 7 Tagen“ ab dann genau rechenbar.
  Ob das jetzt schon passiert, ist offen.
- **Vergleich mit anderen und Prozent** erst mit einem Server.

## Reihenfolge, wenn gebaut wird

1. **Dauer je Gewohnheit** — alles andere hängt daran.
2. **Wochenrückblick montags** mit Zeit und Einheiten.
3. **Statistik aufräumen**, drei Zahlen oben.
4. **Aussagen aus Studien**, nach dem Gegenlesen.

Der Store-Termin (Ziel 9, 20.11.) geht vor: Jeder Block ist klein genug,
um ihn danach oder dazwischen zu bauen.

## Offene Fragen

- Welche drei Zahlen stehen oben in der Statistik?
- Braucht die Dauer eine Historie, oder gilt eine Änderung rückwirkend?
- Soll die Statistik die Zeit auch zeigen, oder nur der Rückblick?
  (In der Runde nicht gewählt.)
- Das Level ab jetzt täglich mitschreiben, damit der Schatten später
  „vor 7 Tagen“ kann?
