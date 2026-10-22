import 'dart:math' as math;

import 'package:action_combat/action_combat.dart';
import 'package:progression/progression.dart';

/// Was ein gefallener Gegner auswirft: Münzen und Funken, die erst
/// springen und dann zum Helden fliegen.
///
/// **Nur Darstellung.** Die Welt hat Gold und Erfahrung schon gezählt,
/// sobald sie `LootDropped` meldet (ADR-0041); was hier fliegt, ist
/// dieselbe Summe, in Stücke zerlegt. Ein Stück, das nie ankommt, kostet
/// also nichts — es zeigt nur zu spät, was die Welt schon gezählt hat.
/// Deshalb gibt es kein Aufheben: Jedes Stück fliegt von selbst zum
/// Helden.
///
/// **Gebucht wird es erst mit dem Sieg** (ADR-0084). Geht der Lauf
/// verloren, nimmt [verliere] alles wieder: Die Kasse zählt herunter,
/// der Balken läuft zurück, und Münzen und Funken springen vom Helden weg
/// und verlöschen.
///
/// **Eine reine Rechnung, ohne Leinwand**, wie `Kampfgefuehl` und
/// `DamagePopup`: Was ankommt und wann der Balken überläuft, prüft ein
/// Test ohne Spiel.
class BeuteRegen {
  BeuteRegen({required this.startXp, int seed = 7})
    : _zufall = math.Random(seed);

  /// Die Erfahrung des Spielers vor dem Lauf, oder null, wenn der Lauf
  /// keine zahlt (Tagesgrube, Prototyp). Dann gibt es keinen Balken.
  final int? startXp;

  final math.Random _zufall;
  final List<Beutestueck> _stuecke = <Beutestueck>[];
  final List<GehenderFund> _gehendeFunde = <GehenderFund>[];

  double _gold = 0;
  double _xp = 0;
  int _geworfenesGold = 0;
  double _goldPuls = double.infinity;
  double _xpPuls = double.infinity;
  double _aufstiegAlter = double.infinity;

  /// Seit wann die Niederlage nimmt, oder null, solange sie es nicht tut.
  double? _verlustAlter;

  /// Was beim Helden angekommen war, als die Niederlage kam.
  double _verlustGold = 0;
  double _verlustXp = 0;

  // --- Wie viel fällt ---

  /// Wie viele Münzen ein Betrag wirft. **Nie eine einzelne**: Ein
  /// Goldstück ist eine Zahl, drei sind ein Regen. Der Wächter wirft
  /// einen Brunnen.
  static int muenzenFuer(int gold, {required bool gross}) {
    if (gold <= 0) return 0;
    return gross ? (gold * 4).clamp(16, 48) : (gold * 3).clamp(3, 14);
  }

  /// Wie viele Funken eine Menge Erfahrung wirft.
  static int funkenFuer(int xp, {required bool gross}) {
    if (xp <= 0) return 0;
    return gross ? xp.clamp(12, 36) : (xp * 2).clamp(3, 12);
  }

  /// Ab wann ein Stück zum Helden fliegt. Vorher springt es — erst das
  /// Aufplatzen, dann das Einsammeln, sonst sieht man keins von beiden.
  static const double muenzeSammeltAb = 0.5;
  static const double funkeSammeltAb = 0.3;

  /// Wie weit die Stücke gestaffelt abheben. Ein Brunnen, der auf einmal
  /// losfliegt, ist ein Klumpen.
  static const double staffel = 0.03;

  /// Wie lange ein Stück höchstens unterwegs ist. Danach gilt es als
  /// angekommen — ein Held, der davonrennt, soll keine Wolke hinter sich
  /// herziehen.
  static const double hoechstensUnterwegs = 3;

  /// Ab wann ein Stück als angekommen gilt.
  static const double ankunftsRadius = 10;

  /// Wie lange die Kasse und der Balken nach einer Ankunft aufleuchten.
  static const double pulsDauer = 0.18;

