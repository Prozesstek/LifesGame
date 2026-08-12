import 'habit.dart';

/// Alle Gewohnheits-Vorlagen des Spiels.
///
/// Jede Vorlage hier hat genau eine Lektion im Skillbaum, die sie
/// freischaltet — und jede Lektion mit `unlocksHabit` hat genau eine
/// Vorlage hier. Beide Richtungen prüft `test/habits_theory_test.dart`.
/// Die Verbindung läuft über [HabitTemplate.name], weil `package:theory`
/// und `package:habits` bewusst nichts voneinander wissen.
abstract final class HabitCatalog {
  static const List<HabitTemplate> all = <HabitTemplate>[
    // --- Gewohnheiten (Wurzelzweig) ---
    HabitTemplate(
      id: 'habit-drei-aufgaben',
      name: 'Drei Aufgaben für morgen festlegen',
      stat: HabitStat.disziplin,
      branchId: 'habits',
      why: 'Der Abend entscheidet, wie der Morgen läuft. Eine Entscheidung '
          'im Voraus kostet abends eine Minute und morgens keine.',
    ),
    HabitTemplate(
      id: 'habit-zwei-minuten-lesen',
      name: 'Zwei Minuten lesen',
      stat: HabitStat.klarheit,
      branchId: 'habits',
      why: 'So klein, dass kein Tag zu voll dafür ist. Die Länge ist nicht '
          'der Punkt — dass es überhaupt stattfindet, ist der Punkt.',
    ),
    HabitTemplate(
      id: 'habit-abendnotiz',
      name: 'Abendnotiz: ein Beleg für heute',
      stat: HabitStat.disziplin,
      branchId: 'habits',
      why: 'Ein Satz, der belegt, dass der Tag gezählt hat. Ohne Beleg '
          'erinnert man abends nur das, was fehlte.',
    ),

    // --- Körper ---
    HabitTemplate(
      id: 'habit-aufstehzeit',
      name: 'Feste Aufstehzeit — auch am Wochenende',
      stat: HabitStat.ausdauer,
      branchId: 'koerper',
      why: 'Die Aufstehzeit stellt die innere Uhr, nicht die Zubettgehzeit. '
          'Zwei Stunden Unterschied am Wochenende wirken wie ein Jetlag.',
    ),
    HabitTemplate(
      id: 'habit-zehn-minuten-gehen',
      name: 'Zehn Minuten am Stück gehen',
      stat: HabitStat.staerke,
      branchId: 'koerper',
      why: 'Die erste Bewegung des Tages ist die, die am seltensten '
          'ausfällt. Zehn Minuten sind kurz genug, um nicht zu verhandeln.',
    ),
    HabitTemplate(
      id: 'habit-wasser-vor-mahlzeit',
      name: 'Ein Glas Wasser vor jeder Mahlzeit',
      stat: HabitStat.ausdauer,
      branchId: 'koerper',
      why: 'An eine bestehende Handlung gehängt — die Mahlzeit ist der '
          'Auslöser, den man nicht vergisst.',
    ),

    // --- Geist ---
    HabitTemplate(
      id: 'habit-stunde-ohne-benachrichtigungen',
      name: 'Eine Stunde ohne Benachrichtigungen',
      stat: HabitStat.klarheit,
      branchId: 'geist',
      why: 'Nicht die Nachricht kostet die Aufmerksamkeit, sondern die '
          'Erwartung einer Nachricht.',
    ),
    HabitTemplate(
      id: 'habit-fuenf-minuten-still',
      name: 'Fünf Minuten still sitzen',
      stat: HabitStat.klarheit,
      branchId: 'geist',
      why: 'Übung darin, einen Impuls zu bemerken, ohne ihm zu folgen. '
          'Genau das braucht jede andere Gewohnheit auch.',
    ),

    // --- Wissenschaft ---
    HabitTemplate(
      id: 'habit-messgroesse-notieren',
      name: 'Eine Messgröße täglich notieren',
      stat: HabitStat.klarheit,
      branchId: 'wissenschaft',
      why: 'Ohne Zahl bleibt jeder Selbstversuch ein Gefühl. Eine einzige '
          'Größe reicht, solange sie täglich dieselbe ist.',
    ),

    // --- Gesellschaft ---
    HabitTemplate(
      id: 'habit-echte-frage',
      name: 'Einem Menschen täglich eine echte Frage stellen',
      stat: HabitStat.staerke,
      branchId: 'gesellschaft',
      why: 'Beziehungen entstehen aus Interesse, nicht aus Anwesenheit. '
          'Eine Frage pro Tag ist wenig genug, um sie zu stellen.',
    ),
    HabitTemplate(
      id: 'habit-vor-zusage-durchatmen',
      name: 'Vor jeder Zusage einmal durchatmen',
      stat: HabitStat.disziplin,
      branchId: 'gesellschaft',
      why: 'Der Atemzug schiebt eine Entscheidung zwischen Frage und '
          'Antwort. Ohne ihn sagt die Gewohnheit ja, nicht man selbst.',
    ),
  ];

  static HabitTemplate? byId(String id) {
    for (final template in all) {
      if (template.id == id) return template;
    }
    return null;
  }

  /// Die Vorlage zu einem Namen, wie ihn `Lesson.unlocksHabit` liefert.
  static HabitTemplate? byName(String name) {
    for (final template in all) {
      if (template.name == name) return template;
    }
    return null;
  }

  /// Alle Vorlagen, deren Namen freigeschaltet sind — die Übersetzung von
  /// „bestandene Lektionen“ in „wählbare Gewohnheiten“.
  ///
  /// Unbekannte Namen werden übersprungen, nicht geworfen: Ein Tippfehler
  /// im Inhalt darf die App nicht anhalten. Gefunden wird er vom
  /// Nahtstellen-Test, nicht vom Nutzer.
  static List<HabitTemplate> byNames(Iterable<String> names) {
    final found = <HabitTemplate>[];
    for (final name in names) {
      final template = byName(name);
      if (template != null) found.add(template);
    }
    return List<HabitTemplate>.unmodifiable(found);
  }
}
