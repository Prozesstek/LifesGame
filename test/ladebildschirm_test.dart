import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/gear/widgets/character_figure.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/ui/holz.dart';
import 'package:lifes_game/ui/ladebildschirm.dart';
import 'package:lifes_game/ui/spaeter_laden.dart';

/// Der Ladebildschirm (Issue #135): beim Start der Web-Fassung in
/// `web/index.html`, im Spiel vor dem Dungeon über `oeffneGeladen`.
void main() {
  Widget app(Widget home) => ProviderScope(
    overrides: [savedGameProvider.overrideWithValue(const SaveData.empty())],
    child: MaterialApp(home: home),
  );

  test('die Tipps der Web-Seite sind dieselben wie im Spiel', () {
    final seite = File('web/index.html').readAsStringSync();
    for (final tipp in LadeTipps.alle) {
      expect(seite, contains('"$tipp"'), reason: tipp);
    }
    final zeilen = RegExp(
      r'^\s+"[^"]+",?$',
      multiLine: true,
    ).allMatches(seite.split('var tipps = [').last.split('];').first);
    expect(zeilen.length, LadeTipps.alle.length);
  });

  test('die Web-Seite ist nie weiß', () {
    final seite = File('web/index.html').readAsStringSync();
    expect(seite, contains('background: #17110A'));
  });

  testWidgets('zeigt die Figur, den Balken und den Tipp', (tester) async {
    final stand = ValueNotifier<double>(0.4);
    addTearDown(stand.dispose);
    await tester.pumpWidget(
      app(Ladebildschirm(stand: stand, tipp: LadeTipps.alle.first)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CharacterFigure), findsOneWidget);
    expect(find.text(LadeTipps.alle.first), findsOneWidget);
    expect(
      tester.widget<HolzBalken>(find.byType(HolzBalken)).value,
      closeTo(0.4, 0.001),
    );

    stand.value = 0.9;
    await tester.pumpAndSettle();
    expect(
      tester.widget<HolzBalken>(find.byType(HolzBalken)).value,
      closeTo(0.9, 0.001),
    );
  });

  group('oeffneGeladen', () {
    setUp(() => SpaeterLaden.vorbereiten = true);
    tearDown(() => SpaeterLaden.vorbereiten = false);

    Future<void> tippe(
      WidgetTester tester, {
      required Future<void> Function() vorbereiten,
      ValueListenable<double>? fortschritt,
    }) async {
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => oeffneGeladen<void>(
                context,
                laden: () async {},
                vorbereiten: vorbereiten,
                fortschritt: fortschritt == null ? null : () => fortschritt,
                bauen: () => const Scaffold(body: Text('Dungeon')),
              ),
              child: const Text('Hinab'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Hinab'));
    }

    testWidgets('was schnell geladen ist, öffnet ohne Ladebildschirm', (
      tester,
    ) async {
      await tippe(tester, vorbereiten: () async {});
      await tester.pumpAndSettle();

      expect(find.text('Dungeon'), findsOneWidget);
      expect(find.byType(Ladebildschirm), findsNothing);
    });

    testWidgets('wartet auf die Bilder und zeigt solange den Bildschirm', (
      tester,
    ) async {
      final bilder = Completer<void>();
      final fortschritt = ValueNotifier<double>(0);
      addTearDown(fortschritt.dispose);
      await tippe(
        tester,
        vorbereiten: () => bilder.future,
        fortschritt: fortschritt,
      );
      await tester.pump();
      await tester.pump(SpaeterLaden.ladebildschirmAb);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(Ladebildschirm), findsOneWidget);
      expect(find.text('Dungeon'), findsNothing);

      // Die Hälfte der Bilder: der Balken steht zwischen Laden und Ende.
      fortschritt.value = 0.5;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.widget<HolzBalken>(find.byType(HolzBalken)).value,
        closeTo(0.3 + 0.7 * 0.5, 0.001),
      );

      bilder.complete();
      await tester.pump();
      await tester.pump(SpaeterLaden.mindestens);
      await tester.pumpAndSettle();

      expect(find.text('Dungeon'), findsOneWidget);
      expect(find.byType(Ladebildschirm), findsNothing);

      // Zurück führt zum Eingang, nicht auf den Ladebildschirm.
      Navigator.of(tester.element(find.text('Dungeon'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Hinab'), findsOneWidget);
    });

    testWidgets('scheitern die Bilder, beginnt der Lauf trotzdem', (
      tester,
    ) async {
      await tippe(
        tester,
        vorbereiten: () => Future<void>.delayed(
          const Duration(seconds: 1),
          () => throw FlutterError('Bild fehlt'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(SpaeterLaden.mindestens);
      await tester.pumpAndSettle();

      expect(find.text('Dungeon'), findsOneWidget);
    });
  });
}
