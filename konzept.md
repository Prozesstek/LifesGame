# Habit-RPG — Konzeptstand

Stand: 31.08.2026 · aus vier Fragerunden am 11.08., seither fortgeschrieben

> **Was in diesem Dokument steht, ist entweder gebaut oder ausdrücklich als
> ungebaut gekennzeichnet.** Beim Abgleich am 31.08. standen hier mehrere
> Sätze, die einmal richtig waren und es nicht mehr sind — ein Baum mit zwei
> Wurzeln, Drift als Persistenz, Gegner als „offen". Wo eine Absicht etwas
> erklärt, bleibt sie als Zitat stehen; wo sie überholt ist, steht daneben,
> was gilt.

---

## 1. Kernidee

Ein Habit-Tracker, dessen Fortschritt sich in einem rundenbasierten RPG
auszahlt. Was der Nutzer im echten Leben tut, bestimmt, wie stark sein
Charakter ist. Theorie-Inhalte zur Selbstverbesserung sind fest in den
Fortschritt eingebaut, nicht danebengestellt.

**Fortschrittsquellen:** Habits und Theorie. Kämpfe zahlen **nicht** ein.

> **Ursprünglich geplant waren 50 % Habits · 30 % Theorie · 20 % Kämpfe**,
> mit der Empfehlung daneben: Kämpfe sollten kein Level geben, sondern Gold
> und Items — sonst kann man den Habit-Teil umgehen, indem man grindet.
> Habits und Theorie = Einnahme, Kämpfe = Ausgabe.

Die erste Hälfte der Empfehlung ist umgesetzt und steht als Kommentar über
`totalXpProvider` (`lib/progression/level_provider.dart`): Erfahrung und Gold
kommen ausschließlich aus Theorie und Gewohnheiten.

**Die zweite Hälfte ist nie gebaut worden.** Ein gewonnener Kampf gibt heute
weder Gold noch einen Gegenstand — er gibt gar nichts. Damit ist der Kampf
weder Einnahme noch Ausgabe, sondern folgenlos, und die Prozentzahlen oben
beschreiben keine gebaute Aufteilung. **Was ein Sieg einbringen soll, ist
offen** (§6, Punkt 12) — und es ist die Frage, an der hängt, ob jemand
freiwillig kämpft.

---

## 2. Kern-Loop

**Was heute läuft:**

```
  Theoriepunkt ──► Knoten öffnen ──► Seite lesen, drei Fragen
                                          │
                 ┌────────────────────────┼────────────────────┐
                 ▼                        ▼                    ▼
          Habit-Vorlage             XP + Gold              Fähigkeit
                 │                        │                    │
                 ▼                        ▼                    │
          täglich abhaken ──► Charakterwerte + XP + Gold        │
                                          │                    │
                                          ▼                    ▼
                                  Ausrüstung kaufen ──► vier Move-Slots
                                          │                    │
                                     Waffe gibt Slot 1 ────────►│
                                                               ▼
                                                             Kampf
```

**Der Weg über die Fähigkeit ist seit
[ADR-0020](docs/decisions/0020-kampf-haengt-am-moveset.md) Teil des Loops,
nicht Beiwerk:** Der Kampf öffnet sich erst, wenn das Handbuch durch ist
**und** mindestens zwei Moves im Set liegen. Mit einem Move ist der erste
Gegner nicht knapp, sondern unschlagbar — gemessen, nicht geschätzt.

**Der Kreis schließt sich noch nicht.** Geplant war er über
`Dungeon ──► Drops ──► Ausrüstung`; beides existiert nicht (§3.4, §4). Heute
endet der Loop beim Einzelkampf und läuft nur über Habits und Theorie zurück.

Tägliche Sitzung: 1–2 Minuten Abhaken, optional 3–5 Minuten Theorie,
optional ein Kampf. Die 8–12 Minuten beziehen sich auf den Dungeon und
gelten deshalb noch nicht.

---

## 3. Systeme

### 3.1 Charakter

