import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../action/pit_screen.dart';
import '../gear/gear_controller.dart';
import '../gear/gear_icon.dart';
import '../ui/druck.dart';
import '../ui/gold_icon.dart';
import '../ui/holz.dart';
import '../ui/palette.dart';
import '../ui/pixel_art.dart';
import 'ladder_controller.dart';
import 'widgets/tagesform_kreis.dart';

/// Der Eingang zur Grube — dreissig Stufen als **Fahrstuhl** (Issue #88).
///
/// **Seit ADR-0039 führt er in die Grube statt in den Rundenkampf.** Die
/// Zahl oben ist dieselbe geblieben, weil an ihr die Sperren im Laden,
/// die Errungenschaften und die einmalige Belohnung hängen; aus der
/// Sprosse ist eine Stufe geworden. Der Klassenname bleibt — er ist der
/// Ort, auf den Startbildschirm und Tests zeigen.
///
/// **Seit dem 28.09. ein Schacht statt Text.** Vorher standen hier eine
/// Karte mit den vier Stufen des Tages, eine Leiste mit Bestzeiten, ein
/// leeres Bild und drei Sätze. Jetzt stehen alle dreissig Stufen
/// untereinander, jede mit Stern (Stufe des Tages) und Bestzeit; ein Tipp
/// wählt, „Hinab“ fährt hin. Was die gewählte Stufe einbringt, steht als
/// Zeichen und Zahl darunter.
class LadderScreen extends ConsumerStatefulWidget {
  const LadderScreen({super.key});

  static const double _maxWidth = 560;

  /// Woran man „Hinab“ findet — der Knopf trägt nur noch einen Pfeil.
  static const Key hinabKey = ValueKey<String>('grube-hinab');

  /// Die Etage einer Stufe im Schacht — sie trägt nur noch ihre Zahl.
  static Key etageKey(int stufe) => ValueKey<String>('grube-etage-$stufe');

  @override
  ConsumerState<LadderScreen> createState() => _LadderScreenState();
}

class _LadderScreenState extends ConsumerState<LadderScreen> {
  /// Die gewählte Stufe, oder null: dann die nächste neue. Wer nichts
  /// wählt, fährt nach einem Sieg von selbst eine Stufe tiefer.
  int? _gewaehlt;

