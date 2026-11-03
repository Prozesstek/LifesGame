import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory/theory.dart';

import '../../audio/sound_effects.dart';
import '../../ui/palette.dart';
import 'schreib_text.dart';
import 'umblaettern.dart';

/// **Die Seite in Häppchen** — ein Abschnitt je Blatt statt einer Wand
/// aus drei.
///
/// Bis zum 18.10. stand alles untereinander, und wer auf dem Handy die
/// Seite öffnete, sah zuerst, wie lang sie ist. **Seit dem 23.10. ein
/// Buch** ([Umblaettern]), **seit dem 03.11. ein ganzes**: Es liegt
/// geschlossen da und schlägt seinen Deckel auf, geblättert wird mit dem
/// Finger oder am Eselsohr, unter dem Buch steht „1 / 3“, und am Rand
/// sieht man, wie viel gelesen ist und wie viel noch kommt. Einen Knopf
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
  int _hier = 0;

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
                  _hier = i;
                  if (i > _weitester) _weitester = i;
                }),
                seite: (context, i, aktiv) => _Abschnitt(
                  zusammenfassung: i == 0 ? _lesson.summary : null,
                  abschnitt: i < _lesson.sections.length
                      ? _lesson.sections[i]
                      : null,
                  aktiv: aktiv && _offen,
                  gelesen: i < _weitester,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
          child: _Seitenzahl(hier: _hier, anzahl: _anzahl),
        ),
      ],
    );
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

/// **Wo man ist, unter dem Buch**: „1 / 3“, daneben ein Zeichen, dass
/// sich wischen lässt.
class _Seitenzahl extends StatelessWidget {
  const _Seitenzahl({required this.hier, required this.anzahl});

  final int hier;
  final int anzahl;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Seite ${hier + 1} von $anzahl, zum Blättern wischen',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.swipe_left_rounded,
            size: 20,
            color: Palette.textOnDarkDim,
          ),
          const SizedBox(width: 10),
          Text(
            '${hier + 1} / $anzahl',
            key: LeseHaeppchen.seitenKey,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Palette.textOnDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _Abschnitt extends StatelessWidget {
  const _Abschnitt({
    required this.zusammenfassung,
    required this.abschnitt,
    required this.aktiv,
    required this.gelesen,
  });

  final String? zusammenfassung;
  final LessonSection? abschnitt;
  final bool aktiv;
  final bool gelesen;

  @override
  Widget build(BuildContext context) {
    final oben = zusammenfassung;
    final teil = abschnitt;
    return ListView(
      // Links weicht der Text der Falz aus, rechts dem Stapel.
      padding: const EdgeInsets.fromLTRB(BuchPapier.falz + 6, 18, 18, 20),
      children: <Widget>[
        if (oben != null) ...<Widget>[
          Text(
            oben,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Palette.textDim,
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (teil != null)
          SchreibText(
            heading: teil.heading,
            body: teil.body,
            aktiv: aktiv,
            sofort: gelesen,
          ),
      ],
    );
  }
}
