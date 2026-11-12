import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';

import '../../gear/widgets/rarity_badge.dart';
import '../../ui/gold_icon.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';
import '../../ui/pulsieren.dart';
import 'daily_chest_card.dart';

/// Welche Seltenheit eine Stufe der Tagestruhe trägt — **eine Tabelle**,
/// die Farben stehen in `RarityBadge`. Die Namen trägt die Stufe selbst
/// (`ChestTier.label`).
abstract final class TruhenSeltenheit {
  static GearRarity von(ChestTier stufe) => switch (stufe) {
    ChestTier.schlicht => GearRarity.common,
    ChestTier.gut => GearRarity.rare,
    ChestTier.eis => GearRarity.epic,
    ChestTier.schatz => GearRarity.legendary,
  };

  /// Die helle Farbe auf dunklem Grund — der Rahmenton der Seltenheit.
  static Color farbe(ChestTier stufe) => RarityBadge.rahmenOf(von(stufe));
}

/// **Die Tagestruhe kommt von selbst** (11.11.2026, Frederik: „mit
/// Seltenheit wie bei Duolingo oder Clash Royale durch Tippen“).
///
/// Groß in der Mitte, auf dunklem Schleier. **Drei Tipps**: Bei jedem
/// wackelt sie, leuchtet stärker und klingt einen Ton höher; beim dritten
/// springt sie auf — erst jetzt in der Farbe ihrer Seltenheit, mit
/// Strahlen und Funken. Dann zählt das Gold hoch, und das Eis springt
/// heraus. Die Seltenheit sieht man vorher nicht.
///
/// **Kennt keine Provider**: Wer sie zeigt, bucht in [onAuf] und spielt
/// in [onTipp] den Klang (`zeigeTagestruhe`). Wer sie mit dem Kreuz
/// schließt, hat sie nicht geöffnet — sie wartet am Lagerfeuer.
///
/// **Läuft einmal und hält an** — außer dem Pulsieren vor dem ersten Tipp,
/// das in Tests still ist (`Pulsieren.pulsiert`).
class TruheOeffnen extends StatefulWidget {
  const TruheOeffnen({
    required this.inhalt,
    required this.onTipp,
    required this.onAuf,
    required this.onFertig,
    super.key,
  });

  final ChestContent inhalt;

  /// Der wievielte Tipp, 1 bis [tipps].
  final void Function(int nr) onTipp;

  /// Der letzte Tipp: Jetzt ist sie offen.
  final VoidCallback onAuf;

  /// Eingesackt oder später — der Dialog geht zu.
  final VoidCallback onFertig;

  /// So oft wird getippt, bis sie aufgeht.
  static const int tipps = 3;

  /// Wie lange sie nach dem letzten Tipp aufgeht.
  static const Duration aufgehen = Duration(milliseconds: 1800);

  /// Woran Tests sie finden.
  static const Key truheKey = ValueKey<String>('tagestruhe-tippen');
  static const Key spaeterKey = ValueKey<String>('tagestruhe-spaeter');
  static const Key stufeKey = ValueKey<String>('tagestruhe-stufe');

  @override
  State<TruheOeffnen> createState() => _TruheOeffnenState();
}

