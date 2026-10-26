import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'beute_flug.dart';
import 'konfetti.dart';
import 'palette.dart';
import 'pixel_art.dart';

/// Eine aufsteigende Zeile, wie über einem gefallenen Gegner in der Grube.
class AufstiegZeile {
  const AufstiegZeile(
    this.text, {
    this.color = Palette.accent,
    this.bild,
    this.icon,
  });

  final String text;
  final Color color;

  /// Ein kleines Bild vor dem Text — der Schlüssel (ADR-0048).
  final String? bild;

  /// Ein Zeichen vor dem Text — das Gebiet eines Häkchens (ADR-0085).
  final IconData? icon;
}

/// **Zahlen steigen dort auf, wo getippt wurde.**
///
/// Merkt sich über einen [Listener], wo der Finger zuletzt aufsetzte, und
/// lässt dort Zeilen aufsteigen und ausblenden ([zeige]). Die Stelle kommt
/// vom Finger, nicht vom Widget: Eine abgehakte Gewohnheit rutscht im
/// selben Moment nach unten (`dailyListOn`) — die Zahlen stehen trotzdem
/// dort, wo man hinsieht.
///
/// **Und was ein Häkchen sonst noch auswirft** (18.10.): Münzen und
/// Funken, die zur Leiste oben fliegen ([fliege]), und das Konfetti,
/// wenn der Tag geschafft ist ([konfetti]). Beides liegt hier, weil
/// beides vom Finger ausgeht — und weil ein Host das Bild über allem
/// anderen hat.
///
/// Jede Animation endet von selbst; ein Test mit `pumpAndSettle` wartet
/// sie einfach ab.
class AufstiegHost extends StatefulWidget {
  const AufstiegHost({required this.child, super.key});

  final Widget child;

  static const Duration dauer = Duration(milliseconds: 1100);

  /// Wie weit die Zeilen steigen.
  static const double hoehe = 56;

  /// Wie dicht Ankunftsklänge aufeinander folgen dürfen, in Sekunden. Acht
  /// Münzen in vierhundert Millisekunden sind ein Rasseln, kein Brei.
  static const double klangAbstand = 0.07;

  /// Der Host über [context] — oder null, wenn es keinen gibt. Dann steigt
  /// eben nichts auf; das Häkchen gilt trotzdem.
  static AufstiegHostState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<AufstiegHostState>();

  @override
  State<AufstiegHost> createState() => AufstiegHostState();
}

