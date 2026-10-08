# Das nächste Level — die Vorlage

> **Herkunft:** aus einem Gespräch am 08. und 09.10.2026. Frederik fragte:
> „Was würdest du machen, um unser Konzept auf das nächste Level zu
> bringen und garantiert Erfolg zu haben? Sei ruhig kreativ.“ Claude
> schlug fünf Ideen vor, Frederik: „finde alle Ideen super, halt die auf
> jeden Fall fest, das bauen wir nach und nach.“
>
> **Was sie ist:** die Absicht hinter fünf Ideen und die Fragen, die vor
> dem Bau jeder einzelnen zu klären sind. Die Richtung hält
> [ADR-0071](../decisions/0071-das-naechste-level.md) fest.
>
> **Was sie nicht ist:** eine Entscheidung über Einzelheiten. Nichts
> davon ist gebaut. Jede Idee bekommt vor dem Bau ihre eigene
> Konzeptrunde und dort ihren ADR. Was hier an Zahlen und Regeln steht,
> ist ein Vorschlag für diese Runden.
>
> **Warum sie hier liegt:** `CLAUDE.md` verlangt es — wer nach einem
> Dokument baut, legt es zuerst hierher.

---

## Der Befund

Garantieren kann Erfolg niemand. Bauen lässt sich aber gegen die drei
Gründe, an denen Habit-Apps meistens scheitern:

| Grund | bei uns |
|---|---|
| **Niemand erfährt davon.** | Es gibt keinen Weg, das Spiel jemandem zu zeigen. |
| **Die tägliche Pflicht wird zu schwer.** | Abhaken, Truhe, Aufgaben, Rückfrage, vier Dailies, Laden — alles verfällt um Mitternacht (Durchsicht vom 02.10.). |
| **Irgendwann ist alles gesehen.** | Dreißig Stufen zahlen je einmal, und der Baum wächst nur so schnell, wie geschrieben wird (`konzept.md` 3.3). |

Dazu kommt ein vierter, eigener Befund: **zwölf Systeme ohne eine
Geschichte**, die sie zu einem Ganzen macht. Das Spiel hat mehr Systeme
als die meisten Habit-Apps und, anders als Habitica oder Finch, einen
Kampf, der ein echtes Spiel ist. Es fehlen ein Grund, es jemandem zu
zeigen, und ein Grund zum Wiederkommen, der keine Pflicht ist.

**Der Grundsatz daraus: Das nächste Level heißt nicht mehr Systeme,
sondern weniger, die enger zusammenhängen.** Vier der fünf Ideen
bündeln, was es schon gibt. Nur die Seilschaft ist neu.

## Die Positionierung: das Spiel, das dich wegschickt

Ein Versuch am Tag in der Tagesgrube, ein Feuer am Abend, und der Tag
endet mit einem Satz, der vom Bildschirm wegschickt. Damit hebt sich das
Spiel von allem ab, was auf Bildschirmzeit optimiert ist. Und es passt
zu dem, was `konzept.md` Abschnitt 2 vom Kampf sagt: Er ist die
Auszahlung des Fortschritts, nicht seine Quelle.

---

## 1. Die Tagesgrube — Wordle für Gewohnheiten

**Gegen:** Niemand erfährt davon.

Jeden Tag gibt es **dieselbe Grube für alle**, gesät aus dem Datum, und
jeder hat **einen Versuch**. Alle gehen mit **demselben Helden** hinein.
Stärker macht nur eins: ob man heute in Form ist, also alles erledigt
hat, was man sich für heute vorgenommen hat. Ob das eine Gewohnheit war
oder fünf, ist egal, deshalb ist der Vergleich unter Freunden fair.

Danach gibt es einen **Text zum Kopieren**, ohne Spoiler:

```
Lifes Game · Tagesgrube 08.10.
⏱ 2:41 · ⚡ In Form · 🔥 12 Tage
```

**Warum das trägt:** Wordle war eine statische Seite mit
Browser-Speicher, wie wir gerade, und ist vor allem über so einen Text
gewachsen. Spelunky und Slay the Spire haben den Tageslauf seit Jahren.
Bei uns zeigt der geteilte Text nebenbei, dass jemand seine
Gewohnheiten erledigt hat — der Vergleich zahlt auf den Kern ein, nicht
daneben. Und es braucht **keinen Server**: Verglichen wird in der Gruppe,
in die man den Text kopiert.

