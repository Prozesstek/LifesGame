import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../habits/habits_controller.dart';
import '../habits/stat_icon.dart';
import '../ui/holz.dart';
import '../ui/palette.dart';
import 'statistik_text.dart';
import 'widgets/kalender_raster.dart';
import 'widgets/statistik_karten.dart';

/// **Der Jahresrückblick** (ADR-0087): ein Kalenderjahr der Gewohnheiten
/// in Zahlen, das sich aufbaut wie der Wochenrückblick.
///
/// Erst das Jahr, dann die Zahlen, die hochzählen, dann das Raster, das
/// sich Tag für Tag füllt, dann die Gewohnheit des Jahres, die Mengen und
/// der Vergleich mit dem Vorjahr. Gerechnet wird in `package:habits`
/// (`StatRechnung.jahresrueckblick`).
class JahresrueckblickScreen extends ConsumerWidget {
  const JahresrueckblickScreen({required this.jahr, super.key});

  final int jahr;

  static const Key haekchenKey = ValueKey<String>('jahr-haekchen');
  static const Key besteKey = ValueKey<String>('jahr-beste');
  static const Key vorjahrKey = ValueKey<String>('jahr-vorjahr');

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(habitTrackerProvider);
    final heute = ref.watch(todayProvider);
    final rechnung = StatRechnung(tracker, heute: heute);
    final rueckblick = rechnung.jahresrueckblick(jahr);
    final fenster = StatFenster.um(
      StatZeitraum.jahr,
      Day(jahr, 1, 1),
      anfang: Day(jahr, 1, 1),
      heute: heute,
    );
    String name(String id) => tracker.definitionFor(id)?.name ?? id;

    final beste = rueckblick.besteQuote;
    final meiste = rueckblick.meisteHaekchen;
    final mengen = <StatJahrGewohnheit>[
      for (final g in rueckblick.gewohnheiten)
        if (g.menge > 0) g,
    ];
    final vorjahr = rueckblick.vorjahr;

    var schritt = 0;
    Widget spaeter(Widget kind) => _Spaeter(schritt: schritt++, child: kind);

