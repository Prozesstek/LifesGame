import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/ui/phone_frame.dart';

/// Prüft den Vorschau-Rahmen selbst.
///
/// **Warum das ein eigener Test sein muss.** `PhoneFrame` schaltet sich über
/// [kIsWeb] frei, und `kIsWeb` ist im Test immer falsch — die erste Fassung
/// war deshalb vollständig ungetestet und lief im Browser mit einem
/// Überlauf von 5990 Pixeln quer über den Bildschirm. Sichtbar war das nur
/// in Chrome, grün war alles andere.
///
/// Deshalb ist `enabled` heute ein Parameter und keine feste Abfrage.
void main() {
  /// Ein Fenster, in das der Rahmen passt.
  void useDesktopView(
    WidgetTester tester, {
    Size size = const Size(1400, 950),
  }) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Die App, wie `main.dart` sie aufbaut: Rahmen **über** `MaterialApp`.
  /// Genau diese Reihenfolge war der Fehler, also prüft der Test sie.
  Widget appImRahmen({bool enabled = true}) {
    return PhoneFrame(
      enabled: enabled,
      child: const MaterialApp(
        home: Scaffold(body: Center(child: Text('Inhalt'))),
      ),
    );
  }

  testWidgets('der Rahmen läuft nicht über', (tester) async {
    useDesktopView(tester);
    await tester.pumpWidget(appImRahmen());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Inhalt'), findsOneWidget);
  });

  testWidgets('die App bekommt genau Handygröße', (tester) async {
    useDesktopView(tester);
    await tester.pumpWidget(appImRahmen());
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(MaterialApp));

    expect(size.width, PhoneFrame.phoneSize.width);
    expect(size.height, PhoneFrame.phoneSize.height);
  });

  testWidgets('in einem zu kleinen Fenster tritt der Rahmen zurück', (
    tester,
  ) async {
    // Ein Rahmen, der selbst nicht passt, wäre schlimmer als keiner.
    useDesktopView(tester, size: const Size(500, 600));
    await tester.pumpWidget(appImRahmen());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final size = tester.getSize(find.byType(MaterialApp));
    expect(size.height, 600);
  });

  testWidgets('ausgeschaltet reicht er das Kind unverändert durch', (
    tester,
  ) async {
    // Der Fall auf dem echten Gerät: kein Rahmen, volle Fläche.
    useDesktopView(tester, size: const Size(390, 844));
    await tester.pumpWidget(appImRahmen(enabled: false));
    await tester.pumpAndSettle();

    expect(find.byType(PhoneFrame), findsOneWidget);
    expect(tester.getSize(find.byType(MaterialApp)), const Size(390, 844));
    expect(tester.takeException(), isNull);
  });

  group('Auf einem echten Handy gibt es keinen Rahmen', () {
    // **Der Fall, den die PWA neu gemacht hat.** Auf dem Startbildschirm
    // eines iPhones laeuft dieselbe Web-Fassung -- und dort *ist* der
    // Bildschirm bereits das Geraet. Die Groessenpruefung faengt das
    // nicht ab: Ein iPhone Pro Max misst 430 x 932 Punkte, der Rahmen
    // braucht 406 x 860. Er passt also und wuerde gezeichnet.
    // **Die Ueberschreibung muss im Testkoerper selbst zurueckgesetzt
    // werden.** `flutter_test` prueft nach jedem Test, dass kein
    // foundation-Debugschalter stehen geblieben ist -- ein `tearDown`
    // laeuft dafuer zu spaet.
    testWidgets('ein Geraet in Rahmengroesse zeigt trotzdem keinen', (
      tester,
    ) async {
      // 430 x 932 -- ein iPhone Pro Max, gross genug fuer den Rahmen.
      useDesktopView(tester, size: const Size(430, 932));
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(appImRahmen(enabled: false));
      await tester.pumpAndSettle();

      expect(find.text('Inhalt'), findsOneWidget);
      // Ohne Rahmen fuellt die App den Bildschirm; mit Rahmen waere sie
      // auf 390 Punkte beschnitten.
      expect(tester.getSize(find.byType(MaterialApp)).width, 430);

      debugDefaultTargetPlatformOverride = null;
    });

    test('der Standard haengt am Geraet, nicht nur am Browser', () {
      // Im Test ist kIsWeb immer falsch -- der Standard ist hier also
      // ohnehin `false`. Geprueft wird, dass die Entscheidung ueberhaupt
      // an der Plattform haengt und nicht fest verdrahtet ist: Auf einem
      // Handy bleibt sie auch dann `false`, wenn kIsWeb wahr waere.
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(PhoneFrame.showsFrameByDefault, isFalse);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(PhoneFrame.showsFrameByDefault, isFalse);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