**Was sie einbringt:** nur Ruhm. Der ist laut `konzept.md` 3.8 ohnehin
„nur ein Stand zum Vergleichen, kein Zahlungsmittel“, und ADR-0032
bleibt unberührt: Kein Kampf wird zur Dauerquelle.

**Vorschlag: Die vier Dailies gehen darin auf** — eine gemeinsame Grube
statt vier eigener, weniger Pflicht. Das braucht einen eigenen ADR
(ADR-0040 wäre abgelöst) und eine neue Rechnung des Zuflusses
(`runway_sim`, `progression_test.dart`).

**Woran es im Code hängt:**

| Was | Wo |
|---|---|
| Die Grube ist gesät | `LevelBuilder.build(stage:, seed:)` — Karte, Wächter (`bossFor`) und Besetzung (`PitCast.forSeed`) aus dem Startwert |
| Der Startwert ist frei gewürfelt | `lib/action/pit_screen.dart`, `_neuerLauf` |
| Etwas aus dem Datum würfeln | wie `PitDailies.forDay`, `DailyChest.forDay`, `DailyShop.offersFor` |
| Die Tagesform | `HabitTracker.formOn` |
| Der Held | `PitPower.hero` — für die Tagesgrube ein fester statt des eigenen |

**Fragen für die Konzeptrunde:**

1. Wie schwer ist die Tagesgrube — eine feste Stufe, oder je Wochentag
   anders (Montag leicht, Sonntag schwer)?
2. Der Einheitsheld: welche Waffe, welche Fähigkeiten? Für alle immer
   gleich, oder je Tag eine andere Ausstattung, aus dem Datum gewürfelt
   („heute: Bogen und Eisfeld“)?
3. Zählt nur „In Form“ ja oder nein, oder die ganze Tagesform je Wert?
4. Ab wann ist sie offen: den ganzen Tag, oder ab dem ersten Häkchen?
5. Was steht im Text: Zeit, Sieg oder Niederlage, Tagesform, Tageskette?
   Ein Raster der Räume wie bei Wordle?
6. Ein Versuch: Was gilt für einen Lauf, der abbricht, weil die App
   geschlossen wird?
7. Wie viel Ruhm, und gehen die vier Dailies darin auf?

## 2. Das Lagerfeuer — der Tag endet an einer Stelle

**Gegen:** die tägliche Pflicht.

