import 'package:abilities/abilities.dart';
import 'package:action_combat/action_combat.dart' show PitStage;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../action/action_prototype_screen.dart';
import '../action/hero_power.dart';
import '../action/pit_screen.dart';
import '../action/pit_text.dart';
import '../combat/daily_pit_controller.dart';
import '../combat/ladder_controller.dart';
import '../gear/gear_controller.dart';
import '../habits/habits_controller.dart';
import '../progression/level_provider.dart';
import '../theory/theory_controller.dart';
import '../ui/palette.dart';
import 'dev_actions.dart';
import 'dev_controller.dart';
import 'save_slot.dart';
import '../ui/holz.dart';
import '../ui/druck.dart';
import '../village/village_screen.dart';

/// Die Werkbank: Erfahrung, Gold, Punkte und Sachen per Knopfdruck.
///
/// **Existiert nur im Debug-Build** (`devModeAvailable`) und arbeitet nur
/// auf dem Dev-Spielstand. Beides zusammen ist der Grund, warum dieser
/// Bildschirm den 30-Tage-Nachweis aus `ziele.md` nicht gefährden kann
/// (ADR-0021).
class DevScreen extends ConsumerWidget {
  const DevScreen({super.key});

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slot = ref.watch(activeSlotProvider);
    final actions = DevActions(ref);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entwicklermodus'),
        backgroundColor: Palette.surface,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: <Widget>[
                _SlotBanner(slot: slot),
                const SizedBox(height: 8),
                _SlotSwitch(slot: slot),
                const SizedBox(height: 16),
                const _CurrentValues(),
                const SizedBox(height: 20),

                const _SectionTitle('Erfahrung und Level'),
                _ButtonRow(
                  entries: <String, VoidCallback>{
                    '+1 Level': () => actions.addLevels(1),
                    '+5 Level': () => actions.addLevels(5),
                    '+100 XP': () => _grants(ref).addXp(100),
                    '+1000 XP': () => _grants(ref).addXp(1000),
                  },
                ),
                _FreeInput(
                  label: 'XP',
                  onSubmit: (value) => _grants(ref).addXp(value),
                ),

                const _SectionTitle('Gold'),
                _ButtonRow(
                  entries: <String, VoidCallback>{
                    '+500': () => _grants(ref).addGold(500),
                    '+5000': () => _grants(ref).addGold(5000),
                  },
                ),
                _FreeInput(
                  label: 'Gold',
                  onSubmit: (value) => _grants(ref).addGold(value),
                ),

                const _SectionTitle('Punkte'),
                _ButtonRow(
                  entries: <String, VoidCallback>{
                    '+2 Theorie': () => _grants(ref).addTheoryPoints(2),
                    '+10 Theorie': () => _grants(ref).addTheoryPoints(10),
                    '+1 Fähigkeit': () => _grants(ref).addAbilityPoints(1),
                    '+5 Fähigkeit': () => _grants(ref).addAbilityPoints(5),
                  },
                ),
                const _Note(
                  'Fähigkeitspunkte werden gespeichert, wirken aber noch '
                  'nicht — das Feature aus ADR-0013 ist nicht gebaut.',
                ),

                const _SectionTitle('Kampfwerte'),
                _ButtonRow(
                  entries: <String, VoidCallback>{
                    'Angriff +100': () => _grants(ref).addStats(attack: 100),
                    'Angriff +1000': () => _grants(ref).addStats(attack: 1000),
                    'Leben +500': () => _grants(ref).addStats(maxHp: 500),
                    'Leben +5000': () => _grants(ref).addStats(maxHp: 5000),
                    'Abwehr +100': () => _grants(ref).addStats(defense: 100),
                    'Mana +50': () => _grants(ref).addStats(mana: 50),
                  },
                ),
                const _Note(
                  'Im Kampfmassstab, wie der Wurf eines Ausrüstungsstücks — '
                  'Level, Seltenheit und Tagesform vervielfachen ihn noch. '
                  '„Nur Zuschläge zurücksetzen“ nimmt sie wieder weg.',
                ),

                const _SectionTitle('Grube'),
                _EbenenWahl(
                  onHinab: (ebene) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PitScreen(stage: PitStage(ebene)),
                    ),
                  ),
                  onSpringen: (ebene) =>
                      ref.read(ladderProvider.notifier).devSpringeZu(ebene),
                ),
                const _Note(
                  '„Hinab“ startet einen Lauf auf dieser Ebene, ohne die '
                  'Reihe zu ändern — ein Sieg zählt dort nicht, Beute schon. '
                  '„Dorthin“ setzt die Reihe so, dass die Ebene die nächste '
                  'ist; alles darunter gilt als geschafft. In der Grube '
                  'öffnet der Kolben oben rechts die Werkbank: Funde jeder '
                  'Seltenheit und Gegner jeder Art.',
                ),

                const _SectionTitle('Ausrüstung'),
                _ButtonRow(
                  entries: <String, VoidCallback>{
                    'Alles schenken': actions.grantAllItems,
                  },
                ),
                _ItemPicker(onPick: actions.grantItem),

                const _SectionTitle('Fähigkeiten'),
                _ButtonRow(
                  entries: <String, VoidCallback>{
                    'Alle freischalten': _grants(ref).grantAllAbilities,
                  },
                ),
                _AbilityPicker(onPick: _grants(ref).grantAbility),

                const _SectionTitle('Tagesgrube'),
                _ButtonRow(
                  entries: <String, VoidCallback>{
                    'Versuch von heute freigeben': () => ref
                        .read(dailyPitProvider.notifier)
                        .reset(dayNumberOf(ref.read(todayProvider))),
                  },
                ),
                const _Note(
                  'Ein Versuch am Tag (ADR-0072). Der Knopf löscht den von '
                  'heute, damit sich die Tagesgrube mehrmals ausprobieren '
                  'lässt — die Karte bleibt dieselbe.',
                ),

                const SizedBox(height: 24),
                const _SectionTitle('Prototypen'),
                const _Note(
                  'Echtzeit-Kampf in einer Halle voller Gegner. Steht '
                  'neben dem rundenbasierten Kampf, nicht an seiner '
                  'Stelle — nichts davon berührt einen Spielstand.',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ActionPrototypeScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.sports_martial_arts, size: 18),
                    label: const Text('Die Grube (Echtzeit-Prototyp)'),
                  ),
                ),
                const _Note(
                  'Das Dorf: statt der Kreise ein Ort zum Herumlaufen — '
                  'Bücherei, Höhle, Laden, Brett und das eigene Haus. '
                  'Führt in die echten Bildschirme, auf dem Stand, der '
                  'gerade geladen ist.',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const VillageScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.holiday_village, size: 18),
                    label: const Text('Das Dorf (Prototyp)'),
                  ),
                ),

                const _SectionTitle('Große Knöpfe'),
                const SizedBox(height: 4),
                FilledButton.icon(
                  onPressed: () => _confirm(
                    context,
                    title: 'Alles freischalten?',
                    body:
                        'Jeder Knoten geöffnet und bestanden, jedes Stück im '
                        'Besitz, jede Fähigkeit offen, reichlich Punkte.',
                    onYes: actions.unlockAll,
                  ),
                  icon: const Icon(Icons.lock_open_outlined),
                  label: const Text('Alles freischalten'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirm(
                    context,
                    title: 'Zuschläge zurücksetzen?',
                    body:
                        'Geschenkte XP, Gold und Punkte gehen auf 0. Was du '
                        'im Dev-Stand echt gespielt hast, bleibt.',
                    onYes: _grants(ref).resetGrants,
                  ),
                  icon: const Icon(Icons.undo),
                  label: const Text('Nur Zuschläge zurücksetzen'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirm(
                    context,
                    title: 'Dev-Stand komplett löschen?',
                    body:
                        'Alles weg: Lektionen, Häkchen, Ausrüstung, '
                        'Zuschläge. Wie ein frisch installiertes Spiel.\n\n'
                        'Dein echter Spielstand ist davon nicht betroffen.',
                    danger: true,
                    onYes: () => _eraseDevSave(context, ref),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Palette.enemyOnDark,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Dev-Stand komplett löschen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DevController _grants(WidgetRef ref) => ref.read(devGrantsProvider.notifier);

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required VoidCallback onYes,
    bool danger = false,
  }) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => HolzDialog(
        child: AlertDialog(
          backgroundColor: Palette.surfaceRaised,
          title: Text(title),
          content: Text(body),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: danger
                  ? FilledButton.styleFrom(backgroundColor: Palette.enemy)
                  : null,
              child: const Text('Ja'),
            ),
          ],
        ),
      ),
    );

    if (!(yes ?? false)) return;

    // **Erst nach dem Frame handeln, nicht sofort.**
    //
    // `showDialog` kehrt zurück, sobald `Navigator.pop` gerufen wurde --
    // der Dialog wird zu dem Zeitpunkt aber noch abgebaut. „Alles
    // freischalten" ändert rund 25 Provider-Zustände auf einen Schlag
    // (Theorie, neun Ausrüstungsstücke, Fähigkeiten, Punkte). Fällt das
    // in den Abbau, versucht Riverpod die Scope neu zu bauen, während
    // `PhoneFrame`s `LayoutBuilder` noch rechnet:
    //
    //     setState() or markNeedsBuild() called during build
    //
    // Ein Bildaufbau später ist alles ruhig, und dieselben Änderungen
    // laufen durch einen normalen Rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) => onYes());
  }

  Future<void> _eraseDevSave(BuildContext context, WidgetRef ref) async {
    await ref.read(devSaveEraserProvider)();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dev-Stand gelöscht. App neu laden, um ihn zu leeren.'),
      ),
    );
  }
}

