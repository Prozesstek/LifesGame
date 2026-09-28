import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory/theory.dart';

import '../../combat/ladder_controller.dart';
import '../../habits/habits_controller.dart';
import '../../ui/druck.dart';
import '../../ui/palette.dart';
import '../review_controller.dart';
import '../review_flow.dart';
import 'review_card.dart';

/// Die Rückfrage des Tages oben in der Theorie (Issue #88).
///
/// **Sie beginnt als eine Zeile**, offen oder beantwortet. Aufgeklappt
/// nähme die Karte mit Frage und vier Antworten auf dem Handy rund ein
/// Drittel der Höhe, und der Baum darunter wäre kaum noch zu bedienen
/// (`phone_layout_test.dart`). Ein Tipp klappt sie auf; nach der Antwort
/// bleibt die Auflösung stehen, bis man sie zutippt oder geht. Ohne
/// fällige Frage steht hier nichts.
class ReviewSection extends ConsumerStatefulWidget {
  const ReviewSection({super.key});

  @override
  ConsumerState<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends ConsumerState<ReviewSection> {
  bool _aufgeklappt = false;

  @override
  Widget build(BuildContext context) {
    final frage = ref.watch(todaysReviewProvider);
    if (frage == null) return const SizedBox.shrink();
    final antwort = ref.watch(todaysReviewAnswerProvider);
    final today = ref.watch(todayProvider);

    if (!_aufgeklappt) {
      return _Zeile(
        richtig: antwort?.correct,
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
        answer: antwort,
        day: dayNumberOf(today),
        daysUntilNext: daysUntilReview(ref, frage, today),
        onAnswer: (wahl) => answerReview(context, ref, frage, wahl),
      ),
    );
  }
}

/// Die Rückfrage als eine Zeile auf dem Leder: offen hervorgehoben,
/// beantwortet leise.
class _Zeile extends StatelessWidget {
  const _Zeile({
    required this.richtig,
    required this.tage,
    required this.onTap,
  });

  /// Null, solange offen.
  final bool? richtig;
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
    final farbe = offen ? Palette.accentOnDark : Palette.textOnDarkDim;

    return Druck(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: <Widget>[
              Icon(
                richtig == true ? Icons.check_circle : Icons.menu_book,
                size: 16,
                color: richtig == true ? Palette.successOnDark : farbe,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: offen ? FontWeight.bold : FontWeight.normal,
                    color: farbe,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more, size: 16, color: farbe),
            ],
          ),
        ),
      ),
    );
  }
}
