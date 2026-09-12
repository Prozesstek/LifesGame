import 'package:abilities/abilities.dart';
import 'package:achievements/achievements.dart';
import 'package:combat/combat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:identity/identity.dart';
import 'package:lifes_game/achievements/achievements_controller.dart';
import 'package:lifes_game/character/abilities_controller.dart';
import 'package:lifes_game/character/identity_controller.dart';
import 'package:lifes_game/dev/debug_grants.dart';
import 'package:lifes_game/gear/gear_controller.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:theory/theory.dart';

/// Die Naht zwischen `achievements` und allem, woran es hängt.
///
/// **Kein Package kann das allein prüfen.** `package:achievements` hält
/// Ids — eine Titel-Id, eine Move-Id — und weiß nicht, ob es sie drüben
/// gibt. `package:identity` kennt die Errungenschaften nicht,
/// `package:combat` auch nicht. Erst hier treffen sie sich.
///
/// Dieselbe Bauform wie `abilities_seam_test.dart` und
/// `habits_theory_test.dart`.
void main() {
  ProviderContainer containerMit(SaveData saved) {
    final container = ProviderContainer(
      overrides: [savedGameProvider.overrideWithValue(saved)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('Jede Id kommt drüben an', () {
    test('jede Titel-Id existiert in package:identity', () {
      for (final achievement in AchievementCatalog.all) {
        final id = achievement.titleId;
        if (id == null) continue;
        expect(
          TitleCatalog.byId(id),
          isNotNull,
          reason:
              '${achievement.id} vergibt den Titel "$id", den es nicht '
              'gibt.',
        );
      }
    });

    // Die Gegenrichtung, und sie ist die wichtigere: Ein Titel **ohne**
    // Errungenschaft wäre unverdienbar und stünde für immer gesperrt im
    // Dialog. Seit ADR-0033 ist eine Errungenschaft der einzige Weg zu
    // einem Titel.
    test('jeder Titel hat eine Errungenschaft, die ihn vergibt', () {
      final vergeben = <String>{
        for (final a in AchievementCatalog.all)
          if (a.titleId != null) a.titleId!,
      };

      for (final title in TitleCatalog.all) {
        expect(
          vergeben,
          contains(title.id),
          reason: 'Der Titel "${title.id}" ist von niemandem zu verdienen.',
        );
      }
    });

    test('jede Move-Id existiert in package:combat', () {
      for (final achievement in AchievementCatalog.all) {
        final id = achievement.moveId;
        if (id == null) continue;
        expect(Moves.byId(id), isNotNull, reason: achievement.id);
      }
    });

    test('jede Fähigkeit aus einer Errungenschaft kennt ihre Quelle', () {
      for (final ability in AbilityCatalog.choosable) {
        final source = ability.source;
        if (source is! FromAchievement) continue;

        final achievement = AchievementCatalog.byId(source.achievementId);
        expect(
          achievement,
          isNotNull,
          reason:
              '${ability.moveId} hängt an "${source.achievementId}", '
              'die es nicht gibt.',
        );
        // Und beide Seiten müssen dasselbe sagen: Die Errungenschaft
        // vergibt genau diesen Move.
        expect(achievement!.moveId, ability.moveId);
      }
    });

    test('jede Fähigkeit aus dem Katalog kommt genau einmal vor', () {
      final ids = <String>{};
      for (final ability in AbilityCatalog.choosable) {
        expect(ids.add(ability.moveId), isTrue, reason: ability.moveId);
      }
      expect(AbilityCatalog.choosable, hasLength(19));
    });
  });

  group('Rückwirkend', () {
    // Der Kern von ADR-0033: Was verdient ist, wird aus der Historie
    // gerechnet. Ein Stand, der die Bedingung längst erfüllt, bekommt die
    // Errungenschaft beim Start — ohne dass irgendwo etwas nachgetragen
    // werden müsste.
    test('ein bestehender Stand hat sofort, was er verdient hat', () {
      var tracker = const HabitTracker.empty();
      final template = HabitCatalog.all.first;
      tracker = tracker.activate(template.id);
      var day = const Day(2026, 1, 1);
      for (var i = 0; i < 40; i++) {
        tracker = tracker.check(template.id, day).tracker;
        day = day.next;
      }

      final container = containerMit(SaveData(habits: tracker));
      final verdient = container.read(earnedAchievementIdsProvider);

      expect(verdient, contains('erster-schritt'));
      expect(verdient, contains('entschlossen'));
      expect(verdient, contains('bestaendig'));
      expect(container.read(fameProvider), greaterThan(0));
    });

    test('ein leerer Stand hat nichts und keinen Ruhm', () {
      final container = containerMit(const SaveData.empty());

      expect(container.read(earnedAchievementIdsProvider), isEmpty);
      expect(container.read(fameProvider), 0);
      expect(container.read(achievementXpProvider), 0);
      expect(container.read(achievementGoldProvider), 0);
    });
  });

  group('Der Entwicklermodus schaltet nichts frei (Punkt 10)', () {
    // **Er schenkt Summanden, keine Historie** (ADR-0021). Eine geschenkte
    // Stufe darf deshalb keine Errungenschaft auslösen — sonst ließe sich
    // der ganze Satz per Knopfdruck einsammeln, und Ziel 7 wäre nicht
    // mehr nachweisbar.
    test('geschenkte Erfahrung und Gold ändern nichts', () {
      final container = containerMit(
        const SaveData(grants: DebugGrants(bonusXp: 100000, bonusGold: 100000)),
      );

      expect(container.read(earnedAchievementIdsProvider), isEmpty);
      expect(container.read(fameProvider), 0);
    });

    test('geschenkte Fähigkeiten ändern nichts', () {
      final container = containerMit(
        SaveData(
          grants: DebugGrants(
            unlockedAbilityIds: <String>{
              for (final a in AbilityCatalog.choosable) a.moveId,
            },
          ),
        ),
      );

      expect(container.read(earnedAchievementIdsProvider), isEmpty);
    });
  });

  group('Titel hängen an den Errungenschaften', () {
    test('ohne Errungenschaft ist kein Titel verdient', () {
      final container = containerMit(const SaveData.empty());

      expect(container.read(earnedTitleIdsProvider), isEmpty);
      expect(container.read(earnedTitlesProvider), isEmpty);
    });

    test('drei Tage Kette bringen genau den Entschlossenen', () {
      var tracker = const HabitTracker.empty();
      final template = HabitCatalog.all.first;
      tracker = tracker.activate(template.id);
      var day = const Day(2026, 1, 1);
      for (var i = 0; i < 3; i++) {
        tracker = tracker.check(template.id, day).tracker;
        day = day.next;
      }

      final container = containerMit(SaveData(habits: tracker));

      expect(container.read(earnedTitleIdsProvider), contains('entschlossen'));
      expect(
        container.read(earnedTitlesProvider).map((t) => t.id),
        contains('entschlossen'),
      );
      expect(
        container.read(earnedTitleIdsProvider),
        isNot(contains('bestaendig')),
      );
    });
  });

  group('Fähigkeiten aus Errungenschaften', () {
    test('Sprosse 10 bringt Kraftschlag in die Auswahl', () {
      final ohne = containerMit(
        const SaveData(ladder: LadderProgress(highestDefeated: 9)),
      );
      expect(
        ohne.read(unlockedAbilitiesProvider).map((a) => a.moveId),
        isNot(contains('heavy_attack')),
      );

      final mit = containerMit(
        const SaveData(ladder: LadderProgress(highestDefeated: 10)),
      );
      expect(
        mit.read(unlockedAbilitiesProvider).map((a) => a.moveId),
        contains('heavy_attack'),
      );
    });

    test('die Fähigkeit geht auch wirklich in den Kampf', () {
      final container = containerMit(
        SaveData(
          ladder: const LadderProgress(highestDefeated: 10),
          abilities: ChosenAbilities(moveIds: const <String>['heavy_attack']),
        ),
      );

      // Auf dieser Sprosse ist das Level hoch genug für einen zweiten
      // Platz — sonst fiele der Move hier still heraus, und der Test
      // prüfte nichts.
      expect(container.read(playerLevelProvider).level, greaterThan(2));
      expect(
        container.read(activeMovesProvider).map((m) => m.id),
        contains('heavy_attack'),
      );
    });
  });

  group('Der fünfte Zufluss', () {
    // ADR-0033: 1680 Erfahrung und 560 Gold über ein Spielerleben. Zum
    // Vergleich gibt die Reihe 2775 und 1110 (ADR-0032). Die
    // Errungenschaften sollen daneben stehen, nicht darüber.
    test('er ist gedeckelt und kleiner als die Reihe', () {
      expect(AchievementCatalog.lifetimeXp, 1680);
      expect(AchievementCatalog.lifetimeGold, 560);
      expect(AchievementCatalog.lifetimeXp, lessThan(LadderRewards.lifetimeXp));
      expect(
        AchievementCatalog.lifetimeGold,
        lessThan(LadderRewards.lifetimeGold),
      );
    });

    test('verdiente Errungenschaften stehen in Erfahrung und Gold', () {
      final container = containerMit(
        const SaveData(ladder: LadderProgress(highestDefeated: 1)),
      );

      final ersterSieg = AchievementCatalog.byId('erster-sieg')!;
      expect(container.read(achievementXpProvider), ersterSieg.tier.xp);
      expect(
        container.read(totalXpProvider),
        LadderRewards.xpFor(1) + ersterSieg.tier.xp,
      );
    });

    // Der Kauf ist der Fall, in dem beides zusammenläuft: Er kostet Gold
    // **und** zahlt einen Meilenstein aus. Dass das kein Zirkelbezug
    // wird, ist der Grund für `incomeWithoutAchievementsProvider`.
    test('ein Kauf löst keinen Zirkelbezug aus', () {
      var tracker = const HabitTracker.empty();
      final template = HabitCatalog.all.first;
      tracker = tracker.activate(template.id);
      var day = const Day(2026, 1, 1);
      for (var i = 0; i < 60; i++) {
        tracker = tracker.check(template.id, day).tracker;
        day = day.next;
      }

      final container = containerMit(SaveData(habits: tracker));
      final item = GearCatalog.all.first;

      // Ohne die Auflösung wirft diese Zeile CircularDependencyError.
      expect(container.read(loadoutProvider.notifier).buy(item.id), isNull);
      expect(container.read(loadoutProvider).isOwned(item.id), isTrue);
      expect(
        container.read(earnedAchievementIdsProvider),
        contains('erster-kauf'),
      );
    });
  });

  group('Die zwei neuen Spuren', () {
    test(
      'Niederlagen überleben einen Neustart und ergeben den Unbeugsamen',
      () {
        var ladder = const LadderProgress.empty();
        for (var i = 0; i < 3; i++) {
          ladder = ladder.recordDefeat(1);
        }
        ladder = ladder.defeat(1);

        final stand = SaveData(ladder: ladder);
        final geladen = SaveData.decode(stand.encode());
        final container = containerMit(geladen);

        expect(
          container.read(earnedAchievementIdsProvider),
          contains('unbeugsam'),
        );
        expect(container.read(earnedTitleIdsProvider), contains('unbeugsam'));
      },
    );

    test('gescheiterte Lektionsversuche ergeben den zweiten Anlauf', () {
      final node = theoryGraph.nodes.firstWhere((n) => !n.isFree);
      final lesson = node.lesson;

      var progress = const TheoryProgress.empty();
      progress = progress.submit(lesson, <int?>[
        for (final f in lesson.questions) f.correctIndex == 0 ? 1 : 0,
      ]).progress;
      progress = progress.submit(lesson, <int?>[
        for (final f in lesson.questions) f.correctIndex,
      ]).progress;

      final stand = SaveData(theory: progress);
      final container = containerMit(SaveData.decode(stand.encode()));

      expect(
        container.read(earnedAchievementIdsProvider),
        contains('zweiter-anlauf'),
      );
    });
  });
}
