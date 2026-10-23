import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Die Statistik der Gewohnheiten (ADR-0087): Fenster, Quote, Vergleich,
/// Abschnitte, Wochentage, Mengen, Rekorde und der Jahresrückblick.
///
/// Der 05.10.2026 ist ein Montag — die Tests zählen von dort.
void main() {
  const montag = Day(2026, 10, 5);
  Day tag(int n) => montag.plus(n);

  final a = HabitCatalog.all[0].id;
  final b = HabitCatalog.all[1].id;

  HabitTracker laeuft(List<String> ids, {Day? ab}) {
    var t = const HabitTracker.empty();
    for (final id in ids) {
      t = t.activate(id, today: ab ?? montag);
    }
    return t;
  }

  HabitTracker abhaken(HabitTracker t, String id, Iterable<int> tage) {
    var tracker = t;
    for (final n in tage) {
      tracker = tracker.check(id, tag(n)).tracker;
    }
    return tracker;
  }

  group('Das Fenster', () {
    test('eine Woche läuft von Montag bis Sonntag', () {
      final f = StatFenster.um(
        StatZeitraum.woche,
        tag(3),
        anfang: montag,
        heute: tag(3),
      );
      expect(f.von, montag);
      expect(f.bis, tag(6));
      expect(f.laenge, 7);
      expect(f.davor.von, tag(-7));
      expect(f.danach.von, tag(7));
    });

    test('ein Monat ist ein Kalendermonat, auch im Schaltjahr', () {
      final feb = StatFenster.um(
        StatZeitraum.monat,
        const Day(2028, 2, 10),
        anfang: montag,
        heute: montag,
      );
      expect(feb.von, const Day(2028, 2, 1));
      expect(feb.bis, const Day(2028, 2, 29));
      expect(feb.davor.von, const Day(2028, 1, 1));
      expect(feb.danach.bis, const Day(2028, 3, 31));
    });

    test('ein Jahr ist ein Kalenderjahr', () {
      final f = StatFenster.um(
        StatZeitraum.jahr,
        montag,
        anfang: montag,
        heute: montag,
      );
      expect(f.von, const Day(2026, 1, 1));
      expect(f.bis, const Day(2026, 12, 31));
      expect(f.davor.von, const Day(2025, 1, 1));
    });

    test('„Gesamt“ reicht vom ersten Häkchen bis heute und blättert nicht', () {
      final t = abhaken(laeuft(<String>[a]), a, <int>[0, 1]);
      final r = StatRechnung(t, heute: tag(10));
      final f = r.fenster(StatZeitraum.gesamt);
      expect(f.von, montag);
      expect(f.bis, tag(10));
      expect(f.blaetterbar, isFalse);
      expect(f.davor, f);
    });
  });

  group('Ein Tag', () {
    test('zählt Fälliges und Erledigtes, Zukunft ist Zukunft', () {
      final t = abhaken(laeuft(<String>[a, b]), a, <int>[0]);
      final r = StatRechnung(t, heute: tag(1));

      final erster = r.tag(montag);
      expect(erster.faellig, 2);
      expect(erster.erledigt, 1);
      expect(erster.haekchen, 1);
      expect(erster.quote.prozent, 50);

      expect(r.tag(tag(5)).zukunft, isTrue);
      expect(r.tag(tag(5)).ruhetag, isFalse);
    });

    test('ein Tag außerhalb des Plans ist ein Ruhetag', () {
      final t =
          laeuft(<String>[a]).setWeekdays(a, <int>{1, 3, 5}, today: montag);
      final r = StatRechnung(t, heute: tag(6));

      expect(r.tag(tag(1)).ruhetag, isTrue); // Dienstag
      expect(r.tag(tag(2)).faellig, 1); // Mittwoch
    });

    test('ein Streak-Eis steht da, zählt aber nicht als erledigt', () {
      var t = abhaken(laeuft(<String>[a]), a, <int>[0]);
      t = t.freeze(tag(1), today: tag(2));
      final r = StatRechnung(t, heute: tag(2));

      expect(r.tag(tag(1)).eis, isTrue);
      expect(r.tag(tag(1)).quote.erledigt, 0);
      expect(r.tag(tag(1)).quote.faellig, 1);
    });

    test('eine gestoppte Gewohnheit zählt mit, solange sie lief', () {
      var t = abhaken(laeuft(<String>[a]), a, <int>[0, 1]);
      t = t.deactivate(a, today: tag(1));
      final r = StatRechnung(t, heute: tag(4));

      expect(r.tag(tag(1)).quote.voll, isTrue);
      expect(r.tag(tag(3)).ruhetag, isTrue);
      expect(t.trackedIds, contains(a));
    });
  });

  group('Quote und Vergleich', () {
    test('die Quote der Woche zählt nur bis heute', () {
      final t = abhaken(laeuft(<String>[a]), a, <int>[0, 1]);
      final r = StatRechnung(t, heute: tag(2));
      final q = r.quote(r.fenster(StatZeitraum.woche));
      expect(q.erledigt, 2);
      expect(q.faellig, 3);
    });

    test('verglichen werden die gleichen Tage davor', () {
      // Letzte Woche Mo bis Mi eins von drei, diese Woche drei von drei.
      final ab = tag(-7);
      var t = laeuft(<String>[a], ab: ab);
      t = abhaken(t, a, <int>[-7, 0, 1, 2]);
      // Rest der Vorwoche voll — darf am Mittwoch nicht mitzählen.
      t = abhaken(t, a, <int>[-4, -3, -2, -1]);
      final r = StatRechnung(t, heute: tag(2));

      expect(r.vergleich(r.fenster(StatZeitraum.woche)), 100 - 33);
    });

    test('ohne Fälliges davor gibt es keinen Vergleich', () {
      final t = abhaken(laeuft(<String>[a]), a, <int>[0]);
      final r = StatRechnung(t, heute: montag);
      expect(r.vergleich(r.fenster(StatZeitraum.woche)), isNull);
      expect(r.vergleich(r.fenster(StatZeitraum.gesamt)), isNull);
    });
  });

  group('Abschnitte', () {
    test('das Jahr in zwölf Monate, die Zukunft markiert', () {
      final t = abhaken(laeuft(<String>[a]), a, <int>[0]);
      final r = StatRechnung(t, heute: montag);
      final f = r.fenster(StatZeitraum.jahr);
      final monate = r.abschnitte(f, f.balkenTeilung);

      expect(monate, hasLength(12));
      expect(monate[9].von, const Day(2026, 10, 1));
      expect(monate[9].quote.erledigt, 1);
      expect(monate[10].zukunft, isTrue);
    });

    test('die Kurve des Jahres je Woche, mit der Kette am Ende', () {
      final t = abhaken(laeuft(<String>[a]), a, <int>[0, 1, 2]);
      final r = StatRechnung(t, heute: tag(2));
      final f = r.fenster(StatZeitraum.jahr);
      final wochen = r.abschnitte(f, f.kurvenTeilung);
      final diese =
          wochen.firstWhere((w) => w.von <= tag(2) && w.bis >= tag(2));

      expect(diese.kette, 3);
      expect(diese.quote.voll, isTrue);
      expect(wochen.first.von, const Day(2026, 1, 1));
      expect(wochen.last.bis, const Day(2026, 12, 31));
    });

    test('die Woche je Tag, sieben Stück', () {
      final t = laeuft(<String>[a]);
      final r = StatRechnung(t, heute: montag);
      final f = r.fenster(StatZeitraum.woche);
      expect(r.abschnitte(f, f.balkenTeilung), hasLength(7));
    });
  });

  test('der stärkste Wochentag hat die beste Quote', () {
    // Zwei Wochen, dienstags immer, sonst nie.
    final t = abhaken(laeuft(<String>[a]), a, <int>[1, 8]);
    final r = StatRechnung(t, heute: tag(13));
    final f = r.fenster(StatZeitraum.gesamt);

    expect(r.staerksterWochentag(f), 2);
    expect(r.jeWochentag(f)[2]!.prozent, 100);
    expect(r.jeWochentag(f)[1]!.prozent, 0);
  });

  test('eine Gewohnheit mit Menge zählt Summe und Schnitt', () {
    final eigen = CustomHabit(
      id: 'eigen-liegestuetze',
      name: 'Liegestütze',
      stat: HabitStat.staerke,
      area: SkillArea.koerper,
      difficulty: HabitDifficulty.mittel,
      goal: HabitGoal.menge(target: 3, unit: 'Mal'),
    );
    var t = const HabitTracker.empty()
        .addCustom(eigen, slots: 5)
        .activate(eigen.id, today: montag);
    // Montag voll (3), Dienstag zwei, Mittwoch nichts.
    for (var i = 0; i < 3; i++) {
      t = t.advance(eigen.id, montag).tracker;
    }
    t = t.advance(eigen.id, tag(1)).tracker.advance(eigen.id, tag(1)).tracker;
    final r = StatRechnung(t, heute: tag(2), habitId: eigen.id);
    final menge = r.menge(r.fenster(StatZeitraum.woche))!;

    expect(menge.summe, 5);
    expect(menge.tage, 3);
    expect(menge.schnitt, 2);
    expect(
      StatRechnung(t, heute: tag(2)).menge(r.fenster(StatZeitraum.woche)),
      isNull,
      reason: 'gesamt gibt es keine Menge',
    );
  });

  group('Rekorde', () {
    test('perfekte Wochen, bester Monat, meiste Häkchen, längste Kette', () {
      // Woche 1 ganz, Woche 2 bis auf Freitag; dazu b am ersten Montag.
      var t = laeuft(<String>[a]);
      final tage = <int>[
        for (var i = 0; i < 14; i++)
          if (i != 11) i,
      ];
      t = abhaken(t, a, tage);
      t = t.activate(b, today: montag).check(b, montag).tracker;
      final r = StatRechnung(t, heute: tag(13));
      final rekorde = r.rekorde();

      expect(rekorde.perfekteWochen, 0, reason: 'b war in Woche 1 offen');
      expect(rekorde.meisteHaekchen!.tag, montag);
      expect(rekorde.meisteHaekchen!.anzahl, 2);
      expect(rekorde.besterMonat!.monat, const Day(2026, 10, 1));
      expect(rekorde.haekchenGesamt, 14);

      final nurA = StatRechnung(t, heute: tag(13), habitId: a).rekorde();
      expect(nurA.perfekteWochen, 1);
      expect(nurA.laengsteKette, greaterThanOrEqualTo(11));
    });

    test('ein Monat mit zu wenig Fälligem ist kein bester Monat', () {
      final t = abhaken(laeuft(<String>[a]), a, <int>[0]);
      final r = StatRechnung(t, heute: montag);
      expect(r.rekorde().besterMonat, isNull);
    });
  });

  test('der Jahresrückblick wird vom 20.12. bis 7.1. angekündigt', () {
    expect(StatRechnung.rueckblickJahr(const Day(2026, 12, 19)), isNull);
    expect(StatRechnung.rueckblickJahr(const Day(2026, 12, 20)), 2026);
    expect(StatRechnung.rueckblickJahr(const Day(2027, 1, 7)), 2026);
    expect(StatRechnung.rueckblickJahr(const Day(2027, 1, 8)), isNull);
  });

  group('Der Jahresrückblick', () {
    test('zählt das Jahr und kennt die Gewohnheit des Jahres', () {
      var t = laeuft(<String>[a, b]);
      t = abhaken(t, a, <int>[for (var i = 0; i < 20; i++) i]);
      t = abhaken(t, b, <int>[for (var i = 0; i < 20; i += 2) i]);
      final r = StatRechnung(t, heute: tag(19));
      final jahr = r.jahresrueckblick(2026);

      expect(jahr.jahr, 2026);
      expect(jahr.tage, hasLength(365));
      expect(jahr.haekchen, 30);
      expect(jahr.besteQuote!.habitId, a);
      expect(jahr.meisteHaekchen!.habitId, a);
      expect(jahr.laengsteKette, 20);
      expect(jahr.vorjahr, isNull);
    });

    test('mit einem Vorjahr wird verglichen', () {
      const ab = Day(2025, 12, 20);
      var t = laeuft(<String>[a], ab: ab);
      t = t.check(a, ab).tracker.check(a, const Day(2026, 1, 2)).tracker;
      final r = StatRechnung(t, heute: const Day(2026, 1, 2));
      final jahr = r.jahresrueckblick(2026);

      expect(jahr.vorjahr, isNotNull);
      expect(jahr.vorjahr!.haekchen, 1);
    });
  });
}
