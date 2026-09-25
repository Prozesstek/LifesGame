import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:lifes_game/home/widgets/character_stage.dart';
import 'package:lifes_game/ui/pixel_art.dart';
import 'package:progression/progression.dart';

/// Helm, Rüstung und Waffe auf der Figur des Startbildschirms.
///
/// Dieselben Nähte wie in `gear_icon_test.dart` — jeder Helm hat eine
/// Zeichnung, jede Zeichnung ist da und angemeldet — plus die eine
/// Zusage, an der das Bild hängt: **gleich groß wie die Figur**, sonst
/// sitzt der Helm nicht auf dem Kopf.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('jedes Stück auf Helm, Rüstung und Waffe hat eine Zeichnung', () {
    for (final slot in CharacterStage.layers) {
      for (final item in GearCatalog.forSlot(slot)) {
        expect(
          CharacterStage.overlays,
          contains(item.id),
          reason: '${item.name} steht im Laden, aber die Figur trägt es nicht.',
        );
      }
    }
  });

  test('keine Zeichnung zeigt auf ein Stück, das es nicht gibt', () {
    final ids = GearCatalog.all.map((item) => item.id);
    for (final id in CharacterStage.overlays.keys) {
      expect(ids, contains(id));
    }
  });

  test('jede Zeichnung ist ein PNG in der Größe der Figur', () async {
    final figur = await rootBundle.load(CharacterStage.assetPath);
    final breite = figur.getUint32(16);
    final hoehe = figur.getUint32(20);
    expect(breite, PixelArt.assetSize);

    for (final pfad in CharacterStage.overlays.values) {
      final daten = await rootBundle.load(pfad);
      expect(daten.getUint32(0), 0x89504E47, reason: '$pfad ist kein PNG.');
      expect(daten.getUint32(16), breite, reason: pfad);
      expect(daten.getUint32(20), hoehe, reason: pfad);
    }
  });

  Future<void> zeige(WidgetTester tester, {List<String> worn = const []}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 400,
            child: CharacterStage(
              level: LevelCurve.levelFor(0),
              gold: 0,
              worn: worn,
            ),
          ),
        ),
      ),
    );
  }

  // Die Goldmünze darunter ist auch `PixelArt` — gezählt wird nur die Figur.
  List<String> figurenbilder(WidgetTester tester) => tester
      .widgetList<PixelArt>(find.byType(PixelArt))
      .map((b) => b.assetPath)
      .where((p) => p.startsWith('assets/character/'))
      .toList();

  testWidgets('ohne Helm steht nur die Figur da', (tester) async {
    await zeige(tester);

    expect(figurenbilder(tester), <String>[CharacterStage.assetPath]);
  });

  testWidgets('Rüstung, Waffe und Helm liegen in dieser Reihenfolge', (
    tester,
  ) async {
    // Absichtlich verdreht übergeben: gestapelt wird nach Platz, nicht
    // nach Liste — sonst läge die Rüstung je nach Zufall über dem Helm.
    await zeige(
      tester,
      worn: <String>['gear-drachenhelm', 'gear-kurzbogen', 'gear-lederwams'],
    );

    expect(figurenbilder(tester), <String>[
      CharacterStage.assetPath,
      CharacterStage.overlays['gear-lederwams']!,
      CharacterStage.overlays['gear-kurzbogen']!,
      CharacterStage.overlays['gear-drachenhelm']!,
    ]);
  });

  testWidgets('Ring und Talisman zeigen sich nicht auf der Figur', (
    tester,
  ) async {
    final ring = GearCatalog.forSlot(GearSlot.ring).first.id;
    await zeige(tester, worn: <String>[ring]);

    expect(figurenbilder(tester), <String>[CharacterStage.assetPath]);
  });
}
