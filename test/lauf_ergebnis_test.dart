import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/staerker_werden.dart';
import 'package:lifes_game/combat/widgets/lauf_ergebnis.dart';
import 'package:lifes_game/ui/palette.dart';

/// Das Blatt am Ende eines Laufs: Überschrift, Ebene und Zeit, Beute, die
/// hereinkommt, zuletzt „Weiter“ — nach einer Niederlage statt der Beute
/// drei Tipps (ADR-0083).
///
/// Die Grenze aus ADR-0032 bleibt bewacht: Was das Blatt an Beute zeigt,
/// ist genau, was `LadderController.recordRun` gebucht hat. Ein zweiter
/// Sieg bucht nichts und zeigt nichts.
void main() {
  Future<void> zeige(
    WidgetTester tester, {
    bool won = true,
    int xp = 55,
    int gold = 22,
    bool newBest = false,
    bool timedOut = false,
    List<StaerkerTipp> tipps = const <StaerkerTipp>[],
    void Function(StaerkerWeg?)? danach,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  final weg = await showDialog<StaerkerWeg>(
                    context: context,
                    builder: (_) => LaufErgebnis(
                      won: won,
                      stage: 12,
                      seconds: 84,
                      earnedXp: xp,
                      earnedGold: gold,
                      newBest: newBest,
                      timedOut: timedOut,
                      tipps: tipps,
                    ),
                  );
                  danach?.call(weg);
                },
                child: const Text('los'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('los'));
    await tester.pump();
  }

  Opacity deckkraftVon(WidgetTester tester, Finder finder) =>
      tester.widget<Opacity>(
        find.ancestor(of: finder, matching: find.byType(Opacity)).first,
      );

  Color? farbeVon(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  group('Sieg', () {
    testWidgets('„Sieg“ in Grün, Ebene und Zeit stehen sofort da', (
      tester,
    ) async {
      await zeige(tester);

      expect(find.text('Sieg'), findsOneWidget);
      expect(farbeVon(tester, 'Sieg'), Palette.success);
      expect(find.text('Ebene: 12'), findsOneWidget);
      expect(find.text('84 s'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('die Beute kommt herein und endet in ihrer Farbe', (
      tester,
    ) async {
      await zeige(tester);
      expect(deckkraftVon(tester, find.text('+55')).opacity, 0);

      await tester.pumpAndSettle();
      expect(deckkraftVon(tester, find.text('+55')).opacity, 1);
      expect(deckkraftVon(tester, find.text('+22')).opacity, 1);
      expect(farbeVon(tester, '+55'), Palette.accent);
      expect(farbeVon(tester, '+22'), Palette.gold);
    });

    testWidgets('Weiter erscheint zuletzt und schliesst', (tester) async {
      await zeige(tester);

      await tester.tap(find.byKey(LaufErgebnis.weiterKey), warnIfMissed: false);
      await tester.pump();
      expect(find.byType(LaufErgebnis), findsOneWidget);

      await tester.pumpAndSettle();
      await tester.tap(find.byKey(LaufErgebnis.weiterKey));
      await tester.pumpAndSettle();
      expect(find.byType(LaufErgebnis), findsNothing);
    });

    testWidgets('ein zweiter Sieg zeigt keine Beute und sagt warum', (
      tester,
    ) async {
      await zeige(tester, xp: 0, gold: 0);
      await tester.pumpAndSettle();

      expect(find.textContaining('+'), findsNothing);
      expect(find.byTooltip(RegExp('nur beim ersten Mal')), findsOneWidget);
      expect(find.byKey(LaufErgebnis.weiterKey), findsOneWidget);
    });

    testWidgets('eine neue Bestzeit trägt einen Stern', (tester) async {
      await zeige(tester, newBest: true);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('Niederlage', () {
    testWidgets('„Niederlage“ in Rot, sonst derselbe Aufbau', (tester) async {
      await zeige(tester, won: false, xp: 0, gold: 0);
      await tester.pumpAndSettle();

      expect(find.text('Niederlage'), findsOneWidget);
      expect(find.text('Sieg'), findsNothing);
      expect(farbeVon(tester, 'Niederlage'), Palette.enemy);
      expect(find.text('Ebene: 12'), findsOneWidget);
      expect(find.textContaining('+'), findsNothing);
      expect(find.byKey(LaufErgebnis.weiterKey), findsOneWidget);
    });

    testWidgets('abgelaufene Zeit trägt die durchgestrichene Uhr', (
      tester,
    ) async {
      await zeige(tester, won: false, timedOut: true, xp: 0, gold: 0);
      expect(find.byIcon(Icons.timer_off_outlined), findsOneWidget);
      await tester.pumpAndSettle();
    });

    final dreiTipps = StaerkerWerden.tipps(
      const StaerkerStand(
        leerePlaetze: 1,
        ungenutzteFaehigkeiten: 2,
        freiePunkte: 2,
      ),
    );

    testWidgets('drei Tipps statt Beute, sie kommen nacheinander herein', (
      tester,
    ) async {
      await zeige(tester, won: false, xp: 0, gold: 0, tipps: dreiTipps);
      final erster = find.text(dreiTipps.first.satz);
      expect(deckkraftVon(tester, erster).opacity, 0);

      await tester.pumpAndSettle();
      for (final tipp in dreiTipps) {
        expect(find.text(tipp.satz), findsOneWidget);
        expect(find.byKey(LaufErgebnis.tippKey(tipp.weg)), findsOneWidget);
      }
      expect(find.textContaining('+'), findsNothing);
      expect(find.byTooltip(RegExp('Ohne den Wächter')), findsOneWidget);
    });

    testWidgets('ein Tipp schliesst das Blatt und sagt, wohin', (tester) async {
      StaerkerWeg? gewaehlt;
      await zeige(
        tester,
        won: false,
        xp: 0,
        gold: 0,
        tipps: dreiTipps,
        danach: (weg) => gewaehlt = weg,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(LaufErgebnis.tippKey(StaerkerWeg.baum)));
      await tester.pumpAndSettle();
      expect(find.byType(LaufErgebnis), findsNothing);
      expect(gewaehlt, StaerkerWeg.baum);
    });

    testWidgets('ein Sieg zeigt keine Tipps', (tester) async {
      await zeige(tester, tipps: dreiTipps);
      await tester.pumpAndSettle();
      expect(find.text(dreiTipps.first.satz), findsNothing);
    });

    testWidgets('und nennt keinen Verlust an Werten', (tester) async {
      // `konzept.md` 3.7: Das Spiel bestraft nicht.
      await zeige(tester, won: false, xp: 0, gold: 0);
      await tester.pumpAndSettle();

      expect(find.byTooltip(RegExp('Werte wachsen')), findsOneWidget);
      expect(find.textContaining('verlierst'), findsNothing);
    });
  });
}
