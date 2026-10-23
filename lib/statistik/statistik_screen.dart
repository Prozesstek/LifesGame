import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../habits/habits_controller.dart';
import '../ui/holz.dart';
import '../ui/palette.dart';
import 'jahresrueckblick_screen.dart';
import 'statistik_text.dart';
import 'widgets/kalender_raster.dart';
import 'widgets/statistik_graphen.dart';
import 'widgets/statistik_karten.dart';

/// **Die Statistik** (ADR-0087): wie die Gewohnheiten laufen — als Woche,
/// Monat, Jahr oder alles seit dem ersten Häkchen, mit Blättern.
///
/// Ohne [habitId] alle zusammen, darunter je Gewohnheit ein Ring; ein Tipp
/// darauf öffnet denselben Bildschirm nur für sie. Gerechnet wird in
/// `package:habits` (`StatRechnung`), hier wird nur gezeigt.
class StatistikScreen extends ConsumerStatefulWidget {
  const StatistikScreen({this.habitId, super.key});

  /// Nur diese Gewohnheit — oder null für alle.
  final String? habitId;

  static Key zeitraumKey(StatZeitraum z) =>
      ValueKey<String>('stat-zeitraum-${z.name}');
  static const Key davorKey = ValueKey<String>('stat-davor');
  static const Key danachKey = ValueKey<String>('stat-danach');
  static const Key titelKey = ValueKey<String>('stat-fenster');
  static const Key rueckblickKey = ValueKey<String>('stat-rueckblick');
  static const Key ankuendigungKey = ValueKey<String>('stat-ankuendigung');

  @override
  ConsumerState<StatistikScreen> createState() => _StatistikScreenState();
}

class _StatistikScreenState extends ConsumerState<StatistikScreen> {
  StatZeitraum _zeitraum = StatZeitraum.woche;

