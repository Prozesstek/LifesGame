import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/achievements/achievements_controller.dart';
import 'package:lifes_game/action/action_game.dart';
import 'package:lifes_game/action/daily_pit_screen.dart';
import 'package:lifes_game/action/pit_run_view.dart';
import 'package:lifes_game/combat/daily_pit_controller.dart';
import 'package:lifes_game/combat/ladder_controller.dart';
import 'package:lifes_game/combat/ladder_screen.dart';
import 'package:lifes_game/combat/tagesgrube_text.dart';
import 'package:lifes_game/combat/widgets/raumzeile.dart';
import 'package:lifes_game/combat/widgets/tagesgrube_ergebnis.dart';
import 'package:lifes_game/combat/widgets/tagesgrube_karte.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/ui/ruhm_zahl.dart';

import 'test_view.dart';

/// Die Tagesgrube in der App (ADR-0072): dieselbe Grube für alle, ein
/// Versuch am Tag, danach ein Text zum Teilen.
void main() {
  // Der 12.10.2026 ist ein Montag — der zweite Tag der Tagesgrube.
  const heute = Day(2026, 10, 12);
  final tag = dayNumberOf(heute);
  const gewohnheit = HabitCatalog.starterId;

  /// Wer einmal in der Grube war: erst dann steht die Tagesgrube da.
  final warUnten = const LadderProgress.empty().recordDefeat(1);

  HabitTracker eineOffen() {
    return const HabitTracker.empty().activate(gewohnheit, today: heute);
  }

  HabitTracker allesErledigt() => eineOffen().check(gewohnheit, heute).tracker;

  DailyPitLog mit(DailyRun lauf) {
    return DailyPitLog.fromJson(<String, Object?>{'$tag': lauf.toJson()});
  }

  const sieg = DailyRun(
    outcome: DailyOutcome.sieg,
    seconds: 64.2,
    condition: DailyCondition.inForm,
    rooms: <RoomMark>[
      RoomMark.sauber,
      RoomMark.sauber,
      RoomMark.angekratzt,
      RoomMark.blutig,
      RoomMark.krone,
    ],
  );

  ProviderContainer container(SaveData stand) {
    final c = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(stand),
        todayProvider.overrideWithValue(heute),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('Der Text zum Teilen', () {
    test('ein Sieg in Form: Raumzeile, Zeit, Blitz und Kette', () {
      expect(
        TagesgrubeText.teilen(number: 12, run: sieg, dayStreak: 12),
        'Lifes Game · Tagesgrube #12\n'
        '🟩🟩🟨🟥👑 1:04\n'
        '⚡ In Form · 🔥 12 Tage\n'
        'prozesstek.de/LifesGame',
      );
    });

    test('eine Niederlage am Ruhetag: ein Totenkopf, keine Zeit', () {
      const lauf = DailyRun(
        outcome: DailyOutcome.gefallen,
        seconds: 48,
        condition: DailyCondition.ruhetag,
        rooms: <RoomMark>[
          RoomMark.sauber,
          RoomMark.angekratzt,
          RoomMark.gefallen,
          RoomMark.offen,
          RoomMark.offen,
        ],
      );

      expect(
        TagesgrubeText.teilen(number: 12, run: lauf, dayStreak: 12),
        'Lifes Game · Tagesgrube #12\n'
        '🟩🟨💀⬛⬛\n'
        '🌙 Ruhetag · 🔥 12 Tage\n'
        'prozesstek.de/LifesGame',
      );
    });

    test('ohne Form und ohne Kette steht nichts davon da', () {
      const lauf = DailyRun(
        outcome: DailyOutcome.zeitAus,
        seconds: 145,
        condition: DailyCondition.ohneForm,
        rooms: <RoomMark>[RoomMark.blutig, RoomMark.zeitAus, RoomMark.offen],
      );
      final text = TagesgrubeText.teilen(number: 3, run: lauf, dayStreak: 0);

      expect(text.split('\n'), <String>[
        'Lifes Game · Tagesgrube #3',
        '🟥⏳⬛',
        'prozesstek.de/LifesGame',
      ]);
    });

    test('ein Tag ist ein Tag, nicht ein Tage', () {
      final text = TagesgrubeText.teilen(number: 1, run: sieg, dayStreak: 1);

      expect(text, contains('🔥 1 Tag\n'));
    });

    test('ein abgebrochener Versuch sagt genau das', () {
      const lauf = DailyRun.started(condition: DailyCondition.inForm);
      final text = TagesgrubeText.teilen(number: 4, run: lauf, dayStreak: 0);

      expect(text.split('\n')[1], '💨 abgebrochen');
    });

    test('er verrät weder Waffe noch Fähigkeiten des Tages', () {
      final text = TagesgrubeText.teilen(number: 12, run: sieg, dayStreak: 3);

      for (final satz in DailyPit.loadouts) {
        for (final id in <String>[satz.weaponMoveId, ...satz.abilityIds]) {
          final name =
              PitAbilities.byId(id)?.name ?? PitWeapons.byMoveId(id)!.name;
          expect(text, isNot(contains(name)));
        }
      }
    });

    test('die Zeit steht in Minuten und Sekunden', () {
      expect(TagesgrubeText.zeit(59.4), '0:59');
      expect(TagesgrubeText.zeit(64.2), '1:04');
      expect(TagesgrubeText.zeit(145), '2:25');
    });
  });

  group('Die Verfassung', () {
    test('nichts fällig ist ein Ruhetag', () {
      final c = container(const SaveData());

      expect(c.read(dailyConditionProvider), DailyCondition.ruhetag);
    });

    test('etwas offen heißt ohne Form', () {
      final c = container(SaveData(habits: eineOffen()));

      expect(c.read(dailyConditionProvider), DailyCondition.ohneForm);
      expect(c.read(todayDailyPitProvider).open, 1);
    });

    test('alles Fällige erledigt heißt in Form — auch mit nur einer', () {
      final c = container(SaveData(habits: allesErledigt()));

      expect(c.read(dailyConditionProvider), DailyCondition.inForm);
      expect(c.read(todayDailyPitProvider).open, 0);
    });
  });

  group('Die Tagesgrube von heute', () {
    test('Nummer und Satz kommen aus dem Datum', () {
      final c = container(const SaveData());
      final grube = c.read(todayDailyPitProvider);

      expect(grube.day, DailyPit.firstDay + 1);
      expect(grube.number, 2);
      expect(grube.loadout, same(DailyPit.loadouts.first), reason: 'Montag');
      expect(grube.run, isNull);
    });

    test('ein Versuch am Tag: der zweite Start ändert nichts', () {
      final c = container(const SaveData());
      final grube = c.read(dailyPitProvider.notifier);

      expect(grube.start(tag, DailyCondition.ruhetag), isTrue);
      expect(grube.start(tag, DailyCondition.inForm), isFalse);
      expect(
        c.read(todayDailyPitProvider).run!.condition,
        DailyCondition.ruhetag,
      );
    });

    test('morgen gibt es einen neuen', () {
      final c = container(const SaveData());
      final grube = c.read(dailyPitProvider.notifier);

      grube.start(tag, DailyCondition.ruhetag);

      expect(grube.start(tag + 1, DailyCondition.ruhetag), isTrue);
    });

    test('der Entwicklermodus gibt den Versuch wieder frei', () {
      final c = container(const SaveData());
      final grube = c.read(dailyPitProvider.notifier);

      grube.start(tag, DailyCondition.ruhetag);
      grube.reset(tag);

      expect(c.read(todayDailyPitProvider).run, isNull);
    });
  });

  group('Was sie einbringt', () {
    test('Ruhm kommt aus Errungenschaften und der Tagesgrube', () {
      final ohne = container(const SaveData());
      final mitSieg = container(SaveData(dailyPit: mit(sieg)));

      expect(
        mitSieg.read(fameProvider),
        ohne.read(fameProvider) + DailyPitRewards.fameForWinInForm,
      );
    });

    test('weder Erfahrung noch Gold, und die Reihe bleibt, wie sie war', () {
      final ohne = container(SaveData(ladder: warUnten));
      final mitSieg = container(
        SaveData(ladder: warUnten, dailyPit: mit(sieg)),
      );

      expect(mitSieg.read(totalXpProvider), ohne.read(totalXpProvider));
      expect(mitSieg.read(goldProvider), ohne.read(goldProvider));
      expect(mitSieg.read(ladderProvider), ohne.read(ladderProvider));
    });
  });

  group('Speichern', () {
    test('der Versuch überlebt einen Neustart', () {
      final stand = SaveData(dailyPit: mit(sieg));
      final wieder = SaveData.decode(stand.encode());

      expect(wieder.dailyPit, stand.dailyPit);
      expect(wieder.dailyPit.runOn(tag), sieg);
    });

    test('ein Stand von vor ADR-0072 hat einfach keinen', () {
      final alt = SaveData.decode('{"version": 1, "ladder": {"defeated": 4}}');

      expect(alt.dailyPit.isEmpty, isTrue);
      expect(alt.ladder.highestDefeated, 4);
    });

    test('ein Stand mit nur einem Versuch ist nicht leer', () {
      expect(SaveData(dailyPit: mit(sieg)).isEmpty, isFalse);
    });

    test('ohne Versuch schreibt der Stand nichts dazu', () {
      expect(const SaveData().toJson().containsKey('dailyPit'), isFalse);
    });
  });

  group('Wann sie erscheint', () {
    test('erst nach dem ersten Lauf, gewonnen oder verloren', () {
      expect(
        ErsterStart.aus(const ErsterStartStand(haekchen: 1)).zeigtTagesgrube,
        isFalse,
      );
      expect(
        ErsterStart.aus(
          const ErsterStartStand(haekchen: 1, hatGekaempft: true),
        ).zeigtTagesgrube,
        isTrue,
      );
      expect(ErsterStart.allesOffen.zeigtTagesgrube, isTrue);
    });

    test('ein verlorener erster Lauf reicht', () {
      final c = container(SaveData(ladder: warUnten));

      expect(c.read(ersterStartProvider).zeigtTagesgrube, isTrue);
    });
  });

  group('Im Eingang der Grube', () {
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

    Future<ProviderContainer> eingang(
      WidgetTester tester,
      SaveData stand,
    ) async {
      usePhoneView(tester);
      final c = container(stand);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: LadderScreen()),
        ),
      );
      await tester.pumpAndSettle();
      return c;
    }

    /// Tippt „Hinab“ der Tagesgrube und wartet, bis die Seite steht. Kein
    /// `pumpAndSettle`: Flame zeichnet dauerhaft (`gotchas.md`).
    Future<void> hinab(WidgetTester tester) async {
      await tester.tap(find.byKey(TagesgrubeKarte.hinabKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    ActionGame spielVon(WidgetTester tester) =>
        tester.widget<PitRunView>(find.byType(PitRunView)).game;

    testWidgets('wer noch nie unten war, sieht sie nicht', (tester) async {
      await eingang(tester, const SaveData());

      expect(find.byKey(TagesgrubeKarte.hinabKey), findsNothing);
      expect(find.textContaining('Tagesgrube'), findsNothing);
    });

    testWidgets('danach steht sie da: Nummer, Satz des Tages, Knopf', (
      tester,
    ) async {
      await eingang(tester, SaveData(ladder: warUnten));

      expect(find.text('Tagesgrube #2'), findsOneWidget);
      expect(find.byKey(TagesgrubeKarte.hinabKey), findsOneWidget);
      // Montag: der Bogen und die drei ersten aus dem Baum.
      for (final name in <String>['Funkenstoß', 'Steinhaut', 'Blütentau']) {
        expect(
          find.byWidgetPredicate(
            (w) => w is Tooltip && (w.message ?? '').startsWith(name),
          ),
          findsOneWidget,
          reason: name,
        );
      }
    });

    testWidgets('am Ruhetag geht es ohne Rückfrage hinab — der Versuch ist '
        'damit gebraucht', (tester) async {
      final c = await eingang(tester, SaveData(ladder: warUnten));

      await hinab(tester);

      expect(find.byType(DailyPitScreen), findsOneWidget);
      final lauf = c.read(dailyPitProvider).runOn(tag)!;
      expect(lauf.outcome, DailyOutcome.abgebrochen);
      expect(lauf.condition, DailyCondition.ruhetag);
    });

    testWidgets('wer noch etwas offen hat, wird einmal gefragt', (
      tester,
    ) async {
      final c = await eingang(
        tester,
        SaveData(ladder: warUnten, habits: eineOffen()),
      );

      await tester.tap(find.byKey(TagesgrubeKarte.hinabKey));
      await tester.pumpAndSettle();
      expect(find.text('Noch 1 offen'), findsOneWidget);

      await tester.tap(find.byKey(TagesgrubeKarte.erstAbhakenKey));
      await tester.pumpAndSettle();

      expect(find.byType(DailyPitScreen), findsNothing);
      expect(
        c.read(dailyPitProvider).hasStarted(tag),
        isFalse,
        reason: 'Wer erst abhaken geht, hat seinen Versuch noch.',
      );
    });

    testWidgets('„Trotzdem hinab“ geht ohne Form hinab', (tester) async {
      final c = await eingang(
        tester,
        SaveData(ladder: warUnten, habits: eineOffen()),
      );

      await tester.tap(find.byKey(TagesgrubeKarte.hinabKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(TagesgrubeKarte.trotzdemKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(DailyPitScreen), findsOneWidget);
      expect(
        c.read(dailyPitProvider).runOn(tag)!.condition,
        DailyCondition.ohneForm,
      );
      expect(
        spielVon(tester).sim.heroMaxHp,
        PitPower.dailyHero(inForm: false).combatMaxHp,
      );
    });

    testWidgets('in Form geht es ohne Rückfrage hinab, und der Held ist '
        'stärker', (tester) async {
      final c = await eingang(
        tester,
        SaveData(ladder: warUnten, habits: allesErledigt()),
      );

      await hinab(tester);

      expect(find.byType(DailyPitScreen), findsOneWidget);
      expect(
        c.read(dailyPitProvider).runOn(tag)!.condition,
        DailyCondition.inForm,
      );
      expect(
        spielVon(tester).sim.heroMaxHp,
        PitPower.dailyHero(inForm: true).combatMaxHp,
      );
    });

    testWidgets('unten wartet die Grube des Tages mit dem Satz des Tages', (
      tester,
    ) async {
      await eingang(tester, SaveData(ladder: warUnten));
      await hinab(tester);

      final sim = spielVon(tester).sim;
      final satz = DailyPit.loadoutFor(tag);
      expect(sim.weapon.moveId, satz.weaponMoveId);
      expect(sim.slots.map((a) => a.id), satz.abilityIds);
      expect(sim.stage, PitStage(satz.stage));
      expect(sim.rewardPot, (xp: 0, gold: 0));
      expect(find.text('Tagesgrube #2'), findsOneWidget);
    });

    testWidgets('„Zurück“ mitten im Lauf fragt, und „Weiterkämpfen“ bleibt', (
      tester,
    ) async {
      await eingang(tester, SaveData(ladder: warUnten));
      await hinab(tester);

      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Aufgeben?'), findsOneWidget);
      expect(spielVon(tester).paused, isTrue, reason: 'Der Lauf hält an.');

      await tester.tap(find.byKey(DailyPitScreen.bleibenKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(DailyPitScreen), findsOneWidget);
      expect(spielVon(tester).paused, isFalse);
    });

    testWidgets('wer aufgibt, hat abgebrochen — und keinen zweiten Versuch', (
      tester,
    ) async {
      final c = await eingang(tester, SaveData(ladder: warUnten));
      await hinab(tester);

      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(DailyPitScreen.aufgebenKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byType(DailyPitScreen), findsNothing);
      expect(
        c.read(dailyPitProvider).runOn(tag)!.outcome,
        DailyOutcome.abgebrochen,
      );
      expect(find.byKey(TagesgrubeKarte.hinabKey), findsNothing);
      expect(find.byIcon(Icons.directions_run_rounded), findsOneWidget);
      expect(find.byKey(TagesgrubeKarte.teilenKey), findsOneWidget);
    });

    testWidgets('ein ganzer Lauf: Ergebnis, teilen, zurück — und nichts '
        'ausser Ruhm', (tester) async {
      final c = await eingang(tester, SaveData(ladder: warUnten));
      final xpVorher = c.read(totalXpProvider);
      final goldVorher = c.read(goldProvider);
      final ruhmVorher = c.read(fameProvider);
      await hinab(tester);

      // Der Held bleibt stehen, bis die Uhr abläuft.
      final game = spielVon(tester);
      for (var i = 0; i < 20000 && !game.sim.isOver; i++) {
        game.update(0.05);
      }
      expect(game.sim.isTimedOut, isTrue);
      await tester.pump();
      await tester.pump();

      expect(find.byType(TagesgrubeErgebnis), findsOneWidget);
      expect(find.text('Niederlage'), findsOneWidget);

      await tester.tap(find.byKey(TagesgrubeErgebnis.teilenKey));
      await tester.pump();
      expect(zwischenablage, startsWith('Lifes Game · Tagesgrube #2\n'));
      expect(zwischenablage, endsWith(TagesgrubeText.adresse));
      expect(find.text('Kopiert'), findsOneWidget);

      await tester.tap(find.byKey(TagesgrubeErgebnis.weiterKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Zurück im Eingang: das Ergebnis statt des Knopfs.
      expect(find.byType(DailyPitScreen), findsNothing);
      expect(find.byKey(TagesgrubeKarte.hinabKey), findsNothing);
      expect(find.byType(Raumzeile), findsOneWidget);

      final lauf = c.read(dailyPitProvider).runOn(tag)!;
      expect(lauf.outcome, DailyOutcome.zeitAus);
      expect(lauf.rooms.first, RoomMark.zeitAus);
      expect(c.read(fameProvider), ruhmVorher + 1);
      expect(c.read(totalXpProvider), xpVorher);
      expect(c.read(goldProvider), goldVorher);
      expect(c.read(ladderProvider), warUnten, reason: 'Die Reihe bleibt.');
    });

    testWidgets('nach dem Versuch: Raumzeile, Zeit, Ruhm, und der Knopf '
        'kopiert den Text', (tester) async {
      await eingang(
        tester,
        SaveData(
          ladder: warUnten,
          habits: allesErledigt(),
          dailyPit: mit(sieg),
        ),
      );

      expect(find.byType(Raumzeile), findsOneWidget);
      expect(find.text('1:04'), findsOneWidget);
      expect(
        tester.widget<RuhmZahl>(find.byType(RuhmZahl)).fame,
        DailyPitRewards.fameForWinInForm,
      );

      await tester.tap(find.byKey(TagesgrubeKarte.teilenKey));
      await tester.pump();

      expect(
        zwischenablage,
        'Lifes Game · Tagesgrube #2\n'
        '🟩🟩🟨🟥👑 1:04\n'
        '⚡ In Form · 🔥 1 Tag\n'
        'prozesstek.de/LifesGame',
      );
    });

    testWidgets('gezeigt wird die Verfassung vom Start, nicht die von jetzt', (
      tester,
    ) async {
      // Ohne Form hinabgestiegen, danach abgehakt: Der Blitz bleibt leer.
      const ohneForm = DailyRun(
        outcome: DailyOutcome.gefallen,
        seconds: 30,
        condition: DailyCondition.ohneForm,
        rooms: <RoomMark>[RoomMark.gefallen, RoomMark.offen],
      );
      await eingang(
        tester,
        SaveData(
          ladder: warUnten,
          habits: allesErledigt(),
          dailyPit: mit(ohneForm),
        ),
      );

      expect(find.byIcon(Icons.bolt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsNothing);
    });
  });

  group('Das Blatt am Ende', () {
    testWidgets('ein Sieg: Raumzeile, Zeit, Kette und fünf Ruhm', (
      tester,
    ) async {
      usePhoneView(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TagesgrubeErgebnis(number: 12, run: sieg, dayStreak: 12),
          ),
        ),
      );

      expect(find.text('Sieg'), findsOneWidget);
      expect(find.text('Tagesgrube #12'), findsOneWidget);
      expect(find.text('1:04'), findsOneWidget);
      expect(find.text('12'), findsOneWidget, reason: 'die Tageskette');
      expect(tester.widget<RuhmZahl>(find.byType(RuhmZahl)).fame, 5);
      expect(
        tester.widget<Raumzeile>(find.byType(Raumzeile)).rooms,
        sieg.rooms,
      );
    });

    test('der Vorleser bekommt die Raumzeile in Worten', () {
      expect(
        Raumzeile.label(sieg.rooms),
        'kaum getroffen, kaum getroffen, getroffen, schwer getroffen, '
        'Wächter besiegt',
      );
      expect(Raumzeile.label(const <RoomMark>[]), 'Kein Raum erreicht');
    });
  });
}
