import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

double _schlagkraft(PitAbility a) {
  var summe = 0.0;
  for (final e in a.effects) {
    summe += switch (e) {
      BoltAtNearest(:final power) => power,
      StrikeNearest(:final power) => power,
      StrikeAround(:final power) => power,
      _ => 0,
    };
  }
  return summe;
}

void main() {
  group('Eine Veränderung trifft nur ihre Art', () {
    test('mehr Schaden auf Angriffe lässt Schutz unberührt', () {
      const mod = <PitModifier>[
        ScaleDamage(factor: 1.25, kind: PitKind.angriff),
      ];

      final funke = PitModifiers.apply(PitAbilities.funkenstoss, mod);
      final haut = PitModifiers.apply(PitAbilities.steinhaut, mod);

      expect(
        _schlagkraft(funke),
        closeTo(_schlagkraft(PitAbilities.funkenstoss) * 1.25, 1e-9),
      );
      expect(haut.effects, PitAbilities.steinhaut.effects);
    });

    test('Rabatt auf Umgebungen macht Frostnebel billiger, Funken nicht', () {
      const mod = <PitModifier>[
        ReduceManaCost(amount: 10, kind: PitKind.umgebung),
      ];

      expect(
        PitModifiers.apply(PitAbilities.frostnebel, mod).manaCost,
        PitAbilities.frostnebel.manaCost - 10,
      );
      expect(
        PitModifiers.apply(PitAbilities.funkenstoss, mod).manaCost,
        PitAbilities.funkenstoss.manaCost,
      );
    });

    test('Mana fällt nie unter null', () {
      const mod = <PitModifier>[ReduceManaCost(amount: 999)];
      for (final a in PitAbilities.all) {
        expect(PitModifiers.apply(a, mod).manaCost, 0, reason: a.id);
      }
    });

    test('Schutz heilt stärker und hält länger', () {
      const mod = <PitModifier>[
        ScaleProtection(factor: 1.6, kind: PitKind.schutz),
      ];

      final tau = PitModifiers.apply(PitAbilities.bluetentau, mod);
      final haut = PitModifiers.apply(PitAbilities.steinhaut, mod);

      expect((tau.effects.single as HealSelf).share, closeTo(0.4, 1e-9));
      expect((haut.effects.single as ReduceIncoming).seconds, closeTo(8, 1e-9));
      // Die Stärke der Minderung bleibt — nur die Dauer wächst. Sonst
      // führe ein Set mit einer Fähigkeit zu Unverwundbarkeit.
      expect(
        (haut.effects.single as ReduceIncoming).factor,
        (PitAbilities.steinhaut.effects.single as ReduceIncoming).factor,
      );
    });

    test('Dauerschaden lässt direkte Treffer unberührt', () {
      const mod = <PitModifier>[ScaleOverTime(factor: 2)];
      final lava = PitModifiers.apply(PitAbilities.vulkanbruch, mod);

      expect(_schlagkraft(lava), _schlagkraft(PitAbilities.vulkanbruch));
      final dot = lava.effects.whereType<DamageOverTime>().single;
      expect(dot.perSecond, closeTo(0.8, 1e-9));
    });

    test('zusätzliche Wirkungen nur an der genannten Fähigkeit', () {
      const mod = <PitModifier>[
        AddEffects(
          abilityId: 'steinhaut',
          effects: <PitEffect>[GainMana(amount: 5)],
        ),
      ];

      expect(
        PitModifiers.apply(PitAbilities.steinhaut, mod).effects,
        hasLength(2),
      );
      expect(
        PitModifiers.apply(PitAbilities.bluetentau, mod).effects,
        hasLength(1),
      );
    });

    test('Faktoren multiplizieren sich, in jeder Reihenfolge gleich', () {
      const a = ScaleDamage(factor: 1.1);
      const b = ScaleDamage(factor: 1.25);

      final ab = PitModifiers.apply(PitAbilities.donnerkeil, const [a, b]);
      final ba = PitModifiers.apply(PitAbilities.donnerkeil, const [b, a]);

      expect(_schlagkraft(ab), closeTo(_schlagkraft(ba), 1e-9));
      expect(_schlagkraft(ab), closeTo(3.0 * 1.1 * 1.25, 1e-9));
    });

    test('der Katalog selbst bleibt unverändert', () {
      final vorher = PitAbilities.donnerkeil.effects;
      PitModifiers.apply(
        PitAbilities.donnerkeil,
        const <PitModifier>[ScaleDamage(factor: 9)],
      );
      expect(PitAbilities.donnerkeil.effects, same(vorher));
    });
  });

  group('Die Welt sieht die veränderte Fähigkeit', () {
    test('ein Rabatt kommt im Lauf an', () {
      final welt = ActionWorld(
        level: LevelCatalog.grube,
        heroStats: ActionStats.frisch,
        abilityIds: const <String>['steinhaut'],
        modifiers: const <PitModifier>[ReduceManaCost(amount: 20)],
      );

      expect(welt.slots.single.manaCost, 0);
      expect(welt.cast('steinhaut'), isTrue);
      expect(welt.mana, welt.maxMana);
    });

    test('Weitblick verkürzt die Abklingzeit im Lauf', () {
      final welt = ActionWorld(
        level: LevelCatalog.grube,
        heroStats: ActionStats.frisch,
        abilityIds: const <String>['steinhaut'],
        modifiers: PitLegendaries.weitblick.modifiers,
      );
      expect(
        welt.slots.single.cooldown,
        closeTo(PitAbilities.steinhaut.cooldown * 0.8, 1e-9),
      );
    });
  });

  group('Die legendären Kräfte', () {
    test('eindeutige Ids, und jede verändert etwas', () {
      final ids = PitLegendaries.all.map((l) => l.id).toList();
      expect(ids.toSet(), hasLength(ids.length));

      for (final kraft in PitLegendaries.all) {
        final veraendert = PitAbilities.all.any((a) {
          final b = PitModifiers.apply(a, kraft.modifiers);
          return b.manaCost != a.manaCost ||
              b.cooldown != a.cooldown ||
              !_gleich(a, b);
        });
        expect(veraendert, isTrue, reason: kraft.id);
      }
    });

    test('jede Fähigkeit, die eine Kraft nennt, gibt es', () {
      for (final kraft in PitLegendaries.all) {
        for (final mod in kraft.modifiers.whereType<AddEffects>()) {
          expect(
            PitAbilities.byId(mod.abilityId),
            isNotNull,
            reason: '${kraft.id} → ${mod.abilityId}',
          );
        }
      }
    });
  });
}

/// Ob zwei Fähigkeiten dieselben Zahlen tragen — über alle Wirkungen.
bool _gleich(PitAbility a, PitAbility b) {
  String zahlen(PitEffect e) => switch (e) {
        BoltAtNearest(:final power, :final range, :final leech) =>
          'b$power/$range/$leech',
        StrikeNearest(:final power, :final range) => 'n$power/$range',
        StrikeAround(:final power, :final radius) => 'a$power/$radius',
        HealSelf(:final share) => 'h$share',
        GainMana(:final amount) => 'm$amount',
        ReduceIncoming(:final factor, :final seconds) => 'r$factor/$seconds',
        ReflectIncoming(:final share, :final seconds) => 'x$share/$seconds',
        SlowAround(:final radius, :final factor, :final seconds) =>
          's$radius/$factor/$seconds',
        DamageOverTime(:final radius, :final perSecond, :final seconds) =>
          'd$radius/$perSecond/$seconds',
      };
  return a.effects.map(zahlen).join() == b.effects.map(zahlen).join();
}
