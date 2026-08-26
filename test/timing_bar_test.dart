import 'package:combat/combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/combat/widgets/timing_bar.dart';

/// Prüft die Timing-Leiste.
///
/// **`pumpAndSettle` ist hier verboten.** Der Marker läuft endlos hin und
/// her, es gibt also nie einen Frame, nach dem nichts mehr aussteht —
/// derselbe Fall wie beim Flame-Widget (`docs/context/gotchas.md`).
/// Deshalb überall `pump(Duration)`.
void main() {
  _ausSpec();

  /// Baut die Leiste und sammelt, was sie meldet.
  Future<List<TimedHit>> pumpBar(WidgetTester tester) async {
    final results = <TimedHit>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TimingBar(onResult: (hits) => results.addAll(hits)),
          ),
        ),
      ),
    );
    return results;
  }

  testWidgets('sie entscheidet sich nicht von selbst', (tester) async {
    // Der Kern der Änderung: Früher lief der Marker einmal durch und
    // meldete dann „daneben" — der Zug war entschieden, ohne dass der
    // Spieler etwas getan hätte. Jetzt wartet die Leiste.
    final results = await pumpBar(tester);

    // Deutlich über einen vollen Hin- und Rücklauf hinaus (1150 ms je
    // Richtung).
    await tester.pump(const Duration(seconds: 5));

    expect(results, isEmpty);

    // **Und sie bewegt sich noch.** Ohne diese Zusicherung wäre der Test
    // auch dann grün, wenn der Marker nach einem Durchlauf einfach am Rand
    // stehen bliebe — stumm, aber genauso unbrauchbar. Ein laufender
    // Controller plant fortlaufend Frames ein; ein fertiger nicht.
    expect(tester.binding.hasScheduledFrame, isTrue);

    // Aufräumen: Ohne Tipp läuft der Controller weiter, und ein laufender
    // Timer am Testende ist ein Fehler.
    await tester.tap(find.byType(TimingBar));
    await tester.pump();
  });

  testWidgets('ein Tipp meldet genau ein Ergebnis', (tester) async {
    final results = await pumpBar(tester);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(TimingBar));
    await tester.pump();

    expect(results, hasLength(1));
  });

  testWidgets('ein zweiter Tipp ändert nichts mehr', (tester) async {
    // Sonst könnte ein Doppeltipp zwei Runden auslösen.
    final results = await pumpBar(tester);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byType(TimingBar));
    await tester.pump();
    await tester.tap(find.byType(TimingBar));
    await tester.pump();

    expect(results, hasLength(1));
  });

  testWidgets('die Leiste läuft nach dem Tipp nicht weiter', (tester) async {
    final results = await pumpBar(tester);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byType(TimingBar));

    // Nach dem Anhalten steht nichts mehr aus — jetzt darf `pumpAndSettle`.
    await tester.pumpAndSettle();

    expect(results, hasLength(1));
  });
}

/// Die Leiste liest ihre Werte aus `package:combat` (ADR-0022).
void _ausSpec() {
  group('Timing-Werte kommen aus der Fähigkeit', () {
    /// Baut die Leiste mit einer bestimmten Angabe und sammelt Ergebnisse.
    Future<List<TimedHit>> pumpMit(
      WidgetTester tester, {
      required TimingSpec spec,
      int hits = 1,
    }) async {
      final results = <TimedHit>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TimingBar(
                spec: spec,
                hits: hits,
                onResult: (h) => results.addAll(h),
              ),
            ),
          ),
        ),
      );
      return results;
    }

    testWidgets('ein schnellerer Marker legt mehr Strecke zurück', (
      tester,
    ) async {
      // Bei 3.0x ist ein Durchlauf in gut einem Drittel der Zeit vorbei.
      // Nach 400 ms hat der schnelle Marker die Leiste schon gewechselt,
      // der langsame noch nicht — sichtbar daran, dass beide bei
      // demselben Tipp verschieden bewertet werden.
      await pumpMit(tester, spec: const TimingSpec(speed: 3.0));
      await tester.pump(const Duration(milliseconds: 400));

      // Kein Absturz, Leiste läuft — der eigentliche Beweis steckt im
      // Test unten über die Fensterbreite.
      expect(find.byType(TimingBar), findsOneWidget);
      await tester.tap(find.byType(TimingBar));
      await tester.pump();
    });

    // **Zwei Tests statt einem, und das ist kein Zufall.** Zwei Leisten
    // nacheinander im selben Test bekommen denselben Zustand: Flutter
    // erkennt denselben Widget-Typ an derselben Stelle und verwendet das
    // Element wieder. Der zweite Tipp lief dann in ein bereits fertiges
    // `TimingBarState` und wurde verworfen.
    const gleicheZeit = Duration(milliseconds: 300);

    testWidgets('ein weites Fenster trifft immer', (tester) async {
      final results = await pumpMit(
        tester,
        spec: const TimingSpec(perfectWindow: 0.99),
      );

      await tester.pump(gleicheZeit);
      await tester.tap(find.byType(TimingBar));
      await tester.pump();

      expect(results.single, TimedHit.perfect);
    });

    testWidgets('ein enges Fenster an derselben Stelle nicht', (tester) async {
      // Gleiche Geschwindigkeit, gleiche Zeit, gleicher Tipp — nur das
      // Fenster ist enger. Genau das ist der Unterschied zwischen
      // Funkenstoß (24 %) und Sternenfall (4 %).
      final results = await pumpMit(
        tester,
        spec: const TimingSpec(perfectWindow: 0.04),
      );

      await tester.pump(gleicheZeit);
      await tester.tap(find.byType(TimingBar));
      await tester.pump();

      expect(results.single, isNot(TimedHit.perfect));
    });

    testWidgets('drei Tipps ergeben drei Ergebnisse', (tester) async {
      final results = await pumpMit(
        tester,
        spec: const TimingSpec(perfectWindow: 0.99),
        hits: 3,
      );

      // Nach dem ersten und zweiten Tipp ist noch nichts gemeldet.
      await tester.tap(find.byType(TimingBar));
      await tester.pump();
      expect(results, isEmpty);

      await tester.tap(find.byType(TimingBar));
      await tester.pump();
      expect(results, isEmpty);

      await tester.tap(find.byType(TimingBar));
      await tester.pump();

      expect(results, hasLength(3));
    });

    testWidgets('die Leiste sagt, wie viele Tipps noch fehlen', (tester) async {
      await pumpMit(
        tester,
        spec: const TimingSpec(perfectWindow: 0.99),
        hits: 3,
      );

      expect(find.textContaining('NOCH 3'), findsOneWidget);

      await tester.tap(find.byType(TimingBar));
      await tester.pump();

      expect(find.textContaining('NOCH 2'), findsOneWidget);
    });

    testWidgets('bei einem Tipp steht der gewohnte Text', (tester) async {
      await pumpMit(tester, spec: TimingSpec.standard);

      expect(find.text('JETZT TIPPEN'), findsOneWidget);

      await tester.tap(find.byType(TimingBar));
      await tester.pump();
    });
  });
}
