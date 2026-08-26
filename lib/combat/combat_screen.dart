import 'package:combat/combat.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/palette.dart';
import 'battle_game.dart';
import 'combat_controller.dart';
import 'event_text.dart';
import 'move_help.dart';
import 'widgets/environment_banner.dart';
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

  /// Zugriff auf die Leiste, damit ein Tipp irgendwo im Kampfbereich sie
  /// auslösen kann.
  final GlobalKey<TimingBarState> _timingKey = GlobalKey<TimingBarState>();
  _Phase _phase = _Phase.chooseMove;
  Move? _pendingMove;

  void _onMoveSelected(Move move) {
    if (_phase != _Phase.chooseMove) return;

    // Ob getippt wird, entscheidet der Move — nicht der Bildschirm.
    //
    // Hier stand bis heute `!move.dealsDamage`, eine Regel aus der Zeit
    // der vier Moves: Damals hatte nur ein Angriff etwas zu gewinnen. Von
    // den fünfzehn Fähigkeiten haben acht `power` 0 und trotzdem eigene
    // Timing-Werte — Steinhaut, Aurastrom, Blütentau und Prisma-Barriere
    // werden bei Perfect deutlich stärker, ohne je Schaden zu machen.
    // Ihre Perfect-Wirkungen waren dadurch unerreichbar.
    if (!move.hasTimingWindow) {
      _resolve(move, const <TimedHit>[TimedHit.none]);
      return;
    }
    setState(() {
      _pendingMove = move;
      _phase = _Phase.timing;
    });
  }

  void _onTimingResult(List<TimedHit> hits) {
    final move = _pendingMove;
    if (move == null) return;
    _resolve(move, hits);
  }

  void _resolve(Move move, List<TimedHit> hits) {
    final controller = ref.read(combatControllerProvider.notifier);
    final events = controller.playRound(move, hits);

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
      // **Die Tippfläche liegt über dem Körper, nicht über der AppBar.**
      // Während des Zeitfensters zählt jeder Tipp — auf die Kämpfer, auf
      // den Log, auf die Leiste. Nur der Zurück-Pfeil bleibt erreichbar,
      // weil er außerhalb von `body` sitzt. Ohne diese Trennung könnte man
      // den Kampf nicht mehr verlassen, ohne vorher zu tippen.
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            _buildBody(session, state),
            if (_phase == _Phase.timing)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _timingKey.currentState?.lockIn(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CombatSession session, CombatState state) {
    return Column(
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
        EnvironmentBanner(environment: state.environment),
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
    );
  }

  /// Welche Timing-Werte für den gewählten Zug gelten.
  ///
  /// Fällt auf den Standard zurück, solange nichts gewählt ist — die
  /// Leiste steht dann ohnehin nicht im Bild.
  TimingSpec _timingFor(CombatState state) {
    final move = _pendingMove;
    if (move == null) return TimingSpec.standard;

    return timingForSide(state, Side.player, move);
  }

  Widget _buildControls(CombatState state, List<Move> loadout) {
    return switch (_phase) {
      // Geschwindigkeit und Fenster kommen aus `package:combat` — sie
      // hängen an der Fähigkeit, an Statuseffekten und an der Umgebung.
      // Der Bildschirm rechnet daran nichts, er reicht durch (ADR-0002).
      _Phase.timing => SizedBox(
        height: 96,
        child: Center(
          child: TimingBar(
            key: _timingKey,
            spec: _timingFor(state),
            hits: _pendingMove?.hits ?? 1,
            onResult: _onTimingResult,
          ),
        ),
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
              attack: state.player.attack,
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
    required this.attack,
    required this.onTap,
  });

  final Move move;
  final bool affordable;

  /// Der Angriffswert des Spielers — die Erklärung nennt echte Zahlen,
  /// keine Multiplikatoren.
  final int attack;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cost = move.energyDelta >= 0
        ? '+${move.energyDelta} EN'
        : '${move.energyDelta} EN';

    // **Langes Drücken erklärt den Zug.** Auf einem Handy gibt es kein
    // Mausschweben, und ein zusätzliches „i" auf dem Knopf nähme Platz,
    // den Name und Energiekosten schon brauchen.
    //
    // Der Tooltip liegt **außen**: So funktioniert er auch, wenn der
    // Knopf gerade nicht bezahlbar oder gesperrt ist — gerade dann will
    // man wissen, worauf man spart.
    return Tooltip(
      richMessage: _erklaerung(),
      triggerMode: TooltipTriggerMode.longPress,
      showDuration: const Duration(seconds: 6),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Palette.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Palette.accent.withValues(alpha: 0.4)),
      ),
      child: _button(cost),
    );
  }

  /// Name, Wirkung und Perfect-Wirkung als ein Textblock.
  TextSpan _erklaerung() {
    final hilfe = moveHelpFor(move, attack);
    final perfekt = hilfe.perfect;

    return TextSpan(
      children: <InlineSpan>[
        TextSpan(
          text: '${move.name}\n',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.5,
          ),
        ),
        TextSpan(
          text: hilfe.effect,
          style: const TextStyle(color: Palette.textDim, height: 1.35),
        ),
        if (perfekt != null) ...<InlineSpan>[
          const TextSpan(
            text: '\n\nPerfekt: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD166),
              height: 1.35,
            ),
          ),
          TextSpan(
            text: perfekt,
            style: const TextStyle(color: Palette.textDim, height: 1.35),
          ),
        ],
      ],
    );
  }

  Widget _button(String cost) {
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
        // Der Hinweis steht hier, weil langes Drücken sonst niemand
        // findet — und der leere Log ist die einzige Stelle, an der Platz
        // dafür ist, ohne dass etwas Neues dazukommt.
        child: Text(
          'Wähle einen Zug.\nLange drücken erklärt ihn.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Palette.muted, height: 1.6),
        ),
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
