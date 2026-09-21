import 'package:action_combat/action_combat.dart';
import 'package:combat/combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../action/pit_screen.dart';
import '../ui/holz.dart';
import '../ui/palette.dart';
import 'ladder_controller.dart';

/// Der Eingang zur Grube — dreissig Stufen, eine nach der anderen.
///
/// **Seit ADR-0039 führt er in die Grube statt in den Rundenkampf.** Die
/// Zahl oben ist dieselbe geblieben, weil an ihr die Sperren im Laden,
/// die Errungenschaften und die einmalige Belohnung hängen; aus der
/// Sprosse ist eine Stufe geworden. Der Klassenname bleibt, bis
/// `package:combat` gelöscht wird — er ist der Ort, auf den Startbildschirm
/// und Tests zeigen.
///
/// **Kein Gegnerbild mehr.** Eine Stufe hat keinen einen Gegner, sondern
/// eine Grube voller, die bei jedem Lauf anders liegt. Was sich zwischen
/// den Stufen ändert, steht als Zahl darunter.
class LadderScreen extends ConsumerWidget {
  const LadderScreen({super.key});

  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stand = ref.watch(ladderProvider);
    final stufe = PitStage(stand.nextRung);

    return Scaffold(
      appBar: AppBar(title: const Text('Die Grube')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: <Widget>[
                  _Fortschritt(stand: stand),
                  const SizedBox(height: 14),
                  const Expanded(child: _GrubenBild()),
                  const SizedBox(height: 14),
                  _Stufenleiste(stage: stufe),
                  const SizedBox(height: 10),
                  _Belohnung(stand: stand),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PitScreen(stage: stufe),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Hinab'),
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

/// „7 / 30" mit Balken — die Zahl, die zwei Spieler vergleichen.
class _Fortschritt extends StatelessWidget {
  const _Fortschritt({required this.stand});

  final LadderProgress stand;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          '${stand.highestDefeated} / ${PitStage.count}',
          // Die Zahl steht auf dem Leder, nicht auf einer Fläche — und
          // sie ist die Überschrift des Bildschirms.
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Palette.textOnDark,
          ),
        ),
        const SizedBox(height: 8),
        HolzBalken(
          value: stand.highestDefeated / PitStage.count,
          color: Palette.accentOnDark,
        ),
      ],
    );
  }
}

/// Die Bildfläche über der Stufe.
///
/// Ein Platzhalter, bis es ein Bild der Grube gibt — dieselbe Fläche, auf
/// der vorher der Gegner der Sprosse stand.
class _GrubenBild extends StatelessWidget {
  const _GrubenBild();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Palette.surfaceRaised, width: 2),
          ),
          child: const Center(
            child: Icon(
              Icons.stairs_outlined,
              size: 72,
              color: Palette.surfaceRaised,
            ),
          ),
        ),
      ),
    );
  }
}

/// Welche Stufe ansteht und was sie von der ersten unterscheidet.
///
/// **Gerechnet in `package:action_combat`**, hier nur abgelesen: Die
/// Faktoren stehen in `PitStage`, der Bildschirm rundet sie für die
/// Anzeige.
class _Stufenleiste extends StatelessWidget {
  const _Stufenleiste({required this.stage});

  final PitStage stage;

  @override
  Widget build(BuildContext context) {
    final leben = stage.hpFactor.toStringAsFixed(1).replaceAll('.', ',');
    final angriff = stage.attackFactor.toStringAsFixed(1).replaceAll('.', ',');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Text(
            'Stufe ${stage.number}',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Palette.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${stage.roomCount} Räume vor dem Wächter · '
            'Leben ×$leben · Angriff ×$angriff',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Palette.textDim),
          ),
        ],
      ),
    );
  }
}

/// Was dieser Sieg einbringt — oder dass er nichts mehr einbringt.
///
/// **Die Zeile gehört vor den Kampf, nicht nur danach.** Eine Belohnung,
/// von der man erst hinterher erfährt, motiviert den Kampf nicht, den man
/// gerade überlegt.
class _Belohnung extends StatelessWidget {
  const _Belohnung({required this.stand});

  final LadderProgress stand;

  @override
  Widget build(BuildContext context) {
    final rung = stand.nextRung;
    final neu = stand.isNewGround(rung);

    return Text(
      neu
          ? 'Erste Räumung: +${LadderRewards.xpFor(rung)} Erfahrung, '
                '+${LadderRewards.goldFor(rung)} Gold'
          : 'Alle Stufen geräumt — ein Lauf bringt nichts mehr ein.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: neu ? Palette.goldOnDark : Palette.textOnDarkDim,
      ),
    );
  }
}