  /// Das Fenster, zu dem geblättert wurde — null heißt: das von heute.
  StatFenster? _fenster;
  Day? _gewaehlt;

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context) {
    final tracker = ref.watch(habitTrackerProvider);
    final heute = ref.watch(todayProvider);
    final id = widget.habitId;
    final rechnung = StatRechnung(tracker, heute: heute, habitId: id);
    final fenster = _fenster ?? rechnung.fenster(_zeitraum);
    final habit = id == null ? null : tracker.definitionFor(id);
    final rueckblick = id == null ? StatRechnung.rueckblickJahr(heute) : null;

    return Scaffold(
      appBar: AppBar(title: Text(habit?.name ?? 'Statistik')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: <Widget>[
                if (rueckblick != null &&
                    rechnung.anfang.year <= rueckblick) ...<Widget>[
                  _Ankuendigung(jahr: rueckblick),
                  const SizedBox(height: 12),
                ],
                _ZeitraumWahl(
                  gewaehlt: _zeitraum,
                  onWahl: (z) => setState(() {
                    _zeitraum = z;
                    _fenster = null;
                    _gewaehlt = null;
                  }),
                ),
                const SizedBox(height: 6),
                _Blaettern(
                  fenster: fenster,
                  davor: fenster.blaetterbar && fenster.von > rechnung.anfang,
                  danach: fenster.blaetterbar && fenster.bis < heute,
                  onWechsel: (neu) => setState(() {
                    _fenster = neu;
                    _gewaehlt = null;
                  }),
                ),
                const SizedBox(height: 8),
                Aufbau(
                  schluessel: fenster,
                  builder: (context, wert) => _Inhalt(
                    rechnung: rechnung,
                    fenster: fenster,
                    habit: habit,
                    gewaehlt: _gewaehlt,
                    wachsen: wert,
                    onTag: (tag) => setState(
                      () => _gewaehlt = _gewaehlt == tag ? null : tag,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Inhalt extends StatelessWidget {
  const _Inhalt({
    required this.rechnung,
    required this.fenster,
    required this.habit,
    required this.gewaehlt,
    required this.wachsen,
    required this.onTag,
  });

  final StatRechnung rechnung;
  final StatFenster fenster;
  final Habit? habit;
  final Day? gewaehlt;
  final double wachsen;
  final ValueChanged<Day> onTag;

  @override
  Widget build(BuildContext context) {
    final einheit = habit?.goal?.unit;
    final balken = rechnung.abschnitte(fenster, fenster.balkenTeilung);
    final kurve = <StatAbschnitt>[
      for (final a in rechnung.abschnitte(fenster, fenster.kurvenTeilung))
        if (!a.zukunft) a,
    ];
    final tag = gewaehlt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        QuoteKarte(
          quote: rechnung.quote(fenster),
          vergleich: rechnung.vergleich(fenster),
          haekchen: rechnung.haekchen(fenster),
          menge: rechnung.menge(fenster),
          einheit: einheit,
          wachsen: wachsen,
        ),
        const SizedBox(height: 12),
        StatKarte(
          icon: Icons.grid_view,
          erklaerung:
              'Jeder Tag: je grüner, desto mehr erledigt. '
              'Blau ist Streak-Eis, grau ein freier Tag.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              KalenderRaster(
                rechnung: rechnung,
                fenster: fenster,
                gewaehlt: gewaehlt,
                fortschritt: wachsen,
                onTag: onTag,
              ),
              if (tag != null && fenster.enthaelt(tag)) ...<Widget>[
                const SizedBox(height: 8),
                _gewaehlteZeile(tag),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        StatKarte(
          icon: Icons.bar_chart,
          erklaerung: einheit == null
              ? 'Erledigt von fällig'
              : 'Wie viel $einheit',
          child: SizedBox(
            height: 160,
            child: StatBalken(
              abschnitte: balken,
              zeitraum: fenster.zeitraum,
              einheit: einheit,
              wachsen: wachsen,
            ),
          ),
        ),
        if (kurve.length > 1) ...<Widget>[
          const SizedBox(height: 12),
          StatKarte(
            icon: Icons.show_chart,
            erklaerung: 'Grün die Quote, gold gestrichelt die Kette',
            child: SizedBox(
              height: 170,
              child: StatKurve(
                abschnitte: kurve,
                zeitraum: fenster.zeitraum,
                wachsen: wachsen,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        StatKarte(
          icon: Icons.date_range,
          erklaerung: 'Quote je Wochentag, der stärkste in Gold',
          child: SizedBox(
            height: 140,
            child: StatWochentage(
              je: rechnung.jeWochentag(fenster),
              staerkster: rechnung.staerksterWochentag(fenster),
              wachsen: wachsen,
            ),
          ),
        ),
        if (habit == null) ...<Widget>[
          const SizedBox(height: 12),
          _Ringe(rechnung: rechnung, fenster: fenster, wachsen: wachsen),
        ],
        const SizedBox(height: 12),
        RekordeKarte(rekorde: rechnung.rekorde()),
        if (habit == null &&
            fenster.zeitraum == StatZeitraum.jahr &&
            rechnung.quote(fenster).faellig > 0) ...<Widget>[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: StatistikScreen.rueckblickKey,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => JahresrueckblickScreen(jahr: fenster.von.year),
              ),
            ),
            icon: const Icon(Icons.auto_awesome),
            label: Text('${fenster.von.year}'),
          ),
        ],
      ],
    );
  }

  Widget _gewaehlteZeile(Day tag) {
    if (fenster.zeitraum == StatZeitraum.gesamt) {
      final monat = StatFenster.um(
        StatZeitraum.monat,
        tag,
        anfang: tag,
        heute: rechnung.heute,
      );
      return TagZeile(titel: StatText.monat(tag), quote: rechnung.quote(monat));
    }
    final stand = rechnung.tag(tag);
    return TagZeile(
      titel: StatText.tag(tag),
      quote: stand.quote,
      eis: stand.eis,
    );
  }
}

/// Je Gewohnheit ein Ring mit ihrer Quote: die laufenden in ihrer
/// Reihenfolge, darunter blass die gestoppten.
class _Ringe extends StatelessWidget {
  const _Ringe({
    required this.rechnung,
    required this.fenster,
    required this.wachsen,
  });

  final StatRechnung rechnung;
  final StatFenster fenster;
  final double wachsen;

  @override
  Widget build(BuildContext context) {
    final tracker = rechnung.tracker;
    final laufende = <Habit>[for (final h in tracker.activeHabitsByPriority) h];
    final gestoppte = <Habit>[
      for (final id in tracker.trackedIds)
        if (!tracker.isActive(id)) ?tracker.definitionFor(id),
    ];
    if (laufende.isEmpty && gestoppte.isEmpty) return const SizedBox.shrink();

    Widget ring(Habit habit, {required bool laeuft}) {
      final einzeln = StatRechnung(
        tracker,
        heute: rechnung.heute,
        habitId: habit.id,
      );
      return GewohnheitRing(
        habit: habit,
        quote: einzeln.quote(fenster),
        laeuft: laeuft,
        wachsen: wachsen,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StatistikScreen(habitId: habit.id),
          ),
        ),
      );
    }

    return StatKarte(
      icon: Icons.donut_large,
      erklaerung: 'Je Gewohnheit — antippen für ihre Statistik',
      child: Column(
        children: <Widget>[
          for (final h in laufende) ring(h, laeuft: true),
          for (final h in gestoppte) ring(h, laeuft: false),
        ],
      ),
    );
  }
}

class _ZeitraumWahl extends StatelessWidget {
  const _ZeitraumWahl({required this.gewaehlt, required this.onWahl});

  final StatZeitraum gewaehlt;
  final ValueChanged<StatZeitraum> onWahl;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<StatZeitraum>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        backgroundColor: Palette.surface,
        selectedBackgroundColor: Palette.success,
        selectedForegroundColor: Palette.surface,
        foregroundColor: Palette.text,
        visualDensity: VisualDensity.compact,
      ),
      segments: <ButtonSegment<StatZeitraum>>[
        for (final z in StatZeitraum.values)
          ButtonSegment<StatZeitraum>(
            value: z,
            label: Text(
              StatText.zeitraum(z),
              key: StatistikScreen.zeitraumKey(z),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      selected: <StatZeitraum>{gewaehlt},
      onSelectionChanged: (auswahl) => onWahl(auswahl.single),
    );
  }
}

class _Blaettern extends StatelessWidget {
  const _Blaettern({
    required this.fenster,
    required this.davor,
    required this.danach,
    required this.onWechsel,
  });

  final StatFenster fenster;
  final bool davor;
  final bool danach;
  final ValueChanged<StatFenster> onWechsel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          key: StatistikScreen.davorKey,
          onPressed: davor ? () => onWechsel(fenster.davor) : null,
          icon: const Icon(Icons.chevron_left),
          color: Palette.textOnDark,
          disabledColor: Palette.textOnDarkDim.withValues(alpha: 0.3),
          tooltip: 'Davor',
        ),
        Expanded(
          child: Text(
            StatText.fenster(fenster),
            key: StatistikScreen.titelKey,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Palette.textOnDark,
            ),
          ),
        ),
        IconButton(
          key: StatistikScreen.danachKey,
          onPressed: danach ? () => onWechsel(fenster.danach) : null,
          icon: const Icon(Icons.chevron_right),
          color: Palette.textOnDark,
          disabledColor: Palette.textOnDarkDim.withValues(alpha: 0.3),
          tooltip: 'Danach',
        ),
      ],
    );
  }
}

/// Vom 20.12. bis 7.1. groß über allem: das Jahr, das endet.
class _Ankuendigung extends StatelessWidget {
  const _Ankuendigung({required this.jahr});

  final int jahr;

  @override
  Widget build(BuildContext context) {
    return HolzKarte(
      key: StatistikScreen.ankuendigungKey,
      color: Palette.surfaceRaised,
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(
        children: <Widget>[
          const Icon(Icons.auto_awesome, color: Palette.gold, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dein Jahr $jahr',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Palette.text,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => JahresrueckblickScreen(jahr: jahr),
              ),
            ),
            child: const Icon(Icons.play_arrow),
          ),
        ],
      ),
    );
  }
}
