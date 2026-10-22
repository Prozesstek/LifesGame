import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Erfahrung und Gold je Gegner (ADR-0041): derselbe Betrag wie vorher
/// am Ende, nur anders ausgegeben.
void main() {
  /// Vier Fussvolk vor einem Tor, der Wächter dahinter. Der Held bleibt
  /// draussen — so fällt das Fussvolk, und der Wächter schläft.
  final vorraum = Level.parse('Vorraum', const <String>[
    '##############',
    '#.e..@....e..#',
    '#....e...e...#',
    '#######==#####',
    '#............#',
    '#......B.....#',
    '##############',
  ]);

  const riese = ActionStats(
    attack: 400,
    maxHp: 99999,
    defense: 200,
    energy: 16,
  );

  List<LootDropped> laufe(ActionWorld welt, Vec2 eingabe, int schritte) {
    final beute = <LootDropped>[];
    for (var i = 0; i < schritte && !welt.isOver; i++) {
      welt.step(eingabe);
      beute.addAll(welt.drainEvents().whereType<LootDropped>());
    }
    return beute;
  }

  group('In der Grube', () {
    test('jeder Gegner bringt seinen Teil, der Wächter den Rest', () {
      final welt = ActionWorld(
        level: vorraum,
        heroStats: riese,
        rewardPot: (xp: 100, gold: 40),
      );

      // Draussen bleiben, bis das Fussvolk liegt.
      final draussen = laufe(welt, Vec2.zero, 60 * 10);
      expect(draussen, hasLength(4));
      expect(welt.runXp, 70);
      expect(welt.runGold, 28);
      expect(
        draussen.fold<int>(0, (s, e) => s + e.xp),
        welt.runXp,
        reason: 'Was fällt, ist, was zählt.',
      );

      // Hinein und den Wächter fällen: Der Topf ist voll.
      final drinnen = <LootDropped>[];
      for (var i = 0; i < 60 * 20 && !welt.isOver; i++) {
        final ziel = welt.sleepingBossAt ?? welt.bossView?.position;
        final held = welt.heroView.position;
        welt.step(
          ziel == null ? Vec2.zero : welt.fieldTo(ziel).directionFrom(held),
        );
        drinnen.addAll(welt.drainEvents().whereType<LootDropped>());
      }
      expect(welt.isOver, isTrue);
      expect(drinnen, hasLength(1));
      expect(welt.runXp, 100);
      expect(welt.runGold, 40);
    });

    test('ohne Topf fällt nichts', () {
      final welt = ActionWorld(level: vorraum, heroStats: riese);
      expect(laufe(welt, Vec2.zero, 60 * 10), isEmpty);
      expect(welt.runXp, 0);
    });
  });

  group('Der Topf einer Stufe', () {
    test('verloren bringt nichts — gewonnen den ganzen Topf (ADR-0084)', () {
      const vorher = LadderProgress(highestDefeated: 6);
      final voll = LadderRewards.xpFor(7);

      final verloren = vorher.bookRun(7, won: false);
      expect(verloren.earnedXp, vorher.earnedXp);
      expect(verloren.earnedGold, vorher.earnedGold);
      expect(verloren.highestDefeated, 6);
      expect(verloren.defeatsAt(7), 1);
      expect(
        verloren.potFor(7).xp,
        voll,
        reason: 'Der nächste Versuch spielt um den ganzen Topf.',
      );

      final gewonnen = verloren.bookRun(7, won: true);
      expect(gewonnen.earnedXp, vorher.earnedXp + voll);
      expect(gewonnen.highestDefeated, 7);
    });

    test('eine längst geschaffte Stufe hat keinen Topf', () {
      const stand = LadderProgress(highestDefeated: 30);
      for (var stufe = 1; stufe <= 30; stufe++) {
        expect(stand.potFor(stufe), (xp: 0, gold: 0), reason: 'Stufe $stufe');
      }
    });

    test('Teile aus alten Ständen zählen weiter — nie mehr als der Topf', () {
      // Bis ADR-0084 behielt ein verlorener Lauf, was gefallen war. Was
      // ein Stand so verdient hat, bleibt, sonst fiele ein Level.
      final alt = LadderProgress.fromJson(<String, Object?>{
        'defeated': 6,
        'partial': <String, Object?>{
          '7': <int>[20, 5],
        },
      });
      const ohne = LadderProgress(highestDefeated: 6);
      expect(alt.earnedXp, ohne.earnedXp + 20);
      expect(alt.potFor(7).xp, LadderRewards.xpFor(7) - 20);
      expect(LadderProgress.fromJson(alt.toJson()).earnedXp, alt.earnedXp);

      // Eine neue Niederlage legt nichts dazu.
      expect(alt.bookRun(7, won: false).earnedXp, alt.earnedXp);
      // Der Sieg bringt den Rest, zusammen genau den Topf.
      expect(
        alt.bookRun(7, won: true).earnedXp,
        ohne.earnedXp + LadderRewards.xpFor(7),
      );

      final erfunden = LadderProgress.fromJson(<String, Object?>{
        'defeated': 6,
        'partial': <String, Object?>{
          '7': <int>[99999, 99999],
        },
      });
      expect(
        erfunden.earnedXp,
        const LadderProgress(highestDefeated: 6).earnedXp +
            LadderRewards.xpFor(7),
      );
    });
  });
}
