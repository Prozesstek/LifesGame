import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show HitTestTarget;
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
///
/// **Sie weicht aus** (12.11.2026): Oben rechts liegen in vielen
/// Titelzeilen Knöpfe — Sammlung, Gold, Talentpunkte. Ein paar Mal je
/// Sekunde fragt die Hülle, was unter der Blase läge ([BlasenPlatz]),
/// und rückt sie nach links, dann eine Reihe tiefer, bis nichts darunter
/// liegt. Was keinen Tipp annimmt (`IgnorePointer`), sieht sie nicht.
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

  /// Wie oft nachgesehen wird, ob die Blase etwas verdeckt.
  static const Duration nachsehen = Duration(milliseconds: 400);

  @override
  ConsumerState<FeedbackHuelle> createState() => _FeedbackHuelleState();
}

class _FeedbackHuelleState extends ConsumerState<FeedbackHuelle> {
  final GlobalKey _flaeche = GlobalKey();
  late final FeedbackDienst _dienst = widget.dienst ?? DiscordFeedbackDienst();
  bool _offen = false;
  Offset _platz = Offset.zero; // von rechts oben, in Punkten
  Timer? _takt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _rueckeAus());
    _takt = Timer.periodic(FeedbackHuelle.nachsehen, (_) => _rueckeAus());
  }

  @override
  void dispose() {
    _takt?.cancel();
    super.dispose();
  }

  /// Sucht den ersten Platz, an dem die Blase nichts verdeckt.
  void _rueckeAus() {
    if (!mounted || _offen) return;
    final grenze = _flaeche.currentContext?.findRenderObject();
    if (grenze is! RenderBox || !grenze.hasSize) return;
    final oben = MediaQuery.paddingOf(context).top;
    final neu = BlasenPlatz.waehle(
      breite: grenze.size.width,
      oben: oben,
      belegt: (rect) => BlasenPlatz.liegtEtwasUnter(grenze, rect),
    );
    if (neu != _platz) setState(() => _platz = neu);
  }

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
            top: oben + BlasenPlatz.rand + _platz.dy,
            right: BlasenPlatz.rand + _platz.dx,
            child: _Blase(onTap: _oeffnen),
          ),
      ],
    );
  }
}

/// **Wohin die Blase rückt**, wenn oben rechts etwas liegt — reine
/// Rechnung, damit sie sich ohne Bildschirm prüfen lässt.
abstract final class BlasenPlatz {
  /// Kantenlänge der Blase.
  static const double seite = 32;

  /// Abstand zum Rand des Bildschirms.
  static const double rand = 1;

  /// Schritt zum nächsten Platz, nach links und nach unten.
  static const double schritt = 40;

  /// Wie viele Plätze je Reihe, in wie vielen Reihen.
  static const int jeReihe = 5;
  static const int reihen = 2;

  /// Was größer ist, gilt als Hintergrund, nicht als Knopf: ein Holzrahmen
  /// über die ganze Breite, ein Bild hinter allem, eine Fläche, die jeden
  /// Tipp nimmt.
  static const double groesster = 160;

  /// Der erste freie Platz, als Versatz von rechts oben. Ist keiner frei,
  /// bleibt sie in der Ecke.
  static Offset waehle({
    required double breite,
    required double oben,
    required bool Function(Rect) belegt,
  }) {
    for (var r = 0; r < reihen; r++) {
      for (var i = 0; i < jeReihe; i++) {
        final versatz = Offset(i * schritt, r * schritt);
        final rechts = breite - rand - versatz.dx;
        final rect = Rect.fromLTWH(
          rechts - seite,
          oben + rand + versatz.dy,
          seite,
          seite,
        );
        if (rect.left < breite / 2) break;
        if (!belegt(rect)) return versatz;
      }
    }
    return Offset.zero;
  }

  /// Ob unter [rect] etwas liegt, das man sehen oder antippen will: Text,
  /// ein Zeichen, ein Bild oder ein Knopf. Gefragt wird an neun Punkten.
  static bool liegtEtwasUnter(RenderBox wurzel, Rect rect) {
    for (final fx in const <double>[0.1, 0.5, 0.9]) {
      for (final fy in const <double>[0.1, 0.5, 0.9]) {
        final punkt = Offset(
          rect.left + rect.width * fx,
          rect.top + rect.height * fy,
        );
        final ergebnis = BoxHitTestResult();
        wurzel.hitTest(ergebnis, position: punkt);
        for (final eintrag in ergebnis.path) {
          if (zaehlt(eintrag.target)) return true;
        }
      }
    }
    return false;
  }

  /// Was die Blase nicht verdecken soll.
  static bool zaehlt(HitTestTarget ziel) {
    if (ziel is RenderParagraph) return true;
    if (ziel is! RenderBox || !ziel.hasSize) return false;
    final klein = ziel.size.width <= groesster && ziel.size.height <= groesster;
    if (!klein) return false;
    return ziel is RenderImage ||
        ziel is RenderCustomPaint ||
        ziel is RenderPointerListener ||
        ziel is RenderDecoratedBox;
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
              // **Golden und mit Schatten** (11.11.2026): dunkel auf dem
              // dunklen Holzrahmen hat sie am Handy niemand gesehen.
              width: BlasenPlatz.seite,
              height: BlasenPlatz.seite,
              decoration: BoxDecoration(
                color: Palette.goldOnDark,
                shape: BoxShape.circle,
                border: Border.all(color: Palette.background, width: 2),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble,
                size: 17,
                color: Palette.background,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
