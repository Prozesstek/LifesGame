import 'package:combat/combat.dart';

/// Was ein Zug tut — in Worten, mit den Zahlen dieses Charakters.
///
/// **Die Formulierungen stammen aus der Vorlage**
/// (`docs/vorlagen/faehigkeiten.md`), die Zahlen nicht: Die Vorlage rechnet
/// mit einem Angriffswert von 16, das Spiel mit 13 bis 20. Hier wird
/// deshalb eingesetzt, was der Zug bei *diesem* Angriffswert anrichtet.
///
/// **Alle Zahlen sind flach.** Keine Verteidigung, keine Streuung, kein
/// Timing — es ist die obere Schranke, nicht der Erwartungswert. Deshalb
/// steht überall „etwa". Gerechnet wird in `package:combat`
/// ([Move.flatDamage], [flatFromFactor]); hier wird nur eingesetzt.
class MoveHelp {
  const MoveHelp({required this.effect, this.perfect});

  /// Was der Zug immer tut.
  final String effect;

  /// Was ein perfekter Treffer daran ändert. Null, wenn nichts.
  final String? perfect;
}

/// Der Hilfetext zu [move] für einen Charakter mit [attack] Angriff.
///
/// Unbekannte Ids bekommen eine knappe, erzeugte Zeile statt gar nichts —
/// ein neuer Move soll erklärbar sein, auch bevor jemand einen Text dafür
/// geschrieben hat.
MoveHelp moveHelpFor(Move move, int attack) {
  final schaden = move.flatDamage(attack);
  final perfekt = move.flatPerfectDamage(attack);

  return switch (move.id) {
    // --- Die Waffen (ADR-0017) ---
    //
    // Die Vorlage kennt sie nicht; ihr Unterschied ist der Rhythmus, nicht
    // die Wirkung. Deshalb steht hier, was sie an Energie bringen.
    'basic_attack' => MoveHelp(
      effect: 'Etwa $schaden Schaden. Bringt Energie für teure Fähigkeiten.',
      perfect: 'Etwa $perfekt Schaden.',
    ),
    'sword_strike' => MoveHelp(
      effect: 'Etwa $schaden Schaden. Trifft hart, baut Energie langsam auf.',
      perfect: 'Etwa $perfekt Schaden.',
    ),
    'dagger_double' => MoveHelp(
      effect: 'Etwa $schaden Schaden. Wenig Wucht, dafür schnell Energie.',
      perfect: 'Etwa $perfekt Schaden.',
    ),
    'mace_bash' => MoveHelp(
      effect:
          'Etwa $schaden Schaden und senkt die Verteidigung des Gegners '
          'für ${_defenseDownTurns()} Runden.',
      perfect: 'Etwa $perfekt Schaden.',
    ),
    'staff_gather' => MoveHelp(
      effect: 'Etwa $schaden Schaden. Der Motor: bringt am meisten Energie.',
      perfect: 'Etwa $perfekt Schaden.',
    ),

    // --- Common ---
    'funkenstoss' => MoveHelp(
      effect: 'Etwa $schaden Schaden.',
      perfect:
          'Etwa $perfekt Schaden und '
          '${_burnChance(move)} % Chance auf Brand '
          '(${_burnPerTurn(move, attack)} pro Runde, '
          '${_burnTurns(move)} Runden).',
    ),
    'steinhaut' => MoveHelp(
      effect:
          'Eingehender Schaden ${_reduction(move.effects)} für '
          '${_reduceTurns(move.effects)} Runde.',
      perfect:
          '${_reduction(move.perfectEffects)} statt '
          '${_reduction(move.effects)}, und '
          '${_reflectFlat(move.perfectEffects)} Schaden werden '
          'zurückgeworfen.',
    ),
    'wurzelgriff' => MoveHelp(
      effect:
          'Etwa $schaden Schaden. Das Perfect-Fenster des Gegners '
          'schrumpft um ${_windowShrink(move.effects)} für '
          '${_shrinkTurns(move.effects)} Runden.',
      perfect:
          '${_shrinkTurns(move.perfectEffects)} Runden statt '
          '${_shrinkTurns(move.effects)}.',
    ),
    'aurastrom' => MoveHelp(
      effect: '+${move.energyDelta} Energie. Kostet nichts.',
      perfect:
          '+${move.energyDelta + _energyGain(move.perfectEffects)} Energie, '
          'und die nächste Fähigkeit kostet '
          '${_cheapenAmount(move.perfectEffects)} weniger.',
    ),

    // --- Uncommon ---
    'bluetentau' => MoveHelp(
      effect: 'Heilt etwa ${_healAmount(move.effects, attack)} Leben.',
      perfect:
          'Heilt etwa '
          '${_healAmount(move.effects, attack) + _healAmount(move.perfectEffects, attack)} '
          'Leben und entfernt einen negativen Effekt.',
    ),
    'klingenwirbel' => MoveHelp(
      effect:
          '${move.hits} Treffer zu je etwa $schaden Schaden — '
          'du tippst ${move.hits} Mal.',
      perfect:
          'Jeder perfekte Tipp macht aus seinem Treffer etwa $perfekt '
          'Schaden. Sind alle ${move.hits} perfekt, kommt ein '
          'Bonustreffer dazu.',
    ),
    'frostnebel' => MoveHelp(
      effect: _environmentLine(move.effects, attack),
      perfect: _environmentPerfect(move.perfectEffects),
    ),
    'prisma_barriere' => MoveHelp(
      effect:
          'Wirft ${_reflectShare(move.effects)} des erlittenen Schadens '
          'zurück, ${_reflectTurns(move.effects)} Runden.',
      perfect:
          '${_reflectShare(move.perfectEffects)} statt '
          '${_reflectShare(move.effects)}.',
    ),

    // --- Rare ---
    'donnerkeil' => MoveHelp(
      effect: 'Etwa $schaden Schaden.',
      perfect:
          'Etwa $perfekt Schaden, und der Gegner bekommt eine Runde lang '
          'keinen Timing-Bonus.',
    ),
    'sandsturm' => MoveHelp(
      effect: _environmentLine(move.effects, attack),
      perfect: _environmentPerfect(move.perfectEffects),
    ),
    'seelenraub' => MoveHelp(
      effect:
          'Etwa $schaden Schaden, und du heilst dich um den vollen '
          'angerichteten Schaden.',
      perfect:
          'Etwa $perfekt Schaden, du heilst dich um das Anderthalbfache '
          'davon und stiehlst ${_stolenEnergy(move.perfectEffects)} '
          'Energie.',
    ),
    'giftmoor' => MoveHelp(
      effect: _environmentLine(move.effects, attack),
      perfect: _environmentPerfect(move.perfectEffects),
    ),

    // --- Epic ---
    'zeitdehnung' => MoveHelp(
      effect:
          'Deine Leiste läuft ${_dilateTurns(move.effects)} Runden halb so '
          'schnell — viel leichter zu treffen. Perfekte Treffer machen in '
          'dieser Zeit zusätzlich '
          '${_dilateBonus(move.effects)} Schaden.',
      perfect:
          '${_dilateTurns(move.perfectEffects)} Runden statt '
          '${_dilateTurns(move.effects)}.',
    ),
    'vulkanbruch' => MoveHelp(
      effect:
          'Etwa $schaden Schaden. '
          '${_environmentLine(move.effects, attack)}',
      perfect:
          'Etwa $perfekt Schaden. '
          '${_environmentPerfect(move.perfectEffects)}',
    ),

    // --- Legendary ---
    'sternenfall' => MoveHelp(
      effect:
          'Etwa $schaden Schaden. Verfehlt: nur etwa '
          '${flatFromFactor(move.power * (move.missFactor ?? 1), attack)}.',
      perfect: 'Etwa $perfekt Schaden, und jeder Schutz wird ignoriert.',
    ),

    // Kein geschriebener Text: wenigstens die Zahlen.
    _ => MoveHelp(
      effect: move.dealsDamage
          ? 'Etwa $schaden Schaden.'
          : 'Richtet keinen direkten Schaden an.',
      perfect: move.dealsDamage ? 'Etwa $perfekt Schaden.' : null,
    ),
  };
}

