import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/action_game.dart';
import 'package:lifes_game/action/damage_popup.dart';
import 'package:lifes_game/action/pit_run_view.dart';
import 'package:lifes_game/ui/palette.dart';

/// Die Uhr der Grube, wie man sie sieht.
void main() {
  group('Die Anzeige', () {
    test('Minuten und zweistellige Sekunden', () {
      expect(PitClock.text(125), '2:05');
      expect(PitClock.text(60), '1:00');
      expect(PitClock.text(9), '0:09');
    });

    test('aufgerundet — 0:00 erst, wenn sie wirklich abgelaufen ist', () {
      expect(PitClock.text(0.2), '0:01');
      expect(PitClock.text(0), '0:00');
      expect(PitClock.text(-3), '0:00');
    });

    test('warnt erst kurz vor Schluss', () {
      expect(PitClock.isLow(60), isFalse);
      expect(PitClock.isLow(PitClock.warnSeconds), isTrue);
      expect(PitClock.isLow(3), isTrue);
    });
  });

  group('Eine Zeitkugel', () {
    test('zeigt, was sie brachte, in der Farbe der Zeit', () {
      final popup = DamagePopup.forTime(8, Vec2.zero);
      expect(popup, isNotNull);
      expect(popup!.text, '+8 s');
      expect(popup.color, Palette.tintZeit);
    });

    test('bei voller Uhr steht nichts da', () {
      expect(DamagePopup.forTime(0, Vec2.zero), isNull);
      expect(DamagePopup.forTime(0.3, Vec2.zero), isNull);
    });
  });

  group('In der Grube', () {
    testWidgets('mit Stufe läuft die Uhr rückwärts', (tester) async {
      final stufe = PitStage(1);
      final game = ActionGame(
        sim: ActionWorld(
          level: LevelBuilder.build(stage: stufe, seed: 1),
          heroStats: ActionStats.gereift,
          stage: stufe,
        ),
      );
      addTearDown(game.frame.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PitRunView(game: game)),
        ),
      );
      await tester.pump();

      expect(find.text(PitClock.text(stufe.timeLimitSeconds)), findsOneWidget);
    });
  });
}
