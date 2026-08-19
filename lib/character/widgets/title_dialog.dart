import 'package:flutter/material.dart';
import 'package:identity/identity.dart';

import '../../ui/palette.dart';

/// Das Ergebnis der Titelwahl.
///
/// Nötig, weil „keinen Titel tragen" und „abgebrochen" beides ein leeres
/// Ergebnis wären. Der Dialog gibt null zurück, wenn abgebrochen wurde, und
/// eine [TitleSelection] mit null darin, wenn der Titel abgelegt wurde.
class TitleSelection {
  const TitleSelection(this.titleId);

  final String? titleId;
}

/// Lässt einen verdienten Titel auswählen.
///
/// Gesperrte Titel bleiben sichtbar und nennen ihre Bedingung — dieselbe
/// Hausregel wie beim Startbildschirm und beim Laden: „Ein Bildschirm, der
/// nur zeigt, was schon fertig ist, verschweigt, worum es geht."
Future<TitleSelection?> showTitleDialog(
  BuildContext context, {
  required String? current,
  required TitleStats stats,
}) {
  return showDialog<TitleSelection>(
    context: context,
    builder: (context) => _TitleDialog(current: current, stats: stats),
  );
}

class _TitleDialog extends StatelessWidget {
  const _TitleDialog({required this.current, required this.stats});

  final String? current;
  final TitleStats stats;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.surfaceRaised,
      title: const Text('Titel wählen'),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: SizedBox(
        width: 400,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Titel werden verdient, nicht ausgesucht. Was du erreicht '
                'hast, kannst du tragen.',
                style: TextStyle(fontSize: 12, color: Palette.textDim),
              ),
            ),
            _NoTitleTile(isSelected: current == null),
            for (final title in TitleCatalog.all)
              _TitleTile(
                title: title,
                stats: stats,
                isSelected: title.id == current,
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
      ],
    );
  }
}

class _NoTitleTile extends StatelessWidget {
  const _NoTitleTile({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? Palette.accent : Palette.muted,
      ),
      title: const Text('Kein Titel'),
      subtitle: const Text(
        'Nur der Name',
        style: TextStyle(fontSize: 12, color: Palette.textDim),
      ),
      onTap: () => Navigator.of(context).pop(const TitleSelection(null)),
    );
  }
}

class _TitleTile extends StatelessWidget {
  const _TitleTile({
    required this.title,
    required this.stats,
    required this.isSelected,
  });

  final CharacterTitle title;
  final TitleStats stats;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isEarned = title.isEarnedBy(stats);
    final missing = title.missingFor(stats);

    return ListTile(
      enabled: isEarned,
      leading: Icon(
        !isEarned
            ? Icons.lock_outline
            : isSelected
            ? Icons.check_circle
            : Icons.circle_outlined,
        color: !isEarned
            ? Palette.muted
            : isSelected
            ? Palette.accent
            : Palette.textDim,
      ),
      title: Text(
        title.label,
        style: TextStyle(
          color: isEarned ? Colors.white : Palette.muted,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        isEarned ? title.requirement : '${title.requirement} — noch $missing',
        style: const TextStyle(fontSize: 12, color: Palette.textDim),
      ),
      onTap: isEarned
          ? () => Navigator.of(context).pop(TitleSelection(title.id))
          : null,
    );
  }
}
