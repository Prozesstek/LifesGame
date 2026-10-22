import 'package:action_combat/action_combat.dart';
import 'package:gear/gear.dart';

/// Was in einem Lauf an Beute gefallen ist (ADR-0083) — **reine
/// Rechnung, kein Widget**.
///
/// Die Grube weiß nur, *dass* etwas fällt ([ItemDropped]); was es ist,
/// würfelt hier `GearLoot.cascade` aus der Ebene, dem Startwert des Laufs
/// und der Nummer des Fundes. Gewürfelt wird **beim Fallen**, nicht erst
/// beim Einsammeln: Der Rand am Boden zeigt schon die Seltenheit, und eine
/// Lichtsäule steht nur über Legendärem.
class PitBeute {
  PitBeute({required this.stage, required this.run});

  /// Die Ebene, auf der gewürfelt wird — sie bestimmt die Seltenheit.
  final int stage;

  /// Der Startwert des Laufs; mit ihm sind die Uids eindeutig, auch wenn
  /// dieselbe Ebene am selben Tag zweimal gespielt wird.
  final int run;

  final Map<int, GearCopy> _funde = <int, GearCopy>{};
  final Map<int, GearRarity> _gewuenscht = <int, GearRarity>{};

  /// **Nur Entwicklermodus**: Der Fund mit der Nummer [nth] soll [rarity]
  /// haben. Muss vor dem Fallen gesagt werden — danach ist gewürfelt.
  void wuensche(int nth, GearRarity rarity) => _gewuenscht[nth] = rarity;

  /// Nimmt einen Fund aus der Grube auf und gibt zurück, was es ist.
  GearCopy fallen(ItemDropped fund) {
    return _funde.putIfAbsent(
      fund.nth,
      () => GearLoot.cascade(
        stage: stage,
        run: run,
        nth: fund.nth,
        boss: fund.boss,
        rarity: _gewuenscht[fund.nth],
      ),
    );
  }

  /// Was der Fund mit der Nummer [nth] ist, oder null, wenn er nicht
  /// gemeldet wurde.
  GearCopy? fund(int nth) => _funde[nth];

  /// Die Exemplare zu den eingesammelten Nummern, in derselben Reihenfolge.
  List<GearCopy> eingesammelt(List<int> nummern) => <GearCopy>[
    for (final n in nummern) ?_funde[n],
  ];
}
