import 'package:flutter/material.dart';

/// **Solange [aktiv], fängt sie jeden Tipp** und meldet [onWeiter]
/// (06.11.2026): Der Mentor sagt etwas, das man nur lesen muss, und ein
/// Tipp irgendwohin führt weiter — wie in einem Dialog. Die Hülle steht
/// immer, sonst baute sich darunter alles neu (`gotchas.md`).
class WeiterTipp extends StatelessWidget {
  const WeiterTipp({
    required this.aktiv,
    required this.onWeiter,
    required this.child,
    super.key,
  });

  final bool aktiv;
  final VoidCallback onWeiter;
  final Widget child;

  static const Key flaecheKey = ValueKey<String>('weiter-tipp');

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        child,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !aktiv,
            child: GestureDetector(
              key: flaecheKey,
              behavior: HitTestBehavior.opaque,
              onTap: onWeiter,
            ),
          ),
        ),
      ],
    );
  }
}
