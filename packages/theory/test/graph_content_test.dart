import 'package:test/test.dart';
import 'package:theory/theory.dart';

/// Prüft den Graphen aus ADR-0019 — Struktur **und** Inhalt.
///
/// Gleiche Absicht wie `content_test.dart` bei den Zweigen: Beim
/// Verdrahten von Knoten sind Tippfehler in Eltern-Ids und doppelte Ids
/// die wahrscheinlichsten Fehler, und beide fallen beim Durchklicken
/// kaum auf.
void main() {
  final nodes = theoryGraph.nodes;

  group('Der Graph ist gesund', () {
    test('keine doppelten Ids, keine Eltern-Id ins Leere, kreisfrei', () {
      expect(theoryGraph.duplicateIds, isEmpty);
      expect(theoryGraph.danglingParentIds, isEmpty);
      expect(theoryGraph.isAcyclic, isTrue);
      expect(theoryGraph.isHealthy, isTrue);
    });

    test('jede Lektions-Id kommt nur einmal vor', () {
      final ids = nodes.map((n) => n.lesson.id).toList();

      expect(ids.toSet().length, ids.length);
    });
  });

  group('Vier Wurzeln (Issue #16)', () {
    test('genau die vier geplanten', () {
      expect(theoryGraph.roots.map((n) => n.id), theoryRootIds);
    });

    test('alle Wurzeln sind kostenlos — der Einstieg kostet nichts', () {
      for (final root in theoryGraph.roots) {
        expect(root.isFree, isTrue, reason: root.id);
      }
    });

    test('jede Wurzel hat mindestens fünf Unterknoten', () {
      for (final rootId in theoryRootIds) {
        expect(
          theoryGraph.childrenOf(rootId).length,
          greaterThanOrEqualTo(5),
          reason: rootId,
        );
      }
    });

    test('alles außer den Wurzeln kostet genau einen Punkt', () {
      for (final node in nodes.where((n) => !n.isRoot)) {
        expect(node.cost, 1, reason: node.id);
      }
    });
  });

  group('Verbindende Knoten (ADR-0019 Punkt 5)', () {
    test('es gibt mindestens einen mit zwei Eltern', () {
      final verbindend = nodes.where((n) => n.parentIds.length > 1);

      expect(verbindend, isNotEmpty);
    });

    test('ein Elternteil genügt zum Öffnen', () {
      final verbindend = nodes.firstWhere((n) => n.parentIds.length > 1);
      final einElternteil = <String>{verbindend.parentIds.first};

      expect(theoryGraph.canOpen(verbindend.id, einElternteil), isTrue);
    });
  });

  group('Fähigkeiten am Baum', () {
    test('elf Knoten bringen eine Fähigkeit mit', () {
      // Seit ADR-0022 hängen elf der fünfzehn wählbaren Fähigkeiten am
      // Baum; die vier stärksten kommen über Streak-Marken. Die Zahl
      // steht hier, damit ein versehentlich entfernter Eintrag auffällt.
      final mitFaehigkeit = nodes.where((n) => n.unlocksAbility != null);

      expect(mitFaehigkeit.length, 11);
    });

    test('keine Wurzel bringt eine Fähigkeit mit', () {
      // Wurzeln kosten nichts (ADR-0019). Eine Fähigkeit dort wäre
      // geschenkt, noch bevor jemand einen Punkt ausgegeben hat.
      for (final node in nodes.where((n) => n.isRoot)) {
        expect(node.unlocksAbility, isNull, reason: node.id);
      }
    });

    test('keine Fähigkeit hängt an zwei Knoten', () {
      final ids = <String>[
        for (final node in nodes)
          if (node.unlocksAbility case final String id) id,
      ];

      expect(ids.toSet().length, ids.length);
    });
  });

  group('Inhalt jeder Knotenseite', () {
    test('jede hat Titel, Zusammenfassung, Abschnitte und Fragen', () {
      for (final node in nodes) {
        expect(node.name.trim(), isNotEmpty, reason: node.id);
        expect(node.summary.trim(), isNotEmpty, reason: node.id);
        expect(node.lesson.sections, isNotEmpty, reason: node.id);
        expect(node.lesson.questions.length, 3, reason: node.id);
      }
    });

    test('jeder Abschnitt hat Überschrift und Fließtext', () {
      for (final node in nodes) {
        for (final section in node.lesson.sections) {
          expect(section.heading.trim(), isNotEmpty, reason: node.id);
          expect(
            section.body.trim().length,
            greaterThan(40),
            reason: '${node.id}: ${section.heading}',
          );
        }
      }
    });

    test('jeder correctIndex zeigt auf eine vorhandene Antwort', () {
      for (final node in nodes) {
        for (final question in node.lesson.questions) {
          expect(question.correctIndex, greaterThanOrEqualTo(0));
          expect(
            question.correctIndex,
            lessThan(question.options.length),
            reason: '${node.id}: ${question.prompt}',
          );
        }
      }
    });

    test('keine Antwortmöglichkeit steht doppelt', () {
      for (final node in nodes) {
        for (final question in node.lesson.questions) {
          expect(
            question.options.toSet().length,
            question.options.length,
            reason: '${node.id}: ${question.prompt}',
          );
        }
      }
    });

    test('jede Frage hat mindestens zwei Antworten und eine Erklärung', () {
      for (final node in nodes) {
        for (final question in node.lesson.questions) {
          expect(question.options.length, greaterThanOrEqualTo(2));
          expect(question.explanation.trim(), isNotEmpty, reason: node.id);
        }
      }
    });

    test('die richtige Antwort liegt nicht immer an derselben Stelle', () {
      final stellen = <int>[
        for (final node in nodes)
          for (final question in node.lesson.questions) question.correctIndex,
      ];

      expect(stellen.toSet().length, greaterThan(1));
    });

    test('jeder Knoten hat ein Icon', () {
      for (final node in nodes) {
        expect(node.iconId.trim(), isNotEmpty, reason: node.id);
      }
    });
  });

  group('Der Startbaum in Zahlen', () {
    test('24 Knoten — vier Wurzeln und zwanzig Unterknoten', () {
      expect(theoryGraph.nodeCount, 24);
      expect(theoryGraph.roots.length, 4);
    });

    test('kostet zwanzig Theoriepunkte', () {
      final gesamt = nodes.fold(0, (sum, n) => sum + n.cost);

      expect(gesamt, 20);
    });
  });

  group('Zählen über Zweige und Graph', () {
    test('Handbuch und Graph überschneiden sich nicht', () {
      final imGraph = theoryGraph.nodes.map((n) => n.lesson.id).toSet();
      final imHandbuch = habitsBranch.lessons.map((l) => l.id).toSet();

      expect(imGraph.intersection(imHandbuch), isEmpty);
    });

    test('zusammen sind es 29 Seiten', () {
      expect(theoryGraph.nodeCount + habitsBranch.lessonCount, 29);
    });

    test('ein bestandener Knoten wird gezählt', () {
      final knoten = theoryGraph.nodes.first;
      final bestanden =
          const TheoryProgress.empty().submit(knoten.lesson, <int?>[
        for (final q in knoten.lesson.questions) q.correctIndex,
      ]).progress;

      expect(bestanden.passedNodeCount(theoryGraph), 1);
    });

    test('ohne Fortschritt ist nichts gezählt', () {
      expect(const TheoryProgress.empty().passedNodeCount(theoryGraph), 0);
    });
  });
}
