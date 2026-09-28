import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../achievements/show_achievement_unlock.dart';
import '../combat/ladder_controller.dart';
import '../progression/level_provider.dart';
import '../progression/show_level_up.dart';
import '../ui/gold_icon.dart';
import '../ui/palette.dart';
import 'gear_controller.dart';
import 'weapon_ability_line.dart';
import 'widgets/shop_item_cell.dart';
import 'widgets/shop_item_tile.dart';

/// Der Laden — seit ADR-0048 ein **Tagesladen**.
///
/// Sechs Angebote, eins je Platz, aus dem Datum gewürfelt. Jedes ist ein
/// fertiges Exemplar mit eigenen Werten; der Preis hängt an der
/// Seltenheit, nicht am Wurf. Um Mitternacht kommt eine neue Auswahl.
///
/// **Nur noch kaufen** (Issue #88). Bis zum 28.09. hatte der Laden einen
/// zweiten Reiter „Inventar“ mit Anlegen und Verkaufen — dasselbe, was
/// der Ausrüstungs-Bildschirm kann (ADR-0057). Alles Besessene steht
/// jetzt dort, auch „Alles Schlechtere verkaufen“.
///
/// **Die Detailfläche ist nie leer.** Beim Wechsel rückt die Wahl auf das
/// erste Stück. Ein leeres Feld mit „bitte wählen" wäre ein zweiter
/// Schritt für etwas, das ohnehin nur eine Antwort hat.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  static const double maxWidth = 560;

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String? _gewaehlt;

  @override
  Widget build(BuildContext context) {
    final gold = ref.watch(goldProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laden'),
        backgroundColor: Palette.surface,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const GoldIcon(size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '$gold',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Palette.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ShopScreen.maxWidth),
            child: _heute(gold),
          ),
        ),
      ),
    );
  }

  Widget _heute(int gold) {
    final angebote = ref.watch(dailyOffersProvider);
    final loadout = ref.watch(loadoutProvider);
    final rung = ref.watch(ladderProvider).highestDefeated;
    final gewaehlt = angebote.firstWhere(
      (c) => c.uid == _gewaehlt,
      orElse: () => angebote.first,
    );
    final item = gewaehlt.item;
    final block = loadout.blockFor(
      gewaehlt,
      availableGold: gold,
      highestRung: rung,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: <Widget>[
        const Text(
          'Sechs Stücke, jeden Tag neu gewürfelt. Um Mitternacht kommt '
          'eine neue Auswahl.',
          style: TextStyle(fontSize: 12, color: Palette.textOnDarkDim),
        ),
        const SizedBox(height: 10),
        _Raster(
          copies: angebote,
          gewaehlteUid: gewaehlt.uid,
          isOwned: (_) => false,
          isEquipped: (_) => false,
          blockFor: (c) =>
              loadout.blockFor(c, availableGold: gold, highestRung: rung),
          onWaehle: (uid) => setState(() => _gewaehlt = uid),
        ),
        const SizedBox(height: 14),
        if (item != null)
          ShopItemTile(
            copy: gewaehlt,
            block: block,
            missingGold: gewaehlt.paid - gold,
            worn: loadout.equippedCopyIn(item.slot),
            requiredRung: GearGates.rungFor(item.rarity),
            abilityLine: itemAbilityText(item),
            setPieces: loadout.equippedPiecesOf(item.setId ?? ''),
            onBuy: () => _buy(context, ref, gewaehlt),
          ),
      ],
    );
  }

  void _buy(BuildContext context, WidgetRef ref, GearCopy offer) {
    final item = offer.item;
    if (item == null) return;
    final vorherErrungen = achievementsBefore(ref);
    final vorherLevel = levelBefore(ref);
    final block = ref.read(loadoutProvider.notifier).buy(offer);
    if (!context.mounted) return;

    final message = switch (block) {
      null => '${item.name} gekauft.',
      PurchaseBlock.zuWenigGold => 'Dafür reicht das Gold noch nicht.',
      PurchaseBlock.bereitsGekauft => 'Heute schon gekauft.',
      PurchaseBlock.unbekannt => 'Dieses Stück gibt es nicht mehr.',
      PurchaseBlock.gesperrt =>
        'Erst Stufe ${GearGates.rungFor(item.rarity)} der Grube schaffen.',
    };
    _say(context, message);

    // Vier Errungenschaften hängen am Laden (ADR-0033) — hier ist der
    // Moment, in dem sich eine davon überschreiten lässt.
    if (block != null) return;
    _feiern(context, ref, vorherErrungen, vorherLevel);
  }

  /// Errungenschaften im Laden zahlen auch Erfahrung (ADR-0033).
  void _feiern(
    BuildContext context,
    WidgetRef ref,
    Set<String> vorherErrungen,
    int vorherLevel,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      unawaited(() async {
        await showAchievementUnlocks(context, ref, before: vorherErrungen);
        if (!context.mounted) return;
        await showLevelUp(context, ref, before: vorherLevel);
      }());
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

/// Exemplare als Raster.
///
/// **Kein `GridView` mit `childAspectRatio`.** Der koppelt die Zellenhöhe
/// an die Fensterbreite und hat in diesem Projekt schon einmal eine ganze
/// Knopfreihe verschluckt (`docs/context/gotchas.md`). Hier rechnet
/// [ShopItemCell.sideFor] die Breite aus, und die Höhe steht fest.
class _Raster extends StatelessWidget {
  const _Raster({
    required this.copies,
    required this.gewaehlteUid,
    required this.isOwned,
    required this.isEquipped,
    required this.blockFor,
    required this.onWaehle,
  });

  final List<GearCopy> copies;
  final String? gewaehlteUid;
  final bool Function(GearCopy) isOwned;
  final bool Function(GearCopy) isEquipped;

  /// **Dieselbe Frage wie beim Kaufknopf.** Stünde die Bedingung hier ein
  /// zweites Mal, zeigte die Kachel irgendwann „kaufbar" und der Knopf
  /// „zu teuer" (`gotchas.md`, „Zwei Stellen").
  final PurchaseBlock? Function(GearCopy) blockFor;
  final void Function(String uid) onWaehle;

  /// Höhe einer Kachel. Fest, damit sie nicht an der Fensterbreite hängt;
  /// 141 lässt dem Bild rund 90 Punkte, also wird ein 256er Bild knapp
  /// vergrössert statt verkleinert.
  static const double _hoehe = 141;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breite = ShopItemCell.sideFor(constraints.maxWidth);
        return Wrap(
          spacing: ShopItemCell.gap,
          runSpacing: ShopItemCell.gap,
          children: <Widget>[
            for (final copy in copies)
              SizedBox(
                width: breite,
                height: _hoehe,
                child: ShopItemCell(
                  copy: copy,
                  isSelected: copy.uid == gewaehlteUid,
                  isOwned: isOwned(copy),
                  isEquipped: isEquipped(copy),
                  block: blockFor(copy),
                  onTap: () => onWaehle(copy.uid),
                ),
              ),
          ],
        );
      },
    );
  }
}
