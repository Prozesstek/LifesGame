import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../character/widgets/equipment_slot_tile.dart';
import '../character/widgets/set_card.dart';
import '../combat/ladder_controller.dart';
import '../ui/ausgegraut.dart';
import '../ui/druck.dart';
import '../ui/halten_und_ziehen.dart';
import '../ui/palette.dart';
import '../ui/pixel_art.dart';
import 'gear_controller.dart';
import 'gear_grouping.dart';
import 'gear_icon.dart';
import 'shop_screen.dart';
import 'widgets/gear_sheet.dart';
import 'widgets/rarity_badge.dart';

/// Der Ausrüstungs-Bildschirm: sechs Plätze oben, der ganze Katalog
/// darunter (ADR-0057).
///
/// **Gebaut wie der Fähigkeiten-Bildschirm** (ADR-0049), aus demselben
/// Grund: Im Charakter standen nur die sechs Plätze, und was es sonst zu
/// holen gibt, sah man nur im Laden, und dort nur die sechs Angebote des
/// Tages. Achtundvierzig Stücke, von denen man die meisten nie zu sehen
/// bekommt, sind kein Ziel.
///
/// **Der Katalog, nicht das Inventar.** Jedes Stück steht einmal da,
/// besessene farbig, der Rest grau. Wer ein Stück mehrfach hat, sieht
/// die Zahl auf der Kachel, und im Blatt jedes Exemplar mit seinem Wurf.
/// Das Inventar im Laden bleibt daneben bestehen.
class EquipmentScreen extends ConsumerStatefulWidget {
  const EquipmentScreen({super.key});

  static const double _maxWidth = 560;

