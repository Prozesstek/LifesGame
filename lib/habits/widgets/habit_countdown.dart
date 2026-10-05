import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../habits_controller.dart';

/// Wo der Timer einer Gewohnheit gerade steht (ADR-0067).
///
/// Rechnet nichts selbst: Die Sekunden kommen aus
/// `HabitTracker.timedSecondsOn`, hier werden sie nur lesbar.
class HabitClock {
  const HabitClock({
    required this.doneSeconds,
    required this.totalSeconds,
    required this.isRunning,
  });

  final int doneSeconds;
  final int totalSeconds;
  final bool isRunning;

  int get remainingSeconds => totalSeconds - doneSeconds;

  /// Ob schon Zeit gelaufen ist — dann heißt der Knopf „weiter“.
  bool get hasStarted => doneSeconds > 0;

  double get fraction {
    return totalSeconds <= 0 ? 0 : (doneSeconds / totalSeconds).clamp(0, 1);
  }

  /// Die Restzeit als „07:42“.
  String get label {
    final rest = remainingSeconds < 0 ? 0 : remainingSeconds;
    final minuten = (rest ~/ 60).toString().padLeft(2, '0');
    final sekunden = (rest % 60).toString().padLeft(2, '0');
    return '$minuten:$sekunden';
  }

  /// Dasselbe für den Vorleser.
  String get semanticLabel {
    final rest = remainingSeconds < 0 ? 0 : remainingSeconds;
    return 'Noch ${rest ~/ 60} Minuten und ${rest % 60} Sekunden';
  }
}

/// Zeigt den Timer von [habit] und tickt, solange er läuft.
///
/// **Eine Stelle für jede Anzeige**: Blatt, Kachel und „Heute“ bauen ihr
/// Bild über [builder] aus derselben [HabitClock]. Der Sekundentakt
/// läuft nur, während der Timer läuft — eine Liste ruhender Gewohnheiten
/// hält keinen einzigen wach.
///
/// Die Zeit kommt aus `clockProvider`, nicht aus dem Takt: Der Takt sagt
/// nur „schau noch einmal hin“. Wird er im Hintergrund gedrosselt,
/// stimmt die Anzeige beim nächsten Hinsehen trotzdem.
class HabitCountdown extends ConsumerStatefulWidget {
  const HabitCountdown({
    required this.habit,
    required this.builder,
    this.onDone,
    super.key,
  });

  final Habit habit;
  final Widget Function(BuildContext context, HabitClock clock) builder;

  /// Gerufen, wenn der laufende Timer bei null ankommt — einmal. Wer
  /// daraufhin abhakt und feiert, tut das mit **seinem** Kontext: Dieses
  /// Widget verschwindet mit dem Häkchen.
  final VoidCallback? onDone;

  @override
  ConsumerState<HabitCountdown> createState() => _HabitCountdownState();
}

class _HabitCountdownState extends ConsumerState<HabitCountdown> {
  Timer? _takt;
  bool _gemeldet = false;

  @override
  void dispose() {
    _takt?.cancel();
    super.dispose();
  }

  void _stelleTakt(bool laeuft) {
    if (!laeuft) {
      _takt?.cancel();
      _takt = null;
      _gemeldet = false;
      return;
    }
    _takt ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _meldeEnde() {
    if (_gemeldet) return;
    _gemeldet = true;
    // Einen Bildaufbau später: Abhaken ändert Zustand, und das darf
    // nicht mitten im Bauen passieren (`gotchas.md`).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onDone?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tracker = ref.watch(habitTrackerProvider);
    final heute = ref.watch(todayProvider);
    final jetzt = ref.watch(clockProvider)();
    final id = widget.habit.id;

    final tag = tracker.timerDayFor(id, heute);
    final uhr = HabitClock(
      doneSeconds: tracker.timedSecondsOn(id, tag, jetzt),
      totalSeconds: tracker.requiredFor(id) * 60,
      isRunning: tracker.timerFor(id, tag)?.isRunning ?? false,
    );

    _stelleTakt(uhr.isRunning);
    if (uhr.isRunning && uhr.remainingSeconds <= 0) _meldeEnde();

    return widget.builder(context, uhr);
  }
}
