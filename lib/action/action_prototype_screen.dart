import 'package:action_combat/action_combat.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gear/gear_controller.dart';
import '../ui/on_dark.dart';
import '../ui/palette.dart';
import 'ability_buttons.dart';
import 'action_game.dart';
import 'action_joystick.dart';

/// **Prototyp.** Echtzeit-Kampf in einer Halle voller Gegner.
///
/// Er beantwortet eine Frage, die sich nicht ausrechnen lässt: Fühlt sich
/// der Kampf belohnender an, wenn Gegner unter einem zerfallen, statt
/// dass jeder einzelne knapp ausgeht? Die Zahlen dazu stehen in
/// `packages/action_combat/example/headless_run.dart`; hier steht das
/// Gefühl.
///
/// **Er ersetzt nichts.** Der rundenbasierte Kampf, `package:combat` und
/// die Gegnerreihe sind unberührt. Erreichbar ist dieser Bildschirm nur
/// über den Entwicklermodus, also nur im Debug-Bau — wie alles, was noch
/// keine Entscheidung ist (ADR-0021).
class ActionPrototypeScreen extends ConsumerStatefulWidget {
  const ActionPrototypeScreen({super.key});

  @override
  ConsumerState<ActionPrototypeScreen> createState() =>
      _ActionPrototypeScreenState();
}

class _ActionPrototypeScreenState extends ConsumerState<ActionPrototypeScreen> {
  ActionGame? _game;
  ActionStats? _gewaehlt;
  bool _fertig = false;

  /// Welche Tasten gerade gedrückt sind. Für den Browser — mit der Maus
  /// ein Steuerkreuz zu ziehen ist zum Ausprobieren zu mühsam.
  final Set<LogicalKeyboardKey> _tasten = <LogicalKeyboardKey>{};

  @override
  void dispose() {
    _game?.frame.dispose();
    super.dispose();
  }

  void _start(ActionStats stats) {
    _game?.frame.dispose();
    final sim = ActionWorld(level: LevelCatalog.grube, heroStats: stats);
    setState(() {
      _gewaehlt = stats;
      _fertig = false;
      _game = ActionGame(
        sim: sim,
        onRunEnded: () {
          if (mounted) setState(() => _fertig = true);
        },
      );
    });
  }

  /// Die Werte, mit denen der Charakter gerade wirklich dasteht.
  ActionStats _echteWerte() {
    final stats = ref.read(equippedStatsProvider);
    return ActionStats(
      attack: stats.attack,
      maxHp: stats.maxHp,
      defense: stats.defense,
      energy: stats.maxEnergy,
    );
  }

  void _tastenGeaendert() {
    final game = _game;
    if (game == null) return;

    var x = 0.0;
    var y = 0.0;
    if (_tasten.contains(LogicalKeyboardKey.keyA) ||
        _tasten.contains(LogicalKeyboardKey.arrowLeft)) {
      x -= 1;
    }
    if (_tasten.contains(LogicalKeyboardKey.keyD) ||
        _tasten.contains(LogicalKeyboardKey.arrowRight)) {
      x += 1;
    }
    if (_tasten.contains(LogicalKeyboardKey.keyW) ||
        _tasten.contains(LogicalKeyboardKey.arrowUp)) {
      y -= 1;
    }
    if (_tasten.contains(LogicalKeyboardKey.keyS) ||
        _tasten.contains(LogicalKeyboardKey.arrowDown)) {
      y += 1;
    }
    game.moveInput = Vec2(x, y).normalized;
  }

  /// Welche Taste welche Fähigkeit auslöst.
  ///
  /// Leertaste und Umschalt, weil beide erreichbar sind, ohne die linke
  /// Hand von WASD zu nehmen.
  /// Nicht `const`: `LogicalKeyboardKey` hat ein eigenes `==`, und
  /// konstante Maps verlangen Schlüssel mit dem Standardvergleich.
  static final Map<LogicalKeyboardKey, ActionAbility> _abilityKeys =
      <LogicalKeyboardKey, ActionAbility>{
        LogicalKeyboardKey.space: ActionAbility.rundumschlag,
        LogicalKeyboardKey.shiftLeft: ActionAbility.sturmschritt,
        LogicalKeyboardKey.shiftRight: ActionAbility.sturmschritt,
      };

