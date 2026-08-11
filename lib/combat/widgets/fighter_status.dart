import 'package:combat/combat.dart';
import 'package:flutter/material.dart';

import '../event_text.dart';

/// HP, Energie und Statuseffekte einer Seite.
class FighterStatus extends StatelessWidget {
  const FighterStatus({
    required this.combatant,
    required this.accent,
    this.alignEnd = false,
    super.key,
  });

  final Combatant combatant;
  final Color accent;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: <Widget>[
        Text(
          combatant.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        _Bar(
          value: combatant.hp / combatant.maxHp,
          color: accent,
          label: '${combatant.hp} / ${combatant.maxHp}',
        ),
        const SizedBox(height: 3),
        _Bar(
          value: combatant.maxEnergy == 0
              ? 0
              : combatant.energy / combatant.maxEnergy,
          color: const Color(0xFFFFD166),
          label: 'EN ${combatant.energy}',
          height: 5,
        ),
        if (combatant.statuses.isNotEmpty) ...<Widget>[
          const SizedBox(height: 5),
          Wrap(
            spacing: 4,
            children: combatant.statuses
                .map((s) => _StatusChip(id: s.id, turns: s.remainingTurns))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.color,
    required this.label,
    this.height = 12,
  });

  final double value;
  final Color color;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: value, end: value.clamp(0, 1)),
            duration: const Duration(milliseconds: 320),
            builder: (context, animated, _) => LinearProgressIndicator(
              value: animated,
              minHeight: height,
              backgroundColor: const Color(0xFF232838),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        if (height >= 10)
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.id, required this.turns});

  final String id;
  final int turns;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3042),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${statusName(id)} $turns',
        style: const TextStyle(fontSize: 10),
      ),
    );
  }
}
