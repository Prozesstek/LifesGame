import 'package:achievements/achievements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/combat/ladder_controller.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/habits/widgets/cue_dialog.dart';
import 'package:lifes_game/habits/widgets/habit_check_tile.dart';
import 'package:lifes_game/habits/widgets/streak_freeze_card.dart';
import 'package:lifes_game/habits/widgets/gewohnheit_anlegen.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

const Day _heute = Day(2026, 8, 12);

/// Ein Container mit festem „heute", damit Streak-Anzeigen nicht vom
/// Systemdatum abhängen.
ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [todayProvider.overrideWithValue(_heute)],
  );
  addTearDown(container.dispose);
  return container;
}

/// Spielt Lektionen des Wurzelzweigs durch, damit Vorlagen offen sind.
void _passRootBranch(ProviderContainer container) {
  final controller = container.read(theoryProgressProvider.notifier);
  for (final lesson in habitsBranch.lessons) {
    controller.submit(
      lesson,
      lesson.questions.map<int?>((q) => q.correctIndex).toList(),
    );
  }
}

/// Öffnet den Plus-Knopf und klappt die Vorlagen auf (ADR-0089).
Future<void> _vorlagenAuf(WidgetTester tester) async {
  await tester.tap(find.byKey(HabitsScreen.plusKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(GewohnheitAnlegen.vorlageKey));
  await tester.pumpAndSettle();
}

/// Die Einträge der aufgeklappten Vorlagen.
final Finder _eintraege = find.byWidgetPredicate((w) {
  final key = w.key;
  return key is ValueKey<String> && key.value.startsWith('anlegen-vorlage-');
});

/// Startet die oberste Vorlage über den Plus-Knopf und lässt Auslöser
/// und Belohnung liegen — „Ohne", wie jemand, der es eilig hat.
Future<void> _vorlageStarten(WidgetTester tester) async {
  await _vorlagenAuf(tester);
  await tester.tap(_eintraege.first);
  await tester.pumpAndSettle();
  await _ohneEinrichtung(tester);
}

/// Wann → „Ohne", Tage → „Weiter", Danach → „Ohne" — falls gefragt wird.
Future<void> _ohneEinrichtung(WidgetTester tester) async {
  if (find.byKey(GewohnheitAnlegen.ohneKey).evaluate().isEmpty) return;
  await tester.tap(find.byKey(GewohnheitAnlegen.ohneKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(GewohnheitAnlegen.weiterKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(GewohnheitAnlegen.ohneKey));
  await tester.pumpAndSettle();
}

Future<void> _pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
) async {
  useTallView(tester);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: HabitsScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  group('HabitsScreen', () {
    testWidgets('ohne Fortschritt steht die Startvorlage bereit', (
      tester,
    ) async {
      // Die erste Sitzung soll mit einem Häkchen enden, nicht mit Lesen
      // (ADR-0052). Bis dahin stand hier ein leerer Bildschirm mit dem
      // Weg zum Skillbaum.
      final container = _container();
      await _pumpScreen(tester, container);

      // Seit ADR-0089 hinter dem Plus-Knopf, nicht mehr in einem Reiter.
      expect(find.text('Vorerstellte'), findsNothing);
      await _vorlagenAuf(tester);
      expect(
        find.byKey(GewohnheitAnlegen.vorlageEintrag(HabitCatalog.starterId)),
        findsOneWidget,
      );
    });

    testWidgets('bestandene Lektionen bringen ihre Vorlagen mit', (
      tester,
    ) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);
      await _vorlagenAuf(tester);

      final erwartet = habitsBranch.lessons
          .map((l) => l.unlocksHabit)
          .whereType<String>();

      expect(erwartet, isNotEmpty);
      for (final name in erwartet) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
    });

    testWidgets('eine Vorlage lässt sich starten und abhaken', (tester) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      await _vorlageStarten(tester);

      final tracker = container.read(habitTrackerProvider);
      expect(tracker.activeIds, hasLength(1));

      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pump();
      await schonErledigt(tester);

      final habitId = tracker.activeIds.first;
      expect(
        container.read(habitTrackerProvider).isChecked(habitId, _heute),
        isTrue,
      );
    });

    testWidgets('abgehakt rutscht die Kachel nach unten', (tester) async {
      final container = _container();
      _passRootBranch(container);
      final vorlagen = container.read(unlockedHabitsProvider);
      expect(vorlagen.length, greaterThanOrEqualTo(2));
      final erste = vorlagen[0];
      final zweite = vorlagen[1];
      container.read(habitTrackerProvider.notifier)
        ..activate(erste.id)
        ..activate(zweite.id);
      await _pumpScreen(tester, container);

      double oben(String name) => tester
          .getTopLeft(
            find.descendant(
              of: find.byType(HabitCheckTile),
              matching: find.text(name),
            ),
          )
          .dy;

      expect(oben(erste.name), lessThan(oben(zweite.name)));

      await tester.tap(
        find.descendant(
          of: find.byKey(ValueKey<String>(erste.id)),
          matching: find.byIcon(Icons.radio_button_unchecked),
        ),
      );
      await tester.pump();
      await schonErledigt(tester);

      expect(
        oben(erste.name),
        greaterThan(oben(zweite.name)),
        reason: 'offen oben, erledigt unten',
      );
    });

    testWidgets('ein Häkchen zahlt sofort auf Erfahrung und Gold ein', (
      tester,
    ) async {
      final container = _container();
      _passRootBranch(container);
      final xpVorher = container.read(totalXpProvider);
      final goldVorher = container.read(goldProvider);

      await _pumpScreen(tester, container);
      await _vorlageStarten(tester);
      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pump();
      await schonErledigt(tester);

      // **Das erste Haekchen ueberhaupt loest „Erster Schritt" aus**
      // (ADR-0033). Der Meilenstein steht als eigener Summand da, statt
      // die Zahl stillschweigend groesser zu machen.
      final ersterSchritt = AchievementCatalog.byId('erster-schritt')!;
      expect(
        container.read(totalXpProvider),
        xpVorher + HabitRewards.xpPerCheck + ersterSchritt.tier.xp,
      );
      expect(
        container.read(goldProvider),
        goldVorher + HabitRewards.goldPerCheck + ersterSchritt.tier.gold,
      );
    });

    testWidgets('das Häkchen lässt sich zurücknehmen', (tester) async {
      final container = _container();
      _passRootBranch(container);
      final xpVorher = container.read(totalXpProvider);

      await _pumpScreen(tester, container);
      await _vorlageStarten(tester);
      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pump();
      await schonErledigt(tester);
      // Die Feiern zum ersten Häkchen liegen jetzt über der Liste — die
      // Errungenschaft und, seit ADR-0079 die erste Seite 30 Erfahrung
      // mehr bringt, auch ein Aufstieg.
      final kreis = find.byIcon(Icons.check_circle).hitTestable();
      for (var i = 0; i < 4 && kreis.evaluate().isEmpty; i++) {
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
      }
      await tester.tap(kreis);
      await tester.pump();

      expect(container.read(totalXpProvider), xpVorher);
    });

    testWidgets('mehr als die Obergrenze lässt sich nicht starten', (
      tester,
    ) async {
      final container = _container();

      // Alles freischalten, damit genug Vorlagen zur Auswahl stehen.
      final controller = container.read(theoryProgressProvider.notifier);
      for (final branch in theoryTree.branches) {
        for (final lesson in branch.lessons) {
          controller.submit(
            lesson,
            lesson.questions.map<int?>((q) => q.correctIndex).toList(),
          );
        }
      }

      await _pumpScreen(tester, container);

      for (var i = 0; i < HabitRewards.maxActiveHabits; i++) {
        await _vorlageStarten(tester);
      }

      expect(
        container.read(habitTrackerProvider).activeIds,
        hasLength(HabitRewards.maxActiveHabits),
      );

      // Die übrigen Vorlagen stehen weiter da, matt — ein Tipp sagt,
      // warum es nicht geht, und startet nichts.
      await _vorlagenAuf(tester);
      expect(_eintraege, findsWidgets);
      await tester.tap(_eintraege.first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Die Liste ist voll'), findsOneWidget);
      expect(
        container.read(habitTrackerProvider).activeIds,
        hasLength(HabitRewards.maxActiveHabits),
      );
    });
  });

  /// Der Auslöser (ADR-0052): wann eine Gewohnheit drankommt.
  ///
  /// Der Weg geht über drei Stellen — Starten, Dialog, Kachel —, und der
  /// Satz muss am Ende auf der Kachel stehen und im Tracker liegen.
  group('Wann machst du das?', () {
    testWidgets('Starten fragt nach dem Auslöser', (tester) async {
      final container = _container();
      await _pumpScreen(tester, container);

      await _vorlagenAuf(tester);
      await tester.tap(_eintraege.first);
      await tester.pumpAndSettle();

      expect(find.text('Wann machst du das?'), findsOneWidget);
      expect(find.byKey(GewohnheitAnlegen.ohneKey), findsOneWidget);
    });

    testWidgets('ein Vorschlag landet auf der Kachel', (tester) async {
      final container = _container();
      await _pumpScreen(tester, container);

      await _vorlagenAuf(tester);
      await tester.tap(_eintraege.first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'Nach dem Zähneputzen'));
      await tester.pump();
      await tester.tap(find.byKey(GewohnheitAnlegen.weiterKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(GewohnheitAnlegen.weiterKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(GewohnheitAnlegen.ohneKey));
      await tester.pumpAndSettle();

      final starter = HabitCatalog.starterId;
      expect(
        container.read(habitTrackerProvider).cueFor(starter),
        'Nach dem Zähneputzen',
      );
      expect(
        find.descendant(
          of: find.byType(HabitCheckTile),
          matching: find.text('Nach dem Zähneputzen'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('„Ohne" lässt die Frage auf der Kachel stehen', (tester) async {
      final container = _container();
      await _pumpScreen(tester, container);
      await _vorlageStarten(tester);

      expect(
        container.read(habitTrackerProvider).cueFor(HabitCatalog.starterId),
        isNull,
      );
      expect(
        find.descendant(
          of: find.byType(HabitCheckTile),
          matching: find.byIcon(Icons.add_alarm_outlined),
        ),
        findsOneWidget,
      );
    });

    testWidgets('die Zeile ändert den Satz, statt abzuhaken', (tester) async {
      final container = _container();
      await _pumpScreen(tester, container);
      await _vorlageStarten(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(HabitCheckTile),
          matching: find.byIcon(Icons.add_alarm_outlined),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        container
            .read(habitTrackerProvider)
            .isChecked(HabitCatalog.starterId, _heute),
        isFalse,
      );
      await tester.enterText(find.byKey(cueFieldKey), 'Nach dem Kaffee');
      await tester.tap(find.widgetWithText(FilledButton, 'Festlegen'));
      await tester.pumpAndSettle();

      expect(
        container.read(habitTrackerProvider).cueFor(HabitCatalog.starterId),
        'Nach dem Kaffee',
      );
    });

    testWidgets('auf einer erledigten Kachel steht er nicht', (tester) async {
      final container = _container();
      container
          .read(habitTrackerProvider.notifier)
          .activate(HabitCatalog.starterId);
      container
          .read(habitTrackerProvider.notifier)
          .setCue(HabitCatalog.starterId, 'Nach dem Kaffee');
      await _pumpScreen(tester, container);

      expect(find.text('Nach dem Kaffee'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pumpAndSettle();
      await schonErledigt(tester);

      expect(find.text('Nach dem Kaffee'), findsNothing);
    });
  });

  /// Eigene Gewohnheiten (ADR-0028).
  ///
  /// Der Weg, den kein Package allein prüfen kann: Formular ausfüllen →
  /// angelegt → steht auf der Tagesliste → zahlt auf einen Wert ein. Er
  /// geht über drei Schichten, und genau solche Wege sind es, die in
  /// `gotchas.md` stehen, weil beide Enden für sich geprüft waren.
  group('Eigene Gewohnheiten', () {
    /// Geht den Ablauf einer eigenen durch und legt an (ADR-0089).
    Future<void> anlegen(
      WidgetTester tester, {
      String name = 'Zehn Liegestütze',
      String? menge,
    }) async {
      await tester.tap(find.byKey(HabitsScreen.plusKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(GewohnheitAnlegen.eigeneKey));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(GewohnheitAnlegen.nameKey), name);
      await tester.pump();
      await tester.tap(find.byKey(GewohnheitAnlegen.weiterKey));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(GewohnheitAnlegen.gebietKey(SkillArea.koerper)),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(GewohnheitAnlegen.gradKey(HabitDifficulty.mittel)),
      );
      await tester.pumpAndSettle();

      if (menge == null) {
        await tester.tap(find.byKey(GewohnheitAnlegen.zielKey(ZielArt.keins)));
        await tester.pumpAndSettle();
      } else {
        await tester.tap(find.byKey(GewohnheitAnlegen.zielKey(ZielArt.menge)));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(GewohnheitAnlegen.mengeKey), menge);
        await tester.pump();
        await tester.tap(find.byKey(GewohnheitAnlegen.weiterKey));
        await tester.pumpAndSettle();
      }
      await _ohneEinrichtung(tester);
    }

    testWidgets('ohne Lektion gibt es den Platz der Startvorlage', (
      tester,
    ) async {
      // Eine Vorlage bringt beides mit, den Eintrag und den Platz
      // (ADR-0028) — auch die Startvorlage (ADR-0052).
      final container = _container();
      await _pumpScreen(tester, container);

      expect(container.read(customSlotsProvider), 1);
      expect(find.byKey(HabitsScreen.plusKey), findsOneWidget);
    });

    test('der erste Sieg gibt zwei Plätze dazu, also drei (ADR-0093)', () {
      final container = _container();
      expect(container.read(customSlotsProvider), 1);

      container.read(ladderProvider.notifier).defeat(1);

      expect(container.read(customSlotsProvider), 3);
      expect(container.read(customSlotsLeftProvider), 3);
    });

    test('eine Niederlage gibt keinen Platz, der Mentor ist nicht fertig', () {
      final container = _container();

      container.read(ladderProvider.notifier).recordDefeat(1);

      expect(container.read(customSlotsProvider), 1);
    });

    test('nach dem ersten Sieg lassen sich drei wirklich anlegen', () {
      final container = _container();
      container.read(ladderProvider.notifier).defeat(1);
      final controller = container.read(habitTrackerProvider.notifier);

      CustomHabit? anlegen(int i) => controller.addCustom(
        name: 'Eigene $i',
        area: SkillArea.koerper,
        difficulty: HabitDifficulty.mittel,
      );

      expect(anlegen(1), isNotNull);
      expect(anlegen(2), isNotNull);
      expect(anlegen(3), isNotNull);
      expect(anlegen(4), isNull);
      expect(container.read(customSlotsLeftProvider), 0);
    });

    testWidgets('jede freigeschaltete Vorlage gibt einen Platz', (
      tester,
    ) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      final vorlagen = container.read(unlockedHabitsProvider).length;
      expect(vorlagen, greaterThan(0));
      expect(container.read(customSlotsProvider), vorlagen);
      expect(container.read(customSlotsLeftProvider), vorlagen);
    });

    testWidgets('anlegen setzt sie sofort auf die Tagesliste', (tester) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      await anlegen(tester);

      final tracker = container.read(habitTrackerProvider);
      expect(tracker.customHabits, hasLength(1));

      final habit = tracker.customHabits.single;
      expect(habit.name, 'Zehn Liegestütze');
      expect(tracker.isActive(habit.id), isTrue);
      expect(
        container.read(customSlotsLeftProvider),
        lessThan(container.read(customSlotsProvider)),
      );
    });

    testWidgets('sie lässt sich abhaken und zahlt auf ihren Wert ein', (
      tester,
    ) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);
      await anlegen(tester);

      final habit = container.read(habitTrackerProvider).customHabits.single;
      final xpVorher = container.read(totalXpProvider);

      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pump();

      final tracker = container.read(habitTrackerProvider);
      expect(tracker.isChecked(habit.id, _heute), isTrue);
      final ersterSchritt = AchievementCatalog.byId('erster-schritt')!;
      expect(
        container.read(totalXpProvider),
        xpVorher +
            HabitRewards.xpFor(1, habit.difficulty) +
            ersterSchritt.tier.xp,
      );
      expect(container.read(characterStatsProvider).checksFor(habit.stat), 1);
    });

    testWidgets('ein Tagesziel füllt sich schrittweise', (tester) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);
      await anlegen(tester, name: 'Wasser trinken', menge: '3');

      final habit = container.read(habitTrackerProvider).customHabits.single;
      expect(habit.goal?.target, 3);

      // Das Plus auf der Kachel — die Vorlagen stehen seit ADR-0089
      // nicht mehr auf dem Bildschirm.
      expect(find.text('0/3'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump();

      expect(
        container.read(habitTrackerProvider).progressOn(habit.id, _heute),
        1,
      );
      expect(
        container.read(habitTrackerProvider).isChecked(habit.id, _heute),
        isFalse,
        reason: 'halb getan ist nicht getan',
      );

      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump();

      expect(
        container.read(habitTrackerProvider).isChecked(habit.id, _heute),
        isTrue,
      );
    });

    testWidgets('ohne Namen lässt sich nichts anlegen', (tester) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      await tester.tap(find.byKey(HabitsScreen.plusKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(GewohnheitAnlegen.eigeneKey));
      await tester.pumpAndSettle();

      final knopf = tester.widget<FilledButton>(
        find.byKey(GewohnheitAnlegen.weiterKey),
      );
      expect(knopf.onPressed, isNull);
    });

    testWidgets('ist kein Platz frei, nennt der Knopf den Weg', (tester) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      // Alle Plätze belegen. Mehr als die Tagesliste fasst, ist Absicht:
      // Anlegen und Verfolgen sind zwei verschiedene Grenzen.
      final controller = container.read(habitTrackerProvider.notifier);
      final slots = container.read(customSlotsProvider);
      for (var i = 0; i < slots; i++) {
        controller.addCustom(
          name: 'Eigene $i',
          area: SkillArea.koerper,
          difficulty: HabitDifficulty.mittel,
        );
      }
      await tester.pump();

      expect(container.read(customSlotsLeftProvider), 0);

      // Der Plus-Knopf bleibt, „Eigene erstellen" sagt ab. Der Grund
      // kommt beim Antippen — sonst bliebe die Frage „warum geht das
      // nicht" offen.
      expect(find.byKey(HabitsScreen.plusKey), findsOneWidget);
      await tester.tap(find.byKey(HabitsScreen.plusKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('Kein Platz frei'), findsNothing);

      await tester.tap(find.byKey(GewohnheitAnlegen.eigeneKey));
      await tester.pumpAndSettle();

      expect(find.textContaining('Kein Platz frei'), findsOneWidget);
      expect(find.byKey(GewohnheitAnlegen.nameKey), findsNothing);
    });

    testWidgets('die Untertexte sind weg, die Zahlen nicht (Issue #35)', (
      tester,
    ) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      // Eine eigene Gewohnheit mit Tagesziel, gestern und vorgestern
      // abgehakt -- damit heute eine Kette von zwei Tagen zaehlt.
      final controller = container.read(habitTrackerProvider.notifier);
      final habit = controller.addCustom(
        name: 'Wasser trinken',
        area: SkillArea.koerper,
        difficulty: HabitDifficulty.mittel,
        goal: HabitGoal.menge(target: 5, unit: 'Gläser'),
      );
      controller.toggle(habit!.id, _heute.previous.previous);
      controller.toggle(habit.id, _heute.previous);
      controller.advance(habit.id, _heute);
      await tester.pump();

      // Die Prosa ist weg: kein „+1 Angriff", kein „2 Tage am Stück".
      expect(find.textContaining('am Stück'), findsNothing);
      expect(find.textContaining('+1 Angriff'), findsNothing);

      // Die Zahlen sind geblieben -- die Kette als Marke, der Stand des
      // Tagesziels neben seinem Knopf (ADR-0092). Ohne sie waere aus einer
      // Layout-Aenderung eine Produktaenderung geworden.
      expect(find.text('Wasser trinken'), findsOneWidget);
      // Nur die Marke auf der Kachel — die Flamme steht seit Issue #46
      // auch über der Beständigkeits-Leiter.
      expect(
        find.descendant(
          of: find.byType(HabitCheckTile),
          matching: find.byIcon(Icons.local_fire_department),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('2'), findsWidgets);
      expect(find.text('1/5'), findsOneWidget);
    });

    testWidgets('ohne Kette steht keine Marke da', (tester) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      container
          .read(habitTrackerProvider.notifier)
          .addCustom(
            name: 'Frisch angelegt',
            area: SkillArea.koerper,
            difficulty: HabitDifficulty.mittel,
          );
      await tester.pump();

      expect(find.text('Frisch angelegt'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HabitCheckTile),
          matching: find.byIcon(Icons.local_fire_department),
        ),
        findsNothing,
      );
    });

    testWidgets('mehr als die Plätze hergeben, kommt nicht hinzu', (
      tester,
    ) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      final controller = container.read(habitTrackerProvider.notifier);
      final slots = container.read(customSlotsProvider);
      for (var i = 0; i < slots + 3; i++) {
        controller.addCustom(
          name: 'Eigene $i',
          area: SkillArea.koerper,
          difficulty: HabitDifficulty.mittel,
        );
      }

      expect(
        container.read(habitTrackerProvider).customHabits,
        hasLength(slots),
      );
    });
  });

  group('Was ein Häkchen einbringt (Issue #46)', () {
    testWidgets('die Kachel nennt Erfahrung und Gold, bevor getippt wird', (
      tester,
    ) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      await _vorlageStarten(tester);
      await tester.pump();

      expect(find.text('+${HabitRewards.xpPerCheck}'), findsOneWidget);
      expect(find.text('+${HabitRewards.goldPerCheck}'), findsOneWidget);
    });

    testWidgets('nach dem Häkchen steht dort, was es gebracht hat', (
      tester,
    ) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      await _vorlageStarten(tester);
      await tester.tap(find.byType(HabitCheckTile).first);
      await schonErledigt(tester);

      // Die Zahlen stehen jetzt ohne „Heute" davor, in der Farbe des
      // Erfolgs.
      expect(find.bySemanticsLabel(RegExp('Heute geholt')), findsOneWidget);
      expect(find.text('+${HabitRewards.xpPerCheck}'), findsOneWidget);
    });

    testWidgets('mit laufender Kette steht dort mehr', (tester) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      // Zwei Tage stehen: Das nächste Häkchen erreicht x1,2.
      final controller = container.read(habitTrackerProvider.notifier);
      final vorlage = container.read(unlockedHabitsProvider).first;
      controller.activate(vorlage.id);
      controller.toggle(vorlage.id, _heute.previous.previous);
      controller.toggle(vorlage.id, _heute.previous);
      await tester.pump();

      expect(
        find.text('+${HabitRewards.xpFor(3)}'),
        findsOneWidget,
        reason: 'die Kachel muss den Multiplikator in Erfahrung umrechnen',
      );
      expect(HabitRewards.xpFor(3), greaterThan(HabitRewards.xpPerCheck));
    });

    testWidgets('ein gewonnener Charakterpunkt wird gemeldet', (tester) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      // Fünf Häkchen auf Angriff sind ein Punkt (`StatCurve`). Vier
      // liegen hinter uns, das fünfte fällt jetzt.
      final controller = container.read(habitTrackerProvider.notifier);
      final habit = controller.addCustom(
        name: 'Liegestütze',
        area: SkillArea.koerper,
        difficulty: HabitDifficulty.mittel,
      );
      var tag = _heute;
      for (var i = 0; i < 4; i++) {
        tag = tag.previous;
      }
      for (var i = 0; i < 4; i++) {
        controller.toggle(habit!.id, tag);
        tag = tag.next;
      }
      await tester.pump();
      expect(
        container.read(characterStatsProvider).bonusFor(HabitStat.staerke),
        0,
        reason: 'vier Häkchen sind noch kein Punkt',
      );

      await tester.tap(find.text('Liegestütze'));
      await tester.pump(const Duration(milliseconds: 300));

      // Zweimal: in der Leiste unten und als aufsteigende Zahl dort, wo
      // getippt wurde.
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('+1 Angriff'),
        ),
        findsOneWidget,
      );
      expect(find.text('+1 Angriff'), findsOneWidget, reason: 'aufsteigend');
    });
  });

  group('Was Beständigkeit bringt (Issue #46, #88)', () {
    testWidgets('die Kachel nennt die Kette in Tagen, sonst nichts', (
      tester,
    ) async {
      // ADR-0092: kein Bonus und keine nächste Stufe mehr an der Kachel.
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      final controller = container.read(habitTrackerProvider.notifier);
      final vorlage = container.read(unlockedHabitsProvider).first;
      controller.activate(vorlage.id);
      controller.toggle(vorlage.id, _heute.previous);
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(HabitCheckTile),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining(RegExp(r'^x\d')), findsNothing);
      expect(find.byIcon(Icons.update_rounded), findsNothing);
    });

    testWidgets('die Leiter und die Werte stehen nicht mehr da', (
      tester,
    ) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      expect(find.text('Kette je Gewohnheit'), findsNothing);
      expect(find.text('Tagesform'), findsNothing);
    });
  });

  group('Streak-Eis (Issue #46)', () {
    /// Gestern fehlt, vorgestern steht — genau der Fall, den das Eis
    /// abdeckt.
    void mitLuecke(ProviderContainer container) {
      final controller = container.read(habitTrackerProvider.notifier);
      final vorlage = container.read(unlockedHabitsProvider).first;
      controller.activate(vorlage.id);
      controller.toggle(vorlage.id, _heute.previous.previous.previous);
      controller.toggle(vorlage.id, _heute.previous.previous);
    }

    testWidgets('ohne Lücke steht die Karte nicht da', (tester) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      expect(find.byType(StreakFreezeCard), findsNothing);
    });

    testWidgets('mit Lücke bietet sie das Eis an', (tester) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);
      mitLuecke(container);
      await tester.pump();

      expect(find.byType(StreakFreezeCard), findsOneWidget);
      expect(find.byIcon(Icons.ac_unit), findsWidgets);
    });

    testWidgets('der Knopf rettet die Kette, ohne sie zu verlängern', (
      tester,
    ) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);
      mitLuecke(container);
      await tester.pump();

      final vorlage = container.read(unlockedHabitsProvider).first;
      final vorher = container.read(habitTrackerProvider);
      expect(vorher.currentStreak(vorlage.id, _heute), 0);

      await tester.tap(find.byType(FilledButton).first);
      await tester.pump();

      final nachher = container.read(habitTrackerProvider);
      expect(nachher.currentStreak(vorlage.id, _heute), 2);
      expect(nachher.totalChecks, vorher.totalChecks);
      expect(nachher.totalXp, vorher.totalXp);
      expect(nachher.freezesLeft, vorher.freezesLeft - 1);
    });

    testWidgets('danach verschwindet die Karte', (tester) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);
      mitLuecke(container);
      await tester.pump();

      await tester.tap(find.byType(FilledButton).first);
      await tester.pump();

      expect(find.byType(StreakFreezeCard), findsNothing);
    });
  });
}
