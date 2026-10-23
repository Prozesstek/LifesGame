import 'package:flutter/material.dart';
import 'package:habits/habits.dart';

import '../../gear/gear_icon.dart';
import '../../ui/anschlagtafel.dart';
import '../../ui/druck.dart';
import '../../ui/palette.dart';
import '../../ui/pixel_art.dart';

/// Die drei Aufgaben des Tages (ADR-0055) — als **Anschlagtafel**, jede
/// Aufgabe ein Steckbrief (Wunsch vom 23.10.2026).
///
/// Ein Steckbrief hat ein Bild, darunter wer gesucht wird, und unten die
/// Belohnung. Hier: das Zeichen der Aufgabe, ihr Satz, Kästchen für den
/// Stand und der Schlüssel. Abgeholt wird mit einem Tipp aufs Blatt,
/// danach liegt ein Stempel darauf.
///
/// **Abholen ist ein eigener Tipp**, nicht automatisch: Der kurze Moment,
/// in dem der Schlüssel dazukommt, ist die Belohnung — wie beim Öffnen der
/// Tagestruhe.
class DailyQuestsCard extends StatelessWidget {
  const DailyQuestsCard({
    required this.quests,
    required this.isClaimed,
    required this.onClaim,
    super.key,
  });

  /// Woran man ein abholbares Blatt findet — es trägt kein Wort. Der
  /// Schlüssel sitzt am Knopf unten, getippt wird das ganze Blatt.
  static const Key abholenKey = ValueKey<String>('quest-abholen');

  final List<DailyQuest> quests;
  final bool Function(DailyQuest quest) isClaimed;
  final void Function(DailyQuest quest) onClaim;

  /// Wie schief die Blätter hängen und wie tief — fest, nicht gewürfelt,
  /// damit sie bei jedem Neubau gleich hängen.
  static const List<double> _neigung = <double>[-0.045, 0.03, -0.02];
  static const List<double> _versatz = <double>[0, 10, 4];

  static const double _luecke = 8;

  @override
  Widget build(BuildContext context) {
    final fertig = quests.where(isClaimed).length;

    return Anschlagtafel(
      schild: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.flag_rounded,
            size: 20,
            semanticLabel: 'Tagesaufgaben',
          ),
          const SizedBox(width: 8),
          Text('$fertig / ${quests.length}'),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, platz) {
          // Immer ein Drittel, auch wenn heute nur zwei hängen: Ein
          // einzelnes Blatt über die ganze Tafel wäre kein Aushang mehr.
          final breite =
              (platz.maxWidth - (DailyQuests.perDay - 1) * _luecke) /
              DailyQuests.perDay;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (var i = 0; i < quests.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: _luecke),
                SizedBox(
                  width: breite,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: _versatz[i % _versatz.length],
                    ),
                    child: _Aufgabe(
                      key: ValueKey<String>(quests[i].id),
                      quest: quests[i],
                      claimed: isClaimed(quests[i]),
                      onClaim: () => onClaim(quests[i]),
                      neigung: _neigung[i % _neigung.length],
                      saat: i,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Ein Steckbrief: Bild, Satz, Kästchen, Belohnung.
class _Aufgabe extends StatelessWidget {
  const _Aufgabe({
    required this.quest,
    required this.claimed,
    required this.onClaim,
    required this.neigung,
    required this.saat,
    super.key,
  });

  final DailyQuest quest;
  final bool claimed;
  final VoidCallback onClaim;
  final double neigung;
  final int saat;

  @override
  Widget build(BuildContext context) {
    final abholbar = quest.isDone && !claimed;

    // Der Satz steht immer da, offen wie abgeholt: Ein Zeichen mit
    // Kästchen sagt nicht, was zu tun ist.
    final blatt = Steckbrief(
      neigung: neigung,
      saat: saat,
      abgestempelt: claimed,
      stempelText: 'Abgeholt',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Bild(kind: quest.kind, claimed: claimed),
          const SizedBox(height: 6),
          Text(
            quest.text,
            textAlign: TextAlign.center,
            // „Hol nach, was gestern liegen blieb: …“ samt Namen braucht
            // auf einem Drittel der Tafel bis zu sieben Zeilen.
            maxLines: 7,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: claimed ? Palette.textDim : Palette.text,
            ),
          ),
          const SizedBox(height: 6),
          _Kaestchen(progress: quest.progress, target: quest.target),
          const SizedBox(height: 6),
          // Die Linie, unter der auf einem Aushang die Belohnung steht.
          Container(height: 1, color: Palette.textDim.withValues(alpha: 0.5)),
          const SizedBox(height: 6),
          _Belohnung(abholbar: abholbar, claimed: claimed),
        ],
      ),
    );

    // **Die Hülle bleibt, auch wenn es nichts abzuholen gibt.** Fiele sie
    // beim Abholen weg, baute sich das Blatt neu, und der Stempel läge
    // sofort da, statt aufzuschlagen.
    return Semantics(
      button: abholbar,
      label: abholbar ? 'Abholen' : null,
      child: Druck(
        enabled: abholbar,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: abholbar ? onClaim : null,
          child: blatt,
        ),
      ),
    );
  }
}

