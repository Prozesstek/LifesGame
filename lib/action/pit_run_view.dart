import 'package:action_combat/action_combat.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/palette.dart';
import 'ability_buttons.dart';
import 'action_game.dart';
import 'action_joystick.dart';

/// Ein laufender Lauf durch die Grube: Spielfeld, Steuerkreuz, Kopfzeile
/// und Knöpfe.
///
/// **Eine Stelle für beide Wege hinein.** Die Grube aus der Reihe
/// (`pit_screen.dart`) und der Prototyp im Entwicklermodus
/// (`action_prototype_screen.dart`) zeigen denselben Lauf; was sie
/// unterscheidet, ist nur, was davor und danach kommt. Stünde die
/// Steuerung zweimal da, liefe eine Taste irgendwann nur noch in einem
/// von beiden (`gotchas.md`, zwei Stellen für eine Frage).
class PitRunView extends StatefulWidget {
  const PitRunView({super.key, required this.game});

  final ActionGame game;

  @override
  State<PitRunView> createState() => _PitRunViewState();
}

class _PitRunViewState extends State<PitRunView> {
  /// Welche Tasten gerade gedrückt sind. Für den Browser — mit der Maus
  /// ein Steuerkreuz zu ziehen ist zum Ausprobieren zu mühsam.
  final Set<LogicalKeyboardKey> _tasten = <LogicalKeyboardKey>{};

  void _tastenGeaendert() {
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
    widget.game.moveInput = Vec2(x, y).normalized;
  }

  /// Die Plätze auf 1, 2, 3 — in der Reihenfolge, in der sie auf dem
  /// Charakter liegen. Oben auf der Tastatur oder im Nummernblock.
  static final List<LogicalKeyboardKey> _slotKeys = <LogicalKeyboardKey>[
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
  ];
  static final List<LogicalKeyboardKey> _slotKeysNumpad = <LogicalKeyboardKey>[
    LogicalKeyboardKey.numpad1,
    LogicalKeyboardKey.numpad2,
    LogicalKeyboardKey.numpad3,
  ];

  /// Welcher Platz zu [key] gehört, oder -1.
  static int _platzFuer(LogicalKeyboardKey key) {
    final oben = _slotKeys.indexOf(key);
    return oben >= 0 ? oben : _slotKeysNumpad.indexOf(key);
  }

  /// Wo die Maus zuletzt stand — am Rechner zielt sie.
  Offset? _maus;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final game = widget.game;
    final platz = _platzFuer(event.logicalKey);
    final slots = game.sim.slots;
    if (platz >= 0) {
      if (platz >= slots.length) return KeyEventResult.handled;
      final ability = slots[platz];
      // **Taste halten, mit der Maus zielen, loslassen wirkt** — wie der
      // Daumen am Knopf. Was nichts zu zielen hat, wirkt beim Drücken.
      if (event is KeyDownEvent) {
        if (ability.aim == PitAim.selbst) {
          game.sim.cast(ability.id);
        } else {
          game.beginAim(ability.id);
          final maus = _maus;
          if (maus != null) game.aimAtScreen(maus);
        }
      } else if (event is KeyUpEvent && game.aimingId == ability.id) {
        game.releaseAim();
      }
      return KeyEventResult.handled;
    }

