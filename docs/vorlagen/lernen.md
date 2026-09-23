# Lernen — die Vorlage

> **Herkunft:** aus einer Konzeptrunde am 20.09.2026, nach dem Teststart.
> Ausgelöst von der Frage „Wie könnten wir die Art des Lernens aus
> psychologischer und UI/UX-Sicht besser gestalten?"
>
> **Was sie ist:** die Absicht. Sie sagt, wie sich Lernen anfühlen soll
> und woran das hängt.
>
> **Was sie nicht ist:** eine Entscheidung. Nichts davon ist gebaut, und
> Punkt 1 braucht einen ADR, bevor er es wird — er bringt zum ersten Mal
> **wiederholbare Erfahrung** ins Spiel, und das ist genau die Grenze, die
> [ADR-0032](../decisions/0032-gegnerreihe-statt-dungeon.md) beim Kampf
> gezogen hat.
>
> **Warum sie hier liegt:** Weil `CLAUDE.md` es so verlangt — wer nach
> einem Dokument baut, legt das Dokument zuerst hierher. `Kampfsystem.docx`
> ist der Gegenbeweis: seit dem 22.08. „noch nicht im Repo", und deshalb
> ist der Kampfsystem-Umbau bis heute unentschieden.

---

## Wie Lernen heute abläuft

1. Knoten im Baum öffnen — kostet einen Theoriepunkt ([ADR-0019](../decisions/0019-skillbaum-mit-vier-wurzeln.md), [ADR-0035](../decisions/0035-ein-theoriepunkt-je-level.md))
2. Drei Abschnitte Fließtext lesen, je etwa 150 Wörter
3. Drei Multiple-Choice-Fragen, Antworten gemischt ([ADR-0027](../decisions/0027-fragen-ohne-verraeter.md))
4. Erklärung nach jeder Antwort — auch nach einer richtigen
5. Ab 60 % bestanden (zwei von drei), 40 Erfahrung und 25 Gold, einmalig,
   +15 Erfahrung bei drei von drei
6. **Fertig. Für immer.**

Der Inhalt ist gut: 29 Seiten, klare Sprache, konkrete Beispiele, jede
Frage mit Begründung. Was fehlt, ist nicht Qualität, sondern **Form**.

## Der Befund

> **Eine App über Wiederholung lehrt ohne Wiederholung.**

Eine Lektion wird einmal gelesen, einmal abgefragt und nie wieder
angesehen. Das Produkt behauptet auf jeder Kachel, dass Wiederholung der
Kern ist — und macht beim Lernen das Gegenteil.

Zwei Nebenbefunde aus demselben Blick:

- **Wer mit 2 von 3 besteht, hat über ein Drittel des Inhalts eine falsche
  Vorstellung und sieht sie nie wieder.** `LessonRecord` hält
  `bestCorrect`; *welche* Frage falsch war, steht nirgends.
- **Die Lektion endet im Nichts.** Sie schaltet eine Habit-Vorlage frei —
  aber erst später, im Gewohnheiten-Bildschirm, ohne Bezug zum eben
  Gelesenen.

---

## 1. Die Rückfrage des Tages

> **Gebaut am 23.09.2026** ([ADR-0045](../decisions/0045-rueckfrage-des-tages.md)).
> Abweichend von hier: **Erfahrung und Gold** (10 und 3), **eine** Frage
> statt ein bis drei, und die Frage rotiert innerhalb der Seite, statt die
> beim ersten Mal falsche zuerst zu bringen. Das bräuchte eine neue Spur
> in `LessonRecord`.

**Der größte Hebel, und der mit den meisten Folgen.**

Neben der Tagesliste stehen ein bis drei Fragen aus **bereits
bestandenen** Lektionen. Zwanzig Sekunden. Das Intervall wächst mit jedem
richtigen Treffer und fällt bei einer falschen Antwort zurück.

| Treffer in Folge | nächste Rückfrage nach |
|---|---|
| 1 | 1 Tag |
| 2 | 3 Tagen |
| 3 | 7 Tagen |
| 4 | 21 Tagen |
| falsch | zurück auf 1 Tag |

