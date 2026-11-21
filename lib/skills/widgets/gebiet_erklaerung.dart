import 'package:flutter/material.dart';
import 'package:habits/habits.dart';
import 'package:progression/progression.dart';

import '../../habits/stat_icon.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../gebiet_farbe.dart';
import '../gebiet_zeichen.dart';

/// **Was ein Gebiet ist** — eine kleine Karte auf Tipp (19.11.2026,
/// Frederik: „Kleine Erklärkarte für die Gebiete“): was hineingehört,
/// welchen Kampfwert es steigert und wie weit der Skill ist.
///
/// Erklärt wird erst beim Antippen (ADR-0060).
abstract final class GebietErklaerung {
  /// Woran Tests die Karte finden.
  static const Key karteKey = ValueKey<String>('gebiet-erklaerung');

  /// Was in ein Gebiet gehört: Dinge, die man kennt. Dieselben stehen
  /// bei der ersten Gewohnheit unter jedem Gebiet.
  static const Map<SkillArea, String> beispiele = <SkillArea, String>{
    SkillArea.koerper: 'Sport, Schlaf, Essen',
    SkillArea.geist: 'Lesen, Meditieren, Tagebuch',
    SkillArea.wissenschaft: 'Lernen, Sprachen, Forschen',
    SkillArea.gesellschaft: 'Freunde, Familie, Helfen',
  };

  static Future<void> zeige(
    BuildContext context, {
    required SkillArea area,
    required SkillLevel skill,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => HolzDialog(
        child: _Karte(area: area, skill: skill),
      ),
    );
  }
}

class _Karte extends StatelessWidget {
  const _Karte({required this.area, required this.skill});

  final SkillArea area;
  final SkillLevel skill;

  @override
  Widget build(BuildContext context) {
    final farbe = GebietFarbe.pergament(area);
    final wert = area.kampfwert;

    Widget zeile(Widget zeichen, String text) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: 22, child: Center(child: zeichen)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, color: Palette.text),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      key: GebietErklaerung.karteKey,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(gebietZeichen(area), size: 26, color: farbe),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                area.label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: farbe,
                ),
              ),
            ),
            Text(
              'Stufe ${skill.level}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Palette.textDim,
              ),
            ),
          ],
        ),
        zeile(
          Icon(Icons.checklist_rounded, size: 18, color: farbe),
          GebietErklaerung.beispiele[area] ?? '',
        ),
        zeile(
          StatIcon(wert, size: 18),
          '${wert.label} steigt mit jedem Häkchen hier.',
        ),
        zeile(
          Icon(Icons.trending_up_rounded, size: 18, color: farbe),
          skill.isMaxLevel
              ? 'Höchste Stufe erreicht.'
              : 'Noch ${skill.xpToNextLevel} Erfahrung bis Stufe '
                    '${skill.level + 1}.',
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: skill.ratio,
            minHeight: 6,
            backgroundColor: Palette.surfaceSunken,
            valueColor: AlwaysStoppedAnimation<Color>(farbe),
          ),
        ),
      ],
    );
  }
}
