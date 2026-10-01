import 'package:action_combat/action_combat.dart';

/// Wie die vier Wächter heissen (ADR-0062).
///
/// **Nur der Wortlaut.** Was ein Wächter tut, steht in
/// `packages/action_combat` (`boss.dart`), wie er aussieht in
/// `GrubeFiguren.forBoss`. Die Unterzeile sagt in einem Satz, worauf man
/// achten muss — sie steht nur beim Auftritt da, wenn ohnehin niemand
/// kämpft.
abstract final class BossText {
  /// Der Name über dem Balken und beim Auftritt.
  static String nameOf(BossKind kind) => switch (kind) {
    BossKind.zyklop => 'Der Zyklop',
    BossKind.ettin => 'Der Zweikopf',
    BossKind.slaad => 'Der Schlund',
    BossKind.sumpftroll => 'Der Sumpftroll',
  };

  /// Die Zeile unter dem Namen beim Auftritt.
  static String hintOf(BossKind kind) => switch (kind) {
    BossKind.zyklop => 'Hüter der Tiefe',
    BossKind.ettin => 'Zwei Köpfe, zwei Stöße',
    BossKind.slaad => 'Er springt dorthin, wo du stehst',
    BossKind.sumpftroll => 'Sein Gift bleibt liegen',
  };
}
