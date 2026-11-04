import 'package:flutter/material.dart';

import 'druck.dart';
import 'gehrung.dart';
import 'holz_teile.dart';
import 'palette.dart';

/// Die Holzflächen der Oberfläche: Planke, Knopf, Balken, Seil, Rahmen.
///
/// **Seit ADR-0099 alle gemalt, nicht gedehnt** — der Rahmen auf Gehrung
/// (`lib/ui/gehrung.dart`), die übrigen Teile in `lib/ui/holz_teile.dart`,
/// mit denselben Farben und derselben Maserung. Hier stehen nur noch ihre
/// Maße und die Widgets, die sie tragen.
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
  /// Logische Punkte je Bildpunkt. **Ganzzahlig**, sonst werden die
  /// Pixel ungleich breit.
  static const double pixel = 2;

  /// Die Planke ist 23 Bildpunkte hoch, doppelt gezeichnet.
  static const double plankeHoehe = 23 * pixel;

  /// Wie weit der Inhalt vom Außenrand des Rahmens wegbleibt.
  static const double rahmenRand = 12 * pixel;

  /// Derselbe Rand um eine Karte — der Rahmen in einfacher statt doppelter
  /// Größe. Doppelt wären es 24 Punkte Holz um jede Karte, und auf einem
  /// Handy mit sieben Karten untereinander bliebe für den Inhalt zu wenig.
  static const double kartenRand = 12;

  /// Die dunkle Kante zwischen Holz und Pergament — dieselbe wie beim
  /// hängenden Rahmen, damit beide aus einem Satz wirken.
  static const Color kante = Color(0xFF3A1F0C);

  /// Das Holz innen in einer [HolzGruppe], bevor das Leder es abdunkelt.
  static const Color gruppenGrund = Color(0xFF9E6230);

  /// Wie breit diese Kante im hängenden Rahmen ist. Der Inhalt bleibt um
  /// genau so viel von ihr weg, sonst malt er sie zu.
  static const double kantenBreite = 2;

  /// Das Seil über dem Rahmen, 61 × 23 Bildpunkte.
  static const Size seilGroesse = Size(61 * pixel, 23 * pixel);

  /// Der Knopf ist 14 × 14 Bildpunkte, dreifach gezeichnet — so groß wie
  /// ein Symbolknopf in der Kopfzeile.
  static const double knopfSeite = 14 * 3;

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

    Widget flaeche = CustomPaint(
      painter: const PlankenMaler(pixel: pixel),
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
    return DruckSkala(gedrueckt: gedrueckt, child: flaeche);
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
    Widget flaeche = CustomPaint(
      painter: KnopfMaler(gedrueckt: gedrueckt),
      child: child,
    );
    if (states.contains(WidgetState.disabled)) {
      flaeche = Opacity(opacity: 0.45, child: flaeche);
    }
    return DruckSkala(gedrueckt: gedrueckt, child: flaeche);
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
/// Die Fassung malt `BalkenMaler`, die Füllung zeichnet dieses Widget: So
/// kann derselbe Balken rot, blau oder golden sein.
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
  /// Punkte.
  final int zoom;

  double get height => BalkenMaler.hoehe * zoom.toDouble();

  @override
  Widget build(BuildContext context) {
    final s = zoom.toDouble();
    final anteil = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final links = BalkenMaler.rinneLinks * s;
          final rinne =
              constraints.maxWidth - links - BalkenMaler.rinneRechts * s;
          final breite = rinne * anteil;
          // Die oberste Zeile der Rinne ist ihr dunkler Rand.
          final oben = (BalkenMaler.rinneOben + 1) * s;
          final hoehe = (BalkenMaler.rinneHoehe - 1) * s;

          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(painter: BalkenMaler(pixel: s)),
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
                      // Das obere Drittel heller, sonst sähe die Füllung
                      // flach wie eine Fläche aus dem Code aus.
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
  const HolzRahmen({required this.child, this.art = RahmenArt.holz, super.key});

  final Widget child;

  /// Welcher Rahmen — Messing für Belohnungen, Eisen im Dungeon (ADR-0099).
  final RahmenArt art;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox.fromSize(
          size: Holz.seilGroesse,
          child: const CustomPaint(painter: SeilMaler(pixel: Holz.pixel)),
        ),
        // Das Seil greift über die Oberkante — sonst hinge der Rahmen an
        // einer Lücke.
        Transform.translate(
          offset: const Offset(0, -2 * Holz.pixel),
          child: CustomPaint(
            painter: GehrungsMaler(pixel: Holz.pixel, art: art),
            child: Padding(
              padding: const EdgeInsets.all(Holz.rahmenRand),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Palette.surface,
                  border: Border.all(
                    color: Holz.kante,
                    width: Holz.kantenBreite,
                  ),
                ),
                // **Um die Breite der Kante eingerückt.** Ein
                // `DecoratedBox` malt sein Kind über den eigenen Rand; ein
                // Dialog, der die ganze Breite füllt, deckte die Kante
                // sonst auf seiner Höhe zu, und der Rahmen hatte Lücken.
                child: Padding(
                  padding: const EdgeInsets.all(Holz.kantenBreite),
                  child: child,
                ),
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
    this.art,
    super.key,
  });

  final Widget child;

  /// Welcher Rahmen. Ohne Angabe der des Bildschirms (`RahmenOrt`), dort
  /// ohne Angabe Holz (ADR-0099).
  final RahmenArt? art;

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
    return CustomPaint(
      painter: GehrungsMaler(art: art ?? RahmenOrt.of(context)),
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

/// Ein Holzrahmen um eine **Gruppe von Knöpfen** — die Kreise der
/// Startseite (Wunsch vom 23.10.2026: „damit die zusammenhängender
/// aussehen“).
///
/// Derselbe Rahmen wie bei [HolzKarte], innen aber **kein Pergament**:
/// Die Mitte des Rahmens ist selbst Holz, und darüber liegt Leder, das
/// es abdunkelt. Die Namen unter den Kreisen stehen in den Farben für
/// dunklen Grund.
class HolzGruppe extends StatelessWidget {
  const HolzGruppe({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(4, 8, 4, 4),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Wie stark das Leder das Holz innen abdunkelt — 0 helles Holz, 1
  /// ganz dunkel.
  static const double deckung = 0.6;

  /// Was der Rahmen samt Innenabstand oben und unten an Höhe dazugibt.
  static const double hoeheDazu = 2 * Holz.kartenRand + 12;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GehrungsMaler(
        art: RahmenOrt.of(context),
        mitte: Holz.gruppenGrund,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Holz.kartenRand),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Palette.background.withValues(alpha: deckung),
            border: Border.all(color: Holz.kante, width: 1.5),
          ),
          child: Padding(padding: padding, child: child),
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
  const HolzDialog({required this.child, this.art = RahmenArt.holz, super.key});

  /// Welcher Rahmen — ein Dialog erbt den Ort des Bildschirms nicht, er
  /// sagt ihn selbst (ADR-0099).
  final RahmenArt art;

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
              platz.maxHeight -
              Holz.seilGroesse.height -
              2 * Holz.rahmenRand -
              2 * Holz.kantenBreite;
          return HolzRahmen(
            art: art,
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
