# ADR-0072: Die Tagesgrube — eine Grube für alle, ein Versuch am Tag; die Dailies gehen

**Datum:** 11.10.2026
**Status:** Aktiv — löst [ADR-0040](0040-vier-dailies-je-tag.md) ab
**Entschieden von:** Frederik, in zwei Fragerunden

## Kontext

[ADR-0071](0071-das-naechste-level.md) hält fünf Ideen fest, die nach und
nach gebaut werden, jede nach ihrer eigenen Konzeptrunde. Die Tagesgrube
ist die erste: Sie zielt auf den Grund „niemand erfährt davon“ und
beantwortet am billigsten, ob sich das Spiel verbreitet. Die Vorlage
[`das-naechste-level.md`](../vorlagen/das-naechste-level.md) stellt dafür
sieben Fragen.

**Was der Code schon hatte.** Karte, Wächter und Besetzung einer Grube
kommen aus einem Startwert (`LevelBuilder.build`); nur
`PitScreen._neuerLauf` würfelt ihn frei. Aus dem Datum gewürfelt wurde
schon für Truhe, Laden und Dailies. Ruhm gab es als reinen
Vergleichsstand, bis dahin nur aus Errungenschaften und höchstens 385.

**Was der Bot gemessen hat.** Ein fester Held mit den Werten eines
fleißigen Spielers an Tag 30 (Level 15, ohne Ausrüstung), Kurzbogen und
drei Fähigkeiten, 24 Läufe je Feld:

| Stufe | ohne Aufschlag | +10 % | +25 % |
|---|---|---|---|
| 11 | 92 % | 100 % | 100 % |
| 12 | 58 % | 96 % | 100 % |
| 13 | 8 % | 71 % | 96 % |
| 14 | 0 % | 17 % | 79 % |

Die Grube hat eine **scharfe Kante**: Zwei Stufen trennen „fast immer“
von „fast nie“, und ein Aufschlag auf die Werte dreht das Ergebnis. Die
Waffe verschiebt die Quote mäßig (Stufe 12: 58 % bis 96 %), der Satz
Fähigkeiten stark (dieselbe Stufe: 0 % bis 58 %). Ein Sieg dauert dem
Bot rund eine Minute.

**Was die Dailies brachten.** Einem fleißigen Spieler überschlagen ein
Fünftel von Erfahrung und Gold, für vier Läufe am Tag.

## Entscheidung

**Jeden Tag gibt es eine Grube, die für alle dieselbe ist, und jeder hat
einen Versuch.** Die vier Stufen des Tages aus ADR-0040 gibt es nicht
mehr.

| Frage | Entschieden |
|---|---|
| Die Karte | aus dem Datum: Startwert, daraus Karte, Wächter und Besetzung |
| Der Held | für alle derselbe; je **Wochentag ein fester Satz** aus Waffe und drei Fähigkeiten, jeder mit eigener, gemessener Stufe |
| Die Form | **ja oder nein**: alles Fällige von heute erledigt gibt +25 % auf Angriff, Leben, Abwehr und Mana — ob eine Gewohnheit oder fünf |
| Ein Ruhetag | ohne Aufschlag, aber mit eigenem Namen im Text (wie ADR-0064) |
| Ein Versuch | **zählt mit dem Start**; wer die App mitten im Lauf schließt, hat abgebrochen |
| Ab wann offen | nach dem ersten Lauf in der Grube, dann jeden Tag von Anfang an |
| Was sie bringt | **nur Ruhm**: antreten 1, Sieg 3, Sieg in Form 5 |
| Die Dailies | **gehen jetzt** |
| Der Text | mit Raumzeile, zum Kopieren |

```
Lifes Game · Tagesgrube #12
🟩🟩🟨🟥👑 1:04
⚡ In Form · 🔥 12 Tage
prozesstek.de/LifesGame
```

Frederik hat achtmal entschieden, siebenmal wie empfohlen. Bei den
Dailies gegen die Empfehlung: Sie lautete, sie eine Woche neben der
Tagesgrube stehen zu lassen und dann mit Zahlen zu entscheiden.

**Die sieben Sätze**, jeder mit der Stufe, auf der der Bot ohne Form
etwa jeden zweiten Lauf gewinnt und in Form fast jeden (40 Läufe je
Feld, `tool/tagesgrube_sim.dart`):

| Tag | Waffe | Fähigkeiten | Stufe | ohne Form | in Form |
|---|---|---|---|---|---|
| Montag | Kurzbogen | Funkenstoß, Steinhaut, Blütentau | 12 | 53 % | 100 % |
| Dienstag | Zweihänder | Klingenwirbel, Wurzelgriff, Sammeln | 12 | 55 % | 100 % |
| Mittwoch | Langbogen | Donnerkeil, Frostnebel, Aurastrom | 12 | 45 % | 100 % |
| Donnerstag | Kriegsstab | Seelenraub, Giftmoor, Atemzug | 12 | 78 % | 100 % |
| Freitag | Geschliffene Klinge | Zehrung, Sandsturm, Prisma-Barriere | 11 | 73 % | 100 % |
| Samstag | Streitkolben | Kraftschlag, Vulkanbruch, Steinhaut | 13 | 50 % | 100 % |
| Sonntag | Sonnenklinge | Sternenfall, Zeitdehnung, Blütentau | 13 | 20 % | 100 % |

