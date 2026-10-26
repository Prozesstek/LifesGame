/// Das Blatt, das ein Ausrüstungsstück vollständig erklärt, samt dem
/// Exemplar, das angetippt wurde (ADR-0057).
///
/// **Nur dieses eine** (AktivesBrett, 26.10.): Bis dahin standen darunter
/// alle eigenen Exemplare desselben Stücks, jedes mit Anlegen, Verkaufen
/// und Schloss. Wer im Rucksack eins antippt, meint dieses; die anderen
/// liegen daneben als eigene Kachel. Wie viele es gibt, sagt weiter die
/// Zeile zur Herkunft. Ohne Exemplar (aus der Sammlung) bleiben die
/// Werte allein.
///
/// **Es kommt auch bei Stücken, die man nicht hat.** Dieselbe Hausregel
/// wie bei den Fähigkeiten (ADR-0049): Ein graues Stück, das beim
/// Antippen nichts sagt, ist eine Sackgasse, eines mit Werten, Preis
/// und Sperre ist ein Ziel.
///
/// **Es liest den Spielstand selbst** (`ConsumerWidget`), statt ihn beim
/// Öffnen mitzubekommen. Wer im Blatt anlegt oder verkauft, sieht die
/// Änderung sofort darin, ohne es schließen zu müssen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../../action/pit_text.dart';
import '../../combat/ladder_controller.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';
import '../gear_controller.dart';
import '../gear_icon.dart';
import '../sell_flow.dart';
import '../weapon_ability_line.dart';
import 'copy_stats.dart';
import 'rarity_badge.dart';

/// Zeigt das Blatt zu [item] — mit [exemplar], wenn ein bestimmtes
/// angetippt wurde.
Future<void> showGearSheet(
  BuildContext context,
  GearItem item, {
  GearCopy? exemplar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: true,
    builder: (_) => GearSheet(item: item, exemplar: exemplar),
  );
}

class GearSheet extends ConsumerWidget {
  const GearSheet({required this.item, this.exemplar, super.key});

  final GearItem item;

  /// Das angetippte Exemplar. Nur dieses steht im Blatt, und nur solange
  /// es noch da ist.
  final GearCopy? exemplar;

  static const double _bildSeite = 52;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadout = ref.watch(loadoutProvider);
    final rung = ref.watch(ladderProvider).highestDefeated;
    final heute = ref.watch(dailyOffersProvider);
    final getragen = loadout.equippedCopyIn(item.slot);
    final eigene = <GearCopy>[
      for (final copy in loadout.copiesIn(item.slot))
        if (copy.itemId == item.id) copy,
    ];
    final dieses = <GearCopy>[
      for (final copy in eigene)
        if (copy.uid == exemplar?.uid) copy,
    ].firstOrNull;
    final offen = GearGates.isOpen(item.rarity, highestRung: rung);
    final imLaden = heute.any((c) => c.itemId == item.id);
    final set = GearSets.byId(item.setId);
    final faehigkeit = itemAbilityText(item);
    final pfad = GearIcons.forItemId(item.id);

