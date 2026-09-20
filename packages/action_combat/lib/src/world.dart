import 'dart:math' as math;

import 'balance.dart';
import 'entity.dart';
import 'events.dart';
import 'flow_field.dart';
import 'level.dart';
import 'stats.dart';
import 'vec2.dart';

/// Ein Lauf durch eine Halle.
///
/// **Fester Zeitschritt, gesäter Zufall, keine Wanduhr.** Das ist die
/// ganze Disziplin dieses Packages, und sie ist der Grund, warum es
/// überhaupt ein eigenes gibt: Derselbe Startwert und dieselbe Eingabe
/// ergeben denselben Lauf — auf dem Handy, im Browser und in einem Test
/// ohne Bildschirm. Der rundenbasierte Kampf kann das seit ADR-0002, und
/// jede belastbare Balance-Zahl dieses Projekts hängt daran.
///
/// Der Renderer ruft [advance] mit der Zeit, die seit dem letzten Bild
/// vergangen ist. Wie oft daraus ein Schritt wird, entscheidet **diese**
/// Klasse, nicht er.
class ActionWorld {
  ActionWorld({
    required this.level,
    required this.heroStats,
    int seed = 1,
  }) : _rng = math.Random(seed) {
    _hero = ActionEntity(
      id: _nextId++,
      faction: Faction.held,
      kind: EnemyKind.keiner,
      position: level.heroStart,
      maxHp: heroStats.maxHp,
      attack: heroStats.attack,
      defense: heroStats.defense,
      radius: ActionBalance.heroRadius,
      speed: ActionBalance.heroSpeed,
      attackRange: ActionBalance.heroAttackRange,
      attackCooldown: heroStats.attackCooldown,
      damageMultiplier: heroStats.damageMultiplier,
      critChance: heroStats.critChance,
      critFactor: heroStats.critFactor,
    );
    _entities.add(_hero);

    for (final spawn in level.spawns) {
      _entities.add(_enemyFor(spawn));
    }
    _totalEnemies = level.spawns.length;
    _rebuildPath();
  }

  final Level level;
  final ActionStats heroStats;

  final math.Random _rng;
  final List<ActionEntity> _entities = <ActionEntity>[];
  final List<ActionEvent> _events = <ActionEvent>[];

  late final ActionEntity _hero;
  int _nextId = 1;
  int _totalEnemies = 0;
  int _kills = 0;
  double _elapsed = 0;
  double _carry = 0;
  bool _over = false;
  bool _won = false;

  /// Das Wegfeld zum Helden. Jeder Gegner liest daraus seine
  /// Richtung ab — eine Flutfüllung für alle statt einer Suche je
  /// Gegner.
  late FlowField _pathToHero;
  int _stepsSincePath = 0;

  // --- Was die Darstellung sehen darf ---

  /// Kopien, keine Verweise: Die Darstellung soll zeichnen, nicht
  /// mitspielen.
  List<EntityView> get views {
    return <EntityView>[
      for (final entity in _entities)
        if (entity.isAlive) EntityView.of(entity),
    ];
  }

  EntityView get heroView => EntityView.of(_hero);

  /// Der Endgegner, solange er lebt — für den Balken am oberen Rand.
  EntityView? get bossView {
    for (final entity in _entities) {
      if (entity.kind == EnemyKind.endgegner && entity.isAlive) {
        return EntityView.of(entity);
      }
    }
    return null;
  }

  int get heroHp => _hero.hp;

  int get heroMaxHp => _hero.maxHp;

  double get heroHpRatio => _hero.hpRatio;

  int get kills => _kills;

  int get totalEnemies => _totalEnemies;

  int get enemiesLeft => _totalEnemies - _kills;

  double get elapsed => _elapsed;

  bool get isOver => _over;

  bool get isWon => _won;

