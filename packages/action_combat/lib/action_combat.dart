/// Echtzeit-Kampf als **Prototyp** für Lifes Game.
///
/// Reines Dart: kein Flutter, kein Flame. Ein ganzer Lauf durch eine Halle
/// lässt sich damit ohne Bildschirm durchspielen — siehe
/// `example/headless_run.dart`. Das ist dieselbe Naht wie bei
/// `package:combat` (ADR-0002) und der Grund, warum dieses Package
/// überhaupt getrennt ist.
///
/// **Es ersetzt nichts.** `package:combat` und der rundenbasierte
/// Kampfbildschirm sind unberührt; dieses Package hängt an keinem von
/// ihnen und sie nicht an ihm. Ein Rückbau ist ein `git revert`, kein
/// Aufräumen.
library;

export 'src/balance.dart';
export 'src/entity.dart';
export 'src/events.dart';
export 'src/flow_field.dart';
export 'src/level.dart';
export 'src/level_catalog.dart';
export 'src/stats.dart';
export 'src/vec2.dart';
export 'src/world.dart';
