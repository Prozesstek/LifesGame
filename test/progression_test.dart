import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:progression/progression.dart';
import 'package:theory/theory.dart';

/// Antworten, die alle Fragen richtig treffen.
List<int?> _perfect(Lesson lesson) {
  return lesson.questions.map<int?>((q) => q.correctIndex).toList();
}

/// Antworten, die gerade so zum Bestehen reichen: die letzte Frage falsch.
List<int?> _barelyPassing(Lesson lesson) {
  final answers = _perfect(lesson);
  final last = lesson.questions.last;
  answers[answers.length - 1] = (last.correctIndex + 1) % last.options.length;
  return answers;
}

/// Spielt alle offenen Lektionen durch und gibt den neuen Stand zurück.
({TheoryProgress progress, bool didSomething}) _clearOpenLessons(
  TheoryProgress progress,
  int level,
  List<int?> Function(Lesson) answersFor,
) {
  var current = progress;
  var didSomething = false;

  for (final branch in theoryTree.unlockedAt(level)) {
    for (final lesson in branch.lessons) {
      if (current.isPassed(lesson.id)) continue;
      current = current.submit(lesson, answersFor(lesson)).progress;
      didSomething = true;
    }
  }

  return (progress: current, didSomething: didSomething);
}

void main() {
  _goldZuflussPasstZuDenPreisen();

  group('Level aus Theorie', () {
    test('ohne Fortschritt ist der Spieler Level 1', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(playerLevelProvider).level, 1);
      expect(container.read(totalXpProvider), 0);
      expect(container.read(goldProvider), 0);
    });

    test('bestandene Lektionen heben das Level', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(theoryProgressProvider.notifier);

      for (final lesson in habitsBranch.lessons) {
        controller.submit(lesson, _perfect(lesson));
      }

      final level = container.read(playerLevelProvider);
      expect(container.read(totalXpProvider), greaterThan(0));
      expect(level.level, greaterThan(1));
      expect(
        container.read(goldProvider),
        habitsBranch.lessonCount * TheoryRewards.goldForPass,
      );
    });

    test('der Wurzelzweig allein öffnet mindestens einen weiteren', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(theoryProgressProvider.notifier);

      for (final lesson in habitsBranch.lessons) {
        controller.submit(lesson, _perfect(lesson));
      }

      final level = container.read(playerLevelProvider).level;
      expect(theoryTree.unlockedAt(level).length, greaterThan(1));
    });
  });

  // Diese Gruppe prüft, was keines der beiden Packages allein prüfen kann:
  // ob Belohnungskurve (`theory`) und Levelkurve (`progression`) so
  // zusammenpassen, dass der Baum spielbar bleibt.
  group('Belohnung und Levelkurve passen zusammen', () {
    test('mit perfekten Antworten öffnet sich der ganze Baum', () {
      _expectTreeOpensCompletely(_perfect);
    });

    test('auch knapp bestandene Lektionen reichen aus', () {
      _expectTreeOpensCompletely(_barelyPassing);
    });

    test('der ganze Baum bringt mehr XP, als alle Sperren kosten', () {
      final highestUnlock = _highestUnlock;

      var progress = const TheoryProgress.empty();
      for (final branch in theoryTree.branches) {
        for (final lesson in branch.lessons) {
          progress = progress.submit(lesson, _barelyPassing(lesson)).progress;
        }
      }

      expect(
        progress.totalXp,
        greaterThanOrEqualTo(LevelCurve.totalXpFor(highestUnlock)),
      );
    });
  });

  // Dritte Naht: `habits` liefert Erfahrung, `progression` macht Level
  // daraus, `theory` hängt seine Zweige daran. Keines der drei Packages
  // kann diese Kette allein prüfen.
  group('Gewohnheiten und Levelkurve passen zusammen', () {
    test('Häkchen zahlen auf dasselbe Level ein wie Lektionen', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final habits = container.read(habitTrackerProvider.notifier);

      final template = HabitCatalog.all.first;
      habits.activate(template.id);
      habits.toggle(template.id, const Day(2026, 1, 1));

      expect(container.read(totalXpProvider), HabitRewards.xpPerCheck);
      expect(container.read(goldProvider), HabitRewards.goldPerCheck);
    });

    test('Erfahrung aus beiden Quellen addiert sich', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final lesson = habitsBranch.lessons.first;
      container
          .read(theoryProgressProvider.notifier)
          .submit(lesson, _perfect(lesson));
      final nurTheorie = container.read(totalXpProvider);

      final habits = container.read(habitTrackerProvider.notifier);
      final template = HabitCatalog.all.first;
      habits.activate(template.id);
      habits.toggle(template.id, const Day(2026, 1, 1));

      expect(
        container.read(totalXpProvider),
        nurTheorie + HabitRewards.xpPerCheck,
      );
    });

    test('der Baum öffnet sich in Tagen, nicht in Monaten', () {
      // Das Tempo ist eine Produktentscheidung, keine Nebenwirkung. Wer an
      // `habits/rewards.dart` oder `progression/level_curve.dart` dreht,
      // soll hier merken, wenn es kippt.
      final tage = _daysToLevel(_highestUnlock);

      expect(tage, greaterThan(0), reason: 'Der Baum öffnet sich nie.');
      expect(
        tage,
        inInclusiveRange(3, 21),
        reason:
            'Mit voller täglicher Liste braucht der letzte Zweig $tage Tage. '
            'Unter 3 ist die Levelsperre Deko, über 21 sperrt sie Inhalt weg.',
      );
    });

    test('das Maximallevel bleibt ein Fernziel', () {
      // Die Kurve ist laut ADR-0006 bewusst linear, damit späte Stufen
      // erreichbar bleiben — aber nicht in einem Monat.
      final tage = _daysToLevel(LevelCurve.maxLevel);

      expect(tage, greaterThan(120), reason: 'Level 50 nach $tage Tagen.');
    });
  });
}

