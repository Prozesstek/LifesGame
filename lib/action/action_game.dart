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
        case AttackSwung():
          _swings.add(
            SwingMark(
              origin: event.from,
              direction: event.direction,
              isHero: event.faction == Faction.held,
            ),
          );
        case EntityDied():
        case EnemyNoticed():
          break;
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
    _drawEntities(canvas);
    _drawSwings(canvas);
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
      EnemyKind.endgegner => Palette.enemy,
    };
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
