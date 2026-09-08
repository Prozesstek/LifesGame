import 'package:flutter/material.dart';

import '../../ui/palette.dart';

/// Was am Ende eines Kampfes dasteht.
///
/// **Belohnung nur beim ersten Sieg über einen Gegner** (ADR-0032). Bis
/// dahin gab der Kampf gar nichts: Er ist im Konzept die Auszahlung des
/// Fortschritts, nicht seine Quelle (`konzept.md` Abschnitt 2). Der
/// Einwand galt aber wiederholbarer Belohnung — wer denselben Gegner zum
/// zweiten Mal schlägt, bekommt weiterhin nichts, und genau das sagt der
/// Satz darunter dann auch.
class CombatResultDialog extends StatelessWidget {
  const CombatResultDialog({
    super.key,
    required this.won,
    required this.rounds,
    required this.enemyName,
    this.earnedXp = 0,
    this.earnedGold = 0,
  });

  final bool won;
  final int rounds;
  final String enemyName;

  /// Was dieser Sieg eingebracht hat. Null bei einer Niederlage und bei
  /// einem Gegner, der schon geschlagen war.
  final int earnedXp;
  final int earnedGold;

  bool get _hatBelohnung => won && (earnedXp > 0 || earnedGold > 0);

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
          if (_hatBelohnung) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              '+$earnedXp Erfahrung · +$earnedGold Gold',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Palette.gold,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            _fussnote,
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

  /// Der Satz, der die Frage „und was habe ich jetzt davon?" beantwortet,
  /// statt sie offenzulassen.
  String get _fussnote {
    if (!won) {
      return 'Das kostet nichts außer diesem Kampf. Werte wachsen über '
          'Häkchen und Lektionen, nicht über Siege.';
    }
    if (_hatBelohnung) {
      return 'Einmal je Gegner — ein zweiter Sieg gegen ihn bringt nichts '
          'mehr. Der größere Teil deiner Werte kommt weiterhin aus '
          'Gewohnheiten und Theorie.';
    }
    return 'Den hattest du schon. Ein erneuter Sieg bringt nichts ein — '
        'Erfahrung und Gold gibt es nur beim ersten Mal.';
  }
}
