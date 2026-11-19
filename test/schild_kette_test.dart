import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/ui/schild_kette.dart';

/// Zwei Ketten zwischen gekoppelten Gewohnheiten (19.11.2026): von Öse
/// zu Öse, ohne Versatz, auf jedem Bildschirm und jeder Breite.
void main() {
  const heute = Day(2026, 8, 21);
  final ids = HabitCatalog.all.map((t) => t.id).toList();

  /// A → B → C offen, D allein.
  HabitTracker stand() {
    var t = const HabitTracker.empty();
    for (final id in ids.take(4)) {
      t = t.activate(id, today: heute);
    }
    return t.setAnchor(ids[1], ids[0]).setAnchor(ids[2], ids[1]);
  }

  Future<void> zeige(
    WidgetTester tester,
    Widget screen,
    Size size, [
    HabitTracker? tracker,
  ]) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedGameProvider.overrideWithValue(
            SaveData(habits: tracker ?? stand()),
          ),
          todayProvider.overrideWithValue(heute),
          ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
        ],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder alle(Key key) => find.byKey(key);

  /// Jede Kette endet oben in der Mitte einer unteren Öse und unten in der
  /// Mitte einer oberen Öse, und steht mittig darüber.
  void ohneVersatz(WidgetTester tester) {
    for (final seite in <int>[0, 1]) {
      final ketten = alle(SchildKette.ketteKey(seite)).evaluate().toList();
      final oben = alle(SchildKette.oeseObenKey(seite)).evaluate().toList();
      final unten = alle(SchildKette.oeseUntenKey(seite)).evaluate().toList();
      expect(ketten, hasLength(2), reason: 'A→B und B→C');
      expect(oben, hasLength(2));
      expect(unten, hasLength(2));
      for (var i = 0; i < 2; i++) {
        final k = tester.getRect(find.byWidget(ketten[i].widget));
        final o = tester.getRect(find.byWidget(oben[i].widget));
        final u = tester.getRect(find.byWidget(unten[i].widget));
        expect(k.center.dx, closeTo(o.center.dx, 0.01));
        expect(k.center.dx, closeTo(u.center.dx, 0.01));
        expect(k.top, closeTo(u.center.dy, 0.01));
        expect(k.bottom, closeTo(o.center.dy, 0.01));
      }
    }
  }

  for (final size in <Size>[
    const Size(360, 900),
    const Size(390, 900),
    const Size(700, 1000),
  ]) {
    testWidgets('Gewohnheiten, $size: Kette von Öse zu Öse', (tester) async {
      await zeige(tester, const HabitsScreen(), size);
      ohneVersatz(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Startseite, $size: Kette von Öse zu Öse', (tester) async {
      await zeige(tester, const HomeScreen(), size);
      ohneVersatz(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('die Ketten hängen 15 % vom Rand', (tester) async {
    await zeige(tester, const HabitsScreen(), const Size(390, 900));
    final karte = tester.getRect(
      find.ancestor(
        of: find.byKey(SchildKette.ketteKey(0)).first,
        matching: find.byType(SchildKette),
      ),
    );
    final links = tester.getRect(find.byKey(SchildKette.ketteKey(0)).first);
    final rechts = tester.getRect(find.byKey(SchildKette.ketteKey(1)).first);
    expect(links.center.dx - karte.left, closeTo(karte.width * 0.15, 0.5));
    expect(karte.right - rechts.center.dx, closeTo(karte.width * 0.15, 0.5));
  });

  testWidgets('ohne Kopplung keine Ösen und keine Ketten', (tester) async {
    var t = const HabitTracker.empty();
    for (final id in ids.take(3)) {
      t = t.activate(id, today: heute);
    }
    await zeige(tester, const HabitsScreen(), const Size(390, 900), t);
    expect(alle(SchildKette.ketteKey(0)), findsNothing);
    expect(alle(SchildKette.oeseObenKey(0)), findsNothing);
    expect(alle(SchildKette.oeseUntenKey(0)), findsNothing);
  });

  testWidgets('gekoppelte stehen näher beieinander als ungekoppelte', (
    tester,
  ) async {
    await zeige(tester, const HabitsScreen(), const Size(390, 900));
    final ketten = find.byType(SchildKette);
    final a = tester.getRect(ketten.at(0));
    final b = tester.getRect(ketten.at(1));
    final c = tester.getRect(ketten.at(2));
    final d = tester.getRect(ketten.at(3));
    expect(b.top - a.bottom, lessThan(d.top - c.bottom));
  });

  testWidgets('wird die Kopplung gelöst, verschwinden Ketten und Ösen', (
    tester,
  ) async {
    await zeige(tester, const HabitsScreen(), const Size(390, 900));
    expect(alle(SchildKette.ketteKey(0)), findsNWidgets(2));

    final c = ProviderScope.containerOf(
      tester.element(find.byType(HabitsScreen)),
    );
    c.read(habitTrackerProvider.notifier).setAnchor(ids[2], null);
    await tester.pumpAndSettle();

    expect(alle(SchildKette.ketteKey(0)), findsOneWidget);
    expect(alle(SchildKette.oeseUntenKey(0)), findsOneWidget);
  });

  testWidgets('erledigt wird die Kette blasser', (tester) async {
    final t = stand()
        .check(ids[0], heute)
        .tracker
        .check(ids[1], heute)
        .tracker
        .check(ids[2], heute)
        .tracker;
    await zeige(tester, const HabitsScreen(), const Size(390, 900), t);
    final blass = tester.widgetList<Opacity>(
      find.descendant(
        of: find.byKey(SchildKette.ketteKey(0)).first,
        matching: find.byType(Opacity),
      ),
    );
    expect(blass.first.opacity, lessThan(1));
  });
}
