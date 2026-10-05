import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/habits/widgets/habit_timer_sheet.dart';

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