  /// Wie lange der Aufstieg mitten im Lauf gross dasteht.
  static const double aufstiegDauer = 1.8;

  /// Wie lange eine Niederlage braucht, um alles zu nehmen. In den ersten
  /// drei Vierteln verlässt ein Stück nach dem anderen den Helden, die
  /// letzten verlöschen danach noch [verlorenLebt] lang.
  static const double verlustDauer = 1.4;

  /// Wie lange ein genommenes Stück noch zu sehen ist.
  static const double verlorenLebt = 0.9;

  /// Höchstens so viele Stücke je Art verlassen den Helden — mehr wäre
  /// ein Klumpen statt einer Rechnung, die man mitzählen kann.
  static const int verlorenHoechstens = 24;

  // --- Was fliegt ---

  /// Ein gefallener Gegner hat [loot] gebracht. [gross] ist der Wächter.
  void wirf(LootDropped loot, {required bool gross}) {
    _geworfenesGold += loot.gold;
    final muenzen = muenzenFuer(loot.gold, gross: gross);
    for (var i = 0; i < muenzen; i++) {
      _stuecke.add(
        _neu(
          BeuteArt.gold,
          loot.at,
          wert: loot.gold / muenzen,
          tempo: gross ? 70 + _zufall.nextDouble() * 50 : 60,
          sammeltAb: muenzeSammeltAb + i * staffel,
          sprung: gross ? 220 : 160,
        ),
      );
    }
    final funken = funkenFuer(loot.xp, gross: gross);
    for (var i = 0; i < funken; i++) {
      _stuecke.add(
        _neu(
          BeuteArt.erfahrung,
          loot.at,
          wert: loot.xp / funken,
          tempo: gross ? 70 : 45,
          sammeltAb: funkeSammeltAb + i * staffel,
          sprung: 0,
        ),
      );
    }
  }

  Beutestueck _neu(
    BeuteArt art,
    Vec2 at, {
    required double wert,
    required double tempo,
    required double sammeltAb,
    required double sprung,
  }) {
    final winkel = _zufall.nextDouble() * 2 * math.pi;
    final schnell = tempo * (0.6 + _zufall.nextDouble() * 0.8);
    return Beutestueck(
      art: art,
      x: at.x,
      y: at.y,
      vx: math.cos(winkel) * schnell,
      vy: math.sin(winkel) * schnell,
      vz: sprung * (0.75 + _zufall.nextDouble() * 0.5),
      wert: wert,
      sammeltAb: sammeltAb,
      phase: _zufall.nextDouble() * 2 * math.pi,
    );
  }

  /// Die Niederlage nimmt alles, was in diesem Lauf gefallen ist — vom
  /// Helden bei [held] aus (ADR-0084). [funde] sind die Nummern der
  /// eingesammelten Gegenstände (ADR-0083); auch sie verlassen ihn.
  ///
  /// Was noch fliegt, kommt nicht mehr an und verlischt, wo es ist. Gibt
  /// zurück, ob es etwas zu nehmen gab; ohne gibt es auch kein Bild.
  bool verliere(Vec2 held, {List<int> funde = const <int>[]}) {
    if (_verlustAlter != null) return false;
    for (final stueck in _stuecke) {
      stueck.verliere(losAb: 0);
    }
    if (_gold <= 0 && _xp <= 0 && _stuecke.isEmpty && funde.isEmpty) {
      return false;
    }
    for (final (i, nth) in funde.indexed) {
      final winkel = -math.pi / 2 + (i - (funde.length - 1) / 2) * 0.7;
      _gehendeFunde.add(
        GehenderFund(
          nth: nth,
          vonX: held.x,
          vonY: held.y,
          richtungX: math.cos(winkel),
          richtungY: math.sin(winkel),
          losAb: math.min(i * 0.18, verlustDauer * 0.75),
        ),
      );
    }
    final goldVorher = gold;
    final xpVorher = xp;
    _verlustAlter = 0;
    _verlustGold = _gold;
    _verlustXp = _xp;
    _nimm(BeuteArt.gold, held, muenzenFuer(goldVorher, gross: true));
    _nimm(BeuteArt.erfahrung, held, funkenFuer(xpVorher, gross: true));
    return true;
  }

