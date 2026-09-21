import 'dart:math' as math;

/// Ein Punkt oder eine Richtung in der Halle.
///
/// **Eigener Typ statt Flames `Vector2`.** Dieses Package kennt Flame
/// nicht und soll es nicht kennen (ADR-0002, ADR-0003) — sonst liesse sich
/// ein Lauf nicht mehr ohne Renderer durchspielen, und genau das ist der
/// Grund, warum die Kampflogik dieses Projekts seit jeher eigenständig
/// ist.
///
/// Unveränderlich: Ein Vektor ist ein Wert. Was sich bewegt, ist die
/// Figur, die ihn hält.
class Vec2 {
  const Vec2(this.x, this.y);

  static const Vec2 zero = Vec2(0, 0);

  final double x;
  final double y;

  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);

  Vec2 operator -(Vec2 other) => Vec2(x - other.x, y - other.y);

  Vec2 operator *(double factor) => Vec2(x * factor, y * factor);

  /// Um [radians] gedreht, gegen den Uhrzeigersinn.
  Vec2 rotated(double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    return Vec2(x * c - y * s, x * s + y * c);
  }

  double get length => math.sqrt(x * x + y * y);

  /// Länge ohne Wurzel — für Vergleiche, die nur wissen wollen, was näher
  /// ist. In einer Schleife über dreissig Gegner je Bild ist das der
  /// Unterschied, den man misst.
  double get lengthSquared => x * x + y * y;

  bool get isZero => x == 0 && y == 0;

  /// Derselbe Vektor mit Länge 1. Der Nullvektor bleibt der Nullvektor —
  /// eine Richtung aus „keine Eingabe" gibt es nicht.
  Vec2 get normalized {
    final len = length;
    if (len == 0) return zero;
    return Vec2(x / len, y / len);
  }

  /// Gekürzt auf höchstens [max] Länge.
  Vec2 clampLength(double max) {
    final len = length;
    if (len <= max || len == 0) return this;
    return Vec2(x / len * max, y / len * max);
  }

  double distanceTo(Vec2 other) => (this - other).length;

  double distanceSquaredTo(Vec2 other) => (this - other).lengthSquared;

  @override
  String toString() => '(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';

  @override
  bool operator ==(Object other) {
    return other is Vec2 && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}
