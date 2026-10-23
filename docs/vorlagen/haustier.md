# Das Haustier — Fortschritt, der nicht kämpft

> **Stand:** 23.10.2026 · **in jeder Fassung**, sobald es eine Gewohnheit
> gibt ([ADR-0086](../decisions/0086-das-haustier-fuer-alle.md)). Bis zum
> 22.10. nur im Entwicklermodus.
> Der ADR kommt, wenn Frederik und AktivesBrett es gespielt haben.

## Anlass

Frederik: „Nicht jede Spielergruppe will sich über den Kampf vergleichen.
Wir brauchen andere Möglichkeiten Fortschritt zu zeigen wie z.B.
Haustiere welche durch Gewohnheiten verbessert werden (Level, Verhalten,
Ausrüstung) oder zum Beispiel ein eigenes Haus oder Dorf was ausgebaut
werden kann.“

Bis dahin zeigte sich Fortschritt im Kampf (Grube, Ebenen, Wächter), in
Zahlen (Level, Skills seit ADR-0085, Ruhm) und im Haus-Prototyp, der nur
sammelt, was es schon gibt. Am 28.09. hatte Frederik das Dorf als
Navigation abgelehnt und notiert: „lieber die Haus-Idee ausbauen
(Möblieren, Haustiere)“ (Issue #88). ADR-0071 sagt: „Der Begleiter kommt
später mit dem Haus.“

## Entschieden in zwei Fragerunden

| Frage | Antwort |
|---|---|
| Womit anfangen? | **ein Haustier** — wie bei der App Finch; das Haus folgt als sein Zuhause |
| Ohne Häkchen? | **es wartet nur**: schläft oder sitzt da, wird nie traurig, krank oder läuft weg |
| Woran wächst es? | **an Tagen mit Häkchen**, nie zurück; das stärkste Gebiet prägt, wie es ausgewachsen aussieht |
| Wann? | **Prototyp jetzt, nur im Entwicklermodus** — der Tester-Build am 26.10. merkt nichts davon |
| Welches Wesen? | **drei Eier zur Wahl**: Drache, Eule, Katze — **gegen die Empfehlung** (ein Drache), Frederik will die Wahl |
| Ausrüstung? | **Laden für Gold, dazu verdiente Stücke** an Stufen — wer nicht kämpft, gibt sein Gold für das Tier aus |
| Wo lebt es? | **auf der Startseite über „Heute“**, wo abgehakt wird |
| Grafik? | **Platzhalter jetzt, echtes Paket später** |

## Was gebaut ist

| Was | Wie | Wo |
|---|---|---|
| **Drei Eier** | Drache (grün, gefleckt), Eule (hell, gesprenkelt), Katze (orange, gestreift); gewählt wird einmal | `HaustierArt`, `_EiWahl` |
| **Level** | jedes Level kostet einen Tag mit Häkchen mehr als das vorige: Level 2 nach 1 Tag, 5 nach 10, 10 nach 45, 27 nach 351 | `HaustierWachstum` |
| **Sechs Stufen** | Ei (0), Schlüpfling (3 Tage), Jung (15), Ausgewachsen (45), Prächtig (136), Uralt (351) | `HaustierStufe` |
| **Laune** | schläft (22–6 Uhr), wartet (nichts abgehakt), munter (etwas), spielt (alles — „In Form“), ruht (Ruhetag) | `HaustierLaune` |
| **Sprung** | mit jedem Häkchen von heute springt es | `HaustierBild.sprung` |
| **Prägung** | ab „Ausgewachsen“ trägt es das stärkste Gebiet: Stirnband (Körper), leuchtender Punkt (Geist), Brille (Wissenschaft), Herz (Gesellschaft) | `haustierPraegungProvider` |
| **Zubehör** | je Platz (Kopf, Hals, Spielzeug) gekaufte und verdiente Stücke; Preise 25 bis 120 Gold | `ZubehoerKatalog` |
| **Gold** | Zubehör ist der zweite Abfluss neben der Ausrüstung; Leiste und Laden ziehen es ab | `goldProvider`, `GearController` |
| **Blatt** | das Tier groß, Name ändern, der Weg durch die Stufen, Zubehör kaufen und anlegen; im Entwicklermodus Tage vorspulen | `HaustierBlatt` |

| Zubehör | Platz | Preis oder Stufe |
|---|---|---|
| Schleife | Kopf | ab Jung |
| Strohhut | Kopf | 40 Gold |
| Zauberhut | Kopf | 120 Gold |
| Krone | Kopf | ab Prächtig |
| Halstuch | Hals | 30 Gold |
| Glöckchen | Hals | 60 Gold |
| Umhang | Hals | ab Ausgewachsen |
| Ball | Spielzeug | 25 Gold |
| Kissen | Spielzeug | 50 Gold |
| Kristall | Spielzeug | ab Uralt |

**Gespeichert** wird nur, was gewählt wurde: Ei, Name, Gekauftes samt
Preis, Angelegtes (`HaustierStand`, im Spielstand unter `haustier`).
Wachstum, Laune und Prägung werden aus den Häkchen gerechnet.

**Das Bild** ist gezeichnet, nicht gemalt (`haustier_bild.dart`,
`haustier_schmuck.dart`): Formen und Farben, damit es atmen, blinzeln,
schlafen und springen kann. Kommt ein Grafikpaket, wird nur diese Stelle
getauscht.

## Ohne Rückfrage entschieden

- **Ein eigenes Package** (`packages/haustier`) wie beim Wechsel zur
  Grube: Rückbau ist ein Revert. Es kennt weder Gewohnheiten noch
  Gebiete; die App reicht Zahlen herein.
- **Level als Tage-Kurve**, nicht „Level = Tage“: Am Anfang geht es
  schnell, wie bei einem Jungtier, nach einem Jahr steigt es noch, nur
  seltener.
- **Die Stunde entscheidet über den Schlaf** (22 bis 6 Uhr), gleich was
  erledigt ist.
- **Der Kauf bekommt das Gold von außen**: Der Controller läse es sonst
  über `goldProvider` sich selbst (`gotchas.md`).
- **Ein gekauftes Stück legt sich an**, wenn sein Platz frei ist.
- **In Tests atmet es nicht** (`HaustierBild.lebt`), wie das Lagerfeuer.

## Offen — vor dem ADR

- **Spielen.** Ob es sich lebendig anfühlt, ob man morgens nachsieht,
  ob die Laune ohne Worte verständlich ist.
- **AktivesBrett hat es nicht gesehen.** Haus und Dorf hängen laut
  `state.md` an ihm; das Haustier ist der erste Schritt dorthin.
- **Gold gegen den Laden**: Zubehör konkurriert mit Ausrüstung.
  `runway_sim` zählt es nicht; ob die Preise stimmen, zeigt das Spielen.
- **Ein Grafikpaket mit drei Tieren in sechs Stufen** — oder dabei
  bleiben, gezeichnet.
- **Vergleichen**: ein Teilen-Text wie bei den Skills
  („Funki, Drache, Prächtig, Lv 18“)?
- **Das Haus als sein Zuhause** — der nächste Schritt aus der ersten
  Frage: Räume je Gebiet, Möbel, das Tier darin.
- **Ob die Karte über „Heute“ zu viel Platz nimmt**, wenn viele
  Gewohnheiten laufen.
