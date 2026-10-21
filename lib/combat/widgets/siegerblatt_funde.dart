import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../../audio/sound_effects.dart';
import '../../gear/equipment_screen.dart' show ExemplarKachel;
import '../../gear/gear_controller.dart';
import '../../gear/gear_icon.dart';
import '../../gear/sell_flow.dart';
import '../../gear/verkauf_auswahl.dart';
import '../../gear/widgets/gear_sheet.dart';
import '../../gear/widgets/rarity_badge.dart';
import '../../gear/widgets/verkauf_leiste.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';

/// **Die Funde im Siegerblatt** (ADR-0083) — nach AktivesBretts Skizze
/// zu #136.
///
/// Jeder Fund liegt zuerst so da, wie er am Boden lag: das Zeichen seines
/// Platzes im Rand der Seltenheit. Dann dreht sich eine Kachel nach der
/// anderen um und zeigt das Stück, **das Seltenste zuletzt**; Legendäres
/// mit seinem Klang. Jede trägt den Pfeil gegen das Getragene.
///
/// **Antippen öffnet das Blatt** des Stücks — anlegen, sperren, alle
/// Werte. Mit der Auswahl ([VerkaufLeiste]) setzt ein Tipp stattdessen
/// ein Häkchen, und „Verkaufen“ zeigt das Gold der Auswahl.
class SiegerblattFunde extends ConsumerStatefulWidget {
  const SiegerblattFunde({
    required this.funde,
    this.vorlauf = const Duration(milliseconds: 1200),
    super.key,
  });

  /// Was eingesammelt wurde, in der Reihenfolge des Fundes.
  final List<GearCopy> funde;

  /// Wie lange es dauert, bis die erste Kachel sich dreht — bis Erfahrung
  /// und Gold hereingeglitten sind.
  final Duration vorlauf;

  /// Wie lange eine Kachel sich dreht, und wie dicht sie folgen.
  static const Duration drehen = Duration(milliseconds: 420);
  static const Duration abstand = Duration(milliseconds: 330);

  /// In welcher Reihenfolge aufgedeckt wird: das Seltenste zuletzt, bei
  /// gleicher Seltenheit der bessere Wurf später.
  static List<GearCopy> reihenfolge(List<GearCopy> funde) {
    return <GearCopy>[
      for (final copy in funde)
        if (copy.item != null) copy,
    ]..sort((a, b) {
      final stufe = a.item!.rarity.index.compareTo(b.item!.rarity.index);
      if (stufe != 0) return stufe;
      return a.bonus.total.compareTo(b.bonus.total);
    });
  }

  @override
  ConsumerState<SiegerblattFunde> createState() => _SiegerblattFundeState();
}

