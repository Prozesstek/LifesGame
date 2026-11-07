import 'package:flutter/foundation.dart';

import 'action_sprites.dart';
import 'beute_am_boden.dart';

/// Holt alle Bilder des Dungeons, **bevor** der Lauf beginnt.
///
/// Bis zum 07.11.2026 lief der Lauf sofort los und lud die Bilder
/// nebenher; im Browser standen so lange die Würfel des Prototyps da,
/// und Uhr und Gegner liefen schon. Jetzt wartet der Ladebildschirm
/// (`lib/ui/ladebildschirm.dart`) hierauf.
///
/// Aufgerufen über den Prefix des nachgeladenen Bildschirms
/// (`grube.grubeVorladen`), damit der Code mit ihm nachgeladen wird.
Future<void> grubeVorladen() async {
  await Future.wait(<Future<void>>[GrubeBilder.load(), BeuteAmBoden.laden()]);
}

/// Wie weit [grubeVorladen] ist, von 0 bis 1 — gezählt werden die
/// Figuren, die Umrisse der Beute sind nur sechs kleine Bilder.
ValueListenable<double> get grubeFortschritt => GrubeBilder.fortschritt;