  /// Holt die Ereignisse seit dem letzten Aufruf ab und leert die Liste.
  ///
  /// Abholen statt zuhören: Der Renderer arbeitet sie einmal je Bild ab,
  /// und wer sie nicht abholt, sammelt sie nicht endlos an.
  List<ActionEvent> drainEvents() {
    if (_events.isEmpty) return const <ActionEvent>[];
    final kopie = List<ActionEvent>.unmodifiable(_events);
    _events.clear();
    return kopie;
  }

  // --- Der Takt ---

  /// Lässt so viele feste Schritte laufen, wie in [dt] passen.
  ///
  /// Gibt zurück, wie viele es waren. Der Rest wird aufgehoben, damit
  /// über viele Bilder hinweg keine Zeit verloren geht.
  int advance(double dt, Vec2 moveInput) {
    if (_over) return 0;

    _carry += dt;
    var schritte = 0;
    while (_carry >= ActionBalance.stepSeconds &&
        schritte < ActionBalance.maxCatchUpSteps) {
      _carry -= ActionBalance.stepSeconds;
      step(moveInput);
      schritte++;
      if (_over) break;
    }

    // Nur wenn der Deckel gegriffen hat, wird der Rest weggeworfen: Dann
    // ist die Welt ohnehin hinter der Uhr, und Nachholen machte es
    // schlimmer. Sonst bleibt der Rest liegen — sonst geht über viele
    // Bilder hinweg Zeit verloren.
    if (schritte >= ActionBalance.maxCatchUpSteps) _carry = 0;
    return schritte;
  }

  /// Ein einzelner fester Schritt. Tests rufen den direkt auf.
  void step(Vec2 moveInput) {
    if (_over) return;

    const dt = ActionBalance.stepSeconds;
    _elapsed += dt;

    _stepsSincePath++;
    if (_stepsSincePath >= ActionBalance.pathRefreshSteps) {
      _rebuildPath();
    }

    _moveHero(moveInput, dt);
    _heroAttack(dt);
    _enemiesAct(dt);
    _separate();
    _collectDead();
    _checkEnd();
  }

  // --- Held ---

  void _moveHero(Vec2 input, double dt) {
    final richtung = input.clampLength(1);
    if (richtung.isZero) return;

    _hero.facing = richtung.normalized;
    _hero.position = _slide(
      _hero.position,
      richtung * (_hero.speed * dt),
      _hero.radius,
    );
  }

  void _heroAttack(double dt) {
    _hero.cooldownLeft -= dt;
    if (_hero.cooldownLeft > 0) return;

    final ziel = _nearestEnemyInRange(_hero);
    if (ziel == null) return;

    _hero.cooldownLeft = _hero.attackCooldown;
    _hero.facing = (ziel.position - _hero.position).normalized;
    _events.add(
      AttackSwung(
        attackerId: _hero.id,
        faction: Faction.held,
        from: _hero.position,
        direction: _hero.facing,
      ),
    );
    _hit(_hero, ziel);
  }

  ActionEntity? _nearestEnemyInRange(ActionEntity attacker) {
    ActionEntity? beste;
    var besteDistanz = double.infinity;

    for (final entity in _entities) {
      if (!entity.isAlive || entity.faction == attacker.faction) continue;
      final reichweite = attacker.attackRange + entity.radius;
      final distanz = attacker.position.distanceSquaredTo(entity.position);
      if (distanz > reichweite * reichweite) continue;
      if (distanz < besteDistanz) {
        besteDistanz = distanz;
        beste = entity;
      }
    }
    return beste;
  }

  // --- Gegner ---

