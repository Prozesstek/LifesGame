import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../combat/move_icon.dart';
import '../ui/palette.dart';
import '../ui/pixel_art.dart';
import 'action_game.dart';
import 'action_joystick.dart';
import 'lauf_zeichen.dart';

/// Die Zeichen des ersten Laufs, über dem Spielfeld (ADR-0069).
///
/// **Sie nehmen keinen Tipp an.** Das Geister-Steuerkreuz liegt dort, wo
/// der linke Daumen ohnehin aufsetzt; finge es ihn ab, stünde es dem im
/// Weg, was es zeigen soll. Wer sie einbaut, legt sie in ein
/// `IgnorePointer`.
///
/// **Kein eigener Takt.** Beide Zeichen bewegen sich aus der Zeit des
/// Laufs (`ActionWorld.elapsed`) und bauen sich mit `ActionGame.frame`
/// neu — steht der Lauf, stehen auch sie.
class LaufZeichenView extends StatelessWidget {
  const LaufZeichenView({required this.game, required this.zeichen, super.key});

  final ActionGame game;
  final LaufZeichen zeichen;

  /// Woran Tests die beiden Zeichen finden.
  static const Key ziehenKey = ValueKey<String>('zeichen-ziehen');
  static const Key schlagKey = ValueKey<String>('zeichen-schlag');

  /// Wo das Geister-Steuerkreuz steht: links unten, über den Knöpfen der
  /// Fähigkeiten und unter dem Helden.
  static const Alignment ziehenLage = Alignment(-0.4, 0.45);

  /// So lange braucht der Geisterdaumen für einmal Ziehen und Loslassen.
  static const double ziehenPeriode = 1.6;

  /// Wie hoch über dem Helden das Zeichen sitzt — über seinem Balken.
  static const double schlagHoehe = 78;

  /// Wie tief darunter, wenn oben kein Platz ist.
  static const double schlagTiefe = 46;

  /// So weit reichen Karte und Balken von oben ins Spielfeld. Steht der
  /// Held dicht darunter, läge das Zeichen sonst unter der Kopfzeile oder
  /// über dem Rand.
  static const double kopfzeile = 108;

  static const double _schlagSeite = 46;

  /// Wo das Zeichen sitzt, wenn der Held bei [held] im [feld] steht:
  /// über ihm — und unter ihm, wenn dort die Kopfzeile liegt. Am Rand
  /// rückt es herein, statt halb aus dem Bild zu stehen.
  static Offset schlagMitte(Offset held, Size feld) {
    const halb = _schlagSeite / 2;
    final oben = held.dy - schlagHoehe;
    final y = oben - halb < kopfzeile
        ? math.max(held.dy + schlagTiefe, kopfzeile + halb)
        : oben;
    final rechts = math.max(halb + 4, feld.width - halb - 4);
    return Offset(held.dx.clamp(halb + 4, rechts), y);
  }

  /// Wohin der Geisterdaumen zu [sekunden] ausgelenkt ist.
  ///
  /// Aufsetzen, hinausziehen, halten, loslassen — und jedes Mal in eine
  /// andere der vier Richtungen. Immer nach rechts hieße „lauf nach
  /// rechts“; gemeint ist „zieh, wohin du willst“.
  static Offset knopf(double sekunden) {
    final t = (sekunden % ziehenPeriode) / ziehenPeriode;
    final double weit;
    if (t < 0.15) {
      weit = 0;
    } else if (t < 0.5) {
      weit = Curves.easeOut.transform((t - 0.15) / 0.35);
    } else if (t < 0.8) {
      weit = 1;
    } else {
      weit = 1 - Curves.easeIn.transform((t - 0.8) / 0.2);
    }
    final richtung = (sekunden ~/ ziehenPeriode) % 4;
    final winkel = richtung * math.pi / 2;
    return Offset(math.cos(winkel), -math.sin(winkel)) *
        (weit * ActionJoystick.radius);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ValueListenableBuilder<int>(
        valueListenable: game.frame,
        builder: (context, _, _) => _zeichen(constraints.biggest),
      ),
    );
  }

  Widget _zeichen(Size feld) {
    // Ohne Maße weiß das Spiel nicht, wo der Held im Bild steht.
    final schlag = zeichen.zeigtSchlag && game.hasLayout
        ? schlagMitte(game.heroOnScreen, feld)
        : null;

    return Stack(
      children: <Widget>[
        if (zeichen.zeigtZiehen)
          Align(
            alignment: ziehenLage,
            child: Opacity(
              opacity: zeichen.ziehenDeckkraft,
              child: _Geisterkreuz(
                key: ziehenKey,
                knopf: knopf(game.sim.elapsed),
              ),
            ),
          ),
        if (schlag != null)
          Positioned(
            left: schlag.dx - _schlagSeite / 2,
            top: schlag.dy - _schlagSeite / 2,
            child: Opacity(
              opacity: zeichen.schlagDeckkraft,
              child: _SchlaegtVonSelbst(
                key: schlagKey,
                seite: _schlagSeite,
                moveId: game.sim.weapon.moveId,
                winkel: zeichen.schlagAlter * 2.4,
              ),
            ),
          ),
      ],
    );
  }
}

/// Das Steuerkreuz, wie es unter dem Daumen aussähe — mit einem Finger,
/// der es vormacht.
class _Geisterkreuz extends StatelessWidget {
  const _Geisterkreuz({required this.knopf, super.key});

  final Offset knopf;

  @override
  Widget build(BuildContext context) {
    const seite = ActionJoystick.radius * 2 + 44;
    return Semantics(
      container: true,
      label: 'Zum Laufen ziehen',
      child: SizedBox.square(
        dimension: seite,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: ActionJoystick.radius * 2,
              height: ActionJoystick.radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Palette.textOnDark.withValues(alpha: 0.10),
                border: Border.all(
                  color: Palette.textOnDark.withValues(alpha: 0.45),
                  width: 2,
                ),
              ),
            ),
            Transform.translate(
              offset: knopf,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Palette.goldOnDark.withValues(alpha: 0.85),
                ),
                child: const Icon(
                  Icons.touch_app,
                  size: 28,
                  color: Palette.background,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Die Waffe in zwei Pfeilen, die sich drehen: Das läuft von selbst.
class _SchlaegtVonSelbst extends StatelessWidget {
  const _SchlaegtVonSelbst({
    required this.seite,
    required this.moveId,
    required this.winkel,
    super.key,
  });

  final double seite;
  final String moveId;
  final double winkel;

  @override
  Widget build(BuildContext context) {
    const faust = Icon(
      Icons.sports_martial_arts,
      size: 20,
      color: Palette.textOnDark,
    );
    final pfad = MoveIcons.forMoveId(moveId);

    return Semantics(
      container: true,
      label: 'Der Held schlägt von selbst',
      child: Container(
        width: seite,
        height: seite,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Palette.backgroundRaised.withValues(alpha: 0.9),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Transform.rotate(
              angle: winkel,
              child: Icon(
                Icons.autorenew,
                size: seite,
                color: Palette.goldOnDark,
              ),
            ),
            if (pfad == null)
              faust
            else
              PixelArt(assetPath: pfad, side: 22, fallback: faust),
          ],
        ),
      ),
    );
  }
}
