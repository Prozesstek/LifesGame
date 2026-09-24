import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../../gear/copy_text.dart';
import '../../gear/gear_icon.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';
import '../../ui/holz.dart';
import '../../ui/druck.dart';

/// Ein Ausrüstungsplatz als Kachel im 6er-Raster.
///
/// Leere Plätze werden angezeigt statt versteckt — dieselbe Entscheidung
/// wie bei den gesperrten Kacheln auf dem Startbildschirm: Was fehlt, ist
/// eine Information.
///
/// **Warum ein Raster und keine sechs Zeilen.** Vier Werte plus sechs
/// Plätze plus Beständigkeit plus Knöpfe sind als Liste über zwanzig
/// Zeilen — auf 390 Pixeln Breite scrollt man dann an allem vorbei, statt
/// es zu überblicken. Als Raster braucht die Ausrüstung ein Drittel der
/// Höhe (ADR-0013).
///
/// **Was das kostet, steht im Auswahlblatt.** Wirkung und Ablegen passen
/// nicht mehr auf die Kachel. Beides ist einen Fingertipp entfernt statt
/// sichtbar — vertretbar, weil die Wirkung bereits in „Werte im Kampf"
/// mit Herkunft steht und dort zurechenbar ist.
class EquipmentSlotTile extends StatelessWidget {
  const EquipmentSlotTile({
    required this.slot,
    required this.equipped,
    required this.owned,
    required this.onEquip,
    required this.onUnequip,
    super.key,
  });

  final GearSlot slot;

  /// Was gerade auf dem Platz liegt. Null heißt leer.
  final GearCopy? equipped;

  /// Jedes Exemplar, das auf diesen Platz passt — die Auswahl (ADR-0048).
  final List<GearCopy> owned;

  /// Bekommt die Uid des gewählten Exemplars.
  final void Function(String uid) onEquip;
  final VoidCallback onUnequip;

  /// Wie gross das Bild eines Stücks im Auswahlblatt ist. Grösser als auf
  /// der Kachel: Dort ist es ein Zeichen, hier soll man es ansehen.
  static const double _bildImBlatt = 32;

  /// Das Symbol je Platz.
  ///
  /// **Es stand hier einmal als eigene Tabelle** und war zeichengleich
  /// mit `GearIcons.fallbackFor`. Zwei Stellen, die dieselbe Frage
  /// beantworten, driften auseinander — der Fall steht in
  /// `docs/context/gotchas.md`, und hier wäre er ohne Meldung passiert:
  /// Laden und Charakterbildschirm hätten dasselbe Stück verschieden
  /// gezeichnet.
  static IconData _iconFor(GearSlot slot) => GearIcons.fallbackFor(slot);

