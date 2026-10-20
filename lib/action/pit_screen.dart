import 'dart:math' as math;

import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:gear/gear.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../progression/level_provider.dart';
import '../progression/show_level_up.dart';

import '../achievements/show_achievement_unlock.dart';
import '../audio/sound_effects.dart';
import '../character/abilities_controller.dart';
import '../combat/ladder_controller.dart';
import '../combat/widgets/loot_dialog.dart';
import '../combat/widgets/lauf_ergebnis.dart';
import '../gear/gear_controller.dart';
import '../gear/set_effects.dart';
import '../home/erster_start_provider.dart';
import '../home/home_screen.dart' show HomeScreen;
import '../theory/skill_tree_screen.dart';
import '../ui/on_dark.dart';
import '../ui/palette.dart';
import '../ui/pixel_art.dart';
import 'action_game.dart';
import 'hero_power.dart';
import 'lauf_verlassen.dart';
import 'lauf_zeichen.dart';
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

  /// Woran Tests den Weg zur Theorie nach einer Niederlage finden.
  static const Key lesenKey = ValueKey<String>('grube-lesen');

  /// Woran Tests die Knöpfe der Rückfrage finden.
  static const Key abbrechenKey = ValueKey<String>('grube-abbrechen');
  static const Key bleibenKey = ValueKey<String>('grube-bleiben');

  @override
  ConsumerState<PitScreen> createState() => _PitScreenState();
}

class _PitScreenState extends ConsumerState<PitScreen> {
  final math.Random _wuerfel = math.Random();

