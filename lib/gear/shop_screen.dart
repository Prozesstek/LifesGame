import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../achievements/show_achievement_unlock.dart';
import '../combat/ladder_controller.dart';
import '../progression/level_provider.dart';
import '../progression/show_level_up.dart';
import '../ui/druck.dart';
import '../ui/gold_icon.dart';
import '../ui/holz.dart';
import '../ui/palette.dart';
import 'gear_controller.dart';
import 'weapon_ability_line.dart';
import 'widgets/shop_item_cell.dart';
import 'widgets/shop_item_tile.dart';

/// Der Laden — seit ADR-0048 ein **Tagesladen** und das Inventar.
///
/// **Heute:** sechs Angebote, eins je Platz, aus dem Datum gewürfelt.
/// Jedes ist ein fertiges Exemplar mit eigenen Werten; der Preis hängt an
/// der Seltenheit, nicht am Wurf. Um Mitternacht kommt eine neue Auswahl.
///
/// **Inventar:** jedes Exemplar, je Platz. Anlegen, verkaufen, und ein
/// Knopf, der alles Schlechtere auf einmal verkauft.
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

enum _Ansicht { heute, inventar }

class _ShopScreenState extends ConsumerState<ShopScreen> {
  _Ansicht _ansicht = _Ansicht.heute;
  GearSlot _slot = GearSlot.values.first;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _Reiterleiste<_Ansicht>(
                  werte: _Ansicht.values,
                  aktiv: _ansicht,
                  label: (a) => a == _Ansicht.heute ? 'Heute' : 'Inventar',
                  onWaehle: (a) => setState(() {
                    _ansicht = a;
                    _gewaehlt = null;
                  }),
                ),
                Expanded(
                  child: _ansicht == _Ansicht.heute
                      ? _heute(gold)
                      : _inventar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Heute ---

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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
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
            isOwned: false,
            isEquipped: false,
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

  // --- Inventar ---

  Widget _inventar() {
    final loadout = ref.watch(loadoutProvider);
    final hier = loadout.copiesIn(_slot);
    final ausschuss = loadout.junk;
    final erloes = ausschuss.fold<int>(
      0,
      (s, c) => s + (c.item == null ? 0 : Loadout.refundFor(c.item!)),
    );
    final gewaehlt =
        hier.where((c) => c.uid == _gewaehlt).firstOrNull ??
        loadout.equippedCopyIn(_slot) ??
        hier.firstOrNull;
    final item = gewaehlt?.item;
    final getragen = loadout.equippedCopyIn(_slot);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: <Widget>[
        if (ausschuss.isNotEmpty) ...<Widget>[
          OutlinedButton.icon(
            onPressed: () => _sellJunk(context, ref, ausschuss.length, erloes),
            icon: const Icon(Icons.cleaning_services_outlined, size: 18),
            label: Text(
              'Alles Schlechtere verkaufen · ${ausschuss.length} Stück, '
              '+$erloes Gold',
            ),
          ),
          const SizedBox(height: 8),
        ],
        _Reiterleiste<GearSlot>(
          werte: GearSlot.values,
          aktiv: _slot,
          label: (s) => '${s.label} ${loadout.copiesIn(s).length}',
          onWaehle: (s) => setState(() {
            _slot = s;
            _gewaehlt = null;
          }),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        if (hier.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Hier liegt noch nichts. Stücke kommen aus dem Laden und als '
              'Beute des Wächters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.textOnDarkDim),
            ),
          )
        else ...<Widget>[
          _Raster(
            copies: hier,
            gewaehlteUid: gewaehlt?.uid,
            isOwned: (_) => true,
            isEquipped: (c) => loadout.isEquipped(c.uid),
            blockFor: (_) => null,
            onWaehle: (uid) => setState(() => _gewaehlt = uid),
          ),
          const SizedBox(height: 14),
          if (gewaehlt != null && item != null)
            ShopItemTile(
              copy: gewaehlt,
              isOwned: true,
              isEquipped: loadout.isEquipped(gewaehlt.uid),
              worn: getragen?.uid == gewaehlt.uid ? null : getragen,
              abilityLine: itemAbilityText(item),
              setPieces: loadout.equippedPiecesOf(item.setId ?? ''),
              onEquip: () =>
                  ref.read(loadoutProvider.notifier).equip(gewaehlt.uid),
              onSell: () => _sell(context, ref, gewaehlt),
            ),
        ],
      ],
    );
  }

