import 'dart:typed_data';

/// Worum es in einem Feedback geht — genau eine Kategorie je Bericht.
enum FeedbackArt {
  bug('🐞', 'Bug'),
  idee('💡', 'Idee'),
  unklar('🤔', 'Unklar/nervt');

  const FeedbackArt(this.zeichen, this.wort);

  final String zeichen;
  final String wort;

  /// Wie die Kategorie auf dem Chip und im Discord steht.
  String get beschriftung => '$zeichen $wort';
}

/// Ein Feedback aus der Testphase (11.11.2026), samt allem, was
/// automatisch mitgeht. **Ein Wert, keine Logik** — wie er verschickt
/// wird, entscheidet der [FeedbackDienst].
class FeedbackBericht {
  const FeedbackBericht({
    required this.art,
    required this.text,
    required this.zeitpunkt,
    required this.umgebung,
    this.screenshot,
    this.screen,
    this.spieler,
    this.level,
  });

  final FeedbackArt art;
  final String text;
  final DateTime zeitpunkt;

  /// App-Version, Build, Gerät und Betriebssystem.
  final FeedbackUmgebung umgebung;

  /// Der Screen als PNG, schon verkleinert — oder `null`, wenn der
  /// Tester ihn entfernt hat.
  final Uint8List? screenshot;

  /// Von welchem Screen aus das Feedback geöffnet wurde.
  final String? screen;

  /// Name des Spielers, wenn er einen gewählt hat.
  final String? spieler;
  final int? level;
}

/// Was über App und Gerät mitgeschickt wird.
class FeedbackUmgebung {
  const FeedbackUmgebung({
    required this.appVersion,
    required this.build,
    required this.geraet,
    required this.system,
  });

  final String appVersion;
  final String build;

  /// Hersteller und Modell, z. B. „Google Pixel 7“.
  final String geraet;

  /// Betriebssystem und Version, z. B. „Android 14 (SDK 34)“.
  final String system;

  static const FeedbackUmgebung unbekannt = FeedbackUmgebung(
    appVersion: '?',
    build: '?',
    geraet: 'unbekannt',
    system: 'unbekannt',
  );
}