// --- Ablesehilfen ---
//
// Sie holen eine Zahl aus einer Wirkungsliste, statt sie hier noch einmal
// hinzuschreiben. Der Grund ist derselbe wie ueberall: Wer im Katalog eine
// Zahl aendert, soll den Hilfetext nicht nachziehen muessen.

T? _first<T extends MoveEffect>(List<MoveEffect> effects) {
  for (final effect in effects) {
    if (effect is T) return effect;
  }
  return null;
}

/// Ein Faktor kleiner 1 als Minus-Prozent: 0.6 wird zu „−40 %".
String _reduction(List<MoveEffect> effects) {
  final effect = _first<ReduceIncoming>(effects);
  if (effect == null) return '−0 %';
  return '−${((1 - effect.factor) * 100).round()} %';
}

int _reduceTurns(List<MoveEffect> effects) =>
    _first<ReduceIncoming>(effects)?.turns ?? 0;

String _windowShrink(List<MoveEffect> effects) {
  final effect = _first<ShrinkEnemyWindow>(effects);
  if (effect == null) return '0 %';
  return '${((1 - effect.factor) * 100).round()} %';
}

int _shrinkTurns(List<MoveEffect> effects) =>
    _first<ShrinkEnemyWindow>(effects)?.turns ?? 0;

String _reflectShare(List<MoveEffect> effects) {
  final effect = _first<ReflectIncoming>(effects);
  if (effect == null) return '0 %';
  return '${(effect.share * 100).round()} %';
}

