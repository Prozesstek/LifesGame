import 'package:flutter/material.dart';

import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';

/// Ein Bereich des Spiels als runder Knopf.
///
/// **Er ersetzt seit Issue #35 die Kachelliste.** Fünf Kacheln
/// untereinander waren ein Menü; fünf Kreise um die Figur herum sind ein
/// Ort, an dem die Figur in der Mitte steht. Das ist die Aussage des
/// Produkts, und der Startbildschirm ist die einzige Stelle, an der sie
/// ohne Worte auskommt.
///
/// **Der Kreis trägt Zeichen und Namen.** Der Entwurf zeigt nur einen
/// Buchstaben je Kreis; ein „K" allein sagt aber weder „Kampf" noch
/// „Kaufen". Name unter dem Kreis kostet zwölf Pixel und nimmt die Frage
/// heraus.
///
/// **Die Fläche ist seit den ersten Zeichnungen gemalt und nicht
/// gerechnet.** `assets/UI/ButtonBG.png` liegt unter dem Zeichen; der
/// Charakterkreis hat mit `CharacterButton.png` eine eigene Fassung, in
/// der die Figur schon drin steckt. Fehlt eine Datei, bleibt der
/// gezeichnete Kreis von vorher — der Startbildschirm sieht dann
/// schlichter aus und nicht kaputt.
class HubCircle extends StatelessWidget {
  const HubCircle({
    required this.icon,
    required this.label,
    required this.onTap,
    this.lockedReason,
    this.image,
    super.key,
  });

  final IconData icon;

  /// Die gezeichnete Fläche, oder `null` für die schlichte.
  ///
  /// **Trägt sie das Zeichen schon selbst**, wie `CharacterButton.png`,
  /// dann setzt [imageCarriesIcon] das [icon] aus. Zwei Figuren
  /// übereinander wären eine zu viel.
  final HubCircleImage? image;

  /// Der Name des Bereichs — steht unter dem Kreis.
  final String label;

  /// Wird gerufen, wenn der Bereich offen ist.
  final VoidCallback onTap;

  /// Warum der Bereich zu ist, in einem Satz — oder `null`, wenn er offen
  /// ist.
  ///
  /// **Der Satz verschwindet nicht, er wandert.** Auf der alten Kachel
  /// stand er dauerhaft darunter; ADR-0020 nennt ihn ausdrücklich
  /// wichtig, weil eine Sperre ohne Weg jemanden in die Theorie
  /// zurückschickt, wo er nichts mehr zu tun hat. Ein Kreis hat dafür
  /// keinen Platz, also kommt der Satz beim Antippen.
  final String? lockedReason;

  bool get isLocked => lockedReason != null;

  /// Kantenlänge des Kreises. Drei davon plus Abstand passen bei 390
  /// Pixeln Breite nebeneinander, und 72 liegt über den 48 Pixeln, die
  /// eine Tippfläche mindestens braucht.
  static const double diameter = 72;

  /// Wie stark eine gesperrte Fläche verblasst.
  ///
  /// Die alte Sperre färbte den Kreis grau. Eine Zeichnung lässt sich
  /// nicht umfärben, ohne sie zu ruinieren — sie wird deshalb blasser,
  /// und das Schloss unten rechts bleibt die eigentliche Aussage.
  static const double _lockedOpacity = 0.45;

  @override
  Widget build(BuildContext context) {
    final bild = image;

    // Zwei Farben, weil es zwei Untergründe gibt: der schlichte Kreis
    // steht auf dunklem Grund, das Zeichen auf der Zeichnung dagegen auf
    // Pergament. Ein Wert für beides wäre auf einem der beiden
    // unlesbar.
    final farbe = isLocked ? Palette.muted : Palette.accent;

    return Semantics(
      button: true,
      enabled: !isLocked,
      label: label,
      child: InkWell(
        onTap: () => isLocked ? _sageWarum(context) : onTap(),
        borderRadius: BorderRadius.circular(diameter),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  if (bild == null)
                    _SchlichterKreis(icon: icon, farbe: farbe)
                  else
                    Opacity(
                      opacity: isLocked ? _lockedOpacity : 1,
                      child: SizedBox(
                        width: diameter,
                        height: diameter,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            PixelArt(
                              assetPath: bild.assetPath,
                              side: diameter,
                              fallback: _SchlichterKreis(
                                icon: icon,
                                farbe: farbe,
                              ),
                            ),
                            if (!bild.carriesIcon)
                              Icon(icon, size: 30, color: Palette.text),
                          ],
                        ),
                      ),
                    ),
                  if (isLocked)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Palette.background,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock,
                          size: 13,
                          color: Palette.muted,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: diameter + 16,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isLocked ? Palette.muted : Palette.textOnDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sageWarum(BuildContext context) {
    final grund = lockedReason;
    if (grund == null) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(grund), duration: const Duration(seconds: 4)),
      );
  }
}

/// Eine gezeichnete Knopffläche.
///
/// **Warum ein Typ und nicht zwei Parameter.** Pfad und „trägt das
/// Zeichen schon" gehören zusammen: Wer die Fläche wechselt, ohne die
/// zweite Angabe nachzuziehen, bekommt entweder zwei Figuren übereinander
/// oder einen leeren Kreis. Als ein Wert kann das nicht auseinanderlaufen.
enum HubCircleImage {
  /// Die leere Fläche. Das Zeichen des Bereichs liegt darauf.
  plain('assets/UI/ButtonBG.png', carriesIcon: false),

  /// Die Charakter-Fassung — die Figur ist schon eingezeichnet.
  character('assets/UI/CharacterButton.png', carriesIcon: true);

  const HubCircleImage(this.assetPath, {required this.carriesIcon});

  final String assetPath;

  /// Ob die Zeichnung ihr Zeichen selbst mitbringt.
  final bool carriesIcon;
}

/// Der ungezeichnete Kreis — Rand, Fläche, Zeichen.
///
/// **Er ist beides**: die Darstellung ohne Bild und der Rückfall, wenn
/// eine Bilddatei fehlt. Zweimal derselbe Kreis an zwei Stellen wäre
/// genau die Sorte Verdopplung, die irgendwann nur an einer Stelle
/// nachgezogen wird.
class _SchlichterKreis extends StatelessWidget {
  const _SchlichterKreis({required this.icon, required this.farbe});

  final IconData icon;
  final Color farbe;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: HubCircle.diameter,
      height: HubCircle.diameter,
      decoration: BoxDecoration(
        color: Palette.surface,
        shape: BoxShape.circle,
        border: Border.all(color: farbe, width: 2),
      ),
      child: Icon(icon, size: 30, color: farbe),
    );
  }
}
