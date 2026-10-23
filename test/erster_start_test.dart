import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/action/pit_screen.dart';
import 'package:lifes_game/character/abilities_controller.dart';
import 'package:lifes_game/combat/ladder_screen.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/widgets/daily_quests_card.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/home/widgets/erste_gewohnheit.dart';
import 'package:lifes_game/home/widgets/hub_circle.dart';
import 'package:lifes_game/home/widgets/today_card.dart';
import 'package:lifes_game/lagerfeuer/widgets/lagerfeuer_karte.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// Der erste Start (ADR-0068): Die Startseite fragt nach einer
/// Gewohnheit, und die Bereiche kommen nach und nach.
///
/// Oben die Regel als reine Rechnung, unten der Weg durch die App — vom
/// leeren Stand bis in die Grube, ohne eine Seite gelesen zu haben.
void main() {
  const heute = Day(2026, 10, 6);
  const billig = 70;

  Set<Bereich> sichtbarBei(ErsterStartStand stand) =>
      ErsterStart.aus(stand).sichtbar;

  group('die Regel', () {
    test('ein leerer Stand zeigt nur die Gewohnheiten und fragt', () {
      final start = ErsterStart.aus(
        const ErsterStartStand(billigstesStueck: billig),
      );

      expect(start.sichtbar, <Bereich>{Bereich.gewohnheiten});
      expect(start.fragtNachGewohnheit, isTrue);
      expect(start.schritt, Schritt.gewohnheit);
      expect(start.leuchtet, isNull);
      expect(start.zeigtTagesaufgaben, isFalse);
    });

    test('mit einer Gewohnheit wird nicht mehr gefragt, sondern abgehakt', () {
      final start = ErsterStart.aus(
        const ErsterStartStand(hatGewohnheit: true, billigstesStueck: billig),
      );

      expect(start.fragtNachGewohnheit, isFalse);
      expect(start.schritt, Schritt.abhaken);
      expect(start.sichtbar, <Bereich>{Bereich.gewohnheiten});
    });

    test('das erste Häkchen deckt die Theorie auf, und sie leuchtet '
        '(ADR-0079)', () {
      final start = ErsterStart.aus(
        const ErsterStartStand(
          hatGewohnheit: true,
          haekchen: 1,
          billigstesStueck: billig,
        ),
      );

      expect(start.zeigt(Bereich.theorie), isTrue);
      expect(start.zeigt(Bereich.kampf), isFalse);
      expect(start.schritt, Schritt.ersteSeite);
      expect(start.leuchtet, Bereich.theorie);
      expect(start.zeigtTagesaufgaben, isTrue);
    });

    test('die erste Seite deckt die Fähigkeiten auf, und sie leuchten', () {
      // Sie bringt jedem Funkenstoß (ADR-0079).
      final start = ErsterStart.aus(
        const ErsterStartStand(
          hatGewohnheit: true,
          haekchen: 1,
          seiten: 1,
          gelernt: 1,
          level: 2,
          billigstesStueck: billig,
        ),
      );

      expect(start.zeigt(Bereich.faehigkeiten), isTrue);
      expect(start.zeigt(Bereich.kampf), isFalse);
      expect(start.schritt, Schritt.faehigkeitAnlegen);
      expect(start.leuchtet, Bereich.faehigkeiten);
    });

    test('die erste angelegte Fähigkeit deckt die Grube auf', () {
      final start = ErsterStart.aus(
        const ErsterStartStand(
          hatGewohnheit: true,
          haekchen: 1,
          seiten: 1,
          gelernt: 1,
          angelegt: 1,
          level: 2,
          billigstesStueck: billig,
        ),
      );

      expect(start.zeigt(Bereich.kampf), isTrue);
      expect(start.schritt, Schritt.grube);
      expect(start.leuchtet, Bereich.kampf);
    });

    test('nach dem ersten Sieg ist der Weg gegangen', () {
      final start = ErsterStart.aus(
        const ErsterStartStand(
          hatGewohnheit: true,
          haekchen: 1,
          hatGekaempft: true,
          stufenGeschafft: 1,
          seiten: 1,
          gelernt: 1,
          angelegt: 1,
          jeBesessen: 1,
          level: 3,
          billigstesStueck: billig,
        ),
      );

      expect(start.schritt, isNull);
      expect(start.leuchtet, isNull);
    });

    test('ein verlorener Lauf beendet den Weg nicht', () {
      // Der Mentor wartet auf den Sieg: Erst der bringt die Beute, mit
      // der er sich verabschiedet.
      final start = ErsterStart.aus(
        const ErsterStartStand(
          hatGewohnheit: true,
          haekchen: 1,
          hatGekaempft: true,
          seiten: 1,
          gelernt: 1,
          angelegt: 1,
          level: 2,
          billigstesStueck: billig,
        ),
      );

      expect(start.schritt, Schritt.grube);
    });

    test('wer zuerst liest, wird zum Häkchen geschickt', () {
      // Ohne Häkchen steht er auf Level 1, und der zweite Platz geht erst
      // mit dem Aufstieg auf, den das Häkchen bringt.
      final start = ErsterStart.aus(
        const ErsterStartStand(
          hatGewohnheit: true,
          seiten: 1,
          gelernt: 1,
          billigstesStueck: billig,
        ),
      );

      expect(start.schritt, Schritt.abhaken);
      expect(start.zeigt(Bereich.theorie), isTrue);
      expect(start.zeigt(Bereich.faehigkeiten), isTrue);
    });

    test('niemand muss lesen, um zu kämpfen — nur nicht gleich', () {
      // Wer eine Woche abhakt und nichts liest, sähe die Grube sonst nie.
      final vorher = ErsterStart.aus(
        const ErsterStartStand(
          hatGewohnheit: true,
          haekchen: ErsterStart.haekchenFuerKampf - 1,
          billigstesStueck: billig,
        ),
      );
      final dann = ErsterStart.aus(
        const ErsterStartStand(
          hatGewohnheit: true,
          haekchen: ErsterStart.haekchenFuerKampf,
          billigstesStueck: billig,
        ),
      );

      expect(vorher.zeigt(Bereich.kampf), isFalse);
      expect(dann.zeigt(Bereich.kampf), isTrue);
      expect(dann.leuchtet, Bereich.theorie, reason: 'gezeigt wird weiter');
    });

    test('wer schon gekämpft hat, sieht die Grube', () {
      // Stände aus der Zeit von „Kampf früh“ (ADR-0068).
      final start = ErsterStart.aus(
        const ErsterStartStand(
          hatGewohnheit: true,
          haekchen: 1,
          hatGekaempft: true,
          billigstesStueck: billig,
        ),
      );

      expect(start.zeigt(Bereich.kampf), isTrue);
      expect(start.schritt, Schritt.ersteSeite);
    });

    test('der Laden kommt, sobald das billigste Stück bezahlbar war', () {
      const vorher = ErsterStartStand(
        goldVerdient: billig - 1,
        billigstesStueck: billig,
      );
      const dann = ErsterStartStand(
        goldVerdient: billig,
        billigstesStueck: billig,
      );

      expect(sichtbarBei(vorher), isNot(contains(Bereich.laden)));
      expect(sichtbarBei(dann), contains(Bereich.laden));
    });

    test('das erste Stück deckt die Ausrüstung auf — und den Laden mit', () {
      // Die Beute des ersten Wächters kommt vor dem ersten Kauf.
      final sichtbar = sichtbarBei(
        const ErsterStartStand(jeBesessen: 1, billigstesStueck: billig),
      );

      expect(sichtbar, contains(Bereich.ausruestung));
      expect(sichtbar, contains(Bereich.laden));
    });

    test('der Charakter kommt mit dem ersten Aufstieg', () {
      expect(
        sichtbarBei(const ErsterStartStand(billigstesStueck: billig)),
        isNot(contains(Bereich.charakter)),
      );
      expect(
        sichtbarBei(
          const ErsterStartStand(
            level: ErsterStart.levelFuerCharakter,
            billigstesStueck: billig,
          ),
        ),
        contains(Bereich.charakter),
      );
    });

    test('wer einen Schritt übersprungen hat, sieht die Reihe trotzdem '
        'geschlossen', () {
      // Entwicklermodus oder eingefügter Stand: eine Fähigkeit liegt an,
      // aber es gibt weder Häkchen noch Lauf.
      final sichtbar = sichtbarBei(
        const ErsterStartStand(angelegt: 1, billigstesStueck: billig),
      );

      expect(
        sichtbar,
        containsAll(<Bereich>[
          Bereich.kampf,
          Bereich.theorie,
          Bereich.faehigkeiten,
        ]),
      );
    });

    test('kein Kreis verschwindet, wenn der Stand wächst', () {
      // Die Zusage aus ADR-0068: Was einmal da ist, bleibt.
      const weg = <ErsterStartStand>[
        ErsterStartStand(billigstesStueck: billig),
        ErsterStartStand(hatGewohnheit: true, billigstesStueck: billig),
        ErsterStartStand(
          hatGewohnheit: true,
          haekchen: 1,
          goldVerdient: 5,
          billigstesStueck: billig,
        ),
        ErsterStartStand(
          hatGewohnheit: true,
          haekchen: 1,
          seiten: 1,
          gelernt: 1,
          goldVerdient: 45,
          level: 2,
          billigstesStueck: billig,
        ),
        ErsterStartStand(
          hatGewohnheit: true,
          haekchen: 1,
          seiten: 1,
          gelernt: 1,
          angelegt: 1,
          goldVerdient: 45,
          level: 2,
          billigstesStueck: billig,
        ),
        ErsterStartStand(
          hatGewohnheit: true,
          haekchen: 9,
          hatGekaempft: true,
          stufenGeschafft: 1,
          seiten: 8,
          grundlagenGelesen: true,
          gelernt: 2,
          angelegt: 2,
          goldVerdient: 300,
          jeBesessen: 2,
          level: 4,
          billigstesStueck: billig,
        ),
      ];

      var bisher = <Bereich>{};
      for (final stand in weg) {
        final jetzt = sichtbarBei(stand);
        expect(jetzt, containsAll(bisher));
        bisher = jetzt;
      }
      expect(ErsterStart.aus(weg.last).fertig, isTrue);
      expect(ErsterStart.aus(weg.last).schritt, isNull);
    });

    test('allesOffen zeigt alle sieben, und der Mentor schweigt', () {
      expect(ErsterStart.allesOffen.fertig, isTrue);
      expect(ErsterStart.allesOffen.schritt, isNull);
      expect(ErsterStart.allesOffen.leuchtet, isNull);
      expect(ErsterStart.allesOffen.fragtNachGewohnheit, isFalse);
    });
  });

  group('in der App', () {
    Future<ProviderContainer> starte(
      WidgetTester tester, [
      SaveData stand = const SaveData.empty(),
    ]) async {
      useTallView(tester);
      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(stand),
          todayProvider.overrideWithValue(heute),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    /// Die Namen der Kreise, die einen Tipp annehmen.
    List<String> aufgedeckt(WidgetTester tester) => <String>[
      for (final kreis in tester.widgetList<HubCircle>(
        find.byType(HubCircle).hitTestable(),
      ))
        kreis.label,
    ];

    /// Der Name des Kreises, der leuchtet — oder null.
    String? leuchtet(WidgetTester tester) {
      final kreise = tester
          .widgetList<HubCircle>(find.byType(HubCircle))
          .where((k) => k.leuchtet)
          .toList();
      expect(kreise.length, lessThanOrEqualTo(1));
      return kreise.isEmpty ? null : kreise.single.label;
    }

    final einHaekchen = const HabitTracker.empty()
        .activate(HabitCatalog.starterId)
        .check(HabitCatalog.starterId, heute)
        .tracker;

    testWidgets('der erste Start zeigt einen Kreis und eine Frage', (
      tester,
    ) async {
      await starte(tester);

      expect(aufgedeckt(tester), <String>['Gewohnheiten']);
      expect(find.byType(ErsteGewohnheitKarte), findsOneWidget);
      expect(find.text('Was willst du jeden Tag tun?'), findsOneWidget);
      expect(find.byType(TodayCard), findsNothing);
      expect(find.byType(DailyQuestsCard), findsNothing);
      expect(leuchtet(tester), isNull);
    });

    testWidgets('ein Vorschlag legt mit einem Tipp eine Gewohnheit an', (
      tester,
    ) async {
      final c = await starte(tester);

      await tester.tap(find.text('Spazieren gehen'));
      await tester.pumpAndSettle();

      final eigene = c.read(habitTrackerProvider).customHabits;
      expect(eigene.single.name, 'Spazieren gehen');
      expect(eigene.single.stat, HabitStat.ausdauer);
      expect(c.read(habitTrackerProvider).activeIds, <String>[
        eigene.single.id,
      ]);

      // Die Frage ist beantwortet: „Heute“ steht da, mit der Gewohnheit.
      expect(find.byType(ErsteGewohnheitKarte), findsNothing);
      expect(
        find.descendant(
          of: find.byType(TodayCard),
          matching: find.text('Spazieren gehen'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('der erste Vorschlag startet die Startvorlage und kostet '
        'keinen Platz', (tester) async {
      final c = await starte(tester);

      await tester.tap(find.text(HabitCatalog.starter.name));
      await tester.pumpAndSettle();

      final tracker = c.read(habitTrackerProvider);
      expect(tracker.activeIds, <String>[HabitCatalog.starterId]);
      expect(tracker.customHabits, isEmpty);
    });

    testWidgets('etwas Eigenes: schreiben, Wert wählen, anlegen', (
      tester,
    ) async {
      final c = await starte(tester);

      // Die Wahl des Werts steht erst da, wenn etwas im Feld steht.
      expect(find.byKey(ErsteGewohnheitKarte.losKey), findsNothing);

      await tester.enterText(
        find.byKey(ErsteGewohnheitKarte.feldKey),
        'Gitarre üben',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('erste-gewohnheit-klarheit')),
      );
      await tester.pump();
      await tester.tap(find.byKey(ErsteGewohnheitKarte.losKey));
      await tester.pumpAndSettle();

      final eigene = c.read(habitTrackerProvider).customHabits.single;
      expect(eigene.name, 'Gitarre üben');
      expect(eigene.stat, HabitStat.klarheit);
      expect(find.byType(ErsteGewohnheitKarte), findsNothing);
    });

    testWidgets('ein leeres Feld legt nichts an', (tester) async {
      final c = await starte(tester);

      await tester.enterText(find.byKey(ErsteGewohnheitKarte.feldKey), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(c.read(habitTrackerProvider).customHabits, isEmpty);
      expect(find.byType(ErsteGewohnheitKarte), findsOneWidget);
    });

    testWidgets('nach dem ersten Häkchen leuchtet die Theorie (ADR-0079)', (
      tester,
    ) async {
      await starte(tester, SaveData(habits: einHaekchen));

      // Mit dem ersten Häkchen auch die Statistik (ADR-0087): Ab dann
      // gibt es einen Tag zu sehen.
      expect(aufgedeckt(tester), <String>[
        'Gewohnheiten',
        'Theorie',
        'Statistik',
      ]);
      expect(leuchtet(tester), 'Theorie');
      expect(find.byKey(HubCircle.leuchtKey), findsOneWidget);
      // Die Tagesaufgaben warten am Lagerfeuer (ADR-0076).
      expect(find.byType(LagerfeuerKarte), findsOneWidget);
    });

    testWidgets('wer schon unten war, geht mit der Waffe allein hinab', (
      tester,
    ) async {
      // Die Grube ist nie gesperrt (ADR-0068): Ist ihr Kreis einmal da,
      // geht sie ohne gelesene Seite und ohne Fähigkeit auf.
      final c = await starte(
        tester,
        SaveData(
          habits: einHaekchen,
          ladder: const LadderProgress.empty().recordDefeat(1),
        ),
      );

      // Keine Seite gelesen, keine Fähigkeit: nur der Waffenzug.
      expect(c.read(activeMovesProvider), hasLength(1));

      await tester.tap(find.text('Kampf'));
      await tester.pumpAndSettle();
      expect(find.byType(LadderScreen), findsOneWidget);

      await tester.tap(find.byKey(LadderScreen.hinabKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final grube = tester.widget<PitScreen>(find.byType(PitScreen));
      expect(grube.stage.number, 1);
    });

    testWidgets('nach einem verlorenen Lauf leuchtet die Theorie', (
      tester,
    ) async {
      await starte(
        tester,
        SaveData(
          habits: einHaekchen,
          ladder: const LadderProgress.empty().recordDefeat(1),
        ),
      );

      expect(aufgedeckt(tester), containsAll(<String>['Kampf', 'Theorie']));
      expect(aufgedeckt(tester), isNot(contains('Fähigkeiten')));
      expect(leuchtet(tester), 'Theorie');
    });

    testWidgets('ein versteckter Kreis nimmt keinen Tipp an', (tester) async {
      await starte(tester);

      await tester.tap(find.text('Laden'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(ErsteGewohnheitKarte), findsOneWidget);
    });

    testWidgets('wer überschreibt, sieht alles', (tester) async {
      // So sehen es die Tests der anderen Bereiche.
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(aufgedeckt(tester), hasLength(Bereich.values.length));
    });
  });
}
