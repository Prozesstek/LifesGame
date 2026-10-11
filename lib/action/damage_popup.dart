import 'dart:math' as math;

import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';

import '../ui/palette.dart';

/// Eine Zahl, die über einem Treffer aufploppt, im Bogen davonfliegt und
/// erst am Ende verblasst.
///
/// **Eine reine Rechnung, kein Flame-Gebilde.** Dieselbe Trennung wie bei
/// `damageReadoutFor` im rundenbasierten Kampf, und aus demselben
/// praktischen Grund: Im Spielcode erreicht kein Test die Entscheidung,
/// ohne ein Spiel zu starten — als Klasse mit `update` sind es zehn Zeilen
/// Test.
class DamagePopup {
  DamagePopup({
    required this.text,
    required this.color,
    required this.origin,
    required this.scale,
    this.side = 0,
    this.isCrit = false,
    this.amount = 0,
    this.mergeKey,
  });

  /// Was ein gefallener Gegner einbringt (ADR-0041): golden, etwas höher
  /// als die Schadenszahl, damit beide lesbar bleiben.
  static DamagePopup? forLoot(LootDropped loot) {
    final text = lootText(loot.xp, loot.gold);
    if (text.isEmpty) return null;
    return DamagePopup(
      text: text,
      color: Palette.goldOnDark,
      origin: Vec2(loot.at.x, loot.at.y - 18),
      scale: 0.85,
    );
  }

  /// „+7 EP  +3 G" — aber nur, was wirklich gefallen ist.
  ///
  /// Der Goldtopf einer Stufe ist klein und wird abgerundet verteilt, also
  /// bringt mancher Gegner kein ganzes Goldstück. „+0 G" liest sich wie
  /// ein Fehler; dann steht dort nur die Erfahrung. Dieselbe Regel wie bei
  /// den Schadenszahlen: keine Null über dem Kopf.
  static String lootText(int xp, int gold) {
    return <String>[if (xp > 0) '+$xp EP', if (gold > 0) '+$gold G'].join('  ');
  }

  /// Aus einem Treffer wird eine Zahl — oder nichts.
  ///
  /// Ein Schlag, der nichts anrichtet, bekommt keine Null über den Kopf:
  /// Eine Null liest sich wie ein Fehler, nicht wie ein Ergebnis.
  ///
  /// [scale] sagt, wie gross der Treffer gemessen an den letzten ist
  /// ([HitAverage]), [side], nach welcher Seite er fliegt.
  static DamagePopup? forHit(HitLanded hit, {double scale = 1, int side = 0}) {
    if (hit.amount <= 0) return null;

    final amSpieler = hit.targetFaction == Faction.held;
    return DamagePopup(
      text: '${hit.amount}',
      color: colorOf(hit),
      origin: hit.at,
      // Ein kritischer Treffer ist grösser. Er ist der seltene Fall, und
      // Seltenes darf auffallen.
      scale: hit.isCrit ? scale * critScale : scale,
      side: side,
      isCrit: hit.isCrit,
      amount: hit.amount,
      // Ein kritischer Treffer bleibt für sich: In einer Summe wäre er
      // kein Moment mehr.
      mergeKey: hit.isCrit ? null : (hit.targetId, hit.overTime, amSpieler),
    );
  }

  /// **Eine Farbe je Sache.** Rot kommt beim Helden an, Gold ist
  /// kritisch, Violett frisst über Zeit, Hell ist ein Schlag. Grün bleibt
  /// der Heilung — deshalb trägt Dauerschaden nicht das Grün des Gifts.
  static Color colorOf(HitLanded hit) {
    if (hit.targetFaction == Faction.held) return Palette.enemyOnDark;
    if (hit.isCrit) return Palette.goldOnDark;
    if (hit.overTime) return Palette.tintSeele;
    return Palette.textOnDark;
  }