**Warum das hier besser passt als in jeder Lern-App:** Der teuerste Teil
einer Wiederholungs-App ist, jemanden zurückzuholen. Bei uns ist das
gelöst — die App wird ohnehin jeden Tag geöffnet.

**Welche Frage zuerst zurückkommt:** die, die beim ersten Mal falsch war.
Gezielt statt pauschal. Dafür muss `LessonRecord` die falschen Fragen
mitschreiben, nicht nur ihre Zahl.

### Was daran entschieden werden muss

| Frage | Warum sie nicht nebenbei zu beantworten ist |
|---|---|
| **Gibt es Erfahrung dafür?** | Dann ist es die erste wiederholbare Erfahrungsquelle des Spiels. Vorschlag: **Erfahrung ja, Gold nein** — dieselbe Trennung wie beim Streak-Multiplikator (`HabitRewards.goldPerCheck`) |
| **Wie viel?** | Sie hängt mit in den vier Kurven. Wer die Zahl setzt, lässt `flutter test test/progression_test.dart` laufen |
| **Zählt sie in die Streak?** | Vorschlag: **nein.** Die Streak gehört den Gewohnheiten. Zwei Ketten nebeneinander sind eine zu viel |
| **Wo steht sie?** | Vorschlag: auf dem Gewohnheiten-Bildschirm, über der Tagesliste — dort, wo der Tag ohnehin beginnt |

**Bauform:** eine Historie im Spielstand, dieselbe wie die Häkchen —
wann welche Frage wie beantwortet wurde. Der Stand der Intervalle wird
daraus **gerechnet**, nicht gespeichert (ADR-0008, ADR-0011).

---

## 2. Die Fragen prüfen Wiedererkennen, nicht Erinnern

Vier sichtbare Optionen sind der schwächste Abruf, den es gibt. Drei
Änderungen, alle an der Oberfläche, **keine am Inhalt**:

| Änderung | Was sie bewirkt | Aufwand |
|---|---|---|
| **Frage vor dem Text** | Wer vorher geraten hat, liest danach *nach einer Antwort* statt vor sich hin — auch wenn er falsch lag | klein |
| **Erst denken, dann Optionen** | Ein Knopf „Ich hab's" blendet die vier Antworten erst danach ein. Aus Wiedererkennen wird Abruf | klein |
| **Sicherheit vorher** | „Sicher / unsicher" vor dem Tippen. *Sicher und falsch* ist die Korrektur, die am besten haftet — und die einzige, die jemandem zeigt, dass er sich getäuscht hat | mittel |

Die dritte gibt außerdem eine Zahl her, die es sonst nicht gibt: **wie gut
jemand einschätzt, was er weiß.** Das ist ein besserer Kompetenzmaßstab
als „bestanden".

---

## 3. Die Brücke zum Handeln

**Der billigste große Hebel** — und der, der am meisten auf das
Produktversprechen einzahlt.

Am Ende jeder Lektion eine Zeile: **„Wann machst du das?"** Ein Tippen
legt eine eigene Gewohnheit an oder passt eine bestehende an.

Die Teile liegen alle schon da:

| Was gebraucht wird | Wo es steht |
|---|---|
| Das Formular | `lib/habits/widgets/custom_habit_sheet.dart` |
| Die Verbindung Lektion → Vorlage | `Lesson.unlocksHabit` |
| Der eigene Grund | `CustomHabit.why` |

Es fehlt nur die Verbindung **im Moment des Lernens** statt danach im
Menü. Passend dazu: `why` wird heute nur auf der ruhenden Kachel gezeigt.
Der eigene Satz gehört dorthin, wo abgehakt wird.

**Warum gerade das:** Die Lektion *Systeme schlagen Vorsätze* erklärt
genau dieses Prinzip — „ein System beantwortet Zeitpunkt, Ort und Umfang
im Voraus" — und wendet es nicht an. Vorsätze, die an eine Situation
gebunden sind, werden deutlich zuverlässiger umgesetzt als solche ohne;
es ist die am besten belegte einzelne Verhaltenstechnik.