  /// Legt [anzahl] Stücke an den Helden, die ihn nacheinander verlassen.
  void _nimm(BeuteArt art, Vec2 held, int anzahl) {
    final n = math.min(anzahl, verlorenHoechstens);
    for (var i = 0; i < n; i++) {
      _stuecke.add(
        _neu(
          art,
          held,
          wert: 0,
          tempo: art == BeuteArt.gold ? 110 : 70,
          sammeltAb: double.infinity,
          sprung: art == BeuteArt.gold ? 200 : 0,
        )..verliere(losAb: verlustDauer * 0.75 * i / n),
      );
    }
  }

  /// Wie weit die Niederlage genommen hat, 0 bis 1 — die Kasse zählt im
  /// selben Takt herunter, in dem die Stücke den Helden verlassen.
  double get _genommen {
    final alter = _verlustAlter;
    if (alter == null) return 0;
    return (alter / (verlustDauer * 0.75)).clamp(0.0, 1.0);
  }

  /// Ob die Niederlage gerade nimmt.
  bool get verliert {
    final alter = _verlustAlter;
    return alter != null && alter < verlustDauer + verlorenLebt;
  }

  /// Ob eine Niederlage genommen hat oder gerade nimmt.
  bool get verloren => _verlustAlter != null;

  /// Rechnet [dt] Sekunden weiter, zum Helden bei [held] hin.
  ///
  /// Gibt zurück, was in diesem Bild angekommen ist — für die Klänge.
  BeuteAnkunft update(double dt, Vec2 held) {
    _goldPuls += dt;
    _xpPuls += dt;
    _aufstiegAlter += dt;
    final levelVorher = stand?.level;
    final goldVorher = gold;
    final xpVorher = xp;
    final verlust = _verlustAlter;
    if (verlust != null) _verlustAlter = verlust + dt;

    var goldKam = false;
    var xpKam = false;
    for (final fund in _gehendeFunde) {
      fund.alter += dt;
    }
    _gehendeFunde.removeWhere((f) => f.vorbei);
    for (final stueck in _stuecke) {
      stueck.update(dt, held);
      if (!stueck.angekommen || stueck.verloren) continue;
      switch (stueck.art) {
        case BeuteArt.gold:
          _gold += stueck.wert;
          goldKam = true;
        case BeuteArt.erfahrung:
          _xp += stueck.wert;
          xpKam = true;
      }
    }
    _stuecke.removeWhere((s) => s.angekommen);
    // Auch das Herunterzählen leuchtet: jede Zahl weniger ein Puls.
    if (goldKam || gold < goldVorher) _goldPuls = 0;
    if (xpKam || xp < xpVorher) _xpPuls = 0;

    final levelNachher = stand?.level;
    final aufstieg =
        levelVorher != null &&
        levelNachher != null &&
        levelNachher > levelVorher;
    if (aufstieg) _aufstiegAlter = 0;
    return (gold: goldKam, xp: xpKam, aufstieg: aufstieg);
  }

  // --- Was die Anzeige liest ---

  List<Beutestueck> get stuecke => List<Beutestueck>.unmodifiable(_stuecke);

  /// Ob in diesem Lauf schon Gold gefallen ist — dann steht die Kasse
  /// da, auch wenn die erste Münze noch fliegt.
  bool get hatGold => _geworfenesGold > 0;

  /// Ob nichts mehr unterwegs ist — und keine Niederlage mehr nimmt.
  bool get leer => _stuecke.isEmpty && _gehendeFunde.isEmpty && !verliert;

  /// Die eingesammelten Gegenstände, die eine Niederlage gerade nimmt.
  List<GehenderFund> get gehendeFunde =>
      List<GehenderFund>.unmodifiable(_gehendeFunde);

