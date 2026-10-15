import 'package:flutter/material.dart';
import 'package:progression/progression.dart';

import '../../action/pit_text.dart';
import '../../ui/druck.dart';
import '../../ui/halten_und_ziehen.dart';
import '../../ui/level_abzeichen.dart';
import '../../ui/palette.dart';
import 'ability_slots_row.dart';

/// Der **goldene Doppelrand** einer Ultimate (ADR-0073) — eine Stelle für
/// Platz, Kachel und Blatt.
///
/// Ultimates haben keine Seltenheit. Gold allein hiesse Legendär
/// (`rarity_badge.dart`); die Form unterscheidet: Legendär ist eine
/// goldene Linie, die Ultimate ein goldener Rahmen aus zweien.
class UltimateRand extends StatelessWidget {
  const UltimateRand({
    required this.child,
    this.radius = 10,
    this.hell = true,
    super.key,
  });

  final Widget child;
  final double radius;

  /// Hell, wenn sie offen ist; gedämpft, solange gesperrt.
  final bool hell;

  @override
  Widget build(BuildContext context) {
    final farbe = hell ? Palette.rahmenGoldHell : Palette.rahmenGoldDunkel;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: farbe, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius - 3),
          border: Border.all(color: farbe, width: 2),
        ),
        child: child,
      ),
    );
  }
}

/// Der Platz der Ultimate: gesperrt bis Level 15, danach nimmt er nur
/// eine Ultimate — und eine Ultimate nur ihn.
class UltimatePlatz extends StatelessWidget {
  const UltimatePlatz({
    required this.level,
    required this.ultimate,
    required this.zieht,
    required this.nimmtAn,
    required this.onAblegen,
    required this.onTap,
    this.einladen = false,
    super.key,
  });

  final int level;

  /// Was darauf liegt, oder null.
  final String? ultimate;

  /// Ob gerade irgendetwas gezogen wird.
  final bool zieht;

  /// Ob er das Gezogene nähme — nur eine Ultimate, und nur offen.
  final bool nimmtAn;

  final void Function(String moveId) onAblegen;
  final VoidCallback onTap;

  /// Ob er aufleuchtet: offen, leer, und es gibt eine freigeschaltete.
  final bool einladen;

  static const double _bildSeite = 40;

  @override
  Widget build(BuildContext context) {
    final offen = AbilitySlots.ultimateOpenAt(level);
    final belegt = ultimate;
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => nimmtAn,
      onAcceptWithDetails: (d) => onAblegen(d.data),
      builder: (context, kandidaten, _) {
        final zustand = SlotDragState.fuer(
          zieht: zieht,
          passt: nimmtAn,
          schwebt: kandidaten.isNotEmpty,
        );
        return PlatzLaedtEin(
          aktiv: einladen && offen && belegt == null,
          child: PlatzBeimZiehen(
            zustand: zustand,
            child: Semantics(
              button: offen,
              label: !offen
                  ? 'Platz der Ultimate, ab Level '
                        '${AbilitySlots.ultimateLevel}'
                  : belegt == null
                  ? 'Platz der Ultimate, leer'
                  : 'Platz der Ultimate, ${pitNameOf(belegt) ?? belegt}',
              onTap: offen ? onTap : null,
              excludeSemantics: true,
              child: Druck(
                enabled: offen,
                child: UltimateRand(
                  hell: offen,
                  child: Material(
                    color: offen ? Palette.surface : Palette.surfaceSunken,
                    borderRadius: BorderRadius.circular(7),
                    child: InkWell(
                      key: const Key('ultimate-platz'),
                      onTap: offen ? onTap : null,
                      borderRadius: BorderRadius.circular(7),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: <Widget>[
                            if (offen && belegt != null)
                              MoveBild(
                                moveId: belegt,
                                side: _bildSeite,
                                fallback: const Icon(
                                  Icons.auto_awesome,
                                  color: Palette.gold,
                                ),
                              )
                            else
                              SizedBox.square(
                                dimension: _bildSeite,
                                child: Icon(
                                  offen
                                      ? Icons.add_circle_outline
                                      : Icons.lock_outline,
                                  color: Palette.muted,
                                ),
                              ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.auto_awesome,
                              size: 18,
                              color: Palette.gold,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: offen
                                  ? Text(
                                      belegt == null
                                          ? ''
                                          : pitNameOf(belegt) ?? belegt,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Palette.text,
                                      ),
                                    )
                                  : const Align(
                                      alignment: Alignment.centerLeft,
                                      child: LevelAbzeichen(
                                        level: AbilitySlots.ultimateLevel,
                                        size: 24,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
