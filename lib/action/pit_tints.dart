import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';

import '../ui/palette.dart';

/// Welche Farbe die Fläche einer Fähigkeit trägt — **eine Tabelle**, wie
/// `GrubeFiguren` für die Bilder. Die Farben selbst stehen in der Palette.
Color tintColor(PitTint tint) {
  return switch (tint) {
    PitTint.funke => Palette.tintFunke,
    PitTint.blitz => Palette.tintBlitz,
    PitTint.seele => Palette.tintSeele,
    PitTint.klinge => Palette.tintKlinge,
    PitTint.natur => Palette.tintNatur,
    PitTint.eis => Palette.tintEis,
    PitTint.sand => Palette.tintSand,
    PitTint.gift => Palette.tintGift,
    PitTint.zeit => Palette.tintZeit,
    PitTint.lava => Palette.tintLava,
    PitTint.stern => Palette.tintStern,
    PitTint.schutz => Palette.tintSchutz,
  };
}
