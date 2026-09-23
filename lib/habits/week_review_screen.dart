import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../ui/gold_icon.dart';
import '../ui/holz.dart';
import '../ui/palette.dart';
import 'habits_controller.dart';

/// **Der Wochenrückblick** — was eine Woche gebracht hat, auf einen Blick.
///
/// Er zahlt nichts aus, die Belohnung ist, es zu sehen. Deshalb baut er
/// sich auf, statt einfach dazustehen: Die sieben Tage füllen sich einer
/// nach dem anderen, die Zahlen zählen hoch. Gerechnet wird in
/// `package:habits` ([HabitTracker.weekOf]).
class WeekReviewScreen extends ConsumerWidget {
  const WeekReviewScreen({required this.anyDayOfWeek, super.key});

  /// Irgendein Tag der Woche, die gezeigt wird.
  final Day anyDayOfWeek;

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heute = ref.watch(todayProvider);
    final tracker = ref.watch(habitTrackerProvider);
    final woche = tracker.weekOf(anyDayOfWeek, today: heute);
    final vorwoche = tracker.weekOf(woche.start.previous, today: heute);
    final laeuft = !(woche.end < heute);

    return Scaffold(
      appBar: AppBar(
        title: Text(laeuft ? 'Deine Woche' : 'Deine letzte Woche'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: <Widget>[
                _Tage(woche: woche),
                const SizedBox(height: 12),
                _Zahlen(woche: woche),
                const SizedBox(height: 12),
                _Staerker(woche: woche),
                if (woche.chests > 0) ...<Widget>[
                  const SizedBox(height: 12),
                  _Truhen(woche: woche),
                ],
                const SizedBox(height: 12),
                _Vergleich(woche: woche, vorwoche: vorwoche, laeuft: laeuft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// „21.09. – 27.09."
String weekRangeLabel(WeekSummary woche) {
  String tag(Day d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.';
  return '${tag(woche.start)} – ${tag(woche.end)}';
}

/// Ein Satz, der sagt, was die Woche war — nie, was sie nicht war.
String weekVerdict(WeekSummary woche) => switch (woche.activeDays) {
  7 => 'Eine volle Woche. Genau so.',
  >= 5 => 'Eine starke Woche.',
  >= 3 => 'Ein solides Stück Weg.',
  >= 1 => 'Jeder Tag davon zählt.',
  _ => 'Noch leer — ein Häkchen reicht für den Anfang.',
};

class _Tage extends StatelessWidget {
  const _Tage({required this.woche});

  final WeekSummary woche;

  static const List<String> _namen = <String>[
    'Mo',
    'Di',
    'Mi',
    'Do',
    'Fr',
    'Sa',
    'So',
  ];

  @override
  Widget build(BuildContext context) {
    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            weekRangeLabel(woche),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Palette.textDim),
          ),
          const SizedBox(height: 4),
          Text(
            '${woche.activeDays} von 7 Tagen',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Palette.text,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _Tagespunkt(
                    name: _namen[i],
                    tag: woche.days[i],
                    verzoegerung: i,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            weekVerdict(woche),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Palette.accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ein Tag als Punkt, der nach seinem Vorgänger aufspringt.
class _Tagespunkt extends StatelessWidget {
  const _Tagespunkt({
    required this.name,
    required this.tag,
    required this.verzoegerung,
  });

  final String name;
  final WeekDay tag;

  /// Der wievielte Tag — er springt so viele Schritte später auf.
  final int verzoegerung;

  static const Duration _schritt = Duration(milliseconds: 110);
  static const Duration _sprung = Duration(milliseconds: 420);

  @override
  Widget build(BuildContext context) {
    final gesamt = _schritt * verzoegerung + _sprung;
    final ab = _schritt.inMilliseconds * verzoegerung / gesamt.inMilliseconds;

    final (fuellung, rand, zeichen) = switch (tag.state) {
      WeekDayState.chest => (Palette.gold, Palette.gold, Icons.star),
      WeekDayState.some => (Palette.accent, Palette.accent, Icons.check),
      WeekDayState.none => (Colors.transparent, Palette.muted, null),
      WeekDayState.future => (Colors.transparent, Palette.surfaceRaised, null),
    };

    return Column(
      children: <Widget>[
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: gesamt,
          curve: Interval(ab, 1, curve: Curves.elasticOut),
          builder: (context, s, child) =>
              Transform.scale(scale: s, child: child),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: fuellung,
              shape: BoxShape.circle,
              border: Border.all(color: rand, width: 2),
            ),
            child: zeichen == null
                ? null
                : Icon(zeichen, size: 18, color: Palette.surface),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(fontSize: 11, color: Palette.textDim),
        ),
      ],
    );
  }
}

/// Eine Zahl, die von null hochzählt.
class _Zaehler extends StatelessWidget {
  const _Zaehler({required this.wert, required this.name, this.bild});

  final int wert;
  final String name;
  final Widget? bild;

  @override
  Widget build(BuildContext context) {
    final zeichen = bild;
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (zeichen != null) ...<Widget>[zeichen, const SizedBox(width: 4)],
            Flexible(
              child: TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: wert),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (context, n, _) => Text(
                  '$n',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Palette.text,
                  ),
                ),
              ),
            ),
          ],
        ),
        Text(
          name,
          style: const TextStyle(fontSize: 11, color: Palette.textDim),
        ),
      ],
    );
  }
}