  /// Was beim Helden angekommen ist. Abgerundet, mit einem Hauch Luft:
  /// Drei Münzen zu je einem Drittel sind ein Goldstück, nicht 0,999.
  ///
  /// Nach einer Niederlage zählt es herunter, bis nichts mehr da ist.
  int get gold => _zaehle(_gold, _verlustGold);
  int get xp => _zaehle(_xp, _verlustXp);

  int _zaehle(double angekommen, double beimVerlust) {
    if (_verlustAlter == null) return (angekommen + 1e-6).floor();
    return (beimVerlust * (1 - _genommen) + 1e-6).floor();
  }

  /// Wie stark Kasse oder Balken gerade aufleuchten, 0 bis 1.
  double get goldLeuchten => _leuchten(_goldPuls);
  double get xpLeuchten => _leuchten(_xpPuls);

  static double _leuchten(double alter) =>
      alter >= pulsDauer ? 0 : 1 - alter / pulsDauer;

  /// Wo der Spieler gerade steht — mit allem, was angekommen ist. Null
  /// ohne [startXp].
  PlayerLevel? get stand {
    final start = startXp;
    return start == null ? null : LevelCurve.levelFor(start + xp);
  }

  /// Wie weit der Aufstieg mitten im Lauf ist, 0 bis 1, oder null, wenn
  /// keiner zu sehen ist.
  double? get aufstieg =>
      _aufstiegAlter >= aufstiegDauer ? null : _aufstiegAlter / aufstiegDauer;
}

/// Ein eingesammelter Gegenstand, den die Niederlage wieder nimmt
/// (ADR-0084): Er springt in einem Bogen nach oben vom Helden weg und
/// verblasst. Gezeichnet wird er wie am Boden (`BeuteAmBoden`).
class GehenderFund {
  GehenderFund({
    required this.nth,
    required this.vonX,
    required this.vonY,
    required this.richtungX,
    required this.richtungY,
    required this.losAb,
  });

  /// Die Nummer des Fundes im Lauf.
  final int nth;
  final double vonX;
  final double vonY;
  final double richtungX;
  final double richtungY;

  /// Ab welchem Alter er den Helden verlässt.
  final double losAb;

  double alter = 0;

  /// Wie lange er unterwegs ist, ab [losAb].
  static const double dauer = 1.0;

  /// Wie weit er fliegt.
  static const double weite = 70;

  double get _t => ((alter - losAb) / dauer).clamp(0.0, 1.0);

  bool get vorbei => alter - losAb >= dauer;

  /// Wie deutlich er zu sehen ist: erst ab [losAb], verblasst in der
  /// zweiten Hälfte.
  double get sichtbar {
    if (alter < losAb) return 0;
    return (2 - 2 * _t).clamp(0.0, 1.0);
  }

  /// Wo er steht — abbremsend nach aussen, dazu ein Bogen nach oben.
  double get x => vonX + richtungX * weite * _aus(_t);
  double get y =>
      vonY + richtungY * weite * _aus(_t) - 28 * math.sin(math.pi * _t);

  /// Wie gross, 1 am Helden, kleiner, je weiter er weg ist.
  double get groesse => 1 - 0.35 * _t;

  static double _aus(double t) => 1 - (1 - t) * (1 - t);
}

/// Was in einem Bild angekommen ist.
typedef BeuteAnkunft = ({bool gold, bool xp, bool aufstieg});

enum BeuteArt { gold, erfahrung }

/// Eine Münze oder ein Funke.
///
/// **Veränderlich, wie jedes Teilchen im Renderer** (`DamagePopup`,
/// `Burst`): Hunderte neue Werte je Sekunde wären Buchhaltung ohne
/// Nutzen, und niemand ausser [BeuteRegen] hält eins fest.
class Beutestueck {
  Beutestueck({
    required this.art,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.vz,
    required this.wert,
    required this.sammeltAb,
    required this.phase,
  });

