# ADR-0015: Die Kampfdarstellung bekommt eine eigene Zeitachse

**Datum:** 21.08.2026
**Status:** Aktiv
**Entschieden von:** AktivesBrett

## Kontext

Der Kampf war rundenbasiert, spielbar und ausbalanciert — sah aber aus wie
zwei Rechtecke, die gleichzeitig aufblinken. Beim Versuch, daraus einen Kampf
zum Zusehen zu machen, trat ein Problem zutage, das im Nachhinein
offensichtlich ist:

**Die Engine liefert eine Runde als Liste.** Alles darin ist gleichzeitig
wahr:

```
MoveUsed(player, basic_attack)
DamageDealt(enemy, 14)
MoveUsed(enemy, heavy_attack)
DamageDealt(player, 11)
```

`playEvents` arbeitete diese Liste in **einem** Frame ab. Für eine Zahl im Log
ist das richtig. Für ein Bild ist es unbrauchbar: Ein Pfeil, der fliegen soll,
braucht eine Reihenfolge — erst spannen, dann fliegen, dann trifft es.

Die naheliegende Abhilfe wäre gewesen, die Engine Zeitstempel mitliefern zu
lassen. Das hätte [ADR-0002](0002-kampflogik-ohne-flame.md) ausgehöhlt.

## Entscheidung

**1. Die Darstellung bekommt eine Zeitachse.** `BattleGame` hält eine
Warteschlange von Bewegungen mit Zeitpunkten und arbeitet sie in `update()`
ab. Die Engine bleibt unverändert und weiß von Zeit weiterhin nichts.

**2. Wie ein Move aussieht, steht getrennt davon, was er tut.**
`lib/combat/battle/move_animation.dart` ordnet jeder Move-**Id** eine
Animation zu: Ausholzeit, Einschlagzeit, Art der Darstellung. In
`packages/combat` steht weiterhin nur Schaden, Energie und Wirkung.

**3. Die Zuordnung hängt an der Id, nie am Namen.** Namen sind Anzeigetext.
Der Basisangriff heißt seit heute „Bogenschuss" statt „Schlag" — `power` und
`energyDelta` sind unverändert.

**4. Flugzeit und Trefferzeitpunkt kommen aus derselben Quelle.** Die
Flugdauer eines Geschosses ist `impact - windUp`, und das Zucken des
Getroffenen wird auf `impact` eingeplant. Beide Zahlen stehen in derselben
`MoveAnimation`.

**5. Der Bildschirm sperrt die Eingabe, solange abgespielt wird.** Eine neue
`_Phase.animating` gibt die Knöpfe erst frei, wenn die letzte Bewegung durch
ist.

**6. Die Figuren sind gezeichnet, nicht geladen.** Kopf, Rumpf, Arme, Beine
aus Grundformen. Keine Bilddateien, keine Rive-Assets.

## Begründung

**Warum die Zeit in der Darstellung liegt und nicht in der Logik.** Eine
Engine, die Zeitstempel ausgibt, trifft Darstellungsentscheidungen — und
müsste angefasst werden, sobald eine Animation länger dauert. Dann wäre eine
Balance-Simulation von Animationsdauern abhängig. Die Trennung aus ADR-0002
ist genau dafür da.

**Warum Flugzeit und Treffer aus einer Quelle kommen.** Die erste Fassung
plante den Treffer auf die Abschusszeit ein: Der Getroffene zuckte, während
der Pfeil noch in der Luft war. Zwei Zahlen für denselben Zeitpunkt sind zwei
Zahlen, die auseinanderlaufen können.

**Warum Eingabe gesperrt wird.** Ohne Sperre lassen sich drei Runden in eine
Sekunde drücken, und die Pfeile aus Runde eins schlagen während Runde drei
ein. Die Sperre ist außerdem ehrlicher: Die Runde *ist* bereits ausgerechnet,
das Abspielen holt sie nur ein.

**Warum gezeichnete Figuren statt Rive.** Rive braucht Dateien aus einem
Editor. Gezeichnete Figuren laufen ohne Assets, jede Haltung entsteht aus
Zahlen, und die Schnittstelle (`aimBow`, `takeHit`, …) überlebt den späteren
Umstieg unverändert.

**Warum ein neuer Name für den Basisangriff.** Ein Move namens „Schlag", der
einen Pfeil verschießt, ist ein Widerspruch im Bild. Die Umbenennung kostet
nichts, weil nichts am Namen hängt — die Tests prüfen `move.name` symbolisch.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Zeitstempel in `CombatEvent` | Höhlt ADR-0002 aus; Balance-Simulation würde von Animationsdauern abhängen |
| Ein `onArrive`-Rückruf des Pfeils löst den Treffer aus | Zweite Quelle für denselben Zeitpunkt, die von der Zeitachse abweichen kann |
| Alle Events sofort abspielen, nur langsamer rendern | Löst die Reihenfolge nicht — gleichzeitig bleibt gleichzeitig |
| Eingabe nicht sperren | Runden überlagern sich, Geschosse aus alten Runden schlagen in neuen ein |
| Auf Rive warten | Der Kampf sähe bis dahin weiter aus wie zwei Rechtecke |
| Zuordnung über den Move-Namen | Namen sind Anzeigetext; eine Umbenennung würde die Animation stillschweigend abschalten |

## Konsequenzen

**Leichter:** Eine neue Animation ist ein Eintrag in `move_animation.dart` und
kann die Balance nicht anfassen. `battle_animation_test.dart` prüft die
Zuordnung ohne Renderer — jeder Move im Standard-Set braucht eine Animation,
und der Einschlag darf nie vor der Ausholbewegung liegen.

**Schwerer:** Eine Runde dauert jetzt spürbar Zeit statt null. Das ist
gewollt, macht den Kampf aber langsamer — bei einem Dungeon mit fünf Gegnern
wird das zur Frage. Ein Schnelldurchlauf wäre dann kein neues Konzept,
sondern ein Faktor auf der Zeitachse.

**Offen und sichtbar falsch:** Die Lebensbalken zeigen den Ausgang der Runde
**sofort**, während der Pfeil noch fliegt. Die Zahlen stimmen, die
Reihenfolge nicht. Der Balken müsste der Zeitachse folgen statt dem Zustand.

**Nicht berührt:** Frederiks Design-Notiz zum Kampfsystem (`Kampfsystem.docx`,
Initiative-Minispiel, Angriff/Ausweichen, Kontern) ist eine Frage der
**Regeln** und bleibt unentschieden. Diese Entscheidung betrifft
ausschließlich das Bild und nimmt ihr nichts vorweg.
