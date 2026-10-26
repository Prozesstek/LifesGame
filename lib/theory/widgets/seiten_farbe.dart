import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../skills/gebiet_farbe.dart';
import '../../ui/palette.dart';

/// **Die Farbe der Seite**: die ihres Gebiets (26.10.2026). Betonte
/// Wörter, der Merksatz, die Striche beim Lesen und der Balken bei den
/// Fragen tragen sie.
///
/// Gereicht wird sie von oben, nicht als Feld: Sie geht von der Seite
/// durch das Buch und jedes Blatt bis in den einzelnen Abschnitt.
///
/// **Ob eine Antwort sitzt, bleibt grün und rot** — das ist ein Urteil,
/// keine Farbe des Gebiets.
class SeitenFarbe extends InheritedWidget {
  const SeitenFarbe({required this.gebiet, required super.child, super.key});

  /// Null für eine Seite, die in keinem Knoten steht — dann der Akzent.
  final SkillArea? gebiet;

  /// Für Schrift und Flächen auf dem Papier.
  static Color of(BuildContext context) => switch (_gebiet(context)) {
    final SkillArea gebiet => GebietFarbe.pergament(gebiet),
    null => Palette.accent,
  };

  /// Der helle Ton daneben — der Glanz auf einem Balken.
  static Color hellOf(BuildContext context) => switch (_gebiet(context)) {
    final SkillArea gebiet => GebietFarbe.leder(gebiet),
    null => Palette.accentOnDark,
  };

  static SkillArea? _gebiet(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SeitenFarbe>()?.gebiet;

  @override
  bool updateShouldNotify(SeitenFarbe oldWidget) => oldWidget.gebiet != gebiet;
}
