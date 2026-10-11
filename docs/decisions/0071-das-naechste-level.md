# ADR-0071: Das nächste Level — fünf Ideen, nach und nach

**Datum:** 09.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik, auf einen Vorschlag von Claude

## Kontext

Frederik fragte am 08.10.: „Was würdest du machen, um unser Konzept auf
das nächste Level zu bringen und garantiert Erfolg zu haben? Sei ruhig
kreativ.“

Der Stand: Die Durchsicht vom 02.10. (`state.md`) hatte gefunden, dass
es nicht am Spiel scheitert, sondern an allem drumherum. Zwei ihrer
Punkte sind seitdem gebaut, der erste Kampf in den ersten Minuten
([ADR-0068](0068-erster-start-deckt-die-bereiche-auf.md)) und der
Wochenplan ([ADR-0064](0064-wochenplan-und-kette-die-faellt.md)). Die
großen übrigen hat Frederik zurückgestellt: am 27.09. die Erinnerung, am
02.10. die App — „zuerst wird das Konzept weiter ausgebaut“.

Offen blieben damit die drei Gründe, an denen Habit-Apps meistens
scheitern:

- **Niemand erfährt davon.** Es gibt keinen Weg, das Spiel jemandem zu
  zeigen.
- **Die tägliche Pflicht wird zu schwer.** Abhaken, Truhe, Aufgaben,
  Rückfrage, vier Dailies, Laden — alles verfällt um Mitternacht.
- **Irgendwann ist alles gesehen.** Dreißig Stufen zahlen je einmal, und
  der Baum wächst nur so schnell, wie geschrieben wird.

Und ein vierter, eigener: **zwölf Systeme**, die nebeneinanderstehen,
ohne eine Geschichte, die sie verbindet.

## Entscheidung

**Fünf Ideen werden gebaut, nach und nach:**

| Idee | in einem Satz | gegen |
|---|---|---|
| **Tagesgrube** | dieselbe Grube für alle, aus dem Datum gesät, ein Versuch, ein Einheitsheld; stärker macht nur, ob man heute in Form ist; danach ein Text zum Teilen, wie bei Wordle | niemand erfährt davon |
| **Lagerfeuer** | abends eine Minute für Rückfrage, Truhe, Aufgaben und Wochenrückblick; zum Schluss, was morgen zuerst drankommt | die tägliche Pflicht |
| **Schatten** | ganz unten wartet man selbst, wie man vor 30 Tagen war; die vier Wächter werden innere Gegner | Systeme ohne Geschichte |
| **Saisons** | sechs Wochen, ein Thema aus einem gelesenen Buch: Seiten, Vorlagen, ein Wächter, etwas fürs Haus | irgendwann ist alles gesehen |
| **Seilschaft** | zwei bis vier an einem Seil; wer einen fälligen Tag verpasst, wird einmal die Woche gehalten | allein aufhören |

**Die Positionierung:** das Spiel, das dich wegschickt. Ein Versuch am
Tag, ein Feuer am Abend.

**Der Grundsatz:** weniger Systeme, die enger zusammenhängen. Was
dazukommt, bündelt oder ersetzt Vorhandenes.

Frederik: „finde alle Ideen super, halt die auf jeden Fall fest, das
bauen wir nach und nach.“ **Entschieden ist die Richtung, nicht die
Einzelheiten.** Jede Idee bekommt vor dem Bau ihre eigene Konzeptrunde
und dort ihren ADR. Die Einzelheiten und die Fragen dafür stehen in der
Vorlage [`docs/vorlagen/das-naechste-level.md`](../vorlagen/das-naechste-level.md);
was sie an Zahlen und Regeln nennt, ist ein Vorschlag.

## Begründung

**Jede Idee zielt auf einen Grund, und vier bauen auf Vorhandenem:**

- Die **Tagesgrube** braucht keine neue Welt. Die Grube ist gesät,
  Karte, Wächter und Besetzung kommen aus dem Startwert
  (`LevelBuilder.build`). Das Datum würfelt schon Truhe, Laden und
  Dailies, und Ruhm gibt es als reinen Vergleichsstand. Neu sind ein
  Startwert aus dem Datum, ein fester Held und ein Text.
