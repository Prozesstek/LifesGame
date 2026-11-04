import 'package:flutter/material.dart';
import 'package:progression/progression.dart';

import '../../ui/holz.dart';
import '../../ui/level_abzeichen.dart';
import '../../ui/palette.dart';
import '../level_roadmap.dart';

/// **Die Level-Roadmap als Blatt** (ADR-0098) — öffnet sich mit einem Tipp
/// auf den Level-Ring.
///
/// Oben, wie viel Erfahrung bis zum nächsten Level fehlt (bis dahin der
/// Tooltip des Rings) und was jedes Level bringt. Darunter die
/// Meilensteine als Pfad: erreichte hell mit Haken, der nächste golden,
/// spätere blass. Das Blatt rollt beim Öffnen zum nächsten Meilenstein.
class LevelRoadmapBlatt extends StatefulWidget {
  const LevelRoadmapBlatt({required this.level, super.key});

  final PlayerLevel level;

  /// Woran Tests eine Zeile finden.
  static Key zeileKey(int level) => ValueKey<String>('roadmap-$level');

  /// Höhe einer Zeile ohne Gewinne — fürs Hinrollen.
  static const double _zeilenHoehe = 64;

  static Future<void> zeige(BuildContext context, PlayerLevel level) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => HolzBlatt(child: LevelRoadmapBlatt(level: level)),
    );
  }

  @override
  State<LevelRoadmapBlatt> createState() => _LevelRoadmapBlattState();
}

class _LevelRoadmapBlattState extends State<LevelRoadmapBlatt> {
  late final ScrollController _rollen;

  @override
  void initState() {
    super.initState();
    final naechster = LevelRoadmap.naechsterMeilenstein(widget.level.level);
    final index = naechster == null
        ? LevelRoadmap.meilensteine.length - 1
        : LevelRoadmap.meilensteine.indexOf(naechster);
    // Eine Zeile über dem nächsten, damit man sieht, woher man kommt.
    final oben = (index - 1).clamp(0, LevelRoadmap.meilensteine.length);
    _rollen = ScrollController(
      initialScrollOffset: oben * LevelRoadmapBlatt._zeilenHoehe,
    );
  }

  @override
  void dispose() {
    _rollen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    final naechster = LevelRoadmap.naechsterMeilenstein(level.level);
    final hoehe = MediaQuery.sizeOf(context).height * 0.75;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: hoehe),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Kopf(level: level),
          const Divider(height: 1, color: Palette.surfaceSunken),
          Flexible(
            child: ListView(
              controller: _rollen,
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: <Widget>[
                for (final l in LevelRoadmap.meilensteine)
                  _Stufe(
                    key: LevelRoadmapBlatt.zeileKey(l),
                    level: l,
                    zustand: l <= level.level
                        ? _Zustand.erreicht
                        : l == naechster
                        ? _Zustand.naechster
                        : _Zustand.spaeter,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wo man steht: Abzeichen, Balken, und was jedes Level bringt.
class _Kopf extends StatelessWidget {
  const _Kopf({required this.level});

  final PlayerLevel level;

  @override
  Widget build(BuildContext context) {
    final satz = level.isMaxLevel
        ? 'Höchste Stufe erreicht'
        : '${level.xpIntoLevel} von ${level.xpForLevel} Erfahrung '
              'bis Level ${level.level + 1}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              LevelAbzeichen(level: level.level, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      satz,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Palette.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: level.ratio.clamp(0.0, 1.0),
                        minHeight: 7,
                        color: Palette.ertragXp,
                        backgroundColor: Palette.surfaceSunken,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Was **jedes** Level bringt, einmal statt fünfzigmal.
          Row(
            children: <Widget>[
              const Icon(Icons.menu_book, size: 16, color: Palette.accent),
              const SizedBox(width: 4),
              const Flexible(
                child: Text(
                  '+1 Talentpunkt',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Palette.textDim),
                ),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.bolt, size: 16, color: Palette.accent),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '+${((PowerCurve.perLevel - 1) * 100).round()} % Kraft',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Palette.textDim),
                ),
              ),
              const SizedBox(width: 4),
              const Flexible(
                child: Text(
                  'je Level',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Palette.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _Zustand { erreicht, naechster, spaeter }

/// Ein Meilenstein: das Level links, rechts was es bringt.
class _Stufe extends StatelessWidget {
  const _Stufe({required this.level, required this.zustand, super.key});

  final int level;
  final _Zustand zustand;

  @override
  Widget build(BuildContext context) {
    final gewinne = LevelRoadmap.gewinneAuf(level);
    final naechster = zustand == _Zustand.naechster;
    final blass = zustand == _Zustand.spaeter;
    final farbe = blass ? Palette.muted : Palette.text;

    return Semantics(
      label:
          'Level $level: ${gewinne.map((g) => g.name).join(', ')}'
          '${zustand == _Zustand.erreicht ? ', erreicht' : ''}',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: naechster
              ? Palette.gold.withValues(alpha: 0.14)
              : Colors.transparent,
          border: naechster
              ? Border.all(color: Palette.gold, width: 1.5)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: <Widget>[
            Opacity(
              opacity: blass ? 0.45 : 1,
              child: LevelAbzeichen(level: level, size: 34),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: <Widget>[
                  for (final g in gewinne)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          g.icon,
                          size: 18,
                          color: blass ? Palette.muted : Palette.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          g.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: farbe,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (zustand == _Zustand.erreicht)
              const Icon(Icons.check_circle, size: 20, color: Palette.success)
            else if (blass)
              const Icon(Icons.lock_outline, size: 18, color: Palette.muted),
          ],
        ),
      ),
    );
  }
}
