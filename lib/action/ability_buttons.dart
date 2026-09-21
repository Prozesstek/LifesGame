import 'dart:math' as math;

import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';

import '../combat/move_icon.dart';
import '../ui/palette.dart';
import '../ui/pixel_art.dart';

/// Die Knöpfe unten rechts: oben die Plätze, unten Sturmschritt und
/// Rundumschlag.
///
/// **Rechts unten, wo die zweite Hand liegt.** Der Daumen links läuft,
/// der Daumen rechts drückt — auf einem Handy im Hochformat ist das die
/// einzige Aufteilung, die ohne Umgreifen funktioniert.
///
/// Der Ring zeigt die Abklingzeit. Er läuft zu, statt eine Zahl
/// herunterzuzählen: Im Kampf liest niemand Ziffern, aber jeder sieht
/// einen vollen Kreis.
class AbilityButtons extends StatelessWidget {
  const AbilityButtons({
    required this.world,
    required this.onUse,
    required this.onCast,
    super.key,
  });

  final ActionWorld world;
  final void Function(ActionAbility) onUse;

  /// Wirkt eine Fähigkeit von einem Platz (ADR-0039).
  final void Function(String id) onCast;

  static const double size = 62;

  /// Die Plätze etwas kleiner: Sie liegen über den festen Knöpfen, und
  /// drei davon müssen neben das Steuerkreuz passen.
  static const double slotSize = 52;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        if (world.slots.isNotEmpty) ...<Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final ability in world.slots) ...<Widget>[
                _RoundButton(
                  size: slotSize,
                  label: ability.name,
                  ratio: world.slotCooldownRatio(ability.id),
                  ready: world.canCast(ability.id),
                  onTap: () => onCast(ability.id),
                  child: _SlotIcon(ability: ability),
                ),
                if (ability != world.slots.last) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final ability in ActionAbility.values) ...<Widget>[
              _RoundButton(
                size: size,
                label: ability.label,
                ratio: world.cooldownRatio(ability),
                ready: world.isReady(ability),
                onTap: () => onUse(ability),
                child: Icon(
                  _iconFor(ability),
                  size: 26,
                  color: world.isReady(ability)
                      ? Palette.textOnDark
                      : Palette.textOnDarkDim,
                ),
              ),
              if (ability != ActionAbility.values.last)
                const SizedBox(width: 12),
            ],
          ],
        ),
      ],
    );
  }

  static IconData _iconFor(ActionAbility ability) {
    return switch (ability) {
      ActionAbility.sturmschritt => Icons.double_arrow,
      ActionAbility.rundumschlag => Icons.cyclone,
    };
  }
}

/// Das Bild einer Fähigkeit — dasselbe wie auf dem Charakterbildschirm,
/// über `MoveIcons`, weil die Ids dieselben sind.
class _SlotIcon extends StatelessWidget {
  const _SlotIcon({required this.ability});

  final PitAbility ability;

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
    return PixelArt(
      assetPath: pfad,
      side: AbilityButtons.slotSize - 16,
      fallback: ersatz,
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.size,
    required this.label,
    required this.ratio,
    required this.ready,
    required this.onTap,
    required this.child,
  });

  final double size;
  final String label;

  /// Wie viel der Abklingzeit noch offen ist, 0 bis 1.
  final double ratio;

  final bool ready;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: ready,
      label: label,
      child: GestureDetector(
        // Kein `onTap`: Der Schlag soll fallen, während der Finger unten
        // ist. Ein Knopf, der erst beim Loslassen auslöst, fühlt sich in
        // einem Kampf zäh an.
        onTapDown: (_) => onTap(),
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
