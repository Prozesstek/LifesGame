import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Kopiert einen Text und sagt, dass es geklappt hat (ADR-0072).
///
/// **In die Zwischenablage, nicht ins Teilen-Blatt des Geräts.** Das geht
/// in jedem Browser und braucht kein weiteres Paket; von dort fügt man
/// ihn ein, wo man will. Der Knopf bleibt danach auf „Kopiert“ stehen —
/// ohne Uhr, die ihn zurückstellt, damit nichts im Hintergrund läuft.
class TeilenKnopf extends StatefulWidget {
  const TeilenKnopf({required this.text, this.compact = false, super.key});

  /// Was kopiert wird.
  final String text;

  /// Nur das Zeichen, ohne Wort — für die Zeile im Eingang der Grube.
  final bool compact;

  @override
  State<TeilenKnopf> createState() => _TeilenKnopfState();
}

class _TeilenKnopfState extends State<TeilenKnopf> {
  bool _kopiert = false;

  Future<void> _kopieren() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (mounted) setState(() => _kopiert = true);
  }

  @override
  Widget build(BuildContext context) {
    final zeichen = Icon(
      _kopiert ? Icons.check_rounded : Icons.ios_share_rounded,
      size: 20,
      semanticLabel: widget.compact
          ? (_kopiert ? 'Kopiert' : 'Ergebnis teilen')
          : null,
    );
    if (widget.compact) {
      return FilledButton(
        onPressed: _kopieren,
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: zeichen,
      );
    }
    return FilledButton.icon(
      onPressed: _kopieren,
      icon: zeichen,
      label: Text(_kopiert ? 'Kopiert' : 'Teilen'),
    );
  }
}
