import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:action_combat/action_combat.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../ui/palette.dart';
import 'action_sprites.dart';
import 'damage_popup.dart';
import 'figure_state.dart';
import 'pit_tints.dart';

/// Die Halle, gezeichnet.
///
/// **Sie spielt nicht mit.** Die Welt rechnet in `package:action_combat`
/// und gibt Ereignisse aus; hier wird nur gezeichnet und abgespielt —
/// dieselbe Naht wie zwischen `CombatSession` und `battle_game.dart`
/// (ADR-0002). Der einzige Weg hinein ist [moveInput].
///
/// Gezeichnet wird ohne Flames Komponentenbaum, direkt auf die Leinwand:
/// Für dreissig Quadrate ist ein Baum aus Komponenten mehr Buchhaltung
/// als Nutzen, und ein Prototyp soll an einer Stelle lesbar sein.
class ActionGame extends Game {
  ActionGame({required this.sim, this.onRunEnded});

  final ActionWorld sim;

  /// Wird genau einmal gerufen, wenn der Lauf vorbei ist.
  final VoidCallback? onRunEnded;

  /// Zählt Bilder hoch, damit die Anzeige darüber sich neu bauen kann.
  ///
  /// **Ein Notifier statt `setState`.** Der Bildschirm sechzigmal je
  /// Sekunde neu zu bauen hiesse, auch das Steuerkreuz und die Overlays
  /// neu zu bauen. So hängt nur die Kopfzeile daran.
  final ValueNotifier<int> frame = ValueNotifier<int>(0);

  /// Die Laufrichtung, gesetzt von Steuerkreuz oder Tastatur.
  Vec2 moveInput = Vec2.zero;

  final List<DamagePopup> _popups = <DamagePopup>[];
  final List<SwingMark> _swings = <SwingMark>[];
  final List<Burst> _bursts = <Burst>[];

  /// Wer gerade getroffen wurde, und wie lange das noch aufblitzt.
  ///
  /// **Im Renderer, nicht in der Welt.** Ein Trefferblitz ist Anzeige;
  /// die Simulation weiss nichts davon und soll es nicht.
  final Map<int, double> _flashes = <int, double>{};

  bool _endeGemeldet = false;

  /// Die Bilder der Figuren — `null`, solange sie laden oder wenn sie
  /// fehlen. Dann stehen dort die Würfel des ersten Prototyps; ein Lauf
  /// bleibt spielbar, auch ohne ein einziges Bild.
  GrubeBilder? _bilder;

  /// Was jede Figur gerade tut, je Id. Anzeige, nicht Simulation.
  final Map<int, FigureState> _figuren = <int, FigureState>{};

  /// Wer gefallen ist und gerade umkippt.
  final List<FallenFigure> _leichen = <FallenFigure>[];

  @override
  Future<void> onLoad() async {
    // **Nicht abwarten.** Mit `await` zeigte das Spiel bis zum Ende des
    // Ladens gar nichts — und in Widget-Tests, in denen Bilder nie fertig
    // entpackt werden, bliebe es für immer leer. So läuft der Lauf sofort
    // mit Würfeln los, und die Figuren erscheinen, sobald sie da sind.
    unawaited(
      GrubeBilder.load().then(
        (bilder) => _bilder = bilder,
        onError: (Object fehler) {
          debugPrint('Die Grube läuft ohne Bilder: $fehler');
        },
      ),
    );
  }

  // --- Zielen ---

  /// Welche Fähigkeit gerade gehalten wird, oder null.
  String? get aimingId => _zielId;
  String? _zielId;

  /// Wohin gezielt wird, in Weltkoordinaten. Null heisst: Die Fähigkeit
  /// zielt selbst, wie beim kurzen Tippen.
  Vec2? _zielPunkt;

  /// Wie weit der Daumen gezogen werden muss, damit der Skillshot seine
  /// volle Reichweite hat. Näher als [_totzone] gilt als Tippen.
  static const double _vollerZug = 80;
  static const double _totzone = 12;

  /// Ein Platz wird gehalten. Ab jetzt zeigt das Bild die Vorschau.
  void beginAim(String id) {
    _zielId = id;
    _zielPunkt = null;
  }

