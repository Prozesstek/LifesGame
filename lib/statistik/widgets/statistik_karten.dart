import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../habits/stat_icon.dart';
import '../../skills/gebiet_farbe.dart';
import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../statistik_text.dart';

/// Die Karten der Statistik (ADR-0087) — Zahlen mit Zeichen, was sie
/// bedeuten, kommt auf Tipp (ADR-0060).

/// **Baut auf**: zählt einmal von 0 bis 1, wenn [schluessel] neu ist —
/// beim Öffnen und bei jedem Blättern. Wer Bewegung im System
/// abgeschaltet hat, bekommt sofort 1.
class Aufbau extends StatelessWidget {
  const Aufbau({
    required this.schluessel,
    required this.builder,
    this.dauer = const Duration(milliseconds: 900),
    super.key,
  });

  final Object schluessel;
  final Duration dauer;
  final Widget Function(BuildContext context, double wert) builder;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      key: ValueKey<Object>(schluessel),
      tween: Tween<double>(begin: still ? 1 : 0, end: 1),
      duration: still ? Duration.zero : dauer,
      curve: Curves.easeOutCubic,
      builder: (context, wert, _) => builder(context, wert),
    );
  }
}

/// Ein Zeichen, das auf Tipp sagt, was es ist.
class StatZeichen extends StatelessWidget {
  const StatZeichen({
    required this.icon,
    required this.erklaerung,
    this.farbe = Palette.textDim,
    this.groesse = 16,
    super.key,
  });

  final IconData icon;
  final String erklaerung;
  final Color farbe;
  final double groesse;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: erklaerung,
      triggerMode: TooltipTriggerMode.tap,
      child: Icon(icon, size: groesse, color: farbe, semanticLabel: erklaerung),
    );
  }
}

/// Eine Karte mit einem Zeichen oben links statt einer Überschrift.
class StatKarte extends StatelessWidget {
  const StatKarte({
    required this.icon,
    required this.erklaerung,
    required this.child,
    this.rechts,
    super.key,
  });

  final IconData icon;
  final String erklaerung;
  final Widget child;
  final Widget? rechts;

  @override
  Widget build(BuildContext context) {
    final extra = rechts;
    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              StatZeichen(icon: icon, erklaerung: erklaerung),
              const Spacer(),
              ?extra,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// **Die Quote** groß, daneben der Vergleich mit den gleichen Tagen
/// davor und die Häkchen; bei einer Gewohnheit mit Ziel die Menge.
class QuoteKarte extends StatelessWidget {
  const QuoteKarte({
    required this.quote,
    required this.vergleich,
    required this.haekchen,
    this.menge,
    this.einheit,
    this.wachsen = 1,
    super.key,
  });

  final StatQuote quote;
  final int? vergleich;
  final int haekchen;
  final StatMenge? menge;
  final String? einheit;
  final double wachsen;

  static const Key quoteKey = ValueKey<String>('stat-quote');
  static const Key vergleichKey = ValueKey<String>('stat-vergleich');

  @override
  Widget build(BuildContext context) {
    final prozent = quote.prozent;
    final m = menge;
    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              StatZeichen(
                icon: Icons.check_circle,
                erklaerung: 'Erledigt von fällig',
                farbe: StatTon.of(context),
                groesse: 26,
              ),
              const SizedBox(width: 8),
              Text(
                prozent == null ? '–' : '${(prozent * wachsen).round()} %',
                key: quoteKey,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Palette.text,
                ),
              ),
              if (vergleich != null) ...<Widget>[
                const SizedBox(width: 10),
                _Vergleich(punkte: vergleich!),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 4,
            children: <Widget>[
              _Zahl(
                icon: Icons.done_all,
                text: '${quote.erledigt} / ${quote.faellig}',
                erklaerung: 'Erledigte von fälligen Tagen',
              ),
              _Zahl(
                icon: Icons.check,
                text: StatText.zahl(haekchen),
                erklaerung: 'Häkchen, auch an freien Tagen',
              ),
              if (m != null && einheit != null) ...<Widget>[
                _Zahl(
                  icon: Icons.functions,
                  text: '${StatText.zahl(m.summe)} $einheit',
                  erklaerung: 'Zusammen in diesem Zeitraum',
                ),
                _Zahl(
                  icon: Icons.av_timer,
                  text: 'Ø ${StatText.zahl(m.schnitt)}',
                  erklaerung: 'Im Schnitt je fälligem Tag',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// „▲ 12“ — besser als davor grün, schlechter nur gedämpft: Die Statistik
/// sagt, was war, sie straft nicht.
class _Vergleich extends StatelessWidget {
  const _Vergleich({required this.punkte});

  final int punkte;

  @override
  Widget build(BuildContext context) {
    final besser = punkte > 0;
    final gleich = punkte == 0;
    final farbe = besser ? Palette.success : Palette.muted;
    return Tooltip(
      message: 'Prozentpunkte gegen die gleichen Tage davor',
      triggerMode: TooltipTriggerMode.tap,
      child: Row(
        key: QuoteKarte.vergleichKey,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            gleich
                ? Icons.drag_handle
                : besser
                ? Icons.arrow_drop_up
                : Icons.arrow_drop_down,
            color: farbe,
            size: 24,
          ),
          Text(
            '${punkte.abs()}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: farbe,
            ),
          ),
        ],
      ),
    );
  }
}

class _Zahl extends StatelessWidget {
  const _Zahl({
    required this.icon,
    required this.text,
    required this.erklaerung,
  });

  final IconData icon;
  final String text;
  final String erklaerung;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: erklaerung,
      triggerMode: TooltipTriggerMode.tap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: Palette.textDim),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Palette.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

/// Was hinter einem angetippten Kästchen steckt — eine Zeile unter dem
/// Raster.
class TagZeile extends StatelessWidget {
  const TagZeile({
    required this.titel,
    required this.quote,
    this.eis = false,
    super.key,
  });

  final String titel;
  final StatQuote quote;
  final bool eis;

  static const Key zeileKey = ValueKey<String>('stat-tag-zeile');

  @override
  Widget build(BuildContext context) {
    return Row(
      key: zeileKey,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Flexible(
          child: Text(
            titel,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Palette.textDim),
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.check, size: 14, color: StatTon.of(context)),
        Text(
          quote.faellig == 0 ? '–' : '${quote.erledigt}/${quote.faellig}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Palette.text,
          ),
        ),
        if (eis) ...<Widget>[
          const SizedBox(width: 6),
          const Icon(Icons.ac_unit, size: 14, color: Palette.manaOnDark),
        ],
      ],
    );
  }
}

/// **Die Rekorde**: längste Kette, perfekte Wochen, bester Monat, meiste
/// Häkchen an einem Tag, Häkchen insgesamt.
class RekordeKarte extends StatelessWidget {
  const RekordeKarte({required this.rekorde, super.key});

  final StatRekorde rekorde;

  @override
  Widget build(BuildContext context) {
    final monat = rekorde.besterMonat;
    final tag = rekorde.meisteHaekchen;
    return StatKarte(
      icon: Icons.emoji_events_outlined,
      erklaerung: 'Rekorde',
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 12,
        runSpacing: 10,
        children: <Widget>[
          _Rekord(
            icon: Icons.local_fire_department,
            farbe: Palette.accent,
            wert: '${rekorde.laengsteKette}',
            erklaerung: 'Längste Kette',
          ),
          _Rekord(
            icon: Icons.star,
            farbe: Palette.gold,
            wert: '${rekorde.perfekteWochen}',
            erklaerung: 'Perfekte Wochen: alles Fällige erledigt',
          ),
          if (monat != null)
            _Rekord(
              icon: Icons.calendar_month,
              farbe: StatTon.of(context),
              wert: StatText.prozent(monat.quote),
              unter: StatText.monat(monat.monat),
              erklaerung: 'Bester Monat',
            ),
          if (tag != null)
            _Rekord(
              icon: Icons.bolt,
              farbe: Palette.gold,
              wert: '${tag.anzahl}',
              unter: StatText.tag(tag.tag),
              erklaerung: 'Meiste Häkchen an einem Tag',
            ),
          _Rekord(
            icon: Icons.check,
            farbe: StatTon.of(context),
            wert: StatText.zahl(rekorde.haekchenGesamt),
            erklaerung: 'Häkchen insgesamt',
          ),
        ],
      ),
    );
  }
}

class _Rekord extends StatelessWidget {
  const _Rekord({
    required this.icon,
    required this.farbe,
    required this.wert,
    required this.erklaerung,
    this.unter,
  });

