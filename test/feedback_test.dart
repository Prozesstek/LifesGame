import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lifes_game/feedback/feedback_bericht.dart';
import 'package:lifes_game/feedback/feedback_blatt.dart';
import 'package:lifes_game/feedback/feedback_dienst.dart';
import 'package:lifes_game/feedback/feedback_knopf.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/main.dart';

FeedbackBericht _bericht({Uint8List? bild}) => FeedbackBericht(
  art: FeedbackArt.bug,
  text: 'Der Knopf geht nicht',
  zeitpunkt: DateTime.utc(2026, 11, 11, 12),
  umgebung: const FeedbackUmgebung(
    appVersion: '0.1.0',
    build: '1',
    geraet: 'Google Pixel 7',
    system: 'Android 14 (SDK 34)',
  ),
  screenshot: bild,
  screen: 'ShopScreen',
  spieler: 'Brett',
  level: 4,
);

class _FakeDienst implements FeedbackDienst {
  _FakeDienst({this.fehler});

  final FeedbackFehler? fehler;
  final List<FeedbackBericht> gesendet = <FeedbackBericht>[];

  @override
  Future<void> senden(FeedbackBericht bericht) async {
    final f = fehler;
    if (f != null) throw f;
    gesendet.add(bericht);
  }
}

Future<FeedbackUmgebung> _umgebung() async => FeedbackUmgebung.unbekannt;

void main() {
  group('DiscordFeedbackDienst', () {
    test('schickt Embed und Screenshot als multipart', () async {
      late String rumpf;
      late http.BaseRequest gesehen;
      final client = MockClient.streaming((anfrage, strom) async {
        gesehen = anfrage;
        rumpf = latin1.decode(await strom.toBytes());
        return http.StreamedResponse(Stream.value(<int>[]), 200);
      });
      final dienst = DiscordFeedbackDienst(
        webhook: 'https://discord.com/api/webhooks/1/abc',
        client: client,
      );
      await dienst.senden(_bericht(bild: Uint8List.fromList(<int>[1, 2, 3])));

      expect(gesehen.method, 'POST');
      expect(rumpf, contains('name="payload_json"'));
      expect(rumpf, contains('filename="screenshot.png"'));
      expect(rumpf, contains('attachment://screenshot.png'));
    });

    test('der Embed trägt alles, was mitgehen soll', () {
      final n = DiscordFeedbackDienst.nutzlast(_bericht());
      final embed = (n['embeds']! as List<Object?>).first! as Map;
      expect(embed['title'], '🐞 Bug');
      expect(embed['description'], 'Der Knopf geht nicht');
      final felder = jsonEncode(embed['fields']);
      for (final wert in <String>[
        'ShopScreen',
        'Brett',
        '4',
        '0.1.0 (Build 1)',
        'Google Pixel 7',
        'Android 14 (SDK 34)',
      ]) {
        expect(felder, contains(wert), reason: wert);
      }
      // Ohne Bild verweist der Embed auf keins.
      expect(embed.containsKey('image'), isFalse);
      // Niemand wird angepingt.
      expect(n['allowed_mentions'], {'parse': <Object?>[]});
    });

    test('eine Antwort ohne 2xx ist ein Fehler', () async {
      final dienst = DiscordFeedbackDienst(
        webhook: 'https://discord.com/api/webhooks/1/abc',
        client: MockClient((_) async => http.Response('nein', 429)),
      );
      expect(() => dienst.senden(_bericht()), throwsA(isA<FeedbackFehler>()));
    });

    test('kein Netz ist ein Fehler, kein Absturz', () async {
      final dienst = DiscordFeedbackDienst(
        webhook: 'https://discord.com/api/webhooks/1/abc',
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      expect(() => dienst.senden(_bericht()), throwsA(isA<FeedbackFehler>()));
    });

    test('ohne Webhook sagt er es, statt zu senden', () async {
      final dienst = DiscordFeedbackDienst(webhook: '');
      expect(() => dienst.senden(_bericht()), throwsA(isA<FeedbackFehler>()));
    });
  });

  group('Das Blatt', () {
    Future<void> oeffne(WidgetTester tester, FeedbackDienst dienst) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => zeigeFeedbackBlatt(
                    context,
                    dienst: dienst,
                    screenshot: Uint8List.fromList(_png),
                    screen: 'HomeScreen',
                    umgebung: _umgebung,
                  ),
                  child: const Text('auf'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('auf'));
      await tester.pumpAndSettle();
    }

    FilledButton senden(WidgetTester tester) =>
        tester.widget<FilledButton>(find.byKey(FeedbackBlatt.sendenKey));

    testWidgets('Senden geht erst mit Kategorie und Text', (tester) async {
      final dienst = _FakeDienst();
      await oeffne(tester, dienst);

      expect(find.text('Was ist passiert?'), findsOneWidget);
      expect(senden(tester).onPressed, isNull);

      await tester.tap(find.text('💡 Idee'));
      await tester.pump();
      expect(senden(tester).onPressed, isNull, reason: 'Text fehlt');

      await tester.enterText(find.byKey(FeedbackBlatt.textKey), 'Mehr Gold');
      await tester.pump();
      expect(senden(tester).onPressed, isNotNull);

      await tester.tap(find.byKey(FeedbackBlatt.sendenKey));
      await tester.pumpAndSettle();
      expect(dienst.gesendet.single.art, FeedbackArt.idee);
      expect(dienst.gesendet.single.text, 'Mehr Gold');
      expect(dienst.gesendet.single.screen, 'HomeScreen');
      expect(dienst.gesendet.single.screenshot, isNotNull);
      expect(find.byType(FeedbackBlatt), findsNothing);
    });

    testWidgets('das Bild lässt sich entfernen', (tester) async {
      final dienst = _FakeDienst();
      await oeffne(tester, dienst);
      await tester.tap(find.byKey(FeedbackBlatt.bildWegKey));
      await tester.pump();
      await tester.tap(find.text('🐞 Bug'));
      await tester.enterText(find.byKey(FeedbackBlatt.textKey), 'x');
      await tester.pump();
      await tester.tap(find.byKey(FeedbackBlatt.sendenKey));
      await tester.pumpAndSettle();
      expect(dienst.gesendet.single.screenshot, isNull);
    });

    testWidgets('ein Fehler lässt das Blatt offen und den Text stehen', (
      tester,
    ) async {
      final dienst = _FakeDienst(fehler: const FeedbackFehler('Kein Netz.'));
      await oeffne(tester, dienst);
      await tester.tap(find.text('🤔 Unklar/nervt'));
      await tester.enterText(find.byKey(FeedbackBlatt.textKey), 'Hä?');
      await tester.pump();
      await tester.tap(find.byKey(FeedbackBlatt.sendenKey));
      await tester.pumpAndSettle();

      expect(find.byType(FeedbackBlatt), findsOneWidget);
      expect(find.text('Kein Netz.'), findsOneWidget);
      expect(find.text('Hä?'), findsOneWidget);
    });
  });

  testWidgets('die Sprechblase steht auf der Startseite', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
        ],
        child: const LifesGameApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(FeedbackHuelle.knopfKey), findsOneWidget);
  });
}

/// Ein 1 × 1-PNG, damit `Image.memory` etwas zu zeigen hat.
const List<int> _png = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0xF0,
  0x1F,
  0x00,
  0x05,
  0x00,
  0x01,
  0xFF,
  0x89,
  0x99,
  0x3D,
  0x1D,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
