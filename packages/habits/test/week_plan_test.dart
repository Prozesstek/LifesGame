import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Der Wochenplan und die Kette, die fällt statt zu reißen (ADR-0064).
///
/// Der 05.10.2026 ist ein Montag — die Tests zählen von dort.
void main() {
  const montag = Day(2026, 10, 5);
  Day tag(int n) {
    var d = montag;
    for (var i = 0; i < n.abs(); i++) {
      d = n < 0 ? d.previous : d.next;
    }
    return d;
  }

  final dienstag = tag(1);
  final mittwoch = tag(2);
  final donnerstag = tag(3);
  final freitag = tag(4);
  final samstag = tag(5);
  final sonntag = tag(6);

  final a = HabitCatalog.all[0].id;
  final b = HabitCatalog.all[1].id;
  const moMiFr = <int>{1, 3, 5};

  HabitTracker laeuft(String id) =>
      const HabitTracker.empty().activate(id, today: montag);

  /// Hakt [id] an [tage] Tagen am Stück ab, beginnend bei [start].
  HabitTracker abhaken(HabitTracker t, String id, Day start, int tage) {
    var tracker = t;
    var d = start;
    for (var i = 0; i < tage; i++) {
      tracker = tracker.check(id, d).tracker;
      d = d.next;
    }
    return tracker;
  }

  test('der 05.10.2026 ist ein Montag', () {
    expect(montag.weekday, 1);
  });

  group('Fällig', () {
    test('ohne Plan ist jeder Tag fällig', () {
      final t = laeuft(a);

      for (var i = 0; i < 7; i++) {
        expect(t.isDueOn(a, tag(i)), isTrue);
      }
      expect(t.weekdaysFor(a), HabitPlan.everyDay);
    });

    test('ein Plan gilt sofort, solange noch nichts abgehakt ist', () {
      final t = laeuft(a).setWeekdays(a, moMiFr, today: montag);

      expect(t.isDueOn(a, montag), isTrue);
      expect(t.isDueOn(a, dienstag), isFalse);
      expect(t.isDueOn(a, mittwoch), isTrue);
      expect(t.weekdaysFor(a), moMiFr);
    });

    test('sonst gilt er ab morgen — heute bleibt fällig', () {
      // Sonst nähme man abends den heutigen Tag aus dem Plan und öffnete
      // die Truhe ohne Häkchen.
      final t = abhaken(laeuft(a), a, montag, 1).setWeekdays(
        a,
        const <int>{1},
        today: dienstag,
      );

      expect(t.isDueOn(a, dienstag), isTrue);
      expect(t.isDueOn(a, mittwoch), isFalse);
      // Was der Spieler gewählt hat, steht schon da.
      expect(t.weekdaysFor(a), const <int>{1});
    });

    test('eine Änderung schreibt die Vergangenheit nicht um', () {
      var t = abhaken(laeuft(a), a, montag, 5);
      final vorher = t.totalXp;

      t = t.setWeekdays(a, const <int>{7}, today: freitag);

      expect(t.totalXp, vorher);
      expect(t.streakEndingAt(a, freitag), 5);
    });

    test('ein leerer oder unsinniger Plan ändert nichts', () {
      final t = laeuft(a);

      expect(t.setWeekdays(a, const <int>{}, today: montag), same(t));
      expect(t.setWeekdays(a, const <int>{0, 3}, today: montag), same(t));
      expect(t.setWeekdays(a, const <int>{8}, today: montag), same(t));
    });

    test('die Tagesliste zeigt nur, was fällig ist', () {
      final t = laeuft(a)
          .activate(b, today: montag)
          .setWeekdays(a, moMiFr, today: montag);

      expect(t.dailyListOn(montag).map((h) => h.id), <String>[a, b]);
      expect(t.dailyListOn(dienstag).map((h) => h.id), <String>[b]);
    });

    test('nicht fällig heißt nicht abhakbar', () {
      final t = laeuft(a).setWeekdays(a, moMiFr, today: montag);

      expect(() => t.check(a, dienstag), throwsStateError);
      expect(() => t.advance(a, dienstag), throwsStateError);
    });
  });

  group('Kette', () {
    test('sie zählt erledigte fällige Tage, nicht Kalendertage', () {
      var t = laeuft(a).setWeekdays(a, moMiFr, today: montag);
      t = t.check(a, montag).tracker;
      t = t.check(a, mittwoch).tracker;
      t = t.check(a, freitag).tracker;

      expect(t.streakEndingAt(a, freitag), 3);
      // Das Wochenende trägt sie, verlängert sie aber nicht.
      expect(t.currentStreak(a, sonntag), 3);
      expect(t.check(a, tag(7)).streak, 4);
    });

    test('nach einem verpassten Tag steht sie eine Stufe tiefer', () {
      expect(HabitRewards.streakAfterMiss(75), 60);
      expect(HabitRewards.streakAfterMiss(60), 30);
      expect(HabitRewards.streakAfterMiss(45), 30);
      expect(HabitRewards.streakAfterMiss(10), 7);
      expect(HabitRewards.streakAfterMiss(7), 3);
      expect(HabitRewards.streakAfterMiss(3), 0);
      expect(HabitRewards.streakAfterMiss(2), 0);
      expect(HabitRewards.streakAfterMiss(0), 0);
    });

    test('ein verpasster Tag kostet eine Stufe, nicht alles', () {
      // Zehn Tage, einer fehlt, dann weiter.
      var t = abhaken(laeuft(a), a, montag, 10);
      expect(t.streakEndingAt(a, tag(9)), 10);

      expect(t.streakEndingAt(a, tag(10)), 7);
      t = t.check(a, tag(11)).tracker;
      expect(t.streakEndingAt(a, tag(11)), 8);
    });

    test('jeder weitere verpasste Tag kostet wieder eine', () {
      final t = abhaken(laeuft(a), a, montag, 10);

      expect(t.streakEndingAt(a, tag(10)), 7);
      expect(t.streakEndingAt(a, tag(11)), 3);
      expect(t.streakEndingAt(a, tag(12)), 0);
      expect(t.streakEndingAt(a, tag(13)), 0);
    });

    test('heute zählt erst als verpasst, wenn der Tag vorbei ist', () {
      final t = abhaken(laeuft(a), a, montag, 10);

      expect(t.currentStreak(a, tag(10)), 10);
      expect(t.currentStreak(a, tag(11)), 7);
    });

    test('wer jeden zweiten Tag abhakt, hält seine Stufe und steigt nicht', () {
      // Die Kehrseite der Regel, bewusst so: 8, verpasst 7, 8, verpasst 7.
      var t = abhaken(laeuft(a), a, montag, 8);
      for (var i = 9; i < 30; i += 2) {
        t = t.check(a, tag(i)).tracker;
        expect(t.streakEndingAt(a, tag(i)), 8, reason: 'Tag $i');
      }
    });

    test('ein Streak-Eis verhindert den Rückfall', () {
      var t = abhaken(laeuft(a), a, montag, 10);
      t = t.freeze(tag(10), today: tag(11));

      expect(t.streakEndingAt(a, tag(10)), 10);
      expect(t.check(a, tag(11)).streak, 11);
    });

    test('die Erfahrung rechnet mit der gefallenen Kette, nicht mit null', () {
      var t = abhaken(laeuft(a), a, montag, 10);
      t = t.check(a, tag(11)).tracker;

      final ohneLuecke = abhaken(laeuft(a), a, montag, 10).totalXp;
      // Das elfte Häkchen schließt eine Kette von 8 ab, nicht von 1.
      expect(t.totalXp - ohneLuecke, HabitRewards.xpFor(8));
      expect(HabitRewards.xpFor(8), greaterThan(HabitRewards.xpFor(1)));
    });

    test('die längste Kette fällt durch Verpassen nicht', () {
      var t = abhaken(laeuft(a), a, montag, 10);
      t = t.check(a, tag(11)).tracker;

      expect(t.longestStreak, 10);
    });

    test('das Eis rettet auch nach zwei Fehltagen noch eine Stufe', () {
      // Vorgestern verpasst: aus 10 wurden 7. Gestern verpasst: Ein Eis
      // dort hält die 7, statt auf 3 zu fallen.
      final t = abhaken(laeuft(a), a, montag, 10);

      expect(t.rescuableDay(tag(12)), tag(11));
    });

    test('das Eis rettet auch die Tageskette allein', () {
      // a läuft nur montags und trägt die Tageskette; b ist täglich, hat
      // aber nach seinem ersten Häkchen keine eigene Kette mehr. Dienstag
      // fällig, nichts abgehakt: Die Tageskette fiele.
      var t = laeuft(a)
          .setWeekdays(a, const <int>{1}, today: montag)
          .activate(b, today: tag(-7));
      t = t.check(b, tag(-7)).tracker;
      t = t.check(a, montag).tracker;
      expect(t.streakEndingAt(b, montag), 0);
      expect(t.dayStreakEndingAt(montag), greaterThan(0));

      expect(t.rescuableDay(mittwoch), dienstag);
    });

    test('ein unveränderter Plan schreibt nichts', () {
      final t = laeuft(a).setWeekdays(a, moMiFr, today: montag);

      expect(t.setWeekdays(a, moMiFr, today: dienstag), same(t));
      expect(
        laeuft(a).setWeekdays(a, HabitPlan.everyDay, today: montag),
        isA<HabitTracker>().having(
          (x) => x.weekdaysFor(a),
          'weekdays',
          HabitPlan.everyDay,
        ),
      );
    });

    test('an einem Tag außerhalb des Plans gibt es nichts zu retten', () {
      var t = laeuft(a).setWeekdays(a, moMiFr, today: montag);
      t = t.check(a, montag).tracker;

      expect(t.rescuableDay(mittwoch), isNull);
    });
  });

  group('Stoppen', () {
    test('die Kette bleibt stehen, bis die Gewohnheit wieder läuft', () {
      var t = abhaken(laeuft(a), a, montag, 5);
      t = t.deactivate(a, today: freitag);
      t = t.activate(a, today: tag(20));

      expect(t.streakEndingAt(a, tag(19)), 5);
      expect(t.check(a, tag(20)).streak, 6);
    });

    test('stoppen gilt ab morgen: Was heute offen war, ist verpasst', () {
      var t = abhaken(laeuft(a), a, montag, 10);
      t = t.deactivate(a, today: tag(10));

      expect(t.streakEndingAt(a, tag(10)), 7);
      expect(t.streakEndingAt(a, tag(40)), 7);
    });

    test('eine offene Gewohnheit zu stoppen macht den Tag nicht fertig', () {
      var t = laeuft(a).activate(b, today: montag);
      t = t.check(a, montag).tracker;
      expect(t.isDayComplete(montag), isFalse);

      t = t.deactivate(b, today: montag);

      expect(t.isDayComplete(montag), isFalse);
      expect(t.canOpenChest(montag), isFalse);
      // Morgen zählt sie nicht mehr.
      expect(t.check(a, dienstag).tracker.isDayComplete(dienstag), isTrue);
    });

    test('am selben Tag wieder aufgenommen, pausiert sie nie', () {
      final t = abhaken(laeuft(a), a, montag, 1)
          .deactivate(a, today: dienstag)
          .activate(a, today: dienstag);

      expect(t.isDueOn(a, dienstag), isTrue);
      expect(t.isDueOn(a, mittwoch), isTrue);
    });

    test('sie nimmt ihre Wochentage mit über die Pause', () {
      var t = laeuft(a).setWeekdays(a, moMiFr, today: montag);
      t = t.deactivate(a, today: montag).activate(a, today: tag(14));

      expect(t.weekdaysFor(a), moMiFr);
      expect(t.isDueOn(a, tag(14)), isTrue);
      expect(t.isDueOn(a, tag(15)), isFalse);
    });

    test('eine pausierte ohne Datum fortzusetzen wirft', () {
      final t = laeuft(a).deactivate(a, today: montag);

      expect(() => t.activate(a), throwsStateError);
    });
  });

  group('Ruhetag', () {
    HabitTracker nurMoMiFr() => laeuft(a).setWeekdays(a, moMiFr, today: montag);

    test('er ist kein erledigter Tag: keine Truhe, keine Tagesform', () {
      final t = nurMoMiFr().check(a, montag).tracker;

      expect(t.dueIdsOn(dienstag), isEmpty);
      expect(t.isDayComplete(dienstag), isFalse);
      expect(t.canOpenChest(dienstag), isFalse);
      expect(t.formOn(dienstag).isInForm, isFalse);
    });

    test('er trägt die Tageskette, verlängert sie aber nicht', () {
      var t = nurMoMiFr().check(a, montag).tracker;
      t = t.check(a, mittwoch).tracker;

      expect(t.dayStreakEndingAt(dienstag), 1);
      expect(t.dayStreakEndingAt(mittwoch), 2);
      expect(t.currentDayStreak(freitag), 2);
    });

    test('ein verpasster fälliger Tag lässt auch die Tageskette fallen', () {
      final t = abhaken(laeuft(a), a, montag, 10);

      expect(t.dayStreakEndingAt(tag(9)), 10);
      expect(t.dayStreakEndingAt(tag(10)), 7);
      expect(t.longestDayStreak, 10);
    });

    test('erledigt ist der Tag, wenn alles Fällige erledigt ist', () {
      var t = nurMoMiFr().activate(b, today: montag);
      // Dienstag ist nur b fällig.
      t = t.check(b, dienstag).tracker;

      expect(t.dueIdsOn(dienstag), <String>[b]);
      expect(t.isDayComplete(dienstag), isTrue);
      expect(t.formOn(dienstag).isInForm, isTrue);
    });

    test('ein gestoppter Stand ohne Plan macht keinen Ruhetag kaputt', () {
      // Ein Stand von vor dem Wochenplan: b wurde irgendwann gestoppt.
      final alt = HabitTracker.fromJson(<String, Object?>{
        'activeIds': <Object?>[a],
        'checks': <String, Object?>{
          a: <Object?>['2026-10-05', '2026-10-07'],
          b: <Object?>['2026-09-01', '2026-09-02'],
        },
        'plans': <String, Object?>{
          a: <Object?>[
            <String, Object?>{
              'from': '2026-10-05',
              'days': <Object?>[1, 3, 5],
            },
          ],
        },
      });

      // b pausiert seit dem Tag nach seinem letzten Häkchen.
      expect(alt.isDueOn(b, const Day(2026, 9, 2)), isTrue);
      expect(alt.isDueOn(b, const Day(2026, 9, 3)), isFalse);
      expect(alt.streakEndingAt(b, dienstag), 2);
      // Und Dienstag bleibt ein Ruhetag.
      final amMontag = alt.dayStreakEndingAt(montag);
      expect(alt.dayStreakEndingAt(mittwoch), amMontag + 1);
    });
  });

  group('Speichern', () {
    test('der Plan überlebt toJson und zurück', () {
      var t = laeuft(a).setWeekdays(a, moMiFr, today: montag);
      t = t.check(a, montag).tracker.deactivate(a, today: mittwoch);

      final geladen = HabitTracker.fromJson(t.toJson());

      expect(geladen.toJson(), t.toJson());
      expect(geladen.weekdaysFor(a), moMiFr);
      expect(geladen.isDueOn(a, mittwoch), isTrue);
      expect(geladen.isDueOn(a, freitag), isFalse);
    });

    test('Unlesbares im Plan wird übersprungen, nicht geworfen', () {
      final t = HabitTracker.fromJson(<String, Object?>{
        'activeIds': <Object?>[a],
        'plans': <String, Object?>{
          a: <Object?>[
            'kaputt',
            <String, Object?>{
              'from': 'nie',
              'days': <Object?>[1],
            },
            <String, Object?>{
              'from': '2026-10-05',
              'days': <Object?>[9],
            },
            <String, Object?>{
              'from': '2026-10-06',
              'days': <Object?>[2, 'x', 4],
            },
          ],
          b: 'auch kaputt',
        },
      });

      expect(t.isDueOn(a, montag), isTrue);
      expect(t.weekdaysFor(a), const <int>{2, 4});
      expect(t.isDueOn(a, donnerstag), isTrue);
      expect(t.isDueOn(a, samstag), isFalse);
    });

    test('ein Stand ohne Plan rechnet wie bisher: jeder Tag fällig', () {
      final t = HabitTracker.fromJson(<String, Object?>{
        'activeIds': <Object?>[a],
        'checks': <String, Object?>{
          a: <Object?>['2026-10-05', '2026-10-06'],
        },
      });

      expect(t.streakEndingAt(a, dienstag), 2);
      expect(t.toJson().containsKey('plans'), isFalse);
    });
  });
}
