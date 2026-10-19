import 'package:flutter/material.dart';

import '../ui/holz.dart';
import '../ui/palette.dart';

/// Die Rückfrage, bevor ein laufender Lauf verlassen wird — **eine Stelle**
/// für die Grube und die Tagesgrube.
///
/// **Auf Android ist „Zurück“ eine Geste vom Bildschirmrand**, und das
/// Steuerkreuz nimmt den ganzen Bildschirm ein. Ohne Rückfrage beendete
/// ein Daumen, der zu weit links ansetzt, den Lauf.
///
/// **Der Lauf hält an, solange die Frage steht** — sonst fiele der Held,
/// während man sie liest. Gibt `true` zurück, wenn gegangen wird; dann
/// bleibt er angehalten.
Future<bool> fragtVorDemGehen(
  BuildContext context, {
  required void Function() anhalten,
  required void Function() weiter,
  required String titel,
  required String satz,
  required String gehen,
  required Key gehenKey,
  required Key bleibenKey,
}) async {
  anhalten();
  final geht = await showDialog<bool>(
    context: context,
    builder: (context) => HolzDialog(
      child: AlertDialog(
        backgroundColor: Palette.surface,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(),
        title: Text(titel),
        content: Text(satz),
        actions: <Widget>[
          TextButton(
            key: gehenKey,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(gehen),
          ),
          FilledButton(
            key: bleibenKey,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Weiterkämpfen'),
          ),
        ],
      ),
    ),
  );
  if (geht ?? false) return true;
  weiter();
  return false;
}
