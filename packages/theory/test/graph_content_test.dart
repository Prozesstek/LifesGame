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

    test('jede Wurzel kostet einen Punkt (ADR-0051)', () {
      // Auch welches Gebiet man betritt, ist eine Wahl. Bis ADR-0051
      // waren die Wurzeln kostenlos.
      for (final root in theoryGraph.roots) {
        expect(root.cost, 1, reason: root.id);
      }
    });

    test('jede Wurzel hat mindestens fünf Zwischenebenen', () {
      // Angekündigte zählen mit (ADR-0050): Die Zusage aus ADR-0019 ist,
      // dass ein Gebiet breit genug für eine Wahl ist — und das zeigt
      // der Baum, auch bevor jede Überschrift befüllt ist.
      for (final rootId in theoryRootIds) {
        final breite = theoryGraph.childrenOf(rootId).length +
            theoryGraph.placeholdersOf(rootId).length;

        expect(breite, greaterThanOrEqualTo(5), reason: rootId);
      }
    });

    test('jede Wurzel hat mindestens eine befüllte Zwischenebene', () {
      for (final rootId in theoryRootIds) {
        expect(theoryGraph.childrenOf(rootId), isNotEmpty, reason: rootId);
      }
    });

    test('jeder Knoten kostet genau einen Punkt', () {
      for (final node in nodes) {
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

    test('jedes Gebiet bringt mindestens zwei mit', () {
      // **Der Grund steht nicht im Issue.** Vorher trugen Körper und
      // Geist je fünf Fähigkeitsknoten, Wissenschaft einen,
      // Gesellschaft keinen. Sichtbar gemacht würde daraus „Körper und
      // Geist sind das Spiel, der Rest ist Lesestoff" — und
      // ausgerechnet Gesellschaft stützt die Habit-Vorlagen für Stärke
      // und Ausdauer (Issue #21, Punkt 8).
      for (final rootId in theoryRootIds) {
        final imGebiet = theoryGraph
            .descendantsOf(rootId)
            .where((n) => n.unlocksAbility != null);

        expect(
          imGebiet.length,
          greaterThanOrEqualTo(2),
          reason: 'Gebiet "$rootId" bringt nur ${imGebiet.length} Fähigkeiten '
              'mit. Kein Gebiet darf blosser Lesestoff sein.',
        );
      }
    });

    test('und keines mehr als drei', () {
      // Die Gegenrichtung. Ohne sie wäre die Regel oben erfüllt, sobald
      // jedes Gebiet zwei hat — auch wenn eines zehn trägt.
      for (final rootId in theoryRootIds) {
        final imGebiet = theoryGraph
            .descendantsOf(rootId)
            .where((n) => n.unlocksAbility != null);

        expect(imGebiet.length, lessThanOrEqualTo(3), reason: rootId);
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
    test('48 Knoten — vier Wurzeln, neun Zwischenebenen, 35 Themen', () {
      expect(theoryGraph.nodeCount, 48);
      expect(theoryGraph.roots.length, 4);
    });

    test('kostet achtundvierzig Theoriepunkte', () {
      final gesamt = nodes.fold(0, (sum, n) => sum + n.cost);

      expect(gesamt, 48);
    });

    test('sechzehn Überschriften sind angekündigt', () {
      expect(theoryGraph.placeholders.length, 16);
    });
  });

  group('Zwischenebenen (ADR-0050)', () {
    test('jede Ankündigung hängt direkt an einer Wurzel', () {
      for (final p in theoryGraph.placeholders) {
        expect(p.parentIds, isNotEmpty, reason: p.id);
        for (final parentId in p.parentIds) {
          expect(theoryRootIds, contains(parentId), reason: p.id);
        }
      }
    });

    test('kein Knoten hängt an einer Ankündigung', () {
      // Er wäre unerreichbar: Eine Ankündigung lässt sich nicht öffnen.
      final angekuendigt = theoryGraph.placeholders.map((p) => p.id).toSet();
      for (final node in nodes) {
        expect(
          node.parentIds.where(angekuendigt.contains),
          isEmpty,
          reason: node.id,
        );
      }
    });

    test('jedes Kind einer Wurzel hat eigene Kinder', () {
      // Eine befüllte Zwischenebene ohne Themen wäre ein Punkt für eine
      // Einführung ins Nichts. Stress und Vergleich hängen zusätzlich
      // direkt an Geist — sie sind Themen, keine Zwischenebenen.
      const querverbindungen = <String>{
        'koerper-stress',
        'gesellschaft-vergleich',
      };
      for (final rootId in theoryRootIds) {
        for (final kind in theoryGraph.childrenOf(rootId)) {
          if (querverbindungen.contains(kind.id)) continue;
          expect(theoryGraph.childrenOf(kind.id), isNotEmpty, reason: kind.id);
        }
      }
    });

    test('jedes alte Thema nimmt seinen Weg nach oben mit', () {
      // Die zwanzig Themen von vor ADR-0050 hingen direkt an einer
      // kostenlosen Wurzel. Wer eines offen hat, darf nach dem Umbau
      // keinen Punkt für Zwischenebene oder Wurzel nachzahlen müssen.
      final alteThemen = nodes.where((n) => _alteThemen.contains(n.id));
      expect(alteThemen.length, _alteThemen.length);

      for (final thema in alteThemen) {
        final stand = const TheoryProgress.empty().openNode(thema.id);
        final offen = stand.openIdsIn(theoryGraph);

        expect(stand.spentPointsIn(theoryGraph), 1, reason: thema.id);
        if (thema.parentIds.length == 1) {
          expect(
            offen.intersection(theoryRootIds.toSet()),
            isNotEmpty,
            reason: '${thema.id}: der Weg zur Wurzel muss mit offen sein',
          );
        }
      }
    });
  });

  group('Zählen über Zweige und Graph', () {
    test('Handbuch und Graph überschneiden sich nicht', () {
      final imGraph = theoryGraph.nodes.map((n) => n.lesson.id).toSet();
      final imHandbuch = habitsBranch.lessons.map((l) => l.id).toSet();

      expect(imGraph.intersection(imHandbuch), isEmpty);
    });

    test('zusammen sind es 53 Seiten', () {
      expect(theoryGraph.nodeCount + habitsBranch.lessonCount, 53);
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

/// Die Themen, die vor ADR-0050 direkt an einer Wurzel hingen.
const Set<String> _alteThemen = <String>{
  'koerper-schlaf',
  'koerper-bewegung',
  'koerper-ernaehrung',
  'koerper-erholung',
  'koerper-stress',
  'geist-aufmerksamkeit',
  'geist-gedanken',
  'geist-unbehagen',
  'geist-motivation',
  'geist-wiederholung',
  'wissenschaft-quelle',
  'wissenschaft-ursache',
  'wissenschaft-selbsttest',
  'wissenschaft-stichprobe',
  'wissenschaft-studie',
  'gesellschaft-umfeld',
  'gesellschaft-zugehoerigkeit',
  'gesellschaft-grenzen',
  'gesellschaft-vergleich',
  'gesellschaft-hilfe',
};
