import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory/theory.dart';

import '../../gear/gear_controller.dart';
import '../../gear/widgets/character_figure.dart';
import '../../mentor/mentor.dart';
import '../../mentor/mentor_kasten.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import 'seiten_farbe.dart';

/// **Der Mentor fragt ab** (03.11.2026): Nach dem Buch steht er oben, die
/// Frage unter ihm, darunter die Antworten als Holzknöpfe.
///
/// **Erst wählen, dann antworten.** Ein Tipp auf eine Antwort legt sie
/// nur fest — unten erscheint „Antworten“. Erst dann sagt die eigene
/// Figur sie dem Mentor, und er antwortet: richtig oder nicht ganz, mit
/// der Erklärung. Darunter geht es weiter. Ein Dialog von oben nach
/// unten, wie er gesprochen wird.
///
/// Gezählt wird, was [onAntwort] bekommt — der Dialog selbst rechnet
/// nichts. Auch das Rätsel vor dem Buch stellt er ([geraten]).
class MentorDialog extends StatefulWidget {
  const MentorDialog({
    required this.gestellt,
    required this.frage,
    required this.beantwortet,
    required this.onAntwort,
    required this.knopf,
    required this.onWeiter,
    this.kopf,
    this.geraten = false,
    super.key,
  });

  /// Die wievielte gestellte Frage — wechselt sie, beginnt der Dialog neu.
  final int gestellt;

  final Question frage;

  /// Was schon geantwortet ist, oder null.
  final int? beantwortet;

  /// „Antworten“ ist gedrückt — mit der gewählten Antwort.
  final ValueChanged<int> onAntwort;

  /// Der Knopf, wenn der Mentor geantwortet hat.
  final String knopf;
  final VoidCallback onWeiter;

  /// Eine kurze Zeile über der Frage: „Noch einmal“, „Was schätzt du?“.
  final String? kopf;

  /// Ob es das Rätsel ist — dann zählt nichts, und daneben ist kein
  /// Fehler, sondern eine Überraschung.
  final bool geraten;

  static const Key antwortenKey = ValueKey<String>('mentor-antworten');
  static const Key weiterKey = ValueKey<String>('mentor-weiter');
  static const Key spielerKey = ValueKey<String>('mentor-spieler');
  static const Key urteilKey = ValueKey<String>('mentor-urteil');

  /// Wie lange der Mentor nachdenkt, bevor er antwortet.
  static const Duration nachdenken = Duration(milliseconds: 500);

  @override
  State<MentorDialog> createState() => _MentorDialogState();
}

class _MentorDialogState extends State<MentorDialog> {
  int? _gewaehlt;

  @override
  void didUpdateWidget(MentorDialog alt) {
    super.didUpdateWidget(alt);
    if (alt.gestellt != widget.gestellt) _gewaehlt = null;
  }

  @override
  Widget build(BuildContext context) {
    final beantwortet = widget.beantwortet;
    final gewaehlt = _gewaehlt;
    final frage = widget.frage;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            key: ValueKey<int>(widget.gestellt),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: <Widget>[
              _Kommt(
                child: _MentorSagt(
                  kopf: widget.kopf,
                  text: frage.prompt,
                  gross: true,
                ),
              ),
              const SizedBox(height: 14),
              if (beantwortet == null)
                for (final (i, option) in frage.options.indexed) ...<Widget>[
                  _Kommt(
                    verzoegerung: Duration(milliseconds: 120 + 90 * i),
                    child: _Antwort(
                      key: ValueKey<String>('antwort-$i'),
                      text: option,
                      gewaehlt: gewaehlt == i,
                      onTap: () => setState(() => _gewaehlt = i),
                    ),
                  ),
                  const SizedBox(height: 10),
                ]
              else ...<Widget>[
                _Kommt(child: _SpielerSagt(text: frage.options[beantwortet])),
                const SizedBox(height: 14),
                _Kommt(
                  verzoegerung: MentorDialog.nachdenken,
                  child: _Urteil(
                    frage: frage,
                    antwort: beantwortet,
                    geraten: widget.geraten,
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: switch ((beantwortet, gewaehlt)) {
              (null, null) => const SizedBox(height: Holz.plankeHoehe),
              (null, final int wahl) => FilledButton(
                key: MentorDialog.antwortenKey,
                onPressed: () => widget.onAntwort(wahl),
                child: const Text('Antworten'),
              ),
              (_, _) => _Kommt(
                verzoegerung: MentorDialog.nachdenken,
                child: FilledButton(
                  key: MentorDialog.weiterKey,
                  onPressed: widget.onWeiter,
                  child: Text(widget.knopf),
                ),
              ),
            },
          ),
        ),
      ],
    );
  }
}

