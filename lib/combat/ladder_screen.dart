import 'package:combat/combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/palette.dart';
import 'combat_controller.dart';
import 'combat_screen.dart';
import 'enemy_icon.dart';
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
                  _Namensleiste(enemy: gegner),
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
          // Die Zahl steht auf dem Leder, nicht auf einer Fläche — und
          // sie ist die Überschrift des Bildschirms.
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Palette.textOnDark,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: stand.highestDefeated / Enemies.rungs,
            minHeight: 7,
            backgroundColor: Palette.trackOnDark,
            valueColor: const AlwaysStoppedAnimation<Color>(
              Palette.accentOnDark,
            ),
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

    // **Quadratisch, weil die Bilder es sind.** Der Entwurf zeigt eine
    // hochkante Flaeche; gezeichnet wird aber auf 64 x 64. Ein
    // quadratisches Bild in einer hochkanten Flaeche liesse rund 144
    // Punkte Rahmen leer, und das sieht aus wie ein Fehler. Der Rahmen
    // richtet sich deshalb nach dem Bild, nicht umgekehrt -- der
    // uebrige Platz wird zu Luft darum herum.
    return Center(
      child: AspectRatio(aspectRatio: 1, child: _Rahmen(bild: bild)),
    );
  }
}

class _Rahmen extends StatelessWidget {
  const _Rahmen({required this.bild});

  final String? bild;

  @override
  Widget build(BuildContext context) {
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
              bild!,
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

/// Name und Werte des Gegners.
///
/// **Ohne Einschätzung.** Bis Issue #36 stand hier „wird knapp" oder
/// „vermutlich noch zu stark" — geerbt von der Gegnerwahl, wo sie eine
/// Entscheidung stützte. In der Reihe gibt es nichts zu entscheiden: Es
/// steht genau ein Gegner an, und ob er zu stark ist, sagt der Kampf.
/// Eine Vorhersage, die man ohnehin nicht befolgen kann, ist Reibung.
class _Namensleiste extends StatelessWidget {
  const _Namensleiste({required this.enemy});

  final EnemyBlueprint enemy;

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
              color: Palette.text,
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
      style: TextStyle(
        fontSize: 12,
        color: neu ? Palette.goldOnDark : Palette.textOnDarkDim,
      ),
    );
  }
}
