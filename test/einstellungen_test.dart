import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/ability_buttons.dart';
import 'package:lifes_game/action/action_game.dart';
import 'package:lifes_game/audio/sound_effects.dart';
import 'package:lifes_game/einstellungen/einstellungen.dart';
import 'package:lifes_game/einstellungen/einstellungen_screen.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/main.dart';

class _MerkSpieler implements SoundPlayer {
  final List<SoundEffect> gespielt = <SoundEffect>[];

  @override
  void play(SoundEffect effect) => gespielt.add(effect);
}

void main() {
  group('Einstellungen', () {
    test('lesen nachsichtig und kommen unverändert zurück', () {
      const e = Einstellungen(lautstaerke: 0.4, faehigkeitenLinks: true);
      final zurueck = Einstellungen.fromJson(e.toJson());
      expect(zurueck.lautstaerke, 0.4);
      expect(zurueck.faehigkeitenLinks, isTrue);

      final kaputt = Einstellungen.fromJson(<String, Object?>{
        'lautstaerke': 'laut',
        'faehigkeitenLinks': 3,
      });
      expect(kaputt.lautstaerke, 1);
      expect(kaputt.faehigkeitenLinks, isFalse);
      expect(Einstellungen.fromJson(null).lautstaerke, 1);
      expect(
        Einstellungen.fromJson(<String, Object?>{'lautstaerke': 7}).lautstaerke,
        1,
        reason: 'mehr als voll gibt es nicht',
      );
    });

    test('der Controller schreibt in den Speicher', () {
      final speicher = EinstellungenImSpeicher();
      final c = ProviderContainer(
        overrides: [einstellungenSpeicherProvider.overrideWithValue(speicher)],
      );
      addTearDown(c.dispose);
      c.read(einstellungenProvider.notifier)
        ..setzeLautstaerke(0.3)
        ..setzeFaehigkeitenLinks(true);
      expect(speicher.lesen().lautstaerke, closeTo(0.3, 1e-9));
      expect(speicher.lesen().faehigkeitenLinks, isTrue);
      expect(c.read(einstellungenProvider).faehigkeitenLinks, isTrue);
    });
  });

  testWidgets('das Zahnrad auf der Startseite öffnet die Einstellungen', (
    tester,
  ) async {
    final speicher = EinstellungenImSpeicher();
    final spieler = _MerkSpieler();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
          einstellungenSpeicherProvider.overrideWithValue(speicher),
          soundPlayerProvider.overrideWithValue(spieler),
        ],
        child: const LifesGameApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byKey(HomeScreen.einstellungenKey));
    await tester.pumpAndSettle();
    expect(find.byType(EinstellungenScreen), findsOneWidget);

    await tester.tap(find.byKey(EinstellungenScreen.linksKey));
    await tester.pump();
    expect(speicher.lesen().faehigkeitenLinks, isTrue);

    // Den Regler ganz nach links ziehen: stumm, und zur Probe ein Klang.
    final regler = tester.getRect(
      find.byKey(EinstellungenScreen.lautstaerkeKey),
    );
    await tester.dragFrom(regler.center, Offset(-regler.width, 0));
    await tester.pumpAndSettle();
    expect(speicher.lesen().lautstaerke, 0);
    expect(spieler.gespielt, isNotEmpty);
  });

  group('Fähigkeiten links oder rechts', () {
    Future<(Rect, Rect)> baue(
      WidgetTester tester, {
      required bool links,
    }) async {
      final game = ActionGame(
        klang: const SilentSoundPlayer(),
        startXp: null,
        sim: ActionWorld(
          level: LevelCatalog.grube,
          heroStats: ActionStats.gereift,
          abilityIds: const <String>['steinhaut'],
          ultimateId: PitAbilities.ultimates.first.id,
        ),
      );
      addTearDown(game.frame.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AbilityButtons(game: game, links: links),
            ),
          ),
        ),
      );
      final ganz = tester.getRect(find.byType(AbilityButtons));
      final ult = tester.getRect(find.byKey(const Key('ultimate-knopf')));
      return (ganz, ult);
    }

    testWidgets('rechts sitzt die Ultimate unten rechts', (tester) async {
      final (ganz, ult) = await baue(tester, links: false);
      expect(ult.right, closeTo(ganz.right, 0.5));
    });

    testWidgets('links ist alles gespiegelt', (tester) async {
      final (ganz, ult) = await baue(tester, links: true);
      expect(ult.left, closeTo(ganz.left, 0.5));
      // Der kleine Platz liegt dann rechts von der Ultimate.
      final platz = tester.getRect(find.bySemanticsLabel(RegExp('Steinhaut')));
      expect(platz.center.dx, greaterThan(ult.center.dx));
    });
  });

  test('1 Mana je Sekunde auf Level 1', () {
    const stats = ActionStats.frisch; // Energie 8, wie Level 1
    expect(stats.manaRegen, closeTo(1, 1e-9));
  });
}
