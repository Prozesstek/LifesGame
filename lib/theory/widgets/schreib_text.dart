import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/palette.dart';
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
/// Gesetzt wird in drei Größen: der **erste Satz** groß, der Rest
/// gewöhnlich, ein **Merksatz** am größten auf eigener Fläche. Betont ist,
/// was im Inhalt in `**` steht (`Lesetext`).
class SchreibText extends StatefulWidget {
  const SchreibText({
    required this.heading,
    required this.body,
    this.aktiv = true,
    this.sofort = false,
    super.key,
  });

  final String heading;
  final String body;

  /// Ob der Abschnitt zu sehen ist. Erst dann beginnt er zu schreiben —
  /// der `PageView` baut die Nachbarseite schon beim Wischen.
  final bool aktiv;

  /// Ganz zeigen, ohne zu schreiben: schon gelesen.
  final bool sofort;

  /// So lange braucht ein Wort.
  static const Duration jeWort = Duration(milliseconds: 40);

  /// So lange fällt die Überschrift herein, bevor das erste Wort kommt.
  static const Duration ueberschrift = Duration(milliseconds: 280);

  /// Wie lange ein Wort vom Unsichtbaren ins Volle braucht, in Wörtern.
  static const double einblenden = 3;

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
    _zeit.dispose();
    super.dispose();
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
    var wort = 0;
    var ersterSatzOffen = true;
    final kinder = <Widget>[
      Opacity(
        opacity: oben,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - oben)),
          child: Text(
            widget.heading,
            style: const TextStyle(
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: Palette.text,
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
    ];

    for (final absatz in _absaetze) {
      final erstes = wort;
      final spans = <InlineSpan>[];
      for (final lauf in absatz.laeufe) {
        for (final stueck in _worteIn(lauf.text)) {
          final leer = stueck.trim().isEmpty;
          final sicht = leer
              ? 1.0
              : ((stand - wort) / SchreibText.einblenden + 1 / 3).clamp(
                  0.0,
                  1.0,
                );
          final gross = absatz is Fliesstext && ersterSatzOffen;
          spans.add(
            TextSpan(
              text: stueck,
              style: _stil(
                betont: lauf.betont,
                gross: gross,
                merksatz: absatz is Merksatz,
                sicht: sicht,
              ),
            ),
          );
          if (!leer) wort++;
          if (gross && _endetSatz(stueck)) ersterSatzOffen = false;
        }
      }
      kinder.add(switch (absatz) {
        Merksatz() => _MerksatzFlaeche(
          sichtbar: stand >= erstes,
          child: Text.rich(TextSpan(children: spans)),
        ),
        Fliesstext() => Text.rich(TextSpan(children: spans)),
      });
      kinder.add(const SizedBox(height: 14));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: kinder,
    );
  }

  TextStyle _stil({
    required bool betont,
    required bool gross,
    required bool merksatz,
    required double sicht,
  }) {
    final farbe = betont ? SeitenFarbe.of(context) : Palette.text;
    return TextStyle(
      fontSize: merksatz ? 20 : (gross ? 18 : 16),
      height: merksatz ? 1.35 : 1.55,
      fontWeight: merksatz || betont
          ? FontWeight.w700
          : (gross ? FontWeight.w600 : FontWeight.w400),
      color: farbe.withValues(alpha: farbe.a * sicht),
    );
  }
}

/// Zerlegt Text in Wörter und die Leerräume dazwischen — beides bleibt
/// erhalten, damit der Satz genau so steht wie im Inhalt.
List<String> _worteIn(String text) =>
    RegExp(r'\s+|[^\s]+').allMatches(text).map((m) => m.group(0)!).toList();

/// Endet hier ein Satz? Ein Punkt hinter einer Abkürzung („z.“, „ca.“)
/// zählt nicht, sonst wäre der erste Satz oft nur zwei Wörter lang. Ein
/// Punkt allein schon — er folgt einem betonten Wort („**Spannung**.“).
bool _endetSatz(String wort) {
  final w = wort.trim();
  if (w.endsWith('!') || w.endsWith('?')) return true;
  if (!w.endsWith('.')) return false;
  return !_abkuerzungen.contains(w.substring(0, w.length - 1));
}

const Set<String> _abkuerzungen = <String>{
  'z', 'B', 'ca', 'bzw', 'd', 'h', 'u', 'a', 'ggf', 'evtl', 'inkl', //
  'vgl', 'Nr', 'S', 'etc',
};

/// Die Fläche eines Merksatzes: springt auf, sobald sein erstes Wort
/// kommt, mit einem Balken in der Farbe der Seite ([SeitenFarbe]).
class _MerksatzFlaeche extends StatelessWidget {
  const _MerksatzFlaeche({required this.sichtbar, required this.child});

  final bool sichtbar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: sichtbar ? 1 : 0.92,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: sichtbar ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Palette.surfaceRaised,
            border: Border(
              left: BorderSide(color: SeitenFarbe.of(context), width: 5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
            child: child,
          ),
        ),
      ),
    );
  }
}
