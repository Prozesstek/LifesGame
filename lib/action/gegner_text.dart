import 'package:action_combat/action_combat.dart';

/// Wie die Gegnerarten heißen — für die Sammlung (Issue #138).
///
/// **Nur der Wortlaut**, wie [BossText] für die Wächter. Was eine Art
/// tut, steht in `packages/action_combat` (`EnemyKind`), wie sie
/// aussieht in `GrubeFiguren`. Die Namen sind die, unter denen die Arten
/// in `CLAUDE.md` stehen.
abstract final class GegnerText {
  static String nameOf(EnemyKind kind) => switch (kind) {
    EnemyKind.fussvolk => 'Fussvolk',
    EnemyKind.schuetze => 'Schütze',
    EnemyKind.flink => 'Kobold',
    EnemyKind.flatterer => 'Fledermaus',
    EnemyKind.brocken => 'Troll',
    EnemyKind.schleim => 'Schleim',
    EnemyKind.schleimling => 'Schleimling',
    EnemyKind.grimlock => 'Grimlock',
    EnemyKind.kreischer => 'Kreischpilz',
    EnemyKind.heiler => 'Sporenpilz',
    EnemyKind.strahler => 'Wächterauge',
    EnemyKind.endgegner => 'Der Wächter',
    EnemyKind.keiner => 'Der Held',
  };
}