  /// Der Daumen ist um [zug] Bildpunkte vom Knopf weggezogen: Richtung
  /// und Länge werden auf die Reichweite der Fähigkeit umgelegt.
  void aimDrag(Vec2 zug) {
    final id = _zielId;
    if (id == null) return;
    if (zug.length < _totzone) {
      _zielPunkt = null;
      return;
    }
    final weite = _reachOf(id);
    final anteil = (zug.length / _vollerZug).clamp(0.0, 1.0);
    _zielPunkt = sim.heroView.position + zug.normalized * (weite * anteil);
  }

  /// Gezielt wird auf einen Punkt im Bild — die Maus am Rechner.
  void aimAtScreen(Offset punkt) {
    if (_zielId == null) return;
    _zielPunkt = screenToWorld(punkt);
  }

  /// Losgelassen: kurz getippt zielt selbst, gezogen wirkt dorthin.
  bool releaseAim() {
    final id = _zielId;
    final punkt = _zielPunkt;
    _zielId = null;
    _zielPunkt = null;
    if (id == null) return false;
    return punkt == null ? sim.cast(id) : sim.castAt(id, punkt);
  }

  void cancelAim() {
    _zielId = null;
    _zielPunkt = null;
  }

  double _reachOf(String id) {
    for (final ability in sim.slots) {
      if (ability.id == id) return ability.reach;
    }
    return 0;
  }

  /// Ein Punkt im Bild als Punkt in der Grube.
  Vec2 screenToWorld(Offset punkt) {
    final kamera = _cameraOffset(sim.heroView.position);
    return Vec2(punkt.dx - kamera.x, punkt.dy - kamera.y);
  }

  /// Nur für Tests: was gerade an Zahlen in der Luft steht.
  int get popupCount => _popups.length;

  @override
  Color backgroundColor() => Palette.background;

  /// Wie lange das Bild nach der Landung des Wächters noch bebt.
  double _beben = 0;
  static const double _bebenDauer = 0.45;
  static const double _bebenStaerke = 7;

  @override
  void update(double dt) {
    sim.advance(dt, moveInput);
    if (_beben > 0) _beben -= dt;

    for (final event in sim.drainEvents()) {
      switch (event) {
        case HitLanded():
          final popup = DamagePopup.forHit(event);
          if (popup != null) _popups.add(popup);
          _flashes[event.targetId] = Burst.flashTime;
          _figuren[event.targetId]?.hit();
        case AttackSwung():
          _figuren[event.attackerId]?.swing(Pose.attack);
          _swings.add(
            SwingMark(
              origin: event.from,
              direction: event.direction,
              isHero: event.faction == Faction.held,
            ),
          );
        case EntityDied():
          _bursts.add(Burst.death(event.at, event.kind));
          _flashes.remove(event.id);
          _leichen.add(
            FallenFigure(
              figure: GrubeFiguren.forKind(event.kind),
              at: event.at,
              facesLeft: _figuren[event.id]?.facesLeft ?? false,
            ),
          );
          _figuren.remove(event.id);
        case OrbDropped():
        case EnemyNoticed():
          break;
        case OrbCollected():
          if (event.healed > 0) {
            _popups.add(DamagePopup.forHeal(event.healed, event.at));
          }
        case AbilityCast():
          _figuren[sim.heroView.id]?.swing(Pose.attack2);
          // Ein Flächentreffer bekommt den goldenen Ring, so gross wie
          // seine Reichweite — sonst sähe man nicht, was er erfasst hat.
          for (final effect
              in PitAbilities.byId(event.id)?.effects ?? const <PitEffect>[]) {
            if (effect is StrikeAround) {
              _bursts.add(Burst.cleave(event.at, effect.radius));
            }
          }
        case HeroHealed():
          if (event.amount > 0) {
            _popups.add(DamagePopup.forHeal(event.amount, event.at));
          }
        case BossSlammed():
          _bursts.add(Burst.slam(event.at, event.radius));
        case BossEnraged():
          _bursts.add(Burst.slam(event.at, 60));
        case RunEnded():
          _endeGemeldet = true;
      }
    }

    for (final popup in _popups) {
      popup.update(dt);
    }
    _popups.removeWhere((p) => !p.isAlive);

    for (final swing in _swings) {
      swing.update(dt);
    }
    _swings.removeWhere((s) => !s.isAlive);

    for (final burst in _bursts) {
      burst.update(dt);
    }
    _bursts.removeWhere((b) => !b.isAlive);

    _updateFiguren(dt);
    for (final leiche in _leichen) {
      leiche.age += dt;
    }
    _leichen.removeWhere((l) => !l.isAlive);

    _flashes.removeWhere((_, rest) => rest - dt <= 0);
    for (final id in _flashes.keys.toList()) {
      _flashes[id] = _flashes[id]! - dt;
    }

    frame.value++;
    if (_endeGemeldet) {
      _endeGemeldet = false;
      onRunEnded?.call();
    }
  }

