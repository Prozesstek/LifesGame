import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/palette.dart';
import '../../ui/holz.dart';
import '../../ui/pixel_art.dart';
import '../../ui/sprung.dart';
import '../../gear/gear_icon.dart';
import 'tree_overview.dart';

/// Was nach der letzten Frage steht: Ergebnis, Ertrag, nächster Schritt.
///
/// **Es baut sich auf** (18.10.): Das Zeichen springt, Erfahrung und
/// Gold zählen von null hoch, und erst danach kommen die Knöpfe. Ist
/// nichts zu zählen, stehen sie sofort da. [onGezaehlt] meldet das Ende
/// des Zählens — die Feiern warten darauf, sonst deckte ein Aufstieg die
/// Zahl zu, die ihn gebracht hat.
class LessonResultView extends StatelessWidget {
  const LessonResultView({
    required this.lesson,
    required this.result,
    required this.onRetry,
    required this.onDone,
    this.keyGained = false,
    this.next,
    this.onNext,
    this.onGezaehlt,
    super.key,
  });

  /// Wie lange Erfahrung und Gold hochzählen.
  static const Duration zaehlen = Duration(milliseconds: 900);

  final Lesson lesson;
  final LessonResult result;
  final VoidCallback onRetry;
  final VoidCallback onDone;

  /// Die Seite danach (ADR-0070), oder null. Mit ihr wird sie der
  /// Hauptknopf, und [onDone] heißt „Fertig“.
  final TheoryStep? next;
  final VoidCallback? onNext;

  /// Woran Tests die beiden Knöpfe finden.
  static const Key nextKey = ValueKey<String>('seite-weiter');
  static const Key doneKey = ValueKey<String>('seite-fertig');

  /// Ob die Seite einen Schlüssel gebracht hat (ADR-0048).
  final bool keyGained;

  /// Erfahrung und Gold sind fertig gezählt. Kommt nur, wenn es etwas zu
  /// zählen gibt.
  final VoidCallback? onGezaehlt;

  bool get _zaehlt => result.xpGained > 0 || result.goldGained > 0;

