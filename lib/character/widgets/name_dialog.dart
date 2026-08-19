import 'package:flutter/material.dart';
import 'package:identity/identity.dart';

import '../../ui/palette.dart';

/// Fragt nach dem Namen des Charakters.
///
/// Gibt den neuen Namen zurück — oder null, wenn abgebrochen wurde. Die
/// Länge begrenzt [Identity.maxNameLength]; kürzen und Leerraum entfernen
/// tut `Identity.withName`, damit die Regel an einer Stelle steht und nicht
/// in jedem Eingabefeld noch einmal.
Future<String?> showNameDialog(
  BuildContext context, {
  required String current,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _NameDialog(current: current),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.current});

  final String current;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.current,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.surfaceRaised,
      title: const Text('Wie heißt du?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: Identity.maxNameLength,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: Identity.fallbackName,
              border: OutlineInputBorder(),
            ),
          ),
          const Text(
            'Der Name steht auf dem Charakterbildschirm. Ändern kannst du '
            'ihn jederzeit.',
            style: TextStyle(fontSize: 12, color: Palette.textDim),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Übernehmen')),
      ],
    );
  }
}
