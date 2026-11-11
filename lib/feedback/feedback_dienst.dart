import 'dart:convert';

import 'package:http/http.dart' as http;

import 'feedback_bericht.dart';

/// **Wohin ein Feedback geht** — gekapselt, damit sich das Ziel später
/// austauschen lässt (11.11.2026): Heute ein Discord-Webhook, morgen
/// vielleicht ein eigenes Backend. Der Bildschirm kennt nur diese Naht.
abstract interface class FeedbackDienst {
  /// Schickt [bericht] ab. Wirft eine [FeedbackFehler], wenn es nicht
  /// ankommt — der Bildschirm zeigt dann den Fehler und behält den Text.
  Future<void> senden(FeedbackBericht bericht);
}

/// Was beim Senden schiefgehen kann, in einem Satz für den Tester.
class FeedbackFehler implements Exception {
  const FeedbackFehler(this.meldung);

  final String meldung;

  @override
  String toString() => meldung;
}

/// Die Webhook-URL — **nicht im Code**, sondern beim Bauen eingesetzt:
/// `flutter build apk --dart-define-from-file=feedback.json`. Die Datei
/// ist gitignored, `feedback.example.json` zeigt, wie sie aussieht.
const String feedbackWebhook = String.fromEnvironment('FEEDBACK_WEBHOOK');

/// Schickt ein Feedback als Embed an einen Discord-Webhook, den
/// Screenshot als Dateianhang.
class DiscordFeedbackDienst implements FeedbackDienst {
  DiscordFeedbackDienst({
    this.webhook = feedbackWebhook,
    http.Client? client,
    this.zeitlimit = const Duration(seconds: 20),
  }) : _client = client ?? http.Client();

  final String webhook;
  final http.Client _client;
  final Duration zeitlimit;

  /// Discord nimmt in einem Embed höchstens 4096 Zeichen Beschreibung.
  static const int _maxText = 4000;

  /// Die Farbe des Embeds je Kategorie.
  static int farbeVon(FeedbackArt art) => switch (art) {
    FeedbackArt.bug => 0xD9534F,
    FeedbackArt.idee => 0xF0AD4E,
    FeedbackArt.unklar => 0x5B8DEF,
  };

  /// Was Discord als `payload_json` bekommt — eine eigene Methode, damit
  /// ein Test den Inhalt ohne Netz prüfen kann.
  static Map<String, Object?> nutzlast(FeedbackBericht b) {
    final text = b.text.length > _maxText
        ? '${b.text.substring(0, _maxText)} …'
        : b.text;
    final u = b.umgebung;
    String feld(String? wert) => (wert == null || wert.isEmpty) ? '—' : wert;
    return <String, Object?>{
      'username': 'Lifes Game Feedback',
      'embeds': <Object?>[
        <String, Object?>{
          'title': b.art.beschriftung,
          'description': text,
          'color': farbeVon(b.art),
          'timestamp': b.zeitpunkt.toUtc().toIso8601String(),
          'fields': <Object?>[
            {'name': 'Screen', 'value': feld(b.screen), 'inline': true},
            {'name': 'Spieler', 'value': feld(b.spieler), 'inline': true},
            {
              'name': 'Level',
              'value': b.level?.toString() ?? '—',
              'inline': true,
            },
            {
              'name': 'App',
              'value': '${u.appVersion} (Build ${u.build})',
              'inline': true,
            },
            {'name': 'Gerät', 'value': u.geraet, 'inline': true},
            {'name': 'System', 'value': u.system, 'inline': true},
          ],
          if (b.screenshot != null)
            'image': <String, Object?>{'url': 'attachment://screenshot.png'},
        },
      ],
      // Nie jemanden anpingen, egal was im Text steht.
      'allowed_mentions': <String, Object?>{'parse': <Object?>[]},
    };
  }

  @override
  Future<void> senden(FeedbackBericht bericht) async {
    if (webhook.isEmpty) {
      throw const FeedbackFehler(
        'Feedback ist in dieser Fassung nicht eingerichtet.',
      );
    }
    final anfrage = http.MultipartRequest('POST', Uri.parse(webhook))
      ..fields['payload_json'] = jsonEncode(nutzlast(bericht));
    final bild = bericht.screenshot;
    if (bild != null) {
      anfrage.files.add(
        http.MultipartFile.fromBytes(
          'files[0]',
          bild,
          filename: 'screenshot.png',
        ),
      );
    }
    final http.StreamedResponse antwort;
    try {
      antwort = await _client.send(anfrage).timeout(zeitlimit);
    } on Exception {
      throw const FeedbackFehler(
        'Senden hat nicht geklappt. Bist du online? Versuch es gleich noch '
        'einmal.',
      );
    }
    // Den Rumpf lesen, damit die Verbindung frei wird.
    await antwort.stream.drain<void>();
    if (antwort.statusCode < 200 || antwort.statusCode >= 300) {
      throw FeedbackFehler(
        'Senden hat nicht geklappt (Fehler ${antwort.statusCode}). '
        'Versuch es gleich noch einmal.',
      );
    }
  }
}
