import 'dart:async';
import 'dart:math' as math;

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
/// Neun Angebote, eins je Platz und drei gewürfelte, aus dem Datum. Jedes ist ein
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final breite = constraints.maxWidth;
        final hoehe = constraints.maxHeight;
        final skala = breite / LadenBild.breite;
        // Der Tresen beginnt dort, wo im Bild das dunkle Innere unter der
        // Platte anfängt. Brauchen die Fächer mehr Platz, als darunter
        // bleibt, rutscht das Bild nach oben (AktivesBrett, 22.11.2026) —
        // aber nie so weit, dass das Schild „Laden“ in die Tafel hängt;
        // reicht auch das nicht, rollt der Laden.
        final brauchtTresen = _Tresen.hoeheFuer(breite, angebote.length);
        final schildUnten =
            MediaQuery.paddingOf(context).top +
            const SchildLeiste(titel: '').preferredSize.height;
        final hoechstens = math.max(
          0.0,
          LadenBild.tafel.top * skala - schildUnten,
        );
        final schieben = (LadenBild.tresenOben * skala + brauchtTresen - hoehe)
            .clamp(0.0, hoechstens);
        final tresenY = LadenBild.tresenOben * skala - schieben;
        final gesamt = math.max(hoehe, tresenY + brauchtTresen);
        final tafel = LadenBild.tafel;

        return SingleChildScrollView(
          child: SizedBox(
            width: breite,
            height: gesamt,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: <Widget>[
                Positioned(
                  left: 0,
                  top: -schieben,
                  width: breite,
                  height: LadenBild.hoehe * skala,
                  child: const Image(
                    image: AssetImage(LadenBild.pfad),
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                Positioned.fromRect(
                  rect: Rect.fromLTRB(
                    tafel.left * skala,
                    tafel.top * skala - schieben,
                    tafel.right * skala,
                    tafel.bottom * skala - schieben,
                  ),
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
                Positioned(
                  left: 0,
                  right: 0,
                  top: tresenY,
                  bottom: 0,
                  child: _Tresen(
                    faecher: <Widget>[
                      for (final angebot in angebote)
                        // Der Mentor zeigt im Rundgang auf sein Angebot;
                        // steht es auf der Tafel, sitzt der Punkt auf
                        // „Kaufen“.
                        Zeigefinger(
                          schritt: Schritt.laden,
                          aktiv: angebot.uid.endsWith('-mentor'),
                          punkt: angebot.uid != gewaehlt.uid,
                          eng: true,
                          radius: 8,
                          child: LadenFach(
                            angebot: angebot,
                            block: blockFor(angebot),
                            gewaehlt: angebot.uid == gewaehlt.uid,
                            // Ob es schon in der Sammlung steht: je besessen,
                            // auch verkauft.
                            gesammelt: loadout.everOwnedIds.contains(
                              angebot.itemId,
                            ),
                            onTap: () =>
                                setState(() => _gewaehlt = angebot.uid),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

/// **Der Tresen des Händlers** unter der Platte (AktivesBrett,
/// 21.11.2026): links und rechts ein Pfosten, dazwischen das dunkle Innere,
/// darin drei Spalten Fächer, **alle gleich groß** und **ganz unten**
/// (22.11.2026). Er liegt über dem Bild, wo es selbst schon Tresen ist, und
/// führt es nach unten weiter.
class _Tresen extends StatelessWidget {
  const _Tresen({required this.faecher});

  final List<Widget> faecher;

  static const int spalten = 3;
  static const double abstand = 12;

  /// Ein Fach ist höchstens so viel höher als breit.
  static const double hoechstensHoch = 1.45;

  /// So hoch soll ein Fach sein — gemessen an seiner Breite.
  static const double gewuenschtHoch = 1.25;

  static double _fachBreite(double breite) =>
      (breite - 2 * LadenBild.pfostenBreite - (spalten + 1) * abstand) /
      spalten;

  /// Wie hoch der Tresen sein muss, damit [anzahl] Fächer in gewünschter
  /// Höhe hineinpassen.
  static double hoeheFuer(double breite, int anzahl) {
    final reihen = (anzahl / spalten).ceil();
    return reihen * _fachBreite(breite) * gewuenschtHoch +
        (reihen + 1) * abstand;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const pfosten = LadenBild.pfostenBreite;
        final fachBreite = _fachBreite(constraints.maxWidth);
        final reihen = (faecher.length / spalten).ceil();
        final fachHoehe = math.min(
          fachBreite * hoechstensHoch,
          (constraints.maxHeight - (reihen + 1) * abstand) / reihen,
        );
        return ColoredBox(
          color: LadenBild.tresen,
          child: Stack(
            children: <Widget>[
              const Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: pfosten,
                child: Image(
                  image: AssetImage(LadenBild.pfostenLinks),
                  repeat: ImageRepeat.repeatY,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                ),
              ),
              const Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: pfosten,
                child: Image(
                  image: AssetImage(LadenBild.pfostenRechts),
                  repeat: ImageRepeat.repeatY,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  pfosten + abstand,
                  abstand,
                  pfosten + abstand,
                  abstand,
                ),
                // Ganz unten im Tresen (AktivesBrett, 22.11.2026): Was
                // darüber frei bleibt, gehört dem Bild.
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    for (var r = 0; r < reihen; r++) ...<Widget>[
                      if (r > 0) const SizedBox(height: abstand),
                      Row(
                        children: <Widget>[
                          for (var c = 0; c < spalten; c++) ...<Widget>[
                            if (c > 0) const SizedBox(width: abstand),
                            SizedBox(
                              width: fachBreite,
                              height: fachHoehe,
                              child: r * spalten + c < faecher.length
                                  ? faecher[r * spalten + c]
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
