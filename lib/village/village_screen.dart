import 'package:action_combat/action_combat.dart' show Vec2;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../action/pit_gate.dart';
import '../character/character_screen.dart';
import '../combat/ladder_screen.dart';
import '../gear/shop_screen.dart';
import '../habits/habits_controller.dart';
import '../habits/habits_screen.dart';
import '../progression/level_provider.dart';
import '../theory/skill_tree_screen.dart';
import '../ui/druck.dart';
import '../ui/gold_icon.dart';
import '../ui/on_dark.dart';
import '../ui/palette.dart';
import 'village_game.dart';
import 'village_map.dart';

/// **Das Dorf** — Prototyp im Entwicklermodus: statt fünf Kreisen ein Ort,
/// in dem die Figur herumläuft. Die Bücherei führt in die Theorie, die
/// Höhle in die Grube, das Brett zu den Gewohnheiten, das Haus zum
/// Charakter.
///
/// **Zwei Regeln, damit es dem Häkchen nicht schadet:** Antippen führt
/// hin — Laufen ist ein Angebot, kein Zwang. Und die Gewohnheiten sind
/// oben rechts immer einen Tipp entfernt.
///
/// **Hinein geht es über einen Knopf am Gebäude**, nicht von selbst: Wer
/// vor einer Tür steht, sieht „Bücherei betreten", und erst der öffnet
/// den Ort. Ein zweiter Tipp auf das Gebäude tut dasselbe.
class VillageScreen extends ConsumerStatefulWidget {
  const VillageScreen({super.key});

  @override
  ConsumerState<VillageScreen> createState() => _VillageScreenState();
}

class _VillageScreenState extends ConsumerState<VillageScreen> {
  late final VillageGame _spiel = VillageGame(walker: VillageWalker(village));

  Offset? _zugStart;

  /// Welche Tasten gerade gedrückt sind — am Rechner läuft man mit WASD.
  final Set<LogicalKeyboardKey> _tasten = <LogicalKeyboardKey>{};

  Widget _ziel(VillagePlace ort) => switch (ort) {
    VillagePlace.buecherei => const SkillTreeScreen(),
    VillagePlace.hoehle => const LadderScreen(),
    VillagePlace.laden => const ShopScreen(),
    VillagePlace.zuhause => const CharacterScreen(),
    VillagePlace.brett => const HabitsScreen(),
  };

  Future<void> _betrete(VillagePlace ort) async {
    // Die Höhle ist zu, solange der Kampf es ist — derselbe Satz wie auf
    // dem Kreis der Startseite (ADR-0020).
    if (ort == VillagePlace.hoehle && !ref.read(combatUnlockedProvider)) {
      final grund = ref.read(combatBlockReasonProvider);
      _spiel.walker.stepOutOf(ort);
      if (grund != null && mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(grund)));
      }
      return;
    }
    await _oeffne(ort);
  }

  Future<void> _oeffne(VillagePlace ort) async {
    _spiel.paused = true;
    _tasten.clear();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => _ziel(ort)));
    _spiel.walker.stepOutOf(ort);
    _spiel.paused = false;
  }

  void _tippe(Offset punkt) {
    final welt = _spiel.screenToWorld(punkt);
    final feld = VillageMap.tileOf(welt);
    final hier = _spiel.walker.atDoor;
    // Steht die Figur schon vor diesem Gebäude, heisst ein Tipp darauf:
    // hinein.
    if (hier != null && village.placeAt(feld.x, feld.y) == hier) {
      _betrete(hier);
      return;
    }
    _spiel.walker.walkTo(welt);
  }

  void _ziehe(Offset punkt) {
    final start = _zugStart;
    if (start == null) return;
    final d = punkt - start;
    const totzone = 8.0;
    const voll = 56.0;
    if (d.distance < totzone) {
      _spiel.moveInput = Vec2.zero;
      return;
    }
    final anteil = (d.distance / voll).clamp(0.0, 1.0);
    _spiel.moveInput = Vec2(d.dx / d.distance, d.dy / d.distance) * anteil;
  }

  KeyEventResult _taste(FocusNode _, KeyEvent e) {
    if (e is KeyDownEvent) _tasten.add(e.logicalKey);
    if (e is KeyUpEvent) _tasten.remove(e.logicalKey);
    bool an(LogicalKeyboardKey a, LogicalKeyboardKey b) =>
        _tasten.contains(a) || _tasten.contains(b);
    final x =
        (an(LogicalKeyboardKey.keyD, LogicalKeyboardKey.arrowRight) ? 1 : 0) -
        (an(LogicalKeyboardKey.keyA, LogicalKeyboardKey.arrowLeft) ? 1 : 0);
    final y =
        (an(LogicalKeyboardKey.keyS, LogicalKeyboardKey.arrowDown) ? 1 : 0) -
        (an(LogicalKeyboardKey.keyW, LogicalKeyboardKey.arrowUp) ? 1 : 0);
    _spiel.moveInput = Vec2(x.toDouble(), y.toDouble()).clampLength(1);
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: _taste,
        child: Stack(
          children: <Widget>[
            // Ohne eigenen Fokus: Flames Spielfeld schluckt sonst jede
            // Taste (`gotchas.md`).
            Positioned.fill(child: GameWidget(game: _spiel, autofocus: false)),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _tippe(d.localPosition),
                onPanStart: (d) => _zugStart = d.localPosition,
                onPanUpdate: (d) => _ziehe(d.localPosition),
                onPanEnd: (_) {
                  _zugStart = null;
                  _spiel.moveInput = Vec2.zero;
                },
              ),
            ),
            Positioned.fill(
              child: _TuerKnopf(spiel: _spiel, onEnter: _betrete),
            ),
            const SafeArea(child: _Kopf()),
          ],
        ),
      ),
    );
  }
}

