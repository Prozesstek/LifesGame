import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';
import 'package:identity/identity.dart';
import 'package:progression/progression.dart';

import '../../achievements/achievements_controller.dart';
import '../../character/identity_controller.dart';
import '../../combat/widgets/teilen_knopf.dart';
import '../../habits/habits_controller.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../gebiet_farbe.dart';
import '../gebiet_zeichen.dart';
import '../skill_text.dart';
import '../skills_provider.dart';

/// Die Skills im Charakter (ADR-0085): oben das Gesamtlevel und der Knopf
/// zum Teilen, darunter je Gebiet Zeichen, Name, Balken und Stufe.
///
/// **Steht über der Beständigkeit**, nicht darunter: Die Kette ist der
/// Grund, morgen wiederzukommen, der Skill ist, was davon bleibt — und
/// das soll man zuerst sehen.
class SkillKarte extends ConsumerWidget {
  const SkillKarte({super.key});

  static const Key teilenKey = ValueKey<String>('skills-teilen');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills = ref.watch(skillsProvider);
    final identity = ref.watch(identityProvider);
    final verdient = ref.watch(earnedTitleIdsProvider);
    final titel = TitleCatalog.isEarned(identity.chosenTitleId, verdient)
        ? TitleCatalog.byId(identity.chosenTitleId)?.label
        : null;

    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Tooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  message:
                      'Gesamtlevel: alle vier Gebiete zusammen. Was du in '
                      'einem Gebiet getan und gelesen hast, bleibt — auch '
                      'wenn eine Kette fällt.',
                  child: Semantics(
                    label: 'Gesamtlevel ${skills.gesamt}',
                    excludeSemantics: true,
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.functions_rounded,
                          size: 20,
                          color: Palette.accent,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${skills.gesamt}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Palette.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              TeilenKnopf(
                key: teilenKey,
                compact: true,
                text: SkillText.teilen(
                  skills: skills,
                  longestStreak: ref.watch(habitTrackerProvider).longestStreak,
                  name: identity.name,
                  titel: titel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final area in SkillArea.values) ...<Widget>[
            _GebietZeile(area: area, skill: skills.of(area)),
            if (area != SkillArea.values.last) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

/// Ein Gebiet: Zeichen, Name, Balken, Stufe. Was bis zur nächsten fehlt,
/// steht im Tipp.
class _GebietZeile extends StatelessWidget {
  const _GebietZeile({required this.area, required this.skill});

  final SkillArea area;
  final SkillLevel skill;

  @override
  Widget build(BuildContext context) {
    final noch = skill.isMaxLevel
        ? '${area.label}: höchste Stufe'
        : '${area.label}: noch ${skill.xpToNextLevel} Erfahrung bis '
              'Stufe ${skill.level + 1}';
    final farbe = GebietFarbe.pergament(area);

    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      message: noch,
      child: Semantics(
        label: '${area.label}, Stufe ${skill.level}',
        excludeSemantics: true,
        child: Row(
          children: <Widget>[
            Icon(gebietZeichen(area), size: 18, color: farbe),
            const SizedBox(width: 8),
            SizedBox(
              width: 104,
              child: Text(
                area.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Palette.text,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: skill.ratio,
                  minHeight: 6,
                  backgroundColor: Palette.muted.withValues(alpha: 0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(farbe),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 30,
              child: Text(
                '${skill.level}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Palette.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