class _Zahlen extends StatelessWidget {
  const _Zahlen({required this.woche});

  final WeekSummary woche;

  @override
  Widget build(BuildContext context) {
    return HolzKarte(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _Zaehler(wert: woche.checks, name: 'Häkchen'),
          ),
          Expanded(
            child: _Zaehler(wert: woche.xp, name: 'Erfahrung'),
          ),
          Expanded(
            child: _Zaehler(
              wert: woche.gold,
              name: 'Gold',
              bild: const GoldIcon(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Staerker extends StatelessWidget {
  const _Staerker({required this.woche});

  final WeekSummary woche;

  @override
  Widget build(BuildContext context) {
    final gewonnen = <HabitStat>[
      for (final stat in HabitStat.values)
        if (woche.gainFor(stat) > 0) stat,
    ];
    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Stärker geworden',
            style: TextStyle(fontWeight: FontWeight.bold, color: Palette.text),
          ),
          const SizedBox(height: 6),
          if (gewonnen.isEmpty)
            const Text(
              'Diese Woche kein ganzer Punkt — die Balken sind trotzdem '
              'gewachsen.',
              style: TextStyle(fontSize: 13, color: Palette.textDim),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                for (final stat in gewonnen)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Palette.surfaceRaised,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Palette.success),
                    ),
                    child: Text(
                      '+${woche.gainFor(stat)} ${stat.label}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Palette.success,
                      ),
                    ),
                  ),
              ],
            ),
          if (woche.bestStreak > 0) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Beste Kette: ${woche.bestStreak} '
              '${woche.bestStreak == 1 ? 'Tag' : 'Tage'}',
              style: const TextStyle(fontSize: 13, color: Palette.textDim),
            ),
          ],
        ],
      ),
    );
  }
}

class _Truhen extends StatelessWidget {
  const _Truhen({required this.woche});

  final WeekSummary woche;

  @override
  Widget build(BuildContext context) {
    final extra = <String>[
      if (woche.foundTreasure) 'darunter ein Schatz!',
      if (woche.freezesFound == 1) 'ein Streak-Eis gefunden',
      if (woche.freezesFound > 1) '${woche.freezesFound} Streak-Eis gefunden',
    ];
    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      edgeColor: woche.foundTreasure ? Palette.gold : Holz.kante,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.inventory_2,
            color: woche.foundTreasure ? Palette.gold : Palette.textDim,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${woche.chests} '
              '${woche.chests == 1 ? 'Truhe' : 'Truhen'} geöffnet'
              '${extra.isEmpty ? '' : ' — ${extra.join(', ')}'}',
              style: const TextStyle(fontSize: 14, color: Palette.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _Vergleich extends StatelessWidget {
  const _Vergleich({
    required this.woche,
    required this.vorwoche,
    required this.laeuft,
  });

  final WeekSummary woche;
  final WeekSummary vorwoche;
  final bool laeuft;

  @override
  Widget build(BuildContext context) {
    final diff = woche.activeDays - vorwoche.activeDays;
    final satz = switch (diff) {
      > 0 => '$diff ${diff == 1 ? 'Tag' : 'Tage'} mehr als letzte Woche.',
      0 when vorwoche.activeDays == 0 => null,
      0 => 'Genauso viele Tage wie letzte Woche.',
      _ when laeuft =>
        'Letzte Woche waren es ${vorwoche.activeDays} — '
            'die Woche ist noch nicht vorbei.',
      _ =>
        'Letzte Woche waren es ${vorwoche.activeDays}. '
            'Die nächste zählt neu.',
    };
    if (satz == null) return const SizedBox.shrink();
    return Text(
      satz,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        fontWeight: diff > 0 ? FontWeight.bold : FontWeight.normal,
        color: diff > 0 ? Palette.successOnDark : Palette.textOnDarkDim,
      ),
    );
  }
}
