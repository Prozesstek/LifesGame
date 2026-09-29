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
import 'sell_flow.dart';
import 'shop_screen.dart';
import 'widgets/character_figure.dart';
import 'widgets/gear_sheet.dart';
import 'widgets/rarity_badge.dart';
import '../ui/gold_icon.dart';

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
/// Seit Issue #88 ist er der einzige Ort für Besessenes: Der Laden hat
/// sein Inventar abgegeben und verkauft nur noch, was es heute gibt.
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

  /// Welche Plätze links und rechts der Figur stehen, von oben nach
  /// unten. Links, was sie am Leib trägt, rechts, was sie hält und
  /// umhängt.
  static const List<GearSlot> _linkeSeite = <GearSlot>[
    GearSlot.helm,
    GearSlot.ruestung,
    GearSlot.schuhe,
  ];
  static const List<GearSlot> _rechteSeite = <GearSlot>[
    GearSlot.waffe,
    GearSlot.ring,
    GearSlot.talisman,
  ];

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
                  _Anziehpuppe(
                    links: _linkeSeite,
                    rechts: _rechteSeite,
                    figur: CharacterFigure(
                      worn: <String>[
                        for (final slot in GearSlot.values)
                          ?loadout.equippedCopyIn(slot)?.itemId,
                      ],
                    ),
                    platz: (slot) => _Ablage(
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
                  ),
                  // **Nur sichtbar, wenn etwas anliegt.** Eine Karte, die
                  // „keine Sets" sagt, ist eine Zeile über nichts.
                  if (loadout.wearsAnySetPiece) ...<Widget>[
                    const SizedBox(height: 16),
                    SetCard(loadout: loadout),
                  ],
                  // **Aus dem Laden hierher** (Issue #88): Seit der Laden
                  // nur noch kauft, steht alles Besessene hier — auch das
                  // Aufräumen. Nur sichtbar, wenn es etwas zu räumen gibt.
                  if (loadout.junk case final ausschuss
                      when ausschuss.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => sellJunkWithConfirm(context, ref),
                      icon: const Icon(
                        Icons.cleaning_services_outlined,
                        size: 18,
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '×${ausschuss.length}',
                            semanticsLabel:
                                'Alles Schlechtere verkaufen, '
                                '${ausschuss.length} Stück, '
                                '${junkRefund(ausschuss)} Gold',
                          ),
                          const SizedBox(width: 10),
                          const GoldIcon(size: 16),
                          const SizedBox(width: 3),
                          Text('+${junkRefund(ausschuss)}', semanticsLabel: ''),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Wie viel man hat, und wie geordnet wird — ohne Worte.
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.backpack_outlined,
                        size: 20,
                        color: Palette.textOnDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${besessen.length} / ${GearCatalog.all.length}',
                        semanticsLabel:
                            '${besessen.length} von '
                            '${GearCatalog.all.length} Stücken im Besitz',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Palette.textOnDark,
                        ),
                      ),
                      const Spacer(),
                      _Gruppenwahl(
                        aktiv: _gruppierung,
                        onWaehle: (g) => setState(() => _gruppierung = g),
                      ),
                    ],
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
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ShopScreen(),
                      ),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      semanticLabel: 'Zum Laden',
                    ),
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
        '/ ${gruppe.items.length}';

    return <Widget>[
      if (gruppe.title case final String titel)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: <Widget>[
              if (gruppe.rarity case final GearRarity stufe)
                RarityBadge(rarity: stufe)
              else if (gruppe.slot case final GearSlot platz)
                Icon(
                  GearIcons.fallbackFor(platz),
                  size: 20,
                  color: Palette.textOnDark,
                  semanticLabel: titel,
                )
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

/// Die Figur in der Mitte, drei Plätze links, drei rechts (Frederik,
/// 28.09.) — wie in einem Rollenspiel, statt eines Rasters darüber.
///
/// **Alle Plätze gleich hoch**, sonst stünde ein Platz mit zweizeiligem
/// Namen höher als sein Nachbar, und die Seiten liefen auseinander.
class _Anziehpuppe extends StatelessWidget {
  const _Anziehpuppe({
    required this.links,
    required this.rechts,
    required this.figur,
    required this.platz,
  });

  final List<GearSlot> links;
  final List<GearSlot> rechts;
  final Widget figur;
  final Widget Function(GearSlot slot) platz;

  static const double platzHoehe = 112;
  static const double abstand = 8;

  Widget _seite(List<GearSlot> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final (i, slot) in slots.indexed) ...<Widget>[
          if (i > 0) const SizedBox(height: abstand),
          SizedBox(height: platzHoehe, child: platz(slot)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(flex: 3, child: _seite(links)),
        const SizedBox(width: abstand),
        Expanded(
          flex: 4,
          child: SizedBox(
            height: 3 * platzHoehe + 2 * abstand,
            child: Center(child: figur),
          ),
        ),
        const SizedBox(width: abstand),
        Expanded(flex: 3, child: _seite(rechts)),
      ],
    );
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final g in GearGrouping.values)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Druck(
              child: ChoiceChip(
                label: Icon(
                  _zeichen(g),
                  size: 18,
                  color: Palette.text,
                  semanticLabel: g.label,
                ),
                labelPadding: EdgeInsets.zero,
                padding: const EdgeInsets.all(6),
                selected: g == aktiv,
                onSelected: (_) => onWaehle(g),
                selectedColor: Palette.accentOnDark,
                backgroundColor: Palette.surface,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
      ],
    );
  }

  static IconData _zeichen(GearGrouping g) => switch (g) {
    GearGrouping.alphabetisch => Icons.sort_by_alpha_rounded,
    GearGrouping.platz => Icons.accessibility_new_rounded,
    GearGrouping.seltenheit => Icons.diamond_outlined,
    GearGrouping.set => Icons.link_rounded,
  };
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