  late ActionGame _game;
  bool _ergebnisGezeigt = false;
  bool _verloren = false;
  bool _abgebrochen = false;

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
      // Die Ultimate, ab Level 15 auf ihrem eigenen Platz (ADR-0073).
      ultimateId: ref.read(activeUltimateProvider),
      weaponMoveId: waffe,
      modifiers: veraenderungen,
      seed: seed,
    );

    return ActionGame(
      sim: welt,
      klang: ref.read(soundPlayerProvider),
      // Wo der Balken unten beginnt — dieselbe Erfahrung, aus der die
      // Startseite das Level rechnet.
      startXp: ref.read(effectiveXpProvider),
      // Bis die erste Stufe geschafft ist, erklärt sich die Grube
      // (ADR-0069). Ein neuer Stand je Lauf: Wer verliert und „Nochmal“
      // drückt, sieht die Zeichen wieder.
      zeichen: ref.read(ersterStartProvider).grubeErklaertSich
          ? LaufZeichen()
          : null,
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
    // Mit `setState`: Der `PopScope` liest den Wert beim Bauen, und nach
    // einem Sieg geht es ohne Rückfrage zurück.
    setState(() => _ergebnisGezeigt = true);

    final welt = _game.sim;
    final gewonnen = welt.isWon;
    final stufe = widget.stage.number;

    final vorherErrungen = achievementsBefore(ref);
    final vorherLevel = levelBefore(ref);
    final vorherReihe = ref.read(ladderProvider);
    final ersterSieg = gewonnen && stufe > vorherReihe.highestDefeated;
    final vorherBest = vorherReihe.bestTimes[stufe];
    ref.read(ladderProvider.notifier).recordKills(welt);
    final ertrag = ref
        .read(ladderProvider.notifier)
        .recordRun(
          stufe,
          won: gewonnen,
          collected: (xp: welt.runXp, gold: welt.runGold),
          seconds: welt.elapsed,
        );
    final best = ref.read(ladderProvider).bestTimes[stufe];
    final neueBestzeit = gewonnen && best != null && best != vorherBest;
    if (gewonnen) ref.read(soundPlayerProvider).play(SoundEffect.sieg);

    final sekunden = welt.elapsed.round();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LaufErgebnis(
        won: gewonnen,
        stage: stufe,
        seconds: sekunden,
        earnedXp: ertrag.xp,
        earnedGold: ertrag.gold,
        newBest: neueBestzeit,
        timedOut: welt.isTimedOut,
      ),
    );

    if (!mounted) return;
    if (gewonnen) {
      await _beute(
        stufe,
        ersterSieg: ersterSieg,
        // Der erste Sieg überhaupt: Hier endet der Weg des Mentors.
        ersteBeute: vorherReihe.highestDefeated == 0,
      );
    }
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

  /// Die Beute des Wächters (ADR-0048): Der erste Sieg auf einer Stufe
  /// bringt sie ohne Schlüssel, jeder weitere nur mit einem — und nur,
  /// wenn man ihn einsetzen will.
  Future<void> _beute(
    int stufe, {
    required bool ersterSieg,
    required bool ersteBeute,
  }) async {
    final controller = ref.read(loadoutProvider.notifier);
    if (!ersterSieg) {
      final schluessel = ref.read(availableKeysProvider);
      if (schluessel <= 0) return;
      final oeffnen = await askToOpenLoot(
        context,
        stage: stufe,
        keys: schluessel,
      );
      if (!oeffnen || !mounted) return;
    }
    final beute = controller.takeLoot(stage: stufe, useKey: !ersterSieg);
    if (beute == null || !mounted) return;
    final slot = beute.item?.slot;
    final getragen = slot == null
        ? null
        : ref.read(loadoutProvider).equippedCopyIn(slot);
    final selten = (beute.item?.rarity.index ?? 0) >= GearRarity.rare.index;
    final anlegen = await showLoot(
      context,
      loot: beute,
      headline: ersterSieg
          ? 'Erster Sieg auf Stufe $stufe'
          : 'Die Beute des Wächters',
      worn: getragen?.uid == beute.uid ? null : getragen,
      usedKey: !ersterSieg,
      mentor: ersteBeute,
      onReveal: () => ref
          .read(soundPlayerProvider)
          .play(selten ? SoundEffect.errungenschaft : SoundEffect.beute),
    );
    if (anlegen && mounted) controller.equip(beute.uid);
  }

  /// Nach einer Niederlage zur Theorie — an die Stelle der Grube, damit
  /// „Zurück“ von dort zum Eingang führt und nicht in den verlorenen
  /// Lauf.
  void _zurTheorie() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const SkillTreeScreen()),
    );
  }

  /// „Zurück“ mitten im Lauf — auch die Geste vom Rand: fragen, bevor er
  /// verloren ist. Gebucht wird nur in [_zeigeErgebnis], wer jetzt geht,
  /// verliert also auch, was schon gefallen ist.
  Future<void> _fragtNachAbbrechen() async {
    final abbrechen = await fragtVorDemGehen(
      context,
      anhalten: _game.pauseEngine,
      weiter: _game.resumeEngine,
      titel: 'Lauf abbrechen?',
      satz: 'Was bisher gefallen ist, geht verloren.',
      gehen: 'Abbrechen',
      gehenKey: PitScreen.abbrechenKey,
      bleibenKey: PitScreen.bleibenKey,
    );
    if (!mounted || !abbrechen) return;
    setState(() => _abgebrochen = true);
    Navigator.of(context).pop();
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
    // **Die Niederlage zeigt den Weg** (ADR-0069): Solange keine Stufe
    // geschafft ist, steht neben „Nochmal“ das Buch. Wer zuerst kämpft,
    // soll danach wissen, wofür er liest (ADR-0068).
    final zeigtWeg = ref.watch(ersterStartProvider).grubeErklaertSich;

    // Gehen ohne Frage, sobald der Lauf vorbei ist: Das Ergebnis ist
    // gebucht, oder er ist verloren und „Zurück“ steht schon da.
    return PopScope(
      canPop: _ergebnisGezeigt || _abgebrochen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _fragtNachAbbrechen();
      },
      child: _seite(zeigtWeg),
    );
  }

  Widget _seite(bool zeigtWeg) {
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
                      if (zeigtWeg) ...<Widget>[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          key: PitScreen.lesenKey,
                          onPressed: _zurTheorie,
                          // Auf Leder, nicht auf Pergament: Die Farben
                          // des Themes wären hier kaum zu lesen.
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Palette.textOnDark,
                            side: const BorderSide(color: Palette.goldOnDark),
                          ),
                          icon: const PixelArt(
                            assetPath: HomeScreen.theorySymbol,
                            side: 22,
                            fallback: Icon(Icons.menu_book_outlined, size: 20),
                          ),
                          label: const Text('Stärker werden'),
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Palette.textOnDarkDim,
                        ),
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
