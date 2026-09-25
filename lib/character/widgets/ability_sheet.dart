/// Das Blatt, das eine Fähigkeit vollständig erklärt — und sie anlegt.
///
/// **Es kommt auch bei gesperrten.** Eine graue Kachel, die beim
/// Antippen nichts tut, ist eine Sackgasse; eine, die ihre Werte *und*
/// ihre Bedingung zeigt, ist ein Ziel. Dieselbe Überlegung wie beim
/// gesperrten Stück im Laden (ADR-0034) und beim gesperrten Kreis auf
/// dem Startbildschirm (ADR-0020).
///
/// **Die Zahlen rechnet `pitAbilityStats`, nicht dieses Widget.** Hier
/// steht nur, wie sie stehen.
library;

import 'package:abilities/abilities.dart';
import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';

import '../../action/pit_text.dart';
import '../../combat/move_icon.dart';
import '../../gear/widgets/rarity_badge.dart';
import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';

/// Was das Blatt zurückgibt.
///
/// Eigener Typ, weil Abbrechen (`null` vom Blatt), Anlegen und Räumen
/// drei verschiedene Antworten sind — dieselbe Vorsicht wie beim alten
/// Auswahlblatt.
sealed class AbilityPick {
  const AbilityPick();
}

/// Auf den freien Platz mit diesem Index (0 = Platz 2).
final class LegeAuf extends AbilityPick {
  const LegeAuf(this.freeIndex);

  final int freeIndex;
}

/// Von dem Platz herunter, auf dem sie gerade liegt.
final class RaeumePlatz extends AbilityPick {
  const RaeumePlatz();
}

/// Alles, was das Blatt über eine Fähigkeit wissen muss.
///
/// **Ein Wert statt zehn Parametern.** Die Angaben hängen zusammen —
/// wer „gesperrt" setzt, muss auch die Bedingung mitgeben —, und als ein
/// Wert kann das nicht auseinanderlaufen.
class AbilityCard {
  /// Eine wählbare Fähigkeit aus dem Katalog.
  AbilityCard.faehigkeit({
    required Ability ability,
    required PitAbility pit,
    required this.unlocked,
    required this.currentFreeIndex,
    int? attack,
  }) : moveId = ability.moveId,
       name = pit.name,
       description = pit.description,
       stats = pitAbilityStats(pit, attack: attack),
       rarityStufe = ability.rarity.index,
       rarityLabel = ability.rarity.label,
       requirement = ability.requirement,
       fromWeapon = false;

  /// Der Waffenzug auf Platz 1. Er wird nicht gewählt, sondern getragen
  /// (ADR-0013) — deshalb ohne Seltenheit und ohne Bedingung.
  AbilityCard.waffe({required PitWeapon waffe, int? attack})
    : moveId = waffe.moveId,
      name = waffe.name,
      description =
          'Der Grundangriff: Was die getragene Waffe aus jedem Schlag '
          'macht.',
      stats = pitWeaponStats(waffe, attack: attack),
      rarityStufe = null,
      rarityLabel = null,
      requirement = null,
      unlocked = true,
      currentFreeIndex = null,
      fromWeapon = true;

  final String moveId;
  final String name;
  final String description;
  final List<PitStat> stats;

  /// Nummer und Wortlaut der Seltenheit, oder null beim Waffenzug.
  final int? rarityStufe;
  final String? rarityLabel;

  /// Die Bedingung im Klartext — auch dann, wenn sie erfüllt ist.
  final String? requirement;

  final bool unlocked;
  final bool fromWeapon;

  /// Auf welchem **freien** Platz sie gerade liegt (0 = Platz 2), oder
  /// null.
  final int? currentFreeIndex;
}

/// Zeigt das Blatt und gibt zurück, was der Spieler damit vorhat.
Future<AbilityPick?> showAbilitySheet(
  BuildContext context, {
  required AbilityCard karte,
  required List<String?> freiePlaetze,
}) {
  return showModalBottomSheet<AbilityPick>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: true,
    builder: (sheetContext) => _Blatt(karte: karte, freiePlaetze: freiePlaetze),
  );
}

class _Blatt extends StatelessWidget {
  const _Blatt({required this.karte, required this.freiePlaetze});

  final AbilityCard karte;

  /// Was auf den offenen freien Plätzen liegt — ein Eintrag je Platz,
  /// `null` für leer. Die Länge ist die Zahl der **offenen** Plätze.
  final List<String?> freiePlaetze;

  static const double _bildSeite = 52;

