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

import '../../combat/ladder_controller.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';
import '../gear_controller.dart';
import '../gear_icon.dart';
import '../sell_flow.dart';
import '../weapon_ability_line.dart';
import '../copy_text.dart';
import 'rarity_badge.dart';
import '../../home/erster_start.dart';
import '../../mentor/zeigefinger.dart';

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
    final kampf = itemAbilityText(item);
    final pfad = GearIcons.forItemId(item.id);
    final angelegt = dieses != null && loadout.isEquipped(dieses.uid);
    // **Gegen das Getragene**, je Wert einzeln (AktivesBrett, 13.11.2026)
    // — nur bei einem Exemplar, das nicht selbst angelegt ist.
    final vergleich = dieses != null && !angelegt
        ? loadout.equippedCopyIn(item.slot)
        : null;

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
                            // **Der Wurf steht beim Namen** (13.11.2026):
                            // Er gehört zu diesem einen Exemplar, wie die
                            // Seltenheit zum Stück.
                            if (dieses != null) _Qualitaet(copy: dieses),
                            if (angelegt)
                              const Text(
                                'Angelegt',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Palette.accent,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // **Die Werte dieses Exemplars**, sonst die des Katalogs mit
              // 100 % — und daneben, um wie viel besser oder schlechter
              // als das Getragene. Den Kasten „Angelegt“ gibt es nicht
              // mehr (13.11.2026), der Unterschied steht in der Zeile.
              for (final zeile in CopyText.lines(
                dieses ?? _katalog(item),
                worn: vergleich,
              ))
                _WertZeile(zeile: zeile),
              if (kampf != null) _Kampf(text: kampf),
              if (set != null) ...<Widget>[
                const SizedBox(height: 6),
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
              // Wer es hat, weiss, dass er es hat. Gesagt wird nur, woher
              // ein Stück kommt, das man nicht hat.
              if (eigene.isEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _Herkunft(
                  offen: offen,
                  sprosse: GearGates.rungFor(item.rarity),
                  imLaden: imLaden,
                ),
              ],
              if (dieses != null) ...<Widget>[
                const SizedBox(height: 16),
                _Knoepfe(
                  copy: dieses,
                  istAngelegt: angelegt,
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
              const SizedBox(height: 10),
              // Ganz unten, was es beim Händler bringt (13.11.2026).
              _Zeile(label: 'Verkauf', wert: '${Loadout.refundFor(item)} Gold'),
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

  /// Das Stück, wie es im Katalog steht: ein Exemplar mit genau 100 %.
  static GearCopy _katalog(GearItem item) =>
      GearCopy(uid: '', itemId: item.id, bonus: item.bonus.scaled, paid: 0);
}

/// „Qualität 108 %" beim Namen — golden, wenn der Wurf gut ist; ein Tipp
/// sagt, was das heisst.
class _Qualitaet extends StatelessWidget {
  const _Qualitaet({required this.copy});

  final GearCopy copy;

  @override
  Widget build(BuildContext context) {
    final gut = CopyText.isGoodRoll(copy);
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      message:
          'Jedes Exemplar würfelt seine Werte: 85 bis 115 % des Stücks im '
          'Katalog.',
      child: Text(
        CopyText.qualitaet(copy),
        style: TextStyle(
          fontSize: 12,
          color: gut ? Palette.accent : Palette.textDim,
          fontWeight: gut ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

/// Was das Stück im Kampf tut, in ganzen Sätzen — Grundangriff, Kraft und
/// was die Seltenheit vervielfacht (`itemAbilityText`).
class _Kampf extends StatelessWidget {
  const _Kampf({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Kampf',
            style: TextStyle(fontSize: 13, color: Palette.textDim),
          ),
          for (final zeile in text.split('\n'))
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                zeile,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
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
            flex: 3,
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Palette.textDim),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 4,
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

/// Ein Wert des Exemplars: Name, Zahl und — gegen das Getragene — der
/// Unterschied, grün besser, rot schlechter.
class _WertZeile extends StatelessWidget {
  const _WertZeile({required this.zeile});

  final StatLine zeile;

  @override
  Widget build(BuildContext context) {
    final d = zeile.diff;
    final farbe = switch (d) {
      null || 0 => Palette.muted,
      > 0 => Palette.success,
      _ => Palette.enemy,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Text(
              zeile.label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Palette.textDim),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              zeile.zahlText,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Palette.text,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              zeile.diffZahl,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: farbe,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Woher ein Stück kommt, das man nicht hat.
class _Herkunft extends StatelessWidget {
  const _Herkunft({
    required this.offen,
    required this.sprosse,
    required this.imLaden,
  });

  /// Ob die Seltenheit schon kaufbar ist (`GearGates`).
  final bool offen;

  /// Ab welcher Stufe der Grube sie es ist.
  final int sprosse;

  /// Ob es heute im Tagesladen liegt.
  final bool imLaden;

  @override
  Widget build(BuildContext context) {
    final (IconData zeichen, Color farbe, String text) = switch (offen) {
      false => (
        Icons.lock_outline,
        Palette.gold,
        'Verdient ab Etage $sprosse im Dungeon. Danach im Tagesladen und '
            'als Beute des Bosses.',
      ),
      true when imLaden => (
        Icons.storefront_outlined,
        Palette.accent,
        'Noch nicht im Besitz. Heute im Tagesladen!',
      ),
      true => (
        Icons.help_outline,
        Palette.gold,
        'Noch nicht im Besitz. Kommt aus dem Tagesladen und als Beute des '
            'Bosses.',
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

/// Was man mit dem Exemplar tun kann: anlegen oder ablegen, verkaufen,
/// sperren — **nebeneinander, alle vier als Holzplanke** (AktivesBrett,
/// 26.10.). Bis zum 13.11.2026 standen sie neben einem Kasten mit den
/// Werten gegen das Getragene; den gibt es nicht mehr.
class _Knoepfe extends ConsumerWidget {
  const _Knoepfe({
    required this.copy,
    required this.istAngelegt,
    required this.slot,
    required this.onVerkaufen,
  });

  final GearCopy copy;
  final bool istAngelegt;
  final GearSlot slot;
  final VoidCallback onVerkaufen;

  /// Schmaler eingerückt als sonst, damit das Wort auf die Planke passt.
  static final ButtonStyle _planke = FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 8),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gesperrt = ref.watch(loadoutProvider).isLocked(copy.uid);
    final knoepfe = <Widget>[
      if (istAngelegt)
        FilledButton(
          style: _planke,
          onPressed: () => ref.read(loadoutProvider.notifier).unequip(slot),
          child: const Text('Ablegen'),
        )
      else
        FilledButton(
          style: _planke,
          onPressed: () => ref.read(loadoutProvider.notifier).equip(copy.uid),
          child: const Text('Anlegen'),
        ),
      // **Gesperrtes und Angelegtes lässt sich nicht verkaufen** (Issue
      // #137; AktivesBrett, 13.11.2026). Der Knopf steht erst wieder da,
      // wenn es frei und abgelegt ist.
      if (!gesperrt && !istAngelegt)
        FilledButton(
          style: _planke,
          onPressed: onVerkaufen,
          child: const Text('Verkaufen'),
        ),
      // Im Rundgang zeigt der Mentor auf das Schloss (07.11.2026).
      Zeigefinger(
        schritt: Schritt.sperren,
        aktiv: !gesperrt,
        radius: 8,
        child: FilledButton.icon(
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
      ),
    ];
    return Row(
      children: <Widget>[
        for (final (i, knopf) in knoepfe.indexed) ...<Widget>[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: knopf),
        ],
      ],
    );
  }
}
