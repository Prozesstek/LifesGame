import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/achievements/widgets/achievement_unlock_sheet.dart';
import 'package:lifes_game/character/widgets/ability_unlock_sheet.dart';
import 'package:lifes_game/habits/widgets/habit_timer_sheet.dart';
import 'package:lifes_game/progression/show_level_up.dart';
import 'package:theory/theory.dart';

/// Gibt dem Test ein hohes Fenster.
///
/// Die Standardgröße von 800x600 ist zu klein für Lektionstexte und lange
/// Antwortmöglichkeiten: Was außerhalb einer `ListView` liegt, wird gar
/// nicht erst gebaut und ist deshalb auch nicht antippbar.
void useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Gibt dem Test ein Handy im Hochformat — 390x844, wie [PhoneFrame].
///
/// Der Unterschied zu [useTallView] ist Absicht: Dort geht es darum, dass
/// eine lange Liste überhaupt gebaut wird. Hier geht es um das echte
/// Zielformat, und **schmal** ist der Teil, der wehtut. Läuft ein Widget
/// über den Rand, meldet Flutter das als Fehler und der Test schlägt fehl.
void usePhoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Hakt im offenen Timer-Blatt von Hand ab („schon erledigt“).
///
/// Eine Gewohnheit mit Zeitziel öffnet auf Tipp ihren Timer statt
/// abzuhaken (ADR-0067) — und die Startvorlage hat eins. Tests, die nur
/// „ein Häkchen“ brauchen, gehen diesen Weg, statt zwei Minuten zu warten.
Future<void> schonErledigt(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(HabitTimerSheet.doneKey));
  await tester.pumpAndSettle();
}

/// Blättert eine Seite bis zu ihren Fragen und beginnt sie.
///
/// Seit dem 18.10. kommt der Text in Häppchen (`LeseHaeppchen`): Der Knopf
/// zu den Fragen steht erst auf dem letzten Abschnitt, davor „Weiter“.
/// Hat die Seite ein Rätsel, wird es zuerst geraten — irgendwie, es
/// zählt nicht.
Future<void> zuDenFragen(WidgetTester tester, Lesson lesson) async {
  final teaser = lesson.teaser;
  if (teaser != null) {
    await tester.tap(find.text(teaser.options.first));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
  }
  final start = find.text('${lesson.questionCount} Fragen beantworten');
  for (var i = 0; i < lesson.sections.length && start.evaluate().isEmpty; i++) {
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
  }
  await tester.tap(start);
  await tester.pumpAndSettle();
}

/// Schließt jede Feier, die gerade über dem Bildschirm liegt —
/// Errungenschaft, Aufstieg, neue Fähigkeit —, bis keine mehr da ist.
///
/// Seit ADR-0079 bringt die erste Seite die Errungenschaft „Erste Seite“
/// und mit ihr Funkenstoß. Tests, die nach der ersten Seite auf den
/// Bildschirm darunter schauen, räumen hiermit die beiden Feiern weg.
/// „Ins Inventar“, nicht „Direkt ausrüsten“: Angelegt wird nichts.
Future<void> feiernSchliessen(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    final Finder knopf;
    if (find.byType(AchievementUnlockSheet).evaluate().isNotEmpty) {
      knopf = find.descendant(
        of: find.byType(AchievementUnlockSheet),
        matching: find.text('Weiter'),
      );
    } else if (find.byType(LevelUpSheet).evaluate().isNotEmpty) {
      knopf = find.descendant(
        of: find.byType(LevelUpSheet),
        matching: find.text('Weiter'),
      );
    } else if (find.byType(AbilityUnlockSheet).evaluate().isNotEmpty) {
      final inventar = find.descendant(
        of: find.byType(AbilityUnlockSheet),
        matching: find.text('Ins Inventar'),
      );
      knopf = inventar.evaluate().isNotEmpty
          ? inventar
          : find.descendant(
              of: find.byType(AbilityUnlockSheet),
              matching: find.text('Weiter'),
            );
    } else {
      return;
    }
    await tester.tap(knopf);
    await tester.pumpAndSettle();
  }
}
