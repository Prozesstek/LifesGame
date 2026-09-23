import 'dart:math' as math;

import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:gear/gear.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../progression/show_level_up.dart';

import '../achievements/show_achievement_unlock.dart';
import '../audio/sound_effects.dart';
import '../character/abilities_controller.dart';
import '../combat/ladder_controller.dart';
import '../combat/widgets/result_dialog.dart';
import '../gear/gear_controller.dart';
import '../gear/set_effects.dart';
import '../ui/on_dark.dart';
import '../ui/palette.dart';
import 'action_game.dart';
import 'hero_power.dart';
import 'pit_run_view.dart';

/// Ein Lauf durch eine Stufe der Grube — der Kampf des Spiels (ADR-0039).
///
/// **Die Karte ist jedes Mal neu.** Der Startwert wird beim Betreten
/// gewürfelt; wer nach einer Niederlage „Nochmal" drückt, bekommt eine
/// andere Grube derselben Stufe.
///
/// **Die Werte frieren beim Betreten ein**, wie das Moveset im alten
/// Kampf: Wer mitten im Lauf die Ausrüstung wechselte, änderte sonst den
/// Helden unter dem eigenen Daumen.
class PitScreen extends ConsumerStatefulWidget {
  const PitScreen({super.key, required this.stage});

  final PitStage stage;

  @override
  ConsumerState<PitScreen> createState() => _PitScreenState();
}

class _PitScreenState extends ConsumerState<PitScreen> {
  final math.Random _wuerfel = math.Random();

  late ActionGame _game;
  bool _ergebnisGezeigt = false;
  bool _verloren = false;

  @override
  void initState() {
    super.initState();
    _game = _neuerLauf();
  }

  @override
  void dispose() {
    _game.frame.dispose();
    super.dispose();
  }

  ActionGame _neuerLauf() {
    final seed = _wuerfel.nextInt(1 << 30);
    final werte = ref.read(heroPowerProvider).stats;

    // **Die Plätze kommen aus `activeMovesProvider`** — der einzigen
    // Stelle, an der die Freischaltung einer Fähigkeit gilt. Eine
    // gelernte, aber abgelaufene Fähigkeit fällt dort heraus, nicht hier.
    // Der Waffenzug steht mit darin: Als Fähigkeit kennt die Grube ihn
    // nicht, als Waffe schon — er wird zum Grundangriff.
    final plaetze = ref.read(activeMovesProvider);
    final loadout = ref.read(loadoutProvider);
    final veraenderungen = pitModifiersFor(
      ref.read(activeSetsProvider),
      <GearItem>[for (final slot in GearSlot.values) ?loadout.equippedIn(slot)],
    );
    final waffe = plaetze.firstWhere(
      (id) => PitWeapons.byMoveId(id) != null,
      orElse: () => '',
    );

    final welt = ActionWorld(
      level: LevelBuilder.build(stage: widget.stage, seed: seed),
      // Der Rest des Topfs — je Gegner ein Teil, der Wächter den Rest
      // (ADR-0041).
      rewardPot: ref.read(ladderProvider.notifier).potFor(widget.stage.number),
      // Werte, Level und Seltenheit — zusammengesetzt an einer Stelle
      // (ADR-0042).
      heroStats: werte,
      stage: widget.stage,
      abilityIds: plaetze,
      weaponMoveId: waffe,
      modifiers: veraenderungen,
      seed: seed,
    );

    return ActionGame(
      sim: welt,
      onRunEnded: () {
        // **Erst nach dem Bild.** Das Ende wird aus der Flame-Schleife
        // gemeldet, also mitten in einem Frame; eine Route von dort aus
        // zu öffnen ist der Fallstrick aus `gotchas.md`.
        WidgetsBinding.instance.addPostFrameCallback((_) => _zeigeErgebnis());
      },
    );
  }

  /// Trägt das Ergebnis ein und zeigt das Blatt.
  ///
  /// **Hier und nur hier kommt ein Lauf in der Reihe an** — dieselbe
  /// Stelle, die im Rundenkampf `combat_screen.dart` war. Was er
  /// einbringt, rechnet `LadderController.recordRun`.
  Future<void> _zeigeErgebnis() async {
    if (!mounted || _ergebnisGezeigt) return;
    _ergebnisGezeigt = true;

    final welt = _game.sim;
    final gewonnen = welt.isWon;
    final stufe = widget.stage.number;

    final vorherErrungen = achievementsBefore(ref);
    final vorherLevel = levelBefore(ref);
    final ertrag = ref
        .read(ladderProvider.notifier)
        .recordRun(
          stufe,
          won: gewonnen,
          collected: (xp: welt.runXp, gold: welt.runGold),
        );
    if (gewonnen) ref.read(soundPlayerProvider).play(SoundEffect.sieg);

    final sekunden = welt.elapsed.round();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CombatResultDialog(
        won: gewonnen,
        rounds: 0,
        enemyName: 'Der Wächter',
        earnedXp: ertrag.xp,
        earnedGold: ertrag.gold,
        perStage: true,
        summary: gewonnen
            ? 'Stufe $stufe: Der Wächter liegt — ${welt.kills} Gegner in $sekunden s.'
            : 'Gefallen auf Stufe $stufe, nach ${welt.kills} von '
                  '${welt.totalEnemies} Gegnern.',
      ),
    );

    if (!mounted) return;
    await showAchievementUnlocks(context, ref, before: vorherErrungen);
    if (!mounted) return;
    await showLevelUp(context, ref, before: vorherLevel);
    if (!mounted) return;

    // **Nach einem Sieg zurück zur Grube**, dort steht schon die nächste
    // Stufe. Nach einer Niederlage bleibt man hier: „Nochmal" ist dann
    // genau der nächste Schritt.
    if (gewonnen) {
      await Navigator.of(context).maybePop();
    } else {
      setState(() => _verloren = true);
    }
  }

  void _nochmal() {
    _game.frame.dispose();
    setState(() {
      _game = _neuerLauf();
      _ergebnisGezeigt = false;
      _verloren = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        title: Text('Die Grube · Stufe ${widget.stage.number}'),
        backgroundColor: Palette.backgroundRaised,
        foregroundColor: Palette.textOnDark,
      ),
      body: OnDark(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              // Ein neuer Schlüssel je Lauf: Sonst behielte die Ansicht
              // den alten Fokus und die alten gedrückten Tasten.
              child: PitRunView(key: ObjectKey(_game), game: _game),
            ),
            if (_verloren)
              ColoredBox(
                color: Palette.background.withValues(alpha: 0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FilledButton(
                        onPressed: _nochmal,
                        child: const Text('Nochmal'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Zurück'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
