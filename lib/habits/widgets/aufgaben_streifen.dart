import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../ui/palette.dart';
import 'daily_quests_card.dart';

/// Ein Fortschritt einer Tagesaufgabe: wie weit sie vorher stand, wie
/// weit jetzt.
class AufgabenSchritt {
  const AufgabenSchritt({required this.quest, required this.vorher});

  /// Die Aufgabe mit dem neuen Stand.
  final DailyQuest quest;

  /// Der Stand davor.
  final int vorher;

  bool get geschafft => quest.isDone && vorher < quest.target;

  /// Was sich zwischen [vorher] und [nachher] bewegt hat — nur, was
  /// **gestiegen** ist. Ein zurückgenommenes Häkchen zeigt nichts.
  static List<AufgabenSchritt> zwischen(
    List<DailyQuest> vorher,
    List<DailyQuest> nachher,
  ) {
    final alt = <String, int>{for (final q in vorher) q.id: q.progress};
    return <AufgabenSchritt>[
      for (final q in nachher)
        if (q.progress > (alt[q.id] ?? 0))
          AufgabenSchritt(quest: q, vorher: alt[q.id] ?? 0),
    ];
  }
}

/// **Die Tagesaufgaben kommen kurz von unten** (29.10.2026): Wer etwas
/// tut, das eine Aufgabe voranbringt, sieht sie hereinfahren, ihren
/// Balken sich füllen — und sie wieder verschwinden.
///
/// Nimmt keinen Tipp an und endet von selbst ([onFertig]); abgeholt wird
/// weiter am Lagerfeuer (ADR-0076).
class AufgabenStreifen extends StatefulWidget {
  const AufgabenStreifen({
    required this.schritte,
    required this.onFertig,
    super.key,
  });

  final List<AufgabenSchritt> schritte;
  final VoidCallback onFertig;

  static const Key streifenKey = ValueKey<String>('aufgaben-streifen');

  /// Hereinfahren, füllen, stehen, hinausfahren.
  static const Duration herein = Duration(milliseconds: 380);
  static const Duration fuellen = Duration(milliseconds: 700);
  static const Duration stehen = Duration(milliseconds: 1100);
  static const Duration hinaus = Duration(milliseconds: 320);

  static Duration get dauer => herein + fuellen + stehen + hinaus;

  /// Über der Leiste unten, in der das Häkchen seinen Ertrag nennt.
  static const double abstandUnten = 84;

  @override
  State<AufgabenStreifen> createState() => _AufgabenStreifenState();
}

class _AufgabenStreifenState extends State<AufgabenStreifen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _zeit;

  @override
  void initState() {
    super.initState();
    _zeit = AnimationController(vsync: this, duration: AufgabenStreifen.dauer)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onFertig();
      })
      ..forward();
  }

  @override
  void dispose() {
    _zeit.dispose();
    super.dispose();
  }

  double _anteil(Duration bis) =>
      bis.inMicroseconds / AufgabenStreifen.dauer.inMicroseconds;

  @override
  Widget build(BuildContext context) {
    final a = _anteil(AufgabenStreifen.herein);
    final b = a + _anteil(AufgabenStreifen.fuellen);
    final c = b + _anteil(AufgabenStreifen.stehen);
    final hineinKurve = CurvedAnimation(
      parent: _zeit,
      curve: Interval(0, a, curve: Curves.easeOutBack),
    );
    final hinausKurve = CurvedAnimation(
      parent: _zeit,
      curve: Interval(c, 1, curve: Curves.easeInCubic),
    );
    final fuellKurve = CurvedAnimation(
      parent: _zeit,
      curve: Interval(a, b, curve: Curves.easeOutCubic),
    );

    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            AufgabenStreifen.abstandUnten,
          ),
          child: AnimatedBuilder(
            animation: _zeit,
            builder: (context, kind) {
              // Von unterhalb des Rands herein, wieder hinaus.
              final weg = (1 - hineinKurve.value) + hinausKurve.value;
              return FractionalTranslation(
                translation: Offset(0, weg * 2.2),
                child: Opacity(
                  opacity: (1 - hinausKurve.value).clamp(0, 1),
                  child: kind,
                ),
              );
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                key: AufgabenStreifen.streifenKey,
                decoration: BoxDecoration(
                  color: Palette.backgroundRaised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Palette.goldOnDark, width: 1.5),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (final (i, schritt) in widget.schritte.indexed) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _Zeile(schritt: schritt, fuellen: fuellKurve),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Zeile extends StatelessWidget {
  const _Zeile({required this.schritt, required this.fuellen});

  final AufgabenSchritt schritt;
  final Animation<double> fuellen;

  @override
  Widget build(BuildContext context) {
    final quest = schritt.quest;
    final ziel = quest.target <= 0 ? 1 : quest.target;
    return AnimatedBuilder(
      animation: fuellen,
      builder: (context, _) {
        final stand =
            schritt.vorher + (quest.progress - schritt.vorher) * fuellen.value;
        final voll = schritt.geschafft && fuellen.value >= 1;
        final farbe = voll ? Palette.successOnDark : Palette.goldOnDark;
        return Semantics(
          label: '${quest.text}: ${quest.progress} von ${quest.target}',
          excludeSemantics: true,
          child: Row(
            children: <Widget>[
              Icon(
                voll
                    ? Icons.check_circle_rounded
                    : DailyQuestsCard.zeichenOf(quest.kind),
                size: 22,
                color: farbe,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            quest.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Palette.textOnDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${stand.floor()} / ${quest.target}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: farbe,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (stand / ziel).clamp(0, 1),
                        minHeight: 7,
                        backgroundColor: Palette.chipOnDark,
                        valueColor: AlwaysStoppedAnimation<Color>(farbe),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
