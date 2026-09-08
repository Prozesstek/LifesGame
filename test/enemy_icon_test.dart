import 'package:combat/combat.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/combat/enemy_icon.dart';

/// Die Bilder der Gegner in der Reihe.
///
/// Dieselben zwei Nähte wie bei `move_icon_test.dart` und
/// `gear_icon_test.dart`: dass eine Id wirklich in der Reihe ankommt, und
/// dass die Datei da **und** in `pubspec.yaml` angemeldet ist.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('kein Bild zeigt auf einen Gegner, den es nicht gibt', () {
    for (final id in EnemyIcons.enemyIds) {
      expect(
        Enemies.byId(id),
        isNotNull,
        reason: 'Fuer "$id" gibt es ein Bild, aber keinen Gegner.',
      );
    }
  });

  test('jede eingetragene Datei laesst sich laden', () async {
    for (final id in EnemyIcons.enemyIds) {
      final daten = await rootBundle.load(EnemyIcons.forEnemyId(id)!);

      expect(daten.lengthInBytes, greaterThan(1000));
    }
  });

  group('Derzeit gibt es keine Bilder', () {
    // Issue #36 verlangt ausdrücklich nur ein Platzhalterbild; die
    // Zeichnungen stehen in Issue #35 unter „Gegner" noch aus. Die
    // Prüfungen oben laufen bis dahin über eine leere Menge — sie greifen
    // wieder, sobald jemand eine Zeile in `EnemyIcons` ergänzt.
    test('kein einziger Gegner traegt eins', () {
      for (final gegner in Enemies.ladder) {
        expect(EnemyIcons.forEnemyId(gegner.id), isNull, reason: gegner.name);
      }
    });

    test('eine unbekannte Id ebenfalls nicht', () {
      expect(EnemyIcons.forEnemyId('gibt-es-nicht'), isNull);
    });
  });
}
