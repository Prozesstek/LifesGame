import 'dart:math' as math;

import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../gear/gear_icon.dart';
import '../gear/widgets/rarity_badge.dart';
import '../ui/palette.dart';
import 'pit_beute.dart';

/// Wie Beute am Boden der Grube aussieht (ADR-0083) — **nur
/// Darstellung**.
///
/// **Man sieht die Gruppe, nicht das Stück**: das Zeichen des Platzes
/// (Waffe, Schuh, Ring …) in einem Rahmen in der Farbe der Seltenheit.
/// Welcher Schuh es ist, zeigt erst das Ende des Laufs.
///
/// Episches liegt in einem violetten Schein, Legendäres unter einer
/// goldenen Lichtsäule, die man auch vom Rand des Bildes aus sieht.
abstract final class BeuteAmBoden {
  /// Wie groß ein Fund gezeichnet wird, von der Mitte zum Rand.
  static const double halbeKante = 9;

  /// Wie hoch die Lichtsäule über Legendärem steigt.
  static const double saeulenHoehe = 140;

  static final Map<(GearSlot, Color), TextPainter> _zeichen =
      <(GearSlot, Color), TextPainter>{};

  /// Zeichnet jeden Fund, der am Boden liegt. [zeit] lässt die Säule
  /// atmen und den Fund leicht schweben — aus der Zeit des Laufs, damit
  /// beides mit dem Trefferstopp anhält.
  static void zeichne(
    Canvas canvas,
    List<ItemDropView> funde,
    PitBeute beute,
    double zeit,
  ) {
    for (final fund in funde) {
      final copy = beute.fund(fund.nth);
      final item = copy?.item;
      if (item == null) continue;
      final schweben = math.sin(zeit * 3 + fund.nth) * 1.5;
      final mitte = Offset(fund.position.x, fund.position.y + schweben);
      switch (item.rarity) {
        case GearRarity.legendary:
          _saeule(canvas, mitte, zeit);
        case GearRarity.epic:
          _schein(canvas, mitte, RarityBadge.rahmenOf(item.rarity), zeit);
        case GearRarity.common || GearRarity.uncommon || GearRarity.rare:
          break;
      }
      _kachel(canvas, mitte, item);
    }
  }

  static void _kachel(Canvas canvas, Offset mitte, GearItem item) {
    final rahmen = RarityBadge.rahmenOf(item.rarity);
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: mitte,
        width: halbeKante * 2,
        height: halbeKante * 2,
      ),
      const Radius.circular(4),
    );
    // Ein Schatten darunter, damit der Fund auf hellem Boden steht.
    canvas.drawRRect(
      rect.shift(const Offset(0, 2)),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawRRect(rect, Paint()..color = Palette.background);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = rahmen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final zeichen = _zeichen.putIfAbsent((item.slot, rahmen), () {
      final icon = GearIcons.fallbackFor(item.slot);
      return TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: halbeKante * 1.5,
            color: rahmen,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
    zeichen.paint(
      canvas,
      mitte - Offset(zeichen.width / 2, zeichen.height / 2),
    );
  }

  /// Ein weicher Schein in der Farbe der Seltenheit — Episch.
  static void _schein(Canvas canvas, Offset mitte, Color farbe, double zeit) {
    final atem = 0.25 + 0.1 * math.sin(zeit * 4);
    canvas.drawCircle(
      mitte,
      halbeKante * 2.2,
      Paint()
        ..color = farbe.withValues(alpha: atem)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  /// Die goldene Lichtsäule über Legendärem.
  static void _saeule(Canvas canvas, Offset mitte, double zeit) {
    final gold = RarityBadge.rahmenOf(GearRarity.legendary);
    final atem = 0.55 + 0.2 * math.sin(zeit * 3);
    final saeule = Rect.fromLTRB(
      mitte.dx - 7,
      mitte.dy - saeulenHoehe,
      mitte.dx + 7,
      mitte.dy,
    );
    canvas.drawRect(
      saeule,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: <Color>[
            gold.withValues(alpha: atem),
            gold.withValues(alpha: 0),
          ],
        ).createShader(saeule)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      mitte,
      halbeKante * 2.4,
      Paint()
        ..color = gold.withValues(alpha: atem * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }
}
