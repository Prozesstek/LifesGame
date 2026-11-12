import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/pixel_art.dart';
import '../silbentrennung.dart';
import 'blocksatz.dart';
import 'buch_stil.dart';
import 'seiten_farbe.dart';

/// **Ein Abschnitt schreibt sich**: die Überschrift fällt herein, dann
/// erscheint der Text Wort für Wort.
///
/// **Wort für Wort, nicht Buchstabe für Buchstabe**, und schneller, als
/// man liest: rund 40 ms je Wort, ein Abschnitt von sechzig Wörtern steht
/// nach knapp drei Sekunden. Das Auge hat dabei immer etwas zu lesen und
/// wartet nie. **Ein Tipp auf den Text zeigt ihn ganz.**
///
/// **Der Text steht von Anfang an im Layout**, nur durchsichtig: Nichts
/// springt, wenn ein Wort dazukommt, und der Vorleser bekommt den ganzen
/// Satz.
///
/// **Gesetzt wie in einem Lernbuch** (12.11.2026, [BuchStil]): Serifen,
/// Sepia, Blocksatz mit Trennung, der erste Buchstabe als Initiale über
/// drei Zeilen. `*kursiv*` betont, `**fett**` ist ein Fachbegriff, Kästen,
/// Abbildungen und Zier kommen aus dem Inhalt (`Lesetext`). Am Ende steht
/// ein Zierelement.
class SchreibText extends StatefulWidget {
  const SchreibText({
    required this.heading,
    required this.body,
    this.aktiv = true,
    this.sofort = false,
    this.ersteAbbildung = 1,
    super.key,
  });

  final String heading;
  final String body;

  /// Ob der Abschnitt zu sehen ist. Erst dann beginnt er zu schreiben —
  /// das Buch baut die Nachbarseite schon beim Blättern.
  final bool aktiv;

  /// Ganz zeigen, ohne zu schreiben: schon gelesen.
  final bool sofort;

  /// Die Nummer der ersten Abbildung dieses Abschnitts („Abb. 2“) — die
  /// Abbildungen zählen über die ganze Lektion.
  final int ersteAbbildung;

  /// So lange braucht ein Wort.
  static const Duration jeWort = Duration(milliseconds: 40);

  /// So lange fällt die Überschrift herein, bevor das erste Wort kommt.
  static const Duration ueberschrift = Duration(milliseconds: 280);

  /// Wie lange ein Wort vom Unsichtbaren ins Volle braucht, in Wörtern.
  static const double einblenden = 3;

  /// So groß steht eine Abbildung auf der Seite.
  static const double abbildungSeite = 112;

  static const Key zierKey = ValueKey<String>('buch-zier-ende');

  @override
  State<SchreibText> createState() => _SchreibTextState();
}

