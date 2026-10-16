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
/// **Was abklingt, sieht man auf drei Arten** (`AbklingAnzeige`): ein
/// dunkles Tortenstück läuft im Uhrzeigersinn zu, das Bild ist
/// ausgegraut, und in der Mitte zählen die Sekunden herunter. Ist sie
/// zurück, leuchtet der Knopf kurz auf und ein Ring springt nach aussen.
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
          _platz(ability, slotSize),
          if (ability != world.slots.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

extension on AbilityButtons {
  /// Ein Platz im Kampf. **Ein Passiv hat keinen Knopf** (ADR-0073): Sein
  /// Bild steht da, damit man sieht, was wirkt, nimmt aber keinen Tipp
  /// an und hat nichts zu zielen.
  Widget _platz(PitAbility ability, double size, {double? side}) {
    final knopf = _RoundButton(
      size: size,
      label: ability.isPassive ? '${ability.name}, passiv' : ability.name,
      ratio: world.slotCooldownRatio(ability.id),
      left: world.slotCooldownLeft(ability.id),
      elapsed: world.elapsed,
      ready: ability.isPassive || world.canCast(ability.id),
      child: side == null
          ? _SlotIcon(ability: ability)
          : _SlotIcon(ability: ability, side: side),
    );
    if (ability.isPassive) {
      return IgnorePointer(child: Opacity(opacity: 0.75, child: knopf));
    }
    return _AimGesture(game: game, ability: ability, child: knopf);
  }

  /// Die Ultimate unten rechts, die drei anderen links und oben im
  /// Viertelkreis darum — links zuerst, wo der Daumen hinkommt.
  Widget _mitUltimate(PitAbility ult) {
    const mitte = AbilityButtons.arcExtent - AbilityButtons.ultimateSize / 2;
    const winkel = <double>[math.pi, math.pi * 1.25, math.pi * 1.5];
    return SizedBox(
      width: AbilityButtons.arcExtent,
      height: AbilityButtons.arcExtent,
      child: Stack(
        // Der Ring der Rückkehr springt über den Rand des Knopfs hinaus.
        clipBehavior: Clip.none,
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
              child: _platz(
                world.slots[i],
                AbilityButtons.arcSlotSize,
                side: AbilityButtons.arcSlotSize - 14,
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

/// Was der Knopf beim Abklingen zeigt — reine Rechnung, damit sie ohne
/// Bildschirm prüfbar ist.
abstract final class AbklingAnzeige {
  /// Wie lange der Knopf nach der Rückkehr aufleuchtet, in Sekunden des
  /// Laufs.
  static const double glanzSekunden = 0.45;

  /// Die Zahl in der Mitte: ganze Sekunden, aufgerundet, unter einer
  /// Sekunde mit einer Stelle — „3“, „1“, „0,4“. Bereit heisst keine Zahl.
  static String? zahl(double sekunden) {
    if (sekunden <= 0) return null;
    if (sekunden >= 1) return sekunden.ceil().toString();
    final zehntel = (sekunden * 10).ceil().clamp(1, 9);
    return '0,$zehntel';
  }

  /// Wie stark der Glanz der Rückkehr noch ist: 1 im Augenblick der
  /// Rückkehr, dann bis 0. Ohne Rückkehr kein Glanz.
  static double glanz({required double? zurueckBei, required double jetzt}) {
    if (zurueckBei == null) return 0;
    final vergangen = jetzt - zurueckBei;
    if (vergangen < 0 || vergangen >= glanzSekunden) return 0;
    return 1 - vergangen / glanzSekunden;
  }
}

/// Ein Zustand, weil die Rückkehr ein **Übergang** ist: Der Knopf merkt
/// sich, wann die Abklingzeit auf null fiel. Gezählt wird in der Zeit des
/// Laufs (`ActionWorld.elapsed`), nicht mit eigenem Takt — hält die Welt
/// an, hält auch der Glanz.
class _RoundButton extends StatefulWidget {
  const _RoundButton({
    required this.size,
    required this.label,
    required this.ratio,
    required this.left,
    required this.elapsed,
    required this.ready,
    required this.child,
  });

  final double size;
  final String label;

  /// Wie viel der Abklingzeit noch offen ist, 0 bis 1.
  final double ratio;

  /// Wie viele Sekunden noch offen sind.
  final double left;

  /// Die Zeit des Laufs.
  final double elapsed;

  final bool ready;
  final Widget child;

  @override
  State<_RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<_RoundButton> {
  double? _zurueckBei;

  @override
  void didUpdateWidget(_RoundButton old) {
    super.didUpdateWidget(old);
    if (old.ratio > 0 && widget.ratio <= 0) _zurueckBei = widget.elapsed;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final klingt = w.ratio > 0;
    final glanz = AbklingAnzeige.glanz(
      zurueckBei: _zurueckBei,
      jetzt: w.elapsed,
    );
    final zahl = AbklingAnzeige.zahl(w.left);
    return Semantics(
      button: true,
      enabled: w.ready,
      label: w.label,
      value: zahl == null ? null : '$zahl s',
      child: SizedBox(
        width: w.size,
        height: w.size,
        child: Stack(
          alignment: Alignment.center,
          // Der Ring der Rückkehr springt über den Rand hinaus.
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(
                painter: _CooldownPainter(ratio: w.ratio, ready: w.ready),
                // Das Bild liegt unter dem Tortenstück der Abklingzeit,
                // damit man beides zugleich sieht.
                foregroundPainter: AbklingSchatten(
                  ratio: w.ratio,
                  ready: w.ready,
                  glanz: glanz,
                ),
                child: Center(
                  child: Opacity(
                    // Ausgegraut und blasser, solange sie abklingt.
                    opacity: klingt ? 0.55 : 1,
                    child: klingt
                        ? ColorFiltered(
                            colorFilter: const ColorFilter.matrix(_grau),
                            child: w.child,
                          )
                        : w.child,
                  ),
                ),
              ),
            ),
            // Die Zahl liegt über dem Tortenstück, sonst dunkelt es sie ab.
            if (zahl != null)
              Text(
                zahl,
                key: const Key('abklingzahl'),
                style: TextStyle(
                  fontSize: w.size * 0.34,
                  fontWeight: FontWeight.bold,
                  color: Palette.textOnDark,
                  shadows: const <Shadow>[
                    Shadow(blurRadius: 3, color: Colors.black),
                    Shadow(offset: Offset(1, 1), color: Colors.black),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Graustufen nach Helligkeit (Rec. 709).
const List<double> _grau = <double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
];

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

/// Abklingzeit, Rand und Glanz der Rückkehr über dem Bild — öffentlich,
/// damit ein Test den Glanz lesen kann.
///
/// Ein Knopf, der nur wegen fehlenden Manas nicht geht, ist abgedunkelt
/// ohne Tortenstück — so sieht man den Unterschied zwischen „gleich
/// wieder" und „erst Mana sammeln".
class AbklingSchatten extends CustomPainter {
  const AbklingSchatten({
    required this.ratio,
    required this.ready,
    this.glanz = 0,
  });

  final double ratio;
  final bool ready;

  /// Der Glanz der Rückkehr, 1 bis 0 (`AbklingAnzeige.glanz`).
  final double glanz;

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
        Paint()..color = Colors.black.withValues(alpha: 0.5),
      );
      // Die Kante des Stücks als helle Linie, wie ein Uhrzeiger.
      final winkel = -math.pi / 2 + 2 * math.pi * ratio;
      canvas.drawLine(
        mitte,
        mitte + Offset(math.cos(winkel), math.sin(winkel)) * (radius - 2),
        Paint()
          ..color = Palette.textOnDark.withValues(alpha: 0.7)
          ..strokeWidth = 1.5,
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

    if (glanz > 0) {
      // Zurück: der Knopf leuchtet auf, ein Ring springt nach aussen.
      canvas.drawCircle(
        mitte,
        radius,
        Paint()..color = Palette.goldOnDark.withValues(alpha: 0.35 * glanz),
      );
      canvas.drawCircle(
        mitte,
        radius + 10 * (1 - glanz),
        Paint()
          ..color = Palette.goldOnDark.withValues(alpha: glanz)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * glanz + 1,
      );
    }
  }

  @override
  bool shouldRepaint(AbklingSchatten old) {
    return old.ratio != ratio || old.ready != ready || old.glanz != glanz;
  }
}