Abends gibt es **eine Minute für alles**, statt fünf Dingen, die um
Mitternacht verfallen: die Rückfrage, die Truhe, die Tagesaufgaben und
sonntags den Wochenrückblick. Zum Schluss **tippt man an, was morgen
zuerst drankommt**. Das ist ein Umsetzungsvorsatz (Gollwitzer), einer
der am besten belegten Hebel der Verhaltensforschung, und er passt zu
„Wann machst du das?“ (ADR-0052). Am Feuer sitzt der **Begleiter** — das
Haustier, das sich Frederik fürs Haus gewünscht hat (Issue #88).

Es endet mit **einem Satz, der wegschickt**. Daraus kommt die
Positionierung oben.

**Warum das trägt:** Die Durchsicht vom 02.10. nennt die tägliche
Pflicht als Grund aufzuhören. Das Feuer nimmt keine Belohnung weg, es
sammelt sie an einer Stelle. Und es ist der natürliche Moment für die
eine Erinnerung am Abend, sobald es eine App gibt.

**Woran es hängt:**

| Was | Wo heute |
|---|---|
| Rückfrage | `lib/theory/widgets/review_section.dart`, oben in der Theorie |
| Truhe | `openDailyChest` in `lib/habits/habit_check_flow.dart`, auf der Startseite |
| Tagesaufgaben | `lib/habits/widgets/daily_quests_card.dart`, auf der Startseite |
| Wochenrückblick | `lib/habits/week_review_screen.dart` |
| Das Haus | `lib/village/house_screen.dart`, Prototyp |

**Fragen für die Konzeptrunde:**

1. Ab wann brennt es: ab einer Uhrzeit, sobald alles erledigt ist, oder
   beides?
2. Ist das Feuer der **einzige** Ort für Rückfrage, Truhe und Aufgaben,
   oder ein zweiter Weg dorthin?
3. Verfällt, was am Feuer liegt, weiter um Mitternacht — oder erst am
   nächsten Feuer?
4. „Morgen zuerst“: Was macht der Tipp am nächsten Morgen — steht die
   Gewohnheit oben in „Heute“, leuchtet sie? Eine Zahl erzeugt er nicht.
5. Der Begleiter: kommt er hier zum ersten Mal, oder erst mit dem Haus?
6. Der Satz zum Schluss: welcher Wortlaut?

## 3. Der Schatten — ganz unten wartest du selbst

**Gegen:** zwölf Systeme ohne Geschichte.

Ganz unten in der Grube wartet man **selbst, wie man vor 30 Tagen
war**. Wer drangeblieben ist, gewinnt deutlich. Wer nicht, kämpft gegen
sein Spiegelbild. So wird die Kernfrage der Selbstverbesserung
spielbar: **Bin ich besser als vor einem Monat?**

**Vorschlag: Der Schatten hat alles, was du heute hast, außer deinen
Gewohnheiten der letzten 30 Tage.** Der Unterschied zwischen dir und ihm
sind dann genau sie. Dazu geht man selbst mit seiner Tagesform hinein,
er nicht.

**Woran es hängt:** Das kann nur dieses Spiel, weil alles aus der
Historie gerechnet wird. Zwei Haken stehen schon fest:

- **Die Werte allein reichen nicht.** `HabitTracker.statsUpTo` rechnet
  die Werte eines vergangenen Tages schon aus, aber sie sind nach 32 bis
  40 Häkchen je Wert gedeckelt (`StatCurve`). Danach wäre der Schatten
  so stark wie man selbst. Er muss am **Level** hängen.
- **Nicht jede Erfahrung trägt ein Datum.** Häkchen und Rückfragen
  schon, bestandene Seiten und erste Siege in der Grube nicht. „Alles
  außer den Gewohnheiten der letzten 30 Tage“ lässt sich deshalb heute
  rechnen, „das Level von vor 30 Tagen“ nicht.

**Die Geschichte dazu:** Man steigt in sich selbst hinab. Jung nennt
das, was man an sich nicht sehen will, den Schatten, und Joseph Campbell
wird der Satz zugeschrieben: „Die Höhle, die du zu betreten fürchtest,
birgt den Schatz, den du suchst.“ Die vier Wächter werden zu **inneren
Gegnern**:

| Wächter | wird | weil |
|---|---|---|
| Zweikopf | der Zweifel | bei ihm kommt alles zweimal |
| Schlund | die Ablenkung | er verschlingt |
| Sumpftroll | die Trägheit | seine Pfützen bremsen |
| Zyklop | die Angst | ein Auge, Tunnelblick |

**Fragen für die Konzeptrunde:**

1. Wann kommt er: einmal im Monat, nach Stufe 30, oder jederzeit über
   einen eigenen Eingang?
2. Woraus genau besteht er (Vorschlag oben)? Wer kürzer als 30 Tage
   spielt, trifft sein Ich vom ersten Tag — ein leichter erster Sieg?
3. Was bringt ein Sieg: Ruhm, ein Titel?
4. Wie sieht er aus: die eigene Figur samt Ausrüstung, dunkel?
5. Wo steht die Geschichte, wenn die App ohne Lesen geht (ADR-0060):
   im Namen und in der Zeile beim Auftritt (`BossText`)?
6. Heißen die Wächter um, oder bleibt der Name, und die Zeile darunter
   sagt, wer sie sind?

## 4. Saisons — sechs Wochen, ein Thema

**Gegen:** Irgendwann ist alles gesehen.

Schlaf, Fokus, Stoizismus: **je ein Buch**, das Frederik liest
([ADR-0061](../decisions/0061-der-baum-waechst-aus-dem-gelesenen.md)).
Daraus entstehen Seiten im Baum, zwei Vorlagen, **ein Wächter als
innerer Gegner des Themas**, eine Herausforderung und etwas fürs Haus.
Begleitend läuft das Thema als Video-Reihe (siehe „Vertrieb“).

**Warum das trägt:** Jede Saison ist ein **Neuanfang** für alle, die
abgesprungen sind. Das nennt sich Fresh-Start-Effekt (Dai, Milkman, Riis
2014): An zeitlichen Wendepunkten fällt ein neuer Anlauf leichter. Und
aus einem Buch entstehen drei Dinge auf einmal.

**Fragen für die Konzeptrunde:**

1. Sechs Wochen, oder länger?
2. Welches Thema zuerst — was liest Frederik gerade?
3. Was bleibt nach der Saison: Seiten und Vorlagen für immer, nur die
   Herausforderung und ihr Lohn sind vorbei?
4. Der Wächter der Saison: ein fünfter `BossKind`, der nur während der
   Saison gewürfelt wird?
5. Was gibt es fürs Haus, und wer zeichnet es?
6. Wer schreibt und wer liest gegen? Sechs Wochen sind ein Takt, kein
   Projekt.

## 5. Die Seilschaft — wer fällt, wird gehalten

**Gegen:** allein aufhören.

Zwei bis vier Leute hängen an einem Seil. Man sieht, **ob** die anderen
heute ihre Gewohnheiten erledigt haben, aber nicht **welche**. Verpasst
einer einen fälligen Tag und die anderen haben ihren geschafft, **fällt
seine Kette nicht**. Das geht einmal pro Woche.

**Warum das trägt:** In Habitica schadet ein Fehltag im Bosskampf der
ganzen Gruppe. Hier hält die Gruppe den, der fällt. Das passt zu
ADR-0064: Eine Kette fällt eine Stufe, sie reißt nicht.

**Woran es hängt:**

- **Der erste Server.** `konzept.md` 3.9 sieht ihn für „Freunde“ vor;
  bis dahin läuft alles offline (ADR-0010).
- **Eine Stelle für die Kette:** Ob ein gedeckter Tag trägt, entscheidet
  `HabitTracker._habitDay`. Das Seil wäre dort eine zweite Art, einen
  Tag zu decken, neben dem Streak-Eis (ADR-0036).

**Fragen für die Konzeptrunde:**

1. Welcher Server, welches Konto? Was verlässt das Handy — nur „Tag
   geschafft: ja oder nein“?
2. Zählt das Seil wie ein Eis, oder ist es eine eigene Art?
3. Gibt es eine Kette der Seilschaft — Tage, an denen alle dran waren?
4. Einladen ohne Store: Link oder Code?
5. Wann: mit der App (Vorschlag), oder vorher zu zweit zum Ausprobieren?

---

## Vertrieb: das Spiel als Takeaway

Das Spiel kommt nicht über Entwicklertagebücher zu den Leuten, sondern
als **praktischer Teil von Videos über Psychologie und
Selbstverbesserung**: Ein Video erklärt, warum man Vorsätze nach drei
Tagen abbricht, und am Ende steht das Spiel, das dagegen gebaut ist.
Aus einem Buch werden so ein Video, Seiten im Baum und eine Saison.

## Reihenfolge und Messlatte

Vorgeschlagen von Claude, nicht ausdrücklich bestätigt:

1. **Tagesgrube mit Teilen** — klein, und sie zeigt sofort, ob sich das
   Spiel verbreitet.
2. **Lagerfeuer** — nimmt Pflichten heraus, bevor Fremde kommen.
3. **Schatten und die inneren Gegner** — die Geschichte.
4. **Saisons**, sobald 1 bis 3 tragen.
5. **Seilschaft**, wenn es eine App gibt.

**Die Messlatte**, ebenfalls ein Vorschlag: Tagesgrube und Text gehen an
eine Gruppe von **zehn Leuten, die nicht wir sind** — über die
Web-Fassung, ohne Store. Teilen nach **zwei Wochen noch drei** von
selbst ihr Ergebnis, verbreitet sich das Spiel. Teilt keiner, wissen wir
das nach zwei Wochen und nicht erst nach einem Store-Start. Sobald die
Tagesgrube steht, wird daraus ein Ziel mit Termin in `ziele.md`.

## Leitplanken für alle fünf

Was in keiner Konzeptrunde fällt, ohne dass ein ADR es ausdrücklich
ändert:

- **Kein Kampf wird zur Dauerquelle** für Erfahrung oder Gold (ADR-0032).
- **Schlüssel kommen nie aus dem Spielen** (ADR-0048).
- **Keine Scham:** Nichts wird bestraft, was das Spiel heute nicht
  bestraft; eine Kette fällt eine Stufe (ADR-0064).
- **Die App geht ohne Lesen** (ADR-0060): Das Feuer wird angetippt, die
  Geschichte steht in Namen und Bildern.
- **Eine feste Zahl im Kampf ist ein Bug** — auch der Einheitsheld und
  der Schatten rechnen über `ActionBalance.powerScale`.
- **Abgeleitet, nicht gespeichert**, wo es geht — wie Gold, Erfahrung
  und Errungenschaften.
