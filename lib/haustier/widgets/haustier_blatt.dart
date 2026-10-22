import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haustier/haustier.dart';

import '../../dev/dev_controller.dart';
import '../../progression/level_provider.dart';
import '../../ui/druck.dart';
import '../../ui/gold_icon.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../haustier_controller.dart';
import 'haustier_bild.dart';

/// Öffnet das Blatt des Haustiers.
Future<void> zeigeHaustierBlatt(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: true,
    builder: (_) => const HaustierBlatt(),
  );
}

/// **Das Blatt des Haustiers** (Prototyp, 22.10.2026): das Tier groß, sein
/// Name, sein Weg durch die Stufen und sein Zubehör — gekauft für Gold
/// oder an einer Stufe verdient.
///
/// Im Entwicklermodus stehen unten Knöpfe, die Tage dazurechnen, um
/// spätere Stufen anzusehen. Gespeichert wird davon nichts.
class HaustierBlatt extends ConsumerWidget {
  const HaustierBlatt({super.key});

  static const Key nameKey = ValueKey<String>('haustier-name');

  static Key zubehoerKey(String id) => ValueKey<String>('zubehoer-$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stand = ref.watch(haustierProvider);
    final art = stand.art;
    if (art == null) return const SizedBox.shrink();

    final tage = ref.watch(haustierTageProvider);
    final stufe = HaustierWachstum.stufeFuer(tage);
    final level = HaustierWachstum.levelFuer(tage);
    final gold = ref.watch(goldProvider);

    return HolzBlatt(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      stand.anzeigeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Palette.text,
                      ),
                    ),
                  ),
                  IconButton(
                    key: nameKey,
                    tooltip: 'Namen ändern',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: Palette.accent,
                    onPressed: () => _benenne(context, ref, stand),
                  ),
                  const GoldIcon(size: 16),
                  const SizedBox(width: 4),
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
              Center(
                child: HaustierBild(
                  art: art,
                  stufe: stufe,
                  laune: ref.watch(haustierLauneProvider),
                  praegung: ref.watch(haustierPraegungProvider),
                  zubehoer: <ZubehoerPlatz, Zubehoer>{
                    for (final platz in ZubehoerPlatz.values)
                      if (stand.angelegtAuf(platz, stufe) case final Zubehoer z)
                        platz: z,
                  },
                  groesse: 170,
                ),
              ),
              Text(
                '${stufe.label} · Lv $level · $tage '
                '${tage == 1 ? 'Tag' : 'Tage'} mit Häkchen',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Palette.textDim),
              ),
              const SizedBox(height: 12),
              _StufenWeg(tage: tage),
              const SizedBox(height: 16),
              for (final platz in ZubehoerPlatz.values) ...<Widget>[
                _ZubehoerReihe(
                  platz: platz,
                  stand: stand,
                  stufe: stufe,
                  gold: gold,
                ),
                const SizedBox(height: 12),
              ],
              if (devModeAvailable) const _Vorschau(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _benenne(
    BuildContext context,
    WidgetRef ref,
    HaustierStand stand,
  ) async {
    final feld = TextEditingController(text: stand.name);
    final neu = await showDialog<String>(
      context: context,
      builder: (context) => HolzDialog(
        child: AlertDialog(
          title: const Text('Name'),
          content: TextField(
            controller: feld,
            autofocus: true,
            maxLength: HaustierStand.maxNameLength,
            decoration: InputDecoration(hintText: stand.art?.label),
            onSubmitted: (text) => Navigator.of(context).pop(text),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(feld.text),
              child: const Text('Übernehmen'),
            ),
          ],
        ),
      ),
    );
    feld.dispose();
    if (neu == null) return;
    ref.read(haustierProvider.notifier).benenne(neu);
  }
}

/// Die sechs Stufen in einer Reihe: erreichte gefüllt, die aktuelle
/// hervorgehoben, darunter, ab wie vielen Tagen.
class _StufenWeg extends StatelessWidget {
  const _StufenWeg({required this.tage});

  final int tage;