  /// Verkauft ein Exemplar — **nach Rückfrage**. Zurück kommt ein
  /// Viertel, und ein Wurf ist danach weg (ADR-0048).
  Future<void> _sell(BuildContext context, WidgetRef ref, GearCopy copy) async {
    final item = copy.item;
    if (item == null) return;
    final erloes = Loadout.refundFor(item);

    final bestaetigt = await _frage(
      context,
      titel: '${item.name} verkaufen?',
      text: 'Das bringt $erloes Gold. Dieser Wurf ist danach weg.',
    );
    if (bestaetigt != true || !context.mounted) return;

    // **Erst im nächsten Bild ändern.** `showDialog` kehrt zurück, sobald
    // `Navigator.pop` gerufen wurde — der Dialog wird zu dem Zeitpunkt
    // noch abgebaut (`docs/context/gotchas.md`).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final vorherErrungen = achievementsBefore(ref);
      final vorherLevel = levelBefore(ref);
      final erhalten = ref.read(loadoutProvider.notifier).sell(copy.uid);
      _say(
        context,
        erhalten == null
            ? 'Das besitzt du nicht.'
            : '${item.name} verkauft — $erhalten Gold zurück.',
      );
      if (erhalten == null) return;
      setState(() => _gewaehlt = null);
      _feiern(context, ref, vorherErrungen, vorherLevel);
    });
  }

  Future<void> _sellJunk(
    BuildContext context,
    WidgetRef ref,
    int anzahl,
    int erloes,
  ) async {
    final bestaetigt = await _frage(
      context,
      titel: '$anzahl Stück verkaufen?',
      text:
          'Alles, was nicht getragen wird und schwächer ist als das '
          'Getragene. Set-Teile, Episches und Legendäres bleiben. '
          'Das bringt $erloes Gold.',
    );
    if (bestaetigt != true || !context.mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final vorherErrungen = achievementsBefore(ref);
      final vorherLevel = levelBefore(ref);
      final erhalten = ref.read(loadoutProvider.notifier).sellJunk();
      _say(context, '$anzahl Stück verkauft — $erhalten Gold zurück.');
      setState(() => _gewaehlt = null);
      _feiern(context, ref, vorherErrungen, vorherLevel);
    });
  }

  Future<bool?> _frage(
    BuildContext context, {
    required String titel,
    required String text,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => HolzDialog(
        child: AlertDialog(
          backgroundColor: Palette.surface,
          title: Text(titel),
          content: Text(text),
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
      ),
    );
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

/// Eine waagerechte Reiterleiste — für „Heute / Inventar" und für die
/// sechs Plätze.
///
/// **Waagerecht scrollbar statt gestaucht.** Sechs Reiter nebeneinander
/// auf 390 Pixeln lassen je 65 Pixel — „Talisman" passt dort nicht. Ein
/// abgeschnittenes Wort ist schlimmer als ein Reiter, den man
/// heranschiebt.
class _Reiterleiste<T> extends StatelessWidget {
  const _Reiterleiste({
    required this.werte,
    required this.aktiv,
    required this.label,
    required this.onWaehle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final List<T> werte;
  final T aktiv;
  final String Function(T) label;
  final void Function(T) onWaehle;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        children: <Widget>[
          for (final wert in werte) ...<Widget>[
            _Reiter(
              text: label(wert),
              istAktiv: wert == aktiv,
              onTap: () => onWaehle(wert),
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
    required this.text,
    required this.istAktiv,
    required this.onTap,
  });

  final String text;
  final bool istAktiv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: istAktiv,
      child: Druck(
        child: Material(
          color: istAktiv ? Palette.accent : Palette.surface,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: istAktiv ? Palette.surface : Palette.textDim,
                ),
              ),
            ),
          ),
        ),
      ),
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
