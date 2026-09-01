# ADR-0026: Ein Bildschirm je Gebiet, und der Baum wächst nach oben

**Datum:** 31.08.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

[ADR-0019](0019-skillbaum-mit-vier-wurzeln.md) hat den Baum zeichnen lassen
statt ihn aufzulisten — das war gegenüber der Liste ein Fortschritt und ist
gegenüber dem Inhalt zu klein geblieben. Gebaut sind **vier Bänder
untereinander auf einer Zeichenfläche** mit `InteractiveViewer`, also freiem
Verschieben und Zoomen.

Bei 24 Knoten ist das bereits eng. Der Baum soll aber wachsen: Der Startbaum
ist zwei Ebenen flach (Wurzel plus fünf Kinder), und jede weitere Ebene macht
die gemeinsame Fläche unübersichtlicher, nicht übersichtlicher.

[Issue #21](https://github.com/Prozesstek/LifesGame/issues/21), Punkt 2:
„Layout von Skill Tree anpassen (maybe ein Oberknoten und swipebar, Skyrim)."

## Entscheidung

**Sechs Festlegungen:**

1. **Ein Bildschirm je Gebiet.** Körper, Geist, Wissenschaft, Gesellschaft —
   waagerecht durchwischen.
2. **Der Baum wächst nach oben.** Unten sitzt der Startknoten, darüber die
   nächste Ebene.
3. **Antippen zieht herein.** Der angetippte Knoten wandert nach unten und
   wird der neue Startknoten; seine Kinder erscheinen darüber.
4. **Antippen öffnet nicht.** Über dem angetippten Knoten erscheint ein
   **Öffnen**-Knopf. Zweiter Weg: noch einmal auf den unten sitzenden Knoten
   drücken. Ein Knoten ohne Kinder zieht nichts herein und öffnet direkt.
5. **Zurück ist immer sichtbar.** Der Elternknoten bleibt als flache Fläche
   unter dem Startknoten stehen; ein Druck darauf geht eine Ebene zurück,
   ebenso die Zurück-Geste des Geräts.
6. **Kopfzeile mit Fortschritt und Punkten.** Fortschritt des Gebiets groß,
   Gesamtfortschritt klein daneben, freie Theoriepunkte prominent — eigenes
   Icon, eigene Farbe, größere Schrift.

**`InteractiveViewer` entfällt.** Senkrecht wird gescrollt, waagerecht wird das
Gebiet gewechselt.

## Nachtrag 01.09.2026: ein Blatt öffnet doch nicht direkt

Punkt 4 endete mit dem Satz: „Ein Knoten ohne Kinder zieht nichts herein und
öffnet direkt." Beim Bauen hat sich gezeigt, dass dieser Satz gegen den echten
Baum die Überschrift desselben Punktes aufhebt.

**Zwanzig der vierundzwanzig Knoten sind Blätter.** Der Startbaum ist zwei
Ebenen flach: vier Wurzeln, zwanzig Kinder, keine dritte Ebene. Wörtlich
genommen hätte damit *jeder* Druck auf ein Kind sofort einen Theoriepunkt
gekostet — genau das Versehen, gegen das „Antippen öffnet nicht" geschrieben
wurde. Der Sonderfall war für einen tiefen Baum gedacht und traf einen flachen.

**Entschieden am 01.09.2026 von Frederik: Ein Blatt wird wie jeder andere
Knoten hereingezogen.** Es wandert nach unten, der Öffnen-Knopf erscheint
darüber, die Ebene darüber bleibt leer. Das kostet einen zweiten Druck und ist
die Auskunft „hier geht es nicht weiter" — statt einer Falle.

Die übrigen fünf Festlegungen bleiben unverändert.

## Begründung

**Ein Handy hat Höhe, keine Breite.** Das stand schon in ADR-0019 als
Begründung dafür, von oben nach unten zu zeichnen statt radial — und dann
lagen trotzdem vier Gebiete auf einer Fläche. Ein Gebiet je Bildschirm ist
dieselbe Einsicht, konsequent zu Ende geführt.

**Waagerecht kann nur eine Bedeutung haben.** Solange das Bild frei
verschiebbar ist, ist ein Wisch nach links zweideutig: Bild bewegen oder
Gebiet wechseln? Die Geste dem Gebietswechsel zu geben ist der Grund, warum
das freie Verschieben gehen muss — nicht Sparsamkeit.

**Antippen und Öffnen sind zwei Dinge, weil ein Knoten zwei Dinge ist:** ein
Ort im Baum und eine Seite zum Lesen. Sie auf dieselbe Geste zu legen heißt,
dass man beim Erkunden versehentlich Punkte ausgibt.

**Nach oben statt nach unten, aus zwei Gründen.** Der Startknoten liegt dort,
wo der Daumen ist. Und Fortschritt nach oben ist die Richtung, in der man ihn
ohnehin denkt — der Baum wächst dem Spieler entgegen, statt vor ihm
wegzulaufen.

**Das Hereinziehen ist die eigentliche Antwort auf das Wachstum.** Sichtbar
ist immer nur eine Ebene, egal wie tief der Baum wird. Ein Layout, das alles
zeigt, wird mit jedem Knoten schlechter; eines, das eine Ebene zeigt, bleibt
gleich gut.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Zeichenfläche behalten, nur enger zeichnen | Verschiebt das Problem um ein paar Knoten und kommt dann wieder. |
| Reiter statt Wischen | Vier Reiter kosten die Kopfzeile, die der Fortschritt braucht — und mit mehr Gebieten ginge es ohnehin nicht weiter. |
| Weiter von oben nach unten | Der Startknoten läge am oberen Rand, wo der Daumen nicht hinkommt, und jede neue Ebene schöbe den Baum aus dem Bild. |
| Alles auf einer Fläche lassen und nur den Zoom verbessern | Zoom ist Navigation ohne Orientierung: Man sieht entweder alles zu klein oder einen Ausschnitt ohne Zusammenhang. |
| Antippen öffnet sofort, Tiefe über eine zweite Geste | Die häufigere Handlung bekäme die versteckte Geste. Erkunden passiert oft, Öffnen kostet einen Punkt und soll bewusst sein. |

## Konsequenzen

**`tree_layout.dart` wird neu geschrieben, seine 13 Tests ebenso.** Sie halten
heute die alte Richtung fest (Bänder untereinander, Wurzel oben). Was bleibt,
ist das Prinzip dahinter, und es hat sich bewährt: **Die Anordnung ist eine
reine Funktion und wird ohne Renderer geprüft.**

**Die zwei verbindenden Knoten brauchen eine neue Regel.** *Stress* hängt an
Körper **und** Geist, *Vergleich* an Gesellschaft **und** Geist. Auf einer
gemeinsamen Fläche war das eine gestrichelte Linie quer durchs Bild — mit
einem Bildschirm je Gebiet gibt es kein „quer" mehr.

**Entschieden: Der Knoten erscheint in beiden Gebieten.** Er ist derselbe
Knoten — Id, Kosten und Zustand liegen im Graphen, nicht im Bild. Wer ihn in
Körper öffnet, findet ihn in Geist offen vor. Die gestrichelte Linie entfällt
ersatzlos; an ihre Stelle tritt ein Vermerk am Knoten, dass er zu zwei
Gebieten gehört. `tree_painter.dart` zieht damit nur noch Linien nach oben.

**Bis Inhalt nachwächst, zeigt das Hereinziehen mehr Mechanik, als der Baum
hat.** Zwei Ebenen bedeuten genau einen Schritt hinein. Das ist der Preis
dafür, das Layout **vor** dem Wachstum zu bauen statt danach — und die
Alternative wäre, es zweimal zu bauen.

**`test/phone_layout_test.dart` muss die neuen Bildschirme abdecken.** Vier
Gebiete heißen vier Zustände, die einzeln überlaufen können.
