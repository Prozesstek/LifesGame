# ADR-0073: Eine Ultimate, Mana als Bremse und zehn neue Arten von Wirkung

**Datum:** 14.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik, in einer Fragerunde zu Issue #114

## Kontext

Issue [#114](https://github.com/Prozesstek/LifesGame/issues/114) sagt drei
Dinge: Der Kampf braucht mehr Fähigkeiten, jeder Entwickler steuert zehn
bei; es gibt einen vierten Fähigkeitsplatz für eine **Ultimate**, jeder
denkt sich zwei aus; und **Mana spielt keine Rolle**, weil die
Abklingzeiten zu kurz sind.

**Was der Code hatte.** Neunzehn Fähigkeiten in
`packages/action_combat/lib/src/pit_ability.dart`, gebaut aus neun Arten
von Wirkung (`PitEffect`): Geschoss, Schlag, Rundumschlag, Heilen, Mana,
Schadensminderung, Zurückwerfen, Verlangsamen, Dauerschaden. Keine der
Arten aus dem Issue gab es. Vier Plätze auf Level 1, 3, 6 und 10
(`AbilitySlots`), der erste ist die Waffe — eine Ultimate ist also der
**fünfte** Platz. Im Kampf liegen drei Knöpfe zu 58 Punkten in einer
Reihe unten rechts (`AbilityButtons`).

**Woran Mana hängt.** Vorrat und Nachfluss kommen allein aus der
Energie (`ActionStats.maxMana`, `manaRegen`), dazu Waffen mit Mana je
Treffer, Aurastrom und Atemzug. Das Level spielt keine Rolle. Auf Tag 0
sind es 40 Mana und 6 je Sekunde; drei Fähigkeiten im Takt ihrer
Abklingzeit kosten überschlagen 10 bis 13 je Sekunde. Am Anfang müsste
Mana also knapp sein — dass es das nicht ist oder später nicht mehr,
ist **nicht gemessen**, nur gemeldet.

## Entscheidung

**Die Ultimate.**

| Frage | Entschieden |
|---|---|
| Was sie kostet | **kein Mana, keine Abklingzeit** — sie lädt sich durch Kämpfen auf |
| Woran sie lädt | **Ereignisse, nicht Schaden**: jeder besiegte Gegner einen festen Anteil (etwa ein Achtel), Treffer am Wächter ebenfalls (etwa jeder zehnte einen Anteil) |
| Was nicht lädt | was im Lauf entsteht (`lootless`, die Schleimlinge) und was Begleiter töten |
| Wann sie leer ist | zu Beginn jedes Laufs; zwischen den Räumen bleibt sie |
| Der Platz | ein **eigener**, nur für Ultimates — und eine Ultimate nie auf einem der drei anderen |
| Ab wann | **Level 15**, in `AbilitySlots` wie die anderen Plätze |
| Im Kampf | etwa 76 Punkte in der Ecke unten rechts, Ladering am Rand; die drei anderen etwa 50 Punkte im Bogen darum. **Vor Level 15 bleibt die Reihe**, wie sie ist |
| Tastatur | 1–3 wie bisher, die Ultimate auf 4 |
| Das Bild | **goldener Doppelrand**, im Kampf und im Fähigkeiten-Bildschirm. Ultimates haben **keine Seltenheit** |
| Woher | je Ultimate eine Bedingung aus den bestehenden Quellen (Baum, Kette, Errungenschaft); **mindestens eine auf Level 15 erreichbar**, über einen Knoten im Baum; **keine** aus der Grube selbst |

**Mana bremst.** Die Abklingzeit verhindert nur Dauerfeuer; wer alle
drei Fähigkeiten im Takt drückt, ist nach etwa 10 bis 15 Sekunden leer
und lebt vom Nachfluss. Der Nachfluss wächst mit der Energie langsamer
als der Vorrat, damit die Bremse auch spät greift. **Zuerst wird
gemessen**: `pit_sim` zählt, wie oft ein Wurf am Mana scheitert, auf
Tag 0, 30 und 60. Die Zahlen werden danach gestellt.

**Zehn neue Arten von Wirkung**, jede ein `PitEffect`, und **jede darf
in jede Fähigkeit**, auch in eine Ultimate:

| Art | Regel |
|---|---|
| Dash | stoppt an der Wand wie jede Bewegung |
| Blink | **nie durch eine Wand oder das Tor** |
| Stun | der Wächter hat eine **Stun-Leiste**: drei Kerben, erst jeder dritte Stun wirkt, halb so lang; er bricht seine laufende Ankündigung ab. Einfrieren zählt als Stun |
| Self-Buff | ein Faktor auf Zeit; auf den Grundangriff nur leicht (ADR-0009) |
| Stacking, Rage | gezählt wird, was passiert, nicht der Schaden; immer mit Obergrenze |
| Passiv | liegt auf einem Platz, hat **keinen Knopf**, wirkt dauernd |
| Hook | zieht einen Gegner heran, nicht den Wächter, nicht durch Wände |
| Unsichtbarkeit | kurz, **endet beim ersten Angriff** |
| Begleiter | **höchstens einer zugleich**, lebt auf Zeit, wird nicht angegriffen und greift nur an, was der Held sieht; seine Kills **zahlen normal** (der Topf ist fest, ADR-0041), **laden die Ultimate aber nicht** |
| Terrain | gesetzte Wände **verschwinden nach Sekunden** und nie in den Gang zum Tor |

**Fünf Bausteine kamen beim Durchgehen von Frederiks Ideen dazu**:

| Art | Regel |
|---|---|
| Bumerang | fliegt hin und zurück, trifft jeden je Weg höchstens einmal; an der Wand kehrt er um |
| Falle | liegt am Boden, löst beim ersten Gegner aus; höchstens zwei zugleich |
| Wegschleudern | stößt Gegner weg, die Wand hält auf; nicht den Wächter |
| Zerspringen | ein gefrorener Gegner nimmt den nächsten Treffer sicher kritisch und taut auf |
| Zufall | würfelt mit dem Würfel des Laufs, damit die Tagesgrube für alle gleich bleibt |

**Gebaut wird, was eine Fähigkeit braucht.** Stacking und Rage, Passiv
und Unsichtbarkeit nutzt keine von Frederiks zwölf; sie kommen, sobald
eine Fähigkeit von AktivesBrett sie braucht.

**Die neuen Fähigkeiten entstehen in einer Vorlage**:
[`docs/vorlagen/faehigkeiten-2.md`](../vorlagen/faehigkeiten-2.md). Jeder
Entwickler trägt dort zehn Fähigkeiten und zwei Ultimates ein. Frederiks
Ideen werden Stück für Stück mit Claude durchgegangen.

**Gebaut wird in drei Blöcken**, je ein PR: die Messung und der
Ultimate-Platz samt Knopf, dann die zehn Arten, dann die Fähigkeiten aus
der Vorlage.

## Begründung

**Ereignisse statt Schaden**, weil die Kampfzahlen mit Level und
Seltenheit um ein Vielfaches wachsen (ADR-0042). An Schaden gemessen
wäre die Ultimate spät im Spiel dauernd voll; eine Zählung ist auf jeder
Stufe gleich viel wert — dieselbe Überlegung wie bei Heilung als Anteil.

**Ein eigener Platz**, weil sonst drei Ultimates zugleich die anderen
Fähigkeiten verdrängen könnten und die Ultimate keine Klasse mehr wäre,
sondern nur eine teure Fähigkeit.

**Level 15** setzt die Reihe 1, 3, 6, 10 fort. Ein fleißiger Spieler
steht dort nach etwa drei Wochen (`runway_sim`).

**Kein leerer Knopf vor Level 15.** Ein gesperrter Platz in der Ecke
wäre drei Wochen lang ein toter Knopf. Aus demselben Grund muss eine
Ultimate auf Level 15 erreichbar sein — sonst geht der Platz auf und
bleibt leer.

**Ein Doppelrand statt eines goldenen Randes**, weil Gold die Farbe von
Legendär ist (`rarity_badge.dart`) und Sternenfall sie schon trägt. Die
Form unterscheidet: Legendär ist eine goldene Linie, die Ultimate ein
goldener Rahmen.

**Keine Ultimate aus der Grube**, weil der Kampf die Auszahlung des
Fortschritts ist, nicht seine Quelle (`konzept.md` Abschnitt 2).

**Mana als Bremse (B)**, weil nur dann jeder Wurf eine Entscheidung ist:
Vulkanbruch jetzt oder Blütentau aufsparen. Mit der Abklingzeit als
Bremse (A) hätte man Mana auch streichen können. Und Energie bleibt ein
Wert, der sich lohnt — mehr Energie heißt länger feuern, nie endlos.

**Jede Art in jede Fähigkeit** (Frederik, gegen Claudes Empfehlung):
Claude hatte vorgeschlagen, Begleiter und Terrain den Ultimates
vorzubehalten, weil sie den größten Aufwand haben und die Grube am
stärksten verändern. Frederik will alle Arten für alles. Die beiden
Grenzen bei Begleitern und Terrain stehen deshalb in der Tabelle — sie
halten, was der Vorbehalt halten sollte.

**Die Regeln der Tabelle** schützen je eine Zusage, die schon steht:
Blink durch Wände überspränge Räume und den Auftritt des Wächters
(`gate_test.dart`); ein Wächter im Dauerstun machte seine Ankündigungen
sinnlos (`boss_test.dart`) — deshalb wirkt nur jeder dritte Stun
(Frederik: „Stun-Leiste“), und der bricht einen Angriff ab, statt ihn
nur zu verzögern; lange Unsichtbarkeit liesse sich bis zum
Wächter schleichen, und der zahlt den ganzen Topf (dieselbe Sorge wie
bei der Besetzung, ADR-0063); Kills von Begleitern, die die Ultimate
laden, ließen den Begleiter das Spiel spielen. **Beute zahlen sie
trotzdem**: Der Ertrag einer Stufe ist ein fester Topf (ADR-0041), mehr
als er zählt nie — verweigerte Beute ginge nur verloren, farmen lässt
sich damit nichts (beim Durchgehen des Falken geändert).

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Ultimate über Mana und lange Abklingzeit | wäre eine vierte Taste, kein Moment |
| Laden über Schaden | wächst mit der Macht mit (ADR-0042) |
| Laden auch über eingesteckten Schaden | Frederik: nein |
| Ultimate-Platz auf Level 10 | würde die Ultimates in den Testlauf holen, aber zum vierten Platz dazu |
| gesperrter Ultimate-Knopf ab Level 1 | drei Wochen ein toter Knopf |
| einfacher goldener Rand | liest sich als Legendär |
| Abklingzeit als Bremse (A) | Mana wäre überflüssig |
| Begleiter und Terrain nur als Ultimate | Frederik: alle Arten für alles |

## Konsequenzen

- **`world.dart` wächst um zehn Arten.** Es hat 1.845 Zeilen; mit der
  ersten neuen Art zieht die Ausführung der Wirkungen in eine eigene
  Datei.
- **Begleiter sind eine neue Seite in der Welt**: eine Figur, die für
  den Helden kämpft, mit eigenem Verhalten. Das ist der größte Teil des
  zweiten Blocks.
- **Terrain verändert die Wege** (`FlowField`) mitten im Lauf; die
  Wegfelder müssen neu gerechnet werden, solange die Wand steht.
- **Die Tagesgrube** (ADR-0072) bleibt ohne Ultimate; ihre sieben Sätze
  sind gemessen. Ob sie eine bekommt, ist offen.
- **Die Zahlen sind geschätzt**: ein Achtel je Kill, jeder zehnte
  Treffer am Wächter, 76 und 50 Punkte. Sie werden gemessen und
  angesehen, nicht geraten (`pit_sim`, Vorschau in 390 × 844).
- **Mana knapper zu machen ändert jede Siegquote.** Nach dem Stellen
  müssen `pit_sim` und `tagesgrube_sim` neu laufen, die Stufen der
  Tagesgrube gegebenenfalls nachgestellt werden.
- **AktivesBrett** hat diese Runde nicht gesehen. Seine zehn und zwei
  gehören in die Vorlage, bevor der dritte Block beginnt.
