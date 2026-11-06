import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/mentor/mentor.dart';
import 'package:lifes_game/mentor/mentor_kasten.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/theory/skill_tree_screen.dart';
import 'package:lifes_game/theory/widgets/points_chip.dart';
import 'package:lifes_game/theory/widgets/talentpunkt_einfuehrung.dart';
import 'package:lifes_game/theory/widgets/tree_overview.dart';

import 'test_view.dart';

/// Der Talentpunkt beim ersten Öffnen der Theorie (06.11.2026): groß in
/// der Mitte, der Mentor erklärt, ein Tipp schickt ihn nach oben rechts,
/// dann kommen die Bücher.
void main() {
  const heute = Day(2026, 10, 20);

  Future<ProviderContainer> theorie(WidgetTester tester) async {
    useTallView(tester);
    final c = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(
          SaveData(
            habits: const HabitTracker.empty()
                .activate(HabitCatalog.starterId)
                .check(HabitCatalog.starterId, heute)
                .tracker,
          ),
        ),
        todayProvider.overrideWithValue(heute),
        // Den Hinweis auf die Gewohnheiten hat er schon weggetippt.
        hinweiseProvider.overrideWith(
          () => Hinweise(schon: const <Hinweis>{Hinweis.gewohnheiten}),
        ),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: SkillTreeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  final punkt = find.byKey(TalentpunktEinfuehrung.punktKey);
  final platz = find.descendant(
    of: find.byType(AppBar),
    matching: find.byType(PointsChip),
  );

  double deckkraftDesPlatzes(WidgetTester tester) => tester
      .widget<Opacity>(
        find.ancestor(of: platz, matching: find.byType(Opacity)).first,
      )
      .opacity;

  testWidgets('erst groß in der Mitte, die Bücher warten', (tester) async {
    await theorie(tester);
    final breite =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;

    expect(punkt, findsOneWidget);
    expect(tester.getCenter(punkt).dx, closeTo(breite / 2, 1));
    // Größer als sein Platz oben rechts, und der ist noch leer.
    expect(
      tester.getRect(punkt).width,
      greaterThan(tester.getSize(platz).width * 2),
    );
    expect(deckkraftDesPlatzes(tester), 0);
    // Die Zahl trägt den Stil der App — ohne `Material` darüber stünde
    // sie gelb doppelt unterstrichen da (Frederik, 06.11.2026).
    final zahl = find.descendant(of: punkt, matching: find.text('1'));
    expect(
      DefaultTextStyle.of(tester.element(zahl)).style.decoration,
      isNot(TextDecoration.underline),
    );
    expect(find.byType(ContinueReadingTile), findsNothing);
    expect(
      tester.widget<MentorKasten>(find.byType(MentorKasten)).text,
      Mentor.talentpunkt,
    );
    expect(find.byKey(WeiterZeichen.zeichenKey), findsOneWidget);
  });

  testWidgets('ein Tipp schickt ihn an seinen Platz, dann kommen die Bücher', (
    tester,
  ) async {
    final c = await theorie(tester);
    final vorher = tester.getCenter(punkt);
    final ziel = tester.getCenter(platz);

    await tester.tapAt(const Offset(200, 700));
    await tester.pump();
    await tester.pump(TalentpunktEinfuehrung.flug ~/ 2);
    // Unterwegs: zwischen Mitte und Platz, schon kleiner.
    final unterwegs = tester.getCenter(punkt);
    expect(unterwegs.dy, lessThan(vorher.dy));
    expect(unterwegs.dy, greaterThan(ziel.dy));
    expect(unterwegs.dx, greaterThan(vorher.dx));

    await tester.pumpAndSettle();
    expect(punkt, findsNothing);
    expect(deckkraftDesPlatzes(tester), 1);
    expect(find.byType(ContinueReadingTile), findsNWidgets(3));
    expect(c.read(hinweiseProvider), contains(Hinweis.talentpunkt));
    // Nichts gekauft, nichts gelesen: Der Tipp war nur ein Weiter.
    expect(find.byKey(WeiterZeichen.zeichenKey), findsNothing);
  });
}