  @override
  void render(Canvas canvas) {
    final held = sim.heroView;
    final kamera = _cameraOffset(held.position);

    canvas.save();
    canvas.translate(kamera.x, kamera.y);
    if (_beben > 0) {
      // Abklingend, und aus der Zeit statt aus dem Zufall — derselbe
      // Lauf bebt jedes Mal gleich.
      final staerke = _bebenStaerke * _beben / _bebenDauer;
      canvas.translate(
        math.sin(_beben * 90) * staerke,
        math.cos(_beben * 70) * staerke,
      );
    }

    _drawFloor(canvas, kamera);
    _drawZones(canvas);
    _drawOrbs(canvas);
    final bilder = _bilder;
    if (bilder == null) {
      _drawEntities(canvas);
    } else {
      _drawCorpses(canvas, bilder);
      _drawFigures(canvas, bilder);
    }
    _drawStatus(canvas);
    _drawProjectiles(canvas);
    _drawWard(canvas, held);
    _drawTelegraphs(canvas);
    _drawAim(canvas);
    // Mit Bildern zeigt der Schlag sich selbst; der Ring war der Ersatz.
    if (bilder == null) _drawSwings(canvas);
    _drawBursts(canvas);
    _drawPopups(canvas);

    canvas.restore();
  }

  // --- Kamera ---

  /// Der Held in der Mitte, aber nie über den Rand der Halle hinaus.
  ///
  /// Ohne das Festhalten am Rand sieht man in jedem Raum am Rand die
  /// Hälfte des Bildes schwarz, und die Halle wirkt kleiner, als sie ist.
  Vec2 _cameraOffset(Vec2 hero) {
    final breite = sim.level.worldWidth;
    final hoehe = sim.level.worldHeight;

    var x = size.x / 2 - hero.x;
    var y = size.y / 2 - hero.y;

    if (breite > size.x) {
      x = x.clamp(size.x - breite, 0);
    } else {
      x = (size.x - breite) / 2;
    }
    if (hoehe > size.y) {
      y = y.clamp(size.y - hoehe, 0);
    } else {
      y = (size.y - hoehe) / 2;
    }
    return Vec2(x, y);
  }

  // --- Boden und Wände ---

  static final Paint _bodenHell = Paint()..color = Palette.backgroundRaised;
  static final Paint _bodenDunkel = Paint()..color = Palette.background;
  static final Paint _wand = Paint()..color = Palette.surfaceSunken;
  static final Paint _wandOben = Paint()..color = Palette.surfaceRaised;
  static final Paint _gitter = Paint()
    ..color = Palette.textOnDarkDim
    ..strokeWidth = 3;

