# ADR-0030: Ein Set wirkt auf eine Art von Fähigkeit, nicht auf alles

**Datum:** 08.09.2026
**Status:** Aktiv
**Entschieden von:** AktivesBrett

## Kontext

Der Wunsch war klar formuliert: „Sets für Waffen und Rüstung (erstmal nur
3 Sets), 2er und 4er. Set-Fähigkeit hinzufügen — also wenn man ein Set voll
hat, passiert was." Als Ideen genannt: eine Fähigkeit um Prozent verstärken,
eine Fähigkeit weniger Energie kosten lassen, eine Fähigkeit leichter
treffbar machen (Leiste größer und langsamer).

Damit standen zwei Fragen offen, und beide hätten das Ergebnis grundlegend
verändert.

**Woraus bestehen die Sets?** Der Laden führt seit
[ADR-0029](0029-seltenheit-statt-preisleiter.md) fünf Stücke je Platz, 27
insgesamt. Ein Set kann daraus bestehen — oder zwölf neue Stücke bringen.

**Worauf wirkt der Bonus?** Auf alle Fähigkeiten gleich oder auf eine
bestimmte Art.

Dahinter liegt eine ältere Warnung. `konzept.md` 3.1 sagt: „Ein Ring, der
Energie schneller füllt, erzeugt eine Entscheidung. +3 Angriff nicht."
[ADR-0013](0013-charakter-als-kommandozentrale.md) zitiert sie und nennt den
Charakter eine Kommandozentrale. Ein Set, das jede Fähigkeit gleich
verstärkt, wäre genau das verbotene +3 Angriff — nur teurer.

## Entscheidung

### 1. Set-Teile sind vorhandene Stücke mit einer Marke

Kein neues Stück. Von den fünf Stücken auf jedem der vier Plätze — Waffe,
Rüstung, Helm, Schuhe — tragen drei eine `setId`, zwei keine. Drei Sets à
vier Teile gehen damit genau auf.

**Ring und Talisman gehören zu keinem Set.** Sonst hieße „Set voll" auch
„die ganze Ausrüstung steht fest", und es gäbe nichts mehr zu wählen.

### 2. Jedes Set wirkt auf genau eine Art von Fähigkeit

| Set | Wirkt auf | 2 Teile | 4 Teile |
|---|---|---|---|
| Eiserner Wille | Angriffs-Fähigkeiten | +10 % Schaden | +25 % Schaden |
| Sturmruf | Umgebungen | −1 Energie | −2 Energie |
| Ruhiger Stand | Schutz und Heilung | Leiste ×0,85, Fenster ×1,25 | ×0,7 / ×1,6 |

Die drei Ideen aus dem Wunsch, je einer Art zugeordnet. Die Zuordnung ist
nicht beliebig: Umgebungen sind mit sechs bis acht Energie die teuerste Art
und profitieren am meisten von einem Rabatt; Schutz-Fähigkeiten leben von
ihrer Perfect-Wirkung und werden ausgerechnet dann verfehlt, wenn es eng
wird.

### 3. Die Art eines Zuges wird abgeleitet, nicht gesetzt

`Move.kind` fragt: Legt der Zug eine Umgebung? Dann Umgebung. Macht er
Schaden? Dann Angriff. Sonst Schutz.

Derselbe Grund wie bei `Move.hasTimingWindow`: Ein Feld, das jemand beim
Anlegen einer Fähigkeit vergessen kann, meldet sich nie. Der einzige
Grenzfall ist *Vulkanbruch* — Lava **und** 38 Schaden. Er zählt als
Umgebung, weil ein Umgebungs-Set sonst um die stärkste Umgebung ärmer wäre.

### 4. Ein Set wirkt nur auf Züge, die Energie kosten

Damit ist der **Waffenzug ausgenommen**, obwohl er als Angriff zählt.

Das ist [ADR-0009](0009-kampfbalance-ueber-gegnerreihe.md) ein zweites Mal:
Ein Faktor, der auf den Zug wirkt, den man *jede* Runde drückt, entscheidet
den Kampf allein. Genau deshalb hat der Basisangriff auch keinen eigenen
Perfect-Faktor.

Der Preis dafür ist benannt: *Aurastrom* ist eine Schutz-Fähigkeit, die
Energie erzeugt, und fällt durch dasselbe Raster. Er bekommt nichts.

### 5. Was aktiv ist, wird abgeleitet — nicht gespeichert

`Loadout.activeSets` zählt die getragenen Teile und fragt den Set-Katalog,
was daraus folgt. Kein neues Feld im Spielstand.

Dieselbe Bauform wie beim Gold (ADR-0011) und bei der Erfahrung
(ADR-0008): Ein gespeicherter Set-Zustand könnte von dem abweichen, was
tatsächlich getragen wird.

**Besitz zählt nicht, nur Tragen.** Sonst wäre die Wahl auf jedem Platz
folgenlos, sobald jemand einmal alles gekauft hat.

### 6. Die Zugehörigkeit steht am Stück, nicht im Set

`GearItem.setId`, gelesen von `GearCatalog.piecesOf`. Eine zweite Liste im
Set-Katalog könnte von der ersten abweichen — der Fallstrick aus
`gotchas.md`, der schon einmal eine Fähigkeit sichtbar und wirkungslos
gemacht hat.

### 7. Die vier Preise bleiben, die Sets kosten fast gleich viel

1880 · 1870 · 1840 Gold. Kein Preis wurde für die Sets geändert; die
Zuordnung ist so gewählt, dass die Summen zusammenfallen.

