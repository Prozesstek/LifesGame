import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/druck.dart';
import '../ui/palette.dart';
import 'sammlung.dart';
import 'sammlung_provider.dart';
import 'sammlung_screen.dart';

/// Der Weg in die Sammlung, oben rechts in Ausrüstung und Fähigkeiten
/// (Issues #137, #138): ein Zeichen und wie viel dieses Reiters man hat.
///
/// **Kein `IconButton`**: Das Theme macht jeden zur Holzplanke, und in
/// der Kopfzeile läse sich eine Planke als Hauptknopf.
class SammlungKnopf extends ConsumerWidget {
  const SammlungKnopf({required this.art, super.key});

  /// Der Reiter, der beim Öffnen offen ist.
  final SammelArt art;

  static const Key knopfKey = ValueKey<String>('sammlung-knopf');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prozent = ref.watch(sammelStandProvider(art)).prozent;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        label: 'Sammlung, $prozent Prozent',
        excludeSemantics: true,
        child: Druck(
          child: InkWell(
            key: knopfKey,
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SammlungScreen(anfang: art),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.collections_bookmark_outlined,
                    size: 22,
                    color: Palette.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$prozent %',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Palette.accent,
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