  /// Was eine Heilung über dem Kopf zeigt — von einer Kugel oder von
  /// einer Fähigkeit.
  ///
  /// Grün und mit Pluszeichen — dieselbe Regel wie im rundenbasierten
  /// Kampf: Heilung sieht nie aus wie Schaden.
  static DamagePopup forHeal(int amount, Vec2 at) {
    return DamagePopup(
      text: '+$amount',
      color: Palette.successOnDark,
      origin: at,
      scale: 1.1,
    );
  }

  /// Was eine Zeitkugel über dem Kopf zeigt: „+8 s" in der Farbe der
  /// Zeit. Bei voller Uhr bringt sie nichts, dann steht dort nichts.
  static DamagePopup? forTime(double seconds, Vec2 at) {
    final ganz = seconds.round();
    if (ganz <= 0) return null;
    return DamagePopup(
      text: '+$ganz s',
      color: Palette.tintZeit,
      origin: Vec2(at.x, at.y - 18),
      scale: 1.1,
    );
  }

  String text;
  final Color color;
  final Vec2 origin;
  double scale;

  /// Nach welcher Seite sie fliegt: -1 links, 1 rechts, 0 gerade hoch.
  /// Treffer wechseln sich ab, damit sie sich nicht stapeln; Heilung,
  /// Zeit und Beute steigen gerade.
  final int side;

  final bool isCrit;

  /// Der Schaden, den sie zeigt — wächst, wenn Treffer dazukommen.
  int amount;

  /// Was zusammengezählt werden darf, trägt denselben Schlüssel. Ohne
  /// Schlüssel bleibt eine Zahl für sich.
  final Object? mergeKey;

  /// Wie lange eine Zahl steht.
  static const double lifetime = 0.8;

  /// Wie hoch der Wurf ansetzt und wie stark er wieder fällt, in
  /// Weltpunkten. Der Scheitel liegt nach zwei Dritteln.
  static const double _wurf = 70;
  static const double _fall = 52;

  /// Wie weit sie dabei zur Seite treibt.
  static const double drift = 16;

  /// Wie gross sie geboren wird, und wie schnell sie sich setzt.
  static const double popScale = 1.6;
  static const double popTime = 0.12;

  /// Ab wann sie verblasst. Bis dahin steht sie voll da — sonst ist sie
  /// weg, bevor man sie gelesen hat.
  static const double fadeFrom = 0.7;

  /// Was einen kritischen Treffer zum Moment macht: grösser, schräg, und
  /// er zittert kurz.
  static const double critScale = 1.6;
  static const double critTilt = 0.18;
  static const double shakeTime = 0.3;
  static const double _shakeWeite = 2.5;

  /// Wie lange ein weiterer Treffer noch dazugezählt wird.
  ///
  /// **Kürzer als der Takt des Grundangriffs.** Zählte jede Zahl mit,
  /// solange sie in der Luft steht, stünde über einem Gegner nur noch
  /// eine wachsende Summe. So fällt zusammen, was zusammen trifft
  /// (Wirbel, Schlag und Tick im selben Augenblick), und jeder Schlag
  /// für sich bleibt seine eigene Zahl.
  static const double mergeWindow = 0.3;

  double age = 0;
  double _seitPop = 0;

  bool get isAlive => age < lifetime;

  double get progress => (age / lifetime).clamp(0.0, 1.0);

  bool canAbsorb(Object key) => mergeKey == key && age < mergeWindow;

  /// Ein weiterer Treffer kommt dazu: Die Zahl wird zur Summe und ploppt
  /// noch einmal. Sie lebt dadurch nicht länger.
  void absorb(int more, {required double scale}) {
    amount += more;
    text = '$amount';
    this.scale = scale;
    _seitPop = 0;
  }

  /// Wo die Zahl gerade steht: ein Wurf zur Seite, kein Aufzug.
  Vec2 get position {
    final p = progress;
    return Vec2(
      origin.x + side * drift * p + _zittern,
      origin.y - (_wurf * p - _fall * p * p),
    );
  }

  double get _zittern {
    if (!isCrit || age >= shakeTime) return 0;
    return math.sin(age * 90) * _shakeWeite * (1 - age / shakeTime);
  }

