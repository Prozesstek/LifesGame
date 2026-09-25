import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:lifes_game/home/widgets/character_stage.dart';
import 'package:lifes_game/ui/pixel_art.dart';
import 'package:progression/progression.dart';

/// Der getragene Helm auf der Figur des Startbildschirms.
///
/// Dieselben Nähte wie in `gear_icon_test.dart` — jeder Helm hat eine
/// Zeichnung, jede Zeichnung ist da und angemeldet — plus die eine
/// Zusage, an der das Bild hängt: **gleich groß wie die Figur**, sonst
/// sitzt der Helm nicht auf dem Kopf.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('jeder Helm im Katalog hat eine Zeichnung auf der Figur', () {
    for (final helm in GearCatalog.forSlot(GearSlot.helm)) {
      expect(
        CharacterStage.helmOverlays,
        contains(helm.id),
        reason: '${helm.name} steht im Laden, aber die Figur trägt ihn nicht.',
      );
    }
  });

  test('keine Zeichnung zeigt auf einen Helm, den es nicht gibt', () {
    final helme = GearCatalog.forSlot(GearSlot.helm).map((h) => h.id);
    for (final id in CharacterStage.helmOverlays.keys) {
      expect(helme, contains(id));
    }
  });

  test('jede Zeichnung ist ein PNG in der Größe der Figur', () async {
    final figur = await rootBundle.load(CharacterStage.assetPath);
    final breite = figur.getUint32(16);
    final hoehe = figur.getUint32(20);
    expect(breite, PixelArt.assetSize);

    for (final pfad in CharacterStage.helmOverlays.values) {
      final daten = await rootBundle.load(pfad);
      expect(daten.getUint32(0), 0x89504E47, reason: '$pfad ist kein PNG.');
      expect(daten.getUint32(16), breite, reason: pfad);
      expect(daten.getUint32(20), hoehe, reason: pfad);
    }
  });

  Future<void> zeige(WidgetTester tester, {String? helmId}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 400,
            child: CharacterStage(
              level: LevelCurve.levelFor(0),
              gold: 0,
              helmId: helmId,
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

  testWidgets('mit Helm liegt seine Zeichnung über der Figur', (tester) async {
    await zeige(tester, helmId: 'gear-drachenhelm');

    final bilder = figurenbilder(tester);
    // Reihenfolge ist Stapelreihenfolge: die Figur unten, der Helm oben.
    expect(bilder, <String>[
      CharacterStage.assetPath,
      CharacterStage.helmOverlays['gear-drachenhelm']!,
    ]);
  });
}
