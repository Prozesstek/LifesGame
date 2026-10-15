import 'dart:math' as math;

import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';

import '../combat/move_icon.dart';
import 'action_game.dart';
import '../ui/druck.dart';
import '../ui/palette.dart';
import '../ui/pixel_art.dart';

/// Die Knöpfe unten rechts: die Fähigkeiten auf den Plätzen.
///
/// **Nur die Plätze, keine festen Knöpfe.** Sturmschritt und Rundumschlag
/// gab es bis zum 21.09. als Grundfähigkeiten für jeden; sie sind
/// entfernt, damit der Kampf an dem hängt, was man sich im Baum und über
/// Streaks verdient hat.
///
/// **Rechts unten, wo die zweite Hand liegt.** Der Daumen links läuft,
/// der Daumen rechts drückt — auf einem Handy im Hochformat ist das die
/// einzige Aufteilung, die ohne Umgreifen funktioniert.
///
/// Der Ring zeigt die Abklingzeit. Er läuft zu, statt eine Zahl
/// herunterzuzählen: Im Kampf liest niemand Ziffern, aber jeder sieht
/// einen vollen Kreis.
///
/// **Kurz tippen zielt selbst, halten und ziehen zielt von Hand.** Beim
/// Halten zeigt das Bild die Fläche in der Farbe der Fähigkeit; der Zug
/// vom Knopf weg ist Richtung und Weite, Loslassen wirkt. Heilung,
/// Schutz und Mana haben nichts zu zielen und wirken beim Drücken.
class AbilityButtons extends StatelessWidget {
  const AbilityButtons({required this.game, super.key});

  final ActionGame game;

  ActionWorld get world => game.sim;

  /// Drei davon müssen neben das Steuerkreuz passen.
  static const double slotSize = 58;

  /// Mit Ultimate (ADR-0073): sie gross in der Ecke, die drei kleiner im
  /// Bogen darum.
  static const double ultimateSize = 76;
  static const double arcSlotSize = 50;

  /// Wie weit die Mitten der kleinen von der grossen entfernt sind.
  static const double _bogen = ultimateSize / 2 + arcSlotSize / 2 + 8;

  /// Die ganze Fläche mit Ultimate, quadratisch.
  static const double arcExtent = ultimateSize / 2 + _bogen + arcSlotSize / 2;

