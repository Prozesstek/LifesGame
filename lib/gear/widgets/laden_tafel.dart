import 'package:flutter/material.dart';
import 'package:gear/gear.dart';

import '../../home/erster_start.dart';
import '../../mentor/zeigefinger.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';
import '../../ui/schrift.dart';
import '../copy_text.dart';
import '../gear_icon.dart';
import '../weapon_ability_line.dart';
import 'rarity_badge.dart';

/// **Die Tafel im Laden** (AktivesBrett, 21.11.2026): was zum angetippten
/// Angebot zu wissen ist, mit Kreide auf Schiefer — Bild, Name,
/// Seltenheit, Wurf, die Werte gegen das Getragene, was es im Kampf tut,
/// und „Kaufen“.
///
/// **Sie hat eine feste Größe**, die des Rechtecks im Bild
/// (`LadenBild.tafel`). Was nicht passt, rollt innen.
///
/// **Sie rechnet nichts**: Ob gekauft werden kann, sagt [block] — dieselbe
/// Antwort wie für das Fach (`Loadout.blockFor`).
class LadenTafel extends StatelessWidget {
  const LadenTafel({
    required this.angebot,
    required this.block,
    required this.fehlendesGold,
    required this.onKaufen,
    this.getragen,
    super.key,
  });

  final GearCopy angebot;
  final PurchaseBlock? block;
  final int fehlendesGold;
  final VoidCallback onKaufen;

  /// Was im selben Platz angelegt ist — für den Unterschied je Wert.
  final GearCopy? getragen;

  /// Der Knopf „Kaufen“, damit Tests ihn finden.
  static const Key kaufenKey = ValueKey<String>('laden-kaufen');

  static const TextStyle _klein = TextStyle(
    fontSize: 12,
    height: 1.25,
    color: Palette.textOnDarkDim,
  );
  static const TextStyle _zahl = TextStyle(
    fontSize: 12,
    height: 1.25,
    fontWeight: FontWeight.bold,
    color: Palette.textOnDark,
  );

  @override
  Widget build(BuildContext context) {
    final item = angebot.item;
    if (item == null) return const SizedBox.shrink();
    final kampf = itemAbilityText(item);
    final pfad = GearIcons.forItemId(item.id);
    final farbe = RarityBadge.colorOnDarkOf(item.rarity);

    // Oben links das Bild, daneben Name und Qualität; darunter die Werte
    // über die ganze Breite, unten mittig „Kaufen“ (AktivesBrett,
    // 22.11.2026). Seltenheit und Platz stehen nicht da — die Seltenheit
    // sagen Rahmen und Farbe des Namens, den Platz das Bild.
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 2, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0x33000000),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: RarityBadge.rahmenOf(item.rarity),
                    width: RarityBadge.rahmenBreite,
                  ),
                ),
                child: pfad != null
                    ? PixelArt(
                        assetPath: pfad,
                        side: _bild,
                        fallback: _ersatz(item),
                      )
                    : _ersatz(item),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.1,
                        fontWeight: FontWeight.bold,
                        color: farbe,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(CopyText.qualitaet(angebot), style: _klein),
                    if (_grund case final String grund)
                      Text(
                        grund,
                        style: _zahl.copyWith(
                          color: block == PurchaseBlock.zuWenigGold
                              ? Palette.enemyOnDark
                              : Palette.goldOnDark,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final zeile in CopyText.lines(angebot, worn: getragen))
                    _WertZeile(zeile: zeile),
                  if (kampf != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(kampf, style: _klein),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: _KaufKnopf(
              angebot: angebot,
              block: block,
              onKaufen: onKaufen,
            ),
          ),
        ],
      ),
    );
  }

  /// Wie groß das Bild oben links steht.
  static const double _bild = 48;

  static Widget _ersatz(GearItem item) => Icon(
    GearIcons.fallbackFor(item.slot),
    size: _bild,
    color: Palette.textOnDark,
  );

  /// Warum „Kaufen“ grau ist — ein grauer Knopf ohne Grund wäre eine
  /// Sackgasse.
  String? get _grund => switch (block) {
    null || PurchaseBlock.unbekannt || PurchaseBlock.bereitsGekauft => null,
    PurchaseBlock.zuWenigGold => 'Noch $fehlendesGold Gold',
    PurchaseBlock.gesperrt =>
      'Ab Etage ${GearGates.rungFor(angebot.item!.rarity)} im Dungeon',
  };
}

/// Ein Wert: Name, Zahl und — gegen das Getragene — der Unterschied.
class _WertZeile extends StatelessWidget {
  const _WertZeile({required this.zeile});

  final StatLine zeile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Flexible(
          child: Text(
            zeile.label,
            overflow: TextOverflow.ellipsis,
            style: LadenTafel._klein,
          ),
        ),
        const SizedBox(width: 6),
        Text(zeile.zahlText, style: LadenTafel._zahl),
        if (zeile.diffZahl.isNotEmpty) ...<Widget>[
          const SizedBox(width: 5),
          Text(
            zeile.diffZahl,
            style: LadenTafel._zahl.copyWith(
              color: switch (zeile.diff) {
                null || 0 => Palette.textOnDarkDim,
                > 0 => Palette.successOnDark,
                _ => Palette.enemyOnDark,
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// „Kaufen“ mit der Münze und dem Preis — gekauft ein Haken.
class _KaufKnopf extends StatelessWidget {
  const _KaufKnopf({
    required this.angebot,
    required this.block,
    required this.onKaufen,
  });

  final GearCopy angebot;
  final PurchaseBlock? block;
  final VoidCallback onKaufen;

  @override
  Widget build(BuildContext context) {
    final gekauft = block == PurchaseBlock.bereitsGekauft;
    // Im Rundgang sitzt der Punkt des Mentors auf „Kaufen“.
    return Zeigefinger(
      schritt: Schritt.laden,
      aktiv: angebot.uid.endsWith('-mentor') && block == null,
      radius: 6,
      // Die Holzplanke der App — über das Theme, wie jeder andere Knopf.
      child: FilledButton(
        key: LadenTafel.kaufenKey,
        onPressed: block == null ? onKaufen : null,
        // Die Planke in normaler Größe; sie nennt keine Schrift, hier die
        // der App.
        style: const ButtonStyle(
          textStyle: WidgetStatePropertyAll<TextStyle>(
            TextStyle(
              fontFamily: Schrift.app,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              shadows: <Shadow>[
                Shadow(color: Color(0xCC1A0E05), offset: Offset(1, 1)),
              ],
            ),
          ),
        ),
        // Der Preis steht schon im Fach.
        child: gekauft
            ? const Icon(Icons.check_circle, size: 18, semanticLabel: 'Gekauft')
            : Text('Kaufen', semanticsLabel: 'Kaufen für ${angebot.paid} Gold'),
      ),
    );
  }
}
