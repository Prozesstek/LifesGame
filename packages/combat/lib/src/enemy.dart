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

  /// Die Spitze der Reihe. Kein eigener Charakter, sondern der Endpunkt
  /// der Kurve -- und die einzige Zahl, an der sich die Haerte der ganzen
  /// oberen Haelfte einstellen laesst.
  ///
  /// **Sie muss erreichbar bleiben** (Issue #36). Der Spieler ist nach
  /// etwa einem Monat am Werte-Deckel (ATK 20, HP 224, DEF 14, EN 12);
  /// alles darueber kommt aus Ausruestung, Set und Faehigkeiten. Wer
  /// diese Zahlen anhebt, laesst `dart run tool/balance_sim.dart` laufen
  /// und sieht im Abschnitt "Die Reihe" nach, ob Sprosse 30 noch faellt.
  static const EnemyBlueprint spitze = EnemyBlueprint(
    id: 'titan',
    name: 'Titan der Tiefe',
    maxHp: 460,
    attack: 25,
    defense: 15,
    maxEnergy: 16,
    loadout: _bisRare,
    utilityChance: 0.35,
  );

  /// Wie viele Sprossen die Reihe hat.
  static const int rungs = 30;

  /// Die Namen der Sprossen, aufsteigend.
  ///
  /// Bewusst ohne grosse Varianz (Issue #36): Sie sollen die Stufe
  /// erkennbar machen, nicht eine Welt erzaehlen. Ohne Umlaute, wie alles
  /// in diesem Package.
  static const List<String> _namen = <String>[
    'Wegelagerer',
    'Strauchdieb',
    'Spaeher',
    'Wilderer',
    'Raufbold',
    'Soeldner',
    'Schildknappe',
    'Klingentaenzer',
    'Bogenschuetze',
    'Hauptmann',
    'Grabraeuber',
    'Katakombenwaechter',
    'Knochensammler',
    'Fluchtraeger',
    'Nachtschleicher',
    'Schattenklinge',
    'Runenwaechter',
    'Steinkolossus',
    'Frostgeist',
    'Bergwaechter',
    'Aschewandler',
    'Glutmagier',
    'Sturmrufer',
    'Eisenfaust',
    'Blutzeuge',
    'Seelenweber',
    'Drachenschueler',
    'Hochwaechter',
    'Erzdaemon',
    'Titan der Tiefe',
  ];

  /// Die Stuetzstellen der Kurve: Sprosse und der Gegner, der dort steht.
  ///
  /// **Die drei alten Gegner bleiben unveraendert.** Ihre Werte sind in
  /// ADR-0009 gemessen worden; sie zu ueberschreiben haette die einzigen
  /// belastbaren Zahlen des Projekts entwertet. Die Reihe waechst
  /// stattdessen *zwischen* ihnen -- siebenundzwanzig neue Sprossen auf
  /// einer Kurve, die durch die drei bekannten Punkte laeuft.
  static const List<(int, EnemyBlueprint)> _stuetzstellen =
      <(int, EnemyBlueprint)>[
    (1, wegelagerer),
    (6, soeldner),
    (20, bergwaechter),
    (rungs, spitze),
  ];

  /// Alle dreissig Gegner in aufsteigender Schwierigkeit.
  ///
  /// `final` statt `const`, weil die Werte gerechnet und nicht
  /// abgeschrieben werden. Das ist Absicht: Eine von Hand gepflegte
  /// Tabelle mit dreissig Zeilen laesst sich nicht mehr "stetig steigend"
  /// halten, ohne dass es jemand nachrechnet -- `enemy_ladder_test.dart`
  /// tut genau das, und bei einer Tabelle haette es nichts zu pruefen
  /// gegeben ausser Tippfehlern.
  static final List<EnemyBlueprint> ladder = _baueReihe();

  /// Alle Gegner. Alias auf [ladder], damit aeltere Aufrufer und die
  /// Simulation unveraendert weiterlaufen.
  static List<EnemyBlueprint> get all => ladder;

  static EnemyBlueprint? byId(String id) {
    for (final enemy in all) {
      if (enemy.id == id) return enemy;
    }
    return null;
  }

  /// Der Gegner auf Sprosse [rung], gezaehlt ab 1.
  static EnemyBlueprint atRung(int rung) {
    final index = rung.clamp(1, rungs) - 1;
    return ladder[index];
  }

  static List<EnemyBlueprint> _baueReihe() {
    return <EnemyBlueprint>[
      for (var rung = 1; rung <= rungs; rung++) _sprosse(rung),
    ];
  }

  /// Eine Sprosse: entweder eine Stuetzstelle selbst oder ein Punkt
  /// zwischen zweien.
  static EnemyBlueprint _sprosse(int rung) {
    for (final (sprosse, gegner) in _stuetzstellen) {
      if (sprosse == rung) return gegner;
    }

    final (vonRung, von) = _stuetzeVor(rung);
    final (bisRung, bis) = _stuetzeNach(rung);
    final t = (rung - vonRung) / (bisRung - vonRung);

    return EnemyBlueprint(
      id: 'gegner-$rung',
      name: _namen[rung - 1],
      maxHp: _zwischen(von.maxHp, bis.maxHp, t),
      attack: _zwischen(von.attack, bis.attack, t),
      defense: _zwischen(von.defense, bis.defense, t),
      maxEnergy: _zwischen(von.maxEnergy, bis.maxEnergy, t),
      loadout: _loadoutFuer(rung),
      // **Auch die Utility-Quote laeuft durch die Stuetzstellen**, nicht
      // an ihnen vorbei. Eine eigene Formel daneben liess sie von
      // Sprosse 6 auf 7 *fallen* -- der Soeldner steht bei 0,2, die
      // Formel gab dort 0,15. Gefunden hat es `enemy_ladder_test.dart`,
      // und genau dafuer prueft er jeden Wert einzeln.
      utilityChance: _zwischenD(von.utilityChance, bis.utilityChance, t),
    );
  }

  static (int, EnemyBlueprint) _stuetzeVor(int rung) {
    var treffer = _stuetzstellen.first;
    for (final stelle in _stuetzstellen) {
      if (stelle.$1 < rung) treffer = stelle;
    }
    return treffer;
  }

  static (int, EnemyBlueprint) _stuetzeNach(int rung) {
    for (final stelle in _stuetzstellen) {
      if (stelle.$1 > rung) return stelle;
    }
    return _stuetzstellen.last;
  }

  static int _zwischen(int von, int bis, double t) {
    return (von + (bis - von) * t).round();
  }

  static double _zwischenD(double von, double bis, double t) {
    return von + (bis - von) * t;
  }

  /// Welche Zuege eine Sprosse beherrscht.
  ///
  /// **Epic und Legendary bleiben dem Spieler vorbehalten**, auch ganz
  /// oben -- sie sind der Lohn fuer tiefen Fortschritt, kein
  /// Gegnerwerkzeug. Die obere Haelfte der Reihe wird ueber Werte und
  /// Utility haerter, nicht ueber Zuege, die der Spieler nie gesehen hat.
  static List<Move> _loadoutFuer(int rung) {
    if (rung <= 8) return _nurCommons;
    if (rung <= 16) return _bisUncommon;
    return _bisRare;
  }

  static const List<Move> _nurCommons = <Move>[
    Moves.basicAttack,
    AbilityMoves.funkenstoss,
    AbilityMoves.steinhaut,
    AbilityMoves.wurzelgriff,
    AbilityMoves.aurastrom,
  ];

  static const List<Move> _bisUncommon = <Move>[
    Moves.basicAttack,
    AbilityMoves.funkenstoss,
    AbilityMoves.klingenwirbel,
    AbilityMoves.bluetentau,
    AbilityMoves.prismaBarriere,
    AbilityMoves.frostnebel,
  ];

  static const List<Move> _bisRare = <Move>[
    Moves.basicAttack,
    AbilityMoves.donnerkeil,
    AbilityMoves.seelenraub,
    AbilityMoves.sandsturm,
    AbilityMoves.giftmoor,
    AbilityMoves.steinhaut,
  ];
}
