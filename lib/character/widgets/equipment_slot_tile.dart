import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../../ui/palette.dart';

/// Ein Ausrüstungsplatz als Kachel im 6er-Raster.
///
/// Leere Plätze werden angezeigt statt versteckt — dieselbe Entscheidung
/// wie bei den gesperrten Kacheln auf dem Startbildschirm: Was fehlt, ist
/// eine Information.
///
/// **Warum ein Raster und keine sechs Zeilen.** Vier Werte plus sechs
/// Plätze plus Beständigkeit plus Knöpfe sind als Liste über zwanzig
/// Zeilen — auf 390 Pixeln Breite scrollt man dann an allem vorbei, statt
/// es zu überblicken. Als Raster braucht die Ausrüstung ein Drittel der
/// Höhe (ADR-0013).
///
/// **Was das kostet, steht im Auswahlblatt.** Wirkung und Ablegen passen
/// nicht mehr auf die Kachel. Beides ist einen Fingertipp entfernt statt
/// sichtbar — vertretbar, weil die Wirkung bereits in „Werte im Kampf"
/// mit Herkunft steht und dort zurechenbar ist.
class EquipmentSlotTile extends StatelessWidget {
  const EquipmentSlotTile({
    required this.slot,
    required this.equipped,
    required this.owned,
    required this.onEquip,
    required this.onUnequip,
    super.key,
  });

  final GearSlot slot;

  /// Was gerade auf dem Platz liegt. Null heißt leer.
  final GearItem? equipped;

  /// Alles Gekaufte, das auf diesen Platz passt — die Auswahl.
  final List<GearItem> owned;

  final void Function(String itemId) onEquip;
  final VoidCallback onUnequip;

  /// Das Symbol je Platz. Reine Darstellung — deshalb hier und nicht in
  /// `package:gear`, das von Symbolen nichts wissen soll.
  static IconData _iconFor(GearSlot slot) {
    return switch (slot) {
      GearSlot.waffe => Icons.colorize,
      GearSlot.ruestung => Icons.shield_outlined,
      GearSlot.helm => Icons.sports_motorsports_outlined,
      GearSlot.schuhe => Icons.directions_walk,
      GearSlot.ring => Icons.circle_outlined,
      GearSlot.talisman => Icons.auto_awesome_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final item = equipped;
    final isEmpty = item == null;
    final hasNothingToPick = owned.isEmpty;

    return Semantics(
      button: !hasNothingToPick,
      label: hasNothingToPick
          ? '${slot.label}: nichts gekauft'
          : '${slot.label}: ${item?.name ?? 'leer'}',
      child: Material(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          // Ein Platz ohne Auswahl ist nicht antippbar. Ein Blatt, in dem
          // nichts steht, wäre eine Sackgasse statt einer Antwort.
          onTap: hasNothingToPick ? null : () => _pick(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isEmpty ? Palette.surfaceRaised : Palette.accent,
                width: isEmpty ? 1 : 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  _iconFor(slot),
                  size: 20,
                  color: isEmpty ? Palette.muted : Palette.accent,
                ),
                const SizedBox(height: 6),
                Text(
                  slot.label,
                  style: const TextStyle(fontSize: 10, color: Palette.textDim),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item?.name ?? (hasNothingToPick ? 'nichts gekauft' : 'leer'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isEmpty ? FontWeight.normal : FontWeight.bold,
                    color: isEmpty ? Palette.muted : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final chosen = await showModalBottomSheet<_Choice>(
      context: context,
      backgroundColor: Palette.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  children: <Widget>[
                    Icon(_iconFor(slot), size: 18, color: Palette.accent),
                    const SizedBox(width: 10),
                    Text(
                      slot.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              for (final option in owned)
                ListTile(
                  title: Text(
                    option.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    option.bonus.labels.join(' · '),
                    style: const TextStyle(color: Palette.textDim),
                  ),
                  trailing: option.id == equipped?.id
                      ? const Icon(Icons.check, color: Palette.accent)
                      : null,
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_Choice.equip(option.id)),
                ),
              // Das Ablegen ist von der Kachel hierher gewandert: Im
              // Raster ist kein Platz für einen zweiten Knopf, und hier
              // steht es neben dem, was es ersetzt.
              if (equipped != null)
                ListTile(
                  leading: const Icon(Icons.close, color: Palette.muted),
                  title: const Text(
                    'Ablegen',
                    style: TextStyle(color: Palette.textDim),
                  ),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(const _Choice.unequip()),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (chosen == null) return;
    final itemId = chosen.itemId;
    if (itemId == null) {
      onUnequip();
    } else {
      onEquip(itemId);
    }
  }
}

/// Was im Auswahlblatt angetippt wurde.
///
/// Eigener Typ statt eines nullbaren Strings: Abbrechen und Ablegen sind
/// zwei verschiedene Antworten, und beide wären sonst null.
class _Choice {
  const _Choice.equip(this.itemId);

  const _Choice.unequip() : itemId = null;

  final String? itemId;
}
