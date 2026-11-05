import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/ausgegraut.dart';
import '../../ui/druck.dart';
import '../../ui/palette.dart';
import '../level_provider.dart';
import 'level_roadmap_blatt.dart';

/// **Sichtbar, aber gesperrt, bis ein Level erreicht ist** (ADR-0098,
/// Frederik am 04.11.2026: „wenn man die Sachen schon sieht, aber sie halt
/// mit so einem Schloss gesperrt sind“).
///
/// Das Kind wird ausgegraut und nimmt keinen Tipp an; in der Ecke sitzt ein
/// Schloss mit dem Level. Ein Tipp auf das Ganze öffnet die Level-Roadmap —
/// dort steht, was noch fehlt.
///
/// Mit [aktiv] `false` gibt es nur das Kind zurück. **Die Hülle bleibt
/// trotzdem stehen**: Fiele sie weg, baute sich das Kind neu, samt seinem
/// Zustand (`gotchas.md`).
class GesperrtBisLevel extends ConsumerWidget {
  const GesperrtBisLevel({
    required this.level,
    required this.child,
    this.aktiv = true,
    this.rund = false,
    super.key,
  });

  /// Ab welchem Level es aufgeht.
  final int level;

  final Widget child;

  /// Ob gesperrt wird.
  final bool aktiv;

  /// Für einen runden Knopf sitzt das Schloss weiter innen.
  final bool rund;

  /// Wie stark Gesperrtes abgedunkelt wird — nur, was gemalt ist.
  static const ColorFilter abdunkeln = ColorFilter.mode(
    Color(0x59000000),
    BlendMode.srcATop,
  );

  /// Woran Tests das Schloss finden.
  static const Key schlossKey = ValueKey<String>('gesperrt-schloss');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: aktiv,
      label: aktiv ? 'Gesperrt bis Level $level' : null,
      excludeSemantics: aktiv,
      child: Druck(
        enabled: aktiv,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: aktiv
              ? () => LevelRoadmapBlatt.zeige(
                  context,
                  ref.read(playerLevelProvider),
                )
              : null,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.passthrough,
            children: <Widget>[
              AbsorbPointer(
                absorbing: aktiv,
                // **Grau und dunkler, aber deckend.** `Ausgegraut` macht
                // zusätzlich halb durchsichtig — bei einem kleinen Zeichen
                // richtig, bei einer Karte schiene der Hintergrund durch.
                child: aktiv
                    ? ColorFiltered(
                        colorFilter: abdunkeln,
                        child: ColorFiltered(
                          colorFilter: Ausgegraut.grau,
                          child: child,
                        ),
                      )
                    : child,
              ),
              if (aktiv)
                Positioned(
                  // Am Kreis oben rechts — unten steht sein Name.
                  right: rund ? -4 : 6,
                  top: rund ? -4 : 6,
                  child: _Schloss(key: schlossKey, level: level),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Das Schloss mit dem Level daneben, auf dunklem Grund.
class _Schloss extends StatelessWidget {
  const _Schloss({required this.level, super.key});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 3, 7, 3),
      decoration: BoxDecoration(
        color: Palette.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.goldOnDark, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.lock, size: 12, color: Palette.goldOnDark),
          const SizedBox(width: 3),
          Text(
            '$level',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Palette.goldOnDark,
            ),
          ),
        ],
      ),
    );
  }
}
