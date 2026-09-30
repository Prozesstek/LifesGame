import 'package:flutter/material.dart';

import '../../ui/gold_icon.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';

/// Das Blatt am Ende eines Laufs in der Grube (Frederik, 30.09.) —
/// **Sieg und Niederlage im selben Aufbau.**
///
/// Von oben nach unten, und in dieser Reihenfolge erscheint es auch:
/// „Sieg“ in Grün oder „Niederlage“ in Rot, darunter ruhig die Ebene und
/// die Zeit, dann Erfahrung und Gold nacheinander — sie gleiten herein
/// und blenden von der Farbe der Überschrift in ihre eigene —, zuletzt
/// mittig „Weiter“.
///
/// **Beute auch nach einer Niederlage**, wenn etwas gefallen ist: Ein
/// verlorener Lauf behält sie (ADR-0041), also steht sie auch da. Mehr
/// als der Topf der Stufe ist es nie (`loot_test.dart`). Ein zweiter Sieg
/// bringt nichts (ADR-0032); dann fehlen die Zeilen, und der Tipp auf die
/// Überschrift sagt warum.
class LaufErgebnis extends StatefulWidget {
  const LaufErgebnis({
    required this.won,
    required this.stage,
    required this.seconds,
    this.earnedXp = 0,
    this.earnedGold = 0,
    this.newBest = false,
    this.timedOut = false,
    super.key,
  });

  final bool won;
  final int stage;
  final int seconds;
  final int earnedXp;
  final int earnedGold;

  /// Ob die Zeit eine neue Bestzeit ist — dann steht ein Stern daneben.
  final bool newBest;

  /// Ob die Zeit abgelaufen ist (ADR-0046) — dann trägt die Uhr einen
  /// Strich.
  final bool timedOut;

  /// Woran Tests den Knopf finden.
  static const Key weiterKey = ValueKey<String>('lauf-weiter');

  @override
  State<LaufErgebnis> createState() => _LaufErgebnisState();
}

class _LaufErgebnisState extends State<LaufErgebnis>
    with SingleTickerProviderStateMixin {
  /// Der ganze Ablauf, einmal, dann steht alles still — `pumpAndSettle`
  /// in Tests kommt damit zur Ruhe.
  late final AnimationController _ablauf = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..forward();

  bool get _hatBeute => widget.earnedXp > 0 || widget.earnedGold > 0;

  Color get _farbe => widget.won ? Palette.success : Palette.enemy;

  String get _fussnote {
    if (!widget.won) {
      return _hatBeute
          ? 'Was gefallen ist, bleibt dir. Die Stufe zählt erst mit dem '
                'Wächter.'
          : 'Das kostet nichts außer diesem Lauf. Werte wachsen über '
                'Häkchen und Lektionen, nicht über Siege.';
    }
    return _hatBeute
        ? 'Einmal je Stufe — wer sie noch einmal räumt, bekommt nichts '
              'mehr. Der größere Teil deiner Werte kommt aus Gewohnheiten '
              'und Theorie.'
        : 'Diese Stufe hattest du schon. Erfahrung und Gold gibt es nur '
              'beim ersten Mal.';
  }

  @override
  void dispose() {
    _ablauf.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HolzDialog(
      child: AlertDialog(
        backgroundColor: Palette.surface,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(),
        title: Center(
          child: Tooltip(
            triggerMode: TooltipTriggerMode.tap,
            message: _fussnote,
            child: Text(
              widget.won ? 'Sieg' : 'Niederlage',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: _farbe,
              ),
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Fakten(
              stage: widget.stage,
              seconds: widget.seconds,
              newBest: widget.newBest,
              timedOut: widget.timedOut,
            ),
            if (_hatBeute) ...<Widget>[
              const SizedBox(height: 18),
              _BeuteZeile(
                ablauf: _ablauf,
                beginn: 0.15,
                icon: const Icon(Icons.auto_awesome, size: 22),
                wert: widget.earnedXp,
                startfarbe: _farbe,
                endfarbe: Palette.accent,
                semanticLabel: '${widget.earnedXp} Erfahrung',
              ),
              const SizedBox(height: 8),
              _BeuteZeile(
                ablauf: _ablauf,
                beginn: 0.40,
                icon: const GoldIcon(size: 22),
                wert: widget.earnedGold,
                startfarbe: _farbe,
                endfarbe: Palette.gold,
                semanticLabel: '${widget.earnedGold} Gold',
              ),
            ],
            const SizedBox(height: 22),
            _WeiterKnopf(ablauf: _ablauf, beginn: _hatBeute ? 0.75 : 0.2),
          ],
        ),
      ),
    );
  }
}