  void _drawFloor(Canvas canvas, Vec2 kamera) {
    const feld = ActionBalance.tileSize;

    // Nur zeichnen, was auch zu sehen ist. Bei 46 x 34 Feldern spart das
    // wenig — bei einer grösseren Halle ist es der Unterschied.
    final vonX = ((-kamera.x) / feld).floor() - 1;
    final bisX = ((-kamera.x + size.x) / feld).ceil() + 1;
    final vonY = ((-kamera.y) / feld).floor() - 1;
    final bisY = ((-kamera.y + size.y) / feld).ceil() + 1;

    for (var y = vonY; y <= bisY; y++) {
      for (var x = vonX; x <= bisX; x++) {
        if (x < 0 || y < 0 || x >= sim.level.width || y >= sim.level.height) {
          continue;
        }
        final rect = Rect.fromLTWH(x * feld, y * feld, feld, feld);

        if (sim.level.gatesClosed && sim.level.isGateAt(x, y)) {
          _drawGate(canvas, rect);
        } else if (sim.level.isWallAt(x, y)) {
          canvas.drawRect(rect, _wand);
          // Ein heller Streifen oben macht aus dem Quadrat einen Klotz.
          canvas.drawRect(
            Rect.fromLTWH(x * feld, y * feld, feld, feld * 0.22),
            _wandOben,
          );
        } else {
          // Schachbrett, damit Bewegung sichtbar ist. Auf einer
          // einfarbigen Fläche merkt man nicht, dass man läuft.
          final hell = (x + y).isEven;
          canvas.drawRect(rect, hell ? _bodenHell : _bodenDunkel);
        }
      }
    }
  }