/// Löscht den Dev-Stand im Speicher. Wird in `main.dart` überschrieben;
/// ohne Überschreibung passiert nichts — Tests sollen nichts löschen.
final devSaveEraserProvider = Provider<Future<void> Function()>(
  (ref) => () async {},
);

class _SlotBanner extends StatelessWidget {
  const _SlotBanner({required this.slot});

  final SaveSlot slot;

  @override
  Widget build(BuildContext context) {
    final isDev = slot.isDev;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDev ? const Color(0xFF3A2A12) : const Color(0xFF33150C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDev ? Palette.goldOnDark : Palette.enemyOnDark,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isDev ? Icons.science_outlined : Icons.warning_amber_outlined,
            color: isDev ? Palette.goldOnDark : Palette.enemyOnDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isDev
                  ? 'Dev-Stand aktiv. Dein echter Fortschritt ist unberührt.'
                  : 'ACHTUNG: Echter Stand aktiv. Erst auf den Dev-Stand '
                        'wechseln, sonst verfälschst du den 30-Tage-Nachweis.',
              style: const TextStyle(fontSize: 12, color: Palette.textOnDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentValues extends ConsumerWidget {
  const _CurrentValues();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(playerLevelProvider);
    final kampf = ref.watch(heroPowerProvider).stats;
    final geschenkt = ref.watch(grantedStatsProvider);
    final zeilen = <String, String>{
      'Angriff · Leben · Abwehr im Kampf':
          '${kampf.combatAttack} · ${kampf.combatMaxHp} · '
          '${kampf.combatDefense}',
      'davon geschenkt (vor Level)':
          '+${geschenkt.attack} · +${geschenkt.maxHp} · '
          '+${geschenkt.defense} · Mana +${geschenkt.mana}',
      'Nächste Ebene der Grube':
          '${ref.watch(ladderProvider).highestDefeated + 1}',
      'Level': '${level.level}',
      'Erfahrung':
          '${ref.watch(effectiveXpProvider)}'
          ' (davon ${ref.watch(grantedXpProvider)} geschenkt)',
      'Gold':
          '${ref.watch(goldProvider)}'
          ' (davon ${ref.watch(grantedGoldProvider)} geschenkt)',
      'Theoriepunkte frei': '${ref.watch(availableTheoryPointsProvider)}',
      'Fähigkeitspunkte': '${ref.watch(grantedAbilityPointsProvider)}',
      'Stücke im Besitz':
          '${ref.watch(loadoutProvider).everOwnedCount} / ${GearCatalog.all.length}',
      'Seiten bestanden':
          '${ref.watch(passedPagesProvider)} / ${ref.watch(totalPagesProvider)}',
    };

    return HolzKarte(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          for (final zeile in zeilen.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      zeile.key,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Palette.textDim,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      zeile.value,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Palette.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: Palette.textOnDarkDim,
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Palette.textOnDarkDim),
      ),
    );
  }
}

class _ButtonRow extends StatelessWidget {
  const _ButtonRow({required this.entries});

  final Map<String, VoidCallback> entries;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final entry in entries.entries)
          FilledButton.tonal(
            onPressed: entry.value,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(entry.key),
          ),
      ],
    );
  }
}