  @override
  Widget build(BuildContext context) {
    final stand = ref.watch(ladderProvider);
    final dailies = ref.watch(todayDailiesProvider);
    final zahlen = ref.watch(dailiesUnlockedProvider);
    final stufe = _gewaehlt ?? stand.nextRung;

    return Scaffold(
      appBar: AppBar(title: const Text('Die Grube')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: LadderScreen._maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: <Widget>[
                  _Fortschritt(stand: stand),
                  const SizedBox(height: 14),
                  Expanded(
                    child: _Schacht(
                      stand: stand,
                      dailies: dailies,
                      zahlen: zahlen,
                      gewaehlt: stufe,
                      onWaehle: (s) => setState(() => _gewaehlt = s),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Belohnung(
                    stand: stand,
                    stufe: stufe,
                    daily: _dailyFuer(dailies, stufe),
                    zahlen: zahlen,
                  ),
                  const SizedBox(height: 8),
                  // Der Blitz schrumpft, die Schlüssel nicht: Sein Text
                  // kann lang werden („Angriff +10 %, Leben +10 %, …“).
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _Schluessel(),
                      SizedBox(width: 16),
                      Flexible(child: TagesformKreis()),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PitScreen(stage: PitStage(stufe)),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      key: LadderScreen.hinabKey,
                      child: const Icon(
                        Icons.keyboard_double_arrow_down_rounded,
                        size: 26,
                        semanticLabel: 'Hinab',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static DailyStage? _dailyFuer(List<DailyStage> dailies, int stufe) {
    for (final d in dailies) {
      if (d.stage == stufe) return d;
    }
    return null;
  }
}

/// „7 / 30" mit Balken — die Zahl, die zwei Spieler vergleichen.
class _Fortschritt extends StatelessWidget {
  const _Fortschritt({required this.stand});

  final LadderProgress stand;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          '${stand.highestDefeated} / ${PitStage.count}',
          // Die Zahl steht auf dem Leder, nicht auf einer Fläche — und
          // sie ist die Überschrift des Bildschirms.
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Palette.textOnDark,
          ),
        ),
        const SizedBox(height: 8),
        HolzBalken(
          value: stand.highestDefeated / PitStage.count,
          color: Palette.accentOnDark,
        ),
      ],
    );
  }
}

/// Der Schacht: Stufe 30 oben, Stufe 1 unten, wie es hinabgeht.
///
/// **Offen ist jede geschaffte Stufe und die nächste neue** — dieselbe
/// Grenze wie vorher über „Hinab“ und die Leiste der geschafften Stufen.
/// Darunter liegt nichts, was man nicht auch vorher betreten konnte.
class _Schacht extends StatefulWidget {
  const _Schacht({
    required this.stand,
    required this.dailies,
    required this.zahlen,
    required this.gewaehlt,
    required this.onWaehle,
  });

  final LadderProgress stand;
  final List<DailyStage> dailies;
  final bool zahlen;
  final int gewaehlt;
  final ValueChanged<int> onWaehle;

  static const double zeilenHoehe = 44;

  @override
  State<_Schacht> createState() => _SchachtState();
}

class _SchachtState extends State<_Schacht> {
  // Umgekehrt gebaut: Der Anfang der Liste ist unten, dort liegt Stufe 1.
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // **Die gewählte Stufe etwas unter die Mitte**, die geschafften
    // darunter im Bild. Wie hoch der Schacht ist, weiss erst das Layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final pos = _scroll.position;
      final ziel =
          (widget.gewaehlt - 0.5) * _Schacht.zeilenHoehe -
          pos.viewportDimension * 0.4;
      _scroll.jumpTo(ziel.clamp(0, pos.maxScrollExtent).toDouble());
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offen = widget.stand.nextRung;
    return HolzKarte(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        controller: _scroll,
        reverse: true,
        itemExtent: _Schacht.zeilenHoehe,
        itemCount: PitStage.count,
        itemBuilder: (context, i) {
          final s = i + 1;
          final daily = _LadderScreenState._dailyFuer(widget.dailies, s);
          return _Etage(
            key: LadderScreen.etageKey(s),
            stufe: s,
            gesperrt: s > offen,
            neu: widget.stand.isNewGround(s) && s <= offen,
            bestzeit: widget.stand.bestTimes[s],
            daily: daily,
            zahlen: widget.zahlen,
            gewaehlt: s == widget.gewaehlt,
            onTap: () => widget.onWaehle(s),
          );
        },
      ),
    );
  }
}

/// Eine Etage im Schacht.
class _Etage extends StatelessWidget {
  const _Etage({
    required this.stufe,
    required this.gesperrt,
    required this.neu,
    required this.bestzeit,
    required this.daily,
    required this.zahlen,
    required this.gewaehlt,
    required this.onTap,
    super.key,
  });

  final int stufe;
  final bool gesperrt;
  final bool neu;
  final double? bestzeit;
  final DailyStage? daily;
  final bool zahlen;
  final bool gewaehlt;
  final VoidCallback onTap;

  /// Unter einer Minute auf die Zehntelsekunde, darüber Minuten und
  /// Sekunden.
  static String zeit(double sekunden) {
    if (sekunden < 60) {
      return '${sekunden.toStringAsFixed(1).replaceAll('.', ',')} s';
    }
    final ganz = sekunden.round();
    final rest = (ganz % 60).toString().padLeft(2, '0');
    return '${ganz ~/ 60}:$rest';
  }