  @override
  ConsumerState<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends ConsumerState<EquipmentScreen> {
  /// Die Ordnung des Rasters. Sie gehört zur Ansicht, nicht zum
  /// Spielstand: Wer den Bildschirm wieder öffnet, sieht wieder A bis Z.
  GearGrouping _gruppierung = GearGrouping.values.first;

  /// Drei Spalten für die Plätze, wie bisher im Charakter.
  static const int _slotColumns = 3;

  /// Vier Spalten für den Katalog, wie bei den Fähigkeiten.
  static const int _columns = 4;

  final ScrollController _scroll = ScrollController();

  /// Was gerade gezogen wird, oder null. Die Plätze lesen es, um zu
  /// zeigen, wohin das Stück gehört.
  GearItem? _gezogen;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _beginneZiehen(GearItem item) {
    setState(() => _gezogen = item);
    zuDenPlaetzen(_scroll);
  }

  void _beendeZiehen() {
    if (_gezogen == null) return;
    setState(() => _gezogen = null);
  }

  /// Legt das beste Exemplar des gezogenen Stücks an
  /// (`Loadout.bestCopyOf`). Ein bestimmtes anderes legt man im Blatt an.
  void _lege(GearItem item) {
    final copy = ref.read(loadoutProvider).bestCopyOf(item.id);
    _beendeZiehen();
    if (copy == null) return;
    ref.read(loadoutProvider.notifier).equip(copy.uid);
    HapticFeedback.selectionClick();
    _sage('${item.name} angelegt.');
  }

  /// Ein belegter Platz zeigt das Blatt seines Stücks. Ein leerer sagt,
  /// wie er sich füllt, statt ein Auswahlblatt zu öffnen.
  void _tippePlatz(GearSlot slot, Loadout loadout) {
    final item = loadout.equippedCopyIn(slot)?.item;
    if (item != null) {
      showGearSheet(context, item);
      return;
    }
    _sage(
      loadout.copiesIn(slot).isEmpty
          ? 'Für diesen Platz hast du noch nichts. Stücke kommen aus dem '
                'Laden und als Beute des Wächters.'
          : 'Halte unten ein Stück gedrückt und zieh es hierher.',
    );
  }

  /// Was beim Ziehen unter dem Finger hängt: das Bild des Stücks.
  static Widget _schwebeBild(GearItem item) {
    const seite = HaltenUndZiehen.schwebeSeite - 12;
    final ersatz = Icon(
      GearIcons.fallbackFor(item.slot),
      color: Palette.accent,
    );
    final pfad = GearIcons.forItemId(item.id);
    if (pfad == null) return ersatz;
    return PixelArt(assetPath: pfad, side: seite, fallback: ersatz);
  }

  void _sage(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 3)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final loadout = ref.watch(loadoutProvider);
    final rung = ref.watch(ladderProvider).highestDefeated;
    final besessen = <String>{
      for (final copy in loadout.ownedCopies) copy.itemId,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ausrüstung'),
        backgroundColor: Palette.surface,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: EquipmentScreen._maxWidth,
            ),
            // **Kein ListView.** Eine ListView baut nur, was in der Nähe
            // des Sichtbaren liegt. Wer ein Stück von unten zieht und die
            // Fläche nach oben rollt, bekäme seine Kachel dabei verworfen,
            // und mit ihr das Ende des Ziehens. 48 Kacheln sind wenig genug,
            // um sie alle gebaut zu halten.
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _SectionTitle('Deine sechs Plätze'),
                  const SizedBox(height: 4),
                  Text(
                    '${loadout.equippedCount} von '
                    '${GearSlot.values.length} Plätzen belegt. Antippen '
                    'zeigt die Werte. Zum Wechseln ein Stück unten gedrückt '
                    'halten und auf seinen Platz ziehen.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Palette.textOnDarkDim,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    // Das Raster sitzt in einer ListView: eigene Höhe, kein
                    // eigenes Scrollen. Sonst scrollten zwei Flächen
                    // ineinander.
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: _slotColumns,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.92,
                    children: <Widget>[
                      for (final slot in GearSlot.values)
                        _Ablage(
                          slot: slot,
                          gezogen: _gezogen,
                          onAblegen: _lege,
                          child: (dragState) => EquipmentSlotTile(
                            slot: slot,
                            equipped: loadout.equippedCopyIn(slot),
                            hasAny: loadout.copiesIn(slot).isNotEmpty,
                            dragState: dragState,
                            onTap: () => _tippePlatz(slot, loadout),
                          ),
                        ),
                    ],
                  ),
                  // **Nur sichtbar, wenn etwas anliegt.** Eine Karte, die
                  // „keine Sets" sagt, ist eine Zeile über nichts.
                  if (loadout.wearsAnySetPiece) ...<Widget>[
                    const SizedBox(height: 18),
                    const _SectionTitle('Sets'),
                    const SizedBox(height: 10),
                    SetCard(loadout: loadout),
                  ],
                  const SizedBox(height: 20),
                  const _SectionTitle('Alle Stücke'),
                  const SizedBox(height: 4),
                  Text(
                    '${besessen.length} von ${GearCatalog.all.length} im '
                    'Besitz. Antippen zeigt alle Werte, auch bei den grauen.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Palette.textOnDarkDim,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Gruppenwahl(
                    aktiv: _gruppierung,
                    onWaehle: (g) => setState(() => _gruppierung = g),
                  ),
                  const SizedBox(height: 12),
                  for (final gruppe in groupGear(_gruppierung))
                    ..._gruppe(
                      gruppe,
                      loadout: loadout,
                      besessen: besessen,
                      rung: rung,
                    ),
                  const SizedBox(height: 4),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ShopScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.storefront_outlined),
                    label: const Text('Zum Laden'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Eine Gruppe mit Überschrift und Raster. Das alphabetische Raster hat
  /// keine Überschrift, es ist die eine Gruppe.
  List<Widget> _gruppe(
    GearGroup gruppe, {
    required Loadout loadout,
    required Set<String> besessen,
    required int rung,
  }) {
    final zaehler =
        '${gruppe.items.where((i) => besessen.contains(i.id)).length} '
        'von ${gruppe.items.length}';

    return <Widget>[
      if (gruppe.title case final String titel)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: <Widget>[
              if (gruppe.rarity case final GearRarity stufe)
                RarityBadge(rarity: stufe)
              else
                Flexible(
                  child: Text(
                    titel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Palette.textOnDark,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                zaehler,
                style: const TextStyle(
                  fontSize: 11,
                  color: Palette.textOnDarkDim,
                ),
              ),
            ],
          ),
        ),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: _columns,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.78,
        children: <Widget>[
          for (final item in gruppe.items)
            HaltenUndZiehen<GearItem>(
              data: item,
              bild: _schwebeBild(item),
              rahmenFarbe: RarityBadge.colorOf(item.rarity),
              // **Nur was man hat, lässt sich ziehen.** Ein graues Stück
              // auf einen Platz zu legen hieße, etwas anzulegen, das es
              // nicht gibt.
              aktiv: besessen.contains(item.id),
              onStart: () => _beginneZiehen(item),
              onEnde: _beendeZiehen,
              child: _Kachel(
                item: item,
                anzahl: loadout.ownedCopies
                    .where((c) => c.itemId == item.id)
                    .length,
                angelegt: loadout.equippedCopyIn(item.slot)?.itemId == item.id,
                gesperrt: !GearGates.isOpen(item.rarity, highestRung: rung),
                ausgeblendet: _gezogen?.id == item.id,
                onTap: () => showGearSheet(context, item),
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
    ];
  }
}

/// Ein Platz als Ablageziel: Er nimmt nur Stücke, die auf ihn gehören.
///
/// **Die Regel steht am Stück** (`GearItem.slot`), hier wird sie nur
/// gefragt. Ein Helm, über dem Waffenplatz losgelassen, fliegt zurück.
class _Ablage extends StatelessWidget {
  const _Ablage({
    required this.slot,
    required this.gezogen,
    required this.onAblegen,
    required this.child,
  });

  final GearSlot slot;

  /// Was der Bildschirm gerade gezogen weiß, oder null.
  final GearItem? gezogen;

  final ValueChanged<GearItem> onAblegen;

  /// Baut die Kachel im passenden Zustand.
  final Widget Function(SlotDragState dragState) child;

  @override
  Widget build(BuildContext context) {
    return DragTarget<GearItem>(
      onWillAcceptWithDetails: (details) => details.data.slot == slot,
      onAcceptWithDetails: (details) => onAblegen(details.data),
      builder: (context, kandidaten, _) {
        return child(
          SlotDragState.fuer(
            zieht: gezogen != null,
            passt: gezogen?.slot == slot,
            schwebt: kandidaten.isNotEmpty,
          ),
        );
      },
    );
  }
}

/// Die vier Ordnungen als Reihe von Chips.
class _Gruppenwahl extends StatelessWidget {
  const _Gruppenwahl({required this.aktiv, required this.onWaehle});

  final GearGrouping aktiv;
  final ValueChanged<GearGrouping> onWaehle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: <Widget>[
        for (final g in GearGrouping.values)
          Druck(
            child: ChoiceChip(
              label: Text(g.label),
              selected: g == aktiv,
              onSelected: (_) => onWaehle(g),
              selectedColor: Palette.accentOnDark,
              backgroundColor: Palette.surface,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: g == aktiv ? FontWeight.bold : FontWeight.normal,
                color: Palette.text,
              ),
              showCheckmark: false,
            ),
          ),
      ],
    );
  }
}

