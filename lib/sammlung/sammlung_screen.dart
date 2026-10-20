import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';
import 'package:theory/theory.dart';

import '../achievements/achievements_screen.dart';
import '../action/action_sprites.dart';
import '../character/widgets/ability_slots_row.dart';
import '../gear/gear_icon.dart';
import '../gear/widgets/gear_sheet.dart';
import '../gear/widgets/rarity_badge.dart';
import '../theory/widgets/node_icon.dart';
import '../ui/druck.dart';
import '../ui/holz.dart';
import '../ui/palette.dart';
import '../ui/pixel_art.dart';
import 'figur_bild.dart';
import 'sammlung.dart';
import 'sammlung_provider.dart';

/// **Die Sammlung** (Issues #137, #138): alles, was es im Spiel zu
/// haben gibt, in sechs Reitern — Ausrüstung, Fähigkeiten, Gegner, Titel,
/// Seiten und die Errungenschaften, die hier eingezogen sind.
///
/// **Was man noch nicht hat, ist ein Fragezeichen**, und ein Tipp sagt,
/// woher es kommt (Frederik, 20.10.). Ausrüstung und Fähigkeiten zeigen
/// in ihren eigenen Bildschirmen nur noch, was man besitzt; das Ganze
/// steht hier.
class SammlungScreen extends ConsumerStatefulWidget {
  const SammlungScreen({this.anfang = SammelArt.ausruestung, super.key});

  /// Welcher Reiter beim Öffnen offen ist.
  final SammelArt anfang;

  static const double _maxWidth = 560;

  @override
  ConsumerState<SammlungScreen> createState() => _SammlungScreenState();
}

class _SammlungScreenState extends ConsumerState<SammlungScreen> {
  late SammelArt _art = widget.anfang;

  @override
  Widget build(BuildContext context) {
    final gesamt = ref.watch(sammelGesamtProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sammlung'),
        backgroundColor: Palette.surface,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${gesamt.prozent} %',
                semanticsLabel: 'Gesammelt: ${gesamt.prozent} Prozent',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Palette.accent,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: SammlungScreen._maxWidth,
            ),
            child: Column(
              children: <Widget>[
                _ArtReiter(
                  aktiv: _art,
                  onWaehle: (art) => setState(() => _art = art),
                ),
                Expanded(
                  child: _art == SammelArt.errungenschaften
                      ? const ErrungenschaftenAnsicht()
                      : _Raster(art: _art),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Die sechs Reiter, jeder mit seinem Anteil.
///
/// **Umgebrochen, nicht gerollt**: In einer Zeile lägen auf dem Handy
/// Titel, Seiten und Errungenschaften außerhalb des Bildes, und man
/// wüsste nicht, dass es sie gibt.
class _ArtReiter extends ConsumerWidget {
  const _ArtReiter({required this.aktiv, required this.onWaehle});

  final SammelArt aktiv;
  final ValueChanged<SammelArt> onWaehle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (final art in SammelArt.values)
            _Reiter(
              art: art,
              istAktiv: art == aktiv,
              prozent: ref.watch(sammelStandProvider(art)).prozent,
              onTap: () => onWaehle(art),
            ),
        ],
      ),
    );
  }
}

class _Reiter extends StatelessWidget {
  const _Reiter({
    required this.art,
    required this.istAktiv,
    required this.prozent,
    required this.onTap,
  });

  final SammelArt art;
  final bool istAktiv;
  final int prozent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: istAktiv,
      child: Druck(
        child: Material(
          key: ValueKey<String>('sammlung-${art.name}'),
          color: istAktiv ? Palette.accent : Palette.surface,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    art.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: istAktiv ? Palette.surface : Palette.textDim,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$prozent %',
                    style: TextStyle(
                      fontSize: 11,
                      color: istAktiv ? Palette.surface : Palette.muted,
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
}

/// Ein Reiter als Raster: vier Spalten, wie Ausrüstung und Fähigkeiten.
class _Raster extends ConsumerWidget {
  const _Raster({required this.art});

  final SammelArt art;

  static const int _spalten = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eintraege = ref.watch(sammelEintraegeProvider(art));
    final stand = ref.watch(sammelStandProvider(art));
    final gesammelt = eintraege.where((e) => e.gesammelt).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  '$gesammelt / ${eintraege.length}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Palette.textOnDark,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stand.gesamt == 0
                        ? 0
                        : stand.erreicht / stand.gesamt,
                    minHeight: 8,
                    color: Palette.goldOnDark,
                    backgroundColor: Palette.backgroundRaised,
                  ),
                ),
              ),
            ],
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _spalten,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.78,
          children: <Widget>[
            for (final eintrag in eintraege)
              SammelKachel(art: art, eintrag: eintrag),
          ],
        ),
      ],
    );
  }
}

/// Ein Platz der Sammlung: Bild und Name — oder ein Fragezeichen.
class SammelKachel extends StatelessWidget {
  const SammelKachel({required this.art, required this.eintrag, super.key});

  final SammelArt art;
  final SammelEintrag eintrag;

