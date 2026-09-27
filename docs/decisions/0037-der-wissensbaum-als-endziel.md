# ADR-0037: Der Wissensbaum als Endziel

**Datum:** 21.09.2026
**Status:** Aktiv — als **Zielbild**. Gebaut wird nach dem 30-Tage-Lauf (Ziel 7).
**Nachtrag 26.09.2026:** Der erste Schritt ist doch schon im Testlauf gebaut, und die Punkte 2 bis 5 sind entschieden — siehe [ADR-0050](0050-zwischenebenen-und-angekuendigte-gebiete.md). Am selben Tag hat der Baum mit 54 Knoten die 50 Punkte eines Spielerlebens überholt; Grundsatz 1 gilt damit im Spiel.
**Entschieden von:** Frederik

## Kontext

Issue [#54](https://github.com/Prozesstek/LifesGame/issues/54) („Theorie
Ummodeln") listet rund **340 Themen** in den vier Gebieten, die es seit
ADR-0019 gibt — Körper 88, Geist 105, Gesellschaft 65, Wissenschaft 84 —,
geordnet über eine Zwischenebene („Kraft & Muskulatur", „Philosophie",
„Physik") und verbunden über die Gebiete hinweg (Schlaf → Gedächtnis →
Lernen). Das Issue spricht von einem „wachsenden Wissensuniversum"
statt eines Baums mit Ende.

Heute hat der Baum 21 kostenpflichtige Knoten (mit PR #53) und steht mit
einem Punkt je Level ab Level 22 vollständig offen. Theorie bringt über ein Spielerleben
rund 2.700 Erfahrung; Gewohnheiten tragen den Großteil der rund 34.000,
die Level 50 kostet.

Frederiks Antwort auf die Frage, ob das ein Bauauftrag ist:

> „Das ist das Endziel, da soll die App mal hingehen. Es soll quasi so
> sein, dass man einfach nicht in der Lage ist, alle Theorie-Sachen
> abzudecken. Man soll sich bewusst für das entscheiden, auf was man Bock
> hat. Und dann immer besser in den einzelnen Dingern werden. […] Das kann
> ruhig ordentlich Gold und XP geben. Weil ich finde, es ist wichtig für
> einen Menschen, sowohl gesunde Gewohnheiten aufzubauen, als auch neue
> Sachen zu lernen."

## Entscheidung

Die Theorie wird ein **Wissensbaum, der größer ist als ein Spielerleben**.
Drei Grundsätze:

1. **Man kann nicht alles lernen — mit Absicht.** Die Punkte reichen für
   einen Bruchteil des Baums. Welche Gebiete jemand öffnet, ist eine
   Entscheidung nach Interesse und damit Teil seines Charakters — wie Titel
   und Waffe, und wie es `konzept.md` für die Klassen sagt: aus dem
   Verhalten, nie gewählt.
2. **Tiefe statt Breite.** Wer sich für etwas entschieden hat, soll darin
   immer besser werden können: tiefere Knoten, Querverbindungen in andere
   Gebiete, und später Wiederholen und Vertiefen
   (`docs/vorlagen/lernen.md`).
3. **Lernen zählt so viel wie Gewohnheiten.** Beides soll ordentlich
   Erfahrung und Gold geben. Theorie ist keine Beigabe zum Abhaken mehr.

## Was daraus folgt

| Frage | Heute | Zielbild |
|---|---|---|
| Wie viele Punkte? | 1 je Level, 49 im Leben | **bleibt knapp** — die Knappheit ist jetzt der Zweck |
| Wie groß ist der Baum? | 25 Knoten | ~340 Knoten, offen nach oben |
| Wann ist er ganz offen? | ab Level 22 | **nie** |
| Was bringt Theorie im Leben? | ~2.700 XP | **in der Größenordnung der Gewohnheiten** — Zahl wird gemessen |
| Braucht ein Knoten eine Gewohnheit? | ja (`konzept.md` 3.3) | **nein** — siehe unten |
| Wo steht der Inhalt? | in Dart-Konstanten | in Datendateien, eine je Seite |
| Was trägt ein Knoten? | Eltern, Icon, Fähigkeit | dazu **Tags** |

**Eine Regel aus `konzept.md` fällt.** Dort steht: „Ein Knoten verdient
seinen Platz nur, wenn er […] mindestens eine täglich abhakbare Gewohnheit
hervorbringt." Mit Geschichte, Physik oder Philosophie ist das nicht
vereinbar, und Grundsatz 3 sagt, dass Lernen für sich zählt. Knoten
*dürfen* weiter eine Vorlage freischalten; sie *müssen* es nicht mehr.
**Aus Frederiks Satz abgeleitet, nicht wörtlich entschieden** — beim
Nachlesen bestätigen.

## Begründung

**Warum Knappheit statt „alles erreichbar".** Ein Baum, den am Ende jeder
ganz offen hat, ist eine Reihenfolge, keine Wahl — genau das hat ADR-0035
schon einmal korrigiert. Zwei Spieler auf Level 30 sollen verschiedene
Dinge wissen, und daran soll man sie erkennen.

**Warum mehr Belohnung.** Heute ist Theorie über ein Spielerleben ein
Zwölftel dessen, was Gewohnheiten bringen. Wer dem Spiel glaubt, lernt
also nebenbei. Das widerspricht Grundsatz 3 — und damit dem, was die App
über einen Menschen aussagen will.

**Warum Datendateien.** 340 Seiten mit je drei Abschnitten und drei
Fragen sind rund tausend Fragen. In Dart-Konstanten ist das weder zu
pflegen noch von jemandem ohne Flutter zu schreiben. Die Prüfungen aus
`graph_content_test.dart` (eindeutige Ids, drei Fragen, kreisfrei,
ADR-0027) laufen über Dateien genauso.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Punkte so erhöhen, dass alles erreichbar ist | widerspricht Grundsatz 1 — dann gibt es nichts zu entscheiden |
| Den Baum klein halten (~45 Knoten wie in ADR-0012) | Frederiks Zielbild ist ausdrücklich ein Baum ohne Ende |
| Theorie weiter gering belohnen, damit Gewohnheiten der Motor bleiben | widerspricht Grundsatz 3 |
| Alle ~340 Themen auf einmal bauen | ~1.000 Fragen, die fachlich stimmen müssen; die Erscheinungsregel („ein Knoten erscheint erst, wenn seine Seite steht") bleibt |

## Offen

Diese Punkte sind **bewusst nicht entschieden**:

1. **Wie viel genau.** „Größenordnung der Gewohnheiten" ist eine Richtung,
   keine Zahl. Sie wird in `test/progression_test.dart` gemessen — die
   vier Kurven (Theorie, Gewohnheiten, Level, Preise) müssen danach
   weiter zusammenpassen, und der Laden darf nicht in zwei Wochen leer
   gekauft sein.
2. **Belohnung fürs Vertiefen.** „Immer besser werden" kann heißen:
   tiefere Seiten öffnen (zahlt je einmal) — oder eine Seite wiederholen
   und dafür erneut etwas bekommen. Das Zweite wäre die erste
   **wiederholbare** Belohnung außerhalb der Gewohnheiten, genau die
   Grenze, die ADR-0032 beim Kampf gezogen hat. Braucht eine eigene
   Entscheidung.
3. **Wer schreibt.** Entwürfe von Claude, gegengelesen — oder von Hand.
4. **Punkte je Level.** Bleibt es bei einem, oder kommen Punkte auch aus
   anderen Quellen? Knappheit ist gewollt, aber 49 Punkte gegen 340
   Knoten sind ein Siebtel.
5. **Die Zwischenebene.** Kostet ein Knoten wie „Kraft & Muskulatur"
   einen Punkt, oder ist er wie die Wurzeln frei?

## Konsequenzen

- **Nach dem 30-Tage-Lauf**, in dieser Reihenfolge: Gerüst (Datendateien,
  Tags, Zwischenebene) → Belohnung neu rechnen → Inhalt, **Körper zuerst**.
  Körper deshalb, weil dort die älteste Schieflage liegt: Stärke und
  Ausdauer haben die wenigsten Gewohnheitsvorlagen (Konzeptrunde 18.08.).
- **Bis dahin ändert sich im Spiel nichts.** „Baum über 24 Knoten hinaus"
  bleibt auf der Sperrliste in `ziele.md`; dieser ADR begründet nur,
  wohin es danach geht.
- **Der Engpass bleibt die Schreibarbeit**, wie seit ADR-0012 — nur mit
  einem Vielfachen an Seiten.
- **ADR-0012, ADR-0019, ADR-0035 bleiben in Kraft.** Punkte, vier Wurzeln
  und ein Punkt je Level gelten weiter; dieser ADR ändert, wie groß der
  Baum werden darf, nicht wie man ihn öffnet.
