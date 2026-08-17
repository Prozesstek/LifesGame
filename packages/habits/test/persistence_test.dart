import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Prüft, dass ein Stand vollständig durch [HabitTracker.toJson] und
/// zurück kommt.
///
/// Das ist der Test, an dem die Streak hängt. Alles andere im Tracker
/// wurde schon geprüft — aber wenn das Speichern etwas verliert, merkt es
/// niemand, bis jemand die App neu startet und seine Kette weg ist.
void main() {
  const eine = 'habit-drei-aufgaben';
  const andere = 'habit-zwei-minuten-lesen';

  HabitTracker mitTagen(int tage) {
    var tracker = const HabitTracker.empty().activate(eine).activate(andere);
    var tag = const Day(2026, 1, 1);
    for (var i = 0; i < tage; i++) {
      tracker = tracker.check(eine, tag).tracker;
      tracker = tracker.check(andere, tag).tracker;
      tag = tag.next;
    }
    return tracker;
  }

  group('Speichern und laden', () {
    test('ein leerer Stand bleibt leer', () {
      final gelesen = HabitTracker.fromJson(
        const HabitTracker.empty().toJson(),
      );

      expect(gelesen.activeIds, isEmpty);
      expect(gelesen.totalChecks, 0);
    });

    test('Häkchen, Streak und Ertrag überleben unverändert', () {
      final original = mitTagen(10);
      final gelesen = HabitTracker.fromJson(original.toJson());

      expect(gelesen.activeIds, original.activeIds);
      expect(gelesen.totalChecks, original.totalChecks);
      expect(gelesen.totalXp, original.totalXp);
      expect(gelesen.totalGold, original.totalGold);
    });

    test('die Streak zählt nach dem Laden weiter, statt neu zu beginnen', () {
      // Der eigentliche Punkt der ganzen Übung: Eine Streak, die einen
      // Neustart nicht übersteht, ist keine Streak.
      const start = Day(2026, 1, 1);
      final original = mitTagen(10);

      var letzterTag = start;
      for (var i = 1; i < 10; i++) {
        letzterTag = letzterTag.next;
      }

      final gelesen = HabitTracker.fromJson(original.toJson());

      expect(gelesen.streakEndingAt(eine, letzterTag), 10);
      expect(gelesen.currentStreak(eine, letzterTag), 10);
      expect(
        gelesen.nextMultiplier(eine, letzterTag.next),
        HabitRewards.multiplierFor(11),
      );
    });

    test('die Charakterwerte sind nach dem Laden dieselben', () {
      final original = mitTagen(30);
      final gelesen = HabitTracker.fromJson(original.toJson());

      for (final stat in HabitStat.values) {
        expect(
          gelesen.stats.valueFor(stat),
          original.stats.valueFor(stat),
          reason: stat.label,
        );
      }
    });

    test('die Reihenfolge der laufenden Gewohnheiten bleibt erhalten', () {
      final original =
          const HabitTracker.empty().activate(andere).activate(eine);

      final gelesen = HabitTracker.fromJson(original.toJson());

      expect(gelesen.activeIds, <String>[andere, eine]);
    });
  });

  group('Nachsicht beim Laden', () {
    test('unbekannte Vorlagen verschwinden, der Rest bleibt', () {
      final gelesen = HabitTracker.fromJson(<String, Object?>{
        'activeIds': <Object?>[eine, 'habit-aus-einer-anderen-version', 7],
        'checks': <String, Object?>{
          eine: <Object?>['2026-01-01', '2026-01-02'],
        },
      });

      expect(gelesen.activeIds, <String>[eine]);
      expect(gelesen.checksFor(eine), 2);
    });

    test('unlesbare Tage werden übersprungen, lesbare nicht', () {
      final gelesen = HabitTracker.fromJson(<String, Object?>{
        'activeIds': <Object?>[eine],
        'checks': <String, Object?>{
          eine: <Object?>[
            '2026-01-01',
            'gestern',
            '2026-02-31',
            42,
            '2026-01-03',
          ],
        },
      });

      expect(gelesen.checksFor(eine), 2);
      expect(gelesen.isChecked(eine, const Day(2026, 1, 1)), isTrue);
      expect(gelesen.isChecked(eine, const Day(2026, 1, 3)), isTrue);
    });

    test('mehr laufende Gewohnheiten als erlaubt werden gekappt', () {
      // Ein Stand aus einer Version mit anderer Obergrenze darf sie nicht
      // unterlaufen.
      final alleIds = HabitCatalog.all.map((t) => t.id).toList();
      final gelesen = HabitTracker.fromJson(<String, Object?>{
        'activeIds': alleIds,
        'checks': const <String, Object?>{},
      });

      expect(gelesen.activeIds, hasLength(HabitRewards.maxActiveHabits));
      expect(gelesen.isFull, isTrue);
    });

    test('Müll ergibt einen leeren Stand statt einer Ausnahme', () {
      expect(HabitTracker.fromJson(<String, Object?>{}).activeIds, isEmpty);
      expect(
        HabitTracker.fromJson(<String, Object?>{'checks': 'nein'}).totalChecks,
        0,
      );
    });
  });

  group('Day.tryParse', () {
    test('liest zurück, was toString schreibt', () {
      const tag = Day(2026, 8, 17);

      expect(Day.tryParse(tag.toString()), tag);
    });

    test('weist zurück, was kein Tag ist', () {
      for (final murks in <String>[
        '',
        'heute',
        '2026-08',
        '2026-13-01',
        '2026-02-31',
        '2026-00-10',
        'a-b-c',
      ]) {
        expect(Day.tryParse(murks), isNull, reason: murks);
      }
    });
  });
}
