import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../gear/gear_controller.dart';
import '../gear/widgets/character_figure.dart';
import 'holz.dart';
import 'palette.dart';

/// **Die Tipps des Ladebildschirms — eine Tabelle** (Issue #135).
///
/// Die Ausnahme von ADR-0060: Beim Laden wartet man ohnehin, und ein Satz
/// stört dort nichts. **Dieselben Sätze stehen in `web/index.html`**, für
/// den Start der Web-Fassung, bevor Flutter läuft;
/// `test/ladebildschirm_test.dart` prüft, dass beide gleich sind.
abstract final class LadeTipps {
  static const List<String> alle = <String>[
    'Jedes Häkchen heute macht dich heute stärker. Alles erledigt heißt '
        '„In Form“.',
    'Der Boss kündigt jeden Angriff an. Lauf aus dem Ring, bevor er sich '
        'füllt.',
    'Kurz tippen zielt von selbst, halten zielt von Hand.',
    'Zeitkugeln füllen die Uhr im Dungeon wieder auf.',
    'Nur ein Sieg behält die Beute. Wer verliert, verliert, was er '
        'eingesammelt hat.',
    'Schlüssel gibt es für Häkchen, Seiten und Rückfragen. Nach einem Sieg '
        'öffnet einer eine Extra-Truhe.',
    'Körper stärkt den Angriff, Geist das Mana, Wissenschaft die Abwehr, '
        'Gesellschaft das Leben.',
    'Ein verpasster Tag lässt die Kette eine Stufe fallen, nicht auf null.',
    'Streak-Eis deckt einen verpassten Tag. Manchmal steckt es in der '
        'Tagestruhe.',
    'Jedes Level bringt einen Talentpunkt für den Talentbaum.',
    'Ein Kreischpilz weckt den ganzen Raum. Fäll ihn zuerst.',
    'Der Sporenpilz heilt die anderen Gegner. Fäll ihn zuerst.',
    'Gegner bemerken dich nur, wenn sie dich sehen — oder wenn du sie '
        'triffst.',
    'Gesperrte Stücke im Rucksack werden nie verkauft.',
  ];

  static String zufaellig([math.Random? wuerfel]) =>
      alle[(wuerfel ?? math.Random()).nextInt(alle.length)];
}

/// **Der Ladebildschirm**: die eigene Figur läuft über einen Boden, der
/// unter ihr wegzieht, darunter der Balken und ein Tipp (Issue #135).
///
/// Er zeigt nur an — was geladen wird und wie weit, sagt [stand]
/// (`oeffneGeladen`, `lib/ui/spaeter_laden.dart`).
class Ladebildschirm extends ConsumerWidget {
  const Ladebildschirm({required this.stand, required this.tipp, super.key});

  /// Von 0 bis 1.
  final ValueListenable<double> stand;
  final String tipp;

  /// Ob die Figur läuft — in Tests still, sonst käme `pumpAndSettle` nie
  /// zur Ruhe (`test/flutter_test_config.dart`).
  static bool laeuft = true;

  static const double figurGroesse = 168;
  static const double balkenBreite = 240;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadout = ref.watch(loadoutProvider);
    final worn = <String>[
      for (final slot in GearSlot.values) ?loadout.equippedCopyIn(slot)?.itemId,
    ];

    return PopScope(
      // Zurück während des Ladens ginge ins Leere: Danach ersetzt der
      // geladene Bildschirm diesen hier.
      canPop: false,
      child: Scaffold(
        backgroundColor: Palette.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  RepaintBoundary(child: _Laeufer(worn: worn)),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: balkenBreite,
                    child: ValueListenableBuilder<double>(
                      valueListenable: stand,
                      builder: (context, wert, _) =>
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(end: wert),
                            duration: const Duration(milliseconds: 250),
                            builder: (context, v, _) => HolzBalken(
                              value: v,
                              color: Palette.goldOnDark,
                              zoom: 2,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      tipp,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Palette.textOnDarkDim,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Die Figur im Laufschritt über dem ziehenden Boden.
class _Laeufer extends StatefulWidget {
  const _Laeufer({required this.worn});

  final List<String> worn;

  @override
  State<_Laeufer> createState() => _LaeuferState();
}

class _LaeuferState extends State<_Laeufer>
    with SingleTickerProviderStateMixin {
  /// Ein Takt sind zwei Schritte.
  late final AnimationController _takt;

  @override
  void initState() {
    super.initState();
    _takt = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (Ladebildschirm.laeuft) _takt.repeat();
  }

  @override
  void dispose() {
    _takt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const groesse = Ladebildschirm.figurGroesse;
    final figur = CharacterFigure(worn: widget.worn);

    return SizedBox(
      width: Ladebildschirm.balkenBreite,
      height: groesse + 10,
      child: AnimatedBuilder(
        animation: _takt,
        builder: (context, _) {
          final t = _takt.value;
          // Zwei Schritte je Takt: hoch, wenn ein Fuß abstößt.
          final schritt = math.sin(t * 2 * math.pi * 2).abs();
          final neigung = math.sin(t * 2 * math.pi) * 0.035;
          return Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 18,
                child: CustomPaint(painter: _BodenMaler(t)),
              ),
              Positioned(
                bottom: 12 + schritt * 6,
                child: Transform.rotate(
                  angle: neigung,
                  alignment: Alignment.bottomCenter,
                  child: SizedBox.square(dimension: groesse, child: figur),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Steine, die nach links wegziehen — an beiden Enden ins Dunkel
/// verblassend.
class _BodenMaler extends CustomPainter {
  const _BodenMaler(this.t);

  final double t;

  static const double stein = 24;
  static const double pixel = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final versatz = t * stein * 2;
    final hell = Paint()..color = Palette.backgroundRaised;
    final fuge = Paint()..color = const Color(0xFF0B0805);
    final glanz = Paint()..color = const Color(0xFF3A2A17);
    for (var i = -1; i * stein < size.width + stein; i++) {
      final x = i * stein - versatz % stein;
      final rect = Rect.fromLTWH(x, 0, stein - pixel, size.height);
      canvas.drawRect(rect, hell);
      canvas.drawRect(Rect.fromLTWH(x, 0, stein - pixel, pixel), glanz);
      canvas.drawRect(
        Rect.fromLTWH(x + stein - pixel, 0, pixel, size.height),
        fuge,
      );
    }
    // Rechts und links ins Leder verblassen, damit der Boden nicht wie
    // ein abgeschnittener Streifen aussieht.
    final rand = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          Palette.background,
          Color(0x0017110A),
          Color(0x0017110A),
          Palette.background,
        ],
        stops: <double>[0, 0.25, 0.75, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, rand);
  }

  @override
  bool shouldRepaint(_BodenMaler alt) => alt.t != t;
}