/// Wo auf einem Steckbrief das Gesicht wäre: das Zeichen der Aufgabe in
/// einem gedruckten Kasten.
class _Bild extends StatelessWidget {
  const _Bild({required this.kind, required this.claimed});

  final QuestKind kind;
  final bool claimed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Palette.surfaceRaised,
        border: Border.all(color: Palette.textDim, width: 1.5),
      ),
      child: Icon(
        _zeichen(kind),
        size: 22,
        color: claimed ? Palette.textDim : Palette.accent,
      ),
    );
  }

  static IconData _zeichen(QuestKind kind) => switch (kind) {
    QuestKind.zweiHaekchen => Icons.check_circle_outline,
    QuestKind.dreiHaekchen => Icons.check_circle_outline,
    QuestKind.alles => Icons.done_all_rounded,
    QuestKind.liegengeblieben => Icons.history_rounded,
    QuestKind.rueckfrage => Icons.quiz_outlined,
  };
}

/// Der Stand als Kästchen zum Ankreuzen — eins je Schritt.
class _Kaestchen extends StatelessWidget {
  const _Kaestchen({required this.progress, required this.target});

  final int progress;
  final int target;

  /// Darüber werden es zu viele Kästchen; dann steht die Zahl da.
  static const int hoechstens = 6;

  static const double _seite = 13;

  @override
  Widget build(BuildContext context) {
    final stand = '$progress / $target';
    if (target > hoechstens) {
      return Text(
        stand,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Palette.textDim),
      );
    }
    return Semantics(
      label: stand,
      excludeSemantics: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 3,
        runSpacing: 3,
        children: <Widget>[
          for (var i = 0; i < target; i++)
            Container(
              width: _seite,
              height: _seite,
              decoration: BoxDecoration(
                border: Border.all(color: Palette.textDim, width: 1.5),
              ),
              child: i < progress
                  ? const Icon(
                      Icons.check_rounded,
                      size: _seite - 2,
                      color: Palette.accent,
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

/// Die Belohnung unten auf dem Blatt: ein Schlüssel. Ist die Aufgabe
/// erledigt, wird daraus der Knopf — getippt wird aber das ganze Blatt.
class _Belohnung extends StatelessWidget {
  const _Belohnung({required this.abholbar, required this.claimed});

  final bool abholbar;
  final bool claimed;

  @override
  Widget build(BuildContext context) {
    final inhalt = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '+${DailyQuests.keysPerQuest}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: abholbar ? Palette.surface : Palette.textDim,
          ),
        ),
        const SizedBox(width: 3),
        PixelArt(
          assetPath: GearIcons.schluessel,
          side: 18,
          fallback: Icon(
            Icons.key,
            size: 14,
            color: abholbar ? Palette.surface : Palette.textDim,
          ),
        ),
      ],
    );

    return Center(
      child: abholbar
          ? DecoratedBox(
              key: DailyQuestsCard.abholenKey,
              decoration: BoxDecoration(
                color: Palette.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 3, 9, 3),
                child: inhalt,
              ),
            )
          // Abgeholt bleibt der Schlüssel blass stehen, damit die Blätter
          // gleich hoch bleiben.
          : Opacity(
              opacity: claimed ? 0.35 : 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: inhalt,
              ),
            ),
    );
  }
}
