# Fähigkeiten, zweite Runde — die Vorlage

> **Herkunft:** angelegt am 14.10.2026 nach der Fragerunde zu Issue
> [#114](https://github.com/Prozesstek/LifesGame/issues/114). Die Regeln
> stehen in [ADR-0073](../decisions/0073-ultimate-mana-und-neue-arten.md).
>
> **Was sie ist:** der Platz, an dem beide Entwickler ihre Fähigkeiten
> eintragen — **zehn Fähigkeiten und zwei Ultimates je Person**. Gebaut
> wird erst, was hier steht.
>
> **Was sie nicht ist:** die Quelle der Wahrheit für die Zahlen. Die
> stehen nach dem Bau am Eintrag in
> `packages/action_combat/lib/src/pit_ability.dart`. Mana und
> Abklingzeit hier sind Absicht; gestellt werden sie mit
> `dart run tool/pit_sim.dart`.
>
> **Die erste Vorlage** ([`faehigkeiten.md`](faehigkeiten.md)) wurde für
> den Rundenkampf geschrieben. Diese gilt für die Grube.

---

## Die Bausteine

Eine Fähigkeit ist eine Liste von Bausteinen. **Jeder Baustein darf in
jede Fähigkeit**, auch in eine Ultimate (ADR-0073).

**Schaden ist immer ein Vielfaches des Angriffs**, Heilung ein Anteil
des Lebens — nie eine feste Zahl. Eine feste Zahl wäre auf Stufe 30
zehnmal zu klein (`CLAUDE.md`).

### Die neun, die es gibt

| Baustein | Werte | Beispiel |
|---|---|---|
| Geschoss | Wucht × Angriff, Reichweite, Anteil Lebensraub | Funkenstoß, Seelenraub |
| Schlag | Wucht × Angriff, Reichweite | Kraftschlag |
| Rundumschlag | Wucht × Angriff, Umkreis | Klingenwirbel, Sternenfall |
| Heilen | Anteil des Lebens | Blütentau |
| Mana | Menge | Aurastrom |
| Schadensminderung | Faktor, Sekunden | Steinhaut |
| Zurückwerfen | Anteil, Sekunden — nur Nahkampf | Prisma-Barriere |
| Verlangsamen | Umkreis, Faktor, Sekunden | Zeitdehnung |
| Dauerschaden | Umkreis, Angriff je Sekunde, Sekunden | Giftmoor |

### Die zehn neuen

| Baustein | Was er tut | Grenze, die immer gilt |
|---|---|---|
| **Dash** | der Held stürmt eine Strecke in eine Richtung | stoppt an der Wand |
| **Blink** | der Held ist sofort woanders | nie durch eine Wand oder das Tor |
| **Stun** | Gegner stehen still, Sekunden | beim Wächter wirkt nur jeder dritte (Stun-Leiste), halb so lang, und bricht seine Ankündigung ab |
| **Self-Buff** | ein Wert des Helden steigt um einen Faktor, Sekunden | auf den Grundangriff nur leicht |
| **Stacking / Rage** | jede Wiederholung macht die nächste stärker — oder, als Rage, jeder Treffer, den der Held einsteckt | gezählt, nicht am Schaden gemessen; mit Obergrenze |
| **Passiv** | wirkt dauernd, ohne Knopf | kostet den Platz |
| **Hook** | zieht einen Gegner zum Helden | nicht den Wächter, nicht durch Wände |
| **Unsichtbarkeit** | Gegner sehen den Helden nicht | kurz; endet beim ersten Angriff |
| **Begleiter** | eine Figur kämpft für den Helden | höchstens einer zugleich, lebt auf Zeit, wird nicht angegriffen und greift nur an, was der Held sieht; seine Kills zahlen normal (der Topf ist fest, ADR-0041), laden die Ultimate aber nicht |
| **Terrain** | eine Wand entsteht | verschwindet nach Sekunden; nie im Gang zum Tor |

### Wie gezielt wird

| Ziel | Bedeutet |
|---|---|
| selbst | wirkt beim Drücken auf den Helden |
| Richtung | Geschoss oder Schlag geradeaus; daneben ist daneben |
| um den Helden | ein Kreis um ihn |
| Bereich | ein Kreis, abgesetzt bis zur Wurfweite, auch hinter eine Wand |

**Farben:** funke, blitz, seele, klinge, natur, eis, sand, gift, zeit,
lava, stern, schutz. **Rot gehört dem Wächter.**

---

## Die Regeln der Ultimate

- **Kein Mana, keine Abklingzeit.** Sie lädt sich auf: jeder besiegte
  Gegner etwa ein Achtel, Treffer am Wächter auch. Jeder Lauf beginnt
  leer.
- Ein eigener Platz ab **Level 15**, und eine Ultimate liegt nur dort.
- **Keine Seltenheit**, ein goldener Doppelrand.
- **Quelle:** Baum, Kette oder Errungenschaft — nie die Grube.
  **Mindestens eine** der vier muss auf Level 15 über einen Knoten im
  Baum erreichbar sein.

## Mana

Mana ist die **Bremse** (ADR-0073): Wer alle drei Fähigkeiten im Takt
drückt, soll nach etwa 10 bis 15 Sekunden leer sein. Teure Fähigkeiten
dürfen deshalb kurze Abklingzeiten haben — bezahlt wird mit Mana. Ein
frischer Held hat 40; mehr darf keine kosten.

---

## Frederik

### Fähigkeiten

| # | Name | Bausteine | Ziel | Mana | Abklingzeit | Seltenheit | Quelle | Farbe | Icon / Animation |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Glutspur | Dash (etwa 4 Felder) + Dauerschaden entlang des Wegs: 0,4 × Angriff je Sekunde, 4 s, etwa ein Feld breit | Richtung; getippt in die Laufrichtung | 22 | 8 s | Selten | Knoten unter *Ausdauer & Fitness* (Sprint) | lava | der Held zieht einen Feuerstreifen hinter sich her |
| 2 | Fanghaken | Blink zum Gegner (bis etwa 5 Felder) + Hook zurück zum Ausgangspunkt + Schlag 1,0 × Angriff + Stun 1 s beim Ankommen | Richtung; getippt auf den nächsten sichtbaren Gegner, nie den Wächter | 18 | 10 s | Ungewöhnlich | Knoten unter *Psychologie* (Gruppendruck) | seele | ein violetter Faden reißt einen Gegner aus der Gruppe |
| 3 | Glückstrank | **Zufall** aus sechs Wirkungen, 6 s: Angriff +25 %, Schlagtempo +25 %, Lauftempo +30 %, Schaden −30 %, Heilung 15 % Leben, Jackpot (alles zugleich) | selbst | 15 | 12 s | Ungewöhnlich | Errungenschaft, etwa „zehn Tagestruhen geöffnet“ | stern | ein Trank, der in der Farbe seines Wurfs aufleuchtet |
| 4 | Wiederkehr | **Bumerang**: hin 1,0 × Angriff, zurück 1,0 × Angriff, Reichweite etwa 8 Felder, fliegt durch Gegner | Richtung; getippt auf den nächsten sichtbaren Gegner | 16 | 5 s | Ungewöhnlich | Knoten unter *Philosophie*, beim Existenzialismus | zeit | eine Kugel, die hinausfliegt und dem Helden zurück folgt |
| 5 | Schnappfalle | **Falle**: der erste Gegner, der drauftritt, nimmt 1,5 × Angriff und steht 2 s still; höchstens zwei zugleich, je 20 s | Bereich, bis etwa 5 Felder | 14 | 6 s | Gewöhnlich | Knoten unter *Gewohnheiten*, bei „Mach es offensichtlich“ (Umgebung gestalten) | klinge | eine eiserne Falle, die zuschnappt |
| 6 | Falke | **Begleiter**: pickt alle 0,8 s 0,5 × Angriff, 12 s lang | selbst | 25 | 20 s | Selten | die Kette, etwa 14 Tage | natur | ein Falke kreist über dem Helden und stößt herab |
| 7 | Steinschlag | Rundumschlag 2,2 × Angriff, Umkreis 1,5 Felder + **Terrain**: ein Fels, ein Feld, 8 s | Bereich, bis etwa 7 Felder | 26 | 10 s | Selten | Knoten unter *Kraft & Muskulatur* | sand | ein Fels stürzt herab und bleibt liegen |
| 8 | Rankenpeitsche | Schlag im Kegel davor (etwa 2,5 Felder) 1,2 × Angriff + **Wegschleudern** 2 Felder zur Seite | Richtung | 16 | 7 s | Gewöhnlich | Knoten unter *Philosophie*, beim Stoizismus | natur | eine Ranke peitscht von links nach rechts |
| 9 | Rückenwind | um den Helden, 3 Felder: Verlangsamen auf 50 %, 4 s + **Self-Buff** Lauftempo +30 %, 4 s | um den Helden | 20 | 14 s | Ungewöhnlich | Knoten unter *Ausdauer & Fitness* | zeit | ein Windstoß, der den Helden trägt und die anderen bremst |
| 10 | Eisball | Geschoss 1,0 × Angriff, etwa 8 Felder + **Stun** (gefroren) 2 s + **Zerspringen**: der nächste Treffer auf den Gefrorenen ist sicher kritisch und taut ihn auf | Richtung; getippt auf den nächsten sichtbaren Gegner | 20 | 8 s | Selten | die Kette, etwa 30 Tage | eis | eine Eiskugel, der Gegner erstarrt blau und zerspringt beim nächsten Schlag |

### Ultimates

| # | Name | Bausteine | Ziel | Quelle | Icon / Animation |
|---|---|---|---|---|---|
| U1 | Wassergrube | Bereich, Umkreis 3 Felder, bis etwa 7 Felder: **Hook** aller Gegner zur Mitte + **Stun** 3 s + Dauerschaden 0,3 × Angriff je Sekunde, 3 s | Bereich | Knoten im Baum, auf Level 15 erreichbar | der Boden bricht ein, Wasser strudelt, alles rutscht hinein |
| U2 | Fleischfressende Pflanze | **Begleiter**, der stehen bleibt, 10 s, Reichweite 2 Felder: alle 1,5 s ein Biss 1,5 × Angriff; ein Gegner unter 30 % Leben wird **gefressen** | Bereich, bis etwa 5 Felder | die Kette, etwa 30 Tage | eine Pflanze bricht aus dem Boden und schnappt zu |

### Ideen, noch nicht durchgegangen

Am 14.10. gesammelt und einsortiert; die Zeilen oben füllen sich, sobald
eine durchgegangen ist.

| Idee | So gemeint | Wohin |
|---|---|---|
| Pflanzenturm | steht still und schießt | Reserve — höchstens ein Begleiter zugleich |

**Neue Bausteine, die diese Ideen brauchen** (stehen noch nicht in
ADR-0073): Bumerang, Falle, Wegschleudern, Zerspringen (ein gefrorener
Gegner nimmt den nächsten Treffer sicher kritisch) und Zufall — der mit
dem Würfel des Laufs würfelt, sonst ist die Tagesgrube nicht mehr für
alle gleich.

### Festgelegt beim Durchgehen

- **Glutspur:** Der Dash geht durch Gegner, nicht durch Wände. Der
  Aufprall macht keinen Schaden, nur die Spur. Während des Dashs (etwa
  eine Fünftelsekunde) gibt es keinen Schutz. Die Spur liegt als Kette
  kleiner Kreise auf dem Weg — keine neue Form, und wer hineinläuft,
  brennt.
- **Fanghaken:** nur mit freier Sicht — ohne Linie kein Wurf und kein
  Mana. Der Wächter wird nie gezogen, der Haken füllt bei ihm nur eine
  Kerbe der Stun-Leiste. Der ganze Vorgang dauert etwa eine
  Drittelsekunde und lässt sich nicht unterbrechen.
- **Glückstrank:** die fünf einfachen Würfe je 19 von 100, der Jackpot
  5 von 100. **Kein Fehlwurf** — einen Platz, der manchmal bestraft,
  nimmt in einer knappen Grube niemand mit. Gewürfelt wird mit dem
  Würfel des Laufs, damit die Tagesgrube für alle gleich bleibt.
- **Wiederkehr:** jeder Gegner höchstens einmal je Weg. An einer Wand
  kehrt sie um; steht auf dem Rückweg eine Wand zwischen Kugel und Held,
  erlischt sie. Der Rückweg folgt dem Helden, wo er gerade steht.
- **Schnappfalle:** Gegner sehen sie nicht und weichen nicht aus. Der
  Wächter löst sie aus und füllt eine Kerbe. Nur auf freien Boden, nicht
  ins Tor; die dritte Falle lässt die älteste verschwinden.
- **Falke:** greift nur an, was der Held sieht — er fliegt, weckt aber
  keinen Raum hinter der Wand. Gegner greifen ihn nicht an. Seine Kills
  zahlen Beute, laden die Ultimate aber nicht.
- **Steinschlag:** Der Fels hält auch Pfeile auf — Deckung, die man sich
  selbst stellt. Wer darunter steht, wird an den Rand geschoben; er
  landet nie auf einer Figur. Nie in den Gang zum Tor, nie auf den
  einzigen Weg. Die Wegfelder werden beim Liegen und beim Verschwinden
  neu gerechnet.
- **Ab hier ohne Rückfrage** (Frederik: „bau alle so wie du denkst“).
- **Rankenpeitsche:** Geschleudert wird quer zur Schlagrichtung, eine
  Wand hält auf. Der Wächter wird nicht geschleudert.
- **Rückenwind:** Bremse und Eile gelten gleich lang; der Held ist
  danach wieder normal schnell.
- **Eisball:** Gefroren ist ein Stun — beim Wächter füllt er eine Kerbe,
  erst der dritte friert ihn ein. Zerspringen gilt für den nächsten
  Treffer des Helden, egal woher, auch vom Grundangriff.
- **Wassergrube:** Der Wächter wird nicht gezogen, sein Stun geht über
  die Leiste. Die Wassergrube ist die Ultimate, die auf Level 15 über
  den Baum erreichbar sein muss.
- **Fleischfressende Pflanze:** Fressen tötet sofort, aber nie den
  Wächter — ihn beißt sie nur. Was sie frisst, zahlt Beute und lädt
  die Ultimate nicht. Sie zählt als Begleiter: kommt sie, geht der
  Falke.

### Beim Bau entschieden (15.10.)

Gebaut auf `feat/ultimate-und-mana`. Was die Vorlage offen ließ und
ohne Rückfrage festgelegt wurde:

- **Die Knoten der Baum-Quellen:** Glutspur an „Intervalltraining“,
  Rückenwind an „Locker und lang“ (beide Ausdauer), Steinschlag an „Wie
  nah ans Versagen“ (Kraft), Fanghaken an „Die Macht der Mehrheit“
  (Asch), Wiederkehr an „Freiheit und Sinn“, Rankenpeitsche an „Was in
  deiner Macht steht“, Schnappfalle an „Mach es offensichtlich“, die
  **Wassergrube an „Erholung ist Teil der Arbeit“** — drei Punkte vom
  Start, auf Level 15 sicher bezahlbar.
- **Glückstrank:** eine neue Errungenschaft **„Zehn Truhen“** (zehn
  Tagestruhen geöffnet, Stufe mittel: 75 Erfahrung, 25 Gold, 10 Ruhm).
  Rückwirkend: Wer zehn Truhen hat, hat sie sofort.
- **Fanghaken ohne eigenen Blink.** Hin zum Gegner und mit ihm zurück
  endet genau dort, wo ein Haken endet; der Faden zeigt den Weg. Einen
  Blink braucht damit keine Fähigkeit, und er ist nicht gebaut.
- **Zwei Regeln weichen den Quellen:** Körper und Geist tragen jetzt je
  sieben Fähigkeiten statt höchstens drei (Grenze jetzt: keines mehr als
  zwei Fünftel), und die Gewohnheiten vergeben zwei Fähigkeiten über
  Errungenschaften statt einer.
- **Reichweiten, die fehlten:** Der Falke greift bis 7 Felder an, die
  Pflanze bis 2; die Ranke schleudert nach rechts; ein Fels liegt nie im
  Tor oder auf einem Feld daneben.
- **Bilder** aus dem Raven-Paket (`assets/RAVEN.md`), als Platzhalter
  gewählt — die Pflanze ist eine rote Blüte, der Falke ein geflügeltes
  Wesen; ein echter Vogel war nicht dabei.

**Gemessen** (`pit_sim`, Bot, 24 Läufe, Tag 30 ohne Ausrüstung):

- **Mana:** Drei Angriffe im Takt hängen an Tag 0 und Tag 30 in 62 bis
  67 % der Zeit am Mana, an Tag 60 mit bester Ausrüstung nur noch in
  18 %. Die Bremse greift früh, spät kaum — **nicht nachgestellt**.
- **Die Ultimate** ist nach etwa 16 Sekunden zum ersten Mal voll und
  kommt rund dreimal je Lauf. Auf Stufe 13 hebt sie die Siegquote des
  Bots um 20 bis 37 Punkte, auf Stufe 11 ändert sie fast nichts.
- **Frederiks Sätze** liegen auf Stufe 13 zwischen 8 % (Fanghaken,
  Steinschlag, Rückenwind) und 46 % (Wiederkehr, Schnappfalle, Ranke);
  die drei alten (Funkenstoß, Steinhaut, Blütentau) bei 42 %. Der Bot
  benutzt Haken, Fels und Wind schlecht — eine untere Schranke.

## AktivesBrett

Am 16.10. mit Claude zusammengestellt und gebaut
([ADR-0074](../decisions/0074-aktivesbretts-faehigkeiten.md)). Die Liste
war Claudes Vorschlag; AktivesBrett hat sie übernommen, Spiegelbild auf
Episch gesetzt und Bestform und Rückspulen als Ultimates gewählt.

### Fähigkeiten

| # | Name | Bausteine | Ziel | Mana | Abklingzeit | Seltenheit | Quelle | Farbe | Icon / Animation |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Zinseszins | **Stacking** + Schlag 0,8 × Angriff: jede Wiederholung binnen 4 s trifft 20 % härter, bis 5-mal | Richtung | 10 | 2 s | Gewöhnlich | „Zwei Minuten reichen“ | klinge | Klinge vor drei wachsenden Säulen |
| 2 | Schattenschritt | **Blink** bis 4 Felder + **Unsichtbarkeit** 2 s; der erste Treffer daraus ×1,5 | Richtung | 18 | 9 s | Ungewöhnlich | „Warum keiner hilft“ | seele | eine Gestalt mit Streifen dahinter; der Held wird durchscheinend |
| 3 | Kampfrausch | **Passiv**, **Rage**: je eingesteckten Treffer +4 %, bis 10-mal, fällt nach 4 s ohne Treffer ab | — | — | — | Selten | „Gefühle regulieren“ | lava | drei Klauenhiebe; Glutpunkte um den Helden, einer je Treffer |
| 4 | Kriegsschrei | **Stun** um den Helden (2 Felder) 0,8 s + Self-Buff Angriff +20 %, 6 s | um den Helden | 24 | 15 s | Selten | „Wie ein Muskel wächst“ | blitz | ein Horn, aus dem drei Bögen schallen |
| 5 | Spiegelbild | **Begleiter** als Abbild: schlägt 10 s mit dem Grundangriff zu halbem Schaden | selbst | 28 | 22 s | **Episch** | „Sich selbst testen“ | seele | zwei Gestalten am Spiegel; im Kampf der Held noch einmal, durchscheinend |
| 6 | Parade | **Parade**: 0,6 s offen, fängt einen Treffer ganz ab, der Angreifer steht 1,5 s | selbst | 12 | 6 s | Ungewöhnlich | „Eine Überschrift ist keine Studie“ | schutz | ein Schild, an dem eine Klinge abprallt; ein Bogen vor dem Helden |
| 7 | Ruhepuls | **Passiv**: 1 s ohne eigenen Treffer, und Mana kommt 40 % schneller | — | — | — | Gewöhnlich | „Schlaf & Regeneration“ | zeit | ein Herz mit Pulslinie |
| 8 | Kettenblitz | Geschoss 1,0 × Angriff, **springt** auf bis zu 3 weitere, je ×0,75 | Richtung | 22 | 6 s | Selten | „Medien & Information“ | blitz | ein Blitz und zwei kleine; im Kampf ein Faden je Sprung |
| 9 | Rammbock | **Dash** 3 Felder **mit Aufprall**: 1,2 × Angriff, 1,5 Felder zur Seite, 0,5 s Stillstand | Richtung | 20 | 9 s | Ungewöhnlich | „Technik vor Gewicht“ | sand | ein Balken mit Eisenkopf und Fahrtstreifen |
| 10 | Zweiter Atem | **Passiv**, einmal je Lauf: unter 20 % Leben heilt 25 % und 2 s halber Schaden | — | — | — | Episch | 7 Tage Kette | natur | ein grüner Kreis mit Plus; ein grüner Ring, wenn er greift |

### Ultimates

| # | Name | Bausteine | Ziel | Quelle | Icon / Animation |
|---|---|---|---|---|---|
| U1 | Bestform | 8 s: Fähigkeiten +40 %, kein Mana, Abklingzeit ×2 so schnell, Grundangriff +25 % (die Grenze), 40 % weniger Schaden | selbst | Errungenschaft „Sieben Tage in Form“ (sieben Tagestruhen) | ein goldener Stern; ein pulsierender goldener Doppelring |
| U2 | Rückspulen | zurück an Ort und Leben von vor 4 s, nie mit weniger Leben; 1,5 s unverwundbar | selbst | „Erinnerung ist kein Video“ | eine Uhr mit Pfeil gegen den Uhrzeigersinn; ein Zeitring |

### Festgelegt beim Bau

- **Die Grenze des Grundangriffs** ist jetzt `ActionBalance.weaponBuffCap`
  (1,25), für alles zusammen. Bestform und Kampfrausch treffen mit
  Fähigkeiten voll, mit dem Grundangriff höchstens bis dahin.
- **Blink** landet vor jeder Wand und vor dem Tor. Ohne Gegner in Sicht
  springt er dorthin, wohin der Held schaut — ein Ausweg ist kein
  verfehlter Wurf.
- **Unsichtbar** handeln Gegner nicht; **der Wächter schon**.
- **Parade** fängt auch Pfeile, dann steht der Schütze. Gegen Flächen
  hilft sie nicht.
- **Kettenblitz** springt nur auf Gegner, die vom Einschlag aus zu sehen
  sind, und keinen zweimal.
- **Rückspulen** geht nie über ein Tor zurück, das seitdem zugefallen
  ist, und nie in einen Fels; dann gibt es nur das Leben zurück.
- **Das Spiegelbild** steht links neben dem Helden und schlägt im Takt
  seiner Waffe; seine Kills laden die Ultimate nicht, wie beim Falken.
- **Die Bilder** sind gezeichnet (`tool/faehigkeit_icons.py`), nicht
  aus dem Raven-Paket.
