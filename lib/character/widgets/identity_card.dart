import 'package:flutter/material.dart';
import 'package:identity/identity.dart';

import '../../ui/palette.dart';

/// Der Kopf des Charakterbildschirms: wer der Charakter ist.
///
/// Zeigt Name und Titel zusammen in einer Zeile — „Frederik, der
/// Beständige" — und führt zu den beiden Eingaben. Die Trennung ist
/// bewusst: Der Name wird **eingegeben**, der Titel nur **ausgewählt** aus
/// dem, was verdient ist (ADR-0013).
class IdentityCard extends StatelessWidget {
  const IdentityCard({
    required this.identity,
    required this.stats,
    required this.level,
    required this.gold,
    required this.onEditName,
    required this.onChooseTitle,
    super.key,
  });

  final Identity identity;
  final TitleStats stats;
  final int level;
  final int gold;
  final VoidCallback onEditName;
  final VoidCallback onChooseTitle;

  @override
  Widget build(BuildContext context) {
    final title = identity.titleFor(stats);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Palette.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.person_outline, size: 30, color: Palette.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      identity.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: identity.hasName ? Colors.white : Palette.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title == null
                          ? 'Level $level'
                          : '${title.label} · Level $level',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Palette.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$gold Gold',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Palette.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Alles hier kommt aus dem, was du getan hast.',
            style: TextStyle(fontSize: 12, color: Palette.muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEditName,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(identity.hasName ? 'Name ändern' : 'Name geben'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChooseTitle,
                  icon: const Icon(Icons.military_tech_outlined, size: 18),
                  label: const Text('Titel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
