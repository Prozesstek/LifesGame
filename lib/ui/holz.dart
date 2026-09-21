import 'package:flutter/material.dart';

import 'palette.dart';

/// Die gezeichneten Flächen aus dem UI-Paket: Planke, Rahmen, Balken,
/// Knopf.
///
/// **Eine Stelle für Pfade und Schnittkanten.** Jedes Teil ist ein
/// kleines Pixelbild, das per `centerSlice` gedehnt wird: Die Ecken bleiben
/// scharf, nur die Mitte wächst mit. Wo die Mitte liegt, steht hier als
/// Rechteck in Bildpunkten des Originals — wer ein Teil austauscht, misst
/// es neu und ändert genau diese Zahl.
///
/// Herkunft: `UIBundleFree` aus Frederiks Download, Stil „Mittelalter"
/// und „Fantasy" (Entscheidung vom 21.09.2026). Ausgeschnitten, nicht
/// gemalt — die Glyphen der Knöpfe und die rote Füllung des Balkens sind
/// entfernt, weil beides der Code zeichnet.
abstract final class Holz {
  static const String _ordner = 'assets/UI/Holz';

  static const String planke = '$_ordner/Planke.png';
  static const String rahmen = '$_ordner/Rahmen.png';
  static const String seil = '$_ordner/Seil.png';
  static const String balken = '$_ordner/Balken.png';
  static const String knopf = '$_ordner/Knopf.png';
  static const String knopfGedrueckt = '$_ordner/KnopfGedrueckt.png';

  /// Logische Punkte je Bildpunkt. **Ganzzahlig**, sonst werden die
  /// Pixel ungleich breit.
  static const double pixel = 2;

  /// Die Planke ist 45 × 23 groß; gedehnt wird nur zwischen den Enden.
  static const Rect plankeMitte = Rect.fromLTRB(4, 3, 41, 20);
  static const double plankeHoehe = 23 * pixel;

  /// Der Rahmen ist 71 × 67; die Ecken tragen Knäufe, 11 Bildpunkte groß.
  static const Rect rahmenMitte = Rect.fromLTRB(11, 11, 60, 57);

  /// Wie weit der Inhalt vom Außenrand des Rahmens wegbleibt.
  static const double rahmenRand = 12 * pixel;

  /// Derselbe Rand um eine Karte — der Rahmen in einfacher statt doppelter
  /// Größe. Doppelt wären es 24 Punkte Holz um jede Karte, und auf einem
  /// Handy mit sieben Karten untereinander bliebe für den Inhalt zu wenig.
  static const double kartenRand = 12;

  /// Die dunkle Kante zwischen Holz und Pergament — dieselbe wie beim
  /// hängenden Rahmen, damit beide aus einem Satz wirken.
  static const Color kante = Color(0xFF3A1F0C);

  /// Das Seil über dem Rahmen, 61 × 23.
  static const Size seilGroesse = Size(61 * pixel, 23 * pixel);

  /// Der Balken ist 61 × 12. Innen liegt eine Rinne, 6 Bildpunkte links
  /// und 4 rechts vom Rand, von Zeile 3 bis 8.
  static const Rect balkenMitte = Rect.fromLTRB(8, 1, 53, 11);
  static const double balkenBildHoehe = 12;
  static const double balkenRinneLinks = 6;
  static const double balkenRinneRechts = 4;
  static const double balkenRinneOben = 3;
  static const double balkenRinneHoehe = 6;

  /// Die beiden Enden zusammen, in Bildpunkten — darunter lässt sich der
  /// Balken nicht dehnen, sondern nur noch stauchen.
  static const double balkenMindestBreite = 61 - (53 - 8) + 1;

  /// Der Knopf ist 14 × 14, gezeichnet dreifach — so groß wie ein
  /// Symbolknopf in der Kopfzeile.
  static const double knopfSeite = 14 * 3;

