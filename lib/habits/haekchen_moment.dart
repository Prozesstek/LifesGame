import 'package:habits/habits.dart';

import '../audio/sound_effects.dart';

/// **Was ein Häkchen gerade bedeutet** — das wievielte des Tages es ist,
/// ob es die Tageskette anzündet, ob der Tag damit geschafft ist. Daraus
/// folgen Ton, Stoss und Konfetti.
///
/// Reine Rechnung aus zwei Ständen des Trackers, vorher und nachher.
/// **Sie erzeugt keine Zahl** — Erfahrung, Gold und Ketten stehen im
/// Tracker; hier steht nur, wie laut die Darstellung darauf antwortet.
/// `habit_check_flow.dart` spielt es ab.
class HaekchenMoment {
  const HaekchenMoment({
    required this.nummer,
    required this.ersterDesTages,
    required this.tagGeschafft,
    required this.punkt,
  });

  factory HaekchenMoment.aus({
    required HabitTracker vorher,
    required HabitTracker nachher,
    required Day heute,
    required bool punkt,
  }) {
    return HaekchenMoment(
      nummer: nachher.completedOn(heute),
      ersterDesTages: !vorher.hasCheckOn(heute) && nachher.hasCheckOn(heute),
      tagGeschafft:
          !vorher.isDayComplete(heute) && nachher.isDayComplete(heute),
      punkt: punkt,
    );
  }

  /// Das wievielte Häkchen des Tages es ist, ab 1.
  final int nummer;

  /// Ob es das erste des Tages ist — dann trägt der Tag die Tageskette
  /// (ADR-0055), und die Flamme zündet.
  final bool ersterDesTages;

  /// Ob damit alles Fällige erledigt ist — „In Form“, die Truhe, das
  /// Konfetti.
  final bool tagGeschafft;

  /// Ob es einen ganzen Charakterpunkt gebracht hat.
  final bool punkt;

  /// **Der Ton**: eine Stufe höher als das Häkchen davor. Wer schnell
  /// hintereinander abhakt, hört eine Melodie, und das letzte Fällige
  /// löst sie auf.
  ///
  /// Ein Punkt hat den Vorrang: Er ist die Verbindung zum Kampf, und er
  /// fällt seltener als der Tag.
  SoundEffect get klang {
    if (punkt) return SoundEffect.statPunkt;
    if (tagGeschafft) return SoundEffect.tagGeschafft;
    const leiter = SoundEffect.tonleiter;
    return leiter[(nummer - 1).clamp(0, leiter.length - 1)];
  }
}
