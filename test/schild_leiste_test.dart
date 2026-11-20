import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/ui/schild_leiste.dart';

/// Die Kopfzeile als Holzschild an Ketten (20.11.2026): Das Schild wächst
/// mit dem Wort, die Schrift steht nie über den Rand, der Inhalt beginnt
/// darunter, und das Schild nimmt keinen Tipp an.
void main() {
  Future<void> zeige(
    WidgetTester tester,
    String titel, {
    double breite = 390,
    List<Widget> actions = const <Widget>[],
    Widget? body,
  }) async {
    tester.view.physicalSize = Size(breite, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: SchildLeiste(
            titel: titel,
            leading: const BackButton(),
            actions: actions,
          ),
          body: body,
        ),
      ),
    );
  }

  Rect brett(WidgetTester tester) => tester.getRect(
    find
        .descendant(
          of: find.byType(HaengeSchild),
          matching: find.byType(CustomPaint),
        )
        .first,
  );

  testWidgets('ein längeres Wort macht das Schild breiter', (tester) async {
    await zeige(tester, 'Laden');
    final kurz = brett(tester).width;
    await zeige(tester, 'Gewohnheiten');
    final lang = brett(tester).width;
    expect(lang, greaterThan(kurz));
  });

  testWidgets('das Wort hat links und rechts Luft', (tester) async {
    await zeige(tester, 'Gewohnheiten');
    final schild = brett(tester);
    final wort = tester.getRect(find.text('Gewohnheiten'));
    expect(wort.left - schild.left, closeTo(SchildLeiste.luft, 1));
    expect(schild.right - wort.right, closeTo(SchildLeiste.luft, 1));
  });

  testWidgets('ein zu langes Wort wird kleiner, statt überzustehen', (
    tester,
  ) async {
    await zeige(
      tester,
      'Jahresrückblick mit sehr langem Namen 2026',
      breite: 360,
      actions: const <Widget>[
        IconButton(onPressed: null, icon: Icon(Icons.share)),
        IconButton(onPressed: null, icon: Icon(Icons.info)),
      ],
    );
    expect(tester.takeException(), isNull);
    final schild = brett(tester);
    // Gemessen wird das verkleinerte Bild der Schrift.
    final box = tester.renderObject<RenderBox>(find.byType(FittedBox));
    final sichtbar = box.localToGlobal(Offset.zero) & box.size;
    expect(sichtbar.left, greaterThanOrEqualTo(schild.left));
    expect(sichtbar.right, lessThanOrEqualTo(schild.right));
    expect(
      tester
          .getSize(find.text('Jahresrückblick mit sehr langem Namen 2026'))
          .width,
      greaterThan(sichtbar.width),
    );
    // Und es stösst nicht an die Knöpfe.
    final zurueck = tester.getRect(find.byType(BackButton));
    expect(schild.left, greaterThan(zurueck.right));
    final teilen = tester.getRect(find.byIcon(Icons.share));
    expect(schild.right, lessThan(teilen.left));
  });

  testWidgets('der Inhalt beginnt unter dem Schild', (tester) async {
    await zeige(
      tester,
      'Laden',
      body: const Align(
        alignment: Alignment.topCenter,
        child: SizedBox(key: Key('inhalt'), height: 10, width: 10),
      ),
    );
    final inhalt = tester.getRect(find.byKey(const Key('inhalt')));
    expect(inhalt.top, greaterThanOrEqualTo(brett(tester).bottom));
  });

  testWidgets('das Schild nimmt keinen Tipp an', (tester) async {
    await zeige(tester, 'Laden');
    final maler = tester.renderObject(
      find
          .descendant(
            of: find.byType(HaengeSchild),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    final treffer = tester.hitTestOnBinding(brett(tester).center);
    expect(treffer.path.any((e) => identical(e.target, maler)), isFalse);
  });

  testWidgets('der Vorleser hört den Titel als Überschrift', (tester) async {
    await zeige(tester, 'Laden');
    expect(
      tester.getSemantics(find.bySemanticsLabel('Laden')),
      matchesSemantics(label: 'Laden', isHeader: true, namesRoute: true),
    );
  });
}
