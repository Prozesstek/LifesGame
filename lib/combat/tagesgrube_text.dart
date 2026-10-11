import 'package:action_combat/action_combat.dart';

/// Der Text, den man nach der Tagesgrube in eine Gruppe kopiert
/// (ADR-0072) — **reine Rechnung**, kein Widget.
///
/// ```
/// Lifes Game · Tagesgrube #12
/// 🟩🟩🟨🟥👑 1:04
/// ⚡ In Form · 🔥 12 Tage
/// prozesstek.de/LifesGame
/// ```
///
/// **Er verrät nichts**: nicht die Karte, nicht den Wächter, nicht den
/// Satz des Tages. Wer ihn liest, sieht nur, wie es lief — und dass
/// jemand heute seine Gewohnheiten erledigt hat.
abstract final class TagesgrubeText {
  /// Wo das Spiel liegt. Ohne die Adresse fände niemand hin: Nach „Lifes
  /// Game“ sucht man und findet Conways Spiel des Lebens.
  static const String adresse = 'prozesstek.de/LifesGame';

  /// Das Feld zu einem Raum. Ein `switch` ohne Rückfall: Eine neue Marke
  /// ist ein Compilerfehler statt einer Lücke im Text.
  static String feld(RoomMark marke) {
    return switch (marke) {
      RoomMark.sauber => '🟩',
      RoomMark.angekratzt => '🟨',
      RoomMark.blutig => '🟥',
      RoomMark.gefallen => '💀',
      RoomMark.zeitAus => '⏳',
      RoomMark.krone => '👑',
      RoomMark.offen => '⬛',
    };
  }

  static String raumzeile(List<RoomMark> rooms) => rooms.map(feld).join();

  /// „1:04“ — Minuten und Sekunden, gerundet.
  static String zeit(double seconds) {
    final ganz = seconds.round();
    return '${ganz ~/ 60}:${(ganz % 60).toString().padLeft(2, '0')}';
  }

  /// Der ganze Text. [dayStreak] ist die Tageskette beim Teilen — sie
  /// steht nur da, wenn es eine gibt.
  static String teilen({
    required int number,
    required DailyRun run,
    required int dayStreak,
  }) {
    final darunter = <String>[
      ?_verfassung(run.condition),
      if (dayStreak > 0) '🔥 $dayStreak ${dayStreak == 1 ? 'Tag' : 'Tage'}',
    ];
    return <String>[
      'Lifes Game · Tagesgrube #$number',
      _ergebnis(run),
      if (darunter.isNotEmpty) darunter.join(' · '),
      adresse,
    ].join('\n');
  }

  /// Ein Sieg trägt seine Zeit, eine Niederlage nicht: Wie schnell jemand
  /// verloren hat, will keiner vergleichen.
  static String _ergebnis(DailyRun run) {
    final zeile = raumzeile(run.rooms);
    return switch (run.outcome) {
      DailyOutcome.sieg => '$zeile ${zeit(run.seconds)}'.trim(),
      DailyOutcome.gefallen => zeile.isEmpty ? feld(RoomMark.gefallen) : zeile,
      DailyOutcome.zeitAus => zeile.isEmpty ? feld(RoomMark.zeitAus) : zeile,
      DailyOutcome.abgebrochen => '💨 abgebrochen',
    };
  }

  /// „Ohne Form“ steht nicht da — der Text sagt, was war, und hält
  /// niemandem vor, was fehlte.
  static String? _verfassung(DailyCondition condition) {
    return switch (condition) {
      DailyCondition.inForm => '⚡ In Form',
      DailyCondition.ruhetag => '🌙 Ruhetag',
      DailyCondition.ohneForm => null,
    };
  }
}