Der Charakterbildschirm ist die **Kommandozentrale**
([ADR-0013](docs/decisions/0013-charakter-als-kommandozentrale.md)). Die
Trennung zum Startbildschirm ist inhaltlich: Start zeigt **was ich tue**,
Charakter zeigt **wer ich bin**.

- Name und verdienter Titel, Level, Gold, offene Punkte
- 4 Charakterwerte, jeweils mit Herkunft (Alltag / Ausrüstung)
- **4 Fähigkeitsslots** — drei frei wählbar, einer von der getragenen Waffe
  bestimmt; offen ab Level 3 / 6 / 10
- 6 Ausrüstungs-Slots (Waffe, Rüstung, Helm, Schuhe, Ring, Talisman)
- Wege zu Errungenschaften, Streaks, Freunden und in den Laden

> **Es gibt keine Klassenwahl, und es wird nie eine geben.**
> Jeder formt seinen Charakter durch seinen persönlichen Stil. Eine Klasse,
> die man in der ersten Minute in einem Menü anklickt, gibt die Antwort,
> bevor die App ihre Frage stellen konnte. Wo eine Klasse sichtbar werden
> soll, wird sie aus dem tatsächlichen Verhalten **abgeleitet**.

**Fähigkeiten:** 20 Stück, davon **fünfzehn wählbar**
([ADR-0022](docs/decisions/0022-faehigkeiten-set-aus-der-vorlage.md)). Sie
kommen aus dem Theoriebaum (einen Knoten **abschließen**, nicht öffnen), aus
Streak-Marken und aus Waffen; später zusätzlich aus Errungenschaften. Einmal
verdient heißt behalten — auch wenn die Streak reißt (siehe 3.7).

| Quelle | Stück | Bedingung |
|---|---|---|
| Theorieknoten | 11 | Seite **bestanden**, nicht nur bezahlt |
| Streak-Marken | 4 | 7 / 14 / 30 / 60 Tage |
| Waffen | 5 geplant, **1 gebaut** | folgt aus der Ausrüstung, nicht gewählt (3.5) |

Jede Fähigkeit trägt eine von fünf **Seltenheitsstufen** — gewöhnlich,
ungewöhnlich, selten, episch, legendär. *Sternenfall* ist die einzige
legendäre und kommt ausschließlich über sechzig Tage Kette. Was die frühen
von den späten trennt, ist die Energie, und die kommt aus Klarheit, also aus
Häkchen.

> **Nicht gebaut: Fähigkeitspunkte.** Geplant war, dass sie auf jedem dritten
> Levelaufstieg kommen und gegen Gold umverteilbar sind. `packages/progression`
> kennt aber nur `TheoryPoints` und `AbilitySlots` — eine Verdienstregel gibt
> es nirgends, und der einzige Ort im Code, der Fähigkeitspunkte kennt, ist
> `lib/dev/debug_grants.dart`. Sie werden gespeichert und angezeigt und wirken
> nicht. Offen (§6, Punkt 13): bauen oder streichen.

**Identität:** Name und Titel jetzt, Aussehen später. Der Titel ist der
kürzeste Weg zwischen dem, was jemand tut, und dem, was sein Charakter ist.

**Levelkurve:** linear steigend — Stufe 2 kostet 100 Erfahrung, jede
weitere 25 mehr als die vorige. Bewusst nicht exponentiell: Fortschritt
kommt aus echten Gewohnheiten und lässt sich nicht grinden, deshalb dürfen
späte Stufen nicht unerreichbar werden
([ADR-0006](docs/decisions/0006-levelkurve-als-eigenes-package.md)).
Jeder Aufstieg gibt **zwei** Theoriepunkte
([ADR-0019](docs/decisions/0019-skillbaum-mit-vier-wurzeln.md); ADR-0012
hatte einen vorgesehen). Der Fähigkeitspunkt auf jedem dritten Aufstieg ist
geplant und nicht gebaut — siehe den Kasten oben.

