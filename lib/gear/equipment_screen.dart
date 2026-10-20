import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../character/widgets/equipment_slot_tile.dart';
import '../character/widgets/set_card.dart';
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
import '../sammlung/sammlung.dart';
import '../sammlung/sammlung_knopf.dart';

/// Der Ausrüstungs-Bildschirm: sechs Plätze oben, darunter der Rucksack
/// (ADR-0057, Issue #137).
///
/// **Gebaut wie der Fähigkeiten-Bildschirm** (ADR-0049), aus demselben
/// Grund: Im Charakter standen nur die sechs Plätze, und was es sonst zu
/// holen gibt, sah man nur im Laden, und dort nur die sechs Angebote des
/// Tages. Achtundvierzig Stücke, von denen man die meisten nie zu sehen
/// bekommt, sind kein Ziel.
///
/// **Seit Issue #137 das Inventar, nicht der Katalog** — wie bei Diablo:
/// Jedes Exemplar, das nicht getragen wird, ist eine Kachel, mit einem
/// Pfeil, ob es besser, gleich oder schlechter ist als das Getragene,
/// und einem Schloss, wenn es gesperrt ist. Was man noch nie hatte, steht
/// in der Sammlung (ADR-0080). Bis dahin stand hier der ganze Katalog,
/// Nicht-Besessenes grau.
///
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
  GearCopy? _gezogen;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _beginneZiehen(GearCopy copy) {
    setState(() => _gezogen = copy);
    zuDenPlaetzen(_scroll);
  }

  void _beendeZiehen() {
    if (_gezogen == null) return;
    setState(() => _gezogen = null);
  }

  /// Legt genau das gezogene Exemplar an — seit jedes eine eigene
  /// Kachel hat, ist klar, welches gemeint ist.
  void _lege(GearCopy copy) {
    _beendeZiehen();
    final item = copy.item;
    if (item == null) return;
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

  /// Was im Rucksack liegt: alles, was man hat und nicht trägt.
  static List<GearCopy> _rucksack(Loadout loadout) => <GearCopy>[
    for (final copy in loadout.ownedCopies)
      if (!loadout.isEquipped(copy.uid)) copy,
  ];

  /// Was beim Ziehen unter dem Finger hängt: das Bild des Stücks.
  static Widget _schwebeBild(GearCopy copy) {
    final item = copy.item;
    if (item == null) return const SizedBox.shrink();
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
    final rucksack = _rucksack(loadout);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ausrüstung'),
        backgroundColor: Palette.surface,
        actions: const <Widget>[SammlungKnopf(art: SammelArt.ausruestung)],
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
                  // **Aufräumen je Seltenheit** (Issue #137): ein Knopf für
                  // jede, in der etwas Schlechteres liegt. Gesperrtes bleibt.
                  // Nur sichtbar, wenn es etwas zu räumen gibt.
                  if (loadout.junk.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    _Aufraeumen(loadout: loadout),
                  ],
                  const SizedBox(height: 20),
                  // Wie viel im Rucksack liegt, und wie geordnet wird —
                  // ohne Worte.
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.backpack_outlined,
                        size: 20,
                        color: Palette.textOnDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${rucksack.length}',
                        semanticsLabel: '${rucksack.length} Stück im Rucksack',
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
                    ..._gruppe(gruppe, loadout: loadout, rucksack: rucksack),
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
  /// keine Überschrift, es ist die eine Gruppe. **Eine leere Gruppe steht
  /// nicht da**: Der Rucksack zeigt, was drin ist, nicht, was fehlt.
  List<Widget> _gruppe(
    GearGroup gruppe, {
    required Loadout loadout,
    required List<GearCopy> rucksack,
  }) {
    final reihenfolge = <String, int>{
      for (final (i, item) in gruppe.items.indexed) item.id: i,
    };
    final drin =
        <GearCopy>[
          for (final copy in rucksack)
            if (reihenfolge.containsKey(copy.itemId)) copy,
        ]..sort((a, b) {
          final nachStueck = reihenfolge[a.itemId]!.compareTo(
            reihenfolge[b.itemId]!,
          );
          if (nachStueck != 0) return nachStueck;
          return b.bonus.total.compareTo(a.bonus.total);
        });
    if (drin.isEmpty) return const <Widget>[];

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
                '${drin.length}',
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
          for (final copy in drin)
            if (copy.item case final GearItem item)
              HaltenUndZiehen<GearCopy>(
                data: copy,
                // Im Rucksack liegt nur, was man hat — alles lässt sich
                // ziehen.
                aktiv: true,
                bild: _schwebeBild(copy),
                rahmenFarbe: RarityBadge.rahmenOf(item.rarity),
                onStart: () => _beginneZiehen(copy),
                onEnde: _beendeZiehen,
                child: ExemplarKachel(
                  copy: copy,
                  vergleich: loadout.vergleiche(copy),
                  gesperrt: loadout.isLocked(copy.uid),
                  ausgeblendet: _gezogen?.uid == copy.uid,
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
  final GearCopy? gezogen;

  final ValueChanged<GearCopy> onAblegen;

  /// Baut die Kachel im passenden Zustand.
  final Widget Function(SlotDragState dragState) child;

  @override
  Widget build(BuildContext context) {
    return DragTarget<GearCopy>(
      onWillAcceptWithDetails: (details) => details.data.item?.slot == slot,
      onAcceptWithDetails: (details) => onAblegen(details.data),
      builder: (context, kandidaten, _) {
        return child(
          SlotDragState.fuer(
            zieht: gezogen != null,
            passt: gezogen?.item?.slot == slot,
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

/// Die Knöpfe zum Aufräumen: einer je Seltenheit, in der etwas
/// Schlechteres liegt (Issue #137) — mit Zahl und Erlös.
class _Aufraeumen extends ConsumerWidget {
  const _Aufraeumen({required this.loadout});

  final Loadout loadout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        const Icon(
          Icons.cleaning_services_outlined,
          size: 18,
          color: Palette.textOnDark,
          semanticLabel: 'Schlechteres verkaufen',
        ),
        for (final stufe in GearRarity.values)
          if (loadout.junkOf(stufe) case final ausschuss
              when ausschuss.isNotEmpty)
            OutlinedButton(
              key: ValueKey<String>('aufraeumen-${stufe.name}'),
              onPressed: () => sellJunkWithConfirm(context, ref, stufe),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                side: BorderSide(color: RarityBadge.rahmenOf(stufe), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '×${ausschuss.length}',
                    semanticsLabel:
                        '${stufe.label}: ${ausschuss.length} Stück '
                        'verkaufen, ${junkRefund(ausschuss)} Gold',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: RarityBadge.colorOf(stufe),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const GoldIcon(size: 14),
                  const SizedBox(width: 2),
                  Text('+${junkRefund(ausschuss)}', semanticsLabel: ''),
                ],
              ),
            ),
      ],
    );
  }
}

/// Ein Exemplar im Rucksack: Bild im Rahmen seiner Seltenheit, ein Pfeil
/// gegen das Getragene und, wenn es gesperrt ist, ein Schloss.
class ExemplarKachel extends StatelessWidget {
  const ExemplarKachel({
    required this.copy,
    required this.vergleich,
    required this.gesperrt,
    required this.onTap,
    this.ausgeblendet = false,
    super.key,
  });

  final GearCopy copy;
  final GearVergleich vergleich;
  final bool gesperrt;
  final VoidCallback onTap;

  /// Ob das Stück gerade gezogen wird. Dann bleibt an seiner Stelle ein
  /// Schatten, und das Stück selbst hängt unter dem Finger.
  final bool ausgeblendet;

  static const double _bildSeite = 36;

  /// Der Pfeil: grün hoch, rot runter, braun gleich — wie in
  /// AktivesBretts Skizze zu #136.
  static (IconData, Color, String) pfeil(GearVergleich v) => switch (v) {
    GearVergleich.besser => (
      Icons.arrow_upward_rounded,
      Palette.success,
      'besser',
    ),
    GearVergleich.gleich => (
      Icons.drag_handle_rounded,
      Palette.accent,
      'gleich gut',
    ),
    GearVergleich.schlechter => (
      Icons.arrow_downward_rounded,
      Palette.enemy,
      'schlechter',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final item = copy.item;
    if (item == null) return const SizedBox.shrink();
    final pfad = GearIcons.forItemId(item.id);
    final ersatz = SizedBox.square(
      dimension: _bildSeite,
      child: Icon(GearIcons.fallbackFor(item.slot), color: Palette.accent),
    );
    final (zeichen, farbe, wort) = pfeil(vergleich);

    return Opacity(
      opacity: ausgeblendet ? 0.3 : 1,
      child: Semantics(
        button: true,
        label:
            '${item.name}, $wort als das Getragene'
            '${gesperrt ? ', gesperrt' : ''}',
        excludeSemantics: true,
        child: Druck(
          child: Material(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: RarityBadge.rahmenOf(item.rarity),
                    width: RarityBadge.rahmenBreite,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SizedBox(height: 4),
                        if (pfad == null)
                          ersatz
                        else
                          PixelArt(
                            assetPath: pfad,
                            side: _bildSeite,
                            fallback: ersatz,
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
                            fontWeight: FontWeight.bold,
                            color: RarityBadge.colorOf(item.rarity),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: -1,
                      top: -3,
                      child: Icon(
                        zeichen,
                        key: ValueKey<String>('pfeil-${vergleich.name}'),
                        size: 16,
                        color: farbe,
                      ),
                    ),
                    if (gesperrt)
                      const Positioned(
                        left: -1,
                        top: -3,
                        child: Icon(
                          Icons.lock,
                          key: ValueKey<String>('gesperrt'),
                          size: 13,
                          color: Palette.gold,
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
