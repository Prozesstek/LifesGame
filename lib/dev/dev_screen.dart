import 'package:abilities/abilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:combat/combat.dart';
import 'package:gear/gear.dart';

import '../gear/gear_controller.dart';
import '../progression/level_provider.dart';
import '../theory/theory_controller.dart';
import '../ui/palette.dart';
import 'dev_actions.dart';
import 'dev_controller.dart';
import 'save_slot.dart';

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

                const SizedBox(height: 24),
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
                    foregroundColor: Palette.enemy,
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
      builder: (context) => AlertDialog(
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
    );

    if (yes ?? false) onYes();
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
        color: isDev ? const Color(0xFF3A2A12) : const Color(0xFF3A1218),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDev ? Palette.gold : Palette.enemy),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isDev ? Icons.science_outlined : Icons.warning_amber_outlined,
            color: isDev ? Palette.gold : Palette.enemy,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isDev
                  ? 'Dev-Stand aktiv. Dein echter Fortschritt ist unberührt.'
                  : 'ACHTUNG: Echter Stand aktiv. Erst auf den Dev-Stand '
                        'wechseln, sonst verfälschst du den 30-Tage-Nachweis.',
              style: const TextStyle(fontSize: 12, color: Colors.white),
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
    final zeilen = <String, String>{
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
          '${ref.watch(loadoutProvider).owned.length} / ${GearCatalog.all.length}',
      'Seiten bestanden':
          '${ref.watch(passedPagesProvider)} / ${ref.watch(totalPagesProvider)}',
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(10),
      ),
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
                        color: Colors.white,
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
          color: Palette.muted,
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
        style: const TextStyle(fontSize: 11, color: Palette.muted),
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
            ActionChip(
              label: Text(item.name, style: const TextStyle(fontSize: 11)),
              onPressed: () => onPick(item.id),
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
          for (final ability in AbilityCatalog.choosable)
            ActionChip(
              label: Text(
                Moves.byId(ability.moveId)?.name ?? ability.moveId,
                style: const TextStyle(fontSize: 11),
              ),
              onPressed: () => onPick(ability.moveId),
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
