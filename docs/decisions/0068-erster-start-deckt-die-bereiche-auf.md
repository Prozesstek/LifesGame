# ADR-0068: Der erste Start deckt die Bereiche nach und nach auf

**Datum:** 06.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik (in drei Fragerunden mit Claude)

## Kontext

Die Durchsicht vom 02.10. nannte zwei Dinge, die einen neuen Spieler
verlieren: **den Weg zum ersten Kampf** und **zu viele Systeme ohne
Erklärung**. Am 06.10. wollte Frederik an UX und UI weiterarbeiten und
hat diesen Block gewählt.

Der Stand davor, aus dem Code gelesen:

- Eine Einführung gab es nicht. Die Startseite zeigte vom ersten Start
  an sieben Kreise, Level, Gold und drei Tagesaufgaben.
- „Heute“ war leer: Die Startvorlage war freigeschaltet, lief aber
  nicht.
- Der Kampf-Kreis war gesperrt, bis eine Fähigkeit auf einem Platz lag
  ([ADR-0020](0020-kampf-haengt-am-moveset.md),
  [ADR-0025](0025-handbuch-sperrt-den-baum.md)). Bis dahin waren es acht
  Seiten mit je drei Fragen: fünf im Handbuch, dann Wurzel, Zwischenebene
  und Thema, danach anlegen.
- Die Sperre hatte ihren Grund verloren. Gemessen wurde sie im
  Rundenkampf; in der Grube steht Stufe 1 an Tag 0 **ohne Fähigkeit** bei
  93 % für den Bot (`pit_sim`, Spalte „Tag 0“).
  [ADR-0039](0039-die-grube-ersetzt-den-rundenkampf.md) führte sie
  deshalb als offen.

## Entscheidung

1. **Die Startseite fragt zuerst: „Was willst du jeden Tag tun?“** Die
   Frage steht als Karte an der Stelle von „Heute“, solange es keine
   Gewohnheit gibt. Sechs Vorschläge legen mit einem Tipp an; wer etwas
   Eigenes schreibt, wählt dazu einen der vier Werte.
2. **Die Kreise kommen nach und nach**, jeder an seinem festen Platz:

   | Kreis | Erscheint |
   |---|---|
   | Gewohnheiten | immer |
   | Kampf | mit dem ersten Häkchen |
   | Theorie | nach dem ersten Lauf, gewonnen oder verloren — oder mit dem dritten Häkchen |
   | Fähigkeiten | mit dem fertigen Handbuch |
   | Laden | sobald je so viel Gold verdient wurde, wie das billigste Stück kostet |
   | Ausrüstung | mit dem ersten Stück |
   | Charakter | mit Level 2 |

   Tagesaufgaben stehen ebenfalls erst ab dem ersten Häkchen da.
3. **Was als Nächstes dran ist, trägt einen Punkt und pulsiert dreimal**:
   erst der Kampf, dann die Theorie (bis die erste Fähigkeit gelernt
   ist), dann die Fähigkeiten (bis eine angelegt ist). Laden, Ausrüstung
   und Charakter leuchten nicht, sie erscheinen nur.
4. **Der Kampf kommt früh, und die Grube ist nie gesperrt.**
   `combatUnlockedProvider` und `lib/action/pit_gate.dart` sind
   gelöscht; in die Grube geht, wer will, mit der Waffe allein. Das hebt
   die Bedingung aus ADR-0020 auf. Das Handbuch sperrt weiter den Baum
   (ADR-0025), der Baum bringt weiter die Fähigkeiten.
5. **Der Stand des Tutorials wird abgeleitet, nicht gespeichert.**
   `ErsterStart.aus` rechnet aus Zahlen, die nur wachsen. Es gibt kein
   Feld im Spielstand, keine Übernahme und kein „Überspringen“.

Punkt 2 bis 5 hat Frederik in den Fragerunden gewählt: „eine Art
Tutorial, die nach und nach die Bereiche zeigt“, der nächste Kreis
leuchtet, die App fragt zuerst, „Kampf früh“, aus dem Stand abgeleitet.

**Ohne Rückfrage entschieden**, weil es sonst nicht aufgeht:

- **Die Frage ist eine Karte, kein Dialog.** Ein Dialog läge über einer
  Seite, die noch nichts zeigt, und wer ihn wegtippt, stünde vor der
  leeren Seite.
- **Der erste Vorschlag startet die Startvorlage** „Zwei Minuten lesen“
  statt eine eigene Gewohnheit anzulegen. Ein neuer Spieler hat genau
  einen Platz für eine eigene (`HabitRewards.customSlotsFor`); die
  anderen fünf Vorschläge und das freie Feld verbrauchen ihn.
- **Die Theorie kommt auch ohne Kampf**, mit dem dritten Häkchen. Wer
  die Grube auslässt, wäre sonst für immer vom Baum ausgesperrt.
