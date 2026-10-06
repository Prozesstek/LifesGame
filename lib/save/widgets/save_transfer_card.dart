import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../save_data.dart';
import '../save_providers.dart';
import '../save_watcher.dart';

/// **Den Spielstand sichern** — als Text kopieren und wieder einfügen
/// (ADR-0054).
///
/// **Warum es das braucht.** Der Stand liegt nur im Speicher des
/// Browsers. Wer die Browserdaten löscht — oder wessen Handy sie von
/// selbst räumt —, verliert jede Streak und jedes Häkchen, ohne Warnung.
/// Ein Text in einer Notiz ist die einfachste Sicherung, die ohne Server
/// auskommt.
class SaveTransferCard extends ConsumerWidget {
  const SaveTransferCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HolzKarte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Diskette, Kopieren, Einfügen. Warum man das braucht, sagt ein
          // Tipp auf die Diskette; was Einfügen tut, fragt der Dialog.
          Row(
            children: <Widget>[
              const Tooltip(
                triggerMode: TooltipTriggerMode.tap,
                message:
                    'Spielstand sichern: Dein Fortschritt liegt nur auf '
                    'diesem Gerät. Wer die Browserdaten löscht, verliert '
                    'ihn. Kopier ihn ab und zu in eine Notiz — einfügen '
                    'holt ihn zurück.',
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.save_outlined,
                    size: 26,
                    color: Palette.accent,
                    semanticLabel: 'Spielstand sichern',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _kopieren(context, ref),
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 20,
                    semanticLabel: 'Kopieren',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => spielstandEinfuegen(context, ref),
                  child: const Icon(
                    Icons.content_paste_rounded,
                    size: 20,
                    semanticLabel: 'Einfügen',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _kopieren(BuildContext context, WidgetRef ref) async {
    final text = currentSave(ref).encode();
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Spielstand kopiert — leg ihn in eine Notiz.'),
      ),
    );
  }
}

/// Fragt nach einem gesicherten Stand und setzt ihn ein.
///
/// **Eine freie Funktion, weil es zwei Wege hierher gibt:** die Karte im
/// Charakter und die erste Frage auf der Startseite (ADR-0068). Wer auf
/// einem neuen Gerät anfängt, hat noch keinen Charakter-Kreis und käme
/// sonst nicht an seinen Stand.
Future<void> spielstandEinfuegen(BuildContext context, WidgetRef ref) async {
  final neu = await showDialog<SaveData>(
    context: context,
    builder: (_) => const HolzDialog(child: _EinfuegenDialog()),
  );
  if (neu == null || !context.mounted) return;

  final alt = currentSave(ref);
  final ersetzen = await showDialog<bool>(
    context: context,
    builder: (context) => HolzDialog(
      child: AlertDialog(
        backgroundColor: Palette.surfaceRaised,
        title: const Text('Stand ersetzen?'),
        content: Text(
          'Jetzt: ${_kurz(alt)}\n'
          'Eingefügt: ${_kurz(neu)}\n\n'
          'Der jetzige Stand liegt danach in der Zwischenablage — falls '
          'du doch zurückwillst.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ersetzen'),
          ),
        ],
      ),
    ),
  );
  if (ersetzen != true || !context.mounted) return;

  // Der alte Stand wandert in die Zwischenablage, **bevor** er ersetzt
  // wird: Ein Irrtum ist so ein Einfügen entfernt, nicht verloren.
  await Clipboard.setData(ClipboardData(text: alt.encode()));
  if (!context.mounted) return;
  await ref.read(saveImporterProvider)(neu);
}

/// Was zwei Stände unterscheidet, in einer Zeile.
String _kurz(SaveData stand) {
  final haekchen = stand.habits.totalChecks;
  final gewohnheiten = stand.habits.activeIds.length;
  return '$haekchen Häkchen, $gewohnheiten laufende Gewohnheiten';
}

/// Ein Feld zum Einfügen; gibt den gelesenen Stand zurück.
class _EinfuegenDialog extends StatefulWidget {
  const _EinfuegenDialog();

  @override
  State<_EinfuegenDialog> createState() => _EinfuegenDialogState();
}

class _EinfuegenDialogState extends State<_EinfuegenDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _fehler;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pruefen() {
    final stand = SaveData.tryImport(_controller.text);
    if (stand == null) {
      setState(() => _fehler = 'Das ist kein Spielstand aus Lifes Game.');
      return;
    }
    Navigator.of(context).pop(stand);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.surfaceRaised,
      title: const Text('Spielstand einfügen'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        style: const TextStyle(fontSize: 11),
        decoration: InputDecoration(
          hintText: 'Den kopierten Text hier einfügen',
          errorText: _fehler,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _pruefen, child: const Text('Weiter')),
      ],
    );
  }
}
