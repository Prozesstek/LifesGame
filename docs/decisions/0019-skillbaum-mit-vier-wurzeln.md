# ADR-0019: Der Skillbaum bekommt vier Wurzeln, zwei Punkte je Level und Knoten aus einer Seite

**Datum:** 24.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik (Issue [#16](https://github.com/Prozesstek/LifesGame/issues/16))

## Kontext

[ADR-0012](0012-theoriebaum-ueber-punkte.md) vom 18.08. hat den Theoriebaum
entworfen, aber nichts davon wurde gebaut. Der Baum im Spiel ist bis heute die
flache Liste aus [ADR-0007](0007-theorie-als-skillbaum.md): fünf Zweige, die das
Charakterlevel öffnet.

Am 24.08. hat Frederik den Umbau als Issue #16 mit **Abgabedatum 31.08.2026**
angelegt — und darin drei Zahlen anders festgelegt als ADR-0012:

| | ADR-0012 (18.08.) | Issue #16 (24.08.) |
|---|---|---|
| Wurzeln | 2 — Körper, Geist | **4** — Körper, Geist, Wissenschaft, Gesellschaft |
| Theoriepunkte je Level | 1 | **2** |
| Was ein Knoten ist | ein Thema mit mehreren Lektionen | **eine Seite mit 3 MC-Fragen** |
| Fähigkeiten aus dem Baum | 8 | **4** |

Zwei Wahrheiten im Repo sind schlimmer als eine unbequeme. Deshalb dieser ADR.

**Der Auslöser für die Zahlen war Ungeduld mit dem Inhalt, nicht mit dem Code.**
ADR-0012 rechnete mit rund 150 Lektionen für einen vollen Baum. Bei drei
Lektionen je Knoten ist der Baum eine Schreibarbeit von Monaten — und das
Projekt hat 17 Lektionen.

## Entscheidung

**1. Vier Wurzeln statt zwei.** Körper, Geist, Wissenschaft und Gesellschaft.
Die vorhandenen Zweige `koerper`, `geist`, `wissenschaft` und `gesellschaft`
werden zu ihnen; `habits` bleibt daneben das Handbuch ohne Kosten.

**2. Ein Knoten ist eine Seite mit drei MC-Fragen.** Nicht ein Thema mit
Lektionen. Damit ist „Knoten" und „Lektion" dasselbe, und der bestehende
`Lesson`-Typ trägt den Baum weiter.

**3. Zwei Theoriepunkte je Levelaufstieg.** Ein Knoten kostet einen Punkt,
unabhängig von der Tiefe. Das übernimmt ADR-0012 unverändert.

**4. Mindestens fünf Unterknoten je Wurzel.** Ein Knoten erscheint erst im
Baum, wenn sein Inhalt geschrieben ist — die Regel aus ADR-0012 bleibt.

**5. Ein Unterknoten darf zwei Wurzeln verbinden.** Damit ist die Struktur
formal **kein Baum mehr, sondern ein gerichteter Graph**: Ein Knoten kann zwei
Eltern haben. Zum Öffnen genügt **ein** offener Elternknoten, nicht beide.

**6. Vier Fähigkeiten hängen an Knoten.** Alle übrigen Knoten geben XP und
Gold. Icons sitzen auf den Knoten.

**Was aus ADR-0012 gilt weiter:** beliebige Tiefe, Punkte statt Levelsperren,
ein Punkt je Knoten unabhängig von der Tiefe, Handbuch bleibt frei, keine
Klassenwahl.

**Was aus ADR-0012 fällt:** zwei Wurzeln, ein Punkt je Level, Knoten als
Sammlung von Lektionen, acht Fähigkeiten aus dem Baum.

## Begründung

**Vier Wurzeln, weil der Inhalt schon so aussieht.** Wissenschaft und
Gesellschaft sind fertig geschriebene Zweige mit je drei Lektionen. Sie unter
Körper oder Geist zu hängen, wäre eine Umsortierung ohne Gewinn — und ADR-0012
hat ihren Platz nie geklärt.

**Eine Seite je Knoten, weil sonst nichts entsteht.** Der Engpass des Projekts
ist die Schreibarbeit, und das ist gemessen: 17 von rund 150 Lektionen nach
zwei Wochen. Mit einer Seite je Knoten kostet ein voller Startbaum aus 20
Unterknoten **20 Seiten** statt 60. Das ist der Unterschied zwischen „bis zum
31.08." und „irgendwann".

**Ein Elternknoten genügt, weil zwei eine Sackgasse bauen.** Verlangte ein
verbindender Knoten beide Eltern, entstünde eine Reihenfolge quer durch zwei
Wurzeln, die niemand im Baum sieht. Wer von einer Seite kommt, käme nicht
weiter und wüsste nicht, warum.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Bei ADR-0012 bleiben (2 Wurzeln, 1 Punkt, 3 Lektionen je Knoten) | Der volle Baum kostet ~150 Lektionen. Der Termin 31.08. ist damit nicht zu halten, und ein halber Baum ist laut ADR-0012 selbst das schlechteste Ergebnis. |
| Knoten als Lektionssammlung behalten, aber nur eine Lektion einfüllen | Dieselbe Zahl, mehr Code. Ein Knoten mit genau einem Kind ist ein Knoten. |
| Verbindende Knoten weglassen (echter Baum) | Der Reiz von „Ernährung" unter Körper *und* Wissenschaft ist genau die Aussage des Baums: Themen hängen zusammen. Ein reiner Baum kann das nicht ausdrücken. |
| Beide Eltern verlangen | Baut unsichtbare Reihenfolgen quer durch den Baum, siehe Begründung. |

## Konsequenzen

**Der Punktevorrat übersteigt den Baum bei Weitem — und das ist die
unangenehme Folge.** `maxLevel` ist 50, also gibt es über ein Spielerleben
49 Aufstiege:

| | Punkte gesamt | Knoten im Startbaum | Baum komplett offen ab |
|---|---|---|---|
| ADR-0012 (1 Punkt) | 49 | ~45 geplant | Level 46 |
| **ADR-0019 (2 Punkte)** | **98** | **20** | **Level 11** |

**Ab Level 11 ist jeder weitere Theoriepunkt wertlos**, bis der Baum wächst.
Damit ist genau die Knappheit weg, die ADR-0012 herstellen wollte — Punkte
sollten dort eine *Entscheidung* erzwingen, nicht eine Reihenfolge festlegen.

Das wird bewusst in Kauf genommen: Ein Baum, der offensteht, ist besser als
einer, der leer ist. Aber es ist ein Zwischenzustand mit Ablaufdatum.

**Der Auslöser zum Nachjustieren ist benannt:** Sobald der Baum über 40 Knoten
hat, ist zu prüfen, ob 2 Punkte je Level noch richtig sind. Bis dahin steht die
Zahl in `packages/progression` neben der Levelkurve und nirgends sonst.

**Der Graph zwingt zu mehr Sorgfalt als ein Baum.** Zwei Eltern heißt: Kreise
sind möglich, wenn jemand sie einträgt. Ein Test muss den Graphen als
kreisfrei nachweisen — bei einem Baum wäre das unnötig gewesen.

**ADR-0007 ist damit endgültig erledigt.** Levelsperren an Zweigen
verschwinden; sie waren schon durch ADR-0012 abgelöst, aber bis heute die
einzige gebaute Wahrheit.

**Der Handbuch-Zweig bleibt unangetastet**, und damit auch
[ADR-0018](0018-kampf-hinter-dem-handbuch.md): Der Kampf hängt weiter an den
fünf Lektionen von `habits`, die keinen Punkt kosten.
