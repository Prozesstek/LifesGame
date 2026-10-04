import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../habits_controller.dart';
import 'habit_countdown.dart';

/// Wie das Timer-Blatt zugegangen ist — wenn es etwas abzuhaken gibt.
enum HabitTimerEnde {
  /// „Schon erledigt“: von Hand, ohne die Zeit abzuwarten.
  erledigt,

  /// Der Timer ist bei null angekommen.
  abgelaufen,
}

/// Öffnet den Timer von [habit] (ADR-0067).
///
/// Null, wenn das Blatt nur geschlossen wurde. Der Timer läuft dann
/// weiter oder steht, wie er war — das Blatt ist eine Anzeige, kein
/// Zustand.
///
/// **Abgehakt wird nicht hier.** Das Blatt meldet nur, wie es zuging;
/// Klang, Feier und aufsteigende Zahlen gehören dem, der es geöffnet hat
/// (`habit_check_flow.dart`), denn sein Kontext lebt noch, wenn das Blatt
/// längst zu ist.
Future<HabitTimerEnde?> showHabitTimerSheet(BuildContext context, Habit habit) {
  return showModalBottomSheet<HabitTimerEnde>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (_) => HolzBlatt(child: HabitTimerSheet(habit: habit)),
  );
}

class HabitTimerSheet extends ConsumerStatefulWidget {
  const HabitTimerSheet({required this.habit, super.key});

  static const Key startKey = ValueKey<String>('timer-start');
  static const Key pauseKey = ValueKey<String>('timer-pause');
  static const Key doneKey = ValueKey<String>('timer-erledigt');
  static const Key closeKey = ValueKey<String>('timer-schliessen');

  /// Wie groß der Ring ist.
  static const double ringSize = 190;

  final Habit habit;

  @override
  ConsumerState<HabitTimerSheet> createState() => _HabitTimerSheetState();
}

class _HabitTimerSheetState extends ConsumerState<HabitTimerSheet> {
  bool _zu = false;

  /// **Nur einmal schließen.** Der Timer kann an zwei Stellen zugleich
  /// ablaufen — hier und auf der Kachel darunter —, und ein zweites
  /// `pop` nähme den Bildschirm darunter mit.
  void _schliesse([HabitTimerEnde? ende]) {
    if (_zu || !mounted) return;
    _zu = true;
    Navigator.of(context).pop(ende);
  }

  void _start() {
    ref.read(habitTrackerProvider.notifier).startTimer(widget.habit.id);
  }

  void _pause() {
    ref.read(habitTrackerProvider.notifier).pauseTimer();
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;

    // Hat die Kachel darunter schon abgehakt, gibt es hier nichts mehr
    // zu zeigen.
    ref.listen(habitTrackerProvider, (_, tracker) {
      if (tracker.isChecked(habit.id, ref.read(todayProvider))) _schliesse();
    });

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: HabitCountdown(
          habit: habit,
          onDone: () => _schliesse(HabitTimerEnde.abgelaufen),
          builder: (context, uhr) => Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                habit.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Palette.text,
                ),
              ),
              const SizedBox(height: 16),
              _Ring(uhr: uhr),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _Nebenknopf(
                    key: HabitTimerSheet.doneKey,
                    icon: Icons.check_rounded,
                    tooltip: 'Schon erledigt',
                    color: Palette.success,
                    onTap: () => _schliesse(HabitTimerEnde.erledigt),
                  ),
                  _Hauptknopf(
                    laeuft: uhr.isRunning,
                    onTap: uhr.isRunning ? _pause : _start,
                  ),
                  _Nebenknopf(
                    key: HabitTimerSheet.closeKey,
                    icon: Icons.keyboard_arrow_down_rounded,
                    tooltip: uhr.isRunning
                        ? 'Schließen — der Timer läuft weiter'
                        : 'Schließen',
                    color: Palette.textDim,
                    onTap: _schliesse,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Der Ring, der sich füllt, mit der Restzeit in der Mitte.
class _Ring extends StatelessWidget {
  const _Ring({required this.uhr});

  final HabitClock uhr;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: HabitTimerSheet.ringSize,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: <Widget>[
          CircularProgressIndicator(
            value: uhr.fraction,
            strokeWidth: 12,
            strokeCap: StrokeCap.round,
            backgroundColor: Palette.surfaceSunken,
            valueColor: AlwaysStoppedAnimation<Color>(
              uhr.isRunning ? Palette.accent : Palette.muted,
            ),
          ),
          // Schrumpft, statt umzubrechen: Mit großer Schrift stünde
          // „12:“ über „42“.
          Padding(
            padding: const EdgeInsets.all(24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                uhr.label,
                semanticsLabel: uhr.semanticLabel,
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: uhr.isRunning ? Palette.text : Palette.textDim,
                  // Gleich breite Ziffern, sonst zittert die Zahl bei
                  // jedem Sekundenwechsel.
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Start oder Pause — der eine große Knopf.
class _Hauptknopf extends StatelessWidget {
  const _Hauptknopf({required this.laeuft, required this.onTap});

  final bool laeuft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Druck(
      child: Material(
        color: Palette.accent,
        shape: const CircleBorder(),
        child: InkWell(
          key: laeuft ? HabitTimerSheet.pauseKey : HabitTimerSheet.startKey,
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 68,
            child: Icon(
              laeuft ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 38,
              color: Palette.surface,
              semanticLabel: laeuft ? 'Anhalten' : 'Starten',
            ),
          ),
        ),
      ),
    );
  }
}

/// Die zwei kleinen Knöpfe daneben: von Hand abhaken, schließen.
class _Nebenknopf extends StatelessWidget {
  const _Nebenknopf({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Druck(
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        iconSize: 30,
        color: color,
        style: IconButton.styleFrom(
          backgroundColor: Palette.surfaceRaised,
          fixedSize: const Size.square(52),
        ),
        icon: Icon(icon),
      ),
    );
  }
}
