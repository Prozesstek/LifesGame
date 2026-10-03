import 'package:flutter/material.dart';

import '../../ui/druck.dart';
import '../../ui/palette.dart';

/// Wie die sieben Wochentage heißen — **eine Tabelle** für den Wähler, die
/// Kachel und den Vorleser. Die Zahlen sind die aus `Day.weekday`: 1 ist
/// Montag.
abstract final class Wochentage {
  static const List<int> alle = <int>[1, 2, 3, 4, 5, 6, 7];

  static const Map<int, String> _kurz = <int, String>{
    1: 'Mo',
    2: 'Di',
    3: 'Mi',
    4: 'Do',
    5: 'Fr',
    6: 'Sa',
    7: 'So',
  };

  static const Map<int, String> _lang = <int, String>{
    1: 'Montag',
    2: 'Dienstag',
    3: 'Mittwoch',
    4: 'Donnerstag',
    5: 'Freitag',
    6: 'Samstag',
    7: 'Sonntag',
  };

  static String kurz(int tag) => _kurz[tag] ?? '?';

  static String lang(int tag) => _lang[tag] ?? '?';

  /// „Mo Mi Fr" — oder null, wenn jeder Tag gewählt ist. Jeden Tag ist
  /// der Normalfall, und der braucht keine Zeile.
  static String? zeile(Set<int> tage) {
    if (tage.length >= alle.length) return null;
    return <String>[
      for (final tag in alle)
        if (tage.contains(tag)) kurz(tag),
    ].join(' ');
  }
}

/// Sieben Kreise, Montag bis Sonntag, zum An- und Abwählen (ADR-0064).
///
/// **Der letzte Tag lässt sich nicht abwählen.** Eine Gewohnheit ohne
/// fälligen Tag wäre keine — wer sie nicht mehr will, stoppt sie.
class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// Woran ein Test den Kreis eines Wochentags findet.
  static Key keyFor(int tag) => ValueKey<String>('wochentag-$tag');

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  void _tippe(int tag) {
    final next = <int>{...selected};
    if (!next.remove(tag)) next.add(tag);
    if (next.isEmpty) return;
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (final tag in Wochentage.alle)
          _Tag(
            key: keyFor(tag),
            tag: tag,
            gewaehlt: selected.contains(tag),
            onTap: () => _tippe(tag),
          ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.tag,
    required this.gewaehlt,
    required this.onTap,
    super.key,
  });

  /// So groß, wie Platz ist, höchstens so. Sieben feste Kreise liefen in
  /// einem Dialog auf einem schmalen Handy über.
  static const double _seite = 34;

  final int tag;
  final bool gewaehlt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _seite, maxHeight: _seite),
        child: AspectRatio(
          aspectRatio: 1,
          child: Semantics(
            button: true,
            selected: gewaehlt,
            label: Wochentage.lang(tag),
            excludeSemantics: true,
            child: Druck(
              child: Material(
                color: gewaehlt ? Palette.accent : Palette.surfaceSunken,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        Wochentage.kurz(tag),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: gewaehlt ? Palette.surface : Palette.textDim,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
