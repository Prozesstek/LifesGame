import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../../ui/palette.dart';

/// Ein Ausrüstungsplatz mit dem, was darauf liegt.
///
/// Leere Plätze werden angezeigt statt versteckt — dieselbe Entscheidung
/// wie bei den gesperrten Kacheln auf dem Startbildschirm: Was fehlt, ist
/// eine Information.
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

  @override
  Widget build(BuildContext context) {
    final item = equipped;
    final hasAlternatives =
        owned.length > 1 || (item == null && owned.isNotEmpty);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item == null ? Palette.surfaceRaised : Palette.accent,
          width: item == null ? 1 : 1.5,
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  slot.label,
                  style: const TextStyle(fontSize: 11, color: Palette.textDim),
                ),
                const SizedBox(height: 3),
                Text(
                  item?.name ?? 'leer',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: item == null ? Palette.muted : Colors.white,
                  ),
                ),
                if (item != null) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    item.bonus.labels.join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Palette.success,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (owned.isEmpty)
            const Text(
              'nichts gekauft',
              style: TextStyle(fontSize: 11, color: Palette.muted),
            )
          else ...<Widget>[
            if (hasAlternatives)
              TextButton(
                onPressed: () => _pick(context),
                child: const Text('Wechseln'),
              ),
            if (item != null)
              IconButton(
                onPressed: onUnequip,
                icon: const Icon(Icons.close, size: 18),
                color: Palette.muted,
                tooltip: 'Ablegen',
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final chosen = await showModalBottomSheet<String>(
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
                  onTap: () => Navigator.of(sheetContext).pop(option.id),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (chosen != null) onEquip(chosen);
  }
}
