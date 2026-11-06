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
import 'package:lifes_game/home/widgets/status_leiste.dart';
import 'package:lifes_game/haustier/widgets/haustier_karte.dart';
import 'package:lifes_game/ui/pulsieren.dart';
import 'package:lifes_game/mentor/mentor_kasten.dart';
import 'package:lifes_game/theory/skill_tree_screen.dart';
import 'package:theory/theory.dart';
import 'tutorial_helfer.dart';
import 'package:lifes_game/home/widgets/today_card.dart';
import 'package:lifes_game/lagerfeuer/widgets/lagerfeuer_karte.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';
import 'package:lifes_game/progression/widgets/gesperrt_bis_level.dart';
import 'package:lifes_game/progression/widgets/level_roadmap_blatt.dart';
import 'package:lifes_game/statistik/statistik_screen.dart';
import 'nachladen.dart';

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

    test('nur der Mentor bis zum ersten Häkchen, dann alles (06.11.2026)', () {
      ErsterStart mit({bool gewohnheit = false, int haekchen = 0}) =>
          ErsterStart.aus(
            ErsterStartStand(
              hatGewohnheit: gewohnheit,
              haekchen: haekchen,
              billigstesStueck: billig,
            ),
          );

      expect(mit().nurMentor, isTrue);
      expect(mit(gewohnheit: true).nurMentor, isTrue);
      expect(mit(gewohnheit: true, haekchen: 1).nurMentor, isFalse);
      expect(ErsterStart.allesOffen.nurMentor, isFalse);
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
      // Erst zeigt der Mentor, wo die Gewohnheiten wohnen (06.11.2026).
      expect(start.schritt, Schritt.gewohnheitenZeigen);
      expect(start.leuchtet, Bereich.gewohnheiten);
      expect(start.zeigtWenig, isTrue);
      // Das Lagerfeuer wartet seit ADR-0098 auf Level 3.
      expect(start.zeigtTagesaufgaben, isFalse);

      // Weggetippt, schickt er in die Theorie.
      final danach = ErsterStart.aus(
        const ErsterStartStand(
          hatGewohnheit: true,
          haekchen: 1,
          billigstesStueck: billig,
          gewohnheitenGezeigt: true,
          talentpunktGezeigt: true,
        ),
      );
      expect(danach.schritt, Schritt.ersteSeite);

      // Dazwischen: der Talentpunkt, beim ersten Öffnen der Theorie.
      final dazwischen = ErsterStart.aus(
        const ErsterStartStand(
          hatGewohnheit: true,
          haekchen: 1,
          billigstesStueck: billig,
          gewohnheitenGezeigt: true,
        ),
      );
      expect(dazwischen.schritt, Schritt.talentpunkt);
      expect(dazwischen.leuchtet, Bereich.theorie);
      expect(dazwischen.zeigtWenig, isTrue);
      expect(danach.leuchtet, Bereich.theorie);
      expect(danach.zeigtWenig, isTrue, reason: 'bis zur ersten Seite');
    });

    test('wer schon gelesen hat, hört den Hinweis nicht', () {
      final start = ErsterStart.aus(
        const ErsterStartStand(
          hatGewohnheit: true,
          haekchen: 1,
          seiten: 1,
          billigstesStueck: billig,
        ),
      );
      expect(start.schritt, Schritt.faehigkeitAnlegen);
      expect(start.zeigtWenig, isFalse);
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

    test('nach dem ersten Sieg erklärt er die Gebiete (Issue #183)', () {
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
          gewohnheitenJe: 1,
        ),
      );

      expect(start.schritt, Schritt.gebiete);
      expect(start.leuchtet, Bereich.gewohnheiten);
    });

    test('mit der zweiten Gewohnheit ist der Weg gegangen', () {
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
          gewohnheitenJe: 2,
        ),
      );

      expect(start.schritt, isNull);
      expect(start.leuchtet, isNull);
    });

    test('vor dem Sieg erklärt er die Gebiete nicht, auch mit zweien', () {
      final start = ErsterStart.aus(
        const ErsterStartStand(
          hatGewohnheit: true,
          haekchen: 1,
          seiten: 1,
          gelernt: 1,
          angelegt: 1,
          level: 2,
          billigstesStueck: billig,
          gewohnheitenJe: 2,
        ),
      );

      expect(start.schritt, Schritt.grube);
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
          gewohnheitenGezeigt: true,
          talentpunktGezeigt: true,
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
          gewohnheitenGezeigt: true,
          talentpunktGezeigt: true,
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
          gewohnheitenJe: 2,
        ),
        // Die Statistik wartet seit ADR-0098 auf Level 7.
        ErsterStartStand(
          hatGewohnheit: true,
          haekchen: 20,
          hatGekaempft: true,
          stufenGeschafft: 3,
          seiten: 8,
          grundlagenGelesen: true,
          gelernt: 2,
          angelegt: 2,
          goldVerdient: 400,
          jeBesessen: 2,
          level: 7,
          billigstesStueck: billig,
          gewohnheitenJe: 2,
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
      bool hinweisWeg = false,
    ]) async {
      useTallView(tester);
      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(stand),
          todayProvider.overrideWithValue(heute),
          if (hinweisWeg) hinweisGesehen,
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

    /// Die Namen der Kreise, die zu sehen sind — auch wenn gerade nur
    /// die Weiter-Fläche des Mentors Tipps annimmt.
    List<String> zuSehen(WidgetTester tester) => <String>[
      for (final element in find.byType(Aufgedeckt).evaluate())
        if ((element.widget as Aufgedeckt).sichtbar)
          for (final kreis in tester.widgetList<HubCircle>(
            find.descendant(
              of: find.byWidget(element.widget),
              matching: find.byType(HubCircle),
            ),
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

    testWidgets('der erste Start zeigt nur den Mentor und die Frage', (
      tester,
    ) async {
      await starte(tester);

      // Keine Leiste, kein Level, kein Gold (06.11.2026).
      expect(aufgedeckt(tester), isEmpty);
      expect(find.byKey(StatusLeiste.ringKey).hitTestable(), findsNothing);
      expect(find.byType(ErsteGewohnheitKarte), findsOneWidget);
      // Die Frage stellt nur noch der Mentor, nicht auch die Karte
      // (Issue #183).
      expect(find.text('Was willst du jeden Tag tun?'), findsNothing);
      expect(find.text('Willkommen! Was willst du jeden Tag tun?'), findsOne);
      expect(find.byType(TodayCard), findsNothing);
      expect(find.byType(DailyQuestsCard), findsNothing);
      expect(leuchtet(tester), isNull);
    });

    testWidgets('erst der Mentor, dann fliegen die Zeilen nacheinander '
        'herein (Issue #183)', (tester) async {
      useTallView(tester);
      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(const SaveData.empty()),
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

      double sichtbar(Finder zeile) => tester
          .widget<Opacity>(
            find.ancestor(of: zeile, matching: find.byType(Opacity)).first,
          )
          .opacity;

      final erste = find.text(ErsteGewohnheitKarte.vorschlaege.first.name);
      final eigenes = find.byKey(ErsteGewohnheitKarte.eigenesKey);

      await tester.pump();
      expect(sichtbar(erste), 0);
      expect(sichtbar(eigenes), 0);

      // Die erste ist da, bevor die letzte losfliegt.
      await tester.pump(
        ErsteGewohnheitKarte.warten + ErsteGewohnheitKarte.flug,
      );
      expect(sichtbar(erste), 1);
      expect(sichtbar(eigenes), lessThan(1));

      await tester.pumpAndSettle();
      expect(sichtbar(eigenes), 1);
    });

    testWidgets('ein Vorschlag legt mit einem Tipp eine Gewohnheit an', (
      tester,
    ) async {
      final c = await starte(tester);

      await tester.tap(find.text('Spazieren gehen'));
      await tester.pumpAndSettle();

      final eigene = c.read(habitTrackerProvider).customHabits;
      expect(eigene.single.name, 'Spazieren gehen');
      expect(eigene.single.area, SkillArea.koerper);
      expect(eigene.single.stat, HabitStat.staerke);
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

    testWidgets('etwas Eigenes: Name, Weiter, ein Tipp aufs Gebiet legt an', (
      tester,
    ) async {
      final c = await starte(tester);

      // Das Feld kommt erst mit einem Tipp auf „Etwas Eigenes“, die
      // Frage nach dem Gebiet erst nach „Weiter“.
      expect(find.byKey(ErsteGewohnheitKarte.feldKey), findsNothing);
      await tester.tap(find.byKey(ErsteGewohnheitKarte.eigenesKey));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(ErsteGewohnheitKarte.weiterKey))
            .onPressed,
        isNull,
      );

      await tester.enterText(
        find.byKey(ErsteGewohnheitKarte.feldKey),
        'Gitarre üben',
      );
      await tester.pump();
      await tester.tap(find.byKey(ErsteGewohnheitKarte.weiterKey));
      await tester.pumpAndSettle();

      expect(
        find.text(ErsteGewohnheitKarte.gebietFrageFuer('Gitarre üben')),
        findsOneWidget,
      );
      // Jedes Gebiet mit Beispielen, die man ohne das Spiel versteht.
      for (final area in SkillArea.values) {
        expect(find.text(area.label), findsOneWidget);
        expect(
          find.text(ErsteGewohnheitKarte.beispiele[area]!),
          findsOneWidget,
        );
      }
      expect(c.read(habitTrackerProvider).customHabits, isEmpty);

      await tester.tap(
        find.byKey(ErsteGewohnheitKarte.gebietKey(SkillArea.geist)),
      );
      await tester.pumpAndSettle();

      final eigene = c.read(habitTrackerProvider).customHabits.single;
      expect(eigene.name, 'Gitarre üben');
      expect(eigene.area, SkillArea.geist);
      expect(eigene.stat, HabitStat.klarheit);
      expect(find.byType(ErsteGewohnheitKarte), findsNothing);
      // Leiste und Level warten noch auf das erste Häkchen (Screen 2).
      expect(aufgedeckt(tester), isEmpty);
    });

    testWidgets('von der Frage nach dem Gebiet zurück zum Namen', (
      tester,
    ) async {
      final c = await starte(tester);

      await tester.tap(find.byKey(ErsteGewohnheitKarte.eigenesKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(ErsteGewohnheitKarte.feldKey), 'Ab');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      expect(
        find.text(ErsteGewohnheitKarte.gebietFrageFuer('Ab')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(ErsteGewohnheitKarte.zurueckKey));
      await tester.pumpAndSettle();
      expect(find.byKey(ErsteGewohnheitKarte.feldKey), findsOneWidget);
      expect(find.text('Ab'), findsOneWidget);
      expect(c.read(habitTrackerProvider).customHabits, isEmpty);
    });

    testWidgets('ein Name von 60 Zeichen sprengt am Handy nichts', (
      tester,
    ) async {
      final c = await starte(tester);
      // Am Handy, nicht im hohen Testfenster.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      await tester.pumpAndSettle();

      final lang = 'Jeden Morgen vor der Arbeit zwanzig Minuten Spanisch üben';
      expect(lang.length, lessThanOrEqualTo(60));
      await tester.tap(find.byKey(ErsteGewohnheitKarte.eigenesKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(ErsteGewohnheitKarte.feldKey), lang);
      await tester.pump();
      await tester.tap(find.byKey(ErsteGewohnheitKarte.weiterKey));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Jede Kachel steht ganz im Bild und nimmt den Tipp.
      for (final area in SkillArea.values) {
        expect(
          find.byKey(ErsteGewohnheitKarte.gebietKey(area)).hitTestable(),
          findsOneWidget,
        );
      }
      await tester.tap(
        find.byKey(ErsteGewohnheitKarte.gebietKey(SkillArea.wissenschaft)),
      );
      await tester.pumpAndSettle();
      expect(c.read(habitTrackerProvider).customHabits.single.name, lang);
    });

    testWidgets('beim Eigenen verschwinden die Vorschläge, zurück kommen '
        'sie wieder', (tester) async {
      await starte(tester);
      final erster = find.text(ErsteGewohnheitKarte.vorschlaege.first.name);

      await tester.tap(find.byKey(ErsteGewohnheitKarte.eigenesKey));
      await tester.pumpAndSettle();
      expect(erster, findsNothing);

      await tester.enterText(find.byKey(ErsteGewohnheitKarte.feldKey), 'Ab');
      await tester.pump();
      await tester.tap(find.byKey(ErsteGewohnheitKarte.weiterKey));
      await tester.pumpAndSettle();
      expect(erster, findsNothing);

      await tester.tap(find.byKey(ErsteGewohnheitKarte.zurueckKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ErsteGewohnheitKarte.zurAuswahlKey));
      await tester.pumpAndSettle();
      expect(erster, findsOneWidget);
      expect(find.byKey(ErsteGewohnheitKarte.eigenesKey), findsOneWidget);
    });

    testWidgets('ein leeres Feld legt nichts an', (tester) async {
      final c = await starte(tester);

      await tester.tap(find.byKey(ErsteGewohnheitKarte.eigenesKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(ErsteGewohnheitKarte.feldKey), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(c.read(habitTrackerProvider).customHabits, isEmpty);
      expect(find.byType(ErsteGewohnheitKarte), findsOneWidget);
    });

    testWidgets('die Bühne: hinter Flamme und Errungenschaft bleibt alles, '
        'wie es war, danach kommt der neue Schritt (06.11.2026)', (
      tester,
    ) async {
      await starte(tester);
      await tester.tap(find.text('Spazieren gehen'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Spazieren gehen'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      // Die große Flamme steht: Darunter ist noch Screen 2.
      expect(find.text('Geschafft? Hak es ab!'), findsOneWidget);
      expect(zuSehen(tester), isNot(contains('Theorie')));

      await tester.pumpAndSettle();
      // Jetzt die Errungenschaft, und darunter noch immer Screen 2.
      expect(find.text('Geschafft? Hak es ab!'), findsOneWidget);

      await feiernSchliessen(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('Hier findest du alle Gewohnheiten, auch neue.'),
        findsOneWidget,
      );
      expect(zuSehen(tester), contains('Theorie'));
    });

    testWidgets('Screen 2: nur Mentor und Tafel, der Zettel pulsiert bis '
        'zum Häkchen', (tester) async {
      // Ohne Timer: Ein Tipp hakt ab (die Startvorlage öffnete ihn).
      final c = await starte(tester);
      await tester.tap(find.text('Spazieren gehen'));
      await tester.pumpAndSettle();
      final id = c.read(habitTrackerProvider).customHabits.single.id;
      final puls = find.byKey(TodayCard.pulsKey(id));
      bool pulsiert() => tester.widget<Pulsieren>(puls).aktiv;

      expect(aufgedeckt(tester), isEmpty);
      expect(find.byKey(StatusLeiste.ringKey).hitTestable(), findsNothing);
      expect(find.byType(HaustierKarte), findsNothing);
      expect(find.byType(LagerfeuerKarte), findsNothing);
      expect(find.text('Geschafft? Hak es ab!'), findsOneWidget);
      expect(pulsiert(), isTrue);

      await tester.tap(find.text('Spazieren gehen'));
      await tester.pumpAndSettle();
      // Die große Flamme und die Feier liegen darüber.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(c.read(habitTrackerProvider).isChecked(id, heute), isTrue);
      expect(pulsiert(), isFalse);
      expect(zuSehen(tester), contains('Theorie'));
      // Level und Gold warten bis nach der ersten Seite (06.11.2026).
      expect(find.byKey(StatusLeiste.ringKey).hitTestable(), findsNothing);
    });

    testWidgets('nach dem ersten Häkchen zeigt er auf die Gewohnheiten, '
        'ein Tipp irgendwohin schickt in die Theorie', (tester) async {
      await starte(tester, SaveData(habits: einHaekchen));

      expect(zuSehen(tester), <String>['Gewohnheiten', 'Theorie']);
      // Bis zum Tipp nimmt nur die Fläche des Mentors einen an.
      expect(aufgedeckt(tester), isEmpty);
      expect(leuchtet(tester), 'Gewohnheiten');
      expect(
        find.text('Hier findest du alle Gewohnheiten, auch neue.'),
        findsOneWidget,
      );
      expect(find.byKey(WeiterZeichen.zeichenKey), findsOneWidget);
      // Nur, was man kennt: kein Ei, kein Feuer, keine Statistik, kein Level.
      expect(find.byType(LagerfeuerKarte), findsNothing);
      expect(find.byType(HaustierKarte), findsNothing);
      expect(find.byKey(StatusLeiste.ringKey).hitTestable(), findsNothing);

      // Ein Tipp mitten auf die Tafel hakt nichts ab, er führt weiter.
      await tester.tap(find.byType(TodayCard));
      await tester.pumpAndSettle();
      expect(find.text('Lies deine erste Seite.'), findsOneWidget);
      expect(find.byKey(WeiterZeichen.zeichenKey), findsNothing);
      expect(leuchtet(tester), 'Theorie');
      expect(aufgedeckt(tester), <String>['Gewohnheiten', 'Theorie']);
      expect(find.byType(LagerfeuerKarte), findsNothing);

      // Jetzt nehmen die Kreise ihre Tipps wieder an.
      await tester.tap(find.byKey(HubCircle.keyFor('Theorie')));
      await tester.pumpAndSettle();
      expect(find.byType(SkillTreeScreen), findsOneWidget);
    });

    testWidgets('nach der ersten Seite stehen Ei, Feuer und Statistik mit '
        'Schloss da (ADR-0098)', (tester) async {
      var theorie = const TheoryProgress.empty();
      final seite = habitsBranch.lessons.first;
      theorie = theorie.submit(seite, <int?>[
        for (final frage in seite.questions) frage.correctIndex,
      ]).progress;
      await starte(tester, SaveData(habits: einHaekchen, theory: theorie));

      // Die Statistik kommt mit dem ersten Häkchen, offen ist sie aber
      // erst auf Level 7 — bis dahin mit Schloss, wie das Lagerfeuer bis
      // Level 3 (ADR-0098).
      // Die Statistik steht gesperrt neben den offenen Kreisen.
      expect(
        aufgedeckt(tester),
        containsAll(<String>['Gewohnheiten', 'Theorie', 'Fähigkeiten']),
      );
      expect(find.byKey(HubCircle.keyFor('Statistik')), findsWidgets);
      expect(find.byKey(HubCircle.leuchtKey), findsOneWidget);
      expect(find.byType(LagerfeuerKarte), findsOneWidget);
      // Statistik, Lagerfeuer und das Ei des Haustiers (Level 5).
      expect(find.byKey(GesperrtBisLevel.schlossKey), findsNWidgets(3));

      // Ein Tipp auf die gesperrte Statistik zeigt die Roadmap, nicht die
      // Statistik.
      await tester.tap(find.byKey(HubCircle.keyFor('Statistik')).first);
      await tester.pumpAndSettle();
      expect(find.byType(LevelRoadmapBlatt), findsOneWidget);
      expect(find.byType(StatistikScreen), findsNothing);
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
        true,
      );

      // Keine Seite gelesen, keine Fähigkeit: nur der Waffenzug.
      expect(c.read(activeMovesProvider), hasLength(1));

      await tester.tap(find.byKey(HubCircle.keyFor('Kampf')));
      await tester.pumpAndSettle();
      expect(find.byType(LadderScreen), findsOneWidget);

      await tester.tap(find.byKey(LadderScreen.hinabKey));
      await nachgeladen(tester);

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
        true,
      );

      expect(aufgedeckt(tester), containsAll(<String>['Kampf', 'Theorie']));
      expect(aufgedeckt(tester), isNot(contains('Fähigkeiten')));
      expect(leuchtet(tester), 'Theorie');
    });

    testWidgets('ein versteckter Kreis nimmt keinen Tipp an', (tester) async {
      await starte(tester);

      await tester.tap(
        find.byKey(HubCircle.keyFor('Laden')),
        warnIfMissed: false,
      );
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