/// Der höchste Level, den irgendein Zweig verlangt.
int get _highestUnlock {
  return theoryTree.branches
      .map((b) => b.unlockLevel)
      .reduce((a, b) => a > b ? a : b);
}

/// Wie viele Tage tägliches Abhaken bis zum Level [target] brauchen.
int _daysToLevel(int target) {
  final chosen = HabitCatalog.all
      .take(HabitRewards.maxActiveHabits)
      .map((t) => t.id)
      .toList();

  var tracker = const HabitTracker.empty();
  for (final id in chosen) {
    tracker = tracker.activate(id);
  }

  var day = const Day(2026, 1, 1);
  for (var tag = 1; tag <= 365; tag++) {
    for (final id in chosen) {
      tracker = tracker.check(id, day).tracker;
    }
    if (LevelCurve.levelFor(tracker.totalXp).level >= target) return tag;
    day = day.next;
  }
  return -1;
}

/// Spielt den Baum Stufe für Stufe durch und stellt sicher, dass er sich
/// nie festfährt: Wer alles Offene bestanden hat, muss dadurch genug
/// Erfahrung haben, um den nächsten Zweig zu öffnen.
void _expectTreeOpensCompletely(List<int?> Function(Lesson) answersFor) {
  var progress = const TheoryProgress.empty();
  var level = LevelCurve.levelFor(0).level;
  var rounds = 0;

  while (theoryTree.lockedAt(level).isNotEmpty) {
    final step = _clearOpenLessons(progress, level, answersFor);

    expect(
      step.didSomething,
      isTrue,
      reason:
          'Auf Level $level ist alles Offene bestanden, aber es öffnet '
          'sich nichts Neues — der Baum ist eine Sackgasse.',
    );

    progress = step.progress;
    level = LevelCurve.levelFor(progress.totalXp).level;

    rounds++;
    expect(rounds, lessThan(20), reason: 'Endlosschleife im Testaufbau');
  }

  expect(theoryTree.lockedAt(level), isEmpty);
}

