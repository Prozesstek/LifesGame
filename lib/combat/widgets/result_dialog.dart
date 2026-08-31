import 'package:flutter/material.dart';

import '../../ui/palette.dart';

/// Was am Ende eines Kampfes dasteht.
///
/// **Ohne Belohnung, weil es keine gibt.** Der Kampf ist im Konzept die
/// Auszahlung des Fortschritts, nicht seine Quelle — Erfahrung und Gold
/// kommen aus Gewohnheiten und Theorie. Beute ist dem Dungeon vorbehalten
/// (`konzept.md` Abschnitt 2 und 4). Der letzte Satz beantwortet die
/// Frage „und was habe ich jetzt davon?", statt sie offenzulassen.
class CombatResultDialog extends StatelessWidget {
  const CombatResultDialog({
    super.key,
    required this.won,
    required this.rounds,
    required this.enemyName,
  });

  final bool won;
  final int rounds;
  final String enemyName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.surfaceRaised,
      title: Row(
        children: <Widget>[
          Icon(
            won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
            color: won ? Palette.gold : Palette.enemy,
          ),
          const SizedBox(width: 10),
          Text(
            won ? 'Gewonnen' : 'Verloren',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            won
                ? '$enemyName besiegt — nach $rounds Runden.'
                : 'Du bist nach $rounds Runden gefallen.',
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 14),
          Text(
            won
                ? 'Erfahrung und Gold gibt es dafür nicht — sie kommen aus '
                      'deinen Gewohnheiten und aus der Theorie. Der Kampf '
                      'zeigt, was daraus geworden ist.'
                : 'Das kostet nichts außer diesem Kampf. Werte wachsen über '
                      'Häkchen und Lektionen, nicht über Siege.',
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Palette.muted,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
