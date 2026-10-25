# ADR-0088: Der Kampfwert folgt dem Gebiet

**Datum:** 25.10.2026
**Status:** Aktiv
**Entschieden von:** Prozesstek

## Kontext

Frederik wollte das Anlegen einer Gewohnheit entschlacken: ein grüner
Plus-Knopf, danach eine Frage nach der anderen, „damit es nicht so
erschlagend wirkt“. Dazu die Frage: „Können wir irgendwelche von diesen
Fragen noch wegmachen, weil sie sich doppeln?“

Das Formular fragte zwei Dinge, die sich für den Spieler wie eine Frage
anhören — „Worauf zahlt es ein?“ (der Wert: Stärke, Ausdauer, Disziplin,
Klarheit) und „Zu welchem Gebiet gehört es?“ (Körper, Geist,
Wissenschaft, Gesellschaft, ADR-0085). Gemeint war Verschiedenes: Der
Wert macht in der Grube stärker, das Gebiet lässt den Skill wachsen.
Ableiten ließ sich keins aus dem anderen; in ADR-0085 war das Ableiten
des Gebiets aus dem Wert verworfen worden, weil eine soziale Gewohnheit
sonst in Geist landete.

Frederik, auf drei Vorschläge, die beide Fragen auf einem Blatt
verbanden: „Können wir nicht sagen abhängig von Gebiet wird ein anderer
Kampfwert erhöht?“

Dazu hatte jeder Wert zwei Namen — einen im Alltag (Stärke) und einen
im Kampf (Angriff) —, und die Tagesform übersetzte den zweiten noch
einmal („Klarheit füllt in der Grube das Mana“). Am 24.10. hatten Nutzer
die Intuitivität beklagt, und „zu viele Begriffe“ stand dort als
Vermutung.

## Entscheidung

**Das Gebiet bestimmt den Kampfwert**: Körper → Angriff, Geist → Mana,
Wissenschaft → Abwehr, Gesellschaft → Leben. Wählen lässt er sich nicht
mehr. Die Regel gilt **für alle Gewohnheiten und rückwirkend** — für
Vorlagen, eigene und jedes Häkchen der Vergangenheit. Auf den
Bildschirmen heißen die Werte nur noch Angriff, Leben, Abwehr und Mana.

## Begründung

**Eine Frage weniger, ein Begriff weniger.** Das Gebiet ist die Frage,
die ein Spieler beantworten kann („Sport ist Körper“); welcher von vier
Kampfwerten zu „Freund anrufen“ passt, kann er nicht wissen. Und ein
Wert, der heißt, was er tut, braucht keine Übersetzung.

**Breite wird belohnt.** Jeder Wert ist nach 35 bis 40 Häkchen
gedeckelt (`StatCurve`). Es zählt also vor allem, *ob* jemand in einem
Gebiet eine Gewohnheit hat. Wer in allen vier lebt, ist im Kampf rund —
dieselbe Aussage, die die vier Wurzeln des Baums machen.

**Die Zuordnung**, wie sie sich erklärt: Wer trainiert, schlägt härter.
Ein klarer Kopf treibt die Fähigkeiten an. Wer versteht, sieht den
Schlag kommen. Freunde halten dich am Leben.

**Rückwirkend** (Frederiks Wahl, gegen Claudes Empfehlung „ab einem
Stichtag, Bisheriges bleibt“): Eine Regel mit Stichtag hätte zwei
Rechnungen gebraucht und wäre in keinem Stand ganz sichtbar gewesen.
Weil `Habit.stat` ohnehin aus der Historie gerechnet wird (ADR-0008),
ist rückwirkend die einfachste Form: Der Wert wird nicht mehr
gespeichert, sondern aus dem Gebiet gelesen.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Gebiet groß, Kampfwert klein darunter, vorgewählt | Claudes erste Empfehlung: alle 16 Paare möglich, meist ein Tipp. Bleibt aber zwei Fragen, und der Spieler muss die Zuordnung trotzdem verstehen |
| Acht Paare zum Antippen | ein Tipp, aber die Hälfte der Paare fiele weg, ohne dass eine Regel sie erklärt |
| Raster 4 × 4 | volle Freiheit, sieht aus wie eine Tabelle |
| Körper → Leben, Gesellschaft → Angriff | passte zu 6 statt 4 der 11 Vorlagen, aber „Mut“ als Angriff aus Gesellschaft ist schwerer zu erraten als „Freunde halten dich am Leben“ |
| Geist → Abwehr, Wissenschaft → Mana | „Willenskraft schützt, Wissen ist Magie“ — gleich gut erklärbar, aber Geist hat fünf Vorlagen, und Mana trägt die Fähigkeiten |
| Ab einem Stichtag, Bisheriges bleibt | Claudes Empfehlung, damit kein Wert fällt. Frederik: rückwirkend |
| Nur für neue eigene Gewohnheiten | zwei Gewohnheiten im selben Gebiet könnten Verschiedenes stärken; die Regel ließe sich nicht lernen |
| Die alten Namen behalten | eine soziale Gewohnheit hätte dann „Ausdauer“ gesteigert |

