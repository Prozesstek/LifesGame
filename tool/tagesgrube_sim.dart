// Die Tagesgrube: der Einheitsheld gegen die sieben Sätze der Woche
// (ADR-0072).
//
// Jeder Satz soll gleich schwer sein, und „In Form“ soll den Unterschied
// machen. Hier steht, auf welcher Stufe das für welchen Satz gilt: Der
// Bot spielt jeden Satz auf mehreren Stufen, einmal ohne Form und einmal
// mit. Gesucht ist die Stufe, auf der er ohne Form etwa jeden zweiten
// Lauf gewinnt und in Form fast jeden — sie gehört nach
// `DailyPit.loadouts`.
//
// Der Spieler ist `PitBot`, bewusst dumm: Die Quoten sind eine **untere**
// Schranke, und Fähigkeiten, die man zielen muss, unterschätzt er.
//
// Reines Dart trotz Flutter-Projekt: kein Import zieht Flutter herein.
//
//     dart run tool/tagesgrube_sim.dart          # 24 Läufe je Feld
//     dart run tool/tagesgrube_sim.dart 60
//     dart run tool/tagesgrube_sim.dart 16 4     # vier Stufen darüber und darunter

import 'package:action_combat/action_combat.dart';

const List<String> _tage = <String>[
  'Montag',
  'Dienstag',
  'Mittwoch',
  'Donnerstag',
  'Freitag',
  'Samstag',
  'Sonntag',
];

void main(List<String> args) {
  final laeufe = args.isEmpty ? 24 : int.parse(args.first);

  // Wie viele Stufen um die gesetzte herum gemessen werden.
  final umkreis = args.length < 2 ? 2 : int.parse(args[1]);

  final ohne = PitPower.dailyHero(inForm: false);
  final mit = PitPower.dailyHero(inForm: true);
  print('Die Tagesgrube — $laeufe Läufe je Feld, jede Karte neu gebaut\n');
  print(
    '  ohne Form  ATK ${ohne.combatAttack}  HP ${ohne.combatMaxHp}  '
    'DEF ${ohne.combatDefense}  Mana ${ohne.maxMana}',
  );
  print(
    '  in Form    ATK ${mit.combatAttack}  HP ${mit.combatMaxHp}  '
    'DEF ${mit.combatDefense}  Mana ${mit.maxMana}\n',
  );

  final gesetzt = <String>[];
  for (var tag = 0; tag < DailyPit.loadouts.length; tag++) {
    final satz = DailyPit.loadouts[tag];
    print(
      '${_tage[tag]}: ${satz.weaponMoveId} · ${satz.abilityIds.join(', ')}',
    );
    print('  Stufe    ohne Form       in Form');
    for (
      var stufe = satz.stage - umkreis;
      stufe <= satz.stage + umkreis;
      stufe++
    ) {
      if (stufe < 1 || stufe > PitStage.count) continue;
      final a = _spiele(satz, stufe, ohne, laeufe);
      final b = _spiele(satz, stufe, mit, laeufe);
      final marke = stufe == satz.stage ? '  ← gesetzt' : '';
      print(
        '  ${stufe.toString().padRight(6)}'
        '${a.zeile(laeufe)}   ${b.zeile(laeufe)}$marke',
      );
      if (stufe == satz.stage) {
        gesetzt.add(
          '  ${_tage[tag].padRight(11)} Stufe ${stufe.toString().padLeft(2)}'
          '   ${a.zeile(laeufe)}   ${b.zeile(laeufe)}'
          '   Räume ohne Form: ${a.raeume}   in Form: ${b.raeume}',
        );
      }
    }
    print('');
  }

  print('Die Woche, wie sie gesetzt ist — ohne Form, in Form, und wie die');
  print('Räume ausfielen (grün / gelb / rot)\n');
  gesetzt.forEach(print);
}

class _Ergebnis {
  int siege = 0;
  final List<double> zeiten = <double>[];
  int sauber = 0, angekratzt = 0, blutig = 0;

  /// „58 % 1:02“ — die Quote und die mittlere Zeit eines Siegs.
  String zeile(int laeufe) {
    zeiten.sort();
    final quote = '${(siege * 100 / laeufe).round()} %'.padLeft(5);
    if (zeiten.isEmpty) return '$quote   -  ';
    final mitte = zeiten[zeiten.length ~/ 2].round();
    return '$quote ${mitte ~/ 60}:${(mitte % 60).toString().padLeft(2, '0')}';
  }

  /// Wie die Räume ausfielen, in Prozent — zeigt, ob die Raumzeile bunt
  /// wird oder einfarbig.
  String get raeume {
    final alle = sauber + angekratzt + blutig;
    if (alle == 0) return '-';
    String anteil(int n) => '${(n * 100 / alle).round()}'.padLeft(3);
    return '${anteil(sauber)} /${anteil(angekratzt)} /${anteil(blutig)}';
  }
}

_Ergebnis _spiele(DailyLoadout satz, int stufe, ActionStats held, int laeufe) {
  final e = _Ergebnis();
  for (var i = 0; i < laeufe; i++) {
    // Nicht die Startwerte der Tage: Gemessen wird der Satz, nicht ein
    // einzelner Dienstag.
    final seed = 1000 + i;
    final stage = PitStage(stufe);
    final welt = ActionWorld(
      level: LevelBuilder.build(stage: stage, seed: seed),
      heroStats: held,
      stage: stage,
      abilityIds: satz.abilityIds,
      weaponMoveId: satz.weaponMoveId,
      seed: seed,
    );
    PitBot.play(welt);
    if (welt.isWon) {
      e.siege++;
      e.zeiten.add(welt.elapsed);
    }
    for (final marke in DailyRun.marksOf(welt)) {
      switch (marke) {
        case RoomMark.sauber:
          e.sauber++;
        case RoomMark.angekratzt:
          e.angekratzt++;
        case RoomMark.blutig:
          e.blutig++;
        case RoomMark.gefallen ||
            RoomMark.zeitAus ||
            RoomMark.krone ||
            RoomMark.offen:
          break;
      }
    }
  }
  return e;
}