/// Der Mentor mit einer Sprechblase rechts neben sich.
class _MentorSagt extends StatelessWidget {
  const _MentorSagt({
    required this.text,
    this.kopf,
    this.gross = false,
    this.farbe,
    this.titel,
  });

  final String text;
  final String? kopf;
  final bool gross;

  /// Ein Wort vorneweg in Farbe — „Richtig!“ oder „Nicht ganz.“.
  final String? titel;
  final Color? farbe;

  @override
  Widget build(BuildContext context) {
    final oben = kopf;
    final wort = titel;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Beim Fragen steht er ganz da, beim Antworten sein Kopf.
        if (gross)
          SizedBox(
            width: 96,
            child: Image.asset(
              Mentor.figur,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => const MentorBild(seite: 64),
            ),
          )
        else
          const MentorBild(seite: 48),
        const SizedBox(width: 10),
        Expanded(
          child: HolzKarte(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (oben != null) ...<Widget>[
                  Text(
                    oben,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: SeitenFarbe.of(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (wort != null) ...<Widget>[
                  Text(
                    wort,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: farbe ?? Palette.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: gross ? 18 : 15,
                    height: 1.3,
                    fontWeight: gross ? FontWeight.bold : FontWeight.w500,
                    color: Palette.text,
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

/// Eine Antwort als Holzknopf. Gewählt trägt sie einen goldenen Rand und
/// einen Haken.
class _Antwort extends StatelessWidget {
  const _Antwort({
    required this.text,
    required this.gewaehlt,
    required this.onTap,
    super.key,
  });

  final String text;
  final bool gewaehlt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: gewaehlt,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: gewaehlt ? Palette.goldOnDark : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(Holz.plankeHoehe + 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            alignment: Alignment.centerLeft,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 15, height: 1.25),
                ),
              ),
              if (gewaehlt) ...<Widget>[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle_rounded, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Die eigene Figur, samt Ausrüstung, sagt die Antwort — rechts, mit der
/// Blase links von ihr.
class _SpielerSagt extends ConsumerWidget {
  const _SpielerSagt({required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadout = ref.watch(loadoutProvider);
    return Row(
      key: MentorDialog.spielerKey,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        const SizedBox(width: 40),
        Expanded(
          child: HolzKarte(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: Palette.text,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox.square(
          dimension: 100,
          child: CharacterFigure(
            worn: <String>[
              for (final slot in CharacterFigure.layers)
                ?loadout.equippedCopyIn(slot)?.itemId,
            ],
          ),
        ),
      ],
    );
  }
}

/// Was der Mentor auf die Antwort sagt.
class _Urteil extends StatelessWidget {
  const _Urteil({
    required this.frage,
    required this.antwort,
    required this.geraten,
  });

  final Question frage;
  final int antwort;
  final bool geraten;

  @override
  Widget build(BuildContext context) {
    final sitzt = frage.isCorrect(antwort);
    final richtige = frage.options[frage.correctIndex];
    final (wort, farbe) = switch ((sitzt, geraten)) {
      (true, false) => ('Richtig!', Palette.success),
      (true, true) => ('Gut geschätzt!', Palette.success),
      (false, false) => ('Nicht ganz.', Palette.enemy),
      (false, true) => ('Überraschend, oder?', Palette.accent),
    };
    return KeyedSubtree(
      key: MentorDialog.urteilKey,
      child: _MentorSagt(
        titel: wort,
        farbe: farbe,
        text: <String>[
          if (!sitzt) 'Es ist: $richtige',
          frage.explanation,
        ].where((t) => t.isNotEmpty).join('\n\n'),
      ),
    );
  }
}

/// Kommt von unten herein und blendet auf — nach [verzoegerung].
class _Kommt extends StatelessWidget {
  const _Kommt({required this.child, this.verzoegerung = Duration.zero});

  final Widget child;
  final Duration verzoegerung;

  static const Duration dauer = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    final gesamt = verzoegerung + dauer;
    final beginn = verzoegerung.inMicroseconds / gesamt.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: gesamt,
      builder: (context, t, kind) {
        final v = Curves.easeOutCubic.transform(
          ((t - beginn) / (1 - beginn)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - v)),
            child: kind,
          ),
        );
      },
      child: child,
    );
  }
}
