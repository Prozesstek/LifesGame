# ADR-0031: Verkauf zur Hälfte, und was fehlt, bleibt versenkt

**Datum:** 08.09.2026
**Status:** Aktiv
**Ändert:** [ADR-0011](0011-ausruestung-als-eigenes-package.md) (Punkt „kein Verkauf")

## Kontext

[ADR-0011](0011-ausruestung-als-eigenes-package.md) hat den Verkauf
ausdrücklich ausgeschlossen, und zwar mit einer Begründung, die stimmte:

> Das ist auch der Grund, warum es keinen Verkauf gibt: Er bräuchte eine
> Verkaufshistorie und damit die zweite Wahrheit, die ADR-0008 vermeiden
> wollte. Der Preis dafür ist überschaubar, weil jedes Stück einen eigenen
> Platz belegt — man kauft nichts doppelt.

Der zweite Satz gilt nicht mehr. Seit [ADR-0029](0029-seltenheit-statt-preisleiter.md)
führt jeder Platz **fünf** Stücke statt eines bis zwei, seit Ziel 3 sind die
fünf Waffen Alternativen statt einer Leiter, und seit
[ADR-0030](0030-sets-wirken-auf-eine-art-von-faehigkeit.md) kauft man auf
ein Set hin, das erst mit vier Teilen zahlt. Ein Fehlgriff kostet damit bis
zu 1050 Gold — 42 Tage Gewohnheiten —, und er ist nicht mehr zu korrigieren.

**Der technische Kern des Problems ist unverändert und liegt nicht dort, wo
man ihn vermutet.** Gold wird abgeleitet: Zufluss minus Summe der Preise des
Besitzes. Ein Stück aus dem Besitz zu nehmen gibt deshalb **von selbst den
vollen Preis zurück** — man müsste dafür gar nichts bauen. Genau das wäre
der Fehler: Der Laden wäre folgenlos. Kaufen, ansehen, zurückgeben, nächstes
ansehen.

## Entscheidung

### 1. Ein Verkauf bringt die Hälfte

`GearPrices.refundShare` = 0,5. Eine Zahl, an einer Stelle, wie jeder Preis.

### 2. Die andere Hälfte bleibt ausgegeben

Gespeichert wird `Loadout.soldIds` — die Liste dessen, was verkauft wurde,
mit Reihenfolge und Wiederholungen. `lostGold` rechnet daraus, was liegen
geblieben ist, und `spentGold` zählt es dazu.

Die Wirkung ist genau die gewünschte: Nach einem Verkauf hat man die Hälfte
des Preises dauerhaft ausgegeben, für nichts. Zurückkaufen kostet wieder den
vollen Preis.

### 3. Verkaufen legt ab

Ein getragenes Stück wird beim Verkauf vom Platz genommen. Es gehört einem
nicht mehr, also kann es nicht mehr wirken — und ein Set verliert damit
sofort sein Teil.

### 4. Der Verkauf steht im Laden, mit Rückfrage

An derselben Stelle, an der sonst der Kaufknopf steht. Davor ein Dialog, der
**beide** Zahlen nennt: was zurückkommt und was ein Rückkauf kosten würde.

## Begründung

**Warum das keine zweite Wahrheit ist — der Punkt, an dem ADR-0011 hing.**
`soldIds` ist kein gespeicherter Kontostand, sondern eine **Historie**: eine
Liste dessen, was passiert ist. Genau dieselbe Bauform wie die Häkchen in
`package:habits` und wie `ownedIds` selbst. Was daraus für das Gold folgt,
wird weiter gerechnet und nirgends gespeichert.

Der Unterschied ist nicht spitzfindig, er ist der ganze Grund:

| | kann abweichen? |
|---|---|
| gespeicherter Goldstand | **ja** — die Rechnung sagt etwas anderes |
| gespeicherte Verkaufshistorie | **nein** — sie *ist* die Rechnung |

Ein Beleg dafür, dass es dieselbe Sorte Zahl ist: Ändert jemand einen Preis
im Katalog, ändert sich rückwirkend, was ein alter Verkauf gekostet hat —
genauso wie sich ändert, was ein alter Kauf gekostet hat. Beide bleiben
konsistent, weil beide abgeleitet sind.

**Warum die Hälfte.** Die beiden Ränder schließen sich selbst aus:

- Bei 1,0 gäbe es keine Entscheidung mehr. Man kauft alles der Reihe nach
  an, sieht es sich an, gibt es zurück. Der Laden wäre ein Katalog.
- Bei 0,0 wäre der Verkauf eine Löschtaste, kein Verkauf.

Die Hälfte kostet je Stück zwischen vier und einundzwanzig Tagen
Gewohnheiten. `catalog_test.dart` hält beide Grenzen fest: Ein Verkauf muss
weniger einbringen, als er gekostet hat, und ein Fehlgriff darf höchstens gut
drei Wochen kosten.

**Warum die Rückfrage.** Ein Kauf lässt sich ohne Verlust rückgängig machen —
ein Verkauf nicht. Auf einem Handy, wo der Knopf zwei Fingerbreit unter dem
Kaufknopf sitzt, wäre ein Fehlgriff sonst teuer. Der Dialog nennt beide
Zahlen, damit die Entscheidung vollständig dasteht.

**Warum Gold dabei nie sinken kann.** Ein Verkauf senkt `spentGold` um den
Erlös und hebt es nie. Das prüft `loadout_test.dart` über den ganzen Katalog.
Die Zusage aus ADR-0011 — „Gold kann nie unter null fallen" — bleibt damit
unangetastet.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Voller Preis zurück | Der Laden wäre folgenlos; jede Kaufentscheidung wäre widerrufbar und damit keine |
| Ein gespeicherter Goldstand statt der Historie | Genau die zweite Wahrheit, die ADR-0008 und ADR-0011 vermeiden — sie kann von der Rechnung abweichen, die Historie nicht |
| Ein mitgeführter `lostGold`-Zähler | Dasselbe Problem in klein: Eine Zahl, die jede Methode weiterreichen muss, kann veralten. Aus der Liste gerechnet kann sie es nicht |
| Gar kein Verkauf (Stand ADR-0011) | Trug, solange ein Platz ein bis zwei Stücke hatte. Mit 27 Stücken, fünf Sidegrade-Waffen und drei Sets ist ein Fehlgriff bis zu 42 Tage teuer |
| Verkauf nur für nicht getragene Stücke | Zwei Schritte für einen Vorgang, ohne dass der erste etwas entscheidet |
| Rückgabe zum vollen Preis innerhalb einer Frist | Eine Uhr im Spielstand, für einen Fall, den die Rückfrage schon abfängt |
| Verkauf ohne Rückfrage | Auf einem Handy sitzt der Knopf unter dem Kaufknopf; ein Fehlgriff kostet bis zu 525 Gold |

## Konsequenzen

**Leichter:** Der Laden verzeiht. Wer die Geschliffene Klinge kauft und
merkt, dass ihm der Rhythmus nicht liegt, verliert 380 Gold statt 760 — und
kann es anders versuchen. Das ist die Voraussetzung dafür, dass fünf
Sidegrade-Waffen und drei Sets überhaupt ausprobiert werden.

**Schwerer:** `Loadout` hat ein drittes Feld, das jede Methode weiterreichen
muss, die ein neues `Loadout` baut. Wer eines vergisst, löscht die versenkten
Kosten — und der Spieler bekommt sein Gold geschenkt. Ein Test geht deshalb
den Weg *verkaufen → kaufen → anlegen → ablegen* und prüft, dass die Historie
alles überlebt.

**Der Spielstand wächst um einen Abschnitt**, und nur wenn er belegt ist: Ein
Stand ohne Verkäufe sieht aus wie vorher. `fromJson` ist nachsichtig wie
überall — eine Id, die es nicht mehr gibt, fällt heraus, und mit ihr ihre
versenkten Kosten.

**Im Entwicklermodus lässt sich damit Gold erzeugen.** Ein geschenktes Stück
bringt beim Verkauf die Hälfte, während der Zuschlag für seinen Preis stehen
bleibt (ADR-0021). Bewusst nicht abgefangen: Der Modus kann ohnehin Gold
verschenken, er liegt hinter einem eigenen Spielstand, und er ist im
Release-Build nicht vorhanden.

**Offen:** Ob die Hälfte richtig liegt, sagt der 30-Tage-Lauf. Zu großzügig
wäre erkennbar daran, dass jemand mehrere Waffen der Reihe nach durchprobiert;
zu streng daran, dass niemand je verkauft.