  final IconData icon;
  final Color farbe;
  final String wert;
  final String erklaerung;
  final String? unter;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: erklaerung,
      triggerMode: TooltipTriggerMode.tap,
      child: SizedBox(
        width: 58,
        child: Column(
          children: <Widget>[
            Icon(icon, color: farbe, size: 22, semanticLabel: erklaerung),
            Text(
              wert,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Palette.text,
              ),
            ),
            if (unter != null)
              Text(
                unter!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: Palette.textDim),
              ),
          ],
        ),
      ),
    );
  }
}

/// Eine Gewohnheit als Ring mit ihrer Quote — ein Tipp öffnet ihre
/// Statistik. Gestoppte stehen blass.
class GewohnheitRing extends StatelessWidget {
  const GewohnheitRing({
    required this.habit,
    required this.quote,
    required this.laeuft,
    required this.onTap,
    this.wachsen = 1,
    super.key,
  });

  final Habit habit;
  final StatQuote quote;
  final bool laeuft;
  final VoidCallback onTap;
  final double wachsen;

  static Key keyFuer(String habitId) => ValueKey<String>('stat-ring-$habitId');

  @override
  Widget build(BuildContext context) {
    final anteil = quote.anteil ?? 0;
    return Opacity(
      opacity: laeuft ? 1 : 0.5,
      child: Druck(
        child: InkWell(
          key: keyFuer(habit.id),
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      CircularProgressIndicator(
                        value: anteil * wachsen,
                        strokeWidth: 5,
                        // Jeder Ring in der Farbe seines Gebiets
                        // (ADR-0090); ohne Gebiet grün.
                        color: switch (habit.area) {
                          final SkillArea gebiet => GebietFarbe.pergament(
                            gebiet,
                          ),
                          null => StatFarbe.erledigt,
                        },
                        backgroundColor: StatFarbe.leer,
                      ),
                      Center(
                        child: Icon(
                          StatIcons.of(habit.stat),
                          size: 16,
                          color: StatIcons.colorOf(habit.stat),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    habit.name,
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
                Text(
                  StatText.prozent(quote),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Palette.text,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Palette.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
