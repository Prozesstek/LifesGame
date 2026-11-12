import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';
import 'package:theory/theory.dart';

import '../../combat/ladder_controller.dart';
import '../../habits/habits_controller.dart';
import '../../home/erster_start_provider.dart';
import '../../skills/gebiet_farbe.dart';
import '../../ui/aufstieg.dart';
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
///
/// **In der Theorie als Dialog** ([alsDialog], 11.11.2026, Frederik:
/// „Rückfrage öffnet sich mittig wenn man Theorie öffnet – verschwindet
/// dann komplett“): Offen kommt sie beim Betreten groß in die Mitte.
/// Beantwortet steht oben nichts mehr; wer sie vorher wegtippt, findet
/// sie als Zeile, die sie wieder öffnet. Am Lagerfeuer bleibt sie die
/// Karte, die aufklappt.
class ReviewSection extends ConsumerStatefulWidget {
  const ReviewSection({this.alsDialog = false, super.key});

  final bool alsDialog;

  /// Findet den Dialog in Tests.
  static const Key dialogKey = Key('rueckfrage-dialog');

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
    final offen =
        ref.read(todaysReviewProvider) != null &&
        ref.read(todaysReviewAnswerProvider) == null;
    _aufgeklappt = !widget.alsDialog && offen;
    // **Nicht mitten im Tutorial**: Fällig ist sie schon am Tag der ersten
    // Seite, und der Mentor führt dann gerade woandershin. Dort steht nur
    // die Zeile.
    final tutorial = ref.read(ersterStartProvider).schritt != null;
    if (widget.alsDialog && offen && !tutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _zeigeDialog();
      });
    }
  }

  Future<void> _zeigeDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        key: ReviewSection.dialogKey,
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        // Erfahrung und Gold steigen im Dialog auf, wo getippt wurde.
        child: AufstiegHost(
          child: _ImDialog(onZu: () => Navigator.of(dialogContext).pop()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frage = ref.watch(todaysReviewProvider);
    if (frage == null) return const SizedBox.shrink();
    final antwort = ref.watch(todaysReviewAnswerProvider);
    if (widget.alsDialog) {
      // Beantwortet: weg. Offen: eine Zeile, die den Dialog wieder öffnet.
      if (antwort != null) return const SizedBox.shrink();
      return _Zeile(
        richtig: null,
        offenFarbe: _offenFarbe(frage),
        tage: null,
        onTap: () => unawaited(_zeigeDialog()),
      );
    }
    final today = ref.watch(todayProvider);

    if (!_aufgeklappt) {
      return _Zeile(
        richtig: antwort?.correct,
        offenFarbe: _offenFarbe(frage),
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
      child: _karte(
        context,
        ref,
        frage,
        antwort,
        today,
        onZu: () {
          setState(() => _aufgeklappt = false);
        },
      ),
    );
  }

  Color _offenFarbe(ReviewQuestion frage) {
    final gebiet = _gebiet(ref, frage);
    return gebiet == null ? Palette.accentOnDark : GebietFarbe.leder(gebiet);
  }
}

/// Die Rückfrage stammt von einer Seite und trägt deren Farbe.
SkillArea? _gebiet(WidgetRef ref, ReviewQuestion frage) =>
    gebietDerSeite(ref.watch(theoryGraphProvider), frage.lesson.id);

Widget _karte(
  BuildContext context,
  WidgetRef ref,
  ReviewQuestion frage,
  ReviewAnswer? antwort,
  Day today, {
  required VoidCallback onZu,
  IconData zuZeichen = Icons.expand_less,
}) {
  final gebiet = _gebiet(ref, frage);
  return ReviewCard(
    question: frage,
    farbe: gebiet == null ? Palette.accent : GebietFarbe.pergament(gebiet),
    answer: antwort,
    day: dayNumberOf(today),
    daysUntilNext: daysUntilReview(ref, frage, today),
    onAnswer: (wahl) => answerReview(context, ref, frage, wahl),
    onZuklappen: onZu,
    zuklappenZeichen: zuZeichen,
  );
}

/// Die Karte im Dialog: Nach der Antwort bleibt die Auflösung stehen, ein
/// Tipp schließt.
class _ImDialog extends ConsumerWidget {
  const _ImDialog({required this.onZu});

  final VoidCallback onZu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frage = ref.watch(todaysReviewProvider);
    if (frage == null) return const SizedBox.shrink();
    final antwort = ref.watch(todaysReviewAnswerProvider);
    // Die Holzkarte füllt jede Höhe, die man ihr gibt; die Rolle gibt ihr
    // keine, und so ist sie nur so hoch wie ihre Frage.
    return SingleChildScrollView(
      child: GestureDetector(
        onTap: antwort == null ? null : onZu,
        child: _karte(
          context,
          ref,
          frage,
          antwort,
          ref.watch(todayProvider),
          onZu: onZu,
          zuZeichen: Icons.close_rounded,
        ),
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
