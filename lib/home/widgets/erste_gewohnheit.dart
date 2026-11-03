import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../../habits/habits_controller.dart';
import '../../habits/stat_icon.dart';
import '../../save/widgets/save_transfer_card.dart';
import '../../skills/gebiet_farbe.dart';
import '../../skills/gebiet_zeichen.dart';
import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';

/// Ein Vorschlag für die erste Gewohnheit.
class ErsterVorschlag {
  const ErsterVorschlag(this.name, this.area, {this.vorlageId});

  final String name;

  /// Das Gebiet ihres Skills (ADR-0085) — und damit ihr Kampfwert
  /// (ADR-0088). Bei einer Vorlage dasselbe wie im Katalog.
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
/// Eigenes schreibt, wählt dazu sein Gebiet — der Kampfwert folgt
/// daraus (ADR-0088). Wann, an welchen Tagen
/// und was es danach gibt, fragt später die Kachel (ADR-0052) — am
/// Anfang zählt das erste Häkchen, nicht das Formular.
class ErsteGewohnheitKarte extends ConsumerStatefulWidget {
  const ErsteGewohnheitKarte({super.key});

  static const Key feldKey = ValueKey<String>('erste-gewohnheit-feld');
  static const Key losKey = ValueKey<String>('erste-gewohnheit-los');
  static const Key standKey = ValueKey<String>('erste-gewohnheit-stand');

  /// **Drei Vorschläge und das Eigene** (03.11.2026): je einer in einer
  /// Zeile, groß genug zum Lesen — bis dahin waren es sechs kleine Chips.
  /// Drei Gebiete, damit die Wahl auch eine zwischen Kampfwerten ist.
  ///
  /// Der erste ist die Startvorlage (ADR-0052): Sie kostet keinen Platz
  /// für eine eigene Gewohnheit und bringt ihren Timer mit.
  static final List<ErsterVorschlag> vorschlaege = <ErsterVorschlag>[
    ErsterVorschlag(
      HabitCatalog.starter.name,
      HabitCatalog.starter.area,
      vorlageId: HabitCatalog.starterId,
    ),
    const ErsterVorschlag('Spazieren gehen', SkillArea.koerper),
    const ErsterVorschlag('Freund anrufen', SkillArea.gesellschaft),
  ];

  /// So lang wie im Formular einer eigenen Gewohnheit.
  static const int maxNameLength = 60;

  @override
  ConsumerState<ErsteGewohnheitKarte> createState() =>
      _ErsteGewohnheitKarteState();
}

class _ErsteGewohnheitKarteState extends ConsumerState<ErsteGewohnheitKarte> {
  final TextEditingController _name = TextEditingController();
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
    _lege(vorschlag.name, vorschlag.area);
  }

  void _lege(String name, SkillArea area) {
    if (name.trim().isEmpty) return;
    final angelegt = ref
        .read(habitTrackerProvider.notifier)
        .addCustom(name: name, area: area, difficulty: HabitDifficulty.mittel);
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Was willst du jeden Tag tun?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Palette.text,
            ),
          ),
          const SizedBox(height: 14),
          for (final vorschlag in ErsteGewohnheitKarte.vorschlaege) ...<Widget>[
            _VorschlagZeile(
              vorschlag: vorschlag,
              onTap: () => _nimm(vorschlag),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            key: ErsteGewohnheitKarte.feldKey,
            controller: _name,
            maxLength: ErsteGewohnheitKarte.maxNameLength,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _lege(_name.text, _area),
            style: const TextStyle(fontSize: 18, color: Palette.text),
            decoration: InputDecoration(
              hintText: 'Etwas Eigenes',
              hintStyle: const TextStyle(fontSize: 18, color: Palette.muted),
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.edit_rounded, size: 24, color: Palette.muted),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_VorschlagZeile.rund),
              ),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          // Wohin das Eigene gehört, und der Knopf — erst wenn etwas im
          // Feld steht. Vorher wären es vier Zeichen ohne Bezug.
          if (bereit) ...<Widget>[
            const SizedBox(height: 8),
            // Nur das Gebiet (ADR-0085); was es im Kampf stärkt, folgt
            // daraus und steht als Zeichen daneben (ADR-0088).
            Row(
              children: <Widget>[
                for (final area in SkillArea.values)
                  _Wahl(
                    key: ValueKey<String>('erste-gewohnheit-${area.name}'),
                    icon: gebietZeichen(area),
                    farbe: GebietFarbe.pergament(area),
                    label: '${area.label}, stärkt ${area.kampfwert.label}',
                    gewaehlt: area == _area,
                    onTap: () => setState(() => _area = area),
                  ),
                const Spacer(),
                StatIcon(_area.kampfwert, size: 20),
                const SizedBox(width: 8),
                FilledButton(
                  key: ErsteGewohnheitKarte.losKey,
                  onPressed: () => _lege(_name.text, _area),
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

/// Ein Vorschlag als eigene Zeile: das Zeichen seines Gebiets in dessen
/// Farbe, der Name groß, rechts das Plus.
class _VorschlagZeile extends StatelessWidget {
  const _VorschlagZeile({required this.vorschlag, required this.onTap});

  final ErsterVorschlag vorschlag;
  final VoidCallback onTap;

  static const double rund = 10;

  @override
  Widget build(BuildContext context) {
    final farbe = GebietFarbe.pergament(vorschlag.area);
    return Semantics(
      button: true,
      label: '${vorschlag.name}, ${vorschlag.area.label}',
      excludeSemantics: true,
      child: Druck(
        child: Material(
          color: Palette.surfaceRaised,
          borderRadius: BorderRadius.circular(rund),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(rund),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(rund),
                border: Border.all(color: farbe.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(gebietZeichen(vorschlag.area), size: 24, color: farbe),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      vorschlag.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Palette.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatIcon(vorschlag.area.kampfwert, size: 18),
                  const SizedBox(width: 10),
                  Icon(Icons.add_circle_rounded, size: 26, color: farbe),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ein Gebiet als Kreis zum Antippen.
class _Wahl extends StatelessWidget {
  const _Wahl({
    required this.label,
    required this.gewaehlt,
    required this.onTap,
    required this.icon,
    required this.farbe,
    super.key,
  });

  /// Nur für den Vorleser — zu sehen ist das Zeichen.
  final String label;
  final bool gewaehlt;
  final VoidCallback onTap;
  final IconData icon;

  /// Die Farbe des Gebiets (ADR-0090): das Zeichen immer, der Rand, wenn
  /// gewählt.
  final Color farbe;

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
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gewaehlt ? Palette.surfaceRaised : null,
                border: Border.all(
                  color: gewaehlt ? farbe : Palette.muted,
                  width: gewaehlt ? 2 : 1,
                ),
              ),
              child: Icon(icon, size: 18, color: farbe),
            ),
          ),
        ),
      ),
    );
  }
}