class AufstiegHostState extends State<AufstiegHost>
    with SingleTickerProviderStateMixin {
  Offset? _letzterFinger;
  final List<_Stoss> _stoesse = <_Stoss>[];
  int _naechste = 0;

  // --- Was fliegt ---

  final BeuteFlug _flug = BeuteFlug();
  final List<Konfetti> _konfetti = <Konfetti>[];
  final Map<FlugZiel, GlobalKey> _ziele = <FlugZiel, GlobalKey>{};
  final Map<FlugZiel, ValueNotifier<int>> _unterwegs =
      <FlugZiel, ValueNotifier<int>>{
        for (final ziel in FlugZiel.values) ziel: ValueNotifier<int>(0),
      };
  final Map<FlugZiel, double> _letzterKlang = <FlugZiel, double>{};
  void Function(FlugZiel ziel)? _beiAnkunft;

  /// Was geschehen soll, wenn ein Wurf gelandet ist, und wann — in der
  /// Zeit des Hosts ([_zeit]), nicht der Uhr: Läuft der Host nicht,
  /// landet auch nichts.
  final List<(double, VoidCallback)> _landungen = <(double, VoidCallback)>[];

  /// Meldet jedem Bild, dass neu gemalt wird — ohne den Baum neu zu bauen.
  final ValueNotifier<int> _bild = ValueNotifier<int>(0);
  Ticker? _uhrOderNichts;
  Ticker get _uhr => _uhrOderNichts ??= createTicker(_tick);
  Duration _zuletzt = Duration.zero;
  double _zeit = 0;

  /// Ein Ziel meldet sich an ([FlugZielMarke]).
  void meldeZiel(FlugZiel ziel, GlobalKey ort) => _ziele[ziel] = ort;

  /// Und ab — aber nur, wenn es noch dasselbe ist.
  void vergissZiel(FlugZiel ziel, GlobalKey ort) {
    if (identical(_ziele[ziel], ort)) _ziele.remove(ziel);
  }

  /// Wie viel zu [ziel] noch unterwegs ist. Die Leiste zieht es ab.
  ValueListenable<int> unterwegs(FlugZiel ziel) => _unterwegs[ziel]!;

  /// Wie viele Würfe Konfetti gerade in der Luft sind.
  @visibleForTesting
  int get konfettiInDerLuft => _konfetti.length;

  /// Lässt [gold] als Münzen und [xp] als Funken vom letzten Finger zu
  /// ihren Zielen fliegen, [gebiet] als Funken in der [gebietFarbe] zum
  /// Balken des Gebiets (ADR-0085, ADR-0090). **Ohne Ziel fliegt nichts** — wo keine Leiste
  /// ist, steigen nur die Zahlen auf.
  ///
  /// [beiAnkunft] klingt, wenn etwas ankommt, höchstens alle
  /// [AufstiegHost.klangAbstand] Sekunden je Ziel. [wennGelandet] kommt,
  /// sobald das letzte Stück dieses Wurfs angekommen ist — im Takt des
  /// Hosts, damit ein Test, der auf Ruhe wartet, auch darauf wartet.
  ///
  /// Gibt zurück, ob etwas fliegt. Wenn nicht, kommt [wennGelandet] nie.
  bool fliege({
    required int gold,
    required int xp,
    int gebiet = 0,
    Color? gebietFarbe,
    void Function(FlugZiel ziel)? beiAnkunft,
    VoidCallback? wennGelandet,
  }) {
    final finger = _letzterFinger;
    final box = context.findRenderObject();
    if (finger == null || box is! RenderBox) return false;
    final von = box.globalToLocal(finger);
    var landung = 0.0;
    for (final (ziel, betrag) in <(FlugZiel, int)>[
      (FlugZiel.gold, gold),
      (FlugZiel.erfahrung, xp),
      (FlugZiel.gebiet, gebiet),
    ]) {
      final nach = _mitteVon(ziel, box);
      if (nach == null || betrag <= 0) continue;
      final dauer = _flug.wirf(
        von: von,
        ziel: ziel,
        nach: nach,
        betrag: betrag,
        farbe: ziel == FlugZiel.gebiet ? gebietFarbe : null,
      );
      if (dauer > landung) landung = dauer;
    }
    if (landung <= 0) return false;
    _beiAnkunft = beiAnkunft;
    if (wennGelandet != null) _landungen.add((_zeit + landung, wennGelandet));
    _meldeUnterwegs();
    _laufe();
    return true;
  }

  /// Konfetti vom letzten Finger aus — oder von [von], in Punkten des
  /// Hosts. Eine Seite im Wissensbaum endet mit dem Knopf ganz unten; von
  /// dort käme es kaum über die untere Hälfte.
  void konfetti({Offset? von}) {
    final finger = _letzterFinger;
    final box = context.findRenderObject();
    if (box is! RenderBox) return;
    final start = von ?? (finger == null ? null : box.globalToLocal(finger));
    if (start == null) return;
    _konfetti.add(Konfetti(von: start, seed: _naechste++));
    _laufe();
  }

  Offset? _mitteVon(FlugZiel ziel, RenderBox host) {
    final ort = _ziele[ziel]?.currentContext?.findRenderObject();
    if (ort is! RenderBox || !ort.attached || !ort.hasSize) return null;
    return host.globalToLocal(ort.localToGlobal(ort.size.center(Offset.zero)));
  }

  void _meldeUnterwegs() {
    for (final ziel in FlugZiel.values) {
      _unterwegs[ziel]!.value = _flug.unterwegs(ziel);
    }
  }

  void _laufe() {
    if (_uhr.isActive) return;
    _zuletzt = Duration.zero;
    _uhr.start();
  }

  void _tick(Duration seitStart) {
    final dt = (seitStart - _zuletzt).inMicroseconds / 1e6;
    _zuletzt = seitStart;
    _zeit += dt;

    final angekommen = _flug.update(dt);
    if (angekommen.isNotEmpty) _meldeUnterwegs();
    for (final ziel in angekommen) {
      if (_zeit - (_letzterKlang[ziel] ?? -1) < AufstiegHost.klangAbstand) {
        continue;
      }
      _letzterKlang[ziel] = _zeit;
      _beiAnkunft?.call(ziel);
    }

    for (final wurf in _konfetti) {
      wurf.update(dt);
    }
    _konfetti.removeWhere((wurf) => wurf.vorbei);

    _bild.value++;
    _landen();
    if (_flug.leer && _konfetti.isEmpty && _landungen.isEmpty) _uhr.stop();
  }

  /// Ruft, was gelandet ist. Ist nichts mehr in der Luft, ist alles
  /// gelandet — auf einen Bruchteil einer Sekunde kommt es nicht an.
  void _landen() {
    final faellig = _landungen
        .where((l) => _flug.leer || l.$1 <= _zeit)
        .toList(growable: false);
    if (faellig.isEmpty) return;
    _landungen.removeWhere(faellig.contains);
    for (final (_, danach) in faellig) {
      danach();
    }
  }

  @override
  void dispose() {
    _uhrOderNichts?.dispose();
    _bild.dispose();
    for (final notifier in _unterwegs.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  /// Lässt [zeilen] an der Stelle des letzten Fingers aufsteigen.
  void zeige(List<AufstiegZeile> zeilen) {
    final finger = _letzterFinger;
    final box = context.findRenderObject();
    if (finger == null || zeilen.isEmpty || box is! RenderBox) return;
    setState(() {
      _stoesse.add(
        _Stoss(id: _naechste++, bei: box.globalToLocal(finger), zeilen: zeilen),
      );
    });
  }

  void _fertig(int id) {
    if (!mounted) return;
    setState(() => _stoesse.removeWhere((s) => s.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _letzterFinger = e.position,
      child: Stack(
        children: <Widget>[
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: KonfettiMaler(_konfetti, repaint: _bild),
                foregroundPainter: BeuteFlugMaler(_flug, repaint: _bild),
              ),
            ),
          ),
          for (final stoss in _stoesse)
            Positioned(
              key: ValueKey<int>(stoss.id),
              left: stoss.bei.dx - 90,
              width: 180,
              top: stoss.bei.dy - 36,
              child: IgnorePointer(
                child: _Steigen(stoss: stoss, onEnde: () => _fertig(stoss.id)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stoss {
  const _Stoss({required this.id, required this.bei, required this.zeilen});

  final int id;
  final Offset bei;
  final List<AufstiegZeile> zeilen;
}

class _Steigen extends StatelessWidget {
  const _Steigen({required this.stoss, required this.onEnde});

  final _Stoss stoss;
  final VoidCallback onEnde;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AufstiegHost.dauer,
      onEnd: onEnde,
      builder: (context, t, child) {
        // Erst ein kleiner Sprung, dann gleichmässig nach oben; die zweite
        // Hälfte blendet aus.
        final steigen = Curves.easeOutCubic.transform(t);
        final sichtbar = t < 0.5 ? 1.0 : 1 - (t - 0.5) / 0.5;
        final gross = t < 0.15 ? 0.7 + 2 * t : 1.0;
        return Opacity(
          opacity: sichtbar.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -AufstiegHost.hoehe * steigen),
            child: Transform.scale(scale: gross, child: child),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final zeile in stoss.zeilen) _Zeile(zeile: zeile),
        ],
      ),
    );
  }
}

/// Eine aufsteigende Zeile, mit Bild davor, wenn sie eins hat.
class _Zeile extends StatelessWidget {
  const _Zeile({required this.zeile});

  final AufstiegZeile zeile;

  @override
  Widget build(BuildContext context) {
    final bild = zeile.bild;
    final icon = zeile.icon;
    // **Das Bild steht im Text, nicht daneben.** Eine `Row` liefe in der
    // schmalen Fläche über; ein Text darf über seinen Rand hinaus stehen,
    // und genau so sollen die Zahlen aussehen.
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          if (bild != null) ...<InlineSpan>[
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: PixelArt(
                assetPath: bild,
                side: 22,
                fallback: const SizedBox(width: 22, height: 22),
              ),
            ),
            const TextSpan(text: ' '),
          ],
          if (icon != null) ...<InlineSpan>[
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                icon,
                size: 18,
                color: zeile.color,
                shadows: const <Shadow>[
                  Shadow(color: Color(0xCC1A0E05), offset: Offset(1, 1)),
                ],
              ),
            ),
            const TextSpan(text: ' '),
          ],
          TextSpan(text: zeile.text),
        ],
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.visible,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: zeile.color,
        shadows: const <Shadow>[
          Shadow(color: Color(0xCC1A0E05), offset: Offset(1, 1)),
          Shadow(color: Color(0x991A0E05), blurRadius: 3),
        ],
      ),
    );
  }
}