Zusammen alle neunzehn Fähigkeiten, zwei davon doppelt, und sieben der
acht Waffen.

**Ohne Rückfrage entschieden**, weil es sonst nicht aufgeht:

- **Alte Stände behalten, was ihre Dailies gezahlt haben.** Die Historie
  bleibt gespeichert und zählt weiter, sonst fiele nachträglich ein
  Level. Neues kommt dort nicht mehr an.
- **Der fehlende Zufluss wird nicht ausgeglichen.** Das wäre Balance,
  und die ist zurückgestellt. Gemessen ist er, siehe Konsequenzen.
- **Der Einheitsheld** hat die Werte eines fleißigen Spielers an Tag 30.
  Für einen Neuen ist er stärker als der eigene, für einen Veteranen
  schwächer.
- **Die Verfassung und der Tag gelten vom Hinabsteigen.** Wer danach
  abhakt, war beim Kampf trotzdem nicht in Form; wer um 23:59
  hinabsteigt und um 00:01 gewinnt, hat gestern gewonnen.
- **Nur wer ohne Form hinab will, wird gefragt.** Das ist der eine
  Augenblick, in dem der Hinweis „erst abhaken“ etwas ändert.
- **„Zurück“ mitten im Lauf fragt nach**, und der Lauf hält solange an.
  Wer aufgibt, hat abgebrochen.
- **Auch ein abgebrochener Versuch bringt den Ruhm des Antretens.**
- **Kein zweiter Lauf zum Üben.** Für mehr gibt es die dreißig Stufen.
- **Der Text**: laufende Nummer statt Datum (die erste am 11.10.2026),
  die Adresse des Spiels am Ende, ein Sieg mit Zeit, eine Niederlage
  ohne. „Ohne Form“ steht nicht darin; der Text sagt, was war.
- **Die Raumzeile**: ein Feld je Raum vor dem Wächter, grün unter 10 %
  des vollen Lebens verloren, gelb unter 30 %, sonst rot; am Ende Pokal,
  Kreuz oder abgelaufene Uhr. Der Startraum steht nicht darin, was dort
  ankam, zählt zum ersten Raum.
- **Geteilt wird über die Zwischenablage**, ohne weiteres Paket.
- **Sie steht im Eingang der Grube ganz oben**, dort wo die Sterne der
  Dailies waren.
- **Der Entwicklermodus gibt den Versuch von heute wieder frei.**

## Begründung

**Derselbe Held, weil sonst verglichen würde, wer länger spielt.** Das
stand schon in ADR-0071. Offen war nur, womit er kämpft.

**Sätze je Wochentag statt frei gewürfelt, wegen der Messung oben.** Ein
frei gewürfelter Satz verschiebt die Siegquote auf derselben Stufe von
0 % auf 58 %. Dann entschiede an manchen Tagen der Satz und nicht die
Form. Sieben feste Sätze lassen sich einzeln messen und bekommen jeder
die Stufe, auf der sie gleich schwer sind. Und man lernt seinen
Dienstag.

**Die Form als Ja oder Nein, weil nur das zwischen einer Gewohnheit und
fünf fair ist.** Die Tagesform der Grube (ADR-0043) hebt je Häkchen
ihren Wert; wer mehr Gewohnheiten hat, wäre stärker. Ein Viertel reicht
als Aufschlag, weil die Kante so scharf ist: Auf der gesetzten Stufe
gewinnt der Bot ohne Form im Mittel jeden zweiten Lauf, in Form jeden.

**Der Versuch zählt mit dem Start, weil er sonst im Browser nicht
zählt.** Zählte er erst mit dem Ende, reichte Neuladen, sobald es
schlecht läuft. Technisch fällt das von selbst heraus: Der Eintrag steht
ab dem Hinabsteigen als „abgebrochen“ da und wird am Ende überschrieben.
Ein Tag hat nur einen Eintrag, also gibt es keinen Platz für einen
zweiten Versuch.

**Nur Ruhm, weil kein Kampf zur Dauerquelle werden soll** (ADR-0032) und
weil eine Niederlage bei nur einem Versuch sonst echten Fortschritt
kostete. Ruhm ist ein Stand zum Vergleichen, kein Zahlungsmittel
(ADR-0033); auch die Niederlage bringt einen, damit Antreten nie umsonst
ist.

**Die Dailies gehen, weil der Grundsatz aus ADR-0071 „weniger Systeme“
heißt.** Die Tagesgrube ist der eine Kampf des Tages; vier weitere
daneben wären die Pflicht, die sie ablösen soll.

