// Spielbarer Kampf im Terminal. Kein Flutter, kein Flame -- nur die
// Kampflogik aus diesem Package plus etwas Textausgabe.
//
// Zweck: den Kern-Loop fuehlen, bevor eine Zeile UI existiert. Genau die
// Frage, an der laut konzept.md alles haengt.
//
// Aufruf:
//   dart run example/play.dart

import 'dart:io';
import 'dart:math';

import 'package:combat/combat.dart';

/// Reaktionszeit in Millisekunden bis zur jeweiligen Wertung.
const int _perfectWindowMs = 300;
const int _goodWindowMs = 550;

void main() {
  _printIntro();

  final engine = CombatEngine(seed: DateTime.now().millisecondsSinceEpoch);

  // Werte eines Charakters, der etwa eine Woche Gewohnheiten hinter sich
  // hat. Die echten Werte liefert `package:habits`, das dieses Package
  // bewusst nicht kennt -- hier stehen sie nur, um spielbar zu sein.
  var state = CombatState.start(
    player: Combatant.fresh(
      name: 'Du',
      maxHp: 168,
      attack: 14,
      defense: 10,
      maxEnergy: 10,
    ),
    enemy: Enemies.wegelagerer.spawn(),
  );

  while (!state.isOver) {
    _drawStatus(state);
    final move = _askMove(state);
    if (move == null) {
      stdout.writeln('\nAbgebrochen.');
      return;
    }

    final timing = move.dealsDamage ? _askTiming() : TimedHit.none;
    final step = engine.resolveRound(
      state,
      PlayerAction(move: move, timedHit: timing),
    );

    stdout.writeln('');
    for (final event in step.events) {
      final line = _describe(event);
      if (line != null) stdout.writeln('  $line');
    }
    state = step.state;
  }

  _printOutcome(state);
}

void _printIntro() {
  stdout
    ..writeln('')
    ..writeln('=== LIFES GAME — Kampfprobe ===')
    ..writeln('')
    ..writeln('Beide Seiten starten gleich stark. Dein Angriffswert kaeme im')
    ..writeln('fertigen Spiel aus deinen Habits — hier ist er fest auf 16.')
    ..writeln('')
    ..writeln('Bei Angriffen erscheint "JETZT!" — dann so schnell wie moeglich')
    ..writeln('Enter druecken. Unter ${_perfectWindowMs}ms perfekt, unter '
        '${_goodWindowMs}ms gut.')
    ..writeln('(Fruehstarten wird hier nicht erkannt — es ist ein Fuehl-Test,')
    ..writeln(' kein Wettkampf.)')
    ..writeln('');
}

void _drawStatus(CombatState state) {
  stdout
    ..writeln('')
    ..writeln('--- Runde ${state.round} ---')
    ..writeln('  Du      ${_bar(state.player)}  ${_statuses(state.player)}')
    ..writeln('  Gegner  ${_bar(state.enemy)}  ${_statuses(state.enemy)}');
}

String _bar(Combatant c) {
  const width = 20;
  final filled = (c.hp / c.maxHp * width).round().clamp(0, width);
  final hp = '${c.hp}/${c.maxHp}'.padRight(8);
  final energy = '${c.energy}/${c.maxEnergy}'.padLeft(5);
  return '[${'#' * filled}${'.' * (width - filled)}] HP $hp EN $energy';
}

String _statuses(Combatant c) {
  if (c.statuses.isEmpty) return '';
  return c.statuses.map((s) => '${s.id}(${s.remainingTurns})').join(' ');
}

/// Gibt `null` zurueck, wenn der Spieler abbrechen will.
Move? _askMove(CombatState state) {
  stdout.writeln('');
  const loadout = Moves.defaultLoadout;
  for (var i = 0; i < loadout.length; i++) {
    final move = loadout[i];
    final cost = move.energyDelta >= 0
        ? '+${move.energyDelta} EN'
        : '${move.energyDelta} EN';
    final blocked =
        move.isAffordableBy(state.player.energy) ? '' : '   (zu wenig Energie)';
    stdout.writeln('  ${i + 1}) ${move.name.padRight(12)} $cost$blocked');
  }
  stdout.writeln('  q) Abbrechen');

  while (true) {
    stdout.write('\nDein Zug: ');
    final input = stdin.readLineSync()?.trim().toLowerCase();
    // null heisst Eingabeende (Strg+Z / geschlossene Pipe) — sonst wuerde
    // die Schleife hier endlos die Fehlermeldung wiederholen.
    if (input == null || input == 'q') return null;

    final choice = int.tryParse(input);
    if (choice == null || choice < 1 || choice > loadout.length) {
      stdout.writeln('  Bitte 1 bis ${loadout.length} oder q.');
      continue;
    }

    final move = loadout[choice - 1];
    if (!move.isAffordableBy(state.player.energy)) {
      stdout.writeln('  Dafuer fehlt Energie. Schlag erzeugt welche.');
      continue;
    }
    return move;
  }
}

