import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../../habits/habits_controller.dart';
import '../../habits/stat_icon.dart';
import '../../save/widgets/save_transfer_card.dart';
import '../../skills/gebiet_zeichen.dart';
import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';

/// Ein Vorschlag für die erste Gewohnheit.
class ErsterVorschlag {
  const ErsterVorschlag(this.name, this.stat, this.area, {this.vorlageId});

  final String name;
  final HabitStat stat;

  /// Das Gebiet ihres Skills (ADR-0085). Bei einer Vorlage dasselbe wie
  /// im Katalog.
  final SkillArea area;

  /// Gesetzt, wenn der Vorschlag eine Vorlage aus dem Katalog startet
  /// statt eine eigene Gewohnheit anzulegen.
  final String? vorlageId;
}

/// **Die erste Frage** — steht in „Heute“, solange es keine Gewohnheit
/// gibt (ADR-0068).
///
/// **Eine Karte, kein Dialog.** Ein Dialog beim Start läge über einer
/// Startseite, die noch nichts zeigt, und wer ihn wegtippt, stünde vor
/// der leeren Seite. Die Karte *ist* die Seite, bis sie beantwortet ist.
///
/// **Ein Tipp genügt.** Ein Vorschlag legt sofort an; nur wer etwas
/// Eigenes schreibt, wählt dazu, was es stärkt. Wann, an welchen Tagen
/// und was es danach gibt, fragt später die Kachel (ADR-0052) — am
/// Anfang zählt das erste Häkchen, nicht das Formular.
class ErsteGewohnheitKarte extends ConsumerStatefulWidget {
  const ErsteGewohnheitKarte({super.key});

  static const Key feldKey = ValueKey<String>('erste-gewohnheit-feld');
  static const Key losKey = ValueKey<String>('erste-gewohnheit-los');
  static const Key standKey = ValueKey<String>('erste-gewohnheit-stand');

  /// Der erste Vorschlag ist die Startvorlage (ADR-0052): Sie kostet
  /// keinen Platz für eine eigene Gewohnheit und bringt ihren Timer mit.
  static final List<ErsterVorschlag> vorschlaege = <ErsterVorschlag>[
    ErsterVorschlag(
      HabitCatalog.starter.name,
      HabitCatalog.starter.stat,
      HabitCatalog.starter.area,
      vorlageId: HabitCatalog.starterId,
    ),
    const ErsterVorschlag(
      'Spazieren gehen',
      HabitStat.ausdauer,
      SkillArea.koerper,
    ),
    const ErsterVorschlag(
      'Zehn Liegestütze',
      HabitStat.staerke,
      SkillArea.koerper,
    ),
    const ErsterVorschlag('Bett machen', HabitStat.disziplin, SkillArea.geist),
    const ErsterVorschlag(
      'Ein Glas Wasser',
      HabitStat.ausdauer,
      SkillArea.koerper,
    ),
    const ErsterVorschlag(
      'Fünf Minuten aufräumen',
      HabitStat.disziplin,
      SkillArea.geist,
    ),
  ];

  /// So lang wie im Formular einer eigenen Gewohnheit.
  static const int maxNameLength = 60;

  @override
  ConsumerState<ErsteGewohnheitKarte> createState() =>
      _ErsteGewohnheitKarteState();
}

class _ErsteGewohnheitKarteState extends ConsumerState<ErsteGewohnheitKarte> {
  final TextEditingController _name = TextEditingController();
  HabitStat _stat = HabitStat.disziplin;
  SkillArea _area = SkillArea.koerper;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _nimm(ErsterVorschlag vorschlag) {
    final habits = ref.read(habitTrackerProvider.notifier);
    final vorlage = vorschlag.vorlageId;
    if (vorlage != null) {
      habits.activate(vorlage);
      return;
    }
    _lege(vorschlag.name, vorschlag.stat, vorschlag.area);
  }

