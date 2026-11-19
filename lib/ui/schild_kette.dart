import 'package:flutter/material.dart';

/// **Zwei Ketten zwischen gekoppelten Gewohnheiten** (19.11.2026,
/// Frederik): Die Karten hängen aneinander wie zwei Schilder — links und
/// rechts je eine Messingkette, 15 % der Breite vom Rand, von einer Öse
/// an der Unterkante der oberen Karte zu einer Öse an der Oberkante der
/// unteren.
///
/// **Die Kette besteht aus Gliedern**, abwechselnd von der Seite und von
/// vorn ([glieder], immer ungerade): Beide Enden stehen seitlich, schmal
/// genug, um durch das Loch der Öse zu greifen, ohne ihren Ring zu
/// verdecken. Das oberste und das unterste Glied reichen über die
/// Mitte der Öse hinaus, und der vordere Rand der Öse liegt darüber
/// (`eyelet_lip.png`) — so greift das Glied sichtbar hindurch.
///
/// **Gemalt wird in dieser Reihenfolge:** Rahmen (das Kind), Öse, Kette
/// mit Schatten, Rand der Öse. Die Kette gehört zur **unteren** Karte und
/// ragt nach oben bis in die Öse der oberen; weil die untere in der Liste
/// später kommt, liegt sie über beiden.
///
/// **Die Länge folgt aus den Gliedern** ([laenge]), die Lücke zwischen
/// den Karten aus Länge und Lage der Ösen ([lueckeFuer]) — jeder
/// Bildschirm rechnet sie damit, statt sie zu schätzen. Quer rechnet sich
/// alles aus der Breite: links [vomRand], rechts genauso weit vom
/// rechten Rand.
///
/// **Die Bilder** liegen in `assets/UI/Kette/`. Wer sie ersetzt, behält
/// die Größen in Bildpunkten ([vornBreite], [seitBreite], [gliedHoehe],
/// [oeseSeite]) oder trägt die neuen hier ein.
class SchildKette extends StatelessWidget {
  const SchildKette({
    required this.child,
    required this.oseOben,
    required this.oseUnten,
    this.glieder = 3,
    this.haengtOben = false,
    this.traegtUnten = false,
    this.ausgegraut = false,
    super.key,
  }) : assert(glieder % 2 == 1, 'beide Enden greifen seitlich durch die Öse');

  static const String _ordner = 'assets/UI/Kette';
  static const String vornPfad = '$_ordner/chain_link_front.png';
  static const String seitPfad = '$_ordner/chain_link_side.png';
  static const String oesePfad = '$_ordner/eyelet.png';
  static const String randPfad = '$_ordner/eyelet_lip.png';

  /// Die Bilder in Bildpunkten.
  static const int vornBreite = 6;
  static const int seitBreite = 4;
  static const int gliedHoehe = 10;
  static const int oeseSeite = 10;

  /// Wie weit ein Glied unter das nächste reicht, in Bildpunkten: Jedes
  /// beginnt [schritt] tiefer als das vorige.
  static const int schritt = 7;

  /// Wie weit das Endglied über die Mitte der Öse hinausreicht, in
  /// Bildpunkten — bis unter ihren vorderen Rand.
  static const int ueberstand = 4;

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

  /// Wie viele Glieder eine Kette hat.
  final int glieder;

  /// Ob diese Karte an der darüber hängt — dann Ösen oben und die Kette.
  final bool haengtOben;

  /// Ob an dieser Karte eine darunter hängt — dann Ösen unten.
  final bool traegtUnten;

  /// Erledigt: Die Kette wird blasser.
  final bool ausgegraut;

  static double _px(int bildpunkte) => (bildpunkte * faktor).toDouble();

  /// Von Ösenmitte zu Ösenmitte, wenn eine Kette [glieder] Glieder hat.
  static double laenge(int glieder) =>
      _px((glieder - 1) * schritt + gliedHoehe - 2 * ueberstand);

  /// Die Lücke zwischen zwei Karten, damit die Kette genau passt.
  static double lueckeFuer({
    required int glieder,
    required double oseOben,
    required double oseUnten,
  }) {
    final luecke = laenge(glieder) - oseOben - oseUnten;
    assert(luecke >= 0, 'die Kette ist kürzer als der Weg zwischen den Ösen');
    return luecke;
  }

