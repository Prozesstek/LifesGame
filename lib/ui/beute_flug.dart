import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'aufstieg.dart';
import 'muenz_bild.dart';

/// Wohin ein Stück fliegt: die Goldzahl, der Erfahrungsbalken — oder
/// der Balken des Gebiets, zu dem die Gewohnheit gehört (ADR-0085).
///
/// Erfahrung und Gebiet bekommen **denselben Betrag**: Ein Häkchen zählt
/// fürs Level und für seinen Skill. Zwei Ströme zu zwei Balken zeigen
/// genau das.
enum FlugZiel { gold, erfahrung, gebiet }

/// **Was ein Häkchen auswirft** — Münzen, die zur Goldzahl fliegen, und
/// Funken zum Erfahrungsbalken. Reine Rechnung, ohne Leinwand.
///
/// **Nur Darstellung**, wie der Goldregen der Grube: Gezählt ist längst,
/// sobald der Tracker das Häkchen hat. Was hier fliegt, ist dieselbe
/// Summe in Stücken, und die Leiste oben zeigt, was davon **angekommen**
/// ist ([unterwegs] wird abgezogen) — die Zahl steigt mit den Münzen,
/// nicht vor ihnen.
///
/// Erst platzen die Stücke am Finger auf, dann zieht es sie in einem
/// Bogen zu ihrem Ziel, schneller mit jedem Augenblick.
class BeuteFlug {
  BeuteFlug({int seed = 11}) : _zufall = math.Random(seed);

  /// Wie viele Stücke ein Betrag wirft. **Nie eins allein**: Ein Stück
  /// ist eine Zahl, drei sind ein Regen. Und nie mehr als acht — ein
  /// Häkchen ist kein Wächter.
  static int stueckeFuer(int betrag, FlugZiel ziel) {
    if (betrag <= 0) return 0;
    return switch (ziel) {
      FlugZiel.gold => betrag.clamp(3, 8),
      FlugZiel.erfahrung || FlugZiel.gebiet => (betrag ~/ 3).clamp(3, 8),
    };
  }

  /// Wie lange ein Stück unterwegs ist, in Sekunden.
  static const double flugzeit = 0.65;

  /// Wie weit die Stücke gestaffelt abheben.
  static const double staffel = 0.05;

  /// Die Funken heben einen Hauch nach den Münzen ab — sonst flöge alles
  /// als ein Klumpen.
  static const double funkenVersatz = 0.1;

  /// Die grünen Funken des Gebiets noch einen Hauch später: Erst sieht
  /// man das Level, dann, dass es ein zweites Mal zählt.
  static const double gebietVersatz = 0.22;

  /// Welcher Teil der Flugzeit aufs Aufplatzen geht.
  static const double platzen = 0.18;

  /// Wie weit sie am Finger auseinanderplatzen, in Punkten.
  static const double streuung = 34;

  /// Wie weit der Bogen nach oben und zur Seite ausholt.
  static const double bogen = 70;

  final math.Random _zufall;
  final List<FlugStueck> _stuecke = <FlugStueck>[];
  final Map<FlugZiel, int> _unterwegs = <FlugZiel, int>{
    for (final ziel in FlugZiel.values) ziel: 0,
  };

  /// [betrag] fliegt von [von] nach [nach]. Gibt zurück, nach wie vielen
  /// Sekunden das letzte Stück ankommt — 0, wenn nichts fliegt.
  ///
  /// [farbe] trägt ein Funke zum Gebiet: die seines Gebiets (ADR-0090).
  double wirf({
    required Offset von,
    required FlugZiel ziel,
    required Offset nach,
    required int betrag,
    Color? farbe,
  }) {
    final anzahl = stueckeFuer(betrag, ziel);
    if (anzahl == 0) return 0;
    final versatz = switch (ziel) {
      FlugZiel.gold => 0.0,
      FlugZiel.erfahrung => funkenVersatz,
      FlugZiel.gebiet => gebietVersatz,
    };
    for (var i = 0; i < anzahl; i++) {
      final winkel = _zufall.nextDouble() * 2 * math.pi;
      final weit = streuung * (0.5 + _zufall.nextDouble() * 0.5);
      final platzt = von + Offset(math.cos(winkel), math.sin(winkel)) * weit;
      final mitte = Offset.lerp(platzt, nach, 0.5) ?? nach;
      final kontrolle =
          mitte +
          Offset(
            (_zufall.nextDouble() - 0.5) * 2 * bogen,
            -bogen * (0.4 + _zufall.nextDouble() * 0.6),
          );
      _stuecke.add(
        FlugStueck(
          ziel: ziel,
          von: von,
          platzt: platzt,
          kontrolle: kontrolle,
          nach: nach,
          startet: versatz + i * staffel,
          // Ganze Zahlen, die zusammen genau den Betrag ergeben: Der Rest
          // geht an die ersten.
          wert: betrag ~/ anzahl + (i < betrag % anzahl ? 1 : 0),
          phase: _zufall.nextDouble() * 2 * math.pi,
          farbe: farbe,
        ),
      );
    }
    _unterwegs[ziel] = unterwegs(ziel) + betrag;
    return versatz + (anzahl - 1) * staffel + flugzeit;
  }