  /// Ein geschlossenes Tor: Gitterstäbe auf dunklem Grund. Es soll nach
  /// Absicht aussehen, nicht nach einem Stück Fels, das plötzlich da ist.
  void _drawGate(Canvas canvas, Rect rect) {
    canvas.drawRect(rect, _bodenDunkel);
    const staebe = 4;
    for (var i = 0; i < staebe; i++) {
      final x = rect.left + rect.width * (i + 0.5) / staebe;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), _gitter);
    }
    final mitte = rect.top + rect.height / 2;
    canvas.drawLine(
      Offset(rect.left, mitte),
      Offset(rect.right, mitte),
      _gitter,
    );
  }

  // --- Figuren mit Bildern ---

  void _updateFiguren(double dt) {
    final lebend = <int>{};
    for (final view in sim.views) {
      lebend.add(view.id);
      _figuren
          .putIfAbsent(
            view.id,
            () => FigureState(
              view.position,
              figure: GrubeFiguren.forKind(view.kind),
            ),
          )
          .update(view, dt);
    }
    _figuren.removeWhere((id, _) => !lebend.contains(id));
  }

  /// Wo die Füsse stehen: an der Unterkante des Kreises, auf dem Schatten.
  static Offset _fussVon(Vec2 position, double radius) {
    return Offset(position.x, position.y + radius * 0.8);
  }

  void _drawFigures(Canvas canvas, GrubeBilder bilder) {
    final schatten = Paint()..color = Colors.black.withValues(alpha: 0.35);

    // Von oben nach unten zeichnen, damit vorn steht, wer weiter unten
    // steht — sonst läuft ein Ork über den Kopf des Helden.
    final views = sim.views
      ..sort((a, b) => a.position.y.compareTo(b.position.y));

    for (final view in views) {
      final zustand = _figuren[view.id];
      if (zustand == null) continue;
      final figur = GrubeFiguren.forKind(view.kind);
      final fuss = _fussVon(view.position, view.radius);

      canvas.drawOval(
        Rect.fromCenter(
          center: fuss,
          width: view.radius * 1.8,
          height: view.radius * 0.7,
        ),
        schatten,
      );

      final blitz = _flashes[view.id] ?? 0;
      bilder.draw(
        canvas,
        figure: figur,
        pose: zustand.pose,
        time: zustand.poseTime,
        foot: fuss,
        faceLeft: zustand.facesLeft,
        loop: !zustand.pose.playsOnce,
        flash: blitz > 0 ? (blitz / Burst.flashTime) * 0.8 : 0,
      );

      if (view.faction == Faction.gegner && view.hpRatio < 1) {
        _drawHpBarAt(canvas, view, fuss.dy - figur.visibleHeight - 6);
      }
    }
  }

  void _drawCorpses(Canvas canvas, GrubeBilder bilder) {
    for (final leiche in _leichen) {
      final figur = leiche.figure;
      final kippt = figur.has(Pose.death);
      bilder.draw(
        canvas,
        figure: figur,
        pose: kippt ? Pose.death : Pose.idle,
        time: leiche.age,
        foot: leiche.foot,
        faceLeft: leiche.facesLeft,
        loop: !kippt,
        opacity: leiche.opacity,
        // Wer keinen Sterbe-Streifen hat, schrumpft stattdessen weg.
        sizeFactor: kippt ? 1 : 1 - leiche.progress * 0.6,
      );
    }
  }

  void _drawHpBarAt(Canvas canvas, EntityView view, double oben) {
    final breite = view.radius * 2.2;
    final links = view.position.x - breite / 2;

    canvas.drawRect(
      Rect.fromLTWH(links, oben, breite, 3),
      Paint()..color = Palette.trackOnDark,
    );
    canvas.drawRect(
      Rect.fromLTWH(links, oben, breite * view.hpRatio, 3),
      Paint()..color = Palette.successOnDark,
    );
  }

  // --- Figuren als Würfel, solange keine Bilder da sind ---

  void _drawEntities(Canvas canvas) {
    final schatten = Paint()..color = Colors.black.withValues(alpha: 0.35);

    for (final view in sim.views) {
      final seite = view.radius * 2;
      final rect = Rect.fromCenter(
        center: Offset(view.position.x, view.position.y),
        width: seite,
        height: seite,
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(view.position.x, view.position.y + view.radius * 0.8),
          width: seite * 0.9,
          height: seite * 0.35,
        ),
        schatten,
      );

      canvas.drawRect(rect, Paint()..color = _colorFor(view));

      // Ein Treffer blitzt weiss auf. Ohne das ist ein Schlag nur eine
      // Zahl, die irgendwo erscheint — man sieht nicht, wen es traf.
      final flash = _flashes[view.id];
      if (flash != null && flash > 0) {
        canvas.drawRect(
          rect,
          Paint()
            ..color = Colors.white.withValues(
              alpha: (flash / Burst.flashTime).clamp(0.0, 1.0) * 0.8,
            ),
        );
      }

      canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Blickrichtung als heller Balken an der Kante.
      if (!view.facing.isZero) {
        final richtung = view.facing.normalized;
        canvas.drawCircle(
          Offset(
            view.position.x + richtung.x * view.radius * 0.6,
            view.position.y + richtung.y * view.radius * 0.6,
          ),
          3,
          Paint()..color = Colors.white.withValues(alpha: 0.75),
        );
      }

      if (view.faction == Faction.gegner && view.hpRatio < 1) {
        _drawHpBar(canvas, view);
      }
    }
  }

  Color _colorFor(EntityView view) {
    return switch (view.kind) {
      EnemyKind.keiner => Palette.goldOnDark,
      EnemyKind.fussvolk => Palette.enemyOnDark,
      // Der Fernkämpfer hebt sich ab, weil er anders behandelt werden
      // muss: Auf ihn zuzulaufen ist die Entscheidung, die er erzwingt.
      EnemyKind.schuetze => Palette.accentOnDark,
      EnemyKind.endgegner => Palette.enemy,
      EnemyKind.flink => Palette.enemyOnDark,
      EnemyKind.brocken => Palette.enemy,
    };
  }

  // --- Geschosse, Kugeln, Explosionen ---

  /// Was an einem Gegner hängt: blau verlangsamt, orange unter
  /// Dauerschaden.
  ///
  /// Ohne die Marke sähe man nicht, ob Frost und Gift noch wirken — und
  /// damit nicht, wann man sie erneuern muss.
  void _drawStatus(Canvas canvas) {
    for (final view in sim.views) {
      if (view.faction != Faction.gegner) continue;
      final mitte = Offset(view.position.x, view.position.y);
      if (view.isSlowed) {
        canvas.drawCircle(
          mitte,
          view.radius + 4,
          Paint()
            ..color = Palette.manaOnDark.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      if (view.isBurning) {
        canvas.drawCircle(
          Offset(mitte.dx, mitte.dy - view.radius - 6),
          3,
          Paint()..color = Palette.accentOnDark,
        );
      }
    }
  }

  /// Der Ring der Steinhaut, solange sie hält.
  ///
  /// Ohne ihn wüsste man nicht, ob die Fähigkeit noch wirkt — die
  /// Schadenszahlen werden nur kleiner, und das sieht niemand im Gewühl.
  /// Was der Wächter ankündigt: ein Ring oder eine Linie, rot, die sich
  /// füllt, bis es trifft.
  ///
  /// **Deutlich, nicht hübsch.** Die ganze Fairness der Angriffe hängt
  /// daran, dass man sie sieht — ein dezenter Ring im Gewühl wäre so gut
  /// wie keiner.
  /// Die liegenden Flächen: gefüllt in ihrer Farbe, mit Rand, und zum
  /// Ende hin blasser.
  void _drawZones(Canvas canvas) {
    for (final zone in sim.zones) {
      final farbe = tintColor(zone.tint);
      final mitte = Offset(zone.center.x, zone.center.y);
      final aus = zone.remaining.clamp(0.0, 1.0);
      // Die letzte halbe Sekunde blendet aus, sonst verschwindet sie
      // mitten im Laufen.
      final deckkraft = aus < 0.15 ? aus / 0.15 : 1.0;
      canvas.drawCircle(
        mitte,
        zone.radius,
        Paint()..color = farbe.withValues(alpha: 0.22 * deckkraft),
      );
      canvas.drawCircle(
        mitte,
        zone.radius,
        Paint()
          ..color = farbe.withValues(alpha: 0.7 * deckkraft)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  /// Die Vorschau beim Halten — genau das, was beim Loslassen geschieht
  /// (`ActionWorld.aimPreview`).
  void _drawAim(Canvas canvas) {
    final id = _zielId;
    if (id == null) return;
    final vorschau = sim.aimPreview(id, _zielPunkt);
    if (vorschau == null) return;

    final farbe = tintColor(vorschau.tint);
    final flaeche = Paint()..color = farbe.withValues(alpha: 0.28);
    final kante = Paint()
      ..color = farbe.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (vorschau) {
      case AimLine(:final from, :final to, :final width):
        canvas.drawLine(
          Offset(from.x, from.y),
          Offset(to.x, to.y),
          Paint()
            ..color = farbe.withValues(alpha: 0.35)
            ..strokeWidth = width + 8
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(Offset(to.x, to.y), width + 2, kante);
      case AimCone(
        :final origin,
        :final direction,
        :final range,
        :final halfAngle,
      ):
        final mitte = Offset(origin.x, origin.y);
        final winkel = math.atan2(direction.y, direction.x);
        final bogen = Rect.fromCircle(center: mitte, radius: range);
        canvas.drawArc(bogen, winkel - halfAngle, halfAngle * 2, true, flaeche);
        canvas.drawArc(bogen, winkel - halfAngle, halfAngle * 2, true, kante);
      case AimCircle(
        :final center,
        :final radius,
        :final castFrom,
        :final castRange,
      ):
        if (castRange > 0) {
          // Wie weit er abgesetzt werden darf — ein blasser Ring.
          canvas.drawCircle(
            Offset(castFrom.x, castFrom.y),
            castRange,
            Paint()
              ..color = farbe.withValues(alpha: 0.25)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
        final mitte = Offset(center.x, center.y);
        canvas.drawCircle(mitte, radius, flaeche);
        canvas.drawCircle(mitte, radius, kante);
    }
  }

  void _drawTelegraphs(Canvas canvas) {
    for (final zone in sim.telegraphs) {
      final mitte = Offset(zone.origin.x, zone.origin.y);
      final fuellung = Paint()
        ..color = Palette.enemy.withValues(alpha: 0.12 + 0.28 * zone.progress);
      final kante = Paint()
        ..color = Palette.enemyOnDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      if (zone.isRing) {
        canvas.drawCircle(mitte, zone.radius, fuellung);
        canvas.drawCircle(mitte, zone.radius, kante);
        // Der innere Kreis wächst bis zum Rand — dann trifft es.
        canvas.drawCircle(
          mitte,
          zone.radius * zone.progress,
          Paint()
            ..color = Palette.enemyOnDark.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        continue;
      }

      final ende = Offset(
        zone.origin.x + zone.direction.x * zone.length,
        zone.origin.y + zone.direction.y * zone.length,
      );
      canvas.drawLine(
        mitte,
        ende,
        Paint()
          ..color = Palette.enemy.withValues(alpha: 0.15 + 0.3 * zone.progress)
          ..strokeWidth = zone.radius * 2
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        mitte,
        Offset.lerp(mitte, ende, zone.progress) ?? mitte,
        Paint()
          ..color = Palette.enemyOnDark.withValues(alpha: 0.6)
          ..strokeWidth = 3,
      );
    }
  }

  void _drawWard(Canvas canvas, EntityView held) {
    if (!sim.isWarded) return;
    canvas.drawCircle(
      Offset(held.position.x, held.position.y),
      held.radius + 7,
      Paint()
        ..color = Palette.goldOnDark.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _drawProjectiles(Canvas canvas) {
    for (final shot in sim.projectiles) {
      // Die eigenen Funken golden, die fremden Pfeile rot: Wer ausweichen
      // will, muss auf einen Blick sehen, was ihm gilt.
      final farbe = shot.faction == Faction.held
          ? Palette.goldOnDark
          : Palette.enemyOnDark;
      final mitte = Offset(shot.position.x, shot.position.y);
      final schweif = Offset(
        shot.position.x - shot.direction.x * 9,
        shot.position.y - shot.direction.y * 9,
      );

      canvas.drawLine(
        schweif,
        mitte,
        Paint()
          ..color = farbe.withValues(alpha: 0.5)
          ..strokeWidth = 3,
      );
      canvas.drawCircle(mitte, shot.radius, Paint()..color = farbe);
    }
  }

  void _drawOrbs(Canvas canvas) {
    for (final orb in sim.orbs) {
      // Eine blinkende Kugel ist gleich weg. Ohne die Vorwarnung liest
      // sich ihr Verschwinden als Fehler.
      final sichtbar = !orb.fading || (sim.elapsed * 6).floor().isEven;
      if (!sichtbar) continue;

      final mitte = Offset(orb.position.x, orb.position.y);
      canvas.drawCircle(
        mitte,
        orb.radius + 3,
        Paint()..color = Palette.successOnDark.withValues(alpha: 0.25),
      );
      canvas.drawCircle(
        mitte,
        orb.radius,
        Paint()..color = Palette.successOnDark,
      );
    }
  }

  void _drawBursts(Canvas canvas) {
    for (final burst in _bursts) {
      canvas.drawCircle(
        Offset(burst.at.x, burst.at.y),
        burst.radius,
        Paint()
          ..color = burst.color.withValues(alpha: burst.opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = burst.strokeWidth,
      );
    }
  }

  void _drawHpBar(Canvas canvas, EntityView view) {
    final breite = view.radius * 2.2;
    final links = view.position.x - breite / 2;
    final oben = view.position.y - view.radius - 8;

    canvas.drawRect(
      Rect.fromLTWH(links, oben, breite, 3),
      Paint()..color = Palette.trackOnDark,
    );
    canvas.drawRect(
      Rect.fromLTWH(links, oben, breite * view.hpRatio, 3),
      Paint()..color = Palette.successOnDark,
    );
  }

  // --- Schläge und Zahlen ---

  void _drawSwings(Canvas canvas) {
    for (final swing in _swings) {
      final anteil = 1 - swing.progress;
      final farbe = swing.isHero ? Palette.goldOnDark : Palette.enemyOnDark;
      final mitte = Offset(
        swing.origin.x + swing.direction.x * 18,
        swing.origin.y + swing.direction.y * 18,
      );

      canvas.drawCircle(
        mitte,
        6 + 10 * swing.progress,
        Paint()
          ..color = farbe.withValues(alpha: 0.6 * anteil)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  void _drawPopups(Canvas canvas) {
    for (final popup in _popups) {
      final painter = TextPainter(
        text: TextSpan(
          text: popup.text,
          style: TextStyle(
            fontSize: 13 * popup.scale,
            fontWeight: FontWeight.bold,
            color: popup.color.withValues(alpha: popup.opacity),
            shadows: const <ui.Shadow>[
              ui.Shadow(color: Colors.black, blurRadius: 3),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(
          popup.position.x - painter.width / 2,
          popup.position.y - painter.height,
        ),
      );
    }
  }
}
