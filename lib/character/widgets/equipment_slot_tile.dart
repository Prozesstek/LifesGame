import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../../gear/gear_icon.dart';
import '../../ui/druck.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';

/// Wie ein Platz gerade zum gezogenen Stück steht (ADR-0057).
///
/// **Beim Ziehen soll man sehen, wohin es gehört**, bevor man loslässt,
/// wie beim Deckbau in Clash Royale. Der passende Platz leuchtet, die
/// anderen treten zurück.
enum SlotDragState {
  /// Es wird nichts gezogen.
  ruhig,

  /// Das gezogene Stück gehört auf diesen Platz.
  passt,

  /// Und es schwebt gerade darüber: Loslassen legt es an.
  darueber,

  /// Das gezogene Stück gehört woandershin.
  passtNicht,
}

/// Ein Ausrüstungsplatz als Kachel im 6er-Raster.
///
/// Leere Plätze werden angezeigt statt versteckt: Was fehlt, ist eine
/// Information.
///
/// **Sie wählt nichts aus.** Bis zum 28.09. öffnete ein Tipp ein
/// Auswahlblatt mit allen Exemplaren des Platzes. Jetzt öffnet ein Tipp
/// auf einen belegten Platz das Blatt mit den Werten, und gewechselt wird
/// per Ziehen aus dem Katalog darunter (ADR-0057). Die Kachel meldet nur
/// den Tipp; was daraus folgt, entscheidet der Bildschirm.
class EquipmentSlotTile extends StatelessWidget {
  const EquipmentSlotTile({
    required this.slot,
    required this.equipped,
    required this.hasAny,
    required this.onTap,
    this.dragState = SlotDragState.ruhig,
    super.key,
  });

  final GearSlot slot;

  /// Was gerade auf dem Platz liegt. Null heißt leer.
  final GearCopy? equipped;

  /// Ob man für diesen Platz überhaupt etwas besitzt. Unterscheidet
  /// „leer“ (etwas da, nichts angelegt) von „nichts gekauft“.
  final bool hasAny;

  final VoidCallback onTap;

  final SlotDragState dragState;

  /// Kantenlänge von Bild und Zeichen. **Beide gleich groß**, sonst
  /// wäre eine Kachel mit Bild höher als eine ohne, und die ganze Zeile
  /// verschöbe sich.
  static const double _bildSeite = 28;

  @override
  Widget build(BuildContext context) {
    final item = equipped?.item;
    final isEmpty = item == null;

    final rand = switch (dragState) {
      SlotDragState.darueber => Palette.success,
      SlotDragState.passt => Palette.accent,
      _ => isEmpty ? Palette.surfaceRaised : Palette.accent,
    };
    final randBreite = switch (dragState) {
      SlotDragState.darueber => 3.0,
      SlotDragState.passt => 2.5,
      _ => isEmpty ? 1.0 : 1.5,
    };

    final kachel = Semantics(
      button: true,
      label: hasAny || !isEmpty
          ? '${slot.label}: ${item?.name ?? 'leer'}'
          : '${slot.label}: nichts gekauft',
      child: Druck(
        child: Material(
          color: dragState == SlotDragState.darueber
              ? Palette.surfaceRaised
              : Palette.surface,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: rand, width: randBreite),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _Zeichen(
                    slot: slot,
                    item: item,
                    color: isEmpty ? Palette.muted : Palette.accent,
                    side: _bildSeite,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    slot.label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Palette.textDim,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item?.name ?? (hasAny ? 'leer' : 'nichts gekauft'),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isEmpty ? FontWeight.normal : FontWeight.bold,
                      color: isEmpty ? Palette.muted : Palette.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Die Plätze, auf die das gezogene Stück nicht passt, treten zurück,
    // der passende wird ein wenig größer.
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: dragState == SlotDragState.passtNicht ? 0.35 : 1,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: switch (dragState) {
          SlotDragState.darueber => 1.08,
          SlotDragState.passt => 1.04,
          _ => 1,
        },
        child: kachel,
      ),
    );
  }
}

/// Was auf einem Platz steht: das Bild des getragenen Stücks, sonst das
/// Zeichen des Platzes.
class _Zeichen extends StatelessWidget {
  const _Zeichen({
    required this.slot,
    required this.item,
    required this.color,
    required this.side,
  });

  final GearSlot slot;
  final GearItem? item;
  final Color color;
  final double side;

  @override
  Widget build(BuildContext context) {
    final ersatz = Icon(GearIcons.fallbackFor(slot), size: side, color: color);
    final bild = switch (item) {
      final GearItem i => GearIcons.forItemId(i.id),
      null => null,
    };
    if (bild == null) return ersatz;

    return PixelArt(assetPath: bild, side: side, fallback: ersatz);
  }
}
