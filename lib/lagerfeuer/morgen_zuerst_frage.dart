import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../habits/habits_controller.dart';
import '../ui/holz.dart';
import '../ui/on_dark.dart';
import '../ui/palette.dart';
import 'widgets/feuer_bild.dart';
import 'widgets/morgen_zuerst.dart';

/// **„Morgen zuerst“ gleich nach dem geschafften Tag** (29.10.2026).
///
/// Wer die letzte Gewohnheit abhakt, wird gefeiert — und danach fragt
/// das Feuer, was morgen zuerst drankommt. Dieselbe Wahl wie am
/// Lagerfeuer (ADR-0076), nur dort, wo der Tag gerade endet.
///
/// Gefragt wird nur, wenn morgen **mindestens zwei** fällig sind — bei
/// einer gibt es nichts zu wählen — und noch nichts gewählt ist: Wer am
/// Feuer schon gewählt hat, wird nicht zweimal gefragt.
Future<void> frageMorgenZuerst(BuildContext context, WidgetRef ref) async {
  final morgen = ref.read(todayProvider).next;
  final tracker = ref.read(habitTrackerProvider);
  if (tracker.firstUpOn(morgen) != null) return;
  final faellig = morgenFaellig(tracker, morgen);
  if (faellig.length < 2 || !context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (dialog) => HolzDialog(
      child: MorgenZuerstFrage(habits: faellig, morgen: morgen),
    ),
  );
}

/// Was an [morgen] fällig ist — in der Reihenfolge **ohne** Vorsatz,
/// damit die Knöpfe beim Wählen stehen bleiben (`MorgenZuerst`).
List<Habit> morgenFaellig(HabitTracker tracker, Day morgen) => <Habit>[
  for (final habit in tracker.activeHabitsByPriority)
    if (tracker.isDueOn(habit.id, morgen)) habit,
];

/// Der Dialog: oben das Feuer, darunter die Knöpfe. Ein Tipp wählt, und
/// kurz darauf geht er zu — man sieht die Flamme am Gewählten noch.
class MorgenZuerstFrage extends ConsumerStatefulWidget {
  const MorgenZuerstFrage({
    required this.habits,
    required this.morgen,
    super.key,
  });

  final List<Habit> habits;
  final Day morgen;

  /// Wie lange die Wahl stehen bleibt, bevor der Dialog zugeht.
  static const Duration nachhall = Duration(milliseconds: 450);

  static const Key spaeterKey = ValueKey<String>('morgen-zuerst-spaeter');

  @override
  ConsumerState<MorgenZuerstFrage> createState() => _MorgenZuerstFrageState();
}

class _MorgenZuerstFrageState extends ConsumerState<MorgenZuerstFrage> {
  Timer? _zu;

  @override
  void dispose() {
    _zu?.cancel();
    super.dispose();
  }

  void _waehle(String? id) {
    ref.read(habitTrackerProvider.notifier).setFirstUp(widget.morgen, id);
    _zu?.cancel();
    if (id == null) return;
    _zu = Timer(MorgenZuerstFrage.nachhall, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gewaehlt = ref.watch(habitTrackerProvider).firstUpOn(widget.morgen);
    return Material(
      color: Palette.background,
      child: OnDark(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Stack(
                children: <Widget>[
                  const FeuerBild(brennt: true, hoehe: 140),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      key: MorgenZuerstFrage.spaeterKey,
                      tooltip: 'Später',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Palette.textOnDarkDim,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: MorgenZuerst(
                  habits: widget.habits,
                  gewaehlt: gewaehlt,
                  onWaehle: _waehle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
