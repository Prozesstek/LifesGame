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
  /// Baut die Leiste und sammelt, was sie meldet.
  Future<List<TimedHit>> pumpBar(WidgetTester tester) async {
    final results = <TimedHit>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: TimingBar(onResult: results.add)),
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