  final BeuteArt art;

  /// Wo es auf dem Boden steht, in Weltkoordinaten.
  double x;
  double y;

  /// Wie hoch es über dem Boden ist — nur Münzen springen.
  double z = 0;

  double vx;
  double vy;
  double vz;

  /// Welcher Teil des Betrags es ist.
  final double wert;

  /// Ab welchem Alter es zum Helden fliegt.
  final double sammeltAb;

  /// Wo es sich gerade dreht, damit nicht alle Münzen im Gleichtakt
  /// blinken.
  final double phase;

  double alter = 0;
  bool angekommen = false;

  /// Ob die Niederlage das Stück genommen hat. Dann kommt es nie an,
  /// zählt nichts und verlischt (ADR-0084).
  bool verloren = false;

  /// Ab welchem Alter ein genommenes Stück zu sehen ist und sich bewegt.
  double losAb = 0;

  /// Nimmt das Stück: Es verlässt den Helden in [losAb] Sekunden.
  void verliere({required double losAb}) {
    verloren = true;
    this.losAb = alter + losAb;
  }

  /// Wie deutlich es zu sehen ist, 0 bis 1. Nur ein genommenes Stück
  /// verblasst — in der zweiten Hälfte seiner Zeit.
  double get sichtbar {
    if (!verloren) return 1;
    final seit = alter - losAb;
    if (seit < 0) return 0;
    const halb = BeuteRegen.verlorenLebt / 2;
    return (1 - (seit - halb) / halb).clamp(0.0, 1.0);
  }

  /// Wo es im letzten Bild stand — für die Spur des Funkens.
  double vorherX = 0;
  double vorherY = 0;

  bool get fliegt => !verloren && alter >= sammeltAb;

  static const double _schwere = 700;
  static const double _abprall = 0.35;
  static const double _hoeheImFlug = 10;

  void update(double dt, Vec2 held) {
    vorherX = x;
    vorherY = y;
    alter += dt;
    if (verloren) {
      // Genommen: erst warten, dann wegspringen und verlöschen.
      if (alter - losAb >= BeuteRegen.verlorenLebt) angekommen = true;
      if (alter >= losAb) _spring(dt);
      return;
    }
    if (alter >= BeuteRegen.hoechstensUnterwegs) {
      angekommen = true;
      return;
    }
    if (fliegt) {
      _flieg(dt, held);
    } else {
      _spring(dt);
    }
  }

  void _spring(double dt) {
    x += vx * dt;
    y += vy * dt;
    if (art == BeuteArt.erfahrung) {
      // Ein Funke treibt aus und steigt dabei leicht.
      final bremse = math.exp(-3 * dt);
      vx *= bremse;
      vy = vy * bremse - 25 * dt;
      return;
    }
    // Eine Münze springt einmal auf und rollt aus.
    vz -= _schwere * dt;
    z += vz * dt;
    if (z <= 0) {
      z = 0;
      vz = vz.abs() > 60 ? -vz * _abprall : 0;
      final reibung = math.exp(-6 * dt);
      vx *= reibung;
      vy *= reibung;
    }
  }

  /// Zum Helden, schneller mit jeder Zehntelsekunde: Es soll gesaugt
  /// aussehen, nicht geschoben.
  void _flieg(double dt, Vec2 held) {
    final dx = held.x - x;
    final dy = held.y - y;
    final weg = math.sqrt(dx * dx + dy * dy);
    final tempo = 180 + 1100 * (alter - sammeltAb);
    final schritt = tempo * dt;
    if (weg <= BeuteRegen.ankunftsRadius || schritt >= weg) {
      x = held.x;
      y = held.y;
      angekommen = true;
      return;
    }
    x += dx / weg * schritt;
    y += dy / weg * schritt;
    if (art == BeuteArt.gold) z += (_hoeheImFlug - z) * math.min(1, 8 * dt);
  }
}
