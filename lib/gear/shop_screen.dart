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
import 'widgets/laden_bild.dart';
import 'widgets/laden_fach.dart';
import 'widgets/laden_tafel.dart';

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
/// **Der Laden ist ein Laden** (AktivesBrett, 21.11.2026): oben die Wand
/// mit Regalen und dem Händler, links daneben eine Tafel, darunter sein
/// Tresen mit sechs Fächern — ein gemaltes Bild (`LadenBild`), auf das die
/// App Tafel und Fächer legt. Ein Tipp auf ein Fach schreibt das Stück
/// auf die Tafel, dort steht „Kaufen“.
///
/// **Die Tafel ist nie leer.** Am Anfang steht das erste Angebot darauf,
/// im Rundgang das des Mentors. Ein leeres Feld mit „bitte wählen" wäre
/// ein zweiter Schritt für etwas, das ohnehin nur eine Antwort hat.
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
      backgroundColor: LadenBild.tresen,
      // **Das Bild beginnt ganz oben** (AktivesBrett, 21.11.2026): Das
      // Schild „Laden“ hängt in seinen Dachbalken, nicht darüber.
      extendBodyBehindAppBar: true,
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
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: ShopScreen.maxWidth),
              child: SingleChildScrollView(child: _heute(gold)),
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
    // Im Rundgang steht das Angebot des Mentors auf der Tafel (07.11.2026).
    final vorgewaehlt = angebote.firstWhere(
      (c) => c.uid.endsWith('-mentor'),
      orElse: () => angebote.first,
    );
    final gewaehlt = angebote.firstWhere(
      (c) => c.uid == _gewaehlt,
      orElse: () => vorgewaehlt,
    );
    PurchaseBlock? blockFor(GearCopy c) =>
        loadout.blockFor(c, availableGold: gold, highestRung: rung);

    return AspectRatio(
      aspectRatio: LadenBild.breite / LadenBild.hoehe,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final skala = constraints.maxWidth / LadenBild.breite;
          Rect skaliert(Rect r) => Rect.fromLTRB(
            r.left * skala,
            r.top * skala,
            r.right * skala,
            r.bottom * skala,
          );
          return Stack(
            children: <Widget>[
              const Positioned.fill(
                child: Image(
                  image: AssetImage(LadenBild.pfad),
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              Positioned.fromRect(
                rect: skaliert(LadenBild.tafel),
                child: LadenTafel(
                  key: ValueKey<String>('tafel-${gewaehlt.uid}'),
                  angebot: gewaehlt,
                  block: blockFor(gewaehlt),
                  fehlendesGold: gewaehlt.paid - gold,
                  getragen: gewaehlt.item == null
                      ? null
                      : loadout.equippedCopyIn(gewaehlt.item!.slot),
                  onKaufen: () => _buy(context, ref, gewaehlt),
                ),
              ),
              for (final (i, angebot) in angebote.take(6).indexed)
                Positioned.fromRect(
                  rect: skaliert(LadenBild.faecher[i].rahmen),
                  // Der Mentor zeigt im Rundgang auf sein Angebot; steht
                  // es auf der Tafel, sitzt der Punkt auf „Kaufen“.
                  child: Zeigefinger(
                    schritt: Schritt.laden,
                    aktiv: angebot.uid.endsWith('-mentor'),
                    punkt: angebot.uid != gewaehlt.uid,
                    eng: true,
                    radius: 8,
                    child: LadenFach(
                      angebot: angebot,
                      bild: LadenBild.faecher[i],
                      skala: skala,
                      block: blockFor(angebot),
                      gewaehlt: angebot.uid == gewaehlt.uid,
                      // Ob es schon in der Sammlung steht: je besessen,
                      // auch verkauft.
                      gesammelt: loadout.everOwnedIds.contains(angebot.itemId),
                      onTap: () => setState(() => _gewaehlt = angebot.uid),
                    ),
                  ),
                ),
            ],
          );
        },
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
