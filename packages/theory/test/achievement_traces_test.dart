import 'package:test/test.dart';
import 'package:theory/theory.dart';

/// Die Spur „gescheiterte Versuche je Lektion" aus ADR-0033 — und der
/// Fehler, der beim Einbauen auffiel.
void main() {
  final graph = theoryGraph;
  final node = graph.nodes.firstWhere((n) => !n.isFree);
  final lesson = node.lesson;

  List<int?> alleRichtig() => <int?>[
        for (final frage in lesson.questions) frage.correctIndex,
      ];

  List<int?> alleFalsch() => <int?>[
        for (final frage in lesson.questions) frage.correctIndex == 0 ? 1 : 0,
      ];

  group('Fehlversuche', () {
    test('ein bestandener erster Versuch hat keine', () {
      final ergebnis =
          const TheoryProgress.empty().submit(lesson, alleRichtig());
      final eintrag = ergebnis.progress.recordFor(lesson.id)!;

      expect(eintrag.isPassed, isTrue);
      expect(eintrag.failedAttempts, 0);
      expect(eintrag.isRetried, isFalse);
    });

    test('ein misslungener Versuch wird gezählt', () {
      final ergebnis =
          const TheoryProgress.empty().submit(lesson, alleFalsch());
      final eintrag = ergebnis.progress.recordFor(lesson.id)!;

      expect(eintrag.isPassed, isFalse);
      expect(eintrag.failedAttempts, 1);
      // Gescheitert ist nicht „zweiter Anlauf" — dafür fehlt der Erfolg.
      expect(eintrag.isRetried, isFalse);
    });

    test('erst scheitern, dann bestehen ergibt den zweiten Anlauf', () {
      var fortschritt = const TheoryProgress.empty();
      fortschritt = fortschritt.submit(lesson, alleFalsch()).progress;
      fortschritt = fortschritt.submit(lesson, alleRichtig()).progress;

      final eintrag = fortschritt.recordFor(lesson.id)!;
      expect(eintrag.isPassed, isTrue);
      expect(eintrag.failedAttempts, 1);
      expect(eintrag.isRetried, isTrue);
      expect(fortschritt.retriedNodeCount(graph), 1);
    });

    test('die Zahl steigt und fällt nie', () {
      var fortschritt = const TheoryProgress.empty();
      fortschritt = fortschritt.submit(lesson, alleFalsch()).progress;
      fortschritt = fortschritt.submit(lesson, alleFalsch()).progress;
      fortschritt = fortschritt.submit(lesson, alleRichtig()).progress;
      // Noch ein Durchgang, diesmal schlechter: Der Bestwert bleibt, die
      // Fehlversuche wachsen weiter.
      fortschritt = fortschritt.submit(lesson, alleFalsch()).progress;

      final eintrag = fortschritt.recordFor(lesson.id)!;
      expect(eintrag.failedAttempts, 3);
      expect(eintrag.isPassed, isTrue);
    });

    test('sie überlebt Speichern und Laden', () {
      var fortschritt = const TheoryProgress.empty();
      fortschritt = fortschritt.submit(lesson, alleFalsch()).progress;
      fortschritt = fortschritt.submit(lesson, alleRichtig()).progress;

      final geladen = TheoryProgress.fromJson(fortschritt.toJson());
      expect(geladen.recordFor(lesson.id)!.failedAttempts, 1);
      expect(geladen.retriedNodeCount(graph), 1);
    });

    test('ein Stand ohne Fehlversuche sieht aus wie vor ADR-0033', () {
      final fortschritt =
          const TheoryProgress.empty().submit(lesson, alleRichtig()).progress;
      final json = fortschritt.toJson()['records']! as Map<String, Object?>;
      final eintrag = json[lesson.id]! as Map<String, Object?>;

      expect(eintrag.containsKey('failedAttempts'), isFalse);
    });
  });

  // **Der Fehler, den diese Sitzung gefunden hat.** `submit` gab den
  // zweiten Konstruktorparameter nicht weiter, und weil er einen
  // Standardwert hat, schwieg der Compiler. Wirkung im Spiel: Wer einen
  // Knoten für einen Theoriepunkt öffnete und dann seine Seite bestand,
  // bei dem schloss sich der Baum wieder.
  group('Bestehen lässt den Baum offen', () {
    test('ein geöffneter Knoten bleibt nach dem Bestehen offen', () {
      final vorher = const TheoryProgress.empty().openNode(node.id);
      expect(vorher.openedNodeIds, contains(node.id));

      final nachher = vorher.submit(lesson, alleRichtig()).progress;

      expect(nachher.openedNodeIds, contains(node.id));
      expect(nachher.isNodeOpened(node.id, graph), isTrue);
    });

    test('auch ein misslungener Versuch nimmt nichts weg', () {
      final vorher = const TheoryProgress.empty().openNode(node.id);
      final nachher = vorher.submit(lesson, alleFalsch()).progress;

      expect(nachher.openedNodeIds, contains(node.id));
    });

    test('mehrere geöffnete Knoten überstehen eine Seite', () {
      final zwei = graph.nodes.where((n) => !n.isFree).take(2).toList();
      var fortschritt = const TheoryProgress.empty();
      for (final n in zwei) {
        fortschritt = fortschritt.openNode(n.id);
      }

      fortschritt =
          fortschritt.submit(zwei.first.lesson, alleRichtig()).progress;

      expect(
        fortschritt.openedNodeIds,
        containsAll(<String>[for (final n in zwei) n.id]),
      );
    });

    test('der bezahlte Punkt bleibt bezahlt', () {
      final vorher = const TheoryProgress.empty().openNode(node.id);
      final ausgegeben = vorher.spentPointsIn(graph);
      expect(ausgegeben, greaterThan(0));

      final nachher = vorher.submit(lesson, alleRichtig()).progress;
      expect(nachher.spentPointsIn(graph), ausgegeben);
    });
  });

  group('Gebiete', () {
    test('ein leerer Stand hat kein Gebiet und keinen Knoten', () {
      const leer = TheoryProgress.empty();
      expect(leer.completedAreaCount(graph), 0);
      expect(leer.areasWithPassedNodeCount(graph), 0);
    });

    test('eine Seite je Wurzel ergibt vier angefangene Gebiete', () {
      var fortschritt = const TheoryProgress.empty();
      for (final wurzel in graph.roots) {
        fortschritt = fortschritt.submit(wurzel.lesson, <int?>[
          for (final f in wurzel.lesson.questions) f.correctIndex,
        ]).progress;
      }

      expect(fortschritt.areasWithPassedNodeCount(graph), graph.roots.length);
      // Angefangen ist nicht fertig: Die Unterknoten fehlen noch.
      expect(fortschritt.completedAreaCount(graph), 0);
    });

    test('alle Seiten eines Gebiets ergeben ein fertiges Gebiet', () {
      final wurzel = graph.roots.first;
      var fortschritt = const TheoryProgress.empty();
      for (final n in graph.descendantsOf(wurzel.id, includeSelf: true)) {
        fortschritt = fortschritt.submit(n.lesson, <int?>[
          for (final f in n.lesson.questions) f.correctIndex,
        ]).progress;
      }

      expect(fortschritt.isAreaComplete(graph, wurzel.id), isTrue);
      expect(fortschritt.completedAreaCount(graph), greaterThanOrEqualTo(1));
    });
  });

  group('Fehlerfreie Seiten', () {
    test('nur ein makelloser Durchgang zählt', () {
      final knapp = <int?>[
        for (var i = 0; i < lesson.questions.length; i++)
          i == 0
              ? (lesson.questions[i].correctIndex == 0 ? 1 : 0)
              : lesson.questions[i].correctIndex,
      ];

      final fortschritt =
          const TheoryProgress.empty().submit(lesson, knapp).progress;
      expect(fortschritt.perfectNodeCount(graph), 0);

      final besser = fortschritt.submit(lesson, alleRichtig()).progress;
      expect(besser.perfectNodeCount(graph), 1);
    });
  });
}
