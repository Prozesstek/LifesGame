import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abilities/abilities.dart';
import 'package:lifes_game/character/abilities_controller.dart';
import 'package:lifes_game/dev/debug_grants.dart';
import 'package:lifes_game/dev/dev_controller.dart';
import 'package:lifes_game/dev/save_slot.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:progression/progression.dart';

/// Prüft den Entwicklermodus — vor allem die Zusagen, die ihn ungefährlich
/// machen (ADR-0021).
///
/// Die wichtigste steht ganz unten: Ohne Zuschläge verhält sich das Spiel
/// **exakt** wie vorher. Ein Dev-Modus, der die normalen Zahlen verschiebt,
/// wäre schlimmer als keiner.
void main() {
  _geschenkteFaehigkeitImKampf();

  ProviderContainer containerMit(SaveData saved) {
    final container = ProviderContainer(
      overrides: [savedGameProvider.overrideWithValue(saved)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('Zuschläge wirken auf die abgeleiteten Werte', () {
    test('geschenkte Erfahrung hebt das Level', () {
      final container = containerMit(const SaveData.empty());

      expect(container.read(playerLevelProvider).level, 1);

      container.read(devGrantsProvider.notifier).addXp(1000);

      expect(container.read(effectiveXpProvider), 1000);
      expect(container.read(playerLevelProvider).level, greaterThan(1));
      // Der verdiente Anteil bleibt davon unberührt — das ist der Grund,
      // warum der Charakterbildschirm die Herkunft zeigen kann.
      expect(container.read(totalXpProvider), 0);
    });

    test('geschenktes Gold ist verfügbar', () {
      final container = containerMit(const SaveData.empty());

      container.read(devGrantsProvider.notifier).addGold(500);

      expect(container.read(goldProvider), 500);
      expect(container.read(goldEarnedProvider), 0);
    });

    test('geschenkte Theoriepunkte kommen oben drauf', () {
      final container = containerMit(const SaveData.empty());
      final vorher = container.read(availableTheoryPointsProvider);

      container.read(devGrantsProvider.notifier).addTheoryPoints(7);

      expect(container.read(availableTheoryPointsProvider), vorher + 7);
    });

    test('geschenkte Fähigkeiten erscheinen in der Auswahl', () {
      final container = containerMit(const SaveData.empty());
      final vorher = container.read(devGrantsProvider).unlockedAbilityIds;

      expect(vorher, isEmpty);

      container.read(devGrantsProvider.notifier).grantAllAbilities();

      expect(container.read(grantedAbilityIdsProvider), isNotEmpty);
    });
  });

  group('Zuschläge sind begrenzt und rücknehmbar', () {
    test('kein Wert fällt unter null', () {
      final container = containerMit(const SaveData.empty());
      final dev = container.read(devGrantsProvider.notifier)
        ..addXp(100)
        ..addXp(-500);

      expect(container.read(devGrantsProvider).bonusXp, 0);
      expect(dev, isNotNull);
    });

    test('Zurücksetzen räumt alles ab', () {
      final container = containerMit(const SaveData.empty());
      final dev = container.read(devGrantsProvider.notifier)
        ..addXp(1000)
        ..addGold(500)
        ..addTheoryPoints(5)
        ..grantAllAbilities();

      expect(container.read(devGrantsProvider).isNotEmpty, isTrue);

      dev.resetGrants();

      expect(container.read(devGrantsProvider).isEmpty, isTrue);
      expect(container.read(playerLevelProvider).level, 1);
      expect(container.read(goldProvider), 0);
    });
  });

  group('Der Spielstand', () {
    test('Zuschläge überleben Kodieren und Dekodieren', () {
      const original = SaveData(
        grants: DebugGrants(
          bonusXp: 1234,
          bonusGold: 99,
          bonusTheoryPoints: 3,
          bonusAbilityPoints: 2,
          unlockedAbilityIds: <String>{'heavy_attack'},
        ),
      );

      final gelesen = SaveData.decode(original.encode());

      expect(gelesen.grants.bonusXp, 1234);
      expect(gelesen.grants.bonusGold, 99);
      expect(gelesen.grants.bonusTheoryPoints, 3);
      expect(gelesen.grants.bonusAbilityPoints, 2);
      expect(gelesen.grants.unlockedAbilityIds, <String>{'heavy_attack'});
    });

    test('ein alter Stand ohne Zuschläge liest sich als leer', () {
      // Formatversion bleibt 1: Das Feld ist rein additiv, ein Stand von
      // gestern verliert nichts (ADR-0010).
      final gelesen = SaveData.decode('{"version":1,"theory":{}}');

      expect(gelesen.grants.isEmpty, isTrue);
    });

    test('Unsinn in den Zuschlägen wirft nicht', () {
      final grants = DebugGrants.fromJson(const <String, Object?>{
        'xp': 'viel',
        'gold': -50,
        'abilities': 'keine Liste',
      });

      expect(grants.isEmpty, isTrue);
    });
  });

  group('Die beiden Spielstände sind getrennt', () {
    test('echter Stand und Dev-Stand haben verschiedene Schlüssel', () {
      // Das ist die Sperre, die Ziel 7 schützt: „Kein Sonderrecht, keine
      // Testdaten, keine Abkürzung über den Debugger."
      expect(SaveSlot.real.storageKey, isNot(SaveSlot.dev.storageKey));
      expect(SaveSlot.dev.isDev, isTrue);
      expect(SaveSlot.real.isDev, isFalse);
    });

    test('ohne Überschreibung ist der echte Stand aktiv', () {
      final container = containerMit(const SaveData.empty());

      expect(container.read(activeSlotProvider), SaveSlot.real);
    });
  });

  group('Ohne Entwicklermodus ändert sich nichts', () {
    test('alle abgeleiteten Werte bleiben wie ohne das Feature', () {
      // Die wichtigste Zusage des ganzen Umbaus: Solange nichts geschenkt
      // wurde, ist jeder Zuschlag 0 und jede Formel identisch mit der
      // vorherigen.
      final container = containerMit(const SaveData.empty());

      expect(container.read(devGrantsProvider).isEmpty, isTrue);
      expect(
        container.read(effectiveXpProvider),
        container.read(totalXpProvider),
      );
      expect(
        container.read(spendableIncomeProvider),
        container.read(goldEarnedProvider),
      );
      expect(
        container.read(availableTheoryPointsProvider),
        TheoryPoints.availableAt(
          level: container.read(playerLevelProvider).level,
          spent: container.read(spentTheoryPointsProvider),
        ),
      );
    });
  });
}

/// Der Weg vom Zuschlag bis in den Kampf.
///
/// **Der Fehler, den diese Gruppe verhindert:** `unlockedAbilitiesProvider`
/// rechnete die Zuschläge ein, `activeMovesProvider` fragte aber
/// `AbilityCatalog.isUnlocked` noch einmal direkt — und das kennt keine
/// Zuschläge. Eine geschenkte Fähigkeit ließ sich anlegen, wurde
/// gespeichert und fiel auf dem Weg in den Kampf still heraus. Sichtbar
/// war das nur als fehlender Knopf.
void _geschenkteFaehigkeitImKampf() {
  group('Geschenkte Fähigkeiten kommen im Kampf an', () {
    /// Ein hoher Stand, damit alle Slots offen sind.
    ProviderContainer mitZuschlag(String moveId) {
      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(
            SaveData(
              grants: DebugGrants(
                bonusXp: 100000,
                unlockedAbilityIds: <String>{moveId},
              ),
              abilities: const ChosenAbilities.empty().withAt(0, moveId),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('eine geschenkte Streak-Fähigkeit steht zur Auswahl', () {
      final container = mitZuschlag('sandsturm');

      expect(
        container.read(unlockedAbilitiesProvider).map((a) => a.moveId),
        contains('sandsturm'),
      );
    });

    test('sie landet auch im Moveset des Kampfes', () {
      // Ohne den Fix scheitert genau das: In der Auswahl steht sie, im
      // Kampf fehlt sie.
      final container = mitZuschlag('sandsturm');

      expect(
        container.read(activeMovesProvider).map((m) => m.id),
        contains('sandsturm'),
      );
    });

    test('das gilt auch für die legendäre', () {
      final container = mitZuschlag('sternenfall');

      expect(
        container.read(activeMovesProvider).map((m) => m.id),
        contains('sternenfall'),
      );
    });

    test('ohne Zuschlag bleibt sie draußen', () {
      // Die Gegenprobe: Der Fix darf nicht einfach jede Id durchlassen.
      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(
            const SaveData(
              grants: DebugGrants(bonusXp: 100000),
              abilities: ChosenAbilities.empty(),
            ).copyWith(
              abilities: const ChosenAbilities.empty().withAt(0, 'sandsturm'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(activeMovesProvider).map((m) => m.id),
        isNot(contains('sandsturm')),
      );
    });
  });
}
