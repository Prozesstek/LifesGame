import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../achievements/show_achievement_unlock.dart';
import '../progression/show_level_up.dart';
import '../ui/holz.dart';
import '../ui/palette.dart';
import 'gear_controller.dart';

/// Verkauft ein Exemplar, **nach Rückfrage**, und feiert, was daraus
/// folgt (ADR-0048, ADR-0057).
///
/// Gibt zurück, ob verkauft wurde. Zurück kommt ein Viertel des Preises,
/// und der Wurf ist danach weg. Deshalb die Rückfrage.
///
/// **Der Laden hat denselben Weg noch einmal** (`ShopScreen._sell`),
/// weil er beim Bau des Ausrüstungs-Bildschirms nicht angefasst werden
/// sollte. Wer an einem der beiden dreht, sieht beim anderen nach, und
/// irgendwann gehört der Laden auf diese Funktion umgestellt.
Future<bool> sellWithConfirm(
  BuildContext context,
  WidgetRef ref,
  GearCopy copy,
) async {
  final item = copy.item;
  if (item == null) return false;
  final erloes = Loadout.refundFor(item);

  final bestaetigt = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => HolzDialog(
      child: AlertDialog(
        backgroundColor: Palette.surface,
        title: Text('${item.name} verkaufen?'),
        content: Text('Das bringt $erloes Gold. Dieser Wurf ist danach weg.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Behalten'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Verkaufen'),
          ),
        ],
      ),
    ),
  );
  if (bestaetigt != true || !context.mounted) return false;

  // **Erst im nächsten Bild ändern.** `showDialog` kehrt zurück, sobald
  // `Navigator.pop` gerufen wurde, und der Dialog wird zu dem Zeitpunkt
  // noch abgebaut (`docs/context/gotchas.md`).
  final fertig = Completer<bool>();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) {
      fertig.complete(false);
      return;
    }
    final vorherErrungen = achievementsBefore(ref);
    final vorherLevel = levelBefore(ref);
    final erhalten = ref.read(loadoutProvider.notifier).sell(copy.uid);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            erhalten == null
                ? 'Das besitzt du nicht.'
                : '${item.name} verkauft — $erhalten Gold zurück.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    fertig.complete(erhalten != null);
    if (erhalten == null) return;

    // Errungenschaften im Laden zahlen auch Erfahrung (ADR-0033), ein
    // Verkauf kann also einen Aufstieg auslösen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      unawaited(() async {
        await showAchievementUnlocks(context, ref, before: vorherErrungen);
        if (!context.mounted) return;
        await showLevelUp(context, ref, before: vorherLevel);
      }());
    });
  });
  return fertig.future;
}
