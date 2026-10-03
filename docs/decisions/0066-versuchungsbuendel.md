# ADR-0066: Das Versuchungsbündel — eine Belohnung je Gewohnheit

**Datum:** 03.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik (in einer Fragerunde mit Claude)

## Kontext

Frederik: „Können wir ‚eine Gewohnheit muss attraktiv sein‘ irgendwie
einbauen?“ Gemeint ist die zweite Regel aus *Die 1%-Methode*.

Von den vier Regeln hatte die App zwei: **offensichtlich** (Auslöser,
ADR-0052; Koppeln, ADR-0065) und **befriedigend** (Erfahrung, Gold,
Kette, Truhe). Dazwischen fehlte die Vorfreude. Das Buch nennt dafür
das *Versuchungsbündel*: Was man tun **muss**, hängt an etwas, das man
tun **will** — „Nach [Gewohnheit] mache ich [was ich will]“.

Vier Wege standen zur Wahl: (A) eine selbstgesetzte Belohnung je
Gewohnheit, (B) den Spielertrag eines Häkchens vorab auf der Kachel
zeigen, (C) ein „Warum“ je Gewohnheit, (D) die Theorie-Seite zur Regel.
Gewählt wurde **A**.

## Entscheidung

1. **Jede Gewohnheit kann eine Belohnung tragen** — eine Zeile freier
   Text, „Kaffee“, „eine Folge schauen“. Vorlagen und eigene.
2. **Eingetragen wird sie im Dialog „Wann machst du das?“**, unter
   Auslöser und Wochentagen, mit Vorschlägen zum Antippen.
3. **Sie steht vor dem Häkchen da**: auf der Kachel und in „Heute“ auf
   der Startseite, mit einem Geschenk als Zeichen, solange die
   Gewohnheit offen ist.
4. **Beim Abhaken wird sie fällig**: In der Leiste unten steht für drei
   Sekunden „Jetzt: Kaffee“.
5. **Keine Zahl:** Sie ändert weder Erfahrung noch Gold noch Ketten.
6. **Unabhängig vom Auslöser:** Sie steht neben einem Satz **und** neben
   einem Anker. Zusammen ergibt das den ganzen Satz aus dem Buch — nach
   X mache ich Y, und danach gönne ich mir Z.

## Begründung

**Die Vorfreude treibt an, nicht die Belohnung.** Deshalb steht die
Zeile *vor* dem Häkchen auf der Kachel und fällt danach weg; nur einmal,
im Moment des Häkchens, sagt die App „Jetzt“.

**Dieselbe Bauform wie der Auslöser** (`HabitTracker.treatFor`,
`setTreat`, Abschnitt `treats` im Spielstand): eine Angabe des Spielers,
die nichts erzeugt, darf sich jederzeit ändern und braucht keine
Historie. `treat_test.dart` hält fest, dass sie keine Zahl bewegt —
solche Felder wachsen sonst gern in die Rechnung hinein.

**B wurde zurückgestellt**, weil es mehr Zeichen auf eine schon volle
Kachel legte (ADR-0060) und nichts Neues gäbe, nur früher zeigte. **C**
überschneidet sich mit der zurückgestellten Identität im
Wochenrückblick. **D** kommt, wenn Frederik das Kapitel als Seite
mitbringt (ADR-0061).

## Konsequenzen

- **Die App gibt die Belohnung nicht und prüft sie nicht.** Sie ist ein
  Versprechen an sich selbst, wie das Häkchen eine Behauptung ist. Ob
  „Jetzt: Kaffee“ trägt, wenn niemand den Kaffee kontrolliert, zeigt
  das Spielen.
- **„Bleibt stehen, bis eingelöst“ wurde verworfen**: Das wäre ein
  zweites Häkchen je Gewohnheit, und die App verwaltete dann
  Belohnungen statt Gewohnheiten.
- **Der Dialog ist umgebaut:** Die Vorschläge stehen in einer Zeile zum
  Wischen statt umgebrochen. Umgebrochen lag die Belohnung auf dem
  Handy erst nach zwei Bildschirmen Rollen.
- Auf der Kachel steht eine Zeile mehr; auf der Startseite wird „Heute“
  je Gewohnheit mit Belohnung rund 14 Punkte höher.
- Wer das Häkchen zurücknimmt und neu setzt, sieht „Jetzt: …“ noch
  einmal. Das ist hingenommen — es erzeugt nichts.
