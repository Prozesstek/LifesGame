import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progression/progression.dart';
import 'package:theory/theory.dart';

import '../audio/sound_effects.dart';
import '../skills/gebiet_farbe.dart';
import '../theory/theory_controller.dart';
import '../theory/vorschlag_flow.dart';
import '../theory/widgets/tree_overview.dart';
import '../ui/druck.dart';
import '../ui/holz.dart';
import '../ui/palette.dart';
import 'level_provider.dart';
import 'level_roadmap.dart';
import '../ui/gehrung.dart';

/// Das Level vor einer Handlung — **vorher** lesen, danach ist der
/// Unterschied verschwunden.
int levelBefore(WidgetRef ref) => ref.read(playerLevelProvider).level;

/// Feiert einen Aufstieg seit [before], wenn es einen gab.
///
/// **Aufgerufen wird das dort, wo schon gefeiert wird** — nach einem
/// Häkchen, einer Lektion, einem Lauf, einem Kauf — und immer **nach**
/// den Errungenschaften und **vor** den Fähigkeiten: Eine Errungenschaft
/// kann die Erfahrung bringen, die das Level hebt, und ein Level kann den
/// Platz öffnen, auf den eine neue Fähigkeit kommt. Kein Beobachter, der
/// von selbst horcht: Er feuerte auch beim Laden und im Entwicklermodus
/// (dieselbe Begründung wie bei `showAbilityUnlocks`).
Future<void> showLevelUp(
  BuildContext context,
  WidgetRef ref, {
  required int before,
}) async {
  final auf = LevelUp.between(before, ref.read(playerLevelProvider).level);
  if (!auf.isLevelUp || !context.mounted) return;

  unawaited(HapticFeedback.heavyImpact());
  ref.read(soundPlayerProvider).play(SoundEffect.errungenschaft);
  // **Bringt das Level einen Punkt, steht darunter, wofür** (26.10.2026):
  // dieselben Vorschläge wie oben im Baum, ohne Gebiet vorneweg.
  final graph = ref.read(theoryGraphProvider);
  final vorschlaege = auf.theoryPoints > 0
      ? <(TheoryVorschlag, Color)>[
          for (final v in ref.read(vorschlaegeProvider(null)))
            (
              v,
              switch (gebietVon(graph, v.node.id)) {
                final g? => GebietFarbe.pergament(g),
                null => Palette.accent,
              },
            ),
        ]
      : const <(TheoryVorschlag, Color)>[];
  final gewaehlt = await showDialog<TheoryStep>(
    context: context,
    builder: (dialog) => HolzDialog(
      art: RahmenArt.messing,
      child: LevelUpSheet(
        levelUp: auf,
        vorschlaege: vorschlaege,
        onVorschlag: (step) => Navigator.of(dialog).pop(step),
      ),
    ),
  );
  if (gewaehlt != null && context.mounted) {
    await lieseVorschlag(context, ref, gewaehlt);
  }
}

/// Das Blatt selbst: die Zahl springt hoch, darunter, was sie bringt.
class LevelUpSheet extends StatelessWidget {
  const LevelUpSheet({
    required this.levelUp,
    this.vorschlaege = const <(TheoryVorschlag, Color)>[],
    this.onVorschlag,
    super.key,
  });

  final LevelUp levelUp;

  /// Wohin der neue Punkt gehen könnte, je mit der Farbe seines Gebiets.
  /// Leer, wenn der Aufstieg keinen Punkt bringt.
  final List<(TheoryVorschlag, Color)> vorschlaege;

  /// Ein Tipp auf einen Vorschlag — öffnet und liest ihn.
  final ValueChanged<TheoryStep>? onVorschlag;

  /// Woran Tests einen Vorschlag finden.
  static Key vorschlagKey(String nodeId) =>
      ValueKey<String>('aufstieg-vorschlag-$nodeId');

  /// Die Zeile „Als Nächstes“ — für Tests.
  static const Key ausblickKey = ValueKey<String>('aufstieg-ausblick');

  /// „4 %" aus einem Faktor von 1,04.
  static String prozent(double faktor) => '${((faktor - 1) * 100).round()} %';

