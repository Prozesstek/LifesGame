import 'package:abilities/abilities.dart';
import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progression/progression.dart';

import '../action/hero_power.dart';
import '../action/pit_text.dart';
import '../gear/widgets/rarity_badge.dart';
import '../home/erster_start.dart';
import '../mentor/mentor.dart';
import '../mentor/mentor_kasten.dart';
import '../mentor/zeigefinger.dart';
import '../sammlung/sammlung.dart';
import '../sammlung/sammlung_knopf.dart';
import '../progression/level_provider.dart';
import '../ui/ausgegraut.dart';
import '../ui/druck.dart';
import '../ui/halten_und_ziehen.dart';
import '../ui/palette.dart';
import '../ui/wackeln.dart';
import 'abilities_controller.dart';
import 'faehigkeit_ordnung.dart';
import 'widgets/ability_sheet.dart';
import 'widgets/ability_slots_row.dart';
import 'widgets/ultimate_platz.dart';

/// Der Fähigkeiten-Bildschirm: vier Plätze oben, der ganze Katalog
/// darunter (ADR-0049).
///
/// **Bis zum 25.09. war das ein Abschnitt im Charakter.** Dort standen
/// die vier Plätze zwischen Werten und Ausrüstung, und was man *nicht*
/// hatte, stand nirgends — das Auswahlblatt zeigte nur das
/// Freigeschaltete. Neunzehn Fähigkeiten, von denen ein frischer
/// Charakter keine einzige sieht, sind kein Ziel, sondern eine
/// Überraschung.
///
/// **Gesperrte stehen deshalb grau mit dabei**, und antippen erklärt
/// sie vollständig. Dieselbe Hausregel wie beim gesperrten Stück im
/// Laden (ADR-0034) und beim gesperrten Kreis auf der Startseite
/// (ADR-0020): Ein Ziel, das man nicht sieht, ist keins.
class AbilitiesScreen extends ConsumerStatefulWidget {
  const AbilitiesScreen({super.key});

  @override
  ConsumerState<AbilitiesScreen> createState() => _AbilitiesScreenState();
}

class _AbilitiesScreenState extends ConsumerState<AbilitiesScreen> {
  static const double _maxWidth = 560;

  /// Vier Bilder je Reihe. Bei 390 Pixeln Breite bleiben je rund 80 —
  /// genug für das 36er-Bild und zwei Zeilen Name darunter.
  static const int _columns = 4;

  final ScrollController _scroll = ScrollController();

  /// Die Id der Fähigkeit, die gerade gezogen wird, oder null. Die Plätze
  /// lesen sie, um zu zeigen, wohin sie passt (ADR-0057).
  String? _gezogen;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = ref.watch(playerLevelProvider);
    final chosen = ref.watch(chosenAbilitiesProvider);
    final weaponMove = ref.watch(weaponMoveProvider);
    final attack = ref.watch(heroPowerProvider).stats.combatAttack;

