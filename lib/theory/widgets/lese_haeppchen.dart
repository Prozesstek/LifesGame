import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory/theory.dart';

import '../../audio/sound_effects.dart';
import 'buch_stil.dart';
import 'schreib_text.dart';
import 'umblaettern.dart';

/// **Die Seite in Häppchen** — ein Abschnitt je Blatt statt einer Wand
/// aus drei.
///
/// Bis zum 18.10. stand alles untereinander, und wer auf dem Handy die
/// Seite öffnete, sah zuerst, wie lang sie ist. **Seit dem 23.10. ein
/// Buch** ([Umblaettern]), **seit dem 03.11. ein ganzes**: Es liegt
/// geschlossen da und schlägt seinen Deckel auf, geblättert wird mit dem
/// Finger oder am Eselsohr, und am Rand
/// sieht man, wie viel gelesen ist und wie viel noch kommt.
/// **Seit dem 12.11. eine Seite aus einem Lernbuch** ([BuchStil]):
/// Kolumnentitel oben, Seitenzahl „— 1 —“ unten auf dem Blatt; die
/// Zeile „1 / 3“ unter dem Buch ist weg. Einen Knopf
/// „Weiter“ gibt es nicht mehr. Über die letzte Seite hinaus klappt das
/// Buch zu, dann kommt [onStart]. Der Text schreibt sich weiter Wort für
/// Wort, sobald das Blatt liegt und das Buch offen ist.
class LeseHaeppchen extends ConsumerStatefulWidget {
  const LeseHaeppchen({
    required this.lesson,
    required this.onStart,
    this.zeichen,
    super.key,
  });

  final Lesson lesson;
  final VoidCallback onStart;

  /// Das Zeichen auf dem Deckel — das des Gebiets.
  final IconData? zeichen;

  /// Wie lange der Deckel zum Auf- und Zuklappen braucht.
  static const Duration deckel = Duration(milliseconds: 900);

  static const Key seitenKey = ValueKey<String>('buch-seitenzahl');

  @override
  ConsumerState<LeseHaeppchen> createState() => LeseHaeppchenState();
}

class LeseHaeppchenState extends ConsumerState<LeseHaeppchen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<UmblaetternState> _buch = GlobalKey<UmblaetternState>();

  /// Der weiteste Abschnitt, der schon zu sehen war. Was davor liegt, ist
  /// gelesen und schreibt sich beim Zurückblättern nicht noch einmal.
  int _weitester = 0;

  /// 0 liegt der Deckel zu, 1 ist das Buch offen. In `initState`
  /// angelegt, nicht faul (`gotchas.md`).
  late final AnimationController _deckel;
  bool _schliesst = false;

  Lesson get _lesson => widget.lesson;

  /// Ohne Abschnitt bleibt eine Seite mit der Zusammenfassung.
  int get _anzahl => _lesson.sections.isEmpty ? 1 : _lesson.sections.length;

  bool get _offen => _deckel.isCompleted;

  @override
  void initState() {
    super.initState();
    _deckel = AnimationController(vsync: this, duration: LeseHaeppchen.deckel)
      ..addStatusListener((_) {
        if (mounted) setState(() {});
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_deckel.value > 0 || _deckel.isAnimating || _schliesst) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _deckel.value = 1;
    } else {
      _rascheln();
      _deckel.forward();
    }
  }

  @override
  void dispose() {
    _deckel.dispose();
    super.dispose();
  }

  /// **Klappt das Buch zu**, dann kommt [danach] — beim Zurück und am
  /// Ende der letzten Seite.
  Future<void> schliessen(VoidCallback danach) async {
    if (_schliesst) return;
    setState(() => _schliesst = true);
    _rascheln();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _deckel.value = 0;
    } else {
      await _deckel.reverse();
    }
    if (mounted) danach();
  }

  void _rascheln() {
    ref.read(soundPlayerProvider).play(SoundEffect.blaettern);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: AnimatedBuilder(
              animation: _deckel,
              builder: (context, buch) {
                final t = Curves.easeInOutCubic.transform(_deckel.value);
                return Transform.scale(
                  // Geschlossen liegt es etwas kleiner da.
                  scale: 0.9 + 0.1 * t,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ?buch,
                      if (t < 1)
                        _Deckel(winkel: t * math.pi / 2, widget: widget),
                    ],
                  ),
                );
              },
              child: Umblaettern(
                key: _buch,
                anzahl: _anzahl,
                onRascheln: _rascheln,
                onSchluss: () => schliessen(widget.onStart),
                onGeblaettert: (i) => setState(() {
                  if (i > _weitester) _weitester = i;
                }),
                seite: (context, i, aktiv) => _Abschnitt(
                  kolumnentitel: _kolumnentitel(i),
                  zusammenfassung: _lesson.sections.isEmpty
                      ? _lesson.summary
                      : null,
                  abschnitt: i < _lesson.sections.length
                      ? _lesson.sections[i]
                      : null,
                  ersteAbbildung: _ersteAbbildung(i),
                  seite: i,
                  anzahl: _anzahl,
                  oben: aktiv,
                  aktiv: aktiv && _offen,
                  gelesen: i < _weitester,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  /// „KAPITEL 2 · KRAFT & MUSKULATUR“ — ein Abschnitt ist ein Kapitel,
  /// das Thema ist die Lektion.
  String _kolumnentitel(int i) =>
      'Kapitel ${i + 1} · ${_lesson.title}'.toUpperCase();

  /// Die Abbildungen zählen über die ganze Lektion.
  int _ersteAbbildung(int i) {
    var nummer = 1;
    for (var k = 0; k < i && k < _lesson.sections.length; k++) {
      nummer += Lesetext.aus(
        _lesson.sections[k].body,
      ).whereType<Abbildung>().length;
    }
    return nummer;
  }
}

/// Der Deckel, der sich am Rücken öffnet oder schließt.
class _Deckel extends StatelessWidget {
  const _Deckel({required this.winkel, required this.widget});

  final double winkel;
  final LeseHaeppchen widget;

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, Umblaettern.tiefe)
      ..rotateY(winkel);
    return IgnorePointer(
      child: Transform(
        alignment: Alignment.centerLeft,
        transform: matrix,
        child: BuchDeckel(titel: widget.lesson.title, zeichen: widget.zeichen),
      ),
    );
  }
}

