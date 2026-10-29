import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory/theory.dart';

import '../../combat/ladder_controller.dart';
import '../../habits/habits_controller.dart';
import '../../skills/gebiet_farbe.dart';
import '../../ui/druck.dart';
import '../../ui/palette.dart';
import '../review_controller.dart';
import '../review_flow.dart';
import '../theory_controller.dart';
import 'review_card.dart';
import '../../ui/gold_icon.dart';

/// Die Rückfrage des Tages oben in der Theorie (Issue #88).
///
/// **Offen steht sie aufgeklappt da** (Frederik, 29.10.): Wer die
/// Theorie betritt, sieht die Frage gleich. Nach der Antwort bleibt die
/// Auflösung stehen, bis man sie zutippt oder geht. Der Pfeil oben rechts
/// klappt sie auch unbeantwortet zu — auf dem Handy nimmt sie offen rund
/// ein Drittel der Höhe, und der Baum darunter wird eng. Beantwortet beginnt
/// sie als eine Zeile, die ein Tipp aufklappt. Ohne fällige Frage steht
/// hier nichts.
class ReviewSection extends ConsumerStatefulWidget {
  const ReviewSection({super.key});

  @override
  ConsumerState<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends ConsumerState<ReviewSection> {
  /// Offen, solange heute nicht geantwortet ist — wer die Theorie
  /// betritt, sieht die Frage gleich. Gelesen wird nur beim Betreten:
  /// Nach der Antwort bleibt die Auflösung stehen.
  late bool _aufgeklappt;

  @override
  void initState() {
    super.initState();
    _aufgeklappt = ref.read(todaysReviewAnswerProvider) == null;
  }

  @override
  Widget build(BuildContext context) {
    final frage = ref.watch(todaysReviewProvider);
    if (frage == null) return const SizedBox.shrink();
    final antwort = ref.watch(todaysReviewAnswerProvider);
    final today = ref.watch(todayProvider);
    // Die Rückfrage stammt von einer Seite und trägt deren Farbe.
    final gebiet = gebietDerSeite(
      ref.watch(theoryGraphProvider),
      frage.lesson.id,
    );

    if (!_aufgeklappt) {
      return _Zeile(
        richtig: antwort?.correct,
        offenFarbe: gebiet == null
            ? Palette.accentOnDark
            : GebietFarbe.leder(gebiet),
        tage: antwort == null ? null : daysUntilReview(ref, frage, today),
        onTap: () => setState(() => _aufgeklappt = true),
      );
    }

    return GestureDetector(
      // Offen lässt sie sich nur schliessen, wenn geantwortet ist — sonst
      // träfe ein Tipp neben die Antworten die Frage weg.
      onTap: antwort == null
          ? null
          : () => setState(() => _aufgeklappt = false),
      child: ReviewCard(
        question: frage,
        farbe: gebiet == null ? Palette.accent : GebietFarbe.pergament(gebiet),
        answer: antwort,
        day: dayNumberOf(today),
        daysUntilNext: daysUntilReview(ref, frage, today),
        onAnswer: (wahl) => answerReview(context, ref, frage, wahl),
        onZuklappen: () => setState(() => _aufgeklappt = false),
      ),
    );
  }
}

/// Die Rückfrage als eine Zeile auf dem Leder: offen hervorgehoben,
/// beantwortet leise.
class _Zeile extends StatelessWidget {
  const _Zeile({
    required this.richtig,
    required this.offenFarbe,
    required this.tage,
    required this.onTap,
  });

  /// Null, solange offen.
  final bool? richtig;

  /// Die Farbe des Gebiets der Seite, solange offen.
  final Color offenFarbe;
  final int? tage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final offen = richtig == null;
    final wann = switch (tage) {
      null => '',
      1 => ' · wieder morgen',
      final int t => ' · wieder in $t Tagen',
    };
    final text = switch (richtig) {
      null =>
        'Rückfrage des Tages · +${TheoryRewards.xpForReview} EP '
            '+${TheoryRewards.goldForReview} G',
      true => 'Rückfrage des Tages: richtig$wann',
      false => 'Rückfrage des Tages: daneben$wann',
    };
    final farbe = offen ? offenFarbe : Palette.textOnDarkDim;
    final stil = TextStyle(
      fontSize: 12,
      fontWeight: offen ? FontWeight.bold : FontWeight.normal,
      color: farbe,
    );

    // Ohne Satz: Offen zeigt sie, was sie bringt; beantwortet, ob es
    // saß und wann sie wiederkommt. Der Satz bleibt für den Vorleser.
    final inhalt = <Widget>[
      if (offen) ...<Widget>[
        Icon(Icons.auto_awesome, size: 13, color: farbe),
        const SizedBox(width: 2),
        Text('+${TheoryRewards.xpForReview}', style: stil),
        const SizedBox(width: 8),
        const GoldIcon(size: 13),
        const SizedBox(width: 2),
        Text('+${TheoryRewards.goldForReview}', style: stil),
      ] else ...<Widget>[
        if (tage case final int t) ...<Widget>[
          Icon(Icons.update_rounded, size: 14, color: farbe),
          const SizedBox(width: 2),
          Text('$t', style: stil),
        ],
      ],
    ];

    return Semantics(
      button: true,
      label: text,
      excludeSemantics: true,
      child: Druck(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: <Widget>[
                Icon(
                  switch (richtig) {
                    null => Icons.quiz_outlined,
                    true => Icons.check_circle,
                    false => Icons.cancel_outlined,
                  },
                  size: 18,
                  color: richtig == true ? Palette.successOnDark : farbe,
                ),
                const SizedBox(width: 8),
                ...inhalt,
                const SizedBox(width: 4),
                Icon(Icons.expand_more, size: 16, color: farbe),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
