import 'dart:ui' as ui;

import 'package:action_combat/action_combat.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../ui/palette.dart';
import 'damage_popup.dart';

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

  /// Nur für Tests: was gerade an Zahlen in der Luft steht.
  int get popupCount => _popups.length;

  @override
  Color backgroundColor() => Palette.background;

  @override
  void update(double dt) {
    sim.advance(dt, moveInput);

    for (final event in sim.drainEvents()) {
      switch (event) {
        case HitLanded():
          final popup = DamagePopup.forHit(event);
          if (popup != null) _popups.add(popup);
          _flashes[event.targetId] = Burst.flashTime;
        case AttackSwung():
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
        case AbilityUsed():
          if (event.ability == ActionAbility.rundumschlag) {
            _bursts.add(Burst.cleave(event.at));
          }
        case OrbDropped():
        case EnemyNoticed():
          break;
        case OrbCollected():
          if (event.healed > 0) {
            _popups.add(DamagePopup.forHeal(event));
          }
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

    _drawFloor(canvas, kamera);
    _drawOrbs(canvas);
    _drawEntities(canvas);
    _drawProjectiles(canvas);
    _drawSwings(canvas);
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

        if (sim.level.isWallAt(x, y)) {
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

  // --- Figuren ---

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
    };
  }

  // --- Geschosse, Kugeln, Explosionen ---

  void _drawProjectiles(Canvas canvas) {
    for (final shot in sim.projectiles) {
      final mitte = Offset(shot.position.x, shot.position.y);
      final schweif = Offset(
        shot.position.x - shot.direction.x * 9,
        shot.position.y - shot.direction.y * 9,
      );

      canvas.drawLine(
        schweif,
        mitte,
        Paint()
          ..color = Palette.enemyOnDark.withValues(alpha: 0.5)
          ..strokeWidth = 3,
      );
      canvas.drawCircle(
        mitte,
        shot.radius,
        Paint()..color = Palette.enemyOnDark,
      );
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
