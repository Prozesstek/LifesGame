import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// **Ein Windstoß geht über die Anschlagtafel** (16.11.2026, Frederik:
/// „Gerne Lagerfeuer und Heute, es darf aber nicht so viel Leistung
/// ziehen“): Alle paar Sekunden flattern die Zettel kurz an ihrer
/// Reißzwecke, einer nach dem anderen, und hängen dann wieder still.
///
/// **Sparsam, weil es meistens nichts tut**: Zwischen zwei Stößen läuft
/// kein Takt, nur eine Uhr. Ein Stoß dauert [dauer]; dabei dreht sich je
/// Zettel eine fertige Ebene, neu gemalt wird kein Text und kein Brett
/// (`Steckbrief`, `Anschlagtafel`).
///
/// **Nur Darstellung.** In Tests weht nichts ([weht]), und wer Bewegung
/// im System abgeschaltet hat, bekommt keine.
class TafelWind extends StatefulWidget {
  const TafelWind({required this.child, super.key});

  final Widget child;

  /// Aus in Tests (`test/flutter_test_config.dart`): Eine Uhr ohne Ende
  /// bliebe am Ende jedes Tests offen.
  static bool weht = true;

  static const Duration dauer = Duration(milliseconds: 1500);

  /// Der erste Stoß kommt bald, damit man ihn sieht; danach in losen
  /// Abständen zwischen [pauseMin] und [pauseMax].
  static const Duration erster = Duration(milliseconds: 2400);
  static const Duration pauseMin = Duration(seconds: 6);
  static const Duration pauseMax = Duration(seconds: 13);

  /// Wie weit ein Zettel höchstens ausschlägt, im Bogenmaß.
  static const double ausschlag = 0.02;

  /// Welcher Anteil des Stoßes vergeht, bis er beim letzten Zettel
  /// ankommt.
  static const double _laufzeit = 0.4;

  /// Der Stoß über dieser Stelle, 0 bis 1 — oder null, wenn hier keine
  /// Tafel im Wind hängt.
  static Animation<double>? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_WindOrt>()?.notifier;
  }

  /// **Wie schief der Wind einen Zettel gerade hält**: [stoss] ist der
  /// Fortschritt des Stoßes, [versatz] (0 bis 1) sagt, wie spät er bei
  /// diesem Zettel ankommt. Schwingt dreimal aus und endet bei null —
  /// reine Rechnung.
  static double winkel(double stoss, {double versatz = 0}) {
    final start = versatz.clamp(0.0, 1.0) * _laufzeit;
    final t = ((stoss - start) / (1 - _laufzeit)).clamp(0.0, 1.0);
    if (t <= 0 || t >= 1) return 0;
    final abklingen = (1 - t) * (1 - t);
    return ausschlag * math.sin(t * math.pi * 3) * abklingen;
  }

  @override
  State<TafelWind> createState() => _TafelWindState();
}

class _TafelWindState extends State<TafelWind>
    with SingleTickerProviderStateMixin {
  // In `initState` angelegt, nicht faul (`gotchas.md`).
  late final AnimationController _stoss;
  final math.Random _wuerfel = math.Random();
  Timer? _uhr;
  bool _an = false;

  @override
  void initState() {
    super.initState();
    _stoss = AnimationController(vsync: this, duration: TafelWind.dauer)
      ..addStatusListener(_nachDemStoss);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ruhig = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final an = TafelWind.weht && !ruhig;
    if (an == _an) return;
    _an = an;
    _uhr?.cancel();
    if (an) {
      _uhr = Timer(TafelWind.erster, _wehe);
    } else {
      _stoss.value = 0;
    }
  }

  void _wehe() {
    if (!mounted || !_an) return;
    _stoss.forward(from: 0);
  }

  void _nachDemStoss(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_an) return;
    final spanne = TafelWind.pauseMax - TafelWind.pauseMin;
    _uhr = Timer(TafelWind.pauseMin + spanne * _wuerfel.nextDouble(), _wehe);
  }

  @override
  void dispose() {
    _uhr?.cancel();
    _stoss.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _WindOrt(notifier: _stoss, child: widget.child);
  }
}

/// Reicht den Stoß nach unten. **Kein `InheritedNotifier`**: Der baute
/// bei jedem Bild alle Zettel neu — hier hört nur die Drehung zu.
class _WindOrt extends InheritedWidget {
  const _WindOrt({required this.notifier, required super.child});

  final Animation<double> notifier;

  @override
  bool updateShouldNotify(_WindOrt alt) => alt.notifier != notifier;
}
