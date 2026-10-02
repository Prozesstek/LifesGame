import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Gewohnheiten aneinander koppeln (ADR-0065).
///
/// Die wichtigste Zusage steht unten: Eine Kopplung **bewegt keine Zahl**
/// und sperrt nichts.
void main() {
  const heute = Day(2026, 10, 5);
  final a = HabitCatalog.all[0].id;
  final b = HabitCatalog.all[1].id;
  final c = HabitCatalog.all[2].id;
  final d = HabitCatalog.all[3].id;

  HabitTracker laufen(List<String> ids) {
    var t = const HabitTracker.empty();
    for (final id in ids) {
      t = t.activate(id, today: heute);
    }
    return t;
  }

  List<String> liste(HabitTracker t) =>
      t.dailyListOn(heute).map((h) => h.id).toList();

  List<int> tiefen(HabitTracker t) =>
      t.stackOn(heute).map((e) => e.depth).toList();

  List<String> dran(HabitTracker t) => <String>[
        for (final e in t.stackOn(heute))
          if (e.isCued) e.habit.id,
      ];

  group('Koppeln', () {
    test('ohne Kopplung steht die Liste wie bisher', () {
      final t = laufen(<String>[a, b, c]);

      expect(liste(t), <String>[a, b, c]);
      expect(tiefen(t), <int>[0, 0, 0]);
      expect(dran(t), isEmpty);
    });

    test('die gekoppelte steht direkt unter ihrem Anker', () {
      // c hängt an a und rückt vor b.
      final t = laufen(<String>[a, b, c]).setAnchor(c, a);

      expect(t.anchorFor(c), a);
      expect(liste(t), <String>[a, c, b]);
      expect(tiefen(t), <int>[0, 1, 0]);
    });

    test('ein Stapel kann mehrere Glieder haben', () {
      final t = laufen(<String>[a, b, c, d])
          .setAnchor(b, a)
          .setAnchor(c, b)
          .setAnchor(d, c);

      expect(liste(t), <String>[a, b, c, d]);
      expect(tiefen(t), <int>[0, 1, 2, 3]);
    });

    test('an sich selbst oder im Kreis geht nicht', () {
      var t = laufen(<String>[a, b, c]).setAnchor(b, a).setAnchor(c, b);

      expect(t.canAnchor(a, a), isFalse);
      expect(t.canAnchor(a, b), isFalse);
      expect(t.canAnchor(a, c), isFalse);
      expect(t.setAnchor(a, c), same(t));

      // Die Auswahl bietet nur an, was geht.
      expect(t.anchorCandidatesFor(a), isEmpty);
      expect(t.anchorCandidatesFor(c).map((h) => h.id), <String>[a, b]);
      t = t.setAnchor(c, a);
      expect(t.anchorFor(c), a);
    });

    test('an Unbekanntes geht nicht', () {
      const fremd = 'gibt-es-nicht-und-soll-es-nie-geben';
      expect(HabitCatalog.byId(fremd), isNull);
      final t = laufen(<String>[a]);

      expect(t.setAnchor(a, fremd), same(t));
      expect(t.setAnchor(fremd, a), same(t));
    });

    test('null löst die Kopplung', () {
      final t = laufen(<String>[a, b]).setAnchor(b, a).setAnchor(b, null);

      expect(t.anchorFor(b), isNull);
      expect(tiefen(t), <int>[0, 0]);
    });
  });

  group('Satz oder Anker', () {
    test('ein Anker ersetzt den Satz', () {
      final t = laufen(<String>[a, b])
          .setCue(b, 'Nach dem Zähneputzen')
          .setAnchor(b, a);

      expect(t.anchorFor(b), a);
      expect(t.cueFor(b), isNull);
    });

    test('ein Satz ersetzt den Anker', () {
      final t = laufen(<String>[a, b])
          .setAnchor(b, a)
          .setCue(b, 'Nach dem Zähneputzen');

      expect(t.anchorFor(b), isNull);
      expect(t.cueFor(b), 'Nach dem Zähneputzen');
    });

    test('den Satz zu entfernen lässt den Anker stehen', () {
      final t = laufen(<String>[a, b]).setAnchor(b, a).setCue(b, '');

      expect(t.anchorFor(b), a);
    });
  });

  group('Jetzt dran', () {
    test('sobald der Anker abgehakt ist — und nur dann', () {
      var t = laufen(<String>[a, b]).setAnchor(b, a);
      expect(dran(t), isEmpty);

      t = t.check(a, heute).tracker;
      expect(dran(t), <String>[b]);

      t = t.check(b, heute).tracker;
      expect(dran(t), isEmpty);
    });

    test('im Stapel immer nur das nächste Glied', () {
      var t = laufen(<String>[a, b, c]).setAnchor(b, a).setAnchor(c, b);

      t = t.check(a, heute).tracker;
      expect(dran(t), <String>[b]);
      t = t.check(b, heute).tracker;
      expect(dran(t), <String>[c]);
    });

    test('der abgehakte Anker bleibt über seiner offenen Folge stehen', () {
      // Sonst rutschte er nach unten, und man sähe nicht mehr, woran die
      // Folge hängt.
      final t =
          laufen(<String>[a, b, c]).setAnchor(b, a).check(a, heute).tracker;

      expect(liste(t), <String>[a, b, c]);
    });

    test('ein ganz erledigter Stapel wandert als Ganzes nach unten', () {
      var t = laufen(<String>[a, b, c]).setAnchor(b, a);
      t = t.check(a, heute).tracker.check(b, heute).tracker;

      expect(liste(t), <String>[c, a, b]);
      expect(tiefen(t), <int>[0, 0, 1]);
    });
  });

  group('Der Anker fehlt', () {
    test('gestoppt: Die gekoppelte steht normal da, die Kopplung bleibt', () {
      var t = laufen(<String>[a, b]).setAnchor(b, a);
      t = t.deactivate(a, today: heute);

      expect(liste(t), <String>[b]);
      expect(tiefen(t), <int>[0]);
      expect(t.anchorFor(b), a);

      t = t.activate(a, today: heute);
      expect(tiefen(t), <int>[0, 1]);
    });

    test('heute nicht fällig: ebenso', () {
      // a nur dienstags; heute ist Montag.
      final t = laufen(<String>[a, b])
          .setWeekdays(a, const <int>{2}, today: heute)
          .setAnchor(b, a);

      expect(liste(t), <String>[b]);
      expect(tiefen(t), <int>[0]);
      final wiederTaeglich = t.setWeekdays(
        a,
        HabitPlan.everyDay,
        today: heute,
      );
      expect(liste(wiederTaeglich), <String>[a, b]);
    });
  });

  group('Keine Zahl, kein Schloss', () {
    test('die gekoppelte lässt sich vor ihrem Anker abhaken', () {
      final t = laufen(<String>[a, b]).setAnchor(b, a);

      expect(t.check(b, heute).tracker.isChecked(b, heute), isTrue);
    });

    test('eine Kopplung ändert weder Erfahrung noch Gold noch Werte', () {
      HabitTracker spiele(HabitTracker t) {
        var tracker = t;
        var tag = heute;
        for (var i = 0; i < 10; i++) {
          for (final id in <String>[a, b, c]) {
            tracker = tracker.check(id, tag).tracker;
          }
          tag = tag.next;
        }
        return tracker;
      }

      final ohne = spiele(laufen(<String>[a, b, c]));
      final mit = spiele(
        laufen(<String>[a, b, c]).setAnchor(b, a).setAnchor(c, b),
      );

      expect(mit.totalXp, ohne.totalXp);
      expect(mit.totalGold, ohne.totalGold);
      expect(mit.stats.attack, ohne.stats.attack);
      expect(mit.longestStreak, ohne.longestStreak);
      expect(mit.isDayComplete(heute), ohne.isDayComplete(heute));
    });
  });

  group('Speichern', () {
    test('Kopplungen überleben toJson und zurück', () {
      final t = laufen(<String>[a, b, c]).setAnchor(b, a).setAnchor(c, b);

      final geladen = HabitTracker.fromJson(t.toJson());

      expect(geladen.toJson(), t.toJson());
      expect(geladen.anchorFor(c), b);
    });

    test('ohne Kopplung sieht der Stand aus wie vorher', () {
      expect(laufen(<String>[a]).toJson().containsKey('anchors'), isFalse);
    });

    test('Kreise und Unbekanntes fallen beim Laden heraus', () {
      const fremd = 'gibt-es-nicht-und-soll-es-nie-geben';
      final t = HabitTracker.fromJson(<String, Object?>{
        'activeIds': <Object?>[a, b, c],
        'cues': <String, Object?>{c: 'Nach dem Kaffee'},
        'anchors': <String, Object?>{
          a: b,
          b: a,
          c: a,
          d: fremd,
          fremd: a,
          'x': 7,
        },
      });

      // a -> b steht, b -> a schlösse den Kreis.
      expect(t.anchorFor(a), b);
      expect(t.anchorFor(b), isNull);
      // c hat einen Satz, und der gewinnt.
      expect(t.anchorFor(c), isNull);
      expect(t.cueFor(c), 'Nach dem Kaffee');
      expect(t.anchorFor(d), isNull);
      expect(liste(t), hasLength(3));
    });
  });
}
