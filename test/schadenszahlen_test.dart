import 'package:action_combat/action_combat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/damage_popup.dart';
import 'package:lifes_game/ui/palette.dart';

void main() {
  HitLanded treffer({
    int amount = 12,
    int targetId = 2,
    bool isCrit = false,
    bool overTime = false,
    Faction target = Faction.gegner,
  }) {
    return HitLanded(
      targetId: targetId,
      targetFaction: target,
      at: const Vec2(100, 100),
      amount: amount,
      isCrit: isCrit,
      overTime: overTime,
    );
  }

  group('eine Zahl', () {
    test('ploppt gross auf und setzt sich sofort', () {
      final popup = DamagePopup.forHit(treffer())!;

      expect(popup.size, closeTo(DamagePopup.popScale, 0.001));

      popup.update(DamagePopup.popTime);
      expect(popup.size, popup.scale);
    });

    test('fliegt im Bogen: erst hoch, am Ende wieder ein Stück herab', () {
      final popup = DamagePopup.forHit(treffer(), side: 1)!;
      final start = popup.position;

      popup.update(DamagePopup.lifetime * 0.66);
      final scheitel = popup.position;
      popup.update(DamagePopup.lifetime * 0.33);
      final ende = popup.position;

      expect(scheitel.y, lessThan(start.y));
      expect(ende.y, greaterThan(scheitel.y));
      expect(ende.y, lessThan(start.y), reason: 'nie unter den Treffer');
      expect(ende.x, greaterThan(start.x));
    });

    test('steht voll da und verblasst erst am Ende', () {
      final popup = DamagePopup.forHit(treffer())!;

      popup.update(DamagePopup.lifetime * (DamagePopup.fadeFrom - 0.01));
      expect(popup.opacity, 1);

      popup.update(DamagePopup.lifetime * 0.2);
      expect(popup.opacity, inExclusiveRange(0, 1));
    });

    test('Heilung, Zeit und Beute steigen gerade', () {
      final popup = DamagePopup.forHeal(5, const Vec2(100, 100));

      popup.update(DamagePopup.lifetime / 2);

      expect(popup.position.x, 100);
      expect(popup.tilt, 0);
    });

    test('ein kritischer Treffer steht schräg und zittert kurz', () {
      final popup = DamagePopup.forHit(treffer(isCrit: true))!;
      final normal = DamagePopup.forHit(treffer())!;

      expect(popup.tilt, isNot(0));
      expect(normal.tilt, 0);

      popup.update(0.02);
      normal.update(0.02);
      expect(popup.position.x, isNot(normal.position.x));

      popup.update(DamagePopup.shakeTime);
      normal.update(DamagePopup.shakeTime);
      expect(popup.position.x, normal.position.x);
    });
  });

  group('eine Farbe je Sache', () {
    test('Schlag, Dauerschaden, kritisch und Held sind vier Farben', () {
      final farben = <Object>{
        DamagePopup.colorOf(treffer()),
        DamagePopup.colorOf(treffer(overTime: true)),
        DamagePopup.colorOf(treffer(isCrit: true)),
        DamagePopup.colorOf(treffer(target: Faction.held)),
      };

      expect(farben, hasLength(4));
    });

    test('Dauerschaden sieht nie aus wie Heilung', () {
      final heilung = DamagePopup.forHeal(5, const Vec2(0, 0));

      expect(
        DamagePopup.colorOf(treffer(overTime: true)),
        isNot(heilung.color),
      );
      expect(heilung.color, Palette.successOnDark);
    });
  });

  group('Grösse folgt dem Schnitt der letzten Treffer', () {
    test('ohne Vorgeschichte ist jeder Treffer normal', () {
      expect(HitAverage().scaleFor(500), 1);
    });

    test('derselbe Treffer ist früh gross und spät klein', () {
      final frueh = HitAverage()..record(10);
      final spaet = HitAverage()..record(400);

      expect(frueh.scaleFor(40), greaterThan(1));
      expect(spaet.scaleFor(40), lessThan(1));
    });

    test('sie bleibt in ihren Grenzen', () {
      final schnitt = HitAverage()..record(10);

      expect(schnitt.scaleFor(10000), HitAverage.biggest);
      expect(schnitt.scaleFor(1), HitAverage.smallest);
    });

    test('nur die letzten Treffer zählen', () {
      final schnitt = HitAverage();
      for (var i = 0; i < 50; i++) {
        schnitt.record(10);
      }
      for (var i = 0; i < 12; i++) {
        schnitt.record(100);
      }

      expect(schnitt.value, 100);
    });

    test('Dauerschaden zieht den Schnitt nicht herunter', () {
      final zahlen = DamagePopups()..hit(treffer(amount: 20));
      for (var i = 0; i < 20; i++) {
        zahlen
          ..update(DamagePopup.lifetime)
          ..hit(treffer(amount: 1, overTime: true));
      }
      zahlen
        ..update(DamagePopup.lifetime)
        ..hit(treffer(amount: 20));

      expect(zahlen.live.single.scale, 1);
    });
  });

  group('alle Zahlen zusammen', () {
    test('Treffer wechseln die Seite', () {
      final zahlen = DamagePopups()
        ..hit(treffer(targetId: 1))
        ..hit(treffer(targetId: 2));

      expect(zahlen.live.first.side, -zahlen.live.last.side);
      expect(zahlen.live.first.side, isNot(0));
    });

    test('was zugleich auf denselben Gegner fällt, wird eine Summe', () {
      final zahlen = DamagePopups()
        ..hit(treffer(amount: 12))
        ..update(0.1)
        ..hit(treffer(amount: 8));

      expect(zahlen.count, 1);
      expect(zahlen.live.single.text, '20');
      expect(
        zahlen.live.single.size,
        greaterThan(zahlen.live.single.scale),
        reason: 'die Summe ploppt noch einmal',
      );
    });

    test(
      'siebenhundert Treffer in einer Sekunde sind eine Handvoll Zahlen',
      () {
        final zahlen = DamagePopups();
        var groesste = 0;
        for (var i = 0; i < 700; i++) {
          zahlen
            ..hit(treffer(amount: 3))
            ..update(1 / 700);
          if (zahlen.count > groesste) groesste = zahlen.count;
        }

        expect(groesste, lessThanOrEqualTo(4));
      },
    );

    test('der Schlag im eigenen Takt bleibt seine eigene Zahl', () {
      final zahlen = DamagePopups()
        ..hit(treffer())
        ..update(DamagePopup.mergeWindow + 0.05)
        ..hit(treffer());

      expect(zahlen.count, 2);
    });

    test('eine Summe lebt nicht länger als eine Zahl', () {
      final zahlen = DamagePopups()
        ..hit(treffer())
        ..update(DamagePopup.mergeWindow - 0.01)
        ..hit(treffer())
        ..update(DamagePopup.lifetime - DamagePopup.mergeWindow + 0.02);

      expect(zahlen.count, 0);
    });

    test(
      'verschiedene Gegner, Dauerschaden und kritische bleiben getrennt',
      () {
        final zahlen = DamagePopups()
          ..hit(treffer(targetId: 1))
          ..hit(treffer(targetId: 2))
          ..hit(treffer(targetId: 1, overTime: true))
          ..hit(treffer(targetId: 1, isCrit: true));

        expect(zahlen.count, 4);
      },
    );

    test('ein Schlag ohne Wirkung bekommt keine Null', () {
      final zahlen = DamagePopups()..hit(treffer(amount: 0));

      expect(zahlen.count, 0);
    });

    test('es stehen nie mehr als die Obergrenze da', () {
      final zahlen = DamagePopups();
      for (var i = 0; i < DamagePopups.maxLive * 3; i++) {
        zahlen.hit(treffer(targetId: i));
      }

      expect(zahlen.count, DamagePopups.maxLive);
      expect(zahlen.live.last.mergeKey, (
        DamagePopups.maxLive * 3 - 1,
        false,
        false,
      ), reason: 'die älteste geht, die neueste bleibt');
    });
  });
}