  @override
  Widget build(BuildContext context) {
    final ult = world.ultimate;
    if (ult != null) return _mitUltimate(ult);
    if (world.slots.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final ability in world.slots) ...<Widget>[
          _AimGesture(
            game: game,
            ability: ability,
            child: _RoundButton(
              size: slotSize,
              label: ability.name,
              ratio: world.slotCooldownRatio(ability.id),
              ready: world.canCast(ability.id),
              child: _SlotIcon(ability: ability),
            ),
          ),
          if (ability != world.slots.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

extension on AbilityButtons {
  /// Die Ultimate unten rechts, die drei anderen links und oben im
  /// Viertelkreis darum — links zuerst, wo der Daumen hinkommt.
  Widget _mitUltimate(PitAbility ult) {
    const mitte = AbilityButtons.arcExtent - AbilityButtons.ultimateSize / 2;
    const winkel = <double>[math.pi, math.pi * 1.25, math.pi * 1.5];
    return SizedBox(
      width: AbilityButtons.arcExtent,
      height: AbilityButtons.arcExtent,
      child: Stack(
        children: <Widget>[
          for (var i = 0; i < world.slots.length && i < winkel.length; i++)
            Positioned(
              left:
                  mitte +
                  math.cos(winkel[i]) * AbilityButtons._bogen -
                  AbilityButtons.arcSlotSize / 2,
              top:
                  mitte +
                  math.sin(winkel[i]) * AbilityButtons._bogen -
                  AbilityButtons.arcSlotSize / 2,
              child: _AimGesture(
                game: game,
                ability: world.slots[i],
                child: _RoundButton(
                  size: AbilityButtons.arcSlotSize,
                  label: world.slots[i].name,
                  ratio: world.slotCooldownRatio(world.slots[i].id),
                  ready: world.canCast(world.slots[i].id),
                  child: _SlotIcon(
                    ability: world.slots[i],
                    side: AbilityButtons.arcSlotSize - 14,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _AimGesture(
              key: const Key('ultimate-knopf'),
              game: game,
              ability: ult,
              child: _UltimateButton(
                label: ult.name,
                charge: world.ultimateCharge,
                ready: world.canCast(ult.id),
                child: _SlotIcon(
                  ability: ult,
                  side: AbilityButtons.ultimateSize - 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Der Knopf der Ultimate: **goldener Doppelrand**, kein Tortenstück —
/// statt der Abklingzeit läuft ein Ring voll, so weit, wie sie geladen
/// ist (ADR-0073). Ultimates haben keine Seltenheit; Gold allein hiesse
/// Legendär, der doppelte Rand unterscheidet sie.
class _UltimateButton extends StatelessWidget {
  const _UltimateButton({
    required this.label,
    required this.charge,
    required this.ready,
    required this.child,
  });

  final String label;

  /// Wie voll sie ist, 0 bis 1.
  final double charge;
  final bool ready;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: ready,
      label: label,
      child: SizedBox(
        width: AbilityButtons.ultimateSize,
        height: AbilityButtons.ultimateSize,
        child: CustomPaint(
          painter: _CooldownPainter(ratio: 0, ready: ready),
          foregroundPainter: _UltimateRing(charge: charge, ready: ready),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Ladering und Doppelrand der Ultimate.
class _UltimateRing extends CustomPainter {
  const _UltimateRing({required this.charge, required this.ready});

  final double charge;
  final bool ready;

  @override
  void paint(Canvas canvas, Size size) {
    final mitte = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (!ready) {
      canvas.drawCircle(
        mitte,
        radius,
        Paint()..color = Colors.black.withValues(alpha: 0.45),
      );
    }

    // Der Ladering, innen am Rand, von oben im Uhrzeigersinn.
    canvas.drawArc(
      Rect.fromCircle(center: mitte, radius: radius - 7),
      -math.pi / 2,
      2 * math.pi * charge.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = Palette.rahmenGoldHell
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Der Doppelrand.
    final rand = Paint()
      ..color = ready ? Palette.rahmenGoldHell : Palette.rahmenGoldDunkel
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(mitte, radius - 1, rand);
    canvas.drawCircle(mitte, radius - 4, rand);
  }

  @override
  bool shouldRepaint(_UltimateRing old) {
    return old.charge != charge || old.ready != ready;
  }
}

/// Drücken, halten, ziehen, loslassen — über rohe Zeigerereignisse,
/// damit Tippen und Ziehen nicht um dieselbe Geste streiten.
class _AimGesture extends StatefulWidget {
  const _AimGesture({
    super.key,
    required this.game,
    required this.ability,
    required this.child,
  });

  final ActionGame game;
  final PitAbility ability;
  final Widget child;

  @override
  State<_AimGesture> createState() => _AimGestureState();
}

/// Ein Zustand, weil die Knöpfe sich jedes Bild neu bauen — der Anfang
/// eines Zugs muss das überleben.
class _AimGestureState extends State<_AimGesture> {
  Offset? _start;

  /// Ob der Finger auf dem Knopf liegt — auch während des Zielens. Der
  /// Knopf bleibt eingedrückt, solange man hält (`lib/ui/druck.dart`).
  bool _gedrueckt = false;

  void _setze(bool gedrueckt) {
    if (_gedrueckt != gedrueckt) setState(() => _gedrueckt = gedrueckt);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final ability = widget.ability;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        _setze(true);
        // Nichts zu zielen: wirken, solange der Finger unten ist. Ein
        // Knopf, der erst beim Loslassen auslöst, fühlt sich zäh an.
        if (ability.aim == PitAim.selbst) {
          game.sim.cast(ability.id);
          return;
        }
        _start = event.position;
        game.beginAim(ability.id);
      },
      onPointerMove: (event) {
        final von = _start;
        if (von == null) return;
        final zug = event.position - von;
        game.aimDrag(Vec2(zug.dx, zug.dy));
      },
      onPointerUp: (_) {
        _setze(false);
        if (_start == null) return;
        _start = null;
        game.releaseAim();
      },
      onPointerCancel: (_) {
        _setze(false);
        _start = null;
        game.cancelAim();
      },
      child: DruckSkala(gedrueckt: _gedrueckt, child: widget.child),
    );
  }
}

/// Das Bild einer Fähigkeit — dasselbe wie auf dem Charakterbildschirm,
/// über `MoveIcons`, weil die Ids dieselben sind.
class _SlotIcon extends StatelessWidget {
  const _SlotIcon({
    required this.ability,
    this.side = AbilityButtons.slotSize - 16,
  });

  final PitAbility ability;

  /// Wie gross das Bild im Knopf ist.
  final double side;

  @override
  Widget build(BuildContext context) {
    final ersatz = Text(
      ability.name.characters.first,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Palette.textOnDark,
      ),
    );
    final pfad = MoveIcons.forMoveId(ability.id);
    if (pfad == null) return ersatz;
    return PixelArt(assetPath: pfad, side: side, fallback: ersatz);
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.size,
    required this.label,
    required this.ratio,
    required this.ready,
    required this.child,
  });

  final double size;
  final String label;

  /// Wie viel der Abklingzeit noch offen ist, 0 bis 1.
  final double ratio;

  final bool ready;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: ready,
      label: label,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CooldownPainter(ratio: ratio, ready: ready),
          // Das Bild liegt unter dem Tortenstück der Abklingzeit, damit
          // man beides zugleich sieht.
          foregroundPainter: _CooldownShade(ratio: ratio, ready: ready),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _CooldownPainter extends CustomPainter {
  const _CooldownPainter({required this.ratio, required this.ready});

  final double ratio;
  final bool ready;

  @override
  void paint(Canvas canvas, Size size) {
    final mitte = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(
      mitte,
      radius,
      Paint()
        ..color = (ready ? Palette.chipOnDark : Palette.trackOnDark).withValues(
          alpha: 0.85,
        ),
    );
  }

  @override
  bool shouldRepaint(_CooldownPainter old) {
    return old.ratio != ratio || old.ready != ready;
  }
}

/// Abklingzeit und Rand über dem Bild.
///
/// Ein Knopf, der nur wegen fehlenden Manas nicht geht, ist abgedunkelt
/// ohne Tortenstück — so sieht man den Unterschied zwischen „gleich
/// wieder" und „erst Mana sammeln".
class _CooldownShade extends CustomPainter {
  const _CooldownShade({required this.ratio, required this.ready});

  final double ratio;
  final bool ready;

  @override
  void paint(Canvas canvas, Size size) {
    final mitte = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (ratio > 0) {
      // Der offene Rest als Tortenstück, von oben im Uhrzeigersinn.
      canvas.drawArc(
        Rect.fromCircle(center: mitte, radius: radius),
        -math.pi / 2,
        2 * math.pi * ratio,
        true,
        Paint()..color = Colors.black.withValues(alpha: 0.45),
      );
    } else if (!ready) {
      canvas.drawCircle(
        mitte,
        radius,
        Paint()..color = Colors.black.withValues(alpha: 0.4),
      );
    }

    canvas.drawCircle(
      mitte,
      radius - 1,
      Paint()
        ..color = ready ? Palette.goldOnDark : Palette.textOnDarkDim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_CooldownShade old) {
    return old.ratio != ratio || old.ready != ready;
  }
}
