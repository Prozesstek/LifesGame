import 'package:progression/progression.dart';
import 'package:test/test.dart';

/// Prüft, wie sich die vier Fähigkeitsslots über die Level öffnen
/// (ADR-0012, ADR-0013).
///
/// Der Inhalt der Slots — die zwanzig Fähigkeiten — ist noch nicht
/// entschieden. Geprüft wird hier ausschließlich, **wie viele** Plätze
/// offen sind und ab wann.
void main() {
  group('Wie viele Slots offen sind', () {
    test('Slot 1 ist von Anfang an da', () {
      // Er trägt die Fähigkeit der Waffe (ADR-0013). Wer keine Waffe hat,
      // hat trotzdem den Platz.
      expect(AbilitySlots.openAt(1), 1);
      expect(AbilitySlots.openAt(2), 1);
    });

    test('die drei freien Slots öffnen auf 3, 6 und 10', () {
      expect(AbilitySlots.openAt(3), 2);
      expect(AbilitySlots.openAt(5), 2);
      expect(AbilitySlots.openAt(6), 3);
      expect(AbilitySlots.openAt(9), 3);
      expect(AbilitySlots.openAt(10), 4);
    });

    test('ab Level 10 kommt keiner mehr dazu', () {
      expect(AbilitySlots.openAt(11), AbilitySlots.total);
      expect(AbilitySlots.openAt(50), AbilitySlots.total);
    });

    test('unter Level 1 bleibt es bei einem', () {
      // Ein Levelstand kann nie unter 1 liegen, aber eine Zahl, die von
      // außen kommt, darf hier nichts kaputtmachen.
      expect(AbilitySlots.openAt(0), 1);
      expect(AbilitySlots.openAt(-5), 1);
    });

    test('mehr Level nimmt nie einen Slot weg', () {
      // Dieselbe Zusage wie bei den Titeln: Fortschritt schrumpft nicht.
      var previous = 0;
      for (var level = 1; level <= 50; level++) {
        final open = AbilitySlots.openAt(level);
        expect(open, greaterThanOrEqualTo(previous));
        previous = open;
      }
      expect(previous, AbilitySlots.total);
    });
  });

  group('Ab welchem Level ein einzelner Slot aufgeht', () {
    test('nennt für jeden Slot seine Stufe', () {
      expect(AbilitySlots.levelForSlot(1), 1);
      expect(AbilitySlots.levelForSlot(2), 3);
      expect(AbilitySlots.levelForSlot(3), 6);
      expect(AbilitySlots.levelForSlot(4), 10);
    });

    test('einen fünften Slot gibt es nicht', () {
      expect(AbilitySlots.levelForSlot(5), isNull);
      expect(AbilitySlots.levelForSlot(0), isNull);
    });

    test('jede Stufe liegt über der vorigen', () {
      // Damit „ab Level x" im Bildschirm aufsteigend gelesen werden kann.
      for (var slot = 2; slot <= AbilitySlots.total; slot++) {
        expect(
          AbilitySlots.levelForSlot(slot)!,
          greaterThan(AbilitySlots.levelForSlot(slot - 1)!),
        );
      }
    });
  });

  group('Der nächste Slot', () {
    test('nennt die Stufe, auf die es sich zu warten lohnt', () {
      expect(AbilitySlots.nextUnlockAfter(1), 3);
      expect(AbilitySlots.nextUnlockAfter(3), 6);
      expect(AbilitySlots.nextUnlockAfter(5), 6);
      expect(AbilitySlots.nextUnlockAfter(6), 10);
    });

    test('ist null, wenn alle offen sind', () {
      expect(AbilitySlots.nextUnlockAfter(10), isNull);
      expect(AbilitySlots.nextUnlockAfter(42), isNull);
    });
  });

  group('Die Stufen passen zur Levelkurve', () {
    test('alle vier Slots liegen im spielbaren Bereich', () {
      // Ein Slot jenseits von maxLevel wäre einer, den niemand je
      // bekommt.
      for (var slot = 1; slot <= AbilitySlots.total; slot++) {
        expect(
          AbilitySlots.levelForSlot(slot)!,
          lessThanOrEqualTo(LevelCurve.maxLevel),
        );
      }
    });

    test('der letzte Slot kommt früh genug, um noch etwas zu bedeuten', () {
      // Bei etwa 150 XP am Tag ist Level 10 nach gut zwei Wochen
      // erreicht. Läge der letzte Slot deutlich später, wäre die freie
      // Zusammenstellung ein Versprechen für Leute, die längst
      // aufgehört haben.
      final xp = LevelCurve.totalXpFor(AbilitySlots.levelForSlot(4)!);
      const xpProTag = 150;

      expect(xp / xpProTag, lessThan(30));
    });
  });
}