  void _use(ActionAbility ability) {
    _game?.sim.useAbility(ability);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final ability = _abilityKeys[event.logicalKey];
      if (ability != null) {
        _use(ability);
        return KeyEventResult.handled;
      }
      _tasten.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _tasten.remove(event.logicalKey);
    } else {
      return KeyEventResult.ignored;
    }
    _tastenGeaendert();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        title: const Text('Prototyp: Die Grube'),
        backgroundColor: Palette.backgroundRaised,
        foregroundColor: Palette.textOnDark,
      ),
      body: OnDark(
        child: Focus(
          autofocus: true,
          onKeyEvent: _onKey,
          child: Stack(
            children: <Widget>[
              if (game != null) ...<Widget>[
                Positioned.fill(child: GameWidget(game: game)),
                Positioned.fill(
                  child: ActionJoystick(
                    onChanged: (richtung) => game.moveInput = richtung,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 12,
                  right: 12,
                  child: _Hud(game: game),
                ),
                Positioned(
                  right: 16,
                  bottom: 24,
                  child: ValueListenableBuilder<int>(
                    valueListenable: game.frame,
                    builder: (context, _, _) =>
                        AbilityButtons(world: game.sim, onUse: _use),
                  ),
                ),
              ],
              if (game == null) const _StartOverlayPlaceholder(),
              if (game == null)
                _StartOverlay(onPick: _start, echteWerte: _echteWerte),
              if (game != null && _fertig)
                _EndOverlay(
                  sim: game.sim,
                  stats: _gewaehlt,
                  onAgain: () => _start(_gewaehlt ?? ActionStats.gereift),
                  onBack: () => setState(() {
                    _game?.frame.dispose();
                    _game = null;
                    _fertig = false;
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Der dunkle Grund, solange nichts läuft.
class _StartOverlayPlaceholder extends StatelessWidget {
  const _StartOverlayPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Palette.background,
      child: SizedBox.expand(),
    );
  }
}

/// Die Kopfzeile: Leben, Zähler, Zeit — und der Endgegner, wenn er lebt.
class _Hud extends StatelessWidget {
  const _Hud({required this.game});

  final ActionGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.frame,
      builder: (context, _, _) {
        final sim = game.sim;
        final boss = sim.bossView;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Bar(
              ratio: sim.heroHpRatio,
              color: Palette.successOnDark,
              label: '${sim.heroHp} / ${sim.heroMaxHp}',
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: Text(
                    '${sim.kills} / ${sim.totalEnemies} erledigt'
                    '${sim.orbsCollected > 0 ? ' · ${sim.orbsCollected} Kugeln' : ''}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Palette.textOnDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${sim.elapsed.toStringAsFixed(0)} s',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Palette.textOnDarkDim,
                    ),
                  ),
                ),
              ],
            ),
            if (boss != null) ...<Widget>[
              const SizedBox(height: 8),
              _Bar(
                ratio: boss.hpRatio,
                color: Palette.enemyOnDark,
                label: 'Der Wächter',
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.ratio, required this.color, required this.label});

  final double ratio;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 14,
            backgroundColor: Palette.trackOnDark,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Palette.textOnDark,
          ),
        ),
      ],
    );
  }
}

/// Die Wahl der Machtstufe — und damit die eigentliche Frage.
class _StartOverlay extends StatelessWidget {
  const _StartOverlay({required this.onPick, required this.echteWerte});

  final void Function(ActionStats) onPick;
  final ActionStats Function() echteWerte;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Die Grube',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Palette.textOnDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sechsundzwanzig Gegner und ein Wächter, fünf davon mit '
                'Bogen. Laufen mit dem Daumen oder WASD, geschlagen wird '
                'von selbst.\n\n'
                'Zwei Knöpfe unten rechts: Sturmschritt raus aus der '
                'Traube, Rundumschlag mitten hinein. Auf der Tastatur '
                'Umschalt und Leertaste.\n\n'
                'Mit welcher Macht?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Palette.textOnDarkDim,
                ),
              ),
              const SizedBox(height: 20),
              _PowerButton(
                title: 'Tag 0',
                subtitle: 'Angriff 13 — ein frischer Charakter.',
                onTap: () => onPick(ActionStats.frisch),
              ),
              _PowerButton(
                title: 'Deine Werte',
                subtitle: 'Was der Charakter gerade wirklich trägt.',
                onTap: () => onPick(echteWerte()),
              ),
              _PowerButton(
                title: 'Decke von heute',
                subtitle:
                    'Angriff 30 — alle Werte am Maximum, volle Ausrüstung. '
                    'Mehr gibt das Spiel nicht her.',
                onTap: () => onPick(ActionStats.gereift),
              ),
              _PowerButton(
                title: 'Mit Potenz-Kurve',
                subtitle:
                    'Dieselben Werte, aber Schaden mal drei und kritische '
                    'Treffer. Gibt es im Spiel nicht — das ist die offene '
                    'Frage.',
                highlight: true,
                onTap: () => onPick(ActionStats.mitPotenz),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PowerButton extends StatelessWidget {
  const _PowerButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Palette.backgroundRaised,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: highlight ? Palette.goldOnDark : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: highlight ? Palette.goldOnDark : Palette.textOnDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Palette.textOnDarkDim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Das Blatt am Ende eines Laufs.
class _EndOverlay extends StatelessWidget {
  const _EndOverlay({
    required this.sim,
    required this.stats,
    required this.onAgain,
    required this.onBack,
  });

  final ActionWorld sim;
  final ActionStats? stats;
  final VoidCallback onAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final jeGegner = sim.kills == 0 ? 0.0 : sim.elapsed / sim.kills;

    return ColoredBox(
      color: Palette.background.withValues(alpha: 0.88),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  sim.isWon ? 'Die Grube ist leer' : 'Gefallen',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: sim.isWon
                        ? Palette.successOnDark
                        : Palette.enemyOnDark,
                  ),
                ),
                const SizedBox(height: 16),
                _Zeile('Erledigt', '${sim.kills} / ${sim.totalEnemies}'),
                _Zeile('Gebraucht', '${sim.elapsed.toStringAsFixed(0)} s'),
                _Zeile('Je Gegner', '${jeGegner.toStringAsFixed(1)} s'),
                _Zeile('Leben übrig', '${sim.heroHp} / ${sim.heroMaxHp}'),
                _Zeile('Heilkugeln', '${sim.orbsCollected}'),
                if (stats != null) _Zeile('Angriff', '${stats!.attack}'),
                const SizedBox(height: 18),
                const Text(
                  '„Je Gegner" ist die Zahl, um die es geht. Sie sagt, wie '
                  'schnell etwas unter einem zerfällt — und ob '
                  'Stärkerwerden sich belohnend anfühlt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Palette.textOnDarkDim,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: onAgain, child: const Text('Nochmal')),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onBack,
                  child: const Text('Andere Machtstufe'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Zeile extends StatelessWidget {
  const _Zeile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Palette.textOnDarkDim,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Palette.textOnDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
