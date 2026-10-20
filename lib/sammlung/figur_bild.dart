import 'package:flutter/material.dart';

import '../action/action_sprites.dart';

/// Eine Figur aus der Grube als stehendes Bild — das erste Bild ihres
/// Ruhe-Streifens, auf die Figur zugeschnitten.
///
/// **Ausgeschnitten, nicht verkleinert.** Ein Bild im Streifen ist oft
/// 100 × 100 Punkte, die Figur darin 20. Der Ausschnitt reicht vom Kopf
/// ([Figure.topY]) bis zu den Füßen ([Figure.footY]) und steht mittig
/// über [Figure.footX]; dann wird er auf [side] gebracht — hart, außer
/// bei Frederiks eigenen Zeichnungen ([Figure.smooth]).
class FigurBild extends StatelessWidget {
  const FigurBild({required this.figur, required this.side, super.key});

  final Figure figur;
  final double side;

  @override
  Widget build(BuildContext context) {
    final strip = figur.stripFor(Pose.idle);
    final hoehe = (figur.footY - figur.topY).clamp(1.0, figur.frameSize);
    // Etwas Luft um den Kopf und unter den Füßen, und quadratisch.
    final kante = (hoehe * 1.3).clamp(1.0, figur.frameSize);
    final links = (figur.footX - kante / 2).clamp(0.0, figur.frameSize - kante);
    final oben = (figur.footY + hoehe * 0.12 - kante).clamp(
      0.0,
      figur.frameSize - kante,
    );

    return SizedBox.square(
      dimension: side,
      child: FittedBox(
        child: SizedBox.square(
          dimension: kante,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: 0,
              minHeight: 0,
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Transform.translate(
                offset: Offset(-links, -oben),
                child: Image.asset(
                  '${GrubeFiguren.folder}/${strip.file}',
                  width: figur.frameSize * strip.frames,
                  height: figur.frameSize,
                  fit: BoxFit.fill,
                  alignment: Alignment.topLeft,
                  filterQuality: figur.smooth
                      ? FilterQuality.medium
                      : FilterQuality.none,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
