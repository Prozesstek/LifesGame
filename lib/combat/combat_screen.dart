import 'package:combat/combat.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/palette.dart';
import 'battle_game.dart';
import 'combat_controller.dart';
import 'event_text.dart';
import 'move_help.dart';
import 'move_icon.dart';
import 'widgets/environment_banner.dart';
import 'widgets/fighter_status.dart';
import 'widgets/result_dialog.dart';
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

  /// Ob das Ergebnisblatt für diesen Kampf schon offen war.
  ///
  /// Ohne die Sperre könnte es zweimal aufgehen: Der Kampf endet einmal,
  /// aber das Abspielen meldet sich für jede Runde.
  bool _resultShown = false;

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

    if (isOver && !_resultShown) {
      _resultShown = true;
      // **Erst nach dem Bild.** Diese Methode läuft aus der Flame-Schleife
      // heraus, also mitten in einem Frame; `showDialog` von dort aus
      // öffnet eine Route, während noch gezeichnet wird. Derselbe
      // Fallstrick wie bei „Alles freischalten" im Entwicklermodus
      // (`docs/context/gotchas.md`).
      WidgetsBinding.instance.addPostFrameCallback((_) => _showResult());
    }
  }

  /// Das Ergebnis als Blatt, das man wegtippen muss.
  ///
  /// **Es steht bewusst keine Belohnung darin, denn es gibt keine.**
  /// Erfahrung und Gold kommen aus Gewohnheiten und Theorie, nie aus
  /// einem Kampf (`konzept.md` Abschnitt 2). Der Kampf ist die Stelle, an
  /// der sich der Fortschritt auszahlt — gäbe es dort XP, könnte man ihn
  /// erkämpfen statt erarbeiten, und die Aussage des Produkts wäre hin.
  /// Der Satz am Ende sagt das, damit die Frage nicht offen bleibt.
  Future<void> _showResult() async {
    if (!mounted) return;

    final state = ref.read(combatControllerProvider).state;
    final gewonnen = state.outcome == CombatOutcome.victory;
    final runden = state.round - 1;

    await showDialog<void>(
      context: context,
      builder: (context) => CombatResultDialog(
        won: gewonnen,
        rounds: runden,
        enemyName: state.enemy.name,
      ),
    );
  }

  void _restart() {
    ref.read(combatControllerProvider.notifier).restart();
    _game.reset();
    setState(() {
      _pendingMove = null;
      _phase = _Phase.chooseMove;
      _resultShown = false;
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
        // **Hier stand der Log.** Er ist der Kachelleiste gewichen: Das
        // Bild ist jetzt der Knopf, und zwei Reihen davon brauchen den
        // Platz, den vorher die Zeilen hatten.
        //
        // Geführt wird er weiter (`CombatSession.log`), nur nicht mehr
        // gezeigt — wer ihn zurückholen will, hängt eine Zeile in diese
        // Spalte. Was dadurch fehlt, steht in `docs/context/state.md`.
        const SizedBox(height: 12),
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
      // **Alle Züge in einer Reihe.** Die Höhe ergibt sich aus den Kacheln
      // selbst: Sie sind quadratisch, ihre Breite bestimmt also ihre Höhe.
      // Was sie nicht brauchen, bleibt der Arena — und eine zweite Reihe
      // hätte davon rund 190 Pixel genommen.
      _Phase.chooseMove || _Phase.animating => _moveRow(loadout, state),
    };
  }

  /// Eine Reihe mit bis zu zwei Kacheln, beginnend bei [start].
  ///
  /// Bewusst kein `GridView` mit `childAspectRatio`: Das koppelt die
  /// Zellenhöhe an die Fensterbreite, wodurch auf breiten Fenstern die
  /// zweite Reihe aus dem Sichtbereich rutscht und gar nicht erst gebaut
  /// wird (`docs/context/gotchas.md`). Feste Reihen sind bei jeder Breite
  /// verlässlich.
  ///
  /// Während der Animation bleiben dieselben Kacheln stehen, nur
  /// ausgegraut — sie zu entfernen würde die Leiste springen lassen.
  Widget _moveRow(List<Move> loadout, CombatState state) {
    final accepting = _phase == _Phase.chooseMove;

    // Die Kantenlänge kommt aus der verfügbaren Breite, nicht aus einer
    // festen Zahl — nur so ist die Kachel wirklich quadratisch und das
    // Bild vollständig zu sehen.
    return LayoutBuilder(
      builder: (context, constraints) {
        final seite = MoveIcons.tileSideFor(
          constraints.maxWidth,
          loadout.length,
        );

        // Die Namenszeile gilt fuer die ganze Reihe: Sobald ein Zug ein
        // Bild hat, bekommen alle den Platz dafuer, damit die Kacheln
        // buendig stehen. Hat keiner eins, entfaellt sie.
        final mitNamen = loadout.any((m) => MoveIcons.forMoveId(m.id) != null);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (var i = 0; i < loadout.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: MoveIcons.gap),
              SizedBox(
                width: seite,
                child: _MoveTile(
                  move: loadout[i],
                  side: seite,
                  showLabel: mitNamen,
                  affordable:
                      accepting &&
                      loadout[i].isAffordableBy(state.player.energy),
                  attack: state.player.attack,
                  onTap: () => _onMoveSelected(loadout[i]),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Eine Fähigkeit als Kachel — **das Bild ist der Knopf**.
///
/// Wer ein Bild hat, zeigt es groß und trägt den Namen darüber. Wer keins
/// hat, bekommt eine gleich große Kachel im selben Rahmenstil mit dem
/// Namen darin. Das ist kein Schönheitsdetail: Der Waffenzug hat kein
/// Bild, und er ist der Zug, den man **jede Runde** drückt, um Energie
/// aufzubauen. Ohne Knopf dort ließe sich nicht kämpfen.
class _MoveTile extends StatelessWidget {
  const _MoveTile({
    required this.move,
    required this.side,
    required this.showLabel,
    required this.affordable,
    required this.attack,
    required this.onTap,
  });

  final Move move;

  /// Kantenlaenge der Kachel. Kommt aus der verfuegbaren Breite.
  final double side;

  /// Ob ueber der Kachel eine Namenszeile steht. Gilt fuer die ganze
  /// Reihe gemeinsam, damit die Flaechen buendig bleiben.
  final bool showLabel;

  final bool affordable;

  /// Der Angriffswert des Spielers — die Erklärung nennt echte Zahlen,
  /// keine Multiplikatoren.
  final int attack;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bild = MoveIcons.forMoveId(move.id);

    // **Langes Drücken erklärt den Zug.** Der Tooltip liegt außen, damit er
    // auch bei einem unbezahlbaren Zug aufgeht — gerade dann will man
    // wissen, worauf man spart.
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Die Zeile steht nur, wenn in dieser Reihe überhaupt ein Bild
          // vorkommt — dann wird sie auch bei den Kacheln **ohne** Bild
          // freigehalten, damit die Flächen auf gleicher Höhe liegen.
          // Hat kein einziger Zug ein Bild, wäre sie über jeder Kachel ein
          // leerer Streifen; dann entfällt sie ganz.
          if (showLabel) ...<Widget>[
            SizedBox(
              height: MoveIcons.labelHeight,
              child: bild == null
                  ? null
                  : Text(
                      move.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: affordable ? Colors.white : Palette.muted,
                      ),
                    ),
            ),
            const SizedBox(height: 4),
          ],
          _Kachel(
            move: move,
            side: side,
            bild: bild,
            affordable: affordable,
            onTap: onTap,
          ),
        ],
      ),
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
}

/// Die antippbare Fläche: Bild oder Name, dazu die Energiekosten.
class _Kachel extends StatelessWidget {
  const _Kachel({
    required this.move,
    required this.side,
    required this.bild,
    required this.affordable,
    required this.onTap,
  });

  final Move move;
  final double side;
  final String? bild;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kosten = move.energyDelta >= 0
        ? '+${move.energyDelta}'
        : '${move.energyDelta}';

    return SizedBox(
      height: side,
      child: Material(
        color: Palette.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: affordable ? onTap : null,
          child: Opacity(
            opacity: affordable ? 1 : 0.42,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (bild != null)
                  Image.asset(
                    bild!,
                    fit: BoxFit.cover,
                    // Das Bild liegt in dreifacher Kachelgröße vor; ohne
                    // Glättung fräst das Verkleinern die Pixelgrafik kaputt.
                    filterQuality: FilterQuality.medium,
                  )
                else
                  // Ohne Bild trägt die Kachel den Namen — sonst wäre der
                  // Waffenzug ein leeres Kästchen.
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        move.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 5,
                  bottom: 5,
                  child: _EnergieMarke(text: '$kosten EN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Die Energiekosten in der Ecke der Kachel.
///
/// Auf dem Bild statt daneben: Die Kachel ist ohnehin quadratisch, und
/// eine eigene Zeile hätte Höhe gekostet, die der Kampfbildschirm nicht
/// mehr hat.
class _EnergieMarke extends StatelessWidget {
  const _EnergieMarke({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xCC0B0E15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