  void _enemiesAct(double dt) {
    for (final gegner in _entities) {
      if (!gegner.isAlive || gegner.isHero) continue;

      final abstand = gegner.position.distanceTo(_hero.position);
      if (!gegner.aggro && abstand <= ActionBalance.aggroRadius) {
        gegner.aggro = true;
        _events.add(EnemyNoticed(id: gegner.id, at: gegner.position));
      }
      if (!gegner.aggro) continue;
      if (!ActionBalance.aggroIsPermanent &&
          abstand > ActionBalance.aggroRadius * 1.5) {
        gegner.aggro = false;
        continue;
      }

      gegner.cooldownLeft -= dt;

      final reichweite = gegner.attackRange + _hero.radius;
      if (abstand > reichweite) {
        final richtung = _chaseDirection(gegner);
        if (richtung.isZero) continue;
        gegner.facing = richtung;
        gegner.position = _slide(
          gegner.position,
          richtung * (gegner.speed * dt),
          gegner.radius,
        );
        continue;
      }

      if (gegner.cooldownLeft > 0) continue;
      gegner.cooldownLeft = gegner.attackCooldown;
      gegner.facing = (_hero.position - gegner.position).normalized;
      _events.add(
        AttackSwung(
          attackerId: gegner.id,
          faction: Faction.gegner,
          from: gegner.position,
          direction: gegner.facing,
        ),
      );
      _hit(gegner, _hero);
    }
  }

  // --- Schaden ---

  void _hit(ActionEntity attacker, ActionEntity target) {
    final kritisch =
        attacker.critChance > 0 && _rng.nextDouble() < attacker.critChance;

    var roh = attacker.attack * attacker.damageMultiplier;
    if (kritisch) roh *= attacker.critFactor;

    final streuung =
        1 + (_rng.nextDouble() * 2 - 1) * ActionBalance.damageSpread;
    roh = roh * streuung - target.defense / ActionBalance.defenseDivisor;

    final schaden = math.max(ActionBalance.minDamage, roh.round());
    final wirklich = target.takeDamage(schaden);

    _events.add(
      HitLanded(
        targetId: target.id,
        targetFaction: target.faction,
        at: target.position,
        amount: wirklich,
        isCrit: kritisch,
      ),
    );
  }

  // --- Bewegung und Wände ---

  /// Verschiebt [from] um [delta] und bleibt dabei aus Wänden heraus.
  ///
  /// Die beiden Achsen werden getrennt geprüft. Das kostet nichts und
  /// erledigt das Entlanggleiten an einer Wand nebenbei — ohne es rutscht
  /// man an jeder Ecke fest, und ein Gang wird unpassierbar.
  Vec2 _slide(Vec2 from, Vec2 delta, double radius) {
    var position = from;

    final nachX = Vec2(position.x + delta.x, position.y);
    if (!_hitsWall(nachX, radius)) position = nachX;

    final nachY = Vec2(position.x, position.y + delta.y);
    if (!_hitsWall(nachY, radius)) position = nachY;

    return position;
  }

  bool _hitsWall(Vec2 center, double radius) {
    const size = ActionBalance.tileSize;
    final vonX = ((center.x - radius) / size).floor();
    final bisX = ((center.x + radius) / size).floor();
    final vonY = ((center.y - radius) / size).floor();
    final bisY = ((center.y + radius) / size).floor();

    for (var y = vonY; y <= bisY; y++) {
      for (var x = vonX; x <= bisX; x++) {
        if (!level.isWallAt(x, y)) continue;
        final nahX = center.x.clamp(x * size, (x + 1) * size);
        final nahY = center.y.clamp(y * size, (y + 1) * size);
        final dx = center.x - nahX;
        final dy = center.y - nahY;
        if (dx * dx + dy * dy < radius * radius) return true;
      }
    }
    return false;
  }

  /// Schiebt Figuren auseinander, die sich überschneiden.
  ///
  /// Ohne das stehen zwanzig Gegner als ein einziger Punkt auf dem
  /// Helden, und eine Traube sieht aus wie ein Gegner.
  void _separate() {
    for (var i = 0; i < _entities.length; i++) {
      final a = _entities[i];
      if (!a.isAlive) continue;
      for (var j = i + 1; j < _entities.length; j++) {
        final b = _entities[j];
        if (!b.isAlive) continue;

        final delta = b.position - a.position;
        final mindest = a.radius + b.radius;
        final distanz = delta.length;
        if (distanz >= mindest || distanz == 0) continue;

        final schub =
            (mindest - distanz) / 2 * ActionBalance.separationStrength;
        final richtung = delta.normalized;

        // Der Held wird nicht geschoben: Sonst drückt eine Traube ihn
        // durch den halben Raum, und die Steuerung fühlt sich an, als
        // gehöre sie jemand anderem.
        if (a.isHero) {
          b.position = _slide(b.position, richtung * (schub * 2), b.radius);
        } else if (b.isHero) {
          a.position = _slide(a.position, richtung * (-schub * 2), a.radius);
        } else {
          a.position = _slide(a.position, richtung * -schub, a.radius);
          b.position = _slide(b.position, richtung * schub, b.radius);
        }
      }
    }
  }

