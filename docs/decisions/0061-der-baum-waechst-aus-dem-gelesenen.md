# ADR-0061: Der Baum wächst aus dem Gelesenen

**Datum:** 30.09.2026
**Status:** Aktiv
**Entschieden von:** Frederik

## Kontext

Frederik liest täglich (eine seiner Gewohnheiten) und will, was er liest,
in die App bringen: als Überblick über das eigene Wissen und als Wissen,
das anderen weiterhilft. Anlass war *Die 1%-Methode* (James Clear) und
seine eigene Umsetzung daraus — Wasserflaschen und Gemüse sichtbarer in
der Wohnung hinstellen.

Gewünscht war dafür eine Gliederung, die tiefer ist als die drei Ebenen
aus [ADR-0050](0050-zwischenebenen-und-angekuendigte-gebiete.md):
Selbstentwicklung → **Gewohnheiten** → **Die vier Regeln** → **Mach es
offensichtlich**.

## Entscheidung

Ein Thema darf eigene Kinder haben; der Baum ist unter der Zwischenebene
so tief, wie der Inhalt es verlangt. Neue Seiten entstehen aus dem, was
einer von uns liest: Er erzählt in der Sitzung, was er gelesen hat und
was er davon umsetzt, und daraus wird eine Seite mit drei Fragen —
eingehängt dort, wo sie inhaltlich hingehört.

## Begründung

Die Oberfläche kann das schon: `TreeView` zeigt immer einen Knoten und
eine Ebene darüber und folgt einem Pfad beliebiger Länge (ADR-0026).
Die Regel „jeder Knoten ein Punkt“ (ADR-0051) gilt unverändert — tiefer
heißt teurer, und das ist gewollt: Man wählt, man lernt nicht alles
(ADR-0037).

Aus dem eigenen Lesen zu schreiben hält die Theorie an dem, was die
Spieler tatsächlich beschäftigt, und macht sie zum Nachschlagewerk
ihres eigenen Wissens.

## Verworfene Alternativen

| Alternative | Warum verworfen |
|---|---|
| Alles flach als Themen unter „Selbstentwicklung“ | Die vier Regeln sind eine Gliederung, keine vier losen Seiten. Flach würde Selbstentwicklung bei jedem Buch breiter und unübersichtlicher. |
| Eine Eingabe in der App, aus der die Seite entsteht | Seiten brauchen drei faire Fragen und laufen durch `question_fairness_test.dart`. Das geht heute nur im Repo. Ob es später eine Eingabe gibt, ist offen. |
| Die Regeln 2–4 als „Inhalt folgt“ ankündigen | Ankündigungen hängen bisher nur an Wurzeln (`graph_content_test.dart`). Die Seite „Die vier Regeln“ nennt alle vier; die Kinder kommen, wenn sie gelesen sind. |

## Konsequenzen

- Der Baum wird ungleichmäßig tief. Das ist gewollt, macht aber Aussagen
  wie „drei Ebenen“ in älteren Texten ungenau.
- Jeder neue Knoten kostet einen Punkt; der Baum war schon vorher größer
  als ein Spielerleben (54 gegen 50), jetzt 57.
- Die Seiten sind Zusammenfassungen fremder Bücher in eigenen Worten,
  keine Zitate. Zahlen aus Studien stehen als Größenordnung.
- Wer eine solche Seite schreibt, prüft sie gegen das Handbuch: Dort
  steht die Gewohnheitsschleife schon, und sie soll nicht doppelt stehen.
