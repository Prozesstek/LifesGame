import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/palette.dart';

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
class LeseHaeppchen extends StatefulWidget {
  const LeseHaeppchen({required this.lesson, required this.onStart, super.key});

  final Lesson lesson;
  final VoidCallback onStart;

  static const Duration schieben = Duration(milliseconds: 300);

  @override
  State<LeseHaeppchen> createState() => _LeseHaeppchenState();
}

class _LeseHaeppchenState extends State<LeseHaeppchen> {
  late final PageController _seiten;
  int _hier = 0;

  Lesson get _lesson => widget.lesson;

  /// Ohne Abschnitt bleibt eine Seite mit der Zusammenfassung.
  int get _anzahl => _lesson.sections.isEmpty ? 1 : _lesson.sections.length;

  bool get _amEnde => _hier >= _anzahl - 1;

  @override
  void initState() {
    super.initState();
    _seiten = PageController();
  }

  @override
  void dispose() {
    _seiten.dispose();
    super.dispose();
  }

  void _weiter() {
    if (_amEnde) {
      widget.onStart();
      return;
    }
    _seiten.nextPage(
      duration: LeseHaeppchen.schieben,
      curve: Curves.easeOutCubic,
    );
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
          child: PageView.builder(
            controller: _seiten,
            itemCount: _anzahl,
            onPageChanged: (i) => setState(() => _hier = i),
            itemBuilder: (context, i) => _Abschnitt(
              zusammenfassung: i == 0 ? _lesson.summary : null,
              abschnitt: i < _lesson.sections.length
                  ? _lesson.sections[i]
                  : null,
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
  const _Abschnitt({required this.zusammenfassung, required this.abschnitt});

  final String? zusammenfassung;
  final LessonSection? abschnitt;

  @override
  Widget build(BuildContext context) {
    final oben = zusammenfassung;
    final teil = abschnitt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
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
        if (teil != null) ...<Widget>[
          Text(
            teil.heading,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(teil.body, style: const TextStyle(fontSize: 16, height: 1.55)),
        ],
      ],
    );
  }
}