TimedHit _askTiming() {
  final wait = 500 + Random().nextInt(1200);
  stdout.write('  bereit ...');
  sleep(Duration(milliseconds: wait));
  stdout.write('\r  >>> JETZT! <<<          ');

  final watch = Stopwatch()..start();
  stdin.readLineSync();
  watch.stop();

  final ms = watch.elapsedMilliseconds;
  if (ms <= _perfectWindowMs) {
    stdout.writeln('  ${ms}ms — PERFEKT');
    return TimedHit.perfect;
  }
  if (ms <= _goodWindowMs) {
    stdout.writeln('  ${ms}ms — gut');
    return TimedHit.good;
  }
  stdout.writeln('  ${ms}ms — daneben');
  return TimedHit.none;
}

/// Uebersetzt ein Event in eine lesbare Zeile. `null` heisst: nicht anzeigen.
String? _describe(CombatEvent event) {
  return switch (event) {
    RoundStarted() => null,
    EnergyChanged() => null,
    MoveUsed(:final side, :final moveId) =>
      '${_who(side)} nutzt ${_moveName(moveId)}.',
    MoveFailed(:final side) =>
      '${_who(side)} ${_verb(side, 'hast', 'hat')} nicht genug Energie.',
    DamageDealt(:final target, :final amount, :final timedHitFactor) =>
      '${_who(target)} ${_verb(target, 'nimmst', 'nimmt')} $amount Schaden'
          '${timedHitFactor > 1.0 ? '  <<< Treffer!' : '.'}',
    DamageAbsorbed(:final target, :final amount) =>
      '${_possessive(target)} Schild faengt $amount ab.',
    ShieldBroke(:final target) => '${_possessive(target)} Schild zerbricht.',
    Healed(:final target, :final amount) =>
      '${_who(target)} ${_verb(target, 'heilst', 'heilt')} $amount HP.',
    StatusApplied(:final target, :final statusId, :final turns) =>
      '${_who(target)}: ${_statusName(statusId)} fuer $turns Runden.',
    StatusTicked(:final target, :final statusId, :final damage) =>
      '${_who(target)} ${_verb(target, 'verlierst', 'verliert')} $damage HP '
          'durch ${_statusName(statusId)}.',
    StatusExpired(:final target, :final statusId) =>
      '${_statusName(statusId)} bei ${_dative(target)} laeuft aus.',
    CombatantDefeated(:final side) =>
      '${_who(side)} ${_verb(side, 'gehst', 'geht')} zu Boden.',
    CombatEnded() => null,
  };
}

String _who(Side side) => side == Side.player ? 'Du' : 'Gegner';

/// Deutsche Konjugation: der Spieler wird geduzt, der Gegner in der
/// dritten Person beschrieben.
String _verb(Side side, String zweitePerson, String drittePerson) =>
    side == Side.player ? zweitePerson : drittePerson;

String _possessive(Side side) => side == Side.player ? 'Dein' : 'Gegnerisches';

String _dative(Side side) => side == Side.player ? 'dir' : 'Gegner';

String _moveName(String id) {
  for (final move in Moves.defaultLoadout) {
    if (move.id == id) return move.name;
  }
  return id;
}

String _statusName(String id) => switch (id) {
      'poison' => 'Gift',
      'defense_down' => 'Verteidigung gesenkt',
      'shield' => 'Schild',
      _ => id,
    };

void _printOutcome(CombatState state) {
  stdout.writeln('');
  if (state.outcome == CombatOutcome.victory) {
    stdout.writeln('=== GEWONNEN nach ${state.round - 1} Runden ===');
  } else {
    stdout.writeln('=== VERLOREN nach ${state.round - 1} Runden ===');
  }
  stdout
    ..writeln('')
    ..writeln('Hat sich das gut angefuehlt? Genau das ist die Frage, die das')
    ..writeln('MVP beantworten soll. Balance-Schrauben: lib/src/balance.dart')
    ..writeln('');
}
