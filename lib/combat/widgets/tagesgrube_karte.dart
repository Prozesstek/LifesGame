import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../action/daily_pit_screen.dart';
import '../../action/pit_text.dart';
import '../../habits/habits_controller.dart';
import '../../home/erster_start_provider.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';
import '../../ui/ruhm_zahl.dart';
import '../daily_pit_controller.dart';
import '../move_icon.dart';
import '../tagesgrube_text.dart';
import 'raumzeile.dart';
import 'teilen_knopf.dart';

/// **Die Tagesgrube im Eingang der Grube** (ADR-0072): dieselbe Grube für
/// alle, ein Versuch am Tag.
///
/// Vor dem Versuch zeigt sie, womit es heute hinabgeht — Waffe und drei
/// Fähigkeiten, für alle dieselben — und in welcher Verfassung. Danach
/// zeigt sie, wie es lief, und den Knopf zum Teilen.
///
/// **Sie trägt den Versuch ein, bevor der Lauf beginnt.** Deshalb startet
/// man von hier und nicht von der Seite des Laufs: Wäre der Eintrag erst
/// dort, gäbe es einen Augenblick, in dem Neuladen ihn verhinderte.
///
/// Sie erscheint erst, wenn jemand einmal in der Grube war
/// (`ErsterStart.zeigtTagesgrube`) — der eine Versuch soll nicht beim
/// Lernen der Steuerung verloren gehen.
class TagesgrubeKarte extends ConsumerWidget {
  const TagesgrubeKarte({super.key});

  /// Woran Tests die Knöpfe finden — sie tragen nur Zeichen.
  static const Key hinabKey = ValueKey<String>('tagesgrube-hinab');
  static const Key teilenKey = ValueKey<String>('tagesgrube-teilen');
  static const Key trotzdemKey = ValueKey<String>('tagesgrube-trotzdem');
  static const Key erstAbhakenKey = ValueKey<String>('tagesgrube-abhaken');

