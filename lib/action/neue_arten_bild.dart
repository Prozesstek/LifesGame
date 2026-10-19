import 'dart:math' as math;
import 'dart:ui';

import 'package:action_combat/action_combat.dart';

import '../ui/palette.dart';
import 'pit_tints.dart';

/// Wie die Arten aus ADR-0073 im Bild stehen: Falle, Begleiter, Faden des
/// Hakens, Eis und Stillstand, die Kerben des Wächters, der Wurf des
/// Glückstranks.
///
/// **Nur Darstellung.** Die Welt meldet, was geschieht (`HookThrown`,
/// `TrapSprung` …) und zeigt, was liegt (`traps`, `companion`); hier wird
/// es gezeichnet, und was nur einen Augenblick dauert, läuft hier ab. Eine
/// eigene Datei, damit `action_game.dart` nicht weiter wächst.
class NeueArtenBild {
  final List<_Blitz> _blitze = <_Blitz>[];

  /// Nimmt ein Ereignis der Welt. Gibt zurück, ob es eines von hier war.
  bool melde(ActionEvent event) {
    switch (event) {
      case HookThrown(:final from, :final to):
        _blitze.add(_Blitz.faden(from, to));
      case TrapSprung(:final at):
        _blitze.add(_Blitz.ring(at, Palette.tintKlinge, 22));
      case LuckRolled(:final at, :final outcome):
        _blitze.add(_Blitz.ring(at, _wurfFarbe(outcome), 30));
      case RockChanged(:final at, :final present):
        if (present) _blitze.add(_Blitz.ring(at, Palette.tintSand, 26));
      case CompanionStruck(:final from, :final at, :final devoured):
        _blitze.add(
          _Blitz.faden(
            from,
            at,
            farbe: devoured ? Palette.tintGift : Palette.tintNatur,
          ),
        );
      case BossStunNotched(:final at, :final stunned):
        if (stunned) _blitze.add(_Blitz.ring(at, Palette.tintStern, 50));
      // --- ADR-0074 ---
      case HeroBlinked(:final from, :final to, :final rewind):
        final farbe = rewind ? Palette.tintZeit : Palette.tintSeele;
        _blitze.add(_Blitz.ring(from, farbe, 18));
        _blitze.add(_Blitz.faden(from, to, farbe: farbe));
      case AttackParried(:final at):
        _blitze.add(_Blitz.ring(at, Palette.tintSchutz, 26));
      case ChainJumped(:final from, :final to):
        _blitze.add(_Blitz.faden(from, to, farbe: Palette.tintBlitz));
      case LastStandTriggered(:final at):
        _blitze.add(_Blitz.ring(at, Palette.tintNatur, 44));
      // --- Die Kräfte der Ausrüstung (ADR-0077) ---
      case BloodLashed(:final from, :final to):
        _blitze.add(_Blitz.faden(from, to, farbe: Palette.tintBlut));
        _blitze.add(_Blitz.ring(to, Palette.tintBlut, 16));
      case WispBurst(:final at, :final radius):
        _blitze.add(_Blitz.ring(at, Palette.tintIrrlicht, radius));
      case ShieldRaised(:final at):
        _blitze.add(_Blitz.ring(at, Palette.tintSchutz, 30));
      case AbilityEchoed(:final at):
        _blitze.add(_Blitz.ring(at, Palette.tintSeele, 34));
      default:
        return false;
    }
    return true;
  }

  /// Die Farbe eines Wurfs: je Ausgang eine, der Jackpot golden.
  static Color _wurfFarbe(int ausgang) {
    // Rot gehört dem Wächter — der Angriff leuchtet deshalb wie Lava.
    const farben = <Color>[
      Palette.tintLava,
      Palette.tintFunke,
      Palette.tintZeit,
      Palette.tintSchutz,
      Palette.successOnDark,
      Palette.rahmenGoldHell,
    ];
    return farben[ausgang.clamp(0, farben.length - 1)];
  }

  void update(double dt) {
    for (final blitz in _blitze) {
      blitz.alter += dt;
    }
    _blitze.removeWhere((b) => b.alter >= b.dauer);
  }