  @override
  Widget build(BuildContext context) {
    final auf = levelUp;
    final zeilen = <(IconData, String)>[
      (Icons.bolt, 'Im Kampf ${prozent(auf.powerGain)} stärker'),
      if (auf.theoryPoints > 0)
        (
          Icons.menu_book,
          auf.theoryPoints == 1
              ? '+1 Talentpunkt für den Talentbaum'
              : '+${auf.theoryPoints} Talentpunkte für den Talentbaum',
        ),
      // Plätze, Ultimate, Extras, Rahmen — eine Stelle mit der Roadmap
      // (ADR-0098).
      for (final g in LevelRoadmap.gewinne(auf)) (g.icon, g.feier),
    ];
    // **Was als Nächstes kommt** (ADR-0098): der nächste Meilenstein mit
    // seinem ersten Gewinn, damit man weiß, worauf man zuläuft.
    final naechster = LevelRoadmap.naechsterMeilenstein(auf.to);
    final ausblick = naechster == null
        ? null
        : LevelRoadmap.gewinneAuf(naechster).first;

    return AlertDialog(
      backgroundColor: Palette.surface,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Aufgestiegen!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Palette.accent,
            ),
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.3, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, s, child) =>
                Transform.scale(scale: s, child: child),
            child: TweenAnimationBuilder<int>(
              tween: IntTween(begin: auf.from, end: auf.to),
              duration: const Duration(milliseconds: 700),
              builder: (context, n, _) => Text(
                'Level $n',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Palette.gold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < zeilen.length; i++)
            _Zeile(icon: zeilen[i].$1, text: zeilen[i].$2, nummer: i),
          if (naechster != null && ausblick != null) ...<Widget>[
            const SizedBox(height: 8),
            _Ausblick(
              key: LevelUpSheet.ausblickKey,
              level: naechster,
              gewinn: ausblick,
              nummer: zeilen.length,
            ),
          ],
          if (vorschlaege.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            for (final (v, farbe) in vorschlaege)
              _Vorschlag(
                key: vorschlagKey(v.node.id),
                vorschlag: v,
                farbe: farbe,
                onTap: onVorschlag == null ? null : () => onVorschlag!(v.step),
              ),
          ],
        ],
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Weiter'),
        ),
      ],
    );
  }
}

/// Eine Zeile, die nach der vorigen hereinkommt.
class _Zeile extends StatelessWidget {
  const _Zeile({required this.icon, required this.text, required this.nummer});

  final IconData icon;
  final String text;
  final int nummer;

  @override
  Widget build(BuildContext context) {
    final start = 300 + 150 * nummer;
    final gesamt = start + 350;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: gesamt),
      curve: Interval(start / gesamt, 1, curve: Curves.easeOut),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - t)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: Palette.accent),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(fontSize: 15, color: Palette.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ein Vorschlag im Blatt des Aufstiegs: Zeichen des Grundes, Name,
/// Preis — wie oben im Baum, nur auf Pergament.
class _Vorschlag extends StatelessWidget {
  const _Vorschlag({
    required this.vorschlag,
    required this.farbe,
    required this.onTap,
    super.key,
  });

  final TheoryVorschlag vorschlag;
  final Color farbe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final preis = vorschlag.step.needsOpening ? vorschlag.node.cost : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Semantics(
        button: true,
        label:
            '${VorschlagZeichen.wortOf(vorschlag.grund)}: '
            '${vorschlag.node.name}',
        excludeSemantics: true,
        child: Druck(
          child: Material(
            color: farbe.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      VorschlagZeichen.of(vorschlag.grund),
                      size: 18,
                      color: farbe,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vorschlag.node.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Palette.text,
                        ),
                      ),
                    ),
                    if (preis != null) ...<Widget>[
                      const SizedBox(width: 6),
                      PunktPreis(cost: preis, color: Palette.gold),
                    ],
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: farbe),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// **Was als Nächstes kommt** — blass unter dem, was gerade kam:
/// „Level 5 · Haustier“ (ADR-0098).
class _Ausblick extends StatelessWidget {
  const _Ausblick({
    required this.level,
    required this.gewinn,
    required this.nummer,
    super.key,
  });

  final int level;
  final RoadmapGewinn gewinn;
  final int nummer;

  @override
  Widget build(BuildContext context) {
    final start = 300 + 150 * nummer;
    final gesamt = start + 350;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: gesamt),
      curve: Interval(start / gesamt, 1, curve: Curves.easeOut),
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Semantics(
        label: 'Als Nächstes: Level $level, ${gewinn.name}',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Palette.surfaceSunken.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.arrow_upward_rounded,
                size: 16,
                color: Palette.muted,
              ),
              const SizedBox(width: 6),
              Text(
                'Level $level',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Palette.textDim,
                ),
              ),
              const SizedBox(width: 10),
              Icon(gewinn.icon, size: 16, color: Palette.textDim),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  gewinn.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Palette.textDim),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
