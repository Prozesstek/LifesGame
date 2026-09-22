import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/on_dark.dart';
import '../ui/palette.dart';
import 'action_game.dart';
import 'hero_power.dart';
import 'pit_run_view.dart';

/// **Prototyp.** Echtzeit-Kampf in einer Halle voller Gegner.
///
/// Er beantwortet eine Frage, die sich nicht ausrechnen lässt: Fühlt sich
/// der Kampf belohnender an, wenn Gegner unter einem zerfallen, statt
/// dass jeder einzelne knapp ausgeht? Die Zahlen dazu stehen in
/// `packages/action_combat/example/headless_run.dart`; hier steht das
/// Gefühl.
///
/// **Seit ADR-0039 ist die Grube der Kampf des Spiels** — gespielt wird
/// sie über `pit_screen.dart`. Dieser Bildschirm bleibt im
/// Entwicklermodus als Werkbank: dieselbe feste Halle, Grundwerte ohne
/// Stufe, und die Wahl der Machtstufe, an der die Potenz-Frage hängt.
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

  @override
  void dispose() {
    _game?.frame.dispose();
    super.dispose();
  }

  void _start(ActionStats stats) {
    _game?.frame.dispose();
    // Im Entwicklermodus liegen drei Fähigkeiten fest auf den Plätzen —
    // Schaden auf Entfernung, Fläche, Heilung. Zum Ausprobieren, nicht
    // als Regel; im Spiel liegt dort, was der Charakter angelegt hat.
    final sim = ActionWorld(
      level: LevelCatalog.grube,
      heroStats: stats,
      abilityIds: const <String>['funkenstoss', 'klingenwirbel', 'bluetentau'],
    );
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
  ActionStats _echteWerte() => ref.read(heroPowerProvider).stats;

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
        child: Stack(
          children: <Widget>[
            if (game != null) Positioned.fill(child: PitRunView(game: game)),
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
                'Unten rechts liegen drei Fähigkeiten: Funkenstoß, '
                'Klingenwirbel, Blütentau — auf der Tastatur 1, 2, 3.\n\n'
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