    if (event is KeyDownEvent) {
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
    final game = widget.game;

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      // Um den ganzen Stapel: Das Steuerkreuz liegt über dem Spielfeld
      // und finge die Maus sonst ab. Die Koordinaten sind dieselben wie
      // die des Spielfelds, es füllt den Stapel.
      child: MouseRegion(
        onHover: (event) {
          _maus = event.localPosition;
          game.aimAtScreen(event.localPosition);
        },
        child: Stack(
          children: <Widget>[
            // **Ohne eigenen Fokus.** Flames `GameWidget` holt ihn sich sonst
            // selbst und meldet jede Taste als erledigt, auch wenn das Spiel
            // keine Tasten kennt — keine davon käme dann hier oben an
            // (`gotchas.md`).
            Positioned.fill(child: GameWidget(game: game, autofocus: false)),
            Positioned.fill(
              child: ActionJoystick(
                onChanged: (richtung) => game.moveInput = richtung,
              ),
            ),
            Positioned(top: 8, left: 12, right: 12, child: _Hud(game: game)),
            Positioned.fill(
              child: IgnorePointer(child: _BossTitle(game: game)),
            ),
            Positioned(
              right: 16,
              bottom: 24,
              child: ValueListenableBuilder<int>(
                valueListenable: game.frame,
                builder: (context, _, _) => AbilityButtons(game: game),
              ),
            ),
          ],
        ),
      ),
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
            PitBar(
              ratio: sim.heroHpRatio,
              color: Palette.successOnDark,
              label: '${sim.heroHp} / ${sim.heroMaxHp}',
            ),
            // Nur wenn etwas auf den Plätzen liegt: Ohne Fähigkeit ist
            // Mana eine Zahl, die man nicht ausgeben kann.
            if (sim.slots.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              PitBar(
                ratio: sim.manaRatio,
                color: Palette.manaOnDark,
                label: '${sim.mana} / ${sim.maxMana} Mana',
                height: 10,
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: Text(
                    '${sim.kills} / ${sim.totalEnemies} erledigt'
                    '${sim.runXp > 0 || sim.runGold > 0 ? ' · +${sim.runXp} EP +${sim.runGold} G' : ''}'
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
              const SizedBox(height: 10),
              BossBar(
                name: 'Der Wächter',
                ratio: boss.hpRatio * sim.bossBarFill,
                // Wut ändert, was er tut — das soll man lesen können, nicht
                // erst merken, wenn er anstürmt.
                enraged: sim.isBossEnraged,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Der Balken des Wächters, wie in Dark Souls: der Name darüber, klein
/// und links, darunter ein langer, schmaler Balken ohne Zahl.
///
/// Er erscheint erst, wenn der Wächter gelandet ist
/// (`ActionWorld.bossView`), und läuft dann voll
/// (`ActionWorld.bossBarFill`).
class BossBar extends StatelessWidget {
  const BossBar({
    super.key,
    required this.name,
    required this.ratio,
    this.enraged = false,
  });

  final String name;
  final double ratio;
  final bool enraged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          enraged ? '$name · wütend' : name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            letterSpacing: 1.2,
            color: Palette.textOnDark,
            shadows: <Shadow>[Shadow(blurRadius: 4)],
          ),
        ),
        const SizedBox(height: 3),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Palette.textOnDarkDim),
          ),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: Palette.trackOnDark,
            valueColor: const AlwaysStoppedAnimation<Color>(
              Palette.enemyOnDark,
            ),
          ),
        ),
      ],
    );
  }
}

/// Der Schriftzug in der Mitte, während der Wächter auftritt: blendet mit
/// der Landung ein und zum Ende des Auftritts wieder aus.
class _BossTitle extends StatelessWidget {
  const _BossTitle({required this.game});

  final ActionGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.frame,
      builder: (context, _, _) {
        final auftritt = game.sim.bossEntrance;
        if (auftritt == null) return const SizedBox.shrink();

        const landet = ActionBalance.bossLandsShare;
        final deckkraft = auftritt < landet
            ? 0.0
            : auftritt < 0.8
            ? ((auftritt - landet) / 0.15).clamp(0.0, 1.0)
            : ((1 - auftritt) / 0.2).clamp(0.0, 1.0);

        return Align(
          alignment: const Alignment(0, -0.35),
          child: Opacity(
            opacity: deckkraft,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'DER WÄCHTER',
                  style: TextStyle(
                    fontSize: 30,
                    letterSpacing: 6,
                    fontWeight: FontWeight.bold,
                    color: Palette.textOnDark,
                    shadows: <Shadow>[Shadow(blurRadius: 12)],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Hüter der Tiefe',
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 2,
                    color: Palette.enemyOnDark,
                    shadows: <Shadow>[Shadow(blurRadius: 8)],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Ein Balken mit Beschriftung darauf.
class PitBar extends StatelessWidget {
  const PitBar({
    super.key,
    required this.ratio,
    required this.color,
    required this.label,
    this.height = 14,
  });

  final double ratio;
  final Color color;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: height,
            backgroundColor: Palette.trackOnDark,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: height < 14 ? 8 : 10,
            fontWeight: FontWeight.bold,
            color: Palette.textOnDark,
          ),
        ),
      ],
    );
  }
}