## Konsequenzen

- **Die Zuordnung steht an einer Stelle**: `SkillArea.kampfwert`, die
  Umkehrung in `HabitStat.gebiet`. `HabitTemplate` trägt keinen Wert
  mehr, `CustomHabit` nur noch `statOhneGebiet` — den Wert, den eine
  Gewohnheit aus der Zeit vor ADR-0085 hatte, bis die Startseite einmal
  nach ihrem Gebiet fragt. Gespeichert wird weiter `stat` (der Wert, der
  gilt), damit ein älterer Stand der App den Eintrag nicht verwirft.
- **7 der 11 Vorlagen steigern jetzt einen anderen Wert**: Feste
  Aufstehzeit und Wasser vor jeder Mahlzeit Angriff statt Leben; Drei
  Aufgaben und Abendnotiz Mana statt Abwehr; Eine Messgröße notieren
  Abwehr statt Mana; Eine echte Frage und Vor jeder Zusage durchatmen
  Leben statt Angriff bzw. Abwehr.
- **Bestehende Stände verschieben sich.** Wer keine Gewohnheit in
  Gesellschaft hat, verliert seinen Lebensbonus (bis +64, im Kampf
  ×10), wer keine in Wissenschaft hat, seinen Abwehrbonus. Angriff und
  Mana kommen dazu, aber sie sind gedeckelt. Level, Skills, Titel und
  Errungenschaften hängen nicht am Wert.
- **Abwehr kommt nur aus Wissenschaft**, und dort gibt es eine einzige
  Vorlage. Wer Abwehr will, braucht eine eigene Gewohnheit dort.
- **Die Startseite fragt bei alten Gewohnheiten ohne Gebiet** jetzt
  auch nach dem Kampfwert: Die Antwort verschiebt ihre Historie in Skill
  **und** Wert.
- **Die Simulation der Grube rechnet etwa eine Stufe schwächer.** Ihr
  Bot hakt die ersten fünf Vorlagen ab — drei aus Geist, zwei aus
  Körper. Bis dahin steigerten sie alle vier Werte, jetzt nur noch
  Angriff und Mana. Gemessen mit `dart run tool/pit_sim.dart`, zwölf
  Läufe je Feld, die tiefste Stufe, die der Bot mindestens jedes zweite
  Mal schafft:

  | Held | vorher | jetzt |
  |---|---|---|
  | Tag 14 | 6 | 6 (Stufe 7: 42 % statt 8 %) |
  | Tag 30 | 10 | 9 |
  | Tag 30 in Form | 12 | 11 |
  | Tag 60 mit Ausrüstung | 25 | 24 |
  | Tag 60, Ausrüstung, in Form | 28 | 28 |
  | Level 50 | 39 | 38 |

  Früh ist er stärker, weil zwei Gewohnheiten auf den Angriff zahlen;
  ab Tag 30 fehlen Leben und Abwehr. Wer in Gesellschaft und
  Wissenschaft je eine Gewohnheit hat, steht besser da als vorher. Nicht
  nachgestellt — die Simulation bildet weiter den Spieler ab, der die
  ersten fünf Vorlagen nimmt.
- `HabitStat.combatLabel` und `DailyFormText.pitNameOf` sind weg; der
  Name steht in `HabitStat.label`.
- **Die Ausrüstung spricht weiter von „Lebenspunkte“, „Verteidigung“ und
  „Energie“** (`copy_text.dart`, `gear_sheet.dart`). Das war schon vorher
  so (Tagesform sagte „Leben“) und ist nicht Teil dieser Entscheidung.
