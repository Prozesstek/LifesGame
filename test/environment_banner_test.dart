import 'package:combat/combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/combat/widgets/environment_banner.dart';

/// Die Umgebung ist im Kampf ablesbar, solange sie wirkt.
///
/// Vorher stand sie einmal als Logzeile im Bild und war zwei Zeilen später
/// nicht mehr auffindbar — anders als Statuseffekte, die seit jeher Chips
/// mit Restrunden am Kämpfer haben.
void main() {
  Future<void> pumpBanner(WidgetTester tester, Environment? environment) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: EnvironmentBanner(environment: environment)),
      ),
    );
  }

  testWidgets('ohne Umgebung steht nichts da', (tester) async {
    await pumpBanner(tester, null);

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('die Fläche bleibt trotzdem gleich hoch', (tester) async {
    // Sonst springt der Kampfbereich in dem Moment, in dem jemand eine
    // Umgebung legt — mitten in der Animation.
    await pumpBanner(tester, null);
    final leer = tester.getSize(find.byType(EnvironmentBanner));

    await pumpBanner(tester, Environments.frost);
    final gefuellt = tester.getSize(find.byType(EnvironmentBanner));

    expect(leer.height, gefuellt.height);
    expect(leer.height, EnvironmentBanner.height);
  });

  testWidgets('sie nennt Namen und Restrunden', (tester) async {
    await pumpBanner(tester, Environments.frost);

    expect(find.text('Eisfeld'), findsOneWidget);
    expect(find.text('noch 3 Runden'), findsOneWidget);
  });

  testWidgets('die letzte Runde steht im Singular', (tester) async {
    await pumpBanner(tester, Environments.frost.copyWith(remainingTurns: 1));

    expect(find.text('noch 1 Runde'), findsOneWidget);
  });

  testWidgets('eine verlängerte Umgebung zeigt die längere Dauer', (
    tester,
  ) async {
    // Perfekt gelegt hält sie eine Runde länger — das muss ablesbar sein,
    // sonst ist der Unterschied zwischen einem guten und einem perfekten
    // Tipp unsichtbar.
    await pumpBanner(tester, Environments.frost.withExtraTurns(1));

    expect(find.text('noch 4 Runden'), findsOneWidget);
  });

  testWidgets('Giftboden heißt Giftboden, nicht poison_bog', (tester) async {
    await pumpBanner(tester, Environments.poisonBog);

    expect(find.text('Giftboden'), findsOneWidget);
    expect(find.text('noch 4 Runden'), findsOneWidget);
  });
}
