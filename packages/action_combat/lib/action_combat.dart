/// Echtzeit-Kampf als **Prototyp** für Lifes Game.
///
/// Reines Dart: kein Flutter, kein Flame. Ein ganzer Lauf durch eine Halle
/// lässt sich damit ohne Bildschirm durchspielen — siehe
/// `example/headless_run.dart`. Das ist dieselbe Naht wie bei
/// `package:combat` (ADR-0002) und der Grund, warum dieses Package
/// überhaupt getrennt ist.
///
/// **Seit ADR-0039 ist es der Kampf des Spiels.** Die Grube ersetzt den
/// rundenbasierten Kampf aus `package:combat`; dieses Package kennt ihn
/// weiterhin nicht, damit er gelöscht werden kann, sobald nichts mehr an
/// ihm hängt.
library;

export 'src/ability.dart';
export 'src/balance.dart';
export 'src/bot.dart';
export 'src/entity.dart';
export 'src/events.dart';
export 'src/flow_field.dart';
export 'src/health_orb.dart';
export 'src/level.dart';
export 'src/level_builder.dart';
export 'src/level_catalog.dart';
export 'src/projectile.dart';
export 'src/room_catalog.dart';
export 'src/stage.dart';
export 'src/stats.dart';
export 'src/vec2.dart';
export 'src/world.dart';