/// Der kleine Knopf über dem Gebäude, vor dessen Tür die Figur steht.
///
/// Er wandert mit der Kamera über [VillageGame.frame] — nur er baut sich
/// dabei neu, nicht der ganze Bildschirm.
class _TuerKnopf extends StatelessWidget {
  const _TuerKnopf({required this.spiel, required this.onEnter});

  final VillageGame spiel;
  final void Function(VillagePlace ort) onEnter;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: spiel.frame,
      builder: (context, _, _) {
        final ort = spiel.walker.atDoor;
        final flaeche = ort == null ? null : village.bodies[ort];
        if (ort == null || flaeche == null) return const SizedBox.shrink();

        const t = VillageMap.tileSize;
        final mitte = spiel.worldToScreen(
          Vec2(
            (flaeche.from.x + flaeche.to.x + 1) / 2 * t,
            (flaeche.from.y + flaeche.to.y + 1) / 2 * t,
          ),
        );
        return Stack(
          children: <Widget>[
            Positioned(
              left: mitte.dx,
              top: mitte.dy,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -0.5),
                child: Druck(
                  child: Material(
                    color: Palette.accent,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 3,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onEnter(ort),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          '${ort.label} betreten',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Palette.surface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Oben: zurück, Level und Gold, und rechts die Gewohnheiten des Tages.
class _Kopf extends ConsumerWidget {
  const _Kopf();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(playerLevelProvider).level;
    final gold = ref.watch(goldProvider);
    final tracker = ref.watch(habitTrackerProvider);
    final heute = ref.watch(todayProvider);
    final erledigt = tracker.completedOn(heute);
    final gesamt = tracker.activeIds.length;

    return OnDark(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Zurück',
            ),
            const SizedBox(width: 8),
            // Schrumpfbar (`gotchas.md`): Auf dem Handy teilen sich
            // Zurück, dieses Schild und „Heute" eine Zeile.
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _Schild(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          'Level $level',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Palette.textOnDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const GoldIcon(size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$gold',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Palette.goldOnDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // **Das Häkchen bleibt einen Tipp entfernt.** Wer nur abhaken
            // will, muss nicht zum Brett laufen.
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HabitsScreen()),
              ),
              icon: Icon(
                gesamt > 0 && erledigt >= gesamt
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                size: 18,
              ),
              label: Text('Heute $erledigt/$gesamt'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Schild extends StatelessWidget {
  const _Schild({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.background.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Palette.accentOnDark),
      ),
      child: child,
    );
  }
}