  void _lege(String name, HabitStat stat, SkillArea area) {
    if (name.trim().isEmpty) return;
    final angelegt = ref
        .read(habitTrackerProvider.notifier)
        .addCustom(
          name: name,
          stat: stat,
          area: area,
          difficulty: HabitDifficulty.mittel,
        );
    if (angelegt != null || !mounted) return;

    // Kann nur ein Stand treffen, der schon eigene Gewohnheiten hat und
    // trotzdem hier landet — dann lieber ein Satz als ein toter Knopf.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kein Platz für eine eigene Gewohnheit.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bereit = _name.text.trim().isNotEmpty;

    return HolzKarte(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Was willst du jeden Tag tun?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Palette.text,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final vorschlag in ErsteGewohnheitKarte.vorschlaege)
                Druck(
                  child: ActionChip(
                    avatar: StatIcon(vorschlag.stat, size: 15),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(
                      vorschlag.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _nimm(vorschlag),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            key: ErsteGewohnheitKarte.feldKey,
            controller: _name,
            maxLength: ErsteGewohnheitKarte.maxNameLength,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _lege(_name.text, _stat, _area),
            decoration: const InputDecoration(
              hintText: 'Oder etwas Eigenes',
              border: OutlineInputBorder(),
              counterText: '',
              isDense: true,
            ),
          ),
          // Was das Eigene stärkt, und der Knopf — erst wenn etwas im
          // Feld steht. Vorher wären es fünf Zeichen ohne Bezug.
          if (bereit) ...<Widget>[
            const SizedBox(height: 8),
            // Erst das Gebiet (ADR-0085), darunter der Wert: Wohin es
            // gehört, weiß man schneller als, was es im Kampf stärkt.
            Row(
              children: <Widget>[
                for (final area in SkillArea.values)
                  _Wahl(
                    key: ValueKey<String>('erste-gewohnheit-${area.name}'),
                    icon: gebietZeichen(area),
                    label: area.label,
                    gewaehlt: area == _area,
                    onTap: () => setState(() => _area = area),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                for (final stat in HabitStat.values)
                  _StatWahl(
                    stat: stat,
                    gewaehlt: stat == _stat,
                    onTap: () => setState(() => _stat = stat),
                  ),
                const Spacer(),
                FilledButton(
                  key: ErsteGewohnheitKarte.losKey,
                  onPressed: () => _lege(_name.text, _stat, _area),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 20,
                    semanticLabel: 'Anlegen',
                  ),
                ),
              ],
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: ErsteGewohnheitKarte.standKey,
              onPressed: () => spielstandEinfuegen(context, ref),
              icon: const Icon(Icons.content_paste_rounded, size: 16),
              label: const Text(
                'Ich habe schon einen Stand',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Einer der vier Werte zum Antippen — Zeichen statt Wort (ADR-0060).
class _StatWahl extends StatelessWidget {
  const _StatWahl({
    required this.stat,
    required this.gewaehlt,
    required this.onTap,
  });

  final HabitStat stat;
  final bool gewaehlt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Wahl(
      inkKey: ValueKey<String>('erste-gewohnheit-${stat.name}'),
      label: '${stat.label}, ${stat.combatLabel}',
      gewaehlt: gewaehlt,
      onTap: onTap,
      child: StatIcon(stat, size: 18),
    );
  }
}

/// Ein Kreis zum Antippen — für Werte und Gebiete derselbe.
class _Wahl extends StatelessWidget {
  const _Wahl({
    required this.label,
    required this.gewaehlt,
    required this.onTap,
    this.icon,
    this.child,
    this.inkKey,
    super.key,
  });

  /// Nur für den Vorleser — zu sehen ist das Zeichen.
  final String label;
  final bool gewaehlt;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? child;
  final Key? inkKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Semantics(
        button: true,
        selected: gewaehlt,
        label: label,
        excludeSemantics: true,
        child: Druck(
          child: InkWell(
            key: inkKey,
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gewaehlt ? Palette.surfaceRaised : null,
                border: Border.all(
                  color: gewaehlt ? Palette.accent : Palette.muted,
                  width: gewaehlt ? 2 : 1,
                ),
              ),
              child:
                  child ??
                  Icon(
                    icon,
                    size: 18,
                    color: gewaehlt ? Palette.accent : Palette.textDim,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
