import 'package:test/test.dart';
import 'package:theory/theory.dart';

/// Das Handbuch im Baum (ADR-0070): fünf Knoten unter *Gewohnheiten*, der
/// Weg der Grundlagen und der nächste Schritt.
void main() {
  List<int?> richtig(Lesson lesson) => <int?>[
        for (final q in lesson.questions) q.correctIndex,
      ];

  TheoryNode knoten(String id) => theoryGraph.nodeById(id)!;

  /// Öffnet und besteht [ids] der Reihe nach.
  TheoryProgress gelesen(Iterable<String> ids) {
    var stand = const TheoryProgress.empty();
    for (final id in ids) {
      stand = stand.openNode(id);
      stand =
          stand.submit(knoten(id).lesson, richtig(knoten(id).lesson)).progress;
    }
    return stand;
  }

  group('die fünf Seiten', () {
    test('behalten ihre Lektions-Ids — alte Stände behalten sie', () {
      const seiten = <String, String>{
        'gewohnheiten-systeme': 'habits-01-systeme',
        'gewohnheiten-schleife': 'habits-02-schleife',
        'gewohnheiten-zwei-minuten': 'habits-03-zwei-minuten',
        'gewohnheiten-nie-zweimal': 'habits-04-nie-zweimal',
        'gewohnheiten-identitaet': 'habits-05-identitaet',
      };
      for (final MapEntry(key: nodeId, value: lessonId) in seiten.entries) {
        expect(knoten(nodeId).lesson.id, lessonId, reason: nodeId);
        expect(knoten(nodeId).cost, 1, reason: nodeId);
      }
    });

    test('„Zwei Minuten reichen“ ist Regel 3 und hängt bei den Regeln', () {
      expect(knoten('gewohnheiten-zwei-minuten').parentIds, <String>[
        'gewohnheiten-vier-regeln',
      ]);
      for (final id in <String>[
        'gewohnheiten-systeme',
        'gewohnheiten-schleife',
        'gewohnheiten-nie-zweimal',
        'gewohnheiten-identitaet',
      ]) {
        expect(knoten(id).parentIds, <String>['gewohnheiten'], reason: id);
      }
    });

    test('schalten weiter ihre drei Vorlagen frei', () {
      final vorlagen = <String?>[
        for (final lesson in habitsBranch.lessons) lesson.unlocksHabit,
      ].nonNulls.toList();

      expect(vorlagen, hasLength(3));
    });

    test(
        'ein alter Stand mit bestandenem Handbuch hat sie offen, ohne '
        'einen Punkt dafür zu zahlen', () {
      var alt = const TheoryProgress.empty();
      for (final lesson in habitsBranch.lessons) {
        alt = alt.submit(lesson, richtig(lesson)).progress;
      }

      final offen = alt.openIdsIn(theoryGraph);
      expect(offen, containsAll(theoryBasicsPath));
      expect(alt.spentPointsIn(theoryGraph), 0);
    });
  });

  group('der Weg der Grundlagen', () {
    test('enthält alle fünf Seiten', () {
      final lektionen = <String>{
        for (final id in theoryBasicsPath) knoten(id).lesson.id,
      };

      expect(
        lektionen,
        containsAll(habitsBranch.lessons.map((l) => l.id)),
      );
    });

    test('lässt sich in seiner Reihenfolge öffnen', () {
      // Jeder Schritt braucht einen Eltern, der vorher auf dem Weg lag —
      // sonst ginge er mit den Startpunkten nicht auf.
      final vorher = <String>{};
      for (final id in theoryBasicsPath) {
        final node = knoten(id);
        if (!node.isRoot) {
          expect(node.parentIds.any(vorher.contains), isTrue, reason: id);
        }
        vorher.add(id);
      }
    });

    test('kostet neun Punkte', () {
      final kosten =
          theoryBasicsPath.fold(0, (sum, id) => sum + knoten(id).cost);

      expect(kosten, 9);
    });

    test('wer ihn geht, hat am Ende genau das ausgegeben', () {
      final stand = gelesen(theoryBasicsPath);

      expect(stand.spentPointsIn(theoryGraph), 9);
      for (final lesson in habitsBranch.lessons) {
        expect(stand.isPassed(lesson.id), isTrue, reason: lesson.id);
      }
    });
  });

  group('der nächste Schritt auf dem Weg', () {
    test('ein leerer Stand soll Geist öffnen', () {
      final schritt = const TheoryProgress.empty().nextOnPath(
        theoryBasicsPath,
        theoryGraph,
        availablePoints: 9,
      );

      expect(schritt?.node.id, 'geist');
      expect(schritt?.needsOpening, isTrue);
    });

    test('ohne Punkt gibt es keinen Vorschlag', () {
      final schritt = const TheoryProgress.empty().nextOnPath(
        theoryBasicsPath,
        theoryGraph,
        availablePoints: 0,
      );

      expect(schritt, isNull);
    });

    test('was offen und ungelesen ist, wird gelesen statt gekauft', () {
      final schritt = const TheoryProgress.empty()
          .openNode('geist')
          .nextOnPath(theoryBasicsPath, theoryGraph, availablePoints: 0);

      expect(schritt?.node.id, 'geist');
      expect(schritt?.needsOpening, isFalse);
    });

    test('er folgt dem Weg Schritt für Schritt bis zum Ende', () {
      for (var i = 0; i < theoryBasicsPath.length; i++) {
        final schritt = gelesen(theoryBasicsPath.take(i)).nextOnPath(
          theoryBasicsPath,
          theoryGraph,
          availablePoints: 1,
        );

        expect(schritt?.node.id, theoryBasicsPath[i]);
        expect(schritt?.needsOpening, isTrue);
      }

      expect(
        gelesen(theoryBasicsPath).nextOnPath(
          theoryBasicsPath,
          theoryGraph,
          availablePoints: 9,
        ),
        isNull,
      );
    });
  });

  group('die Seite danach', () {
    test(
        'nach „Systeme schlagen Vorsätze“ kommt „Die Schleife“, und sie '
        'kostet', () {
      final stand = gelesen(theoryBasicsPath.take(4));

      final schritt = stand.nextAfter(
        'gewohnheiten-systeme',
        theoryGraph,
        availablePoints: 1,
      );

      expect(schritt?.node.id, 'gewohnheiten-schleife');
      expect(schritt?.needsOpening, isTrue);
    });

    test('was offen herumliegt, drängt sich nicht vor', () {
      // Eine offene, ungelesene Wurzel woanders: Die nächste Seite bleibt
      // die nächste im Buch.
      final stand = gelesen(theoryBasicsPath.take(4)).openNode('koerper');

      final schritt = stand.nextAfter(
        'gewohnheiten-systeme',
        theoryGraph,
        availablePoints: 1,
      );

      expect(schritt?.node.id, 'gewohnheiten-schleife');
    });

    test('ist die nächste schon offen, kostet sie nichts', () {
      final stand = gelesen(
        theoryBasicsPath.take(4),
      ).openNode('gewohnheiten-schleife');

      final schritt = stand.nextAfter(
        'gewohnheiten-systeme',
        theoryGraph,
        availablePoints: 0,
      );

      expect(schritt?.node.id, 'gewohnheiten-schleife');
      expect(schritt?.needsOpening, isFalse);
    });

    test('ohne Punkt und ohne offene Seite gibt es keine', () {
      const nach = 'gewohnheiten-systeme';
      final stand = gelesen(theoryBasicsPath.take(4));

      final schritt = stand.nextAfter(nach, theoryGraph, availablePoints: 0);

      expect(schritt, isNull);
    });

    test('die Regeln kommen in ihrer Reihenfolge: eins, zwei, drei', () {
      final bisRegeln = <String>[
        ...theoryBasicsPath.take(6),
      ];
      expect(bisRegeln.last, 'gewohnheiten-vier-regeln');

      var stand = gelesen(bisRegeln);
      var zuletzt = bisRegeln.last;
      final folge = <String>[];
      for (var i = 0; i < 3; i++) {
        final schritt = stand.nextAfter(
          zuletzt,
          theoryGraph,
          availablePoints: 1,
        );
        final id = schritt!.node.id;
        folge.add(id);
        stand = stand.openNode(id);
        stand = stand
            .submit(knoten(id).lesson, richtig(knoten(id).lesson))
            .progress;
        zuletzt = id;
      }

      expect(folge, <String>[
        'gewohnheiten-offensichtlich',
        'gewohnheiten-attraktiv',
        'gewohnheiten-zwei-minuten',
      ]);
    });

    test('ein unbekannter Knoten hat keine', () {
      expect(
        const TheoryProgress.empty().nextAfter(
          'gibt-es-nicht-und-soll-es-nie-geben',
          theoryGraph,
          availablePoints: 9,
        ),
        isNull,
      );
    });

    test('ist alles gelesen, gibt es keine', () {
      final alles = gelesen(theoryGraph.nodes.map((n) => n.id));

      expect(
        alles.nextAfter('geist', theoryGraph, availablePoints: 99),
        isNull,
      );
    });
  });
}
