import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/character/abilities_screen.dart';
import 'package:lifes_game/character/character_screen.dart';
import 'package:lifes_game/gear/equipment_screen.dart';
import 'package:lifes_game/combat/ladder_screen.dart';
import 'package:lifes_game/gear/shop_screen.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/gear/widgets/character_figure.dart';
import 'package:lifes_game/home/widgets/status_leiste.dart';
import 'package:lifes_game/ui/holz.dart';
import 'package:lifes_game/ui/level_abzeichen.dart';
import 'package:lifes_game/home/widgets/hub_circle.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/ui/gold_icon.dart';
import 'package:lifes_game/ui/pixel_art.dart';
import 'package:abilities/abilities.dart';
import 'package:progression/progression.dart';
import 'package:theory/theory.dart';
import 'package:lifes_game/main.dart';
import 'package:lifes_game/theory/skill_tree_screen.dart';

import 'test_view.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('zeigt alle Bereiche des Konzepts', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
          ],
          child: const LifesGameApp(),
        ),
      );
      await tester.pump();

      for (final title in <String>[
        'Gewohnheiten',
        'Theorie',
        'Kampf',
        'Laden',
        'Fähigkeiten',
        'Ausrüstung',
        'Charakter',
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
    });

    testWidgets('kein Kreis ist gesperrt, auch der Kampf nicht', (
      tester,
    ) async {
      // **Bis ADR-0068 war der Kampf zu**, solange keine Fähigkeit auf
      // einem Platz lag (ADR-0020). Stufe 1 ist mit der Waffe allein
      // schlagbar; die Sperre trug nur noch die Kette Handbuch → Baum →
      // Kampf, und die hält jetzt das Aufdecken der Kreise.
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      // Der Entwicklermodus ist seit Issue #35 kein Bereich mehr,
      // sondern ein kleiner Knopf daneben (ADR-0021: er gehört nicht zum
      // Spiel). Die Kreise sind damit genau die Bereiche — sieben, seit
      // Fähigkeiten und Ausrüstung eigene haben (ADR-0049, ADR-0057).
      final kreise = tester
          .widgetList<HubCircle>(find.byType(HubCircle))
          .toList();

      expect(kreise, hasLength(7));
      expect(kreise.where((k) => k.isLocked), isEmpty);
    });

    testWidgets('das Handbuch sperrt den Kampf nicht mehr (ADR-0025)', (
      tester,
    ) async {
      // Der Gegenbeweis zur alten Sperre: Ein Stand **ohne** Handbuch,
      // aber mit zwei Moves, darf kämpfen. Bis ADR-0025 war das
      // ausgeschlossen -- und zwar aus einem Grund, der nie der echte
      // war (ADR-0020, abgelöst durch ADR-0068).
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedGameProvider.overrideWithValue(_ohneHandbuchAberMitMoves()),
          ],
          child: const LifesGameApp(),
        ),
      );
      await tester.pump();

      final kreise = tester.widgetList<HubCircle>(find.byType(HubCircle));

      expect(kreise.where((k) => k.isLocked), isEmpty);
    });

    testWidgets('mit durchgearbeitetem Handbuch geht der Kampf auf', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [savedGameProvider.overrideWithValue(_kampfbereit())],
          child: const LifesGameApp(),
        ),
      );
      await tester.pump();

      final kreise = tester.widgetList<HubCircle>(find.byType(HubCircle));

      expect(kreise.where((k) => k.isLocked), isEmpty);
    });
    testWidgets('Gewohnheiten führt zum Tracker', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      await tester.tap(find.text('Gewohnheiten'));
      await tester.pumpAndSettle();

      expect(find.byType(HabitsScreen), findsOneWidget);
    });

    testWidgets('Theorie führt zum Skillbaum', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
          ],
          child: const LifesGameApp(),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Theorie'));
      await tester.pumpAndSettle();

      expect(find.byType(SkillTreeScreen), findsOneWidget);
    });

    testWidgets('Kampf führt zur Gegnerwahl, sobald er offen ist', (
      tester,
    ) async {
      // Braucht seit ADR-0018 das durchgearbeitete Handbuch. Ohne
      // Vorbedingung wäre die Kachel gesperrt und der Tipp ginge ins
      // Leere.
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [savedGameProvider.overrideWithValue(_kampfbereit())],
          child: const LifesGameApp(),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Kampf'));
      await tester.pumpAndSettle();

      expect(find.byType(LadderScreen), findsOneWidget);
    });

    testWidgets('ohne Fähigkeit steht der Kampf offen (ADR-0068)', (
      tester,
    ) async {
      // Der Gegenbeweis zu ADR-0020: Handbuch gelesen, nichts gelernt,
      // nichts angelegt — und die Grube geht trotzdem auf.
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedGameProvider.overrideWithValue(
              SaveData(theory: _mitHandbuch()),
            ),
          ],
          child: const LifesGameApp(),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Kampf'));
      await tester.pumpAndSettle();

      expect(find.byType(LadderScreen), findsOneWidget);
    });

    testWidgets('vor dem ersten Häkchen gibt es keinen Kampf', (tester) async {
      // Der Kreis steht an seinem Platz, ist aber noch nicht aufgedeckt:
      // Ein Tipp dorthin geht ins Leere (ADR-0068).
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      await tester.tap(find.text('Kampf'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(LadderScreen), findsNothing);
    });

    testWidgets('Laden führt zum Shop', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
          ],
          child: const LifesGameApp(),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Laden'));
      await tester.pumpAndSettle();

      expect(find.byType(ShopScreen), findsOneWidget);
    });

    testWidgets('Fähigkeiten führt zum eigenen Bildschirm', (tester) async {
      // **Nie gesperrt** (ADR-0049), obwohl auf Level 1 nur der
      // Waffenplatz offen ist: Der Bildschirm zeigt vor allem, was es zu
      // holen gibt — und das ist genau dann nützlich, wenn man noch
      // nichts hat.
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
          ],
          child: const LifesGameApp(),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Fähigkeiten'));
      await tester.pumpAndSettle();

      expect(find.byType(AbilitiesScreen), findsOneWidget);
    });

    testWidgets('der Kreis trägt den Stern, und er ist abgelegt', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      final stern = find.byWidgetPredicate(
        (w) => w is PixelArt && w.assetPath == HomeScreen.abilitySymbol,
      );
      expect(
        tester
            .widget<HubCircle>(
              find.ancestor(of: stern, matching: find.byType(HubCircle)),
            )
            .label,
        'Fähigkeiten',
      );

      final daten = await rootBundle.load(HomeScreen.abilitySymbol);
      expect(daten.lengthInBytes, greaterThan(100));
    });

    testWidgets('Ausrüstung führt zum eigenen Bildschirm', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
          ],
          child: const LifesGameApp(),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Ausrüstung'));
      await tester.pumpAndSettle();

      expect(find.byType(EquipmentScreen), findsOneWidget);
    });

    testWidgets('der Kreis trägt den Harnisch, und er ist abgelegt', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      final harnisch = find.byWidgetPredicate(
        (w) => w is PixelArt && w.assetPath == HomeScreen.gearSymbol,
      );
      expect(
        tester
            .widget<HubCircle>(
              find.ancestor(of: harnisch, matching: find.byType(HubCircle)),
            )
            .label,
        'Ausrüstung',
      );

      final daten = await rootBundle.load(HomeScreen.gearSymbol);
      expect(daten.lengthInBytes, greaterThan(100));
    });

    testWidgets('unten stehen vier kleinere Kreise', (tester) async {
      // **Vier passen nur kleiner** (ADR-0057): Bei 72 Punkten bräuchten
      // sie mit Namen 352 Punkte, ein Handy hat nach dem Rand 335.
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      final unten = tester
          .widgetList<HubCircle>(find.byType(HubCircle))
          .where((k) => k.size == HomeScreen.bottomCircleSize)
          .map((k) => k.label)
          .toList();
      expect(unten, <String>[
        'Laden',
        'Fähigkeiten',
        'Ausrüstung',
        'Charakter',
      ]);
      expect(4 * (HomeScreen.bottomCircleSize + 16), lessThanOrEqualTo(335));
    });

    testWidgets('Charakter führt zum Charakterbildschirm', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
          ],
          child: const LifesGameApp(),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Charakter'));
      await tester.pumpAndSettle();

      expect(find.byType(CharacterScreen), findsOneWidget);
    });

    testWidgets('die Figur ist wirklich abgelegt', (tester) async {
      // **Dieselbe Naht wie bei `move_icon_test.dart`.** `rootBundle`
      // findet nur, was in `pubspec.yaml` unter `assets:` steht — der
      // Test prueft damit Datei **und** Anmeldung in einem Zug. Ohne ihn
      // faellt ein vergessener Eintrag erst im Browser auf, und dann als
      // Platzhalter, den `CharacterFigure` absichtlich still zeigt.
      final daten = await rootBundle.load(CharacterFigure.assetPath);

      expect(daten.lengthInBytes, greaterThan(1000));
    });

    testWidgets('jede gezeichnete Knopffläche ist wirklich abgelegt', (
      tester,
    ) async {
      // Dieselbe Naht wie eine Zeile darüber: Datei **und** Anmeldung in
      // `pubspec.yaml`. Fehlt eine, faellt `HubCircle` still auf den
      // schlichten Kreis zurueck — der Startbildschirm sieht dann aus wie
      // vorher, und niemand merkt, dass eine Zeichnung fehlt.
      for (final bild in HubCircleImage.values) {
        final daten = await rootBundle.load(bild.assetPath);

        expect(
          daten.lengthInBytes,
          greaterThan(1000),
          reason: '${bild.assetPath} ist verdaechtig klein.',
        );
      }
    });

    testWidgets('die Theorie trägt das Buch, und es ist abgelegt', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      final buch = find.byWidgetPredicate(
        (w) => w is PixelArt && w.assetPath == HomeScreen.theorySymbol,
      );
      expect(
        find.ancestor(of: buch, matching: find.byType(HubCircle)),
        findsOneWidget,
      );
      expect(
        tester
            .widget<HubCircle>(
              find.ancestor(of: buch, matching: find.byType(HubCircle)),
            )
            .label,
        'Theorie',
      );

      final daten = await rootBundle.load(HomeScreen.theorySymbol);
      expect(daten.lengthInBytes, greaterThan(1000));
    });

    testWidgets('die Goldmünze ebenfalls', (tester) async {
      final daten = await rootBundle.load(GoldIcon.assetPath);

      expect(daten.lengthInBytes, greaterThan(1000));
    });

    testWidgets('nur der Charakterkreis bringt sein Zeichen selbst mit', (
      tester,
    ) async {
      // Waere das bei `plain` ebenfalls gesetzt, stuenden vier Kreise
      // leer da — die Flaeche allein sagt nicht, wohin sie fuehrt.
      final selbsttragend = HubCircleImage.values
          .where((bild) => bild.carriesIcon)
          .toList();

      expect(selbsttragend, <HubCircleImage>[HubCircleImage.character]);
    });

    testWidgets('der Charakter startet auf Level 1 ohne Gold', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      // Das Level steht als Zahl im Abzeichen, das Gold neben der
      // Münze — beide ohne Wort davor oder dahinter (Frederik, 28.09.).
      final abzeichen = find.byType(LevelAbzeichen);
      expect(abzeichen, findsOneWidget);
      expect(
        find.descendant(of: abzeichen, matching: find.text('1')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(StatusLeiste),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Gold'), findsNothing);
    });

    testWidgets('der Satz zur Erfahrung kommt erst auf Tipp', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      const satz = '0 von 100 Erfahrung bis Level 2';
      expect(find.text(satz), findsNothing);

      await tester.tap(find.byType(HolzBalken));
      await tester.pumpAndSettle();
      expect(find.text(satz), findsOneWidget);

      await tester.tap(find.byType(HolzBalken));
      await tester.pumpAndSettle();
      expect(find.text(satz), findsNothing);
    });

    testWidgets('die Figur steht nicht mehr auf der Startseite', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      expect(find.byType(CharacterFigure), findsNothing);
    });
  });
}

