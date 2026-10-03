# ADR-0065: Gewohnheiten aneinander koppeln

**Datum:** 02.10.2026
**Status:** Aktiv
**Entschieden von:** Frederik (in einer Fragerunde mit Claude)

## Kontext

Frederik: „Ich fände es noch cool, wenn man Gewohnheiten aneinander
koppeln kann wie im Buch *Die 1%-Methode*.“ Gemeint ist die
Gewohnheitskopplung: „Nach [bestehende Gewohnheit] mache ich [neue
Gewohnheit]“ — mehrere hintereinander ergeben einen Gewohnheitsstapel.

Der Baustein dafür war schon da: Seit ADR-0052 trägt jede Gewohnheit
einen **Auslöser**, eine Zeile freien Text („nach dem Zähneputzen“). Er
steht auf der Kachel, tut aber nichts — die App weiß nicht, wann das
Zähneputzen vorbei ist. Hängt eine Gewohnheit an einer anderen *in der
App*, weiß sie es: in dem Moment, in dem die abgehakt wird.

## Entscheidung

1. **Der Auslöser kann eine andere Gewohnheit sein** statt eines Satzes
   — der *Anker*. Gewählt wird er im Dialog „Wann machst du das?“ aus
   den laufenden Gewohnheiten.
2. **Die gekoppelte steht in „Heute“ eingerückt unter ihrem Anker**, und
   ein Stapel bleibt zusammen.
3. **Ist der Anker abgehakt, leuchtet die nächste auf** und bleibt
   markiert, bis sie erledigt ist.
4. **Keine Zahl und kein Schloss:** Eine Kopplung ändert weder
   Erfahrung noch Gold noch Ketten, und alles bleibt jederzeit abhakbar.
5. **Stapel beliebiger Länge**, jede Gewohnheit mit höchstens einem
   Anker, nie im Kreis.

## Begründung

**Ein Anker ist ein Auslöser, also gilt für ihn dieselbe Regel:** Er
erzeugt keine Zahl (ADR-0052) und darf sich deshalb jederzeit ändern —
kein Eintrag in einer Historie, anders als der Wochenplan (ADR-0064).
Ein Bonus für einen ganzen Stapel wurde verworfen: Dann koppelte jeder
alles an alles, nur wegen des Bonus, und die Levelkurve wäre neu zu
rechnen.

**Satz oder Anker, nie beides** (`HabitTracker.setAnchor` und `setCue`
ersetzen einander). Beides beantwortet dieselbe Frage, und zwei
Antworten wären eine zu viel — auf der Kachel wie im Kopf.

**Der Stapel bleibt zusammen** (`HabitStacks.order`). Die Tagesliste
sortiert sonst Erledigtes nach unten; ein abgehakter Anker rutschte
damit von seiner offenen Folge weg, genau in dem Moment, in dem man
sehen soll, woran sie hängt. Ein Stapel steht deshalb oben, solange
irgendein Glied offen ist, und wandert als Ganzes nach unten.

**Kein Schloss.** Wer zuerst liest und dann die Zähne putzt, hat beides
getan. Eine Sperre machte aus einem vergessenen Anker einen blockierten
Stapel — eine Strafe fürs Verpassen, die `konzept.md` 3.7 ausschließt.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Bonus-Erfahrung für den ganzen Stapel | Jeder koppelt alles an alles; eine fünfte Kurve neben den vier, die zusammenpassen müssen. |
| Reihenfolge erzwingen | Ein vergessener Anker blockiert den Stapel; Strafe fürs Verpassen. |
| Nur Paare | Kein Morgenablauf aus vier Schritten — und der ist der Kern der Idee im Buch. |
| Anker und Satz zugleich | Zwei Antworten auf eine Frage; die Kachel hat eine Zeile. |
| Kopplung als Historie wie der Wochenplan | Sie erzeugt keine Zahl, also gibt es nichts, was eine Änderung umschreiben könnte. |

## Konsequenzen

**Leichter:**

- Die App ist selbst der Auslöser: Das Häkchen an der einen Gewohnheit
  zeigt auf die nächste.
- Ein Morgen- oder Abendablauf steht als ein Block da.

**Schwerer, und bewusst so:**

- **Fehlt der Anker, steht die gekoppelte allein.** Ist er gestoppt
  oder heute nicht fällig (ADR-0064), steht sie ohne Einrückung in der
  Liste. Die Kopplung bleibt gespeichert und greift wieder, sobald der
  Anker zurück ist; die Zeile „Nach: …“ steht weiter auf der Kachel.
- **Die Priorität ordnet nur noch Stapel untereinander** und
  Geschwister unter demselben Anker. Eine „wichtige“ Gewohnheit, die an
  einer „nebenbei“ hängt, steht unter ihr.
- **Eingerückt wird höchstens drei Stufen**, sonst bliebe der letzten
  Kachel eines langen Stapels keine Breite.
- `tracker.dart` wächst weiter (rund 1.650 Zeilen); die Ordnung selbst
  liegt in `stack.dart`.

**Offen:**

- Ob das Aufleuchten (dreimal, dann nur noch die Kante) reicht oder zu
  leise ist.
- Koppeln geht nur an **laufende** Gewohnheiten und erst nach dem
  Anlegen, im selben Dialog wie die Wochentage.
- Die Theorie-Seite „Mach es offensichtlich“ (ADR-0061) nennt die
  Kopplung nicht und weist nicht auf die Funktion hin.
- Kein Klang beim Aufleuchten.
