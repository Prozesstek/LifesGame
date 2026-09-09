import 'package:flutter/material.dart';

import 'palette.dart';

/// Alles darin steht auf Leder, nicht auf Pergament.
///
/// **Warum es das braucht.** Das Theme ist `Brightness.light`, weil fast
/// jeder Text der App auf einer Pergamentfläche steht — ein `Text` ohne
/// eigene Farbe wird dadurch Tinte. Auf dem dunklen Grund der Arena und
/// der Baumfläche ist das genau falsch herum, und der Fehler ist der
/// unangenehmste seiner Art: Der Text ist da, er ist nur nicht zu sehen.
///
/// **Eine Klammer statt vieler Farbangaben.** Die Alternative wäre, jeden
/// `Text` in `lib/combat/` und `lib/theory/` einzeln zu färben — und beim
/// nächsten hinzugefügten den einen zu vergessen, der dann unsichtbar
/// ist. Was ausdrücklich gefärbt ist, überschreibt diese Klammer
/// ohnehin; die Pergamentkacheln *innerhalb* der Arena bleiben deshalb
/// richtig.
class OnDark extends StatelessWidget {
  const OnDark({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(color: Palette.textOnDark),
      child: IconTheme.merge(
        data: const IconThemeData(color: Palette.textOnDark),
        child: child,
      ),
    );
  }
}
