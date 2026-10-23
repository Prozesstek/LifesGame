import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../habits/widgets/weekday_picker.dart';
import '../../ui/palette.dart';
import '../statistik_text.dart';

/// Die Graphen der Statistik (ADR-0087), gezeichnet mit fl_chart.
///
/// **Sie rechnen nichts**: Abschnitte, Quoten und Ketten kommen aus
/// `StatRechnung`. [wachsen] (0 bis 1) lässt sie beim Öffnen und beim
/// Blättern aufbauen — Balken wachsen hoch, die Kurve zeichnet sich.
/// fl_charts eigene Animation ist dafür aus: Sie liefe nur beim Wechsel
/// der Daten, nicht beim ersten Bild.

const TextStyle _achse = TextStyle(fontSize: 10, color: Palette.textDim);
const TextStyle _tipp = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: Palette.surface,
);

/// Was unter einem Abschnitt steht — oder nichts, damit die Achse nicht
/// zuläuft.
String? _beschriftung(StatAbschnitt a, StatZeitraum zeitraum, int index) {
  switch (zeitraum) {
    case StatZeitraum.woche:
      return Wochentage.kurz(a.von.weekday);
    case StatZeitraum.monat:
      final t = a.von.day;
      return t == 1 || t % 5 == 0 ? '$t' : null;
    case StatZeitraum.jahr:
      // Balken je Monat: jeder. Kurve je Woche: die Woche, in der ein
      // Monat beginnt — genau eine, sonst stünde „JJ“ da.
      if (!_istWoche(a)) return _buchstabe(a.von.month);
      if (a.von.day == 1) return _buchstabe(a.von.month);
      if (a.bis.month != a.von.month) return _buchstabe(a.bis.month);
      return null;
    case StatZeitraum.gesamt:
      if (a.von.month == 1) {
        return "'${(a.von.year % 100).toString().padLeft(2, '0')}";
      }
      return index % 3 == 0
          ? StatText.monatKurz(a.von.month).substring(0, 1)
          : null;
  }
}

String _buchstabe(int monat) => StatText.monatKurz(monat).substring(0, 1);

/// Ob ein Abschnitt eine Woche ist (oder ihr Rest am Rand des Jahres).
bool _istWoche(StatAbschnitt a) =>
    a.von != a.bis && a.von.daysUntil(a.bis) <= 6;

String _abschnittName(StatAbschnitt a) {
  if (a.von == a.bis) return StatText.tag(a.von);
  if (_istWoche(a)) return 'ab ${StatText.tag(a.von)}';
  return StatText.monat(a.von);
}

AxisTitles _unten(List<StatAbschnitt> abschnitte, StatZeitraum zeitraum) {
  return AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 18,
      interval: 1,
      getTitlesWidget: (wert, meta) {
        final i = wert.round();
        if (i < 0 || i >= abschnitte.length) return const SizedBox.shrink();
        final text = _beschriftung(abschnitte[i], zeitraum, i);
        if (text == null) return const SizedBox.shrink();
        return SideTitleWidget(
          meta: meta,
          space: 4,
          child: Text(text, style: _achse),
        );
      },
    ),
  );
}

const AxisTitles _keine = AxisTitles();

/// **Balken je Tag oder Monat**: erledigt über fällig — oder, bei einer
/// Gewohnheit mit Ziel, die Menge.
class StatBalken extends StatelessWidget {
  const StatBalken({
    required this.abschnitte,
    required this.zeitraum,
    this.einheit,
    this.wachsen = 1,
    super.key,
  });

  final List<StatAbschnitt> abschnitte;
  final StatZeitraum zeitraum;

  /// Gesetzt, wenn die Balken eine Menge zeigen („Minuten“).
  final String? einheit;
  final double wachsen;

