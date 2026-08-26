import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/dev/dev_controller.dart';
import 'package:lifes_game/dev/dev_screen.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:lifes_game/ui/phone_frame.dart';

/// Prüft den Entwicklermodus-Bildschirm über den **ganzen Weg**: Knopf
/// drücken, bestätigen, Wirkung nachsehen.
///
/// **Warum das nötig war.** `dev_mode_test.dart` prüft die Zuschläge und
/// `DevActions` einzeln — beides war grün, während „Alles freischalten"
/// im Browser mit einer Riverpod-Ausnahme abbrach:
///
///     setState() or markNeedsBuild() called during build
///
/// Der Grund lag zwischen den geprüften Teilen: `showDialog` kehrt zurück,
/// während der Dialog noch abgebaut wird, und rund 25 Zustandsänderungen
/// fielen mitten in den Bildaufbau. Ein Test, der nur die Aktion aufruft,
/// kann das nicht sehen — er braucht den Dialog und einen echten
/// Widget-Baum.
///
/// Der Rahmen aus [PhoneFrame] ist deshalb ausdrücklich dabei: Sein
/// `LayoutBuilder` steht im Stack des Fehlers.
void main() {
  Widget appMitRahmen() {
    return ProviderScope(
      overrides: [savedGameProvider.overrideWithValue(const SaveData.empty())],
      child: const PhoneFrame(
        enabled: true,
        child: MaterialApp(home: DevScreen()),
      ),
    );
  }

  /// Scrollt zu einem Knopf und drückt ihn.
  ///
  /// Die großen Knöpfe stehen ganz unten — auf 844 Pixeln Höhe sind sie
  /// nicht gebaut, solange niemand hinscrollt (`test/test_view.dart`).
  Future<void> tippe(WidgetTester tester, String knopf) async {
    await tester.dragUntilVisible(
      find.text(knopf),
      find.byType(ListView),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(knopf));
  }

  /// Drückt einen Knopf und bestätigt den Rückfragedialog.
  Future<void> bestaetige(WidgetTester tester, String knopf) async {
    await tippe(tester, knopf);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ja'));
    await tester.pumpAndSettle();

    // Der Nachlauf: Die Wirkung tritt einen Bildaufbau später ein.
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('„Alles freischalten" läuft ohne Ausnahme durch', (tester) async {
    useDesktopView(tester);
    await tester.pumpWidget(appMitRahmen());
    await tester.pumpAndSettle();

    await bestaetige(tester, 'Alles freischalten');

    expect(tester.takeException(), isNull);
  });

  testWidgets('und es schaltet tatsächlich alles frei', (tester) async {
    useDesktopView(tester);
    await tester.pumpWidget(appMitRahmen());
    await tester.pumpAndSettle();

    final scope = ProviderScope.containerOf(
      tester.element(find.byType(DevScreen)),
    );

    expect(scope.read(passedPagesProvider), 0);

    await bestaetige(tester, 'Alles freischalten');

    expect(scope.read(passedPagesProvider), scope.read(totalPagesProvider));
    expect(scope.read(grantedAbilityIdsProvider), isNotEmpty);
    expect(scope.read(playerLevelProvider).level, greaterThan(1));
  });

  testWidgets('„Zuschläge zurücksetzen" läuft ebenfalls durch', (tester) async {
    useDesktopView(tester);
    await tester.pumpWidget(appMitRahmen());
    await tester.pumpAndSettle();

    await bestaetige(tester, 'Alles freischalten');
    await bestaetige(tester, 'Nur Zuschläge zurücksetzen');

    expect(tester.takeException(), isNull);

    final scope = ProviderScope.containerOf(
      tester.element(find.byType(DevScreen)),
    );
    expect(scope.read(devGrantsProvider).isEmpty, isTrue);
  });

  testWidgets('Abbrechen ändert nichts', (tester) async {
    useDesktopView(tester);
    await tester.pumpWidget(appMitRahmen());
    await tester.pumpAndSettle();

    await tippe(tester, 'Alles freischalten');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    await tester.pump();

    final scope = ProviderScope.containerOf(
      tester.element(find.byType(DevScreen)),
    );

    expect(scope.read(passedPagesProvider), 0);
    expect(tester.takeException(), isNull);
  });
}

/// Ein Fenster, in das der Handy-Rahmen passt.
void useDesktopView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 1100);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}
