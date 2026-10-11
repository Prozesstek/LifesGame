import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';

import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../../ui/ruhm_zahl.dart';
import '../tagesgrube_text.dart';
import 'raumzeile.dart';
import 'teilen_knopf.dart';

/// Das Blatt am Ende der Tagesgrube (ADR-0072): wie es lief, was es an
/// Ruhm bringt, und der Knopf zum Teilen.
///
/// Derselbe Aufbau wie `LaufErgebnis`, aber ohne Erfahrung und Gold — die
/// Tagesgrube zahlt keins von beiden. Dafür steht hier, was im geteilten
/// Text steht, als Bild: Raumzeile, Zeit, Verfassung, Tageskette.
class TagesgrubeErgebnis extends StatelessWidget {
  const TagesgrubeErgebnis({
    required this.number,
    required this.run,
    required this.dayStreak,
    super.key,
  });

  final int number;
  final DailyRun run;

  /// Die Tageskette, wie sie im Text steht.
  final int dayStreak;

  /// Woran Tests die Knöpfe finden.
  static const Key teilenKey = ValueKey<String>('tagesgrube-ergebnis-teilen');
  static const Key weiterKey = ValueKey<String>('tagesgrube-ergebnis-weiter');

  @override
  Widget build(BuildContext context) {
    final farbe = run.won ? Palette.success : Palette.enemy;
    final fussnote = run.won
        ? 'Die Tagesgrube bringt Ruhm, keine Erfahrung und kein Gold. '
              'Morgen wartet eine neue.'
        : 'Ein Versuch am Tag. Das kostet nichts — morgen wartet eine '
              'neue Grube.';

    return HolzDialog(
      child: AlertDialog(
        backgroundColor: Palette.surface,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(),
        title: Center(
          child: Tooltip(
            triggerMode: TooltipTriggerMode.tap,
            message: fussnote,
            child: Text(
              run.won ? 'Sieg' : 'Niederlage',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: farbe,
              ),
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Tagesgrube #$number',
              style: const TextStyle(fontSize: 15, color: Palette.textDim),
            ),
            const SizedBox(height: 14),
            Raumzeile(rooms: run.rooms, side: 30),
            const SizedBox(height: 14),
            TagesgrubeFakten(run: run, dayStreak: dayStreak),
            const SizedBox(height: 16),
            RuhmZahl(fame: run.fame, size: 24),
            const SizedBox(height: 20),
            TeilenKnopf(
              key: teilenKey,
              text: TagesgrubeText.teilen(
                number: number,
                run: run,
                dayStreak: dayStreak,
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              key: weiterKey,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Weiter'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zeit, Verfassung und Tageskette als Zeichen mit Zahl — dieselben drei
/// Angaben wie in der dritten Zeile des geteilten Texts.
class TagesgrubeFakten extends StatelessWidget {
  const TagesgrubeFakten({
    required this.run,
    required this.dayStreak,
    super.key,
  });

  final DailyRun run;
  final int dayStreak;

  static const TextStyle _ruhig = TextStyle(
    fontSize: 15,
    color: Palette.textDim,
  );

  @override
  Widget build(BuildContext context) {
    final zeit = TagesgrubeText.zeit(run.seconds);
    final verfassung = switch (run.condition) {
      DailyCondition.inForm => 'in Form',
      DailyCondition.ruhetag => 'Ruhetag',
      DailyCondition.ohneForm => 'ohne Form',
    };

    return Semantics(
      label:
          '$zeit, $verfassung'
          '${dayStreak > 0 ? ', $dayStreak Tage am Stück' : ''}',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            run.outcome == DailyOutcome.zeitAus
                ? Icons.timer_off_outlined
                : Icons.timer_outlined,
            size: 17,
            color: Palette.textDim,
          ),
          const SizedBox(width: 4),
          Text(zeit, style: _ruhig),
          if (run.condition != DailyCondition.ohneForm) ...<Widget>[
            const SizedBox(width: 14),
            Icon(
              run.condition == DailyCondition.inForm
                  ? Icons.bolt
                  : Icons.bedtime_outlined,
              size: 19,
              color: run.condition == DailyCondition.inForm
                  ? Palette.accent
                  : Palette.textDim,
            ),
          ],
          if (dayStreak > 0) ...<Widget>[
            const SizedBox(width: 14),
            const Icon(
              Icons.local_fire_department,
              size: 18,
              color: Palette.accent,
            ),
            const SizedBox(width: 2),
            Text('$dayStreak', style: _ruhig),
          ],
        ],
      ),
    );
  }
}