  /// Wie gross sie gerade gezeichnet wird: gross geboren, sofort gesetzt.
  double get size {
    if (_seitPop >= popTime) return scale;
    return scale * (popScale - (popScale - 1) * (_seitPop / popTime));
  }

  /// Wie schräg sie steht, im Bogenmass.
  double get tilt => isCrit ? critTilt * (side == 0 ? 1 : side) : 0;

  double get opacity {
    final p = progress;
    if (p < fadeFrom) return 1;
    return (1 - (p - fadeFrom) / (1 - fadeFrom)).clamp(0.0, 1.0);
  }

  void update(double dt) {
    age += dt;
    _seitPop += dt;
  }
}

/// Der Schnitt der letzten Treffer des Helden.
///
/// **Gross ist, was grösser ist als zuletzt** — nicht, was über einer
/// festen Zahl liegt. Der Schaden wächst von Stufe 1 bis 30 um ein
/// Vielfaches (ADR-0042); eine feste Schwelle wäre am Anfang nie und am
/// Ende immer erreicht.
class HitAverage {
  static const int _fenster = 12;
  static const double smallest = 0.8;
  static const double biggest = 1.6;

  final List<int> _letzte = <int>[];

  double get value {
    if (_letzte.isEmpty) return 0;
    return _letzte.reduce((a, b) => a + b) / _letzte.length;
  }

  void record(int amount) {
    _letzte.add(amount);
    if (_letzte.length > _fenster) _letzte.removeAt(0);
  }

  /// Der doppelte Schnitt ist anderthalbmal so gross, der halbe ein
  /// Viertel kleiner. Ohne Vorgeschichte ist jeder Treffer normal.
  double scaleFor(int amount) {
    final schnitt = value;
    if (schnitt <= 0) return 1;
    return (1 + 0.5 * (amount / schnitt - 1)).clamp(smallest, biggest);
  }
}

/// Alle Zahlen, die gerade in der Luft stehen.
///
/// Hier fällt, was eine einzelne Zahl nicht wissen kann: nach welcher
/// Seite die nächste fliegt, was zusammengezählt wird, und dass es nie
/// mehr als [maxLive] werden.
class DamagePopups {
  /// Mehr stehen nie zugleich da; kommt eine dazu, geht die älteste.
  static const int maxLive = 40;

  /// Wie gross steht, was über Zeit frisst oder beim Helden ankommt.
  /// Beides wird nicht am Schnitt gemessen: Ticks zögen ihn herunter,
  /// und was der Held einsteckt, hat einen anderen Massstab.
  static const double overTimeScale = 0.85;
  static const double onHeroScale = 1.1;

  final List<DamagePopup> _live = <DamagePopup>[];
  final HitAverage _schnitt = HitAverage();
  int _seite = 1;

  Iterable<DamagePopup> get live => _live;
  int get count => _live.length;

  void hit(HitLanded hit) {
    final neu = DamagePopup.forHit(hit);
    if (neu == null) return;

    final key = neu.mergeKey;
    if (key != null) {
      for (final popup in _live.reversed) {
        if (!popup.canAbsorb(key)) continue;
        final summe = popup.amount + hit.amount;
        popup.absorb(hit.amount, scale: _scaleFor(hit, summe));
        _merken(hit);
        return;
      }
    }

    final popup = DamagePopup.forHit(
      hit,
      scale: _scaleFor(hit, hit.amount),
      side: _seite,
    );
    _seite = -_seite;
    _merken(hit);
    add(popup);
  }

  void add(DamagePopup? popup) {
    if (popup == null) return;
    _live.add(popup);
    if (_live.length > maxLive) _live.removeAt(0);
  }

  void update(double dt) {
    for (final popup in _live) {
      popup.update(dt);
    }
    _live.removeWhere((p) => !p.isAlive);
  }

  double _scaleFor(HitLanded hit, int amount) {
    if (hit.targetFaction == Faction.held) return onHeroScale;
    if (hit.overTime) return overTimeScale;
    return _schnitt.scaleFor(amount);
  }