  // --- Ende ---

  void _collectDead() {
    for (final entity in _entities) {
      if (entity.isAlive || entity.isHero) continue;
      if (_gemeldet.contains(entity.id)) continue;
      _gemeldet.add(entity.id);
      _kills++;
      _events.add(
        EntityDied(
          id: entity.id,
          faction: entity.faction,
          kind: entity.kind,
          at: entity.position,
        ),
      );
    }
  }

  final Set<int> _gemeldet = <int>{};

  void _checkEnd() {
    if (_over) return;

    if (!_hero.isAlive) {
      _finish(won: false);
      return;
    }
    if (_kills >= _totalEnemies) _finish(won: true);
  }

  void _finish({required bool won}) {
    _over = true;
    _won = won;
    _events.add(RunEnded(won: won, seconds: _elapsed, kills: _kills));
  }

  /// Wohin dieser Gegner laufen muss, um beim Helden anzukommen.
  ///
  /// Auf kurze Sicht geradeaus, weiter weg über das Wegfeld. Ohne das
  /// Feld bleibt jeder an der ersten Ecke stehen — und genau das hat der
  /// kopflose Lauf beim ersten Versuch gemeldet, bevor es das Feld gab.
  Vec2 _chaseDirection(ActionEntity gegner) {
    final direkt = _hero.position - gegner.position;
    if (direkt.length <= ActionBalance.directChaseRange) {
      return direkt.normalized;
    }

    final ueberFeld = _pathToHero.directionFrom(gegner.position);
    return ueberFeld.isZero ? direkt.normalized : ueberFeld;
  }

  void _rebuildPath() {
    const size = ActionBalance.tileSize;
    _pathToHero = FlowField.from(
      level,
      (_hero.position.x / size).floor(),
      (_hero.position.y / size).floor(),
    );
    _stepsSincePath = 0;
  }

  /// Wie weit ein Punkt vom Helden entfernt ist — in Feldern, **am Weg
  /// entlang** statt Luftlinie. Ein Bot wählt damit den Gegner, der
  /// wirklich der nächste ist, und nicht den hinter der Wand.
  int? pathDistanceTo(Vec2 point) => _pathToHero.distanceAtPoint(point);

  /// Ein Wegfeld auf ein beliebiges Ziel — für Bots und Tests.
  FlowField fieldTo(Vec2 target) {
    const size = ActionBalance.tileSize;
    return FlowField.from(
      level,
      (target.x / size).floor(),
      (target.y / size).floor(),
    );
  }

  ActionEntity _enemyFor(Spawn spawn) {
    final istBoss = spawn.kind == EnemyKind.endgegner;
    return ActionEntity(
      id: _nextId++,
      faction: Faction.gegner,
      kind: spawn.kind,
      position: level.centerOfSpawn(spawn),
      maxHp: istBoss ? ActionBalance.bossHp : ActionBalance.trashHp,
      attack: istBoss ? ActionBalance.bossAttack : ActionBalance.trashAttack,
      defense: istBoss ? ActionBalance.bossDefense : ActionBalance.trashDefense,
      radius: istBoss ? ActionBalance.bossRadius : ActionBalance.trashRadius,
      speed: istBoss ? ActionBalance.bossSpeed : ActionBalance.trashSpeed,
      attackRange: istBoss
          ? ActionBalance.bossAttackRange
          : ActionBalance.trashAttackRange,
      attackCooldown: istBoss
          ? ActionBalance.bossAttackCooldown
          : ActionBalance.trashAttackCooldown,
    );
  }
}
