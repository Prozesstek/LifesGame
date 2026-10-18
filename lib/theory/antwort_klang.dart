import '../audio/sound_effects.dart';

/// **Wie eine Antwort auf einer Seite klingt** — reine Rechnung.
///
/// Richtig klettert die Tonleiter des Häkchens hinauf, eine Stufe je
/// richtiger Antwort **in Folge**; falsch klingt [SoundEffect.falsch], und
/// die Leiter beginnt von vorn. Wer drei von drei hat, hört drei Stufen
/// hinauf — die Melodie ist die Kombo, ohne dass eine Zahl dasteht.
///
/// Über die oberste Stufe hinaus bleibt es die oberste, wie beim Häkchen.
abstract final class AntwortKlang {
  /// [inFolge] zählt die richtigen Antworten in Folge **mit** dieser,
  /// ab 1. Bei einer falschen ist es egal.
  static SoundEffect fuer({required bool richtig, required int inFolge}) {
    if (!richtig) return SoundEffect.falsch;
    const leiter = SoundEffect.tonleiter;
    return leiter[inFolge.clamp(1, leiter.length) - 1];
  }
}