  /// „+25 %“ — der Aufschlag, wie er in den Erklärungen steht.
  static String get aufschlag =>
      '+${(ActionBalance.dailyFormBonus * 100).round()} %';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(ersterStartProvider).zeigtTagesgrube) {
      return const SizedBox.shrink();
    }
    final heute = ref.watch(todayDailyPitProvider);
    final lauf = heute.run;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HolzKarte(
        padding: const EdgeInsets.fromLTRB(12, 8, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _Titel(number: heute.number),
                  ),
                ),
                const SizedBox(width: 8),
                _Verfassung(
                  // Nach dem Versuch zählt, wie man hinabgestiegen ist —
                  // nicht, was seitdem abgehakt wurde.
                  condition: lauf?.condition ?? heute.condition,
                  open: lauf == null ? heute.open : 0,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (lauf == null)
              _Davor(
                loadout: heute.loadout,
                onHinab: () => _hinab(context, ref, heute),
              )
            else
              _Danach(
                lauf: lauf,
                text: TagesgrubeText.teilen(
                  number: heute.number,
                  run: lauf,
                  dayStreak: ref
                      .watch(habitTrackerProvider)
                      .currentDayStreak(ref.watch(todayProvider)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Der Versuch beginnt. Wer noch nicht in Form ist, wird einmal gefragt
  /// — genau hier lohnt der Hinweis, erst abzuhaken.
  Future<void> _hinab(
    BuildContext context,
    WidgetRef ref,
    DailyPitToday heute,
  ) async {
    if (heute.condition == DailyCondition.ohneForm) {
      final trotzdem = await showDialog<bool>(
        context: context,
        builder: (context) => _OhneFormFrage(open: heute.open),
      );
      if (!(trotzdem ?? false) || !context.mounted) return;
    }

    // Die Verfassung von jetzt: Während die Frage stand, kann sich
    // nichts abgehakt haben, aber der Tag kann gewechselt haben.
    final jetzt = ref.read(todayDailyPitProvider);
    final begonnen = ref
        .read(dailyPitProvider.notifier)
        .start(jetzt.day, jetzt.condition);
    if (!begonnen || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            DailyPitScreen(day: jetzt.day, condition: jetzt.condition),
      ),
    );
  }
}

/// „Tagesgrube #12“ — ein Tipp sagt, was sie ist.
class _Titel extends StatelessWidget {
  const _Titel({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 6),
      message:
          'Dieselbe Grube für alle, ein Versuch am Tag. Jeder geht mit '
          'demselben Helden hinab — stärker macht nur, ob du heute in Form '
          'bist. Sie bringt Ruhm.',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.today_rounded, size: 18, color: Palette.accent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Tagesgrube #$number',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// In welcher Verfassung es hinabgeht: der Blitz, die offene Zahl oder
/// der Mond.
class _Verfassung extends StatelessWidget {
  const _Verfassung({required this.condition, required this.open});

  final DailyCondition condition;

  /// Wie viele fällige Gewohnheiten noch offen sind.
  final int open;

  @override
  Widget build(BuildContext context) {
    final aufschlag = TagesgrubeKarte.aufschlag;
    final (zeichen, farbe, satz) = switch (condition) {
      DailyCondition.inForm => (
        Icons.bolt,
        Palette.accent,
        'In Form: $aufschlag auf Angriff, Leben, Abwehr und Mana.',
      ),
      DailyCondition.ruhetag => (
        Icons.bedtime_outlined,
        Palette.textDim,
        'Ruhetag: Heute ist nichts fällig. Du gehst ohne Aufschlag hinab.',
      ),
      DailyCondition.ohneForm => (
        Icons.bolt_outlined,
        Palette.muted,
        open > 0
            ? 'Noch $open offen. Ist alles Fällige erledigt, bist du in '
                  'Form: $aufschlag auf Angriff, Leben, Abwehr und Mana.'
            : 'Ohne Form hinabgestiegen.',
      ),
    };

    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 6),
      message: satz,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // In Form ist der Blitz geladen: hell auf einer Scheibe, statt
            // nur dunkler als der leere.
            if (condition == DailyCondition.inForm)
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Palette.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(zeichen, size: 20, color: Palette.surface),
              )
            else
              Icon(zeichen, size: 22, color: farbe),
            if (condition == DailyCondition.ohneForm && open > 0)
              Text(
                '$open',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Palette.textDim,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Vor dem Versuch: der Satz des Tages und der Knopf hinab.
class _Davor extends StatelessWidget {
  const _Davor({required this.loadout, required this.onHinab});

  final DailyLoadout loadout;
  final VoidCallback onHinab;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Wrap(
            spacing: 6,
            children: <Widget>[
              _Zug(moveId: loadout.weaponMoveId),
              for (final id in loadout.abilityIds) _Zug(moveId: id),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          key: TagesgrubeKarte.hinabKey,
          onPressed: onHinab,
          style: FilledButton.styleFrom(
            minimumSize: const Size(56, 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: const Icon(
            Icons.keyboard_double_arrow_down_rounded,
            size: 24,
            semanticLabel: 'In die Tagesgrube',
          ),
        ),
      ],
    );
  }
}

/// Eine Waffe oder Fähigkeit des Tages als Bild — ein Tipp sagt, was sie
/// tut.
class _Zug extends StatelessWidget {
  const _Zug({required this.moveId});

  final String moveId;

  static const double seite = 40;

  @override
  Widget build(BuildContext context) {
    final name = pitNameOf(moveId) ?? moveId;
    final wirkung = pitSummaryOf(moveId);
    final pfad = MoveIcons.forMoveId(moveId);
    const rueckfall = Icon(Icons.auto_awesome, size: 24, color: Palette.accent);

    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 6),
      message: wirkung == null ? name : '$name — $wirkung',
      child: Semantics(
        label: name,
        excludeSemantics: true,
        child: Container(
          width: seite,
          height: seite,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Palette.surfaceRaised,
            borderRadius: BorderRadius.circular(8),
          ),
          child: pfad == null
              ? rueckfall
              : PixelArt(assetPath: pfad, side: seite - 6, fallback: rueckfall),
        ),
      ),
    );
  }
}

/// Nach dem Versuch: wie es lief, der Ruhm und der Knopf zum Teilen.
class _Danach extends StatelessWidget {
  const _Danach({required this.lauf, required this.text});

  final DailyRun lauf;

  /// Was der Knopf kopiert.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: lauf.isFinished
              ? Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Raumzeile(rooms: lauf.rooms),
                    if (lauf.won)
                      Text(
                        TagesgrubeText.zeit(lauf.seconds),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Palette.text,
                        ),
                      ),
                  ],
                )
              : const Align(
                  alignment: Alignment.centerLeft,
                  child: Tooltip(
                    triggerMode: TooltipTriggerMode.tap,
                    message:
                        'Abgebrochen: Der Versuch von heute ist gebraucht. '
                        'Morgen wartet eine neue Grube.',
                    child: Icon(
                      Icons.directions_run_rounded,
                      size: 26,
                      color: Palette.textDim,
                      semanticLabel: 'Abgebrochen',
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        RuhmZahl(fame: lauf.fame, size: 15),
        const SizedBox(width: 10),
        TeilenKnopf(key: TagesgrubeKarte.teilenKey, text: text, compact: true),
      ],
    );
  }
}

/// Die eine Frage vor dem Hinabsteigen ohne Form.
class _OhneFormFrage extends StatelessWidget {
  const _OhneFormFrage({required this.open});

  final int open;

  @override
  Widget build(BuildContext context) {
    return HolzDialog(
      child: AlertDialog(
        backgroundColor: Palette.surface,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(),
        title: Text('Noch $open offen'),
        content: Text(
          'Du hast einen Versuch am Tag. Erledigst du erst, was heute '
          'fällig ist, gehst du in Form hinab: '
          '${TagesgrubeKarte.aufschlag} auf alle vier Werte.',
        ),
        actions: <Widget>[
          TextButton(
            key: TagesgrubeKarte.trotzdemKey,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Trotzdem hinab'),
          ),
          FilledButton(
            key: TagesgrubeKarte.erstAbhakenKey,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Erst abhaken'),
          ),
        ],
      ),
    );
  }
}
