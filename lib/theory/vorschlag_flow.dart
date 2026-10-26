import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';
import 'package:theory/theory.dart';

import '../skills/gebiet_farbe.dart';
import 'lesson_screen.dart';
import 'theory_controller.dart';

/// **Was ein Tipp auf einen Vorschlag tut** — öffnen, falls nötig, dann
/// lesen. Eine Stelle für den Baum und die Feier eines Aufstiegs.
///
/// Der Punkt wird mit dem Tipp ausgegeben; der Preis steht vorher auf
/// dem Vorschlag. Reichen die Punkte nicht mehr — etwa, weil zwischen
/// Anzeigen und Tippen einer ausgegeben wurde —, geschieht nichts.
///
/// Gelesen wird in der Farbe von [bevorzugt], wenn die Seite dort steht,
/// sonst in der ihres Zuhauses (ADR-0090).
Future<void> lieseVorschlag(
  BuildContext context,
  WidgetRef ref,
  TheoryStep schritt, {
  SkillArea? bevorzugt,
}) async {
  if (schritt.needsOpening) {
    final offen = ref
        .read(theoryProgressProvider.notifier)
        .openNode(
          schritt.node.id,
          availablePoints: ref.read(availableTheoryPointsProvider),
        );
    if (!offen) return;
  }
  final gebiet = gebietVon(
    ref.read(theoryGraphProvider),
    schritt.node.id,
    bevorzugt: bevorzugt,
  );
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => LessonScreen(lesson: schritt.node.lesson, gebiet: gebiet),
    ),
  );
}