/// Ein Zahlenfeld für krumme Werte.
class _FreeInput extends StatefulWidget {
  const _FreeInput({required this.label, required this.onSubmit});

  final String label;
  final void Function(int value) onSubmit;

  @override
  State<_FreeInput> createState() => _FreeInputState();
}

class _FreeInputState extends State<_FreeInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value == 0) return;

    widget.onSubmit(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                isDense: true,
                labelText: '${widget.label} frei eingeben',
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: _submit, child: const Text('Geben')),
        ],
      ),
    );
  }
}

/// Eine Ebene eingeben, dann hinab oder dorthin springen.
class _EbenenWahl extends StatefulWidget {
  const _EbenenWahl({required this.onHinab, required this.onSpringen});

  final void Function(int ebene) onHinab;
  final void Function(int ebene) onSpringen;

  @override
  State<_EbenenWahl> createState() => _EbenenWahlState();
}

class _EbenenWahlState extends State<_EbenenWahl> {
  final TextEditingController _controller = TextEditingController(text: '20');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _ebene {
    final wert = int.tryParse(_controller.text.trim());
    if (wert == null) return null;
    return wert.clamp(1, PitStage.count);
  }

  void _mit(void Function(int) handlung) {
    final ebene = _ebene;
    if (ebene != null) handlung(ebene);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            key: const ValueKey<String>('dev-ebene'),
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Ebene (1–${PitStage.count})',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          key: const ValueKey<String>('dev-hinab'),
          onPressed: () => _mit(widget.onHinab),
          child: const Text('Hinab'),
        ),
        const SizedBox(width: 6),
        OutlinedButton(
          key: const ValueKey<String>('dev-dorthin'),
          onPressed: () => _mit(widget.onSpringen),
          child: const Text('Dorthin'),
        ),
      ],
    );
  }
}

