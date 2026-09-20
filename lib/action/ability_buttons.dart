import 'dart:math' as math;

import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';

import '../ui/palette.dart';

/// Die zwei Knöpfe unten rechts.
///
/// **Rechts unten, wo die zweite Hand liegt.** Der Daumen links läuft,
/// der Daumen rechts drückt — auf einem Handy im Hochformat ist das die
/// einzige Aufteilung, die ohne Umgreifen funktioniert.
///
/// Der Ring zeigt die Abklingzeit. Er läuft zu, statt eine Zahl
/// herunterzuzählen: Im Kampf liest niemand Ziffern, aber jeder sieht
/// einen vollen Kreis.
class AbilityButtons extends StatelessWidget {
  const AbilityButtons({required this.world, required this.onUse, super.key});

  final ActionWorld world;
  final void Function(ActionAbility) onUse;

  static const double size = 62;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final ability in ActionAbility.values) ...<Widget>[
          _AbilityButton(
            ability: ability,
            ratio: world.cooldownRatio(ability),
            ready: world.isReady(ability),
            onTap: () => onUse(ability),
          ),
          if (ability != ActionAbility.values.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _AbilityButton extends StatelessWidget {
  const _AbilityButton({
    required this.ability,
    required this.ratio,
    required this.ready,
    required this.onTap,
  });

  final ActionAbility ability;

  /// Wie viel der Abklingzeit noch offen ist, 0 bis 1.
  final double ratio;

  final bool ready;
  final VoidCallback onTap;

  IconData get _icon {
    return switch (ability) {
      ActionAbility.sturmschritt => Icons.double_arrow,
      ActionAbility.rundumschlag => Icons.cyclone,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: ready,
      label: ability.label,
      child: GestureDetector(
        // Kein `onTap`: Der Schlag soll fallen, während der Finger unten
        // ist. Ein Knopf, der erst beim Loslassen auslöst, fühlt sich in
        // einem Kampf zäh an.
        onTapDown: (_) => onTap(),
        child: SizedBox(
          width: AbilityButtons.size,
          height: AbilityButtons.size,
          child: CustomPaint(
            painter: _CooldownPainter(ratio: ratio, ready: ready),
            child: Center(
              child: Icon(
                _icon,
                size: 26,
                color: ready ? Palette.textOnDark : Palette.textOnDarkDim,
              ),
            ),
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

    if (ratio > 0) {
      // Der offene Rest als Tortenstück, von oben im Uhrzeigersinn.
      canvas.drawArc(
        Rect.fromCircle(center: mitte, radius: radius),
        -math.pi / 2,
        2 * math.pi * ratio,
        true,
        Paint()..color = Colors.black.withValues(alpha: 0.45),
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
  bool shouldRepaint(_CooldownPainter old) {
    return old.ratio != ratio || old.ready != ready;
  }
}
