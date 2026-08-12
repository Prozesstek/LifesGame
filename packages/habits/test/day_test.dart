import 'package:habits/habits.dart';
import 'package:test/test.dart';

void main() {
  group('Day', () {
    test('gleiche Kalenderdaten sind gleich, egal zu welcher Uhrzeit', () {
      final morgens = Day.from(DateTime(2026, 8, 12, 6, 30));
      final abends = Day.from(DateTime(2026, 8, 12, 23, 59));

      expect(morgens, abends);
      expect(morgens.hashCode, abends.hashCode);
    });

    test('previous und next springen über Monatsgrenzen', () {
      expect(const Day(2026, 9, 1).previous, const Day(2026, 8, 31));
      expect(const Day(2026, 12, 31).next, const Day(2027, 1, 1));
    });

    test('rechnet über den Schalttag hinweg', () {
      expect(const Day(2028, 2, 28).next, const Day(2028, 2, 29));
      expect(const Day(2028, 2, 29).next, const Day(2028, 3, 1));
    });

    test('daysUntil zählt vorwärts und rückwärts', () {
      const start = Day(2026, 8, 1);
      const later = Day(2026, 8, 31);

      expect(start.daysUntil(later), 30);
      expect(later.daysUntil(start), -30);
      expect(start.daysUntil(start), 0);
    });

    test('daysUntil zählt auch über eine Zeitumstellung ganze Tage', () {
      // Ende der Sommerzeit in Mitteleuropa: In lokaler Zeit hat der
      // 25.10.2026 25 Stunden. Mit lokalem DateTime-Rechnen käme hier 0
      // oder ein Tag zu wenig heraus.
      const davor = Day(2026, 10, 24);
      const danach = Day(2026, 10, 26);

      expect(davor.daysUntil(danach), 2);
      expect(davor.next.next, danach);
    });

    test('sortiert chronologisch', () {
      final days = <Day>[
        const Day(2026, 8, 12),
        const Day(2025, 12, 31),
        const Day(2026, 1, 1),
      ]..sort();

      expect(days.map((d) => d.toString()), <String>[
        '2025-12-31',
        '2026-01-01',
        '2026-08-12',
      ]);
    });

    test('toString ist ISO-förmig und zweistellig', () {
      expect(const Day(2026, 1, 5).toString(), '2026-01-05');
    });
  });
}
