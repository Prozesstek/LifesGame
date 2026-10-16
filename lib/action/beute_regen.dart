import 'dart:math' as math;

import 'package:action_combat/action_combat.dart';
import 'package:progression/progression.dart';

/// Was ein gefallener Gegner auswirft: Münzen und Funken, die erst
/// springen und dann zum Helden fliegen.
///
/// **Nur Darstellung.** Die Welt hat Gold und Erfahrung schon gezählt,
/// sobald sie `LootDropped` meldet (ADR-0041); was hier fliegt, ist
/// dieselbe Summe, in Stücke zerlegt. Ein Stück, das nie ankommt, kostet
/// also nichts — es zeigt nur zu spät, was längst gebucht ist. Deshalb
/// gibt es kein Aufheben: Jedes Stück fliegt von selbst zum Helden.
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

  double _gold = 0;
  double _xp = 0;
  int _geworfenesGold = 0;
  double _goldPuls = double.infinity;
  double _xpPuls = double.infinity;
  double _aufstiegAlter = double.infinity;

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

  /// Rechnet [dt] Sekunden weiter, zum Helden bei [held] hin.
  ///
  /// Gibt zurück, was in diesem Bild angekommen ist — für die Klänge.
  BeuteAnkunft update(double dt, Vec2 held) {
    _goldPuls += dt;
    _xpPuls += dt;
    _aufstiegAlter += dt;
    final levelVorher = stand?.level;

    var gold = false;
    var xp = false;
    for (final stueck in _stuecke) {
      stueck.update(dt, held);
      if (!stueck.angekommen) continue;
      switch (stueck.art) {
        case BeuteArt.gold:
          _gold += stueck.wert;
          gold = true;
        case BeuteArt.erfahrung:
          _xp += stueck.wert;
          xp = true;
      }
    }
    _stuecke.removeWhere((s) => s.angekommen);
    if (gold) _goldPuls = 0;
    if (xp) _xpPuls = 0;

    final levelNachher = stand?.level;
    final aufstieg =
        levelVorher != null &&
        levelNachher != null &&
        levelNachher > levelVorher;
    if (aufstieg) _aufstiegAlter = 0;
    return (gold: gold, xp: xp, aufstieg: aufstieg);
  }

  // --- Was die Anzeige liest ---

  List<Beutestueck> get stuecke => List<Beutestueck>.unmodifiable(_stuecke);

  /// Ob in diesem Lauf schon Gold gefallen ist — dann steht die Kasse
  /// da, auch wenn die erste Münze noch fliegt.
  bool get hatGold => _geworfenesGold > 0;

  /// Ob nichts mehr unterwegs ist.
  bool get leer => _stuecke.isEmpty;

  /// Was beim Helden angekommen ist. Abgerundet, mit einem Hauch Luft:
  /// Drei Münzen zu je einem Drittel sind ein Goldstück, nicht 0,999.
  int get gold => (_gold + 1e-6).floor();
  int get xp => (_xp + 1e-6).floor();

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

  /// Wo es im letzten Bild stand — für die Spur des Funkens.
  double vorherX = 0;
  double vorherY = 0;

  bool get fliegt => alter >= sammeltAb;

  static const double _schwere = 700;
  static const double _abprall = 0.35;
  static const double _hoeheImFlug = 10;

  void update(double dt, Vec2 held) {
    vorherX = x;
    vorherY = y;
    alter += dt;
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
