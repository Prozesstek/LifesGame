import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Zeitziele laufen als Timer
/// ([ADR-0067](../../../docs/decisions/0067-zeitziele-als-timer.md)).
///
/// Die zwei Zusagen, die hier stehen: **Gerechnet wird aus der Startzeit**
/// — der Timer läuft weiter, auch wenn niemand zusieht —, und **er bewegt
/// keine Zahl**, die ein Häkchen von Hand nicht genauso bewegt hätte.
void main() {
  const heute = Day(2026, 10, 4);
  final start = DateTime.utc(2026, 10, 4, 8);

  DateTime nach({int minuten = 0, int sekunden = 0}) {
    return start.add(Duration(minutes: minuten, seconds: sekunden));
  }

  const lesen = CustomHabit(
    id: 'custom-1',
    name: 'Lesen',
    stat: HabitStat.klarheit,
    difficulty: HabitDifficulty.mittel,
    goal: null,
  );
  final zwanzig = CustomHabit(
    id: 'custom-1',
    name: 'Lesen',
    stat: HabitStat.klarheit,
    difficulty: HabitDifficulty.mittel,
    goal: HabitGoal.zeit(target: 20),
  );
  final dehnen = CustomHabit(
    id: 'custom-2',
    name: 'Dehnen',
    stat: HabitStat.ausdauer,
    difficulty: HabitDifficulty.mittel,
    goal: HabitGoal.zeit(target: 10),
  );
  final glaeser = CustomHabit(
    id: 'custom-3',
    name: 'Wasser',
    stat: HabitStat.ausdauer,
    difficulty: HabitDifficulty.mittel,
    goal: HabitGoal.menge(target: 5, unit: 'Gläser'),
  );

  HabitTracker mit(List<CustomHabit> habits) {
    var t = const HabitTracker.empty();
    for (final habit in habits) {
      t = t.addCustom(habit, slots: 5).activate(habit.id);
    }
    return t;
  }

  group('Wer einen Timer hat', () {
    test('nur ein Zeitziel, keine Menge und kein Ziel', () {
      expect(mit(<CustomHabit>[zwanzig]).hasTimer(zwanzig.id), isTrue);
      expect(mit(<CustomHabit>[glaeser]).hasTimer(glaeser.id), isFalse);
      expect(mit(<CustomHabit>[lesen]).hasTimer(lesen.id), isFalse);
    });

    test('die Startvorlage läuft zwei Minuten, die anderen Vorlagen nicht', () {
      final starter = HabitCatalog.starter;
      final t = const HabitTracker.empty().activate(starter.id);

      expect(t.hasTimer(starter.id), isTrue);
      expect(t.requiredFor(starter.id), 2);
      for (final vorlage in HabitCatalog.all) {
        if (vorlage.id == starter.id) continue;
        expect(vorlage.goal, isNull, reason: vorlage.id);
      }
    });

    test('die Dauer ändert nicht, was die Startvorlage einbringt', () {
      final starter = HabitCatalog.starter;
      final andere = HabitCatalog.all.firstWhere((h) => h.id != starter.id);
      final t =
          const HabitTracker.empty().activate(starter.id).activate(andere.id);

      final mitUhr = t.check(starter.id, heute);
      final ohne = t.check(andere.id, heute);

      expect(mitUhr.xpGained, ohne.xpGained);
      expect(mitUhr.goldGained, ohne.goldGained);
    });

    test('ohne Zeitziel startet nichts', () {
      final t = mit(<CustomHabit>[glaeser]);

      expect(identical(t.startTimer(glaeser.id, heute, start), t), isTrue);
    });
  });

  group('Laufen', () {
    test('gerechnet wird aus der Startzeit, nicht aus Ticks', () {
      final t =
          mit(<CustomHabit>[zwanzig]).startTimer(zwanzig.id, heute, start);

      expect(t.timerFor(zwanzig.id, heute)!.isRunning, isTrue);
      expect(t.timedSecondsOn(zwanzig.id, heute, nach(minuten: 7)), 7 * 60);
      expect(
        t.timedSecondsOn(zwanzig.id, heute, nach(minuten: 12, sekunden: 30)),
        12 * 60 + 30,
      );
    });

    test('die Zeit läuft nie über das Ziel hinaus', () {
      final t =
          mit(<CustomHabit>[zwanzig]).startTimer(zwanzig.id, heute, start);

      expect(t.timedSecondsOn(zwanzig.id, heute, nach(minuten: 90)), 20 * 60);
    });

    test('vor dem Ziel hakt nichts ab', () {
      final t =
          mit(<CustomHabit>[zwanzig]).startTimer(zwanzig.id, heute, start);

      expect(t.settleTimer(nach(minuten: 19, sekunden: 59)), isNull);
    });

    test('am Ziel ist abgehakt, mit demselben Ertrag wie von Hand', () {
      final basis = mit(<CustomHabit>[zwanzig]);
      final vonHand = basis.check(zwanzig.id, heute);

      final ergebnis = basis
          .startTimer(zwanzig.id, heute, start)
          .settleTimer(nach(minuten: 20))!;

      expect(ergebnis.isComplete, isTrue);
      expect(ergebnis.xpGained, vonHand.xpGained);
      expect(ergebnis.goldGained, vonHand.goldGained);
      expect(ergebnis.tracker.isChecked(zwanzig.id, heute), isTrue);
      expect(ergebnis.tracker.timerFor(zwanzig.id, heute), isNull);
      expect(ergebnis.tracker.totalXp, vonHand.tracker.totalXp);
    });

    test('ein zweites Mal abrechnen ändert nichts', () {
      final fertig = mit(<CustomHabit>[zwanzig])
          .startTimer(zwanzig.id, heute, start)
          .settleTimer(nach(minuten: 20))!
          .tracker;

      expect(fertig.settleTimer(nach(minuten: 25)), isNull);
    });

    test('eine zurückgestellte Uhr nimmt keine Zeit weg', () {
      final t =
          mit(<CustomHabit>[zwanzig]).startTimer(zwanzig.id, heute, start);
      final frueher = start.subtract(const Duration(minutes: 5));

      expect(t.timedSecondsOn(zwanzig.id, heute, frueher), 0);
    });

    test('über Mitternacht landet das Häkchen auf dem Tag des Starts', () {
      final spaet = DateTime.utc(2026, 10, 4, 23, 50);
      final t =
          mit(<CustomHabit>[zwanzig]).startTimer(zwanzig.id, heute, spaet);

      final ergebnis = t.settleTimer(DateTime.utc(2026, 10, 5, 0, 10))!;

      expect(ergebnis.day, heute);
      expect(ergebnis.tracker.isChecked(zwanzig.id, heute), isTrue);
      expect(ergebnis.tracker.isChecked(zwanzig.id, heute.next), isFalse);
    });
  });

  group('Anhalten', () {
    test('was gelaufen ist, bleibt als Minuten stehen', () {
      final ergebnis = mit(<CustomHabit>[zwanzig])
          .startTimer(zwanzig.id, heute, start)
          .pauseTimer(nach(minuten: 12, sekunden: 40))!;
      final t = ergebnis.tracker;

      expect(ergebnis.isComplete, isFalse);
      expect(ergebnis.xpGained, 0);
      expect(t.progressOn(zwanzig.id, heute), 12);
      expect(t.timerFor(zwanzig.id, heute)!.isRunning, isFalse);
      // Angehalten läuft nichts weiter, auch eine Stunde später nicht.
      expect(
        t.timedSecondsOn(zwanzig.id, heute, nach(minuten: 72)),
        12 * 60 + 40,
      );
    });

    test('der nächste Start macht dort weiter, samt angefangener Minute', () {
      final pausiert = mit(<CustomHabit>[zwanzig])
          .startTimer(zwanzig.id, heute, start)
          .pauseTimer(nach(minuten: 12, sekunden: 40))!
          .tracker;
      final weiter = pausiert.startTimer(zwanzig.id, heute, nach(minuten: 60));

      // Offen sind 7:20 — eine Sekunde davor ist noch nichts abgehakt.
      expect(
        weiter.settleTimer(nach(minuten: 67, sekunden: 19)),
        isNull,
      );
      expect(
        weiter.settleTimer(nach(minuten: 67, sekunden: 20))!.isComplete,
        isTrue,
      );
    });

    test('anhalten nach dem Ziel hakt ab', () {
      final ergebnis = mit(<CustomHabit>[zwanzig])
          .startTimer(zwanzig.id, heute, start)
          .pauseTimer(nach(minuten: 21))!;

      expect(ergebnis.isComplete, isTrue);
      expect(ergebnis.tracker.isChecked(zwanzig.id, heute), isTrue);
    });

    test('ohne laufenden Timer gibt es nichts anzuhalten', () {
      expect(mit(<CustomHabit>[zwanzig]).pauseTimer(start), isNull);
    });

    test('unter einer Minute steht kein Fortschritt, aber der Rest bleibt', () {
      final t = mit(<CustomHabit>[zwanzig])
          .startTimer(zwanzig.id, heute, start)
          .pauseTimer(nach(sekunden: 45))!
          .tracker;

      expect(t.progressOn(zwanzig.id, heute), 0);
      expect(t.timedSecondsOn(zwanzig.id, heute, nach(minuten: 5)), 45);
    });
  });

  group('Nur einer läuft', () {
    test('ein zweiter Start hält den ersten an und behält dessen Minuten', () {
      final t = mit(<CustomHabit>[zwanzig, dehnen])
          .startTimer(zwanzig.id, heute, start)
          .startTimer(dehnen.id, heute, nach(minuten: 6, sekunden: 30));

      expect(t.timer!.habitId, dehnen.id);
      expect(t.timerFor(zwanzig.id, heute), isNull);
      expect(t.progressOn(zwanzig.id, heute), 6);
      // Der erste läuft nicht im Hintergrund weiter.
      expect(t.timedSecondsOn(zwanzig.id, heute, nach(minuten: 30)), 6 * 60);
    });

    test('ein laufender Timer startet nicht neu', () {
      final t =
          mit(<CustomHabit>[zwanzig]).startTimer(zwanzig.id, heute, start);

      expect(
        identical(t.startTimer(zwanzig.id, heute, nach(minuten: 5)), t),
        isTrue,
      );
    });
  });

  group('Von Hand', () {
    test('ein Häkchen von Hand beendet den Timer', () {
      final t = mit(<CustomHabit>[zwanzig])
          .startTimer(zwanzig.id, heute, start)
          .check(zwanzig.id, heute)
          .tracker;

      expect(t.timer, isNull);
      expect(t.settleTimer(nach(minuten: 30)), isNull);
    });

    test('zurücknehmen fängt den Tag neu an, ohne Timer', () {
      final t = mit(<CustomHabit>[zwanzig])
          .startTimer(zwanzig.id, heute, start)
          .pauseTimer(nach(minuten: 5, sekunden: 10))!
          .tracker
          .uncheck(zwanzig.id, heute);

      expect(t.timer, isNull);
      expect(t.progressOn(zwanzig.id, heute), 0);
    });

    test('eine erledigte Gewohnheit startet keinen Timer', () {
      final t = mit(<CustomHabit>[zwanzig]).check(zwanzig.id, heute).tracker;

      expect(identical(t.startTimer(zwanzig.id, heute, start), t), isTrue);
    });

    test('stoppen nimmt den Timer mit', () {
      final t = mit(<CustomHabit>[zwanzig])
          .startTimer(zwanzig.id, heute, start)
          .deactivate(zwanzig.id, today: heute);

      expect(t.timer, isNull);
    });
  });

  group('Speichern', () {
    test('ein laufender Timer überlebt toJson und zurück', () {
      final t =
          mit(<CustomHabit>[zwanzig]).startTimer(zwanzig.id, heute, start);
      final geladen = HabitTracker.fromJson(t.toJson());

      expect(geladen.timerFor(zwanzig.id, heute)!.isRunning, isTrue);
      expect(
        geladen.timedSecondsOn(zwanzig.id, heute, nach(minuten: 9)),
        9 * 60,
      );
      expect(geladen.settleTimer(nach(minuten: 20))!.isComplete, isTrue);
    });

    test('ein angehaltener behält seinen Rest', () {
      final t = mit(<CustomHabit>[zwanzig])
          .startTimer(zwanzig.id, heute, start)
          .pauseTimer(nach(minuten: 3, sekunden: 25))!
          .tracker;
      final geladen = HabitTracker.fromJson(t.toJson());

      expect(
        geladen.timedSecondsOn(zwanzig.id, heute, nach(minuten: 50)),
        3 * 60 + 25,
      );
    });

    test('ohne Timer steht keiner im Stand', () {
      final stand = mit(<CustomHabit>[zwanzig]).toJson();

      expect(stand.containsKey('timer'), isFalse);
    });

    test('Unlesbares und Fremdes wird übersprungen, nicht geworfen', () {
      const fremd = 'gibt-es-nicht-und-soll-es-nie-geben';
      final basis = mit(<CustomHabit>[zwanzig]).toJson();

      for (final kaputt in <Object?>[
        'unsinn',
        <String, Object?>{'habit': zwanzig.id},
        <String, Object?>{'habit': zwanzig.id, 'day': 'kein-tag'},
        <String, Object?>{'habit': fremd, 'day': heute.toString()},
      ]) {
        final geladen = HabitTracker.fromJson(<String, Object?>{
          ...basis,
          'timer': kaputt,
        });
        expect(geladen.timer, isNull, reason: '$kaputt');
      }
    });
  });
}
