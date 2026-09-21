import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Tag 1 bis Tag 5 als benannte Größen — die Tests lesen sich sonst wie
/// Datumsarithmetik statt wie Aussagen über Ketten.
const Day _tag1 = Day(2026, 8, 10);
final Day _tag2 = _tag1.next;
final Day _tag3 = _tag2.next;
final Day _tag4 = _tag3.next;
final Day _tag5 = _tag4.next;

HabitTemplate _irgendeine() => HabitCatalog.all.first;

HabitTracker _mitVorlage() {
  return const HabitTracker.empty().activate(_irgendeine().id);
}

HabitTracker _abhaken(HabitTracker tracker, List<Day> tage) {
  var current = tracker;
  for (final tag in tage) {
    current = current.check(_irgendeine().id, tag).tracker;
  }
  return current;
}

void main() {
  final id = _irgendeine().id;

  group('Vorrat', () {
    test('ein frischer Stand hat den vollen Vorrat', () {
      const tracker = HabitTracker.empty();

      expect(tracker.usedFreezes, 0);
      expect(tracker.freezesLeft, StreakFreeze.lifetimeStock);
    });

    test('ein gelegtes Eis fehlt im Vorrat', () {
      final tracker = _abhaken(
        _mitVorlage(),
        <Day>[_tag1],
      ).freeze(_tag2, today: _tag3);

      expect(tracker.usedFreezes, 1);
      expect(tracker.freezesLeft, StreakFreeze.lifetimeStock - 1);
    });

    test('ist der Vorrat leer, legt freeze() nichts mehr', () {
      var tracker = _abhaken(_mitVorlage(), <Day>[_tag1]);
      // Jedes Eis braucht einen eigenen Tag — so viele Tage, wie es Eis
      // gibt, plus einen, der übrig bleiben muss.
      var tag = _tag2;
      for (var i = 0; i < StreakFreeze.lifetimeStock; i++) {
        tracker = tracker.freeze(tag, today: _tag5);
        tag = tag.next;
      }
      final voll = tracker;

      expect(voll.freezesLeft, 0);
      expect(voll.freeze(tag, today: _tag5).frozenDays, voll.frozenDays);
    });

    test('heruntergenommen kommt das Eis zurück', () {
      final gelegt = _abhaken(
        _mitVorlage(),
        <Day>[_tag1],
      ).freeze(_tag2, today: _tag3);

      expect(gelegt.unfreeze(_tag2).freezesLeft, StreakFreeze.lifetimeStock);
    });
  });

  group('Was sich decken lässt', () {
    test('ein Tag mit Häkchen nicht', () {
      final tracker = _abhaken(_mitVorlage(), <Day>[_tag1, _tag2]);

      expect(tracker.canFreeze(_tag2, today: _tag3), isFalse);
    });

    test('heute nicht — der Tag ist noch nicht vorbei', () {
      final tracker = _abhaken(_mitVorlage(), <Day>[_tag1]);

      expect(tracker.canFreeze(_tag3, today: _tag3), isFalse);
      expect(tracker.canFreeze(_tag4, today: _tag3), isFalse);
    });

    test('ein leerer Tag in der Vergangenheit schon', () {
      final tracker = _abhaken(_mitVorlage(), <Day>[_tag1]);

      expect(tracker.canFreeze(_tag2, today: _tag3), isTrue);
    });

    test('derselbe Tag kein zweites Mal', () {
      final tracker = _abhaken(
        _mitVorlage(),
        <Day>[_tag1],
      ).freeze(_tag2, today: _tag3);

      expect(tracker.canFreeze(_tag2, today: _tag3), isFalse);
    });
  });

  group('Was das Eis mit der Kette macht', () {
    test('ohne Eis reißt die Kette', () {
      final tracker = _abhaken(_mitVorlage(), <Day>[_tag1, _tag2, _tag4]);

      expect(tracker.currentStreak(id, _tag4), 1);
    });

    test('mit Eis läuft sie weiter', () {
      final tracker = _abhaken(
        _mitVorlage(),
        <Day>[_tag1, _tag2, _tag4],
      ).freeze(_tag3, today: _tag4);

      expect(tracker.currentStreak(id, _tag4), 3);
    });

    test('der gedeckte Tag zählt nicht mit', () {
      // Drei Häkchen, vier Kalendertage: Die Kette ist drei lang, nicht
      // vier. Das Eis bewahrt, was da war, und schenkt nichts dazu.
      final tracker = _abhaken(
        _mitVorlage(),
        <Day>[_tag1, _tag2, _tag4],
      ).freeze(_tag3, today: _tag4);

      expect(tracker.checksFor(id), 3);
      expect(tracker.streakEndingAt(id, _tag4), 3);
    });

    test('eine Kette, die auf einem gedeckten Tag endet, lebt weiter', () {
      // Gestern nichts getan, Eis gelegt, heute noch nicht abgehakt:
      // Die Kette steht weiter bei zwei und ist nicht gerissen.
      final tracker = _abhaken(
        _mitVorlage(),
        <Day>[_tag1, _tag2],
      ).freeze(_tag3, today: _tag4);

      expect(tracker.currentStreak(id, _tag4), 2);
    });

    test('zwei Fehltage brauchen zwei Eis', () {
      final einEis = _abhaken(
        _mitVorlage(),
        <Day>[_tag1, _tag4],
      ).freeze(_tag2, today: _tag4);

      expect(einEis.currentStreak(id, _tag4), 1);
    });

    test('ein Eis wirkt auf alle Gewohnheiten dieses Tages', () {
      // Es deckt einen **Kalendertag**, nicht eine Gewohnheit: Wer krank
      // im Bett liegt, hakt gar nichts ab.
      final zwei = HabitCatalog.all.take(2).toList();
      var tracker = const HabitTracker.empty();
      for (final habit in zwei) {
        tracker = tracker.activate(habit.id);
      }
      for (final habit in zwei) {
        tracker = tracker.check(habit.id, _tag1).tracker;
        tracker = tracker.check(habit.id, _tag3).tracker;
      }
      tracker = tracker.freeze(_tag2, today: _tag3);

      for (final habit in zwei) {
        expect(tracker.currentStreak(habit.id, _tag3), 2, reason: habit.name);
      }
    });
  });

  group('Was das Eis nicht ändert', () {
    test('es bringt keine Erfahrung und kein Gold', () {
      final ohne = _abhaken(_mitVorlage(), <Day>[_tag1, _tag2]);
      final mit = ohne.freeze(_tag3, today: _tag4);

      expect(mit.totalChecks, ohne.totalChecks);
      expect(mit.totalGold, ohne.totalGold);
      expect(mit.totalXp, ohne.totalXp);
    });

    test('die Charakterwerte hängen weiter nur an Häkchen', () {
      final ohne = _abhaken(_mitVorlage(), <Day>[_tag1, _tag2]);
      final mit = ohne.freeze(_tag3, today: _tag4);
      final stat = _irgendeine().stat;

      expect(mit.stats.valueFor(stat), ohne.stats.valueFor(stat));
    });

    test('die bewahrte Kette zahlt sich erst im nächsten Häkchen aus', () {
      // Der Multiplikator gilt ab dem nächsten Häkchen — rückwirkend
      // wird nichts gutgeschrieben, was nicht getan wurde.
      final gerettet = _abhaken(
        _mitVorlage(),
        <Day>[_tag1, _tag2],
      ).freeze(_tag3, today: _tag4);
      final gerissen = _abhaken(_mitVorlage(), <Day>[_tag1, _tag2]);

      expect(
        gerettet.currentStreak(id, _tag4),
        greaterThan(gerissen.currentStreak(id, _tag4)),
      );
    });
  });

  group('Der Bestwert', () {
    test('steigt durch ein Eis, aber nur um das, was wirklich da war', () {
      final gerissen = _abhaken(_mitVorlage(), <Day>[
        _tag1,
        _tag2,
        _tag4,
        _tag5,
      ]);
      final gedeckt = gerissen.freeze(_tag3, today: _tag5);

      expect(gerissen.longestStreak, 2);
      expect(gedeckt.longestStreak, 4);
    });

    test('ein Eis kann den Bestwert nie senken', () {
      final ohne = _abhaken(_mitVorlage(), <Day>[_tag1, _tag2, _tag3]);
      final mit = ohne.freeze(_tag4, today: _tag5);

      expect(mit.longestStreak, greaterThanOrEqualTo(ohne.longestStreak));
    });
  });

  group('Persistenz', () {
    test('gedeckte Tage überleben einen Neustart', () {
      final tracker = _abhaken(
        _mitVorlage(),
        <Day>[_tag1, _tag2],
      ).freeze(_tag3, today: _tag4);

      final gelesen = HabitTracker.fromJson(tracker.toJson());

      expect(gelesen.frozenDays, tracker.frozenDays);
      expect(gelesen.freezesLeft, tracker.freezesLeft);
      expect(gelesen.currentStreak(id, _tag4), 2);
    });

    test('ein Stand ohne Eis schreibt den Abschnitt gar nicht', () {
      final tracker = _abhaken(_mitVorlage(), <Day>[_tag1]);

      expect(tracker.toJson().containsKey('frozen'), isFalse);
    });

    test('ein gedeckter Tag mit Häkchen wird beim Laden verworfen', () {
      // Ein älterer Stand könnte beides halten. Das Eis wäre dann
      // wirkungslos und trotzdem verbraucht.
      final tracker = _abhaken(_mitVorlage(), <Day>[_tag1]);
      final json = <String, Object?>{
        ...tracker.toJson(),
        'frozen': <Object?>[_tag1.toString()],
      };

      expect(HabitTracker.fromJson(json).frozenDays, isEmpty);
    });
  });
}
