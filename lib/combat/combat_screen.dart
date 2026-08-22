import 'package:combat/combat.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/palette.dart';
import 'battle_game.dart';
import 'combat_controller.dart';
import 'event_text.dart';
import 'widgets/fighter_status.dart';
import 'widgets/timing_bar.dart';

/// Was der Bildschirm gerade vom Spieler erwartet.
///
/// [animating] ist keine Eingabephase, sondern eine Sperre: Solange die
/// Runde noch abgespielt wird, nimmt der Bildschirm nichts an. Ohne sie
/// könnte man drei Runden in eine Sekunde drücken, und die Pfeile aus
/// Runde eins schlügen während Runde drei ein.
enum _Phase { chooseMove, timing, animating, finished }

class CombatScreen extends ConsumerStatefulWidget {
  const CombatScreen({super.key});

  @override
  ConsumerState<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends ConsumerState<CombatScreen> {
  final BattleGame _game = BattleGame();
  _Phase _phase = _Phase.chooseMove;
  Move? _pendingMove;

  void _onMoveSelected(Move move) {
    if (_phase != _Phase.chooseMove) return;

    // Nur Angriffe haben ein Zeitfenster. Utility löst sofort aus.
    if (!move.dealsDamage) {
      _resolve(move, TimedHit.none);
      return;
    }
    setState(() {
      _pendingMove = move;
      _phase = _Phase.timing;
    });
  }

  void _onTimingResult(TimedHit timedHit) {
    final move = _pendingMove;
    if (move == null) return;
    _resolve(move, timedHit);
  }

  void _resolve(Move move, TimedHit timedHit) {
    final controller = ref.read(combatControllerProvider.notifier);
    final events = controller.playRound(move, timedHit);

    controller.appendLog(events.map(describeEvent).whereType<String>());

    // Die Runde ist bereits ausgerechnet — das Abspielen holt sie nur ein.
    // Freigegeben wird erst, wenn die letzte Bewegung durch ist.
    _game.playEvents(events, onDone: _onAnimationDone);

    setState(() {
      _pendingMove = null;
      _phase = _Phase.animating;
    });
  }

  void _onAnimationDone() {
    if (!mounted) return;

    final isOver = ref.read(combatControllerProvider).state.isOver;
    setState(() {
      _phase = isOver ? _Phase.finished : _Phase.chooseMove;
    });
  }

  void _restart() {
    ref.read(combatControllerProvider.notifier).restart();
    _game.reset();
    setState(() {
      _pendingMove = null;
      _phase = _Phase.chooseMove;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(combatControllerProvider);
    final state = session.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kampf'),
        backgroundColor: Palette.background,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: FighterStatus(
                      combatant: state.player,
                      accent: Palette.accent,
                    ),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    child: FighterStatus(
                      combatant: state.enemy,
                      accent: Palette.enemy,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Palette.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: GameWidget<BattleGame>(game: _game),
              ),
            ),
            Expanded(flex: 2, child: _LogPanel(lines: session.log)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildControls(state, session.moves),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(CombatState state, List<Move> loadout) {
    return switch (_phase) {
      _Phase.timing => SizedBox(
        height: 96,
        child: Center(child: TimingBar(onResult: _onTimingResult)),
      ),
      _Phase.finished => SizedBox(
        height: 96,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                state.outcome == CombatOutcome.victory
                    ? 'Gewonnen nach ${state.round - 1} Runden'
                    : 'Verloren nach ${state.round - 1} Runden',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton(onPressed: _restart, child: const Text('Nochmal')),
            ],
          ),
        ),
      ),
      // Bewusst kein GridView mit childAspectRatio: das koppelt die
      // Zellenhoehe an die Fensterbreite, wodurch auf breiten Fenstern die
      // zweite Reihe aus dem Sichtbereich rutscht und gar nicht erst
      // gebaut wird. Feste Reihen sind bei jeder Breite verlaesslich.
      // Während der Animation bleiben dieselben Knöpfe stehen, nur
      // ausgegraut. Sie zu entfernen würde die Leiste springen lassen —
      // und der Sprung fiele stärker auf als der Kampf.
      // Die Hoehe haengt an der Zahl der Knoepfe, nicht an einer festen
      // Zahl: Seit ADR-0017 hat ein frischer Charakter genau einen Move
      // (nur der Waffenslot ist offen), und eine leere zweite Reihe waere
      // ein Loch, das nach einem Fehler aussieht.
      _Phase.chooseMove || _Phase.animating => SizedBox(
        height: loadout.length > 2 ? 96 : 44,
        child: Column(
          children: <Widget>[
            Expanded(child: _moveRow(loadout, state, 0)),
            if (loadout.length > 2) ...<Widget>[
              const SizedBox(height: 8),
              Expanded(child: _moveRow(loadout, state, 2)),
            ],
          ],
        ),
      ),
    };
  }

  /// Eine Reihe mit bis zu zwei Move-Buttons, beginnend bei [start].
  Widget _moveRow(List<Move> loadout, CombatState state, int start) {
    final accepting = _phase == _Phase.chooseMove;

    return Row(
      children: <Widget>[
        for (
          var i = start;
          i < start + 2 && i < loadout.length;
          i++
        ) ...<Widget>[
          if (i > start) const SizedBox(width: 8),
          Expanded(
            child: _MoveButton(
              move: loadout[i],
              affordable:
                  accepting && loadout[i].isAffordableBy(state.player.energy),
              onTap: () => _onMoveSelected(loadout[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({
    required this.move,
    required this.affordable,
    required this.onTap,
  });

  final Move move;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cost = move.energyDelta >= 0
        ? '+${move.energyDelta} EN'
        : '${move.energyDelta} EN';

    return FilledButton.tonal(
      onPressed: affordable ? onTap : null,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Text(
              move.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(cost, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _LogPanel extends StatelessWidget {
  const _LogPanel({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const Center(
        child: Text('Wähle einen Zug.', style: TextStyle(color: Palette.muted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      reverse: true,
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[lines.length - 1 - index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            line,
            style: TextStyle(
              fontSize: 13,
              color: index == 0
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.55),
            ),
          ),
        );
      },
    );
  }
}
