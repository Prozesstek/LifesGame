import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../../gear/copy_text.dart';
import '../../gear/gear_icon.dart';
import '../../gear/widgets/rarity_badge.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';

/// Fragt, ob ein Schlüssel die Beute des Wächters öffnen soll
/// (ADR-0048). Gibt `true` zurück, wenn ja.
///
/// **Gefragt, nicht automatisch.** Ein Schlüssel ist ein Wurf, und wer
/// ihn lieber auf einer tieferen Stufe einsetzt, soll ihn behalten
/// können — sonst kostete jeder Lauf um die Bestzeit einen.
Future<bool> askToOpenLoot(
  BuildContext context, {
  required int stage,
  required int keys,
}) async {
  final antwort = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => HolzDialog(
      child: AlertDialog(
        backgroundColor: Palette.surface,
        title: const Text('Die Beute des Wächters'),
        content: Text(
          'Ein Schlüssel öffnet sie: ein gewürfeltes Stück von Stufe '
          '$stage. Du hast $keys Schlüssel.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Liegen lassen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Öffnen'),
          ),
        ],
      ),
    ),
  );
  return antwort ?? false;
}

/// Zeigt, was gefallen ist. Gibt `true` zurück, wenn es angelegt werden
/// soll.
Future<bool> showLoot(
  BuildContext context, {
  required GearCopy loot,
  required String headline,
  GearCopy? worn,
}) async {
  final item = loot.item;
  if (item == null) return false;
  final bild = GearIcons.forItemId(item.id);
  final antwort = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => HolzDialog(
      child: AlertDialog(
        backgroundColor: Palette.surface,
        title: Text(headline),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 72,
              child: bild == null
                  ? Icon(
                      GearIcons.fallbackFor(item.slot),
                      size: 48,
                      color: Palette.textDim,
                    )
                  : PixelArt(
                      assetPath: bild,
                      side: 72,
                      fallback: Icon(
                        GearIcons.fallbackFor(item.slot),
                        size: 48,
                        color: Palette.textDim,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  child: Text(
                    item.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Palette.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                RarityBadge(rarity: item.rarity),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              CopyText.line(loot),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Palette.success,
                fontWeight: CopyText.isGoodRoll(loot)
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            if (worn != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'Getragen: ${CopyText.line(worn)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Palette.muted),
              ),
            ],
            if (GearSets.byId(item.setId) case final GearSet set) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'Teil von „${set.name}"',
                style: const TextStyle(fontSize: 12, color: Palette.accent),
              ),
            ],
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Ins Inventar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Anlegen'),
          ),
        ],
      ),
    ),
  );
  return antwort ?? false;
}