**Empfehlung:** Ausrüstung sollte Ressourcen beeinflussen, nicht nur
Zahlen erhöhen. Ein Ring, der Energie schneller füllt, erzeugt eine
Entscheidung. „+3 Angriff" nicht.

> Zweimal übernommen: Energie sitzt auf Ring und Talisman (3.5), und die
> **Waffe bestimmt den vierten Fähigkeitsslot**. Damit ist eine Waffe kein
> Zahlenaufschlag mehr, sondern ein Spielstil — und es lohnt sich, mehrere
> zu besitzen und zu wechseln.

### 3.2 Kampfsystem
Rundenbasiert, **vier Move-Slots**, keine Typen-Effektivität. Timed Hits als
Skill-Element: Tap im richtigen Moment → Schadensbonus.

**Vier Slots heißt nicht mehr vier Moves.** Was hineinkommt, wird gewählt:
fünfzehn Fähigkeiten plus die Waffenfähigkeit auf Slot 1. Jede bringt eigene
Energiekosten, ein eigenes Zeitfenster (`TimingSpec`) und eine eigene
Perfect-Wirkung mit.

**Der Timed-Hit-Deckel von +20 % gilt weiter — aber nicht für alles.**

| | Perfect-Bonus |
|---|---|
| Basisangriff, Waffenmoves | **+20 %**, der gemessene Deckel aus `balance.dart` |
| Fähigkeiten | eigener `perfectFactor` je Fähigkeit, oft eine andere Wirkung statt mehr Schaden |

> Ursprünglich waren pauschal +50 % vorgesehen. Die Simulation zeigte, dass
> das den Kampf allein entscheidet — bei gleichen Werten 56 % Siegquote ohne
> Timing gegen 100 % mit perfektem. Gesenkt mit
> [ADR-0009](docs/decisions/0009-kampfbalance-ueber-gegnerreihe.md).

Der eigene Faktor je Fähigkeit widerspricht dem nicht: ADR-0009 maß einen
*pauschalen* Faktor auf jeden Treffer. Eine Fähigkeit kostet Energie und
hängt an einem engen Fenster — der Zug, den man jede Runde drückt, bleibt bei
+20 %, und ein Test hält das fest
([ADR-0022](docs/decisions/0022-faehigkeiten-set-aus-der-vorlage.md)).

**Vier Umgebungen** liegen im Kampf und wirken auf beide Seiten: Eisfeld,
Sandsturm, Giftboden, Lavafeld. Sie halten eine begrenzte Zahl Runden,
verändern Schaden und Zeitfenster — und perfekt gelegt halten sie eine Runde
länger.

**Der Gegner spielt nach denselben Regeln wie der Spieler**
([ADR-0023](docs/decisions/0023-der-gegner-spielt-nach-denselben-regeln.md)):
Er tippt auf der Leiste, kann perfekt treffen, und greift mit einer Quote je
Gegner zu Schutz oder Umgebung. Das ist keine Kosmetik — vorher waren drei
Fähigkeiten gegen ihn wirkungslos, weil sie an seinem Zeitfenster angreifen.

**Gegner sind eine Reihe, kein einzelner.** Drei Stufen, jede an einem
anderen Punkt des Gewohnheits-Pfads knapp. Der Grund ist grundsätzlich: Ein
Kampf mit beidseitig festen Werten ist ein Rennen und kippt scharf von
„unmöglich" auf „geschenkt". Ein breites Band spannender Kämpfe lässt sich
deshalb nicht in einen Gegner einstellen — es entsteht nur aus mehreren.

Die ursprünglich vorgeschlagenen Move-Archetypen beschreiben heute nicht mehr
die Struktur des Kampfes, sondern das **Standard-Loadout** — die Rollen, die
ein Set abdecken sollte, damit ein Kampf funktioniert:

| Rolle | Energie |
|-------|---------|
| Basisangriff | erzeugt |
| Starker Angriff | verbraucht viel |
| Debuff (Gift, Verteidigung senken) | mittel |
| Utility (Heilung, Schild) | mittel |