  @override
  Widget build(BuildContext context) {
    final menge = einheit != null;
    final hoechster = abschnitte.fold<int>(
      1,
      (m, a) => math.max(m, menge ? a.menge : a.quote.faellig),
    );
    final breite = math.max(2.0, math.min(18.0, 220 / abschnitte.length));

    return BarChart(
      duration: Duration.zero,
      BarChartData(
        maxY: hoechster.toDouble(),
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: _unten(abschnitte, zeitraum),
          leftTitles: _keine,
          rightTitles: _keine,
          topTitles: _keine,
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Palette.text,
            getTooltipItem: (gruppe, index, stab, stabIndex) {
              final a = abschnitte[gruppe.x];
              final zeile = menge
                  ? '${StatText.zahl(a.menge)} $einheit'
                  : '${a.quote.erledigt}/${a.quote.faellig} · '
                        '${StatText.prozent(a.quote)}';
              return BarTooltipItem('${_abschnittName(a)}\n$zeile', _tipp);
            },
          ),
        ),
        barGroups: <BarChartGroupData>[
          for (final (i, a) in abschnitte.indexed)
            BarChartGroupData(
              x: i,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: (menge ? a.menge : a.quote.erledigt) * wachsen,
                  width: breite,
                  color: StatFarbe.erledigt,
                  borderRadius: BorderRadius.circular(breite / 3),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: !menge && !a.zukunft,
                    toY: a.quote.faellig.toDouble(),
                    color: StatFarbe.leer,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// **Die Kurve der Quote**, grün, und darunter die Kette in Gold —
/// rechts an der Achse ihre Länge.
class StatKurve extends StatelessWidget {
  const StatKurve({
    required this.abschnitte,
    required this.zeitraum,
    this.wachsen = 1,
    super.key,
  });

  /// Nur, was schon war.
  final List<StatAbschnitt> abschnitte;
  final StatZeitraum zeitraum;
  final double wachsen;

  @override
  Widget build(BuildContext context) {
    final laengste = abschnitte.fold<int>(1, (m, a) => math.max(m, a.kette));
    final bis = (abschnitte.length * wachsen).ceil();
    final quote = <FlSpot>[
      for (final (i, a) in abschnitte.take(bis).indexed)
        a.quote.prozent == null
            ? FlSpot.nullSpot
            : FlSpot(i.toDouble(), a.quote.prozent!.toDouble()),
    ];
    final kette = <FlSpot>[
      for (final (i, a) in abschnitte.take(bis).indexed)
        FlSpot(i.toDouble(), a.kette * 100 / laengste),
    ];

    return LineChart(
      duration: Duration.zero,
      LineChartData(
        minY: 0,
        maxY: 100,
        minX: 0,
        maxX: math.max(1, abschnitte.length - 1).toDouble(),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: StatFarbe.leer, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: _unten(abschnitte, zeitraum),
          topTitles: _keine,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: 50,
              getTitlesWidget: (wert, meta) => SideTitleWidget(
                meta: meta,
                child: Text('${wert.round()}%', style: _achse),
              ),
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 100,
              getTitlesWidget: (wert, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  '${(wert * laengste / 100).round()}',
                  style: _achse.copyWith(color: StatFarbe.kette),
                ),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Palette.text,
            getTooltipItems: (punkte) => <LineTooltipItem?>[
              for (final p in punkte)
                p.barIndex == 0
                    ? LineTooltipItem(
                        '${_abschnittName(abschnitte[p.x.round()])}\n'
                        '${StatText.prozent(abschnitte[p.x.round()].quote)}',
                        _tipp,
                      )
                    : LineTooltipItem(
                        '🔥 ${abschnitte[p.x.round()].kette}',
                        _tipp.copyWith(color: Palette.goldOnDark),
                      ),
            ],
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: quote,
            isCurved: true,
            preventCurveOverShooting: true,
            color: StatFarbe.erledigt,
            barWidth: 3,
            dotData: FlDotData(show: abschnitte.length <= 31),
            belowBarData: BarAreaData(
              show: true,
              color: StatFarbe.erledigt.withValues(alpha: 0.15),
            ),
          ),
          LineChartBarData(
            spots: kette,
            isCurved: true,
            preventCurveOverShooting: true,
            color: StatFarbe.kette,
            barWidth: 2,
            dashArray: <int>[5, 4],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

/// **Die Wochentage**: die Quote je Tag, der stärkste in Gold.
class StatWochentage extends StatelessWidget {
  const StatWochentage({
    required this.je,
    required this.staerkster,
    this.wachsen = 1,
    super.key,
  });

  final Map<int, StatQuote> je;
  final int? staerkster;
  final double wachsen;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      duration: Duration.zero,
      BarChartData(
        maxY: 100,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: _keine,
          rightTitles: _keine,
          topTitles: _keine,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (wert, meta) => SideTitleWidget(
                meta: meta,
                space: 4,
                child: Text(
                  Wochentage.kurz(wert.round()),
                  style: wert.round() == staerkster
                      ? _achse.copyWith(
                          color: Palette.gold,
                          fontWeight: FontWeight.bold,
                        )
                      : _achse,
                ),
              ),
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Palette.text,
            getTooltipItem: (gruppe, index, stab, stabIndex) {
              final q = je[gruppe.x]!;
              return BarTooltipItem(
                '${Wochentage.lang(gruppe.x)}\n'
                '${q.erledigt}/${q.faellig} · ${StatText.prozent(q)}',
                _tipp,
              );
            },
          ),
        ),
        barGroups: <BarChartGroupData>[
          for (final w in Wochentage.alle)
            BarChartGroupData(
              x: w,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: (je[w]?.prozent ?? 0) * wachsen,
                  width: 18,
                  color: w == staerkster ? Palette.gold : StatFarbe.erledigt,
                  borderRadius: BorderRadius.circular(6),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: StatFarbe.leer,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
