import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import 'weekday_picker.dart';

/// Was im Dialog gewählt wurde: der Auslöser und die Wochentage.
class CueChoice {
  const CueChoice({required this.cue, required this.weekdays, this.anchorId});

  /// Leer heißt „entfernen".
  final String cue;

  /// Die Gewohnheit, nach der diese drankommt (ADR-0065) — oder null.
  /// Mit Anker ist [cue] leer: Es gibt einen Satz **oder** einen Anker.
  final String? anchorId;

  /// Wochentage wie bei `Day.weekday`, nie leer.
  final Set<int> weekdays;
}

/// Fragt, **wann** eine Gewohnheit drankommt: woran sie hängt — ein Satz
/// (ADR-0052) oder eine andere Gewohnheit (ADR-0065) — und an welchen
/// Wochentagen (ADR-0064).
///
/// Gibt die Wahl zurück — oder null, wenn abgebrochen wurde. Ein leerer
/// Auslöser heißt „entfernen". Kürzen und Leerraum entfernen tut
/// `HabitTracker.setCue`, ab wann die Wochentage gelten
/// `HabitTracker.setWeekdays` — damit jede Regel an einer Stelle steht.
///
/// **Warum das eine Frage ist und kein Pflichtfeld.** Ein Vorsatz, der an
/// eine Situation gebunden ist, wird deutlich zuverlässiger umgesetzt als
/// einer ohne — die Handbuch-Lektion „Die Schleife hinter jeder
/// Gewohnheit" sagt es selbst. Wer nicht will, tippt „Später" und hat
/// dieselbe Gewohnheit wie vorher.
Future<CueChoice?> showCueDialog(
  BuildContext context, {
  required String habitName,
  required Set<int> weekdays,
  required bool weekdaysFromTomorrow,
  List<Habit> anchors = const <Habit>[],
  String? currentAnchorId,
  String? current,
}) {
  return showDialog<CueChoice>(
    context: context,
    builder: (context) => HolzDialog(
      child: _CueDialog(
        habitName: habitName,
        current: current,
        weekdays: weekdays,
        weekdaysFromTomorrow: weekdaysFromTomorrow,
        anchors: anchors,
        currentAnchorId: currentAnchorId,
      ),
    ),
  );
}

/// Woran ein Test den Knopf findet, der an [habitId] koppelt.
Key cueAnchorKey(String habitId) => ValueKey<String>('anker-$habitId');

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
  const _CueDialog({
    required this.habitName,
    required this.weekdays,
    required this.weekdaysFromTomorrow,
    required this.anchors,
    this.currentAnchorId,
    this.current,
  });

  /// Woran sich koppeln lässt — die laufenden Gewohnheiten ohne diese
  /// selbst und ohne alles, was einen Kreis schlösse
  /// (`HabitTracker.anchorCandidatesFor`).
  final List<Habit> anchors;
  final String? currentAnchorId;

  final String habitName;
  final String? current;
  final Set<int> weekdays;

  /// Ob eine Änderung der Wochentage erst morgen gilt — dann sagt der
  /// Dialog es, sobald jemand daran dreht.
  final bool weekdaysFromTomorrow;

  @override
  State<_CueDialog> createState() => _CueDialogState();
}

class _CueDialogState extends State<_CueDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.current ?? '',
  );

  late String? _anchorId = widget.currentAnchorId;

  @override
  void initState() {
    super.initState();
    // Satz oder Anker: Wer tippt, löst die Kopplung.
    _controller.addListener(() {
      if (_anchorId != null && _controller.text.isNotEmpty) {
        setState(() => _anchorId = null);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _kopple(String habitId) {
    setState(() {
      _anchorId = _anchorId == habitId ? null : habitId;
      if (_anchorId != null) _controller.clear();
    });
  }

  late Set<int> _weekdays = <int>{...widget.weekdays};

  bool get _wochentageGeaendert =>
      _weekdays.length != widget.weekdays.length ||
      !_weekdays.containsAll(widget.weekdays);

  void _schliesse(String cue, {String? anchorId}) {
    Navigator.of(context).pop(
      CueChoice(
        cue: anchorId == null ? cue : '',
        weekdays: _weekdays,
        anchorId: anchorId,
      ),
    );
  }

  void _submit() => _schliesse(_controller.text, anchorId: _anchorId);

  @override
  Widget build(BuildContext context) {
    final hatteEinen = widget.current != null || widget.currentAnchorId != null;

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
              'tust, und wähle die Tage.',
              style: const TextStyle(fontSize: 13, color: Palette.textDim),
            ),
            const SizedBox(height: 12),
            WeekdayPicker(
              selected: _weekdays,
              onChanged: (tage) => setState(() => _weekdays = tage),
            ),
            if (widget.weekdaysFromTomorrow && _wochentageGeaendert)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Die Tage gelten ab morgen. Heute bleibt, wie es war.',
                  style: TextStyle(fontSize: 12, color: Palette.textDim),
                ),
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
            if (widget.anchors.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              const Text(
                'Oder direkt nach einer deiner Gewohnheiten:',
                style: TextStyle(fontSize: 13, color: Palette.textDim),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final habit in widget.anchors)
                    Druck(
                      child: ChoiceChip(
                        key: cueAnchorKey(habit.id),
                        // Die Farben der App statt des blassen Rosa, das
                        // Material für „gewählt" mitbringt.
                        showCheckmark: false,
                        selectedColor: Palette.accent,
                        avatar: Icon(
                          Icons.link_rounded,
                          size: 16,
                          color: _anchorId == habit.id
                              ? Palette.surface
                              : Palette.textDim,
                        ),
                        label: Text(
                          habit.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: _anchorId == habit.id
                                ? Palette.surface
                                : Palette.text,
                          ),
                        ),
                        selected: _anchorId == habit.id,
                        onSelected: (_) => _kopple(habit.id),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        if (hatteEinen)
          TextButton(
            onPressed: () => _schliesse(''),
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