  @override
  Widget build(BuildContext context) {
    final pfad = MoveIcons.forMoveId(karte.moveId);

    return HolzBlatt(
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (pfad != null)
                  PixelArt(
                    assetPath: pfad,
                    side: _bildSeite,
                    fallback: const SizedBox.square(dimension: _bildSeite),
                  )
                else
                  const SizedBox.square(
                    dimension: _bildSeite,
                    child: Icon(Icons.bolt, color: Palette.accent),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        karte.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Palette.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (karte.rarityStufe case final stufe?)
                        RarityBadge.stufe(
                          stufe: stufe,
                          label: karte.rarityLabel ?? '',
                          faded: !karte.unlocked,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              karte.description,
              style: const TextStyle(fontSize: 13, color: Palette.textDim),
            ),
            const SizedBox(height: 14),
            for (final stat in karte.stats) _StatZeile(stat: stat),
            const SizedBox(height: 8),
            const Text(
              'Schadenszahlen sind flach gerechnet — ohne Abwehr des '
              'Gegners, ohne Streuung.',
              style: TextStyle(fontSize: 11, color: Palette.muted),
            ),
            const SizedBox(height: 14),
            _Herkunft(karte: karte),
            const SizedBox(height: 14),
            ..._handlungen(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _handlungen(BuildContext context) {
    if (karte.fromWeapon) {
      return const <Widget>[
        Text(
          'Kommt von der getragenen Waffe und liegt immer auf Platz 1. '
          'Wechseln geht im Laden.',
          style: TextStyle(fontSize: 12, color: Palette.textDim),
        ),
      ];
    }

    if (freiePlaetze.isEmpty) {
      return const <Widget>[
        Text(
          'Noch kein freier Platz offen — der zweite geht mit dem Level '
          'auf.',
          style: TextStyle(fontSize: 12, color: Palette.textDim),
        ),
      ];
    }

    return <Widget>[
      Text(
        karte.unlocked ? 'Auf welchen Platz?' : 'Erst freischalten:',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Palette.text,
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: <Widget>[
          for (var i = 0; i < freiePlaetze.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _PlatzKnopf(
                // Platz 1 gehört der Waffe, die freien zählen ab 2.
                nummer: i + 2,
                belegtMit: freiePlaetze[i],
                istHier: karte.currentFreeIndex == i,
                onTap: karte.unlocked && karte.currentFreeIndex != i
                    ? () => Navigator.of(context).pop(LegeAuf(i))
                    : null,
              ),
            ),
          ],
        ],
      ),
      if (karte.currentFreeIndex != null) ...<Widget>[
        const SizedBox(height: 10),
        Druck(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(const RaeumePlatz()),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Platz räumen'),
          ),
        ),
      ],
    ];
  }
}

/// Eine Zeile der Werte-Tabelle: Name links, Zahl rechts.
class _StatZeile extends StatelessWidget {
  const _StatZeile({required this.stat});

  final PitStat stat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // **Beide dürfen schrumpfen.** Zwei Texte nebeneinander, von
          // denen keiner nachgibt, sind der Fehler aus `gotchas.md` —
          // und „auf 35 % Tempo, 4 s" ist lang.
          Flexible(
            child: Text(
              stat.label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Palette.textDim),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 2,
            child: Text(
              stat.value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Woher sie kommt — und ob sie schon da ist.
class _Herkunft extends StatelessWidget {
  const _Herkunft({required this.karte});

  final AbilityCard karte;

  @override
  Widget build(BuildContext context) {
    final bedingung = karte.requirement;
    if (bedingung == null) return const SizedBox.shrink();

    final offen = karte.unlocked;
    final farbe = offen ? Palette.success : Palette.gold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: farbe.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: farbe.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            offen ? Icons.check_circle_outline : Icons.lock_outline,
            size: 16,
            color: farbe,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              offen ? 'Freigeschaltet: $bedingung' : bedingung,
              style: TextStyle(fontSize: 12, color: farbe),
            ),
          ),
        ],
      ),
    );
  }
}

/// Einer der drei Platz-Knöpfe: Nummer oben, was dort liegt darunter.
///
/// **Er sagt vorher, was er überschreibt.** Ein „Anlegen", das den
/// nächsten freien Platz nimmt, ist kürzer — aber sobald alle drei
/// belegt sind, ersetzt es blind.
class _PlatzKnopf extends StatelessWidget {
  const _PlatzKnopf({
    required this.nummer,
    required this.belegtMit,
    required this.istHier,
    required this.onTap,
  });

  final int nummer;

  /// Was dort gerade liegt, oder null für leer.
  final String? belegtMit;

  /// Ob die gezeigte Fähigkeit selbst hier liegt.
  final bool istHier;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final aus = onTap == null;
    final rand = istHier
        ? Palette.accent
        : (aus ? Palette.muted : Palette.surfaceSunken);

    return Semantics(
      button: !aus,
      label: 'Platz $nummer, ${belegtMit ?? 'leer'}',
      child: Druck(
        enabled: !aus,
        child: Material(
          color: Palette.surfaceRaised,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: rand),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Platz $nummer',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: aus ? Palette.muted : Palette.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    istHier ? 'liegt hier' : (belegtMit ?? 'leer'),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: istHier ? Palette.accent : Palette.muted,
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