  /// Ein Teil, per `centerSlice` gedehnt und [zoom]-fach vergrößert.
  ///
  /// **Zwei Fallstricke, beide mit einer Assertion statt einer Meldung:**
  /// `centerSlice` erwartet *logische* Punkte, nicht Bildpunkte — die
  /// Mitte wird deshalb hier mit dem Zoom multipliziert. Und Flutter
  /// vergleicht die gedehnte Größe auf exakte Gleichheit; ein Zoom wie
  /// 1,5 rechnet sich über `1 / 1,5` nicht glatt zurück und bricht ab.
  /// Deshalb nur ganze Zweierpotenzen.
  static DecorationImage _gedehnt(String pfad, Rect mitte, {int zoom = 2}) {
    assert(zoom == 1 || zoom == 2 || zoom == 4, 'nur 1, 2 oder 4');
    final z = zoom.toDouble();
    return DecorationImage(
      image: AssetImage(pfad),
      centerSlice: Rect.fromLTRB(
        mitte.left * z,
        mitte.top * z,
        mitte.right * z,
        mitte.bottom * z,
      ),
      scale: 1 / z,
      filterQuality: FilterQuality.none,
    );
  }

  /// Hintergrund eines Hauptknopfs — für `ButtonStyle.backgroundBuilder`.
  ///
  /// So bekommen **alle** `FilledButton`s die Planke über das Theme, statt
  /// dass jede der zwanzig Stellen einzeln umgebaut wird.
  static Widget buttonBackground(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) {
    final aus = states.contains(WidgetState.disabled);
    final gedrueckt = states.contains(WidgetState.pressed);

    Widget flaeche = DecoratedBox(
      decoration: BoxDecoration(image: _gedehnt(planke, plankeMitte)),
      child: child,
    );
    if (gedrueckt) {
      flaeche = ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Color(0x33000000),
          BlendMode.srcATop,
        ),
        child: flaeche,
      );
    }
    // Ausgegraut, nicht ausgeblendet: Ein gesperrter Knopf soll als Knopf
    // lesbar bleiben — er sagt, dass es hier etwas gibt, nur noch nicht.
    if (aus) flaeche = Opacity(opacity: 0.45, child: flaeche);
    return flaeche;
  }

  /// Der Stil aller Hauptknöpfe.
  static ButtonStyle buttonStyle() {
    return ButtonStyle(
      backgroundColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? Palette.textOnDarkDim
            : Palette.textOnDark,
      ),
      overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      elevation: const WidgetStatePropertyAll<double>(0),
      shape: const WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(),
      ),
      minimumSize: const WidgetStatePropertyAll<Size>(Size(88, plankeHoehe)),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: 20),
      ),
      textStyle: const WidgetStatePropertyAll<TextStyle>(
        TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          // Helle Schrift auf Holz braucht einen Rand, sonst verschwimmt
          // sie auf den helleren Maserungen.
          shadows: <Shadow>[
            Shadow(color: Color(0xCC1A0E05), offset: Offset(1, 1)),
          ],
        ),
      ),
      backgroundBuilder: buttonBackground,
    );
  }

  /// Hintergrund eines Symbolknopfs.
  static Widget iconButtonBackground(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) {
    final gedrueckt = states.contains(WidgetState.pressed);
    Widget flaeche = DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(gedrueckt ? knopfGedrueckt : knopf),
          fit: BoxFit.fill,
          filterQuality: FilterQuality.none,
        ),
      ),
      child: child,
    );
    if (states.contains(WidgetState.disabled)) {
      flaeche = Opacity(opacity: 0.45, child: flaeche);
    }
    return flaeche;
  }

  /// Der Stil aller Symbolknöpfe — Zurück, Plus, Zahnrad.
  static ButtonStyle iconButtonStyle() {
    return ButtonStyle(
      foregroundColor: const WidgetStatePropertyAll<Color>(Palette.textOnDark),
      overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      fixedSize: const WidgetStatePropertyAll<Size>(Size.square(knopfSeite)),
      iconSize: const WidgetStatePropertyAll<double>(20),
      shape: const WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(),
      ),
      backgroundBuilder: iconButtonBackground,
    );
  }
}

