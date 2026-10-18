import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Was am Lagerfeuer für morgen gewählt wird (ADR-0076).
///
/// Ein Umsetzungsvorsatz: Die Gewohnheit steht morgen zuerst in der
/// Tagesliste. Die wichtigste Zusage steht unten — er **bewegt keine
/// Zahl**.
void main() {
  const heute = Day(2026, 10, 18);
  final morgen = heute.next;
  final a = HabitCatalog.all[0].id;
  final b = HabitCatalog.all[1].id;
  final c = HabitCatalog.all[2].id;

  HabitTracker laufen(List<String> ids) {
    var t = const HabitTracker.empty();
    for (final id in ids) {
      t = t.activate(id, today: heute);
    }
    return t;
  }

  List<String> liste(HabitTracker t, Day tag) =>
      t.dailyListOn(tag).map((h) => h.id).toList();

  test('ohne Vorsatz steht die Liste wie bisher', () {
    final t = laufen(<String>[a, b, c]);

    expect(t.firstUpOn(morgen), isNull);
    expect(liste(t, morgen), <String>[a, b, c]);
  });

  test('der Vorsatz steht am Tag danach zuerst — und nur dort', () {
    final t = laufen(<String>[a, b, c]).setFirstUp(morgen, c);

    expect(t.firstUpOn(morgen), c);
    expect(liste(t, morgen), <String>[c, a, b]);
    expect(liste(t, heute), <String>[a, b, c]);
  });

  test('erledigt wandert er nach unten wie jede andere', () {
    final t = laufen(<String>[a, b, c])
        .setFirstUp(morgen, c)
        .check(c, morgen)
        .tracker;

    expect(liste(t, morgen), <String>[a, b, c]);
  });

  test('ein gekoppelter Vorsatz zieht seinen ganzen Stapel nach vorn', () {
    // c hängt an b: Nach vorn kommt b mit c darunter, nicht c allein.
    final t = laufen(<String>[a, b, c]).setAnchor(c, b).setFirstUp(morgen, c);

    expect(liste(t, morgen), <String>[b, c, a]);
  });

  test('ein zweiter Tipp ersetzt den ersten, null nimmt ihn zurück', () {
    var t = laufen(<String>[a, b, c]).setFirstUp(morgen, c);
    t = t.setFirstUp(morgen, b);
    expect(t.firstUpOn(morgen), b);

    t = t.setFirstUp(morgen, null);
    expect(t.firstUpOn(morgen), isNull);
    expect(liste(t, morgen), <String>[a, b, c]);
  });

  test('eine unbekannte Gewohnheit ändert nichts', () {
    const fremd = 'gibt-es-nicht-und-soll-es-nie-geben';
    final t = laufen(<String>[a, b]);

    expect(t.setFirstUp(morgen, fremd).firstUpOn(morgen), isNull);
  });

  test('der Vorsatz übersteht das Speichern', () {
    final t = laufen(<String>[a, b, c]).setFirstUp(morgen, c);
    final geladen = HabitTracker.fromJson(t.toJson());

    expect(geladen.firstUpOn(morgen), c);
    expect(liste(geladen, morgen), <String>[c, a, b]);
  });

  test(
      'ein Vorsatz für eine verschwundene Gewohnheit fällt beim Laden '
      'heraus', () {
    final json = laufen(<String>[a]).toJson()
      ..['firstUp'] = <String, Object?>{
        morgen.toString(): 'gibt-es-nicht-und-soll-es-nie-geben',
      };

    expect(HabitTracker.fromJson(json).firstUpOn(morgen), isNull);
  });

  test('er bewegt keine Zahl', () {
    final ohne = laufen(<String>[a, b, c]).check(a, heute).tracker;
    final mit = ohne.setFirstUp(morgen, c);

    expect(mit.totalXp, ohne.totalXp);
    expect(mit.totalGold, ohne.totalGold);
    expect(mit.currentDayStreak(heute), ohne.currentDayStreak(heute));
  });
}
