import 'package:achievements/achievements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:identity/identity.dart';

import '../ui/palette.dart';
import 'achievements_controller.dart';

/// Die Errungenschaften, nach Spielbereichen sortiert.
///
/// **Vier Reiter wie im Laden** (ADR-0033, Punkt 11) — und aus demselben
/// Grund: Siebenundzwanzig Einträge untereinander sind eine Rolle, durch
/// die man scrollt, statt sie zu lesen. Die vier Bereiche entsprechen den
/// Kreisen des Startbildschirms, die Zuordnung ist damit nie strittig.
///
/// **Zwei Arten, zwei Darstellungen.** Ein Meilenstein zeigt seinen
/// Fortschritt („37 / 50"), weil ein gesperrter Eintrag ohne Abstand zum
/// Ziel nur eine Absage ist. Eine Entdeckung zeigt ??? — sie verliert
/// alles, wenn man sie vorher lesen kann, und der leere Platz sagt
/// trotzdem, dass es etwas zu finden gibt.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  static const double _maxWidth = 560;

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  AchievementArea _area = AchievementArea.values.first;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(achievementStatsProvider);
    final verdient = ref.watch(earnedAchievementIdsProvider);
    final eintraege = AchievementCatalog.inArea(_area);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Errungenschaften'),
        backgroundColor: Palette.surface,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AchievementsScreen._maxWidth,
            ),
            child: Column(
              children: <Widget>[
                _RuhmZeile(
                  fame: ref.watch(fameProvider),
                  verdient: verdient.length,
                  gesamt: AchievementCatalog.all.length,
                ),
                _BereichsReiter(
                  aktiv: _area,
                  onWaehle: (area) => setState(() => _area = area),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: eintraege.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _Eintrag(achievement: eintraege[index], stats: stats),
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

/// Der Ruhm-Stand über allem.
///
/// **Eine Zahl zum Vergleichen, kein Guthaben** (ADR-0033, Punkt 5). Sie
/// steht hier oben, weil sie die einzige Zahl ist, die zwei Spieler
/// nebeneinanderhalten können — wie „17 / 30" bei der Reihe.
class _RuhmZeile extends StatelessWidget {
  const _RuhmZeile({
    required this.fame,
    required this.verdient,
    required this.gesamt,
  });

  final int fame;
  final int verdient;
  final int gesamt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Text(
              '$fame Ruhm',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Palette.accent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$verdient / $gesamt',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Palette.textDim),
            ),
          ),
        ],
      ),
    );
  }
}

class _BereichsReiter extends StatelessWidget {
  const _BereichsReiter({required this.aktiv, required this.onWaehle});

  final AchievementArea aktiv;
  final void Function(AchievementArea) onWaehle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: <Widget>[
          for (final area in AchievementArea.values) ...<Widget>[
            _Reiter(
              area: area,
              istAktiv: area == aktiv,
              onTap: () => onWaehle(area),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Reiter extends ConsumerWidget {
  const _Reiter({
    required this.area,
    required this.istAktiv,
    required this.onTap,
  });

  final AchievementArea area;
  final bool istAktiv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stand = ref.watch(areaProgressProvider(area));

    return Semantics(
      button: true,
      selected: istAktiv,
      child: Material(
        color: istAktiv ? Palette.accent : Palette.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  area.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: istAktiv ? Palette.surface : Palette.textDim,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${stand.earned}/${stand.total}',
                  style: TextStyle(
                    fontSize: 11,
                    color: istAktiv ? Palette.surface : Palette.muted,
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

/// Ein Eintrag in der Liste.
class _Eintrag extends StatelessWidget {
  const _Eintrag({required this.achievement, required this.stats});

  final Achievement achievement;
  final AchievementStats stats;

  @override
  Widget build(BuildContext context) {
    final verdient = achievement.isEarnedBy(stats);
    // Eine unverdiente Entdeckung verrät weder Namen noch Bedingung.
    final versteckt = !verdient && achievement.isDiscovery;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: verdient ? Palette.surfaceRaised : Palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: verdient ? Border.all(color: Palette.accent, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                verdient
                    ? Icons.emoji_events
                    : versteckt
                    ? Icons.help_outline
                    : Icons.lock_outline,
                size: 20,
                color: verdient ? Palette.accent : Palette.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  versteckt ? '???' : achievement.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: verdient ? Palette.text : Palette.textDim,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${achievement.tier.fame} Ruhm',
                style: const TextStyle(fontSize: 12, color: Palette.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            versteckt ? 'Noch nicht entdeckt' : achievement.requirement,
            style: const TextStyle(fontSize: 12, color: Palette.textDim),
          ),
          // Der Abstand zum Ziel — nur bei Meilensteinen, und nur solange
          // sie offen sind.
          if (!verdient && achievement.isMilestone) ...<Widget>[
            const SizedBox(height: 8),
            _Fortschritt(achievement: achievement, stats: stats),
          ],
          if (verdient) ...<Widget>[
            const SizedBox(height: 8),
            _Belohnung(achievement: achievement),
          ],
        ],
      ),
    );
  }
}

class _Fortschritt extends StatelessWidget {
  const _Fortschritt({required this.achievement, required this.stats});

  final Achievement achievement;
  final AchievementStats stats;

  @override
  Widget build(BuildContext context) {
    final stand = achievement.progressIn(stats);
    final anteil = achievement.target == 0
        ? 0.0
        : (stand / achievement.target).clamp(0.0, 1.0);

    return Row(
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: anteil,
              minHeight: 6,
              backgroundColor: Palette.surfaceSunken,
              valueColor: const AlwaysStoppedAnimation<Color>(Palette.accent),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$stand / ${achievement.target}',
          style: const TextStyle(fontSize: 12, color: Palette.textDim),
        ),
      ],
    );
  }
}

/// Was eine verdiente Errungenschaft eingebracht hat.
class _Belohnung extends StatelessWidget {
  const _Belohnung({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final teile = <String>[
      if (achievement.tier.xp > 0) '${achievement.tier.xp} XP',
      if (achievement.tier.gold > 0) '${achievement.tier.gold} Gold',
      if (achievement.titleId != null)
        'Titel „${TitleCatalog.byId(achievement.titleId)?.label ?? '?'}"',
      if (achievement.moveId != null) 'eine Fähigkeit',
    ];

    if (teile.isEmpty) {
      // Eine Entdeckung ohne Titel zahlt wirklich nichts außer Ruhm. Das
      // ist Absicht und darf ruhig dastehen.
      return const Text(
        'Nichts außer Ruhm.',
        style: TextStyle(fontSize: 12, color: Palette.muted),
      );
    }

    return Text(
      teile.join(' · '),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Palette.success,
      ),
    );
  }
}
