import 'ability_moves.dart';
import 'combatant.dart';
import 'move.dart';

/// Ein Gegner, wie er im Spiel vorkommt — Werte, Moveset, Name.
///
/// Bewusst hier und nicht in der App: Gegnerwerte sind Spielzahlen. Standen
/// sie im Controller, waeren sie der Balance-Simulation nicht zugaenglich --
/// und genau das war vorher der Fall (Schichtregel in `CLAUDE.md`).
class EnemyBlueprint {
  const EnemyBlueprint({
    required this.id,
    required this.name,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.maxEnergy,
    this.loadout = Moves.defaultLoadout,
    this.utilityChance = 0,
  });

  /// Stabiler Bezeichner fuer Speicherstaende, Events und Tests.
  final String id;

  final String name;
  final int maxHp;
  final int attack;
  final int defense;
  final int maxEnergy;

  /// Welche Moves dieser Gegner beherrscht. Ueber diese Liste
  /// unterscheiden sich Gegner im Verhalten, ohne dass die Engine oder die
  /// Policy etwas davon wissen muessen.
  final List<Move> loadout;

  /// Wie oft dieser Gegner etwas anderes tut als zuzuschlagen -- eine
  /// Umgebung legen, sich abschirmen, das Fenster verengen.
  ///
  /// **Nach Haerte gestaffelt**, aus demselben Grund wie die Reihe selbst
  /// (ADR-0009): Der letzte Gegner soll sich *anders* anfuehlen, nicht nur
  /// haerter zuschlagen. Der Wegelagerer bleibt fast durchgehend ein
  /// Angreifer, der Bergwaechter baut sich das Feld zurecht.
  final double utilityChance;

  /// Frischer Kaempfer aus diesem Bauplan.
  Combatant spawn() {
    return Combatant.fresh(
      name: name,
      maxHp: maxHp,
      attack: attack,
      defense: defense,
      maxEnergy: maxEnergy,
    );
  }
}

/// Die Gegner des Spiels, aufsteigend nach Schwierigkeit.
///
/// Namen bewusst ohne Umlaute: Dieses Package ist durchgehend ASCII, damit
/// es in jeder Umgebung gleich liest.
///
/// **Warum eine Reihe und nicht ein Gegner.** Die Simulation hat gezeigt,
/// dass die Siegquote gegen einen festen Gegner innerhalb von etwa einem
/// Angriffspunkt von "unmoeglich" auf "geschenkt" kippt. Das ist keine
/// schlechte Einstellung, sondern liegt in der Sache: Ein Kampf mit
/// beidseitig festen Werten ist ein Rennen, und ein Rennen entscheidet die
/// Geschwindigkeit, nicht der Zufall. Ein breites Band an spannenden
/// Kaempfen laesst sich deshalb nicht in einen Gegner einstellen -- es
/// entsteht nur aus mehreren, von denen zu jedem Zeitpunkt einer knapp ist
/// (ADR-0009).
///
/// Jede Stufe ist so gesetzt, dass sie an einem bestimmten Punkt des
/// Gewohnheits-Pfads knapp wird. Nachgeprueft in `tool/balance_sim.dart`.
abstract final class Enemies {
  /// Ab Tag eins knapp schlagbar. Niemand soll ausgesperrt sein, bevor er
  /// angefangen hat.
  static const EnemyBlueprint wegelagerer = EnemyBlueprint(
    id: 'wegelagerer',
    name: 'Wegelagerer',
    maxHp: 120,
    attack: 18,
    defense: 10,
    maxEnergy: 10,
    // Nur Commons. Wer am Tag eins hier steht, soll gegen nichts
    // antreten, das er selbst noch nicht kennt.
    loadout: <Move>[
      Moves.basicAttack,
      AbilityMoves.funkenstoss,
      AbilityMoves.steinhaut,
      AbilityMoves.wurzelgriff,
      AbilityMoves.aurastrom,
    ],
    // Fast durchgehend ein Angreifer. Wer am Tag eins hier steht, soll den
    // Kampf verstehen koennen, ohne ein Feld lesen zu muessen.
    utilityChance: 0.1,
  );

  /// Knapp nach etwa zwei Wochen Gewohnheiten.
  static const EnemyBlueprint soeldner = EnemyBlueprint(
    id: 'soeldner',
    name: 'Soeldner',
    maxHp: 150,
    attack: 18,
    defense: 12,
    maxEnergy: 10,
    // Commons plus Uncommons: Der Soeldner kann heilen und spiegeln,
    // damit ein reiner Schlagabtausch hier nicht mehr reicht.
    loadout: <Move>[
      Moves.basicAttack,
      AbilityMoves.funkenstoss,
      AbilityMoves.klingenwirbel,
      AbilityMoves.bluetentau,
      AbilityMoves.prismaBarriere,
      AbilityMoves.frostnebel,
    ],
    utilityChance: 0.2,
  );

  /// Knapp nach etwa einem Monat -- und erst mit Ausruestung verlaesslich.
  /// Das ist der Grund, warum es im Shop etwas zu kaufen gibt.
  static const EnemyBlueprint bergwaechter = EnemyBlueprint(
    id: 'bergwaechter',
    name: 'Bergwaechter',
    maxHp: 230,
    attack: 20,
    defense: 13,
    maxEnergy: 10,
    // Bis Rare. Epic und Legendary bleiben dem Spieler vorbehalten --
    // sie sind der Lohn fuer tiefen Fortschritt, kein Gegnerwerkzeug.
    loadout: <Move>[
      Moves.basicAttack,
      AbilityMoves.donnerkeil,
      AbilityMoves.seelenraub,
      AbilityMoves.sandsturm,
      AbilityMoves.giftmoor,
      AbilityMoves.steinhaut,
    ],
    // Er baut sich das Feld zurecht. Fast jede dritte Runde geht in
    // Sandsturm, Giftmoor oder Steinhaut statt in einen Schlag.
    utilityChance: 0.3,
  );

  /// Alle Gegner in aufsteigender Schwierigkeit.
  static const List<EnemyBlueprint> all = <EnemyBlueprint>[
    wegelagerer,
    soeldner,
    bergwaechter,
  ];

  static EnemyBlueprint? byId(String id) {
    for (final enemy in all) {
      if (enemy.id == id) return enemy;
    }
    return null;
  }
}