class _SchreibTextState extends State<SchreibText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _zeit;
  late List<Absatz> _absaetze;
  late int _woerter;

  @override
  void initState() {
    super.initState();
    _lesen();
    _zeit = AnimationController(vsync: this, duration: _dauer);
    if (widget.sofort) {
      _zeit.value = 1;
    } else if (widget.aktiv) {
      _zeit.forward();
    }
    Silbentrennung.deutsch.addListener(_neuGetrennt);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Wer Bewegung im System abgeschaltet hat, bekommt den ganzen Text.
    if (MediaQuery.disableAnimationsOf(context)) _zeit.value = 1;
  }

  @override
  void didUpdateWidget(SchreibText alt) {
    super.didUpdateWidget(alt);
    if (alt.body != widget.body || alt.heading != widget.heading) {
      _lesen();
      _zeit.duration = _dauer;
    }
    if (widget.sofort) {
      _zeit.value = 1;
    } else if (widget.aktiv && !alt.aktiv && !_zeit.isCompleted) {
      _zeit.forward();
    }
  }

  @override
  void dispose() {
    Silbentrennung.deutsch.removeListener(_neuGetrennt);
    _zeit.dispose();
    super.dispose();
  }

  void _neuGetrennt() {
    if (mounted) setState(() {});
  }

  void _lesen() {
    _absaetze = Lesetext.aus(widget.body);
    _woerter = 0;
    for (final absatz in _absaetze) {
      for (final lauf in absatz.laeufe) {
        _woerter += _worteIn(
          lauf.text,
        ).where((w) => w.trim().isNotEmpty).length;
      }
    }
  }

  Duration get _dauer =>
      SchreibText.ueberschrift +
      SchreibText.jeWort * (_woerter + SchreibText.einblenden.ceil());

  /// Wie weit geschrieben ist, in Wörtern; vor dem ersten Wort negativ.
  double get _stand {
    final ms = _zeit.value * _dauer.inMilliseconds;
    return (ms - SchreibText.ueberschrift.inMilliseconds) /
        SchreibText.jeWort.inMilliseconds;
  }

  double get _ueberschriftStand =>
      (_zeit.value *
              _dauer.inMilliseconds /
              SchreibText.ueberschrift.inMilliseconds)
          .clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _zeit.value = 1,
      child: AnimatedBuilder(
        animation: _zeit,
        builder: (context, _) => _bild(),
      ),
    );
  }

  Widget _bild() {
    final stand = _stand;
    final oben = Curves.easeOutCubic.transform(_ueberschriftStand);
    final akzent = SeitenFarbe.of(context);
    final trennung = Silbentrennung.deutsch.value;
    var wort = 0;
    var abbildung = widget.ersteAbbildung;
    var initialeOffen = true;

    final kinder = <Widget>[
      Opacity(
        opacity: oben,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - oben)),
          child: Text(widget.heading, style: BuchStil.titel),
        ),
      ),
      const SizedBox(height: 16),
    ];

    /// Die Wörter eines Absatzes als Stücke, jedes mit seiner Deckkraft.
    /// Getrennt wird nur im Blocksatz — eine zentrierte Unterschrift
    /// bräche sonst ohne Strich um.
    List<SatzStueck> stuecke(
      Absatz absatz, {
      TextStyle? basis,
      bool trennen = true,
    }) {
      final liste = <SatzStueck>[];
      for (final lauf in absatz.laeufe) {
        for (final stueck in _worteIn(lauf.text)) {
          final leer = stueck.trim().isEmpty;
          final sicht = leer ? 1.0 : _sicht(stand, wort);
          final text = leer || trennung == null || !trennen
              ? stueck
              : trennung.trenne(stueck);
          liste.add(SatzStueck(text, _stil(lauf, sicht, basis: basis)));
          if (!leer) wort++;
        }
      }
      return liste;
    }

    for (final absatz in _absaetze) {
      final erstes = wort;
      switch (absatz) {
        case Fliesstext():
          final teile = stuecke(absatz);
          Text? initiale;
          if (initialeOffen) {
            initialeOffen = false;
            initiale = _initiale(teile, akzent);
          }
          kinder.add(
            Blocksatz(
              stuecke: teile,
              initiale: initiale,
              semantik: absatz.klartext,
            ),
          );
        case Kasten():
          kinder.add(
            _Merkkasten(
              sichtbar: stand >= erstes,
              label: absatz.label,
              titel: absatz.titel,
              akzent: akzent,
              child: Blocksatz(
                stuecke: stuecke(absatz),
                semantik: absatz.klartext,
              ),
            ),
          );
        case Abbildung():
          final nummer = abbildung++;
          final unterschrift = stuecke(
            absatz,
            basis: BuchStil.unterschrift,
            trennen: false,
          );
          kinder.add(
            _Abbildung(
              pfad: absatz.pfad,
              sichtbar: stand >= erstes,
              unterschrift: TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: 'Abb. $nummer: ',
                    style: BuchStil.unterschrift.copyWith(
                      color: _mitSicht(
                        BuchStil.tinteBlass,
                        _sicht(stand, erstes),
                      ),
                    ),
                  ),
                  for (final s in unterschrift)
                    TextSpan(text: s.text, style: s.stil),
                ],
              ),
            ),
          );
        case Zier():
          kinder.add(_Zier(sichtbar: stand >= erstes));
      }
      kinder.add(const SizedBox(height: BuchStil.absatz));
    }
    // Am Ende des Abschnitts ein Zierelement, wenn alles geschrieben ist.
    kinder.add(_Zier(key: SchreibText.zierKey, sichtbar: stand >= _woerter));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: kinder,
    );
  }

  /// Nimmt den ersten Buchstaben aus dem ersten Wort und gibt ihn als
  /// Initiale zurück — nur, wenn der Absatz mit einem Buchstaben beginnt.
  Text? _initiale(List<SatzStueck> teile, Color akzent) {
    if (teile.isEmpty) return null;
    final erstes = teile.first;
    final ohneStrich = erstes.text.replaceAll(Silbentrennung.weich, '');
    if (ohneStrich.isEmpty ||
        !RegExp(r'\p{L}', unicode: true).hasMatch(ohneStrich[0])) {
      return null;
    }
    // Ein weicher Strich direkt hinter der Initiale fällt mit weg.
    var rest = erstes.text.substring(1);
    if (rest.startsWith(Silbentrennung.weich)) rest = rest.substring(1);
    teile[0] = SatzStueck(rest, erstes.stil);
    final sicht = (erstes.stil.color?.a ?? 1) / BuchStil.tinte.a;
    return Text(
      ohneStrich[0],
      style: BuchStil.initiale.copyWith(color: _mitSicht(akzent, sicht)),
    );
  }

  static double _sicht(double stand, int wort) =>
      ((stand - wort) / SchreibText.einblenden + 1 / 3).clamp(0.0, 1.0);

  static Color _mitSicht(Color farbe, double sicht) =>
      farbe.withValues(alpha: farbe.a * sicht);

  TextStyle _stil(TextLauf lauf, double sicht, {TextStyle? basis}) {
    final grund = basis ?? BuchStil.fliess;
    final farbe = grund.color ?? BuchStil.tinte;
    return grund.copyWith(
      color: _mitSicht(farbe, sicht),
      fontStyle: lauf.kursiv ? FontStyle.italic : grund.fontStyle,
      fontVariations: lauf.betont ? BuchStil.gewicht(700) : null,
    );
  }
}