  /// Rechnet [dt] Sekunden weiter. Gibt zurück, wo in diesem Bild etwas
  /// angekommen ist — für Klang und Aufspringen.
  Set<FlugZiel> update(double dt) {
    final angekommen = <FlugZiel>{};
    for (final stueck in _stuecke) {
      stueck.alter += dt;
      if (!stueck.angekommen) continue;
      angekommen.add(stueck.ziel);
      _unterwegs[stueck.ziel] = unterwegs(stueck.ziel) - stueck.wert;
    }
    _stuecke.removeWhere((s) => s.angekommen);
    return angekommen;
  }

  /// Was noch fliegt, als Betrag — die Leiste zieht es ab.
  int unterwegs(FlugZiel ziel) => _unterwegs[ziel] ?? 0;

  bool get leer => _stuecke.isEmpty;

  List<FlugStueck> get stuecke => List<FlugStueck>.unmodifiable(_stuecke);
}

/// Eine Münze oder ein Funke auf dem Weg zur Leiste.
///
/// Nur [alter] ändert sich; wo das Stück steht, folgt daraus. Damit ist
/// jeder Augenblick des Flugs nachrechenbar, ohne ihn abzuspielen.
class FlugStueck {
  FlugStueck({
    required this.ziel,
    required this.von,
    required this.platzt,
    required this.kontrolle,
    required this.nach,
    required this.startet,
    required this.wert,
    required this.phase,
    this.farbe,
  });

  final FlugZiel ziel;
  final Offset von;

  /// Wohin es am Finger aufplatzt.
  final Offset platzt;

  /// Der Punkt, um den sich der Bogen spannt.
  final Offset kontrolle;
  final Offset nach;

  /// Ab welchem Alter es abhebt.
  final double startet;

  /// Welcher Teil des Betrags es ist.
  final int wert;

  /// Wo es sich gerade dreht, damit nicht alle im Gleichtakt blinken.
  final double phase;

  /// Die Farbe eines Funkens zum Gebiet; sonst null.
  final Color? farbe;

  double alter = 0;

  double get _weg => (alter - startet) / BeuteFlug.flugzeit;

  bool get angekommen => _weg >= 1;
  bool get sichtbar => _weg > 0 && _weg < 1;

  Offset get ort => ortBei(_weg);

  /// Wo es einen Augenblick vorher stand — für die Spur des Funkens.
  Offset get vorher => ortBei(_weg - 0.04);

  /// Wie die Münze gerade steht, als Kosinus ihres Winkels.
  double get drehung => math.cos(alter * 14 + phase);

  /// Wo es bei [weg] steht, 0 am Finger, 1 am Ziel.
  Offset ortBei(double weg) {
    if (weg <= 0) return von;
    if (weg >= 1) return nach;
    if (weg < BeuteFlug.platzen) {
      final e = Curves.easeOutCubic.transform(weg / BeuteFlug.platzen);
      return Offset.lerp(von, platzt, e) ?? platzt;
    }
    // Erst langsam, dann gesaugt — eine quadratische Bézierkurve, im
    // Quadrat der Zeit durchlaufen. Kubisch hingen die Stücke zu lange
    // hinter den aufsteigenden Zahlen.
    final roh = (weg - BeuteFlug.platzen) / (1 - BeuteFlug.platzen);
    final s = roh * roh;
    final a = 1 - s;
    return platzt * (a * a) + kontrolle * (2 * a * s) + nach * (s * s);
  }
}

