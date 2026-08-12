import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Prüft den Inhalt des Katalogs, nicht den Code darum herum. Eine neue
/// Vorlage wird hier automatisch mitgeprüft.
void main() {
  group('HabitCatalog', () {
    test('hat eindeutige Ids', () {
      final ids = HabitCatalog.all.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'doppelte Id im Katalog');
    });

    test('hat eindeutige Namen', () {
      // Der Name ist die Verbindung zum Skillbaum. Zwei gleiche Namen
      // hiessen: eine Lektion schaltet zwei Vorlagen frei.
      final names = HabitCatalog.all.map((t) => t.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('jede Vorlage nennt Zweig und Begründung', () {
      for (final template in HabitCatalog.all) {
        expect(template.name.trim(), isNotEmpty, reason: template.id);
        expect(template.branchId.trim(), isNotEmpty, reason: template.id);
        expect(template.why.trim(), isNotEmpty, reason: template.id);
      }
    });

    test('jeder Charakterwert wird von mindestens einer Vorlage gespeist', () {
      // Sonst gäbe es einen Kampfwert, den kein Verhalten erhöht.
      for (final stat in HabitStat.values) {
        expect(
          HabitCatalog.all.any((t) => t.stat == stat),
          isTrue,
          reason: 'kein Habit zahlt auf ${stat.label} ein',
        );
      }
    });

    test('byId und byName finden dieselbe Vorlage', () {
      for (final template in HabitCatalog.all) {
        expect(HabitCatalog.byId(template.id)?.name, template.name);
        expect(HabitCatalog.byName(template.name)?.id, template.id);
      }
    });

    test('byNames überspringt Unbekanntes, statt zu werfen', () {
      final found = HabitCatalog.byNames(<String>[
        HabitCatalog.all.first.name,
        'Gibt es nicht',
      ]);

      expect(found, hasLength(1));
      expect(found.first.id, HabitCatalog.all.first.id);
    });

    test('genug Vorlagen, um die Obergrenze zu füllen', () {
      // Sonst wäre die Auswahl keine Entscheidung.
      expect(
        HabitCatalog.all.length,
        greaterThan(HabitRewards.maxActiveHabits),
      );
    });
  });
}