  @override
  Widget build(BuildContext context) {
    final farbe = gesperrt ? Palette.muted : Palette.text;
    final rechts = switch ((gesperrt, neu, bestzeit)) {
      (true, _, _) => const Icon(Icons.lock, size: 16, color: Palette.muted),
      (_, true, _) => const Icon(
        Icons.explore_outlined,
        size: 18,
        color: Palette.accent,
      ),
      (_, _, final double t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.timer_outlined, size: 14, color: Palette.textDim),
          const SizedBox(width: 3),
          Text(
            zeit(t),
            style: const TextStyle(fontSize: 13, color: Palette.textDim),
          ),
        ],
      ),
      _ => const SizedBox.shrink(),
    };

    return Semantics(
      button: !gesperrt,
      selected: gewaehlt,
      label:
          'Stufe $stufe${daily != null ? ', Stufe des Tages' : ''}'
          '${neu && !gesperrt ? ', neu' : ''}',
      excludeSemantics: true,
      onTap: gesperrt ? null : onTap,
      child: Druck(
        child: Material(
          color: gewaehlt ? Palette.surfaceRaised : Colors.transparent,
          child: InkWell(
            onTap: gesperrt ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 22,
                    child: gewaehlt
                        ? const Icon(
                            Icons.play_arrow,
                            size: 18,
                            color: Palette.accent,
                          )
                        : null,
                  ),
                  SizedBox(
                    width: 22,
                    child: switch (daily) {
                      null => null,
                      final d => Icon(
                        Icons.star,
                        size: 18,
                        // Offen und zahlend gold, sonst blass: geschafft
                        // oder heute noch ohne Häkchen.
                        color: !d.cleared && zahlen
                            ? Palette.gold
                            : Palette.muted,
                      ),
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$stufe',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: gewaehlt
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: farbe,
                      ),
                    ),
                  ),
                  rechts,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Was die gewählte Stufe einbringt, als Zeichen und Zahl: Erstsieg oder
/// Stufe des Tages. Zahlt sie nichts, steht nichts da.
///
/// **Die Zeile gehört vor den Kampf, nicht nur danach.** Seit ADR-0041
/// ist es beim Erstsieg der **Rest** des Topfs: Was ein verlorener Lauf
/// schon eingesammelt hat, ist abgezogen.
class _Belohnung extends ConsumerWidget {
  const _Belohnung({
    required this.stand,
    required this.stufe,
    required this.daily,
    required this.zahlen,
  });

  final LadderProgress stand;
  final int stufe;
  final DailyStage? daily;
  final bool zahlen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ({int xp, int gold, bool stern})? topf;
    if (stand.isNewGround(stufe)) {
      final t = ref.read(ladderProvider.notifier).potFor(stufe);
      topf = (xp: t.xp, gold: t.gold, stern: false);
    } else if (daily case final d? when zahlen && !d.cleared) {
      topf = (xp: d.xp, gold: d.gold, stern: true);
    } else {
      topf = null;
    }

    // Die Höhe bleibt, auch wenn nichts zahlt — sonst springt „Hinab“.
    return SizedBox(
      height: 22,
      child: topf == null || (topf.xp == 0 && topf.gold == 0)
          ? null
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (topf.stern) ...<Widget>[
                  const Icon(Icons.star, size: 16, color: Palette.goldOnDark),
                  const SizedBox(width: 6),
                ],
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Palette.goldOnDark,
                ),
                const SizedBox(width: 4),
                Text(
                  '+${topf.xp}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Palette.goldOnDark,
                  ),
                ),
                const SizedBox(width: 14),
                const GoldIcon(size: 16),
                const SizedBox(width: 4),
                Text(
                  '+${topf.gold}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Palette.goldOnDark,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Die Schlüssel zur Beute des Wächters (ADR-0048), als Zeichen mit Zahl.
/// Ein Tipp sagt, wofür sie sind und woher sie kommen.
class _Schluessel extends ConsumerWidget {
  const _Schluessel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anzahl = ref.watch(availableKeysProvider);
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      message:
          'Schlüssel öffnen die Beute des Wächters, höchstens '
          '${GearKeys.cap}. Jedes Häkchen, jede Seite und jede Rückfrage '
          'bringt einen.',
      child: Semantics(
        label: '$anzahl Schlüssel',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              PixelArt(
                assetPath: GearIcons.schluessel,
                side: 26,
                fallback: const Icon(Icons.key, color: Palette.goldOnDark),
              ),
              const SizedBox(width: 6),
              Text(
                '×$anzahl',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: anzahl > 0
                      ? Palette.goldOnDark
                      : Palette.textOnDarkDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
