import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';

import '../../ui/palette.dart';

/// Die Raumzeile der Tagesgrube als Bild: ein Feld je Raum (ADR-0072).
///
/// **Gezeichnet, nicht als Emoji.** Im geteilten Text stehen 🟩🟨🟥; im
/// Browser müsste Flutter dafür erst eine Schrift nachladen, und bis
/// dahin stünden dort leere Kästchen. Farbe und Zeichen sind dieselben
/// wie im Text (`TagesgrubeText.feld`).
class Raumzeile extends StatelessWidget {
  const Raumzeile({required this.rooms, this.side = 20, super.key});

  final List<RoomMark> rooms;

  /// Kantenlänge eines Felds.
  final double side;

  /// Was der Vorleser sagt — die Zeile ist sonst nur Farbe.
  static String label(List<RoomMark> rooms) {
    if (rooms.isEmpty) return 'Kein Raum erreicht';
    return rooms.map(_wort).join(', ');
  }

  static String _wort(RoomMark marke) {
    return switch (marke) {
      RoomMark.sauber => 'kaum getroffen',
      RoomMark.angekratzt => 'getroffen',
      RoomMark.blutig => 'schwer getroffen',
      RoomMark.gefallen => 'gefallen',
      RoomMark.zeitAus => 'Zeit abgelaufen',
      RoomMark.krone => 'Wächter besiegt',
      RoomMark.offen => 'nicht erreicht',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label(rooms),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var i = 0; i < rooms.length; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : side * 0.15),
              child: _Feld(marke: rooms[i], side: side),
            ),
        ],
      ),
    );
  }
}

class _Feld extends StatelessWidget {
  const _Feld({required this.marke, required this.side});

  final RoomMark marke;
  final double side;

  @override
  Widget build(BuildContext context) {
    // Der Wächter ist kein Raum: Sein Feld trägt nur das Zeichen.
    if (marke == RoomMark.krone) {
      return SizedBox.square(
        dimension: side,
        child: Icon(
          Icons.emoji_events_rounded,
          size: side,
          color: Palette.raumKrone,
        ),
      );
    }

    final (Color? farbe, IconData? zeichen) = switch (marke) {
      RoomMark.sauber => (Palette.raumSauber, null),
      RoomMark.angekratzt => (Palette.raumAngekratzt, null),
      RoomMark.blutig => (Palette.raumBlutig, null),
      RoomMark.gefallen => (Palette.text, Icons.close_rounded),
      RoomMark.zeitAus => (Palette.text, Icons.timer_off_outlined),
      // Nicht erreicht: ein leeres Feld, nur der Rand.
      RoomMark.offen => (null, null),
      RoomMark.krone => (null, null),
    };

    return Container(
      width: side,
      height: side,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: farbe,
        borderRadius: BorderRadius.circular(side * 0.2),
        border: Border.all(
          color: marke == RoomMark.offen
              ? Palette.muted
              : Palette.text.withValues(alpha: 0.55),
          width: side * 0.07,
        ),
      ),
      child: zeichen == null
          ? null
          : Icon(zeichen, size: side * 0.72, color: Palette.surface),
    );
  }
}