/// Zerlegt Text in Wörter und die Leerräume dazwischen — beides bleibt
/// erhalten, damit der Satz genau so steht wie im Inhalt.
List<String> _worteIn(String text) =>
    RegExp(r'\s+|[^\s]+').allMatches(text).map((m) => m.group(0)!).toList();

/// Springt auf, sobald sein erstes Wort kommt.
class _Aufspringen extends StatelessWidget {
  const _Aufspringen({required this.sichtbar, required this.child});

  final bool sichtbar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: sichtbar ? 1 : 0.94,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: sichtbar ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        child: child,
      ),
    );
  }
}

/// **Der Merkkasten**: etwas dunkleres Papier, ein dünner Rahmen, links
/// ein Balken in der Farbe der Seite, oben das Label in Kapitälchen —
/// „MERKE“, „DEFINITION“, „BEISPIEL“.
class _Merkkasten extends StatelessWidget {
  const _Merkkasten({
    required this.sichtbar,
    required this.label,
    required this.titel,
    required this.akzent,
    required this.child,
  });

  final bool sichtbar;
  final String label;
  final String? titel;
  final Color akzent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = titel;
    return _Aufspringen(
      sichtbar: sichtbar,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BuchStil.kastenGrund,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: BuchStil.kastenRand, width: 0.8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: akzent, width: 4)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    label.toUpperCase(),
                    style: BuchStil.label.copyWith(color: akzent),
                  ),
                  if (t != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(t, style: BuchStil.titel.copyWith(fontSize: 21)),
                  ],
                  const SizedBox(height: 6),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// **Eine Abbildung**: das Bild im Pixelstil, hart skaliert, darunter
/// „Abb. 1: …“ kursiv.
class _Abbildung extends StatelessWidget {
  const _Abbildung({
    required this.pfad,
    required this.sichtbar,
    required this.unterschrift,
  });

  final String pfad;
  final bool sichtbar;
  final TextSpan unterschrift;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _Aufspringen(
          sichtbar: sichtbar,
          child: PixelArt(
            assetPath: pfad,
            side: SchreibText.abbildungSeite,
            fallback: const SizedBox.square(
              dimension: SchreibText.abbildungSeite,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text.rich(unterschrift, textAlign: TextAlign.center),
      ],
    );
  }
}

/// **Ein Zierelement**: ein Fleuron in der Mitte.
class _Zier extends StatelessWidget {
  const _Zier({required this.sichtbar, super.key});

  final bool sichtbar;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedOpacity(
        opacity: sichtbar ? 1 : 0,
        duration: const Duration(milliseconds: 400),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Center(child: Text(BuchStil.zier, style: BuchStil.zierStil)),
        ),
      ),
    );
  }
}
