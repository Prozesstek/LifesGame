import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../character/identity_controller.dart';
import '../progression/level_provider.dart';
import '../ui/druck.dart';
import '../ui/palette.dart';
import 'feedback_blatt.dart';
import 'feedback_dienst.dart';

/// **Feedback von jedem Screen aus** (11.11.2026, für die Testphase):
/// eine kleine Sprechblase schwebt oben rechts über der ganzen App. Ein
/// Tipp nimmt zuerst ein Bild des Screens auf, dann öffnet sich das
/// Blatt ([FeedbackBlatt]).
///
/// Liegt im `builder` von `MaterialApp` um den Navigator. Die Blase
/// selbst steht **außerhalb** der aufgenommenen Fläche und ist deshalb
/// nie auf dem Bild.
class FeedbackHuelle extends ConsumerStatefulWidget {
  const FeedbackHuelle({
    required this.navigatorKey,
    required this.messengerKey,
    required this.child,
    this.dienst,
    super.key,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  /// Für Tests; sonst der Discord-Webhook.
  final FeedbackDienst? dienst;

  /// Damit Tests die Blase finden.
  static const Key knopfKey = ValueKey<String>('feedback-knopf');

  /// Wie breit der Screenshot höchstens wird, in echten Bildpunkten —
  /// klein genug für einen schnellen Upload, groß genug zum Lesen.
  static const double bildBreite = 540;

  @override
  ConsumerState<FeedbackHuelle> createState() => _FeedbackHuelleState();
}

class _FeedbackHuelleState extends ConsumerState<FeedbackHuelle> {
  final GlobalKey _flaeche = GlobalKey();
  late final FeedbackDienst _dienst = widget.dienst ?? DiscordFeedbackDienst();
  bool _offen = false;

  Future<Uint8List?> _aufnehmen() async {
    final grenze = _flaeche.currentContext?.findRenderObject();
    if (grenze is! RenderRepaintBoundary) return null;
    try {
      final breite = grenze.size.width;
      if (breite <= 0) return null;
      final dichte = MediaQuery.devicePixelRatioOf(context);
      final faktor = math.min(dichte, FeedbackHuelle.bildBreite / breite);
      final bild = await grenze.toImage(pixelRatio: faktor);
      final daten = await bild.toByteData(format: ui.ImageByteFormat.png);
      bild.dispose();
      return daten?.buffer.asUint8List();
    } on Exception {
      return null;
    }
  }

  /// Der Name des Screens, der gerade oben liegt — der letzte
  /// `…Screen` im Baum unter dem Navigator, denn die oberste Route wird
  /// zuletzt gebaut.
  String? _screenName() {
    final wurzel = widget.navigatorKey.currentContext;
    if (wurzel == null) return null;
    String? zuletzt;
    void besuche(Element e) {
      final name = e.widget.runtimeType.toString();
      if (name.endsWith('Screen') && !name.startsWith('_')) zuletzt = name;
      e.visitChildElements(besuche);
    }

    (wurzel as Element).visitChildElements(besuche);
    return zuletzt;
  }

  Future<void> _oeffnen() async {
    if (_offen) return;
    final screenshot = await _aufnehmen();
    final screen = _screenName();
    // Erst nach dem Bild nach dem Navigator fragen — derselbe Kontext,
    // aus dem das Blatt dann aufgeht.
    final navContext = widget.navigatorKey.currentContext;
    if (!mounted || navContext == null || !navContext.mounted) return;
    final identity = ref.read(identityProvider);
    final level = ref.read(playerLevelProvider).level;
    setState(() => _offen = true);
    final gesendet = await zeigeFeedbackBlatt(
      navContext,
      dienst: _dienst,
      screenshot: screenshot,
      screen: screen,
      spieler: identity.hasName ? identity.name : null,
      level: level,
    );
    if (!mounted) return;
    setState(() => _offen = false);
    if (gesendet == true) {
      widget.messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Danke, ist angekommen 🙌'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final oben = MediaQuery.paddingOf(context).top;
    return Stack(
      children: <Widget>[
        RepaintBoundary(key: _flaeche, child: widget.child),
        if (!_offen)
          Positioned(
            top: oben + 2,
            right: 2,
            child: _Blase(onTap: _oeffnen),
          ),
      ],
    );
  }
}

/// Die Sprechblase: klein, rund, dunkel mit goldenem Rand.
class _Blase extends StatelessWidget {
  const _Blase({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Feedback senden',
      child: Druck(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: FeedbackHuelle.knopfKey,
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Palette.background.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(color: Palette.goldOnDark, width: 1.5),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: Palette.goldOnDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
