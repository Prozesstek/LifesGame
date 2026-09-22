# ADR-0041: Erfahrung und Gold fallen je Gegner — derselbe Topf, anders ausgeschüttet

**Datum:** 22.09.2026
**Status:** Aktiv
**Entschieden von:** Prozesstek

## Kontext

Frederik: „Geil wäre, wenn man die XP und Gold pro Gegner bekommt,
dadurch fühlt sich das Kämpfen belohnender an. Genauso viel XP und Gold
wie der Abschluss jetzt geben würde, nur halt anders ausgegeben."

Bis dahin zahlte eine Stufe beim ersten Sieg ihren Betrag auf einmal,
nach dem Lauf, im Ergebnisblatt (ADR-0032); ein Daily sein Viertel
(ADR-0040). Während des Laufs fiel nichts. Und seit dem 22.09. ist der
Lauf mit dem Wächter geschafft — wer nicht jeden Gegner fällt, fällt
nicht jeden Anteil.

Die Schwierigkeit steckt in „genauso viel": Zahlt jeder Gegner, und
gilt das auch in einem verlorenen Lauf, wird aus dem Kampf eine
wiederholbare Quelle — genau das, was ADR-0032 ausgeschlossen hat.

## Entscheidung

Jede Stufe hat einen **Topf**: ihren Erstsieg-Betrag, als Daily ihr
Viertel. Die Welt schüttet ihn je Kill aus — 70 % gleich verteilt auf
alle Gegner ausser dem Wächter, der Wächter füllt den Topf auf. **Ein
verlorener Lauf behält, was gefallen ist**; der nächste Versuch kann nur
noch den Rest einsammeln. In der Summe zahlt jede Stufe genau ihren
Topf, nie mehr.

## Begründung

**Der Topf hält die Summe fest.** Die Reihe merkt sich, was aus einem
angebrochenen Topf schon gezahlt ist (`LadderProgress.partial`,
`dailyPartial`), und reicht der Welt nur den Rest
(`LadderProgress.potFor`). Mehr als der Topf zählt nie; was die Welt
meldet, wird gekappt (`bookRun`). Damit ist Grinden unmöglich, und
`LadderRewards.lifetimeXp` stimmt weiter.

**Verlieren kostet nichts, was man schon hatte.** Die naheliegende
Alternative — alles erst beim Sieg gutschreiben, die Zahlen nur zeigen —
hätte gesammelte Beute beim Tod wieder genommen. Das fühlt sich wie
Strafe an, und das Konzept schliesst Strafe fürs Scheitern aus
(`konzept.md` 3.7).

**Der Wächter füllt auf.** Mit ihm ist die Grube geschafft. Wer ihn
fällt, bekommt alles, auch den Teil der Gegner, an denen er vorbeigelaufen
ist — sonst hiesse „gewonnen" je nach Laufweg etwas anderes.

**Gerechnet als Stand, nicht als Häppchen.** Nach k von n Gegnern ist
genau `k/n` des Fussvolk-Anteils gezahlt, abgerundet. Rundung verliert
so nichts und erfindet nichts.

**Gutgeschrieben wird am Ende des Laufs**, nicht je Kill im Spielstand.
Die Zahl fällt sichtbar über dem Gegner und läuft in der Kopfzeile mit;
gebucht wird sie in `PitScreen._zeigeErgebnis`, der einen Stelle, an der
ein Lauf ankommt. Wer die App mitten im Lauf schliesst, verliert die
Beute dieses Laufs — der Topf bleibt aber voll.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Je Kill ein fester Betrag, unbegrenzt | Wiederholbare Quelle, Grinden — genau der Einwand aus ADR-0032 |
| Erst beim Sieg gutschreiben, Zahlen nur anzeigen | Beim Tod wäre die gezeigte Beute weg — eine Strafe fürs Scheitern |
| Gleicher Anteil für jeden Gegner, auch den Wächter | Der Wächter ist der Kampf der Stufe; und wer ihn fällt, soll den Rest haben |
| Je Kill in den Spielstand schreiben | 60 Schreibvorgänge je Lauf und ein zweiter Ort, an dem ein Lauf ankommt |

## Konsequenzen

- Die Summen sind unverändert — `progression_test.dart` muss nichts
  wissen. Neu ist nur die **Reihenfolge**: Ein Spieler, der an Stufe 7
  zweimal scheitert, hat danach schon einen Teil ihres Betrags.
- Der Spielstand hält angebrochene Töpfe. Sie werden bedeutungslos, sobald
  die Stufe geschafft ist, und fallen aus der Rechnung heraus.
- Die Kopfzeile zeigt „+45 EP +18 G" im Lauf; über jedem Gegner steigt
  „+7 EP  +3 G" auf. Nicht am Gerät angesehen: ob das neben den
  Schadenszahlen zu voll wird.
