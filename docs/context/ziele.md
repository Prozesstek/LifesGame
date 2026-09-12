# Ziele

> Diese Datei ist die Antwort auf „Wo wollen wir hin?".
> `state.md` beantwortet „Wo stehen wir?" — die beiden gehören zusammen und
> widersprechen sich nie: Was hier als erreicht abgehakt wird, steht dort als
> fertig.
>
> Ziele sind **SMART**: spezifisch, messbar, erreichbar, relevant, terminiert.
> Ein Ziel ohne Prüfbefehl ist hier keins.

**Zuletzt aktualisiert:** 12.09.2026 · Prozesstek

---

## Die Ziellinie

**Ein spielbarer MVP für uns zwei — und der Nachweis, dass er trägt.**

Nicht „für Tester", nicht „für den Store". Die Abnahme ist konkret:

> Beide Entwickler spielen das Spiel **30 Tage am Stück täglich**, ohne dass
> einer wegen eines Fehlers oder wegen Langeweile abbricht.

Das ist absichtlich hart formuliert. Ein Habit-Tracker, den seine eigenen
Erbauer nach neun Tagen weglegen, ist widerlegt — und zwar von der einzigen
Instanz, die zählt.

**Termin: MVP steht am Sonntag, 20.09.2026. Testlauf 21.09.–20.10.2026.**

## Die Ziele auf einen Blick

| # | Ziel | Quelle | Termin |
|---|---|---|---|
| 1 | Der Kampf lässt sich starten | Issue #15 | **26.08.** |
| 2 | Skillbaum mit vier Wurzeln ✓ | Issue #16 | **31.08.** |
| 3 | Der Laden trifft eine Entscheidung ✓ | `state.md` Punkt 1 | ~~06.09.~~ **08.09.** |
| 4 | Die App übersteht Mitternacht ✓ | `state.md` Punkt 8 | ~~06.09.~~ **11.09.** |
| 5 | Fähigkeiten mit Art und Seltenheit ✓ | Issue #17 | ~~13.09.~~ **26.08.** |
| 6 | Die Gegnerreihe schließt den MVP-Schnitt ✓ | Issue #36 | ~~20.09.~~ **08.09.** |
| 7 | Der Nachweis | diese Datei | 20.10. |
| 8 | Errungenschaften vor dem Teststart ✓ | Issue #41 | ~~20.09.~~ **12.09.** |

## Was **nicht** im MVP ist — und warum

Ohne diese Abgrenzung wandert jeder gute Einfall in den kritischen Pfad.

| Zurückgestellt | Warum es für „wir zwei, 30 Tage" nicht nötig ist |
|---|---|
| **Große Schrift** (`textScaler` 2,0) | Wir zwei stellen sie nicht ein. Für Tester zwingend, für uns nicht. |
| **Rive-Animationen** | Die gezeichneten Figuren spielen. Die Schnittstelle steht und wartet. |
| **Lebensbalken an der Zeitachse** | Kosmetisch. Die Zahlen stimmen, nur die Reihenfolge nicht. |
| **Kampfsystem-Umbau** (Initiative, Kontern) | Nicht entschieden, kein Dokument im Repo. Ein unentschiedener Umbau gehört nicht in einen terminierten Plan. |
| ~~**Android**~~ → **jetzt dazugehörend** (26.08.) | Zurückgenommen von AktivesBrett: „Im Browser ist ja nur zum Testen, aber es soll auf dem Handy laufen." Das trägt: Ziel 7 verlangt **30 Tage tägliches** Spielen, und ein Browser-Tab wird seltener angetippt als ein Symbol auf dem Startbildschirm. Die Einrichtung steht in `state.md`. |
| **Store, Icons der App** | Ein sideloadetes APK reicht für zwei Leute. Das Startsymbol bleibt vorerst das Flutter-Logo. |
| ~~**Verkauf im Laden**~~ → **gebaut am 08.09.** | Das Signal war eingetreten ([ADR-0031](../decisions/0031-verkauf-als-versenkte-kosten.md)): Mit 27 Stücken, fünf Sidegrade-Waffen und drei Sets kostet ein Fehlgriff bis zu 42 Tage und war nicht zu korrigieren. Wer fünf Rhythmen anbietet, muss das Ausprobieren bezahlbar machen — sonst probiert niemand. **Entprellen der Persistenz** bleibt zurückgestellt. |
| **Dungeon** (Lauf aus 5 Kämpfen, Tränke, Wiederbelebung) | Neu auf dieser Liste am 08.09. ([ADR-0032](../decisions/0032-gegnerreihe-statt-dungeon.md)): Issue #36 hat Ziel 6 auf die Gegnerreihe umgeschrieben. Der Dungeon braucht drei Systeme mehr **und** eine Entscheidung, die `konzept.md` selbst offen lässt. Nach dem Teststart. |
| **Baum über 24 Knoten hinaus** | Der Startbaum aus ADR-0019 reicht für 30 Tage. Wachstum ist Inhalt, kein MVP. |
| **Entwicklermodus** | Gebaut am 25.08. ([ADR-0021](../decisions/0021-entwicklermodus-mit-eigenem-spielstand.md)), aber **kein MVP-Bestandteil**: nur im Debug-Build, eigener Spielstand. Er kann Ziel 7 technisch nicht berühren — genau dafür ist er so gebaut. |