    return HolzBlatt(
      child: SafeArea(
        child: ConstrainedBox(
          // Ein Stück mit Set und Fähigkeit wird lang. Höher als vier
          // Fünftel des Bildschirms wäre es nicht mehr als Blatt zu
          // erkennen, dann scrollt es lieber.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Das Bild im Rahmen seiner Seltenheit, wie auf der
                  // Kachel, von der man kommt.
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Palette.surfaceRaised,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: RarityBadge.rahmenOf(item.rarity),
                        width: RarityBadge.rahmenBreite,
                      ),
                    ),
                    child: pfad != null
                        ? PixelArt(
                            assetPath: pfad,
                            side: _bildSeite,
                            fallback: _ersatz(),
                          )
                        : _ersatz(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: RarityBadge.colorOf(item.rarity),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            RarityBadge(rarity: item.rarity),
                            Text(
                              item.slot.label,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Palette.textDim,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.why,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Palette.textDim,
                ),
              ),
              const SizedBox(height: 14),
              for (final (label, wert) in _werte(item))
                _Zeile(label: label, wert: wert),
              if (faehigkeit != null) _Zeile(label: 'Kampf', wert: faehigkeit),
              if (set != null) ...<Widget>[
                _Zeile(label: 'Set', wert: '„${set.name}"'),
                _Zeile(
                  label: '${GearSet.smallSize} Teile',
                  wert: setPerkText(set, set.twoPiece),
                ),
                _Zeile(
                  label: '${GearSet.fullSize} Teile',
                  wert: setPerkText(set, set.fourPiece),
                ),
                _Zeile(
                  label: 'Getragen',
                  wert:
                      '${loadout.equippedPiecesOf(set.id)} von '
                      '${GearSet.fullSize}',
                ),
              ],
              _Zeile(label: 'Preis', wert: '${item.price} Gold'),
              _Zeile(label: 'Verkauf', wert: '${Loadout.refundFor(item)} Gold'),
              const SizedBox(height: 12),
              _Herkunft(
                besessen: eigene.length,
                offen: offen,
                sprosse: GearGates.rungFor(item.rarity),
                imLaden: imLaden,
              ),
              if (dieses != null) ...<Widget>[
                const SizedBox(height: 16),
                _Exemplar(
                  copy: dieses,
                  worn: getragen,
                  istAngelegt: loadout.isEquipped(dieses.uid),
                  slot: item.slot,
                  // **Über das Blatt, nicht über das Exemplar**: Verkauft,
                  // verschwindet das Exemplar samt seinem Kontext, und mit
                  // ihm Feier und Schließen. Das Blatt bleibt, bis die Feier
                  // vorbei ist, und geht dann zu.
                  onVerkaufen: () => sellWithConfirm(
                    context,
                    ref,
                    dieses,
                    danach: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _ersatz() {
    return SizedBox.square(
      dimension: _bildSeite,
      child: Icon(GearIcons.fallbackFor(item.slot), color: Palette.accent),
    );
  }

  /// Die Grundwerte des Katalogs, im Kampfmassstab, und was die
  /// Seltenheit vervielfacht.
  ///
  /// **„Grundwert", weil jedes Exemplar anders würfelt** (85–115 %,
  /// ADR-0048). Was ein bestimmtes Stück bringt, steht darunter beim
  /// Exemplar; hier steht, womit man bei diesem Stück rechnen kann.
  static List<(String, String)> _werte(GearItem item) {
    final grund = item.bonus.scaled;
    return <(String, String)>[
      if (grund.attack != 0) ('Angriff', '+${grund.attack}'),
      if (grund.maxHp != 0) ('Lebenspunkte', '+${grund.maxHp}'),
      if (grund.defense != 0) ('Verteidigung', '+${grund.defense}'),
      if (grund.maxEnergy != 0) ('Energie', '+${grund.maxEnergy}'),
      ('Wurf', '85 bis 115 % dieser Werte'),
      // Nur Waffe und Rüstung vervielfachen (ADR-0042), und nur, wenn
      // die Seltenheit es überhaupt tut: Gewöhnlich ist ×1.
      if (item.rarity.powerFactor != 1 && item.slot == GearSlot.waffe)
        (
          'Seltenheit',
          'Angriff im Kampf ×${pitNumber(item.rarity.powerFactor)}',
        ),
      if (item.rarity.powerFactor != 1 && item.slot == GearSlot.ruestung)
        ('Seltenheit', 'Leben im Kampf ×${pitNumber(item.rarity.powerFactor)}'),
    ];
  }
}

/// Eine Zeile der Tabelle: Name links, Wert rechts.
class _Zeile extends StatelessWidget {
  const _Zeile({required this.label, required this.wert});

  final String label;
  final String wert;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Beide dürfen schrumpfen (`gotchas.md`, zwei Texte in einer
          // Row). Eine Set-Wirkung ist lang.
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Palette.textDim),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 2,
            child: Text(
              wert,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ob man es hat, und wenn nicht, woher es kommt.
class _Herkunft extends StatelessWidget {
  const _Herkunft({
    required this.besessen,
    required this.offen,
    required this.sprosse,
    required this.imLaden,
  });

  final int besessen;

  /// Ob die Seltenheit schon kaufbar ist (`GearGates`).
  final bool offen;

  /// Ab welcher Stufe der Grube sie es ist.
  final int sprosse;

  /// Ob es heute im Tagesladen liegt.
  final bool imLaden;

  @override
  Widget build(BuildContext context) {
    final (IconData zeichen, Color farbe, String text) = switch (besessen) {
      > 0 => (
        Icons.check_circle_outline,
        Palette.success,
        besessen == 1 ? 'Im Besitz.' : '$besessen Mal im Besitz.',
      ),
      _ when !offen => (
        Icons.lock_outline,
        Palette.gold,
        'Verdient ab Stufe $sprosse der Grube. Danach im Tagesladen und '
            'als Beute des Wächters.',
      ),
      _ when imLaden => (
        Icons.storefront_outlined,
        Palette.accent,
        'Noch nicht im Besitz. Heute im Tagesladen!',
      ),
      _ => (
        Icons.help_outline,
        Palette.gold,
        'Noch nicht im Besitz. Kommt aus dem Tagesladen und als Beute des '
            'Wächters.',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: farbe.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: farbe.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: <Widget>[
          Icon(zeichen, size: 16, color: farbe),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: farbe)),
          ),
        ],
      ),
    );
  }
}

/// Ein eigenes Exemplar: sein Wurf gegen das Getragene, und was man damit
/// tun kann.
class _Exemplar extends ConsumerWidget {
  const _Exemplar({
    required this.copy,
    required this.worn,
    required this.istAngelegt,
    required this.slot,
    required this.onVerkaufen,
  });

  final GearCopy copy;
  final GearSlot slot;
  final VoidCallback onVerkaufen;

  /// So breit steht die Spalte der Knöpfe — genug für „Verkaufen“ und
  /// „Gesperrt“ samt Schloss auf einer Planke.
  static const double _knopfBreite = 124;

  /// **Alle vier Knöpfe sind Planken** (AktivesBrett, 26.10.): Bis dahin
  /// war nur „Anlegen“ aus Holz, die übrigen standen als bloßer Text
  /// darunter. Schmaler eingerückt als sonst, damit das Wort auf die
  /// Planke passt.
  static final ButtonStyle _planke = FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 8),
  );
  final GearCopy? worn;
  final bool istAngelegt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gesperrt = ref.watch(loadoutProvider).isLocked(copy.uid);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Palette.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: istAngelegt ? Palette.accent : Palette.surfaceSunken,
          width: istAngelegt ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (istAngelegt)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Text(
                      'Angelegt',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Palette.accent,
                      ),
                    ),
                  ),
                // Der Vergleich zeigt, was dieser Wurf gegen das
                // Getragene bringt, beim angelegten selbst gibt es
                // nichts zu vergleichen.
                CopyStats(copy: copy, worn: istAngelegt ? null : worn),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // **Feste Breite**, damit „Anlegen“ und „Verkaufen“ gleich breit
          // untereinanderstehen. Ohne sie hätte die Spalte in der Zeile
          // keine Breite, an der sie sich strecken könnte.
          SizedBox(
            width: _knopfBreite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (istAngelegt)
                  FilledButton(
                    style: _planke,
                    onPressed: () =>
                        ref.read(loadoutProvider.notifier).unequip(slot),
                    child: const Text('Ablegen'),
                  )
                else
                  FilledButton(
                    style: _planke,
                    onPressed: () =>
                        ref.read(loadoutProvider.notifier).equip(copy.uid),
                    child: const Text('Anlegen'),
                  ),
                const SizedBox(height: 6),
                // **Gesperrtes lässt sich nicht verkaufen** (Issue #137),
                // also steht der Knopf erst wieder da, wenn es frei ist.
                if (!gesperrt) ...<Widget>[
                  FilledButton(
                    style: _planke,
                    onPressed: onVerkaufen,
                    child: const Text('Verkaufen'),
                  ),
                  const SizedBox(height: 6),
                ],
                FilledButton.icon(
                  style: _planke,
                  key: ValueKey<String>('schloss-${copy.uid}'),
                  onPressed: () =>
                      ref.read(loadoutProvider.notifier).toggleLock(copy.uid),
                  icon: Icon(
                    gesperrt ? Icons.lock : Icons.lock_open_outlined,
                    size: 16,
                  ),
                  label: Text(gesperrt ? 'Gesperrt' : 'Sperren'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
