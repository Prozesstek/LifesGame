import 'package:test/test.dart';
import 'package:theory/theory.dart';

/// Prüft, dass bestandene Lektionen einen Neustart überleben.
void main() {
  /// Beantwortet die ersten [anzahl] Lektionen des Wurzelzweigs richtig.
  TheoryProgress mitBestandenen(int anzahl) {
    final branch = theoryTree.branches.first;
    var progress = const TheoryProgress.empty();

    for (final lesson in branch.lessons.take(anzahl)) {
      final antworten = <int?>[
        for (final question in lesson.questions) question.correctIndex,
      ];
      progress = progress.submit(lesson, antworten).progress;
    }
    return progress;
  }

  group('Speichern und laden', () {
    test('ein leerer Fortschritt bleibt leer', () {
      final gelesen = TheoryProgress.fromJson(
        const TheoryProgress.empty().toJson(),
      );

      expect(gelesen.totalXp, 0);
      expect(gelesen.totalGold, 0);
    });

    test('bestandene Lektionen bleiben bestanden', () {
      final branch = theoryTree.branches.first;
      final original = mitBestandenen(3);

      final gelesen = TheoryProgress.fromJson(original.toJson());

      expect(gelesen.passedCount(branch), original.passedCount(branch));
      expect(gelesen.totalXp, original.totalXp);
      expect(gelesen.totalGold, original.totalGold);
      for (final lesson in branch.lessons.take(3)) {
        expect(gelesen.isPassed(lesson.id), isTrue, reason: lesson.id);
      }
    });

    test('die nächste Lektion ist nach dem Laden weiterhin offen', () {
      final branch = theoryTree.branches.first;
      final gelesen = TheoryProgress.fromJson(mitBestandenen(2).toJson());

      final naechste = gelesen.nextLesson(branch);

      expect(naechste?.id, branch.lessons[2].id);
      expect(gelesen.isUnlocked(branch, branch.lessons[2].id), isTrue);
    });

    test('freigeschaltete Vorlagen bleiben freigeschaltet', () {
      // Die Naht zu `package:habits`: Ginge sie beim Speichern verloren,
      // stünde der Gewohnheiten-Bildschirm nach einem Neustart leer da.
      final branch = theoryTree.branches.first;
      final original = mitBestandenen(branch.lessonCount);

      final gelesen = TheoryProgress.fromJson(original.toJson());

      expect(gelesen.unlockedHabits(branch), original.unlockedHabits(branch));
      expect(gelesen.unlockedHabits(branch), isNotEmpty);
    });

    test('ein zweiter Versuch zahlt auch nach dem Laden nur die Differenz', () {
      // Ohne gespeicherte Auszahlung liesse sich dieselbe Lektion nach
      // jedem Neustart erneut kassieren.
      final lesson = theoryTree.branches.first.lessons.first;
      final gelesen = TheoryProgress.fromJson(mitBestandenen(1).toJson());

      final nochmal = gelesen.submit(lesson, <int?>[
        for (final question in lesson.questions) question.correctIndex,
      ]);

      expect(nochmal.xpGained, 0);
      expect(nochmal.goldGained, 0);
    });
  });

  group('Nachsicht beim Laden', () {
    test('unlesbare Einträge fallen weg, lesbare bleiben', () {
      final lessonId = theoryTree.branches.first.lessons.first.id;

      final gelesen = TheoryProgress.fromJson(<String, Object?>{
        'records': <String, Object?>{
          lessonId: <String, Object?>{
            'bestCorrect': 3,
            'questionCount': 3,
            'xpAwarded': 40,
            'goldAwarded': 20,
          },
          'kaputt': <String, Object?>{'bestCorrect': 'drei'},
          'unsinnig': <String, Object?>{
            // Mehr richtig als gefragt — das kann nicht sein.
            'bestCorrect': 9,
            'questionCount': 3,
            'xpAwarded': 40,
            'goldAwarded': 20,
          },
          'garnichts': 42,
        },
      });

      expect(gelesen.isPassed(lessonId), isTrue);
      expect(gelesen.totalXp, 40);
      expect(gelesen.isPassed('unsinnig'), isFalse);
    });

    test('Müll ergibt einen leeren Fortschritt statt einer Ausnahme', () {
      expect(TheoryProgress.fromJson(<String, Object?>{}).totalXp, 0);
      expect(
        TheoryProgress.fromJson(<String, Object?>{'records': 7}).totalXp,
        0,
      );
    });
  });
}
