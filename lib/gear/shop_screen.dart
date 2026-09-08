import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../progression/level_provider.dart';
import '../ui/palette.dart';
import 'gear_controller.dart';
import 'weapon_ability_line.dart';
import 'widgets/shop_item_cell.dart';
import 'widgets/shop_item_tile.dart';

/// Der Laden — der einzige Ort, an dem Gold wieder verschwindet.
///
/// Ohne ihn war Gold eine Zahl, die nur wuchs. Das Konzept nennt
/// Gewohnheiten und Theorie ausdrücklich „Einnahme" und alles Weitere
/// „Ausgabe" (Abschnitt 1); bis hierher fehlte die zweite Hälfte.
///
/// **Seit Issue #35 ein Reiter je Platz statt einer Liste.** Mit
/// siebenundzwanzig Stücken war der Laden eine Rolle von rund fünftausend
/// Pixeln: Wer Ringe vergleichen wollte, scrollte an vier Plätzen vorbei
/// und hatte den ersten Ring vergessen, bevor er den letzten sah. Jetzt
/// liegt ein Platz auf einem Bildschirm — Raster oben, Einzelheiten
/// unten.
///
/// **Die Detailfläche ist nie leer.** Beim Wechsel des Reiters rückt die
/// Wahl auf das erste Stück des neuen Platzes. Ein leeres Feld mit „bitte
/// wählen" wäre ein zweiter Schritt für etwas, das ohnehin nur eine
/// Antwort hat.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  static const double maxWidth = 560;

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  GearSlot _slot = GearSlot.values.first;
  late String _itemId = GearCatalog.forSlot(_slot).first.id;

  void _waehleSlot(GearSlot slot) {
    setState(() {
      _slot = slot;
      _itemId = GearCatalog.forSlot(slot).first.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gold = ref.watch(goldProvider);
    final loadout = ref.watch(loadoutProvider);

    final items = GearCatalog.forSlot(_slot);
    final gewaehlt = items.firstWhere(
      (item) => item.id == _itemId,
      orElse: () => items.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laden'),
        backgroundColor: Palette.surface,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$gold Gold',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Palette.gold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ShopScreen.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _SlotReiter(
                  aktiv: _slot,
                  equippedIn: loadout.equippedIn,
                  onWaehle: _waehleSlot,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _ItemRaster(
                    items: items,
                    gewaehlteId: gewaehlt.id,
                    loadout: loadout,
                    onWaehle: (id) => setState(() => _itemId = id),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: ShopItemTile(
                      item: gewaehlt,
                      block: loadout.blockFor(gewaehlt.id, availableGold: gold),
                      isEquipped: loadout.isEquipped(gewaehlt.id),
                      missingGold: gewaehlt.price - gold,
                      abilityLine: weaponAbilityLine(gewaehlt),
                      setPieces: gewaehlt.setId == null
                          ? 0
                          : loadout.equippedPiecesOf(gewaehlt.setId ?? ''),
                      onBuy: () => _buy(context, ref, gewaehlt),
                      onSell: () => _sell(context, ref, gewaehlt),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _buy(BuildContext context, WidgetRef ref, GearItem item) {
    final block = ref.read(loadoutProvider.notifier).buy(item.id);
    if (!context.mounted) return;

    final message = switch (block) {
      null => '${item.name} gekauft und angelegt.',
      PurchaseBlock.zuWenigGold => 'Dafür reicht das Gold noch nicht.',
      PurchaseBlock.bereitsGekauft => 'Hast du schon.',
      PurchaseBlock.unbekannt => 'Dieses Stück gibt es nicht mehr.',
    };

    _say(context, message);
  }

  /// Verkauft ein Stück — **nach Rückfrage**.
  ///
  /// Anders als der Kauf lässt sich ein Verkauf nicht ohne Verlust
  /// rückgängig machen: Zurück kommt die Hälfte, zurückkaufen kostet den
  /// vollen Preis (ADR-0031). Ein Fehlgriff auf einem Handy wäre damit
  /// teuer, und der Dialog nennt genau diese beiden Zahlen.
  Future<void> _sell(BuildContext context, WidgetRef ref, GearItem item) async {
    final erloes = Loadout.refundFor(item);

    final bestaetigt = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Palette.surface,
        title: Text('${item.name} verkaufen?'),
        content: Text(
          'Das bringt $erloes Gold. Zurückkaufen kostet wieder '
          '${item.price} Gold.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Behalten'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Verkaufen'),
          ),
        ],
      ),
    );

    if (bestaetigt != true || !context.mounted) return;

    // **Erst im nächsten Bild ändern.** `showDialog` kehrt zurück, sobald
    // `Navigator.pop` gerufen wurde — der Dialog wird zu dem Zeitpunkt
    // noch abgebaut. Eine Zustandsänderung, die in diesen Abbau fällt,
    // hat im Entwicklermodus schon einmal „setState called during build"
    // ausgelöst, und zwar nur im Browser: Ein Widget-Test ist dafür kein
    // Nachweis (`docs/context/gotchas.md`).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final erhalten = ref.read(loadoutProvider.notifier).sell(item.id);

      _say(
        context,
        erhalten == null
            ? 'Das besitzt du nicht.'
            : '${item.name} verkauft — $erhalten Gold zurück.',
      );
    });
  }

  void _say(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}

/// Die sechs Plätze als waagerechte Reiterleiste.
///
/// **Waagerecht scrollbar statt gestaucht.** Sechs Reiter nebeneinander
/// auf 390 Pixeln lassen je 65 Pixel — „Talisman" passt dort nicht. Ein
/// abgeschnittenes Wort ist schlimmer als ein Reiter, den man
/// heranschiebt.
class _SlotReiter extends StatelessWidget {
  const _SlotReiter({
    required this.aktiv,
    required this.equippedIn,
    required this.onWaehle,
  });

  final GearSlot aktiv;

  /// Was auf einem Platz getragen wird — `null`, wenn nichts.
  final GearItem? Function(GearSlot) equippedIn;

  final void Function(GearSlot) onWaehle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: <Widget>[
          for (final slot in GearSlot.values) ...<Widget>[
            _Reiter(
              slot: slot,
              istAktiv: slot == aktiv,
              // Ein Punkt an einem Reiter heißt: Dieser Platz ist
              // besetzt. Damit sieht man die Lücken, ohne jeden Reiter
              // einzeln anzutippen.
              istBesetzt: equippedIn(slot) != null,
              onTap: () => onWaehle(slot),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Reiter extends StatelessWidget {
  const _Reiter({
    required this.slot,
    required this.istAktiv,
    required this.istBesetzt,
    required this.onTap,
  });

  final GearSlot slot;
  final bool istAktiv;
  final bool istBesetzt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: istAktiv,
      child: Material(
        color: istAktiv ? Palette.accent : Palette.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  slot.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: istAktiv ? Colors.white : Palette.textDim,
                  ),
                ),
                if (istBesetzt) ...<Widget>[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: istAktiv ? Colors.white : Palette.success,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Die Stücke eines Platzes als Raster.
///
/// **Kein `GridView` mit `childAspectRatio`.** Der koppelt die Zellenhöhe
/// an die Fensterbreite und hat in diesem Projekt schon einmal eine ganze
/// Knopfreihe verschluckt (`docs/context/gotchas.md`). Hier rechnet
/// [ShopItemCell.sideFor] die Breite aus, und die Höhe steht fest.
class _ItemRaster extends StatelessWidget {
  const _ItemRaster({
    required this.items,
    required this.gewaehlteId,
    required this.loadout,
    required this.onWaehle,
  });

  final List<GearItem> items;
  final String gewaehlteId;
  final Loadout loadout;
  final void Function(String) onWaehle;

  /// Höhe einer Kachel. Fest, damit sie nicht an der Fensterbreite hängt:
  /// Bild, zwei Zeilen Name und die Fußnote.
  static const double _hoehe = 104;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breite = ShopItemCell.sideFor(constraints.maxWidth);

        return Wrap(
          spacing: ShopItemCell.gap,
          runSpacing: ShopItemCell.gap,
          children: <Widget>[
            for (final item in items)
              SizedBox(
                width: breite,
                height: _hoehe,
                child: ShopItemCell(
                  item: item,
                  isSelected: item.id == gewaehlteId,
                  isOwned: loadout.isOwned(item.id),
                  isEquipped: loadout.isEquipped(item.id),
                  onTap: () => onWaehle(item.id),
                ),
              ),
          ],
        );
      },
    );
  }
}