  @override
  Widget build(BuildContext context) {
    final passed = result.isPassed;
    final color = passed ? Palette.success : Palette.enemy;
    final weiter = next;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: <Widget>[
        _Aufspringen(
          child: Icon(
            passed ? Icons.verified_outlined : Icons.replay_circle_filled,
            size: 52,
            color: color,
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            passed ? 'Bestanden' : 'Noch nicht bestanden',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '${result.correct} von ${result.total} Fragen richtig',
            style: const TextStyle(fontSize: 14, color: Palette.textDim),
          ),
        ),
        const SizedBox(height: 24),
        if (_zaehlt)
          _Earnings(
            xp: result.xpGained,
            gold: result.goldGained,
            onGezaehlt: onGezaehlt,
          ),
        if (keyGained) ...<Widget>[
          const SizedBox(height: 10),
          const _Schluessel(),
        ] else
          _Note(
            text: passed
                ? 'Diese Lektion war schon bestanden — es gibt nichts '
                      'doppelt. Ein besseres Ergebnis zahlt die Differenz.'
                : 'Ab ${TheoryRewards.passPercent} % richtiger Antworten '
                      'gibt es Erfahrung und Gold.',
          ),
        if (passed && lesson.unlocksHabit != null) ...<Widget>[
          const SizedBox(height: 12),
          _HabitUnlock(habit: lesson.unlocksHabit ?? ''),
        ],
        const SizedBox(height: 28),
        _NachDemZaehlen(
          wartet: _zaehlt,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (weiter != null) ...<Widget>[
                _NaechsteSeite(schritt: weiter, onTap: onNext),
                const SizedBox(height: 8),
                TextButton(
                  key: doneKey,
                  onPressed: onDone,
                  child: const Text('Fertig'),
                ),
              ] else
                FilledButton(
                  key: doneKey,
                  onPressed: onDone,
                  child: const Text('Weiter'),
                ),
              const SizedBox(height: 8),
              if (!result.isPerfect)
                TextButton(
                  onPressed: onRetry,
                  child: Text(passed ? 'Nochmal für alle Punkte' : 'Nochmal'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Das Zeichen oben springt einmal auf, wenn das Ergebnis kommt.
class _Aufspringen extends StatelessWidget {
  const _Aufspringen({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      builder: (context, t, child) =>
          Transform.scale(scale: Sprung.feder(t, von: 0.1), child: child),
      child: child,
    );
  }
}

/// Die Knöpfe kommen, wenn gezählt ist — und lassen sich vorher nicht
/// tippen. Ohne etwas zu zählen sind sie sofort da.
class _NachDemZaehlen extends StatelessWidget {
  const _NachDemZaehlen({required this.wartet, required this.child});

  final bool wartet;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!wartet) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: LessonResultView.zaehlen + const Duration(milliseconds: 250),
      builder: (context, t, child) {
        final sichtbar = Sprung.abschnitt(t, 0.75, 1);
        return IgnorePointer(
          ignoring: t < 1,
          child: Opacity(
            opacity: sichtbar,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - sichtbar)),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// Der Knopf zur nächsten Seite: Pfeil, Name — und der Preis, wenn ihr
/// Knoten noch zu ist. Der Tipp öffnet ihn dann; deshalb steht der Punkt
/// **auf** dem Knopf und nicht daneben.
class _NaechsteSeite extends StatelessWidget {
  const _NaechsteSeite({required this.schritt, required this.onTap});

  final TheoryStep schritt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final node = schritt.node;
    final preis = schritt.needsOpening ? node.cost : null;

    return Semantics(
      button: true,
      label: preis == null
          ? 'Weiter zu ${node.name}'
          : 'Weiter zu ${node.name}, kostet $preis '
                '${preis == 1 ? 'Punkt' : 'Punkte'}',
      excludeSemantics: true,
      child: FilledButton(
        key: LessonResultView.nextKey,
        onPressed: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.arrow_forward_rounded, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                node.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (preis != null) ...<Widget>[
              const SizedBox(width: 10),
              // Auf der Planke, also hell wie ihre Schrift: Das Gold für
              // Pergament ginge im Holz unter.
              PunktPreis(cost: preis, color: Palette.textOnDark),
            ],
          ],
        ),
      ),
    );
  }
}

/// Erfahrung und Gold, von null hochgezählt. **Nur Darstellung**: Gezählt
/// hat der Fortschritt längst, hier steigt dieselbe Zahl.
class _Earnings extends StatelessWidget {
  const _Earnings({required this.xp, required this.gold, this.onGezaehlt});

  final int xp;
  final int gold;
  final VoidCallback? onGezaehlt;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: LessonResultView.zaehlen,
      curve: Curves.easeOutCubic,
      onEnd: onGezaehlt,
      builder: (context, t, _) {
        // Ein Hauch Wachsen, solange gezählt wird — am Ende steht die
        // Zahl wieder still in ihrer Grösse.
        final gross = t >= 1 ? 1.0 : 1 + 0.08 * math.sin(math.pi * t);
        return Transform.scale(
          scale: gross,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (xp > 0)
                _Chip(
                  icon: Icons.auto_graph,
                  label: '+${(xp * t).round()} Erfahrung',
                  color: Palette.accent,
                ),
              if (xp > 0 && gold > 0) const SizedBox(width: 10),
              if (gold > 0)
                _Chip(
                  icon: Icons.savings_outlined,
                  label: '+${(gold * t).round()} Gold',
                  color: Palette.gold,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitUnlock extends StatelessWidget {
  const _HabitUnlock({required this.habit});

  final String habit;

  @override
  Widget build(BuildContext context) {
    return HolzKarte(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.add_task, size: 18, color: Palette.success),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Habit-Vorlage freigeschaltet',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  habit,
                  style: const TextStyle(fontSize: 13, color: Palette.textDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, height: 1.4, color: Palette.muted),
    );
  }
}

/// „+1 Schlüssel", der einmal hineinspringt — ein Wurf mehr für die Beute
/// des Wächters (ADR-0048).
class _Schluessel extends StatelessWidget {
  const _Schluessel();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const PixelArt(
            assetPath: GearIcons.schluessel,
            side: 28,
            fallback: Icon(Icons.key, color: Palette.gold),
          ),
          const SizedBox(width: 6),
          Text(
            '+1 Schlüssel für die Beute',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Palette.gold,
            ),
          ),
        ],
      ),
    );
  }
}
