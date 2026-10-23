import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haustier/haustier.dart';

import '../../habits/habits_controller.dart';
import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../haustier_controller.dart';
import 'haustier_bild.dart';
import 'haustier_blatt.dart';

/// **Das Haustier auf der Startseite** (Prototyp, 22.10.2026) — über
/// „Heute“, damit es dort reagiert, wo abgehakt wird: Mit jedem Häkchen
/// springt es, an Tagen „In Form“ spielt es, nachts schläft es.
///
/// Ohne Ei steht hier die Wahl zwischen dreien. Ein Tipp auf das Tier
/// öffnet sein Blatt.
///
/// **Nur das Tier und sein Level** (Frederik, 23.10.2026, mit einer
/// Skizze: „Bei Haustier nur Level drunter anzeigen“). Name, Stufe und
/// der Balken bis zum nächsten Level stehen im Blatt.
///
/// Seit ADR-0086 **in jeder Fassung**, sobald es eine Gewohnheit gibt
/// (gefragt auf der Startseite). Nur das Vorspulen im Blatt bleibt dem
/// Entwicklermodus.
class HaustierKarte extends ConsumerWidget {
  const HaustierKarte({super.key});

  static Key eiKey(HaustierArt art) =>
      ValueKey<String>('haustier-ei-${art.name}');

  static const Key tierKey = ValueKey<String>('haustier-tier');

  /// Die Marke mit dem Level unter dem Tier.
  static const Key levelKey = ValueKey<String>('haustier-level');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stand = ref.watch(haustierProvider);
    final art = stand.art;
    if (art == null) return const _EiWahl();

    final tage = ref.watch(haustierTageProvider);
    final stufe = HaustierWachstum.stufeFuer(tage);
    final level = HaustierWachstum.levelFuer(tage);
    final heute = ref.watch(todayProvider);
    final tracker = ref.watch(habitTrackerProvider);

    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Druck(
        child: InkWell(
          key: tierKey,
          onTap: () => zeigeHaustierBlatt(context),
          borderRadius: BorderRadius.circular(8),
          child: Semantics(
            label: '${stand.anzeigeName}, Level $level',
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  HaustierBild(
                    art: art,
                    stufe: stufe,
                    laune: ref.watch(haustierLauneProvider),
                    praegung: ref.watch(haustierPraegungProvider),
                    zubehoer: <ZubehoerPlatz, Zubehoer>{
                      for (final platz in ZubehoerPlatz.values)
                        if (stand.angelegtAuf(platz, stufe)
                            case final Zubehoer z)
                          platz: z,
                    },
                    groesse: 92,
                    // Jedes Häkchen von heute ist ein Sprung.
                    sprung: tracker.completedOn(heute),
                  ),
                  // Unten rechts neben dem Tier, wie auf der Skizze.
                  Positioned(
                    right: -18,
                    bottom: 2,
                    child: _LevelMarke(level: level),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Das Level des Tiers als kleine Marke — dunkel mit Holzkante, damit
/// sie nicht mit dem Level-Abzeichen des Spielers verwechselt wird.
class _LevelMarke extends StatelessWidget {
  const _LevelMarke({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: HaustierKarte.levelKey,
      constraints: const BoxConstraints(minWidth: 26),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Palette.abzeichenGrund,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Holz.kante, width: 1.5),
      ),
      child: Text(
        '$level',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Palette.textOnDark,
        ),
      ),
    );
  }
}

/// **Drei Eier zur Wahl** (Frederik, 22.10.2026). Gewählt wird einmal.
class _EiWahl extends ConsumerWidget {
  const _EiWahl();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Welches Ei?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Palette.text,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              for (final art in HaustierArt.values)
                Expanded(
                  child: Druck(
                    child: InkWell(
                      key: HaustierKarte.eiKey(art),
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          ref.read(haustierProvider.notifier).waehle(art),
                      child: Column(
                        children: <Widget>[
                          HaustierBild(
                            art: art,
                            stufe: HaustierStufe.ei,
                            laune: HaustierLaune.wartet,
                            groesse: 84,
                          ),
                          Text(
                            art.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Palette.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
