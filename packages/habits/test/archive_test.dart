import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Eigene Gewohnheiten löschen (19.11.2026): weg aus der Liste, Platz
/// frei — die Häkchen zählen weiter.
void main() {
  const heute = Day(2026, 11, 19);
  const eigene = CustomHabit(
    id: 'eigen-1',
    name: 'Gitarre üben',
    area: SkillArea.geist,
    difficulty: HabitDifficulty.mittel,
  );

  HabitTracker mitHaekchen() {
    var t = const HabitTracker.empty().addCustom(eigene, slots: 1);
    t = t.activate(eigene.id, today: heute.previous);
    t = t.check(eigene.id, heute.previous).tracker;
    return t.deactivate(eigene.id, today: heute);
  }

  test('gelöscht verschwindet sie aus der Liste und gibt den Platz frei', () {
    final vorher = mitHaekchen();
    expect(vorher.canAddCustom(1), isFalse);

    final t = vorher.archiveCustom(eigene.id);

    expect(t.isArchived(eigene.id), isTrue);
    expect(t.visibleCustomHabits, isEmpty);
    expect(t.canAddCustom(1), isTrue);
    expect(t.canActivate(eigene.id), isFalse);
  });

  test('ihre Häkchen zählen weiter — nichts fällt nachträglich', () {
    final vorher = mitHaekchen();
    final t = vorher.archiveCustom(eigene.id);

    expect(t.totalXp, vorher.totalXp);
    expect(t.totalGold, vorher.totalGold);
    expect(t.customCount, vorher.customCount);
  });

  test('eine laufende, eine Vorlage oder Unbekanntes löscht nichts', () {
    var t = const HabitTracker.empty().addCustom(eigene, slots: 1);
    t = t.activate(eigene.id, today: heute);
    expect(t.archiveCustom(eigene.id), same(t));

    final vorlage = HabitCatalog.all.first.id;
    expect(t.archiveCustom(vorlage), same(t));
    expect(t.archiveCustom('gibt-es-nicht-und-soll-es-nie-geben'), same(t));
  });

  test('gelöscht übersteht das Speichern', () {
    final t = mitHaekchen().archiveCustom(eigene.id);
    final geladen = HabitTracker.fromJson(t.toJson());

    expect(geladen.isArchived(eigene.id), isTrue);
    expect(geladen.visibleCustomHabits, isEmpty);
  });
}
