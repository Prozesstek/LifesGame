import 'package:flutter/material.dart';

import '../../habits/widgets/daily_chest_card.dart';
import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/on_dark.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';
import '../am_feuer.dart';
import 'feuer_bild.dart';

/// **Das Lagerfeuer auf der Startseite** (ADR-0076) — an der Stelle, wo
/// bis zum 18.10. Truhe und Tagesaufgaben als zwei Karten standen.
///
/// Ein kleines Feuer, das Wort und, was dort wartet, als Zeichen mit
/// Zahl: Rückfrage, Truhe, Aufgaben. Ein Tipp führt hin. Brennt es, ist
/// die Karte warm umrandet; sonst glimmt sie nur.
class LagerfeuerKarte extends StatelessWidget {
  const LagerfeuerKarte({
    required this.amFeuer,
    required this.onOpen,
    super.key,
  });

  final AmFeuer amFeuer;
  final VoidCallback onOpen;

  static const Key oeffnenKey = ValueKey<String>('lagerfeuer-oeffnen');

  @override
  Widget build(BuildContext context) {
    final wartet = amFeuer.wartet;
    return Semantics(
      container: true,
      button: true,
      label: wartet == 0
          ? 'Lagerfeuer'
          : 'Lagerfeuer, $wartet ${wartet == 1 ? 'wartet' : 'warten'}',
      excludeSemantics: true,
      child: Druck(
        child: GestureDetector(
          key: oeffnenKey,
          behavior: HitTestBehavior.opaque,
          onTap: onOpen,
          child: HolzKarte(
            color: Palette.backgroundRaised,
            edgeColor: amFeuer.brennt ? Palette.tintLava : Holz.kante,
            padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
            child: OnDark(
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CustomPaint(
                      painter: FeuerMaler(
                        brennt: amFeuer.brennt,
                        zeit: 1.8,
                        himmel: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Lagerfeuer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (amFeuer.rueckfrageOffen)
                    const _Wartet(zeichen: Icon(Icons.quiz_outlined, size: 18)),
                  if (amFeuer.truheWartet)
                    const _Wartet(
                      zeichen: PixelArt(
                        assetPath: truhenBild,
                        side: 22,
                        fallback: Icon(Icons.inventory_2, size: 18),
                      ),
                    ),
                  if (amFeuer.aufgabenAbholbar > 0)
                    _Wartet(
                      zeichen: const Icon(Icons.flag_rounded, size: 18),
                      zahl: amFeuer.aufgabenAbholbar,
                    ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Palette.textOnDarkDim,
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

/// Ein Zeichen für etwas, das am Feuer wartet — mit Zahl, wenn es mehr
/// als eins ist.
class _Wartet extends StatelessWidget {
  const _Wartet({required this.zeichen, this.zahl = 1});

  final Widget zeichen;
  final int zahl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconTheme.merge(
            data: const IconThemeData(color: Palette.goldOnDark),
            child: zeichen,
          ),
          if (zahl > 1) ...<Widget>[
            const SizedBox(width: 2),
            Text(
              '$zahl',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Palette.goldOnDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