/// **Eine Seite im Buch**: oben der Kolumnentitel mit feiner Linie,
/// darunter der Abschnitt, unten die Seitenzahl „— 1 —“. Die Ränder
/// stehen in [BuchStil]: innen an der Bindung schmaler als außen.
class _Abschnitt extends StatelessWidget {
  const _Abschnitt({
    required this.kolumnentitel,
    required this.zusammenfassung,
    required this.abschnitt,
    required this.ersteAbbildung,
    required this.seite,
    required this.anzahl,
    required this.oben,
    required this.aktiv,
    required this.gelesen,
  });

  final String kolumnentitel;
  final String? zusammenfassung;
  final LessonSection? abschnitt;
  final int ersteAbbildung;
  final int seite;
  final int anzahl;

  /// Liegt oben — nur dann trägt die Seitenzahl ihren Schlüssel.
  final bool oben;
  final bool aktiv;
  final bool gelesen;

  @override
  Widget build(BuildContext context) {
    final rest = zusammenfassung;
    final teil = abschnitt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BuchStil.randInnen,
        BuchStil.randOben,
        BuchStil.randAussen,
        BuchStil.randUnten,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Kolumnentitel(kolumnentitel),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: <Widget>[
                if (rest != null) Text(rest, style: BuchStil.fliess),
                if (teil != null)
                  SchreibText(
                    heading: teil.heading,
                    body: teil.body,
                    ersteAbbildung: ersteAbbildung,
                    aktiv: aktiv,
                    sofort: gelesen,
                  ),
              ],
            ),
          ),
          Semantics(
            label: 'Seite ${seite + 1} von $anzahl, zum Blättern wischen',
            excludeSemantics: true,
            child: Text(
              '— ${seite + 1} —',
              key: oben ? LeseHaeppchen.seitenKey : null,
              textAlign: TextAlign.center,
              style: BuchStil.seitenzahl,
            ),
          ),
        ],
      ),
    );
  }
}

/// **Der Kolumnentitel**: klein, gesperrt, in Versalien, gedämpft, mit
/// einer feinen Linie darunter.
class _Kolumnentitel extends StatelessWidget {
  const _Kolumnentitel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: BuchStil.kolumnentitel,
        ),
        const SizedBox(height: 6),
        const Divider(height: 1, thickness: 0.6, color: BuchStil.tinteBlass),
      ],
    );
  }
}
