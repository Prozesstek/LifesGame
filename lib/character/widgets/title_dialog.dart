import 'package:achievements/achievements.dart';
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
///
/// **Mit einer Ausnahme seit ADR-0033: Entdeckungen.** Sechs der dreizehn
/// Titel kommen aus einer Entdeckung, und die verliert alles, wenn man sie
/// vorher lesen kann. Sie steht deshalb als ??? da — sichtbar, dass es
/// etwas zu finden gibt, aber nicht was.
Future<TitleSelection?> showTitleDialog(
  BuildContext context, {
  required String? current,
  required AchievementStats stats,
}) {
  return showDialog<TitleSelection>(
    context: context,
    builder: (context) => _TitleDialog(current: current, stats: stats),
  );
}

class _TitleDialog extends StatelessWidget {
  const _TitleDialog({required this.current, required this.stats});

  final String? current;
  final AchievementStats stats;

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
  final AchievementStats stats;
  final bool isSelected;

  /// Die Errungenschaft, die diesen Titel vergibt.
  ///
  /// Null wäre ein Titel ohne Quelle — den kann niemand verdienen.
  /// `test/achievements_seam_test.dart` schließt das aus; hier wird der
  /// Fall trotzdem nicht geworfen, sondern still gesperrt (ADR-0010).
  Achievement? get _quelle {
    for (final achievement in AchievementCatalog.all) {
      if (achievement.titleId == title.id) return achievement;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final quelle = _quelle;
    final isEarned = quelle != null && quelle.isEarnedBy(stats);

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
        // Ein unverdienter Entdeckungstitel verrät nicht einmal seinen
        // Namen -- er *ist* die Überraschung.
        isEarned || (quelle?.isMilestone ?? false) ? title.label : '???',
        style: TextStyle(
          color: isEarned ? Palette.text : Palette.muted,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        _untertitel(quelle, isEarned),
        style: const TextStyle(fontSize: 12, color: Palette.textDim),
      ),
      onTap: isEarned
          ? () => Navigator.of(context).pop(TitleSelection(title.id))
          : null,
    );
  }

  String _untertitel(Achievement? quelle, bool isEarned) {
    if (quelle == null) return 'Ohne Quelle';
    if (isEarned) return quelle.requirement;
    if (quelle.isDiscovery) return 'Noch nicht entdeckt';

    final fehlt = quelle.missingFor(stats);
    return '${quelle.requirement} — noch $fehlt';
  }
}