Wäre ein Set deutlich billiger, wäre die Wahl zwischen ihnen keine Frage des
Spielstils mehr, sondern des Geldbeutels. `set_catalog_test.dart` hält die
Spanne unter 15 %.

## Begründung

**Warum Marken statt neuer Stücke.** Der Auslöser für die ganze Reihe war
„mehr Content" — und dagegen spricht es zunächst. Aber zwölf zusätzliche
Stücke hätten jeden Platz auf acht gebracht und die Form aus ADR-0029
(zwei · zwei · eins) gesprengt. Wichtiger: Ein Laden mit 39 Einträgen auf
einem Handy ist keine Auswahl mehr, sondern eine Liste. Die Sets fügen dem
vorhandenen Laden eine **zweite Leseart** hinzu — dieselben 27 Stücke,
plötzlich mit einer Frage mehr daran. Das ist der billigere Content.

**Warum eine Art je Set.** Bei „alles gleich" gäbe es genau eine richtige
Antwort: das Set mit der größten Zahl. Bei „eine Art je Set" hängt die
Antwort davon ab, was auf den Fähigkeitsplätzen liegt — und das hängt am
Skillbaum und an den Streaks. Damit reicht die Entscheidung im Laden bis in
die Gewohnheiten zurück, statt eine Zahl zu vergleichen.

**Warum das Konzept es so verlangt.** ADR-0013 hat den Satz „Es wird nie eine
Klassenwahl geben" fett gesetzt: Wo eine Klasse sichtbar wird, wird sie aus
dem Verhalten abgeleitet. Ein Set, das nur mit Umgebungs-Fähigkeiten lohnt,
ist genau das — eine Klasse, die man nicht wählt, sondern in die man
hineinwächst.

**Warum die 4er-Stufe ein Fernziel ist.** Rund 75 Tage Gold. Das ist mehr
als der 30-Tage-Lauf aus Ziel 7 — und mit Absicht: Der Laden soll nach
dreißig Tagen noch etwas zu wollen übrig lassen. Die 2er-Stufe ist dagegen
nach 10 bis 19 Tagen erreichbar; `set_catalog_test.dart` prüft beide
Grenzen.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Zwölf neue Set-Stücke | Jeder Platz führte acht statt fünf; die Form aus ADR-0029 fällt, und der Laden wird eine Liste statt einer Auswahl |
| Set-Bonus auf alle Fähigkeiten | Dann gibt es eine richtige Antwort — das stärkste Set — und die Wahl ist keine |
| Set-Bonus als Werte-Zuschlag (+3 Angriff) | Genau das, wovor `konzept.md` 3.1 warnt: Ausrüstung, die nur Zahlen erhöht |
| Sets über alle sechs Plätze | „Set voll" hieße „die ganze Ausrüstung steht fest" |
| `Move.kind` als gesetztes Feld | Ein Feld, das vergessen werden kann, meldet sich nie (`gotchas.md`) |
| Der Bonus wirkt auch auf den Waffenzug | ADR-0009: Ein Faktor auf den Zug jeder Runde entscheidet den Kampf allein |
| Aktive Sets im Spielstand speichern | Zweite Wahrheit neben dem, was getragen wird (ADR-0008, ADR-0011) |
| Sets-Liste im Set-Katalog statt Marke am Stück | Zwei Listen über dieselbe Sache laufen auseinander (`gotchas.md`) |

## Konsequenzen

**Leichter:** Der Laden hat eine zweite Frage bekommen, ohne ein Stück mehr
zu führen. Der Kampf bekommt drei neue Hebel, die alle an getragener
Ausrüstung hängen und keine neue Mechanik brauchen. Der Spielstand ist
unverändert — Sets überleben einen Neustart, weil das Getragene es tut.

**Schwerer:** `package:combat` hat einen neuen Eingang (`playerSets`), und
`package:gear` eine Aufzählung, die zu einer in `combat` passen muss.
`test/gear_sets_seam_test.dart` prüft die Naht in beide Richtungen — käme
in `combat` eine vierte Art dazu, gäbe es Fähigkeiten, die kein Set je
erreicht.

**Der Gegner trägt keine Sets.** Das ist keine Ausnahme von
[ADR-0023](0023-der-gegner-spielt-nach-denselben-regeln.md), sondern liegt
daneben: Dort ging es um Timing und Zugwahl, also darum, wie beide Seiten
*spielen*. Woher ihre Werte kommen, war nie dieselbe Frage — Gegner haben
auch keine Gewohnheiten.

**Offen — und gemessen:**

- **Zwei der drei Sets kann die Simulation nicht messen**, und beide Male
  liegt es an ihr. *Ruhiger Stand* ändert die Leiste, aber der simulierte
  Spieler tippt nicht; sein Timing kommt aus einer gewichteten Münze.
  *Eiserner Wille* verstärkt Angriffs-Fähigkeiten, die der Bot nicht
  spielt, weil sie schwächer sind als sein Waffenzug — derselbe Befund wie
  beim Waffenvergleich.
- **Gegen drei Gegner ist ein volles Set Überfluss.** Die Siegquote steht
  mit vier Set-Stücken überall auf 100 %. Der Platz eines Sets ist der
  Dungeon (Ziel 6), wo HP zwischen den Kämpfen nicht heilen und jede
  gesparte Runde zählt.
- **Kein Verkauf.** Wer auf ein Set hinkauft und sich umentscheidet, sitzt
  auf den Stücken. Bei sechs Plätzen war das tragbar (ADR-0011); mit Sets
  wird es unangenehmer. Bewusst nicht in diesem Zug gelöst — Verkauf
  bräuchte eine Verkaufshistorie und damit die zweite Wahrheit, die
  ADR-0008 vermeiden wollte.