**Die Raumzeile, weil sie den Lauf erzählt, ohne die Karte zu verraten.**
Sie ist der Teil, der im Gruppenchat wie Wordle aussieht.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Waffe und Fähigkeiten jeden Tag frei gewürfelt | die Schwierigkeit schwankt stärker, als die Form ausgleicht (0 % bis 58 % auf derselben Stufe) |
| Immer derselbe Held | am genauesten zu messen, aber jeder Tag wäre derselbe Kampf auf anderer Karte |
| Die Form anteilig (drei von fünf erledigt) | im Text stünde ein Bruch statt eines Blitzes; „alles Fällige“ ist dieselbe Regel wie bei der Truhe |
| Die normale Tagesform, je Häkchen +10 % | wer fünf Gewohnheiten hat, wäre stärker als wer eine hat |
| Ein Ruhetag zählt als in Form | die erste Ausnahme von ADR-0064; wer wenig plant, hätte öfter den Aufschlag |
| Der Versuch zählt erst mit dem Ende | Neuladen wäre ein zweiter Versuch |
| Ein Abbruch am Tag ist frei | erlaubt genau den einen Neustart, den die Regel verhindern soll |
| Die Dailies bleiben vorerst (die Empfehlung) | fünf Kämpfe am Tag statt einem; Frederik wollte die Pflicht sofort senken |
| Die Tagesgrube zahlt, was die Dailies zahlten | eine Niederlage kostete Erfahrung und Gold, bei nur einem Versuch |
| Erst mit einem Häkchen heute offen | an einem Ruhetag wäre sie zu |
| Schon mit dem ersten Häkchen offen | der eine Versuch ginge beim Lernen der Steuerung verloren |
| Der Text mit Herzen oder als eine Zeile | erzählt nur das Ende, nicht den Lauf |
| Kein Ruhm, eigene Zahlen | ein drittes Zählwerk neben Ruhm und Stufen |
| Das Teilen-Blatt des Geräts | braucht ein weiteres Paket und ist am Rechner schlechter als die Zwischenablage |

## Konsequenzen

- **Rund ein Viertel weniger Gold, vier Level weniger nach zwei
  Monaten.** `runway_sim`, fleißiger Spieler, vorher und nachher:

  | Tag | Level | Seiten | Gold |
  |---|---|---|---|
  | 30 | 21 → 18 | 28 → 26 | 2482 → 1991 |
  | 60 | 33 → 29 | 41 → 37 | 5759 → 4286 |

  Die Reichweite in der Grube ist in dieser Rechnung fest; mit weniger
  Leveln dürfte sie etwas später steigen. Die Kurven-Tests
  (`progression_test.dart`) zählten die Dailies nie mit und bleiben
  grün.
- **Schlüssel werden nicht mehr nebenbei verbraucht.** Bisher fiel Beute
  bei den vier Dailies; jetzt muss man dafür eine geschaffte Stufe von
  sich aus noch einmal spielen.
- **Ruhm misst künftig vor allem, wer dranbleibt.** In zwei Monaten
  bringt die Tagesgrube bis zu 300, fast so viel wie alle
  Errungenschaften zusammen.
- **Die Stufen sind grob.** Zwischen zwei Stufen liegt mehr als der
  Abstand zwischen den Sätzen; ohne Form reicht die Spanne von 20 %
  (Sonntag) bis 78 % (Donnerstag). Genauer geht es nur über die Werte
  des Helden je Satz.
- **Wie schwer sie für Menschen ist, weiß niemand.** Der Bot ist eine
  untere Schranke, und Fähigkeiten, die man zielen muss, unterschätzt
  er.
- **Wer den Bau der Grube ändert, ändert die Tagesgrube mit**: Räume,
  Besetzung, Würfel. Ein Test hält die Karte eines Tages fest und läuft
  auch im Browser (`dart test -p chrome`), damit „dieselbe Grube“ auf
  jedem Gerät gilt. Ein Deploy mitten am Tag kann sie für den Rest des
  Tages verändern.
- **Ein Versuch ist eine Vereinbarung, keine Sperre.** Ohne Server lässt
  er sich umgehen (Browserdaten löschen, Stand einfügen), wie ein
  Häkchen eine Behauptung ist. Verglichen wird unter Leuten, die sich
  kennen.
- **„Heute“ ist der Tag am eigenen Ort.** Zwei in verschiedenen
  Zeitzonen haben zeitweise verschiedene Gruben.
- **Der Spielstand wächst** um einen kurzen Eintrag je gespieltem Tag.
- **Die Karte kennt jetzt ihre Räume** (`Level.rooms`), und die Welt
  zählt, was der Held je Raum verliert (`ActionWorld.damageByRoom`).
  Beides steht jedem Lauf offen, nicht nur der Tagesgrube.
- **Die Messlatte aus ADR-0071** — zehn Fremde, nach zwei Wochen teilen
  noch drei — ist damit prüfbar, aber noch kein Ziel: Sie braucht einen
  Termin und Frederiks Bestätigung.
