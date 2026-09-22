import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Erfahrung und Gold je Gegner (ADR-0041): derselbe Betrag wie vorher
/// am Ende, nur anders ausgegeben.
void main() {
  const tag = 20718;

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
    test('verloren behält man, was gefallen ist — gewonnen den Rest', () {
      const vorher = LadderProgress(highestDefeated: 6);
      final voll = LadderRewards.xpFor(7);

      final verloren = vorher.bookRun(
        tag,
        7,
        won: false,
        collected: (xp: 20, gold: 5),
        dailyAllowed: true,
      );
      expect(verloren.earnedXp, vorher.earnedXp + 20);
      expect(verloren.highestDefeated, 6);
      expect(
        verloren.potFor(tag, 7, dailyAllowed: true).xp,
        voll - 20,
        reason: 'Der nächste Versuch füllt nur den Rest.',
      );

      final gewonnen = verloren.bookRun(
        tag,
        7,
        won: true,
        collected: verloren.potFor(tag, 7, dailyAllowed: true),
        dailyAllowed: true,
      );
      // **Genau so viel wie vorher am Ende** — nicht mehr, nicht weniger.
      expect(gewonnen.earnedXp, vorher.earnedXp + voll);
      expect(gewonnen.highestDefeated, 7);
    });

    test('mehr als der Topf zählt nie', () {
      const vorher = LadderProgress(highestDefeated: 6);
      final gierig = vorher.bookRun(
        tag,
        7,
        won: false,
        collected: (xp: 99999, gold: 99999),
        dailyAllowed: true,
      );
      expect(gierig.earnedXp, vorher.earnedXp + LadderRewards.xpFor(7));
      expect(gierig.potFor(tag, 7, dailyAllowed: true), (xp: 0, gold: 0));
    });

    test('eine längst geschaffte Stufe ausserhalb der Dailies hat keinen Topf',
        () {
      const stand = LadderProgress(highestDefeated: 30);
      final heute = stand.dailiesOn(tag);
      final andere = List<int>.generate(30, (i) => i + 1)
          .firstWhere((s) => !heute.contains(s));
      expect(stand.potFor(tag, andere, dailyAllowed: true), (xp: 0, gold: 0));
    });

    test('ein Daily zahlt ohne Häkchen nichts, mit Häkchen sein Viertel', () {
      const stand = LadderProgress(highestDefeated: 20);
      final daily = stand.dailiesOn(tag).first;

      expect(stand.potFor(tag, daily, dailyAllowed: false), (xp: 0, gold: 0));
      expect(
        stand.potFor(tag, daily, dailyAllowed: true),
        (
          xp: LadderRewards.dailyXpFor(daily),
          gold: LadderRewards.dailyGoldFor(daily),
        ),
      );
    });

    test('ein Daily in zwei Läufen zahlt so viel wie in einem', () {
      const stand = LadderProgress(highestDefeated: 20);
      final daily = stand.dailiesOn(tag).first;

      final halb = stand.bookRun(
        tag,
        daily,
        won: false,
        collected: (xp: 3, gold: 1),
        dailyAllowed: true,
      );
      final ganz = halb.bookRun(
        tag,
        daily,
        won: true,
        collected: halb.potFor(tag, daily, dailyAllowed: true),
        dailyAllowed: true,
      );
      expect(ganz.earnedXp, stand.earnedXp + LadderRewards.dailyXpFor(daily));
      expect(ganz.isDailyCleared(tag, daily), isTrue);
    });

    test('Teile überleben einen Neustart — und nie mehr als der Topf', () {
      final stand = const LadderProgress(highestDefeated: 6).bookRun(
        tag,
        7,
        won: false,
        collected: (xp: 20, gold: 5),
        dailyAllowed: true,
      );
      expect(LadderProgress.fromJson(stand.toJson()).earnedXp, stand.earnedXp);

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
