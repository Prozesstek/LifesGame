import 'dart:math';

import 'package:combat/combat.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Eine Zahl, die über einem Kämpfer aufsteigt und verblasst.
///
/// **Reine Darstellung.** Was die Zahl bedeutet, hat die Engine bereits
/// entschieden; hier wird sie nur gezeigt (ADR-0002). Es wird nichts
/// gerechnet, nichts zusammengezählt und nichts abgeleitet.
///
/// Sie hängt bewusst am Spielfeld und nicht am Kämpfer: Wer getroffen
/// wird, zuckt zurück — die Zahl soll dort stehen bleiben, wo der Treffer
/// saß, statt mitzuwandern.
class FloatingText extends PositionComponent {
  FloatingText({
    required this.text,
    required this.color,
    required Vector2 at,
    this.fontSize = 19,
    this.sparkle = false,
  }) : super(position: at, priority: 100);

  final String text;
  final Color color;
  final double fontSize;

  /// Kleine Funken um die Zahl. Trägt das Lavafeld.
  final bool sparkle;

  /// Wie lange sie zu sehen ist.
  static const double lifetime = 0.95;

  /// Wie weit sie dabei steigt.
  static const double rise = 30;

  double _age = 0;
  TextPainter? _fill;
  TextPainter? _stroke;

  /// Anteil der Lebenszeit, ab dem sie verblasst.
  static const double _fadeFrom = 0.55;

  double get _progress => (_age / lifetime).clamp(0.0, 1.0);

  double get _opacity {
    if (_progress <= _fadeFrom) return 1;
    return 1 - (_progress - _fadeFrom) / (1 - _fadeFrom);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= lifetime) removeFromParent();
  }

  /// Baut die beiden Maler einmal auf und hält sie fest.
  ///
  /// Zwei, weil eine helle Zahl auf einem hellen Kämpfer sonst verschwindet:
  /// erst ein dunkler Rand, dann die Füllung darüber.
  void _prepare() {
    if (_fill != null && _stroke != null) return;

    TextPainter build(Paint paint) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            foreground: paint,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return painter;
    }

    _stroke = build(
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF0B0E15),
    );
    _fill = build(Paint()..color = color);
  }

  @override
  void render(Canvas canvas) {
    _prepare();
    final fill = _fill;
    final stroke = _stroke;
    if (fill == null || stroke == null) return;

    // Am Anfang ein kurzer Stups nach oben, danach ruhiger — ein Treffer
    // soll sich wie ein Aufprall anfühlen, nicht wie ein Fahrstuhl.
    final eased = 1 - pow(1 - _progress, 2.2);
    final dy = -rise * eased;
    final origin = Offset(-fill.width / 2, dy);

    canvas.saveLayer(
      Rect.fromLTWH(
        origin.dx - 24,
        origin.dy - 12,
        fill.width + 48,
        fill.height + 24,
      ),
      Paint()..color = Color.fromARGB((255 * _opacity).round(), 0, 0, 0),
    );

    if (sparkle) _drawSparkles(canvas, origin, fill.size);
    stroke.paint(canvas, origin);
    fill.paint(canvas, origin);

    canvas.restore();
  }

  /// Vier kleine Funken links und rechts der Zahl.
  void _drawSparkles(Canvas canvas, Offset origin, Size textSize) {
    final paint = Paint()..color = color;
    final middle = origin.dy + textSize.height / 2;

    void star(double cx, double cy, double r) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final angle = i * pi / 2;
        path
          ..moveTo(cx, cy)
          ..lineTo(cx + cos(angle) * r, cy + sin(angle) * r)
          ..lineTo(
            cx + cos(angle + pi / 4) * r * 0.28,
            cy + sin(angle + pi / 4) * r * 0.28,
          )
          ..close();
      }
      canvas.drawPath(path, paint);
    }

    final left = origin.dx - 8;
    final right = origin.dx + textSize.width + 8;

    // Sie pulsieren leicht, damit sie nicht wie Staub aussehen.
    final puls = 0.7 + 0.3 * sin(_progress * pi * 3);
    star(left, middle - 4, 5 * puls);
    star(right, middle - 4, 5 * puls);
    star(left + 3, middle + 8, 3 * puls);
    star(right - 3, middle + 8, 3 * puls);
  }
}

