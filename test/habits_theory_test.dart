import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:theory/theory.dart';

/// Die Naht zwischen `package:theory` und `package:habits`.
///
/// Beide kennen einander nicht — sie treffen sich nur über den Wortlaut
/// der Gewohnheit (`Lesson.unlocksHabit` ↔ `HabitTemplate.name`). Genau
/// deshalb muss die Naht hier geprüft werden: Kein Package allein kann es,
/// und ein Tippfehler würde sonst erst dem Spieler auffallen, in Form
/// einer Vorlage, die es nie gibt.
void main() {
  final lessonsWithHabit = <Lesson>[
    for (final branch in theoryTree.branches)
      for (final lesson in branch.lessons)
        if (lesson.unlocksHabit != null) lesson,
  ];

  group('Skillbaum und Gewohnheiten passen zusammen', () {
    test('jede Lektion mit Vorlage findet ihre Vorlage', () {
      for (final lesson in lessonsWithHabit) {
        final name = lesson.unlocksHabit ?? '';
        expect(
          HabitCatalog.byName(name),
          isNotNull,
          reason:
              'Lektion "${lesson.id}" schaltet "$name" frei, aber der '
              'Katalog kennt diesen Namen nicht.',
        );
      }
    });

    test('jede Vorlage wird von genau einer Lektion freigeschaltet', () {
      for (final template in HabitCatalog.all) {
        final matches = lessonsWithHabit
            .where((l) => l.unlocksHabit == template.name)
            .toList();

        expect(
          matches,
          hasLength(1),
          reason:
              'Vorlage "${template.id}" wird von ${matches.length} '
              'Lektionen freigeschaltet, erwartet ist genau eine.',
        );
      }
    });

    test('die Vorlage nennt den Zweig, aus dem sie stammt', () {
      for (final template in HabitCatalog.all) {
        final lesson = lessonsWithHabit.firstWhere(
          (l) => l.unlocksHabit == template.name,
        );
        final branch = theoryTree.branchOfLesson(lesson.id);

        expect(
          template.branchId,
          branch?.id,
          reason: 'Vorlage "${template.id}" nennt den falschen Zweig.',
        );
      }
    });

    test('der Wurzelzweig gibt genug Vorlagen für einen ersten Tag her', () {
      // „Gewohnheiten" ist ohne Level offen. Wer ihn durchspielt, muss
      // danach eine tägliche Liste füllen können — sonst führt der
      // Skillbaum in einen leeren Tracker.
      final ausWurzel = habitsBranch.lessons
          .where((l) => l.unlocksHabit != null)
          .length;

      expect(ausWurzel, greaterThanOrEqualTo(3));
    });

    test('der ganze Baum schaltet den ganzen Katalog frei', () {
      var progress = const TheoryProgress.empty();
      for (final branch in theoryTree.branches) {
        for (final lesson in branch.lessons) {
          final answers = lesson.questions
              .map<int?>((q) => q.correctIndex)
              .toList();
          progress = progress.submit(lesson, answers).progress;
        }
      }

      final names = <String>[
        for (final branch in theoryTree.branches)
          ...progress.unlockedHabits(branch),
      ];

      expect(HabitCatalog.byNames(names), hasLength(HabitCatalog.all.length));
    });

    test('ohne Fortschritt ist keine Vorlage offen', () {
      const progress = TheoryProgress.empty();
      final names = <String>[
        for (final branch in theoryTree.branches)
          ...progress.unlockedHabits(branch),
      ];

      expect(names, isEmpty);
    });
  });
}