/// Der vierte Fadenschluss: Passen die Preise im Laden zum Gold, das
/// tatsächlich hereinkommt?
///
/// `packages/gear/test/catalog_test.dart` prüft die Preise gegen eine
/// **angenommene** Tageseinnahme — es muss annehmen, weil `package:gear`
/// und `package:habits` einander bewusst nicht kennen. Hier steht die
/// Gegenprobe: Nur die App sieht beide Seiten. Ohne diesen Test könnte
/// jemand `HabitRewards.goldPerCheck` halbieren, und der Laden wäre
/// unbemerkt doppelt so teuer.
void _goldZuflussPasstZuDenPreisen() {
  group('Preise und Gold-Zufluss', () {
    /// Was ein Tag mit vollem Häkchen-Satz einbringt.
    final goldProTag = HabitRewards.goldPerCheck * HabitRewards.maxActiveHabits;

    test('die Annahme im Gear-Package stimmt noch', () {
      // Steht diese Zahl in `packages/gear/test/catalog_test.dart` als
      // `goldProTag`. Ändert sich die eine, muss die andere mit.
      expect(goldProTag, 25);
    });

    test('der erste Satz Ausrüstung ist in etwa einem Monat tragbar', () {
      final tage = GearCatalog.cheapestFullSetPrice / goldProTag;

      expect(
        tage,
        greaterThan(20),
        reason: 'Der Laden ist leer gekauft, bevor er interessant wird.',
      );
      expect(
        tage,
        lessThan(60),
        reason: 'Bis dahin hat niemand mehr Lust — der Laden bleibt Deko.',
      );
    });

    test('der ganze Skillbaum allein kauft den Laden nicht leer', () {
      // Theorie ist einmalig, Gewohnheiten sind täglich. Käme der ganze
      // Laden schon aus dem Lesen, hätte das Abhaken keinen Zweck mehr —
      // und das Konzept stellt Gewohnheiten ausdrücklich an die erste
      // Stelle.
      var progress = const TheoryProgress.empty();
      for (final branch in theoryTree.branches) {
        for (final lesson in branch.lessons) {
          progress = progress.submit(lesson, _perfect(lesson)).progress;
        }
      }

      final alles = GearCatalog.all.fold<int>(0, (sum, i) => sum + i.price);

      expect(
        progress.totalGold,
        lessThan(alles),
        reason: 'Der Skillbaum allein finanziert den kompletten Laden.',
      );
    });
  });

  group('Das Handbuch öffnet genau den zweiten Slot', () {
    // **Der Zusammenhang, auf dem ADR-0018 steht.** Der Kampf ist
    // gesperrt, bis der freie Zweig durch ist -- und das ist nur
    // deshalb die richtige Bedingung, weil derselbe Zweig genug
    // Erfahrung für Level 3 gibt. Auf Level 3 geht der zweite
    // Fähigkeitsslot auf, und erst mit zwei Moves ist der erste Kampf
    // überhaupt zu gewinnen (0 % gegen 100 % in der Simulation).
    //
    // Das ist gemessen, nicht entworfen: Wer an TheoryRewards, an der
    // Levelkurve oder an der Länge des Zweigs dreht, kann den
    // Zusammenhang zerstören, ohne es zu merken. Deshalb steht er hier
    // und nicht als Kommentar.

    TheoryProgress durchgearbeitet(TheoryBranch branch) {
      var progress = const TheoryProgress.empty();
      for (final lesson in branch.lessons) {
        progress = progress.submit(lesson, _perfect(lesson)).progress;
      }
      return progress;
    }

    final handbuch = theoryTree.branches.firstWhere(
      (b) => b.id == handbookBranchId,
    );

    test('das durchgearbeitete Handbuch reicht für Level 3', () {
      final xp = durchgearbeitet(handbuch).totalXp;
      final level = LevelCurve.levelFor(xp).level;

      expect(
        level,
        greaterThanOrEqualTo(AbilitySlots.levelForSlot(2)!),
        reason:
            'Das Handbuch gibt $xp Erfahrung und damit nur Level $level. '
            'Der zweite Fähigkeitsslot braucht Level ${AbilitySlots.levelForSlot(2)} '
            '-- ohne ihn ist der erste Kampf nicht zu gewinnen (ADR-0018).',
      );
    });

    test('ohne die letzte Lektion reicht es nicht', () {
      // Die Probe aufs Exempel: Die Bedingung ist der *abgeschlossene*
      // Zweig, nicht ein Teil davon. Wäre schon die Hälfte genug,
      // stünde die Sperre an der falschen Stelle.
      var progress = const TheoryProgress.empty();
      for (final lesson in handbuch.lessons.take(handbuch.lessons.length - 1)) {
        progress = progress.submit(lesson, _perfect(lesson)).progress;
      }

      expect(
        LevelCurve.levelFor(progress.totalXp).level,
        lessThan(AbilitySlots.levelForSlot(2)!),
        reason:
            'Wenn schon vier Lektionen für Level 3 reichen, ist die '
            'Sperre auf den ganzen Zweig unnötig streng.',
      );
    });

    test('das Handbuch kostet keinen Theoriepunkt', () {
      // ADR-0012: Der Zweig erklärt, wie die App funktioniert -- das
      // Handbuch gehört nicht hinter eine Sperre. Seit ADR-0018 hängt
      // zusätzlich der Zugang zum Kampf daran, also erst recht nicht.
      expect(handbuch.unlockLevel, LevelCurve.minLevel);
    });
  });
}