/// Ein Theoriestand, in dem das Handbuch durchgearbeitet ist.
///
/// **Die Zahl dahinter ist der Grund für ADR-0018:** Die fünf Lektionen
/// geben zusammen 275 Erfahrung und damit Level 3 — genau die Stufe, auf
/// der der zweite Fähigkeitsslot aufgeht. Vier Lektionen wären 220 und
/// damit fünf Punkte zu wenig.
TheoryProgress _mitHandbuch() {
  var progress = const TheoryProgress.empty();
  for (final lesson in habitsBranch.lessons) {
    progress = progress.submit(lesson, <int?>[
      for (final question in lesson.questions) question.correctIndex,
    ]).progress;
  }
  return progress;
}

/// Der Knoten, der die erste Fähigkeit bringt.
final TheoryNode _ersterFaehigkeitsknoten = theoryGraph.nodes.firstWhere(
  (n) => n.unlocksAbility != null,
);

/// Ein Stand, der den Kampf tatsächlich öffnet.
///
/// **Seit ADR-0020 sind es drei Schritte, nicht einer.** Das Handbuch
/// öffnet den zweiten Platz, ein Theorieknoten liefert die Fähigkeit,
/// und gelegt werden muss sie auch noch. Vorher genügte das Handbuch,
/// weil vier Fähigkeiten von Anfang an offen waren.
SaveData _kampfbereit() {
  var progress = _mitHandbuch();
  final lesson = _ersterFaehigkeitsknoten.lesson;
  progress = progress.submit(lesson, <int?>[
    for (final question in lesson.questions) question.correctIndex,
  ]).progress;

  return SaveData(
    theory: progress,
    abilities: const ChosenAbilities.empty().withAt(
      0,
      _ersterFaehigkeitsknotenMoveId,
    ),
  );
}