/// Ein Balken in der Holzfassung — Leben, Energie, Erfahrung.
///
/// Ersetzt `LinearProgressIndicator` dort, wo ein Wert sichtbar sein soll.
/// Die Fassung kommt aus dem Bild, die Füllung zeichnet der Code: So kann
/// derselbe Balken rot, blau oder golden sein.
class HolzBalken extends StatelessWidget {
  const HolzBalken({
    required this.value,
    required this.color,
    this.zoom = 1,
    super.key,
  });

  /// Zwischen 0 und 1; alles darüber oder darunter wird abgeschnitten.
  final double value;
  final Color color;

  /// 1 oder 2: Der Balken ist 12 Bildpunkte hoch, also 12 oder 24
  /// Punkte. Zwischenwerte gehen nicht (siehe `Holz._gedehnt`).
  final int zoom;

  double get height => Holz.balkenBildHoehe * zoom;

  @override
  Widget build(BuildContext context) {
    final s = zoom.toDouble();
    final anteil = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final links = Holz.balkenRinneLinks * s;
          final rinne =
              constraints.maxWidth - links - Holz.balkenRinneRechts * s;
          final breite = rinne * anteil;
          final oben = Holz.balkenRinneOben * s;
          final hoehe = Holz.balkenRinneHoehe * s;

          // **Schmaler als die beiden Enden geht nicht.** `centerSlice`
          // bricht dann mit einer Assertion ab, statt zu schrumpfen — und
          // eine Zeile im ersten Bildaufbau hat oft noch keine Breite.
          if (constraints.maxWidth < Holz.balkenMindestBreite * s) {
            return const SizedBox.expand(
              child: ColoredBox(color: Palette.trackOnDark),
            );
          }

          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    image: Holz._gedehnt(
                      Holz.balken,
                      Holz.balkenMitte,
                      zoom: zoom,
                    ),
                  ),
                ),
              ),
              if (breite > 0)
                Positioned(
                  left: links,
                  top: oben,
                  width: breite,
                  height: hoehe,
                  child: Column(
                    // Ohne `stretch` wäre jede Fläche null Punkte breit —
                    // ein `ColoredBox` ohne Kind nimmt nur, was es muss.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Das obere Drittel heller — wie im Original, das
                      // sonst flach wie eine Fläche aus dem Code aussähe.
                      Expanded(
                        child: ColoredBox(
                          color: Color.lerp(color, Colors.white, 0.3)!,
                        ),
                      ),
                      Expanded(flex: 2, child: ColoredBox(color: color)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Der hängende Holzrahmen für Dialoge und Feiern.
///
/// Oben das Seil, darunter der Rahmen, innen Pergament — so bleibt die
/// Schrift auf dem Untergrund, für den die Palette gemacht ist
/// ([Palette.surface]).
class HolzRahmen extends StatelessWidget {
  const HolzRahmen({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Image.asset(
          Holz.seil,
          width: Holz.seilGroesse.width,
          height: Holz.seilGroesse.height,
          filterQuality: FilterQuality.none,
        ),
        // Das Seil greift über die Oberkante — sonst hinge der Rahmen an
        // einer Lücke.
        Transform.translate(
          offset: const Offset(0, -2 * Holz.pixel),
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: Holz._gedehnt(Holz.rahmen, Holz.rahmenMitte),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Holz.rahmenRand),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Palette.surface,
                  border: Border.all(color: Holz.kante, width: 2),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Eine Karte im Holzrahmen — **die** Fläche für alles, was auf dem Leder
/// liegt (Wunsch vom 21.09.2026: „um alles so einen Holzrahmen, dass es
/// einheitlich aussieht").
///
/// Derselbe Rahmen wie beim hängenden [HolzRahmen], nur ohne Seil und in
/// einfacher Größe. Innen Pergament, damit die Schrift auf dem Untergrund
/// steht, für den die Palette gemacht ist.
///
/// **Wer eine Pergamentfläche baut, nimmt diese.** Ein `Container` mit
/// `Palette.surface` und runden Ecken ist die Form von vorher; stünden
/// beide nebeneinander, sähe man genau den Bruch, den diese Klasse
/// schliesst.
///
/// Ausgenommen sind Kacheln in Rastern und Knöpfe (Ladenraster,
/// Ausrüstungs- und Fähigkeitsplätze, Antworten, Baumknoten): Zwölf Punkte
/// Holz um eine Kachel von fünfzig wären dicker als ihr Inhalt. Sie liegen
/// in einer gerahmten Karte oder auf einer gerahmten Fläche.
class HolzKarte extends StatelessWidget {
  const HolzKarte({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = Palette.surface,
    this.edgeColor = Holz.kante,
    super.key,
  });

  final Widget child;

  /// Abstand des Inhalts vom Pergamentrand.
  final EdgeInsetsGeometry padding;

  /// Das Pergament. Nur für die wenigen Flächen, die bewusst anders
  /// getönt sind — etwa ein verdienter oder abgehakter Eintrag.
  final Color color;

  /// Die Kante zwischen Holz und Pergament. Eine andere Farbe hebt eine
  /// Karte hervor — grün, wenn eine Gewohnheit abgehakt ist.
  final Color edgeColor;

  /// Wie lange ein Wechsel von [color] oder [edgeColor] dauert. Abhaken
  /// soll sichtbar *passieren*, nicht nur umspringen.
  static const Duration wechsel = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        image: Holz._gedehnt(Holz.rahmen, Holz.rahmenMitte, zoom: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Holz.kartenRand),
        child: AnimatedContainer(
          duration: wechsel,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: edgeColor, width: 1.5),
          ),
          // **Ein durchsichtiges Material auf dem Pergament.** Listeneinträge
          // und Knöpfe malen ihre Tipp-Welle auf das nächste Material
          // darüber; ohne dieses hier läge die Pergamentfarbe dazwischen
          // und verdeckte sie. Flutter meldet das bei `ListTile` sogar.
          child: Material(
            type: MaterialType.transparency,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Ein Dialog im hängenden Holzrahmen — für `showDialog`.
///
/// Die Hülle, die das Ergebnisblatt schon trug, als eine Stelle: Der
/// Dialog selbst wird durchsichtig, der Rahmen trägt ihn, innen bleibt
/// ein gewöhnlicher [AlertDialog] mit seinen Knöpfen.
class HolzDialog extends StatelessWidget {
  const HolzDialog({required this.child, super.key});

  /// Meist ein [AlertDialog]. Er wird auf Pergament gelegt und verliert
  /// seine eigenen Ecken und seinen Schatten.
  final Widget child;

  static const EdgeInsets _abstand = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 24,
  );

  @override
  Widget build(BuildContext context) {
    // **Die Höhe begrenzen, bevor der Rahmen sie verliert.** Der hängende
    // Rahmen ist eine Spalte mit `min` — darin bekäme ein `AlertDialog`
    // unbegrenzte Höhe. Er misst seine Breite aber über die Höhe seines
    // Inhalts, und eine Liste darin (Titelwahl) darf das nicht: Flutter
    // bricht mit „does not support returning intrinsic dimensions" ab.
    //
    // **Aus dem Platz, nicht aus dem Bildschirm.** `MediaQuery` meldet im
    // Browser das ganze Fenster, `PhoneFrame` zeigt aber nur 844 Punkte
    // davon — mit der Fenstergrösse lief der Rahmen dort um 256 über.
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: _abstand,
      child: LayoutBuilder(
        builder: (context, platz) {
          final hoehe =
              platz.maxHeight - Holz.seilGroesse.height - 2 * Holz.rahmenRand;
          return HolzRahmen(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: hoehe > 0 ? hoehe : 0),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dialogTheme: const DialogThemeData(
                    backgroundColor: Palette.surface,
                    elevation: 0,
                    insetPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(),
                  ),
                ),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Ein Blatt von unten im Holzrahmen — für `showModalBottomSheet` mit
/// durchsichtigem Hintergrund.
///
/// Ohne Seil: Ein Blatt kommt von unten, es hängt nicht.
class HolzBlatt extends StatelessWidget {
  const HolzBlatt({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: HolzKarte(padding: EdgeInsets.zero, child: child),
    );
  }
}
