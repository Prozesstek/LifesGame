import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory/theory.dart';

import '../../audio/sound_effects.dart';
import '../../ui/palette.dart';
import 'schreib_text.dart';
import 'umblaettern.dart';

/// **Die Seite in Häppchen** — ein Abschnitt je Bildschirm statt einer
/// Wand aus drei.
///
/// Oben zeigt eine Reihe aus Strichen, wo man ist; „Weiter“ schiebt zum
/// nächsten Abschnitt, Wischen geht in beide Richtungen. Erst auf dem
/// letzten steht der Knopf zu den Fragen. Der Inhalt ist derselbe wie
/// vorher, die Zusammenfassung steht über dem ersten Abschnitt.
///
/// Bis zum 18.10. stand alles untereinander, und wer auf dem Handy die
/// Seite öffnete, sah zuerst, wie lang sie ist.
///
/// **Seit dem 23.10. ein Buch** (AktivesBrett: „so aussehen als würde
/// man umblättern“): Jeder Abschnitt steht auf einem Blatt Papier mit
/// Falz, und „Weiter“ oder ein Wisch schlägt es am Rücken um, mit einem
/// Rascheln ([Umblaettern]). Auf dem letzten schlägt „Fragen
/// beantworten“ das Blatt auf ein leeres um, dann kommen die Fragen.
/// Der Text schreibt sich weiter Wort für Wort, sobald das Blatt liegt.
class LeseHaeppchen extends ConsumerStatefulWidget {
  const LeseHaeppchen({required this.lesson, required this.onStart, super.key});

  final Lesson lesson;
  final VoidCallback onStart;

  /// Wie schnell die Striche oben nachziehen.
  static const Duration schieben = Duration(milliseconds: 300);

  @override
  ConsumerState<LeseHaeppchen> createState() => _LeseHaeppchenState();
}

class _LeseHaeppchenState extends ConsumerState<LeseHaeppchen> {
  final GlobalKey<UmblaetternState> _buch = GlobalKey<UmblaetternState>();
  int _hier = 0;

  /// Der weiteste Abschnitt, der schon zu sehen war. Was davor liegt, ist
  /// gelesen und schreibt sich beim Zurückblättern nicht noch einmal.
  int _weitester = 0;

  Lesson get _lesson => widget.lesson;

  /// Ohne Abschnitt bleibt eine Seite mit der Zusammenfassung.
  int get _anzahl => _lesson.sections.isEmpty ? 1 : _lesson.sections.length;

  bool get _amEnde => _hier >= _anzahl - 1;

  void _weiter() {
    final buch = _buch.currentState;
    if (buch == null) {
      widget.onStart();
      return;
    }
    buch.vor(schluss: widget.onStart);
  }

  void _rascheln() {
    ref.read(soundPlayerProvider).play(SoundEffect.blaettern);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _Striche(anzahl: _anzahl, hier: _hier),
        ),
        Expanded(
          child: Umblaettern(
            key: _buch,
            anzahl: _anzahl,
            onRascheln: _rascheln,
            onGeblaettert: (i) => setState(() {
              _hier = i;
              if (i > _weitester) _weitester = i;
            }),
            seite: (context, i, aktiv) => _Abschnitt(
              zusammenfassung: i == 0 ? _lesson.summary : null,
              abschnitt: i < _lesson.sections.length
                  ? _lesson.sections[i]
                  : null,
              aktiv: aktiv,
              gelesen: i < _weitester,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _weiter,
              child: Text(
                _amEnde
                    ? '${_lesson.questionCount} Fragen beantworten'
                    : 'Weiter',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Ein Strich je Abschnitt; gelesene und der jetzige sind gefüllt.
class _Striche extends StatelessWidget {
  const _Striche({required this.anzahl, required this.hier});

  final int anzahl;
  final int hier;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Abschnitt ${hier + 1} von $anzahl',
      excludeSemantics: true,
      child: Row(
        children: <Widget>[
          for (var i = 0; i < anzahl; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: LeseHaeppchen.schieben,
                height: 6,
                decoration: BoxDecoration(
                  color: i <= hier ? Palette.accent : Palette.surfaceSunken,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(BuchPapier.falz + 8, 18, 24, 20),
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
