import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../character/widgets/equipment_slot_tile.dart';
import '../character/widgets/set_card.dart';
import '../combat/ladder_controller.dart';
import '../ui/ausgegraut.dart';
import '../ui/druck.dart';
import '../ui/palette.dart';
import '../ui/pixel_art.dart';
import 'gear_controller.dart';
import 'gear_grouping.dart';
import 'gear_icon.dart';
import 'shop_screen.dart';
import 'widgets/gear_sheet.dart';
import 'widgets/rarity_badge.dart';

/// Der Ausrüstungs-Bildschirm: sechs Plätze oben, der ganze Katalog
/// darunter (ADR-0057).
///
/// **Gebaut wie der Fähigkeiten-Bildschirm** (ADR-0049), aus demselben
/// Grund: Im Charakter standen nur die sechs Plätze, und was es sonst zu
/// holen gibt, sah man nur im Laden, und dort nur die sechs Angebote des
/// Tages. Achtundvierzig Stücke, von denen man die meisten nie zu sehen
/// bekommt, sind kein Ziel.
///
/// **Der Katalog, nicht das Inventar.** Jedes Stück steht einmal da,
/// besessene farbig, der Rest grau. Wer ein Stück mehrfach hat, sieht
/// die Zahl auf der Kachel, und im Blatt jedes Exemplar mit seinem Wurf.
/// Das Inventar im Laden bleibt daneben bestehen.
class EquipmentScreen extends ConsumerStatefulWidget {
  const EquipmentScreen({super.key});

  static const double _maxWidth = 560;

  @override
  ConsumerState<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends ConsumerState<EquipmentScreen> {
  /// Die Ordnung des Rasters. Sie gehört zur Ansicht, nicht zum
  /// Spielstand: Wer den Bildschirm wieder öffnet, sieht wieder A bis Z.
  GearGrouping _gruppierung = GearGrouping.values.first;

  /// Drei Spalten für die Plätze, wie bisher im Charakter.
  static const int _slotColumns = 3;

  /// Vier Spalten für den Katalog, wie bei den Fähigkeiten.
  static const int _columns = 4;

  @override
  Widget build(BuildContext context) {
    final loadout = ref.watch(loadoutProvider);
    final rung = ref.watch(ladderProvider).highestDefeated;
    final besessen = <String>{
      for (final copy in loadout.ownedCopies) copy.itemId,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ausrüstung'),
        backgroundColor: Palette.surface,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: EquipmentScreen._maxWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: <Widget>[
                const _SectionTitle('Deine sechs Plätze'),
                const SizedBox(height: 4),
                Text(
                  loadout.equippedCount == 0
                      ? 'Noch nichts angelegt. Antippen wechselt, was auf '
                            'einem Platz liegt.'
                      : '${loadout.equippedCount} von '
                            '${GearSlot.values.length} Plätzen belegt. '
                            'Antippen wechselt.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Palette.textOnDarkDim,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  // Das Raster sitzt in einer ListView: eigene Höhe, kein
                  // eigenes Scrollen. Sonst scrollten zwei Flächen
                  // ineinander.
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: _slotColumns,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.92,
                  children: <Widget>[
                    for (final slot in GearSlot.values)
                      EquipmentSlotTile(
                        slot: slot,
                        equipped: loadout.equippedCopyIn(slot),
                        owned: loadout.copiesIn(slot),
                        onEquip: (uid) =>
                            ref.read(loadoutProvider.notifier).equip(uid),
                        onUnequip: () =>
                            ref.read(loadoutProvider.notifier).unequip(slot),
                      ),
                  ],
                ),
                // **Nur sichtbar, wenn etwas anliegt.** Eine Karte, die
                // „keine Sets" sagt, ist eine Zeile über nichts.
                if (loadout.wearsAnySetPiece) ...<Widget>[
                  const SizedBox(height: 18),
                  const _SectionTitle('Sets'),
                  const SizedBox(height: 10),
                  SetCard(loadout: loadout),
                ],
                const SizedBox(height: 20),
                const _SectionTitle('Alle Stücke'),
                const SizedBox(height: 4),
                Text(
                  '${besessen.length} von ${GearCatalog.all.length} im '
                  'Besitz. Antippen zeigt alle Werte, auch bei den grauen.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Palette.textOnDarkDim,
                  ),
                ),
                const SizedBox(height: 10),
                _Gruppenwahl(
                  aktiv: _gruppierung,
                  onWaehle: (g) => setState(() => _gruppierung = g),
                ),
                const SizedBox(height: 12),
                for (final gruppe in groupGear(_gruppierung))
                  ..._gruppe(
                    gruppe,
                    loadout: loadout,
                    besessen: besessen,
                    rung: rung,
                  ),
                const SizedBox(height: 4),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ShopScreen()),
                  ),
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('Zum Laden'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Eine Gruppe mit Überschrift und Raster. Das alphabetische Raster hat
  /// keine Überschrift, es ist die eine Gruppe.
  List<Widget> _gruppe(
    GearGroup gruppe, {
    required Loadout loadout,
    required Set<String> besessen,
    required int rung,
  }) {
    final zaehler =
        '${gruppe.items.where((i) => besessen.contains(i.id)).length} '
        'von ${gruppe.items.length}';

    return <Widget>[
      if (gruppe.title case final String titel)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: <Widget>[
              if (gruppe.rarity case final GearRarity stufe)
                RarityBadge(rarity: stufe)
              else
                Flexible(
                  child: Text(
                    titel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Palette.textOnDark,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                zaehler,
                style: const TextStyle(
                  fontSize: 11,
                  color: Palette.textOnDarkDim,
                ),
              ),
            ],
          ),
        ),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: _columns,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.78,
        children: <Widget>[
          for (final item in gruppe.items)
            _Kachel(
              item: item,
              anzahl: loadout.ownedCopies
                  .where((c) => c.itemId == item.id)
                  .length,
              angelegt: loadout.equippedCopyIn(item.slot)?.itemId == item.id,
              gesperrt: !GearGates.isOpen(item.rarity, highestRung: rung),
              onTap: () => showGearSheet(context, item),
            ),
        ],
      ),
      const SizedBox(height: 16),
    ];
  }
}

