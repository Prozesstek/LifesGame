import 'package:test/test.dart';
import 'package:theory/theory.dart';

/// Prüft, dass sich die richtige Antwort nicht verrät (ADR-0027).
///
/// Gemessen am 31.08.2026 war sie in **71 von 87 Fragen die längste** —
/// bei drei bis vier Antworten wäre der Zufall bei etwa 29 %. Wer das
/// Muster erkennt, besteht jede Seite ohne zu lesen, und die Theorie
/// gibt Erfahrung, Gold und Habit-Vorlagen für Mustererkennung statt
/// für Wissen.
///
/// Der Test läuft über **Handbuch und Graph**. `graph_content_test.dart`
/// sieht nur den Graphen; die fünf Handbuchseiten liest aber jeder als
/// Erstes.
void main() {
  // Handbuch und Graph überschneiden sich nicht — das prüft
  // `graph_content_test.dart` eigens.
  final seiten = <Lesson>[
    ...theoryGraph.nodes.map((n) => n.lesson),
    ...habitsBranch.lessons,
  ];

  /// Jede Frage einmal, mit einer Herkunft für die Fehlermeldung.
  final fragen = <({String quelle, Question frage})>[
    for (final seite in seiten)
      for (var i = 0; i < seite.questions.length; i++)
        (quelle: '${seite.id} F${i + 1}', frage: seite.questions[i]),
  ];

  test('es sind die erwarteten 29 Seiten', () {
    expect(seiten.length, 29);
  });

  group('Die richtige Antwort verrät sich nicht (ADR-0027)', () {
    test('keine Antwort enthält eine Klammer', () {
      // Ein Zusatz in Klammern ist fast immer eine Präzisierung — und
      // präzisiert wird die richtige Antwort.
      for (final (:quelle, :frage) in fragen) {
        for (final option in frage.options) {
          expect(
            option.contains('(') || option.contains(')'),
            isFalse,
            reason: '$quelle: "$option"',
          );
        }
      }
    });

    test('sie weicht höchstens 20 % vom Schnitt der falschen ab', () {
      final ausreisser = <String>[];

      for (final (:quelle, :frage) in fragen) {
        final richtig = frage.options[frage.correctIndex].length;
        final falsch = <int>[
          for (var i = 0; i < frage.options.length; i++)
            if (i != frage.correctIndex) frage.options[i].length,
        ];
        final schnitt = falsch.reduce((a, b) => a + b) / falsch.length;
        final abweichung = (richtig - schnitt) / schnitt;

        if (abweichung.abs() > 0.20) {
          ausreisser.add(
            '$quelle: richtig $richtig Zeichen, falsche im Schnitt '
            '${schnitt.round()} — ${(abweichung * 100).round()} %',
          );
        }
      }

      expect(
        ausreisser,
        isEmpty,
        reason: 'Repariert wird über die **falschen** Antworten: Eine falsche '
            'Antwort auf Länge zu bringen heißt, ihr einen echten Gedanken '
            'zu geben. Die richtige zu kürzen macht die Seite schlechter.\n'
            '${ausreisser.join('\n')}',
      );
    });

    test('keine Stelle trägt mehr als 40 % der Fragen', () {
      // Absicherung. Beim Anzeigen wird gemischt (ADR-0027), diese Regel
      // greift nur, falls irgendwo ungemischt angezeigt wird.
      final proStelle = <int, int>{};
      for (final (quelle: _, :frage) in fragen) {
        proStelle[frage.correctIndex] =
            (proStelle[frage.correctIndex] ?? 0) + 1;
      }

      for (final eintrag in proStelle.entries) {
        expect(
          eintrag.value / fragen.length,
          lessThanOrEqualTo(0.40),
          reason: 'Stelle ${eintrag.key} trägt ${eintrag.value} von '
              '${fragen.length} Fragen',
        );
      }
    });
  });
}