/// Welche Farbe der Schaden aus einer Quelle bekommt.
///
/// **Nur Darstellung.** Die Ids kommen aus `package:combat`; was sie
/// bewirken, steht dort. Hier steht ausschliesslich, wie sie aussehen.
abstract final class DamageColors {
  /// Ein gewöhnlicher Treffer.
  static const Color hit = Color(0xFFFF5A5A);

  /// Heilung.
  static const Color heal = Color(0xFF5BD98A);

  /// Ein Schlag, den der Schild ganz geschluckt hat.
  static const Color blocked = Color(0xFFAEB8CC);

  /// Schaden über Zeit — je Quelle eine eigene Farbe, damit am
  /// Rundenende ablesbar ist, *woher* der Verlust kommt.
  static const Map<String, Color> _overTime = <String, Color>{
    'poison': Color(0xFFC42BFF), // Gift: kräftiges Lila
    'poison_bog': Color(0xFF9500E8), // Giftboden: tieferes, sattes Lila
    'burn': Color(0xFFFF9A4D), // Brand: orange
    'frost': Color(0xFF7FD4F5), // Eisfeld: hellblau
    'sandstorm': Color(0xFFE8C55A), // Sandsturm: sandgelb
    'lava': Color(0xFFFF4D3D), // Lavafeld: rot, mit Funken
  };

  /// Das Lavafeld bekommt Funken um die Zahl.
  static const Set<String> _sparkling = <String>{'lava'};

  /// Farbe für eine Schadensquelle. Unbekanntes bleibt beim Treffer-Rot —
  /// ein neuer Effekt soll sichtbar sein, auch wenn niemand daran gedacht
  /// hat, ihm eine Farbe zu geben.
  static Color forSource(String id) => _overTime[id] ?? hit;

  static bool sparklesFor(String id) => _sparkling.contains(id);
}

/// Was über einem Kämpfer erscheinen soll.
class DamageReadout {
  const DamageReadout({
    required this.target,
    required this.text,
    required this.color,
    this.fontSize = 19,
    this.sparkle = false,
  });

  final Side target;
  final String text;
  final Color color;
  final double fontSize;
  final bool sparkle;
}

/// Übersetzt ein Kampf-Event in die Zahl über dem Kopf. `null` heisst:
/// nichts anzeigen.
///
/// **Eine reine Funktion, und zwar mit Absicht.** Sie steckte zuerst im
/// Flame-Code, verteilt über die Zweige der Ereignisschleife — und damit
/// an einem Ort, den kein Test erreicht, ohne ein Spiel zu starten.
/// Dieselbe Trennung wie bei [MoveAnimation]: Der Kampf entscheidet, was
/// passiert; hier steht, wie es aussieht; und das Abspielen macht nur noch
/// das Abspielen.
///
/// Drei Entscheidungen stecken darin:
///
/// 1. **„Geblockt" nur bei einem vollständigen Block.** Kam etwas durch,
///    steht dort gleich die Zahl, die durchkam — beides wäre zweimal
///    dieselbe Auskunft.
/// 2. **Ein perfekter Treffer steht grösser da.** Dieselbe Aussage wie das
///    stärkere Zucken, nur lesbar.
/// 3. **Schaden über Zeit trägt die Farbe seiner Quelle.** Am Rundenende
///    fallen mehrere Balken gleichzeitig; ohne die Farbe wäre nicht
///    ablesbar, woher der Verlust kommt.
DamageReadout? damageReadoutFor(CombatEvent event) {
  return switch (event) {
    DamageDealt(:final target, :final amount, :final timedHitFactor) =>
      DamageReadout(
        target: target,
        text: '$amount',
        color: DamageColors.hit,
        fontSize: timedHitFactor > 1 ? 24 : 19,
      ),

    DamageAbsorbed(:final target, :final complete) when complete =>
      DamageReadout(
        target: target,
        text: 'Geblockt',
        color: DamageColors.blocked,
        fontSize: 14,
      ),

    Healed(:final target, :final amount) when amount > 0 => DamageReadout(
      target: target,
      text: '+$amount',
      color: DamageColors.heal,
    ),

    StatusTicked(:final target, :final statusId, :final damage)
        when damage > 0 =>
      DamageReadout(
        target: target,
        text: '$damage',
        color: DamageColors.forSource(statusId),
        fontSize: 16,
        sparkle: DamageColors.sparklesFor(statusId),
      ),

    _ => null,
  };
}
