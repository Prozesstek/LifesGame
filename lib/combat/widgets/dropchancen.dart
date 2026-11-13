import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../../gear/widgets/rarity_badge.dart';
import '../../ui/druck.dart';
import '../../ui/gehrung.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';

/// **Was auf der nächsten Etage fällt** (AktivesBrett, 13.11.2026): ein
/// Knopf im Eingang, der je Seltenheit die Chance zeigt — für Gegner und
/// für den Boss. Bis dahin stand im Blatt eines Stücks nur „Seltenheit
/// ×1,15“, und niemand wusste, wie oft eine kommt.
///
/// **Rechnet nichts**: die Anteile aus `GearRolls.chancesFor`, die
/// Chance auf einen Fund aus `ActionBalance`.
class DropchancenKnopf extends StatelessWidget {
  const DropchancenKnopf({required this.etage, super.key});

  final int etage;

  static const Key knopfKey = ValueKey<String>('dropchancen');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Dropchancen auf Etage $etage',
      excludeSemantics: true,
      child: Druck(
        child: InkWell(
          key: knopfKey,
          customBorder: const CircleBorder(),
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => DropchancenDialog(etage: etage),
          ),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.diamond_outlined,
                  size: 24,
                  color: Palette.goldOnDark,
                ),
                SizedBox(width: 4),
                Text(
                  '%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Palette.goldOnDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DropchancenDialog extends StatelessWidget {
  const DropchancenDialog({required this.etage, super.key});

  final int etage;

  static String _prozent(double anteil) {
    final p = anteil * 100;
    return p < 1 && p > 0 ? '<1 %' : '${p.round()} %';
  }

  @override
  Widget build(BuildContext context) {
    final gegner = GearRolls.chancesFor(etage);
    final boss = GearRolls.chancesFor(etage, boss: true);
    const kopf = TextStyle(fontSize: 12, color: Palette.textDim);

    return HolzDialog(
      art: RahmenArt.eisen,
      child: AlertDialog(
        backgroundColor: Palette.surface,
        scrollable: true,
        title: Text('Beute auf Etage $etage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Table(
              columnWidths: const <int, TableColumnWidth>{
                0: FlexColumnWidth(),
                1: IntrinsicColumnWidth(),
                2: IntrinsicColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: <TableRow>[
                const TableRow(
                  children: <Widget>[
                    SizedBox(),
                    Padding(
                      padding: EdgeInsets.only(left: 16, bottom: 6),
                      child: Text('Gegner', style: kopf),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 16, bottom: 6),
                      child: Text('Boss', style: kopf),
                    ),
                  ],
                ),
                for (final rarity in GearRarity.values)
                  TableRow(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: RarityBadge(
                            rarity: rarity,
                            faded:
                                !gegner.containsKey(rarity) &&
                                !boss.containsKey(rarity),
                          ),
                        ),
                      ),
                      _Zahl(text: _zahl(gegner[rarity])),
                      _Zahl(text: _zahl(boss[rarity])),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Jeder Gegner lässt mit '
              '${_prozent(ActionBalance.itemDropChance)} etwas fallen, '
              'Troll und Grimlock mit '
              '${_prozent(ActionBalance.itemDropChanceTough)}. Der Boss '
              'immer, eine Seltenheit höher. Episch gibt es ab Etage '
              '${GearGates.epicRung}, Legendär ab '
              '${GearGates.legendaryRung}.',
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: Palette.textDim,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  static String _zahl(double? anteil) =>
      anteil == null ? '—' : _prozent(anteil);
}

class _Zahl extends StatelessWidget {
  const _Zahl({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Palette.text,
        ),
      ),
    );
  }
}