/// Ebene und Zeit, ruhig: gedämpfte Farbe, die Zeit nur mit Zeichen.
class _Fakten extends StatelessWidget {
  const _Fakten({
    required this.stage,
    required this.seconds,
    required this.newBest,
    required this.timedOut,
  });

  final int stage;
  final int seconds;
  final bool newBest;
  final bool timedOut;

  static const TextStyle _ruhig = TextStyle(
    fontSize: 15,
    color: Palette.textDim,
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Ebene $stage, $seconds Sekunden'
          '${timedOut ? ', Zeit abgelaufen' : ''}'
          '${newBest ? ', neue Bestzeit' : ''}',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Ebene: $stage', style: _ruhig),
          const SizedBox(width: 18),
          Icon(
            timedOut ? Icons.timer_off_outlined : Icons.timer_outlined,
            size: 17,
            color: Palette.textDim,
          ),
          const SizedBox(width: 4),
          Text('$seconds s', style: _ruhig),
          if (newBest) ...<Widget>[
            const SizedBox(width: 4),
            const Icon(Icons.star_rounded, size: 17, color: Palette.gold),
          ],
        ],
      ),
    );
  }
}

/// Eine Zeile Beute: gleitet von unten herein und blendet von
/// [startfarbe] — der Farbe der Überschrift — in [endfarbe].
class _BeuteZeile extends StatelessWidget {
  const _BeuteZeile({
    required this.ablauf,
    required this.beginn,
    required this.icon,
    required this.wert,
    required this.startfarbe,
    required this.endfarbe,
    required this.semanticLabel,
  });

  final Animation<double> ablauf;

  /// Wann im [ablauf] die Zeile hereinkommt, als Anteil von 0 bis 1.
  final double beginn;
  final Widget icon;
  final int wert;
  final Color startfarbe;
  final Color endfarbe;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final herein = CurvedAnimation(
      parent: ablauf,
      curve: Interval(beginn, beginn + 0.2, curve: Curves.easeOutBack),
    );
    final farbe = ColorTween(begin: startfarbe, end: endfarbe).animate(
      CurvedAnimation(
        parent: ablauf,
        curve: Interval(beginn + 0.2, beginn + 0.45, curve: Curves.easeInOut),
      ),
    );

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: ablauf,
        builder: (context, _) {
          final t = herein.value;
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 24 * (1 - t)),
              child: IconTheme.merge(
                data: IconThemeData(color: farbe.value),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    icon,
                    const SizedBox(width: 8),
                    Text(
                      '+$wert',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: farbe.value,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// „Weiter“, mittig, erst wenn die Beute da ist.
class _WeiterKnopf extends StatelessWidget {
  const _WeiterKnopf({required this.ablauf, required this.beginn});

  final Animation<double> ablauf;
  final double beginn;

  @override
  Widget build(BuildContext context) {
    final sichtbar = CurvedAnimation(
      parent: ablauf,
      curve: Interval(beginn, 1, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: sichtbar,
      child: AnimatedBuilder(
        animation: sichtbar,
        // Unsichtbar lässt er sich nicht drücken.
        builder: (context, child) =>
            IgnorePointer(ignoring: sichtbar.value < 0.5, child: child),
        child: Center(
          child: FilledButton(
            key: LaufErgebnis.weiterKey,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Weiter'),
          ),
        ),
      ),
    );
  }
}