    return Scaffold(
      appBar: AppBar(title: Text('$jahr')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                spaeter(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(
                        Icons.auto_awesome,
                        color: Palette.goldOnDark,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$jahr',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Palette.goldOnDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                spaeter(
                  HolzKarte(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 14,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _Zaehler(
                            key: haekchenKey,
                            icon: Icons.check,
                            farbe: StatFarbe.erledigt,
                            wert: rueckblick.haekchen,
                            erklaerung: 'Häkchen im Jahr',
                          ),
                        ),
                        Expanded(
                          child: _Zaehler(
                            icon: Icons.check_circle,
                            farbe: StatFarbe.erledigt,
                            wert: rueckblick.quote.prozent ?? 0,
                            nach: ' %',
                            erklaerung: 'Erledigt von fällig',
                          ),
                        ),
                        Expanded(
                          child: _Zaehler(
                            icon: Icons.star,
                            farbe: Palette.gold,
                            wert: rueckblick.perfekteWochen,
                            erklaerung: 'Perfekte Wochen',
                          ),
                        ),
                        Expanded(
                          child: _Zaehler(
                            icon: Icons.local_fire_department,
                            farbe: Palette.accent,
                            wert: rueckblick.laengsteKette,
                            erklaerung: 'Längste Kette in diesem Jahr',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                spaeter(
                  HolzKarte(
                    padding: const EdgeInsets.all(12),
                    child: Aufbau(
                      schluessel: jahr,
                      dauer: const Duration(milliseconds: 2400),
                      builder: (context, wert) => KalenderRaster(
                        rechnung: rechnung,
                        fenster: fenster,
                        fortschritt: wert,
                        onTag: (_) {},
                      ),
                    ),
                  ),
                ),
                if (beste != null || meiste != null) ...<Widget>[
                  const SizedBox(height: 12),
                  spaeter(
                    StatKarte(
                      key: besteKey,
                      icon: Icons.emoji_events,
                      erklaerung: 'Die Gewohnheit des Jahres',
                      child: Column(
                        children: <Widget>[
                          if (beste != null)
                            _Gewohnheit(
                              habit: tracker.definitionFor(beste.habitId),
                              name: name(beste.habitId),
                              icon: Icons.check_circle,
                              wert: StatText.prozent(beste.quote),
                              erklaerung: 'Die beste Quote',
                            ),
                          if (meiste != null)
                            _Gewohnheit(
                              habit: tracker.definitionFor(meiste.habitId),
                              name: name(meiste.habitId),
                              icon: Icons.check,
                              wert: StatText.zahl(meiste.haekchen),
                              erklaerung: 'Die meisten Häkchen',
                            ),
                          if (rueckblick.besterMonat case final monat?)
                            _Gewohnheit(
                              habit: null,
                              name: StatText.monatLang(monat.monat.month),
                              icon: Icons.calendar_month,
                              wert: StatText.prozent(monat.quote),
                              erklaerung: 'Der beste Monat',
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (mengen.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  spaeter(
                    StatKarte(
                      icon: Icons.functions,
                      erklaerung: 'Was zusammenkam',
                      child: Column(
                        children: <Widget>[
                          for (final g in mengen)
                            _Gewohnheit(
                              habit: tracker.definitionFor(g.habitId),
                              name: name(g.habitId),
                              icon: Icons.functions,
                              wert:
                                  '${StatText.zahl(g.menge)} '
                                  '${tracker.definitionFor(g.habitId)?.goal?.unit ?? ''}',
                              erklaerung: 'Zusammen im Jahr',
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (vorjahr != null) ...<Widget>[
                  const SizedBox(height: 12),
                  spaeter(
                    StatKarte(
                      key: vorjahrKey,
                      icon: Icons.compare_arrows,
                      erklaerung: 'Gegen ${jahr - 1}',
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: _Gegen(
                              icon: Icons.check,
                              jetzt: rueckblick.haekchen,
                              damals: vorjahr.haekchen,
                              erklaerung: 'Häkchen gegen ${jahr - 1}',
                            ),
                          ),
                          Expanded(
                            child: _Gegen(
                              icon: Icons.check_circle,
                              jetzt: rueckblick.quote.prozent ?? 0,
                              damals: vorjahr.quote.prozent ?? 0,
                              nach: ' %',
                              erklaerung: 'Quote gegen ${jahr - 1}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Erscheint nach den Teilen davor: ein Schritt je Teil.
class _Spaeter extends StatelessWidget {
  const _Spaeter({required this.schritt, required this.child});

  final int schritt;
  final Widget child;

  static const Duration _abstand = Duration(milliseconds: 260);
  static const Duration _einblenden = Duration(milliseconds: 420);

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    final gesamt = _abstand * schritt + _einblenden;
    final ab = _abstand.inMilliseconds * schritt / gesamt.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: gesamt,
      curve: Interval(ab, 1, curve: Curves.easeOutCubic),
      builder: (context, t, kind) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: kind,
        ),
      ),
      child: child,
    );
  }
}

class _Zaehler extends StatelessWidget {
  const _Zaehler({
    required this.icon,
    required this.farbe,
    required this.wert,
    required this.erklaerung,
    this.nach = '',
    super.key,
  });

  final IconData icon;
  final Color farbe;
  final int wert;
  final String erklaerung;
  final String nach;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: erklaerung,
      triggerMode: TooltipTriggerMode.tap,
      child: Column(
        children: <Widget>[
          Icon(icon, color: farbe, size: 22, semanticLabel: erklaerung),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: wert),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (context, n, _) => Text(
              '${StatText.zahl(n)}$nach',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Gewohnheit extends StatelessWidget {
  const _Gewohnheit({
    required this.habit,
    required this.name,
    required this.icon,
    required this.wert,
    required this.erklaerung,
  });

  final Habit? habit;
  final String name;
  final IconData icon;
  final String wert;
  final String erklaerung;

  @override
  Widget build(BuildContext context) {
    final h = habit;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          StatZeichen(icon: icon, erklaerung: erklaerung, farbe: Palette.gold),
          const SizedBox(width: 8),
          if (h != null) ...<Widget>[
            Icon(
              StatIcons.of(h.stat),
              size: 16,
              color: StatIcons.colorOf(h.stat),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Palette.text,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              wert,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// „312 ▲ 40“ — eine Zahl gegen das Vorjahr.
class _Gegen extends StatelessWidget {
  const _Gegen({
    required this.icon,
    required this.jetzt,
    required this.damals,
    required this.erklaerung,
    this.nach = '',
  });

  final IconData icon;
  final int jetzt;
  final int damals;
  final String erklaerung;
  final String nach;

  @override
  Widget build(BuildContext context) {
    final unterschied = jetzt - damals;
    final farbe = unterschied > 0 ? Palette.success : Palette.muted;
    return Tooltip(
      message: erklaerung,
      triggerMode: TooltipTriggerMode.tap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 16, color: Palette.textDim),
          const SizedBox(width: 4),
          Text(
            '${StatText.zahl(jetzt)}$nach',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Palette.text,
            ),
          ),
          Icon(
            unterschied == 0
                ? Icons.drag_handle
                : unterschied > 0
                ? Icons.arrow_drop_up
                : Icons.arrow_drop_down,
            color: farbe,
          ),
          Text(
            '${StatText.zahl(unterschied.abs())}$nach',
            style: TextStyle(fontSize: 13, color: farbe),
          ),
        ],
      ),
    );
  }
}