int _reflectTurns(List<MoveEffect> effects) =>
    _first<ReflectIncoming>(effects)?.turns ?? 0;

int _reflectFlat(List<MoveEffect> effects) =>
    _first<ReflectIncoming>(effects)?.flatBonus ?? 0;

int _energyGain(List<MoveEffect> effects) =>
    _first<GainEnergy>(effects)?.amount ?? 0;

int _cheapenAmount(List<MoveEffect> effects) =>
    _first<CheapenNext>(effects)?.amount ?? 0;

int _stolenEnergy(List<MoveEffect> effects) =>
    _first<StealEnergy>(effects)?.amount ?? 0;

int _healAmount(List<MoveEffect> effects, int attack) {
  final effect = _first<HealSelfBy>(effects);
  if (effect == null) return 0;
  return flatFromFactor(effect.factor, attack);
}

int _burnChance(Move move) {
  final effect = _first<ApplyBurn>(move.perfectEffects);
  return ((effect?.chance ?? 0) * 100).round();
}

int _burnPerTurn(Move move, int attack) {
  final effect = _first<ApplyBurn>(move.perfectEffects);
  if (effect == null) return 0;
  return flatFromFactor(effect.damageFactor, attack);
}

int _burnTurns(Move move) => _first<ApplyBurn>(move.perfectEffects)?.turns ?? 0;

int _dilateTurns(List<MoveEffect> effects) =>
    _first<DilateTime>(effects)?.turns ?? 0;

String _dilateBonus(List<MoveEffect> effects) {
  final effect = _first<DilateTime>(effects);
  if (effect == null) return '0 %';
  return '+${(effect.perfectBonus * 100).round()} %';
}

int _defenseDownTurns({Balance balance = const Balance()}) =>
    balance.defenseDownDurationTurns;

/// Was eine Umgebung tut, in einem Satz.
///
/// Erzeugt statt geschrieben: Die vier Umgebungen unterscheiden sich nur
/// in Zahlen, und diese Zahlen stehen in `environment.dart`. Ein
/// geschriebener Satz je Umgebung wäre eine zweite Wahrheit über
/// dieselben Werte.
String _environmentLine(List<MoveEffect> effects, int attack) {
  final gelegt = _first<SetEnvironment>(effects);
  final feld = gelegt == null ? null : Environments.byId(gelegt.environmentId);
  if (feld == null) return 'Verändert das Feld.';

  final teile = <String>[];

  final dot = flatFromFactor(feld.dotFactorOnEnemy, attack);
  if (dot > 0) {
    final wachstum = flatFromFactor(feld.dotGrowthPerTurn, attack);
    teile.add(
      wachstum > 0
          ? 'der Gegner verliert etwa $dot Leben pro Runde, steigend um '
                'etwa $wachstum'
          : 'der Gegner verliert etwa $dot Leben pro Runde',
    );
  }
  if (feld.speedFactorBoth != 1) teile.add('beide Leisten laufen langsamer');
  if (feld.windowFactorOnEnemy != 1) {
    final weniger = ((1 - feld.windowFactorOnEnemy) * 100).round();
    teile.add('sein Perfect-Fenster schrumpft um $weniger %');
  }
  if (feld.damageFactorOwner != 1) {
    teile.add(
      'deine Angriffe +${((feld.damageFactorOwner - 1) * 100).round()} %',
    );
  }
  if (feld.damageFactorBoth != 1) {
    final mehr = ((feld.damageFactorBoth - 1) * 100).round();
    teile.add('alle Angriffe +$mehr % (auch seine)');
  }
  if (feld.healFactorOnEnemy != 1) teile.add('seine Heilung wirkt nur halb');
  if (feld.healFactorBoth != 1) {
    teile.add('Heilung wirkt nur halb (auch deine)');
  }
  if (feld.energyPenaltyOnEnemy > 0) {
    teile.add('er bekommt ${feld.energyPenaltyOnEnemy} Energie weniger');
  }

  // Ohne „Legt": Die vier Umgebungen brauchen verschiedene Artikel (das
  // Eisfeld, den Sandsturm), und die stünden nirgends. Als Kopfzeile
  // gelesen kommt der Satz ohne aus.
  return '${feld.name} für ${feld.remainingTurns} Runden: '
      '${teile.join(', ')}.';
}

/// Was ein perfekter Treffer beim Legen einer Umgebung ändert (ADR-0023).
String _environmentPerfect(List<MoveEffect> perfectEffects) {
  final gelegt = _first<SetEnvironment>(perfectEffects);
  final feld = gelegt == null ? null : Environments.byId(gelegt.environmentId);
  if (feld == null || gelegt!.extraTurns <= 0) return 'Keine weitere Wirkung.';

  final gesamt = feld.remainingTurns + gelegt.extraTurns;
  return '${feld.name} hält $gesamt Runden statt ${feld.remainingTurns}.';
}
