import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';
import 'package:progression/progression.dart';

import '../../ui/aufstieg.dart';
import '../../ui/beute_flug.dart';
import '../../ui/druck.dart';
import '../../ui/palette.dart';
import '../gebiet_farbe.dart';
import '../gebiet_zeichen.dart';
import '../skills_provider.dart';

/// **Die vier Gebiete oben auf dem Gewohnheiten-Bildschirm**, jedes in
/// seiner Farbe: Zeichen, Stufe, Name, Balken (ADR-0092). Ein Tipp sagt,
/// wie viel bis zur nächsten Stufe fehlt.
///
/// **Jede Kachel ist ein eigenes Flugziel**: Die Funken eines Häkchens
/// fliegen in die Kachel seines Gebiets, nicht in einen Balken, der
/// erst dafür einblendet. Wie die Leiste zeigt sie, was **angekommen**
/// ist.
class GebietsKacheln extends ConsumerWidget {
  const GebietsKacheln({super.key});

  /// Die Kachel von [area], zum Finden in Tests.
  static Key keyFor(SkillArea area) {
    return ValueKey<String>('gebiets-kachel-${area.name}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills = ref.watch(skillsProvider);
    final zuletzt = ref.watch(zuletztGebietProvider);
    final unterwegs = AufstiegHost.maybeOf(context)?.unterwegs(FlugZiel.gebiet);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final area in SkillArea.values) ...<Widget>[
          if (area != SkillArea.values.first) const SizedBox(width: 6),
          Expanded(
            child: _Kachel(
              key: keyFor(area),
              area: area,
              skill: skills.of(area),
              // Nur die eine, in die gerade geflogen wird.
              unterwegs: area == zuletzt ? unterwegs : null,
              fliegtHierher: area == zuletzt,
            ),
          ),
        ],
      ],
    );
  }
}

class _Kachel extends StatelessWidget {
  const _Kachel({
    required this.area,
    required this.skill,
    required this.unterwegs,
    required this.fliegtHierher,
    super.key,
  });

  final SkillArea area;
  final SkillLevel skill;
  final ValueListenable<int>? unterwegs;
  final bool fliegtHierher;

  @override
  Widget build(BuildContext context) {
    final farbe = GebietFarbe.leder(area);
    final stand = unterwegs;

    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      message: skill.isMaxLevel
          ? '${area.label}: höchste Stufe'
          : '${area.label}: noch ${skill.xpToNextLevel} Erfahrung bis '
                'Stufe ${skill.level + 1}',
      child: Druck(
        child: FlugZielMarke(
          ziel: FlugZiel.gebiet,
          fuer: area,
          pulst: fliegtHierher,
          staerke: 0.08,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: farbe.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: farbe, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 7, 6, 8),
              child: stand == null
                  ? _inhalt(skill, farbe)
                  : ValueListenableBuilder<int>(
                      valueListenable: stand,
                      builder: (context, fliegt, _) => _inhalt(
                        // Zwei schnelle Häkchen in zwei Gebieten ziehen
                        // hier die Summe ab; unter null geht es nicht.
                        SkillCurve.levelFor(
                          math.max(0, skill.totalXp - fliegt),
                        ),
                        farbe,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inhalt(SkillLevel stufe, Color farbe) {
    return Semantics(
      label: '${area.label}, Stufe ${stufe.level}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(gebietZeichen(area), size: 17, color: farbe),
              const SizedBox(width: 4),
              Text(
                '${stufe.level}',
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Palette.textOnDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Die Namen sind verschieden lang; keiner wird abgeschnitten.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              area.label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: farbe,
              ),
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: stufe.ratio,
              minHeight: 4,
              backgroundColor: Palette.textOnDarkDim.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(farbe),
            ),
          ),
        ],
      ),
    );
  }
}
