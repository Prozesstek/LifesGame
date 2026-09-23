import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Die Tagesform: Was heute abgehakt ist, macht heute stärker — und zwar
/// genau in dem Wert, den die Gewohnheit trägt.
void main() {
  const heute = Day(2026, 9, 23);

  CustomHabit eigene(String id, HabitStat stat) {
    return CustomHabit(
      id: id,
      name: id,
      stat: stat,
      difficulty: HabitDifficulty.mittel,
      priority: HabitPriority.normal,
    );
  }

  /// Zwei Stärke-Gewohnheiten, eine für Ausdauer.
  HabitTracker dreiLaufende() {
    return const HabitTracker.empty()
        .addCustom(eigene('kraft-1', HabitStat.staerke), slots: 5)
        .addCustom(eigene('kraft-2', HabitStat.staerke), slots: 5)
        .addCustom(eigene('lauf', HabitStat.ausdauer), slots: 5)
        .activate('kraft-1')
        .activate('kraft-2')
        .activate('lauf');
  }

  const eins = HabitRewards.formPerCheck;

  test('ohne Häkchen ist alles beim Alten', () {
    final form = dreiLaufende().formOn(heute);

    for (final stat in HabitStat.values) {
      expect(form.factorFor(stat), 1, reason: stat.name);
    }
    expect(form.isInForm, isFalse);
  });

  test('ein Häkchen stärkt heute genau seinen Wert', () {
    final tracker = dreiLaufende().check('kraft-1', heute).tracker;
    final form = tracker.formOn(heute);

    expect(form.factorFor(HabitStat.staerke), closeTo(1 + eins, 1e-9));
    expect(form.factorFor(HabitStat.ausdauer), 1);
    expect(form.factorFor(HabitStat.disziplin), 1);
  });

  test('zwei Häkchen auf demselben Wert zählen doppelt', () {
    final tracker = dreiLaufende()
        .check('kraft-1', heute)
        .tracker
        .check('kraft-2', heute)
        .tracker;

    expect(
      tracker.formOn(heute).factorFor(HabitStat.staerke),
      closeTo(1 + 2 * eins, 1e-9),
    );
  });

  test('alles erledigt heisst in Form — ein Aufschlag auf alle vier', () {
    var tracker = dreiLaufende();
    for (final id in <String>['kraft-1', 'kraft-2', 'lauf']) {
      tracker = tracker.check(id, heute).tracker;
    }
    final form = tracker.formOn(heute);
    const alle = HabitRewards.formAllDone;

    expect(form.isInForm, isTrue);
    expect(
      form.factorFor(HabitStat.staerke),
      closeTo(1 + 2 * eins + alle, 1e-9),
    );
    expect(form.factorFor(HabitStat.ausdauer), closeTo(1 + eins + alle, 1e-9));
    expect(form.factorFor(HabitStat.klarheit), closeTo(1 + alle, 1e-9));
  });

  test('sie gilt nur für den Tag, an dem abgehakt wurde', () {
    final tracker = dreiLaufende().check('kraft-1', heute).tracker;

    expect(tracker.formOn(heute.next).factorFor(HabitStat.staerke), 1);
  });

  test('eine gestoppte Gewohnheit zählt nicht mehr', () {
    final tracker =
        dreiLaufende().check('kraft-1', heute).tracker.deactivate('kraft-1');

    expect(tracker.formOn(heute).factorFor(HabitStat.staerke), 1);
  });

  test('ohne laufende Gewohnheit ist niemand in Form', () {
    expect(const HabitTracker.empty().formOn(heute).isInForm, isFalse);
  });
}