Die Zuordnung Rolle → Slot ist entfallen: Der Spieler legt die drei freien
Plätze frei zusammen, Slot 1 bestimmt die Waffe.

### 3.3 Theorie / Skilltree
Text plus Multiple-Choice-Fragen, verknüpft mit Habit-Vorlagen. Bestehensgrenze
60 %, XP und Gold nur einmal je Seite.

**Das Handbuch steht außerhalb des Graphen** und hat als Einziges eine
verbindliche Reihenfolge: Lektion n+1 öffnet sich mit bestandener Lektion n.
Es kostet keinen Punkt — es ist die Anleitung, nicht der Baum.

**Der Baum hat vier Wurzeln**
([ADR-0019](docs/decisions/0019-skillbaum-mit-vier-wurzeln.md);
[ADR-0012](docs/decisions/0012-theoriebaum-ueber-punkte.md) hatte zwei
vorgesehen und ist dadurch **teilweise abgelöst**). Knoten öffnen sich über
**Theoriepunkte** — ein
Punkt, ein Knoten, unabhängig von der Tiefe. Die Wurzeln und das Handbuch
kosten nichts:

```
Gewohnheiten  (frei — das Handbuch der App, außerhalb des Graphen)

Körper            Geist               Wissenschaft       Gesellschaft
├── Schlaf        ├── Aufmerksamkeit  ├── Quelle         ├── Umfeld
├── Bewegung      ├── Gedanken        ├── Ursache        ├── Zugehörigkeit
├── Ernährung     ├── Unbehagen       ├── Selbsttest     ├── Grenzen
├── Erholung      ├── Motivation      ├── Stichprobe     ├── Vergleich *
└── Stress *      └── Wiederholung    └── Studien lesen  └── Um Hilfe bitten

* hängt an zwei Wurzeln: Stress an Körper und Geist,
  Vergleich an Gesellschaft und Geist
```

**Ein Knoten ist eine Seite mit drei Fragen**, kein Thema mit Lektionen
(ADR-0019 — das ist die Änderung, die den Umbau überhaupt in eine Woche
passen ließ). **Es ist ein Graph, kein Baum:** Zwei Knoten hängen an zwei
Wurzeln, und **ein** offener Elternknoten genügt zum Öffnen.

Der Baum ist heute genau **eine Ebene tief** — alle zwanzig Unterknoten
hängen direkt an einer Wurzel. Beliebige Tiefe bleibt vorgesehen und ist
nicht benutzt.

Ein Knoten erscheint erst, wenn sein Inhalt geschrieben ist. **Ein halber
Knoten ist schlimmer als keiner** — für ihn wurde ein Punkt bezahlt.

> **Ursprünglich galt:** Ein Knoten verdient seinen Platz nur, wenn er drei
> Lektionen trägt, mindestens eine täglich abhakbare Gewohnheit hervorbringt
> und auf einen der vier Charakterwerte einzahlt.

Die erste Bedingung ist mit ADR-0019 entfallen. Was ein Knoten heute erfüllen
muss, prüft `graph_content_test.dart` über den ganzen Graphen: eindeutige
Ids, genau drei Fragen, gültiger `correctIndex`, keine doppelten Antworten —
und für die Struktur: keine Eltern-Id ins Leere, kreisfrei, jede Wurzel mit
mindestens fünf Kindern.

**Die zweite Bedingung ist als Anspruch geblieben, aber nicht als Test.**
Elf der neunundzwanzig Seiten schalten eine Habit-Vorlage frei. Ein Thema
ohne tägliche Handlung ist weiterhin ein Essay, kein Knoten — nur hält das
heute niemand außer der Sorgfalt beim Schreiben fest.

**Was ein Levelaufstieg gibt:**

| Aufstieg | gibt | gebaut |
|---|---|---|
| jeder | **2 Theoriepunkte** | ja |
| jeder dritte | 1 Fähigkeitspunkt | **nein** (3.1) |
| Level 3 / 6 / 10 | Fähigkeitsslot 2 / 3 / 4 | ja |