/// Ein Stück im Raster.
///
/// **Nicht besessen heißt grau, nicht weg.** Die Zeichnung bleibt
/// erkennbar, damit man weiß, worauf man zuarbeitet. Ein Schloss steht
/// nur da, wo die Seltenheit noch an der Grube hängt (ADR-0034), dort
/// hilft auch Gold nicht.
class _Kachel extends StatelessWidget {
  const _Kachel({
    required this.item,
    required this.anzahl,
    required this.angelegt,
    required this.gesperrt,
    required this.onTap,
    this.ausgeblendet = false,
  });

  final GearItem item;

  /// Wie viele Exemplare man davon besitzt.
  final int anzahl;

  /// Ob eines davon auf seinem Platz liegt.
  final bool angelegt;

  /// Ob die Seltenheit noch gesperrt ist.
  final bool gesperrt;

  /// Ob das Stück gerade gezogen wird. Dann bleibt an seiner Stelle ein
  /// Schatten, und das Stück selbst hängt unter dem Finger.
  final bool ausgeblendet;

  final VoidCallback onTap;

  static const double _bildSeite = 36;

  bool get _besessen => anzahl > 0;

  @override
  Widget build(BuildContext context) {
    final farbe = RarityBadge.colorOf(item.rarity);
    final pfad = GearIcons.forItemId(item.id);
    final ersatz = SizedBox.square(
      dimension: _bildSeite,
      child: Icon(
        GearIcons.fallbackFor(item.slot),
        color: _besessen ? Palette.accent : Palette.muted,
      ),
    );

    return Opacity(
      opacity: ausgeblendet ? 0.3 : 1,
      child: Semantics(
        button: true,
        label: _besessen
            ? '${item.name}, $anzahl im Besitz'
            : '${item.name}, nicht im Besitz',
        child: Druck(
          child: Material(
            color: _besessen ? Palette.surface : Palette.surfaceSunken,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: angelegt
                        ? Palette.accent
                        : farbe.withValues(alpha: _besessen ? 0.7 : 0.25),
                    width: angelegt ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Ausgegraut(
                          aktiv: !_besessen,
                          child: pfad == null
                              ? ersatz
                              : PixelArt(
                                  assetPath: pfad,
                                  side: _bildSeite,
                                  fallback: ersatz,
                                ),
                        ),
                        if (angelegt)
                          const Positioned(
                            right: -2,
                            bottom: -2,
                            child: Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Palette.accent,
                            ),
                          )
                        else if (!_besessen && gesperrt)
                          const Positioned(
                            right: -2,
                            bottom: -2,
                            child: Icon(
                              Icons.lock,
                              size: 12,
                              color: Palette.muted,
                            ),
                          ),
                        if (anzahl > 1)
                          Positioned(
                            left: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Palette.accent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '×$anzahl',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Palette.surface,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.15,
                        color: _besessen ? Palette.text : Palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Palette.textOnDark,
      ),
    );
  }
}