/// Ein Stand **ohne** Handbuch, aber mit zwei Moves.
///
/// Konstruiert und nicht erspielbar -- genau das ist der Punkt: Er
/// trennt die beiden Bedingungen, die bis ADR-0025 zusammen auftraten,
/// und weist nach, dass nur noch eine von beiden zählt.
///
/// Erfahrung kommt hier aus **Graphseiten** statt aus dem Handbuch,
/// weil der zweite Fähigkeitsplatz Level 3 braucht. Gelesen wird bis
/// dorthin und keine Seite weiter -- eine feste Zahl würde still falsch,
/// sobald jemand an `TheoryRewards` oder der Levelkurve dreht.
SaveData _ohneHandbuchAberMitMoves() {
  var progress = const TheoryProgress.empty();

  List<int?> richtig(Lesson lesson) => <int?>[
    for (final question in lesson.questions) question.correctIndex,
  ];

  progress = progress
      .submit(
        _ersterFaehigkeitsknoten.lesson,
        richtig(_ersterFaehigkeitsknoten.lesson),
      )
      .progress;

  for (final node in theoryGraph.nodes) {
    if (LevelCurve.levelFor(progress.totalXp).level >= 3) break;
    if (node.id == _ersterFaehigkeitsknoten.id) continue;
    progress = progress.submit(node.lesson, richtig(node.lesson)).progress;
  }

  return SaveData(
    theory: progress,
    abilities: const ChosenAbilities.empty().withAt(
      0,
      _ersterFaehigkeitsknotenMoveId,
    ),
  );
}

final String _ersterFaehigkeitsknotenMoveId =
    _ersterFaehigkeitsknoten.unlocksAbility!;