> **Das größte Projektrisiko hat sich verändert, nicht erledigt.**
>
> **Es war die Schreibmenge.** Der Baum aus ADR-0012 hatte rund 45 Knoten,
> also etwa 150 Lektionen — bei damals 17. Das ist vom Tisch: Seit ein Knoten
> **eine Seite** ist, kostete der Startbaum acht neue Seiten statt hundert.
> Heute stehen **24 Knoten und 29 Seiten**, der Startbaum ist vollständig.
>
> **Jetzt ist es die Knappheit.** Zwei Punkte je Aufstieg ergeben über
> `maxLevel` 50 insgesamt **98 Theoriepunkte** — für zwanzig
> kostenpflichtige Knoten. Der Baum steht damit **ab Level 11 komplett
> offen**, und jeder weitere Punkt ist wertlos. Die Entscheidung, die
> ADR-0012 wollte, gibt es nicht mehr.
>
> ADR-0019 nimmt das bewusst in Kauf — ein Baum, der offensteht, ist besser
> als einer, der leer ist — und merkt die Nachjustierung **ab 40 Knoten**
> vor. Bis dahin bleibt es ein bekannter, angenommener Mangel.

### 3.4 Dungeon
4 Gegner + 1 Boss, etwa 8–12 Minuten.

- **HP heilt nicht zwischen den Kämpfen** → Zermürbung erzeugt echte
  Entscheidungen (Trank jetzt oder für den Boss aufsparen?)
- Niederlage: Dungeon von vorn
- Zugang kostet Gold

> **Konflikt:** Niederlage + verfallener Eintritt bestraft doppelt, und
> man kann sich nicht hochgrinden, weil Stärke aus echten Habits kommt.
> Ohne ein Wiederbelebungs-Item wird das zur Abwärtsspirale.

**Nichts davon ist gebaut** — der Dungeon ist das letzte offene Stück des
MVP-Schnitts (Ziel 6 in [`docs/context/ziele.md`](docs/context/ziele.md),
Termin 20.09.2026). Der Konflikt oben ist bis heute unentschieden, und
`ziele.md` macht die Auflage ausdrücklich: **Der ADR zur Niederlagen-Regel
steht, bevor gebaut wird.**

### 3.5 Shop
Ausrüstung über sechs Plätze, in zwei Stufen. Gebaut, siehe
[ADR-0011](docs/decisions/0011-ausruestung-als-eigenes-package.md).

**Gold wird abgeleitet, nicht gezählt:** Zufluss aus Theorie und
Gewohnheiten minus Preis des Besitzes. Deshalb gibt es keinen Verkauf — er
bräuchte eine Verkaufshistorie und damit eine zweite Wahrheit.

Die Empfehlung, Ausrüstung solle Ressourcen beeinflussen statt nur Zahlen
(Abschnitt 3.1), ist übernommen: Energie sitzt auf Ring und Talisman, und
der Ring ist auf beiden Stufen das teuerste Stück.