class _TruheOeffnenState extends State<TruheOeffnen>
    with TickerProviderStateMixin {
  // In `initState`, nicht faul (`gotchas.md`).
  late final AnimationController _wackel;
  late final AnimationController _auf;
  int _getippt = 0;

  bool get _offen => _getippt >= TruheOeffnen.tipps;

  @override
  void initState() {
    super.initState();
    _wackel = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _auf = AnimationController(vsync: this, duration: TruheOeffnen.aufgehen);
  }

  @override
  void dispose() {
    _wackel.dispose();
    _auf.dispose();
    super.dispose();
  }

  void _tipp() {
    if (_offen) return;
    setState(() => _getippt++);
    widget.onTipp(_getippt);
    if (_offen) {
      widget.onAuf();
      _auf.forward();
    } else {
      _wackel.forward(from: 0);
    }
  }

  /// Wie weit [t] zwischen [von] und [bis] ist, 0 bis 1.
  static double _phase(double t, double von, double bis) =>
      ((t - von) / (bis - von)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final farbe = TruhenSeltenheit.farbe(widget.inhalt.tier);
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              key: TruheOeffnen.truheKey,
              behavior: HitTestBehavior.opaque,
              onTap: _tipp,
              child: Semantics(
                button: !_offen,
                label: _offen
                    ? 'Tagestruhe, ${widget.inhalt.tier.label}: '
                          '${chestSummary(widget.inhalt)}'
                    : 'Tagestruhe antippen, noch '
                          '${TruheOeffnen.tipps - _getippt} Mal',
                child: AnimatedBuilder(
                  animation: Listenable.merge(<Listenable>[_wackel, _auf]),
                  builder: (context, _) => _mitte(farbe),
                ),
              ),
            ),
          ),
          if (!_offen)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: IconButton(
                  key: TruheOeffnen.spaeterKey,
                  onPressed: widget.onFertig,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Palette.textOnDarkDim,
                    semanticLabel: 'Später am Feuer öffnen',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mitte(Color farbe) {
    final t = _auf.value;
    final platzen = _phase(t, 0, 0.18);
    final strahlen = Curves.easeOut.transform(_phase(t, 0.05, 0.5));
    final stufe = Curves.elasticOut.transform(_phase(t, 0.15, 0.6));
    final zaehlen = Curves.easeOut.transform(_phase(t, 0.3, 0.7));
    final eis = Curves.elasticOut.transform(_phase(t, 0.65, 0.95));
    final knopf = _phase(t, 0.85, 1);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 300,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: <Widget>[
                // Vorher: ein warmer Schein, der mit jedem Tipp wächst.
                if (!_offen || platzen < 1) _schein(1 - platzen),
                if (_offen)
                  CustomPaint(
                    size: const Size(300, 260),
                    painter: _Strahlen(farbe: farbe, t: strahlen),
                  ),
                if (platzen < 1) _truhe(platzen),
                if (_offen && stufe > 0)
                  Transform.scale(
                    scale: 0.4 + 0.6 * stufe,
                    child: _Beute(
                      inhalt: widget.inhalt,
                      zaehlen: zaehlen,
                      eis: eis,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 130,
            child: _offen
                ? Column(
                    children: <Widget>[
                      Opacity(
                        opacity: stufe.clamp(0.0, 1.0),
                        child: Text(
                          widget.inhalt.tier.label,
                          key: TruheOeffnen.stufeKey,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: farbe,
                            shadows: <Shadow>[
                              Shadow(
                                color: farbe.withValues(alpha: 0.6),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      IgnorePointer(
                        ignoring: knopf < 1,
                        child: Opacity(
                          opacity: knopf,
                          child: FilledButton(
                            key: DailyChestCard.einsackenKey,
                            onPressed: widget.onFertig,
                            child: const Icon(
                              Icons.check_rounded,
                              semanticLabel: 'Einsacken',
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : _Punkte(getippt: _getippt),
          ),
        ],
      ),
    );
  }

  Widget _schein(double deckkraft) {
    final groesse = 220.0 + 40 * _getippt;
    return Opacity(
      opacity: deckkraft,
      child: Container(
        width: groesse,
        height: groesse,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              Palette.goldOnDark.withValues(alpha: 0.25 + 0.15 * _getippt),
              Palette.goldOnDark.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

  /// Wackelt nach jedem Tipp, jedes Mal heftiger; beim Aufgehen wird sie
  /// groß und verschwindet im Licht.
  Widget _truhe(double platzen) {
    final w = _wackel.value;
    final heftig = 1 + 0.6 * _getippt;
    final winkel = math.sin(w * math.pi * 6) * 0.1 * heftig * (1 - w);
    final hopser = math.sin(w * math.pi) * 14 * heftig;
    final wachsen = 1 + 0.07 * _getippt + platzen * 0.5;
    return Opacity(
      opacity: 1 - platzen,
      child: Transform.translate(
        offset: Offset(0, -hopser),
        child: Transform.rotate(
          angle: winkel,
          child: Transform.scale(
            scale: wachsen,
            child: Pulsieren(
              aktiv: _getippt == 0,
              radius: 70,
              child: const PixelArt(
                assetPath: truhenBild,
                side: 140,
                fallback: Icon(
                  Icons.inventory_2,
                  color: Palette.goldOnDark,
                  size: 110,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Drei Punkte unter der Truhe: wie oft noch. Kein Satz (ADR-0060).
class _Punkte extends StatelessWidget {
  const _Punkte({required this.getippt});

  final int getippt;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var i = 0; i < TruheOeffnen.tipps; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < getippt
                    ? Palette.goldOnDark
                    : Palette.goldOnDark.withValues(alpha: 0.15),
                border: Border.all(color: Palette.goldOnDark, width: 2),
              ),
            ),
        ],
      ),
    );
  }
}

/// Das Gold zählt hoch, das Eis springt dazu.
class _Beute extends StatelessWidget {
  const _Beute({
    required this.inhalt,
    required this.zaehlen,
    required this.eis,
  });

  final ChestContent inhalt;
  final double zaehlen;
  final double eis;

  @override
  Widget build(BuildContext context) {
    const stil = TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w900,
      color: Palette.goldOnDark,
    );
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const GoldIcon(size: 44),
              const SizedBox(width: 8),
              Text('+${(inhalt.gold * zaehlen).round()}', style: stil),
            ],
          ),
          if (inhalt.freezes > 0 && eis > 0)
            Transform.scale(
              scale: eis,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.ac_unit,
                      size: 38,
                      color: Palette.manaOnDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${inhalt.freezes}',
                      style: stil.copyWith(color: Palette.manaOnDark),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Strahlen und Funken in der Farbe der Seltenheit. Sie gehen auf und
/// bleiben halb stehen — wie weit sie reichen, sagt nichts; die Farbe
/// sagt, wie selten.
class _Strahlen extends CustomPainter {
  const _Strahlen({required this.farbe, required this.t});

  final Color farbe;
  final double t;

  static const int _anzahl = 14;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final mitte = size.center(Offset.zero);
    final lang = size.shortestSide * 0.62 * t;
    final strahl = Paint()
      ..color = farbe.withValues(alpha: 0.5 * (1 - 0.4 * t))
      ..style = PaintingStyle.fill;
    final dreh = t * 0.6;
    for (var i = 0; i < _anzahl; i++) {
      final a = dreh + i * 2 * math.pi / _anzahl;
      final b = a + 0.09;
      final pfad = Path()
        ..moveTo(mitte.dx, mitte.dy)
        ..lineTo(mitte.dx + math.cos(a) * lang, mitte.dy + math.sin(a) * lang)
        ..lineTo(mitte.dx + math.cos(b) * lang, mitte.dy + math.sin(b) * lang)
        ..close();
      canvas.drawPath(pfad, strahl);
    }
    // Der Blitz in der Mitte.
    canvas.drawCircle(
      mitte,
      40 + 70 * t,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            farbe.withValues(alpha: 0.85 * (1 - 0.5 * t)),
            farbe.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: mitte, radius: 40 + 70 * t)),
    );
    // Funken, die nach außen fliegen und verglühen.
    final funke = Paint()..color = farbe.withValues(alpha: 1 - t);
    for (var i = 0; i < 18; i++) {
      final a = i * 2.39996;
      final weit = (50 + (i % 5) * 18) * (0.3 + t * 1.4);
      final p = mitte + Offset(math.cos(a), math.sin(a)) * weit;
      canvas.drawRect(Rect.fromCenter(center: p, width: 5, height: 5), funke);
    }
  }

  @override
  bool shouldRepaint(_Strahlen alt) => alt.t != t || alt.farbe != farbe;
}

/// Zeigt die Truhe über allem. Gebucht wird in [onAuf].
Future<void> showTruheOeffnen(
  BuildContext context, {
  required ChestContent inhalt,
  required void Function(int nr) onTipp,
  required VoidCallback onAuf,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Palette.scheinwerfer.withValues(alpha: 0.86),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, _, _) => TruheOeffnen(
      inhalt: inhalt,
      onTipp: onTipp,
      onAuf: onAuf,
      onFertig: () => Navigator.of(dialogContext).pop(),
    ),
    transitionBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
