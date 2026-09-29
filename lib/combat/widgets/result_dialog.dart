import 'package:flutter/material.dart';

import '../../ui/gold_icon.dart';
import '../../ui/holz.dart';
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
    this.summary,
    this.perStage = false,
    this.fakten,
  });

  final bool won;
  final int rounds;
  final String enemyName;

  /// Was dieser Sieg eingebracht hat. Null bei einer Niederlage und bei
  /// einem Gegner, der schon geschlagen war.
  final int earnedXp;
  final int earnedGold;

  /// Der erste Satz, wenn er nicht aus Runden besteht.
  ///
  /// Die Grube kennt keine Runden (ADR-0039); sie reicht ihren Satz
  /// fertig herein. Ohne ihn steht da, was der Rundenkampf sagt.
  final String? summary;

  /// Ob die Belohnung an einer Stufe der Grube hängt statt an einem
  /// Gegner — ändert nur den Wortlaut der Fussnote, nicht die Regel.
  final bool perStage;

  /// Was der Lauf war, als Zeichen und Zahl — Stufe, Gegner, Zeit. Ist
  /// es gesetzt, steht [summary] nur noch für den Vorleser da.
  final List<(IconData, String)>? fakten;

  bool get _hatBelohnung => won && (earnedXp > 0 || earnedGold > 0);

  static const TextStyle _beute = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Palette.gold,
  );

  @override
  Widget build(BuildContext context) {
    // Der hängende Holzrahmen trägt das Blatt; innen bleibt Pergament.
    return HolzDialog(child: _blatt(context));
  }

  Widget _blatt(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.surface,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
      // **Ohne Worte:** Pokal oder Gesicht, darunter die Fakten als
      // Zeichen und die Beute als Zahlen. Warum ein zweiter Sieg nichts
      // bringt, sagt ein Tipp auf das Zeichen.
      title: Center(
        child: Tooltip(
          triggerMode: TooltipTriggerMode.tap,
          message: _fussnote,
          child: Icon(
            won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
            size: 56,
            color: won ? Palette.gold : Palette.enemy,
            semanticLabel: won ? 'Gewonnen' : 'Verloren',
          ),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (fakten case final List<(IconData, String)> liste)
            Semantics(
              label: summary,
              excludeSemantics: true,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: <Widget>[
                  for (final (icon, wert) in liste)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(icon, size: 20, color: Palette.textDim),
                        if (wert.isNotEmpty) ...<Widget>[
                          const SizedBox(width: 4),
                          Text(
                            wert,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Palette.text,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            )
          else
            Text(
              summary ??
                  (won
                      ? '$enemyName besiegt — nach $rounds Runden.'
                      : 'Du bist nach $rounds Runden gefallen.'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          if (_hatBelohnung) ...<Widget>[
            const SizedBox(height: 14),
            Semantics(
              label: '$earnedXp Erfahrung und $earnedGold Gold',
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.auto_awesome, size: 20, color: Palette.gold),
                  const SizedBox(width: 4),
                  Text('+$earnedXp', style: _beute),
                  const SizedBox(width: 16),
                  const GoldIcon(size: 20),
                  const SizedBox(width: 4),
                  Text('+$earnedGold', style: _beute),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(Icons.check_rounded, semanticLabel: 'OK'),
        ),
      ],
    );
  }

  /// Der Satz, der die Frage „und was habe ich jetzt davon?" beantwortet,
  /// statt sie offenzulassen.
  String get _fussnote {
    if (perStage) return _fussnoteStufe;
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

  String get _fussnoteStufe {
    if (!won) {
      return 'Das kostet nichts außer diesem Lauf. Werte wachsen über '
          'Häkchen und Lektionen, nicht über Siege.';
    }
    if (_hatBelohnung) {
      return 'Einmal je Stufe — wer sie noch einmal räumt, bekommt nichts '
          'mehr. Der größere Teil deiner Werte kommt weiterhin aus '
          'Gewohnheiten und Theorie.';
    }
    return 'Diese Stufe hattest du schon. Erfahrung und Gold gibt es nur '
        'beim ersten Mal.';
  }
}
