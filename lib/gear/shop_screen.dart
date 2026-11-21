import 'dart:async';

import 'package:abilities/abilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../achievements/show_achievement_unlock.dart';
import '../character/abilities_controller.dart';
import '../character/show_ability_unlock.dart';
import '../combat/ladder_controller.dart';
import '../home/erster_start.dart';
import '../mentor/mentor.dart';
import '../mentor/mentor_kasten.dart';
import '../mentor/zeigefinger.dart';
import '../progression/level_provider.dart';
import '../progression/show_level_up.dart';
import '../ui/gold_icon.dart';
import '../ui/palette.dart';
import '../ui/schild_leiste.dart';
import 'gear_controller.dart';
import 'widgets/gear_sheet.dart';
import 'widgets/shop_item_cell.dart';

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
/// **Ein Tipp öffnet das Blatt des Stücks** (AktivesBrett, 21.11.2026):
/// dasselbe wie in der Ausrüstung (`GearSheet`), mit dem Wurf, dem
/// Unterschied zum Getragenen und „Kaufen“ statt Anlegen. Bis dahin stand
/// unter dem Raster eine eigene Detailfläche (`ShopItemTile`), die anders
/// aussah als alles, was man nach dem Kauf vom Stück sieht.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  static const double maxWidth = 560;

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  @override
  Widget build(BuildContext context) {
    final gold = ref.watch(goldProvider);

    return Scaffold(
      appBar: SchildLeiste(
        leading: const ZurueckPfeil(schritt: Schritt.sperren),
        titel: 'Laden',
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
      body: MentorFlaeche(
        ort: MentorOrt.laden,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: ShopScreen.maxWidth),
              child: _heute(gold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heute(int gold) {
    final angebote = ref.watch(dailyOffersProvider);
    final loadout = ref.watch(loadoutProvider);
    final rung = ref.watch(ladderProvider).highestDefeated;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: <Widget>[
        _Raster(
          copies: angebote,
          // Ob es schon in der Sammlung steht: je besessen, auch verkauft.
          gesammelt: (c) => loadout.everOwnedIds.contains(c.itemId),
          blockFor: (c) =>
              loadout.blockFor(c, availableGold: gold, highestRung: rung),
          onWaehle: _zeige,
        ),
      ],
    );
  }

  /// Das Blatt des Angebots — „Kaufen“ darin kauft hier, damit die Feier
  /// auf dem Laden läuft und nicht auf dem Blatt, das dabei zugeht.
  void _zeige(GearCopy angebot) {
    final item = angebot.item;
    if (item == null) return;
    unawaited(
      showGearSheet(
        context,
        item,
        angebot: angebot,
        onKaufen: () => _buy(context, ref, angebot),
      ),
    );
  }

  void _buy(BuildContext context, WidgetRef ref, GearCopy offer) {
    final item = offer.item;
    if (item == null) return;
    final vorherErrungen = achievementsBefore(ref);
    final vorherLevel = levelBefore(ref);
    final vorherFaehigkeiten = ref.read(unlockedAbilitiesProvider);
    final block = ref.read(loadoutProvider.notifier).buy(offer);
    if (!context.mounted) return;

    final message = switch (block) {
      null => '${item.name} gekauft.',
      PurchaseBlock.zuWenigGold => 'Dafür reicht das Gold noch nicht.',
      PurchaseBlock.bereitsGekauft => 'Heute schon gekauft.',
      PurchaseBlock.unbekannt => 'Dieses Stück gibt es nicht mehr.',
      PurchaseBlock.gesperrt =>
        'Erst Etage ${GearGates.rungFor(item.rarity)} im Dungeon schaffen.',
    };
    _say(context, message);

    // Vier Errungenschaften hängen am Laden (ADR-0033) — hier ist der
    // Moment, in dem sich eine davon überschreiten lässt.
    if (block != null) return;
    _feiern(context, ref, vorherErrungen, vorherLevel, vorherFaehigkeiten);
  }

  /// Errungenschaften im Laden zahlen auch Erfahrung (ADR-0033).
  void _feiern(
    BuildContext context,
    WidgetRef ref,
    Set<String> vorherErrungen,
    int vorherLevel,
    List<Ability> vorherFaehigkeiten,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      unawaited(() async {
        await showAchievementUnlocks(context, ref, before: vorherErrungen);
        if (!context.mounted) return;
        await showLevelUp(context, ref, before: vorherLevel);
        if (!context.mounted) return;
        // „Beim Händler“ bringt Sammeln (07.11.2026).
        await showAbilityUnlocks(context, ref, before: vorherFaehigkeiten);
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
    required this.gesammelt,
    required this.blockFor,
    required this.onWaehle,
  });

  final List<GearCopy> copies;
  final bool Function(GearCopy) gesammelt;

  /// **Dieselbe Frage wie beim Kaufknopf.** Stünde die Bedingung hier ein
  /// zweites Mal, zeigte die Kachel irgendwann „kaufbar" und der Knopf
  /// „zu teuer" (`gotchas.md`, „Zwei Stellen").
  final PurchaseBlock? Function(GearCopy) blockFor;
  final void Function(GearCopy) onWaehle;

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
                // Der Mentor zeigt im Rundgang auf sein Angebot; im Blatt
                // sitzt sein Punkt dann auf „Kaufen“.
                child: Zeigefinger(
                  schritt: Schritt.laden,
                  aktiv: copy.uid.endsWith('-mentor'),
                  eng: true,
                  radius: 10,
                  child: ShopItemCell(
                    copy: copy,
                    isSelected: false,
                    isOwned: false,
                    isEquipped: false,
                    gesammelt: gesammelt(copy),
                    block: blockFor(copy),
                    onTap: () => onWaehle(copy),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
