import 'dart:math' as math;
import 'dart:ui';

import '../audio/sound_effects.dart';

/// Wie sich ein Treffer **anfühlt** — reine Rechnung, ohne Leinwand.
///
/// Die Welt meldet, was geschehen ist (`HitLanded`, `EntityDied`,
/// `AbilityCast`); hier steht, wie laut die Darstellung darauf antwortet:
/// ein kurzer Stopp, ein Beben, ein roter Rand, ein Klang. **Nichts davon
/// ändert eine Zahl des Kampfes** — die Welt erfährt von alledem nur, dass
/// sie einen Augenblick später weitergerechnet wird.

/// Der Trefferstopp: Das Bild friert kurz ein, wenn ein Gegner fällt oder
/// ein kritischer Treffer sitzt.
///
/// Gestoppt wird die **ganze** Darstellung samt Welt, nicht nur die
/// Figuren — sonst liefe die Uhr des Laufs weiter, während nichts
/// geschieht, und der Stopp kostete Zeit.
class Trefferstopp {
  /// Wie lange das Bild steht.
  static const double dauer = 0.05;

  /// Wie lange danach keiner mehr folgt. Ohne die Pause stotterte das
  /// Bild, wenn ein Flächentreffer fünf Gegner nacheinander fällt.
  static const double pause = 0.15;

  double _rest = 0;
  double _sperre = 0;

  bool get haelt => _rest > 0;

  /// Ein Grund zu stoppen. Steht das Bild schon oder ist der letzte
  /// Stopp eben erst vorbei, geschieht nichts.
  void ausloesen() {
    if (_sperre > 0) return;
    _rest = dauer;
    _sperre = dauer + pause;
  }

  /// Wie viel von [dt] die Welt weiterrechnen darf: nichts, solange das
  /// Bild steht, und nur den Rest, wenn der Stopp in diesem Bild endet.
  double zeit(double dt) {
    _sperre = math.max(0, _sperre - dt);
    if (_rest <= 0) return dt;
    final frei = dt - _rest;
    _rest = math.max(0, _rest - dt);
    return math.max(0, frei);
  }
}

/// Das Beben des Bildes.
///
/// Abklingend, und aus der Zeit statt aus dem Zufall — derselbe Lauf bebt
/// jedes Mal gleich.
class Beben {
  /// Der Wächter schlägt bei seinem Auftritt auf.
  static const double landungDauer = 0.45;
  static const double landungStaerke = 7;

  /// Der Held wurde getroffen: kurz und klein, es kommt oft.
  static const double trefferDauer = 0.18;
  static const double trefferStaerke = 3;

  double _rest = 0;
  double _dauer = 1;
  double _staerke = 0;

  /// Wie stark es in diesem Augenblick bebt, in Bildpunkten.
  double get staerke => _rest > 0 ? _staerke * _rest / _dauer : 0;

  /// Ein Stoss. **Ein schwächerer löscht keinen stärkeren**: Wer während
  /// der Landung des Wächters getroffen wird, soll sie nicht abkürzen.
  void stoss({required double dauer, required double staerke}) {
    if (this.staerke > staerke) return;
    _rest = dauer;
    _dauer = dauer;
    _staerke = staerke;
  }

  void advance(double dt) {
    if (_rest > 0) _rest = math.max(0, _rest - dt);
  }

  /// Um wie viel das Bild gerade verschoben ist.
  Offset get versatz {
    final s = staerke;
    if (s <= 0) return Offset.zero;
    return Offset(math.sin(_rest * 90) * s, math.cos(_rest * 70) * s);
  }
}

/// Der rote Rand: Er steht, solange der Held wenig Leben hat.
abstract final class LebensRand {
  /// Unter diesem Anteil des Lebens erscheint er.
  static const double schwelle = 0.25;

  /// Wie breit er an jeder Kante ins Bild reicht, in Bildpunkten.
  static const double breite = 56;

  /// Wie oft er je Sekunde pulst.
  static const double _puls = 1.2;

  /// Wie deckend der Rand ist, 0 bis 1.
  ///
  /// Je weniger Leben, desto kräftiger; dazu ein ruhiger Puls aus der
  /// Zeit des Laufs ([zeit]), damit er ohne eigenen Takt auskommt. Ein
  /// gefallener Held hat keinen Rand mehr — dann steht das Ergebnis da.
  static double deckkraft(double hpRatio, double zeit) {
    if (hpRatio <= 0 || hpRatio >= schwelle) return 0;
    final not = 1 - hpRatio / schwelle;
    final grund = 0.45 + 0.55 * not;
    final puls = 0.8 + 0.2 * math.sin(zeit * 2 * math.pi * _puls);
    return (grund * puls).clamp(0.0, 1.0);
  }
}

/// Welche Klänge ein Bild der Grube auslöst.
///
/// Die Welt kann in einem Bild zehn Treffer melden. Zehnmal denselben
/// Klang zu starten hiesse, ihn neunmal abzuschneiden — deshalb wird hier
/// gesammelt: **jeder Klang höchstens einmal je Bild**, und nie dichter
/// als [abstand].
class KampfKlang {
  /// So dicht dürfen zwei gleiche Klänge aufeinander folgen.
  static const double abstand = 0.07;

  final Set<SoundEffect> _gemeldet = <SoundEffect>{};
  final Map<SoundEffect, double> _ruhe = <SoundEffect, double>{};

  void melde(SoundEffect effect) => _gemeldet.add(effect);

  /// Was nach [dt] Sekunden zu spielen ist, und vergisst es.
  ///
  /// **Ein Kill schluckt den Treffer**, der ihn gebracht hat: Beide im
  /// selben Augenblick wären ein Geräusch, nicht zwei.
  List<SoundEffect> abholen(double dt) {
    for (final effect in _ruhe.keys.toList()) {
      final rest = _ruhe[effect]! - dt;
      if (rest <= 0) {
        _ruhe.remove(effect);
      } else {
        _ruhe[effect] = rest;
      }
    }
    if (_gemeldet.contains(SoundEffect.gefallen)) {
      _gemeldet.remove(SoundEffect.treffer);
    }
    final faellig = <SoundEffect>[
      for (final effect in _gemeldet)
        if (!_ruhe.containsKey(effect)) effect,
    ];
    _gemeldet.clear();
    for (final effect in faellig) {
      _ruhe[effect] = abstand;
    }
    return faellig;
  }
}
