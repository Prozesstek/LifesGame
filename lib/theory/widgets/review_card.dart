import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';

/// **Die Rückfrage des Tages** auf der Tagesliste (ADR-0045).
///
/// Offen: die Frage und ihre Antworten, zum Antippen. Beantwortet: was
/// richtig war, warum, und wann die Seite wiederkommt. Die Regel — welche
/// Frage, welcher Abstand — steht in `package:theory` ([ReviewLog]).
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    required this.question,
    required this.answer,
    required this.day,
    required this.daysUntilNext,
    required this.onAnswer,
    super.key,
  });

  final ReviewQuestion question;

  /// Die Antwort von heute, oder null, solange offen.
  final ReviewAnswer? answer;

  /// Tage seit 1970 — dreht die Reihenfolge der Antworten jeden Tag.
  final int day;

  /// Nach wie vielen Tagen diese Seite wiederkommt, sobald beantwortet.
  final int? daysUntilNext;

  /// Mit dem Index der Antwort **in der Lektion**, nicht auf dem Schirm.
  final ValueChanged<int> onAnswer;

  @override
  Widget build(BuildContext context) {
    final beantwortet = answer;
    final frage = question.question;

    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      edgeColor: switch (beantwortet?.correct) {
        true => Palette.success,
        false => Holz.kante,
        null => Palette.accent,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.menu_book, size: 20, color: Palette.accent),
              const SizedBox(width: 8),
              // Beide Texte schrumpfbar (`gotchas.md`): Der Titel einer
              // Lektion kann lang sein, und die Karte ist schmal.
              const Flexible(
                flex: 3,
                child: Text(
                  'Rückfrage des Tages',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Palette.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Text(
                  question.lesson.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 11, color: Palette.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            frage.prompt,
            style: const TextStyle(fontSize: 14, color: Palette.text),
          ),
          const SizedBox(height: 10),
          if (beantwortet == null)
            for (final i in _reihenfolge(frage.options.length))
              _Antwort(text: frage.options[i], onTap: () => onAnswer(i))
          else
            _Ergebnis(
              richtig: beantwortet.correct,
              loesung: frage.options[frage.correctIndex],
              erklaerung: frage.explanation,
              inTagen: daysUntilNext,
            ),
        ],
      ),
    );
  }

  /// Die Antworten, jeden Tag um eins weitergedreht — sonst merkt man sich
  /// die Stelle statt der Antwort.
  List<int> _reihenfolge(int n) {
    if (n == 0) return const <int>[];
    final versatz = day % n;
    return <int>[for (var i = 0; i < n; i++) (i + versatz) % n];
  }
}

class _Antwort extends StatelessWidget {
  const _Antwort({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Druck(
        child: Material(
          color: Palette.surfaceRaised,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, color: Palette.text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Ergebnis extends StatelessWidget {
  const _Ergebnis({
    required this.richtig,
    required this.loesung,
    required this.erklaerung,
    required this.inTagen,
  });

  final bool richtig;
  final String loesung;
  final String erklaerung;
  final int? inTagen;

  @override
  Widget build(BuildContext context) {
    final tage = inTagen;
    final wieder = richtig
        ? (tage == null
              ? ''
              : ' Diese Seite kommt in $tage '
                    '${tage == 1 ? 'Tag' : 'Tagen'} wieder.')
        : ' Sie kommt morgen wieder.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          richtig
              ? 'Richtig! +${TheoryRewards.xpForReview} Erfahrung · '
                    '+${TheoryRewards.goldForReview} Gold'
              : 'Nicht ganz. Richtig ist: $loesung',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: richtig ? Palette.success : Palette.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$erklaerung$wieder',
          style: const TextStyle(
            fontSize: 12,
            height: 1.4,
            color: Palette.textDim,
          ),
        ),
      ],
    );
  }
}
