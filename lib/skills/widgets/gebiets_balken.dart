import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';
import 'package:progression/progression.dart';

import '../../ui/aufstieg.dart';
import '../../ui/beute_flug.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../gebiet_zeichen.dart';
import '../skills_provider.dart';

/// **Der zweite Balken** (ADR-0085): unter dem Level-Balken, solange die
/// grünen Funken eines Häkchens fliegen — Zeichen, Name, Balken und
/// Stufe des Gebiets.
///
/// Er sagt, was ein Häkchen sonst verschwiege: **Dieselbe Erfahrung zählt
/// zweimal**, fürs Level und für den Skill. Die Funken teilen sich am
/// Finger, ein Strom fliegt nach oben, einer hierher, und beide Balken
/// füllen sich im selben Augenblick.
///
/// **Er liegt immer da, nur unsichtbar.** Ein Ziel muss stehen, bevor
/// geworfen wird (`AufstiegHost.fliege` nimmt seinen Ort beim Werfen),
/// und jeder Teil hat eine feste Breite — sonst verschöbe ein langer
/// Name den Balken, und die Funken landeten daneben.
///
/// Er zeigt, was **angekommen** ist, wie die Leiste darüber: Was noch
/// fliegt, zieht er ab, also steigt die Stufe mit dem Funken, der sie
/// vollmacht.
class GebietsBalken extends ConsumerStatefulWidget {
  const GebietsBalken({super.key});

  /// Wie hoch er ist — so hoch wie der Balken darüber.
  static const double hoehe = 12;

  /// Wie lange er stehen bleibt, nachdem alles gelandet ist, bevor er
  /// verblasst.
  static const Duration nachklang = Duration(milliseconds: 1900);

  @override
  ConsumerState<GebietsBalken> createState() => _GebietsBalkenState();
}

class _GebietsBalkenState extends ConsumerState<GebietsBalken>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sicht;
  AufstiegHostState? _host;
  ValueListenable<int>? _unterwegs;
  int _zuletzt = 0;

  @override
  void initState() {
    super.initState();
    // In `initState`, nicht faul: Sonst entstünde er womöglich erst im
    // `dispose` (`gotchas.md`).
    _sicht = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final host = AufstiegHost.maybeOf(context);
    if (identical(host, _host)) return;
    _unterwegs?.removeListener(_geaendert);
    _host = host;
    final unterwegs = host?.unterwegs(FlugZiel.gebiet);
    unterwegs?.addListener(_geaendert);
    _unterwegs = unterwegs;
    _zuletzt = unterwegs?.value ?? 0;
  }

  /// Fliegt etwas los, blendet er ein; ist alles da, bleibt er noch einen
  /// Moment stehen und verblasst dann.
  void _geaendert() {
    final jetzt = _unterwegs?.value ?? 0;
    if (jetzt > 0 && _zuletzt == 0) {
      _sicht.forward();
    } else if (jetzt == 0 && _zuletzt > 0) {
      _sicht.animateTo(
        0,
        duration: GebietsBalken.nachklang,
        curve: const Interval(0.7, 1, curve: Curves.easeOut),
      );
    }
    _zuletzt = jetzt;
  }

  @override
  void dispose() {
    _unterwegs?.removeListener(_geaendert);
    _sicht.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final area = ref.watch(zuletztGebietProvider);
    final skills = ref.watch(skillsProvider);
    final unterwegs = _unterwegs;

    return FadeTransition(
      opacity: _sicht,
      child: ListenableBuilder(
        listenable: unterwegs ?? _sicht,
        builder: (context, _) {
          final skill = area == null
              ? const SkillLevel.start()
              : SkillCurve.levelFor(
                  skills.of(area).totalXp - (unterwegs?.value ?? 0),
                );
          return _zeile(area, skill);
        },
      ),
    );
  }

  Widget _zeile(SkillArea? area, SkillLevel skill) {
    return Semantics(
      label: area == null ? null : '${area.label}, Stufe ${skill.level}',
      excludeSemantics: true,
      child: SizedBox(
        height: GebietsBalken.hoehe,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 16,
              child: area == null
                  ? null
                  : Icon(gebietZeichen(area), size: 13, color: Palette.success),
            ),
            SizedBox(
              width: 62,
              child: Text(
                area?.label ?? '',
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: Palette.success,
                ),
              ),
            ),
            Expanded(
              child: FlugZielMarke(
                ziel: FlugZiel.gebiet,
                staerke: 0.04,
                child: HolzBalken(value: skill.ratio, color: Palette.success),
              ),
            ),
            SizedBox(
              width: 22,
              child: Text(
                area == null ? '' : '${skill.level}',
                textAlign: TextAlign.right,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  color: Palette.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
