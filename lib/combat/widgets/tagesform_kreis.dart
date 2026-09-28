import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../habits/daily_form_text.dart';
import '../../habits/habits_controller.dart';
import '../../habits/widgets/daily_form_card.dart';
import '../../ui/druck.dart';
import '../../ui/palette.dart';

/// **Die Tagesform als Blitz, der sich auflädt** — am Eingang der Grube
/// (Issue #88).
///
/// Bis zum 28.09. stand sie als Karte über der Tagesliste. Dort war sie
/// ein Satz über den Kampf an einem Ort ohne Kampf. Hier steht sie, wo sie
/// wirkt: Der Ring füllt sich mit jedem Häkchen, voll heisst „In Form“.
/// Ein Tipp zeigt, was sie genau bringt.
class TagesformKreis extends ConsumerWidget {
  const TagesformKreis({super.key});

  static const double seite = 44;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(dailyFormProvider);
    final tracker = ref.watch(habitTrackerProvider);
    final today = ref.watch(todayProvider);
    final laufend = tracker.dailyListOn(today).length;
    final erledigt = tracker.completedOn(today);
    final anteil = form.isInForm
        ? 1.0
        : laufend == 0
        ? 0.0
        : erledigt / laufend;
    final summe = DailyFormText.summary(form);

    return Semantics(
      button: true,
      label: 'Tagesform: ${summe ?? 'noch nichts'}',
      excludeSemantics: true,
      child: Druck(
        child: InkWell(
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: DailyFormCard(form: form, open: laufend - erledigt),
            ),
          ),
          borderRadius: BorderRadius.circular(seite),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox.square(
                  dimension: seite,
                  child: CustomPaint(
                    painter: _Ring(anteil: anteil, voll: form.isInForm),
                    child: Icon(
                      form.isInForm ? Icons.local_fire_department : Icons.bolt,
                      size: 22,
                      color: anteil == 0
                          ? Palette.textOnDarkDim
                          : Palette.goldOnDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    summe ?? 'Tagesform leer',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: summe == null
                          ? Palette.textOnDarkDim
                          : Palette.goldOnDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Ring extends CustomPainter {
  const _Ring({required this.anteil, required this.voll});

  final double anteil;
  final bool voll;

  @override
  void paint(Canvas canvas, Size size) {
    const breite = 4.0;
    final rect = (Offset.zero & size).deflate(breite / 2);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = breite
        ..color = Palette.trackOnDark,
    );
    if (anteil <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * anteil.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = breite
        ..strokeCap = StrokeCap.round
        ..color = voll ? Palette.accentOnDark : Palette.goldOnDark,
    );
  }

  @override
  bool shouldRepaint(_Ring old) => old.anteil != anteil || old.voll != voll;
}