  void _merken(HitLanded hit) {
    if (hit.targetFaction == Faction.held || hit.overTime) return;
    _schnitt.record(hit.amount);
  }
}

/// Der Strahl eines Wächterauges im Moment, in dem er trifft — er
/// leuchtet einen Augenblick nach und ist weg.
class BeamFlash {
  BeamFlash({required this.from, required this.to});

  final Vec2 from;
  final Vec2 to;
  double age = 0;

  static const double lifetime = 0.22;

  bool get isAlive => age < lifetime;

  double get opacity => (1 - age / lifetime).clamp(0.0, 1.0);
}

/// Ein Ring, der aufgeht und verblasst — für alles, was knallt.
///
/// Drei Anlässe, drei Farben: ein gefallener Gegner, der Rundumschlag,
/// und der Endgegner, der grösser platzt als sein Fussvolk.
class Burst {
  Burst({
    required this.at,
    required this.color,
    required this.maxRadius,
    required this.lifetime,
    required this.strokeWidth,
  });

  /// Wie lange ein Treffer aufblitzt.
  static const double flashTime = 0.12;

  factory Burst.death(Vec2 at, EnemyKind kind) {
    // Der Troll fällt grösser als Fussvolk, aber kleiner als der Wächter —
    // sein Tod soll sich anfühlen wie ein Etappensieg, nicht wie das Ende.
    final (farbe, radius, dauer, strich) = switch (kind) {
      EnemyKind.endgegner => (Palette.enemy, 90.0, 0.7, 5.0),
      EnemyKind.brocken => (Palette.enemy, 55.0, 0.5, 4.0),
      // Die Fledermaus ist klein und zerplatzt entsprechend.
      EnemyKind.flatterer => (Palette.enemyOnDark, 18.0, 0.25, 2.0),
      _ => (Palette.enemyOnDark, 26.0, 0.3, 3.0),
    };
    return Burst(
      at: at,
      color: farbe,
      maxRadius: radius,
      lifetime: dauer,
      strokeWidth: strich,
    );
  }

  /// Der Schrei des Kreischpilzes: ein goldener Ring über den ganzen
  /// Umkreis, den er geweckt hat.
  factory Burst.scream(Vec2 at, double radius) {
    return Burst(
      at: at,
      color: Palette.goldOnDark,
      maxRadius: radius,
      lifetime: 0.6,
      strokeWidth: 4,
    );
  }

  /// Die rote Welle des Bodenstosses — der Moment, in dem es trifft.
  factory Burst.slam(Vec2 at, double radius) {
    return Burst(
      at: at,
      color: Palette.enemy,
      maxRadius: radius,
      lifetime: 0.4,
      strokeWidth: 6,
    );
  }

  /// Der goldene Ring eines Flächentreffers, so gross wie sein [radius].
  factory Burst.cleave(Vec2 at, double radius) {
    return Burst(
      at: at,
      color: Palette.goldOnDark,
      maxRadius: radius,
      lifetime: 0.28,
      strokeWidth: 4,
    );
  }

  final Vec2 at;
  final Color color;
  final double maxRadius;
  final double lifetime;
  final double strokeWidth;

  double age = 0;

  bool get isAlive => age < lifetime;

  double get progress => (age / lifetime).clamp(0.0, 1.0);

  double get radius => maxRadius * progress;

  double get opacity => (1 - progress).clamp(0.0, 1.0);

  void update(double dt) => age += dt;
}

/// Ein kurzer Bogen dort, wo jemand zugeschlagen hat.
///
/// Ohne ihn sieht ein Kampf aus wie zwei Würfel, die sich berühren.
class SwingMark {
  SwingMark({
    required this.origin,
    required this.direction,
    required this.isHero,
  });

  static const double lifetime = 0.16;

  final Vec2 origin;
  final Vec2 direction;
  final bool isHero;

  double age = 0;

  bool get isAlive => age < lifetime;

  double get progress => (age / lifetime).clamp(0.0, 1.0);

  void update(double dt) => age += dt;
}
