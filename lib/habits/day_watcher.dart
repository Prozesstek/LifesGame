import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import 'habits_controller.dart';

/// Hält „heute" aktuell, solange die App läuft.
///
/// **Warum es das braucht.** [todayProvider] liest die Uhr einmal und
/// behält den Tag. Wer die App über Mitternacht offen lässt, hakt sonst
/// auf dem gestrigen Tag ab — und eine grundlos gerissene Streak ist in
/// diesem Spiel der schlimmste denkbare Fehler (`konzept.md` 3.7).
///
/// **Drei Anlässe, auf die Uhr zu sehen:**
///
/// - **Genau um Mitternacht.** Sonst landete ein Häkchen kurz nach zwölf
///   noch auf dem alten Tag.
/// - **Mindestens jede Minute.** Ein einzelner Wecker auf Mitternacht
///   verpasst zwei Fälle: Ein schlafendes Handy lässt Timer nicht
///   zuverlässig weiterlaufen, und wer die Zeitzone wechselt oder die Uhr
///   stellt, verschiebt Mitternacht, nachdem der Wecker gestellt ist.
/// - **Wenn die App wieder in den Vordergrund kommt.** Morgens hervorgeholt
///   darf sie nicht erst eine Minute lang den gestrigen Tag zeigen.
///
/// **Warum ein Widget und kein Timer im Provider.** Ein Provider lebt so
/// lange wie sein Container, und viele Tests entsorgen den erst im
/// `tearDown` — ein Timer darin wäre noch offen, wenn Flutter nach dem
/// Test prüft, ob alle Timer beendet sind. Ein Widget endet mit dem Baum.
/// Der Preis ist derselbe wie beim `SaveWatcher`: Es muss in `main.dart`
/// unter dem `ProviderScope` hängen.
///
/// Neu gerechnet wird nur, wenn tatsächlich ein anderer Tag anbricht. Der
/// Minutentakt baut also keinen Bildschirm neu.
class DayWatcher extends ConsumerStatefulWidget {
  const DayWatcher({required this.child, super.key});

  final Widget child;

  /// Wie lange höchstens zwischen zwei Blicken auf die Uhr liegt.
  static const Duration checkInterval = Duration(minutes: 1);

  /// Wann nach [now] das nächste Mal nachgesehen wird: in einer Minute,
  /// oder um Mitternacht, falls die früher kommt.
  ///
  /// Mitternacht über den Kalender statt über `Duration(days: 1)`: Am Tag
  /// der Zeitumstellung hat der Tag 23 oder 25 Stunden (`gotchas.md`).
  static Duration nextCheckAfter(DateTime now) {
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final untilMidnight = midnight.difference(now);
    return untilMidnight < checkInterval ? untilMidnight : checkInterval;
  }

  @override
  ConsumerState<DayWatcher> createState() => _DayWatcherState();
}

class _DayWatcherState extends ConsumerState<DayWatcher>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshIfNewDay();
  }

  void _schedule() {
    final now = ref.read(clockProvider)();
    _timer = Timer(DayWatcher.nextCheckAfter(now), () {
      _refreshIfNewDay();
      _schedule();
    });
  }

  void _refreshIfNewDay() {
    final day = Day.from(ref.read(clockProvider)());
    if (day != ref.read(todayProvider)) ref.invalidate(todayProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