class _ItemPicker extends StatelessWidget {
  const _ItemPicker({required this.onPick});

  final void Function(String itemId) onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (final item in GearCatalog.all)
            Druck(
              child: ActionChip(
                label: Text(item.name, style: const TextStyle(fontSize: 11)),
                onPressed: () => onPick(item.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _AbilityPicker extends StatelessWidget {
  const _AbilityPicker({required this.onPick});

  final void Function(String moveId) onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (final ability in <Ability>[
            ...AbilityCatalog.choosable,
            ...AbilityCatalog.ultimates,
          ])
            Druck(
              child: ActionChip(
                label: Text(
                  pitNameOf(ability.moveId) ?? ability.moveId,
                  style: const TextStyle(fontSize: 11),
                ),
                onPressed: () => onPick(ability.moveId),
              ),
            ),
        ],
      ),
    );
  }
}

/// Schaltet zwischen echtem Stand und Dev-Stand um.
///
/// **Der Wechsel braucht einen Neustart der App**, und das ist kein
/// Schönheitsfehler: Der Spielstand wird einmal vor `runApp` gelesen
/// (ADR-0010), und jeder Controller baut seinen Anfangszustand daraus.
/// Einen davon mitten im Betrieb auszutauschen hieße, alle gleichzeitig
/// zurückzusetzen — mit dem Risiko, dass einer es nicht mitbekommt und
/// Daten des einen Standes in den anderen schreibt.
class _SlotSwitch extends ConsumerWidget {
  const _SlotSwitch({required this.slot});

  final SaveSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ziel = slot.isDev ? SaveSlot.real : SaveSlot.dev;

    return OutlinedButton.icon(
      onPressed: () async {
        await ref.read(slotSwitcherProvider)(ziel);
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Beim nächsten Start wird der ${ziel.label} geladen. '
              'Jetzt neu laden.',
            ),
          ),
        );
      },
      icon: const Icon(Icons.swap_horiz),
      label: Text('Auf ${ziel.label} umschalten'),
    );
  }
}

/// Merkt sich den gewünschten Stand für den nächsten Start. Wird in
/// `main.dart` überschrieben; ohne Überschreibung passiert nichts.
final slotSwitcherProvider = Provider<Future<void> Function(SaveSlot)>(
  (ref) => (_) async {},
);
