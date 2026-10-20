import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Das Bestiarium: die Gegner der Sammlung (Issue #138).
void main() {
  group('Zählen und Stufen', () {
    test('ein leeres Bestiarium kennt keine Art', () {
      const leer = Bestiarium.leer();

      for (final art in Bestiarium.arten) {
        expect(leer.besiegt(art), 0);
        expect(leer.stufeVon(art), 0);
      }
      expect(leer.istLeer, isTrue);
    });

    test('Siege zählen sich zusammen', () {
      const sieben = <EnemyKind, int>{EnemyKind.fussvolk: 7};
      const fuenf = <EnemyKind, int>{EnemyKind.fussvolk: 5};
      final b = const Bestiarium.leer().mit(gegner: sieben).mit(gegner: fuenf);

      expect(b.besiegt(EnemyKind.fussvolk), 12);
      expect(b.stufeVon(EnemyKind.fussvolk), 2, reason: '1 und 10 erreicht');
    });

    test('Stufen: einmal, zehnmal, hundertmal', () {
      expect(Bestiarium.stufe(0, Bestiarium.stufenGegner), 0);
      expect(Bestiarium.stufe(1, Bestiarium.stufenGegner), 1);
      expect(Bestiarium.stufe(9, Bestiarium.stufenGegner), 1);
      expect(Bestiarium.stufe(10, Bestiarium.stufenGegner), 2);
      expect(Bestiarium.stufe(100, Bestiarium.stufenGegner), 3);
      expect(Bestiarium.stufe(5000, Bestiarium.stufenGegner), 3);
    });

    test('ein Wächter zählt einmal je Sieg', () {
      final b = const Bestiarium.leer()
          .mit(waechter: BossKind.ettin)
          .mit(waechter: BossKind.ettin);

      expect(b.besiegtWaechter(BossKind.ettin), 2);
      expect(b.stufeVonWaechter(BossKind.ettin), 1);
      expect(b.besiegtWaechter(BossKind.zyklop), 0);
    });

    test('was nicht gesammelt wird, fällt heraus', () {
      // Der Schleimling entsteht nur aus einem Schleim, der Wächter steht
      // als seine Art da, der Held trägt „keiner“.
      final b = const Bestiarium.leer().mit(
        gegner: <EnemyKind, int>{
          EnemyKind.schleimling: 4,
          EnemyKind.endgegner: 1,
          EnemyKind.keiner: 1,
        },
      );

      expect(b.istLeer, isTrue);
    });
  });

  group('Speichern', () {
    test('kommt so zurück, wie es hinging', () {
      const gegner = <EnemyKind, int>{
        EnemyKind.grimlock: 3,
        EnemyKind.heiler: 11,
      };
      final b = const Bestiarium.leer()
          .mit(gegner: gegner)
          .mit(waechter: BossKind.slaad);

      final zurueck = Bestiarium.fromJson(b.toJson());

      expect(zurueck.besiegt(EnemyKind.grimlock), 3);
      expect(zurueck.besiegt(EnemyKind.heiler), 11);
      expect(zurueck.besiegtWaechter(BossKind.slaad), 1);
    });

    test('liest nachsichtig: Unbekanntes und Unsinn fallen heraus', () {
      final b = Bestiarium.fromJson(<String, Object?>{
        'gegner': <String, Object?>{
          'gibt-es-nicht': 5,
          'fussvolk': 'viele',
          'schuetze': -2,
          'brocken': 4,
        },
        'waechter': 'kaputt',
      });

      expect(b.besiegt(EnemyKind.brocken), 4);
      expect(b.besiegt(EnemyKind.fussvolk), 0);
      expect(b.besiegt(EnemyKind.schuetze), 0);
      expect(Bestiarium.fromJson(null).istLeer, isTrue);
    });

    test('steht in der Reihe und überlebt sie', () {
      final reihe = const LadderProgress.empty().recordKills(
        <EnemyKind, int>{EnemyKind.flink: 6},
        waechter: BossKind.sumpftroll,
      );

      final zurueck = LadderProgress.fromJson(reihe.toJson());

      expect(zurueck.bestiarium.besiegt(EnemyKind.flink), 6);
      expect(zurueck.bestiarium.besiegtWaechter(BossKind.sumpftroll), 1);
    });

    test('ein Stand ohne Siege schreibt nichts dazu', () {
      final json = const LadderProgress.empty().toJson();

      expect(json.containsKey('kills'), isFalse);
    });

    test('ein anderer Schritt der Reihe vergisst es nicht', () {
      // `copyWith` statt Konstruktor (`gotchas.md`): Ein neues Feld darf
      // beim nächsten Sieg nicht still herausfallen.
      final reihe = const LadderProgress.empty()
          .recordKills(<EnemyKind, int>{EnemyKind.fussvolk: 2})
          .bookRun(1, won: true, collected: (xp: 0, gold: 0))
          .recordTime(1, 40)
          .recordDefeat(2);

      expect(reihe.bestiarium.besiegt(EnemyKind.fussvolk), 2);
    });
  });

  group('In der Welt', () {
    test('ein Lauf zählt je Art, was fiel, und den Wächter extra', () {
      final stage = PitStage(1);
      final welt = ActionWorld(
        level: LevelBuilder.build(stage: stage, seed: 7),
        heroStats: ActionStats.gereift,
        stage: stage,
        weaponMoveId: 'sword_strike',
        seed: 7,
      );
      PitBot.play(welt);

      final jeArt = welt.killsJeArt;
      final summe = jeArt.values.fold<int>(0, (a, b) => a + b);
      expect(jeArt.keys, isNot(contains(EnemyKind.endgegner)));
      expect(summe, lessThanOrEqualTo(welt.kills));
      expect(summe, greaterThan(0));
      if (welt.isWon) expect(welt.bossFiel, isTrue);
    });
  });
}