  /// Was am Boden liegt — unter den Figuren.
  void drawBoden(Canvas canvas, ActionWorld welt) {
    _frostreif(canvas, welt);
    for (final falle in welt.traps) {
      final mitte = Offset(falle.center.x, falle.center.y);
      canvas.drawCircle(
        mitte,
        falle.radius,
        Paint()..color = Palette.tintKlinge.withValues(alpha: 0.25),
      );
      // Zwei Kiefer mit Zähnen, angedeutet als Zickzack.
      final zacken = Path();
      for (var i = 0; i <= 6; i++) {
        final x = mitte.dx - falle.radius + i * falle.radius / 3;
        final y = mitte.dy + (i.isEven ? -3 : 3);
        if (i == 0) {
          zacken.moveTo(x, y);
        } else {
          zacken.lineTo(x, y);
        }
      }
      canvas.drawPath(
        zacken,
        Paint()
          ..color = Palette.tintKlinge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    for (final (x, y) in welt.level.rocks) {
      const size = ActionBalance.tileSize;
      final rect = Rect.fromLTWH(
        x * size + 2,
        y * size + 2,
        size - 4,
        size - 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(9)),
        Paint()..color = Palette.tintSand.withValues(alpha: 0.35),
      );
    }
  }

  /// Was über den Figuren liegt.
  void drawOben(Canvas canvas, ActionWorld welt) {
    _status(canvas, welt);
    _begleiter(canvas, welt);
    _heldenZustand(canvas, welt);
    _ausruestung(canvas, welt);
    if (welt.isBuffed) {
      final held = welt.heroView;
      canvas.drawCircle(
        Offset(held.position.x, held.position.y),
        held.radius + 7,
        Paint()
          ..color = Palette.tintStern.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    for (final blitz in _blitze) {
      blitz.draw(canvas);
    }
  }

  /// Gefroren: blau überzogen. Betäubt: drei Sterne über dem Kopf.
  void _status(Canvas canvas, ActionWorld welt) {
    for (final view in welt.views) {
      if (view.faction != Faction.gegner || !view.isStunned) continue;
      final mitte = Offset(view.position.x, view.position.y);
      if (view.isFrozen) {
        canvas.drawCircle(
          mitte,
          view.radius + 2,
          Paint()..color = Palette.tintEis.withValues(alpha: 0.45),
        );
        continue;
      }
      final t = welt.elapsed * 4;
      for (var i = 0; i < 3; i++) {
        final winkel = t + i * 2 * math.pi / 3;
        canvas.drawCircle(
          Offset(
            mitte.dx + math.cos(winkel) * view.radius * 0.8,
            mitte.dy - view.radius - 6 + math.sin(winkel) * 2,
          ),
          2,
          Paint()..color = Palette.tintStern,
        );
      }
    }

    // Die Stun-Leiste des Wächters: drei Punkte unter ihm, gefüllt, was
    // schon getroffen hat.
    final kerben = welt.bossStunNotches;
    final boss = welt.bossView;
    if (boss == null || kerben == 0) return;
    for (var i = 0; i < ActionBalance.bossStunNotches; i++) {
      final mitte = Offset(
        boss.position.x + (i - 1) * 9,
        boss.position.y + boss.radius + 8,
      );
      canvas.drawCircle(
        mitte,
        3,
        Paint()..color = i < kerben ? Palette.tintStern : Palette.trackOnDark,
      );
    }
  }

  /// Was AktivesBretts Fähigkeiten am Helden zeigen (ADR-0074): eine
  /// offene Parade als Schild davor, Bestform als goldener Doppelring,
  /// unverwundbar als Zeitring, Kampfrausch als Glut je Treffer.
  void _heldenZustand(Canvas canvas, ActionWorld welt) {
    final held = welt.heroView;
    final mitte = Offset(held.position.x, held.position.y);
    Paint ring(Color farbe, double breite) => Paint()
      ..color = farbe
      ..style = PaintingStyle.stroke
      ..strokeWidth = breite;

    if (welt.isParrying) {
      final blick = held.facing;
      final winkel = math.atan2(blick.y, blick.x);
      canvas.drawArc(
        Rect.fromCircle(center: mitte, radius: held.radius + 9),
        winkel - 0.9,
        1.8,
        false,
        ring(Palette.tintSchutz, 3),
      );
    }
    if (welt.isOverdriven) {
      final puls = 1 + 0.08 * math.sin(welt.elapsed * 8);
      canvas.drawCircle(
        mitte,
        (held.radius + 10) * puls,
        ring(Palette.rahmenGoldHell, 2),
      );
      canvas.drawCircle(
        mitte,
        (held.radius + 14) * puls,
        ring(Palette.rahmenGoldHell.withValues(alpha: 0.6), 1.5),
      );
    }
    if (welt.isInvulnerable) {
      canvas.drawCircle(
        mitte,
        held.radius + 12,
        ring(Palette.tintZeit.withValues(alpha: 0.8), 2.5),
      );
    }
    final rausch = welt.rageStacks;
    for (var i = 0; i < rausch; i++) {
      final winkel = welt.elapsed * 2 + i * 2 * math.pi / 10;
      canvas.drawCircle(
        Offset(
          mitte.dx + math.cos(winkel) * (held.radius + 5),
          mitte.dy + math.sin(winkel) * (held.radius + 5),
        ),
        1.6,
        Paint()..color = Palette.tintLava,
      );
    }
  }

  /// Der Frostreif liegt als blasser Kreis unter dem Helden und atmet
  /// leicht (ADR-0077).
  void _frostreif(Canvas canvas, ActionWorld welt) {
    final radius = welt.frostAuraRadius;
    if (radius == null) return;
    final held = welt.heroView;
    final mitte = Offset(held.position.x, held.position.y);
    final atem = radius * (1 + 0.04 * math.sin(welt.elapsed * 2));
    canvas.drawCircle(
      mitte,
      atem,
      Paint()..color = Palette.tintEis.withValues(alpha: 0.12),
    );
    canvas.drawCircle(
      mitte,
      atem,
      Paint()
        ..color = Palette.tintEis.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  /// Was die Ausrüstung am Helden zeigt (ADR-0077): Irrlichter als
  /// leuchtende Punkte, das Flickwerk als Ring, der mit dem Schild
  /// schwindet, und der Blutpakt als Puls in der Farbe des Bluts.
  void _ausruestung(Canvas canvas, ActionWorld welt) {
    final held = welt.heroView;
    final mitte = Offset(held.position.x, held.position.y);

    for (final licht in welt.wisps) {
      final wo = Offset(licht.position.x, licht.position.y);
      canvas.drawCircle(
        wo,
        ActionBalance.wispRadius + 3,
        Paint()..color = Palette.tintIrrlicht.withValues(alpha: 0.3),
      );
      canvas.drawCircle(
        wo,
        ActionBalance.wispRadius,
        Paint()..color = Palette.tintIrrlicht,
      );
    }

    final schild = welt.shieldRatio;
    if (schild > 0) {
      canvas.drawCircle(
        mitte,
        held.radius + 6,
        Paint()
          ..color = Palette.tintSchutz.withValues(alpha: 0.3 + 0.5 * schild)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 + 2 * schild,
      );
    }

    if (welt.isBloodPact) {
      final puls = 0.5 + 0.5 * math.sin(welt.elapsed * 4);
      canvas.drawCircle(
        mitte,
        held.radius + 3,
        Paint()
          ..color = Palette.tintBlut.withValues(alpha: 0.25 + 0.35 * puls)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  /// Der Falke kreist über dem Helden, die Pflanze steht und atmet. Das
  /// Spiegelbild zeichnet `ActionGame` als Figur.
  void _begleiter(Canvas canvas, ActionWorld welt) {
    final begleiter = welt.companion;
    if (begleiter == null || begleiter.mirror) return;
    final farbe = tintColor(begleiter.tint);
    final deckkraft = begleiter.remaining < 0.1
        ? begleiter.remaining * 10
        : 1.0;
    final Offset wo;
    if (begleiter.stationary) {
      wo = Offset(begleiter.position.x, begleiter.position.y);
    } else {
      final winkel = welt.elapsed * 3;
      wo = Offset(
        begleiter.position.x + math.cos(winkel) * 22,
        begleiter.position.y - 18 + math.sin(winkel) * 8,
      );
    }
    canvas.drawCircle(
      wo,
      begleiter.stationary ? 11 : 6,
      Paint()..color = farbe.withValues(alpha: 0.9 * deckkraft),
    );
    canvas.drawCircle(
      wo,
      begleiter.stationary ? 11 : 6,
      Paint()
        ..color = Palette.background.withValues(alpha: 0.7 * deckkraft)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

/// Etwas, das einen Augenblick im Bild steht.
class _Blitz {
  _Blitz.faden(this.von, this.bis, {this.farbe = Palette.tintSeele})
    : radius = 0,
      dauer = 0.3;

  _Blitz.ring(this.von, this.farbe, this.radius) : bis = null, dauer = 0.4;

  final Vec2 von;
  final Vec2? bis;
  final Color farbe;
  final double radius;
  final double dauer;
  double alter = 0;

  void draw(Canvas canvas) {
    final rest = (1 - alter / dauer).clamp(0.0, 1.0);
    final ende = bis;
    final paint = Paint()
      ..color = farbe.withValues(alpha: rest)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    if (ende != null) {
      canvas.drawLine(Offset(von.x, von.y), Offset(ende.x, ende.y), paint);
      return;
    }
    canvas.drawCircle(
      Offset(von.x, von.y),
      radius * (0.4 + 0.6 * (1 - rest)),
      paint,
    );
  }
}