  @override
  Widget build(BuildContext context) {
    final jetzt = HaustierWachstum.stufeFuer(tage);
    return Row(
      children: <Widget>[
        for (final stufe in HaustierStufe.values)
          Expanded(
            child: Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              message: '${stufe.label}: ab ${stufe.abTagen} Tagen',
              child: Column(
                children: <Widget>[
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: stufe.index <= jetzt.index
                          ? Palette.success
                          : Palette.surfaceRaised,
                      border: Border.all(
                        color: stufe == jetzt ? Palette.gold : Palette.muted,
                        width: stufe == jetzt ? 2.5 : 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${stufe.abTagen}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: stufe == jetzt
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: Palette.textDim,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Die Stücke eines Platzes: angelegt (Rand), besessen (antippen legt
/// an oder ab), zu kaufen (Preis) oder an einer Stufe verdient (Schloss).
class _ZubehoerReihe extends ConsumerWidget {
  const _ZubehoerReihe({
    required this.platz,
    required this.stand,
    required this.stufe,
    required this.gold,
  });

  final ZubehoerPlatz platz;
  final HaustierStand stand;
  final HaustierStufe stufe;
  final int gold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final angelegt = stand.angelegtAuf(platz, stufe);
    final haustier = ref.read(haustierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          platz.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Palette.text,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final z in ZubehoerKatalog.fuer(platz))
              _ZubehoerChip(
                key: HaustierBlatt.zubehoerKey(z.id),
                stueck: z,
                besessen: stand.besitzt(z, stufe),
                angelegt: angelegt?.id == z.id,
                bezahlbar: stand.kannKaufen(z, verfuegbaresGold: gold),
                onTap: () {
                  if (angelegt?.id == z.id) {
                    haustier.ablege(platz);
                  } else if (stand.besitzt(z, stufe)) {
                    haustier.lege(z);
                  } else {
                    haustier.kaufe(z, verfuegbaresGold: ref.read(goldProvider));
                  }
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _ZubehoerChip extends StatelessWidget {
  const _ZubehoerChip({
    required this.stueck,
    required this.besessen,
    required this.angelegt,
    required this.bezahlbar,
    required this.onTap,
    super.key,
  });

  final Zubehoer stueck;
  final bool besessen;
  final bool angelegt;
  final bool bezahlbar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gesperrt = !besessen && (stueck.istVerdient || !bezahlbar);
    final rechts = switch ((besessen, stueck.istVerdient)) {
      (true, _) => null,
      (false, true) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.lock_outline, size: 13, color: Palette.muted),
          const SizedBox(width: 2),
          Text(
            stueck.abStufe!.label,
            style: const TextStyle(fontSize: 11, color: Palette.muted),
          ),
        ],
      ),
      (false, false) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const GoldIcon(size: 13),
          const SizedBox(width: 2),
          Text(
            '${stueck.preis}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: bezahlbar ? Palette.gold : Palette.muted,
            ),
          ),
        ],
      ),
    };

    return Semantics(
      button: true,
      selected: angelegt,
      child: Druck(
        child: Material(
          color: angelegt ? Palette.accent : Palette.surfaceRaised,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: gesperrt ? null : onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    stueck.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: angelegt
                          ? Palette.surface
                          : (gesperrt ? Palette.muted : Palette.text),
                    ),
                  ),
                  if (rechts != null) ...<Widget>[
                    const SizedBox(width: 6),
                    rechts,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// **Nur im Entwicklermodus:** Tage vorspulen, um spätere Stufen
/// anzusehen. Gespeichert wird nichts.
class _Vorschau extends ConsumerWidget {
  const _Vorschau();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vorschau = ref.watch(haustierVorschauProvider);
    final notifier = ref.read(haustierVorschauProvider.notifier);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        const Icon(Icons.science_outlined, size: 18, color: Palette.muted),
        Text(
          'Vorschau +$vorschau',
          style: const TextStyle(fontSize: 12, color: Palette.muted),
        ),
        for (final tage in <int>[1, 10, 50])
          OutlinedButton(
            onPressed: () => notifier.plus(tage),
            child: Text('+$tage'),
          ),
        TextButton(onPressed: notifier.zurueck, child: const Text('0')),
      ],
    );
  }
}
