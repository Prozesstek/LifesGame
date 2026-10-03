import 'package:habits/habits.dart';
import 'package:test/test.dart';

/// Die Tagesaufgaben ([ADR-0055](../../../docs/decisions/0055-tageskette-aufgaben-und-wiederholen.md)).
///
/// Die schärfste Zusage steht ganz unten: Eine Aufgabe lässt sich nur
/// **einmal** abholen, und nur, wenn sie erledigt ist — sonst wären die
/// Schlüssel, die daran hängen, eine Frage der Geduld.
void main() {
  const heute = Day(2026, 9, 27);
  const alle = HabitCatalog.all;

  HabitTracker mitAktiven(int n) {
    var t = const HabitTracker.empty();
    for (final h in alle.take(n)) {
      t = t.activate(h.id);
    }
    return t;
  }

  List<DailyQuest> aufgaben(
    HabitTracker t, {
    Day day = heute,
    bool review = true,
    bool richtig = false,
  }) {
    return DailyQuests.forDay(
      t,
      day,
      reviewAvailable: review,
      reviewCorrect: richtig,
    );
  }

  group('Die Auswahl', () {
    test('drei am Tag, wenn genug zur Wahl steht', () {
      expect(aufgaben(mitAktiven(4)), hasLength(DailyQuests.perDay));
    });

    test('immer genau eine zum Abhaken', () {
      var tag = heute;
      for (var i = 0; i < 60; i++) {
        final zaehlen =
            aufgaben(mitAktiven(4), day: tag).where((q) => q.kind.isHabitCount);
        expect(zaehlen, hasLength(1), reason: '$tag');
        tag = tag.next;
      }
    });

    test('derselbe Tag gibt dieselben Aufgaben', () {
      final a = aufgaben(mitAktiven(4)).map((q) => q.id).toList();
      final b = aufgaben(mitAktiven(4)).map((q) => q.id).toList();

      expect(a, b);
    });

    test('über die Tage wechselt die Mischung', () {
      final mischungen = <String>{};
      var tag = heute;
      for (var i = 0; i < 30; i++) {
        mischungen.add(
          aufgaben(mitAktiven(4), day: tag).map((q) => q.id).join(','),
        );
        tag = tag.next;
      }

      expect(mischungen.length, greaterThan(3));
    });

    test('ohne Rückfrage keine Rückfrage-Aufgabe', () {
      var tag = heute;
      for (var i = 0; i < 30; i++) {
        final ids =
            aufgaben(mitAktiven(4), day: tag, review: false).map((q) => q.kind);
        expect(ids, isNot(contains(QuestKind.rueckfrage)));
        tag = tag.next;
      }
    });

    test('„Hake 3 ab“ nur, wenn drei laufen', () {
      var tag = heute;
      for (var i = 0; i < 30; i++) {
        final ids = aufgaben(mitAktiven(2), day: tag).map((q) => q.kind);
        expect(ids, isNot(contains(QuestKind.dreiHaekchen)));
        tag = tag.next;
      }
    });

    test('ohne Gewohnheit keine Aufgabe zum Abhaken', () {
      final ids = aufgaben(const HabitTracker.empty()).map((q) => q.kind);

      expect(ids.where((k) => k.isHabitCount), isEmpty);
    });
  });

  group('Mit Wochenplan (ADR-0064)', () {
    // Der 27.09.2026 ist ein Sonntag.
    const sonntag = heute;
    final montag = heute.next;

    /// Drei laufen, aber sonntags ist nur die erste fällig.
    HabitTracker nurEineSonntags() {
      var t = const HabitTracker.empty();
      for (final h in alle.take(3)) {
        t = t.activate(h.id, today: sonntag);
      }
      for (final h in alle.skip(1).take(2)) {
        t = t.setWeekdays(h.id, const <int>{1}, today: sonntag);
      }
      return t;
    }

    test('gezählt wird, was heute fällig ist', () {
      final kinds = aufgaben(nurEineSonntags()).map((q) => q.kind);

      expect(kinds, isNot(contains(QuestKind.zweiHaekchen)));
      expect(kinds, isNot(contains(QuestKind.dreiHaekchen)));
      final alles = aufgaben(nurEineSonntags())
          .singleWhere((q) => q.kind == QuestKind.alles);
      expect(alles.target, 1);
    });

    test('an einem Ruhetag gibt es keine Aufgabe zum Abhaken', () {
      final t = const HabitTracker.empty()
          .activate(alle.first.id, today: sonntag)
          .setWeekdays(alle.first.id, const <int>{1}, today: sonntag);

      expect(aufgaben(t).where((q) => q.kind.isHabitCount), isEmpty);
    });

    test('liegen geblieben ist nur, was gestern fällig war', () {
      // Die zwei Montags-Gewohnheiten waren sonntags nicht dran; am
      // Montag blieb also höchstens die erste liegen.
      var tag = montag;
      for (var i = 0; i < 30; i++) {
        final liegen = aufgaben(nurEineSonntags(), day: tag)
            .where((q) => q.kind == QuestKind.liegengeblieben);
        for (final q in liegen) {
          expect(q.text, contains(alle.first.name), reason: '$tag');
        }
        tag = tag.next;
      }
    });
  });

  group('Der Stand kommt aus der Historie', () {
    DailyQuest suche(List<DailyQuest> qs, QuestKind kind) =>
        qs.firstWhere((q) => q.kind == kind);

    Day tagMit(QuestKind kind, HabitTracker t) {
      var tag = heute;
      while (!aufgaben(t, day: tag).any((q) => q.kind == kind)) {
        tag = tag.next;
      }
      return tag;
    }

    test('Häkchen zählen mit', () {
      final t = mitAktiven(4);
      final tag = tagMit(QuestKind.zweiHaekchen, t);
      final nachEinem = t.check(alle[0].id, tag).tracker;
      final nachZwei = nachEinem.check(alle[1].id, tag).tracker;

      final halb = suche(aufgaben(nachEinem, day: tag), QuestKind.zweiHaekchen);
      expect(halb.progress, 1);
      expect(
        suche(aufgaben(nachZwei, day: tag), QuestKind.zweiHaekchen).isDone,
        isTrue,
      );
    });

    test('„liegen geblieben“ nennt die Gewohnheit von gestern', () {
      final t = mitAktiven(4);
      final tag = tagMit(QuestKind.liegengeblieben, t);
      final quest = suche(aufgaben(t, day: tag), QuestKind.liegengeblieben);

      expect(quest.text, contains(t.activeHabitsByPriority.first.name));
      final nachher = t.check(t.activeHabitsByPriority.first.id, tag).tracker;
      expect(
        suche(aufgaben(nachher, day: tag), QuestKind.liegengeblieben).isDone,
        isTrue,
      );
    });

    test('die Rückfrage zählt, wenn sie richtig war', () {
      final t = mitAktiven(4);
      final tag = tagMit(QuestKind.rueckfrage, t);

      expect(
        suche(aufgaben(t, day: tag, richtig: true), QuestKind.rueckfrage)
            .isDone,
        isTrue,
      );
    });
  });

  group('Abholen', () {
    const erledigt = DailyQuest(
      kind: QuestKind.rueckfrage,
      text: '',
      progress: 1,
      target: 1,
    );

    test('eine erledigte Aufgabe lässt sich abholen', () {
      final nachher = mitAktiven(1).claimQuest(heute, erledigt);

      expect(nachher.isQuestClaimed(heute, erledigt.id), isTrue);
      expect(nachher.claimedQuestCount, 1);
    });

    test('eine offene nicht', () {
      final t = mitAktiven(4);
      final offen = aufgaben(t).firstWhere((q) => !q.isDone);

      expect(identical(t.claimQuest(heute, offen), t), isTrue);
    });

    test('dieselbe nicht zweimal', () {
      final einmal = mitAktiven(1).claimQuest(heute, erledigt);

      expect(einmal.claimQuest(heute, erledigt).claimedQuestCount, 1);
      expect(
        einmal.claimQuest(heute.next, erledigt).claimedQuestCount,
        2,
        reason: 'am nächsten Tag ist es eine neue Aufgabe',
      );
    });

    test('Abgeholtes überlebt das Speichern', () {
      const q = DailyQuest(
        kind: QuestKind.alles,
        text: '',
        progress: 1,
        target: 1,
      );
      final t = mitAktiven(1).claimQuest(heute, q);

      final geladen = HabitTracker.fromJson(t.toJson());

      expect(geladen.isQuestClaimed(heute, 'alles'), isTrue);
      expect(geladen.claimedQuestCount, 1);
    });

    test('Unbekanntes wird beim Laden übersprungen', () {
      final geladen = HabitTracker.fromJson(<String, Object?>{
        'quests': <String, Object?>{
          heute.toString(): <Object?>['alles', 'gibt-es-nicht', 7],
          'kein-tag': <Object?>['alles'],
        },
      });

      expect(geladen.claimedQuestCount, 1);
    });

    test('ohne Abgeholtes sieht der Stand aus wie vorher', () {
      expect(mitAktiven(1).toJson().containsKey('quests'), isFalse);
    });
  });
}
