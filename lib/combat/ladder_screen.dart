import 'package:combat/combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gear/gear_controller.dart';
import '../ui/palette.dart';
import 'combat_controller.dart';
import 'combat_screen.dart';
import 'enemy_icon.dart';
import 'enemy_outlook.dart';
import 'ladder_controller.dart';

/// Die Gegnerreihe — dreißig Stufen, eine nach der anderen.
///
/// **Sie ersetzt die Gegnerwahl** (Issue #36, ADR-0032). Vorher standen
/// drei Gegner zur Auswahl; jetzt gibt es genau einen nächsten. Das ist
/// weniger Freiheit und mehr Aussage: Die Zahl oben ist das, was zwei
/// Spieler im Teststart miteinander vergleichen.
///
/// **Warum kein Blättern durch die geschlagenen.** Der Entwurf zeigt
/// einen Gegner und einen Knopf. Wer hängenbleibt, hat damit genau einen
/// Kampf im Spiel — das ist der bewusste Preis dafür, dass der Bildschirm
/// keine zweite Frage stellt. Ein erneuter Sieg gegen einen längst
/// geschlagenen Gegner brächte ohnehin nichts (ADR-0032).
class LadderScreen extends ConsumerWidget {
  const LadderScreen({super.key});

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stand = ref.watch(ladderProvider);
    final gegner = ref.watch(nextEnemyProvider);
    final stats = ref.watch(equippedStatsProvider);

    final aussicht = outlookFor(
      gegner,
      playerAttack: stats.attack,
      playerHp: stats.maxHp,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Kampf')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: <Widget>[
                  _Fortschritt(stand: stand),
                  const SizedBox(height: 14),
                  Expanded(child: _GegnerBild(enemy: gegner)),
                  const SizedBox(height: 14),
                  _Namensleiste(enemy: gegner, aussicht: aussicht),
                  const SizedBox(height: 10),
                  _Belohnung(stand: stand),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _start(context, ref, gegner),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Kampf'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _start(BuildContext context, WidgetRef ref, EnemyBlueprint enemy) {
    // **Erst wählen, dann neu aufsetzen, dann öffnen.** `restart()` baut
    // die Sitzung samt Engine neu — und die Engine muss den Gegner schon
    // kennen. Die umgekehrte Reihenfolge hatte den Kampf einmal ohne
    // einen einzigen Move-Knopf hinterlassen (`docs/context/gotchas.md`).
    ref.read(selectedEnemyProvider.notifier).select(enemy);
    ref.read(combatControllerProvider.notifier).restart();

    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CombatScreen()));
  }
}

/// „7 / 30" mit Balken — die Zahl, die zwei Spieler vergleichen.
class _Fortschritt extends StatelessWidget {
  const _Fortschritt({required this.stand});

  final LadderProgress stand;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          '${stand.highestDefeated} / ${Enemies.rungs}',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: stand.highestDefeated / Enemies.rungs,
            minHeight: 7,
            backgroundColor: Palette.surfaceRaised,
            valueColor: const AlwaysStoppedAnimation<Color>(Palette.accent),
          ),
        ),
      ],
    );
  }
}

/// Die Bildfläche des Gegners — oder ein Platzhalter, solange es keine
/// Bilder gibt.
class _GegnerBild extends StatelessWidget {
  const _GegnerBild({required this.enemy});

  final EnemyBlueprint enemy;

  @override
  Widget build(BuildContext context) {
    final bild = EnemyIcons.forEnemyId(enemy.id);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.surfaceRaised, width: 2),
      ),
      padding: const EdgeInsets.all(12),
      child: bild == null
          ? const _KeinBild()
          : Image.asset(
              bild,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              errorBuilder: (context, error, stack) => const _KeinBild(),
            ),
    );
  }
}

class _KeinBild extends StatelessWidget {
  const _KeinBild();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.sports_martial_arts,
        size: 72,
        color: Palette.surfaceRaised,
      ),
    );
  }
}

/// Name des Gegners und die Einschätzung darunter.
class _Namensleiste extends StatelessWidget {
  const _Namensleiste({required this.enemy, required this.aussicht});

  final EnemyBlueprint enemy;
  final EnemyOutlook aussicht;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Text(
            enemy.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${enemy.maxHp} HP · ${enemy.attack} Angriff · '
            '${enemy.defense} Verteidigung',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Palette.textDim),
          ),
          const SizedBox(height: 4),
          Text(
            aussicht.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: aussicht.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Was dieser Sieg einbringt — oder dass er nichts mehr einbringt.
///
/// **Die Zeile gehört vor den Kampf, nicht nur danach.** Eine Belohnung,
/// von der man erst hinterher erfährt, motiviert den Kampf nicht, den man
/// gerade überlegt.
class _Belohnung extends StatelessWidget {
  const _Belohnung({required this.stand});

  final LadderProgress stand;

  @override
  Widget build(BuildContext context) {
    final rung = stand.nextRung;
    final neu = stand.isNewGround(rung);

    return Text(
      neu
          ? 'Erster Sieg: +${LadderRewards.xpFor(rung)} Erfahrung, '
                '+${LadderRewards.goldFor(rung)} Gold'
          : 'Schon geschlagen — bringt nichts mehr ein.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: neu ? Palette.gold : Palette.muted),
    );
  }
}