---

## 4. Der Lesebildschirm

| Heute | Besser | Warum |
|---|---|---|
| Drei Absätze am Stück, dann drei Fragen | Abschnitt → Frage → Abschnitt → Frage | Kurzer Abruf direkt nach dem Lesen, und auf dem Handy drei kleine Blöcke statt einer Wand |
| Kein Fortschritt innerhalb der Lektion | „2 von 3" oben | Die stumme Frage „wie lange noch" beantwortet sich selbst |
| Kein Weg zurück in den Text | Nachlesen **nach** einer falschen Antwort | Vorher wäre es Abschreiben und zerstört den Abruf |
| Jeder Abschnitt gleich gewichtet | Ein **Kernsatz** je Abschnitt | Er ist zugleich die Karteikarte für Punkt 1 |

**Die Verschränkung ist nicht gratis.** Abschnitte und Fragen kommen beide
dreimal vor, das lädt dazu ein — aber in Lektion 1 gehören zwei der drei
Fragen zum selben Abschnitt. Es wäre **Schreibarbeit an 29 Seiten**, nicht
nur Layout.

---

## 5. Was ausdrücklich **nicht** vorgeschlagen wird

**Keine variablen Belohnungen, keine Lootbox aufs Lernen.**

Lernen zahlt schon Erfahrung und Gold. Noch mehr Äußeres draufzulegen ist
die Richtung, in der Interesse erfahrungsgemäß eher verdrängt als
verstärkt wird — und es kollidiert mit `konzept.md`: Theorie soll 30 % des
Fortschritts sein, nicht die beste Quelle.

Was stattdessen fehlt, ist **sichtbare Kompetenz** statt sichtbarer
Belohnung: „Du hast 12 von 29 Seiten sicher" — ein Stand, der zeigt, was
jemand *kann*, nicht was er *verdient hat*. Das Gegenstück zum Ruhm bei
den Errungenschaften ([ADR-0033](../decisions/0033-errungenschaften-aus-der-historie.md)).

Mit Punkt 1 fällt diese Zahl von selbst ab: „sicher" heißt, die Frage ist
im längsten Intervall.

---

## Reihenfolge

| # | Was | Nutzen | Kosten | Braucht einen ADR |
|---|---|---|---|---|
| 1 | „Wann machst du das?" am Lektionsende | größter Verhaltenseffekt | fast nur Verdrahtung | nein |
| 2 | Erst denken, dann Optionen | echter Abruf statt Wiedererkennen | klein | nein |
| 3 | **Rückfrage des Tages** | größter Lerneffekt | neue Historie, berührt die vier Kurven | **ja** |
| 4 | Sicherheit vorher abfragen | Kalibrierung, neue Kompetenzzahl | mittel | nein |
| 5 | Abschnitt ↔ Frage verschränken | besser lesbar und behaltbar | 29 Seiten Schreibarbeit | nein |

**Punkt 1 und 2 sind Bauarbeit.** Punkt 3 ist eine Entscheidung und
gehört vorher in einen ADR — er ändert, was ein Theoriepunkt wert ist.

## Was diese Vorlage nicht beantwortet

- **Ob die Rückfrage im Alltag nervt.** Zwanzig Sekunden klingen kurz;
  ob sie es neben fünf Häkchen auch sind, sagt nur ein Lauf.
- **Was mit Lektionen passiert, die nie bestanden wurden.** Die Rückfrage
  zieht nur aus bestandenen — wer eine Seite liegen lässt, sieht sie nie
  wieder. Vielleicht ist das richtig, vielleicht fehlt ein Anstoß.
- **Ob der Baum dadurch zu langsam wird.** Wer wiederholt, öffnet in
  derselben Zeit weniger Knoten. Die Kurve aus `progression_test.dart`
  sagt es, sobald eine Zahl feststeht.