  @override
  Widget build(BuildContext context) {
    final item = equipped?.item;
    final isEmpty = item == null;
    final hasNothingToPick = owned.isEmpty;

    return Semantics(
      button: !hasNothingToPick,
      label: hasNothingToPick
          ? '${slot.label}: nichts gekauft'
          : '${slot.label}: ${item?.name ?? 'leer'}',
      child: Druck(
        enabled: !hasNothingToPick,
        child: Material(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            // Ein Platz ohne Auswahl ist nicht antippbar. Ein Blatt, in dem
            // nichts steht, wäre eine Sackgasse statt einer Antwort.
            onTap: hasNothingToPick ? null : () => _pick(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isEmpty ? Palette.surfaceRaised : Palette.accent,
                  width: isEmpty ? 1 : 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _Zeichen(
                    slot: slot,
                    item: item,
                    color: isEmpty ? Palette.muted : Palette.accent,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    slot.label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Palette.textDim,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item?.name ??
                        (hasNothingToPick ? 'nichts gekauft' : 'leer'),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isEmpty ? FontWeight.normal : FontWeight.bold,
                      color: isEmpty ? Palette.muted : Palette.text,
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

  Future<void> _pick(BuildContext context) async {
    final chosen = await showModalBottomSheet<_Choice>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (sheetContext) {
        return HolzBlatt(
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Row(
                    children: <Widget>[
                      Icon(_iconFor(slot), size: 18, color: Palette.accent),
                      const SizedBox(width: 10),
                      Text(
                        slot.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Palette.text,
                        ),
                      ),
                    ],
                  ),
                ),
                // **Die Auswahl scrollt.** Seit es Beute gibt (ADR-0048),
                // liegen auf einem Platz schnell zwanzig Exemplare.
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      // **Dasselbe Bild wie im Laden und auf der Kachel.**
                      // Ob ein Stück zu einem Set gehört, entscheidet die
                      // Wahl mit: Ein Teil ablegen kann eine Stufe kosten.
                      for (final option in owned)
                        Druck(
                          child: ListTile(
                            leading: _Zeichen(
                              slot: slot,
                              item: option.item,
                              color: Palette.textDim,
                              side: _bildImBlatt,
                            ),
                            title: Text(
                              option.item?.name ?? option.itemId,
                              style: const TextStyle(color: Palette.text),
                            ),
                            subtitle: _Untertitel(option: option),
                            trailing: option.uid == equipped?.uid
                                ? const Icon(Icons.check, color: Palette.accent)
                                : null,
                            onTap: () => Navigator.of(
                              sheetContext,
                            ).pop(_Choice.equip(option.uid)),
                          ),
                        ),
                      // Das Ablegen steht neben dem, was es ersetzt.
                      if (equipped != null)
                        Druck(
                          child: ListTile(
                            leading: const Icon(
                              Icons.close,
                              color: Palette.muted,
                            ),
                            title: const Text(
                              'Ablegen',
                              style: TextStyle(color: Palette.textDim),
                            ),
                            onTap: () => Navigator.of(
                              sheetContext,
                            ).pop(const _Choice.unequip()),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (chosen == null) return;
    final uid = chosen.uid;
    if (uid == null) {
      onUnequip();
    } else {
      onEquip(uid);
    }
  }
}

/// Was im Auswahlblatt angetippt wurde.
///
/// Eigener Typ statt eines nullbaren Strings: Abbrechen und Ablegen sind
/// zwei verschiedene Antworten, und beide wären sonst null.
class _Choice {
  const _Choice.equip(this.uid);

  const _Choice.unequip() : uid = null;

  final String? uid;
}

/// Was auf einem Platz oben steht: das Bild des getragenen Stücks, sonst
/// das Zeichen des Platzes.
///
/// **Die Größe ist die des Zeichens, nicht die des Bildes.** Ein Raster
/// aus sechs Kacheln verträgt keine zwei Höhen — eine Kachel, die mit
/// Bild höher wird als ohne, verschiebt die ganze Zeile.
class _Zeichen extends StatelessWidget {
  const _Zeichen({
    required this.slot,
    required this.item,
    required this.color,
    this.side = 20,
  });

  final GearSlot slot;
  final GearItem? item;
  final Color color;

  /// Kantenlänge. 20 auf der Kachel, mehr im Auswahlblatt.
  final double side;

  @override
  Widget build(BuildContext context) {
    final bild = item == null ? null : GearIcons.forItemId(item!.id);
    final ersatz = Icon(GearIcons.fallbackFor(slot), size: side, color: color);

    if (bild == null) return ersatz;

    return PixelArt(assetPath: bild, side: side, fallback: ersatz);
  }
}

/// Wirkung und -- falls vorhanden -- das Set, zu dem ein Stück gehört.
///
/// Die Set-Zeile steht in derselben Farbe wie im Laden, damit man sie
/// wiedererkennt. Gezählt wird hier nichts: Wie viele Teile getragen
/// werden, sagt die Set-Karte weiter unten auf demselben Bildschirm.
class _Untertitel extends StatelessWidget {
  const _Untertitel({required this.option});

  final GearCopy option;

  @override
  Widget build(BuildContext context) {
    final set = GearSets.byId(option.item?.setId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          CopyText.line(option),
          style: TextStyle(
            color: CopyText.isGoodRoll(option)
                ? Palette.accent
                : Palette.textDim,
          ),
        ),
        if (set != null)
          Text(
            'Teil von „${set.name}"',
            style: const TextStyle(fontSize: 12, color: Palette.accent),
          ),
      ],
    );
  }
}
