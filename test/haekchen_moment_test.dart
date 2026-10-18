import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/audio/sound_effects.dart';
import 'package:lifes_game/habits/haekchen_moment.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/habits/widgets/haekchen_kreis.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/home/widgets/status_leiste.dart';
import 'package:lifes_game/home/widgets/today_card.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/ui/aufstieg.dart';
import 'package:lifes_game/ui/beute_flug.dart';
import 'package:lifes_game/ui/konfetti.dart';
import 'package:lifes_game/ui/sprung.dart';

import 'test_view.dart';

/// Merkt sich, was gespielt werden sollte, statt es zu spielen.
class _Mitschrift implements SoundPlayer {
  final List<SoundEffect> gespielt = <SoundEffect>[];

  @override
  void play(SoundEffect effect) => gespielt.add(effect);
}

/// Der Häkchen-Moment: Kreis, Tonleiter, Flamme, Münzen, Konfetti.
///
/// **Keine Zahl ändert sich** — was hier geprüft wird, ist nur, wie laut
/// die Darstellung auf ein Häkchen antwortet, und dass die Leiste oben
/// am Ende dasselbe zeigt wie vorher, nur später.
void main() {
  const heute = Day(2026, 10, 18);

  // Drei Vorlagen ohne Timer: Ein Tipp hakt sie ab. Die Startvorlage
  // öffnete ihren Timer (ADR-0067).
  final drei = HabitCatalog.all
      .where((t) => t.id != HabitCatalog.starter.id)
      .take(3)
      .toList(growable: false);

  HabitTracker mitDreien() {
    var tracker = const HabitTracker.empty();
    for (final vorlage in drei) {
      tracker = tracker.activate(vorlage.id);
    }
    return tracker;
  }

  group('Sprung', () {
    test('die Feder beginnt klein, schiesst über und steht auf 1', () {
      expect(Sprung.feder(0), 0.3);
      final spitze = <double>[
        for (var i = 1; i < 100; i++) Sprung.feder(i / 100),
      ].reduce((a, b) => a > b ? a : b);
      expect(spitze, greaterThan(1.15));
      expect(Sprung.feder(1), 1);
    });

    test('der Stoss steht vorher und nachher auf 1', () {
      expect(Sprung.stoss(0), 1);
      expect(Sprung.stoss(1), 1);
      expect(Sprung.stoss(0.1, hoehe: 0.8), greaterThan(1.4));
    });
  });

  group('HaekchenMoment', () {
    test('die Tonleiter steigt mit jedem Häkchen, das letzte löst auf', () {
      var tracker = mitDreien();
      final klaenge = <SoundEffect>[];
      final erste = <bool>[];
      final geschafft = <bool>[];
      for (final vorlage in drei) {
        final nachher = tracker.check(vorlage.id, heute).tracker;
        final moment = HaekchenMoment.aus(
          vorher: tracker,
          nachher: nachher,
          heute: heute,
          punkt: false,
        );
        klaenge.add(moment.klang);
        erste.add(moment.ersterDesTages);
        geschafft.add(moment.tagGeschafft);
        tracker = nachher;
      }

      expect(klaenge, <SoundEffect>[
        SoundEffect.ton1,
        SoundEffect.ton2,
        SoundEffect.tagGeschafft,
      ]);
      expect(erste, <bool>[true, false, false]);
      expect(geschafft, <bool>[false, false, true]);
    });

    test('ein Punkt klingt vor allem anderen', () {
      const moment = HaekchenMoment(
        nummer: 3,
        ersterDesTages: false,
        tagGeschafft: true,
        punkt: true,
      );
      expect(moment.klang, SoundEffect.statPunkt);
    });

    test('über der fünften Stufe bleibt es die oberste', () {
      const moment = HaekchenMoment(
        nummer: 7,
        ersterDesTages: false,
        tagGeschafft: false,
        punkt: false,
      );
      expect(moment.klang, SoundEffect.ton5);
      expect(
        SoundEffect.tonleiter,
        hasLength(HabitRewards.maxActiveHabits),
        reason: 'eine Stufe je Gewohnheit, die laufen kann',
      );
    });
  });

  group('BeuteFlug', () {
    test('nie ein Stück allein, nie mehr als acht', () {
      expect(BeuteFlug.stueckeFuer(0, FlugZiel.gold), 0);
      expect(BeuteFlug.stueckeFuer(1, FlugZiel.gold), 3);
      expect(BeuteFlug.stueckeFuer(100, FlugZiel.gold), 8);
      expect(BeuteFlug.stueckeFuer(3, FlugZiel.erfahrung), 3);
      expect(BeuteFlug.stueckeFuer(90, FlugZiel.erfahrung), 8);
    });

    test('der ganze Betrag kommt an, und dann ist nichts mehr unterwegs', () {
      final flug = BeuteFlug()
        ..wirf(
          von: const Offset(200, 600),
          ziel: FlugZiel.gold,
          nach: const Offset(330, 100),
          betrag: 17,
        );
      expect(flug.stuecke.fold<int>(0, (summe, s) => summe + s.wert), 17);
      expect(flug.unterwegs(FlugZiel.gold), 17);

      var zeit = 0.0;
      while (!flug.leer && zeit < 5) {
        flug.update(1 / 60);
        zeit += 1 / 60;
      }
      expect(flug.unterwegs(FlugZiel.gold), 0);
      expect(
        zeit,
        lessThan(BeuteFlug.flugzeit + 8 * BeuteFlug.staffel + 0.05),
        reason: 'kein Stück hängt',
      );
    });

    test('ein Stück platzt erst vom Finger weg und endet am Ziel', () {
      final flug = BeuteFlug()
        ..wirf(
          von: const Offset(200, 600),
          ziel: FlugZiel.erfahrung,
          nach: const Offset(200, 100),
          betrag: 9,
        );
      final stueck = flug.stuecke.first;
      expect(stueck.ortBei(0), const Offset(200, 600));
      expect(stueck.ortBei(1), const Offset(200, 100));
      expect(
        (stueck.ortBei(BeuteFlug.platzen) - stueck.von).distance,
        greaterThan(BeuteFlug.streuung * 0.4),
      );
    });
  });

  group('Konfetti', () {
    test('steigt erst, fällt dann und ist nach seiner Dauer vorbei', () {
      final wurf = Konfetti(von: const Offset(200, 500));
      double mittlereHoehe() =>
          wurf.stuecke.fold<double>(0, (s, k) => s + k.ort.dy) /
          wurf.stuecke.length;

      void laufe(double sekunden) {
        for (var t = 0.0; t < sekunden; t += 1 / 60) {
          wurf.update(1 / 60);
        }
      }

      laufe(0.3);
      final oben = mittlereHoehe();
      expect(oben, lessThan(500));
      expect(wurf.deckkraft, 1);

      laufe(1.7);
      expect(mittlereHoehe(), greaterThan(oben));
      for (final stueck in wurf.stuecke) {
        expect(
          stueck.vy,
          lessThanOrEqualTo(Konfetti.schwere / Konfetti.luft + 1),
          reason: 'Papier fällt nicht wie ein Stein',
        );
      }

      laufe(0.5);
      expect(wurf.vorbei, isTrue);
      expect(wurf.deckkraft, 0);
    });
  });

  group('Der Kreis', () {
    Finder springt() => find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is HaekchenSprungMaler,
    );

    Future<void> kreis(WidgetTester tester, {required bool an}) {
      return tester.pumpWidget(
        MaterialApp(
          home: Center(child: HaekchenKreis(isChecked: an, size: 26)),
        ),
      );
    }

    testWidgets('springt beim Setzen, nicht beim Zurücknehmen', (tester) async {
      await kreis(tester, an: false);
      expect(springt(), findsNothing);

      await kreis(tester, an: true);
      await tester.pump(const Duration(milliseconds: 100));
      expect(springt(), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await tester.pumpAndSettle();
      expect(springt(), findsNothing);

      await kreis(tester, an: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(springt(), findsNothing);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });

    testWidgets('ein schon erledigtes springt beim Aufbau nicht', (
      tester,
    ) async {
      await kreis(tester, an: true);
      await tester.pump(const Duration(milliseconds: 100));
      expect(springt(), findsNothing);
    });
  });

  group('Auf der Startseite', () {
    Future<(ProviderContainer, _Mitschrift)> startseite(
      WidgetTester tester,
      HabitTracker tracker,
    ) async {
      useTallView(tester);
      final mitschrift = _Mitschrift();
      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(SaveData(habits: tracker)),
          todayProvider.overrideWithValue(heute),
          soundPlayerProvider.overrideWithValue(mitschrift),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();
      return (container, mitschrift);
    }

    Finder inDerKarte(Finder finder) =>
        find.descendant(of: find.byType(TodayCard), matching: finder);

    Finder inDerLeiste(String text) => find.descendant(
      of: find.byType(StatusLeiste),
      matching: find.text(text),
    );

    // Gestern war schon etwas abgehakt: Die Kette steht bei 1, und das
    // erste Häkchen überhaupt — mit seiner Errungenschaft — liegt zurück.
    HabitTracker mitGestern() =>
        mitDreien().check(drei.first.id, heute.previous).tracker;

    testWidgets('die Goldzahl steigt erst, wenn die Münzen ankommen', (
      tester,
    ) async {
      final (container, mitschrift) = await startseite(tester, mitGestern());
      final vorher = container.read(goldProvider);
      expect(inDerLeiste('$vorher'), findsOneWidget);

      await tester.tap(inDerKarte(find.text(drei[1].name)));
      await tester.pump();

      final nachher = container.read(goldProvider);
      expect(nachher, greaterThan(vorher), reason: 'gezählt ist sofort');
      expect(inDerLeiste('$vorher'), findsOneWidget, reason: 'noch im Flug');

      await tester.pumpAndSettle();
      expect(inDerLeiste('$nachher'), findsOneWidget);
      expect(mitschrift.gespielt, contains(SoundEffect.muenze));
      expect(mitschrift.gespielt, contains(SoundEffect.funke));
      final host = tester.state<AufstiegHostState>(find.byType(AufstiegHost));
      expect(host.unterwegs(FlugZiel.gold).value, 0);
      expect(host.unterwegs(FlugZiel.erfahrung).value, 0);
    });

    testWidgets('das erste Häkchen des Tages zündet die Flamme', (
      tester,
    ) async {
      final (_, mitschrift) = await startseite(tester, mitGestern());
      expect(inDerKarte(find.text('1')), findsOneWidget);

      await tester.tap(inDerKarte(find.text(drei[1].name)));
      await tester.pump(const Duration(milliseconds: 120));

      // Die Zahl rollt: die alte hinaus, die neue herein.
      expect(inDerKarte(find.text('1')), findsOneWidget);
      expect(inDerKarte(find.text('2')), findsOneWidget);
      expect(mitschrift.gespielt.first, SoundEffect.ton1);
      expect(mitschrift.gespielt, contains(SoundEffect.kette));

      await tester.pumpAndSettle();
      expect(inDerKarte(find.text('1')), findsNothing);
      expect(inDerKarte(find.text('2')), findsOneWidget);

      // Das zweite zündet nichts mehr und klingt eine Stufe höher.
      mitschrift.gespielt.clear();
      await tester.tap(inDerKarte(find.text(drei[2].name)));
      await tester.pump();
      expect(mitschrift.gespielt.first, SoundEffect.ton2);
      expect(mitschrift.gespielt, isNot(contains(SoundEffect.kette)));
      await tester.pumpAndSettle();
    });

    testWidgets('vom leeren Tag bis zum Akkord, Häkchen für Häkchen', (
      tester,
    ) async {
      final (_, mitschrift) = await startseite(tester, mitDreien());

      for (final vorlage in drei) {
        await tester.tap(inDerKarte(find.text(vorlage.name)));
        await tester.pumpAndSettle();
        // Das allererste Häkchen bringt eine Errungenschaft; ihre Feier
        // liegt über der Karte.
        if (vorlage == drei.first) {
          await tester.tapAt(const Offset(10, 10));
          await tester.pumpAndSettle();
        }
      }

      final toene = mitschrift.gespielt
          .where(
            (k) =>
                SoundEffect.tonleiter.contains(k) ||
                k == SoundEffect.tagGeschafft,
          )
          .toList();
      expect(toene, <SoundEffect>[
        SoundEffect.ton1,
        SoundEffect.ton2,
        SoundEffect.tagGeschafft,
      ]);
    });

    testWidgets('Konfetti fliegt, solange der Tag frisch geschafft ist', (
      tester,
    ) async {
      final fast = mitGestern()
          .check(drei[0].id, heute)
          .tracker
          .check(drei[1].id, heute)
          .tracker;
      await startseite(tester, fast);
      final host = tester.state<AufstiegHostState>(find.byType(AufstiegHost));

      await tester.tap(inDerKarte(find.text(drei[2].name)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(host.konfettiInDerLuft, 1);

      await tester.pumpAndSettle();
      expect(host.konfettiInDerLuft, 0);
    });
  });

  testWidgets('auf dem Gewohnheiten-Bildschirm fliegt nichts', (tester) async {
    // Dort gibt es keine Leiste oben — nur die Zahlen steigen auf.
    useTallView(tester);
    final container = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(SaveData(habits: mitDreien())),
        todayProvider.overrideWithValue(heute),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HabitsScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text(drei.first.name));
    await tester.pump();
    final host = tester.state<AufstiegHostState>(find.byType(AufstiegHost));
    expect(host.unterwegs(FlugZiel.gold).value, 0);
    expect(
      container.read(habitTrackerProvider).isChecked(drei.first.id, heute),
      isTrue,
    );
    await tester.pumpAndSettle();
  });
}
