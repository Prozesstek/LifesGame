import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gear/gear.dart';

import '../action/pit_screen.dart';
import '../gear/gear_controller.dart';
import '../gear/gear_icon.dart';
import '../home/erster_start.dart';
import '../mentor/mentor.dart';
import '../mentor/mentor_kasten.dart';
import '../mentor/zeigefinger.dart';
import '../ui/gold_icon.dart';
import '../ui/palette.dart';
import '../ui/pixel_art.dart';
import 'ladder_controller.dart';
import 'widgets/eingangs_glut.dart';
import 'widgets/tagesform_kreis.dart';
import 'widgets/tagesgrube_karte.dart';

/// Der Eingang zur Grube: die Tagesgrube, darunter die **eine** Ebene,
/// in die es als Nächstes geht, und „Hinab“.
///
/// **Seit ADR-0039 führt er in die Grube statt in den Rundenkampf.** Der
/// Klassenname bleibt — er ist der Ort, auf den Startbildschirm und Tests
/// zeigen.
///
/// **Seit dem 16.10. ohne Fahrstuhl** (Frederik). Bis dahin standen hier
/// „7 / 30“ mit Balken und alle Stufen als Schacht zum Auswählen, jede
/// mit Bestzeit. Jetzt steht nur noch, wo es weitergeht: „Ebene 8“. Eine
/// geschaffte Ebene lässt sich von hier aus nicht mehr wählen.
///
/// **Seit ADR-0072 steht darüber die Tagesgrube** (`TagesgrubeKarte`).
class LadderScreen extends ConsumerWidget {
  const LadderScreen({super.key});

  static const double _maxWidth = 560;

  /// Woran man „Hinab“ findet — der Knopf trägt nur noch einen Pfeil.
  static const Key hinabKey = ValueKey<String>('grube-hinab');

  /// Woran man die Ebene findet, in die es geht.
  static const Key ebeneKey = ValueKey<String>('grube-ebene');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stand = ref.watch(ladderProvider);
    final stufe = stand.nextRung;

    return Scaffold(
      appBar: AppBar(title: const Text('Die Grube')),
      body: MentorFlaeche(
        ort: MentorOrt.eingang,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: LadderScreen._maxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: <Widget>[
                    const TagesgrubeKarte(),
                    const Spacer(),
                    EingangsGlut(
                      ebene: stufe,
                      child: _Ebene(stufe: stufe),
                    ),
                    _Belohnung(stand: stand, stufe: stufe),
                    const Spacer(),
                    // Der Blitz schrumpft, die Schlüssel nicht: Sein Text
                    // kann lang werden („Angriff +10 %, Leben +10 %, …“).
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _Schluessel(),
                        SizedBox(width: 16),
                        Flexible(child: TagesformKreis()),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Zeigefinger(
                      schritt: Schritt.grube,
                      radius: 10,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PitScreen(stage: PitStage(stufe)),
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          key: LadderScreen.hinabKey,
                          child: const Icon(
                            Icons.keyboard_double_arrow_down_rounded,
                            size: 26,
                            semanticLabel: 'Hinab',
                          ),
                        ),
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

/// „Ebene 8“ — die Überschrift des Bildschirms und die Zahl, die zwei
/// Spieler vergleichen.
class _Ebene extends StatelessWidget {
  const _Ebene({required this.stufe});

  final int stufe;

  @override
  Widget build(BuildContext context) {
    // Die Zahl leuchtet in der Farbe des Schlunds darunter.
    final glut = GlutStufe.fuer(stufe).farbe;
    return Column(
      key: LadderScreen.ebeneKey,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          'Ebene',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: Palette.textOnDarkDim,
          ),
        ),
        Text(
          '$stufe',
          semanticsLabel: 'Ebene $stufe',
          style: TextStyle(
            fontSize: 64,
            height: 1.1,
            fontWeight: FontWeight.bold,
            color: Palette.textOnDark,
            shadows: <Shadow>[
              Shadow(color: glut, blurRadius: 18),
              Shadow(color: glut.withValues(alpha: 0.6), blurRadius: 36),
            ],
          ),
        ),
      ],
    );
  }
}

/// Was die Ebene einbringt, als Zeichen und Zahl. Zahlt sie nichts
/// mehr — die letzte, wenn alle geschafft sind —, steht nichts da.
///
/// **Die Zeile gehört vor den Kampf, nicht nur danach.** Seit ADR-0041
/// ist es der **Rest** des Topfs: Was ein verlorener Lauf schon
/// eingesammelt hat, ist abgezogen.
class _Belohnung extends StatelessWidget {
  const _Belohnung({required this.stand, required this.stufe});

  final LadderProgress stand;
  final int stufe;

  @override
  Widget build(BuildContext context) {
    final topf = stand.potFor(stufe);

    // Die Höhe bleibt, auch wenn nichts zahlt — sonst springt „Hinab“.
    return SizedBox(
      height: 22,
      child: topf.xp == 0 && topf.gold == 0
          ? null
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Palette.goldOnDark,
                ),
                const SizedBox(width: 4),
                Text(
                  '+${topf.xp}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Palette.goldOnDark,
                  ),
                ),
                const SizedBox(width: 14),
                const GoldIcon(size: 16),
                const SizedBox(width: 4),
                Text(
                  '+${topf.gold}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Palette.goldOnDark,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Die Schlüssel zur Beute des Wächters (ADR-0048), als Zeichen mit Zahl.
/// Ein Tipp sagt, wofür sie sind und woher sie kommen.
class _Schluessel extends ConsumerWidget {
  const _Schluessel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anzahl = ref.watch(availableKeysProvider);
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      message:
          'Schlüssel öffnen die Beute des Wächters, höchstens '
          '${GearKeys.cap}. Jedes Häkchen, jede Seite und jede Rückfrage '
          'bringt einen.',
      child: Semantics(
        label: '$anzahl Schlüssel',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              PixelArt(
                assetPath: GearIcons.schluessel,
                side: 26,
                fallback: const Icon(Icons.key, color: Palette.goldOnDark),
              ),
              const SizedBox(width: 6),
              Text(
                '×$anzahl',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: anzahl > 0
                      ? Palette.goldOnDark
                      : Palette.textOnDarkDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
