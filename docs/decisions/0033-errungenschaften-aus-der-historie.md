# ADR-0033: Errungenschaften werden aus der Historie abgeleitet — Meilensteine zahlen, Entdeckungen nicht

**Datum:** 11.09.2026
**Status:** Aktiv
**Entschieden von:** Prozesstek

## Kontext

Issue [#41](https://github.com/Prozesstek/LifesGame/issues/41) beschreibt
Errungenschaften in zwei Teilen, die nicht ohne Weiteres zusammenpassen.

Der erste Teil ist klassisch: Für Errungenschaften gibt es Gold, Erfahrung
und eigene Punkte „ähnlich wie bei GW2", besondere schalten Items oder
Titel frei. Beispiele: „/5, /10, /50 Theorie-Zweige", „/5, /10 Gegner
besiegt", „Shop geöffnet".

Der zweite Teil ist das Gegenteil: Der Spieler soll **nicht** wissen,
welche Errungenschaften es gibt. Er sieht Kategorien mit ???-Plätzen, und
eine Errungenschaft wird erst *entdeckt*, wenn er etwas Besonderes tut —
„Der Frühaufsteher", „Unbeugsam", „Der Stoiker". Sie sollen ein
**Selbstbild** erzeugen („ich bin offensichtlich jemand, der sowas
macht"), bis hin zu einem abgeleiteten Persönlichkeitsprofil
(Herausforderer, Mönch, Alchemist, Mentor, Stratege, Chaosagent). Und über
den Stoiker steht dort: „Du bekommst nichts dafür. …außer Respekt."

Beim Abgleich mit dem Repo fielen fünf Dinge auf:

1. **`konzept.md` führte Errungenschaften unter „Raus für später"**, 3.8
   stellte sie zurück, „bis die zwanzig Fähigkeiten stehen". Die stehen
   seit dem 26.08. (ADR-0022), und alle sechs Bauziele vor dem Teststart
   sind erreicht.
2. **Viele Beispiele brauchen Daten, die der Spielstand nicht hat.** Ein
   Häkchen kennt nur seinen Kalendertag, keine Uhrzeit. Eine Lektion hält
   nur ihr bestes Ergebnis (`LessonRecord.bestCorrect`), die Reihe nur den
   höchsten Sieg (`LadderProgress.highestDefeated`) — Fehlschläge stehen
   nirgends. Bedienung wie „Shop geöffnet" wird nicht festgehalten, und
   „hilft anderen" bräuchte Freunde und damit einen Server.
3. **„Alle Gewohnheiten des Tages erledigt" lässt sich nicht rückwirkend
   bestimmen.** `HabitTracker.isDayComplete` vergleicht mit der *heutigen*
   Liste laufender Gewohnheiten. Welche an einem vergangenen Tag liefen,
   steht nirgends.
4. **Die sieben Titel aus [ADR-0014](0014-titelkatalog-aus-drei-quellen.md)
   sind der Sache nach schon Meilenstein-Errungenschaften** — Schwelle,
   Bedingung im Klartext, verdient statt gewählt.
5. **[ADR-0013](0013-charakter-als-kommandozentrale.md) sieht
   Errungenschaften als Quelle für Fähigkeiten vor** („später, vorerst
   zurückgestellt"). Das Issue erwähnt das nicht.

## Entscheidung

**1. Errungenschaften kommen vor dem Teststart**, als Ziel 8 mit Termin
20.09.2026.

**2. Sie werden aus der Historie abgeleitet.** Welche verdient sind, steht
nicht im Spielstand — es wird aus dem gerechnet, was dort ohnehin steht,
wie Gold, Erfahrung und Titel. Braucht eine Errungenschaft Daten, die es
nicht gibt, wird genau diese Spur einzeln ergänzt, und zwar wieder als
Historie. Für den ersten Satz sind es zwei:

| Spur | Package | ermöglicht |
|---|---|---|
| Niederlagen je Sprosse | `combat` | der Unbeugsame |
| gescheiterte Versuche je Lektion | `theory` | Zweiter Anlauf |

**3. Eine Bedingung hängt nur an Größen, die nie fallen** — die längste
Kette statt der laufenden, „je besessen" statt „gerade getragen", die
höchste Sprosse.

**4. Es gibt zwei Arten.**

| | Meilenstein | Entdeckung |
|---|---|---|
| vorher sichtbar | ja, mit Fortschritt („37 / 50") | nein, als ??? in ihrer Kategorie |
| Erfahrung und Gold | einmalig, nach Stufe | **nie** |
| Ruhm | nach Stufe | 15 |
| Titel | teils | meist |
| Fähigkeit | vier davon | nie |

**5. Die Punkte heißen „Ruhm" und sind nur ein Stand** — eine Zahl auf dem
Charakter, kein Zahlungsmittel.

**6. Titel werden Belohnung von Errungenschaften.** Die Bedingungen der
sieben Titel wandern aus `packages/identity` in die Errungenschaften;
sechs neue Titel kommen aus Entdeckungen dazu.

**7. Die vier Fähigkeiten aus ADR-0017 kommen zurück** — Kraftschlag,
Zehrung, Sammeln, Atemzug —, als Belohnung je eines Meilensteins, einer
je Bereich. `packages/abilities` bekommt dafür eine vierte Quelle,
`FromAchievement`.

**8. Sortiert wird nach Spielbereichen:** Gewohnheiten, Theorie, Kampf,
Laden.

**9. Das Persönlichkeitsprofil aus dem Issue ist kein eigenes System.**
Jeder Typ ist eine Entdeckung mit Titel.

**10. Zuschläge aus dem Entwicklermodus schalten nichts frei.** Es zählt
nur die Historie.

**11. Der Weg führt über den Charakterbildschirm**: eine Karte, dahinter
ein eigener Bildschirm mit vier Reitern wie im Laden. Eine neue
Errungenschaft wird als Blatt gefeiert, wie heute eine neue Fähigkeit.

**12. Ein achtes Package, `packages/achievements`.** Reines Dart, leerer
`dependencies`-Block. Die App reicht die nötigen Zahlen herein, wie bei
`TitleStats` und `AbilityProgress`.

### Der erste Satz

**Belohnung nach Stufe** — die Zahlen stehen an einer Stelle und werden
gegen die übrigen Kurven gemessen:

| Stufe | Erfahrung | Gold | Ruhm |
|---|---|---|---|
| klein | 30 | 10 | 5 |
| mittel | 75 | 25 | 10 |
| groß | 150 | 50 | 25 |
| Entdeckung | — | — | 15 |

M = Meilenstein, E = Entdeckung.

**Gewohnheiten**

| | Name | Bedingung | Stufe | Extra |
|---|---|---|---|---|
| M | Erster Schritt | 1 Häkchen | klein | |
| M | der Entschlossene | 3 Tage am Stück | klein | Titel |
| M | Eigene Handschrift | eine eigene Gewohnheit angelegt | klein | |
| M | der Verlässliche | 50 Häkchen | mittel | Titel |
| M | Durchatmen | 14 Tage mit mindestens 3 Häkchen | mittel | Atemzug |
| M | der Beständige | 30 Tage am Stück | groß | Titel |
| M | der Unermüdliche | 200 Häkchen | groß | Titel |
| M | der Unbeirrbare | 60 Tage am Stück | groß | Titel |
| E | der Mönch | 21 Tage am Stück mit je mindestens 3 Häkchen | | Titel |
| E | der Herausforderer | 30 Häkchen bei schweren eigenen Gewohnheiten | | Titel |
| E | der Stoiker | nach mindestens 3 Tagen Pause eine neue Kette von 7 Tagen | | Titel |

**Theorie**

| | Name | Bedingung | Stufe | Extra |
|---|---|---|---|---|
| M | der Wissbegierige | 5 Lektionen bestanden | klein | Titel |
| M | der Belesene | 12 Lektionen bestanden | mittel | Titel |
| M | Fehlerfrei | 10 Seiten ohne Fehler | mittel | |
| M | Ein Gebiet ganz | ein Gebiet des Baums vollständig bestanden | groß | Zehrung |
| E | der Alchemist | in allen vier Gebieten mindestens einen Knoten bestanden | | Titel |
| E | Zweiter Anlauf | eine Lektion bestanden, an der man vorher gescheitert ist | | neue Spur |

**Kampf**

| | Name | Bedingung | Stufe | Extra |
|---|---|---|---|---|
| M | Erster Sieg | Sprosse 1 | klein | |
| M | Zehn Sprossen | Sprosse 10 | mittel | Kraftschlag |
| M | Zwanzig Sprossen | Sprosse 20 | groß | |
| M | Die Spitze | Sprosse 30 | groß | |
| E | der Unbeugsame | einen Gegner nach 3 Niederlagen gegen ihn doch geschlagen | | Titel, neue Spur |

**Laden**

| | Name | Bedingung | Stufe | Extra |
|---|---|---|---|---|
| M | Erster Kauf | ein Stück je besessen | klein | |
| M | Voll ausgerüstet | auf allen 6 Plätzen je ein Stück besessen | mittel | Sammeln |
| M | Sammler | 15 der 30 Stücke je besessen | groß | |
| E | der Stratege | alle 4 Teile eines Sets je besessen | | Titel |
| E | Kein Blick zurück | ein Stück verkauft | | |

**Zusammen:** 19 Meilensteine, 8 Entdeckungen. Über ein Spielerleben 1680
Erfahrung, 560 Gold und 385 Ruhm — zum Vergleich: Die Reihe gibt 2775
Erfahrung und 1110 Gold (ADR-0032).

**Bewusst nicht im ersten Satz:** der Frühaufsteher (keine Uhrzeit), der
Opportunist (keine Tagesplanung), „Shop geöffnet" (kein
Ereignisprotokoll), der Mentor (keine Freunde), der Chaosagent (nicht
bestimmbar), „/50 Theorie-Zweige" (es gibt 24 Knoten) und „Handbuch
gelesen" — das Handbuch hat genau fünf Lektionen und fiele auf denselben
Moment wie „der Wissbegierige".

## Begründung

**Warum abgeleitet und nicht gezählt.** Es ist dieselbe Entscheidung wie
bei Erfahrung (ADR-0008), Gold (ADR-0011) und Titeln (ADR-0014): Ein
gespeichertes „verdient" könnte von der Historie abweichen, eine Rechnung
aus der Historie nicht. Drei Folgen machen es hier besonders wertvoll:

- **Es wirkt rückwirkend.** Wer beim Einbau schon 40 Häkchen hat, bekommt
  „Erster Schritt" sofort. Damit lässt sich sogar ein Teil während des
  Testlaufs nachliefern, ohne dass jemandem etwas verloren geht.
- **Der Entwicklermodus kann nichts erschleichen.** Er schenkt Summanden,
  keine Historie (ADR-0021).
- **Der Spielstand wächst nicht.** Ein Ereignisprotokoll wüchse täglich
  und bräuchte das Entprellen der Persistenz, das zurückgestellt ist.

**Warum nur Größen, die nie fallen.** Sonst verschwände eine verdiente
Errungenschaft wieder — bei einem Verkauf, einem abgelegten Stück, einer
gerissenen Kette. ADR-0014 hat die Regel für Titel schon festgehalten:
„Mehr Fortschritt nimmt nie einen Titel weg." Deshalb heißt es
„Tage mit mindestens drei Häkchen" statt „Tage mit allem erledigt": Die
zweite Bedingung ist nicht rückwirkend bestimmbar (Kontext, Punkt 3).

**Warum zwei Arten, und warum Entdeckungen nichts zahlen.** Das Issue
begründet Entdeckungen mit Selbstbestimmung und Identität — und genau
dafür ist äußere Belohnung schädlich: Wer für ein Selbstbild bezahlt
wird, lernt, dass es um die Bezahlung ging. Meilensteine sind dagegen
ehrlich Leistung und zahlen deshalb, einmalig, nach demselben Vorbild wie
Lektionen und die Reihe (ADR-0032). So tragen beide Teile des Issues,
ohne sich zu widersprechen.

**Warum Meilensteine sichtbar und Entdeckungen versteckt.** Ein
Meilenstein ohne sichtbaren Abstand ist nur eine Absage — der Laden und
die Titel zeigen deshalb „noch 12 Tage". Eine Entdeckung verliert dagegen
alles, wenn man sie vorher lesen kann. Die ???-Plätze zeigen trotzdem, dass
es etwas zu finden gibt.

**Warum Ruhm nur ein Stand ist.** Er soll Ziel 7 dienen: Zwei Spieler
vergleichen „340 gegen 410", wie „17 / 30" bei der Reihe. Ein
Zahlungsmittel wäre eine fünfte Kurve neben Belohnung, Häkchen, Level und
Preisen, und das Issue verlangt keine. Belohnungen an Ruhm-Schwellen
bleiben möglich, ohne dass etwas umgebaut werden müsste. Der Name ist
bewusst kein „…punkte": Theorie- und Fähigkeitspunkte gibt man aus, Ruhm
nicht.

**Warum Titel Belohnung werden und nicht daneben stehen.** Sonst gäbe es
„30 Tage am Stück" zweimal, als Titel und als Errungenschaft — zwei
Stellen, die dieselbe Frage beantworten (`gotchas.md`). Punkt 4 aus
ADR-0014 gilt unverändert: Der gespeicherte Titel ist eine Wahl und wird
bei jeder Anzeige geprüft; ein bestehender Spielstand bleibt gültig.

**Warum die vier alten Fähigkeiten — obwohl ADR-0024 genau das verworfen
hat.** Dort steht unter den verworfenen Alternativen: „Die vier alten
wieder in den Katalog aufnehmen — macht ADR-0022 rückgängig. Kraftschlag
hat weder Timing-Werte noch Seltenheit noch eine Quelle im Baum." Keiner
der drei Einwände trifft die Lage von heute:

- **ADR-0022 bleibt, wie es ist.** Die fünfzehn aus der Vorlage bleiben
  wählbar; die vier kommen *dazu*, als neunzehnte Wahl.
- **Die fehlende Quelle ist jetzt da** — ein Meilenstein. Dass sie nicht
  am Baum hängen, ist der Sinn: Sie belohnen Kampf, Laden und Beständigkeit,
  wo der Baum Wissen belohnt.
- **Timing und Seltenheit sind Angaben, keine Mechanik.** Ohne eigene
  Werte gilt `TimingSpec.standard`, wie für den Basisangriff, und ohne
  eigenen `perfectFactor` der Deckel aus `balance.dart`. Die Seltenheit ist
  laut `Rarity` „ein Etikett, keine Mechanik" und wird beim Eintrag gesetzt.

Den Ausschlag gibt der Termin: Die vier existieren in `package:combat`
samt Zahlen, die Gegner spielen sie. Es entsteht keine einzige neue
Kampfzahl.

**Warum nach Spielbereichen sortiert wird.** Jede Errungenschaft kommt aus
genau einem Bereich, die Zuordnung ist damit nie strittig, und die vier
Reiter entsprechen den Kreisen des Startbildschirms. Die fünf Kategorien
aus dem Issue (Geist, Körper, Disziplin, Soziales, Abenteuer) erzählen
mehr über die Person — diese Aufgabe übernehmen jetzt die Titel der
Entdeckungen.

**Warum das Profil kein eigenes System ist.** ADR-0013 sagt über Klassen:
abgeleitet, nie gewählt. Eine Entdeckung „der Mönch" *ist* eine
abgeleitete Klasse, samt Titel, den man tragen kann — ohne einen zweiten
Mechanismus, der Anteile über Wochen rechnet.

**Warum vom Charakter aus.** ADR-0013 trennt Start („was ich tue") und
Charakter („wer ich bin") und nennt Errungenschaften ausdrücklich auf der
Seite des Charakters.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Allgemeines Ereignisprotokoll mit Zeitstempeln | Am flexibelsten, aber nicht rückwirkend, der Stand wächst täglich, und es braucht das zurückgestellte Entprellen |
| Gespeicherte Zähler je Errungenschaft | Zweite Wahrheit neben der Historie — die Fehlerquelle, die ADR-0008 und ADR-0011 vermeiden |
| Alle Errungenschaften zahlen Gold, Erfahrung und Punkte | Bezahlt das Selbstbild, gegen die Begründung des Issues selbst |
| Keine zahlt Gold oder Erfahrung | Meilensteine blieben materiell folgenlos, obwohl sie Leistung sind |
| Alles versteckt | Meilensteine ohne sichtbaren Abstand sind Absagen |
| Alles sichtbar | Nimmt den Entdeckungen ihren Sinn |
| Ruhm-Schwellen mit Belohnung (wie GW2-Truhen) | Eine fünfte Kurve ohne Anlass; nachrüstbar |
| Titel und Errungenschaften nebeneinander | Dieselbe Frage an zwei Stellen |
| Items als Belohnung | Braucht nicht kaufbare Stücke, neue Seltenheiten und Ladenregeln; siehe Issue #37, nach dem Teststart |
| Neue Fähigkeiten nach eigener Vorlage | Vorlage, neue Kampfzahlen und Balance in neun Tagen |
| Ein zweiter Weg zu einer der fünfzehn | Wird zur Abkürzung am Baum oder an der Streak vorbei |
| Kategorien aus dem Issue | Zuordnung oft strittig, „Soziales" ohne Freunde fast leer |
| Kategorien nach den vier Wurzeln | Kampf und Laden hätten keinen Platz |
| Eigenes Profilsystem mit Anteilen | Ein zweiter Mechanismus für dieselbe Aussage |
| Ein sechster Kreis auf dem Startbildschirm | Start zeigt, was ich tue, nicht wer ich bin (ADR-0013) |
| Uhrzeit am Häkchen, für den Frühaufsteher | Die größte Formatänderung am Tracker, für eine Errungenschaft; später einzeln |
| Erst nach dem Testlauf bauen | Ziel 7 misst Abbrüche wegen Langeweile — genau dagegen sind sie gedacht |

## Konsequenzen

**Leichter:** Eine neue Errungenschaft ist ein Katalogeintrag, solange die
Zahl, an der sie hängt, schon hereingereicht wird. Weil alles abgeleitet
ist, lässt sich der Satz auch während des Testlaufs erweitern.

**Ein achtes Package.** Die Schichtregel in `CLAUDE.md` bekommt eine Zeile
dazu: Bedingungen und Belohnungen von Errungenschaften nur in
`packages/achievements`.

**ADR-0014 ist teilweise abgelöst.** Punkt 1 (sieben Titel aus drei
Quellen) und Punkt 3 (`identity` bekommt drei Zahlen) gelten nicht mehr in
dieser Form; Punkt 2 (längste Kette) und Punkt 4 (Titel als Wahl) gelten
weiter. `identity` behält Name, Titelwortlaut und die Wahl.

**ADR-0024 bleibt aktiv, aber seine verworfene Alternative ist gewählt.**
Die Entscheidung dort — unbekannte Ids fallen beim Laden heraus — gilt
unverändert. Spielstände, die einen der vier hielten, sind seit dem
26.08. bereinigt; zurück kommt nichts von selbst.

**Die vier Kurven bekommen einen fünften Zufluss.** 1680 Erfahrung und
560 Gold gehen in `totalXpProvider` und den Goldzufluss ein;
`test/progression_test.dart` muss sie mitrechnen. Wer an den Stufen dreht,
lässt ihn laufen.

**Der Spielstand bekommt zwei Felder** — Niederlagen je Sprosse,
gescheiterte Versuche je Lektion. Beide lesen nachsichtig (ADR-0010) und
wirken **nicht** rückwirkend: „Zweiter Anlauf" und „der Unbeugsame"
zählen ab dem Einbau.

**Unangenehm:**

- *Durchatmen* und *der Mönch* messen „mindestens drei Häkchen", nicht
  „alles erledigt". Wer nur drei Gewohnheiten führt, erfüllt beides
  leichter als jemand mit fünf.
- *Kraftschlag* ist mit `power` 2,2 stärker als die frühen Commons. Er
  kommt erst auf Sprosse 10, wenn der Charakter ohnehin trägt — aber
  Balancing bleibt zurückgestellt, und das ist ein Punkt dafür.
- Vom Persönlichkeitsprofil des Issues fehlen Mentor und Chaosagent, von
  den Beispielen der Frühaufsteher und der Opportunist.

**Offen:** Items als Belohnung (zusammen mit Issue #37), Ruhm-Schwellen,
die Uhrzeit als Spur, und welche Seltenheit die vier alten Fähigkeiten
tragen.
