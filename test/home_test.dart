import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/character/character_screen.dart';
import 'package:lifes_game/combat/enemy_picker_screen.dart';
import 'package:lifes_game/gear/shop_screen.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/home/widgets/hub_tile.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/theory/theory_controller.dart';
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
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      for (final title in <String>[
        'Gewohnheiten',
        'Theorie',
        'Kampf',
        'Laden',
        'Charakter',
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
    });

    testWidgets('nur der Kampf ist zu Beginn gesperrt', (tester) async {
      // Der Startbildschirm hatte lange gesperrte Kacheln, damit
      // sichtbar blieb, wohin es geht. Seit ADR-0018 ist genau eine
      // wieder zu: Mit nur einem Move ist der erste Kampf nicht knapp,
      // sondern unmöglich.
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      // Tests laufen im Debug-Build, deshalb ist die Dev-Kachel hier
      // sichtbar (ADR-0021). Sie gehört nicht zum Spiel und wird für die
      // Zählung herausgenommen — im Release-Build gibt es sie nicht.
      final tiles = tester
          .widgetList<HubTile>(find.byType(HubTile))
          .where((t) => t.title != 'Entwicklermodus')
          .toList();
      final locked = tiles
          .where((t) => t.onTap == null)
          .map((t) => t.title)
          .toList();

      expect(tiles, hasLength(5));
      expect(locked, <String>['Kampf']);
    });

    testWidgets('die gesperrte Kachel nennt den Weg, nicht die Absage', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      // **Seit ADR-0025 nennt sie nicht mehr das Handbuch.** Der Kampf
      // hängt nur noch am Moveset; das Handbuch sperrt den Baum. Die
      // Kette ist dieselbe, sie steht nur nicht mehr zweimal da.
      expect(find.textContaining('Erst eine Fähigkeit lernen'), findsOneWidget);
      expect(find.textContaining('Erst das Handbuch'), findsNothing);
    });

    testWidgets('das Handbuch sperrt den Kampf nicht mehr (ADR-0025)', (
      tester,
    ) async {
      // Der Gegenbeweis zur alten Sperre: Ein Stand **ohne** Handbuch,
      // aber mit zwei Moves, darf kämpfen. Bis ADR-0025 war das
      // ausgeschlossen -- und zwar aus einem Grund, der nie der echte
      // war (siehe `combatUnlockedProvider`).
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

      final tiles = tester.widgetList<HubTile>(find.byType(HubTile));

      expect(tiles.where((t) => t.onTap == null), isEmpty);
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

      final tiles = tester.widgetList<HubTile>(find.byType(HubTile));
      final locked = tiles.where((t) => t.onTap == null);

      expect(locked, isEmpty);
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
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
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

      expect(find.byType(EnemyPickerScreen), findsOneWidget);
    });

    testWidgets('ohne Fähigkeit bleibt der Kampf zu (ADR-0020)', (
      tester,
    ) async {
      // **Der Grund für diesen Test.** Bis ADR-0019 waren vier
      // Fähigkeiten von Anfang an offen — das Handbuch öffnete den
      // zweiten Platz, und es passte immer etwas hinein. Seit sie an
      // Knoten hängen, kann der Platz aufgehen und leer bleiben. Dann
      // stünde der Spieler mit einem Move vor einem Gegner, den die
      // Simulation bei 0 % ausweist (ADR-0018).
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

      final tiles = tester.widgetList<HubTile>(find.byType(HubTile));
      final locked = tiles
          .where((t) => t.onTap == null)
          .map((t) => t.title)
          .toList();

      expect(locked, <String>['Kampf']);
      expect(find.textContaining('Erst eine Fähigkeit lernen'), findsOneWidget);
    });

    testWidgets('gelernt, aber nicht angelegt nennt den anderen Weg', (
      tester,
    ) async {
      // Wer die Fähigkeit hat, sie aber auf keinem Platz liegen hat,
      // darf nicht in die Theorie zurückgeschickt werden — dort ist
      // nichts mehr zu tun.
      useTallView(tester);

      var progress = _mitHandbuch();
      final lesson = _ersterFaehigkeitsknoten.lesson;
      progress = progress.submit(lesson, <int?>[
        for (final question in lesson.questions) question.correctIndex,
      ]).progress;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedGameProvider.overrideWithValue(SaveData(theory: progress)),
          ],
          child: const LifesGameApp(),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Leg eine Fähigkeit'), findsOneWidget);
    });

    testWidgets('ein gesperrter Kampf führt nirgendwohin', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      await tester.tap(find.text('Kampf'));
      await tester.pumpAndSettle();

      expect(find.byType(EnemyPickerScreen), findsNothing);
    });

    testWidgets('Laden führt zum Shop', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      await tester.tap(find.text('Laden'));
      await tester.pumpAndSettle();

      expect(find.byType(ShopScreen), findsOneWidget);
    });

    testWidgets('Charakter führt zum Charakterbildschirm', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      await tester.tap(find.text('Charakter'));
      await tester.pumpAndSettle();

      expect(find.byType(CharacterScreen), findsOneWidget);
    });

    testWidgets('der Charakter startet auf Level 1 ohne Gold', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('0 von 100 Erfahrung bis Level 2'), findsOneWidget);

      // Zweimal: einmal auf der Levelkarte, einmal als Zustand der
      // Laden-Kachel.
      expect(find.text('0 Gold'), findsNWidgets(2));
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
  final branch = theoryTree.branches.firstWhere(
    (b) => b.id == handbookBranchId,
  );

  var progress = const TheoryProgress.empty();
  for (final lesson in branch.lessons) {
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
