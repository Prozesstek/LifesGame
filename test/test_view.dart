import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/achievements/widgets/achievement_unlock_sheet.dart';
import 'package:lifes_game/character/widgets/ability_unlock_sheet.dart';
import 'package:lifes_game/habits/widgets/habit_timer_sheet.dart';
import 'package:lifes_game/progression/show_level_up.dart';
import 'package:lifes_game/theory/widgets/mentor_dialog.dart';
import 'package:lifes_game/theory/widgets/umblaettern.dart';
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
/// Seit dem 18.10. kommt der Text in Häppchen (`LeseHaeppchen`), seit
/// dem 03.11. in einem Buch ohne Knopf ([buchDurch]).
/// Hat die Seite ein Rätsel, wird es zuerst geraten — irgendwie, es
/// zählt nicht.
Future<void> zuDenFragen(WidgetTester tester, Lesson lesson) async {
  final teaser = lesson.teaser;
  if (teaser != null) {
    await waehle(tester, teaser.options.first);
    await tester.tap(find.text('Buch öffnen'));
    await tester.pumpAndSettle();
  }
  await buchDurch(tester);
}

/// Blättert das Buch bis über die letzte Seite, dann klappt es zu.
///
/// Seit dem 03.11. gibt es keinen Knopf „Weiter“ mehr: Geblättert wird am
/// Eselsohr unten rechts, und auf der letzten Seite schließt es das Buch.
Future<void> buchDurch(WidgetTester tester) async {
  await tester.pumpAndSettle();
  for (var i = 0; i < 40; i++) {
    final ohr = find.byKey(Umblaettern.ohrVorKey);
    if (ohr.evaluate().isEmpty) return;
    await tester.tap(ohr);
    await tester.pumpAndSettle();
  }
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
        matching: find.text(LevelUpSheet.weiter),
      );
    } else if (find.byType(AbilityUnlockSheet).evaluate().isNotEmpty) {
      // „Ins Inventar“, wenn es die Wahl gibt; im Tutorial ist sie schon
      // angelegt („Weiter geht's“); ohne freien Platz „Weiter“.
      Finder imBlatt(String text) => find.descendant(
        of: find.byType(AbilityUnlockSheet),
        matching: find.text(text),
      );
      knopf =
          <Finder>[
            imBlatt('Ins Inventar'),
            imBlatt(AbilityUnlockSheet.weiter),
            imBlatt('Weiter'),
          ].firstWhere(
            (f) => f.evaluate().isNotEmpty,
            orElse: () => imBlatt('Weiter'),
          );
    } else {
      return;
    }
    await tester.tap(knopf);
    await tester.pumpAndSettle();
  }
}

/// Wählt beim Mentor eine Antwort und sagt sie ihm (03.11.2026): Erst legt
/// ein Tipp sie fest, dann sagt „Antworten“ sie.
Future<void> waehle(WidgetTester tester, String antwort) async {
  await tester.tap(find.text(antwort));
  await tester.pump();
  await tester.tap(find.byKey(MentorDialog.antwortenKey));
  await tester.pumpAndSettle();
}
