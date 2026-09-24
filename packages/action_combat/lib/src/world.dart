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

part 'aim.dart';
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
    required Level level,
    required this.heroStats,
    this.stage,
    List<String> abilityIds = const <String>[],
    String? weaponMoveId,
    List<PitModifier> modifiers = const <PitModifier>[],
    this.rewardPot = const (xp: 0, gold: 0),
    int seed = 1,
  })  : _level = level,
        _rng = math.Random(seed),
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
      // Die Zahlen, wie die Grube sie führt (ADR-0042): mal zehn und mal
      // Level und Seltenheit. Der Schaden rechnet danach mit dem blossen
      // Angriff weiter, der Faktor steckt schon darin.
      maxHp: heroStats.combatMaxHp,
      attack: heroStats.combatAttack,
      defense: heroStats.combatDefense,
      radius: ActionBalance.heroRadius,
      speed: ActionBalance.heroSpeed,
      attackRange: weapon.range,
      attackCooldown: heroStats.attackCooldown * weapon.cooldownFactor,
      critChance: heroStats.critChance + ActionBalance.heroBaseCritChance,
      critFactor: heroStats.critFactor,
    );
    _entities.add(_hero);

    for (final spawn in level.spawns) {
      _entities.add(_enemyFor(spawn));
    }
    _totalEnemies = level.spawns.length;
    _boss = _entities.where((e) => e.kind == EnemyKind.endgegner).firstOrNull;
    // Mit Tor schläft der Wächter, bis es hinter dem Helden zufällt.
    // Ohne Tor — im Prototyp und in Testhallen — ist er von Anfang an da.
    final boss = _boss;
    if (level.hasGates && boss != null) {
      _bossPhase = _BossPhase.schlaeft;
      boss.untouchable = true;
    }
    _rebuildPath();
  }

  /// Was dieser Lauf höchstens einbringt — der Rest des Topfs der Stufe,
  /// den die Reihe hereinreicht (ADR-0041). Null in Tests, im Prototyp
  /// und bei einer Stufe, die heute nichts mehr zahlt.
  final ({int xp, int gold}) rewardPot;

  /// Was bisher aus dem Topf gefallen ist.
  int get runXp => _runXp;
  int get runGold => _runGold;
  int _runXp = 0;
  int _runGold = 0;

  /// Wie viele Gegner ausser dem Wächter schon gefallen sind.
  int _fussvolkGefallen = 0;

  ActionEntity? _boss;
  _BossPhase _bossPhase = _BossPhase.wach;
  double _entranceTime = 0;

  /// Die Halle, wie sie gerade ist — mit offenem oder geschlossenem Tor
  /// zum Wächterraum. Der Renderer liest sie jedes Bild neu und zeichnet
  /// ein geschlossenes Tor damit von selbst als Wand.
  Level get level => _level;
  Level _level;

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
  bool _timedOut = false;

  /// Was auf der Uhr steht. Unendlich ohne Stufe — die Halle des
  /// Prototyps und die Tests laufen ohne Uhr.
  late double _timeLeft = stage?.timeLimitSeconds ?? double.infinity;

  /// Das Wegfeld zum Helden. Jeder Gegner liest daraus seine
  /// Richtung ab — eine Flutfüllung für alle statt einer Suche je
  /// Gegner.
  late FlowField _pathToHero;

  /// Dasselbe für Figuren, die breiter sind als ein Feld.
  late FlowField _widePathToHero;
  int _stepsSincePath = 0;

  final List<Projectile> _projectiles = <Projectile>[];

  /// Abgesetzte Flächen, die noch liegen.
  final List<_Zone> _zones = <_Zone>[];
  final List<HealthOrb> _orbs = <HealthOrb>[];

  // --- Was die Darstellung sehen darf ---

  /// Kopien, keine Verweise: Die Darstellung soll zeichnen, nicht
  /// mitspielen.
  List<EntityView> get views {
    return <EntityView>[
      for (final entity in _entities)
        if (entity.isAlive && _isShown(entity)) _viewOf(entity),
    ];
  }

  /// Der schlafende Wächter steht nicht im Bild.
  bool _isShown(ActionEntity entity) {
    return entity != _boss || _bossPhase != _BossPhase.schlaeft;
  }

  /// Wie der Renderer eine Figur sieht. Beim Auftritt steht der Wächter
  /// höher, als er ist — so fällt er ins Bild, ohne dass der Renderer
  /// davon wissen muss.
  EntityView _viewOf(ActionEntity entity) {
    final view = EntityView.of(entity);
    final hoehe = entity == _boss ? _dropHeight : 0.0;
    if (hoehe == 0) return view;
    return EntityView(
      id: view.id,
      faction: view.faction,
      kind: view.kind,
      position: view.position - Vec2(0, hoehe),
      radius: view.radius,
      hpRatio: view.hpRatio,
      facing: view.facing,
      isAlive: view.isAlive,
      isSlowed: view.isSlowed,
      isBurning: view.isBurning,
    );
  }

  /// Wie hoch der Wächter beim Auftritt noch über seinem Platz ist —
  /// schneller werdend, wie etwas, das fällt.
  double get _dropHeight {
    if (_bossPhase != _BossPhase.auftritt) return 0;
    const landung =
        ActionBalance.bossEntranceSeconds * ActionBalance.bossLandsShare;
    if (_entranceTime >= landung) return 0;
    final rest = 1 - _entranceTime / landung;
    return ActionBalance.bossDropHeight * rest * rest;
  }

  EntityView get heroView => EntityView.of(_hero);

  List<ProjectileView> get projectiles {
    return <ProjectileView>[
      for (final p in _projectiles)
        if (!p.spent) ProjectileView.of(p),
    ];
  }

  /// Die liegenden Flächen — Eisfeld, Giftboden, Sturm.
  List<ZoneView> get zones {
    return <ZoneView>[
      for (final zone in _zones)
        ZoneView(
          center: zone.center,
          radius: zone.radius,
          tint: zone.tint,
          remaining: (zone.secondsLeft / zone.seconds).clamp(0.0, 1.0),
        ),
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

  /// Wirkt eine Fähigkeit von einem Platz — **kurz getippt**: Sie zielt
  /// selbst, auf den nächsten Gegner, den der Held sieht. Gibt false
  /// zurück, wenn sie nicht geht — nicht auf einem Platz, nicht
  /// abgeklungen, zu wenig Mana, oder niemand da, worauf sie zielen könnte.
  ///
  /// **Kein Ziel, kein Mana.** Wer ins Leere tippt, soll nicht bestraft
  /// werden, sondern es gleich noch einmal versuchen können.
  bool cast(String id) => _castWith(id, null);

  /// Wirkt eine Fähigkeit von einem Platz — **gezielt**, nach dem Halten:
  /// in Richtung [target] oder, bei einem Bereich, an [target] (höchstens
  /// so weit, wie sie reicht; gezielt werden darf über Wände hinweg,
  /// ein Geschoss bleibt trotzdem an ihnen hängen).
  ///
  /// Anders als [cast] kostet sie hier **immer**: Ein Skillshot, der
  /// danebengeht, ist ein verfehlter Skillshot.
  bool castAt(String id, Vec2 target) => _castWith(id, target);

  /// Was [castAt] mit [target] täte — für die Vorschau beim Halten. Null
  /// bei einer Fähigkeit ohne Ziel (Heilung, Schutz, Mana), und null
  /// [target] zeigt, wohin kurzes Tippen zielen würde.
  AimPreview? aimPreview(String id, Vec2? target) {
    final ability = _slotFor(id);
    if (ability == null) return null;
    return _preview(ability, target);
  }

  bool _castWith(String id, Vec2? zielpunkt) {
    if (!canCast(id)) return false;
    final ability = _slotFor(id);
    if (ability == null) return false;
    final plan = _plan(ability, zielpunkt);
    if (plan == null) return false;

    _mana -= ability.manaCost;
    _slotCooldowns[id] = ability.cooldown;
    _events.add(AbilityCast(id: id, at: plan.center));

    final flaechen = <double, _Zone>{};
    for (final effect in ability.effects) {
      _apply(effect, ability, plan, flaechen);
    }
    // Eine Fläche greift schon beim Aufschlagen, nicht erst im nächsten
    // Schritt.
    for (final zone in flaechen.values) {
      _affect(zone);
    }
    _zones.addAll(flaechen.values);
    return true;
  }

  /// Die eine Stelle, die jede Art von [PitEffect] ausführt — dorthin,
  /// wohin [plan] zeigt.
  void _apply(
    PitEffect effect,
    PitAbility ability,
    _CastPlan plan,
    Map<double, _Zone> flaechen,
  ) {
    switch (effect) {
      case BoltAtNearest(:final power, :final range, :final leech):
        final richtung = plan.direction;
        if (richtung != null) {
          _shootAlong(richtung, power: power, weite: range, leech: leech);
          return;
        }
        final ziel = _nearestEnemyWithin(range, needsSight: true);
        if (ziel == null) return;
        _shoot(ziel, power: power, leech: leech);
      case StrikeNearest(:final power, :final range):
        final richtung = plan.direction;
        final ziel = richtung != null
            ? _nearestInCone(richtung, range)
            : _nearestEnemyWithin(range);
        if (richtung != null) _hero.facing = richtung;
        if (ziel == null) return;
        _hero.facing = (ziel.position - _hero.position).normalized;
        _hit(_hero, ziel, powerFactor: power);
      case StrikeAround(:final power, :final radius):
        for (final ziel in _enemiesAround(plan.center, radius)) {
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
        if (plan.placed) {
          final zone = _zoneFor(flaechen, plan, ability, radius, seconds);
          zone.slowFactor = math.min(zone.slowFactor, factor);
          return;
        }
        for (final ziel in _enemiesWithin(radius)) {
          ziel.slowFactor =
              ziel.slowLeft > 0 ? math.min(ziel.slowFactor, factor) : factor;
          ziel.slowLeft = math.max(ziel.slowLeft, seconds);
        }
      case DamageOverTime(:final radius, :final perSecond, :final seconds):
        final jeSekunde = _hero.attack * _hero.damageMultiplier * perSecond;
        if (plan.placed) {
          final zone = _zoneFor(flaechen, plan, ability, radius, seconds);
          zone.dotPerSecond = math.max(zone.dotPerSecond, jeSekunde);
          return;
        }
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
            !ziel.untouchable &&
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
      if (!ziel.isAlive || ziel.isHero || ziel.untouchable) continue;
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
  ///
  /// **Erst ab seiner Landung**, wie Name und Balken in Dark Souls:
  /// Solange er schläft oder noch fällt, gibt es ihn für die Kopfzeile
  /// nicht.
  EntityView? get bossView {
    final boss = _boss;
    if (boss == null || !boss.isAlive || !_bossLanded) return null;
    return EntityView.of(boss);
  }

  bool get _bossLanded {
    return switch (_bossPhase) {
      _BossPhase.wach => true,
      _BossPhase.schlaeft => false,
      _BossPhase.auftritt => _entranceTime >=
          ActionBalance.bossEntranceSeconds * ActionBalance.bossLandsShare,
    };
  }

  /// Wie weit der Balken des Wächters gefüllt gezeigt wird, 0 bis 1 —
  /// er läuft nach der Landung voll, statt einfach dazustehen.
  double get bossBarFill {
    if (_bossPhase == _BossPhase.wach) return 1;
    if (!_bossLanded) return 0;
    const gesamt = ActionBalance.bossEntranceSeconds;
    const landung = gesamt * ActionBalance.bossLandsShare;
    return ((_entranceTime - landung) / (gesamt - landung)).clamp(0.0, 1.0);
  }

  /// Wie weit der Auftritt ist, 0 bis 1 — oder null, wenn gerade keiner
  /// läuft. Für den Schriftzug in der Mitte des Bildes.
  double? get bossEntrance {
    if (_bossPhase != _BossPhase.auftritt) return null;
    return (_entranceTime / ActionBalance.bossEntranceSeconds).clamp(0.0, 1.0);
  }

  /// Wo der Wächter schläft, solange er schläft — sonst null. Für den
  /// Bot: Er sieht ihn nicht und fände den Raum sonst nie.
  Vec2? get sleepingBossAt {
    if (_bossPhase != _BossPhase.schlaeft) return null;
    return _boss?.position;
  }

  int get heroHp => _hero.hp;

  int get heroMaxHp => _hero.maxHp;

  double get heroHpRatio => _hero.hpRatio;

  int get kills => _kills;

  int get totalEnemies => _totalEnemies;

  int get enemiesLeft => _totalEnemies - _kills;

  double get elapsed => _elapsed;

  /// Wie viele Sekunden der Lauf hat, oder `null` ohne Uhr.
  double? get timeLimit => stage?.timeLimitSeconds;

  /// Was noch auf der Uhr steht, oder `null` ohne Uhr.
  double? get timeLeft => stage == null ? null : _timeLeft.clamp(0, 1e9);

  /// Ob der Lauf endete, weil die Uhr ablief.
  bool get isTimedOut => _timedOut;

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
    _timeLeft -= dt;

    _stepsSincePath++;
    if (_stepsSincePath >= ActionBalance.pathRefreshSteps) {
      _rebuildPath();
    }

    _tickMana(dt);
    _moveHero(moveInput, dt);
    _heroAttack(dt);
    _tickZones(dt);
    _enemiesAct(dt);
    _tickStatus(dt);
    _moveProjectiles(dt);
    _separate();
    _moveOrbs(dt);
    _collectDead();
    _updateGate();
    _tickEntrance(dt);
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
      if (entity.untouchable) continue;
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
      if (!gegner.isAlive || gegner.isHero || gegner.untouchable) continue;

      final abstand = gegner.position.distanceTo(_hero.position);
      // **Wer weiter schiesst, als er sieht, wäre blind.** Der
      // Fernkämpfer hat eine grössere Reichweite als der Aufmerksamkeits-
      // radius; ohne diese Zeile stünde er da und liesse sich beschiessen.
      final merkt = math.max(ActionBalance.aggroRadius, gegner.attackRange);
      // **Wer getroffen wurde, weiss, woher.** Schaden kommt nur vom
      // Helden — ein Funke aus der Ferne, eine Fläche, Dauerschaden —,
      // und wer ihn nimmt, kommt. Sonst stünde ein Gegner still da und
      // liesse sich aus sicherer Entfernung abtragen.
      final verwundet = gegner.hp < gegner.maxHp;
      // **Nah genug heisst nicht gesehen.** Ohne Blickkontakt zog der
      // Radius Gegner durch Wände aus dem Nachbarraum. Jetzt kommt nur,
      // wer den Helden sieht — oder von ihm getroffen wurde.
      if (!gegner.aggro &&
          (verwundet ||
              (abstand <= merkt && _canSee(gegner.position, _hero.position)))) {
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
      if (gegner.kind == EnemyKind.flatterer) {
        _batActs(gegner, abstand, takt);
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

  /// Die Fledermaus: im Zickzack heran, beissen, davonflattern.
  ///
  /// Der Zickzack ist gesät über ihre Id und die Weltzeit, also genauso
  /// wiederholbar wie alles andere in der Halle.
  void _batActs(ActionEntity fledermaus, double abstand, double takt) {
    fledermaus.retreatLeft -= takt;
    final zumHelden = (_hero.position - fledermaus.position).normalized;
    final seitlich = Vec2(-zumHelden.y, zumHelden.x) *
        (ActionBalance.flattererWobble *
            math.sin(
              _elapsed * ActionBalance.flattererWobbleSpeed + fledermaus.id,
            ));

    if (fledermaus.retreatLeft > 0) {
      // Weg vom Helden, geradewegs — wie der Schütze, nur flatternd.
      final weg = (zumHelden * -1 + seitlich).normalized;
      fledermaus.facing = weg;
      fledermaus.position = _slide(
        fledermaus.position,
        weg * (fledermaus.speed * takt),
        fledermaus.radius,
      );
      return;
    }

    final reichweite = fledermaus.attackRange + _hero.radius;
    if (abstand > reichweite) {
      final richtung = _chaseDirection(fledermaus);
      if (richtung.isZero) return;
      final flug = (richtung + seitlich).normalized;
      fledermaus.facing = flug;
      fledermaus.position = _slide(
        fledermaus.position,
        flug * (fledermaus.speed * takt),
        fledermaus.radius,
      );
      _trackProgress(fledermaus, takt);
      return;
    }

    if (fledermaus.cooldownLeft > 0) return;
    fledermaus.cooldownLeft = fledermaus.attackCooldown;
    fledermaus.facing = zumHelden;
    _events.add(
      AttackSwung(
        attackerId: fledermaus.id,
        faction: Faction.gegner,
        from: fledermaus.position,
        direction: zumHelden,
      ),
    );
    _hit(fledermaus, _hero);
    fledermaus.retreatLeft = ActionBalance.flattererRetreatSeconds;
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
      if (geschoss.age > geschoss.maxAge) {
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
        if (ziel.untouchable) continue;
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
        if (orb.kind == OrbKind.zeit) {
          _collectTime(orb);
          continue;
        }
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

  /// Legt die Sekunden einer Zeitkugel auf die Uhr — nie über das Limit.
  void _collectTime(HealthOrb orb) {
    final limit = timeLimit;
    if (limit == null) return;
    final vorher = _timeLeft;
    _timeLeft = math.min(limit, _timeLeft + orb.seconds);
    _events.add(TimeGained(at: _hero.position, seconds: _timeLeft - vorher));
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

    final breite = attacker.isHero
        ? ActionBalance.heroDamageSpread
        : ActionBalance.damageSpread;
    final streuung = 1 + (_rng.nextDouble() * 2 - 1) * breite;
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
    return _touches(center, radius, _level.isWallAt);
  }

  /// Ob ein Kreis um [center] ein Feld streift, für das [test] gilt.
  bool _touches(Vec2 center, double radius, bool Function(int, int) test) {
    const size = ActionBalance.tileSize;
    final vonX = ((center.x - radius) / size).floor();
    final bisX = ((center.x + radius) / size).floor();
    final vonY = ((center.y - radius) / size).floor();
    final bisY = ((center.y + radius) / size).floor();

    for (var y = vonY; y <= bisY; y++) {
      for (var x = vonX; x <= bisX; x++) {
        if (!test(x, y)) continue;
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
      if (!a.isAlive || a.untouchable) continue;
      for (var j = i + 1; j < _entities.length; j++) {
        final b = _entities[j];
        if (!b.isAlive || b.untouchable) continue;
        // Wer sich aus einem Stau löst, geht durch Verbündete hindurch.
        if (!a.isHero && !b.isHero && (a.ghostLeft > 0 || b.ghostLeft > 0)) {
          continue;
        }

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
      _maybeDropTime(entity);
      _dropLoot(entity);
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

  /// Zahlt den Teil des Topfs, der an [gefallen] hängt.
  ///
  /// **Gerechnet als Stand, nicht als Häppchen:** Nach k von n Gegnern ist
  /// genau `k/n` des Fussvolk-Anteils gezahlt, abgerundet. So gehen durch
  /// Rundung keine Punkte verloren und keine kommen dazu. **Der Wächter
  /// füllt den Topf auf** — mit ihm ist die Grube geschafft, und wer ihn
  /// fällt, bekommt alles, auch den Teil der Gegner, die noch stehen.
  void _dropLoot(ActionEntity gefallen) {
    if (rewardPot.xp <= 0 && rewardPot.gold <= 0) return;

    final int zielXp;
    final int zielGold;
    if (gefallen == _boss) {
      zielXp = rewardPot.xp;
      zielGold = rewardPot.gold;
    } else {
      final alle = level.trashCount;
      if (alle <= 0) return;
      _fussvolkGefallen++;
      const anteil = 1 - ActionBalance.bossLootShare;
      final stand = _fussvolkGefallen / alle * anteil;
      zielXp = (rewardPot.xp * stand).floor();
      zielGold = (rewardPot.gold * stand).floor();
    }

    final xp = zielXp - _runXp;
    final gold = zielGold - _runGold;
    if (xp <= 0 && gold <= 0) return;
    _runXp = zielXp;
    _runGold = zielGold;
    _events.add(LootDropped(at: gefallen.position, xp: xp, gold: gold));
  }

  // --- Das Tor zum Wächterraum ---

  /// Schliesst das Tor hinter dem Helden — und weckt den Wächter.
  ///
  /// **Zu erst, wenn der Held ganz drin ist und niemand im Tor steht.**
  /// Wer im Durchgang stünde, steckte danach in der Wand. Wer ihm folgt,
  /// wartet also vor dem Tor mit — oder kommt eben noch hinein.
  ///
  /// **Es geht nicht wieder auf.** Fällt der Wächter, ist der Lauf
  /// gewonnen, ob draussen noch jemand steht oder nicht.
  void _updateGate() {
    if (!_level.hasGates || _level.gatesClosed) return;
    if (!_insideArena(_hero)) return;
    for (final entity in _entities) {
      if (!entity.isAlive || entity.untouchable) continue;
      if (_touches(entity.position, entity.radius, _level.isGateAt)) return;
    }

    _level = _level.withGates(closed: true);
    _rebuildPath();
    _events.add(GateClosed(at: _gateCenter()));
    if (_bossPhase == _BossPhase.schlaeft) {
      _bossPhase = _BossPhase.auftritt;
      _entranceTime = 0;
    }
  }

  /// Der Auftritt: fallen, aufschlagen, brüllen — dann ist er wach.
  void _tickEntrance(double dt) {
    final boss = _boss;
    if (_bossPhase != _BossPhase.auftritt || boss == null) return;

    final warGelandet = _bossLanded;
    _entranceTime += dt;
    if (!warGelandet && _bossLanded) {
      _events.add(BossLanded(at: boss.position));
    }
    if (_entranceTime < ActionBalance.bossEntranceSeconds) return;

    _bossPhase = _BossPhase.wach;
    boss.untouchable = false;
    boss.aggro = true;
  }

  /// Ob [entity] mit ihrem ganzen Umriss im Wächterraum steht.
  bool _insideArena(ActionEntity entity) {
    const size = ActionBalance.tileSize;
    final p = entity.position;
    final r = entity.radius;
    for (var y = ((p.y - r) / size).floor();
        y <= ((p.y + r) / size).floor();
        y++) {
      for (var x = ((p.x - r) / size).floor();
          x <= ((p.x + r) / size).floor();
          x++) {
        if (!_level.isArenaAt(x, y)) return false;
      }
    }
    return true;
  }

  /// Die Mitte aller Tor-Felder.
  Vec2 _gateCenter() {
    const size = ActionBalance.tileSize;
    var summe = Vec2.zero;
    var anzahl = 0;
    for (var y = 0; y < _level.height; y++) {
      for (var x = 0; x < _level.width; x++) {
        if (!_level.isGateAt(x, y)) continue;
        summe = summe + Vec2(x * size + size / 2, y * size + size / 2);
        anzahl++;
      }
    }
    return anzahl == 0 ? Vec2.zero : summe * (1 / anzahl);
  }

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
      kind: OrbKind.heilung,
      seconds: 0,
    );
    _orbs.add(orb);
    _events.add(OrbDropped(id: orb.id, at: orb.position));
  }

  /// Manchmal eine Zeitkugel — nur mit Uhr, nie vom Wächter.
  ///
  /// Sie fällt ein Stück neben die Heilkugel, damit beide zu sehen sind.
  void _maybeDropTime(ActionEntity gefallen) {
    if (stage == null || gefallen.kind == EnemyKind.endgegner) return;
    if (_rng.nextDouble() >= ActionBalance.timeDropChance) return;

    final orb = HealthOrb(
      id: _nextId++,
      position: gefallen.position + const Vec2(10, 6),
      heal: 0,
      radius: ActionBalance.orbRadius,
      kind: OrbKind.zeit,
      seconds: ActionBalance.timeDropSeconds,
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
    // **Mit dem Wächter ist die Grube geschafft**, nicht erst mit dem
    // letzten Gegner. Nur eine Halle ohne Wächter — es gibt sie nur in
    // Tests — muss man leer räumen.
    final boss = _boss;
    final geschafft = boss != null ? !boss.isAlive : _kills >= _totalEnemies;
    if (geschafft) {
      _finish(won: true);
      return;
    }
    // **Die Uhr zuletzt:** Wer im letzten Schritt den Wächter fällt, hat
    // gewonnen, auch wenn die Uhr im selben Schritt null zeigt.
    if (_timeLeft <= 0) _finish(won: false, timedOut: true);
  }

  void _finish({required bool won, bool timedOut = false}) {
    _over = true;
    _won = won;
    _timedOut = timedOut;
    _events.add(
      RunEnded(
        won: won,
        seconds: _elapsed,
        kills: _kills,
        timedOut: timedOut,
      ),
    );
  }

  /// Wohin dieser Gegner laufen muss, um beim Helden anzukommen.
  ///
  /// **Geradeaus, wo es geht, sonst um die Ecke — aber schräg.** Passt
  /// der Gegner mit seiner ganzen Breite in Luftlinie zum Helden, läuft
  /// er direkt. Sonst folgt er dem Wegfeld, steuert aber den weitesten
  /// Punkt darauf an, den er noch ohne Wand erreicht. Feld für Feld
  /// gefolgt ergäbe das Feld eine Treppe aus rechten Winkeln — es kennt
  /// nur vier Richtungen.
  ///
  /// Ohne das Feld bliebe jeder an der ersten Ecke stehen — genau das hat
  /// der kopflose Lauf beim ersten Versuch gemeldet, bevor es das Feld
  /// gab.
  Vec2 _chaseDirection(ActionEntity gegner) {
    final direkt = _hero.position - gegner.position;
    if (direkt.length <= ActionBalance.directChaseRange ||
        _canPass(gegner.position, _hero.position, gegner.radius)) {
      return direkt.normalized;
    }
    // Kein Weg — etwa vor dem geschlossenen Tor. Stehen, nicht gegen die
    // Wand drücken.
    final feld = _fieldFor(gegner);
    if (feld.distanceAtPoint(gegner.position) == null) {
      return Vec2.zero;
    }

    final weg = feld.pathFrom(
      gegner.position,
      maxSteps: ActionBalance.chaseLookaheadTiles,
    );
    if (weg.isEmpty) return direkt.normalized;

    // Die Wegpunkte sind Feldmitten. Für einen Troll, breiter als ein
    // Feld, liegt eine davon im Durchgang zu nah an der Wand — er zielte
    // auf einen Platz, an dem er nicht stehen kann, und blieb hängen.
    // Also erst auf seine Breite aus der Wand drücken.
    final punkte = <Vec2>[
      for (final punkt in weg) _pushOut(punkt, gegner.radius) ?? punkt,
    ];

    // Vorwärts, bis der erste Punkt nicht mehr frei erreichbar ist: Der
    // Weg biegt um Ecken, und was hinter einer liegt, bleibt dahinter.
    var ziel = punkte.first;
    for (final punkt in punkte.skip(1)) {
      if (!_canPass(gegner.position, punkt, gegner.radius)) break;
      ziel = punkt;
    }
    final richtung = ziel - gegner.position;
    return richtung.isZero ? direkt.normalized : richtung.normalized;
  }

  /// Ob ein Körper mit [radius] geradewegs von [a] nach [b] kommt, ohne
  /// eine Wand zu streifen. Strenger als [_canSee]: Eine Sichtlinie
  /// passt durch jede Türritze, ein Troll nicht.
  bool _canPass(Vec2 a, Vec2 b, double radius) {
    final weg = b - a;
    final abstand = math.min(radius, ActionBalance.tileSize / 4);
    final schritte = (weg.length / abstand).ceil();
    for (var i = 1; i <= schritte; i++) {
      if (_hitsWall(a + weg * (i / schritte), radius)) return false;
    }
    return true;
  }

  /// Merkt sich, ob [gegner] beim Verfolgen vorankommt. Tritt er zu lange
  /// auf der Stelle, geht er eine Weile durch Verbündete hindurch — der
  /// Stau in einer Tür löst sich so von selbst.
  void _trackProgress(ActionEntity gegner, double dt) {
    final anker = gegner.progressAnchor;
    if (anker == null ||
        anker.distanceTo(gegner.position) > ActionBalance.stuckDistance) {
      gegner.progressAnchor = gegner.position;
      gegner.stuckFor = 0;
      return;
    }
    gegner.stuckFor += dt;
    if (gegner.stuckFor < ActionBalance.stuckSeconds) return;
    gegner.stuckFor = 0;
    gegner.ghostLeft = ActionBalance.ghostSeconds;
  }

  /// Das Wegfeld, das zur Breite von [gegner] passt. Ein breiter, der
  /// gerade auf einem Feld steht, das das breite Feld nicht kennt, nimmt
  /// das schmale — sonst stünde er dort für immer.
  FlowField _fieldFor(ActionEntity gegner) {
    if (gegner.radius <= ActionBalance.tileSize / 2) return _pathToHero;
    if (_widePathToHero.distanceAtPoint(gegner.position) == null) {
      return _pathToHero;
    }
    return _widePathToHero;
  }

  void _rebuildPath() {
    const size = ActionBalance.tileSize;
    final x = (_hero.position.x / size).floor();
    final y = (_hero.position.y / size).floor();
    _pathToHero = FlowField.from(level, x, y);
    _widePathToHero = FlowField.from(level, x, y, wide: true);
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

  /// Die Gegnerwerte — mal der Stufe und immer mal [ActionBalance.powerScale],
  /// auch ohne Stufe: Held und Gegner müssen im selben Massstab stehen.
  int _hp(int base) {
    final faktor = stage?.hpFactor ?? 1;
    return math.max(1, (base * faktor * ActionBalance.powerScale).round());
  }

  int _attack(int base) {
    final faktor = stage?.attackFactor ?? 1;
    return math.max(1, (base * faktor * ActionBalance.powerScale).round());
  }

  int _defense(int base) {
    final stufe = stage;
    final roh = base + (stufe?.defenseBonus ?? 0);
    final faktor = stufe?.powerFactor ?? 1;
    return (roh * faktor * ActionBalance.powerScale).round();
  }

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
      EnemyKind.flatterer => ActionEntity(
          id: _nextId++,
          faction: Faction.gegner,
          kind: spawn.kind,
          position: level.centerOfSpawn(spawn),
          maxHp: _hp(ActionBalance.flattererHp),
          attack: _attack(ActionBalance.flattererAttack),
          defense: _defense(ActionBalance.flattererDefense),
          radius: ActionBalance.flattererRadius,
          speed: ActionBalance.flattererSpeed,
          attackRange: ActionBalance.flattererAttackRange,
          attackCooldown: ActionBalance.flattererAttackCooldown,
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

/// Wo der Wächter in seinem Lauf steht.
enum _BossPhase {
  /// Unsichtbar in seinem Raum, bis das Tor hinter dem Helden zufällt.
  schlaeft,

  /// Fällt herab und brüllt — unverwundbar, untätig.
  auftritt,

  /// Kämpft.
  wach,
}
