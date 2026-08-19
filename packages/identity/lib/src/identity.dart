import 'title.dart';
import 'title_catalog.dart';

/// Wer der Charakter ist: sein Name und der Titel, den er trägt.
///
/// **Was hier steht und was nicht.** Gespeichert wird nur, was der Nutzer
/// entschieden hat — der eingegebene Name und die *Wahl* eines Titels.
/// Welche Titel verdient sind, steht nicht hier; das ergibt sich jederzeit
/// neu aus dem Fortschritt ([TitleCatalog.earnedBy]). Zwei Wahrheiten
/// darüber, was jemand geschafft hat, wären dieselbe Fehlerquelle, die bei
/// Gold und Erfahrung schon vermieden wurde (ADR-0008, ADR-0011).
class Identity {
  const Identity({this.name = '', this.chosenTitleId});

  const Identity.empty() : this();

  /// Leer, solange nichts eingegeben wurde. Die Oberfläche zeigt dann
  /// [fallbackName] und fragt danach.
  final String name;

  /// Der gewählte Titel — oder null für „keinen tragen".
  ///
  /// Dass hier etwas steht, heißt **nicht**, dass der Titel getragen wird:
  /// [titleFor] prüft bei jeder Anzeige gegen den Fortschritt. So kann ein
  /// von Hand bearbeiteter Spielstand keinen unverdienten Titel einbringen.
  final String? chosenTitleId;

  /// Der Name ist eine Zeile, kein Aufsatz.
  static const int maxNameLength = 24;

  static const String fallbackName = 'Namenlos';

  bool get hasName => name.isNotEmpty;

  String get displayName => hasName ? name : fallbackName;

  /// Der Titel, der tatsächlich getragen wird — null, wenn keiner gewählt
  /// oder der gewählte (noch) nicht verdient ist.
  CharacterTitle? titleFor(TitleStats stats) {
    final title = TitleCatalog.byId(chosenTitleId);
    if (title == null) return null;
    return title.isEarnedBy(stats) ? title : null;
  }

  /// Die Zeile, die oben auf dem Charakterbildschirm steht:
  /// „Frederik, der Beständige" — oder nur „Frederik".
  String displayLine(TitleStats stats) {
    final title = titleFor(stats);
    return title == null ? displayName : '$displayName, ${title.label}';
  }

  /// Setzt den Namen. Leerraum am Rand fällt weg, zu Langes wird gekürzt —
  /// die Oberfläche darf sich darauf verlassen, dass hier nichts
  /// Unmögliches ankommt.
  Identity withName(String value) {
    final trimmed = value.trim();
    final capped = trimmed.length > maxNameLength
        ? trimmed.substring(0, maxNameLength)
        : trimmed;
    return Identity(name: capped, chosenTitleId: chosenTitleId);
  }

  /// Wählt einen Titel oder legt ihn ab (null).
  ///
  /// Nimmt bewusst auch einen unverdienten an: Geprüft wird beim Anzeigen,
  /// nicht beim Setzen. Damit bleibt eine Wahl erhalten, wenn ein Titel
  /// kurzzeitig nicht verdient scheint -- und es gibt nur **eine** Stelle,
  /// an der die Bedingung gilt.
  Identity withTitle(String? titleId) {
    return Identity(name: name, chosenTitleId: titleId);
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{'name': name, 'title': chosenTitleId};
  }

  /// Liest die Identität. Was nicht lesbar ist, fehlt einfach — dieselbe
  /// Nachsicht wie im übrigen Spielstand (ADR-0010).
  factory Identity.fromJson(Map<String, Object?> json) {
    final name = json['name'];
    final title = json['title'];

    return Identity(
      name: name is String ? name : '',
      chosenTitleId: title is String && title.isNotEmpty ? title : null,
    );
  }
}