class _SiegerblattFundeState extends ConsumerState<SiegerblattFunde>
    with SingleTickerProviderStateMixin {
  late final List<GearCopy> _reihe;
  late final AnimationController _ablauf;

  /// Wie viele Kacheln schon herumgedreht sind — für den Klang.
  int _gedreht = 0;

  bool _waehlen = false;
  Set<String> _auswahl = <String>{};

  static const double _breite = 64;
  static const double _hoehe = 82;

  @override
  void initState() {
    super.initState();
    _reihe = SiegerblattFunde.reihenfolge(widget.funde);
    // **In `initState`, nicht faul** (`gotchas.md`): Ein Controller, den
    // erst `dispose` berührt, entsteht mitten im Abbau.
    _ablauf = AnimationController(vsync: this, duration: _gesamt)
      ..addListener(_klinge);
    _ablauf.forward();
  }

  Duration get _gesamt {
    final n = math.max(0, _reihe.length - 1);
    return widget.vorlauf +
        SiegerblattFunde.abstand * n +
        SiegerblattFunde.drehen;
  }

  /// Wo im Ablauf (0 bis 1) die Kachel [i] beginnt und endet.
  (double, double) _fenster(int i) {
    final gesamt = _gesamt.inMicroseconds;
    final beginn = widget.vorlauf + SiegerblattFunde.abstand * i;
    final ende = beginn + SiegerblattFunde.drehen;
    return (
      beginn.inMicroseconds / gesamt,
      math.min(1, ende.inMicroseconds / gesamt),
    );
  }

  /// Wie weit die Kachel [i] gedreht ist, 0 (Rückseite) bis 1 (Stück).
  double _drehung(int i) {
    final (beginn, ende) = _fenster(i);
    if (ende <= beginn) return 1;
    return ((_ablauf.value - beginn) / (ende - beginn)).clamp(0.0, 1.0);
  }

  /// Klingt, wenn eine Kachel die Hälfte ihrer Drehung erreicht — dort
  /// wird das Stück sichtbar.
  void _klinge() {
    while (_gedreht < _reihe.length && _drehung(_gedreht) >= 0.5) {
      final rarity = _reihe[_gedreht].item?.rarity;
      _gedreht++;
      ref
          .read(soundPlayerProvider)
          .play(
            rarity == GearRarity.legendary
                ? SoundEffect.legendaer
                : SoundEffect.fund,
          );
    }
  }

  @override
  void dispose() {
    _ablauf.dispose();
    super.dispose();
  }

  void _tippe(GearCopy copy, Loadout loadout) {
    final item = copy.item;
    if (item == null) return;
    if (!_waehlen) {
      showGearSheet(context, item);
      return;
    }
    if (!VerkaufAuswahl.waehlbar(loadout, copy)) return;
    setState(() {
      _auswahl = _auswahl.contains(copy.uid)
          ? (<String>{..._auswahl}..remove(copy.uid))
          : <String>{..._auswahl, copy.uid};
    });
  }

  Future<void> _verkaufe() async {
    final verkauft = await sellSelectedWithConfirm(context, ref, _auswahl);
    if (!verkauft || !mounted) return;
    setState(() {
      _auswahl = <String>{};
      _waehlen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loadout = ref.watch(loadoutProvider);
    // **Verkauftes verschwindet**; was nie im Rucksack war (in Tests),
    // bleibt stehen.
    final sichtbar = <(int, GearCopy)>[
      for (final (i, copy) in _reihe.indexed)
        if (loadout.owns(copy.uid) || !loadout.hasAcquired(copy.uid)) (i, copy),
    ];
    final auswahl = VerkaufAuswahl.bereinigt(loadout, _auswahl);

    return Semantics(
      container: true,
      label: '${sichtbar.length} Funde',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final (i, copy) in sichtbar)
                AnimatedBuilder(
                  animation: _ablauf,
                  builder: (context, _) =>
                      _gedrehteKachel(_drehung(i), copy, loadout, auswahl),
                ),
            ],
          ),
          if (sichtbar.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            VerkaufLeiste(
              waehlen: _waehlen,
              anzahl: auswahl.length,
              gold: VerkaufAuswahl.erloes(loadout, auswahl),
              onUmschalten: () => setState(() {
                _waehlen = !_waehlen;
                _auswahl = <String>{};
              }),
              onVerkaufen: _verkaufe,
            ),
          ],
        ],
      ),
    );
  }

  Widget _gedrehteKachel(
    double drehung,
    GearCopy copy,
    Loadout loadout,
    Set<String> auswahl,
  ) {
    final item = copy.item!;
    final vorne = drehung >= 0.5;
    final winkel = vorne ? math.pi * (drehung - 1) : math.pi * drehung;
    final legendaer = vorne && item.rarity == GearRarity.legendary;
    final inhalt = vorne
        ? ExemplarKachel(
            key: ValueKey<String>('fund-${copy.uid}'),
            copy: copy,
            vergleich: loadout.vergleiche(copy),
            gesperrt: loadout.isLocked(copy.uid),
            // Ein Kreis nur, wo ein Häkchen geht: Was gerade angelegt ist,
            // lässt sich nicht verkaufen.
            ausgewaehlt: _waehlen && VerkaufAuswahl.waehlbar(loadout, copy)
                ? auswahl.contains(copy.uid)
                : null,
            onTap: () => _tippe(copy, loadout),
          )
        : _Rueckseite(item: item);

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0015)
        ..rotateY(winkel),
      child: Container(
        width: _breite,
        height: _hoehe,
        decoration: legendaer
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: RarityBadge.rahmenOf(
                      GearRarity.legendary,
                    ).withValues(alpha: 0.7),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              )
            : null,
        child: inhalt,
      ),
    );
  }
}

/// Wie ein Fund am Boden lag: der Umriss seines Platzes
/// (`GearIcons.gruppeFor`) in der Farbe der Seltenheit — welches Stück es
/// ist, zeigt erst die Drehung.
class _Rueckseite extends StatelessWidget {
  const _Rueckseite({required this.item});

  final GearItem item;

  @override
  Widget build(BuildContext context) {
    final rahmen = RarityBadge.rahmenOf(item.rarity);
    return Semantics(
      label: '${item.slot.label}, ${item.rarity.label}',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: Palette.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: rahmen, width: RarityBadge.rahmenBreite),
        ),
        child: Center(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(rahmen, BlendMode.srcIn),
            child: PixelArt(
              assetPath: GearIcons.gruppeFor(item.slot),
              side: 36,
              fallback: Icon(GearIcons.fallbackFor(item.slot), color: rahmen),
            ),
          ),
        ),
      ),
    );
  }
}
