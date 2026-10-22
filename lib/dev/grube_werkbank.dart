import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../action/action_game.dart';
import '../action/gegner_text.dart';
import '../action/pit_beute.dart';
import '../gear/widgets/rarity_badge.dart';
import '../ui/palette.dart';

/// **Die Werkbank in der Grube** — nur im Entwicklermodus und nur auf dem
/// Dev-Stand (ADR-0021).
///
/// Legt Funde einer gewählten Seltenheit neben den Helden, um Legendäres
/// anzusehen, ohne Gegner zu jagen, und beschwört Gegner einer Art, um
/// den Schaden an ihnen zu messen. Beides nimmt den Weg des Spiels
/// (`EntwicklerWerkzeug` in `package:action_combat`): Ein Fund wird
/// eingesammelt und landet im Rucksack, ein Gegner hat die Werte der
/// Stufe und zählt, wenn er fällt.
///
/// Solange das Blatt offen ist, steht der Lauf still.
abstract final class GrubeWerkbank {
  /// Der Knopf oben in der Leiste der Grube.
  static const Key knopfKey = ValueKey<String>('grube-werkbank');

  static Key fundKey(GearRarity rarity) =>
      ValueKey<String>('werkbank-fund-${rarity.name}');

  static Key gegnerKey(EnemyKind kind) =>
      ValueKey<String>('werkbank-gegner-${kind.name}');

  /// Wen man beschwören kann: jede Art ausser dem Wächter, der in seinen
  /// Raum gehört, und dem Helden.
  static final List<EnemyKind> beschwoerbar = <EnemyKind>[
    for (final kind in EnemyKind.values)
      if (kind != EnemyKind.endgegner && kind != EnemyKind.keiner) kind,
  ];

  /// Legt einen Fund der Seltenheit [rarity] vor den Helden.
  static void legeFund(ActionGame game, PitBeute funde, GearRarity rarity) {
    final nth = game.sim.devLegeFund();
    funde.wuensche(nth, rarity);
  }

  static Future<void> zeige(
    BuildContext context, {
    required ActionGame game,
    required PitBeute funde,
  }) async {
    game.pauseEngine();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Palette.surface,
      // Elf Arten und fünf Seltenheiten passen nicht immer in die halbe
      // Höhe — das Blatt darf wachsen und rollt.
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _Titel('Fund vor den Helden legen'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final rarity in GearRarity.values)
                    ActionChip(
                      key: fundKey(rarity),
                      side: BorderSide(
                        color: RarityBadge.rahmenOf(rarity),
                        width: 2,
                      ),
                      label: Text(
                        rarity.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: RarityBadge.colorOf(rarity),
                        ),
                      ),
                      onPressed: () => legeFund(game, funde, rarity),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const _Titel('Gegner beschwören'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final kind in beschwoerbar)
                    ActionChip(
                      key: gegnerKey(kind),
                      label: Text(
                        GegnerText.nameOf(kind),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => game.sim.devBeschwoereGegner(kind),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Gegner erscheinen zwei, drei Felder in Blickrichtung. '
                'Der Lauf steht still, bis das Blatt zu ist.',
                style: TextStyle(fontSize: 11, color: Palette.textDim),
              ),
            ],
          ),
        ),
      ),
    );
    game.resumeEngine();
  }
}

class _Titel extends StatelessWidget {
  const _Titel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Palette.text,
        ),
      ),
    );
  }
}
