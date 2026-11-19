import 'package:flutter/material.dart';

/// **Zwei Ketten zwischen gekoppelten Gewohnheiten** (19.11.2026,
/// Frederik): Die Karten hängen aneinander wie zwei Schilder — links und
/// rechts je eine Kette, 15 % der Breite vom Rand, von einer Öse an der
/// Unterkante der oberen Karte zu einer Öse an der Oberkante der unteren.
///
/// **Gemalt wird in dieser Reihenfolge:** Rahmen (das Kind), Öse, Kette.
/// Die Kette gehört zur **unteren** Karte und ragt nach oben bis in die
/// Öse der oberen; weil die untere in der Liste später kommt, liegt sie
/// über beiden Rahmen.
///
/// **Die Länge ist gerechnet, nicht geschätzt**: von der eigenen oberen
/// Öse ([oseOben]) über die Lücke ([luecke]) bis zur unteren Öse der
/// Karte darüber ([oseUnten]). Das gilt, solange alle Karten einer Liste
/// dieselben drei Zahlen nehmen — jeder Bildschirm hat sie als
/// Konstanten. Die Lage quer rechnet sich aus der Breite, nicht aus dem
/// Gerät.
///
/// **Platzhalter:** `assets/UI/Kette/chain_segment.png` und
/// `assets/UI/Kette/eyelet.png` sind dunkelgraue Entwürfe. Wer sie
/// ersetzt, behält die Größen in Bildpunkten ([gliedBreite],
/// [gliedHoehe], [oeseSeite]) oder trägt die neuen hier ein.
class SchildKette extends StatelessWidget {
  const SchildKette({
    required this.child,
    required this.oseOben,
    required this.oseUnten,
    required this.luecke,
    this.haengtOben = false,
    this.traegtUnten = false,
    this.ausgegraut = false,
    super.key,
  });

  static const String gliedPfad = 'assets/UI/Kette/chain_segment.png';
  static const String oesePfad = 'assets/UI/Kette/eyelet.png';

  /// Die Bilder in Bildpunkten — ein Stück Kette kachelt senkrecht.
  static const int gliedBreite = 4;
  static const int gliedHoehe = 8;
  static const int oeseSeite = 6;

  /// Ganzzahlig vergrößert, damit jeder Bildpunkt gleich groß bleibt.
  static const int faktor = 2;

  /// Wie weit eine Kette vom Rand hängt, als Anteil der Breite.
  static const double vomRand = 0.15;

  /// Woran Tests die Ketten und Ösen finden — `seite` 0 links, 1 rechts.
  static Key ketteKey(int seite) => ValueKey<String>('schild-kette-$seite');
  static Key oeseObenKey(int seite) =>
      ValueKey<String>('schild-oese-oben-$seite');
  static Key oeseUntenKey(int seite) =>
      ValueKey<String>('schild-oese-unten-$seite');

  final Widget child;

  /// Abstand der oberen Öse (ihre Mitte) von der Oberkante der Karte.
  final double oseOben;

  /// Abstand der unteren Öse (ihre Mitte) von der Unterkante der Karte.
  final double oseUnten;

  /// Die Lücke zur Karte darüber, wenn sie gekoppelt ist.
  final double luecke;

  /// Ob diese Karte an der darüber hängt — dann Ösen oben und die Kette.
  final bool haengtOben;

  /// Ob an dieser Karte eine darunter hängt — dann Ösen unten.
  final bool traegtUnten;

  /// Erledigt: Die Kette wird blasser.
  final bool ausgegraut;

  /// Wie lang eine Kette ist: von Öse zu Öse.
  double get laenge => oseOben + luecke + oseUnten;

  static double get _oese => (oeseSeite * faktor).toDouble();
  static double get _glied => (gliedBreite * faktor).toDouble();

  /// Wo die Mitte der linken und rechten Kette liegt, auf ganze Punkte
  /// gerundet — sonst läge die Öse zwischen zwei Bildpunkten.
  static List<double> mitten(double breite) => <double>[
    (breite * vomRand).roundToDouble(),
    (breite * (1 - vomRand)).roundToDouble(),
  ];

  @override
  Widget build(BuildContext context) {
    // **Die Hülle steht immer** (`gotchas.md`): Wechselt die Kopplung
    // beim Abhaken, baute sich die Karte sonst neu, und der Sprung des
    // Häkchens ginge verloren.
    return LayoutBuilder(
      builder: (context, platz) {
        final xs = mitten(platz.maxWidth);
        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.passthrough,
          children: <Widget>[
            child,
            for (final (seite, x) in xs.indexed) ...<Widget>[
              if (traegtUnten)
                Positioned(
                  key: oeseUntenKey(seite),
                  left: x - _oese / 2,
                  bottom: oseUnten - _oese / 2,
                  child: const _Oese(),
                ),
              if (haengtOben) ...<Widget>[
                Positioned(
                  key: oeseObenKey(seite),
                  left: x - _oese / 2,
                  top: oseOben - _oese / 2,
                  child: const _Oese(),
                ),
                Positioned(
                  key: ketteKey(seite),
                  left: x - _glied / 2,
                  top: oseOben - laenge,
                  child: _Kette(laenge: laenge, ausgegraut: ausgegraut),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _Oese extends StatelessWidget {
  const _Oese();

  @override
  Widget build(BuildContext context) {
    // Feste Fläche: Bis das Bild geladen ist, säße die Öse sonst bei
    // 0 × 0 und neben ihrer Kette.
    return IgnorePointer(
      child: SizedBox.square(
        dimension: SchildKette._oese,
        child: Image.asset(
          SchildKette.oesePfad,
          scale: 1 / SchildKette.faktor,
          filterQuality: FilterQuality.none,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}

/// Die Kette, gekachelt, mit einem kleinen Schatten aufs Holz.
class _Kette extends StatelessWidget {
  const _Kette({required this.laenge, required this.ausgegraut});

  final double laenge;
  final bool ausgegraut;

  /// Wohin der Schatten fällt: Licht von oben links (ADR-0099).
  static const Offset schatten = Offset(1, 2);

  Widget _bild({Color? farbe}) {
    return SizedBox(
      width: SchildKette._glied,
      height: laenge,
      child: Image.asset(
        SchildKette.gliedPfad,
        scale: 1 / SchildKette.faktor,
        repeat: ImageRepeat.repeatY,
        alignment: Alignment.topCenter,
        fit: BoxFit.none,
        filterQuality: FilterQuality.none,
        color: farbe,
        colorBlendMode: farbe == null ? null : BlendMode.srcIn,
        excludeFromSemantics: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: ausgegraut ? 0.5 : 1,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Transform.translate(
              offset: schatten,
              child: _bild(farbe: const Color(0x59000000)),
            ),
            _bild(),
          ],
        ),
      ),
    );
  }
}
