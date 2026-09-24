import 'dart:ui' as ui;

import 'package:action_combat/action_combat.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/action_sprites.dart';
import 'package:lifes_game/action/figure_state.dart';

EntityView _view({
  required Vec2 at,
  Vec2 facing = const Vec2(1, 0),
  EnemyKind kind = EnemyKind.fussvolk,
}) {
  return EntityView(
    id: 1,
    faction: Faction.gegner,
    kind: kind,
    position: at,
    radius: 10,
    hpRatio: 1,
    facing: facing,
    isAlive: true,
  );
}

void main() {
  group('Die Streifen passen zu ihren Dateien', () {
    // **Die Zahlen in `GrubeFiguren` sind abgezählt, nicht gelesen.** Ein
    // Streifen mit sechs statt acht Bildern liefe trotzdem — er zeigte
    // nur ab dem siebten Bild ins Leere. Dieser Test liest die Dateien.
    testWidgets('jede Datei ist angemeldet und so breit wie ihre Bilder', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final figure in GrubeFiguren.all) {
          for (final strip in figure.strips.values) {
            final data = await rootBundle.load(
              '${GrubeFiguren.folder}/${strip.file}',
            );
            final codec = await ui.instantiateImageCodec(
              data.buffer.asUint8List(),
            );
            final image = (await codec.getNextFrame()).image;

            expect(
              image.width,
              (strip.frames * figure.frameSize).round(),
              reason: strip.file,
            );
            expect(image.height, figure.frameSize.round(), reason: strip.file);
          }
        }
      });
    });

    testWidgets('der Ausschnitt des Steins liegt genau um den Stein', (
      tester,
    ) async {
      // Stimmt er nicht, stehen zwischen den Wandblöcken Lücken — oder
      // der Stein ist angeschnitten.
      await tester.runAsync(() async {
        final data = await rootBundle.load(
          '${GrubeFiguren.folder}/${GrubeFiguren.stein}',
        );
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final image = (await codec.getNextFrame()).image;
        final rgba = (await image.toByteData())!;

        var links = image.width, oben = image.height, rechts = 0, unten = 0;
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            final alpha = rgba.getUint8((y * image.width + x) * 4 + 3);
            if (alpha == 0) continue;
            if (x < links) links = x;
            if (y < oben) oben = y;
            if (x + 1 > rechts) rechts = x + 1;
            if (y + 1 > unten) unten = y + 1;
          }
        }
        expect(
          Rect.fromLTRB(
            links.toDouble(),
            oben.toDouble(),
            rechts.toDouble(),
            unten.toDouble(),
          ),
          GrubeFiguren.steinAusschnitt,
        );
      });
    });

    test('jede Art in der Grube hat eine Figur', () {
      for (final kind in EnemyKind.values) {
        expect(GrubeFiguren.forKind(kind).has(Pose.idle), isTrue);
      }
    });

    test('die Füsse liegen im Bild, der Kopf darüber', () {
      for (final figure in GrubeFiguren.all) {
        expect(figure.footY, lessThanOrEqualTo(figure.frameSize));
        expect(figure.topY, lessThan(figure.footY));
        expect(figure.visibleHeight, greaterThan(0));
      }
    });
  });

  group('Welches Bild dran ist', () {
    const strip = SpriteStrip('x.png', 4, fps: 10);

    test('in Schleife beginnt der Streifen von vorn', () {
      expect(strip.frameAt(0), 0);
      expect(strip.frameAt(0.35), 3);
      expect(strip.frameAt(0.45), 0);
    });

    test('ohne Schleife bleibt er auf dem letzten Bild liegen', () {
      expect(strip.frameAt(0.45, loop: false), 3);
      expect(strip.frameAt(99, loop: false), 3);
    });
  });

  group('Welche Pose gilt', () {
    test('ein Schlag schlägt den Treffer, ein Treffer das Laufen', () {
      expect(
        poseFor(
          attackLeft: 0.1,
          attackPose: Pose.attack2,
          hurtLeft: 0.1,
          isMoving: true,
        ),
        Pose.attack2,
      );
      expect(
        poseFor(
          attackLeft: 0,
          attackPose: Pose.attack,
          hurtLeft: 0.1,
          isMoving: true,
        ),
        Pose.hurt,
      );
      expect(
        poseFor(
          attackLeft: 0,
          attackPose: Pose.attack,
          hurtLeft: 0,
          isMoving: true,
        ),
        Pose.walk,
      );
      expect(
        poseFor(
          attackLeft: 0,
          attackPose: Pose.attack,
          hurtLeft: 0,
          isMoving: false,
        ),
        Pose.idle,
      );
    });
  });

  group('Was eine Figur tut', () {
    const dt = 1 / 60;

    test('wer sich bewegt, läuft; wer steht, steht', () {
      final state = FigureState(Vec2.zero, figure: GrubeFiguren.fussvolk);
      var at = Vec2.zero;

      for (var i = 0; i < 30; i++) {
        at = at + const Vec2(1.5, 0); // 90 Punkte je Sekunde
        state.update(_view(at: at), dt);
      }
      expect(state.pose, Pose.walk);

      for (var i = 0; i < 30; i++) {
        state.update(_view(at: at), dt);
      }
      expect(state.pose, Pose.idle);
    });

    test('der Blick folgt der Richtung, rein senkrecht behält er sie', () {
      final state = FigureState(Vec2.zero, figure: GrubeFiguren.fussvolk);

      state.update(_view(at: Vec2.zero, facing: const Vec2(-1, 0)), dt);
      expect(state.facesLeft, isTrue);

      state.update(_view(at: Vec2.zero, facing: const Vec2(0, 1)), dt);
      expect(state.facesLeft, isTrue);

      state.update(_view(at: Vec2.zero, facing: const Vec2(1, 0.2)), dt);
      expect(state.facesLeft, isFalse);
    });

    test('ein Schlag dauert so lange wie sein Streifen, dann endet er', () {
      final figure = GrubeFiguren.fussvolk;
      final state = FigureState(Vec2.zero, figure: figure);
      state.swing(Pose.attack);

      final dauer = figure.stripFor(Pose.attack).duration;
      var zeit = 0.0;
      while (zeit < dauer - dt) {
        state.update(_view(at: Vec2.zero), dt);
        zeit += dt;
      }
      expect(state.pose, Pose.attack);

      for (var i = 0; i < 5; i++) {
        state.update(_view(at: Vec2.zero), dt);
      }
      expect(state.pose, Pose.idle);
    });

    test('ein Treffer lässt zucken, unterbricht aber keinen Schlag', () {
      final state = FigureState(Vec2.zero, figure: GrubeFiguren.held);

      state.hit();
      state.update(_view(at: Vec2.zero), dt);
      expect(state.pose, Pose.hurt);

      state.swing(Pose.attack);
      state.hit();
      state.update(_view(at: Vec2.zero), dt);
      expect(state.pose, Pose.attack);
    });
  });

  group('Wer fällt', () {
    test('kippt um, liegt, verblasst und verschwindet', () {
      final fallen = FallenFigure(
        figure: GrubeFiguren.fussvolk,
        at: Vec2.zero,
        facesLeft: false,
      );

      expect(fallen.opacity, 1);
      fallen.age = fallen.duration * 0.5;
      expect(fallen.opacity, 1);
      fallen.age = fallen.duration * 0.9;
      expect(fallen.opacity, inExclusiveRange(0, 1));
      fallen.age = fallen.duration;
      expect(fallen.isAlive, isFalse);
    });

    test('wer keinen Sterbe-Streifen hat, verschwindet trotzdem', () {
      final fallen = FallenFigure(
        figure: GrubeFiguren.schuetze,
        at: Vec2.zero,
        facesLeft: false,
      );

      expect(fallen.duration, FallenFigure.shrinkTime + FallenFigure.lieTime);
    });
  });
}
