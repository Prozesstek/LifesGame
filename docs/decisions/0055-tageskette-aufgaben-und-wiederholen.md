# ADR-0055: Tageskette, Tagesaufgaben und falsche Antworten wiederholen

**Datum:** 27.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Die Frage war, wie sich das Konzept mit Duolingo als Vorbild verfeinern
lässt — der App, die am besten darin ist, Menschen täglich für ein paar
Minuten zurückzuholen. Vieles davon gab es schon (Streak, Streak-Eis,
Truhe, Erfahrung, Wiederholung in Abständen). Drei Unterschiede waren
groß und billig zu schließen; Frederik hat alle drei gewählt und dazu
entschieden, im Testlauf **weiterzubauen** statt einzufrieren.

## Entscheidung

1. **Eine Tageskette**: Tage am Stück mit mindestens einem Häkchen, egal
   an welcher Gewohnheit. Sie steht als Flamme in „Heute" auf der
   Startseite. Die Ketten je Gewohnheit bleiben für die Multiplikatoren
   und heißen jetzt auch so („Kette je Gewohnheit“, ohne Flamme).
2. **Falsche Antworten kommen am Ende noch einmal**, mit neu gemischten
   Antworten, bis sie sitzen. Gewertet wird weiter der erste Durchgang.
3. **Drei Tagesaufgaben**, aus dem Datum gewürfelt, immer genau eine zum
   Abhaken. Eine erledigte Aufgabe wird mit einem Tipp **abgeholt** und
   bringt einen Schlüssel.

## Begründung

**Die Tageskette ist die eine Zahl, die man schützen will.** Bis hierhin
gab es nur Ketten je Gewohnheit, und wer eine von fünf ausließ, sah eine
reißen, obwohl der Tag geschafft war. Das Streak-Eis gilt für beide
gleich: Ein gedeckter Tag trägt die Kette, verlängert sie aber nicht.
Die Flamme brennt blass, solange heute noch nichts abgehakt ist.

**Die zweite Runde lehrt, sie wertet nicht.** Würde sie zählen, bestünde
jede Seite, und die 60 % aus `TheoryRewards` wären keine Grenze mehr.
Die Antworten werden neu gemischt, sonst wäre die Wiederholung direkt
nach der Auflösung eine Gedächtnisübung für die Stelle.

**Tagesaufgaben geben jedem Tag etwas Eigenes.** `runway_sim` zeigt, dass
Neues in Woche 3 und 4 selten wird; Gewohnheiten zahlen jeden Tag
dasselbe. Die Aufgaben:

| Art | wann möglich |
|---|---|
| Hake 2 Gewohnheiten ab | ab zwei laufenden |
| Hake 3 Gewohnheiten ab | ab drei laufenden |
| Erledige heute alles | ab einer laufenden |
| Hol nach, was gestern liegen blieb: *Name* | eine laufende blieb gestern offen |
| Beantworte die Rückfrage richtig | es gibt heute eine |

Nie zwei zum Abhaken zugleich — „Hake 2“ neben „Hake 3“ wäre eine
Aufgabe in zwei Zeilen.

**Keine Aufgabe aus der Grube.** Eine Aufgabe bringt einen Schlüssel, und
die Zahl der Schlüssel soll nur an Gewohnheiten und Theorie hängen
(ADR-0048): Wer mehr spielt, darf, wird dadurch aber nicht stärker.

**Abholen statt automatisch.** Der Tipp, bei dem der Schlüssel aufsteigt,
ist die Belohnung — wie das Öffnen der Tagestruhe. Gespeichert wird nur
das Abholen (`quests` im Habit-Tracker), eine Historie wie die
geöffneten Truhen.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Ketten je Gewohnheit abschaffen | An ihnen hängen Multiplikatoren, Titel und Errungenschaften |
| Zweite Runde zählt mit | Jede Seite bestünde |
| „Lies eine Seite“ als Aufgabe | Bestandene Seiten haben kein Datum; ob heute gelesen wurde, ist nicht ableitbar |
| Aufgaben aus der Grube | Verletzte ADR-0048: Schlüssel aus dem Spielen |
| Gold und Erfahrung als Belohnung | Drei Zufluss-Provider und vier Kurven; ein Schlüssel ist eine Stelle |
| Aufgaben beim ersten Blick einfrieren | Bräuchte einen weiteren gespeicherten Stand; siehe Konsequenzen |

## Konsequenzen

- Die Auswahl hängt am Datum **und** daran, was gerade läuft. Wer mitten
  am Tag eine dritte Gewohnheit startet, kann eine andere Mischung
  sehen. Was schon abgeholt ist, bleibt abgeholt.
- „Liegen geblieben“ kennt nicht, wann eine Gewohnheit gestartet wurde:
  Eine heute gestartete gilt auch als gestern offen.
- Ein Schlüssel mehr je Aufgabe, also höchstens drei am Tag zusätzlich.
  Der Vorrat bleibt bei zehn gedeckelt.
- Nebenbei behoben: Die Namen der Werte brachen auf dem
  Gewohnheiten-Bildschirm mit echter Schrift mitten im Wort um.
