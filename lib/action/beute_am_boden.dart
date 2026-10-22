import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gear/gear.dart';

import '../gear/gear_icon.dart';
import '../gear/widgets/rarity_badge.dart';
import '../ui/palette.dart';
import '../ui/pixel_art.dart';
import 'beute_regen.dart';
import 'pit_beute.dart';

/// Wie Beute am Boden der Grube aussieht (ADR-0083) — **nur
/// Darstellung**.
///
/// **Man sieht die Gruppe, nicht das Stück**: der Umriss eines Schwerts,
/// eines Stiefels, eines Rings (`GearIcons.gruppeFor`) in der Farbe der
/// Seltenheit, in einem Rahmen derselben Farbe. Welcher Schuh es ist,
/// zeigt erst das Ende des Laufs. Bis die Umrisse geladen sind, steht ein
/// Zeichen da ([laden]).
///
/// Episches liegt in einem violetten Schein, Legendäres unter einer
/// goldenen Lichtsäule, die man auch vom Rand des Bildes aus sieht.
abstract final class BeuteAmBoden {
  /// Wie groß der Umriss steht: **die Hälfte der Zeichnung**
  /// (`PixelArt.artSize` 64 → 32), ein Feld der Grube, so groß wie der
  /// Held (AktivesBrett, 21.10. — vorher 14 Punkte, im Lauf kaum zu
  /// sehen). Halb, damit je zwei mal zwei Bildpunkte zu einem werden und
  /// nichts schief verwischt.
  static const double umrissKante = PixelArt.artSize / 2;

  /// Wie groß der Rahmen darum ist, von der Mitte zum Rand: zwei Punkte
  /// Luft, sonst stößt ein Stiefel an die Kante.
  static const double halbeKante = umrissKante / 2 + 2;

  /// Wie hoch die Lichtsäule über Legendärem steigt — gut über den
  /// halben Bildschirm, damit man sie aus dem Nachbarraum sieht (vorher
  /// 140).
  static const double saeulenHoehe = 420;

  static final Map<(GearSlot, Color), TextPainter> _zeichen =
      <(GearSlot, Color), TextPainter>{};

  static final Map<GearSlot, ui.Image> _umrisse = <GearSlot, ui.Image>{};
  static Future<void>? _laden;

  /// Lädt die Umrisse einmal je App-Lauf. **Nicht abwarten**: Bis sie da
  /// sind, zeichnet [zeichne] das Zeichen des Platzes.
  static Future<void> laden() => _laden ??= _ladeAlle();

  static Future<void> _ladeAlle() async {
    for (final slot in GearSlot.values) {
      final daten = await rootBundle.load(GearIcons.gruppeFor(slot));
      final codec = await ui.instantiateImageCodec(daten.buffer.asUint8List());
      _umrisse[slot] = (await codec.getNextFrame()).image;
    }
  }

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

  /// Zeichnet, was eine Niederlage gerade nimmt (ADR-0084): dieselbe
  /// Kachel wie am Boden, im Flug vom Helden weg, kleiner und blasser.
  static void zeichneGehende(
    Canvas canvas,
    List<GehenderFund> gehende,
    PitBeute beute,
  ) {
    for (final fund in gehende) {
      final sichtbar = fund.sichtbar;
      final item = beute.fund(fund.nth)?.item;
      if (sichtbar <= 0 || item == null) continue;
      final mitte = Offset(fund.x, fund.y);
      canvas
        ..saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, sichtbar))
        ..translate(mitte.dx, mitte.dy)
        ..scale(fund.groesse)
        ..translate(-mitte.dx, -mitte.dy);
      _kachel(canvas, mitte, item);
      canvas.restore();
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
    final umriss = _umrisse[item.slot];
    if (umriss != null) {
      canvas.drawImageRect(
        umriss,
        Rect.fromLTWH(0, 0, umriss.width.toDouble(), umriss.height.toDouble()),
        Rect.fromCenter(center: mitte, width: umrissKante, height: umrissKante),
        Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = ColorFilter.mode(rahmen, BlendMode.srcIn),
      );
      return;
    }
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

  /// Die goldene Lichtsäule über Legendärem: **hoch, hell und dünn**
  /// (AktivesBrett, 21.10.) — ein weißgoldener Kern, kaum breiter als
  /// ein Strich, in einem schmalen Schein, der erst weit oben ausläuft.
  static void _saeule(Canvas canvas, Offset mitte, double zeit) {
    final gold = RarityBadge.rahmenOf(GearRarity.legendary);
    final atem = 0.85 + 0.15 * math.sin(zeit * 3);
    // Von unten bis gut zur Hälfte voll, dann läuft es aus.
    void strahl(double halbeBreite, Color farbe, double unschaerfe) {
      final flaeche = Rect.fromLTRB(
        mitte.dx - halbeBreite,
        mitte.dy - saeulenHoehe,
        mitte.dx + halbeBreite,
        mitte.dy,
      );
      canvas.drawRect(
        flaeche,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: <Color>[farbe, farbe, farbe.withValues(alpha: 0)],
            stops: const <double>[0, 0.55, 1],
          ).createShader(flaeche)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, unschaerfe),
      );
    }

    strahl(8, gold.withValues(alpha: 0.35 * atem), 8);
    strahl(3.5, gold.withValues(alpha: 0.9 * atem), 2.5);
    strahl(1.2, Color.lerp(gold, Colors.white, 0.75)!, 0.8);
    canvas.drawCircle(
      mitte,
      halbeKante * 2.4,
      Paint()
        ..color = gold.withValues(alpha: atem * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }
}
