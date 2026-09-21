import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Was ein Häkchen einbringt, **bevor** es gesetzt ist.
///
/// Die Rechnung stand bis Issue #46 nirgends: Die Kachel zeigte den
/// Multiplikator, aber nicht, was er in Erfahrung bedeutet. Sie hier zu
/// halten ist dieselbe Regel wie überall — wer eine Spielzahl in `lib/`
/// ausrechnet, hat sie an der falschen Stelle.
const Day _tag1 = Day(2026, 8, 10);

HabitTemplate _vorlage() => HabitCatalog.all.first;

HabitTracker _mitKette(int tage) {
  var tracker = const HabitTracker.empty().activate(_vorlage().id);
  var tag = _tag1;
  for (var i = 0; i < tage; i++) {
    tracker = tracker.check(_vorlage().id, tag).tracker;
    tag = tag.next;
  }
  return tracker;
}

/// Der Tag nach einer Kette aus [tage] Tagen.
Day _danach(int tage) {
  var tag = _tag1;
  for (var i = 0; i < tage; i++) {
    tag = tag.next;
  }
  return tag;
}

void main() {
  final id = _vorlage().id;

  group('Was das nächste Häkchen bringt', () {
    test('ohne Kette der nackte Wert', () {
      final tracker = const HabitTracker.empty().activate(id);

      expect(tracker.xpForNextCheck(id, _tag1), HabitRewards.xpPerCheck);
      expect(tracker.goldForNextCheck(id, _tag1), HabitRewards.goldPerCheck);
    });

    test('mit laufender Kette der Wert des **nächsten** Tages', () {
      // Zwei Tage stehen, das dritte Häkchen erreicht den ersten
      // Meilenstein — die Kachel muss x1,2 zeigen, nicht x1,0.
      final tracker = _mitKette(2);
      final morgen = _danach(2);

      expect(
        tracker.xpForNextCheck(id, morgen),
        HabitRewards.xpFor(3, HabitDifficulty.mittel),
      );
    });

    test('ist heute schon abgehakt, steht dort, was es gebracht hat', () {
      final tracker = _mitKette(3);
      final heute = _danach(2);

      expect(
        tracker.xpForNextCheck(id, heute),
        HabitRewards.xpFor(3, HabitDifficulty.mittel),
      );
    });

    test('Gold kennt den Streak nicht', () {
      final lang = _mitKette(30);
      final morgen = _danach(30);

      expect(lang.goldForNextCheck(id, morgen), HabitRewards.goldPerCheck);
    });

    test('der Grad einer eigenen Gewohnheit zählt mit', () {
      const schwer = CustomHabit(
        id: 'custom-1',
        name: 'Kaltduschen',
        stat: HabitStat.disziplin,
        difficulty: HabitDifficulty.schwer,
      );
      const leicht = CustomHabit(
        id: 'custom-2',
        name: 'Fenster auf',
        stat: HabitStat.disziplin,
        difficulty: HabitDifficulty.leicht,
      );
      var tracker = const HabitTracker.empty();
      tracker = tracker.addCustom(schwer, slots: 2).activate(schwer.id);
      tracker = tracker.addCustom(leicht, slots: 2).activate(leicht.id);

      expect(
        tracker.xpForNextCheck(schwer.id, _tag1),
        greaterThan(tracker.xpForNextCheck(leicht.id, _tag1)),
      );
    });
  });

  group('Der nächste Meilenstein', () {
    test('ohne Kette ist es der erste', () {
      final tracker = const HabitTracker.empty().activate(id);
      final naechster = tracker.nextMilestoneFor(id, _tag1);

      expect(naechster?.days, HabitRewards.streakMilestones.first.days);
      expect(tracker.checksToNextMilestone(id, _tag1), naechster!.days);
    });

    test('er rückt näher, je länger die Kette steht', () {
      final tracker = _mitKette(2);
      final morgen = _danach(2);

      expect(tracker.nextMilestoneFor(id, morgen)?.days, 3);
      expect(tracker.checksToNextMilestone(id, morgen), 1);
    });

    test('am Deckel gibt es keinen mehr', () {
      final tracker = _mitKette(60);
      final morgen = _danach(60);

      expect(tracker.nextMilestoneFor(id, morgen), isNull);
      expect(tracker.checksToNextMilestone(id, morgen), 0);
    });

    test('er fordert nie null Häkchen', () {
      // Sonst stünde auf der Kachel „noch 0 Tage bis x1,2", während der
      // Meilenstein noch nicht erreicht ist.
      for (var tage = 0; tage <= 60; tage++) {
        final tracker = _mitKette(tage);
        final morgen = _danach(tage);
        final offen = tracker.checksToNextMilestone(id, morgen);
        if (tracker.nextMilestoneFor(id, morgen) != null) {
          expect(offen, greaterThan(0), reason: 'nach $tage Tagen');
        }
      }
    });
  });
}
