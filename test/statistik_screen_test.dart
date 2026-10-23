import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/statistik/jahresrueckblick_screen.dart';
import 'package:lifes_game/statistik/statistik_screen.dart';
import 'package:lifes_game/statistik/widgets/kalender_raster.dart';
import 'package:lifes_game/statistik/widgets/statistik_karten.dart';

import 'test_view.dart';

/// Die Statistik (ADR-0087) in der App: Zeiträume, Blättern, das Raster,
/// je Gewohnheit, der Jahresrückblick — und dass alles aufs Handy passt.
void main() {
  // Mittwoch, 21.10.2026.
  const heute = Day(2026, 10, 21);
  final a = HabitCatalog.all[0];
  final b = HabitCatalog.all[1];

  /// Zwei Gewohnheiten seit dem 01.09.: a jeden Tag, b jeden zweiten.
  HabitTracker stand() {
    const anfang = Day(2026, 9, 1);
    var t = const HabitTracker.empty()
        .activate(a.id, today: anfang)
        .activate(b.id, today: anfang);
    for (var d = anfang; d <= heute; d = d.next) {
      t = t.check(a.id, d).tracker;
      if (anfang.daysUntil(d).isEven) t = t.check(b.id, d).tracker;
    }
    return t;
  }

  Future<ProviderContainer> zeige(
    WidgetTester tester, {
    Widget screen = const StatistikScreen(),
    Day tag = heute,
    HabitTracker? tracker,
  }) async {
    usePhoneView(tester);
    final c = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(
          SaveData(habits: tracker ?? stand()),
        ),
        clockProvider.overrideWithValue(
          () => DateTime(tag.year, tag.month, tag.day, 12),
        ),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  String titel(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(StatistikScreen.titelKey)).data!;

  testWidgets('öffnet bei dieser Woche, mit Quote und Vergleich', (
    tester,
  ) async {
    await zeige(tester);

    expect(titel(tester), '19.10. – 25.10.');
    // Mo bis Mi: a dreimal, b zweimal von drei — fünf von sechs.
    expect(tester.widget<Text>(find.byKey(QuoteKarte.quoteKey)).data, '83 %');
    expect(find.byKey(QuoteKarte.vergleichKey), findsOneWidget);
  });

  testWidgets('jeder Zeitraum passt aufs Handy und blättert', (tester) async {
    await zeige(tester);

    for (final (zeitraum, erwartet) in <(StatZeitraum, String)>[
      (StatZeitraum.monat, 'Oktober 2026'),
      (StatZeitraum.jahr, '2026'),
      (StatZeitraum.gesamt, 'seit Sep 2026'),
      (StatZeitraum.woche, '19.10. – 25.10.'),
    ]) {
      await tester.tap(find.byKey(StatistikScreen.zeitraumKey(zeitraum)));
      await tester.pumpAndSettle();
      expect(titel(tester), erwartet);
      expect(tester.takeException(), isNull, reason: zeitraum.name);
    }

    await tester.tap(find.byKey(StatistikScreen.davorKey));
    await tester.pumpAndSettle();
    expect(titel(tester), '12.10. – 18.10.');

    await tester.tap(find.byKey(StatistikScreen.danachKey));
    await tester.pumpAndSettle();
    expect(titel(tester), '19.10. – 25.10.');
  });

  testWidgets('über heute hinaus und vor den Anfang blättert nichts', (
    tester,
  ) async {
    await zeige(tester);
    await tester.tap(
      find.byKey(StatistikScreen.zeitraumKey(StatZeitraum.monat)),
    );
    await tester.pumpAndSettle();

    final danach = tester.widget<IconButton>(
      find.byKey(StatistikScreen.danachKey),
    );
    expect(danach.onPressed, isNull);

    await tester.tap(find.byKey(StatistikScreen.davorKey));
    await tester.pumpAndSettle();
    expect(titel(tester), 'September 2026');
    final davor = tester.widget<IconButton>(
      find.byKey(StatistikScreen.davorKey),
    );
    expect(davor.onPressed, isNull, reason: 'vor September gab es nichts');
  });

  testWidgets('ein Tipp auf einen Tag zeigt, was er war', (tester) async {
    await zeige(tester);

    await tester.tap(
      find.byKey(KalenderRaster.zelleKey(const Day(2026, 10, 20))),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(TagZeile.zeileKey), findsOneWidget);
    expect(find.text('Di 20.10.'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
  });

  testWidgets('ein Ring öffnet die Statistik seiner Gewohnheit', (
    tester,
  ) async {
    await zeige(tester);

    final ring = find.byKey(GewohnheitRing.keyFuer(a.id));
    await tester.ensureVisible(ring);
    await tester.pumpAndSettle();
    await tester.tap(ring);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, a.name), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(QuoteKarte.quoteKey)).data, '100 %');
    expect(find.byKey(GewohnheitRing.keyFuer(b.id)), findsNothing);
  });

  testWidgets('das Jahr führt in den Jahresrückblick', (tester) async {
    await zeige(tester);
    await tester.tap(
      find.byKey(StatistikScreen.zeitraumKey(StatZeitraum.jahr)),
    );
    await tester.pumpAndSettle();

    final knopf = find.byKey(StatistikScreen.rueckblickKey);
    await tester.ensureVisible(knopf);
    await tester.pumpAndSettle();
    await tester.tap(knopf);
    await tester.pumpAndSettle();

    expect(find.byType(JahresrueckblickScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    // 51 Tage a, 26 Tage b.
    expect(
      find.descendant(
        of: find.byKey(JahresrueckblickScreen.haekchenKey),
        matching: find.text('77'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(JahresrueckblickScreen.besteKey), findsOneWidget);
  });

  testWidgets('vom 20.12. bis 7.1. kündigt sich das Jahr an', (tester) async {
    await zeige(tester, tag: const Day(2026, 12, 22));
    expect(find.byKey(StatistikScreen.ankuendigungKey), findsOneWidget);
  });

  testWidgets('sonst nicht', (tester) async {
    await zeige(tester);
    expect(find.byKey(StatistikScreen.ankuendigungKey), findsNothing);
  });

  testWidgets('eine Gewohnheit mit Ziel zeigt die Menge', (tester) async {
    final starter = HabitCatalog.starter;
    var t = const HabitTracker.empty().activate(starter.id, today: heute);
    t = t.check(starter.id, heute).tracker;
    await zeige(
      tester,
      tracker: t,
      screen: StatistikScreen(habitId: starter.id),
    );

    final einheit = starter.goal!.unit;
    expect(find.text('${starter.goal!.target} $einheit'), findsOneWidget);
  });

  testWidgets('ohne Häkchen steht kein Prozent, und nichts bricht', (
    tester,
  ) async {
    await zeige(tester, tracker: const HabitTracker.empty());
    expect(tester.widget<Text>(find.byKey(QuoteKarte.quoteKey)).data, '–');
    expect(tester.takeException(), isNull);
  });
}
