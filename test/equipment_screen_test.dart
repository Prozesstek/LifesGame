import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/character/widgets/equipment_slot_tile.dart';
import 'package:lifes_game/gear/equipment_screen.dart';
import 'package:lifes_game/gear/gear_controller.dart';
import 'package:lifes_game/gear/gear_grouping.dart';
import 'package:lifes_game/gear/gear_icon.dart';
import 'package:lifes_game/gear/widgets/gear_sheet.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/ui/pixel_art.dart';

import 'gear_helpers.dart';
import 'test_view.dart';

/// Der Ausrüstungs-Bildschirm (ADR-0057).
///
/// **Die Plätze standen bis zum 28.09. im Charakter**, und die Tests dazu
/// in `character_test.dart`. Sie sind hierher gewandert und um das
/// erweitert, was es dort nicht gab: den ganzen Katalog, die Ordnungen
/// und das Blatt mit den Exemplaren.
void main() {
  const tag = Day(2026, 9, 28);

  Widget appMit(SaveData saved) {
    return ProviderScope(
      overrides: [
        savedGameProvider.overrideWithValue(saved),
        todayProvider.overrideWithValue(tag),
      ],
      child: const MaterialApp(home: EquipmentScreen()),
    );
  }

  /// Alle Waffen gekauft, damit es auf einem Platz wirklich etwas zu
  /// wählen gibt. Gekauft wird angelegt, das erste Stück liegt also drauf.
  SaveData mitAllenWaffen() {
    var loadout = const Loadout.empty();
    for (final item in GearCatalog.forSlot(GearSlot.waffe)) {
      // **Mit der höchsten Sprosse.** Ohne sie greift seit ADR-0034 die
      // Sperre, und die verdienten Waffen fehlen still.
      loadout = loadout.buy(
        angebot(item.id),
        availableGold: item.price,
        highestRung: GearGates.legendaryRung,
      );
    }
    return SaveData(loadout: loadout);
  }

  /// Ein Stück zweimal, mit verschiedenen Würfen.
  GearItem doppelt() => GearCatalog.forSlot(GearSlot.helm).first;

  SaveData mitZweiExemplaren() {
    final item = doppelt();
    final grund = item.bonus.scaled;
    GearCopy exemplar(String uid, int plus) => GearCopy(
      uid: uid,
      itemId: item.id,
      bonus: GearBonus(
        attack: grund.attack,
        maxHp: grund.maxHp,
        defense: grund.defense + plus,
        maxEnergy: grund.maxEnergy,
      ),
      paid: 0,
    );
    final loadout = const Loadout.empty()
        .addFree(exemplar('test-a', 0))
        .addFree(exemplar('test-b', 2));
    return SaveData(loadout: loadout);
  }

  /// Nur die Schrift auf den sechs Plätzen, nicht die im Raster darunter.
  Finder aufDenPlaetzen(String text) => find.descendant(
    of: find.byType(EquipmentSlotTile),
    matching: find.text(text),
  );

  Future<void> oeffne(WidgetTester tester, GearItem item) async {
    await tester.scrollUntilVisible(
      find.text(item.name).last,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(item.name).last);
    await tester.pumpAndSettle();
  }

  group('Die sechs Plätze', () {
    testWidgets('alle sechs sind sichtbar, auch die leeren', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      for (final slot in GearSlot.values) {
        expect(aufDenPlaetzen(slot.label), findsOneWidget);
      }
      // Ohne Gekauftes sagt jede Kachel, warum sie leer ist.
      expect(
        aufDenPlaetzen('nichts gekauft'),
        findsNWidgets(GearSlot.values.length),
      );
    });

    testWidgets('ein leerer Platz ohne Auswahl lässt sich nicht antippen', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(aufDenPlaetzen('Waffe'));
      await tester.pumpAndSettle();

      // Kein Auswahlblatt: Ein Blatt ohne Einträge wäre eine Sackgasse.
      expect(find.text('Ablegen'), findsNothing);
    });

    testWidgets('antippen öffnet die Auswahl und wechselt das Stück', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitAllenWaffen()));

      await tester.tap(aufDenPlaetzen('Waffe'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Übungsklinge').last);
      await tester.pumpAndSettle();

      expect(aufDenPlaetzen('Übungsklinge'), findsOneWidget);
    });

    testWidgets('das Auswahlblatt zeigt Bild und Set jedes Stücks', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitAllenWaffen()));

      await tester.tap(aufDenPlaetzen('Waffe'));
      await tester.pumpAndSettle();

      final mitBild = GearCatalog.forSlot(
        GearSlot.waffe,
      ).where((i) => GearIcons.forItemId(i.id) != null);
      expect(mitBild, isNotEmpty, reason: 'Der Test braucht ein Bild');
      expect(find.byType(PixelArt), findsAtLeastNWidgets(mitBild.length));

      for (final item in GearCatalog.forSlot(GearSlot.waffe)) {
        final set = GearSets.byId(item.setId);
        if (set == null) continue;
        expect(find.text('Teil von „${set.name}"'), findsWidgets);
      }
      // Ein Stück ohne Set bekommt keine leere Set-Zeile.
      expect(find.text('Teil von „"'), findsNothing);
    });

    testWidgets('Ablegen räumt den Platz', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitAllenWaffen()));

      await tester.tap(aufDenPlaetzen('Waffe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ablegen'));
      await tester.pumpAndSettle();

      // Leer, aber nicht „nichts gekauft": Es liegt nur nichts drauf.
      expect(aufDenPlaetzen('leer'), findsOneWidget);
    });
  });

  group('Der Katalog darunter', () {
    testWidgets('jedes Stück steht da, auch was man nicht hat', (tester) async {
      // **Das ist der Grund für den Bildschirm.** Im Laden sieht man
      // sechs Angebote am Tag, im Charakter sechs Plätze. Die übrigen
      // Stücke standen nirgends.
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      expect(
        find.textContaining('0 von ${GearCatalog.all.length} im Besitz'),
        findsOneWidget,
      );
      for (final item in GearCatalog.all) {
        await tester.scrollUntilVisible(
          find.text(item.name),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(item.name), findsOneWidget, reason: item.name);
      }
    });

    testWidgets('nach Seltenheit stehen die Stufen als Marken da', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      // Im alphabetischen Raster gibt es keine Überschriften.
      expect(find.text(GearRarity.legendary.label), findsNothing);

      await tester.tap(find.text(GearGrouping.seltenheit.label));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text(GearRarity.legendary.label),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(GearRarity.legendary.label), findsOneWidget);
    });

    testWidgets('nach Set steht auch, was zu keinem gehört', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(find.text(GearGrouping.set.label));
      await tester.pumpAndSettle();

      expect(find.text(GearSets.all.first.name), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Ohne Set'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Ohne Set'), findsOneWidget);
    });

    testWidgets('mehrere Exemplare stehen als Zahl auf der Kachel', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitZweiExemplaren()));

      await tester.scrollUntilVisible(
        find.text('×2'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('×2'), findsOneWidget);
    });
  });

  group('Das Blatt', () {
    testWidgets('ein fremdes Stück nennt Werte, Preis und Herkunft', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      final item = GearCatalog.all.firstWhere(
        (i) => i.rarity == GearRarity.common,
      );
      await oeffne(tester, item);

      expect(find.byType(GearSheet), findsOneWidget);
      expect(find.text(item.why), findsOneWidget);
      expect(find.text('${item.price} Gold'), findsOneWidget);
      expect(find.text('Wurf'), findsOneWidget);
      expect(find.textContaining('Noch nicht im Besitz'), findsOneWidget);
      // Nichts zum Anlegen, man hat es ja nicht.
      expect(find.text('Anlegen'), findsNothing);
    });

    testWidgets('ein legendäres nennt die Stufe, ab der es geht', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      final legendaer = GearCatalog.all.firstWhere(
        (i) => i.rarity == GearRarity.legendary,
      );
      await oeffne(tester, legendaer);

      expect(
        find.textContaining('Verdient ab Stufe ${GearGates.legendaryRung}'),
        findsOneWidget,
      );
    });

    testWidgets('jedes Exemplar steht einzeln da und lässt sich anlegen', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitZweiExemplaren()));

      await oeffne(tester, doppelt());

      expect(find.text('Deine 2 Exemplare'), findsOneWidget);
      // Das erste liegt schon (gekauft wird angelegt), das zweite nicht.
      expect(find.text('Angelegt'), findsOneWidget);
      expect(find.text('Anlegen'), findsOneWidget);

      await tester.tap(find.text('Anlegen'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(EquipmentScreen)),
      );
      expect(
        container.read(loadoutProvider).equippedCopyIn(doppelt().slot)?.uid,
        'test-b',
      );
    });

    testWidgets('verkaufen fragt nach und nimmt das Exemplar weg', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitZweiExemplaren()));

      await oeffne(tester, doppelt());
      await tester.tap(find.widgetWithText(TextButton, 'Verkaufen').last);
      await tester.pumpAndSettle();

      // Die Rückfrage steht, noch ist nichts weg.
      expect(find.text('${doppelt().name} verkaufen?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Verkaufen'));
      await tester.pump();
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(EquipmentScreen)),
      );
      final uebrig = container
          .read(loadoutProvider)
          .ownedCopies
          .where((c) => c.itemId == doppelt().id);
      expect(uebrig, hasLength(1));
    });
  });

  group('Die Ordnungen', () {
    test('keine verliert ein Stück, keine zählt eines doppelt', () {
      for (final grouping in GearGrouping.values) {
        final ids = <String>[
          for (final gruppe in groupGear(grouping))
            for (final item in gruppe.items) item.id,
        ];
        expect(ids, hasLength(GearCatalog.all.length), reason: grouping.name);
        expect(ids.toSet(), hasLength(GearCatalog.all.length));
      }
    });

    test('alphabetisch heißt nach deutschem Alphabet', () {
      // **„Übungsklinge" gehört unter U**, nicht hinter „Zweihänder".
      // Dart vergleicht nach Zeichencode, und dort liegt „Ü" hinter „Z".
      final namen = <String>[
        for (final item in groupGear(GearGrouping.alphabetisch).single.items)
          item.name,
      ];
      expect(namen.last, isNot('Übungsklinge'));
      final sortiert = [...namen]
        ..sort((a, b) => sortKey(a).compareTo(sortKey(b)));
      expect(namen, sortiert);
      expect(sortKey('Übungsklinge').compareTo(sortKey('Zweihänder')), -1);
    });

    test('nur die Ordnung nach Seltenheit trägt Marken', () {
      for (final grouping in GearGrouping.values) {
        final mitMarke = groupGear(grouping).where((g) => g.rarity != null);
        expect(
          mitMarke.isNotEmpty,
          grouping == GearGrouping.seltenheit,
          reason: grouping.name,
        );
      }
    });
  });
}