- Das **Lagerfeuer** erfindet nichts. Es sammelt Rückfrage, Truhe,
  Aufgaben und Wochenrückblick an einer Stelle.
- Der **Schatten** nutzt, was nur dieses Spiel hat: Alles wird aus der
  Historie gerechnet.
- Die **Saisons** geben dem Schreiben einen Takt, den
  [ADR-0061](0061-der-baum-waechst-aus-dem-gelesenen.md) schon angelegt
  hat: Aus dem Gelesenen wird Theorie.
- Nur die **Seilschaft** ist neu, und sie ist der Teil, den `konzept.md`
  3.9 seit dem ersten Entwurf vorsieht.

**Die Tagesgrube zuerst**, weil sie die wichtigste offene Frage am
billigsten beantwortet: ob sich das Spiel verbreitet. Sie macht „Fremde
als Tester“ aus der Durchsicht möglich, ohne Store und ohne Konto — die
Web-Fassung reicht.

**Die Positionierung, weil sie schon der Kern des Produkts ist:** Der
Kampf ist die Auszahlung des Fortschritts, nicht seine Quelle
(`konzept.md` Abschnitt 2). Ein Spiel, das einen Versuch am Tag gibt und
abends wegschickt, sagt das in einem Satz. Damit hebt es sich von allem
ab, was auf Bildschirmzeit optimiert ist.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Zuerst Konto, Erinnerung und Android-App, wie in der Durchsicht vom 02.10. vorgeschlagen | Frederik hat Erinnerung (27.09.) und App (02.10.) zurückgestellt; die Tagesgrube braucht keins davon |
| Weitere Systeme einzeln, wie sie einfallen | wiederholt den Befund „zwölf Systeme ohne Geschichte“ |
| Rangliste der Tagesgrube auf einem Server | Wordle kam ohne aus; ob sich das Spiel verbreitet, zeigt ein kopierter Text |
| Tagesgrube mit dem eigenen Helden | verglichen würde, wer länger spielt, nicht wer heute dran war |
| Eine Gruppe, die Fehltage bestraft (wie Habitica) | Scham statt Halt; die Kette fällt seit ADR-0064 bewusst nur eine Stufe |

## Konsequenzen

- **Kein neues Ziel, kein Termin.** Ein Termin entsteht in der
  Konzeptrunde jeder Idee; die Messlatte der Tagesgrube wird dann ein
  Ziel in `ziele.md`.
- **Die vier Dailies stehen zur Wahl**
  ([ADR-0040](0040-vier-dailies-je-tag.md)): Die Vorlage schlägt vor,
  dass sie in der Tagesgrube aufgehen. Das braucht einen eigenen ADR und
  eine neue Rechnung des Zuflusses.
- **Der erste Server** kommt mit der Seilschaft, und mit ihm Konto und
  Datenschutz. [ADR-0010](0010-persistenz-hinter-einem-anschluss.md),
  offline-first, bekommt dann seine erste Ausnahme.
- **Die Wächter bekommen eine zweite Bedeutung**, sobald der Schatten
  kommt; ihre Namen und Zeilen stehen in `BossText`.
- **Saisons sind ein Takt**: alle sechs Wochen Seiten, Vorlagen, ein
  Wächter und etwas fürs Haus. Das ist die Schreibseite, die
  `konzept.md` 3.3 das größte Risiko des Projekts nennt.
- **Der Schatten kann nicht am Level von vor 30 Tagen hängen**, solange
  bestandene Seiten und erste Siege kein Datum tragen. Und die Werte von
  damals reichen nicht, weil sie gedeckelt sind. Die Vorlage schlägt
  vor: alles, was man heute hat, außer den Gewohnheiten der letzten 30
  Tage.

### Offen

- Die **Reihenfolge** (Tagesgrube, Lagerfeuer, Schatten, Saisons,
  Seilschaft) und die **Messlatte** (zehn Fremde, zwei Wochen, drei
  teilen noch) sind Claudes Vorschlag, nicht ausdrücklich bestätigt.
- Woher die zehn Fremden kommen.
- AktivesBrett hat das nicht gesehen.