**Die Waffe bestimmt heute nichts.** Sie soll den vierten Fähigkeitsslot
festlegen und damit einen Spielstil (3.1) — im Laden liegen aber zwei
Klingen, und **beide geben denselben Move** (`sword_strike` in
`packages/abilities/lib/src/ability_catalog.dart`). Damit ist der Waffenslot
Dekoration. Ziel 3 (Termin 06.09.) macht daraus fünf Waffen mit fünf eigenen
Fähigkeiten zum **ähnlichen Preis** — Alternativen, keine Leiter. Das nimmt
eine Regel aus ADR-0011 zurück („teurer muss auch besser sein") und braucht
deshalb einen eigenen ADR.

**Noch offen:** Tränke, Wiederbelebung, Streak-Schutz — bewusst zusammen mit
dem Dungeon. Zwischen Einzelkämpfen sind die HP ohnehin voll; ein Trank
wäre ein Knopf ohne Situation.

### 3.6 Gegner
Weitgehend gebaut. Drei Gegner in `packages/combat/lib/src/enemy.dart`, jeder
mit Werten, eigenem Moveset und einer Quote, wie oft er zu Utility statt
Schaden greift:

| Gegner | Fähigkeiten | Utility-Quote |
|---|---|---|
| Wegelagerer | nur gewöhnliche | 10 % |
| Söldner | bis ungewöhnlich | 20 % |
| Bergwächter | bis selten | 30 % |

Timing-Muster braucht es nicht mehr als eigene Größe: Der Gegner würfelt eine
Stelle auf der Leiste und wird mit denselben Fenstern gewertet wie der
Spieler (ADR-0023).

**Offen bleiben allein die Drop-Tabellen** — sie hängen am Dungeon (3.4) und
an der Frage, was ein Sieg überhaupt einbringt (§1).

### 3.7 Habits (= Daily Quests)
**Elf Vorlagen**, jede mit einem Charakterwert, einem Gebiet und einer
Begründung. Gebaut, siehe
[ADR-0008](docs/decisions/0008-gewohnheiten-als-eigenes-package.md).

**Freigeschaltet wird eine Vorlage von genau einer Seite** im Baum, und jede
Seite mit `unlocksHabit` hat genau eine Vorlage — beide Richtungen prüft
`test/habits_theory_test.dart` in der App. Die Verbindung läuft über den
Namen, weil `package:theory` und `package:habits` bewusst nichts voneinander
wissen.

**Vier Werte**, jeder mit einer Wirkung im Kampf:

| Wert | Kampf | Beispielvorlage |
|---|---|---|
| Stärke | Angriff | Zehn Minuten am Stück gehen |
| Ausdauer | Lebenspunkte | Feste Aufstehzeit |
| Disziplin | Verteidigung | Drei Aufgaben für morgen festlegen |
| Klarheit | Energie | Fünf Minuten still sitzen |

**Streak-System:** Streaks erzeugen XP-Multiplikatoren, die bei
Meilensteinen steigen (3 / 7 / 14 / 30 / 60 Tage). Verpasste Habits werden
nicht bestraft — der Bonus fehlt einfach, und die Kette stirbt erst, wenn
der Tag vorbei ist, nicht beim Aufwachen.

Der Multiplikator ist bei **x2 gedeckelt** — die Empfehlung wurde
übernommen: Bei x3 wird der Verlust einer langen Streak so schmerzhaft, dass
Nutzer aufgeben statt neu anzufangen. **Gold folgt dem Streak bewusst
nicht**, sonst wird eine lange Kette zur Abkürzung durch den Shop.

**Höchstens fünf Gewohnheiten gleichzeitig.** Ohne Grenze hakt man alle
Vorlagen an und keine davon ab; außerdem hält die Grenze die Erfahrung pro
Tag berechenbar, worauf die Levelkurve angewiesen ist.

### 3.8 Errungenschaften
Offen. Sie sollen später eine dritte Quelle für Fähigkeiten sein (3.1) und
bekommen einen eigenen Weg von der Kommandozentrale aus.

**Die Bedingung, an die das zurückgestellt war, ist seit dem 26.08. erfüllt**
— die Fähigkeiten stehen (ADR-0022). Zurückgestellt bleiben sie trotzdem:
`ziele.md` hält sie bewusst aus dem MVP heraus, weil sie für „wir zwei,
dreißig Tage" nichts beantworten. Der Auslöser ist damit von „bis die
Fähigkeiten stehen" auf „nach dem 30-Tage-Lauf" gewandert.

### 3.9 Freunde
Offen, und der einzige geplante Teil, der einen **Server** braucht — alles
andere läuft offline (ADR-0010). Steht als Weg auf der Kommandozentrale,
ohne dass damit über Umfang oder Zeitpunkt entschieden wäre.

---

## 4. Ausrüstungsquellen — Rollen trennen

| Quelle | Charakter | Rolle | gebaut |
|--------|-----------|-------|---|
| Shop | verlässlich, planbar | Grundversorgung, Mittelmaß | **ja** — 9 Stücke auf 6 Plätzen |
| Drops | zufällig | Aufregung, Varianz | nein — hängt am Dungeon |
| Theorie-Meilensteine | einzigartig, unverkäuflich | Prestige | nein |

**Von drei Quellen existiert eine.** Solange das so ist, gibt es im Laden
nichts zu entscheiden, was nicht der Preis schon entscheidet — die
Rollentrennung oben ist Absicht, nicht Zustand. Der Theoriebaum gibt heute
statt Ausrüstung **Fähigkeiten** (3.1); ob er zusätzlich Prestige-Stücke
geben soll, ist offen.

---

## 5. Tech-Stack

**Zielgerät: Handy im Hochformat.** Das ist keine Vorliebe, sondern folgt
aus dem Kern-Loop: Ein Häkchen wird im Vorbeigehen gesetzt, mit einer Hand,
mehrmals am Tag. Was man dafür erst aufklappen muss, wird nicht benutzt.

Querformat ist deshalb ausdrücklich **kein** Ziel — es wäre kein zweites
Layout, sondern ein zweites Produkt: Der Kampfbildschirm stapelt Gegner,
Log und vier Knöpfe untereinander, die Tagesliste lebt vom Scrollen. Die
App legt sich beim Start auf Hochformat fest (`lib/main.dart`).

Entwickelt wird gegen **Chrome**, weil Android auf keinem der beiden Rechner
fertig eingerichtet ist. Damit man das Zielformat dabei sieht, zeigt
`lib/ui/phone_frame.dart` die App im Browser in Handygröße, und
`test/phone_layout_test.dart` prüft jeden Bildschirm bei 390x844.

**Seit dem 26.08. ist Android ein Ziel**, kein Ausschluss: Der
`android/`-Teil ist vollständig, der Release-Build signiert mit dem
Debug-Schlüssel, ein APK zum Selbstinstallieren braucht also keinen Keystore.
Die Begründung steht in `ziele.md` — ein Browser-Tab wird seltener angetippt
als ein Symbol auf dem Startbildschirm, und Ziel 7 verlangt dreißig Tage
tägliches Spielen.

- **Flutter / Dart** — App-Shell, alle Tracker-Screens
- **Flame** — nur der Kampfbildschirm, als eingebettetes Widget
- **`SaveStore` + shared_preferences** — lokale Daten, offline-first
- **Riverpod** — State Management
- **Rive** — Skill- und Treffer-Animationen; die Schnittstelle steht, gespielt
  wird bis dahin mit gezeichneten Figuren

> **Drift war geplant und ist verschoben**
> ([ADR-0010](docs/decisions/0010-persistenz-hinter-einem-anschluss.md)).
> Persistenz liegt hinter einem Anschluss, `shared_preferences` ist die erste
> Implementierung dahinter, Drift passt später an dieselbe Stelle. Der
> Auslöser zum Wechsel ist benannt: sobald der Dungeon eine Lauf-Historie
> mitbringt.

**Architekturregel:** Kampflogik als reines Dart ohne Flame-Imports.
Die Logik gibt nur Events aus, Flame spielt sie ab.

---

## 6. Offene Punkte

1. ~~Multiplikator-Deckel und Streak-Meilenstein-Kurve festlegen~~ —
   erledigt, siehe 3.7 und ADR-0008
2. ~~Gold-Abflüsse schaffen~~ — Ausrüstung erledigt, siehe 3.5 und ADR-0011.
   Offen bleiben Tränke, Wiederbelebung und Streak-Schutz; sie gehören zum
   Dungeon
3. **Niederlagen-Regel entschärfen** — unentschieden seit dem 11.08. und
   damit der älteste offene Punkt. `ziele.md` macht die Auflage: Der ADR
   steht, **bevor** der Dungeon gebaut wird (3.4, Ziel 6)
4. ~~Ersten Theoriezweig auswählen~~ — erledigt, siehe 3.3 und ADR-0005/0007
5. Errungenschaften definieren
6. ~~Gegner-Design: Move-Sets~~ — erledigt, siehe 3.6 und ADR-0022/0023.
   **Drop-Tabellen** bleiben offen und hängen an Punkt 12
7. ~~Timed-Hit-Fenster in Millisekunden festlegen~~ — erledigt, jede
   Fähigkeit trägt ihre eigene `TimingSpec` (ADR-0022)
8. Onboarding: erste Sitzung bis zum ersten Kampf. **Der Weg ist seit
   ADR-0020 länger geworden** — Handbuch, Knoten öffnen, Seite bestehen,
   Fähigkeit anlegen. Ob das trägt, zeigt erst der 30-Tage-Lauf
9. ~~Die zwanzig Fähigkeiten festlegen~~ — erledigt, siehe 3.1 und ADR-0022.
   Es fehlen noch die **Icons** (Issue #17 ist deshalb offen)
10. ~~Titel-Katalog~~ — erledigt, sieben Titel aus drei Quellen (ADR-0014)
11. ~~Inhalt für die neuen Baumknoten~~ — der Startbaum steht mit 24 Knoten
    und 29 Seiten. Was an seine Stelle tritt, steht im Risikokasten in 3.3:
    die Knappheit, nicht die Menge

**Neu aufgenommen beim Abgleich am 31.08.:**

12. **Was ein gewonnener Kampf einbringt** — heute nichts (§1). Gold?
    Drops? Nur der Zugang zum nächsten Gegner? Die Frage entscheidet, ob
    jemand freiwillig kämpft, und sie blockiert Punkt 6
13. **Fähigkeitspunkte bauen oder streichen** — sie stehen im Konzept, sind
    im Spielstand und wirken nicht (3.1)
14. **Waffen als Sidegrades** — fünf Waffen, fünf Fähigkeiten, ähnlicher
    Preis. Braucht einen ADR, weil es ADR-0011 zurücknimmt (3.5, Ziel 3)
15. **Tageswechsel bei laufender App** — `todayProvider` rechnet sich nicht
    neu; wer über Mitternacht offen lässt, hakt auf dem gestrigen Tag ab
    (Ziel 4). Eine grundlos gerissene Kette ist der schlimmste denkbare
    Fehler in diesem Spiel (3.7)
16. **Die acht Punkte aus Issue #21** („Skill Tree Feedback", 25.08.) — vom
    Layout des Baums über randomisierte Antwortreihenfolge bis zu einem
    Freischaltungsscreen für neue Fähigkeiten. Noch nicht eingeordnet: MVP
    oder danach

---

## 7. Vorschlag MVP-Schnitt

**Drin:** Habits aus Vorlagen · Streaks · Stats · 1 Theoriezweig ·
Kampf mit 4 Moves und Timed Hits · 1 Dungeon · Shop mit Ausrüstung und
Tränken

**Stand 31.08.2026:** alles davon gebaut außer dem Dungeon — und damit außer
den Tränken, die ohne ihn wirkungslos wären. Statt einem Theoriezweig gibt es
einen Graphen aus 24 Knoten (ADR-0019), statt einem Gegner drei (ADR-0009),
statt vier Moves fünfzehn wählbare Fähigkeiten (ADR-0022).

**Raus für später:** Errungenschaften · Drop-Tabellen · Kosmetik ·
Cloud-Sync. Die vollständige, bindende Liste dessen, was bis zum MVP nicht
angefasst wird, steht in [`docs/context/ziele.md`](docs/context/ziele.md) —
dort mit Begründung je Punkt.

Ziel des MVP: Beantwortet die Frage, ob sich der Kampf gut genug
anfühlt, um am nächsten Tag wieder Habits abzuhaken. Alles andere ist
Ausbau.

**Seit dem 24.08. ist daraus eine nachprüfbare Ziellinie geworden:** Beide
Entwickler spielen dreißig Tage am Stück täglich, ohne dass einer wegen eines
Fehlers oder wegen Langeweile abbricht. MVP am 20.09.2026, Testlauf bis zum
20.10.2026.
