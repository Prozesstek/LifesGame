import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Zeigt die App am Rechner in Handygröße, im Hochformat.
///
/// **Warum das nötig ist.** Das Ziel ist ein Handy im Hochformat, entwickelt
/// wird aber gegen Chrome — und ein Browserfenster ist breit. Ohne Rahmen
/// sieht man beim Bauen nie das Format, für das gebaut wird, und
/// Layoutfehler fallen erst auf dem Gerät auf. Ein `GridView`, das auf
/// breiten Fenstern Zeilen verschluckt, ist genau so einmal durchgerutscht
/// (`docs/context/gotchas.md`).
///
/// **Dieses Widget sitzt über `MaterialApp`.** Das ist der Grund für den
/// [Directionality]- und [DefaultTextStyle]-Aufbau weiter unten: Oberhalb
/// der App gibt es keine Textrichtung und keinen Standardstil, ein nacktes
/// [Text] wirft dort. Genau daran ist die erste Fassung gescheitert — mit
/// einem Überlauf quer über den Bildschirm statt einer Fehlermeldung.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({required this.child, this.enabled = kIsWeb, super.key});

  final Widget child;

  /// Ob der Rahmen überhaupt gezeigt wird.
  ///
  /// Standard ist [kIsWeb] — auf einem echten Handy *ist* der Bildschirm
  /// bereits das Gerät. Als Parameter und nicht als feste Abfrage, damit
  /// ein Test den Rahmen prüfen kann; sonst bliebe genau dieses Widget
  /// ungetestet, weil `kIsWeb` im Test immer falsch ist.
  final bool enabled;

  /// Die Maße eines gängigen Handys in logischen Pixeln.
  ///
  /// Bewusst eher schmal gewählt: Was hier passt, passt auf breiteren
  /// Geräten auch. Andersherum gilt das nicht.
  static const Size phoneSize = Size(390, 844);

  /// Dicke des gezeichneten Gehäuserands.
  static const double _bezel = 8;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Passt der Rahmen samt Gehäuse nicht ins Fenster, wird die App
        // einfach normal gezeigt. Ein Rahmen, der selbst überläuft, wäre
        // schlimmer als gar keiner.
        final needed = phoneSize + const Offset(_bezel, _bezel) * 2;
        final fits =
            constraints.hasBoundedHeight &&
            constraints.maxHeight >= needed.height &&
            constraints.maxWidth >= needed.width;

        if (!fits) return child;

        return Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: const Color(0xFF05070C),
            child: Center(child: _Screen(child: child)),
          ),
        );
      },
    );
  }
}

class _Screen extends StatelessWidget {
  const _Screen({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: PhoneFrame.phoneSize.width + PhoneFrame._bezel * 2,
      height: PhoneFrame.phoneSize.height + PhoneFrame._bezel * 2,
      decoration: BoxDecoration(
        color: const Color(0xFF262C3A),
        borderRadius: BorderRadius.circular(38),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x66000000), blurRadius: 28, spreadRadius: 4),
        ],
      ),
      padding: const EdgeInsets.all(PhoneFrame._bezel),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          width: PhoneFrame.phoneSize.width,
          height: PhoneFrame.phoneSize.height,
          child: child,
        ),
      ),
    );
  }
}
