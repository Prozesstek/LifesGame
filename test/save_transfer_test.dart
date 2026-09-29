import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/main.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/save/save_store.dart';
import 'package:lifes_game/save/widgets/save_transfer_card.dart';

import 'test_view.dart';

/// Den Spielstand sichern und zurückholen (ADR-0054).
///
/// Die schärfste Zusage steht in der ersten Gruppe: Ein **falsch
/// kopierter** Text darf nie zu einem leeren Stand werden, der den echten
/// ersetzt. Beim Start ist Nachsicht richtig, beim Einfügen nicht.
void main() {
  const heute = Day(2026, 9, 27);
  final vorlage = HabitCatalog.starter;

  SaveData mitHaekchen(int tage) {
    var t = const HabitTracker.empty().activate(vorlage.id);
    var tag = heute;
    for (var i = 0; i < tage; i++) {
      t = t.check(vorlage.id, tag).tracker;
      tag = tag.previous;
    }
    return SaveData(habits: t);
  }

  group('Einlesen ist streng', () {
    test('ein kopierter Stand kommt unverändert zurück', () {
      final stand = mitHaekchen(3);

      final gelesen = SaveData.tryImport(stand.encode());

      expect(gelesen, isNotNull);
      expect(gelesen!.encode(), stand.encode());
    });

    test('Leerraum drumherum stört nicht', () {
      expect(
        SaveData.tryImport('  \n${mitHaekchen(1).encode()}\n '),
        isNotNull,
      );
    });

    for (final (name, text) in <(String, String)>[
      ('leer', ''),
      ('kein JSON', 'hallo'),
      ('abgeschnitten', mitHaekchen(2).encode().substring(0, 40)),
      ('eine Liste', '[1, 2, 3]'),
      ('ohne Version', '{"habits": {}}'),
      ('aus einer neueren App', '{"version": ${SaveData.schemaVersion + 1}}'),
    ]) {
      test('$name wird abgelehnt', () {
        expect(SaveData.tryImport(text), isNull);
      });
    }
  });

  group('Kopieren und Einfügen', () {
    late String? zwischenablage;

    setUp(() {
      zwischenablage = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              zwischenablage =
                  (call.arguments as Map<Object?, Object?>)['text'] as String?;
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Future<List<SaveData>> karte(WidgetTester tester, SaveData stand) async {
      useTallView(tester);
      final eingefuegt = <SaveData>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedGameProvider.overrideWithValue(stand),
            todayProvider.overrideWithValue(heute),
            saveImporterProvider.overrideWithValue(
              (SaveData neu) async => eingefuegt.add(neu),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: SaveTransferCard())),
        ),
      );
      return eingefuegt;
    }

    testWidgets('Kopieren legt den jetzigen Stand ab', (tester) async {
      final stand = mitHaekchen(2);
      await karte(tester, stand);

      await tester.tap(find.bySemanticsLabel('Kopieren'));
      await tester.pump();

      expect(zwischenablage, stand.encode());
    });

    testWidgets('Einfügen fragt nach und ersetzt dann', (tester) async {
      final alt = mitHaekchen(1);
      final neu = mitHaekchen(5);
      final eingefuegt = await karte(tester, alt);

      await tester.tap(find.bySemanticsLabel('Einfügen'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), neu.encode());
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();

      expect(find.text('Stand ersetzen?'), findsOneWidget);
      expect(find.textContaining('5 Häkchen'), findsOneWidget);

      await tester.tap(find.text('Ersetzen'));
      await tester.pumpAndSettle();

      expect(eingefuegt.single.encode(), neu.encode());
      expect(
        zwischenablage,
        alt.encode(),
        reason: 'der alte Stand liegt danach in der Zwischenablage',
      );
    });

    testWidgets('Unsinn wird abgewiesen und ersetzt nichts', (tester) async {
      final eingefuegt = await karte(tester, mitHaekchen(1));

      await tester.tap(find.bySemanticsLabel('Einfügen'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'nicht mein Stand');
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();

      expect(
        find.text('Das ist kein Spielstand aus Lifes Game.'),
        findsOneWidget,
      );
      expect(eingefuegt, isEmpty);
    });

    testWidgets('Abbrechen beim Nachfragen ersetzt nichts', (tester) async {
      final eingefuegt = await karte(tester, mitHaekchen(1));

      await tester.tap(find.bySemanticsLabel('Einfügen'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), mitHaekchen(4).encode());
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(eingefuegt, isEmpty);
    });
  });

  testWidgets('Einfügen startet die App mit dem neuen Stand', (tester) async {
    // Der ganze Weg in `main.dart`: Der Stand wird geschrieben, und jeder
    // Controller baut sich aus ihm neu. Ohne den Neustart schriebe die
    // laufende App ihren alten Stand beim nächsten Häkchen darüber.
    useTallView(tester);
    final store = InMemorySaveStore();
    await tester.pumpWidget(
      SpielstandHost(store: store, saved: const SaveData.empty()),
    );
    await tester.pump();

    ProviderContainer container() =>
        ProviderScope.containerOf(tester.element(find.byType(LifesGameApp)));

    expect(container().read(habitTrackerProvider).activeIds, isEmpty);

    final neu = mitHaekchen(3);
    await container().read(saveImporterProvider)(neu);
    await tester.pump();

    expect(container().read(habitTrackerProvider).checksFor(vorlage.id), 3);
    expect((await store.read()).encode(), neu.encode());
  });
}
