import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:haustier/haustier.dart';
import 'package:lifes_game/dev/debug_grants.dart';
import 'package:lifes_game/gear/gear_controller.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/haustier/haustier_controller.dart';
import 'package:lifes_game/haustier/widgets/haustier_blatt.dart';
import 'package:lifes_game/haustier/widgets/haustier_karte.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// Das Haustier (Prototyp, 22.10.2026): Es wächst an Tagen mit Häkchen,
/// leidet nie, und sein Zubehör kostet echtes Gold.
void main() {
  const start = Day(2026, 10, 1);
  final vorlage = HabitCatalog.all.firstWhere(
    (h) => h.area == SkillArea.koerper && h.goal == null,
  );

  /// Eine Vorlage [tage] Tage am Stück abgehakt, ab [start].
  HabitTracker taeglich(int tage) {
    var t = const HabitTracker.empty().activate(vorlage.id, today: start);
    var tag = start;
    for (var i = 0; i < tage; i++) {
      t = t.check(vorlage.id, tag).tracker;
      tag = tag.next;
    }
    return t;
  }

  Day nach(int tage) {
    var tag = start;
    for (var i = 0; i < tage; i++) {
      tag = tag.next;
    }
    return tag;
  }

  ProviderContainer container(SaveData stand, {Day? heute, int stunde = 12}) {
    final c = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(stand),
        if (heute != null) todayProvider.overrideWithValue(heute),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 22, stunde)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('Wachsen', () {
    test('an Tagen mit Häkchen: nach drei schlüpft es', () {
      expect(
        container(SaveData(habits: taeglich(2))).read(haustierStufeProvider),
        HaustierStufe.ei,
      );
      expect(
        container(SaveData(habits: taeglich(3))).read(haustierStufeProvider),
        HaustierStufe.schluepfling,
      );
    });

    test('die Vorschau rechnet Tage dazu, ohne etwas zu speichern', () {
      final c = container(SaveData(habits: taeglich(3)));
      c.read(haustierVorschauProvider.notifier).plus(50);

      expect(c.read(haustierTageProvider), 53);
      expect(c.read(haustierStufeProvider), HaustierStufe.ausgewachsen);
      expect(c.read(savedGameProvider).haustier.isEmpty, isTrue);
    });

    test('ausgewachsen prägt es das stärkste Gebiet', () {
      final c = container(SaveData(habits: taeglich(60)));
      expect(c.read(haustierPraegungProvider), SkillArea.koerper);

      final jung = container(SaveData(habits: taeglich(20)));
      expect(jung.read(haustierPraegungProvider), isNull);
    });
  });

  group('Laune', () {
    test('ohne Häkchen wartet es, alles erledigt spielt es', () {
      final heute = nach(3);
      final ohne = container(SaveData(habits: taeglich(3)), heute: heute);
      expect(ohne.read(haustierLauneProvider), HaustierLaune.wartet);

      final mit = container(SaveData(habits: taeglich(4)), heute: heute);
      expect(mit.read(haustierLauneProvider), HaustierLaune.spielt);
    });

    test('nachts schläft es', () {
      final c = container(
        SaveData(habits: taeglich(3)),
        heute: nach(3),
        stunde: 23,
      );
      expect(c.read(haustierLauneProvider), HaustierLaune.schlaeft);
    });
  });

  group('Gold', () {
    final mitGold = const SaveData(
      grants: DebugGrants(bonusGold: 200),
      haustier: HaustierStand(art: HaustierArt.katze),
    );
    final hut = ZubehoerKatalog.byId('zauberhut')!;

    test('Zubehör kostet Gold — und der Laden sieht es', () {
      final c = container(mitGold);
      final vorher = c.read(goldProvider);

      final gekauft = c
          .read(haustierProvider.notifier)
          .kaufe(hut, verfuegbaresGold: c.read(goldProvider));

      expect(gekauft, isTrue);
      expect(c.read(goldProvider), vorher - hut.preis!);
    });

    test('was nicht bezahlbar ist, wird nicht gekauft', () {
      final c = container(
        const SaveData(haustier: HaustierStand(art: HaustierArt.katze)),
      );
      expect(
        c
            .read(haustierProvider.notifier)
            .kaufe(hut, verfuegbaresGold: c.read(goldProvider)),
        isFalse,
      );
      expect(c.read(haustierProvider).spentGold, 0);
    });

    test('Gold für das Tier fehlt danach im Laden der Ausrüstung', () {
      final c = container(mitGold);
      c
          .read(haustierProvider.notifier)
          .kaufe(hut, verfuegbaresGold: c.read(goldProvider));
      // Die Ausrüstung hat nichts ausgegeben; was fehlt, ist das Tier.
      expect(c.read(loadoutProvider).spentGold, 0);
      expect(c.read(goldProvider), 200 - hut.preis!);
    });
  });

  group('Speichern', () {
    test('das Tier übersteht Kodieren und Lesen — und copyWith', () {
      final stand = const HaustierStand(art: HaustierArt.eule)
          .benenne('Hedwig')
          .kaufe(ZubehoerKatalog.byId('ball')!, verfuegbaresGold: 99);
      final save = SaveData(haustier: stand);

      final gelesen = SaveData.decode(save.encode());
      expect(gelesen.haustier.anzeigeName, 'Hedwig');
      expect(gelesen.haustier.spentGold, 25);
      expect(save.copyWith(habits: taeglich(1)).haustier.name, 'Hedwig');
    });

    test('ein Stand ohne Tier schreibt keins', () {
      expect(const SaveData.empty().toJson().containsKey('haustier'), isFalse);
    });
  });

  group('Auf der Startseite', () {
    Future<ProviderContainer> zeige(WidgetTester tester, SaveData stand) async {
      useTallView(tester);
      final c = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(stand),
          ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();
      return c;
    }

    testWidgets('ohne Ei stehen drei zur Wahl; eins gewählt, steht es da', (
      tester,
    ) async {
      final c = await zeige(tester, SaveData(habits: taeglich(1)));

      for (final art in HaustierArt.values) {
        expect(find.byKey(HaustierKarte.eiKey(art)), findsOneWidget);
      }

      await tester.tap(find.byKey(HaustierKarte.eiKey(HaustierArt.drache)));
      await tester.pump();

      expect(c.read(haustierProvider).art, HaustierArt.drache);
      expect(find.byKey(HaustierKarte.tierKey), findsOneWidget);
      expect(find.text('Drache'), findsOneWidget);
    });

    testWidgets('ein Tipp öffnet das Blatt mit dem Zubehör', (tester) async {
      await zeige(
        tester,
        SaveData(
          habits: taeglich(1),
          haustier: const HaustierStand(art: HaustierArt.katze),
        ),
      );

      await tester.tap(find.byKey(HaustierKarte.tierKey));
      await tester.pumpAndSettle();

      expect(find.byType(HaustierBlatt), findsOneWidget);
      for (final z in ZubehoerKatalog.alle) {
        expect(find.byKey(HaustierBlatt.zubehoerKey(z.id)), findsOneWidget);
      }
    });
  });
}