    final offen = <String>{
      for (final ability in ref.watch(unlockedAbilitiesProvider))
        ability.moveId,
    };
    final offeneUltimates = <String>{
      for (final ability in ref.watch(unlockedUltimatesProvider))
        ability.moveId,
    };
    final gezogen = _gezogen;
    final zieheUltimate =
        gezogen != null && AbilityCatalog.ultimateByMoveId(gezogen) != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fähigkeiten'),
        backgroundColor: Palette.surface,
        actions: const <Widget>[SammlungKnopf(art: SammelArt.faehigkeiten)],
      ),
      body: MentorFlaeche(
        ort: MentorOrt.faehigkeiten,
        child: SafeArea(
          child: Align(
            // **Oben, nicht in der Mitte**: Ein kurzer Inhalt — wenige
            // eigene Fähigkeiten, ein leerer Rucksack — rutschte sonst in
            // die Mitte des Bildschirms (beim Ansehen gefunden, 20.10.).
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              // **Kein ListView**, aus demselben Grund wie bei der
              // Ausrüstung: Beim Hochrollen während des Ziehens verwürfe sie
              // die Kachel, von der gezogen wird.
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AbilitySlotsRow(
                      einladen: offen.any((id) => !chosen.contains(id)),
                      level: level.level,
                      weaponMove: weaponMove,
                      chosen: chosen,
                      gezogen: _gezogen,
                      gewaehlt: _waehlt,
                      // Dieselbe Grenze wie bei den Platz-Knöpfen im Blatt:
                      // die belegten plus der nächste leere.
                      // Eine Ultimate liegt nie auf einem der drei Plätze.
                      nimmtAn: (slot) =>
                          !zieheUltimate &&
                          slot >= 2 &&
                          slot - 2 < _belegung(chosen, level.level).length,
                      onAblegen: _lege,
                      onTapSlot: (slot) => _tippePlatz(
                        context,
                        ref,
                        slot: slot,
                        weaponMove: weaponMove,
                        attack: attack,
                        offen: offen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    UltimatePlatz(
                      level: level.level,
                      ultimate: chosen.ultimate,
                      zieht: _gezogen != null,
                      nimmtAn:
                          zieheUltimate &&
                          AbilitySlots.ultimateOpenAt(level.level),
                      einladen: offeneUltimates.isNotEmpty,
                      onAblegen: _legeUltimate,
                      onTap: () => _tippeUltimatePlatz(
                        context,
                        ref,
                        offen: offeneUltimates,
                        attack: attack,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.auto_awesome,
                          size: 20,
                          color: Palette.textOnDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${offen.length} / ${AbilityCatalog.choosable.length}',
                          semanticsLabel:
                              '${offen.length} von '
                              '${AbilityCatalog.choosable.length} '
                              'freigeschaltet',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Palette.textOnDark,
                          ),
                        ),
                        const Spacer(),
                        _Ordnungswahl(
                          aktiv: _ordnung,
                          onWaehle: (o) => setState(() => _ordnung = o),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _raster(
                      context,
                      ref,
                      offen: offen,
                      offeneUltimates: offeneUltimates,
                      chosen: chosen,
                      attack: attack,
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

  /// Das Raster der eigenen Fähigkeiten — **eines, ohne Überschriften**
  /// (Frederik, 20.10.), in der gewählten Ordnung. Die Ultimates stehen
  /// am Ende; ihr goldener Doppelrand sagt, was sie sind.
  ///
  /// **Nur, was man hat** (Issue #138). Was es sonst gibt und woher,
  /// steht in der Sammlung (ADR-0080).
  Widget _raster(
    BuildContext context,
    WidgetRef ref, {
    required Set<String> offen,
    required Set<String> offeneUltimates,
    required ChosenAbilities chosen,
    required int attack,
  }) {
    final eigene = ordneFaehigkeiten(<Ability>[
      for (final ability in AbilityCatalog.choosable)
        if (offen.contains(ability.moveId)) ability,
    ], _ordnung);
    final ultimates = ordneFaehigkeiten(<Ability>[
      for (final ability in AbilityCatalog.ultimates)
        if (offeneUltimates.contains(ability.moveId)) ability,
    ], _ordnung);

    return GridView.count(
      // Das Raster sitzt in einer ListView: eigene Höhe, kein eigenes
      // Scrollen. Sonst scrollten zwei Flächen ineinander.
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: _columns,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.78,
      children: <Widget>[
        for (final ability in eigene)
          HaltenUndZiehen<String>(
            data: ability.moveId,
            aktiv: true,
            bild: MoveBild(
              moveId: ability.moveId,
              side: HaltenUndZiehen.schwebeSeite - 12,
              fallback: const Icon(Icons.bolt, color: Palette.accent),
            ),
            rahmenFarbe: RarityBadge.colorOfStufe(ability.rarity.index),
            onStart: () => _beginneZiehen(ability.moveId),
            onEnde: _beendeZiehen,
            // Der Mentor zeigt auf das, was gelernt und noch nicht
            // angelegt ist (ADR-0079) — beim ersten Mal Funkenstoß.
            child: Zeigefinger(
              schritt: Schritt.faehigkeitAnlegen,
              aktiv: !chosen.contains(ability.moveId),
              // Wird für einen Platz gewählt, wackelt, was dorthin kann.
              child: Wackeln(
                aktiv:
                    _waehlt != null &&
                    chosen.at(_waehlt! - 2) != ability.moveId,
                child: _Kachel(
                  ability: ability,
                  unlocked: true,
                  imEinsatz: chosen.contains(ability.moveId),
                  ausgeblendet: _gezogen == ability.moveId,
                  onTap: () {
                    final platz = _waehlt;
                    if (platz != null) {
                      _lege(platz, ability.moveId);
                      return;
                    }
                    _zeigeFaehigkeit(
                      context,
                      ref,
                      ability: ability,
                      unlocked: true,
                      attack: attack,
                    );
                  },
                ),
              ),
            ),
          ),
        for (final ability in ultimates)
          HaltenUndZiehen<String>(
            data: ability.moveId,
            aktiv: true,
            bild: MoveBild(
              moveId: ability.moveId,
              side: HaltenUndZiehen.schwebeSeite - 12,
              fallback: const Icon(Icons.auto_awesome, color: Palette.gold),
            ),
            rahmenFarbe: Palette.rahmenGoldHell,
            onStart: () => _beginneZiehen(ability.moveId),
            onEnde: _beendeZiehen,
            child: UltimateRand(
              hell: true,
              child: _Kachel(
                ability: ability,
                unlocked: true,
                imEinsatz: chosen.ultimate == ability.moveId,
                ausgeblendet: _gezogen == ability.moveId,
                ohneRand: true,
                onTap: () => _zeigeUltimate(
                  context,
                  ref,
                  ability: ability,
                  unlocked: true,
                  attack: attack,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _legeUltimate(String moveId) {
    _beendeZiehen();
    ref.read(chosenAbilitiesProvider.notifier).chooseUltimate(moveId);
    HapticFeedback.selectionClick();
  }

  /// Der Platz der Ultimate angetippt: belegt zeigt er ihr Blatt, leer
  /// sagt er, wo sie herkommt.
  Future<void> _tippeUltimatePlatz(
    BuildContext context,
    WidgetRef ref, {
    required Set<String> offen,
    required int attack,
  }) async {
    final id = ref.read(chosenAbilitiesProvider).ultimate;
    final ability = id == null ? null : AbilityCatalog.ultimateByMoveId(id);
    if (ability == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              offen.isEmpty
                  ? 'Noch keine Ultimate freigeschaltet. Was es dafür '
                        'braucht, steht bei den goldenen.'
                  : 'Halte unten eine Ultimate gedrückt und zieh sie '
                        'hierher.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      return;
    }
    await _zeigeUltimate(
      context,
      ref,
      ability: ability,
      unlocked: offen.contains(ability.moveId),
      attack: attack,
    );
  }

  Future<void> _zeigeUltimate(
    BuildContext context,
    WidgetRef ref, {
    required Ability ability,
    required bool unlocked,
    required int attack,
  }) async {
    final pit = PitAbilities.ultimateById(ability.moveId);
    if (pit == null) return;
    final level = ref.read(playerLevelProvider).level;
    final pick = await showAbilitySheet(
      context,
      karte: AbilityCard.ultimate(
        ability: ability,
        pit: pit,
        unlocked: unlocked,
        ultimateOpen: AbilitySlots.ultimateOpenAt(level),
        onUltimateSlot:
            ref.read(chosenAbilitiesProvider).ultimate == ability.moveId,
        attack: attack,
      ),
      freiePlaetze: const <String?>[],
    );
    final steuer = ref.read(chosenAbilitiesProvider.notifier);
    switch (pick) {
      case null || LegeAuf():
        return;
      case LegeUltimate():
        steuer.chooseUltimate(ability.moveId);
      case RaeumePlatz():
        steuer.clearUltimate();
    }
  }

  /// Der Platz, für den gerade gewählt wird, oder null (Issue #138):
  /// Platz antippen, dann eine Fähigkeit.
  int? _waehlt;

  /// Wie das Raster geordnet ist. Gehört zur Ansicht, nicht zum
  /// Spielstand, wie bei der Ausrüstung.
  FaehigkeitOrdnung _ordnung = FaehigkeitOrdnung.values.first;

  void _beginneZiehen(String moveId) {
    setState(() {
      _gezogen = moveId;
      _waehlt = null;
    });
    zuDenPlaetzen(_scroll);
  }

  void _beendeZiehen() {
    if (_gezogen == null) return;
    setState(() => _gezogen = null);
  }

  /// Legt die gezogene Fähigkeit auf den freien Platz [slot] (ab 2).
  ///
  /// Lag sie schon woanders, zieht sie um. Das regelt
  /// `ChosenAbilities.withAt`, nicht dieser Bildschirm.
  void _lege(int slot, String moveId) {
    _beendeZiehen();
    if (_waehlt != null) setState(() => _waehlt = null);
    ref.read(chosenAbilitiesProvider.notifier).choose(slot - 2, moveId);
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${pitNameOf(moveId) ?? moveId} liegt auf Platz $slot.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  /// Ein angetippter Platz: Der Waffenplatz und belegte Plätze zeigen
  /// ihr Blatt, ein leerer sagt, wo etwas herkommt.
  Future<void> _tippePlatz(
    BuildContext context,
    WidgetRef ref, {
    required int slot,
    required String weaponMove,
    required int attack,
    required Set<String> offen,
  }) async {
    if (slot == 1) {
      final waffe = PitWeapons.byMoveId(weaponMove);
      if (waffe == null) return;
      await showAbilitySheet(
        context,
        karte: AbilityCard.waffe(waffe: waffe, attack: attack),
        freiePlaetze: const <String?>[],
      );
      return;
    }

    // **Platz antippen, dann eine Fähigkeit** (Issue #138). Ein zweiter
    // Tipp auf denselben Platz bricht ab. Was ein belegter Platz kann,
    // zeigt das Blatt seiner Fähigkeit unten im Raster.
    if (_waehlt == slot) {
      setState(() => _waehlt = null);
      return;
    }
    final chosen = ref.read(chosenAbilitiesProvider);
    final level = ref.read(playerLevelProvider).level;
    final nimmt = slot - 2 < _belegung(chosen, level).length;
    if (offen.isEmpty || !nimmt) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              offen.isEmpty
                  ? 'Noch keine Fähigkeit freigeschaltet. Was es gibt, '
                        'steht in der Sammlung.'
                  : 'Erst Platz ${chosen.length + 2} belegen.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _waehlt = slot);
  }

  /// Zeigt das Blatt und führt aus, was daraus zurückkommt.
  Future<void> _zeigeFaehigkeit(
    BuildContext context,
    WidgetRef ref, {
    required Ability ability,
    required bool unlocked,
    required int attack,
  }) async {
    final pit = PitAbilities.byId(ability.moveId);
    // Eine Fähigkeit, die die Grube nicht kennt, tut dort nichts
    // (`activeMovesProvider` lässt sie fallen) — sie hat auch keine
    // Werte zu zeigen.
    if (pit == null) return;

    final chosen = ref.read(chosenAbilitiesProvider);
    final level = ref.read(playerLevelProvider).level;
    final aktuell = _platzVon(chosen, ability.moveId);

    final pick = await showAbilitySheet(
      context,
      karte: AbilityCard.faehigkeit(
        ability: ability,
        pit: pit,
        unlocked: unlocked,
        currentFreeIndex: aktuell,
        attack: attack,
      ),
      freiePlaetze: _belegung(chosen, level),
    );

    switch (pick) {
      case null || LegeUltimate():
        return;
      case LegeAuf(:final freeIndex):
        ref
            .read(chosenAbilitiesProvider.notifier)
            .choose(freeIndex, ability.moveId);
      case RaeumePlatz():
        if (aktuell != null) {
          ref.read(chosenAbilitiesProvider.notifier).clear(aktuell);
        }
    }
  }

  /// Auf welchem freien Platz eine Fähigkeit liegt, oder null.
  static int? _platzVon(ChosenAbilities chosen, String moveId) {
    for (var i = 0; i < chosen.length; i++) {
      if (chosen.at(i) == moveId) return i;
    }
    return null;
  }

  /// Was auf den anbietbaren freien Plätzen liegt.
  ///
  /// **Nur die belegten plus der nächste leere.** `ChosenAbilities` hält
  /// keine Lücken: Wer auf „Platz 4" legt, während 2 und 3 leer sind,
  /// landet in Wahrheit auf Platz 2. Ein Knopf, der etwas anderes tut,
  /// als er sagt, ist schlimmer als ein Knopf, den es nicht gibt —
  /// deshalb wird gar nicht erst mehr angeboten, als das Modell trägt.
  static List<String?> _belegung(ChosenAbilities chosen, int level) {
    final offeneFreie = AbilitySlots.openAt(level) - 1;
    final anbietbar = chosen.length + 1 < offeneFreie
        ? chosen.length + 1
        : offeneFreie;

    return <String?>[
      for (var i = 0; i < anbietbar; i++)
        switch (chosen.at(i)) {
          final String id => pitNameOf(id) ?? id,
          null => null,
        },
    ];
  }
}

/// Die drei Ordnungen als Reihe von Chips — wie bei der Ausrüstung.
class _Ordnungswahl extends StatelessWidget {
  const _Ordnungswahl({required this.aktiv, required this.onWaehle});

  final FaehigkeitOrdnung aktiv;
  final ValueChanged<FaehigkeitOrdnung> onWaehle;

  static IconData _zeichen(FaehigkeitOrdnung o) => switch (o) {
    FaehigkeitOrdnung.seltenheit => Icons.diamond_outlined,
    FaehigkeitOrdnung.alphabetisch => Icons.sort_by_alpha_rounded,
    FaehigkeitOrdnung.art => Icons.category_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final o in FaehigkeitOrdnung.values)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Druck(
              child: ChoiceChip(
                label: Icon(
                  _zeichen(o),
                  size: 18,
                  color: Palette.text,
                  semanticLabel: o.label,
                ),
                labelPadding: EdgeInsets.zero,
                padding: const EdgeInsets.all(6),
                selected: o == aktiv,
                onSelected: (_) => onWaehle(o),
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
}

/// Eine Fähigkeit im Raster.
///
/// **Gesperrte sind grau, nicht weg.** Entsättigt und halb durchsichtig,
/// mit einem Schloss in der Ecke — die Zeichnung bleibt erkennbar, damit
/// man weiß, worauf man zuarbeitet.
class _Kachel extends StatelessWidget {
  const _Kachel({
    required this.ability,
    required this.unlocked,
    required this.imEinsatz,
    required this.onTap,
    this.ausgeblendet = false,
    this.ohneRand = false,
  });

  /// Ohne eigenen Rand — wenn ihn schon der Doppelrand der Ultimate trägt.
  final bool ohneRand;

  final Ability ability;
  final bool unlocked;

  /// Ob sie gerade auf einem Platz liegt.
  final bool imEinsatz;

  /// Ob sie gerade gezogen wird. Dann bleibt an ihrer Stelle ein Schatten.
  final bool ausgeblendet;

  final VoidCallback onTap;

  static const double _bildSeite = 36;

  @override
  Widget build(BuildContext context) {
    final farbe = RarityBadge.colorOfStufe(ability.rarity.index);
    final name = pitNameOf(ability.moveId) ?? ability.moveId;

    final bild = Ausgegraut(
      aktiv: !unlocked,
      child: MoveBild(
        moveId: ability.moveId,
        side: _bildSeite,
        fallback: Icon(
          Icons.bolt,
          color: unlocked ? Palette.accent : Palette.muted,
        ),
      ),
    );

    return Opacity(
      opacity: ausgeblendet ? 0.3 : 1,
      child: Semantics(
        button: true,
        label: unlocked
            ? '$name, freigeschaltet'
            : '$name, noch nicht freigeschaltet',
        child: Druck(
          child: Material(
            color: unlocked ? Palette.surface : Palette.surfaceSunken,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: ohneRand && !imEinsatz
                      ? null
                      : Border.all(
                          color: imEinsatz
                              ? Palette.accent
                              : farbe.withValues(alpha: unlocked ? 0.7 : 0.25),
                          width: imEinsatz ? 2 : 1,
                        ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        bild,
                        if (!unlocked)
                          const Positioned(
                            right: -2,
                            bottom: -2,
                            child: Icon(
                              Icons.lock,
                              size: 12,
                              color: Palette.muted,
                            ),
                          ),
                        if (imEinsatz)
                          const Positioned(
                            right: -2,
                            bottom: -2,
                            child: Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Palette.accent,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.15,
                        color: unlocked ? Palette.text : Palette.muted,
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