  @override
  Widget build(BuildContext context) {
    final rahmen = _rahmen();
    return Semantics(
      button: true,
      label: eintrag.gesammelt ? eintrag.name : 'Noch nicht gesammelt',
      excludeSemantics: true,
      child: Druck(
        child: Material(
          color: eintrag.gesammelt ? Palette.surface : Palette.surfaceSunken,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: rahmen ?? Palette.rahmenHolzDunkel,
              width: rahmen == null ? 1.5 : 2.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _tippe(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Center(
                      child: SammelBild(art: art, eintrag: eintrag, side: 44),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    eintrag.gesammelt ? eintrag.name : '???',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      color: eintrag.gesammelt ? Palette.text : Palette.muted,
                    ),
                  ),
                  if (eintrag.stufen > 1) ...<Widget>[
                    const SizedBox(height: 2),
                    Sterne(erreicht: eintrag.stufe, von: eintrag.stufen),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Ein gesammeltes Stück öffnet sein volles Blatt mit allen Werten
  /// (Issue #137) — das gab es vorher über den Katalog der Ausrüstung.
  /// Alles andere zeigt, was es ist oder woher es kommt.
  void _tippe(BuildContext context) {
    if (art == SammelArt.ausruestung && eintrag.gesammelt) {
      final item = GearCatalog.byId(eintrag.id);
      if (item != null) {
        showGearSheet(context, item);
        return;
      }
    }
    zeigeSammelBlatt(context, art: art, eintrag: eintrag);
  }

  /// Ein Stück trägt den Rahmen seiner Seltenheit — erst, wenn man es
  /// hatte; vorher verriete die Farbe zu viel.
  Color? _rahmen() {
    if (!eintrag.gesammelt || art != SammelArt.ausruestung) return null;
    final item = GearCatalog.byId(eintrag.id);
    return item == null ? null : RarityBadge.rahmenOf(item.rarity);
  }
}

/// Die Stufen eines Gegners als Sterne.
class Sterne extends StatelessWidget {
  const Sterne({required this.erreicht, required this.von, super.key});

  final int erreicht;
  final int von;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < von; i++)
          Icon(
            i < erreicht ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 12,
            color: i < erreicht ? Palette.gold : Palette.muted,
          ),
      ],
    );
  }
}

/// Das Bild eines Eintrags — oder das Fragezeichen.
class SammelBild extends StatelessWidget {
  const SammelBild({
    required this.art,
    required this.eintrag,
    required this.side,
    super.key,
  });

  final SammelArt art;
  final SammelEintrag eintrag;
  final double side;

  @override
  Widget build(BuildContext context) {
    if (!eintrag.gesammelt) {
      return Icon(
        Icons.question_mark_rounded,
        size: side * 0.7,
        color: Palette.muted,
      );
    }
    final zeichen = Icon(
      Icons.auto_awesome,
      size: side * 0.7,
      color: Palette.accent,
    );
    switch (art) {
      case SammelArt.ausruestung:
        final item = GearCatalog.byId(eintrag.id);
        final ersatz = Icon(
          item == null
              ? Icons.shield_outlined
              : GearIcons.fallbackFor(item.slot),
          size: side * 0.7,
          color: Palette.accent,
        );
        final pfad = GearIcons.forItemId(eintrag.id);
        if (pfad == null) return ersatz;
        return PixelArt(assetPath: pfad, side: side, fallback: ersatz);
      case SammelArt.faehigkeiten:
        return MoveBild(moveId: eintrag.id, side: side, fallback: zeichen);
      case SammelArt.gegner:
        final figur = eintrag.id.startsWith('waechter-')
            ? GrubeFiguren.forBoss(
                BossKind.values.byName(
                  eintrag.id.substring('waechter-'.length),
                ),
              )
            : GrubeFiguren.forKind(EnemyKind.values.byName(eintrag.id));
        return FigurBild(figur: figur, side: side);
      case SammelArt.titel:
        return Icon(
          Icons.workspace_premium_outlined,
          size: side * 0.75,
          color: Palette.gold,
        );
      case SammelArt.seiten:
        final node = theoryGraph.nodeById(eintrag.id);
        return Icon(
          node == null ? Icons.menu_book_outlined : iconForNode(node.iconId),
          size: side * 0.7,
          color: Palette.accent,
        );
      case SammelArt.errungenschaften:
        return zeichen;
    }
  }
}

/// Das Blatt eines Eintrags: was es ist — oder nur, woher es kommt.
Future<void> zeigeSammelBlatt(
  BuildContext context, {
  required SammelArt art,
  required SammelEintrag eintrag,
}) {
  final schwelle = Sammlung.naechsteSchwelle(eintrag);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: true,
    builder: (_) => HolzBlatt(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                SammelBild(art: art, eintrag: eintrag, side: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        eintrag.gesammelt ? eintrag.name : '???',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Palette.text,
                        ),
                      ),
                      if (eintrag.stufen > 1) ...<Widget>[
                        const SizedBox(height: 4),
                        Sterne(erreicht: eintrag.stufe, von: eintrag.stufen),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              eintrag.woher,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Palette.textDim,
              ),
            ),
            if (eintrag.anzahl case final int anzahl) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                schwelle == null
                    ? '$anzahl× besiegt'
                    : '$anzahl× besiegt — nächster Stern bei $schwelle',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Palette.text,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
