import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../../ui/palette.dart';
import '../gear_icon.dart';

/// Ein Ausrüstungsstück als Kachel im Raster.
///
/// **Sie wählt aus, sie kauft nicht.** Gekauft wird in der Detailfläche
/// darunter — dort steht, was das Stück kann, was es kostet und was noch
/// fehlt. Eine Kachel, die beides täte, müsste zwei Tippflächen tragen,
/// und genau diese Mehrdeutigkeit steht bei den Gewohnheiten schon als
/// offener Punkt in `state.md`.
///
/// Was sie zeigen muss, damit die Wahl überhaupt eine ist: den Namen, die
/// Seltenheit als Rand, und ob das Stück schon einem gehört.
class ShopItemCell extends StatelessWidget {
  const ShopItemCell({
    required this.item,
    required this.isSelected,
    required this.isOwned,
    required this.isEquipped,
    required this.onTap,
    super.key,
  });

  final GearItem item;
  final bool isSelected;
  final bool isOwned;
  final bool isEquipped;
  final VoidCallback onTap;

  /// Abstand zwischen zwei Kacheln.
  static const double gap = 10;

  /// Wie viele Kacheln nebeneinander stehen.
  ///
  /// Drei sind bei 390 Pixeln Breite die letzte Zahl, bei der ein
  /// Itemname noch in zwei Zeilen passt. Bei vieren bricht
  /// „Schuppenpanzer" mitten im Wort.
  static const int columns = 3;

  /// Wie breit eine Kachel in einem [rowWidth] Pixel breiten Raster wird.
  static double sideFor(double rowWidth) {
    return (rowWidth - gap * (columns - 1)) / columns;
  }

  @override
  Widget build(BuildContext context) {
    final rand = isSelected
        ? Palette.accent
        : (isEquipped ? Palette.success : Palette.surfaceRaised);
    final bild = GearIcons.forItemId(item.id);

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.name,
      child: Material(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: rand, width: isSelected ? 2 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: bild == null
                      ? Icon(
                          GearIcons.fallbackFor(item.slot),
                          size: 30,
                          color: isOwned ? Palette.muted : Palette.textDim,
                        )
                      : Image.asset(
                          bild,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                          errorBuilder: (context, error, stack) => Icon(
                            GearIcons.fallbackFor(item.slot),
                            size: 30,
                            color: Palette.muted,
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.15,
                    fontWeight: FontWeight.bold,
                    color: isOwned ? Palette.textDim : Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                // **Preis oder Besitz, nie beides.** Was einem gehört,
                // hat keinen Preis mehr — es hat einen Zustand.
                Text(
                  _fussnote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isEquipped
                        ? Palette.success
                        : (isOwned ? Palette.muted : Palette.gold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _fussnote {
    if (isEquipped) return 'getragen';
    if (isOwned) return 'gekauft';
    return '${item.price} G';
  }
}