  /// Wo die Mitte der linken und rechten Kette liegt: gleich weit von
  /// beiden Rändern, auf ganze Punkte gerundet.
  static List<double> mitten(double breite) {
    final links = (breite * vomRand).roundToDouble();
    return <double>[links, breite - links];
  }

  @override
  Widget build(BuildContext context) {
    final l = laenge(glieder);
    final oese = _px(oeseSeite);
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
                  left: x - oese / 2,
                  bottom: oseUnten - oese / 2,
                  child: const _Bild(oesePfad, oeseSeite, oeseSeite),
                ),
              if (haengtOben) ...<Widget>[
                Positioned(
                  key: oeseObenKey(seite),
                  left: x - oese / 2,
                  top: oseOben - oese / 2,
                  child: const _Bild(oesePfad, oeseSeite, oeseSeite),
                ),
                Positioned(
                  key: ketteKey(seite),
                  left: x - _px(vornBreite) / 2,
                  top: oseOben - l - _px(ueberstand),
                  child: _Kette(glieder: glieder, ausgegraut: ausgegraut),
                ),
                // Der vordere Rand beider Ösen über den Endgliedern: oben
                // der der Karte darüber, unten der eigene, gespiegelt.
                Positioned(
                  left: x - oese / 2,
                  top: oseOben - l - oese / 2,
                  child: _blass(const _Bild(randPfad, oeseSeite, oeseSeite)),
                ),
                Positioned(
                  left: x - oese / 2,
                  top: oseOben - oese / 2,
                  child: _blass(
                    Transform.flip(
                      flipY: true,
                      child: const _Bild(randPfad, oeseSeite, oeseSeite),
                    ),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _blass(Widget bild) =>
      Opacity(opacity: ausgegraut ? _Kette.blass : 1, child: bild);
}

/// Ein Bild der Kette in fester Größe, ganzzahlig vergrößert, ohne
/// Glättung. Die feste Größe gilt schon, bevor es geladen ist — sonst
/// säße eine Öse kurz neben ihrer Kette.
class _Bild extends StatelessWidget {
  const _Bild(this.pfad, this.breite, this.hoehe, {this.farbe});

  final String pfad;
  final int breite;
  final int hoehe;
  final Color? farbe;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: SchildKette._px(breite),
        height: SchildKette._px(hoehe),
        child: Image.asset(
          pfad,
          scale: 1 / SchildKette.faktor,
          filterQuality: FilterQuality.none,
          color: farbe,
          colorBlendMode: farbe == null ? null : BlendMode.srcIn,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}

/// Die Glieder untereinander, abwechselnd von vorn und von der Seite, mit
/// einem kleinen Schatten aufs Holz oder Papier.
class _Kette extends StatelessWidget {
  const _Kette({required this.glieder, required this.ausgegraut});

  final int glieder;
  final bool ausgegraut;

  /// Wie blass eine Kette zwischen erledigten Karten ist.
  static const double blass = 0.55;

  /// Wohin der Schatten fällt: Licht von oben links (ADR-0099).
  static const Offset schatten = Offset(2, 2);
  static const Color schattenFarbe = Color(0x4D000000);

  List<Widget> _glieder({Color? farbe}) {
    final breit = SchildKette._px(SchildKette.vornBreite);
    final schmal = SchildKette._px(SchildKette.seitBreite);
    Widget glied(int i) {
      final vorn = i.isOdd;
      return Positioned(
        left: vorn ? 0 : (breit - schmal) / 2,
        top: SchildKette._px(i * SchildKette.schritt),
        child: _Bild(
          vorn ? SchildKette.vornPfad : SchildKette.seitPfad,
          vorn ? SchildKette.vornBreite : SchildKette.seitBreite,
          SchildKette.gliedHoehe,
          farbe: farbe,
        ),
      );
    }

    // Die seitlichen zuerst: Sie laufen hinter den Bögen der vorderen.
    return <Widget>[
      for (var i = 0; i < glieder; i += 2) glied(i),
      for (var i = 1; i < glieder; i += 2) glied(i),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hoehe = SchildKette._px(
      (glieder - 1) * SchildKette.schritt + SchildKette.gliedHoehe,
    );
    return IgnorePointer(
      child: Opacity(
        opacity: ausgegraut ? blass : 1,
        child: SizedBox(
          width: SchildKette._px(SchildKette.vornBreite),
          height: hoehe,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Transform.translate(
                offset: schatten,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: _glieder(farbe: schattenFarbe),
                ),
              ),
              ..._glieder(),
            ],
          ),
        ),
      ),
    );
  }
}