/// Malt, was fliegt. Zeichnet neu, sobald [repaint] sich meldet.
class BeuteFlugMaler extends CustomPainter {
  BeuteFlugMaler(this.flug, {required Listenable repaint})
    : super(repaint: repaint);

  final BeuteFlug flug;

  static const double muenzRadius = 7;
  static const double funkenRadius = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stueck in flug.stuecke) {
      if (!stueck.sichtbar) continue;
      switch (stueck.ziel) {
        case FlugZiel.gold:
          MuenzBild.muenze(
            canvas,
            stueck.ort,
            radius: muenzRadius,
            drehung: stueck.drehung,
            glimmt: true,
          );
        case FlugZiel.erfahrung:
        case FlugZiel.gebiet:
          MuenzBild.funke(
            canvas,
            stueck.ort,
            spur: stueck.vorher,
            radius: funkenRadius,
            flackern: 0.8 + 0.2 * math.sin(stueck.alter * 30 + stueck.phase),
            farbe: stueck.ziel == FlugZiel.gebiet ? stueck.farbe : null,
          );
      }
    }
  }

  @override
  bool shouldRepaint(BeuteFlugMaler alt) => !identical(alt.flug, flug);
}

/// **Ein Ziel, zu dem ein Häkchen fliegt** — die Goldzahl oder der
/// Balken in der Leiste oben.
///
/// Meldet sich beim [AufstiegHost] darüber an und springt kurz auf, wenn
/// etwas bei ihm ankommt. Ohne Host ist es ein gewöhnliches Kind.
class FlugZielMarke extends StatefulWidget {
  const FlugZielMarke({
    required this.ziel,
    required this.child,
    this.staerke = 0.3,
    this.fuer,
    this.pulst = true,
    super.key,
  });

  final FlugZiel ziel;
  final Widget child;

  /// Wofür genau dieses Ziel steht, wenn es mehrere gleicher Art gibt —
  /// die vier Kacheln der Gebiete. Null für das eine.
  final Object? fuer;

  /// Ob es beim Ankommen aufspringt. Kommt bei einer Nachbarkachel etwas
  /// an, bleibt diese stehen.
  final bool pulst;

  /// Wie weit es beim Ankommen aufspringt, als Anteil seiner Grösse. Ein
  /// breiter Balken braucht weniger als eine Zahl.
  final double staerke;

  @override
  State<FlugZielMarke> createState() => _FlugZielMarkeState();
}

class _FlugZielMarkeState extends State<FlugZielMarke>
    with SingleTickerProviderStateMixin {
  final GlobalKey _ort = GlobalKey();
  late final AnimationController _puls;
  AufstiegHostState? _host;
  ValueListenable<int>? _unterwegs;
  int _zuletzt = 0;

  @override
  void initState() {
    super.initState();
    _puls = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final host = AufstiegHost.maybeOf(context);
    if (identical(host, _host)) return;
    _abmelden();
    _host = host;
    if (host == null) return;
    host.meldeZiel(widget.ziel, _ort, fuer: widget.fuer);
    final unterwegs = host.unterwegs(widget.ziel)..addListener(_geaendert);
    _unterwegs = unterwegs;
    _zuletzt = unterwegs.value;
  }

  /// Weniger unterwegs heisst: Es ist etwas angekommen.
  void _geaendert() {
    final jetzt = _unterwegs?.value ?? 0;
    if (jetzt < _zuletzt && widget.pulst) _puls.forward(from: 0);
    _zuletzt = jetzt;
  }

  void _abmelden() {
    _unterwegs?.removeListener(_geaendert);
    _unterwegs = null;
    _host?.vergissZiel(widget.ziel, _ort, fuer: widget.fuer);
  }

  @override
  void dispose() {
    _abmelden();
    _puls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _puls,
      child: KeyedSubtree(key: _ort, child: widget.child),
      builder: (context, child) {
        final t = _puls.value;
        final groesse = t >= 1
            ? 1.0
            : 1 + widget.staerke * math.sin(math.pi * t);
        return Transform.scale(scale: groesse, child: child);
      },
    );
  }
}
