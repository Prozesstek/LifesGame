import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../week_review_screen.dart';

/// Der Weg zum Wochenrückblick.
///
/// **Sonntags und montags gross**, sonst eine Zeile: Am Ende der Woche soll
/// der Rückblick einen ansprechen, statt gesucht werden zu müssen. Montags
/// zeigt er die Woche, die gerade zu Ende ging — sonntags ist sie noch
/// nicht ganz vorbei, und montags ist der Moment, an dem man sie
/// abschliesst.
class WeekCard extends StatelessWidget {
  const WeekCard({
    required this.today,
    required this.thisWeek,
    required this.lastWeek,
    super.key,
  });

  final Day today;
  final WeekSummary thisWeek;
  final WeekSummary lastWeek;

  @override
  Widget build(BuildContext context) {
    final sonntag = today.weekday == DateTime.sunday;
    final montag = today.weekday == DateTime.monday && lastWeek.activeDays > 0;

    if (sonntag || montag) {
      final woche = montag ? lastWeek : thisWeek;
      return _Gross(
        titel: montag ? 'Deine letzte Woche' : 'Deine Woche',
        woche: woche,
        oeffnen: () => _zeige(context, woche),
      );
    }
    return _Zeile(woche: thisWeek, oeffnen: () => _zeige(context, thisWeek));
  }

  void _zeige(BuildContext context, WeekSummary woche) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WeekReviewScreen(anyDayOfWeek: woche.start),
      ),
    );
  }
}

class _Gross extends StatelessWidget {
  const _Gross({
    required this.titel,
    required this.woche,
    required this.oeffnen,
  });

  final String titel;
  final WeekSummary woche;
  final VoidCallback oeffnen;

  @override
  Widget build(BuildContext context) {
    return Druck(
      child: HolzKarte(
        padding: EdgeInsets.zero,
        edgeColor: Palette.gold,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: oeffnen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.calendar_month,
                    color: Palette.gold,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          titel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Palette.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${woche.activeDays} von 7 Tagen · '
                          '${weekVerdict(woche)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Palette.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Palette.textDim),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Zeile extends StatelessWidget {
  const _Zeile({required this.woche, required this.oeffnen});

  final WeekSummary woche;
  final VoidCallback oeffnen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: oeffnen,
        icon: const Icon(
          Icons.calendar_month,
          size: 18,
          color: Palette.textOnDarkDim,
        ),
        label: Text(
          'Diese Woche: ${woche.activeDays} / 7 Tage · Rückblick',
          style: const TextStyle(fontSize: 12, color: Palette.textOnDarkDim),
        ),
      ),
    );
  }
}
