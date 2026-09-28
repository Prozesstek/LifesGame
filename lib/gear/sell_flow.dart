import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../achievements/show_achievement_unlock.dart';
import '../progression/show_level_up.dart';
import '../ui/holz.dart';
import '../ui/palette.dart';
import 'gear_controller.dart';

/// **Der einzige Weg, etwas zu verkaufen** (ADR-0048, ADR-0057,
/// Issue #88): ein Exemplar oder alles Schlechtere, jeweils nach
/// Rückfrage, und danach wird gefeiert, was daraus folgt.
///
/// Bis zum 28.09. hatte der Laden denselben Weg noch einmal
/// (`ShopScreen._sell`). Seit der Laden nur noch verkauft, was es heute
/// gibt, und alles Besessene in der Ausrüstung steht, gibt es ihn nur
/// hier.

/// Verkauft ein Exemplar. Gibt zurück, ob verkauft wurde. Zurück kommt
/// ein Viertel des Preises, und der Wurf ist danach weg — deshalb die
/// Rückfrage.
Future<bool> sellWithConfirm(
  BuildContext context,
  WidgetRef ref,
  GearCopy copy,
) async {
  final item = copy.item;
  if (item == null) return false;
  final erloes = Loadout.refundFor(item);

  return _nachRueckfrage(
    context,
    ref,
    titel: '${item.name} verkaufen?',
    text: 'Das bringt $erloes Gold. Dieser Wurf ist danach weg.',
    verkaufe: () {
      final erhalten = ref.read(loadoutProvider.notifier).sell(copy.uid);
      return (
        ok: erhalten != null,
        meldung: erhalten == null
            ? 'Das besitzt du nicht.'
            : '${item.name} verkauft — $erhalten Gold zurück.',
      );
    },
  );
}

/// Verkauft alles Schlechtere auf einmal (`Loadout.junk`): was nicht
/// getragen wird und schwächer ist als das Getragene. Set-Teile,
/// Episches und Legendäres bleiben.
Future<bool> sellJunkWithConfirm(BuildContext context, WidgetRef ref) {
  final ausschuss = ref.read(loadoutProvider).junk;
  final anzahl = ausschuss.length;
  final erloes = junkRefund(ausschuss);

  return _nachRueckfrage(
    context,
    ref,
    titel: '$anzahl Stück verkaufen?',
    text:
        'Alles, was nicht getragen wird und schwächer ist als das '
        'Getragene. Set-Teile, Episches und Legendäres bleiben. '
        'Das bringt $erloes Gold.',
    verkaufe: () {
      final erhalten = ref.read(loadoutProvider.notifier).sellJunk();
      return (
        ok: true,
        meldung: '$anzahl Stück verkauft — $erhalten Gold zurück.',
      );
    },
  );
}

/// Was der Ausschuss beim Verkauf einbringt.
int junkRefund(List<GearCopy> ausschuss) => ausschuss.fold<int>(
  0,
  (s, c) => s + (c.item == null ? 0 : Loadout.refundFor(c.item!)),
);

Future<bool> _nachRueckfrage(
  BuildContext context,
  WidgetRef ref, {
  required String titel,
  required String text,
  required ({bool ok, String meldung}) Function() verkaufe,
}) async {
  final bestaetigt = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => HolzDialog(
      child: AlertDialog(
        backgroundColor: Palette.surface,
        title: Text(titel),
        content: Text(text),
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
    final ergebnis = verkaufe();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(ergebnis.meldung),
          duration: const Duration(seconds: 2),
        ),
      );
    fertig.complete(ergebnis.ok);
    if (!ergebnis.ok) return;

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
