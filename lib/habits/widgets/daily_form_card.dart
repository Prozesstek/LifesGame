import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../daily_form_text.dart';

/// **Die Tagesform** über der Tagesliste: was die heutigen Häkchen in der
/// Grube bringen, und was zu „In Form" noch fehlt.
///
/// Sie steht da, damit das Abhaken einen Grund im Kampf hat, den man
/// **vor** dem Tippen sieht — „Angriff +10 %" statt nur „+15 Erfahrung".
class DailyFormCard extends StatelessWidget {
  const DailyFormCard({required this.form, required this.open, super.key});

  final DailyForm form;

  /// Wie viele laufende Gewohnheiten heute noch offen sind.
  final int open;

  @override
  Widget build(BuildContext context) {
    final summe = DailyFormText.summary(form);
    final alle = DailyFormText.percent(1 + HabitRewards.formAllDone);
    final einer = DailyFormText.percent(1 + HabitRewards.formPerCheck);

    final titel = form.isInForm ? 'In Form' : 'Tagesform';
    final zeile = summe ?? 'Noch nichts — jedes Häkchen gibt heute $einer';
    final darunter = form.isInForm
        ? 'Alles erledigt. So gehst du heute in die Grube.'
        : open == 1
        ? 'Noch eine bis „In Form": $alle auf alles.'
        : 'Noch $open bis „In Form": $alle auf alles.';

    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      edgeColor: form.isInForm ? Palette.accent : Holz.kante,
      child: Row(
        children: <Widget>[
          Icon(
            form.isInForm ? Icons.local_fire_department : Icons.bolt,
            color: form.isInForm ? Palette.accent : Palette.textDim,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  titel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Palette.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  zeile,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: summe == null ? Palette.textDim : Palette.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  darunter,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Palette.textDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
