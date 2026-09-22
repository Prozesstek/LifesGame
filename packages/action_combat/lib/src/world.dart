import 'dart:math' as math;

import 'balance.dart';
import 'entity.dart';
import 'health_orb.dart';
import 'events.dart';
import 'flow_field.dart';
import 'level.dart';
import 'pit_ability.dart';
import 'pit_modifier.dart';
import 'pit_weapon.dart';
import 'projectile.dart';
import 'stage.dart';
import 'stats.dart';
import 'vec2.dart';

part 'boss.dart';

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
    this.stage,
    List<String> abilityIds = const <String>[],
    String? weaponMoveId,
    List<PitModifier> modifiers = const <PitModifier>[],
    int seed = 1,
  })  : _rng = math.Random(seed),
        weapon = PitWeapons.byMoveId(weaponMoveId ?? '') ?? PitWeapons.fist,
        _mana = heroStats.maxMana.toDouble(),
        // Sets und legendäre Kräfte werden hier einmal angewendet; die
        // Welt sieht danach nur noch die veränderten Fähigkeiten.
        slots = List<PitAbility>.unmodifiable(
          abilityIds
              .map(PitAbilities.byId)
              .whereType<PitAbility>()
              .take(ActionBalance.maxAbilitySlots)
              .map((a) => PitModifiers.apply(a, modifiers)),
        ) {
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
      attackRange: weapon.range,
      attackCooldown: heroStats.attackCooldown * weapon.cooldownFactor,
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

  /// Wie hart die Gegner sind (ADR-0039). `null` heisst Grundwerte aus
  /// [ActionBalance] — so läuft der Prototyp im Entwicklermodus, und so
  /// sind die Tests geschrieben, die eine Mechanik prüfen statt einer
  /// Stufe.
  final PitStage? stage;

  /// Die Fähigkeiten, die in diesen Lauf mitgehen, in Platzreihenfolge.
  ///
  /// **Ids, die die Grube noch nicht kennt, fallen hier heraus** — sie
  /// liegen auf dem Platz des Charakters und tun erst etwas, wenn sie in
  /// [PitAbilities] stehen. Ein Knopf ohne Wirkung wäre schlimmer als
  /// keiner.
  final List<PitAbility> slots;

  /// Was den Grundangriff bestimmt. Ohne bekannte Waffe die Faust.
  final PitWeapon weapon;

  /// Wie lange die Prisma-Barriere noch hält, und wie viel sie zurückwirft.
  double _reflectLeft = 0;
  double _reflectShare = 0;

  double _mana;
  final Map<String, double> _slotCooldowns = <String, double>{};

  /// Der Wächter zwischen zwei Schritten — erst angelegt, wenn er handelt.
  _BossState? _bossState;
  bool _bossEnraged = false;

  /// Wie lange eine Schadensminderung noch hält, und wie stark sie ist.
  double _wardLeft = 0;
  double _wardFactor = 1;

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

  final List<Projectile> _projectiles = <Projectile>[];
  final List<HealthOrb> _orbs = <HealthOrb>[];

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

  List<ProjectileView> get projectiles {
    return <ProjectileView>[
      for (final p in _projectiles)
        if (!p.spent) ProjectileView.of(p),
    ];
  }

  List<OrbView> get orbs {
    return <OrbView>[
      for (final orb in _orbs)
        if (!orb.taken)
          OrbView.of(
            orb,
            fading: orb.age > ActionBalance.orbLifetime - 3,
          ),
    ];
  }

  // --- Mana und Plätze (ADR-0039) ---

  int get mana => _mana.floor();

  int get maxMana => heroStats.maxMana;

  double get manaRatio => maxMana == 0 ? 0 : _mana / maxMana;

  /// Ob gerade eine Schadensminderung liegt — für die Darstellung.
  bool get isWarded => _wardLeft > 0;

  /// Abklingzeit einer Platz-Fähigkeit als Anteil, 0 heisst bereit.
  double slotCooldownRatio(String id) {
    final rest = _slotCooldowns[id] ?? 0;
    final ability = _slotFor(id);
    if (rest <= 0 || ability == null || ability.cooldown <= 0) return 0;
    return (rest / ability.cooldown).clamp(0.0, 1.0);
  }

  /// Ob [id] jetzt gewirkt werden kann: auf einem Platz, abgeklungen,
  /// genug Mana.
  bool canCast(String id) {
    if (_over) return false;
    final ability = _slotFor(id);
    if (ability == null) return false;
    if ((_slotCooldowns[id] ?? 0) > 0) return false;
    return _mana >= ability.manaCost;
  }

  PitAbility? _slotFor(String id) {
    for (final ability in slots) {
      if (ability.id == id) return ability;
    }
    return null;
  }

  /// Wirkt eine Fähigkeit von einem Platz. Gibt false zurück, wenn sie
  /// nicht geht — nicht auf einem Platz, nicht abgeklungen, zu wenig Mana.
  ///
  /// **Kein Ziel, kein Mana.** Ein Funke ohne Gegner in Reichweite kostet
  /// nichts und klingt nicht ab: Wer ins Leere tippt, soll nicht bestraft
  /// werden, sondern es gleich noch einmal versuchen können.
  bool cast(String id) {
    if (!canCast(id)) return false;
    final ability = _slotFor(id);
    if (ability == null) return false;

    for (final effect in ability.effects) {
      if (effect is BoltAtNearest &&
          _nearestEnemyWithin(effect.range, needsSight: true) == null) {
        return false;
      }
      if (effect is StrikeNearest &&
          _nearestEnemyWithin(effect.range) == null) {
        return false;
      }
    }

    _mana -= ability.manaCost;
    _slotCooldowns[id] = ability.cooldown;
    _events.add(AbilityCast(id: id, at: _hero.position));

    for (final effect in ability.effects) {
      _apply(effect);
    }
    return true;
  }

  /// Die eine Stelle, die jede Art von [PitEffect] ausführt.
  void _apply(PitEffect effect) {
    switch (effect) {
      case BoltAtNearest(:final power, :final range, :final leech):
        final ziel = _nearestEnemyWithin(range, needsSight: true);
        if (ziel == null) return;
        _shoot(ziel, power: power, leech: leech);
      case StrikeNearest(:final power, :final range):
        final ziel = _nearestEnemyWithin(range);
        if (ziel == null) return;
        _hero.facing = (ziel.position - _hero.position).normalized;
        _hit(_hero, ziel, powerFactor: power);
      case StrikeAround(:final power, :final radius):
        for (final ziel in _enemiesWithin(radius)) {
          _hit(_hero, ziel, powerFactor: power);
        }
      case HealSelf(:final share):
        _healHero((_hero.maxHp * share).round());
      case GainMana(:final amount):
        _mana = math.min(heroStats.maxMana.toDouble(), _mana + amount);
      case ReduceIncoming(:final factor, :final seconds):
        _wardFactor = _wardLeft > 0 ? math.min(_wardFactor, factor) : factor;
        _wardLeft = seconds;
      case ReflectIncoming(:final share, :final seconds):
        _reflectShare =
            _reflectLeft > 0 ? math.max(_reflectShare, share) : share;
        _reflectLeft = seconds;
      case SlowAround(:final radius, :final factor, :final seconds):
        for (final ziel in _enemiesWithin(radius)) {
          ziel.slowFactor =
              ziel.slowLeft > 0 ? math.min(ziel.slowFactor, factor) : factor;
          ziel.slowLeft = math.max(ziel.slowLeft, seconds);
        }
      case DamageOverTime(:final radius, :final perSecond, :final seconds):
        final jeSekunde = _hero.attack * _hero.damageMultiplier * perSecond;
        for (final ziel in _enemiesWithin(radius)) {
          _applyDot(ziel, jeSekunde, seconds);
        }
    }
  }

  /// Ein Geschoss des Helden auf [ziel].
  void _shoot(
    ActionEntity ziel, {
    required double power,
    double leech = 0,
    bool fromWeapon = false,
    double angle = 0,
  }) {
    var richtung = (ziel.position - _hero.position).normalized;
    if (angle != 0) richtung = richtung.rotated(angle);
    _hero.facing = richtung;
    _projectiles.add(
      Projectile(
        id: _nextId++,
        faction: Faction.held,
        position: _hero.position,
        velocity: richtung * ActionBalance.heroBoltSpeed,
        damage: 0,
        radius: ActionBalance.heroBoltRadius,
        heroPower: power,
        heroLeech: leech,
        fromWeapon: fromWeapon,
      ),
    );
  }

  void _healHero(int menge) {
    final vorher = _hero.hp;
    _hero.hp = math.min(_hero.maxHp, _hero.hp + menge);
    _events.add(HeroHealed(at: _hero.position, amount: _hero.hp - vorher));
  }

  /// Dauerschaden: Bei zweien gilt der stärkere, die Dauer die längere.
  /// Sie addieren sich nicht — sonst wäre das Stapeln von Gift die beste
  /// Antwort auf alles.
  void _applyDot(ActionEntity ziel, double jeSekunde, double sekunden) {
    if (jeSekunde >= ziel.dotPerSecond || ziel.dotLeft <= 0) {
      ziel.dotPerSecond = jeSekunde;
    }
    ziel.dotLeft = math.max(ziel.dotLeft, sekunden);
  }

  /// Alle lebenden Gegner, die den Kreis um den Helden berühren.
  List<ActionEntity> _enemiesWithin(double radius) {
    return <ActionEntity>[
      for (final ziel in _entities)
        if (ziel.isAlive &&
            !ziel.isHero &&
            _hero.position.distanceSquaredTo(ziel.position) <=
                (radius + ziel.radius) * (radius + ziel.radius))
          ziel,
    ];
  }

  /// Der nächste lebende Gegner, höchstens [range] entfernt — mit
  /// [needsSight] nur einer, den der Held auch sieht.
  ///
  /// **Sichtlinie für alles, was fliegt.** Ein Funke auf einen Gegner
  /// hinter der Wand bleibt an der Wand hängen und kostet trotzdem
  /// Mana — bis zu diesem Schritt stand das als offener Fehler in
  /// `state.md`.
  ActionEntity? _nearestEnemyWithin(double range, {bool needsSight = false}) {
    ActionEntity? bester;
    var besteDistanz = double.infinity;
    for (final ziel in _entities) {
      if (!ziel.isAlive || ziel.isHero) continue;
      final reichweite = range + ziel.radius;
      final d = _hero.position.distanceSquaredTo(ziel.position);
      if (d > reichweite * reichweite || d >= besteDistanz) continue;
      if (needsSight && !_canSee(_hero.position, ziel.position)) continue;
      besteDistanz = d;
      bester = ziel;
    }
    return bester;
  }

  /// Ob zwischen [a] und [b] keine Wand steht, in Vierteln eines Feldes
  /// abgetastet.
  bool _canSee(Vec2 a, Vec2 b) {
    final weg = b - a;
    final schritte = (weg.length / (ActionBalance.tileSize / 4)).ceil();
    for (var i = 1; i < schritte; i++) {
      final punkt = a + weg * (i / schritte);
      if (level.isWallAtPoint(punkt)) return false;
    }
    return true;
  }

  /// Schaden am Helden nach seiner Schadensminderung.
  int _mitigate(ActionEntity target, int schaden) {
    if (!target.isHero || _wardLeft <= 0) return schaden;
    return math.max(ActionBalance.minDamage, (schaden * _wardFactor).round());
  }

  /// Was der Wächter gerade ankündigt — ein Ring oder eine Linie, die
  /// sich füllt. Leer, wenn er nichts vorhat.
  List<TelegraphView> get telegraphs => _bossTelegraphs();

  /// Ob der Wächter wütend ist (unter halbem Leben).
  bool get isBossEnraged => _bossEnraged;

  /// Wie viele Heilkugeln eingesammelt wurden. Eine Zahl fürs Blatt am
  /// Ende: Sie sagt, ob jemand den Lauf bestritten oder durchgehalten hat.
  int get orbsCollected => _orbsCollected;
  int _orbsCollected = 0;

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

    _tickMana(dt);
    _moveHero(moveInput, dt);
    _heroAttack(dt);
    _enemiesAct(dt);
    _tickStatus(dt);
    _moveProjectiles(dt);
    _separate();
    _moveOrbs(dt);
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

  void _tickMana(double dt) {
    _mana = math.min(
      heroStats.maxMana.toDouble(),
      _mana + heroStats.manaRegen * dt,
    );
    for (final id in _slotCooldowns.keys.toList()) {
      _slotCooldowns[id] = (_slotCooldowns[id] ?? 0) - dt;
    }
    if (_wardLeft > 0) _wardLeft -= dt;
    if (_reflectLeft > 0) _reflectLeft -= dt;
  }

  /// Verlangsamung und Dauerschaden der Gegner.
  ///
  /// **Dauerschaden fällt in halben Sekunden**, nicht in jedem Schritt:
  /// Sechzig Zahlen je Sekunde über einem Kopf liest niemand.
  void _tickStatus(double dt) {
    const takt = 0.5;
    for (final ziel in _entities) {
      if (!ziel.isAlive || ziel.isHero) continue;
      if (ziel.ghostLeft > 0) ziel.ghostLeft -= dt;
      if (ziel.slowLeft > 0) ziel.slowLeft -= dt;
      if (ziel.dotLeft <= 0) continue;

      ziel.dotLeft -= dt;
      ziel.dotTick += dt;
      if (ziel.dotTick < takt) continue;
      ziel.dotTick -= takt;

      final menge = math.max(1, (ziel.dotPerSecond * takt).round());
      final wirklich = ziel.takeDamage(menge);
      _events.add(
        HitLanded(
          targetId: ziel.id,
          targetFaction: ziel.faction,
          at: ziel.position,
          amount: wirklich,
          isCrit: false,
        ),
      );
    }
  }

  /// Der Grundangriff — wie er fällt, bestimmt die [weapon].
  void _heroAttack(double dt) {
    _hero.cooldownLeft -= dt;
    if (_hero.cooldownLeft > 0) return;

    final ziel = weapon.ranged
        ? _nearestEnemyWithin(weapon.range, needsSight: true)
        : _nearestEnemyInRange(_hero);
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

    if (weapon.ranged) {
      // Mehrere Pfeile fächern leicht auf, damit sie nicht als einer
      // aussehen.
      for (var i = 0; i < weapon.hits; i++) {
        final versatz = (i - (weapon.hits - 1) / 2) * 0.12;
        _shoot(ziel, power: weapon.power, fromWeapon: true, angle: versatz);
      }
      return;
    }

    final ziele =
        weapon.cleave ? _enemiesWithin(weapon.range) : <ActionEntity>[ziel];
    for (final getroffen in ziele) {
      for (var i = 0; i < weapon.hits && getroffen.isAlive; i++) {
        _weaponLanded(getroffen);
      }
    }
  }

  /// Ein Treffer der Waffe, samt dem, was sie mitbringt.
  void _weaponLanded(ActionEntity ziel, {double? power}) {
    _hit(_hero, ziel, powerFactor: power ?? weapon.power);
    if (weapon.manaOnHit > 0) {
      _mana = math.min(
        heroStats.maxMana.toDouble(),
        _mana + weapon.manaOnHit,
      );
    }
    if (weapon.burnPerSecond > 0 && ziel.isAlive) {
      _applyDot(
        ziel,
        _hero.attack * _hero.damageMultiplier * weapon.burnPerSecond,
        ActionBalance.weaponBurnSeconds,
      );
    }
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
      // **Wer weiter schiesst, als er sieht, wäre blind.** Der
      // Fernkämpfer hat eine grössere Reichweite als der Aufmerksamkeits-
      // radius; ohne diese Zeile stünde er da und liesse sich beschiessen.
      final merkt = math.max(ActionBalance.aggroRadius, gegner.attackRange);
      if (!gegner.aggro && abstand <= merkt) {
        gegner.aggro = true;
        _events.add(EnemyNoticed(id: gegner.id, at: gegner.position));
      }
      if (!gegner.aggro) continue;
      if (!ActionBalance.aggroIsPermanent &&
          abstand > ActionBalance.aggroRadius * 1.5) {
        gegner.aggro = false;
        continue;
      }

      // Verlangsamt heisst: Laufen **und** Zuschlagen im selben Takt.
      final takt = dt * gegner.tempo;
      gegner.cooldownLeft -= takt;

      if (gegner.kind == EnemyKind.schuetze) {
        _archerActs(gegner, abstand, takt);
        continue;
      }
      if (gegner.kind == EnemyKind.endgegner) {
        _bossActs(gegner, abstand, takt);
        continue;
      }

      _meleeActs(gegner, abstand, takt);
    }
  }

  /// Heranlaufen und zuschlagen — Fussvolk, Kobold, Troll, und der
  /// Wächter, wenn er gerade nichts Besonderes vorhat.
  void _meleeActs(ActionEntity gegner, double abstand, double takt) {
    final reichweite = gegner.attackRange + _hero.radius;
    if (abstand > reichweite) {
      final richtung = _chaseDirection(gegner);
      if (richtung.isZero) return;
      gegner.facing = richtung;
      gegner.position = _slide(
        gegner.position,
        richtung * (gegner.speed * takt),
        gegner.radius,
      );
      _trackProgress(gegner, takt);
      return;
    }

    if (gegner.cooldownLeft > 0) return;
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

  /// Der Fernkämpfer: auf Abstand halten, dann schiessen.
  ///
  /// **Er weicht zurück, wenn der Held zu nah kommt** — das ist sein
  /// ganzer Zweck. Ein Schütze, der stehenbleibt, ist ein Nahkämpfer mit
  /// anderer Farbe; einer, der zurückweicht, zwingt zum Nachsetzen und
  /// damit dazu, die Traube im Rücken zu lassen.
  void _archerActs(ActionEntity schuetze, double abstand, double dt) {
    schuetze.facing = (_hero.position - schuetze.position).normalized;

    if (abstand < ActionBalance.archerPreferredRange * 0.8) {
      // Zu nah — rückwärts, und zwar geradewegs weg. Das Wegfeld hilft
      // hier nicht, es zeigt ja zum Helden hin.
      schuetze.position = _slide(
        schuetze.position,
        schuetze.facing * (-schuetze.speed * dt),
        schuetze.radius,
      );
    } else if (abstand > ActionBalance.archerShootRange) {
      final richtung = _chaseDirection(schuetze);
      if (!richtung.isZero) {
        schuetze.position = _slide(
          schuetze.position,
          richtung * (schuetze.speed * dt),
          schuetze.radius,
        );
        _trackProgress(schuetze, dt);
      }
      return;
    }

    if (schuetze.cooldownLeft > 0) return;
    schuetze.cooldownLeft = schuetze.attackCooldown;

    _events.add(
      AttackSwung(
        attackerId: schuetze.id,
        faction: Faction.gegner,
        from: schuetze.position,
        direction: schuetze.facing,
      ),
    );
    _projectiles.add(
      Projectile(
        id: _nextId++,
        faction: Faction.gegner,
        position: schuetze.position,
        velocity: schuetze.facing * ActionBalance.projectileSpeed,
        damage: schuetze.attack,
        radius: ActionBalance.projectileRadius,
      ),
    );
  }

  // --- Geschosse ---

  void _moveProjectiles(double dt) {
    for (final geschoss in _projectiles) {
      if (geschoss.spent) continue;

      geschoss.age += dt;
      if (geschoss.age > ActionBalance.projectileLifetime) {
        geschoss.spent = true;
        continue;
      }

      geschoss.position = geschoss.position + geschoss.velocity * dt;

      if (_hitsWall(geschoss.position, geschoss.radius)) {
        geschoss.spent = true;
        continue;
      }

      for (final ziel in _entities) {
        if (!ziel.isAlive || ziel.faction == geschoss.faction) continue;
        final reichweite = geschoss.radius + ziel.radius;
        if (geschoss.position.distanceSquaredTo(ziel.position) >
            reichweite * reichweite) {
          continue;
        }

        geschoss.spent = true;
        final heldenKraft = geschoss.heroPower;
        if (heldenKraft != null) {
          if (geschoss.fromWeapon) {
            _weaponLanded(ziel, power: heldenKraft);
          } else {
            _hit(
              _hero,
              ziel,
              powerFactor: heldenKraft,
              leech: geschoss.heroLeech,
            );
          }
          break;
        }
        final wirklich = ziel.takeDamage(
          _mitigate(ziel, math.max(ActionBalance.minDamage, geschoss.damage)),
        );
        _events.add(
          HitLanded(
            targetId: ziel.id,
            targetFaction: ziel.faction,
            at: ziel.position,
            amount: wirklich,
            isCrit: false,
          ),
        );
        break;
      }
    }
    _projectiles.removeWhere((p) => p.spent);
  }

  // --- Heilkugeln ---

  void _moveOrbs(double dt) {
    for (final orb in _orbs) {
      if (orb.taken) continue;

      orb.age += dt;
      if (orb.age > ActionBalance.orbLifetime) {
        orb.taken = true;
        continue;
      }

      final zumHelden = _hero.position - orb.position;
      final abstand = zumHelden.length;

      if (abstand <= orb.radius + _hero.radius) {
        orb.taken = true;
        final vorher = _hero.hp;
        _hero.hp = math.min(_hero.maxHp, _hero.hp + orb.heal);
        _orbsCollected++;
        _events.add(
          OrbCollected(at: _hero.position, healed: _hero.hp - vorher),
        );
        continue;
      }

      // Sie fliegt von selbst, sobald man nah genug ist. Ein Prototyp
      // soll nicht am Pixelgenauen scheitern.
      if (abstand <= ActionBalance.orbMagnetRange) {
        orb.position = orb.position +
            zumHelden.normalized * (ActionBalance.orbMagnetSpeed * dt);
      }
    }
    _orbs.removeWhere((orb) => orb.taken);
  }

  // --- Schaden ---

  /// Ein Schlag von [attacker] auf [target]. Gibt zurück, was wirklich
  /// abgezogen wurde.
  int _hit(
    ActionEntity attacker,
    ActionEntity target, {
    double powerFactor = 1,
    double leech = 0,
  }) {
    final kritisch =
        attacker.critChance > 0 && _rng.nextDouble() < attacker.critChance;

    var roh = attacker.attack * attacker.damageMultiplier * powerFactor;
    if (kritisch) roh *= attacker.critFactor;

    final streuung =
        1 + (_rng.nextDouble() * 2 - 1) * ActionBalance.damageSpread;
    roh = roh * streuung - target.defense / ActionBalance.defenseDivisor;

    final schaden = math.max(ActionBalance.minDamage, roh.round());
    final wirklich = target.takeDamage(_mitigate(target, schaden));
    _knockBack(attacker, target);

    _events.add(
      HitLanded(
        targetId: target.id,
        targetFaction: target.faction,
        at: target.position,
        amount: wirklich,
        isCrit: kritisch,
      ),
    );

    if (leech > 0 && attacker.isHero && wirklich > 0) {
      _healHero((wirklich * leech).round());
    }
    if (target.isHero && !attacker.isHero && _reflectLeft > 0) {
      final zurueck = attacker.takeDamage(
        math.max(1, (wirklich * _reflectShare).round()),
      );
      _events.add(
        HitLanded(
          targetId: attacker.id,
          targetFaction: attacker.faction,
          at: attacker.position,
          amount: zurueck,
          isCrit: false,
        ),
      );
    }
    return wirklich;
  }

  /// Schiebt den Getroffenen ein Stück vom Schlag weg.
  ///
  /// **Der Endgegner und der Held bleiben stehen.** Ein Koloss, den man
  /// durch den Raum schiebt, ist kein Koloss — und ein Held, den fünf
  /// Gegner vor sich herschieben, gehört seinem Spieler nicht mehr.
  void _knockBack(ActionEntity attacker, ActionEntity target) {
    if (target.isHero ||
        target.kind == EnemyKind.endgegner ||
        target.kind == EnemyKind.brocken) {
      return;
    }

    final richtung = (target.position - attacker.position).normalized;
    if (richtung.isZero) return;

    target.position = _slide(
      target.position,
      richtung * ActionBalance.knockback,
      target.radius,
    );
  }

  // --- Bewegung und Wände ---

  /// Verschiebt [from] um [delta] und bleibt dabei aus Wänden heraus.
  ///
  /// **Erst bewegen, dann aus der Wand drücken** — entlang der Richtung
  /// vom nächsten Wandpunkt zur Mitte. An einer glatten Wand ist das
  /// Entlanggleiten, an einer **Ecke** zeigt diese Richtung schräg, und
  /// die Figur rutscht um die Kante herum.
  ///
  /// Vorher wurden die Achsen getrennt geprüft und eine blockierte einfach
  /// verworfen. An einer Ecke hiess das: stehen bleiben, und im Gedränge
  /// vor einer Tür nie wieder loskommen. Ein Troll, breiter als ein Feld,
  /// hing so an jedem Durchgang, dessen Feldmitte zu nah an der Wand lag.
  ///
  /// In Teilschritten von höchstens einem halben Radius, damit nichts
  /// durch eine Ecke tunnelt; wo sich eine Überlappung nicht auflösen
  /// lässt (ein Durchgang schmaler als die Figur), gilt die alte Regel.
  Vec2 _slide(Vec2 from, Vec2 delta, double radius) {
    final laenge = delta.length;
    if (laenge == 0) return from;
    final schritte = math.max(1, (laenge / (radius * 0.5)).ceil());
    final teil = delta * (1 / schritte);

    var position = from;
    for (var i = 0; i < schritte; i++) {
      position = _pushOut(position + teil, radius) ??
          _slideAxes(position, teil, radius);
    }
    return position;
  }

  /// Drückt einen Kreis aus allen Wänden, die er schneidet. Null, wenn
  /// das nicht gelingt — dann steckt er fest oder wäre eingeklemmt.
  Vec2? _pushOut(Vec2 center, double radius) {
    const size = ActionBalance.tileSize;
    var p = center;
    for (var runde = 0; runde < 4; runde++) {
      var geschoben = false;
      final vonX = ((p.x - radius) / size).floor();
      final bisX = ((p.x + radius) / size).floor();
      final vonY = ((p.y - radius) / size).floor();
      final bisY = ((p.y + radius) / size).floor();
      for (var y = vonY; y <= bisY; y++) {
        for (var x = vonX; x <= bisX; x++) {
          if (!_level.isWallAt(x, y)) continue;
          final nah = Vec2(
            p.x.clamp(x * size, (x + 1) * size),
            p.y.clamp(y * size, (y + 1) * size),
          );
          final weg = p - nah;
          final abstand = weg.length;
          if (abstand >= radius) continue;
          // Die Mitte liegt in der Wand: keine Richtung, nach der man
          // drücken könnte.
          if (abstand == 0) return null;
          p = p + weg * ((radius - abstand) / abstand);
          geschoben = true;
        }
      }
      if (!geschoben) return p;
    }
    return _hitsWall(p, radius - 0.01) ? null : p;
  }

  /// Die alte Regel: Achsen getrennt, eine blockierte fällt aus.
  Vec2 _slideAxes(Vec2 from, Vec2 delta, double radius) {
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
      _maybeDropOrb(entity);
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

  /// Manchmal bleibt etwas liegen.
  ///
  /// **Der Endgegner lässt nichts fallen.** Nach ihm ist der Lauf vorbei;
  /// eine Kugel dort wäre eine Belohnung für einen Weg, den niemand mehr
  /// geht. **Ein Troll lässt immer eine fallen** — er hat gekostet.
  void _maybeDropOrb(ActionEntity gefallen) {
    if (gefallen.kind == EnemyKind.endgegner) return;
    final sicher = gefallen.kind == EnemyKind.brocken;
    if (!sicher && _rng.nextDouble() >= ActionBalance.orbDropChance) return;

    final orb = HealthOrb(
      id: _nextId++,
      position: gefallen.position,
      heal: math.max(
        1,
        (_hero.maxHp * ActionBalance.orbHealShare).round(),
      ),
      radius: ActionBalance.orbRadius,
    );
    _orbs.add(orb);
    _events.add(OrbDropped(id: orb.id, at: orb.position));
  }

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

  int _hp(int base) {
    final stufe = stage;
    if (stufe == null) return base;
    return math.max(1, (base * stufe.hpFactor).round());
  }

  int _attack(int base) {
    final stufe = stage;
    if (stufe == null) return base;
    return math.max(1, (base * stufe.attackFactor).round());
  }

  int _defense(int base) => base + (stage?.defenseBonus ?? 0);

  ActionEntity _enemyFor(Spawn spawn) {
    return switch (spawn.kind) {
      EnemyKind.endgegner => ActionEntity(
          id: _nextId++,
          faction: Faction.gegner,
          kind: spawn.kind,
          position: level.centerOfSpawn(spawn),
          maxHp: _hp(ActionBalance.bossHp),
          attack: _attack(ActionBalance.bossAttack),
          defense: _defense(ActionBalance.bossDefense),
          radius: ActionBalance.bossRadius,
          speed: ActionBalance.bossSpeed,
          attackRange: ActionBalance.bossAttackRange,
          attackCooldown: ActionBalance.bossAttackCooldown,
        ),
      EnemyKind.schuetze => ActionEntity(
          id: _nextId++,
          faction: Faction.gegner,
          kind: spawn.kind,
          position: level.centerOfSpawn(spawn),
          maxHp: _hp(ActionBalance.archerHp),
          attack: _attack(ActionBalance.archerAttack),
          defense: _defense(ActionBalance.archerDefense),
          radius: ActionBalance.archerRadius,
          speed: ActionBalance.archerSpeed,
          attackRange: ActionBalance.archerShootRange,
          attackCooldown: ActionBalance.archerCooldown,
        ),
      EnemyKind.flink => ActionEntity(
          id: _nextId++,
          faction: Faction.gegner,
          kind: spawn.kind,
          position: level.centerOfSpawn(spawn),
          maxHp: _hp(ActionBalance.flinkHp),
          attack: _attack(ActionBalance.flinkAttack),
          defense: _defense(ActionBalance.flinkDefense),
          radius: ActionBalance.flinkRadius,
          speed: ActionBalance.flinkSpeed,
          attackRange: ActionBalance.flinkAttackRange,
          attackCooldown: ActionBalance.flinkAttackCooldown,
        ),
      EnemyKind.brocken => ActionEntity(
          id: _nextId++,
          faction: Faction.gegner,
          kind: spawn.kind,
          position: level.centerOfSpawn(spawn),
          maxHp: _hp(ActionBalance.brockenHp),
          attack: _attack(ActionBalance.brockenAttack),
          defense: _defense(ActionBalance.brockenDefense),
          radius: ActionBalance.brockenRadius,
          speed: ActionBalance.brockenSpeed,
          attackRange: ActionBalance.brockenAttackRange,
          attackCooldown: ActionBalance.brockenAttackCooldown,
        ),
      EnemyKind.fussvolk || EnemyKind.keiner => ActionEntity(
          id: _nextId++,
          faction: Faction.gegner,
          kind: EnemyKind.fussvolk,
          position: level.centerOfSpawn(spawn),
          maxHp: _hp(ActionBalance.trashHp),
          attack: _attack(ActionBalance.trashAttack),
          defense: _defense(ActionBalance.trashDefense),
          radius: ActionBalance.trashRadius,
          speed: ActionBalance.trashSpeed,
          attackRange: ActionBalance.trashAttackRange,
          attackCooldown: ActionBalance.trashAttackCooldown,
        ),
    };
  }
}