- **Die erste Frage bietet „Ich habe schon einen Stand“.** Einfügen
  stand bis dahin nur im Charakter, und den gibt es auf einem neuen
  Gerät erst ab Level 2.
- **Ein versteckter Kreis behält seinen Platz**, nimmt aber keinen Tipp
  an und steht für den Vorleser nicht da.
- **Der Punkt statt eines Rings**: Ein Ring um den Kreis sah in der
  Vorschau aus wie der Fortschritt der Gewohnheiten daneben.

## Begründung

**Kampf vor Theorie**, weil der Kampf die Frage stellt, auf die die
Theorie antwortet. Wer zuerst acht Seiten liest, weiß nicht wofür; wer
Stufe 1 gespielt hat und danach das Buch leuchten sieht, schon. `konzept.md`
nennt den Kampf die Auszahlung des Fortschritts und nicht seine Quelle —
das bleibt: Die Grube zahlt je Stufe einmal, und ohne Fähigkeiten ist bei
Stufe 2 (63 % für den Bot an Tag 0) bald Schluss.

**Abgeleitet statt gezählt**, aus demselben Grund wie bei den
Errungenschaften ([ADR-0033](0033-errungenschaften-aus-der-historie.md)):
Unsere beiden Stände und jeder eingefügte sehen sofort alles, ohne dass
jemand eine Übernahme schreibt. Der Preis ist, dass ein Schritt nur an
etwas hängen kann, das im Stand steht — „hat den Laden einmal geöffnet“
geht nicht.

**Jede Zahl darf nur wachsen**, sonst verschwände ein Kreis wieder: je
gesetzte Häkchen statt „heute abgehakt“, je verdientes Gold statt des
Goldstands, je besessene Stücke statt des Inventars. Die einzige Zahl,
die fallen kann (angelegte Fähigkeiten), steuert nur ein Leuchten.

## Verworfene Alternativen

- **Eine Karte „Erste Schritte“ mit fünf Zeilen zum Abhaken.** Zeigt den
  ganzen Weg, bringt aber Sätze zurück, die
  [ADR-0060](0060-die-app-geht-ohne-lesen.md) entfernt hat.
- **Eine Begrüßung in drei Bildern.** Erklärt, bevor es etwas zu sehen
  gibt.
- **Alles sichtbar lassen, Gesperrtes verblasst.** Der kleinste Eingriff
  und die Linie bis dahin („ein Startbildschirm, der nur zeigt, was
  fertig ist, verschweigt, worum es geht“). Frederik hat sich dagegen
  entschieden.
- **Die Kette behalten und nur führen**, oder **ein Probekampf, danach
  die Sperre**. Beide lassen die acht Seiten vor dem eigentlichen Spiel
  stehen.
- **Ein gespeicherter Tutorial-Schritt**, mit oder ohne „Überspringen“.

## Konsequenzen

- Neu: `lib/home/erster_start.dart` (die Regel, reines Dart),
  `erster_start_provider.dart` (trägt zusammen),
  `lib/home/widgets/erste_gewohnheit.dart` (die Frage). In `gear`:
  `GearCatalog.cheapestPrice`.
- **Es bleiben dreizehn Stellen, an denen etwas zusammenläuft:**
  `ersterStartProvider` kommt, `combatUnlockedProvider` geht.
- **Tests anderer Bereiche überschreiben den Provider** mit
  `ErsterStart.allesOffen`, wenn sie von einem leeren Stand aus einen
  Kreis antippen.
- Ein neuer Bereich braucht einen Eintrag in `Bereich` und eine
  Bedingung in `ErsterStart.aus` — sonst steht sein Kreis nie da.
- ADR-0020 ist abgelöst. ADR-0025 gilt weiter für den Baum; sein Satz
  „der Kampf hängt am Moveset“ nicht mehr.

### Offen

- **Nicht gespielt, nicht am Handy.** Gerendert in 390 × 844 und
  angesehen sind die Frage, das Feld für Eigenes, der Stand nach dem
  ersten Häkchen und nach dem ersten Lauf.
- Ob Stufe 1 für einen Menschen am ersten Tag so leicht ist wie für den
  Bot, und ob eine Niederlage im allerersten Lauf eher zum Lesen führt
  oder zum Aufhören.
- **Die Grube selbst erklärt nichts**: Steuerung, Uhr und Tor stehen
  ohne Einführung da.
- **Die Bildschirme hinter den Kreisen sind unverändert.** Das Handbuch
  ist weiter fünf Lektionen lang, bevor der Baum aufgeht.
- Wer ein Eigenes anlegt, hat seinen einzigen Platz verbraucht; die
  nächste eigene Gewohnheit gibt es erst mit der nächsten Vorlage.
- Die Frage nach Auslöser, Wochentagen und Belohnung kommt am ersten Tag
  nicht von selbst, sondern erst über die Kachel.
- Level 2 für den Charakter und drei Häkchen für die Theorie sind
  gesetzt, nicht gemessen.
