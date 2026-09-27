import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';

/// Fragt, **wann** eine Gewohnheit drankommt (ADR-0052).
///
/// Gibt den Auslöser zurück — oder null, wenn abgebrochen wurde. Ein
/// leerer Text heißt „entfernen". Kürzen und Leerraum entfernen tut
/// `HabitTracker.setCue`, damit die Regel an einer Stelle steht.
///
/// **Warum das eine Frage ist und kein Pflichtfeld.** Ein Vorsatz, der an
/// eine Situation gebunden ist, wird deutlich zuverlässiger umgesetzt als
/// einer ohne — die Handbuch-Lektion „Die Schleife hinter jeder
/// Gewohnheit" sagt es selbst. Wer nicht will, tippt „Später" und hat
/// dieselbe Gewohnheit wie vorher.
Future<String?> showCueDialog(
  BuildContext context, {
  required String habitName,
  String? current,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => HolzDialog(
      child: _CueDialog(habitName: habitName, current: current),
    ),
  );
}

/// Vorschläge zum Antippen — alles Dinge, die ohnehin jeden Tag
/// passieren. Ankoppeln statt neu erfinden.
const List<String> cueSuggestions = <String>[
  'Nach dem Aufstehen',
  'Nach dem Zähneputzen',
  'Nach dem Frühstück',
  'Nach dem Mittagessen',
  'Auf dem Heimweg',
  'Vor dem Schlafengehen',
];

class _CueDialog extends StatefulWidget {
  const _CueDialog({required this.habitName, this.current});

  final String habitName;
  final String? current;

  @override
  State<_CueDialog> createState() => _CueDialogState();
}

class _CueDialogState extends State<_CueDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.current ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    final hatteEinen = widget.current != null;

    return AlertDialog(
      backgroundColor: Palette.surfaceRaised,
      title: const Text('Wann machst du das?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '„${widget.habitName}" — häng es an etwas, das du ohnehin '
              'jeden Tag tust.',
              style: const TextStyle(fontSize: 13, color: Palette.textDim),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLength: HabitTracker.maxCueLength,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: 'Nach dem Zähneputzen',
                border: OutlineInputBorder(),
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final vorschlag in cueSuggestions)
                  Druck(
                    child: ActionChip(
                      label: Text(
                        vorschlag,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => setState(() {
                        _controller.text = vorschlag;
                      }),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        if (hatteEinen)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('Entfernen'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(hatteEinen ? 'Abbrechen' : 'Später'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Festlegen')),
      ],
    );
  }
}
