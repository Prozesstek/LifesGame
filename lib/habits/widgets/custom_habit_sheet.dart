import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habits/habits.dart';

import '../../ui/palette.dart';

/// Was das Formular liefert, wenn es geschlossen wird.
///
/// Bewusst ohne Id: Die vergibt der Controller, weil nur der Spielstand
/// weiß, welche schon vergeben sind.
class CustomHabitDraft {
  const CustomHabitDraft({
    required this.name,
    required this.stat,
    required this.difficulty,
    required this.priority,
    this.goal,
    this.why = '',
  });

  final String name;
  final HabitStat stat;
  final HabitDifficulty difficulty;
  final HabitPriority priority;
  final HabitGoal? goal;
  final String why;
}

/// Das Formular für eine eigene Gewohnheit.
///
/// Öffnet als Blatt von unten und gibt einen [CustomHabitDraft] zurück —
/// oder null, wenn abgebrochen wurde. Es kennt **keine** Provider: So
/// lässt es sich ohne Spielstand prüfen, und die Entscheidung „darf noch
/// eine dazu?" bleibt an einer Stelle, im Controller.
class CustomHabitSheet extends StatefulWidget {
  const CustomHabitSheet({super.key});

  /// Öffnet das Blatt. Null, wenn nichts angelegt wurde.
  static Future<CustomHabitDraft?> show(BuildContext context) {
    return showModalBottomSheet<CustomHabitDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => const CustomHabitSheet(),
    );
  }

  @override
  State<CustomHabitSheet> createState() => _CustomHabitSheetState();
}

/// Welche Art Tagesziel das Formular gerade anbietet.
enum _GoalChoice {
  keins('Nur abhaken'),
  menge('Menge'),
  zeit('Zeit');

  const _GoalChoice(this.label);

  final String label;
}

class _CustomHabitSheetState extends State<CustomHabitSheet> {
  final _name = TextEditingController();
  final _why = TextEditingController();
  final _amount = TextEditingController(text: '5');
  final _unit = TextEditingController(text: 'Mal');
  final _minutes = TextEditingController(text: '10');

  HabitStat _stat = HabitStat.staerke;
  HabitDifficulty _difficulty = HabitDifficulty.mittel;
  HabitPriority _priority = HabitPriority.normal;
  _GoalChoice _goalChoice = _GoalChoice.keins;

  @override
  void initState() {
    super.initState();
    // Der Knopf lebt davon, ob ein Name dasteht.
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _why.dispose();
    _amount.dispose();
    _unit.dispose();
    _minutes.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty;

  HabitGoal? get _goal {
    return switch (_goalChoice) {
      _GoalChoice.keins => null,
      _GoalChoice.menge => HabitGoal.menge(
        target: int.tryParse(_amount.text.trim()) ?? 1,
        unit: _unit.text,
      ),
      _GoalChoice.zeit => HabitGoal.zeit(
        target: int.tryParse(_minutes.text.trim()) ?? 1,
      ),
    };
  }

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(
      CustomHabitDraft(
        name: _name.text,
        stat: _stat,
        difficulty: _difficulty,
        priority: _priority,
        goal: _goal,
        why: _why.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Sonst verdeckt die Tastatur genau das Feld, in das getippt wird.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const _Grip(),
              const SizedBox(height: 14),
              const Text(
                'Eigene Gewohnheit',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sie zählt wie jede andere: Häkchen, Streak, Charakterwert. '
                'Wert, Schwierigkeit und Ziel stehen danach fest.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Palette.textDim,
                ),
              ),
              const SizedBox(height: 18),

              _Field(
                controller: _name,
                label: 'Was tust du?',
                hint: 'Zehn Minuten Sport',
                maxLength: 60,
              ),
              const SizedBox(height: 14),

              const _Label('Worauf zahlt es ein?'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final stat in HabitStat.values)
                    _Chip(
                      label: '${stat.label} · ${stat.combatLabel}',
                      selected: _stat == stat,
                      onTap: () => setState(() => _stat = stat),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              const _Label('Wie schwer fällt es dir?'),
              const SizedBox(height: 4),
              const Text(
                'Ändert nur die Erfahrung, nicht das Gold.',
                style: TextStyle(fontSize: 11, color: Palette.muted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final level in HabitDifficulty.values)
                    _Chip(
                      label: '${level.label} · ${_xpLabel(level)}',
                      selected: _difficulty == level,
                      onTap: () => setState(() => _difficulty = level),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              const _Label('Tagesziel'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final choice in _GoalChoice.values)
                    _Chip(
                      label: choice.label,
                      selected: _goalChoice == choice,
                      onTap: () => setState(() => _goalChoice = choice),
                    ),
                ],
              ),
              if (_goalChoice == _GoalChoice.menge) ...<Widget>[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _Field(
                        controller: _amount,
                        label: 'Wie viele?',
                        hint: '5',
                        numeric: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _Field(
                        controller: _unit,
                        label: 'Wovon?',
                        hint: 'Gläser',
                        maxLength: 20,
                      ),
                    ),
                  ],
                ),
              ],
              if (_goalChoice == _GoalChoice.zeit) ...<Widget>[
                const SizedBox(height: 12),
                _Field(
                  controller: _minutes,
                  label: 'Wie viele Minuten?',
                  hint: '10',
                  numeric: true,
                ),
                const SizedBox(height: 6),
                Text(
                  'Ein Tippen zählt ${HabitGoal.zeitSchritt} Minuten dazu.',
                  style: const TextStyle(fontSize: 11, color: Palette.muted),
                ),
              ],
              const SizedBox(height: 16),

              const _Label('Wie wichtig ist es dir?'),
              const SizedBox(height: 4),
              const Text(
                'Nur für dich — sie sortiert die Liste und ändert sonst '
                'nichts.',
                style: TextStyle(fontSize: 11, color: Palette.muted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final level in HabitPriority.values)
                    _Chip(
                      label: level.label,
                      selected: _priority == level,
                      onTap: () => setState(() => _priority = level),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              _Field(
                controller: _why,
                label: 'Warum? (freiwillig)',
                hint: 'Damit der Morgen steht.',
                maxLength: 140,
                lines: 2,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canSave ? _save : null,
                  child: const Text('Anlegen'),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// „+30 %" statt „x1,3" — der Spieler soll nicht rechnen müssen.
  static String _xpLabel(HabitDifficulty difficulty) {
    final prozent = ((difficulty.xpFactor - 1) * 100).round();
    if (prozent == 0) return 'Erfahrung wie üblich';
    return '${prozent > 0 ? '+' : ''}$prozent % Erfahrung';
  }
}

class _Grip extends StatelessWidget {
  const _Grip();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Palette.muted,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.numeric = false,
    this.maxLength,
    this.lines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool numeric;
  final int? maxLength;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: lines,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: numeric
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : null,
      style: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        isDense: true,
        labelStyle: const TextStyle(fontSize: 13, color: Palette.textDim),
        hintStyle: const TextStyle(fontSize: 13, color: Palette.muted),
        filled: true,
        fillColor: Palette.surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Palette.accent : Palette.surfaceRaised,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : Palette.textDim,
            ),
          ),
        ),
      ),
    );
  }
}
