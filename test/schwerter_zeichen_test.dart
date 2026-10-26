import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/combat/ladder_screen.dart';
import 'package:lifes_game/combat/widgets/schwerter_zeichen.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// „Hinab“ trägt zwei gekreuzte Schwerter statt der Pfeile (26.10.).
void main() {
  testWidgets('der Knopf in die Grube trägt die Schwerter', (tester) async {
    usePhoneView(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedGameProvider.overrideWithValue(
            const SaveData(ladder: LadderProgress(highestDefeated: 3)),
          ),
        ],
        child: const MaterialApp(home: LadderScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final knopf = find.byKey(LadderScreen.hinabKey);
    expect(
      find.descendant(of: knopf, matching: find.byType(SchwerterZeichen)),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.keyboard_double_arrow_down_rounded), findsNothing);
    expect(find.bySemanticsLabel('Hinab'), findsOneWidget);
  });
}
