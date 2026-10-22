import 'package:flutter/material.dart';
import 'package:habits/habits.dart';
import 'package:theory/theory.dart';

import '../theory/widgets/node_icon.dart';

/// Welches Zeichen zu einem Gebiet gehört — **das Zeichen seiner Wurzel
/// im Baum** (ADR-0085).
///
/// Keine eigene Tabelle: Ein Gebiet ist eine Wurzel, und deren Zeichen
/// steht schon in `node_icon.dart`. Stünde es hier ein zweites Mal, sähe
/// Körper im Charakter irgendwann anders aus als im Baum.
IconData gebietZeichen(SkillArea area) {
  return iconForNode(theoryGraph.nodeById(area.name)?.iconId ?? '');
}