/// Die vier Ordnungen als Reihe von Chips.
class _Gruppenwahl extends StatelessWidget {
  const _Gruppenwahl({required this.aktiv, required this.onWaehle});

  final GearGrouping aktiv;
  final ValueChanged<GearGrouping> onWaehle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: <Widget>[
        for (final g in GearGrouping.values)
          Druck(
            child: ChoiceChip(
              label: Text(g.label),
              selected: g == aktiv,
              onSelected: (_) => onWaehle(g),
              selectedColor: Palette.accentOnDark,
              backgroundColor: Palette.surface,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: g == aktiv ? FontWeight.bold : FontWeight.normal,
                color: Palette.text,
              ),
              showCheckmark: false,
            ),
          ),
      ],
    );
  }
}

/// Ein Stück im Raster.
///
/// **Nicht besessen heißt grau, nicht weg.** Die Zeichnung bleibt
/// erkennbar, damit man weiß, worauf man zuarbeitet. Ein Schloss steht
/// nur da, wo die Seltenheit noch an der Grube hängt (ADR-0034), dort
/// hilft auch Gold nicht.
class _Kachel extends StatelessWidget {
  const _Kachel({
    required this.item,
    required this.anzahl,
    required this.angelegt,
    required this.gesperrt,
    required this.onTap,
  });

  final GearItem item;

  /// Wie viele Exemplare man davon besitzt.
  final int anzahl;

  /// Ob eines davon auf seinem Platz liegt.
  final bool angelegt;

  /// Ob die Seltenheit noch gesperrt ist.
  final bool gesperrt;

  final VoidCallback onTap;

  static const double _bildSeite = 36;

  bool get _besessen => anzahl > 0;

  @override
  Widget build(BuildContext context) {
    final farbe = RarityBadge.colorOf(item.rarity);
    final pfad = GearIcons.forItemId(item.id);
    final ersatz = SizedBox.square(
      dimension: _bildSeite,
      child: Icon(
        GearIcons.fallbackFor(item.slot),
        color: _besessen ? Palette.accent : Palette.muted,
      ),
    );

    return Semantics(
      button: true,
      label: _besessen
          ? '${item.name}, $anzahl im Besitz'
          : '${item.name}, nicht im Besitz',
      child: Druck(
        child: Material(
          color: _besessen ? Palette.surface : Palette.surfaceSunken,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: angelegt
                      ? Palette.accent
                      : farbe.withValues(alpha: _besessen ? 0.7 : 0.25),
                  width: angelegt ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Ausgegraut(
                        aktiv: !_besessen,
                        child: pfad == null
                            ? ersatz
                            : PixelArt(
                                assetPath: pfad,
                                side: _bildSeite,
                                fallback: ersatz,
                              ),
                      ),
                      if (angelegt)
                        const Positioned(
                          right: -2,
                          bottom: -2,
                          child: Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Palette.accent,
                          ),
                        )
                      else if (!_besessen && gesperrt)
                        const Positioned(
                          right: -2,
                          bottom: -2,
                          child: Icon(
                            Icons.lock,
                            size: 12,
                            color: Palette.muted,
                          ),
                        ),
                      if (anzahl > 1)
                        Positioned(
                          left: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Palette.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '×$anzahl',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Palette.surface,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      height: 1.15,
                      color: _besessen ? Palette.text : Palette.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Palette.textOnDark,
      ),
    );
  }
}
