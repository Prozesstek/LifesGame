import 'package:test/test.dart';
import 'package:theory/theory.dart';

/// Vorschläge für das nächste Kapitel (26.10.2026): bis zu drei, jeder
/// mit Grund, abhängig davon, was gelesen und abgehakt wurde.
void main() {
  final graph = theoryGraph;

  TheoryProgress bestehe(TheoryProgress p, String nodeId) {
    final node = graph.nodeById(nodeId)!;
    return p.openNode(nodeId).submit(node.lesson, <int?>[
      for (final q in node.lesson.questions) q.correctIndex,
    ]).progress;
  }

  List<TheoryVorschlag> vorschlaege(
    TheoryProgress p, {
    int punkte = 3,
    Map<String, int> gewicht = const <String, int>{},
  }) =>
      p.vorschlaege(
        graph,
        path: theoryBasicsPath,
        availablePoints: punkte,
        gewicht: gewicht,
      );

  test('der erste ist immer der bisherige Vorschlag', () {
    // Wer nicht wählen will, nimmt den ersten — und der Mentor zeigt auf
    // ihn. Geprüft Schritt für Schritt den Weg der Grundlagen entlang.
    var p = const TheoryProgress.empty();
    for (final id in theoryBasicsPath) {
      final alt = p.suggestedStep(
        graph,
        path: theoryBasicsPath,
        availablePoints: 3,
      );
      final neu = vorschlaege(p);
      expect(neu.first.node.id, alt?.node.id, reason: 'vor $id');
      p = bestehe(p, id);
    }
  });

  test('nach den Grundlagen gibt es weiter Vorschläge', () {
    var p = const TheoryProgress.empty();
    for (final id in theoryBasicsPath) {
      p = bestehe(p, id);
    }

    expect(
      p.suggestedStep(graph, path: theoryBasicsPath, availablePoints: 3),
      isNull,
      reason: 'Hier stand bisher nichts.',
    );
    expect(vorschlaege(p), isNotEmpty);
  });

  test('höchstens drei, keine Seite zweimal', () {
    var p = const TheoryProgress.empty();
    for (final id in <String>['koerper', 'geist', 'kraft-muskulatur']) {
      p = bestehe(p, id);
    }
    final v = vorschlaege(p, punkte: 10, gewicht: <String, int>{'geist': 5});

    expect(v.length, lessThanOrEqualTo(3));
    expect(v.map((x) => x.node.id).toSet(), hasLength(v.length));
  });

  test('weiter, wo zuletzt gelesen wurde', () {
    var p = const TheoryProgress.empty();
    for (final id in theoryBasicsPath) {
      p = bestehe(p, id);
    }
    p = bestehe(bestehe(p, 'koerper'), 'kraft-muskulatur');

    final weiter = vorschlaege(
      p,
    ).where((v) => v.grund == TheoryVorschlagGrund.weiter);
    expect(weiter, hasLength(1));
    expect(weiter.single.node.parentIds, contains('kraft-muskulatur'));
    expect(weiter.single.step.needsOpening, isTrue);
  });

  test('das Gebiet mit den meisten Häkchen wird vorgeschlagen', () {
    var p = const TheoryProgress.empty();
    for (final id in theoryBasicsPath) {
      p = bestehe(p, id);
    }
    final v = vorschlaege(
      p,
      gewicht: <String, int>{'gesellschaft': 400, 'koerper': 30},
    );

    final passend =
        v.where((x) => x.grund == TheoryVorschlagGrund.gewohnheiten);
    expect(passend, hasLength(1));
    expect(graph.rootIdsOf(passend.single.node.id), contains('gesellschaft'));
  });

  test('ein unberührtes Gebiet kommt dazu', () {
    var p = const TheoryProgress.empty();
    for (final id in theoryBasicsPath) {
      p = bestehe(p, id);
    }
    final neu = vorschlaege(
      p,
    ).where((x) => x.grund == TheoryVorschlagGrund.neuesGebiet);

    expect(neu, hasLength(1));
    expect(neu.single.node.isRoot, isTrue);
    expect(p.hasPassedInArea(graph, neu.single.node.id), isFalse);
  });

  test('ohne freien Punkt bleibt nur, was schon offen ist', () {
    var p = const TheoryProgress.empty();
    for (final id in theoryBasicsPath) {
      p = bestehe(p, id);
    }
    expect(vorschlaege(p, punkte: 0), isEmpty);

    final offen = p.openNode('koerper');
    final v = vorschlaege(offen, punkte: 0);
    expect(v.map((x) => x.node.id), <String>['koerper']);
    expect(v.single.grund, TheoryVorschlagGrund.offen);
  });

  test('die Reihenfolge des ersten Versuchs übersteht das Speichern', () {
    var p = const TheoryProgress.empty();
    for (final id in <String>['geist', 'koerper']) {
      p = bestehe(p, id);
    }
    final geladen = TheoryProgress.fromJson(p.toJson());
    expect(geladen.passedInOrder, p.passedInOrder);
    expect(
      graph.nodeById('koerper')!.lesson.id,
      geladen.passedInOrder.last,
    );
  });
}
