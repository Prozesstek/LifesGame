import 'package:flutter/gestures.dart';
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
import 'package:lifes_game/gear/widgets/character_figure.dart';
import 'package:lifes_game/gear/widgets/gear_sheet.dart';
import 'package:lifes_game/gear/widgets/rarity_badge.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/ui/palette.dart';
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

  /// Ein Platz über das, was er dem Vorleser sagt — „Waffe: leer“. Zu
  /// sehen ist dort kein Wort mehr, nur Umriss oder Bild.
  Finder aufDenPlaetzen(String text) => find.descendant(
    of: find.byType(EquipmentSlotTile),
    matching: find.bySemanticsLabel(RegExp(RegExp.escape(text))),
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

    testWidgets('die Figur steht zwischen den Plätzen und trägt die Waffe', (
      tester,
    ) async {
      // Seit dem 28.09. hier statt auf der Startseite: drei Plätze links,
      // drei rechts, die Figur dazwischen.
      useTallView(tester);
      await tester.pumpWidget(appMit(mitAllenWaffen()));

      final figur = find.byType(CharacterFigure);
      expect(figur, findsOneWidget);
      final mitte = tester.getCenter(figur).dx;
      expect(tester.getCenter(aufDenPlaetzen('Helm')).dx, lessThan(mitte));
      expect(tester.getCenter(aufDenPlaetzen('Waffe')).dx, greaterThan(mitte));

      final waffe = GearCatalog.forSlot(GearSlot.waffe).first.id;
      expect(tester.widget<CharacterFigure>(figur).worn, contains(waffe));
    });

    testWidgets('ein belegter Platz zeigt das Blatt mit den Werten', (
      tester,
    ) async {
      // **Der Wunsch:** Wer auf ein angelegtes Stück tippt, will wissen,
      // was es kann, nicht eine Liste zum Wechseln sehen.
      useTallView(tester);
      await tester.pumpWidget(appMit(mitAllenWaffen()));

      final angelegt = GearCatalog.forSlot(GearSlot.waffe).first;
      await tester.tap(aufDenPlaetzen('Waffe'));
      await tester.pumpAndSettle();

      expect(find.byType(GearSheet), findsOneWidget);
      expect(find.text(angelegt.why), findsOneWidget);
      expect(find.text('Angelegt'), findsOneWidget);
    });

    testWidgets('ein leerer Platz sagt, wie er sich füllt', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(aufDenPlaetzen('Waffe'));
      await tester.pumpAndSettle();

      expect(find.byType(GearSheet), findsNothing);
      expect(find.textContaining('noch nichts'), findsOneWidget);
    });

    testWidgets('Ablegen im Blatt räumt den Platz', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitAllenWaffen()));

      await tester.tap(aufDenPlaetzen('Waffe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ablegen'));
      await tester.pumpAndSettle();
      // Das Blatt schließen, dann steht der Platz wieder frei im Blick.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Leer, aber nicht „nichts gekauft“: Es liegt nur nichts drauf.
      expect(aufDenPlaetzen('leer'), findsOneWidget);
    });
  });

  group('Ziehen wie beim Deckbau', () {
    /// Hält [item] im Raster gedrückt und zieht es auf den Platz
    /// [ziel]. Gibt nichts zurück: Was passiert ist, prüft der Test am
    /// Spielstand.
    Future<void> ziehe(
      WidgetTester tester,
      GearItem item,
      GearSlot ziel,
    ) async {
      await tester.scrollUntilVisible(
        find.text(item.name).last,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(item.name).last),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      // Das Hochrollen läuft ab, erst danach stehen die Plätze fest.
      await tester.pumpAndSettle();

      final platz = tester.getCenter(aufDenPlaetzen(ziel.label));
      await gesture.moveTo(platz + const Offset(0, -20));
      await tester.pump();
      await gesture.moveTo(platz);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    ProviderContainer containerOf(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(EquipmentScreen)));

    testWidgets('halten, ziehen, loslassen legt das Stück an', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitAllenWaffen()));

      // Nicht das erste (das liegt schon), sondern eines weiter unten
      // im Alphabet, damit das Hochrollen wirklich etwas tut.
      final waffen = GearCatalog.forSlot(GearSlot.waffe).toList()
        ..sort((a, b) => sortKey(b.name).compareTo(sortKey(a.name)));
      final neu = waffen.first;
      expect(
        containerOf(tester).read(loadoutProvider).equippedIn(GearSlot.waffe),
        isNot(neu),
      );

      await ziehe(tester, neu, GearSlot.waffe);

      expect(
        containerOf(tester).read(loadoutProvider).equippedIn(GearSlot.waffe),
        neu,
      );
      expect(aufDenPlaetzen(neu.name), findsOneWidget);
    });

    testWidgets('auf den falschen Platz geht es nicht', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitAllenWaffen()));

      final vorher = containerOf(
        tester,
      ).read(loadoutProvider).equippedIn(GearSlot.waffe);
      final andere = GearCatalog.forSlot(
        GearSlot.waffe,
      ).firstWhere((i) => i != vorher);

      await ziehe(tester, andere, GearSlot.helm);

      final loadout = containerOf(tester).read(loadoutProvider);
      expect(loadout.equippedIn(GearSlot.waffe), vorher);
      expect(loadout.equippedIn(GearSlot.helm), isNull);
    });

    testWidgets('mehrfach besessen: das beste Exemplar kommt drauf', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitZweiExemplaren()));
      // Erst ablegen, damit das Ziehen etwas ändert.
      containerOf(
        tester,
      ).read(loadoutProvider.notifier).unequip(doppelt().slot);
      await tester.pumpAndSettle();

      await ziehe(tester, doppelt(), doppelt().slot);

      expect(
        containerOf(
          tester,
        ).read(loadoutProvider).equippedCopyIn(doppelt().slot)?.uid,
        'test-b',
      );
    });

    testWidgets('was man nicht hat, lässt sich nicht ziehen', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      final item = GearCatalog.forSlot(GearSlot.waffe).first;
      await ziehe(tester, item, GearSlot.waffe);

      expect(
        containerOf(tester).read(loadoutProvider).equippedIn(GearSlot.waffe),
        isNull,
      );
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
        find.bySemanticsLabel(
          '0 von ${GearCatalog.all.length} Stücken im Besitz',
        ),
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

      await tester.tap(find.byIcon(Icons.diamond_outlined));
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

      await tester.tap(find.byIcon(Icons.link_rounded));
      await tester.pumpAndSettle();

      expect(find.text(GearSets.all.first.name), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Ohne Set'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Ohne Set'), findsOneWidget);
    });

    /// Die Randfarbe der Kachel, in der [name] steht.
    Color randUm(WidgetTester tester, Finder name) {
      final kachel = tester.widget<Container>(
        find.ancestor(of: name, matching: find.byType(Container)).first,
      );
      return (kachel.decoration! as BoxDecoration).border!.top.color;
    }

    testWidgets('ein Stück im Besitz trägt Rahmen und Namen seiner Stufe', (
      tester,
    ) async {
      // **Der Wunsch** (Frederik, 01.10.): Man soll die Seltenheit sehen,
      // ohne das Blatt zu öffnen. Alle acht Waffen decken alle fünf
      // Stufen ab.
      useTallView(tester);
      await tester.pumpWidget(appMit(mitAllenWaffen()));

      final waffen = GearCatalog.forSlot(GearSlot.waffe);
      expect(waffen.map((w) => w.rarity).toSet(), GearRarity.values.toSet());
      for (final item in waffen) {
        // Die letzte Fundstelle ist die Kachel im Katalog, die erste
        // kann der Platz oben sein.
        final name = find.text(item.name).last;
        expect(
          tester.widget<Text>(name).style!.color,
          RarityBadge.colorOf(item.rarity),
          reason: item.name,
        );
        expect(
          randUm(tester, name),
          RarityBadge.rahmenOf(item.rarity),
          reason: item.name,
        );
      }
    });

    testWidgets('auch das angelegte behält den Rahmen seiner Stufe', (
      tester,
    ) async {
      // Bis zum 01.10. färbte „angelegt“ den Rand um, und das getragene
      // Stück war das einzige ohne Seltenheit. Dass es anliegt, sagt der
      // Haken.
      useTallView(tester);
      await tester.pumpWidget(appMit(mitAllenWaffen()));

      final getragen = GearCatalog.forSlot(GearSlot.waffe).first;
      final amPlatz = find.descendant(
        of: find.byType(EquipmentSlotTile),
        matching: find.text(getragen.name),
      );

      expect(
        tester.widget<Text>(amPlatz).style!.color,
        RarityBadge.colorOf(getragen.rarity),
      );
      expect(
        randUm(tester, find.text(getragen.name).last),
        RarityBadge.rahmenOf(getragen.rarity),
      );
    });

    testWidgets('was man nicht hat, bleibt grau', (tester) async {
      // Der Name leuchtet erst, wenn das Stück einem gehört — sonst
      // sähe der leere Katalog aus wie ein voller.
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      final fremd = GearCatalog.all.firstWhere(
        (i) => i.rarity == GearRarity.legendary,
      );
      await tester.scrollUntilVisible(
        find.text(fremd.name),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(
        tester.widget<Text>(find.text(fremd.name)).style!.color,
        Palette.muted,
      );
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

    testWidgets('ein Set-Teil zeigt sein Bild und sein Set', (tester) async {
      // **Wer wechselt, soll wissen, ob Ablegen ein Set kostet.** Das
      // stand bis zum 28.09. im Auswahlblatt am Platz, jetzt im Blatt.
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      final teil = GearCatalog.all.firstWhere(
        (i) => i.setId != null && GearIcons.forItemId(i.id) != null,
      );
      await oeffne(tester, teil);

      expect(
        find.descendant(
          of: find.byType(GearSheet),
          matching: find.byType(PixelArt),
        ),
        findsOneWidget,
      );
      expect(find.text('„${GearSets.byId(teil.setId)!.name}"'), findsOneWidget);
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