**Diese Liste ist bindend.** Wer sie ändern will, ändert sie hier — sichtbar
für den anderen, statt still nebenbei.

---

## Ziel 1 — Der Kampf lässt sich starten

**Termin: Mittwoch, 26.08.2026 · Issue [#15](https://github.com/Prozesstek/LifesGame/issues/15)**

### Spezifisch

AktivesBrett meldet: Fähigkeiten laden nicht, angreifen geht nicht, der Kampf
startet nicht — **obwohl er die Lektionen des Handbuchs gemacht hat.** Damit
ist es kein Effekt der Sperre aus ADR-0018, sondern ein Fehler.

### Messbar

| Kriterium | Soll |
|---|---|
| Ursache benannt | in `gotchas.md`, nicht nur behoben |
| Reproduktion | ein Test, der ohne den Fix rot ist |
| Auf **seinem** Rechner | Kampf startet, Fähigkeiten laden |

```bash
flutter test
flutter run -d chrome    # auf beiden Rechnern
```

### Erreichbar

Die geprüften Pfade sind sauber: Branch-Id `habits`, fünf Lektionen, Ids
konsistent, `lessonCount == lessons.length`, alle 149 Tests grün. **Der Fehler
liegt also nicht dort, wo er zuerst vermutet wurde.**

Die beiden offenen Spuren: Er läuft auf **Flutter 3.47.0 / Dart 3.13.0**, hier
läuft 3.44.9 / 3.12.2. Und „Fragen gemacht" ist nicht dasselbe wie „mit ≥ 60 %
bestanden". Beides klärt eine Rückfrage im Issue, kein Debugging.

### Relevant

**Es ist das einzige Ziel, das jemanden vollständig blockiert.** Solange der
zweite Entwickler nicht spielen kann, ist der 30-Tage-Nachweis mit zwei
Spielern nicht möglich — und jedes Balance-Urteil beruht auf einer Person.

---

## Ziel 2 — Skillbaum mit vier Wurzeln

**Termin: Sonntag, 31.08.2026 · Issue [#16](https://github.com/Prozesstek/LifesGame/issues/16) · [ADR-0019](../decisions/0019-skillbaum-mit-vier-wurzeln.md)**

### Spezifisch

Der Baum aus ADR-0019 im Spiel: vier Wurzeln (Körper, Geist, Wissenschaft,
Gesellschaft), je mindestens fünf Unterknoten, geöffnet über Theoriepunkte
statt über Levelsperren. Ein Knoten ist eine Seite mit drei MC-Fragen. Icons
auf den Knoten. Vier Fähigkeiten hängen an Knoten.

### Messbar

| Kriterium | Ist (24.08., Abschluss) | Soll |
|---|---|---|
| Wurzeln | **4 + Handbuch** ✓ | 4 Wurzeln + Handbuch |
| Unterknoten je Wurzel | **5** ✓ | ≥ 5 |
| Knoten gesamt | **24** ✓ | ≥ 24 |
| Neue Seiten | **12 geschrieben** ✓ | 8 nötig, 4 Wurzelseiten kamen dazu |
| Theoriepunkte je Level | **2**, in `TheoryPoints` ✓ | 2, nur in `packages/progression` |
| Öffnen über Level | **nein**, nur über Punkte ✓ | **nein**, nur über Punkte |
| Graph kreisfrei | **Test weist es nach** ✓ | Test weist es nach |
| **Als Baum gezeichnet** | **ja, mit Linien** ✓ | Vorbild aus dem Issue |
| Seiten zählen als Lektionen | **ja** ✓ | — |
| Persistenz | **überlebt Neustart** ✓ | — |
| Knoten mit Fähigkeit | **4, bindend** ✓ | 4 |

**Ziel 2 ist vollständig.** Die vier Fähigkeiten hängen seit dem 24.08.
wirklich am Baum (`FromTheory` mit Knoten-Id); `FromStart` ist ersatzlos
entfallen. Die Lücke, die dabei entstand — zweiter Slot offen, aber
leer — schließt [ADR-0020](../decisions/0020-kampf-haengt-am-moveset.md):
Der Kampf hängt jetzt am Moveset statt am Handbuch allein.

**Noch nicht gemessen:** Ob der Weg zum ersten Kampf dadurch zu lang wird
(Handbuch, Knoten, Platz belegen), zeigt erst Ziel 7.

```bash
cd packages/theory ; dart test    # prüft Struktur **und** Inhalt
flutter test test/progression_test.dart
flutter test test/phone_layout_test.dart
```

### Erreichbar

**Der Inhalt ist die gute Nachricht.** Körper, Geist, Wissenschaft und
Gesellschaft haben je drei fertige Lektionen — zwölf Knoten sind geschrieben
und wandern nur. Auf ≥ 5 je Wurzel fehlen **acht Seiten**, nicht die ~130 aus
der alten Rechnung. ADR-0019 hat den Knoten von „Thema mit Lektionen" auf
„eine Seite" verkleinert, und das ist der Grund, warum der 31.08. überhaupt
denkbar ist.

**Der Aufwand liegt in drei Stücken:** das Datenmodell in `packages/theory`
von Zweigen auf Knoten mit Kindern, die Punkteökonomie in
`packages/progression`, und `skill_tree_screen.dart` — heute eine Liste, ein
Graph braucht etwas anderes.

**Das Risiko war die Darstellung, und es hat sich bestätigt.** Der erste
Anlauf war eine Liste von Listen — funktional vollständig, aber kein Baum.
Erst das Vorbild aus dem Issue (ein Graph mit Verbindungslinien) hat das
sichtbar gemacht. Gebaut ist jetzt eine Zeichenfläche mit
`CustomPainter`, Verschieben und Zoomen; die Anordnung ist eine reine
Funktion und wird von `test/tree_layout_test.dart` geprüft.

### Relevant

Das Level ist ab Stufe 5 heute folgenlos — es öffnet Zweige und sonst nichts
(ADR-0012). Mit Punkten bekommt jeder Aufstieg wieder eine Wirkung, und der
Baum wird eine Entscheidung statt einer Reihenfolge.

---

## Ziel 3 — Der Laden trifft eine Entscheidung

**Termin: Sonntag, 06.09.2026**

### Spezifisch

Fünf Waffen im Laden, jede mit **eigener** Fähigkeit und eigenem Rhythmus, zum
ähnlichen Preis statt als Leiter. Dazu der ADR, der die Regel aus ADR-0011
(„teurer muss auch besser sein") auf Preisstufen beschränkt.

### Messbar

| Kriterium | Ist (08.09., Abschluss) | Soll |
|---|---|---|
| Einträge in `AbilityCatalog.weaponMoves` | **5** ✓ | 5 |
| **verschiedene** Move-Ids darunter | **5** ✓ | **5** |
| Waffen in `gear/catalog.dart` | **5** ✓ | 5 |
| ADR zur Sidegrade-Regel | [ADR-0029](../decisions/0029-seltenheit-statt-preisleiter.md) ✓ | existiert |
| Rhythmus im Laden sichtbar | **ja**, Zeile je Waffe ✓ | — |

```bash
cd packages/gear      ; dart test    # 31
cd packages/abilities ; dart test    # 36
flutter test test/abilities_seam_test.dart
dart run tool/balance_sim.dart       # Abschnitt „Siegquote je Waffe"
```

Der Naht-Test hat die Prüfung dazubekommen: **keine zwei Waffen tragen
dieselbe Move-Id** — und eine zweite, die weiter geht: keine zwei Waffen
haben dasselbe Paar aus Power und Energie. Fünf verschiedene Ids mit
denselben Zahlen wären fünf Namen für eine Waffe.

**Ziel 3 ist erfüllt.** Die Waffe entscheidet jetzt messbar: An Tag 21
gegen den Söldner stehen 4 % (Geschliffene Klinge) gegen 100 %
(Übungsklinge). Die Zahlen und der Befund dazu stehen in `state.md`.

### Relevant

Bis dahin gaben **beide** Klingen `sword_strike`. Die Waffe bestimmte damit
nichts — der ganze Waffenslot war Dekoration.

---

## Ziel 4 — Die App übersteht Mitternacht

**Termin: Sonntag, 06.09.2026 — parallel zu Ziel 3**

### Spezifisch

`todayProvider` rechnet sich beim Tageswechsel neu, ohne Neustart.

### Messbar

Ein Test, der die Uhr über Mitternacht schiebt und prüft, dass die Tagesliste
nachzieht und ein Häkchen auf dem **neuen** Tag landet.

| Kriterium | Ist (11.09., Abschluss) | Soll |
|---|---|---|
| Tagesliste zieht um Mitternacht nach | **ja, ohne Neustart** ✓ | ohne Neustart |
| Häkchen landet auf dem neuen Tag | **ja**, die Streak läuft weiter ✓ | neuer Tag |
| App kommt aus dem Hintergrund zurück | **sofort** ✓ | — |
| Uhr oder Zeitzone umgestellt | **binnen einer Minute** ✓ | — |

```bash
flutter test test/day_watcher_test.dart
```

**Ziel 4 ist erfüllt**, fünf Tage nach Termin. Gebaut ist es als
`lib/habits/day_watcher.dart`; warum ein Widget und warum zusätzlich ein
Minutentakt, steht in `state.md`. Der Prüfbefehl nannte hier bis dahin
`test/habits_screen_test.dart` — die Datei hat es nie gegeben.

**Nicht auf einem Gerät geprüft:** ob ein Handy nach einer Nacht im
Hintergrund beim Aufwecken tatsächlich „zurück im Vordergrund" meldet.
Tut es das nicht, fängt der Minutentakt den Tag spätestens eine Minute
später.

### Erreichbar

Eine Sitzung. Der `Day`-Typ rechnet bereits in UTC und ist getestet — es fehlt
nur der Auslöser, der den Provider ungültig macht.

### Relevant

Wer 30 Tage täglich spielt, trifft Mitternacht garantiert. Ein Häkchen auf dem
falschen Tag reißt eine Streak — und eine grundlos gerissene Streak ist in
diesem Spiel der schlimmste denkbare Fehler (`konzept.md` 3.7).

---

## Ziel 5 — Fähigkeiten mit Art und Seltenheit

**Termin: Sonntag, 13.09.2026 · Issue [#17](https://github.com/Prozesstek/LifesGame/issues/17)**

### Spezifisch

Rund fünfzehn Fähigkeiten, getrennt in **Kampf** und **Support**, jede mit
Name, Schaden, Effekt, Timing-Geschwindigkeit, Energiekosten, Icon und
Seltenheitsstufe. Dazu die Engine-Arbeit aus `state.md` Punkt 2: ein
verallgemeinerter `StatModifier` plus anteilige Heilung, eigene Schwächungen
entfernen und Gift zünden.

### Messbar

| Kriterium | Ist (26.08., Abschluss) | Soll |
|---|---|---|
| Fähigkeiten gesamt | **20** ✓ | ~20 |
| davon **wählbar** (Slots 2–4) | **15** ✓ | ≥ 15 |
| Auswahl auf Level 10 | **3 aus 15** ✓ | 3 aus ≥ 15 |
| Arten (Kampf / Support) | **beide** ✓ | beide belegt |
| Seltenheitsstufen | **5, im Katalog** ✓ | im Katalog, nicht im UI verstreut |
| Eigenes Timing je Fähigkeit | **ja** ✓ | — |
| Umgebungen | **4** ✓ | — |
| Icons | **nein** | Beiwerk, siehe Schnittreihenfolge |

**Ziel 5 ist erfüllt** — achtzehn Tage vor dem Termin
([ADR-0022](../decisions/0022-faehigkeiten-set-aus-der-vorlage.md)).
Icons fehlen als Einziges; sie standen ohnehin als erstes auf der
Schnittliste.

**Was dabei aufgebrochen ist:** Die Balance stimmt nicht mehr. Der
Bergwächter ist unschlagbar geworden, weil er Rare-Fähigkeiten trägt,
während die frühen Spielerfähigkeiten schwächer sind als der Basisangriff.
Zahlen und Hebel stehen in `state.md`. Balancing war ausdrücklich
zurückgestellt — aber es ist jetzt ein offener Punkt mit Nachweis.

> **Nachtrag 26.08., abends.** Die Erklärung im Absatz darüber war falsch:
> Der Bergwächter trug seine Rare-Fähigkeiten gar nicht, weil
> `EnemyBlueprint.loadout` nirgends gelesen wurde. Seit das behoben ist —
> und seit die Gegner zielen und Utility benutzen
> ([ADR-0023](../decisions/0023-der-gegner-spielt-nach-denselben-regeln.md))
> — steht er bei 22 % an Tag 30 und 40 % an Tag 60 statt bei 0 %.
> Schlagbar, aber noch weit von den 100 % aus ADR-0009. Balancing bleibt
> zurückgestellt.
>
> Nebenbei sind dabei drei Fähigkeiten überhaupt erst wirksam geworden:
> Wurzelgriff, Sandsturm und Donnerkeils Perfect-Wirkung greifen alle am
> gegnerischen Zeitfenster an — und das wurde nie ausgerechnet.

```bash
cd packages/combat    ; dart test    # 78
cd packages/abilities ; dart test
flutter test test/abilities_seam_test.dart
dart run tool/balance_sim.dart
```

### Erreichbar mit einer Einschränkung

Der Katalog ist auf Zuwachs gebaut. **Aber Issue #17 verlangt mehr als
ADR-0017:** Seltenheit, Icons, Kampf/Support-Trennung und *umgebungs­verändernde*
Fähigkeiten (Sandsturm) stehen dort nirgends. Umgebungseffekte sind eine neue
Mechanik in `packages/combat`, kein Katalogeintrag.

**Deshalb ist dieses Ziel das erste, das geschnitten wird**, wenn der 20.09.
wackelt: Seltenheit und Icons sind Beiwerk, die Anzahl wählbarer Fähigkeiten
ist es nicht.

### Relevant

Vier wählbare Fähigkeiten auf drei Plätze sind **eine** Entscheidung. ADR-0013
nennt den Charakter eine Kommandozentrale; mit 3 aus 4 ist er ein Formular.

---

## Ziel 6 — Die Gegnerreihe schließt den MVP-Schnitt

**Termin: Sonntag, 20.09.2026 · Issue [#36](https://github.com/Prozesstek/LifesGame/issues/36) · [ADR-0032](../decisions/0032-gegnerreihe-statt-dungeon.md)**

> **Umgeschrieben am 08.09.2026.** Hier stand bis dahin der Dungeon aus
> `konzept.md` 3.4: vier Gegner plus Boss in einem Lauf, HP heilt nicht
> dazwischen, Tränke, Eintritt kostet Gold. Issue #36 beschreibt etwas
> anderes — dreißig aufsteigende Gegner mit einer Fortschrittsanzeige —
> und begründet es mit Ziel 7: „Motivation / Vergleich zwischen den
> Spielern während des Teststarts."
>
> Der Dungeon wandert hinter den Teststart. Der Grund steht in ADR-0032
> und ist nicht Geschmack, sondern Termin: Er braucht Tränke,
> Wiederbelebung, eine Eintrittsökonomie **und** zuerst eine
> Entscheidung, die `konzept.md` selbst als ungelöst markiert
> („bestraft doppelt"). Die Reihe braucht einen Zähler und eine
> Gegnerkurve.

### Spezifisch

Dreißig Gegner, stetig steigend, einer nach dem anderen. Ein Bildschirm
mit Fortschrittsanzeige, Gegnerbild, Namen und Kampf-Knopf. Ein erstmals
besiegter Gegner zahlt Erfahrung und Gold; ein zweiter Sieg gegen
denselben zahlt nichts.

### Messbar

| Kriterium | Ist (08.09.) | Soll |
|---|---|---|
| Gegner in der Reihe | **30** ✓ | 30 |
| Werte steigen stetig | **Test weist es nach** ✓ | kein Wert fällt |
| Sprosse 30 erreichbar | **62 %** ✓ | > 0 %, voll ausgerüstet |
| Belohnung je Gegner | **einmal** ✓ | einmal |
| Fortschritt nach Neustart | **überlebt** ✓ | überlebt |
| Gegnerbilder | **Platzhalter** | Platzhalter genügt (Issue #35) |

```bash
cd packages/combat ; dart test        # enemy_ladder_test, ladder_test
flutter test test/persistence_test.dart
flutter test test/result_dialog_test.dart
dart run tool/balance_sim.dart        # Abschnitt „Die Reihe"
```

**Ziel 6 ist erfüllt** — zwölf Tage vor dem Termin. Was **nicht** erfüllt
ist und bewusst offen bleibt, steht in `state.md`: Die Reihe steigt in
ihren Werten stetig, in der gemessenen Siegquote nicht. Balancing bleibt
zurückgestellt.

### Relevant

Das einzige Stück, das der MVP-Schnitt noch offen hatte. Und die Zahl,
die Ziel 7 überhaupt vergleichbar macht: Zwei Spieler, die dreißig Tage
lang abhaken, haben mit „17 / 30" gegen „21 / 30" zum ersten Mal etwas,
worüber sie reden können.

---

## Ziel 7 — Der Nachweis

**Zeitraum: Montag 21.09. bis Dienstag 20.10.2026**

### Spezifisch

Beide Entwickler spielen täglich. Kein Sonderrecht, keine Testdaten, keine
Abkürzung über den Debugger.

### Messbar

| Kriterium | Soll |
|---|---|
| Tage mit Häkchen je Spieler | ≥ 25 von 30 |
| Abbrüche wegen Fehler | **0** |
| Abbrüche wegen Langeweile | **0** |
| Notierte Reibungspunkte | in `state.md`, sobald sie auftreten |

Ein verpasster Tag ist **kein** Scheitern — das Spiel bestraft ihn auch nicht.
Gezählt wird der Abbruch, nicht die Lücke.

### Relevant

Ohne dieses Ziel sind die ersten sechs nur Bauarbeit. Es ist das einzige, das
die Produktfrage beantwortet statt einer technischen.

---

## Ziel 8 — Errungenschaften vor dem Teststart

**Termin: Sonntag, 20.09.2026 · Issue [#41](https://github.com/Prozesstek/LifesGame/issues/41) · [ADR-0033](../decisions/0033-errungenschaften-aus-der-historie.md)**

> **Neu am 11.09.2026.** Errungenschaften standen in `konzept.md` unter
> „Raus für später". Sie rücken vor den Teststart, weil alle sechs
> Bauziele erreicht sind und Ziel 7 ausdrücklich „Abbrüche wegen
> Langeweile" misst. Die Nummer ist 8, obwohl der Termin vor Ziel 7
> liegt — die Nummern der übrigen Ziele bleiben, wie sie sind.

### Spezifisch

Der erste Satz aus ADR-0033 im Spiel: **19 Meilensteine und 8
Entdeckungen** in `packages/achievements`, abgeleitet aus der Historie.
Die Titel sind Belohnung von Errungenschaften, Kraftschlag, Zehrung,
Sammeln und Atemzug kommen über je einen Meilenstein zurück. Zwei neue
Spuren: Niederlagen je Sprosse, gescheiterte Versuche je Lektion. Ein
Bildschirm vom Charakter aus, eine Feier für jede neue Errungenschaft.

### Messbar

| Kriterium | Ist (12.09., Abschluss) | Soll |
|---|---|---|
| Meilensteine im Katalog | **19** ✓ | 19 |
| Entdeckungen im Katalog | **8** ✓ | 8 |
| Titel aus Errungenschaften | **13** ✓ | 13 (7 bisherige + 6 neue) |
| Fähigkeiten aus Errungenschaften | **4** ✓ | 4 |
| Neue Spuren | **2**, überleben einen Neustart ✓ | 2 |
| Rückwirkend | **ja**, Test weist es nach ✓ | — |
| Entwicklermodus | **schaltet nichts frei** ✓ | Zuschläge schalten nichts frei |
| Kurven | **rechnen mit** ✓ | `progression_test.dart` rechnet Erfahrung und Gold mit |
| Bildschirm | **ja**, vier Reiter ✓ | vom Charakter aus, bei 390 × 844 ohne Überlauf |
| Feier | **ja**, an vier Stellen ✓ | — |

```bash
cd packages/achievements ; dart test    # 24
flutter test test/achievements_seam_test.dart
flutter test test/achievements_test.dart
flutter test test/progression_test.dart
flutter test test/phone_layout_test.dart
```

**Ziel 8 ist erfüllt** — acht Tage vor dem Termin, und ohne dass etwas
geschnitten werden musste: Die Entdeckungen sind mit drin. Was **nicht**
geprüft ist, steht in `state.md`: Wie der Bildschirm auf einem Handy
aussieht, muss jemand ansehen.

### Erreichbar

Die Bedingungen sind fast alle Katalogarbeit, weil sie an Zahlen hängen,
die es schon gibt. Der Aufwand liegt in fünf Stücken, in dieser
Reihenfolge: das Package samt Katalog, die zwei Spuren, Titel und
Fähigkeiten umhängen, die Belohnung in den Kurven, Bildschirm und Feier.

**Wird es knapp, wandern zuerst die Entdeckungen in den Testlauf** — und
mit ihnen die sechs neuen Titel und die zwei Spuren. Weil alles abgeleitet
wird, geht dabei niemandem etwas verloren; nur „Zweiter Anlauf" und „der
Unbeugsame" zählen erst ab ihrem Einbau.

### Relevant

Die Gewohnheiten zahlen jeden Tag dasselbe, der Baum ist nach rund zwei
Wochen offen, die Reihe hat dreißig Sprossen. Dreißig Tage brauchen
zusätzlich etwas, das unerwartet kommt — und etwas, das zwei Spieler
vergleichen können. Beides ist hier der Zweck.

---

## Wie der Fortschritt geprüft wird

**Freitags, in fünf Minuten.** Für jedes laufende Ziel die Ist-Spalte
nachtragen. Eine Zahl, die sich in einer Woche nicht bewegt hat, ist das
Signal — nicht das Gefühl.

Beim Verfehlen eines Termins gilt: **Der Umfang wandert, nicht die Ziellinie.**
Der 20.09. steht, weil der 30-Tage-Lauf sonst in den November rutscht. Die
Schnittreihenfolge ist festgelegt: **zuerst Ziel 5** (Seltenheit, Icons,
Umgebungseffekte), **dann Ziel 2** (Unterknoten über das Minimum hinaus).
Ziel 1, 4 und 6 sind nicht schneidbar — sie sind Blocker oder MVP-Schnitt.
**Bei Ziel 8** wandern zuerst die Entdeckungen hinter den Termin, die
Meilensteine nicht (siehe dort).

## Verlauf

- **12.09.2026** — **Ziel 8 erfüllt**, acht Tage vor dem Termin. Damit sind
  alle sieben Bauziele erreicht und nur noch Ziel 7 offen, der
  30-Tage-Lauf. Die Sperrliste ist unberührt geblieben. Nebenbei kam ein
  Fehler ans Licht, der seit ADR-0019 im Spiel war: Eine bestandene Seite
  schloss den halben Baum wieder (`TheoryProgress.submit`).
- **11.09.2026, nachmittags** — **Ziel 8 neu: Errungenschaften vor dem
  Teststart** ([ADR-0033](../decisions/0033-errungenschaften-aus-der-historie.md),
  Issue #41). Sie standen in `konzept.md` unter „Raus für später". Die
  Sperrliste oben ist unberührt — Errungenschaften standen dort nie.
- **11.09.2026** — **Ziel 4 erfüllt**, fünf Tage nach Termin. „Heute"
  rechnet sich jetzt um Mitternacht, jede Minute und beim Zurückkehren in
  den Vordergrund neu, ohne Neustart. Es war das letzte nicht schneidbare
  Ziel vor dem Teststart. Dazu hat Ziel 2 in der Übersicht den Haken
  bekommen, der dort seit dem 24.08. fehlte — der Abschnitt nannte es
  längst vollständig.
- **08.09.2026, abends** — **Ziel 6 umgeschrieben und erfüllt**
  ([ADR-0032](../decisions/0032-gegnerreihe-statt-dungeon.md)). Issue #36
  beschreibt nicht den Dungeon, sondern eine Reihe aus dreißig Gegnern —
  und begründet sie mit Ziel 7. Der Dungeon steht jetzt auf der
  Sperrliste. Mit derselben Entscheidung fällt eine, die seit dem ersten
  Konzeptentwurf stand: **Der Kampf zahlt jetzt Erfahrung und Gold, aber
  genau einmal je Gegner.** Erzwungen hat sie ein Test, der genau dafür
  geschrieben worden war (`result_dialog_test.dart`).
- **08.09.2026** — **Ziel 3 erfüllt**, zwei Tage nach Termin. Fünf Waffen
  mit fünf verschiedenen Zügen; der ADR zur Sidegrade-Regel war mit
  [ADR-0029](../decisions/0029-seltenheit-statt-preisleiter.md) schon da.
  Die Simulation hat einen Abschnitt dazubekommen, der die Behauptung
  prüft statt sie zu wiederholen — und sie bestätigt: Die Waffe entscheidet
  Kämpfe. Sie zeigt zugleich, dass sie es **zu einseitig** tut; der Befund
  steht in `state.md` und gehört zum zurückgestellten Balancing.
- **06.09.2026** — Issue #28 (eigene Gewohnheiten) gebaut, siehe
  [ADR-0028](../decisions/0028-eigene-gewohnheiten.md). **Kein neues Ziel:**
  Es ist kein MVP-Schnitt, sondern eine Voraussetzung für Ziel 7. Ein
  Tracker, in den man nicht schreiben kann, was man tatsächlich täglich
  tut, wird dreißig Tage lang nicht benutzt — und genau das ist die Frage,
  die Ziel 7 beantworten soll. Die Sperrliste ist unberührt geblieben.
- **24.08.2026, abends** — Nach drei Issues vom selben Nachmittag überarbeitet.
  #16 holt den Skillbaum in den MVP zurück (er stand mittags noch auf der
  Sperrliste) und setzt den 31.08.; ADR-0019 hält die Abweichungen von
  ADR-0012 fest. #15 wird zu Ziel 1, nachdem sich die Sperr-Hypothese
  erledigt hat: AktivesBrett hatte die Lektionen gemacht. #17 erweitert die
  Fähigkeiten über ADR-0017 hinaus.
- **24.08.2026, mittags** — Ziele erstmals festgehalten. Ziellinie auf „MVP für
  uns zwei plus 30-Tage-Nachweis" festgelegt. Anlass war ein Befund beim
  Zählen: vier wählbare Fähigkeiten auf drei Plätze, und beide Waffen im Laden
  geben denselben Move.
