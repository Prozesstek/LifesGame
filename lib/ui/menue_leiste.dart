import 'package:flutter/material.dart';

import 'holz_teile.dart';
import 'palette.dart';

/// **Die Menüleiste jedes Bereichs** (19.11.2026, Frederik: „in jedem
/// Menü … Menüleiste designen, neue Schriftart“): Pergament wie bisher,
/// unten ein gemalter Holzbalken mit Messingnägeln, der Titel in
/// Cormorant Garamond — derselben Schrift wie die Überschriften im
/// Lernbuch.
///
/// Gilt über das Theme (`appBarTheme` in `main.dart`), damit kein
/// Bildschirm es wissen muss. **Das Pergament bleibt**: Was in einer
/// Leiste steht — Level, Gold, Knöpfe —, ist auf Pergament abgestimmt.
abstract final class MenueLeiste {
  /// Die Schrift der Titel.
  static const String schrift = 'CormorantGaramond';

  /// Wie der Titel einer Leiste steht.
  static const TextStyle titel = TextStyle(
    fontFamily: schrift,
    fontSize: 27,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: Palette.text,
  );

  /// Wie hoch der Balken unten ist.
  static const double balken = 10;
}

/// Der Rand einer Leiste: unten der Balken, gemalt wie die Planke
/// ([PlankenMaler], ADR-0099).
class MenueLeistenRand extends ShapeBorder {
  const MenueLeistenRand();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    const maler = PlankenMaler();
    canvas.save();
    canvas.translate(rect.left, rect.bottom - MenueLeiste.balken);
    maler.paint(canvas, Size(rect.width, MenueLeiste.balken));
    canvas.restore();
  }

  @override
  ShapeBorder scale(double t) => this;
}
