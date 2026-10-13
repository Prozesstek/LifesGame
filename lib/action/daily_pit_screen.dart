import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/sound_effects.dart';
import '../combat/daily_pit_controller.dart';
import '../combat/widgets/tagesgrube_ergebnis.dart';
import '../habits/habits_controller.dart';
import '../home/erster_start_provider.dart';
import '../ui/holz.dart';
import '../ui/on_dark.dart';
import '../ui/palette.dart';
import 'action_game.dart';
import 'lauf_zeichen.dart';
import 'pit_run_view.dart';

/// Der eine Lauf des Tages durch die Tagesgrube (ADR-0072).
///
/// **Wer hier ankommt, hat seinen Versuch schon gebraucht.** Der Eingang
/// (`TagesgrubeKarte`) trägt ihn ein, bevor er diese Seite öffnet — sonst
/// reichte Neuladen, um es noch einmal zu versuchen. Diese Seite spielt
/// den Lauf und trägt ein, wie er ausging.
///
/// Was sie von `PitScreen` unterscheidet: Karte, Held und Ausstattung
/// kommen aus `DailyPit` und nicht vom eigenen Charakter, es gibt keinen
/// Topf und keine Beute, und es gibt kein „Nochmal“.
class DailyPitScreen extends ConsumerStatefulWidget {
  const DailyPitScreen({super.key, required this.day, required this.condition});

  /// Der Tag, an dem hinabgestiegen wurde, in Tagen seit dem 1.1.1970.
  /// An ihm hängen Karte, Satz und der Eintrag — nicht an der Uhr beim
  /// Ende des Laufs.
  final int day;

  /// Die Verfassung beim Hinabsteigen.
  final DailyCondition condition;

  /// Woran Tests die Knöpfe der Rückfrage finden.
  static const Key bleibenKey = ValueKey<String>('tagesgrube-bleiben');
  static const Key aufgebenKey = ValueKey<String>('tagesgrube-aufgeben');

  @override
  ConsumerState<DailyPitScreen> createState() => _DailyPitScreenState();
}

class _DailyPitScreenState extends ConsumerState<DailyPitScreen> {
  late final ActionGame _game;
  bool _ergebnisGezeigt = false;

  /// Ob der Lauf vorbei ist — erst dann führt „Zurück“ ohne Rückfrage
  /// hinaus.
  bool _vorbei = false;

  @override
  void initState() {
    super.initState();
    _game = ActionGame(
      sim: DailyPit.worldFor(
        widget.day,
        inForm: widget.condition == DailyCondition.inForm,
      ),
      klang: ref.read(soundPlayerProvider),
      // Dieselbe Regel wie in der Grube (ADR-0069): Bis die erste Stufe
      // geschafft ist, erklärt sich der Lauf.
      zeichen: ref.read(ersterStartProvider).grubeErklaertSich
          ? LaufZeichen()
          : null,
      onRunEnded: () {
        // **Erst nach dem Bild** — das Ende wird mitten in einem Frame
        // gemeldet (`gotchas.md`).
        WidgetsBinding.instance.addPostFrameCallback((_) => _zeigeErgebnis());
      },
    );
  }

  @override
  void dispose() {
    _game.frame.dispose();
    super.dispose();
  }

  /// Trägt das Ergebnis ein und zeigt das Blatt. **Hier und nur hier
  /// endet ein Versuch.**
  Future<void> _zeigeErgebnis() async {
    if (!mounted || _ergebnisGezeigt) return;
    _ergebnisGezeigt = true;

    final lauf = ref
        .read(dailyPitProvider.notifier)
        .finish(widget.day, _game.sim);
    setState(() => _vorbei = true);
    if (lauf == null) return;
    if (lauf.won) ref.read(soundPlayerProvider).play(SoundEffect.sieg);

    final kette = ref
        .read(habitTrackerProvider)
        .currentDayStreak(ref.read(todayProvider));
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TagesgrubeErgebnis(
        number: DailyPit.numberFor(widget.day),
        run: lauf,
        dayStreak: kette,
      ),
    );
    if (!mounted) return;
    await Navigator.of(context).maybePop();
  }

  /// „Zurück“ mitten im Lauf: fragen, bevor der Versuch verloren ist.
  ///
  /// **Der Lauf hält an, solange die Frage steht** — sonst fiele der
  /// Held, während man sie liest.
  Future<void> _fragtNachAufgeben() async {
    _game.pauseEngine();
    final aufgeben = await showDialog<bool>(
      context: context,
      builder: (context) => HolzDialog(
        child: AlertDialog(
          backgroundColor: Palette.surface,
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(),
          title: const Text('Aufgeben?'),
          content: const Text(
            'Der Versuch von heute ist gebraucht. Wer jetzt geht, hat ihn '
            'abgebrochen.',
          ),
          actions: <Widget>[
            TextButton(
              key: DailyPitScreen.aufgebenKey,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Aufgeben'),
            ),
            FilledButton(
              key: DailyPitScreen.bleibenKey,
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Weiterkämpfen'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (aufgeben ?? false) {
      setState(() => _vorbei = true);
      Navigator.of(context).pop();
    } else {
      _game.resumeEngine();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _vorbei,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _fragtNachAufgeben();
      },
      child: Scaffold(
        backgroundColor: Palette.background,
        appBar: AppBar(
          title: Text('Tagesgrube #${DailyPit.numberFor(widget.day)}'),
          backgroundColor: Palette.backgroundRaised,
          foregroundColor: Palette.textOnDark,
        ),
        body: OnDark(child: PitRunView(game: _game)),
      ),
    );
  }
}
