import 'package:flutter/material.dart';

/// Die Farben der App an einem Ort.
///
/// Steht ein Farbwert direkt im Widget-Code, gehört er hierher.
abstract final class Palette {
  static const Color background = Color(0xFF0E1119);
  static const Color surface = Color(0xFF141824);
  static const Color surfaceRaised = Color(0xFF1B2130);

  static const Color accent = Color(0xFF5B8DEF);
  static const Color enemy = Color(0xFFE05B5B);
  static const Color success = Color(0xFF4CAF7D);
  static const Color gold = Color(0xFFE0B65B);

  static const Color textDim = Color(0xFF9AA3B5);
  static const Color muted = Color(0xFF6B7285);
}
